---
topic: 13-cost-optimization
domain: cost
related_note: 13-cost-optimization
tags: [flashcards/cost]
---

# Cards for [[13-cost-optimization]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

Name the seven EC2 purchasing options and what each commits you to.
?
On-Demand (nothing, pay per second). Savings Plans (an amount of spend in $/hour, 1 or 3 years). Reserved Instances (a specific instance configuration, 1 or 3 years). Spot (nothing, but accept interruption). Dedicated Hosts (a whole physical server). Dedicated Instances (single-tenant hardware, hourly). Capacity Reservations (capacity in a specific AZ).

Does a Savings Plan reserve capacity?
?
No — never. It is purely a billing discount. If you need certainty that an instance can launch in a particular Availability Zone (a DR standby, a licensed workload), you need a Capacity Reservation or a ZONAL Reserved Instance. The discount and the capacity guarantee are separate concerns that can be combined.

Compute Savings Plan vs EC2 Instance Savings Plan — discount and flexibility?
?
Compute SP: up to 66% off, flexible across instance family, size, Region, OS and tenancy — and it also covers Fargate and Lambda. EC2 Instance SP: up to 72% off, but locked to ONE instance family in ONE Region (flexible on size, OS and tenancy within that). The LESS flexible plan gives the BIGGER discount, which is the opposite of most people's instinct.

Savings Plans vs Reserved Instances — what do you commit to in each?
?
Savings Plans commit to MONEY ("$10/hour of compute for 3 years") and let you spend it on whatever you like. Reserved Instances commit to a CONFIGURATION (instance type, Region, tenancy, OS) and apply as an automatic billing discount to matching running instances. AWS now explicitly recommends Savings Plans over Reserved Instances.

Standard vs Convertible Reserved Instances?
?
Standard gives the bigger discount but can only be MODIFIED — never exchanged. Convertible gives a smaller discount but can be EXCHANGED for another Convertible RI with different attributes. Neither can be cancelled after purchase, though Standard RIs can be sold on the Reserved Instance Marketplace. "We may need to switch families later" → Convertible.

Are Reserved Instances physical instances, and do they renew?
?
Neither. An RI is a billing discount applied automatically to running On-Demand instances whose attributes match. And they do NOT auto-renew — when one expires the instance keeps running and quietly reverts to On-Demand rates, which is a common surprise on a bill.

How much warning do you get before a Spot interruption, and how is it delivered?
?
Two minutes, delivered two ways: as an EventBridge event ("EC2 Spot Instance Interruption Warning") and as an instance metadata item at /latest/meta-data/spot/instance-action, giving the action and the time. AWS recommends polling that metadata every 5 seconds and notes notices are best-effort.

Which Spot interruption behaviour does NOT get two minutes of warning?
?
Hibernate. You still receive an interruption notice, but not two minutes in advance, because hibernation begins immediately. Terminate and stop both give the two-minute notice.

Why do Spot interruptions happen, and does setting a maximum price help?
?
Three reasons: EC2 needs the capacity back (the usual one), the Spot price exceeded a maximum price you set, or a constraint like a launch group or AZ group can no longer be met. Setting a maximum price is optional and makes interruptions MORE frequent, not fewer.

What workloads suit Spot, and what does not?
?
Suits anything that can checkpoint, retry, or simply be re-run: batch jobs, CI runners, data processing, stateless web tiers behind an ASG. Does not suit anything that can't survive losing a machine in two minutes — databases, in-memory session stores. The fix for a stateful tier is to move state out (e.g. to ElastiCache) or run a mixed-instances policy with an On-Demand baseline.

Dedicated Host vs Dedicated Instance?
?
Both are single-tenant hardware. Dedicated HOST gives you visibility and control of the physical server — sockets, cores, host affinity — which is what per-socket / per-core BYOL licensing requires. Dedicated INSTANCE gives isolation without host-level visibility. Any mention of existing server-bound licences means Dedicated Host.

Cost Explorer vs Budgets vs Compute Optimizer — which does what?
?
Cost Explorer ANALYSES the past and forecasts the future, with filtering, grouping and Savings Plans recommendations. Budgets ALERTS you when cost or usage crosses a threshold you set. Compute Optimizer RIGHTSIZES — it reads CloudWatch metrics and says the resource is the wrong size. "Notify us before we exceed $5,000" is Budgets, not Cost Explorer.

What does AWS Compute Optimizer analyse, and over what period?
?
CloudWatch utilisation metrics over the last 14 days by default (extendable to 93 days with the paid enhanced infrastructure metrics). It covers EC2 instances, Auto Scaling groups, EBS volumes, Lambda functions, ECS on Fargate, RDS/Aurora, NAT Gateway, DynamoDB, ElastiCache and more. You must opt in first.

Name the non-compute cost levers that show up in exam questions.
?
Gateway endpoints for S3/DynamoDB are FREE and remove that traffic from a NAT Gateway (which bills per hour AND per GB). Outbound internet and cross-AZ data transfer are charged. Unattached Elastic IPs cost money. S3 lifecycle rules move data down storage tiers. gp3 decouples IOPS from capacity. EBS snapshots keep charging after the volume is deleted. Many cost questions never mention an instance at all.

What does consolidated billing through AWS Organizations give you?
?
One bill across all accounts, combined tracking, no extra fee — and crucially, usage is COMBINED across accounts so volume pricing discounts, Reserved Instance discounts and Savings Plans are shared organization-wide. A Savings Plan bought in one account can cover usage in another.

Which purchasing option for: steady usage, they know exactly which instance family for three years?
?
EC2 Instance Savings Plan — up to 72%, the deepest committed discount, in exchange for locking to that family in that Region. The question stressing certainty about what they'll run is the signal to pick the narrower, deeper discount rather than the flexible one.
