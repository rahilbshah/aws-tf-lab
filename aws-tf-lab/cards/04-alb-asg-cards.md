---
topic: 04-alb-asg
domain: resilient
related_note: 04-alb-asg
tags: [flashcards/alb-asg]
---

# Cards for [[04-alb-asg]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What layer does each ELB type operate at, and what does each route on?
?
ALB = Layer 7 (HTTP/HTTPS) — routes on host, path, HTTP header, HTTP method, query string, source IP. NLB = Layer 4 (TCP/UDP/TLS) — flow hash, ultra-low latency, static IP/EIP per AZ. GWLB = Layer 3 (GENEVE :6081) — for inline appliances (firewalls/IDS/IPS).

How does an ASG connect its instances to an ALB?
?
Via the ASG's `target_group_arns` — the ASG auto-registers its instances into the target group as it launches them and deregisters as it terminates them. The ALB routes to the target group. Do NOT use `aws_autoscaling_attachment` (that's for pre-existing instances) or register targets by hand.

What's the difference between the ALB health check and the ASG `health_check_type`?
?
Two independent systems. The ALB/target-group health check decides ROUTING (stop sending traffic to a target that fails the path+matcher check). The ASG `health_check_type` decides REPLACEMENT: `EC2` (default) = only hypervisor status checks (VM alive?), so a failed ALB check won't replace the instance → zombie. `ELB` = honor the target-group health, so a hung app gets terminated + replaced. They only cooperate if you set `ELB`.

What does a failed ALB health check do — and does it terminate the instance?
?
It only stops the ALB ROUTING traffic to that target. It does NOT terminate anything by itself. Termination is the ASG's job, and only happens if `health_check_type = "ELB"`. Also: users only see errors if NO target is healthy — with ≥1 healthy target the ALB silently routes around the bad one.

What are the three numbers of an ASG and how do they bound scaling?
?
min_size (floor — scale-in never goes below), desired_capacity (the count the ASG holds), max_size (ceiling — scale-out never exceeds). An unhealthy instance is terminated and replaced to restore desired, respecting min/max.

Name the categories of ASG scaling policy.
?
Dynamic (reacts to metrics): target tracking (recommended default), step scaling, simple scaling (legacy). Predictive (ML forecast on historical load). Scheduled (wall-clock time). Target tracking and predictive can be combined.

What does a target-tracking scaling policy manage for you, and how does its scale-out differ from scale-in?
?
It automatically creates and manages the CloudWatch alarms (one high for scale-out, one low for scale-in) — you must NOT hand-edit them. It scales out aggressively and scales in gradually/conservatively because EC2 Auto Scaling prioritizes availability. It cannot scale out when the metric is below target — scale-out needs real load above the target value.

Why must `health_check_grace_period` exceed an instance's time-to-healthy?
?
The grace period is how long the ASG waits after launch before honoring health checks. If it's shorter than boot + bootstrap (e.g. apt install) + health-check convergence (healthy_threshold × interval), the ASG marks the still-booting instance unhealthy, terminates it, and the replacement hits the same wall → a boot loop. Fix: raise the grace period, or bake dependencies into the AMI so instances are healthy fast.

Cross-zone load balancing: default for ALB vs NLB, and the cost difference?
?
ALB: always ON at the load-balancer level (can't disable there), and cross-zone traffic is FREE. NLB (and GWLB): OFF by default, and enabling it means inter-AZ data transfer is BILLED. Exam-frequent distractor.

When do you pick NLB over ALB?
?
NLB for: non-HTTP TCP/UDP, ultra-low latency / millions of connections, a STATIC IP (or EIP) for the load balancer, or preserving the client source IP natively. ALB is DNS-only and adds X-Forwarded-For instead of preserving source IP; ALB wins when you need L7 features (path/host routing, WebSockets, HTTP-aware).

What's the default deregistration delay (connection draining) on a target group?
?
300 seconds. A deregistering target enters `draining`, finishes in-flight requests, then goes to `unused` (after which the ASG may terminate it). Range 0–3600s. If it has no in-flight requests it completes immediately.

In production, which tier goes in public vs private subnets, and what does that force you to add?
?
ALB in PUBLIC subnets (internet-facing), ASG instances in PRIVATE subnets (only the ALB SG can reach them). Because private instances have no inbound internet path, outbound (e.g. apt install, AWS APIs) needs a NAT gateway (billed hourly + per-GB) or VPC endpoints. Baking the AMI can avoid boot-time internet needs entirely.

Why did the ASG still show an instance as "healthy" right after you terminated it out-of-band?
?
Two reasons: (1) the console page is a static snapshot — it needs a manual refresh; (2) manual (out-of-band) termination isn't instant to the ASG — it detects via its periodic health-check cycle (~1–2 min), then launches a replacement. The Activity tab is the authoritative event log (shows Terminating… + Launching…).

What is the launch template vs launch configuration?
?
`aws_launch_template` is the modern instance blueprint an ASG stamps out (AMI, type, SGs, user_data, IAM profile, versioned). The older launch *configuration* is deprecated/immutable — use launch templates.
