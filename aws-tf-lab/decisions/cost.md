---
decision: cost
question: Where is the money going, and which lever moves it?
spans: [13-cost-optimization, 02-ec2, 09-s3-intro]
tags: [decision, domain/cost]
---

# Where is the money going, and which lever moves it?

The notes price each service. This routes from a line item to the one lever that moves
it. Start at §1 — the lever is usually not the thing you were about to change.

## 1. Which line are you actually attacking?

The deciding question is **is this a rate, a quantity, or a resource nobody owns?**
Commitments move only the *rate*; most surprising bills are quantity or an orphan.

| The largest line item | The lever | Go to |
|---|---|---|
| steady compute hours | the **rate** — a commitment | §2 |
| storage that keeps growing | the **quantity** — expire or delete | §3 |
| NAT Gateway, data transfer | the **path** the bytes take | §4 |
| something charging while nobody uses it | **delete it** | §5 |
| you can't tell yet | a **tool**, not a change | §6 |

## 2. Compute — what can you promise?

Not "which is cheapest" — the axis is **what you can promise, and whether anything needs
capacity actually held for it.**

- **Nothing; spiky or dev/test** → **On-Demand**.
- **A spend rate, and the mix keeps moving** across families, Regions, Fargate, Lambda → **Compute Savings Plan**.
- **A spend rate, family and Region already settled** → **EC2 Instance Savings Plan**. The narrower promise pays *more*.
- **A configuration you may need to switch** → **Convertible RI**; never switching → **Standard RI**.
- **Nothing, but a unit can be killed and re-run** → **Spot**.
- **A licence bound to sockets or cores** → **Dedicated Host**.
- **Capacity must exist in a named AZ** → **Capacity Reservation** or **zonal RI**. Not a discount; no Savings Plan does it.

Committing? Second question: **baseline, not peak.** Usage above it bills On-Demand;
commitment you don't use is gone.

↳ [[13-cost-optimization#The ways to pay for a server]] · [[13-cost-optimization#When each purchasing option is the answer]] · [[13-cost-optimization#Spot, and the two minutes that make it usable]]

## 3. Storage — wrong class, or should it not exist?

Ask **would deleting it be fine?** before asking which class. If yes, the class is
irrelevant and you are paying to move garbage somewhere cheaper.

- **Old versions nobody asked for** → noncurrent-version expiration. A listing shows only current versions, so the console looks innocent.
- **Uploads that never finished** → an abort-incomplete-multipart rule.
- **Snapshots of volumes already gone** → delete; they bill on after the volume.
- **An instance stopped "to save money"** → compute stopped, the volume did not.

Only then is the class the lever, and only for objects **large** enough and **still** enough
that minimum duration and the 128 KB billable floor don't invert the saving.

↳ [[09-s3-intro#Versioning, delete markers, and the bill that grows in the dark]] · [[09-s3-intro#Why moving data to a cheaper class can cost you more]] · [[09-s3-intro#Storage classes (verified against AWS docs 2026-08)|storage classes]]

## 4. Data movement — does the traffic need to leave?

The axis is **which billed boundary each byte crosses**; the fix is routing, not sizing.

- **Private subnet reading S3 or DynamoDB through a NAT** → a **gateway endpoint** is free and drops that traffic from the NAT's hourly *and* per-GB charge.
- **Leaving for the internet** → charged outbound; inbound generally isn't.
- **Chatter between AZs** → charged. Keep the talkative pair in one AZ, or accept it as the price of the resilience you chose.

↳ [[13-cost-optimization#The bill that isn't compute]]

## 5. Does it bill while idle?

The axis is **would this charge stop if everyone went home?** If not, the lever is
deletion — the cheapest saving there is. **Every public IPv4 address** (Elastic or
auto-assigned, attached or not), **EBS volumes outliving their instance** and snapshots
outliving the volume, and **NAT Gateway and load balancer hours**, which accrue at zero
traffic.

↳ [[02-ec2#Stop vs Terminate]] · [[02-ec2#Auto-assigned Public IP vs Elastic IP]]

## 6. You can't tell where it went — which tool?

The axis is **past, threshold, or size.**

- **What happened, and next month** → **Cost Explorer** (also the source of Savings Plans recommendations).
- **Warn me before a number I picked** → **Budgets**.
- **Warn me when something is odd and I picked no number** → **Cost Anomaly Detection**.
- **Which team or environment spent it** → **cost allocation tags**. Without them the bill is one number and no tool can help.
- **Is this resource the wrong size, or idle** → **Compute Optimizer**.
- **Many accounts** → **consolidated billing**: free, pools volume/RI/SP discounts.

↳ [[13-cost-optimization#The tools that tell you where the money went]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **Rightsizing the instance when the line item is the volume.** Stopping an instance
  stops compute and nothing else; terminating deletes the root volume but additional
  volumes default to surviving. Two separate levers.
- **Down-tiering S3 to fix a bill caused by versioning.** Transition and expiration are
  different rules — moving dead versions to Glacier pays a transition *and* a 90-day
  minimum for data that should have been deleted.
- **Answering a NAT bill with a compute decision.** The line item names no instance, the
  fix is a gateway endpoint, and a cheaper family changes nothing.
- **Releasing the Elastic IP to stop the IP charge.** Every public IPv4 bills the same
  whether you allocated it or AWS auto-assigned it — you lose the stable address for nothing.
- **Putting Spot under a tier because an ASG made the instances look interchangeable.**
  Interchangeable to the load balancer is not interchangeable to the user whose session
  is in that instance's memory. Move the state out first.
- **Reaching for Cost Explorer to prevent a bill.** It explains the past; a threshold you
  want to be warned about is Budgets, and "right size?" is Compute Optimizer.
