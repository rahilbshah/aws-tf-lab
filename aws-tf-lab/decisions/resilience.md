---
decision: resilience
question: How much failure must this survive?
spans: [14-dr-resilience, 07-rds-aurora, 04-alb-asg]
tags: [decision, domain/resilient]
---

# How much failure must this survive?

The notes explain each mechanism. This routes you to one. Work top-down — the
first question that applies settles it, and the answer is usually the smaller one.

## 1. What is actually failing?

The deciding question is **the size of the blast radius you are buying against** —
the three sizes use different tools and do not substitute for each other.

| What must survive | What you are buying | Go to |
|---|---|---|
| an instance, or an Availability Zone | **high availability** | §2 |
| an entire Region | **disaster recovery** | §3 |
| the data becoming **wrong** | **backups** — neither of the above | §5 |

↳ [[14-dr-resilience#HA vs DR]]

## 2. Surviving an AZ — does the tier hold state?

**Stateless compute** → an ASG across at least two AZs behind an ALB. Then the
fork people skip: **who may decide an instance is dead?** The ALB only stops
routing, never terminates; replacement happens only when the ASG honours that
verdict (`health_check_type = "ELB"`).
↳ [[04-alb-asg#The target group is the joint — and two health checks meet inside it]]

**Relational data** → Multi-AZ. The axis that gets mis-set: **is the second copy
there to stay up, or to go faster?** Staying up → Multi-AZ: synchronous,
unreadable, automatic. Going faster → a read replica: asynchronous, readable,
promoted by hand. Not alternatives — Multi-AZ *with* replicas is normal. Want one
copy doing both jobs → Aurora, where a replica is failover target and read
scaling at once, because the instances share the volume instead of owning copies.
↳ [[07-rds-aurora#Multi-AZ vs Read Replica (memorize)]] · [[07-rds-aurora#Why Aurora's storage layer changes everything above it]]

## 3. Surviving a Region — two numbers, two different halves

RPO routes the **data** layer, RTO routes the **compute** layer. Answer them
separately; pairing them wrongly lands a design far too expensive or far too slow.
↳ [[14-dr-resilience#Two numbers decide everything: RTO and RPO]]

### 3a. RPO → the data layer

Axis: **may the last good copy be a scheduled one?**

- **Hours acceptable** → AWS Backup cross-Region copy, or copied snapshots.
- **Seconds to minutes** → continuous replication, then one more axis: **where do
  the writes happen?** One writer, promote on failure → **Aurora Global
  Database**. Writes accepted everywhere → **DynamoDB Global Tables**, accepting
  last-writer-wins.

↳ [[14-dr-resilience#Which service buys you which RPO]] · [[14-dr-resilience#Picking a cross-Region database]]

### 3b. RTO → the compute layer

Axis, in AWS's own framing: **could it serve a request right now, with nobody
doing anything first?**

- **Nothing deployed** → backup & restore, viable only with IaC and copied AMIs.
- **Deployed, compute off** → pilot light.
- **Running, just small** → warm standby.
- **Already serving users** → multi-site active/active; nothing was ever passive.

↳ [[14-dr-resilience#Pilot light vs warm standby — the distinction that gets tested]] · [[14-dr-resilience#The four strategies, and what's actually running]]

## 4. How does traffic find the Region that is up?

Axis: **what sits in the path that could be cached, or degraded?** Default →
Route 53 failover on health checks, a data-plane operation bounded by your TTL.
Clients that cache DNS, or a static-IP requirement → Global Accelerator. Only
some requests need to move → CloudFront origin failover, per request rather than
the whole site. Anything needing a *configuration change* mid-disaster — Route 53
weights, a traffic dial, Auto Scaling reaching capacity — is a control plane, and
those are least available exactly when you need them. The clock runs from the
failure, not the decision, so a tight RTO routes to **deep health checks on KPIs**.
↳ [[14-dr-resilience#Data plane vs control plane — why some failovers are more reliable]] · [[14-dr-resilience#Detection and testing — the two halves everyone skips]]

## 5. When the data is wrong rather than gone

Axis: **would another faithful copy help?** For corruption, a bad release,
ransomware or a deletion, no — replication copies it within seconds. That routes
to point-in-time recovery, S3 versioning, and cross-account or immutable backups.
A copy outliving the instance means a **manual** snapshot, and every restore lands
on a **new endpoint**, so recovery is always a cutover.
↳ [[07-rds-aurora#Backups, restores, and the encryption rule with no undo]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **Multi-AZ bought to relieve read pressure** — the standby answers no queries.
  The mirror error is as common: a read replica chosen to survive an AZ.
- **An ASG across three AZs counted as DR.** Excellent HA, nothing against losing
  the Region — no copy sits anywhere the outage can't reach.
- **Warm standby that reaches capacity via Auto Scaling**, making recovery depend
  on a control-plane call and on quotas nobody raised. Pre-provision instead.
- **The ALB health check tuned, the ASG left on its default.** Routing is fixed,
  replacement never happens, and the fleet quietly runs at N-1.
- **More replication bought against corruption.** It defends against data being
  *lost*, never *wrong*, and reaches the DR Region before anyone notices.
- **An RDS cross-Region read replica where Aurora Global Database belongs.** Both
  replicate; only one promotes in under a minute, the other reboots on the way.
- **"Data residency pins us to one Region, so DR is impossible."** The strategies
  are about discrete locations: run the same one across that Region's AZs.
