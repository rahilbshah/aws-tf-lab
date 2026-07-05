---
topic: 04-alb-asg
domain: resilient
status: reviewed
services: [ALB, ASG, ELB, EC2]
related: [02-ec2, 03-ami-bake, 01-iam]
cards: cards/04-alb-asg-cards
tags: [topic, domain/resilient]
---

# 04 – ALB + Auto Scaling Group

The two halves of horizontal scaling on EC2: an **Application Load Balancer** spreads incoming traffic across many instances (Layer 7), and an **Auto Scaling Group** keeps the right number of instances running and replaces the dead ones. Together they turn a single fragile server into a self-healing, elastic fleet.

> [!info] Exam TL;DR
> - **ALB = Layer 7** (reads the HTTP request → routes on host / path / header / method / query-string / source-IP). **NLB = Layer 4** (TCP/UDP, flow-hash, ultra-low latency, millions of connections, static IP / EIP per AZ). **GWLB = Layer 3** (GENEVE, for inline appliances).
> - ALB routes to a **target group**, not to instances directly. An **ASG registers its instances into the target group automatically** via `target_group_arns` — never attach by hand.
> - **`health_check_type` decides self-healing.** Default `EC2` only checks the VM is alive; a failed *ALB* health check won't replace it → zombie serving 500s. Set **`ELB`** so the load balancer's verdict triggers ASG replacement.
> - **ASG = min / desired / max.** `max` caps scale-out, `min` floors scale-in. Unhealthy instance → terminate + launch replacement to restore `desired`.
> - **Scaling policies:** *dynamic* (target-tracking → recommended, step, simple), *predictive* (ML on history), *scheduled* (known times). **Target tracking auto-creates & manages the CloudWatch alarms** — don't hand-edit them.
> - **ALB needs ≥ 2 AZs.** Cross-zone load balancing is **always on** for ALB (free); **off by default** for NLB (and enabling it adds inter-AZ data charges).
> - Production tiering: **ALB in public subnets, instances in private subnets** (only the ALB SG can reach them) + NAT/VPC-endpoints for outbound.

## Concept (plain English)

A single EC2 instance is a single point of failure and a fixed amount of capacity. The ALB is a managed reverse proxy: clients hit its DNS name, and it forwards each request to a healthy instance, checking health continuously so it never sends traffic to a broken one. The ASG is the capacity manager: you tell it a floor, a ceiling, and a target count, and it launches/terminates instances (from a **launch template**) to hold that count, replacing any that fail. The glue is the **target group** — the ASG registers instances into it, and the ALB routes to it. `health_check_type = "ELB"` is what lets the ALB's health opinion drive the ASG's replacement decisions, so a hung app (not just a dead VM) gets recycled.

## AWS console ↔ Terraform map

| Console / what you want | Terraform | Notes |
|---|---|---|
| Instance blueprint for the fleet | `aws_launch_template` | AMI, type, SGs, key, `user_data`, IAM profile. **Replaces the deprecated launch *configuration*.** |
| The fleet manager | `aws_autoscaling_group` | `min/max/desired`, `vpc_zone_identifier` (2+ AZs), `launch_template { version = "$Latest" }`, `target_group_arns`, `health_check_type`, `health_check_grace_period`. |
| The load balancer | `aws_lb` | `load_balancer_type = "application"`, `subnets` (2+ AZ), `security_groups`, `internal`. |
| Where the ALB sends traffic | `aws_lb_target_group` | `port`/`protocol`/`vpc_id` + `health_check {}`. |
| The front door + routing | `aws_lb_listener` (+ `aws_lb_listener_rule`) | Listener = protocol/port + `default_action`; rules add host/path/etc. routing. |
| Scale automatically | `aws_autoscaling_policy` | `policy_type = "TargetTrackingScaling"` + `target_tracking_configuration {}`. Auto-manages its CloudWatch alarms. |
| Tie instances to the LB | `target_group_arns` on the ASG | **NOT** `aws_autoscaling_attachment` — that's for pre-existing instances. |
| "Only the LB can reach my app" | instance SG ingress with `referenced_security_group_id = <alb SG>` | Source is the ALB's SG, not a CIDR. The core security pattern. |

## Architecture diagram

```mermaid
flowchart TD
    Client([Client]) -->|HTTP :80| ALB[ALB<br/>public subnets, 2+ AZ<br/>alb-sg: :80 from 0.0.0.0/0]
    ALB --> LST[Listener :80<br/>default_action: forward]
    LST --> TG[Target Group<br/>HTTP :80, health_check /]

    subgraph ASGX["Auto Scaling Group — desired 2 (min 1 / max 3)"]
      direction LR
      I1[instance us-east-1a<br/>instance-sg: :80 from alb-sg]
      I2[instance us-east-1b<br/>instance-sg: :80 from alb-sg]
    end

    LT[Launch Template<br/>golden AMI + user_data nginx] -.stamps out.-> ASGX
    ASGX -->|auto-register via<br/>target_group_arns| TG
    TG -->|routes only to healthy| I1
    TG -->|routes only to healthy| I2

    POL[TargetTracking policy<br/>ASGAverageCPUUtilization = 50] -.creates.-> AH[Alarm High → scale out]
    POL -.creates.-> AL[Alarm Low → scale in]
    AH -.->|desired++| ASGX
    AL -.->|desired--| ASGX
```

## Key facts, limits & pricing

- **ALB requires at least 2 AZs** (enforced). NLB recommended 2+, not strictly required.
- **Cross-zone load balancing:** ALB — always on at the LB level, can't disable there (only override off per target group); **free**. NLB/GWLB — **off by default**; enabling it means each node spreads to all AZs but **inter-AZ data transfer is billed**. (Exam-frequent.)
- **Default routing algorithm** (ALB target group) = **round robin**; also *least outstanding requests* and *weighted random*.
- **Deregistration delay (connection draining)** default = **300 seconds**. Draining target finishes in-flight requests, state `draining` → `unused`, then the ASG may terminate it. Range 0–3600s.
- **Health checks are two independent systems:** the *ALB/target-group* health check (does the app answer on the path with the matcher code?) decides **routing**; the *ASG* `health_check_type` decides **replacement**. `EC2` = hypervisor status checks only; `ELB` = honor the target-group health. They only cooperate if you set `ELB`.
- **`health_check_grace_period`** — seconds after launch before the ASG counts health against an instance. Must exceed boot + bootstrap + health-check convergence, or you get a **boot loop**. With boot-time `apt install`, ~300s is safe; with a baked AMI you can drop it low.
- **Target tracking:** EC2 Auto Scaling **creates and manages** the CloudWatch alarms (one high, one low) — do not edit/delete them. It **scales out aggressively and scales in gradually** (prioritizes availability). It **cannot scale out when the metric is below target** — scale-out needs real load above the target value. Predefined metrics: `ASGAverageCPUUtilization`, `ASGAverageNetworkIn`, `ASGAverageNetworkOut`, `ALBRequestCountPerTarget`.
- **Pricing gotcha:** an ALB bills **hourly (~$0.0225/hr in us-east-1) + LCUs** (new connections, active connections, processed bytes, rule evaluations) — it bills even with zero traffic and zero healthy targets. Free-tier: 750 ALB-hrs + 15 LCUs/month for 12 months. ⚠️ check current pricing.
- **Manual (out-of-band) termination is not instant to the ASG** — it detects via its periodic health-check cycle (~1–2 min to notice), then launches a replacement. The console pages are **static snapshots** — refresh to see truth; the **Activity tab** is the authoritative event log.

## Comparisons

### ALB vs NLB vs GWLB

|   | ALB | NLB | GWLB |
|---|---|---|---|
| OSI layer | 7 (HTTP/HTTPS) | 4 (TCP/UDP/TLS) | 3 (IP, GENEVE :6081) |
| Routes on | host, path, header, method, query-string, source-IP | flow hash (proto, src/dst IP+port, seq) | 5-tuple flow hash |
| Latency | higher (parses HTTP) | ultra-low | n/a (appliance insertion) |
| Static IP | ❌ DNS name only | ✅ one per AZ, can attach EIP | via endpoints |
| Preserves client source IP | ❌ (adds `X-Forwarded-For`) | ✅ natively | ✅ |
| Cross-zone default | always on (free) | off (inter-AZ charged) | off |
| Use it for | web apps, path/host routing, WebSockets, HTTP-aware | TCP/UDP, extreme perf, static IP, non-HTTP | inline firewalls/IDS/IPS appliances |

### Scaling policy types

|   | Reacts to | When |
|---|---|---|
| Target tracking (dynamic) | keep a metric AT a target (e.g. CPU 50%) | **default choice** — simplest, auto-manages alarms |
| Step scaling (dynamic) | different adjustments per alarm-breach size | need graduated response |
| Simple scaling (dynamic) | one adjustment + cooldown | legacy, avoid |
| Predictive | ML forecast on historical load | known cyclical patterns; pairs with dynamic |
| Scheduled | wall-clock time | predictable spikes (9am rush, batch window) |

## Worked examples

> [!example] Worked example — the ALB↔ASG health-check split that saves (or sinks) you
> A `t3.micro` fleet behind an ALB runs a Java app that occasionally deadlocks: the JVM process is alive (so EC2 status checks pass) but every HTTP request hangs and the ALB health check on `/health` returns 504. With `health_check_type = "EC2"` (the default), the ASG sees "VM healthy" and does nothing — the ALB stops routing to the bad instance (good) but never gets it replaced, so you silently run at N-1 capacity until someone notices. Flip the ASG to `health_check_type = "ELB"` and the ALB's 504 verdict now propagates: after `health_check_grace_period`, the ASG marks it unhealthy, drains it (`deregistration_delay`, default 300s), terminates it, and launches a fresh one from the launch template. This is exactly the behaviour verified live in this topic by terminating an instance and watching the Activity log show `Terminating…` + `Launching…`.

> [!failure] Failure mode — the grace-period boot loop
> Set `health_check_grace_period` too low relative to how long an instance takes to become **ELB-healthy** and you get a self-inflicted outage that looks like a scaling bug. With boot-time `apt install nginx` (~60s) + boot (~30s) + health-check convergence (`healthy_threshold` × `interval`, e.g. 3 × 30s = 90s), an instance isn't healthy until ~180s. A grace period of 120s means the ASG starts honouring the ELB verdict at 120s, sees "unhealthy," **terminates and replaces** — and the replacement hits the same wall. Result: instances cycle every few minutes, the target group never reaches steady healthy state, and you burn money launching doomed instances. Fixes: raise the grace period above the true time-to-healthy (~300s here), **or bake nginx into the AMI** (see [[03-ami-bake]]) so instances are healthy in ~40s and the whole problem evaporates — the clearest argument for golden images there is.

> [!example] Worked example — target tracking, and why it only heals one direction cheaply
> The target-tracking policy (`ASGAverageCPUUtilization = 50`) auto-created two CloudWatch alarms with zero hand-wiring: `TargetTracking-…-AlarmHigh` at 50% (scale out) and `-AlarmLow` at 35% (scale in — the lower band AWS picks). Observed behaviour: an idle fleet sits well below 35%, so after a sustained period the low alarm scales it in toward `min_size` — cheap to watch, no load needed. But you **cannot** provoke a scale-*out* by lowering the target: target tracking never scales out when the metric is below target, and a static nginx page produces near-zero CPU, so the only way to see scale-out is to generate real load (`stress` on the instances). This asymmetry is by design — EC2 Auto Scaling **prioritizes availability**: it scales out fast and scales in conservatively so a brief dip doesn't strand you under-provisioned when traffic returns.

## The Terraform I wrote

Code: [`04-alb-asg/main.tf`](../04-alb-asg/main.tf) + `variables.tf` / `outputs.tf` / `user_data.sh`

13 resources: 2 SGs + 4 rules, `aws_launch_template` (golden AMI from [[03-ami-bake]] via `data.aws_ami` on `tag:BakedBy=packer`, `owners=["self"]`, `user_data = base64encode(file(...))`), `aws_lb` + `aws_lb_target_group` + `aws_lb_listener`, `aws_autoscaling_group` (`min 1 / max 3 / desired 2`, `health_check_type = "ELB"`, `grace 120→300`), and `aws_autoscaling_policy` (target tracking, CPU 50).

Non-obvious bits:
- The **instance SG sources from the ALB SG** via `referenced_security_group_id` — the "only the LB reaches my app" pattern (different argument from the `cidr_ipv4` used in [[02-ec2]]).
- **Scoped the ALB to `us-east-1a`+`us-east-1b`** on purpose: the default VPC includes a `us-east-1e` subnet, and that AZ historically doesn't support ALBs → apply error if you hand it *all* subnets.
- ASG auto-registers into the target group via `target_group_arns`; no `aws_autoscaling_attachment`.
- The golden AMI is a **data source**, so `terraform destroy` leaves it intact.

> [!warning] Trap — "the ALB terminates the unhealthy instance"
> It doesn't. The ALB only stops *routing* to it. Termination is the **ASG's** job, and only if `health_check_type = "ELB"`. Two separate systems; the default (`EC2`) leaves them disconnected.

> [!warning] Trap — "a failed ALB health check means users get errors"
> Only if **no** targets are healthy. With ≥1 healthy target the ALB quietly routes around the bad one and users are fine — you're at reduced capacity with nobody alerted. Silence is the danger.

> [!warning] Trap — NLB vs ALB for a static IP / source-IP
> "Need a static IP for the LB" or "must preserve client source IP with no app changes" → **NLB** (static IP/EIP per AZ, native source-IP preservation). ALB is DNS-only and needs `X-Forwarded-For`. Frequent distractor pairing.

> [!warning] Trap — cross-zone billing
> Cross-zone is free & always-on for ALB, but **off by default and inter-AZ-billed for NLB**. "Cheapest option that spreads evenly across AZs" nuances hinge on this.

> [!example]- Recreate-from-memory drill
> From scratch (default VPC ok), build: golden-AMI launch template → ALB (2 AZ) + target group + listener → ASG (min 1/max 3/desired 2, `health_check_type = "ELB"`) auto-registered to the target group → target-tracking CPU-50 policy → the two SGs (ALB open on 80, instance SG from ALB SG only). Goal: browse the ALB DNS, see the served instance-id flip; terminate one instance and watch the ASG replace it in the Activity tab. `destroy` after.
> > [!success]- Reference solution
> > See `04-alb-asg/main.tf` — 13 resources in dependency order (data → SGs → launch template → ALB → TG → listener → ASG → policy). The one line people forget is `health_check_type = "ELB"` on the ASG.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Conflated "ALB health check fails" with "instance gets terminated."** A failed ALB health check only stops routing; termination needs the ASG with `health_check_type = "ELB"`. Two systems, one linking knob.
- [ ] **Console staleness vs ASG detection lag** — saw an instance as "Healthy" in the ASG tab right after terminating it and thought something was broken. It was a stale page snapshot + the ASG's periodic detection cycle (1–2 min), not a bug. Use the Activity tab + refresh.
- [ ] **Target tracking can't scale OUT from idle** — lowering `target_value` triggers scale-*in*, not out; scale-out genuinely needs load above target. (Corrected mid-session.)
- [ ] **Cross-zone defaults differ by LB type** — ALB always-on/free vs NLB off-by-default/inter-AZ-charged. Easy to blur.

## 🔗 Docs

- [How ELB works — cross-zone, routing, schemes](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html) — ALB cross-zone always-on, NLB/GWLB off by default; round-robin default; verified 2026-06
- [Target group attributes — deregistration delay](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/edit-target-group-attributes.html) — default 300s draining; verified 2026-06
- [Target tracking scaling policies](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html) — auto-managed alarms, scale-out-fast/scale-in-gradual, can't scale out below target; verified 2026-06
- [Terraform `aws_autoscaling_group`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)
- [Terraform `aws_lb` / `aws_lb_target_group` / `aws_lb_listener`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)
- [Terraform `aws_launch_template`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template)
- [Terraform `aws_autoscaling_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy)

---
**Cards for this topic:** [[cards/04-alb-asg-cards]]
