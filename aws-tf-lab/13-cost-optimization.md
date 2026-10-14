---
topic: 13-cost-optimization
domain: cost
status: reviewed
services: [EC2, SavingsPlans, CostExplorer, Budgets, ComputeOptimizer, CostOptimizationHub]
related: [02-ec2, 04-alb-asg, 08-elasticache, 09-s3-intro, 05-vpc-endpoints-peering, 01-iam-advanced, 07-rds-aurora]
tags: [topic, domain/cost]
---

# 13 – Cost optimization

The fourth exam domain, worth **20%**. Not a service — a way of reading questions. Every "MOST cost-effective" question is asking you to compare options on price, which is a different retrieval path from "what does this service do."

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

## What problem does this solve?

On-Demand pricing is the rate you pay for saying nothing in advance. You start an instance, you're charged **by the second with a 60-second minimum**, you stop it, the charge stops ([[02-ec2]] owns the billing detail and the OS exceptions). Nothing is committed and nothing is promised.

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

> In one line: On-Demand commits to nothing, Savings Plans commit to spend, Reserved Instances commit to a configuration, Spot commits to nothing but accepts eviction — and capacity itself is held by zonal RIs, Capacity Reservations, Capacity Blocks and Dedicated Hosts — never by a Savings Plan or a regional RI.

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

**Data transfer**: inbound is generally free, **outbound to the internet costs money**, and **cross-AZ traffic is charged** — with exceptions the exam likes. **RDS Multi-AZ** replication between AZs is free (the pricing page lists it as Free), and so is **same-Region read-replica** replication: *"You aren't charged for the data transfer incurred in replicating data between the source DB instance and a read replica within the same AWS Region."* Mind the scope on that second one — it covers **replication** traffic only, so an app in AZ-a querying a replica in AZ-b still pays standard cross-AZ transfer ($0.01/GB each way), the replica's **instance-hours** are billed in full, and **cross-Region** replica replication **is** charged (the initial snapshot copy plus every subsequent modification, billed as data out of the source Region). See [[07-rds-aurora]]. On load balancers the picture is three-way: cross-zone traffic is **free on an ALB** — *"Since cross-zone load balancing is always on with Application Load Balancer, you are not charged for this type of regional data transfer"* — **free on a CLB**, and **charged on an NLB**: *"you will be charged for regional data transfer between Availability Zones with Network Load Balancer when cross-zone load balancing is enabled."* See [[04-alb-asg]].

**Elastic IPs** — and every public IPv4 address — bill **hourly whether attached or not**; an unattached one is the classic forgotten-resource bill, charging for nothing in return.

**S3 storage classes** differ enormously, and **lifecycle rules** move data down the tiers automatically ([[09-s3-intro]]). Watch the minimum billable object size on the IA classes — many tiny files in IA can cost more than Standard.

**EBS**: `gp3` decouples IOPS from capacity, so you stop over-provisioning size just to buy performance ([[02-ec2]]). And **snapshots keep charging after the volume is deleted** — delete the volume and the snapshot bill carries on, which is the classic silent leak.

**Aurora Serverless v2** scales capacity to the workload, which beats a provisioned instance sized for a peak that happens twice a day ([[07-rds-aurora]]).

**Consolidated billing** through AWS Organizations ([[01-iam-advanced]]) combines usage across all accounts, so **volume discounts, Reserved Instance discounts and Savings Plans are shared** across the organization. It costs nothing extra.

> In one line: a large share of real savings is architectural, not contractual — endpoints instead of NAT, lifecycle instead of Standard, gp3 instead of oversized gp2, and one bill instead of ten.

### The tools that tell you where the money went

Six, and the exam mostly wants you to pick the right one for a described job.

- **AWS Cost Explorer** — the analysis console. Visualise cost and usage, filter and group, **forecast** future spend, and get **Savings Plans purchase recommendations**. This is where you go to *understand* the bill.
- **AWS Budgets** — set a budget on **cost or usage** and get **alerted** when you cross a threshold. This is where you go to *be told* before it's too late.
- **Cost Optimization Hub** — one ranked list of *what to change*: unused resources to delete, rightsizing, Savings Plans and reservations, with the estimated saving attached. AWS now points here first when the question is "where is the money going spare?"
- **Cost Anomaly Detection** — AWS's own ML spots unusual spend and alerts you, rather than you naming the dollar figure up front as you do with **Budgets**. That contrast is the exam point, but state it precisely: an alert **subscription does** take a threshold (an absolute dollar impact or a percentage, and two can be combined with AND/OR). What needs no threshold is the **detection** — *"Even if an anomaly is below the alert threshold, the machine learning model continues to detect spend anomalies on your account."* So the distinction is *detection needs no number; notification does*, where a Budget needs a number to do anything at all. Alerting comes in three frequencies: **individual** alerts (require an **SNS** topic), **daily** summaries (top 10 anomalies, sent 00:00 UTC) and **weekly** summaries.
- **Cost allocation tags** and **cost categories** — how you slice the bill by team, application or environment. Tags are the mechanism; without them the bill is one undifferentiated number.
- **AWS Compute Optimizer** — analyses **CloudWatch metrics over the last 14 days** and recommends **rightsizing**, plus flags **idle resources**. Covers EC2, Auto Scaling groups, EBS volumes, Lambda, ECS on Fargate, RDS/Aurora, NAT Gateway, DynamoDB, ElastiCache and more. You must **opt in**.

The discriminator that matters: **Cost Explorer explains the past, Budgets warn about the future, Compute Optimizer tells you the resource is the wrong size.**

> In one line: Cost Explorer analyses, Budgets alert, Anomaly Detection watches, tags slice, and Compute Optimizer says the instance is too big.

## Key facts, limits & pricing

- **Cost Explorer API** (endpoint `ce.us-east-1.amazonaws.com`) is the documented programmatic **query** interface: `GetCostAndUsage` *"Retrieves cost and usage metrics for your account"*, `GetCostForecast` retrieves a spend forecast. Two precision points. **Pagination is a property of `GetCostAndUsage` alone** — it takes and returns a `NextPageToken` and can raise `InvalidNextTokenException`; `GetCostForecast` has **no pagination at all** and returns the whole result in one call, so grouping "cost/usage/forecast" under one "paginated" claim is false. And it is the documented **API**, not the *only* programmatic route — **CUR** is first-party and is described as *"the most comprehensive set of cost and usage data available"*, delivered as CSV to S3 and queried with Athena/Redshift/QuickSight. So answer "the API is how you *query* programmatically", not "you must use the API". (Granularity: `GetCostAndUsage` is `DAILY | MONTHLY | HOURLY`; `GetCostForecast` gives 3 months of `DAILY` or 18 months of `MONTHLY`.)

- **Spot request type — one-time vs persistent**, now verified verbatim. *One-time*: "Amazon EC2 places a one-time request for your Spot Instance. If your Spot Instance is interrupted, **the request is not resubmitted**." *Persistent*: "If your Spot Instance is interrupted, **the request is resubmitted** to replenish the interrupted Spot Instance." **The default is one-time.** Two consequences the exam likes: the **interruption behaviour** options are tied to the request type — `Stop` and `Hibernate` are valid **only for persistent** requests, `Terminate` **only for one-time** (and `Terminate` is the default, so a persistent request that keeps the default *errors*) — and an expiry date (**Valid to**) applies only to persistent requests. For maintaining a **target capacity** across instance types, that is **EC2 Fleet / Spot Fleet**, not a persistent request. On cancelling, AWS's rule is **asymmetric by request state**, and the blanket "cancelling never terminates" is wrong: *"If you cancel an **`active`** Spot Instance request that has a **running** Spot Instance, the running Spot Instance is **not** automatically terminated; you must manually terminate the Spot Instance."* But *"If you cancel a **`disabled`** Spot Instance request that has a **stopped** Spot Instance, the stopped Spot Instance **is automatically terminated** by the Amazon EC2 Spot service."* The reverse order has its own trap: *"If you terminate a running or stopped Spot Instance that was launched by a **persistent** Spot Instance request, the Spot Instance request transitions to the `open` state so that a new Spot Instance can be launched"* — so terminating first just makes it come back; cancel the request first. (Relatedly, you can only **stop** a Spot Instance from a **persistent** request, and not at all once the request is cancelled.) *(Verified 2026-10-10.)*

- **Two different rightsizing tools, and the exam separates them.** **Cost Explorer** has its own **rightsizing recommendations**: *"identify cost-saving opportunities by downsizing or terminating instances in Amazon EC2"*, showing **underutilised instances across member accounts in a single view** — a *spend* view, netting out what you already own. **AWS Compute Optimizer** is the one that recommends the **instance type and size** from CloudWatch metrics. Neither *rightsizing* tool recommends **purchasing options**. Savings Plans and reservation purchase recommendations come from **Cost Explorer** *and* from **Cost Optimization Hub** — which AWS now steers you to first, the Cost Explorer rightsizing page itself saying "We recommend that you use Cost Optimization Hub to identify cost optimization opportunities." **Compute Optimizer** only ever does rightsizing and idle-resource detection. *(Verified 2026-10-07.)*

- **Seven purchasing options:** On-Demand, Savings Plans, Reserved Instances, Spot, Dedicated Hosts, Dedicated Instances, Capacity Reservations. (Capacity Blocks additionally reserve clusters of GPU instances.)
- **Savings Plans commit to a spend rate in USD/hour** for **1 or 3 years**. Payment: **All Upfront**, **Partial Upfront**, or **No Upfront**. **Terms cannot be changed after purchase** — as usage grows you buy an additional plan.
- **Compute Savings Plans — up to 66% off.** Apply regardless of instance family, size, **Region**, operating system or tenancy, **and cover AWS Fargate and AWS Lambda**.
- **EC2 Instance Savings Plans — up to 72% off.** Commit to a **specific instance family in a chosen Region**; within that, size, OS and tenancy are free to change.
- **Database Savings Plans — up to 35%** across Aurora, RDS, DynamoDB, ElastiCache, DocumentDB, Timestream, Neptune, Keyspaces, DMS and OpenSearch, including serverless usage. **SageMaker AI Savings Plans — up to 64%.**
- Both Compute and EC2 Instance plans **apply to the EC2 instances inside EMR, EKS and ECS clusters** — though EKS's own control-plane charge is not covered. **Dedicated Instances' $2/hour per-Region fee is not discounted** by Savings Plans.
- **Reserved Instances are a billing discount, not a physical instance.** Priced on four attributes: **instance type, Region, tenancy, platform (OS)**. Terms of **1 or 3 years**; the 3-year term discounts more.
- **Standard RIs** give the largest RI discount and can be **modified but never exchanged**. **Convertible RIs** discount less but **can be exchanged** for another Convertible RI with different attributes. **Purchases cannot be cancelled**, though Standard RIs can be **sold on the Reserved Instance Marketplace**.
- **RIs do not auto-renew.** On expiry the instance keeps running and silently reverts to On-Demand rates.
- **Savings Plans and *regional* RIs are discounts only — neither holds capacity.** What actually holds capacity for you: **zonal Reserved Instances**, **On-Demand Capacity Reservations**, **Capacity Blocks** (AWS: "Capacity Blocks can be used to reserve a cluster of GPU instances"), and **Dedicated Hosts** ("a physical host that is fully dedicated to running your instances"). *(Corrected 2026-10-07 — this bullet said "only zonal RIs and Capacity Reservations", which the note's own purchasing-options line already contradicted.)*
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
| Reserves capacity | ❌ **never** | only **zonal** RIs (capacity also comes from Capacity Reservations, Capacity Blocks and Dedicated Hosts) |
| Can be sold | ❌ | ✅ Standard RIs, on the **RI Marketplace** |
| Applies to | EC2, **Fargate, Lambda** (Compute SP) | EC2 (and separately RDS, Redshift, ElastiCache…) |
| AWS's recommendation | ✅ **"We recommend Savings Plans over Reserved Instances"** | still fully supported — and still the only answer for **zonal capacity**, the **RI Marketplace**, and RDS/Redshift/ElastiCache reservations |

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

### Cross-zone data transfer — which load balancer charges

|   | ALB | CLB | NLB |
|---|---|---|---|
| Cross-zone setting | **Always on**, not disableable at the LB | On by default | **Off** by default, per-target-group |
| Regional (cross-AZ) data transfer | **Not charged** | **Not charged** | **Charged** when enabled |
| AWS's wording | "you are not charged for this type of regional data transfer" | "you are not charged" | "you **will** be charged for regional data transfer between Availability Zones" |

*The NLB is the odd one out, and it is the one the exam asks about. See [[04-alb-asg]].*

### The cost tools

| Tool | Answers |
|---|---|
| **Cost Explorer** | "where did the money go, and what will it be?" |
| **Budgets** | "tell me before I cross $X" |
| **Cost Anomaly Detection** | "tell me when something is weird, without me setting a threshold" |
| **Cost allocation tags / categories** | "which team spent it?" |
| **Compute Optimizer** | "is this resource the right size?" |
| **Cost Optimization Hub** | "what should I change, ranked?" |
| **Trusted Advisor** | "which *deployed resources* break best practice?" — including **service quota usage** |

**Trusted Advisor vs Compute Optimizer — do not let "over-provisioned" decide it.** Both
services are described as finding waste, and AWS uses overlapping words for them (Compute
Optimizer *"identif[ies] idle resources"*; Trusted Advisor saves money too). The split is
**what the answer has to produce**: Compute Optimizer returns **a specific recommended
instance type** from CloudWatch utilisation; Trusted Advisor returns **a checklist across six
categories** and only flags the resource. One named workload needing a new size → Compute
Optimizer. An account-wide sweep listed next to root MFA, public buckets or quota usage →
Trusted Advisor.

**Trusted Advisor is the odd one out here, and the exam leans on it.** It does not read your
bill; it *"inspects your AWS environment, and then makes recommendations when opportunities
exist to save money, improve system availability and performance, or help close security
gaps."* It is **advisory only** — it changes nothing. Two details that decide questions:
checks are **refreshed manually** (refresh before trusting a reading), and on a **Basic or
Developer** Support plan you get **all Service Limits checks plus selected Security and Fault
Tolerance checks only** — the full set needs **Business or Enterprise** Support. For quota
*alarming* rather than inspection, the answer is **Service Quotas** with a CloudWatch alarm.
*(Verified 2026-10-14.)*

### Right-size first, or scale out? (vertical vs horizontal)

|   | Vertical — right-sizing | Horizontal — scaling out |
|---|---|---|
| The move | Change the **instance type** of what you already run | Add **more instances** behind a load balancer |
| Which service tells you | **Compute Optimizer** (rightsizing recommendations, idle-resource detection) | **Auto Scaling** policies on a metric |
| Fixes cost from | **Over-provisioning** — paying for CPU/memory nobody uses | Nothing; it adds capacity and adds cost |
| Fixes availability | **No** — still one instance, still one AZ | **Yes** — multiple instances across AZs |
| Ceiling | The largest instance type in the family | Effectively none |
| Stem wording | "right-size", "what instance type should this be", "under-utilised", "reduce cost with no architecture change" | "handle the peak", "improve availability", "no single point of failure" |

The exam pairs these deliberately. *"Resolve the performance issue **and** improve
availability"* wants **one of each** — Compute Optimizer for the sizing, an ASG behind a load
balancer for the availability. Picking two horizontal options, or two cost options, answers
only half the stem. See [[04-alb-asg]] for the horizontal half.

## Worked examples

> [!example] Worked example — a steady fleet with a variable shape
> A company runs roughly $12/hour of EC2 around the clock, but the mix changes — they migrate services between instance families as they tune, and they're moving some workloads to Fargate. A **Reserved Instance** would lock them to a family and be wasted the moment they migrate. An **EC2 Instance Savings Plan** would give the bigger 72% discount but only within one family in one Region — the same problem. The fit is a **Compute Savings Plan** at roughly their steady baseline: it follows them across families, sizes, Regions, operating systems and tenancies, **and covers the Fargate and Lambda usage too**. Commit to the *baseline*, not the peak — usage above the commitment simply bills On-Demand, whereas commitment you don't use is money gone.

> [!example] Worked example — cutting a bill with no instance changes at all
> A team's largest line items are a NAT Gateway and data transfer. Their private-subnet application reads heavily from S3, and every byte is going out through the NAT — charged per hour *and* per gigabyte. Adding an **S3 gateway endpoint** is free, routes that traffic inside the VPC, and removes it from the NAT bill entirely ([[05-vpc-endpoints-peering]]). While they're there: an **unattached Elastic IP** left from a decommissioned host is billing for nothing, old **EBS snapshots** from an image-build pipeline are charging indefinitely, and an **S3 lifecycle rule** moves logs older than 90 days to Glacier ([[09-s3-intro]]). Not one instance was resized. This is the shape of a lot of real cost work, and of the exam questions that don't mention compute.

> [!failure] Failure mode — Spot for the wrong tier
> A team puts their entire ASG on Spot to cut costs, including the instances holding user sessions in memory. AWS reclaims capacity, the **two-minute notice** fires, instances go away, and every user on them is logged out. The instances came back — the sessions didn't. Spot's contract is explicit: you get spare capacity and two minutes' warning, and anything that can't survive that isn't a Spot workload. The correct shapes are a **mixed-instances policy** (an On-Demand baseline with Spot on top for elasticity), moving session state out to **ElastiCache** ([[08-elasticache]]) so the instances are genuinely stateless, or handling the interruption notice to drain gracefully.

## Traps

> [!warning] Trap — "cancel the Spot request to get rid of the instance"
> Cancelling and terminating are **separate actions**, and which one you need depends on the request's **state**. Cancel an **`active`** request holding a **running** instance and the instance *keeps running and keeps billing* — you must terminate it yourself. Cancel a **`disabled`** request holding a **stopped** instance and the Spot service **does** terminate it for you. The inverse is the costlier mistake: terminate an instance from a **persistent** request without cancelling the request and it returns to `open` and **launches a replacement**. Order matters — cancel the request, then terminate the instance.

> [!warning] Trap — "Cost Anomaly Detection needs no threshold"
> Half right, and the half that is wrong is the half being tested. The **ML detection** needs no threshold — *"Even if an anomaly is below the alert threshold, the machine learning model continues to detect spend anomalies on your account."* The **alert subscription** does take one (dollar impact or percentage). The real contrast with **Budgets** is not "threshold vs no threshold" but *what the number is for*: a Budget needs a figure to detect anything, while Anomaly Detection detects regardless and uses the figure only to decide whether to tell you.

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

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Compute Optimizer is the right-sizing recommender** (trainer-sourced,
  drill-mock02-concepts, 2026-10-10): missed marked **"sure"** — got the scale-out half (ASG +
  ALB) and missed that vertical right-sizing comes from **Compute Optimizer**. Two misses now on
  this service across two sessions; it is a recall problem, not a coverage one.

- [ ] **Never studied — the vault had no EC2 purchasing content at all** until 2026-09-05, despite `exam-prep.md` wrongly ticking it as covered by [[02-ec2]]. D4 Cost fell from 85% to 54% between the two mocks, and this hole is the likely reason.
- [ ] **Savings Plans don't reserve capacity** — the single most-missed fact in this topic.
- [ ] **Less flexible = bigger discount** (EC2 Instance SP 72% > Compute SP 66%; Standard RI > Convertible). Counterintuitive.
- [ ] **Standard RI can be modified but not exchanged.**
- [ ] **Non-compute levers** — gateway endpoints vs NAT, unattached EIPs, orphaned snapshots, cross-AZ transfer. Cost questions often never mention an instance.

## 🔗 Docs
- [Working with read replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html) — same-Region replica replication traffic not charged (**cite this, not the pricing page** — the pricing table carries only the Multi-AZ line); **verified 2026-10-10**
- [Elastic Load Balancing FAQs](https://aws.amazon.com/elasticloadbalancing/faqs/) — cross-zone data transfer free on ALB and CLB, charged on NLB; **verified 2026-10-10**
- [`GetCostAndUsage`](https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetCostAndUsage.html) — `NextPageToken` pagination, `DAILY | MONTHLY | HOURLY`; **verified 2026-10-10**
- [`GetCostForecast`](https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetCostForecast.html) — **no** pagination, 3 months DAILY / 18 months MONTHLY; **verified 2026-10-10**
- [Manage your Spot Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances-request.html) — cancel-vs-terminate by request state, persistent requests reopening on termination; **verified 2026-10-10**
- [Detecting anomalies with Cost Anomaly Detection](https://docs.aws.amazon.com/cost-management/latest/userguide/manage-ad.html) — detection runs below the alert threshold; individual/daily/weekly alerting; **verified 2026-10-10**
- [Cost Explorer rightsizing recommendations](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-rightsizing.html)

- [EC2 billing and purchasing options](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-purchasing-options.html) — all seven options and AWS's own decision guidance; verified 2026-09-05
- [What are Savings Plans](https://docs.aws.amazon.com/savingsplans/latest/userguide/what-is-savings-plans.html) — commitment model, 1/3 year, payment options; verified 2026-09-05
- [Savings Plans types](https://docs.aws.amazon.com/savingsplans/latest/userguide/plan-types.html) — Compute 66% vs EC2 Instance 72%, Database 35%, SageMaker 64%, and exactly what each is flexible on; verified 2026-09-05
- [Reserved Instances overview](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-reserved-instances.html) — billing-discount nature, four pricing attributes, Standard vs Convertible, payment options, no auto-renew, Marketplace, and AWS's recommendation of Savings Plans; verified 2026-09-05
- [Spot Instance interruptions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html) — the three interruption reasons and the behaviours; verified 2026-09-05
- [Spot interruption notices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-instance-termination-notices.html) — the two-minute notice, EventBridge event, `spot/instance-action` metadata, the hibernation exception; verified 2026-09-05
- [What is AWS Compute Optimizer](https://docs.aws.amazon.com/compute-optimizer/latest/ug/what-is-compute-optimizer.html) — supported resources, 14-day CloudWatch lookback, opt-in; verified 2026-09-05
- [AWS Billing and Cost Management](https://docs.aws.amazon.com/cost-management/latest/userguide/what-is-costmanagement.html) — Cost Explorer, Budgets, Cost Anomaly Detection, cost allocation tags, cost categories, Cost Optimization Hub, consolidated billing benefits; verified 2026-09-05
