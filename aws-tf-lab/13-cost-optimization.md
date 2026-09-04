---
topic: 13-cost-optimization
domain: cost
status: reviewed
services: [EC2, SavingsPlans, CostExplorer, Budgets, ComputeOptimizer, TrustedAdvisor]
related: [02-ec2, 09-s3-intro, 05-vpc-endpoints-peering, 01-iam-advanced, 07-rds-aurora]
cards: cards/13-cost-optimization-cards
tags: [topic, domain/cost]
---

# 13 – Cost optimization

The fourth exam domain, worth **20%**. Not a service — a way of reading questions. Every "MOST cost-effective" question is asking you to compare options on price, which is a different retrieval path from "what does this service do."

## What problem does this solve?

On-Demand pricing is the rate you pay for saying nothing in advance. You start an instance, you're charged by the second, you stop it, the charge stops. Nothing is committed and nothing is promised.

That flexibility has a price, and it's the highest one AWS offers.

Almost all of cost optimization is trading some of that flexibility back for a discount. You can promise to **spend a certain amount** for a year. You can promise to **use a specific instance family**. You can accept that AWS may **take the server away** with two minutes' notice. Each of those promises buys a bigger discount than the last.

The second half of the topic is quieter and catches more people: **the bill isn't mostly compute.** A NAT Gateway charges by the hour and by the gigabyte. Data leaving AWS costs money. An unattached Elastic IP costs money for doing nothing. Storage classes differ by an order of magnitude. Plenty of real savings have nothing to do with instance pricing at all.

> In one line: you pay the most for committing to nothing, and the exam's cost questions are asking which commitment the scenario can afford to make.

## How it actually works

### The ways to pay for a server

AWS gives you seven, and they answer different questions.

| Option | You commit to | You get |
|---|---|---|
| **On-Demand** | nothing | pay by the second, highest rate |
| **Savings Plans** | **an amount of spend** ($/hour), 1 or 3 years | big discount, wide flexibility |
| **Reserved Instances** | **a specific instance configuration**, 1 or 3 years | big discount, narrow flexibility |
| **Spot** | nothing, but accept interruption | the steepest discount |
| **Dedicated Hosts** | a whole physical server | licence compliance (BYOL per-socket/per-core) |
| **Dedicated Instances** | single-tenant hardware, billed hourly | isolation without host-level control |
| **Capacity Reservations** | capacity in a **specific AZ** | guaranteed capacity, no discount by itself |

AWS's own guidance is almost a decision tree, and it is worth reading twice:

> *If you can't commit to a specific instance configuration but you can commit to a usage amount → **Savings Plans**. If you require a **capacity reservation** → **Reserved Instances or Capacity Reservations** for a specific Availability Zone. If you can be flexible about when your application runs and it can be interrupted → **Spot**. If you have compliance requirements or existing server-bound licences → **Dedicated Hosts or Dedicated Instances**.*

The one people miss: **a Savings Plan does not reserve capacity.** It is purely a billing discount. If you need to be certain an instance will be available in a particular AZ — for a DR standby, say — you need a **Capacity Reservation** or a **zonal Reserved Instance**, and that's a separate thing from the discount.

> In one line: On-Demand commits to nothing, Savings Plans commit to spend, Reserved Instances commit to a configuration, Spot commits to nothing but accepts eviction — and only Capacity Reservations and zonal RIs actually hold capacity for you.

### Savings Plans vs Reserved Instances — and why *more* flexible costs *more*

Both give you a discount for a 1- or 3-year commitment. The difference is *what* you're committing to.

A **Reserved Instance** commits you to a configuration: instance type, Region, tenancy, and operating system. It is **not a physical instance** — it's a billing discount that gets applied automatically to any running On-Demand instance matching those attributes.

A **Savings Plan** commits you to **money**: "I will spend at least $10/hour on compute for three years." What you spend it on is up to you.

AWS now explicitly **recommends Savings Plans over Reserved Instances**, which tells you where this is heading.

The four Savings Plans, and the trade-off that catches people:

| Plan | Max discount | Locked to | Free to change |
|---|---|---|---|
| **Compute Savings Plans** | **up to 66%** | nothing | family, size, **Region**, OS, tenancy — plus **Fargate and Lambda** |
| **EC2 Instance Savings Plans** | **up to 72%** | **one instance family in one Region** | size, OS, tenancy within that family |
| **Database Savings Plans** | up to 35% | nothing | Aurora, RDS, DynamoDB, ElastiCache, DocumentDB and more |
| **SageMaker AI Savings Plans** | up to 64% | nothing | family, size, Region, component |

Look at the first two again. The **less** flexible plan gives the **bigger** discount — 72% for committing to `m5` in Virginia, versus 66% for committing to nothing in particular. That's backwards from most people's instinct, and it's exactly the kind of thing an exam question is built on.

For Reserved Instances the same logic runs through the **offering class**:

- **Standard RI** — the biggest RI discount. Can be **modified**, but **cannot be exchanged**.
- **Convertible RI** — a smaller discount, but **can be exchanged** for a different Convertible RI with different attributes.

Again: less flexibility, more discount.

Payment options apply to both and work the way you'd expect — **All Upfront** saves most, then **Partial Upfront**, then **No Upfront**. And note that RIs **do not auto-renew**: when one expires the instance keeps running and quietly reverts to On-Demand rates.

> In one line: Reserved Instances commit to a configuration, Savings Plans commit to a spend — and in both, giving up flexibility buys a bigger discount, which is the opposite of what most people guess.

### Spot, and the two minutes that make it usable

Spot Instances run on EC2's **unused capacity** at a steep discount. The catch is in the name of the thing that ends them: an **interruption**.

AWS reclaims a Spot Instance for one of three reasons — most often because it **needs the capacity back**, sometimes because the Spot price rose above a maximum you set, sometimes because a constraint you attached can no longer be met. (Setting a maximum price is optional, and doing so makes interruptions *more* frequent, not less.)

What makes Spot usable in practice is the warning. You get a **two-minute interruption notice** before the instance is stopped or terminated, delivered two ways:

- as an **EventBridge event** (`EC2 Spot Instance Interruption Warning`), and
- as an item in **instance metadata** at `/latest/meta-data/spot/instance-action`, which tells you the action and the time.

AWS recommends polling that metadata item **every 5 seconds**, and notes the notices are best-effort.

One detail worth carrying: if you set the interruption behaviour to **hibernate**, you still get a notice but **not two minutes of warning** — hibernation begins immediately.

This shapes what Spot is *for*. Anything that can checkpoint, retry, or simply be re-run: batch jobs, CI runners, data processing, stateless web tiers behind an ASG. Anything that can't tolerate losing a machine in two minutes — a database, a stateful session store — is the wrong fit no matter how attractive the price.

> In one line: Spot is spare capacity at a steep discount, and the two-minute notice via EventBridge or instance metadata is what makes fault-tolerant workloads able to use it.

### The bill that isn't compute

Plenty of exam cost questions never mention an instance. These are the levers, and most of them you have already met:

**NAT Gateway** bills **per hour and per gigabyte processed**. A **gateway endpoint** for S3 or DynamoDB is **free** and keeps that traffic off the NAT entirely — one of the highest-value swaps in AWS, and it's in [[05-vpc-endpoints-peering]].

**Data transfer**: inbound is generally free, **outbound to the internet costs money**, and **cross-AZ traffic is charged**. That's why an NLB with cross-zone load balancing enabled costs more than an ALB, where it's free — see [[04-alb-asg]].

**Elastic IPs** are charged **when not attached to a running instance** — the classic forgotten-resource bill.

**S3 storage classes** differ enormously, and **lifecycle rules** move data down the tiers automatically ([[09-s3-intro]]). Watch the minimum billable object size on the IA classes — many tiny files in IA can cost more than Standard.

**EBS**: `gp3` decouples IOPS from capacity, so you stop over-provisioning size just to buy performance ([[02-ec2]]). And **snapshots keep charging after the volume is deleted** — the silent leak in [[03-ami-bake]].

**Aurora Serverless v2** scales capacity to the workload, which beats a provisioned instance sized for a peak that happens twice a day ([[07-rds-aurora]]).

**Consolidated billing** through AWS Organizations ([[01-iam-advanced]]) combines usage across all accounts, so **volume discounts, Reserved Instance discounts and Savings Plans are shared** across the organization. It costs nothing extra.

> In one line: a large share of real savings is architectural, not contractual — endpoints instead of NAT, lifecycle instead of Standard, gp3 instead of oversized gp2, and one bill instead of ten.

### The tools that tell you where the money went

Five, and the exam mostly wants you to pick the right one for a described job.

- **AWS Cost Explorer** — the analysis console. Visualise cost and usage, filter and group, **forecast** future spend, and get **Savings Plans purchase recommendations**. This is where you go to *understand* the bill.
- **AWS Budgets** — set a budget on **cost or usage** and get **alerted** when you cross a threshold. This is where you go to *be told* before it's too late.
- **Cost Anomaly Detection** — automated alerts when AWS detects unusual spend, without you defining a threshold.
- **Cost allocation tags** and **cost categories** — how you slice the bill by team, application or environment. Tags are the mechanism; without them the bill is one undifferentiated number.
- **AWS Compute Optimizer** — analyses **CloudWatch metrics over the last 14 days** and recommends **rightsizing**, plus flags **idle resources**. Covers EC2, Auto Scaling groups, EBS volumes, Lambda, ECS on Fargate, RDS/Aurora, NAT Gateway, DynamoDB, ElastiCache and more. You must **opt in**.

The discriminator that matters: **Cost Explorer explains the past, Budgets warn about the future, Compute Optimizer tells you the resource is the wrong size.**

> In one line: Cost Explorer analyses, Budgets alert, Anomaly Detection watches, tags slice, and Compute Optimizer says the instance is too big.

## Exam recap

> [!info] Exam TL;DR
> - **Seven ways to pay:** On-Demand · Savings Plans · Reserved Instances · Spot · Dedicated Hosts · Dedicated Instances · Capacity Reservations.
> - **Savings Plans commit to a $/hour spend. Reserved Instances commit to a configuration.** AWS now recommends Savings Plans over RIs.
> - **Compute Savings Plans: up to 66%**, flexible across family, size, **Region**, OS, tenancy — **and covers Fargate and Lambda**. **EC2 Instance Savings Plans: up to 72%**, but locked to **one family in one Region**. Less flexible = bigger discount.
> - **Standard RI** = bigger discount, **can be modified but not exchanged**. **Convertible RI** = smaller discount, **can be exchanged**.
> - **A Savings Plan does not reserve capacity.** For guaranteed capacity in an AZ you need a **Capacity Reservation** or a **zonal Reserved Instance**.
> - **Spot** = spare capacity, steepest discount, **two-minute interruption notice** via **EventBridge** and **instance metadata** (`spot/instance-action`). Hibernate gets a notice but **no two minutes**. For fault-tolerant, interruptible work only.
> - **Dedicated Hosts** for **BYOL per-socket/per-core licensing**; Dedicated Instances for single-tenant hardware without host visibility.
> - **Cost Explorer** analyses and forecasts · **Budgets** alerts on a threshold · **Cost Anomaly Detection** watches for the unexpected · **Compute Optimizer** rightsizes from 14 days of CloudWatch metrics · **cost allocation tags** slice the bill.
> - **Non-compute levers:** gateway endpoints are free vs NAT per-hour+per-GB · outbound and cross-AZ data transfer is charged · unattached EIPs cost money · S3 lifecycle · `gp3` · orphaned EBS snapshots · consolidated billing shares volume/RI/SP discounts.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| Spot in an ASG | `instance_market_options { market_type = "spot" }` on `aws_launch_template` | Or a mixed-instances policy for a Spot/On-Demand blend. |
| Capacity Reservation | `aws_ec2_capacity_reservation` | `availability_zone`, `instance_count`. Holds capacity; separate from any discount. |
| Dedicated Host | `aws_ec2_host` | Then `host_id` / `tenancy` on the instance. |
| Budget + alert | `aws_budgets_budget` | `budget_type` COST or USAGE, `notification` blocks for thresholds. |
| Cost allocation | `default_tags` in the provider | Tags are the mechanism; activate them as cost allocation tags in the console. |
| Cost anomaly alerts | `aws_ce_anomaly_monitor` + `aws_ce_anomaly_subscription` | |
| Savings Plans / RIs | *(not Terraform)* | Financial commitments, bought in the console/API — not infrastructure. |

## Key facts, limits & pricing

- **Seven purchasing options:** On-Demand, Savings Plans, Reserved Instances, Spot, Dedicated Hosts, Dedicated Instances, Capacity Reservations. (Capacity Blocks additionally reserve clusters of GPU instances.)
- **Savings Plans commit to a spend rate in USD/hour** for **1 or 3 years**. Payment: **All Upfront**, **Partial Upfront**, or **No Upfront**. **Terms cannot be changed after purchase** — as usage grows you buy an additional plan.
- **Compute Savings Plans — up to 66% off.** Apply regardless of instance family, size, **Region**, operating system or tenancy, **and cover AWS Fargate and AWS Lambda**.
- **EC2 Instance Savings Plans — up to 72% off.** Commit to a **specific instance family in a chosen Region**; within that, size, OS and tenancy are free to change.
- **Database Savings Plans — up to 35%** across Aurora, RDS, DynamoDB, ElastiCache, DocumentDB, Timestream, Neptune, Keyspaces, DMS and OpenSearch, including serverless usage. **SageMaker AI Savings Plans — up to 64%.**
- Both Compute and EC2 Instance plans **apply to the EC2 instances inside EMR, EKS and ECS clusters** — though EKS's own control-plane charge is not covered. **Dedicated Instances' $2/hour per-Region fee is not discounted** by Savings Plans.
- **Reserved Instances are a billing discount, not a physical instance.** Priced on four attributes: **instance type, Region, tenancy, platform (OS)**. Terms of **1 or 3 years**; the 3-year term discounts more.
- **Standard RIs** give the largest RI discount and can be **modified but never exchanged**. **Convertible RIs** discount less but **can be exchanged** for another Convertible RI with different attributes. **Purchases cannot be cancelled**, though Standard RIs can be **sold on the Reserved Instance Marketplace**.
- **RIs do not auto-renew.** On expiry the instance keeps running and silently reverts to On-Demand rates.
- **Only zonal Reserved Instances and Capacity Reservations reserve capacity.** Savings Plans and regional RIs are discounts only.
- **Spot interruption notice = 2 minutes**, emitted as an **EventBridge event** (`EC2 Spot Instance Interruption Warning`) and as instance metadata at **`/latest/meta-data/spot/instance-action`** (which gives the action and time; HTTP 404 when not marked). AWS recommends polling **every 5 seconds**; notices are **best-effort**.
- **Interruption behaviours:** terminate, stop, or **hibernate** — and hibernate gets a notice **without** the two-minute lead time, because hibernation starts immediately.
- **Spot interruption causes:** EC2 needing the capacity back (most common), the Spot price exceeding a maximum price you set, or a constraint (launch group / AZ group) no longer being satisfiable. **Setting a maximum price increases interruption frequency.**
- **Dedicated Hosts** expose the physical server (sockets, cores, host affinity) and support **per-socket / per-core / per-VM BYOL**. **Dedicated Instances** are single-tenant hardware billed hourly, without host-level visibility.
- **AWS Compute Optimizer** analyses **CloudWatch metrics from the last 14 days** (extendable to **93 days** with the paid enhanced infrastructure metrics) and recommends rightsizing plus flags idle resources. Covers EC2, Auto Scaling groups, EBS volumes, Lambda, ECS on Fargate, Aurora/RDS, NAT Gateway, DynamoDB, ElastiCache, MemoryDB, DocumentDB, WorkSpaces and SageMaker. **You must opt in.**
- **Cost Explorer** analyses and forecasts cost/usage and produces **Savings Plans recommendations**. **AWS Budgets** alerts on **cost or usage** thresholds. **Cost Anomaly Detection** alerts without a threshold. **Cost allocation tags** and **cost categories** slice the bill by team/app/environment.
- **Consolidated billing** (AWS Organizations) is **free** and **combines usage across accounts**, so volume discounts, RI discounts and Savings Plans are shared organization-wide.
- ⚠️ Discount percentages are AWS's stated maxima and change over time; the exam tests the **ordering and the trade-off**, not the exact figure. Check current pricing before relying on a number.

## Comparisons

### Savings Plans vs Reserved Instances

|   | **Savings Plans** | **Reserved Instances** |
|---|---|---|
| Commit to | **$/hour of spend** | **an instance configuration** |
| Term | 1 or 3 years | 1 or 3 years |
| Payment | All / Partial / No Upfront | All / Partial / No Upfront |
| Reserves capacity | ❌ **never** | only **zonal** RIs |
| Can be sold | ❌ | ✅ Standard RIs, on the **RI Marketplace** |
| Applies to | EC2, **Fargate, Lambda** (Compute SP) | EC2 (and separately RDS, Redshift, ElastiCache…) |
| AWS's recommendation | ✅ **preferred** | legacy |

### When each purchasing option is the answer

| The scenario says | Answer |
|---|---|
| steady baseline usage, want flexibility to change instance types | **Compute Savings Plan** |
| steady usage, known instance family, want the deepest committed discount | **EC2 Instance Savings Plan** |
| interruptible batch / CI / stateless workers, cost is the priority | **Spot** |
| must guarantee capacity in an AZ (DR standby, licensed capacity) | **Capacity Reservation** or **zonal RI** |
| BYOL with per-socket or per-core licensing | **Dedicated Host** |
| regulatory isolation, no need to see the physical host | **Dedicated Instance** |
| unpredictable, short-lived, or dev/test | **On-Demand** |

### The cost tools

| Tool | Answers |
|---|---|
| **Cost Explorer** | "where did the money go, and what will it be?" |
| **Budgets** | "tell me before I cross $X" |
| **Cost Anomaly Detection** | "tell me when something is weird, without me setting a threshold" |
| **Cost allocation tags / categories** | "which team spent it?" |
| **Compute Optimizer** | "is this resource the right size?" |
| **Cost Optimization Hub** | "what should I change, ranked?" |

## Worked examples

> [!example] Worked example — a steady fleet with a variable shape
> A company runs roughly $12/hour of EC2 around the clock, but the mix changes — they migrate services between instance families as they tune, and they're moving some workloads to Fargate. A **Reserved Instance** would lock them to a family and be wasted the moment they migrate. An **EC2 Instance Savings Plan** would give the bigger 72% discount but only within one family in one Region — the same problem. The fit is a **Compute Savings Plan** at roughly their steady baseline: it follows them across families, sizes, Regions, operating systems and tenancies, **and covers the Fargate and Lambda usage too**. Commit to the *baseline*, not the peak — usage above the commitment simply bills On-Demand, whereas commitment you don't use is money gone.

> [!example] Worked example — cutting a bill with no instance changes at all
> A team's largest line items are a NAT Gateway and data transfer. Their private-subnet application reads heavily from S3, and every byte is going out through the NAT — charged per hour *and* per gigabyte. Adding an **S3 gateway endpoint** is free, routes that traffic inside the VPC, and removes it from the NAT bill entirely ([[05-vpc-endpoints-peering]]). While they're there: an **unattached Elastic IP** left from a decommissioned host is billing for nothing, old **EBS snapshots** from a Packer pipeline are charging indefinitely ([[03-ami-bake]]), and an **S3 lifecycle rule** moves logs older than 90 days to Glacier ([[09-s3-intro]]). Not one instance was resized. This is the shape of a lot of real cost work, and of the exam questions that don't mention compute.

> [!failure] Failure mode — Spot for the wrong tier
> A team puts their entire ASG on Spot to cut costs, including the instances holding user sessions in memory. AWS reclaims capacity, the **two-minute notice** fires, instances go away, and every user on them is logged out. The instances came back — the sessions didn't. Spot's contract is explicit: you get spare capacity and two minutes' warning, and anything that can't survive that isn't a Spot workload. The correct shapes are a **mixed-instances policy** (an On-Demand baseline with Spot on top for elasticity), moving session state out to **ElastiCache** ([[08-elasticache]]) so the instances are genuinely stateless, or handling the interruption notice to drain gracefully.

## Traps

> [!warning] Trap — "buy a Savings Plan to guarantee capacity"
> A Savings Plan is **only a billing discount**. It never reserves capacity. If a scenario needs certainty that an instance can be launched in a specific Availability Zone — a DR standby, a licensed workload — the answer is a **Capacity Reservation** or a **zonal Reserved Instance**. The two concerns are separate and can be combined.

> [!warning] Trap — assuming the most flexible option is the cheapest
> **EC2 Instance Savings Plans give up to 72%; Compute Savings Plans up to 66%.** The *less* flexible one is cheaper. Same for RIs: **Standard** discounts more than **Convertible**. A question that stresses "they know exactly what they'll run for three years" is pointing at the narrower, deeper discount, not the flexible one.

> [!warning] Trap — Standard vs Convertible RI, exchange vs modify
> **Standard RIs can be *modified* but never *exchanged*.** Convertible RIs can be **exchanged** for a different Convertible RI with different attributes. If the requirement is "we may need to switch instance families later," Standard is wrong however good the discount looks. Neither can be cancelled after purchase — though **Standard** RIs can be **sold** on the Reserved Instance Marketplace.

> [!warning] Trap — Dedicated Host vs Dedicated Instance
> Both give single-tenant hardware. **Dedicated Host** gives you visibility and control of the **physical server** — sockets, cores, host affinity — which is what **per-socket / per-core BYOL licensing** requires. **Dedicated Instance** gives isolation without host-level visibility. Any question mentioning existing server-bound licences is a **Dedicated Host** question.

> [!warning] Trap — Spot hibernation and the two minutes
> The two-minute notice applies when the interruption behaviour is **stop or terminate**. With **hibernate**, you get an interruption notice but **not two minutes of warning** — hibernation starts immediately. Also: setting a maximum Spot price makes interruptions **more** frequent, not fewer.

> [!warning] Trap — Cost Explorer vs Budgets vs Compute Optimizer
> Three tools, three jobs. **Cost Explorer** analyses what already happened and forecasts. **Budgets** alerts you when spend or usage crosses a threshold you set. **Compute Optimizer** looks at CloudWatch metrics and says the resource is the wrong size. "Notify us before we exceed $5,000" → Budgets, not Cost Explorer.

> [!example]- Recall drill
> (1) Which Savings Plan gives the bigger discount, and what does it lock you to? (2) Does a Savings Plan reserve capacity? What does? (3) Standard vs Convertible RI — which can be exchanged? (4) How long is the Spot interruption notice, how is it delivered, and which behaviour doesn't get it? (5) Dedicated Host or Dedicated Instance for per-core BYOL? (6) Which tool alerts you before you cross a spend threshold?
> > [!success]- Answers
> > (1) **EC2 Instance Savings Plans**, up to 72%, locked to one instance family in one Region. Compute SP is up to 66% and flexible everywhere including Fargate and Lambda. (2) No — never. Capacity Reservations or zonal RIs do. (3) **Convertible**. Standard can only be modified (or sold on the Marketplace). (4) **Two minutes**, via EventBridge and instance metadata `spot/instance-action`; **hibernate** gets a notice but not the two minutes. (5) **Dedicated Host**. (6) **AWS Budgets**.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Never studied — the vault had no EC2 purchasing content at all** until 2026-09-05, despite `exam-prep.md` wrongly ticking it as covered by [[02-ec2]]. D4 Cost fell from 85% to 54% between the two mocks, and this hole is the likely reason.
- [ ] **Savings Plans don't reserve capacity** — the single most-missed fact in this topic.
- [ ] **Less flexible = bigger discount** (EC2 Instance SP 72% > Compute SP 66%; Standard RI > Convertible). Counterintuitive.
- [ ] **Standard RI can be modified but not exchanged.**
- [ ] **Non-compute levers** — gateway endpoints vs NAT, unattached EIPs, orphaned snapshots, cross-AZ transfer. Cost questions often never mention an instance.

## 🔗 Docs

- [EC2 billing and purchasing options](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-purchasing-options.html) — all seven options and AWS's own decision guidance; verified 2026-09-05
- [What are Savings Plans](https://docs.aws.amazon.com/savingsplans/latest/userguide/what-is-savings-plans.html) — commitment model, 1/3 year, payment options; verified 2026-09-05
- [Savings Plans types](https://docs.aws.amazon.com/savingsplans/latest/userguide/plan-types.html) — Compute 66% vs EC2 Instance 72%, Database 35%, SageMaker 64%, and exactly what each is flexible on; verified 2026-09-05
- [Reserved Instances overview](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-reserved-instances.html) — billing-discount nature, four pricing attributes, Standard vs Convertible, payment options, no auto-renew, Marketplace, and AWS's recommendation of Savings Plans; verified 2026-09-05
- [Spot Instance interruptions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html) — the three interruption reasons and the behaviours; verified 2026-09-05
- [Spot interruption notices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-instance-termination-notices.html) — the two-minute notice, EventBridge event, `spot/instance-action` metadata, the hibernation exception; verified 2026-09-05
- [What is AWS Compute Optimizer](https://docs.aws.amazon.com/compute-optimizer/latest/ug/what-is-compute-optimizer.html) — supported resources, 14-day CloudWatch lookback, opt-in; verified 2026-09-05
- [AWS Billing and Cost Management](https://docs.aws.amazon.com/cost-management/latest/userguide/what-is-costmanagement.html) — Cost Explorer, Budgets, Cost Anomaly Detection, cost allocation tags, cost categories, Cost Optimization Hub, consolidated billing benefits; verified 2026-09-05
- [Terraform `aws_budgets_budget`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) / [`aws_ec2_capacity_reservation`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_capacity_reservation)

---
**Cards for this topic:** [[cards/13-cost-optimization-cards]]
