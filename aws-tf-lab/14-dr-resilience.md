---
topic: 14-dr-resilience
domain: resilient
status: reviewed
services: [Route53, GlobalAccelerator, Aurora, DynamoDB, S3, AWSBackup, CloudFormation]
related: [07-rds-aurora, 10-route53, 04-alb-asg, 12-storage-extras, 09-s3-advanced]
tags: [topic, domain/resilient]
---

# 14 – Disaster recovery & resilience

The cross-cutting note. Almost no new services — this is how the pieces you already know assemble into an architecture that survives losing a Region.

> [!warning] Build tier — **conceptual-only**
> A real multi-Region DR setup means paying for a second environment. This one is learned, not built — and the exam tests the *strategy choice*, not the HCL.

## What problem does this solve?

Every other note in this vault teaches a service. The exam mostly doesn't ask about services.

It asks things like: *"a three-tier application must survive the loss of an entire Region, with at most 5 minutes of data loss, at the lowest possible cost."*

Answering that needs Aurora Global Database, Route 53 failover, S3 replication and AWS Backup — four things you already know, assembled. Knowing each part individually isn't enough, and that gap is where a lot of "I knew all of this" marks go.

This note is the assembly instructions.

It also draws a line the exam cares about. **High availability** is surviving the loss of a *component* — an instance, an Availability Zone. That's Multi-AZ, an ASG across zones, an ALB. **Disaster recovery** is surviving something bigger: a whole Region, or data corruption that replicates faithfully into every copy you have. Different problem, different tools.

> In one line: HA survives losing a component, DR survives losing a Region — and the exam's DR questions are asking you to assemble services you already know.

## How it actually works

### Two numbers decide everything: RTO and RPO

Before choosing anything, a DR question tells you two numbers, and they're the whole basis for the answer.

- **RTO — Recovery Time Objective.** How long you may be **down**. Measured in time.
- **RPO — Recovery Point Objective.** How much **data** you may lose. Also measured in time — "we can afford to lose the last 15 minutes of writes."

They sound similar and they measure completely different things. A useful way to hold them: **RPO looks backwards** from the disaster (how far back is your last good copy?), **RTO looks forwards** (how long until you're serving again?).

Both are set by the **business**, not by technology. "What's our RTO?" is a question for whoever owns the revenue, and the architecture follows from the answer.

The reason they drive everything: **RPO is bought with replication, RTO is bought with pre-provisioned capacity**, and those cost money in different ways. A tight RPO means continuous replication. A tight RTO means paying for infrastructure that sits there doing nothing until the day it's needed.

> In one line: RPO is how much data you can lose, RTO is how long you can be down, and the two together pick the strategy.

### The four strategies, and what's actually running

AWS names four, and they line up on a single axis: **how much of your workload is already running in the recovery Region.** Cost and speed both climb together as you go down.

| Strategy | Running in the DR Region | RTO | Cost |
|---|---|---|---|
| **Backup & restore** | nothing — just backups sitting in storage | hours | lowest |
| **Pilot light** | data replicating + core infrastructure; **servers switched off** | tens of minutes | low |
| **Warm standby** | a **scaled-down but fully working** copy, taking no traffic | minutes | medium |
| **Multi-site active/active** | a **full** copy, actively serving users | near zero | highest |

Three of the four are **active/passive** — only one Region serves users, and the other waits. Only multi-site is active/active. (Hot standby is the odd one: full capacity deployed, still active/passive.)

**Backup & restore** is backups plus a plan. Note what it's *for*: AWS frames it as the answer to **data loss or corruption**, not just to a cheap Region outage. It's the only strategy that gives you a copy the disaster didn't touch — which is why a corruption or ransomware scenario lands here even when the RTO sounds tight. Crucially, "backups" means more than data: to rebuild in another Region you also need the **infrastructure, configuration and application code**. AWS is emphatic that this means **infrastructure as code** — without CloudFormation or CDK, rebuilding by hand is slow and error-prone, and you'll miss your RTO. Back up your **AMIs** too, and copy them to the recovery Region.

**Pilot light** keeps the *data* live — continuously replicated — and the core infrastructure deployed, but the application servers are **switched off**. The metaphor is exact: a pilot light is a small permanent flame you use to ignite the main burner.

**Warm standby** is a complete, working, smaller copy. It could serve traffic right now if you pointed traffic at it — just not at full volume.

**Multi-site active/active** runs everywhere at once and serves users from every Region. There is no failover, because nothing was ever passive. It's the most complex and most expensive, and it's the only one that gets you near-zero RTO.

One thing the strategy names hide: **all four can be built across Availability Zones instead of Regions.** If data-residency rules pin you to a country with only one AWS Region, you use that Region's AZs as your discrete locations. You lose protection against a Region-wide event, but you keep the strategy — and you keep compliance. The exam reaches for this whenever a scenario mentions data sovereignty.

One caveat that applies to all four: **replication is not backup.** Continuous replication copies your data faithfully — including a malicious deletion or a corruption bug. Every strategy still needs **point-in-time backups** alongside the replication.

> In one line: the four strategies differ only in how much is already running in the recovery Region, and cost and recovery speed rise together.

### Pilot light vs warm standby — the distinction that gets tested

These two are the most-confused pair in the topic, so here is AWS's own wording:

> *"Pilot light **cannot process requests without additional action taken first**, whereas warm standby **can handle traffic (at reduced capacity levels) immediately**. The pilot light approach requires you to 'turn on' servers, possibly deploy additional infrastructure, and scale up, whereas warm standby only requires you to **scale up** (everything is already deployed and running)."*

So the test is a single question: **could it serve a request right now, without you doing anything?**

- **No, something must be switched on first** → pilot light
- **Yes, just not much traffic** → warm standby

Both replicate data continuously. Both have infrastructure in the DR Region. The difference is entirely whether the compute is *running*.

> In one line: pilot light needs switching on before it can serve anything; warm standby is already serving, just small.

### Data plane vs control plane — why some failovers are more reliable

This is the subtlety that separates a good DR answer from a plausible one, and it's straight from the whitepaper.

AWS splits services into a **data plane** (doing the actual work — routing a packet, serving an object) and a **control plane** (changing the configuration — creating a resource, updating a setting). **Data planes are designed for higher availability than control planes.**

The consequence: **during a disaster, prefer operations that only use the data plane.** A control-plane operation may be exactly the thing that's degraded when you need it most.

| Failover mechanism | Plane | Resilience |
|---|---|---|
| Route 53 **health checks** driving failover | **data** | ✅ most resilient |
| Amazon Application Recovery Controller switches | **data** | ✅ manual failover, still data plane |
| Changing Route 53 **weights** | control | ⚠️ works, less resilient |
| Global Accelerator **traffic dial** | control | ⚠️ |
| **Auto Scaling** scaling the DR Region up | control | ⚠️ a dependency at the worst moment |

That last row has a real design consequence. If your warm standby depends on Auto Scaling to reach production capacity, you've made your recovery depend on a control-plane operation. Provisioning the full capacity up front removes that dependency — a configuration AWS calls **statically stable**, and the thing that turns warm standby into **hot standby**.

Also worth knowing: automatic failover is not automatically better. AWS advises caution, because a **false alarm** costs you a real failover with real data loss. Many teams script the failover fully but keep the trigger manual — "automated, push-button" rather than automatic.

> In one line: prefer data-plane operations for failover, because control planes are likelier to be degraded exactly when you need them.

### Which service buys you which RPO

Your RPO target picks the replication mechanism, and this is where everything you already know slots in.

| Mechanism | RPO | Notes |
|---|---|---|
| **Aurora Global Database** | **~1 second** | typical cross-Region latency under a second; promote a secondary in **under a minute**; up to **10** secondary Regions |
| **DynamoDB Global Tables** | seconds | **multi-active** — read *and* write in every Region; conflicts resolved **last-writer-wins** |
| **S3 Cross-Region Replication** | seconds–minutes | S3 RTC gives a **15-minute SLA** |
| **RDS cross-Region read replica** | seconds–minutes | promotion takes **a few minutes and includes a reboot** |
| **ElastiCache Global Datastore** | seconds | cross-Region Redis replication |
| **AWS Backup cross-Region copy** | hours | as often as the backup plan runs |
| **Snapshots copied manually** | hours–days | backup & restore territory |

Two details worth carrying:

**Aurora Global Database beats an RDS read replica for DR** on both numbers — sub-second replication versus seconds-to-minutes, and under-a-minute promotion versus a few minutes plus a reboot. If a question pairs "cross-Region" with "aggressive RTO/RPO", Aurora Global Database is usually the answer.

**S3 does not replicate delete markers by default**, and that's a feature: a malicious or accidental delete in the source Region doesn't destroy the DR copy.

For routing traffic to whichever Region is live: **Route 53 failover** with health checks (remember the TTL floor from [[10-route53]]), **Global Accelerator** when you need static IPs and failover that doesn't wait for DNS caches, or **CloudFront origin failover**, which switches **per request** rather than switching the whole site.

> In one line: your RPO target picks the replication mechanism, and Aurora Global Database is the strongest answer whenever the question pairs cross-Region with a tight recovery window.

### Detection and testing — the two halves everyone skips

Picking a strategy is the part that feels like architecture. These two are what actually decide whether the plan works, and the exam does ask about them.

**Detection eats your RTO.** The recovery clock does not start when you decide to fail over — it starts when the workload stops delivering. Everything before the failover is inside the budget too: detecting the incident, notifying the right people, escalating, evaluating whether normal recovery will beat the DR plan, and formally **declaring a disaster**. With a one-hour RTO, an alarm that takes 25 minutes to fire has already spent nearly half of it. This is why an aggressive RTO forces **deep health checks** — checks that exercise real functionality against your KPIs, not a shallow heartbeat that returns 200 while the database is unreachable.

The counterweight: deep checks and automatic triggers raise the risk of a **false alarm**, and failing over when you didn't need to is itself an availability event. AWS says this plainly — use caution.

**Testing is the whole game.** The whitepaper's sharpest line:

> *"Our experience has shown that the only error recovery that works is the path you test frequently."*

Two consequences that read like exam answers:

- **Keep the number of recovery paths small.** A rarely-executed recovery path is a broken one. A secondary data store you only ever read from will surprise you the first time you write to it under load.
- **Manage configuration drift in the DR Region.** The DR Region silently rots: AMIs go stale, **service quotas** were never raised, security groups drift from the primary. **AWS Config** records and detects the drift, **Systems Manager Automation** remediates it, and **CloudFormation drift detection** catches stacks that no longer match their template.

> In one line: detection time is spent out of your RTO budget, and the only recovery path that works is one you run often enough to trust.

## Exam recap

> [!info] Exam TL;DR
> - **RTO = how long you're down. RPO = how much data you lose.** Both set by the business. RPO is bought with replication; RTO is bought with pre-provisioned capacity.
> - **HA survives a component or AZ. DR survives a Region** (or data corruption).
> - **Four strategies, by how much is running in the DR Region:** backup & restore (nothing) → pilot light (data + core infra, **servers off**) → warm standby (**scaled-down but working**) → multi-site active/active (full, serving). Cost and speed rise together.
> - **Pilot light vs warm standby:** pilot light **cannot serve a request without action first**; warm standby **can serve immediately, at reduced capacity**. It's about whether compute is *running*.
> - **Backup & restore needs infrastructure as code** — you must rebuild infra, config and code, not just data. Back up and copy **AMIs** too.
> - **Prefer data-plane operations for failover.** Route 53 health checks and ARC are data plane; changing Route 53 weights, Global Accelerator traffic dials and **Auto Scaling** are control plane.
> - **Static stability / hot standby** = provision full capacity so recovery doesn't depend on Auto Scaling.
> - **Replication is not backup** — it faithfully copies corruption and deletions. Always keep point-in-time backups too.
> - **RPO by mechanism:** Aurora Global Database ~1s (promote **<1 min**, up to **10** secondary Regions) · DynamoDB Global Tables seconds, **multi-active, last-writer-wins** · S3 CRR seconds–minutes · RDS cross-Region read replica (promotion takes **minutes + a reboot**) · AWS Backup cross-Region copy hours.
> - **S3 does not replicate delete markers by default** — deliberately, so a source-Region deletion can't destroy the DR copy.
> - **Multi-site write strategies:** write global (Aurora Global) · write local (DynamoDB Global Tables) · write partitioned (bidirectional S3 replication).
> - **Detection time is spent out of your RTO.** Detect → notify → escalate → evaluate → declare → recover, all inside the budget. Aggressive RTO ⇒ **deep health checks**, not heartbeats.
> - **Only the recovery path you test frequently works.** Keep recovery paths few; manage **DR-Region configuration drift** (stale AMIs, unraised **service quotas**) with **AWS Config** + **SSM Automation** + **CloudFormation drift detection**.
> - **All four strategies can be built across AZs instead of Regions** — the answer when **data residency** pins you to a single Region.
> - **Backup & restore is the corruption answer**, not just the cheap one — it's the only copy the disaster didn't reach.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| Cross-Region database | `aws_rds_global_cluster` + regional `aws_rds_cluster` | Aurora Global Database; needs a provider alias per Region. |
| Multi-active NoSQL | `replica` blocks on `aws_dynamodb_table` | Global Tables. |
| Cross-Region object copy | `aws_s3_bucket_replication_configuration` | Plus a replication IAM role — see [[09-s3-advanced]]. |
| Cross-Region backup copy | `copy_action` in `aws_backup_plan` | `destination_vault_arn` in the DR Region. |
| DNS failover | `aws_route53_record` + `failover_routing_policy` + `aws_route53_health_check` | Data-plane failover. |
| Static-IP failover | `aws_globalaccelerator_accelerator` + endpoint groups | No DNS caching to wait out. |
| Repeatable infrastructure | your Terraform, or CloudFormation StackSets | The IaC that makes backup & restore viable. |

## Key facts, limits & pricing

- **Four DR strategies:** backup & restore, pilot light, warm standby, multi-site active/active. **Hot standby** is a variant of multi-site that is active/**passive** — full capacity deployed, but only one Region takes traffic.
- **Pilot light vs warm standby (AWS's own wording):** pilot light *"cannot process requests without additional action taken first"*; warm standby *"can handle traffic (at reduced capacity levels) immediately"*. Pilot light requires switching servers on and scaling up; warm standby requires only scaling up.
- **For a disaster confined to one data centre**, a well-architected highly available workload may only need **backup & restore**. Pilot light, warm standby and multi-site are for **Region-level** disasters or regulatory requirements.
- **Use data-plane operations during failover.** Data planes have higher availability design goals than control planes. Route 53 health checks and **Amazon Application Recovery Controller** (health checks used as manual on/off switches) are data plane; Route 53 weight changes, Global Accelerator traffic dials, and Auto Scaling are control plane.
- **Auto Scaling is a control-plane dependency.** Provisioning full capacity instead — **static stability** — removes it, at the cost of paying for idle capacity.
- **Automatic failover carries false-alarm risk.** AWS advises caution; a common pattern is fully scripted but **manually triggered** failover.
- **Continuous cross-Region replication is available from:** S3 Replication, RDS read replicas, **Aurora Global Databases**, **DynamoDB Global Tables**, DocumentDB global clusters, and **ElastiCache Global Datastore**.
- **Aurora Global Database:** typical cross-Region replication latency **under one second** (and well under 100 ms within a Region); a secondary can be promoted to read/write in **less than one minute**, even during a full regional outage; up to **10** secondary Regions; supports **write forwarding** from secondaries to the primary; can monitor RPO lag against a target.
- **RDS (non-Aurora) read replica promotion takes a few minutes and involves a reboot** — materially worse than Aurora Global Database for DR.
- **DynamoDB Global Tables** allow reads *and* writes in every Region, reconciling concurrent updates with **last writer wins**.
- **S3 Cross-Region Replication does not replicate delete markers by default**, protecting the DR Region from deletions in the source. **S3 Replication Time Control (RTC)** replicates **99.9% of objects within 15 minutes**, backed by an SLA — the only way to put a contractual number on your S3 RPO. **Versioning** protects against human error.
- **AWS Backup supports cross-Region and cross-account copy**; cross-account protects against insider threat or account compromise. It also has **restore testing**: a schedule that periodically restores from your recovery points and reports whether the restore actually worked, so "we have backups" and "we can recover" stop being the same claim.
- **AWS Backup's extra EC2 metadata** (instance type, VPC, security group, IAM role, monitoring config, tags) is **only used when restoring to the same Region**.
- **AWS Elastic Disaster Recovery (DRS)** continuously replicates whole servers at block level from on-premises, another cloud, or EC2 — and implements a **pilot light** strategy with switched-off resources in a staging VPC. AWS states recovery instances launch with an **RTO of minutes and an RPO of seconds**. It does not cover RDS.
- **Multi-site write strategies:** *write global* (all writes to one Region — Aurora Global Database), *write local* (write anywhere — DynamoDB Global Tables), *write partitioned* (writes routed by partition key — bidirectional S3 replication, which works across two **or more** buckets/Regions).
- **CloudFront origin failover** switches **per request** — subsequent requests still try the primary first, unlike a DNS or Global Accelerator failover which moves everything.
- **AWS Resilience Hub** continuously validates whether a workload is likely to meet its RTO and RPO targets.
- **Detection, notification, escalation, evaluation and declaration all consume the recovery window** — the RTO clock starts at the failure, not at the decision to fail over. For aggressive objectives AWS recommends automated failover driven by **deep health checks** (representative of user experience, based on KPIs, using multiple signals) rather than shallow heartbeats — while cautioning that false alarms cause a needless failover, which is itself an availability risk.
- **The AWS Health Dashboard** reports AWS-side events affecting your account, and is the first place to look when deciding whether an incident is yours or AWS's.
- **"The only error recovery that works is the path you test frequently"** (AWS's wording) — so keep the number of recovery paths **small**, and execute complex or critical recovery paths regularly, in production, to prove they work.
- **Manage configuration drift in the DR Region**: check AMIs and **service quotas** are current. **AWS Config** continuously records and detects drift and can trigger **AWS Systems Manager Automation** to fix it; **CloudFormation drift detection** covers deployed stacks.
- **The four strategies can be implemented across Availability Zones instead of Regions.** This is the standard answer when **data residency** rules confine a workload to a locality with only one AWS Region — the AZs become the discrete locations.
- **Backup & restore is AWS's stated mitigation for data loss *and* data corruption**, and can also cover the lack of redundancy in a single-AZ deployment — not only a cheap answer to a Region outage.
- **If the recovery strategy costs more than the loss it prevents, don't build it** — unless a secondary driver such as a regulatory requirement demands it.
- **A separate AWS account per Region is recommended for pilot light** (and multi-Region DR generally), for resource and security isolation — it keeps compromised credentials in one Region from being part of the disaster in the other.
- **Pilot light / warm standby / hot standby are all active/passive**; only multi-site is **active/active**. Hot standby = full capacity deployed, still only one Region serving.

## Comparisons

### The four strategies side by side

|   | **Backup & restore** | **Pilot light** | **Warm standby** | **Multi-site active/active** |
|---|---|---|---|---|
| Data in DR Region | backups | **continuously replicated** | continuously replicated | continuously replicated |
| Infrastructure | none — redeploy from IaC | core deployed | **full stack, scaled down** | full stack |
| Servers running | ❌ | ❌ **switched off** | ✅ **running, small** | ✅ running, full |
| Can serve a request now | no | **no** | **yes, at low capacity** | yes |
| Recovery work needed | redeploy + restore | **switch on + scale up** | **scale up only** | none — already live |
| RTO | hours | tens of minutes | minutes | near zero |
| Cost | lowest | low | medium | highest |

### HA vs DR

|   | **High availability** | **Disaster recovery** |
|---|---|---|
| Survives | an instance or an **Availability Zone** | a **Region**, or data corruption |
| Typical tools | Multi-AZ, ASG across AZs, ALB, EFS Regional | cross-Region replication, Route 53/GA failover, backups |
| Failover | automatic, seconds | strategy-dependent, seconds to hours |
| Always paying for it | yes, and it's cheap | yes, and it's the whole cost question |
| Measured by | `MTBF / (MTBF + MTTR)`, or successful ÷ valid requests | RTO and RPO |

### Picking a cross-Region database

|   | **Aurora Global Database** | **RDS cross-Region read replica** | **DynamoDB Global Tables** |
|---|---|---|---|
| Replication lag | **< 1 second** typical | seconds to minutes | seconds |
| Promotion / failover | **< 1 minute** | **minutes, plus a reboot** | none needed — already writable |
| Writes in the DR Region | after promotion (or write forwarding) | after promotion | **always** |
| Secondary Regions | up to **10** | multiple | many |
| Conflict handling | single writer | single writer | **last writer wins** |

## Worked examples

> [!example] Worked example — reading the numbers to pick the strategy
> *"A retail platform must survive the loss of its primary Region. Management will accept up to 15 minutes of downtime and at most 1 minute of lost orders. Cost matters."*
> Work the two numbers separately. **RPO of 1 minute** rules out anything backup-based — AWS Backup cross-Region copy runs on a schedule measured in hours. It demands **continuous replication**: **Aurora Global Database** for the orders database (sub-second, promote in under a minute) and **S3 Cross-Region Replication** for assets. **RTO of 15 minutes** rules out backup & restore, which means redeploying everything. But 15 minutes is loose enough that you don't need a full active/active build — you can afford to switch servers on and scale. That lands on **pilot light**, tightening toward warm standby if 15 minutes proves optimistic. Route the traffic with **Route 53 failover** using health checks — a data-plane operation — and keep the record TTL low, because failover is bounded by `(interval × threshold) + TTL` ([[10-route53]]).

> [!example] Worked example — why the DR plan failed its test
> A team has warm standby: a scaled-down stack in `eu-west-1`, an ASG at desired capacity 2, Aurora Global Database replicating. They run a game day, fail over, and the site collapses under real traffic. Two causes, both classic. First, they depended on **Auto Scaling** to reach production capacity — a **control-plane** operation, and the very thing likely to be degraded in a regional event. Second, their **service quotas** in the DR Region were never raised, so scaling stopped well below production levels. The fixes: pre-provision enough capacity to absorb initial traffic without scaling (**static stability**), raise quotas in the DR Region ahead of time, and treat Auto Scaling as an optimisation rather than a dependency.

> [!failure] Failure mode — replication that faithfully copied the disaster
> A company runs S3 Cross-Region Replication and Aurora Global Database and considers itself protected. A bad deployment writes corrupted records for six hours; replication dutifully copies every one into the DR Region within seconds. Both copies are now wrong, and there is nothing to fail over *to*. **Replication is not backup** — it defends against losing infrastructure, not against losing correctness. The missing pieces: **point-in-time recovery** on the database and **S3 versioning** so the pre-corruption objects still exist. It's also exactly why S3 **doesn't replicate delete markers by default** — a deletion in the source Region shouldn't be able to destroy the DR copy.

## Traps

> [!warning] Trap — pilot light vs warm standby
> The single most-tested pair here. **Pilot light cannot serve a request until you switch something on. Warm standby is already running and serving, just small.** Both replicate data; both have infrastructure in the DR Region. The only question is whether the compute is running. "Scale up" alone → warm standby. "Turn on, then scale up" → pilot light.

> [!warning] Trap — treating replication as backup
> Cross-Region replication copies corruption, bad deployments and malicious deletions perfectly. It protects against **losing** data, not against data becoming **wrong**. Any scenario mentioning corruption, ransomware, accidental deletion or a bad release needs **point-in-time recovery, versioning, or immutable backups** — not more replication.

> [!warning] Trap — RTO and RPO swapped
> **RPO is data loss. RTO is downtime.** A question giving "RPO of 5 minutes" is constraining your **replication**; "RTO of 5 minutes" is constraining how much **capacity is already running**. Answer the wrong one and you'll pick a strategy that's either far too expensive or far too slow.

> [!warning] Trap — automatic failover assumed to be the better answer
> AWS explicitly advises caution with automatically initiated failover, because a false alarm makes you incur real downtime and real data loss for nothing. A fully scripted, **manually triggered** failover is a legitimate and often preferred design. Don't reflexively pick "automatic".

> [!warning] Trap — an RDS read replica used where Aurora Global Database belongs
> Both give cross-Region replication. But an RDS read replica promotion takes **a few minutes and includes a reboot**, while Aurora Global Database replicates in **under a second** and promotes in **under a minute**. When a question pairs cross-Region with an aggressive RTO or RPO, the read replica is the distractor.

> [!warning] Trap — a DR design that depends on the control plane
> Auto Scaling, Route 53 weight changes and Global Accelerator traffic dials are **control-plane** operations, and control planes are less available than data planes exactly when you need them. Route 53 **health checks** and **Application Recovery Controller** are data plane. A "most resilient failover" question is usually asking you to spot this.

> [!warning] Trap — the RTO clock starts before anyone notices
> Candidates budget the RTO for the failover itself and forget everything in front of it. **Detection, notification, escalation, evaluation and declaring the disaster are all inside the RTO.** A one-hour RTO with a 25-minute alarm has already spent nearly half its budget before a human is involved. Scenarios with aggressive RTOs are usually asking for **deep health checks** based on real KPIs — and a shallow heartbeat that returns 200 while the database is unreachable is the distractor.

> [!warning] Trap — a recovery path that has never been run
> "We have a DR Region" is not the same as "we can recover." Untested paths fail on the details: stale AMIs, **service quotas in the DR Region that were never raised**, a read-only secondary nobody has ever written to. AWS's position is that only the path you test *frequently* works, so keep recovery paths **few** and run them. Where a question hints at drift or an untested failover, the answer involves **AWS Config** (detect), **SSM Automation** (remediate) or **CloudFormation drift detection** — not a bigger DR Region.

> [!warning] Trap — assuming DR always means a second Region
> The four strategies are about **discrete locations**, not Regions specifically. When data-residency or sovereignty rules confine a workload to a country with a single AWS Region, the correct answer implements the same strategy across that Region's **Availability Zones**. You give up protection against a Region-wide event and keep compliance — and "we can't leave the country, so DR is impossible" is the wrong conclusion.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Written before the video** — first drafted 2026-09-06 with no orientation pass. D2 Resilient is my weakest domain (62%) and barely moved during the recap; this note is aimed directly at it. Reconciled against the AWS DR whitepaper on 2026-09-25 while I was part-way through the course section — the *strategy* content held up, the *operational* content (detection, testing) was missing entirely.
- [ ] **Detection and testing** — new as of 2026-09-25 and untested on me. The RTO clock starting at the failure rather than at the failover decision is the idea I'm most likely to lose marks on.
- [ ] **Pilot light vs warm standby** — the test is whether compute is *running*, not whether infrastructure exists.
- [ ] **Data plane vs control plane** — a genuinely new idea, and the thing that separates a good failover design from a plausible one.
- [ ] **Replication ≠ backup** — the failure mode that beats teams who think they have DR.
- [ ] **Aurora Global Database vs RDS cross-Region read replica** — sub-second/under-a-minute vs minutes-plus-a-reboot. Aurora also regressed to **44%** in the 2026-09-01 mock.

## 🔗 Docs

- [Disaster recovery options in the cloud](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html) — the four strategies, the explicit pilot-light-vs-warm-standby distinction, data plane vs control plane, static stability, Aurora Global Database timings, continuous replication services, delete-marker behaviour, Elastic Disaster Recovery, and multi-site write strategies; verified 2026-09-06
- [Disaster recovery objectives (RTO/RPO)](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-objectives.html) — definitions and their business-driven nature; verified 2026-09-06
- [Detection](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/detection.html) — detection/notification/escalation inside the recovery window, deep health checks, AWS Health Dashboard; verified 2026-09-25
- [Testing disaster recovery](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/testing-disaster-recovery.html) — "the only error recovery that works is the path you test frequently", few recovery paths, DR-Region drift via AWS Config + SSM Automation + CloudFormation drift detection; verified 2026-09-25
- [Aurora Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html) — **up to 10 secondary Regions**, replication latency typically under a second; verified 2026-09-25 (the DR whitepaper still says five — it is stale)
- [S3 Replication Time Control](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-time-control.html) — 99.9% of objects within 15 minutes, SLA-backed; verified 2026-09-25
- [DynamoDB Global Tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html) · [S3 Replication](https://aws.amazon.com/s3/features/replication/) · [AWS Elastic Disaster Recovery](https://docs.aws.amazon.com/drs/latest/userguide/what-is-drs.html)
- [Terraform `aws_rds_global_cluster`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster) / [`aws_route53_health_check`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_health_check)
