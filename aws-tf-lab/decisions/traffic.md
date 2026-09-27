---
decision: traffic
question: How should traffic reach and scale across instances?
spans: [04-alb-asg, 02-ec2]
tags: [decision, domain/resilient]
---

# How should traffic reach and scale across instances?

The notes explain each piece. This routes you to one. Work top-down — the front
door and the capacity manager are separate decisions, in that order.

## 1. Do you need a load balancer at all?

The deciding question is **must the address outlive the instance behind it?**

- **One instance, address must survive a stop/start** → **Elastic IP**. An
  auto-assigned public IP is released on stop and comes back different.
- **One instance, address must survive *replacement*** → a replacement is a new
  instance, so an EIP is not enough: load balancer (or DNS).
- **More than one instance, or any self-healing** → load balancer, §2.

↳ [[02-ec2#Auto-assigned Public IP vs Elastic IP]]

## 2. Which load balancer

The axis is **what does the routing decision need to read?**

- Needs to read the **HTTP request** — host, path, header, method, query-string —
  or to answer requests itself (redirects, fixed responses) → **ALB**.
- Needs **nothing above the TCP flow**, or a **static IP**, or the **real client IP
  with no code change**, or is not HTTP at all → **NLB**.
- Traffic must be **passed through a firewall/IDS/IPS appliance** in line → **GWLB**.

Two hard constraints, not preferences: **an ALB requires at least two AZs**, and a
**PrivateLink endpoint service must be fronted by an NLB or GWLB** — if you need
Layer 7 there, put the ALB *behind* the NLB as a target.

↳ [[04-alb-asg#ALB vs NLB vs GWLB]]

## 3. Who is allowed to reach the instances

Ask **is the client on the internet, or inside the VPC?**

- **Internet clients** → internet-facing LB in public subnets, instances private,
  and the instance SG's source is **the LB's security group**, not a CIDR.
- **Internal clients only** → the same shape, internal scheme.

A security group narrows who may reach something already reachable; it creates no
route. "Tighten the security group" never answers a reachability question.

↳ [[04-alb-asg#The ALB opens your HTTP request, and everything follows from that]]

## 4. What decides how many instances run

The axis is **when do you learn the load is coming?**

- **After it arrives** (the normal case) → **target tracking** — one metric, one
  target value, its own managed alarms. The default choice.
- **At a known wall-clock time** → **scheduled action**, and set *only* desired
  capacity so the dynamic policy keeps working on top of it.
- **From history, cyclically** → **predictive**, alongside a dynamic policy.
- **In graduated bands, one adjustment being too blunt** → **step scaling**.

"Predictable baseline plus unpredictable spikes" is not a choice between these —
it is scheduled **and** dynamic.

↳ [[04-alb-asg#Scaling policy types]] · [[04-alb-asg#Scheduling capacity without freezing the group]]

## 5. What replaces a broken instance

One question: **can the app be broken while the VM is fine?**

- **Yes** (which is almost always) → ASG `health_check_type = "ELB"`, so the load
  balancer's verdict triggers replacement.
- **No** → the default `EC2` only watches hypervisor status checks.

The load balancer never terminates anything, only stops routing. Replacement is the
ASG's job and this setting is the only wire between them.

↳ [[04-alb-asg#The target group is the joint — and two health checks meet inside it]]

## 6. Which instance dies on scale-in

**Default** unless you are rolling the fleet onto a new instance **type** — then
**`OldestInstance`**, because the default hunts the oldest *configuration*.

↳ [[04-alb-asg#Predefined termination policies]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **Choosing an ALB when the requirement was a static IP**, or the real client IP
  with no app change. Both are NLB-only; an ALB is DNS-name-only and cannot take an EIP.
- **Reaching past the load balancer for HTTP→HTTPS.** It is a listener action on
  the ALB — not CloudFront, not a Lambda, not an app-level rewrite. And an NLB
  cannot do it at all, so picking an NLB quietly forfeits the option.
- **Picking an NLB because it looked cheaper.** Cross-zone is free and always on for
  an ALB, off by default on an NLB — and enabling it adds inter-AZ data charges.
- **Treating "the ALB will replace it" as the resilience answer.** Checking and
  healing are different systems; left at `EC2` you sit at N-1 forever, nobody paged.
- **Guaranteeing capacity by pinning min and max.** "Guarantee 10 at 9am" and "run
  exactly 10 at 9am" are different requirements. Pinning buys the second one and
  switches dynamic scaling off for the day.
- **Lowering the target value to get more instances.** Target tracking never scales
  out while the metric is below target, so this only ever scales you in. More
  capacity comes from real load, or from §4's scheduled action.
- **Choosing an ASG when the address was the problem.** An ASG fixes capacity and
  replacement; it gives clients no single address to talk to. That is still §2.
