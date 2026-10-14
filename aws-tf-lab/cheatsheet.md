---
tags: [exam-prep, cheatsheet]
---

# 📌 Cheatsheet — the exact facts

Tier 3 of three. **[[README|Notes]]** explain how things work; the
**decision pages** route you to which service; this one answers only
*"what is the exact fact?"* — numbers, limits, defaults, and the
three-word discriminators you blank on under pressure.

Nothing here explains itself. If a line surprises you, follow it back.

## Contents

- [[#IAM & Identity|IAM & Identity]]
- [[#EC2, EBS & AMIs|EC2, EBS & AMIs]]
- [[#Load Balancing & Auto Scaling|Load Balancing & Auto Scaling]]
- [[#VPC & Hybrid Networking|VPC & Hybrid Networking]]
- [[#RDS, Aurora & ElastiCache|RDS, Aurora & ElastiCache]]
- [[#S3|S3]]
- [[#Route 53 & CloudFront|Route 53 & CloudFront]]
- [[#EFS, FSx, Gateway & Transfer|EFS, FSx, Gateway & Transfer]]
- [[#Cost & Disaster Recovery|Cost & Disaster Recovery]]
- [[#Messaging & Streaming|Messaging & Streaming]]
- [[#Containers & Serverless|Containers & Serverless]]
- [[#Monitoring & Security|Monitoring & Security]]
- [[#Analytics, ML & Other Services|Analytics, ML & Other Services]]


## IAM & Identity

**STS & role sessions**

| | |
|---|---|
| Temporary credential lifetime on AssumeRole | Default 1 hour, maximum 12 hours |
| API for SAML 2.0 federation to IAM | sts:AssumeRoleWithSAML |
| API for OIDC / web identity federation | sts:AssumeRoleWithWebIdentity |

**IAM DB authentication**

| | |
|---|---|
| IAM database auth token lifetime | 15 minutes |
| IAM action to log in to a database | rds-db:connect on arn:aws:rds-db:…:dbuser:… — NOT the rds: management prefix |
| Engines supporting IAM database authentication | RDS MariaDB/MySQL/PostgreSQL, Aurora MySQL/PostgreSQL — not Oracle, not SQL Server |
| Creating the IAM-auth DB user | MySQL/MariaDB: IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS'; PostgreSQL: GRANT rds_iam |
| Command that mints the RDS auth token | aws rds generate-db-auth-token (SigV4-signed, passed as the password) |
| Secrets Manager rotation mechanism | App creds: Lambda rotation function. RDS/Aurora master user: managed rotation, no Lambda |
| IAM action to read a secret | secretsmanager:GetSecretValue |

**IAM policy evaluation**

| | |
|---|---|
| The three evaluation states | Implicit deny (default) → explicit Allow lifts it → explicit Deny overrides everything |
| simulate-principal-policy verdict values | allowed / implicitDeny / explicitDeny (S3 403s name which, same account/org only) |
| Does order, count or specificity matter? | No to all three — no specificity rule exists in IAM (that is NTFS ACLs) |

**Policy types & limits**

| | |
|---|---|
| Managed policy versions retained | Up to 5 versions, can roll back; inline policies have no versioning |
| AWS-managed policy ARN namespace | arn:aws:iam::aws:policy/… (customer-managed live in your account namespace) |
| Inline vs managed policy lifecycle | Inline dies with the principal, one principal only; managed is standalone and reusable |
| ListBucket scoping | `s3:ListBucket` is a **bucket-level** action — it takes the bare bucket ARN (`arn:aws:s3:::bucket`), **no `/*`**; object actions (`s3:GetObject`/`PutObject`) need `/*`. Getting it wrong fails silently. Restricting a listing to one folder is a **condition on `s3:prefix`** (`StringLike: {"s3:prefix": ["Development/*"]}`), optionally with `s3:delimiter` = `/` to force folder-style listing — verified 2026-10-06. Browsing in the **console** additionally needs `s3:ListAllMyBuckets` and `s3:GetBucketLocation`, and a root-level view needs `s3:prefix` = `""`. |

**IAM groups**

| | |
|---|---|
| Can IAM groups be nested? | No — user groups can contain only users, not other groups |
| Can an IAM group be a policy Principal? | No — groups relate to permissions, not authentication; no federated identity can land in one |

**IAM basics**

| | |
|---|---|
| IAM region scope and cost | Global (no region picker) and free; STS calls free; IAM Identity Center free |
| Consistency model for new IAM objects | Eventually consistent — a few seconds to become globally visible |
| Access Analyzer — what bills | Free: external-access findings, policy validation, policy generation. Bills: unused access, internal access, custom checks |
| EC2 vs Lambda/ECS role attachment | EC2 needs an instance profile wrapper; Lambda and ECS take a role directly |
| Trust vs permissions policy failure modes | No trust policy = nobody can assume it; no permissions policy = assumes fine, does nothing |

**Cross-account access**

| | |
|---|---|
| ExternalId — who generates it, is it secret? | The third party generates it (one per customer); not a secret, only unique |
| ExternalId condition key | sts:ExternalId |
| GitHub Actions OIDC provider URL and audience | URL https://token.actions.githubusercontent.com, audience sts.amazonaws.com |
| GitHub OIDC sub claim format | repo:<org>/<repo>:ref:refs/heads/main |

**Federation & Directory Service**

| | |
|---|---|
| AD Connector — does it store directory data in AWS? | No — proxies sign-in to on-prem DCs, no sync, no data in AWS |
| Simple AD — what it does NOT support | No trusts, no MFA, no schema extensions/LDAPS, not compatible with RDS for SQL Server |
| Which directory works with RDS for SQL Server | AWS Managed Microsoft AD or self-managed AD — not AD Connector or Simple AD |
| IAM Identity Center — former name | Successor to AWS SSO (renamed); AD groups map to permission sets, which become IAM roles |
| Permission sets and instance type | Need an organization instance in the management account — account instances do not support permission sets |

**Organizations**

| | |
|---|---|
| OU hierarchy depth | Five levels deep below the root; one root per organization |
| Invitation expiry for existing accounts | 15 days; sendable only from the management account; an account joins only one org |
| Management account mutability | Cannot be changed after the organization is created; it is the payer |
| Feature sets | All features (required for SCPs/RCPs) and Consolidated billing only |
| Built-in cross-account admin role | OrganizationAccountAccessRole — auto-created for accounts Organizations creates, NOT for invited accounts |

**SCPs**

| | |
|---|---|
| Actions SCPs cannot restrict | Management account, service-linked roles, root-only: Enterprise Support signup, CloudFront trusted signers, reverse DNS |
| Effect of disabling the SCP policy type | Detaches every SCP, and those attachments are not recoverable — reattach manually |
| Root-user asymmetry | Management account entirely exempt from SCPs; a member account's root user IS capped |
| Allow vs Deny placement in the chain | Allow must exist at EVERY level root→OU→account; Deny at ANY level kills everything beneath |
| FullAWSAccess default | Auto-attached to every root, OU and account; removing it without replacement blocks all actions in that subtree |

**Permissions boundaries**

| | |
|---|---|
| How policy types combine | identity+resource = **UNION, but only within one account**; identity+boundary = INTERSECTION; identity+SCP = INTERSECTION. **Cross-account is evaluated twice** — the caller's identity policy *and* the resource policy must both allow it |
| Boundary implicit deny vs resource policy | Same acct: RBP grant to a user/session ARN escapes it, role ARN doesn't; explicit Deny wins |
| What can carry a permissions boundary | Users and roles — not groups; it takes a managed policy ARN and grants nothing |

**Condition keys**

| | |
|---|---|
| MFA condition operator | BoolIfExists — aws:MultiFactorAuthPresent is absent for long-term access keys |
| IP condition through a VPC endpoint | aws:SourceIp is absent — use aws:VpcSourceIp, aws:SourceVpce or aws:SourceVpc |
| Trust a whole org in one resource policy | aws:PrincipalOrgID |
| ABAC condition keys | aws:PrincipalTag/x, aws:ResourceTag/x, aws:RequestTag/x |

**Control Tower**

| | |
|---|---|
| Control types and their implementation | Preventive = SCP/RCP/declarative; detective = Config rules; proactive = CFN hooks |
| SCP vs RCP scope | SCP limits principals in member accounts; RCP limits resources — both need Organizations all features |

| Identity store **not** SAML 2.0 compatible | Build a **custom identity broker** on-prem: it authenticates against the existing system (*"which might use LDAP, Active Directory, or another system"*), then calls **STS** — *"either `AssumeRole` or `GetFederationToken`"* — and hands the temporary credentials to the app. Not Identity Center (needs a supported identity source), not an IAM policy referencing LDAP identifiers. The one exam scenario where "write a custom application" is correct |

↳ [[01-iam]] · [[01-iam-advanced]]


## EC2, EBS & AMIs

**EBS "Delete on termination"**

| | |
|---|---|
| Extra EBS data volume — *Delete on termination* default | **Console** at launch, or attached after launch: **Preserve** (false). At launch via **CLI/API**: **Delete** (true). Answer `false` on the exam; set it explicitly in practice |
| Data volume attached at launch via CLI/API — default | Delete |
| Data volume added via console at launch, or attached after launch | Preserve |
| Additional EBS volume default | false via console or after launch (survives, bills); CLI at launch: true |
| Root volume default | true — deleted with the instance |

**T-family CPU credits**

| | |
|---|---|
| t3.micro max banked CPU credits | 288 (24h of earnings) |
| t3.micro CPU credit earn rate | 12 CPU credits/hour |
| T-family baseline CPU | **Varies by size** — baseline % per vCPU = (credits earned per hour ÷ vCPUs) ÷ 60. `t3.nano` **5%** (6 credits/hr ÷ 2 vCPUs ÷ 60), `t3.micro` **10%**, `t3.small`/`medium` **20%**, `t3.large` **30%**, `t3.xlarge`/`2xlarge` **40%**. Never quote one size's baseline for the family. (Corrected 2026-10-05 — this row said 2.5%, which the formula beside it disproves.) |
| T3 default credit mode | **unlimited** (T2: standard). Free if 24h average CPU ≤ baseline; unpaid surplus bills per vCPU-hour, incl. at stop/terminate |
| Metric to alarm on for surplus billing | CPUSurplusCreditsCharged |
| Burstable CloudWatch metrics (4) | CPUCreditUsage, CPUCreditBalance, CPUSurplusCreditBalance, CPUSurplusCreditsCharged |
| Standard mode at zero credit balance | pinned at baseline (~10% CPU on t3.micro) — CPUCreditBalance flatlined at 0 |

**IMDS**

| | |
|---|---|
| IMDSv2 PUT response IP hop limit | default 1 (2 on v2.0 AMIs); use 2 for containers |
| IMDSv2 token max lifetime | up to 6h, and instance-specific |
| IMDSv2 token request header name | X-aws-ec2-metadata-token-ttl-seconds (on the PUT); example value 21600 |
| IMDSv2 header carried on every GET | X-aws-ec2-metadata-token |
| IMDSv2 rejects a PUT carrying which header? | X-Forwarded-For |
| Symptom of skipping the IMDSv2 token | empty / 401, silently — not a permissions error |
| IMDS endpoint address | 169.254.169.254, link-local, reachable only from inside the instance |
| Token flow order | PUT /latest/api/token first, then GET with the token header |
| IMDSv1 vs IMDSv2 default | both allowed; v2 required if AMI has ImdsSupport=v2.0 (AL2023) or account default set |

**EC2 free tier & billing**

| | |
|---|---|
| Free tier — accounts created before 15 Jul 2025 | t2.micro/t3.micro, 750 hrs/month, 12 months |
| Free tier — accounts created on/after 15 Jul 2025: types | t3.micro, t3.small, t4g.micro, t4g.small, c7i-flex.large, m7i-flex.large |
| Free tier — newer plan credits and expiry | **$100 on sign-up, plus up to $100 more earned by using foundational services** (not granted up front); ends at **6 months or when the credits run out**, whichever comes first |
| OS still billed as a full hour, not per second | SLES |
| On-Demand billing granularity | per second after a 60-second minimum — Linux, Windows, RHEL/Ubuntu Pro |

**Public IPv4 & EIP**

| | |
|---|---|
| Currency warning — "EIP is free while attached" | Retired: since Feb 2024 every public IPv4 bills hourly, auto-assigned or Elastic, attached or not |
| Elastic IP limit per region | soft 5, raisable |
| Which wins, the subnet's auto-assign public IPv4 setting or the instance's? | The instance's setting at launch overrides the subnet default, in either direction |
| Auto-assigned public IP vs Elastic IP across stop/start | auto-assigned is released and changes; EIP is yours and persists |
| EIP IPv6 equivalent | none — IPv4 only |

**EBS vs instance store**

| | |
|---|---|
| EBS max IOPS ceiling | up to ~256K IOPS (io2 Block Express) |
| EBS Multi-attach — types and instance count | io1/io2 only, up to 16 instances, same AZ |
| When instance store data is lost | on stop AND on terminate (and host failure) — it is host-scoped, not instance-scoped |
| EBS scope vs snapshot scope | volume is AZ-scoped; snapshot is region-scoped |
| Only way to move an EBS volume across AZs | snapshot then restore in the target AZ — detach/attach cannot cross AZ |

**Stop vs terminate**

| | |
|---|---|
| Instance after terminate | permanently deleted — can't be started or recovered |
| Private IP on stop vs terminate | preserved on stop; released on terminate |
| EIP on terminate | disassociated; the EIP is retained in your account |
| Only way to move an instance to another AZ | snapshot and relaunch — stop/start cannot change AZ |

**Instance types**

| | |
|---|---|
| Family letters | t burstable, m general, c compute, r memory, g/p GPU, i storage |
| Generation suffixes a and g | t3a = AMD, t4g = Graviton/ARM |
| Instance type separator | `family.size` with a **literal period** — `t3.micro`. A hyphen (`t3-micro`) is **rejected** |
| Instance-type change vs AMI change | Instance type: **stop-modify-start**. **Kept:** instance ID, EBS volumes, Elastic IP. **Lost/changed:** an **auto-assigned public IPv4** changes and **instance-store data is destroyed**. AMI: **root volume replacement** on the same instance, or launch a new one |

**AMI**

| | |
|---|---|
| AMI scope and how to move one | region-scoped — ami-… is unique per region; copy with aws ec2 copy-image |
| What an EBS-backed AMI actually is | metadata (kernel, architecture, virtualization type) plus references to EBS snapshots |

**EC2 identity**

| | |
|---|---|
| What EC2 is handed — role or instance profile? | instance profile wrapping the role; Lambda and ECS take a role directly |

**AMI baking (Packer)**

| | |
|---|---|
| Deleting an AMI leaves what behind? | backing snapshot by default — add --delete-associated-snapshots (skipped if another AMI uses it) |
| Ready time baked vs user_data | lab only: ~30 s vs 2–5 min |
| AWS-native managed equivalent of a Packer pipeline | EC2 Image Builder — test-before-distribute, multi-region, cross-account via AWS RAM, STIG components |
| Installing AWS CLI v2 on Linux | AWS's official installer or the AWS-maintained snap; distro repos may lag |

| `gp2` baseline IOPS formula | **3 IOPS per GiB**, floor **100** (volumes ≤33.33 GiB), ceiling **16,000** reached at **5,334 GiB**. So 250 GiB → 750 baseline, 1,000 GiB → 3,000 |
| `gp2` burst | Volumes **smaller than 1 TiB** (provisioned <3,000 IOPS) burst to **3,000 IOPS** on I/O credits. Accrue 3/GiB/s, cap **5.4 M** = *"at least 30 minutes"* at full burst; every volume starts full. Watch `BurstBalance`. **A ≥1 TiB gp2 volume does not burst at all** |
| `gp2` throughput by size | ≤170 GiB → 128 MiB/s · >170 and <334 GiB → bursts to 250 · ≥334 GiB → 250 MiB/s |
| `gp3` vs `gp2` performance model | gp3 **does not burst** — *"can indefinitely sustain their full provisioned IOPS"*. **3,000 IOPS + 125 MiB/s included at any size**; buy up to **80,000** IOPS at **500 IOPS/GiB** (80,000 needs just **160 GiB**) and 2,000 MiB/s. 20% cheaper per GiB |
| "peaks at 3,000 IOPS, used occasionally" | **gp2/gp3, not io1/io2** — 3,000 is exactly gp2's burst ceiling and gp3's included baseline. The io-series trigger words are **sustained**/**consistent**, not *peak* |

↳ [[02-ec2]] · [[03-ami-bake]]


## Load Balancing & Auto Scaling

**ALB vs NLB vs GWLB**

| | |
|---|---|
| GWLB — layer and protocol/port | Layer 3, GENEVE port 6081; for inline firewall/IDS/IPS appliances |
| Cross-zone load balancing — NLB/GWLB default | Off by default; enabling it means inter-AZ data transfer is billed |
| Cross-zone load balancing — ALB default | Always on at LB level, cannot disable there (only override off per target group); free |
| Minimum AZs for an ALB | At least 2, enforced; NLB 2+ recommended but not strictly required |
| PrivateLink endpoint service — which LB fronts it | NLB or GWLB, never an ALB directly |
| Putting an ALB behind an NLB | Target group of type **Application Load Balancer**, protocol TCP, one ALB per target group |
| Static IP — ALB vs NLB | ALB: DNS name only. NLB: one static IP per AZ, can attach an EIP |
| Client source IP — ALB vs NLB | ALB: X-Forwarded-For. NLB: kept for instance targets; IP-type TCP/TLS off by default |
| NLB flow hash inputs | Settled 2026-10-05 — AWS lists all four: *"The protocol, The source IP address and source port, The destination IP address and destination port, The TCP sequence number."* GWLB uses a 5-tuple flow hash |
| ALB layer and routing conditions | Layer 7; routes on host, path, header, method, query-string, source-IP |

**ALB listener rules & redirect**

| | |
|---|---|
| Redirect — must change at least one of | Protocol, hostname, port or path — otherwise it is a redirect loop |
| Redirect reserved keywords | #{protocol}, #{host}, #{port}, #{path}, #{query} |
| Redirect direction not allowed | HTTPS→HTTP. HTTP→HTTPS, HTTP→HTTP, HTTPS→HTTPS are all allowed |
| Redirect status codes | HTTP_301 (permanent), HTTP_302 (temporary) |
| Allowed terminal actions for a rule | Exactly one of forward, redirect, or fixed-response |
| Redirect HTTP→HTTPS on an NLB | Impossible — Layer 4 cannot inspect or rewrite HTTP |

**Target group**

| | |
|---|---|
| Default routing algorithm | **ALB target group**: round robin (also least outstanding requests, weighted random). **NLB does not use it** — NLB distributes by flow hash |
| Deregistration delay default | 300 seconds |
| Deregistration delay range | 0–3600 seconds |
| Draining target state transition | draining → unused, then the ASG may terminate it |

**Health checks (ALB vs ASG)**

| | |
|---|---|
| ASG health check type default | **EC2** — status checks + scheduled events; ELB results ignored until **ELB** is turned on |
| Which check decides what | Target-group health check = **routing**; ASG health check type = **replacement** |
| Does the ALB terminate an unhealthy instance | No — it only stops routing; termination is the ASG's job, and only when its health check type is **ELB** |
| When a failed health check is user-visible | Only when NO targets are healthy; with ≥1 healthy the ALB routes around it silently |
| Time to ELB-healthy with boot-time apt install | Measure from **`InService`**, not from launch — the grace-period clock starts *"after it enters the `InService` state"*. What must fit inside it: remaining bootstrap (~60s for an apt install) **plus one health-check interval** (~30s), so ~90s. (Corrected 2026-10-05.) |
| Health-check convergence arithmetic | **A newly registered target needs ONE passing check**: *"After your target is registered, it must pass one health check to be considered healthy."* `HealthyThresholdCount` (default **5**) is for bringing an **already-unhealthy** target back; `UnhealthyThresholdCount` (default **2**) × 30s ≈ 60s to pull a healthy one. Thresholds 2–10, interval 5–300s, timeout 2–120s. (Corrected 2026-10-05 — this row previously said 5 × 30s = 150s to *become* healthy.) |
| Safe health check grace period values | ~300s with a boot-time install; ~40s time-to-healthy with a baked AMI |

**Target tracking**

| | |
|---|---|
| Predefined metrics | ASGAverageCPUUtilization, ASGAverageNetworkIn, ASGAverageNetworkOut, ALBRequestCountPerTarget |
| Alarms it auto-creates for a CPU target of 50 | AlarmHigh at 50% (out), AlarmLow below it (in; no published value) — AWS-managed |
| Can lowering the target value force a scale-out | Yes, if the new target is below the current metric; otherwise only scale-in can follow |
| Scale-out vs scale-in behaviour | Scales out aggressively, scales in gradually — prioritises availability |

**Scale-in termination order**

| | |
|---|---|
| Step evaluated before any termination policy | AZ with the most instances that has ≥1 instance unprotected from scale-in (zonal balance wins) |
| Default policy — outdated-configuration order | (1) launch configuration, (2) different launch template, (3) oldest version of current template |
| Default policy tiebreakers, in order | Closest to next billing hour, then random |
| Instances that skip the termination policy | Unhealthy ones — replaced regardless of policy |
| Policy for true oldest-instance behaviour | OldestInstance — a separate policy you opt into; default is ["Default"] |
| OldestLaunchTemplate policy terminates | Noncurrent launch template first, then oldest version of the current one |
| ASG detection lag after out-of-band termination | Next periodic check (~1–2 min in lab, no AWS figure); Activity tab is authoritative |

**Scheduled scaling**

| | |
|---|---|
| Max scheduled actions per ASG | 125; names unique per group, each action needs a unique start time |
| Scheduled action execution delay | May be delayed up to 2 minutes |
| Process to suspend to pause all schedules | ScheduledActions |
| Cron format and default time zone | 5-field [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week], UTC unless an IANA time_zone is set |
| When min/max must be supplied with a schedule | When the new desired capacity would fall outside the group's current limits |

**ELB cost & currency**

| | |
|---|---|
| Legacy ELB free tier — who no longer gets it | Accounts opened since 2025-07-15 get the credits-based Free plan instead |
| Legacy ELB free tier allowance | 750 LB-hrs/month (**shared with Classic LBs**) + 15 LCUs. ⚠️ Dated pricing — check current; accounts opened since 2025-07-15 get the credits-based Free plan instead, so an ALB spends credits from hour one |
| Launch configuration status | Deprecated predecessor to launch templates |

↳ [[04-alb-asg]]


## VPC & Hybrid Networking

**VPC addressing**

| | |
|---|---|
| Which 5 IPs AWS reserves in every subnet | .0 network, .1 VPC router, .2 DNS, .3 future use, last address broadcast |
| Usable IPs in a /24 subnet | 251, not 256 |
| Allowed VPC CIDR size range | /16 to /28 |
| Scope of a subnet vs a VPC | Subnet = exactly one AZ; VPC = one region |

**Routing & IGW**

| | |
|---|---|
| Route table used by a subnet you never associated | The VPC's main route table |
| Public subnet vs internet-reachable instance | Subnet public = route to IGW; instance also needs a public IP/EIP |
| IGW count, direction and cost | One per VPC, bidirectional, no bandwidth limit, free (pay data transfer only) |

**NAT**

| | |
|---|---|
| NAT gateway bandwidth | 5 Gbps, scaling automatically to 100 Gbps |
| NAT gateway security group | None — there is nothing to attach |
| The one IPv6 job a NAT gateway does | NAT64 (always on), paired with DNS64 on the subnet |
| NAT instance's required non-default setting | Source/destination check disabled (legacy option; gateway has no equivalent) |
| Which subnet the NAT gateway lives in | Zonal NAT gateway (the exam's answer): **a public subnet**. Newer regional NAT gateway: no subnet |
| NAT gateway resilience scope | Zonal (the exam's answer): one AZ — **one per AZ for HA**. Newer regional NAT gateway: one ID spans AZs |
| Outbound-only internet for IPv6 | Egress-only Internet Gateway, at the VPC edge |

**VPC defaults**

| | |
|---|---|
| The 3 things auto-created with every VPC | Main route table, default NACL (allow all in/out), default SG (self-referencing inbound) |
| Default NACL vs a custom NACL you create | Default allows all in and out; custom denies all in and out |
| Default SG vs a new SG you create | Default self-references inbound; new SG denies inbound. Both allow all outbound |

**SG vs NACL**

| | |
|---|---|
| Max security groups per ENI | 5 by default, raisable to 16 |
| NACLs per subnet | Exactly one (the default if you associate none) |
| What a rule source can be | SG: CIDR or another SG. NACL: CIDR only |
| Which one can deny | NACL can allow and deny; SG is allow-only |
| Stateful vs stateless, and level | SG stateful at the ENI; NACL stateless at the subnet |

**NACL rules**

| | |
|---|---|
| Custom NACL rule number range | 1–32766, evaluated ascending, first match wins, plus an unremovable * deny |
| OS-specific ephemeral port ranges | AWS's figures: many **Linux** kernels `32768–61000`; **Windows Server 2008+** `49152–65535`; **ELB / Lambda / NAT gateway** `1024–65535`. AWS's example NACL uses `32768–65535`; `1024–65535` is the safe superset |
| Which direction the ephemeral rule goes | Receiving requests → outbound; initiating requests → inbound |
| Ephemeral range to open on a NACL | 1024–65535 |
| Traffic a NACL cannot filter at all | Amazon DNS, DHCP, IMDS, ECS metadata, Windows activation, Time Sync, router IPs |

**Flow Logs**

| | |
|---|---|
| Maximum aggregation interval | **600s (10 min) default**, or **60s** — the two documented values |
| Delivery lag on top of the aggregation interval | Settled 2026-10-05 — AWS **does** publish it: *"typically delivers logs to CloudWatch Logs in about 5 minutes and to Amazon S3 in about 10 minutes"*, on a *"best effort basis"*. Also: on a **Nitro** instance the aggregation interval is always ≤1 minute regardless of the setting — but **T2 is current-gen and Xen**, so on a t2.micro the 600s default is real |
| Protocol numbers in a flow log record | 6 = TCP, 17 = UDP, 1 = ICMP |
| Traffic never logged by flow logs | Amazon DNS (custom DNS is logged), DHCP, 169.254.169.254, 169.254.169.123, Windows activation, VPC router IP |
| Third destination, and its rename | Amazon Data Firehose — renamed from Kinesis Data Firehose; older material uses the old name |
| Attachment levels | VPC, subnet, or ENI |
| What they contain vs never contain | Connection metadata + ACCEPT/REJECT; never payload (that's Network Firewall / Traffic Mirroring) |

**Network Firewall**

| | |
|---|---|
| Rule engine it is built on | Suricata — stateful IPS, deep packet inspection + domain filtering |
| Where the endpoint sits | Dedicated firewall subnet + route redirect, or attached directly to a TGW |

**VPC endpoints**

| | |
|---|---|
| Where a gateway endpoint cannot be reached from | A peered VPC, VPN, or Direct Connect — same VPC only |
| Default endpoint policy | Full access (some interface-endpoint services support no policy at all) |
| Services with a gateway endpoint, and its cost | S3 and DynamoDB only; free |
| What an interface endpoint actually is | An ENI with a private IP (PrivateLink), secured by endpoint policy + a security group |

**Peering & TGW**

| | |
|---|---|
| Full-mesh peering formula | N(N-1)/2 (5→10, 6→15, 10→45, 12→66) |
| The three peering limits | Non-transitive, no overlapping CIDRs, no edge-to-edge (peer's IGW/NAT/VPN/DX/gateway endpoint) |
| Transit Gateway shape and scale | Regional hub, one attachment per VPC/VPN/DX, transitive, scales to thousands of attachments |
| VPC sharing — what actually gets shared | **One or more subnets**, never the whole VPC. Owner shares via **AWS RAM** to participant accounts in the **same Organization**; participants launch their own EC2/RDS/Redshift/Lambda in them and can't see each other's resources. Peering stays the owner's job. |
| Many accounts, one network — which of the three | **Same Organization, lowest complexity, one network → VPC sharing.** Two separate VPCs → peering. Many VPCs / hybrid at scale → Transit Gateway. "Share the VPC" and "peer the subnets" are both wrong wordings. |

**Hybrid — VPN**

| | |
|---|---|
| Tunnels per Site-to-Site VPN connection | Always 2 |
| Standard VPN tunnel throughput | Up to ~1.25 Gbps per tunnel |
| What a Customer Gateway object holds | The on-prem router's public IP + BGP ASN |
| VPN CloudHub | VGW as a hub-and-spoke point for multiple branch offices, over BGP |
| VGW vs CGW | VGW = AWS side (on the VPC); CGW = config object describing your on-prem router |
| Client VPN vs Site-to-Site | Client VPN = OpenVPN for individual laptops; Site-to-Site = IPsec, whole networks |

**Hybrid — Direct Connect**

| | |
|---|---|
| Hosted DX connection speeds | Fixed steps **50/100/200/300/400/500 Mbps and 1/2/5/10/25 Gbps** via a partner. It is the only route to a **sub-1 Gbps** link (dedicated starts at 1 Gbps) — but it is **not** capped below 1 Gbps |
| How to encrypt Direct Connect | Site-to-Site VPN over DX (IPsec over a public VIF), or MACsec on supported ports |
| The three VIF types and where they land | Private → one VPC (via VGW); Public → AWS public services; Transit → TGW (via DXGW) |
| Direct Connect Gateway reach and limit | Global fan-out to multiple VGWs/TGWs across regions and accounts; non-transitive |
| Dedicated DX port speeds | 1 / 10 / 100 Gbps (400 on some) |
| DX encryption by default | Not encrypted |
| Setup time, VPN vs DX | VPN minutes–hours; DX weeks–months |

↳ [[05-vpc-core]] · [[05-vpc-endpoints-peering]] · [[05-vpc-hybrid]] · [[05-vpc-security]]


## RDS, Aurora & ElastiCache

**IAM DB auth**

| | |
|---|---|
| Extra instance memory needed for IAM DB auth | 300–1000 MiB |
| Global condition keys that DON'T work with IAM DB auth | aws:SourceIp, aws:SourceVpc, aws:SourceVpce, aws:UserAgent, aws:Referer, aws:VpcSourceIp |
| Auth token minimum size | ~1 KB minimum — tools that truncate long passwords break it |
| Does CloudTrail log generate-db-auth-token? | No — CloudTrail and CloudWatch do not log it |
| IAM action name and prefix | rds-db:connect — the only action with the rds-db: prefix (rds: is the management API) |
| Token lifetime | 15 minutes — a connection-time limit, not a session limit |
| dbuser ARN shape | arn:aws:rds-db:{region}:{account-id}:dbuser:{DbiResourceId}/{db-user-name} |
| Which id goes in the ARN | DbiResourceId (db-ABC…), not the DB identifier; Aurora = DbClusterResourceId; RDS Proxy = prx- |
| DB-side mapping per engine | MySQL: AWSAuthenticationPlugin · PostgreSQL: GRANT rds_iam TO <user> |
| Supported engines | MariaDB, MySQL, PostgreSQL (and Aurora MySQL/PostgreSQL) |
| Transport encryption | **IAM DB auth: traffic is SSL/TLS.** Native password or Secrets Manager: TLS **optional** — you must require it |
| PostgreSQL rds_iam role precedence | IAM auth takes precedence over password auth for that user; no IAM + Kerberos together |
| Default state of the feature | Off by default |

**Aurora storage**

| | |
|---|---|
| Cluster volume auto-scaling range | Grows automatically to 128 TiB (256 TiB on newer engine versions) |
| Copies and AZ spread | 6 copies across 3 AZs — 2 per AZ, one shared cluster volume |
| Loss tolerance | Loses a whole AZ with no data loss, brief interruption |

**Aurora features**

| | |
|---|---|
| Aurora replica lag | Usually much less than 100 ms (rises with write rate) |
| Global Database secondary regions | 1 primary + up to 10 read-only secondary regions, <1s replication |
| The four endpoint types | writer/cluster, reader (LB'd reads), custom, instance |
| Serverless v2 capacity unit and instance class | Capacity is measured in **ACUs**, settable from **0 to 256 ACUs in increments of 0.5** (the allowed minimum depends on the Aurora version; 0 means auto-pause). Each ACU ≈ **2 GiB RAM** plus matching CPU/network. The DB instance class is **always `db.serverless`**. |
| Backtrack engine support | Aurora MySQL only — rewinds the DB in place, no restore |
| Throughput claim vs stock engines | Up to 6× MySQL and PostgreSQL (older: 5×/3×) |
| Engine compatibility | MySQL/PostgreSQL-compatible only |
| Max Aurora replicas, and how failover is ordered | 15; automatic failover ordered by priority tiers |

**RDS Multi-AZ & replicas**

| | |
|---|---|
| Multi-AZ failover time and mechanism | ~60–120 seconds via DNS CNAME swap |
| Multi-AZ DB cluster vs DB instance deployment | DB instance: 1 unreadable standby · DB cluster: 2 standbys that DO serve reads |
| Max read replicas per source | 15 — the same cap as Aurora, so count is not the discriminator |
| Multi-AZ vs read replica, three words | Multi-AZ synchronous unreadable auto-failover; replica asynchronous readable manual-promote |
| Is Multi-AZ Free-Tier? | No — doubles cost, not Free-Tier |

**RDS backups & restore**

| | |
|---|---|
| Transaction log shipping interval | Roughly every 5 minutes |
| Automated backup retention range | 1–35 days |
| PITR granularity | Any second inside the retention window |
| What survives instance deletion | Manual snapshots survive; automated backups don't, unless Retain automated backups or a final snapshot |
| What a restore produces | Always a new instance with a new endpoint — never in place |

**RDS encryption**

| | |
|---|---|
| When encryption at rest can be set | At creation only |
| Steps to encrypt an existing unencrypted DB | Snapshot → copy the snapshot with encryption → restore (new endpoint) |

**RDS free tier**

| | |
|---|---|
| Legacy RDS Free Tier cutoff and allowance | Accounts activated before 2025-07-15: db.t2/t3/t4g.micro, single-AZ, 750 hrs/mo, 20 GB, 12 months |
| Free Plan backup retention (lab only) | Our lab: 7 rejected, 1 accepted; no AWS doc found |

**ElastiCache engines**

| | |
|---|---|
| Threading, per engine | Redis/Valkey: single main thread; Memcached multi-threaded |
| Auto Discovery availability | Memcached only — AWS states it is NOT available for Valkey or Redis OSS |
| Auto Discovery client requirement | An ElastiCache client library with Auto Discovery support |
| Memcached persistence | Node-based: no replication, failover, persistence or backup (Serverless can back up) |
| What Memcached lacks, exactly | Node-based: no replication/failover/persistence/backup |
| Valkey, one line | Open-source Redis fork; has all Redis OSS 7.2 features (neither has Auto Discovery) |

**ElastiCache Redis HA**

| | |
|---|---|
| Replication group size | 1 primary + up to 5 read replicas |
| Minimum nodes for auto-failover / Multi-AZ | **2** — Multi-AZ with automatic failover requires a cluster **with at least one replica**, so 1 primary + 1 replica. Max **5** read replicas per shard |
| Redis port | Valkey/Redis OSS default 6379; Memcached default 11211 |

**Caching strategies**

| | |
|---|---|
| Other name for lazy loading | Cache-aside — populates only on a miss |
| Write-through, in three words | Writes cache and DB together — always fresh, slower writes |
| Cache hit latency vs DB read | Microseconds (sub-millisecond) vs milliseconds |

↳ [[07-rds-aurora]] · [[08-elasticache]]


## S3

**S3 storage classes**

| | |
|---|---|
| Minimum storage duration by class | Standard/Int-Tiering none · Standard-IA & One Zone-IA 30 d · Glacier Instant & Flexible 90 d · Deep Archive 180 d |
| Minimum billable object size | 128 KB for Standard-IA, One Zone-IA, Glacier Instant; none for Standard / Intelligent-Tiering |
| Availability (designed for) per class | Standard 99.99 · Std-IA / Int-Tiering / Glacier Instant 99.9 · One Zone-IA 99.5 · Flexible & Deep 99.99 post-restore |
| Intelligent-Tiering auto-move thresholds | Frequent → Infrequent at 30 d no access → Archive Instant Access at 90 d; objects <128 KB not monitored |
| Glacier Flexible vs Deep Archive retrieval times | Flexible: Expedited 1–5 min (**objects under 250 MB**; bigger ones stream at up to 300 MB/s), Standard 3–5 h, Bulk 5–12 h · Deep Archive: no Expedited, Std ~12 h, Bulk ~48 h |
| One Zone-IA vs Standard-IA | Same 11 nines; One Zone-IA = 1 AZ, 99.5% availability, re-creatable data only |
| Glacier Instant Retrieval speed | Milliseconds — no restore job at all |
| Durability and AZ count | **"Designed for"** 99.999999999% (11 nines) on every current class; **≥3 AZs**. One Zone classes: **1 AZ**, same 11 nines **but the data is lost if that AZ is destroyed**. Legacy exception: Reduced Redundancy Storage, **99.99%**. Also outside the ≥3-AZ picture: **S3 on Outposts**, which stores on a single on-premises Outpost and is absent from AWS's durability table altogether |

**S3 encryption**

| | |
|---|---|
| SSE-C availability change | Disabled by default since **April 2026** on all new general-purpose buckets **and** on existing buckets in accounts that held **no** SSE-C objects. Re-enable deliberately via `PutBucketEncryption` (the `BlockedEncryptionTypes` field — distinct from the default-algorithm setting). Existing SSE-C objects still read fine with the key |
| DSSE-KMS | Two independent AES-256 layers |
| Which options can be bucket default encryption | SSE-S3, SSE-KMS, DSSE-KMS — never SSE-C (the key arrives with the request, so there is nothing to hold). Separate setting, same API: whether the bucket **accepts** SSE-C writes at all |
| Client-side encryption — current naming | **Amazon S3 Encryption Client** + a **wrapping key** (a KMS key you own, or an AES/RSA key you hold). Older names still in question banks: *CSE-KMS* and *CSE with a client-side master key*. The Encryption Client ignores **S3 Bucket Keys** even with a KMS wrapping key |
| Re-encrypt objects already in the bucket | S3 Batch Operations → Copy (changing the default only affects new writes) |
| Encryption automatic since when | SSE-S3 on every new upload since 5 Jan 2023 |
| Header value: SSE-S3 vs SSE-KMS | AES256 = SSE-S3; aws:kms = SSE-KMS |
| Cut SSE-KMS request cost | S3 Bucket Keys — short-lived bucket-level data key |
| Condition key that enforces TLS | aws:SecureTransport = false (deny it in the bucket policy) |

**S3 Object Lock**

| | |
|---|---|
| Object Lock delete asymmetry | DELETE with a version id → 403 AccessDenied; DELETE without → 200 OK + delete marker |
| GOVERNANCE mode bypass requirements | s3:BypassGovernanceRetention + header x-amz-bypass-governance-retention:true |
| Retention vs legal hold | Retention = a *Retain Until Date*, **fixed** (date up front) or **variable** (event hold + duration; S3 fixes the date at release + duration, and lowering the duration never pulls it earlier); **extend always, shorten only in GOVERNANCE mode with `s3:BypassGovernanceRetention`** — in COMPLIANCE mode nobody, not even root, can shorten it. Legal hold = no expiry, placed/removed freely by anyone with `s3:PutObjectLegalHold` |
| What Object Lock does NOT stop | New **versions** being written, and **delete markers** being added on top — it protects the specific version it was applied to. An object's own retention also **overrides** the bucket default |
| COMPLIANCE mode escape hatch | AWS: "The only way to delete an object under the compliance mode before its retention date expires is to **delete the associated AWS account**" |
| GOVERNANCE bypass in the console | The S3 console sends `x-amz-bypass-governance-retention:true` **by default**, so a user holding `s3:BypassGovernanceRetention` just succeeds there |
| COMPLIANCE mode escape hatch | None — not even root; AWS's documented way out before expiry is closing the AWS account |
| When Object Lock can be enabled / disabled | At bucket creation or on an existing versioned bucket; can never be turned off, versioning can't be suspended |
| MFA Delete — who can configure it | **Root** account (the bucket owner) with an MFA device, via the **CLI *or* the API/SDKs** — **never the console**, never an IAM user. *(Corrected 2026-10-06: this row said "CLI only"; AWS says "the AWS CLI or the API".)* Also **cannot be combined with lifecycle configurations**, and the MFA state lives in the same versioning subresource, so one `PutBucketVersioning` sets both |

**S3 replication**

| | |
|---|---|
| Batch Replication — the four cases it covers | Pre-existing objects, FAILED replications, newly-added destination, replicas-of-replicas (+ objects tagged *after* upload under a tag-based rule) |
| Batch Replication — what it CANNOT do | Objects in Glacier Flexible / Deep Archive / Intelligent-Tiering archive tiers (restore + copy to another class first); objects deleted from the destination **by version ID** (use **Batch Copy** in place) |
| What replication copies that people assume it doesn't | **SSE-C** & SSE-S3 objects, tags, ACL updates, **Object Lock retention (overrides destination default)**; SSE-KMS/DSSE-KMS only if the rule **opts in** |
| What it never copies | Lifecycle-created delete markers, anything a lifecycle action did, bucket-level subresources (lifecycle/notification config), objects in archive tiers |
| Tag-based replication rule trap | The object must carry the matching tag **in the `PutObject` call**; tagged afterwards it is never replicated by the live rule |
| What a live replication rule copies | Only objects created or updated AFTER the rule existed |
| S3 RTC guarantee | Replication within **15 minutes**, SLA-backed + CloudWatch replication metrics. **Do not memorise the percentage** — AWS publishes both: 99.9% on `replication-time-control.html` *and* in `replication.html`'s own table, but 99.99% twice in `replication.html`'s prose. One AWS page contradicts itself. *(Re-checked 2026-10-07.)* |
| Is replication chained / transitive? | No — A→B and B→C does not get A's objects to C |
| Delete replication behaviour | Modern rule (has a `Filter`): delete markers **not** replicated unless you opt in, and that opt-in exists only on **non-tag-based** rules. Legacy **V1** (no `Filter`): user-created delete markers ARE replicated by default. **Cross-account:** not replicated by default. Deleting a specific **version** is NEVER replicated |
| Replication prerequisites | Versioning on BOTH buckets + an IAM role S3 assumes; replication is asynchronous |

**S3 access control**

| | |
|---|---|
| Block Public Access — the four setting names | BlockPublicAcls · IgnorePublicAcls · BlockPublicPolicy · RestrictPublicBuckets. The axis is **ACL vs policy × reject-the-write vs ignore-at-request-time** — **NOT new vs existing**. *(Corrected 2026-10-06: `IgnorePublicAcls` ignores ALL public ACLs, and AWS says it "doesn't prevent new public ACLs from being set".)* |
| Block Public Access — levels and how they combine | Four levels: **access point, bucket, account, organization** (AWS Organizations). S3 applies the **most restrictive combination** — not "account wins". Org level is all-four-or-none and overrides account settings; an access point's BPA is **fixed at creation** |
| When BPA calls an IP-scoped policy "public" | An `aws:SourceIp` range broader than **/8** (IPv4) or **/32** (IPv6), excluding RFC1918 — so an IP-scoped policy can still be rejected as public |
| Bucket policy max size | 20 KB |
| BPA vs a public bucket policy | BPA overrides the policy; settable per-bucket and account-wide, most restrictive combination wins |
| Setting that disables ACLs | BucketOwnerEnforced — AWS states it is "the default setting for all newly created buckets", with ACLs disabled. ⚠️ verify: the "since April 2023" date is not on the Object Ownership page |
| Cross-account access requires | Both the bucket policy AND the caller's IAM policy to allow it |

**Presigned URLs**

| | |
|---|---|
| Presigned URL max expiry | 7 days (604800s) via CLI/SDK; 12 hours via the console |
| Whose permissions does a presigned URL carry? | The generator's, not the recipient's |
| Presigned URL signed with role credentials | Dies when those temporary credentials expire, regardless of --expires-in |

**S3 big objects**

| | |
|---|---|
| Incomplete multipart uploads | Stored and billed but invisible in listings; list with aws s3api list-multipart-uploads |
| Multipart thresholds and part count | Recommended ≥100 MB, required above 5 GB, up to 10,000 parts (numbered 1–10,000) |

**S3 basics**

| | |
|---|---|
| Maximum object size | 0 bytes–50 TB (raised from 5 TB on 2025-12-02; multipart table says 48.8 TiB); old banks say 5 TB |
| Maximum size of a single PUT | 5 GB |
| Bucket naming rules | 3–63 chars, lowercase, no underscores, DNS-compatible; globally unique across all AWS accounts |
| Static website endpoint protocol | HTTP only — HTTPS needs CloudFront in front |
| Global vs regional scope | The bucket NAME is global; the bucket and its data are regional |

**S3 versioning**

| | |
|---|---|
| Versioning on/off states | Suspended but never disabled once enabled; pre-versioning objects have VersionId = null |

**S3 events & query**

| | |
|---|---|
| S3 Select currency warning | ⚠️ No longer available to new customers — use Athena. (Event notification triggers include `s3:ObjectCreated:*`, `s3:ObjectRemoved:*`, `s3:ObjectRestore:*`, replication events **and more** — not a closed list; filterable by prefix and suffix) |
| Who needs a policy for S3 event notifications | **SNS and SQS**: a resource policy allowing `s3.amazonaws.com`, scoped with `aws:SourceArn` **+** `aws:SourceAccount` (and a KMS key-policy grant if the queue/topic uses a CMK). **Lambda**: the S3 console wires it for you; by API you grant it. **EventBridge: no destination policy at all** — enable/disable per bucket, all events go |
| S3 event notification destinations — the hard limits | **Standard SQS, Standard SNS, Lambda, EventBridge**, and **one destination type per notification**. **FIFO is barred both ways**: "FIFO queues aren't supported as an Amazon S3 event notification destination" and "Standard SNS is only allowed … whereas SNS FIFO is not allowed". For FIFO, go **S3 → EventBridge → FIFO queue**. Destination must be in the **same Region** as the bucket; messages up to **64 KB**, so set `MaximumMessageSize` ≥ 64 KB or SQS rejects them |
| Do S3 ObjectRemoved events fire for lifecycle deletes? | **No** — "these event notifications don't alert you for automatic deletes from lifecycle configurations or from failed operations." Use the `s3:LifecycleExpiration:*` / `s3:LifecycleTransition` event types |
| S3 event delivery semantics | **At-least-once**, duplicates possible on retry, and **no ordering guarantee** → consumers must be idempotent and order-independent |
| Why a missing SNS/SQS policy fails loudly | S3 publishes a **test notification** when you enable the rule, so the policy must exist first — it fails at setup, not silently at runtime |

| Requester Pays — who pays what | Requester pays **requests + data transfer out**; *"The bucket owner always pays the cost of storing data."* Requests must be **authenticated** — anonymous access is barred outright. On `RestoreObject` the requester pays the request, the **owner** pays the retrieval. The **owner** is billed for a **403** originating inside the owner's own account/organization |
| Requester Pays as a replication destination | Barred — but AWS documents it **only** under the **cross-account** additional requirements, not as a general rule. Write the conditional |
| Storage Class Analysis — what it recommends | **Standard → Standard-IA only**, never an archive tier (explicit *Important* callout; fields `ObjectAgeForSIATransition`/`RecommendedObjectAgeForSIATransition`). Needs **≥30 days** of data; considers Standard objects **>128 KB** |
| Storage Lens free vs advanced | Free: no charge, 6 metric categories, daily, **14-day** console query window. Advanced (paid): adds activity + detailed status-code metrics, **prefix-level** and group aggregation, CloudWatch publishing, contextual recommendations, **15-month** query window. **Retention is 15 months either way** — the tier changes query reach, not retention. Max **50 dashboards** per home Region |
| Access points — the org-level control AWS documents | An **SCP** denying `s3:CreateAccessPoint` unless **`s3:AccessPointNetworkOrigin`** = `VPC`. But S3 **is** RCP-supported (`prefix:s3`) — so don't say access points are outside RCP scope, only that no access-point-specific RCP example exists. Both the access point **and** the underlying bucket/FSx file system must permit a request |

| "encrypt each file with a different key" | **SSE-S3 already does this** — *"Amazon S3 encrypts each object with a unique key. As an additional safeguard, it encrypts the key itself with a key that it rotates regularly."* One bucket, plain SSE-S3; no splitting into logical groups, no SSE-KMS encryption context. AES-**GCM** 256-bit. Reach for SSE-KMS only for an **audit trail / key policy / your own rotation** |
| What S3 server-side encryption does **not** cover | *"Server-side encryption encrypts only the object data, not the object metadata"* |

↳ [[09-s3-advanced]] · [[09-s3-intro]] · [[09-s3-security]]


## Route 53 & CloudFront

**Route 53 health checks**

| | |
|---|---|
| Aggregate rule across global health checkers | More than 18% reporting healthy ⇒ healthy |
| String-matching health check search window | Must find the string within the first 5,120 bytes |
| HTTP/HTTPS health check timing budget | TCP established within 4 seconds, then 2xx/3xx within 2 more seconds |
| TCP health check timing budget | Must connect within 10 seconds |
| Calculated health check — max children | One parent watches up to 255 children, with AND / OR / "at least N" |
| Status of a brand-new health check | Counts as healthy until it has enough data (inverted if "invert" is enabled) |
| Health check interval options | 30s, or 10s "fast" (costs extra) |
| CloudWatch alarm health check watches what | The alarm's data stream, not its state; same account only, no metric math, no M-of-N |
| Do HTTPS health checks validate certificates? | No — an expired cert passes |
| IP types a health check cannot target | Private, nonroutable, or multicast |
| Failover time (rough model) | ≈ (interval × failure threshold) + TTL — a mental model, not an AWS formula |

**Route 53 routing policies**

| | |
|---|---|
| The eight routing policies | simple · weighted · latency · failover · geolocation · geoproximity · multivalue answer · IP-based |
| Multivalue answer — how many records returned | Up to **8 healthy** records, random order; if none healthy, up to **8 unhealthy**. Health checks **optional, per record**; a record with no health check counts as **healthy** |
| Meaning of weight 0 | **"Stop sending traffic here", NOT "never return this."** AWS: if **all** nonzero-weight records are unhealthy, Route 53 falls back to the zero-weighted ones — so weight 0 is a last-resort fallback, and the documented way to build active/passive from weighted records. *(Corrected 2026-10-06: this row said "never return this record".)* |
| Route 53 SLA — the "100%" line | AWS **no longer states a 100% commitment**: "commercially reasonable efforts … with the Monthly Uptime Percentages set forth in the table". Credits still start **below 100%**: 10% under 100%, 25% under 99.99%, 100% under 99.95% (GovCloud bands start 99.995%). Covers **authoritative DNS hosted zones only** — not the API or console |
| Failover to an ALB/NLB/CloudFront alias | **Do NOT attach a health check to the record.** Set **Evaluate Target Health = Yes** on the alias and Associate with Health Check = **No**. Attach your own health check only for raw IPs and non-AWS endpoints |
| Query price by routing policy | Standard **$0.40**/million · latency **$0.60** · geolocation & geoproximity **$0.70** · IP-based **$0.80** (first 1B/mo). Alias queries to AWS resources are **free**; a CNAME to another R53 record bills **twice** |
| Route 53 VPC Resolver addresses | **169.254.169.253** (IPv4 link-local), **fd00:ec2::253** (IPv6), **and** VPC base **+2**. Link-local still works in an IPv6-only subnet. **Cannot** be filtered by security groups or NACLs. Capped at **1,024 pps per network interface**, shared with IMDS/NTP/Windows licensing — the usual cause of DNS throttling |
| Private hosted zone over VPN | **Not transitive** — on-prem resolves its names via a Resolver **inbound** endpoint (or a forwarder inside the VPC) |
| Geolocation catch-all for unmatched locations | A record with country `*` as the default |
| Simple routing — health checks? | None; returns all values in random order, client picks |
| Geolocation vs geoproximity | Geolocation = where the **USER** is (continent/country/US state) — localization, licensing, compliance. Geoproximity = where your **RESOURCES** are plus a **bias** (**+1…+99** expand, **−1…−99** shrink) — a capacity sentence. The policy does **not** need Traffic Flow; only the console's bias maps do |

**Route 53 alias vs CNAME**

| | |
|---|---|
| TTL on an alias record | You cannot set one — it uses the target's TTL |
| Query cost: alias vs CNAME | **Alias to an AWS resource: free.** A **CNAME is charged** like any other query — and **×2** when it targets another Route 53 record. Base rate **$0.40/million** for the first 1B/month |
| Is an EC2 instance a valid alias target? | No — use a plain A record to its Elastic IP |
| CNAME exclusivity rule | A name with a CNAME can have no other records at all at that name |

**Route 53 zones & Resolver**

| | |
|---|---|
| Private zone queried from outside an associated VPC | No error — falls through to public recursive resolution |
| Private hosted zone nameservers | Four reserved names that are never actually contacted |
| VPC built-in resolver address | VPC base + 2 (10.0.0.2 in a 10.0.0.0/16) |
| Resolver inbound endpoint direction | On-premises resolves names IN AWS — queries coming into AWS |
| Resolver outbound endpoint direction | Your VPC resolves names ON-PREMISES — queries heading out of AWS |
| Route 53 Resolver — rename | Renamed to Route 53 VPC Resolver; course material and exam still say "Route 53 Resolver" |

**Route 53 records**

| | |
|---|---|
| SPF as a record type | Deprecated — put SPF data in a TXT record |
| MX priority — which wins | Lower number wins |

**CloudFront caching**

| | |
|---|---|
| What skips the regional edge cache | **Three** cases: proxy methods (`PUT`, `POST`, `PATCH`, `OPTIONS`, `DELETE`); **dynamic requests** as determined at request time; and an **S3 origin whose optimal regional edge cache is in the same Region as the bucket**. *(Corrected 2026-10-07 — this row listed only two.)* |
| Origin group failover — the method restriction | Fails over **only** for `GET`, `HEAD`, `OPTIONS`. Never for `POST`/`PUT` → origin groups are the **wrong answer for a write path**. Also won't fire unless `OPTIONS` is a cached HTTP method |
| Origin group failover — triggers | A status code you nominated (choose from **400, 403, 404, 416, 429, 500, 502, 503, 504**). A failed **connection** counts only if **503** is configured; a **timeout** only if **504** is |
| Origin group failover — timing | Default up to **30 s** on the primary (3 attempts × 10 s). Connection timeout **1–10 s**, attempts **1–3**, origin response timeout **30 s** default / **1–120 s**. No stickiness — every request goes to the primary first |
| CloudFront pricing — two models | **Flat-rate plans** $0 / $15 / $200 / $1,000 per month bundling CDN + WAF + DDoS + DNS + TLS + logging + edge compute, **no overage charges**; or **pay-as-you-go** (per-GB out + per-request). Either way, **AWS origin → CloudFront data transfer is waived** |
| Free invalidation allowance | First **1,000 paths per month per AWS account** (across all distributions); a path containing `*` counts as **one** path, and **tag invalidations draw on the same allowance**. AWS recommends versioned filenames instead, since invalidation cannot reach a browser cache or corporate proxy |
| Price class coverage | `_100` cheapest/fewest locations · `_200` adds more of Asia, Middle East, Africa · `_All` everywhere (default). ⚠️ verify the exact country lists — AWS retired the PriceClass docs page (301 to the pricing page) and publishes no country breakdown |
| Two-tier TTL pattern values | index.html 60s; hashed /static/app.a1b2c3.css one year |

**CloudFront OAC & origins**

| | |
|---|---|
| Can an S3 website endpoint use OAC or OAI? | No — it is a custom origin, and custom origins support neither |
| Endpoint OAC requires | The S3 REST endpoint: bucket.s3.region.amazonaws.com |
| Bucket policy principal + the condition key | Service principal cloudfront.amazonaws.com, with an AWS:SourceArn condition pinning your distribution |
| What OAI does not support | Opt-in Regions launched after Dec 2022/Jan 2023, SSE-KMS, dynamic PUT/POST/DELETE; OAI is legacy |

**CloudFront certificates**

| | |
|---|---|
| Region for a viewer↔CloudFront ACM certificate | us-east-1, no matter where the origin is |
| The one Region exception | CloudFront↔origin HTTPS with an ELB origin — certificate may be in any Region |
| Origin cert domain does not match origin domain name | Viewers get 502 Bad Gateway |

**CloudFront edge functions**

| | |
|---|---|
| Functions vs Lambda@Edge — code and memory limits | 10 KB / 2 MB vs 50 MB / 128 MB (viewer) or 10 GB (origin) |
| Functions vs Lambda@Edge — max duration | Sub-millisecond vs up to 30 seconds |
| Functions vs Lambda@Edge — events | Viewer request/response only vs viewer + origin request/response |
| Functions vs Lambda@Edge — language | JavaScript (ECMAScript 5.1) **or JavaScript runtime 2.0** vs Node.js and Python |
| CloudFront KeyValueStore | CloudFront **Functions** only, and only on **runtime 2.0**. Not available to Lambda@Edge |

**Global Accelerator**

| | |
|---|---|
| Addresses it gives you | Two static anycast IPs (four dual-stack), kept until the accelerator is deleted |
| Valid endpoint types | NLB, ALB, EC2, Elastic IP |
| Caching and protocols | Caches nothing; routes any TCP/UDP |

**CloudFront private content**

| | |
|---|---|
| Signed URL vs signed cookies | Signed URL = one individual file; signed cookies = multiple files |

| Hosted zone and domain ownership | `CreateHostedZone` takes **no proof of ownership** and never checks. Only name validations: well-formedness (`InvalidDomainName`) and the **TLD prohibition**. AWS permits **duplicate zone names** (*"more than one hosted zone with the same name"*, four distinct NS each). The *"permission to administer"* line under Restrictions is a rule to the reader, **not** an API check — and AWS's bar is *administer*, not own |
| Health checks — what "AWS endpoint" means | A **billing-relationship** term, not infrastructure: provisioned in the same account **OR billed to** it ("within or **linked to**"). A sibling account under one payer = AWS endpoint (**50 free**, then $0.50/mo). A **stranger's** AWS account = **non-AWS** endpoint ($0.75/mo, no free allowance) despite running on AWS. 50 aggregate across all Regions, **no rollover**. Calculated + CloudWatch-metric checks bill at the AWS rate. **ELB** and **S3 website-endpoint** checks are **not billed at all** |
| CloudFront geo restriction — cost and reliability | *"There is no additional charge for configuring geographic restrictions"* (feature only; traffic still bills). **99.8%** accurate and **fails open** — *"If CloudFront can't determine a user's location, CloudFront serves the content."* Distribution-wide, not per-path. Does **not** apply to certificate-validation requests for CloudFront managed certs |

↳ [[10-route53]] · [[11-cloudfront]]


## EFS, FSx, Gateway & Transfer

**Snow Family**

| | |
|---|---|
| Snow Family current availability | **The entire Snow Family is closed to new customers** — AWS: "AWS will no longer offer any AWS Snow Family devices for new customers to order", so Snowcone is gone too. New users → **DataSync** (online), **AWS Data Transfer Terminal** (bring your own disks), **Partner solutions**, **Outposts** (edge compute). **Still examinable.** *(Corrected 2026-10-07: this row asserted a 2026-12-31 end-of-support date that appears on no AWS page.)* |
| Snow Family end-of-support date | ⚠️ verify — **AWS contradicts itself.** The Snowball developer guide says the change "will not impact customers currently using AWS Snowball Edge" and AWS "continues to invest" in them; the AWS General Reference lists "AWS Snowball Edge \| November 12, 2025" under **Services in Full Shutdown** ("completely removed… no longer available or supported in any capacity"). Don't memorise a date |
| Snowball Edge cluster size | 3–16 devices |
| Snowball Edge Storage Optimized capacity | 210 TB |
| Snowball Edge network adapter speed | Up to 100 Gbit/s |
| Snowball Edge supported protocols | NFSv3 / v4 / v4.1 and the S3 API |
| Snowball Edge variants | Storage Optimized or Compute Optimized |

**EFS lifecycle**

| | |
|---|---|
| EFS Transition into Standard default | None — an accessed file does NOT return to Standard automatically |
| EFS lifecycle default to Infrequent Access | 30 days of no access |
| EFS lifecycle default to Archive | 90 days of no access |
| EFS Archive class restrictions | Regional-only; requires Elastic throughput mode |
| Which EFS classes have One Zone variants | Standard and Infrequent Access (not Archive) |
| EFS storage classes | Standard, Infrequent Access, Archive |

**EFS**

| | |
|---|---|
| EFS default performance mode (AWS recommended) | General Purpose |
| EFS default throughput mode (AWS recommended) | Elastic |
| EFS NFS versions | NFSv4.1 and NFSv4.0 |
| EFS encryption at rest — when enabled | At creation only; encrypts data and metadata |
| EFS encryption in transit — when enabled | At mount time |
| EFS mount targets — how many | One per Availability Zone, each in a subnet with a security group |
| EFS + Windows EC2 | Not supported |
| EFS file system types | Regional (multi-AZ redundant, recommended) or One Zone (single AZ, data may be lost) |
| What can mount EFS | EC2, ECS, EKS, Lambda, Fargate |

**FSx for Windows**

| | |
|---|---|
| FSx for Windows SMB versions | SMB 2.0–3.1.1 |
| FSx for Windows encryption in transit | SMB Kerberos session keys |
| FSx for Windows backup consistency mechanism | Volume Shadow Copy Service (VSS); automatic daily backups |
| FSx for Windows independently provisioned dimensions | Storage, SSD IOPS, and throughput |
| FSx for Windows auth requirement | Microsoft Active Directory; enforces Windows ACLs |
| FSx for Windows on-premises access paths | Direct Connect or Site-to-Site VPN |
| FSx for Windows AZ options | Single-AZ or Multi-AZ (standby file server in another AZ) |

**FSx for Lustre**

| | |
|---|---|
| Lustre storage classes | SSD, Intelligent-Tiering, HDD |
| Lustre scratch vs persistent — the axis | Durability, not speed |
| Lustre scratch deployment type | Not replicated; does not survive a file server failure |
| Lustre persistent deployment type | Replicated; failed file servers replaced automatically |
| Lustre OS support | Linux-only (needs the Lustre client); POSIX-compliant |
| Lustre performance figures | Sub-millisecond latency, up to multiple TB/s throughput |

**FSx other**

| | |
|---|---|
| FSx for NetApp ONTAP protocols | **NFS, SMB, iSCSI *and* NVMe** — the **only** FSx with block storage. So "iSCSI block + Multi-AZ" → ONTAP and nothing else (OpenZFS is NFS-only, Windows is SMB, Lustre is Lustre). *(Corrected 2026-10-07: this row said "Both NFS and SMB", losing the elimination that carries the exam weight.)* |
| FSx for OpenZFS protocol / trait | NFS; cheap snapshots and clones |

**Storage Gateway**

| | |
|---|---|
| Stored volume recovery targets | Your own data centre or EC2 |
| Storage Gateway deployment platforms | VM on VMware ESXi, KVM or Hyper-V; hardware appliance; or EC2 instance |
| Volume Gateway cached — where primary copy lives | In S3; frequently-accessed subset kept locally |
| Volume Gateway stored — where primary copy lives | On premises (entire dataset); async point-in-time snapshots to S3 |
| Volume Gateway local protocol | iSCSI |
| S3 File Gateway local protocols | NFS or SMB |
| The four gateway types | S3 File, FSx File (closed to new customers), Volume, Tape Gateway |

**DataSync**

| | |
|---|---|
| DataSync sources | On-prem NFS, SMB, HDFS, object storage; and other clouds (Azure Blob/Files, GCS) |
| DataSync directions | **Both ways**: into S3, EFS, all four FSx — and back out to NFS/SMB/HDFS/object storage/other clouds |
| DataSync vs Storage Gateway | DataSync transfers (one-off or scheduled); Storage Gateway is a permanent bridge |

**AWS Backup**

| | |
|---|---|
| Vault Lock compliance mode grace time minimum | 3 days |
| Vault Lock governance vs compliance mode | **Governance**: unlockable by anyone holding the IAM permission. **Compliance**: unlockable by nobody, including AWS — **but only once the grace period expires** (minimum **3 days**). During that window it is still cancellable, which is what an "accidentally locked vault" question turns on |
| AWS Backup cross-account copy requirement | An AWS Organizations structure |
| AWS Backup incremental vs full | Incremental for supported resource types; others are full copies each time |
| AWS Backup resource assignment | Tags, resource types, ARNs, or all resources (Vault Lock = WORM) |

**Storage shapes**

| | |
|---|---|
| Block / file / object → services | Block = EBS, instance store; File = EFS, FSx; Object = S3, Glacier |

| EFS Archive — Regional vs One Zone | AWS states it **affirmatively**: *"supported on EFS Regional file systems using EFS's default Elastic Throughput mode"*, and the storage-class table has no One Zone entry for Archive. Carry the affirmative, not the flat negative |

↳ [[12-storage-extras]]


## Cost & Disaster Recovery

**Savings Plans**

| | |
|---|---|
| Does a Savings Plan reserve capacity? | No — billing discount only, never reserves capacity |
| EC2 Instance Savings Plan max discount | up to 72% — locked to one instance family in one Region |
| Compute Savings Plan max discount | up to 66% — flexible on family, size, Region, OS, tenancy |
| Which purchases actually reserve capacity | **Zonal** Reserved Instances · **On-Demand Capacity Reservations** · **Capacity Blocks** (a cluster of GPU instances) · **Dedicated Hosts** (a physical host dedicated to you). **Savings Plans and *regional* RIs reserve nothing** — they are discounts. *(Corrected 2026-10-07: this row said "only zonal RIs and Capacity Reservations", missing two.)* |
| Spot request type — one-time vs persistent | *One-time*: if interrupted, "the request is **not** resubmitted". *Persistent*: "the request **is** resubmitted to replenish the interrupted Spot Instance". **Default = one-time.** Interruption behaviour is tied to type: `Stop`/`Hibernate` **persistent only**, `Terminate` **one-time only** (and `Terminate` is the default, so a persistent request left on the default errors). "Valid to" expiry is persistent-only. Maintaining a **target capacity** is EC2 Fleet / Spot Fleet, not a persistent request |
| Who gives Savings Plans / reservation purchase recommendations | **Cost Explorer** *and* **Cost Optimization Hub** (AWS steers you to the Hub first). **Compute Optimizer never does** — it only rightsizes and finds idle resources |
| Reserved Instances vs Savings Plans — status | AWS: "We recommend Savings Plans over Reserved Instances." RIs are **not legacy**: RI Marketplace + RDS/Redshift/ElastiCache reservations are RI-only. AZ capacity: **zonal RI or Capacity Reservation** |
| Non-EC2 services Compute Savings Plans cover | AWS Fargate and AWS Lambda |
| What a Savings Plan commits to | a spend rate in USD/hour, for 1 or 3 years |

**Reserved Instances**

| | |
|---|---|
| Standard RI: modify or exchange? | can be modified, never exchanged |
| Convertible RI: modify or exchange? | can be exchanged for another Convertible RI with different attributes |
| Do RIs auto-renew? | No — instance keeps running and silently reverts to On-Demand rates |
| RI's four pricing attributes | instance type, Region, tenancy, platform (OS) |
| Which RI can be sold on the RI Marketplace | Standard RIs only; purchases cannot be cancelled |

**EC2 purchasing options**

| | |
|---|---|
| Dedicated Host vs Dedicated Instance | Host = physical server visibility, per-socket/per-core BYOL; Instance = single-tenant, no host visibility |
| Number of EC2 purchasing options | **Seven**: On-Demand, Savings Plans, RIs, Spot, Dedicated Hosts, Dedicated Instances, Capacity Reservations — **plus Capacity Blocks** for reserving clusters of GPU instances, so "seven" is the documented count, not the whole universe |

**Spot**

| | |
|---|---|
| Spot interruption metadata path | /latest/meta-data/spot/instance-action — HTTP 404 when not marked |
| Recommended poll interval for spot/instance-action | every 5 seconds; notices are best-effort |
| Spot interruption EventBridge event name | EC2 Spot Instance Interruption Warning |
| Spot hibernate and the two minutes | notice given, but no two-minute warning — hibernation starts immediately |
| Effect of setting a maximum Spot price | interruptions become MORE frequent |
| Spot interruption notice lead time | 2 minutes (with stop or terminate behaviour) |

**Cost tools**

| | |
|---|---|
| Compute Optimizer metric lookback | 14 days default; 32 days free; 93 days needs paid enhanced infrastructure metrics |
| Compute Optimizer enablement | you must opt in |
| Cost Explorer vs Budgets vs Compute Optimizer | Explorer analyses/forecasts past; Budgets alerts on a threshold; Optimizer says the resource is the wrong size |

**Non-compute cost levers**

| | |
|---|---|
| Gateway endpoint cost vs NAT Gateway | gateway endpoint free; NAT Gateway bills per hour AND per GB processed |
| Elastic IP / public IPv4 billing | billed hourly whether attached or not |
| EBS snapshots after the volume is deleted | keep charging indefinitely |
| Data transfer charging directions | inbound generally free; outbound to internet charged; cross-AZ charged |
| Consolidated billing cost | free; shares volume, RI and Savings Plan discounts across the organization |

**DR strategies**

| | |
|---|---|
| Pilot light vs warm standby | pilot light cannot process requests without action first; warm standby handles traffic immediately at reduced capacity |
| Which DR strategies are active/passive | pilot light, warm standby, hot standby; only multi-site is active/active |
| RTO by strategy | backup & restore hours; pilot light tens of minutes; warm standby minutes; multi-site near zero |
| Hot standby | full capacity deployed, still active/passive — only one Region takes traffic |
| RTO vs RPO | RTO = how long you're down; RPO = how much data you lose |
| Can the four strategies use AZs instead of Regions? | yes — the data-residency / single-Region answer |

**Cross-Region replication**

| | |
|---|---|
| Aurora Global Database secondary Regions | up to 10 (the DR whitepaper still says five — stale) |
| Aurora Global Database promotion time | less than one minute, even during a full regional outage |
| Aurora Global Database replication latency | typically under 1 second cross-Region; well under 100 ms within a Region |
| RDS (non-Aurora) read replica promotion | a few minutes, and includes a reboot |
| S3 Replication Time Control SLA | Within **15 minutes**, SLA-backed. AWS states the percentage as both 99.9% and 99.99% across (and within) pages — carry the 15 minutes |
| S3 CRR and delete markers | not replicated by default on a modern (`Filter`-based) rule — opt in, non-tag-based rules only |
| DynamoDB Global Tables conflict handling | multi-active read/write everywhere; **last-writer-wins** in the default **MREC** mode |
| DynamoDB Global Tables consistency modes | **MREC** (multi-Region eventual consistency, the default) or **MRSC** (multi-Region strong consistency, aimed at a **zero RPO**, **same-account only**). Chosen at creation and **cannot be changed afterwards**; a table cannot mix modes |
| What MRSC does **not** support | **TTL**, **LSIs**, **transactions** (`TransactWriteItems`/`TransactGetItems` error on an MRSC replica), and no **`ReplicationLatency`** metric. **Streams are NOT on that list** — not enabled by default, but *"You can enable Streams on an MRSC replica"*, and those records are identical across replicas including ordering |
| MRSC shape constraints | **Exactly three Regions** — three replicas, or two replicas + a **witness** (holds data, cannot be read or written, third Region). Must be created from an **empty** table; cannot add replicas later; cannot delete just one replica. Concurrent cross-Region writes to one item → `ReplicatedWriteConflictException` (retryable) |
| Global tables availability SLA | **99.999%**, vs **99.99%** for a single-Region table |
| DynamoDB Global Tables account models | **Same-account** (all replicas in one account) or **multi-account** (replicas across accounts in one replication group). Both support multi-Region writes, async replication and last-writer-wins |
| Elastic Disaster Recovery (DRS) RTO/RPO | RTO of minutes, RPO of seconds; implements pilot light; does not cover RDS |
| CloudFront origin failover granularity | per request — later requests still try the primary first |

**DR operations**

| | |
|---|---|
| Data plane vs control plane failover | data: Route 53 health checks, Application Recovery Controller; control: R53 weights, GA traffic dial, Auto Scaling |
| What is inside the RTO clock | detection, notification, escalation, evaluation, declaration — clock starts at the failure |
| Static stability | provision full capacity so recovery doesn't depend on Auto Scaling |
| DR-Region drift tooling | AWS Config detects, SSM Automation remediates, CloudFormation drift detection for stacks |

| Cancel a Spot request vs terminate the instance | **Asymmetric by request state.** Cancel an **`active`** request with a **running** instance → *"not automatically terminated; you must manually terminate"*. Cancel a **`disabled`** request with a **stopped** instance → *"automatically terminated"*. And terminating an instance from a **persistent** request flips the request to **`open`** and it **relaunches** — cancel first, then terminate |
| Same-Region RDS read-replica replication traffic | **Not charged** — but cite the **User Guide**, not the pricing page (whose table carries only the Multi-AZ line). Covers **replication only**: app→replica cross-AZ still bills $0.01/GB each way, replica instance-hours bill in full, and **cross-Region** replica replication **is** charged |
| Cost Explorer API pagination | **`GetCostAndUsage` only** (`NextPageToken`, `InvalidNextTokenException`). **`GetCostForecast` has no pagination at all.** And the API is the documented *query* interface, **not the only** programmatic route — **CUR** is the "most comprehensive" set, delivered to S3 |
| Cost Anomaly Detection — threshold or not | **Detection** needs no threshold: *"Even if an anomaly is below the alert threshold, the machine learning model continues to detect spend anomalies."* The **alert subscription** does take one (dollar or %, two combinable AND/OR). vs **Budgets**, which needs a number to detect anything. Alerting: individual (needs **SNS**), daily summary (top 10, 00:00 UTC), weekly |
| ElastiCache Global Datastore figures | *"typical cross-region replication latency of under 1 second"*; promote a replica *"in less than 1 minute"*. Feature page only — the Developer Guide publishes **no** figure. Typical, not a bound (replication is async) |

↳ [[13-cost-optimization]] · [[14-dr-resilience]]


## Messaging & Streaming

**SQS limits & defaults**

| | |
|---|---|
| Max SQS message size | 1,048,576 bytes (1 MiB) — most course material still says 256 KB; know both |
| Payload larger than the max — how and how big | Extended Client Library stores it in S3, reference in message — up to 2 GB |
| Metadata attributes per message | 10 |
| Delay (message timer) default and max | default 0, maximum 15 minutes |
| Message retention — default / min / max | default 4 days (345,600s); min 60 seconds; max 1,209,600s (14 days) |
| Visibility timeout — default / min / max | default 30 seconds; minimum 0; maximum 12 hours |
| Messages per batch request | at most 10 |
| What DeleteMessage needs | the receipt handle (issued per receive), not the message ID |

**SQS polling**

| | |
|---|---|
| Which polling mode is the DEFAULT | short polling (WaitTimeSeconds = 0) — samples a subset of servers, false empty responses |
| Long polling max wait | WaitTimeSeconds up to 20 seconds; queries all servers |

**SQS DLQ**

| | |
|---|---|
| Redrive allow policy — options and limit | allowAll (default), byQueue (up to 10 source ARNs), denyAll |
| Standard queue, maxReceiveCount greater than 3 | a message received 3+ times without deletion moves to the back of the queue |
| DLQ retention clock — standard vs FIFO | standard keeps the original enqueue timestamp; FIFO resets it |
| DLQ placement and type constraints | same account and Region as source, and same queue type (FIFO↔FIFO, standard↔standard) |

**SQS FIFO**

| | |
|---|---|
| High-throughput FIFO max TPS (top Regions) | 70,000 TPS non-batched in N. Virginia / Oregon / Ireland; batching multiplies by 10 |
| High-throughput FIFO TPS in other Regions | 19,000 Ohio/Frankfurt; 9,000 Mumbai/Singapore/Sydney/Tokyo/Spain; 4,500 London/São Paulo; 2,400 else |
| What content-based deduplication hashes | the message body with SHA-256 — not the attributes |
| MessageGroupId on a STANDARD queue | enables fair queues (on FIFO it is required — send fails without it) |
| Deduplication window | **FIFO only: 5 minutes.** A repeated `MessageDeduplicationId` in that window is accepted but not delivered. **Content-based dedup** = SHA-256 of the **body** |
| FIFO throughput ceiling | 300 TPS per API action per partition; 3,000 messages/sec with batching (300 × 10) |
| FIFO queue name requirement | must end in .fifo |

**SNS**

| | |
|---|---|
| SNS FIFO topic — allowed subscriber protocol | SQS protocol only (no email/HTTP/Lambda); can fan out to both FIFO and standard queues |
| Where the payload sits in an SNS-to-SQS message | nested in .Message of a JSON envelope; raw message delivery turns the envelope off |
| Filter policy evaluated against the body | FilterPolicyScope: MessageBody (default is message attributes) |
| Queue policy needed for SNS delivery | allow principal sns.amazonaws.com, pinned with ArnEquals on aws:SourceArn |
| SNS subscriber endpoint types | SQS, Lambda, HTTP(S), email, SMS, mobile push, Amazon Data Firehose, third-party providers |

**Amazon MQ**

| | |
|---|---|
| ActiveMQ wire protocols | AWS lists **exactly six**: AMQP, MQTT, MQTT over WebSocket, OpenWire, STOMP, STOMP over WebSocket (TLS endpoints `amqp+ssl://:5671`, `mqtt+ssl://:8883`, `ssl://:61617` OpenWire, `stomp+ssl://:61614`, `wss://:61619`). **AWS never states an AMQP version** for ActiveMQ — RabbitMQ is explicitly **0-9-1**. Don't expect a version the docs don't publish |
| RabbitMQ wire protocol | AMQP 0-9-1 |
| Deployment modes — **ActiveMQ** | single-instance: EBS **or** EFS, one AZ · **active/standby**: **EFS only**, two AZs, one active, two endpoints per wire protocol (`-1`/`-2`), failover in a few seconds |
| Deployment modes — **RabbitMQ** | single-instance: **EBS**, one AZ, behind an **NLB** · **cluster**: **three** nodes behind an NLB across AZs, **each with its own EBS volume**, classic mirroring automatic (`ha-mode: all`). **No active/standby. No EFS.** *(Corrected 2026-10-07 — the cheatsheet listed only ActiveMQ's modes as if generic.)* |
| Which engine a stem is describing | "three brokers / cluster / NLB" → **RabbitMQ**. "two brokers, one active, shared EFS" → **ActiveMQ** |
| Supported engines | Apache ActiveMQ Classic or RabbitMQ |
| Billing unit | per broker **instance-hour plus storage and data transfer** — a running server, not serverless, so it bills while idle |

**Kinesis Data Streams**

| | |
|---|---|
| Kinesis record size | Default **1 MB** data blob — still the classic exam answer. Not a doc contradiction any more: the per-stream maximum is **configurable** via `UpdateMaxRecordSize` from **1,024 to 10,240 KiB (1–10 MiB)**. *(Corrected 2026-10-07 — this row called it a disagreement between AWS pages.)* |
| Single GetRecords call max return | 10 MB or 10,000 records; if it returns 10 MB, calls in the next 5 seconds throw |
| Capacity mode switches allowed | twice in 24 hours |
| On-demand starting throughput | 4 MB/sec write, 8 MB/sec read for a new stream |
| On-demand maximum throughput | 10 GB/s write / 20 GB/s read in N. Virginia, Oregon, Ireland; 200 MB/s / 400 MB/s elsewhere |
| Partition key — length and hash | ≤256 Unicode chars, MD5-hashed to a shard; required unless on-demand AUTO distribution |
| Retention — default / min / max | default and minimum 24 hours; maximum 8,760 hours (365 days); above 24 h costs extra |
| Per-shard write limit | 1 MB/sec OR 1,000 records/sec — whichever binds first |
| Per-shard read limit | **2 MB/sec *or* 2,000 records/sec out** per shard, max **5 `GetRecords`/sec** — **shared across all consumers only under the default shared fan-out**. With **enhanced fan-out** each registered consumer gets its own 2 MB/sec per shard (`SubscribeToShard`, pushed). "Several consumers each needing full throughput" → enhanced fan-out |
| Free tier | none — Kinesis Data Streams has no free tier |

**Kinesis consumers**

| | |
|---|---|
| Where the KCL stores consumption state | DynamoDB — KCL 3.x default: 3 tables |
| Registered (enhanced fan-out) consumers per stream | up to 20 (50 on On-demand Advantage) |
| Enhanced fan-out API and throughput | SubscribeToShard, pushed; own 2 MB/sec per shard per registered consumer |

**Firehose**

| | |
|---|---|
| Firehose max record size | 1,000 KB |
| Firehose buffering trigger | size (MB) or interval (seconds) — whichever threshold trips first |
| Firehose Redshift delivery path | delivered to S3 first, then loaded with a COPY |
| Firehose destinations | S3, Redshift, OpenSearch Service/Serverless, Splunk, Apache Iceberg, custom HTTP endpoints, partners |
| Firehose shards and retention | No shards, and **nothing re-readable** — so no replay. Precisely: AWS says "the maximum data storage time of Amazon Data Firehose is **24 hours**", holding undelivered data while it retries (with a Data Streams/MSK source, retries run up to the *stream's* retention). "No retention" is the wrong reason for the right conclusion |
| Firehose latency floor | Defaults are the slow end (S3: 5 MB / 300 s), but the buffering interval can be **0 seconds** ("zero buffering") and AWS then delivers "within a few seconds" — so don't eliminate Firehose on latency without reading the stem |
| SNS replay and ordering | **FIFO topics only**: archive up to **365 days**, and a *subscriber* initiates replay over a chosen window (`ReplayPolicy`); strict ordering per message group. A **standard** topic does neither. *(Added 2026-10-07 — several notes marked SNS as having no replay and no ordering at all.)* |
| What actually eliminates SNS for a replay stem | Not the word "replay" — SNS FIFO can replay. It's needing **many independent consumers reading a shared log, each at its own position** → Kinesis Data Streams |

**Messaging discriminators**

| | |
|---|---|
| SQS vs Kinesis after a consumer reads | SQS: deleted. Kinesis: stays until retention expires (no delete operation) |
| Data Streams vs Firehose | Streams stores, you build the consumer; Firehose delivers, you build nothing |
| Kinesis ordering scope | within a shard, not across the stream |
| Standard vs FIFO delivery guarantee | Standard: **at-least-once**, best-effort order. FIFO: **exactly-once**, strict order **per `MessageGroupId`** — *not* across the queue. Different groups have no defined order relative to each other and process in parallel |
| SQS vs SNS delivery direction | SQS: consumer pulls, one consumer. SNS: pushes to every subscriber |
| A2A vs A2P support | SNS: A2A and A2P. SQS: A2A only |
| Amazon MQ vs SQS/SNS trigger | existing app on a **broker/JMS** protocol (OpenWire, STOMP, AMQP), no rewrite → MQ; anything new → SQS/SNS. **MQTT alone is not the MQ signal** — constrained devices publishing MQTT → **AWS IoT Core** |

↳ [[15-decoupling]] · [[16-kinesis]]


## Containers & Serverless

**ECS deployments**

| | |
|---|---|
| Deployment circuit breaker threshold formula | clamp(0.5 × desiredCount, min 3, max 200); BOUNDED_PERCENT default 50 — a small service gets 3 |
| resetOnHealthyTask default | true — only consecutive failures count; one healthy task resets the counter to zero |
| minimumHealthyPercent default | 100 — ECS may not drop below desired count, so it won't kill a healthy old task |
| maximumPercent default | 200 — may temporarily run up to double the desired count while rolling |
| Two deployment states during a rollout | PRIMARY (the new one) and ACTIVE (the old one still serving) |
| Circuit breaker with no prior successful deploy | Rolls back only to the most recent COMPLETED deployment; if none exists it launches no tasks and stalls |

**ECS/Fargate basics**

| | |
|---|---|
| Valid memory values when Fargate cpu = 256 | 512, 1024, 2048 MiB only; cpu/memory must be one of AWS's valid pairs |
| ALB target group algorithms | round_robin, least_outstanding_requests, weighted_random — default round_robin |
| Fargate network mode | awsvpc only — every task gets its own ENI and private IP |
| ALB target type for Fargate | **`ip`, never `instance`** — AWS: services whose tasks use `awsvpc` "only support Application Load Balancers and Network Load Balancers… you must choose `ip` as the target type, not `instance`", because those tasks have an ENI rather than an EC2 instance. Fargate always uses `awsvpc`. *(Corrected 2026-10-07: this row asserted a silent-503 symptom no AWS page states.)* |
| Task definition identifier format | family:revision — immutable; you register a new revision, never edit one |
| Fargate Spot discount | Up to 70% off for interruption-tolerant tasks |
| ECS containment hierarchy | Cluster → Service → Task → Container(s) |

**ECS vs EKS**

| | |
|---|---|
| Control plane cost, ECS vs EKS | ECS control plane free; EKS **$0.10** per cluster-hour on **standard support**, **$0.60** per cluster-hour once the Kubernetes version moves to **extended support** — either way whether or not anything runs |
| ECS capacity options beyond EC2-vs-Fargate | **ECS Managed Instances** (AWS manages the EC2 capacity; EC2 price + a management fee, per second with a 1-minute minimum) and the **`EXTERNAL`** launch type for **ECS Anywhere** (tasks on your own on-prem servers/VMs — no ELB, no service discovery, no `awsvpc` there) |
| EKS autoscaling — two layers, usually both needed | **Pods: Horizontal Pod Autoscaler**, which needs a metrics source — the **Metrics Server** — installed; it scales replicas on CPU. **Nodes: Karpenter** (launches right-sized EC2 "in under a minute"), the **Cluster Autoscaler** (adjusts node count **via Auto Scaling groups**), or **EKS Auto Mode** (managed, built on Karpenter). HPA alone leaves extra pods `Pending`; nodes alone leaves the replica count unchanged |
| ECS autoscaling — two layers, same axis as EKS | **Service Auto Scaling** (via **Application Auto Scaling**) changes the service's **desired task count**. An **EC2 ASG / capacity provider** changes how many **container instances** exist to place tasks on. ASG alone = empty capacity, no more tasks. Service alone = tasks stuck `PENDING` when the cluster is full. On **Fargate** there is no instance layer, so an ASG answer is wrong by construction |
| ECS Service Auto Scaling policy types | **Target tracking** (easiest — metric + target, e.g. ECS average CPU/memory) · **step** (CloudWatch alarms with step adjustments, fastest reaction) · **scheduled** · **predictive** (historical patterns) · **SQS backlog per task** for worker services |
| ECS Service Auto Scaling behaviours | Metrics at **1-minute** intervals · **scale-in suspended during a deployment**, scale-out continues · scales from the **actual running task count**, not desired, to prevent runaway scaling · **min capacity can be 0** (scale to zero) · active policies **can override a manually set desired count** |
| Karpenter vs Cluster Autoscaler | Karpenter = just-in-time, right-sized instances matching workload requirements, **open-source you install and manage, no AWS SLA**. Cluster Autoscaler = adjusts node count **through ASGs**, so it inherits ASG (control-plane) behaviour |
| IAM Roles Anywhere — what it's for | **Temporary IAM credentials for workloads *outside* AWS** (servers, containers, apps) so you hold **no long-term access keys** on-prem. Workload presents an **X.509 cert** from your CA (or AWS Private CA); you register that CA as a **trust anchor**; the role trusts the Roles Anywhere **service principal**, bound by `aws:SourceArn` = the trust anchor ARN; a **profile** picks the roles and can add session policies. Account-scoped trust, **regional** resources, **no** org-wide integration |
| Roles Anywhere vs Identity Center vs AD Connector | **Roles Anywhere** = a *machine* outside AWS. **Identity Center** = a *human* signing in, permission sets. **AD Connector / Managed Microsoft AD** = joining AWS to an existing directory. An IAM user with a long-lived key is what Roles Anywhere replaces |
| Fargate billing granularity | Per **second** with a **1-minute minimum** — a 10-second task bills a full minute. ~$0.0405/vCPU-hour, ~$0.0044/GB-hour (Linux/x86, us-east-1) |

**ECS IAM**

| | |
|---|---|
| Execution role vs task role — who uses it | Execution role = the ECS/Fargate agent; task role = your application code |
| What the execution role is actually required for | Private ECR pulls, the awslogs driver, Secrets Manager/SSM refs — NOT for a public Docker Hub pull |
| Execution role trust principal and managed policy | Trust policy principal is **`"Service": "ecs-tasks.amazonaws.com"`** (verified verbatim 2026-10-07), role conventionally named **`ecsTaskExecutionRole`**, with the managed policy **`AmazonECSTaskExecutionRolePolicy`** attached |
| Are execution-role credentials visible in the container? | No — "not directly accessible by the containers in the task"; task role creds are, via task metadata endpoint |

**ECR & VPC endpoints**

| | |
|---|---|
| Endpoints required to pull from ECR with no internet | ecr.api (interface), ecr.dkr (interface), s3 (GATEWAY), plus logs (interface) if using awslogs |
| S3 endpoint type needed for ECR, and why | Gateway (free) — ECR stores image layers in S3 (prod-<region>-starport-layer-bucket) |
| Fargate platform version requiring both endpoint sets | 1.4.0+ requires both the ECR VPC endpoints and the S3 gateway endpoint |
| Endpoint security group inbound requirement | 443 inbound from the private subnets |

**Lambda VPC**

| | |
|---|---|
| Connections supported per Hyperplane ENI | Up to 65,000 |
| Hyperplane ENI sharing unit | Shared per subnet + security group combination, across functions — not one per concurrent execution |
| Idle period that reclaims a VPC Lambda ENI | 14 days idle; a new VPC function also sits in Pending for several minutes while the ENI is built |
| Superseded model — ENI per concurrent execution | Pre-2019 story; "one ENI per concurrent execution / IP exhaustion" is no longer how it works |
| Does a public subnet give a VPC Lambda internet? | No — "doesn't give it internet access or a public IP address"; needs private subnet + NAT, or VPC endpoints |

**Lambda**

| | |
|---|---|
| Memory at which a function gets one vCPU | 1,769 MB |
| Memory range | 128 MB – 10,240 MB |
| Timeout ceiling | **900 seconds (15 minutes)** for a standard function — the exam answer. Not "hard" any more: **5,400 s (90 min)** for **Lambda Managed Instances** functions invoked **asynchronously or via an event source mapping**, except Amazon MQ and DocumentDB. *(Updated 2026-10-07.)* |
| DynamoDB change-data-capture — two paths | **DynamoDB Streams** (24 h, trigger a Lambda on every change) **or** streaming item-level changes to **Kinesis Data Streams** (longer retention, enhanced fan-out, analytics pipelines). "Streams is the only thing that sees every change" is wrong |
| API Gateway private integration targets | **NLB: REST + HTTP · ALB: REST + HTTP · AWS Cloud Map: HTTP only.** The REST-vs-HTTP discriminator is **Cloud Map**, not the LB type — "REST private integrations are NLB-only" is out of date *(verified 2026-10-07)* |
| API Gateway and security groups | A **public** endpoint has none — restrict callers with a resource policy, IAM, an authorizer or WAF. But a **private REST API** is fronted by an **interface VPC endpoint**, which *does* have a security group, so "security group" isn't automatically wrong once the stem says private |
| AWS-service integrations by API type | **REST**: non-proxy `AWS` integration, you map request/response. **HTTP**: first-class integrations using `AWS_PROXY` with a subtype (e.g. `SQS-SendMessage`). "Non-proxy only" is a REST rule, not an API Gateway rule |
| Retries: synchronous vs asynchronous | Synchronous = no Lambda retries at all; asynchronous = retries twice (3 attempts) then DLQ/destination |
| Event source mapping retry owner | The source's rules — for SQS, visibility timeout + maxReceiveCount → its DLQ, not Lambda's two retries |
| Which services are event source mappings, not async | SQS, Kinesis, DynamoDB Streams (Lambda polls). S3, SNS, EventBridge are asynchronous |
| Number of IAM roles on a Lambda | One role does both jobs — there is no Lambda "task role" |
| Reserved concurrency set to 0 | Disables the function |
| Reserved vs provisioned concurrency — what each solves | Reserved caps/guarantees a function's share; provisioned pre-initialises N environments to kill cold starts |
| Lambda log group name | /aws/lambda/<function-name> |
| Architectures supported by Lambda runtimes | "All supported Lambda runtimes support both x86_64 and arm64"; arm64/Graviton is cheaper per GB-second |

**DynamoDB indexes**

| | |
|---|---|
| LSI size limit | 10 GB total for all indexed items per partition key value |
| Max GSIs and LSIs per table | 20 GSIs (default), 5 LSIs |
| When each index can be created | GSI any time (add or delete freely); LSI at table creation ONLY — never added, never removed |
| Read consistency, GSI vs LSI | GSI eventual only; LSI eventual or strong |
| Partition key rule, GSI vs LSI | GSI any attribute; LSI must be the table's partition key (sort key required, any attribute) |
| Throughput source, GSI vs LSI | GSI has its own, separate from the table; LSI draws from the table's |

**DynamoDB Streams**

| | |
|---|---|
| Stream record retention | 24 hours, organised into shards |
| The four StreamViewType values | KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES |
| Can StreamViewType be changed later? | No — "not possible to edit a StreamViewType once a stream has been setup" |

**API Gateway**

| | |
|---|---|
| Default throttle limits | **10,000 RPS with a 5,000 burst bucket, per account per Region — *shared across* HTTP, REST and WebSocket APIs**, not per API. A few newer/smaller Regions default lower; adjustable via Service Quotas. AWS flags the mismatch itself: API Gateway defaults to 10,000 RPS while Lambda defaults to **1,000** concurrent executions |
| Features that force REST over HTTP API | Caching, API keys/usage plans, WAF, private VPC-only endpoint, edge-optimized, request validation, canary, X-Ray |
| Feature HTTP API has and REST does not | Native JWT authorizer (REST needs a Lambda authorizer) |
| The three authorizer types | IAM (AWS principal), Cognito (logged-in end user), Lambda authorizer (your own scheme) |
| What API keys and usage plans actually do | "Track and limit usage" — metering and throttling only; they are not authentication |
| Does API Gateway load balance across targets? | Only via HTTP API + Cloud Map (spreads over healthy instances) |

| WebSocket API — the two fixed timers | **Idle connection timeout 10 minutes**, **max connection duration 2 hours**, *neither increasable* — so heartbeats and reconnect logic are mandatory. **500** new connections/sec/account/Region (increasable); **no** concurrent-connection quota (ceiling ≈ rate × duration). Frame **32 KB**, message **128 KB**, both fixed; exceeding either closes with code **1009** |
| Circuit breaker `resetOnHealthyTask` | **`true` by default** — the failure count resets to 0 on every healthy task, so only **consecutive** failures count. Set `false` to accumulate across the whole deployment. Circuit breaker is **rolling-update (`ECS`) controller only** |

| Lambda layers | *".zip file archive that contains supplementary code or data"* — smaller packages, deps separate from logic, **sharing deps across functions**. **Max 5 per function**, **.zip only** (container images bake deps in). Can *increase* cold start (AWS: Go/Rust) |
| Lambda metric to alarm on for runaway scaling | **`ConcurrentExecutions`** — instances currently processing events; hitting the Region quota or the function's reserved concurrency causes **throttling**. Siblings: `ProvisionedConcurrentExecutions`, `ProvisionedConcurrencyUtilization` (**not emitted when idle** — breaks naive alarms), `UnreservedConcurrentExecutions`, `ClaimedAccountConcurrency` |

↳ [[17-containers]] · [[19-serverless]]


## Monitoring & Security

**CloudWatch metrics**

| | |
|---|---|
| Metric retention by data period | <60s: 3 hours · 60s: 15 days · 300s: 63 days · 3600s: 455 days (15 months) |
| CloudWatch agent default namespace | CWAgent — its metrics are billed as custom metrics |
| Standard vs high resolution granularity | standard = 1 minute; high resolution = 1 second |
| EC2 basic vs detailed monitoring interval | basic = every 5 minutes; detailed = 1 minute (costs extra) |
| EC2 metrics NOT available by default | memory utilisation and disk space used — in-guest, need the CloudWatch agent |

**CloudWatch alarms**

| | |
|---|---|
| Valid periods | metric stats: 1, 5, 10, 20, 30, n×60 s · alarms: 10, 20, 30, n×60 s |
| High-resolution alarm periods | 10, 20 or 30 seconds (costs more) |
| Alarm history retention / max alarms | history kept 30 days; no limit on number of alarms |
| When an alarm invokes its actions | only on state CHANGE; states OK / ALARM / INSUFFICIENT_DATA; ASG actions repeat once a minute |
| Composite alarm cannot do | EC2 or Auto Scaling actions (SNS, Lambda, OpsItems OK) |

**CloudWatch Logs**

| | |
|---|---|
| Alarm on log line containing ERROR | metric filter → metric → alarm (classic), or a log alarm |
| Ad-hoc query across log groups | CloudWatch Logs Insights |

**CloudTrail**

| | |
|---|---|
| Event history window and scope | past 90 days, management events only, per Region, free |
| Default trail / event data store contents | management events only — data and Insights events NOT logged by default |
| The four event types | management, data, network activity, Insights |
| Data event examples | S3 GetObject/PutObject, Lambda Invoke, DynamoDB item ops |
| What CloudTrail Insights detects | unusual API call rate or error rate vs your own account baseline |

**EventBridge & Config**

| | |
|---|---|
| EventBridge former name | CloudWatch Events — same service, renamed |
| "Was it ever open to 0.0.0.0/0 last month?" | Config (config history + can remediate); CloudTrail gives the caller only |

**KMS**

| | |
|---|---|
| Default RotationPeriodInDays | 365 days |
| AWS managed key rotation (currency warning) | every year — changed from every 3 years (~1,095 days) in May 2022 |
| On-demand rotations per key | maximum 25, quota not adjustable |
| Resource quotas | 100,000 customer managed keys/Region · 50 aliases/key · 50,000 grants/key · 10 custom key stores |
| Keys that cannot auto-rotate | Auto-rotation needs symmetric + AWS_KMS origin. Asymmetric, HMAC, custom key store: manual only. Imported (EXTERNAL): no auto, but on-demand OK |
| Encrypt max plaintext (SYMMETRIC_DEFAULT) | 4,096 bytes |
| What rotation does to your data | nothing — no re-encrypt, no data-key rotation, key ID unchanged |
| What GenerateDataKey returns | a plaintext data key plus an encrypted copy of the same key |
| AWS managed key policy editable? | no — cannot change it; customer managed key required for cross-account |

**Secrets & Parameter Store**

| | |
|---|---|
| Parameter Store Standard tier limits | 10,000 parameters, 4 KB, no policies, no cross-account, no charge |
| Parameter Store Advanced tier limits | 100,000 parameters, 8 KB, policies supported, shareable, charges apply |
| Parameter Store tier change direction | standard → advanced only; never advanced → standard |
| Secrets Manager max value size | 64 KB |
| Rotation discriminator | Secrets Manager rotates; Parameter Store does not (SecureString = encryption only) |

**Detection services**

| | |
|---|---|
| GuardDuty foundational data sources | CloudTrail management events, VPC Flow Logs, Route 53 Resolver DNS query logs — nothing to enable |
| Inspector scan targets | EC2 instances, ECR container images, Lambda functions — continuous, no scheduling |
| Macie scope | Amazon S3 only — not RDS, EBS, DynamoDB or EFS |
| Security Hub vs Detective | Security Hub aggregates findings; Detective investigates one finding's root cause |
| GuardDuty and Macie free trial | 30 days |

**Shield & WAF**

| | |
|---|---|
| WAF web ACL regional targets | ALB, API Gateway REST, AppSync, Cognito user pool, App Runner, Verified Access, Amplify |
| WAF cannot attach to | Network Load Balancer, or an EC2 instance directly |
| CloudFront-scope web ACL Region | hard-coded us-east-1 (N. Virginia); one web ACL per resource |
| ACM certificate Region for CloudFront | us-east-1 |
| Shield Advanced minimum commitment | **$3,000/month, 1-year commitment**; adds L7 DDoS protection, 24×7 SRT access, DDoS cost protection, and covers standard WAF costs **on protected resources** (not account-wide) |
| Shield Standard scope and cost | L3/L4 DDoS, free and automatic for all customers, no rules to configure |

**CloudHSM**

| | |
|---|---|
| CloudHSM exam trigger phrase | **single-tenant / dedicated** HSM, "we must control the keys", "AWS must have no access to the key material". **Drop "FIPS 140-3 Level 3" as a trigger** — AWS: "FIPS 140-3 Security Level 3 validated HSMs are deployed in all AWS Regions where AWS KMS is offered", so that phrase no longer points away from KMS. *(Corrected 2026-10-07.)* |
| ACM public certificate cost | **Non-exportable** (what you attach to an ALB/CloudFront/API Gateway): **no cost**. **Exportable** (since June 2025): **$7.00 per FQDN**, **$79.00 per wildcard**, charged at issuance *and* at each renewal |
| Can an ACM public certificate be exported? | **Yes, now** — `aws acm export-certificate` / `ExportCertificate` returns the cert, chain and a passphrase-encrypted **private key**. Two conditions keep the classic answer mostly alive: it must have been issued as **exportable**, and "ACM public certificates created prior to **June 17, 2025** cannot be exported" |
| Shield Advanced WAF coverage | Included on protected resources **up to 50 billion WAF requests/month** — covered, not uncapped |
| KMS automatic rotation — what is excluded | Asymmetric keys, HMAC keys, custom key stores, **and imported key material (`EXTERNAL` origin)**. AWS: automatic rotation is "supported only on symmetric encryption KMS keys with key material that AWS KMS generates (`AWS_KMS` origin)" |

| CloudWatch Logs retention — valid values | An **enumerated set of 22**, not any integer: **1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653**. Default = **never expire**; restore that by **deleting** the policy, not by setting a big number. Deletion lags *"up to 72 hours"* after expiry |
| `AWS/EC2` `Disk*` metrics scope | **Instance store volumes only** — *"If there are no instance store volumes, either the value is 0 or the metric is not reported."* EBS I/O lives in **two** places: per-volume `Volume*` in **`AWS/EBS`**, and per-instance `EBSReadOps`/`EBSWriteOps`/`EBSIOBalance%` in **`AWS/EC2`** itself (Nitro, non-bare-metal). Rule: `Disk*` = instance store, `EBS*`/`Volume*` = EBS |
| EventBridge ← CloudTrail API call | detail-type exactly **`AWS API Call via CloudTrail`**, source `aws.<service>`, **default bus only**. Needs a trail **actively logging**. The **rule** must be in the Region where the call happened (per-Region buses); the **trail** need not be — a multi-Region trail covers everywhere. IAM/STS/CloudFront global events land in **`us-east-1`** (since 22 Nov 2021) |
| Why an EventBridge rule on a `Describe*` never fires | Default rule state **`ENABLED`** matches only **write/mutating** management events. **Read-only** management events need state **`ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS`** |
| GuardDuty CloudWatch metrics | They **exist** — don't use "no metrics" as an elimination. `AWS/GuardDuty`: **hourly usage** metrics (`AnalyzedCount`, `AnalyzedBytes`, `MonitoredVcpuHours`, `MonitoredAcuHours`, `ScannedBytes`), dims `AccountId`/`DataSource`. `AWS/GuardDuty/MalwareProtection`: S3 scan counts. **But none counts findings** — so alarming on a *finding* is still **EventBridge → SNS** |
| `access-keys-rotated` Config rule | Checks **active** IAM access keys rotated within **`maxAccessKeyAge`** (int, **default 90** days). Trigger **Periodic**, resource `AWS::IAM::User`, and **excludes root-user access keys**. Remediation: Config `ComplianceChangeNotification` → EventBridge → Lambda |
| ACM imported certificates | A third-party CA cert **can** be imported, and behaves like an ACM-issued one **except that ACM gives it no managed renewal** — you own expiry and reimport. "Must auto-renew" eliminates it. The legacy **IAM** server-certificate store is the fallback where ACM is unsupported: **API-only** (`UploadServerCertificate`; *"you cannot manage your certificates from the IAM Console"*), and you **cannot** upload an ACM cert into IAM |
| KMS — deny is one-sided, quoted | *"(You can use an IAM policy to **deny** a permission to a KMS key **without permission from a key policy**.)"* vs the allow direction: *"Without permission from the key policy, IAM policies that allow permissions have no effect."* Governing rule: *"explicitly allowed, and **never denied**"* |

↳ [[20-monitoring]] · [[21-security]]


## Analytics, ML & Other Services

**Athena**

| | |
|---|---|
| Athena federated query minimum data scan | 10 MB minimum per query |
| Athena cost reduction, AWS's worked example | 12x cut: 3:1 compression, then Parquet columnar (~4x further) |
| Athena billing unit | Per TB scanned by default; Capacity Reservations bill per DPU-hour |
| Where a per-query data scan limit is set | On the Athena workgroup |

**Redshift**

| | |
|---|---|
| Redshift Spectrum Region constraint | **Scoped, not universal.** AWS: "For **RA3 and DC2 provisioned clusters** using Redshift Spectrum, the cluster and the Amazon S3 bucket must be in the same AWS Region. **Provisioned RG clusters and Amazon Redshift Serverless** … support querying Amazon S3 data **across AWS Regions**." Same-Region is still the expected exam answer. *(Corrected 2026-10-07.)* |
| Spectrum fact vs dimension table placement | Large fact tables in S3, smaller dimension tables in the cluster |
| Does Spectrum work without a cluster? | It needs **Redshift compute** — but that can be **Redshift Serverless**, which provisions no cluster. "Requires a running cluster" is out of date; "it is a Redshift feature, not a standalone service" is the durable point. If the stem wants S3 queried with **no Redshift at all**, that is **Athena** |
| Redshift's three speed mechanisms | Massively parallel processing (MPP) + columnar storage + compression encoding |
| Redshift vs RDS/Aurora, one word each | Redshift = OLAP; RDS/Aurora = OLTP |

**OpenSearch**

| | |
|---|---|
| OpenSearch Service scale ceiling | 1,002 data nodes and 25 PB of attached storage |
| Legacy Elasticsearch version supported | Elasticsearch OSS up to 7.10 |
| OpenSearch "domain" means | One cluster |
| OpenSearch cheap tiers for read-only indices | UltraWarm and cold storage |

**EMR**

| | |
|---|---|
| Which EMR node type stores HDFS data | Core (task stores none; primary coordinates); task is the usual Spot node |
| Instance groups vs instance fleets — when chosen | At cluster creation, and cannot be changed afterwards |
| Transient vs long-running cluster | Transient auto-terminates after its steps; long-running stays in WAITING |
| EMR: keep a failed cluster's data | Write to S3 (protection won't save HDFS) |

**QuickSight**

| | |
|---|---|
| SPICE stands for | Super-fast, Parallel, In-memory Calculation Engine |
| SPICE capacity allocation scope | Per AWS Region, shared across everyone using QuickSight in that account+Region |

**Glue & Lake Formation**

| | |
|---|---|
| Which engines read the Glue Data Catalog | Athena, EMR and Redshift Spectrum — one catalog, three engines |
| Athena Provisioned Capacity | **It exists** — Capacity Reservations at **$0.30 per DPU-hour**, dedicated capacity for predictable workloads, and it removes the 10 MB per-query minimum on federated queries. Don't reject an option just for naming it; it is simply not the fix for "this query scans too much data" (that's Parquet/ORC, compression, partitioning) |
| Analytics services with a Serverless flavour | **Redshift Serverless, EMR Serverless, OpenSearch Serverless** — so "Redshift/EMR/OpenSearch" no longer implies a cluster to manage. Read whether the stem names the serverless variant before applying the "least operational overhead ⇒ serverless" heuristic |
| Lake Formation — what it is | Permissions over the Glue Catalog, and it also ingests data into the lake |
| Glue visual editor vs no-code data prep | Glue Studio = visual job editor; Glue DataBrew = no-code data prep |

**Analytics renames & retirements**

| | |
|---|---|
| Kinesis Data Analytics now | Flink apps → Managed Service for Apache Flink; KDA for SQL discontinued |
| AWS Data Pipeline status | Closed to new customers, maintenance mode. In-scope in PDF guide v1.1, absent from docs guide; answer it if offered |
| QuickSight rename | Now Amazon Quick Sight; docs exam guide says Amazon Quick, PDF v1.1 says QuickSight |
| Analytics out of scope | CloudSearch (PDF v1.1); docs guide: none |
| Exam task statement covering analytics | Task Statement 3.5 — determine high-performing data ingestion and transformation solutions |

**ML exam scope**

| | |
|---|---|
| ML services in scope, and task statements | 8 in the online exam guide (11 in PDF v1.1); Task 2.2 names Comprehend and Polly |
| Amazon Personalize exam status | Explicitly OUT of scope (with Ground Truth, Data Wrangler, DeepRacer, Lookout family, Monitron) |

**ML currency**

| | |
|---|---|
| SageMaker rename | The ML service became **Amazon SageMaker AI** on 3 December 2024, and "Amazon SageMaker" was reused for a new unified data/analytics/AI platform. **On the exam, bare "Amazon SageMaker" means the ML service** |
| Amazon Forecast status | Closed to new customers → SageMaker Canvas; in PDF v1.1 only; answer if offered |
| Amazon Fraud Detector status | Closed to new customers 7 November 2025 → SageMaker, AutoGluon, AWS WAF. In the **PDF** exam guide v1.1, gone from the online guide — **answer it if it's offered** |
| Amazon Kendra status | Closed to new customers → Amazon Bedrock Knowledge Bases. In the **PDF** exam guide v1.1, gone from the online guide — **answer it if it's offered**, e.g. natural-language enterprise search |

**ML services**

| | |
|---|---|
| Textract sync vs async limit | Synchronous = single-page only; multi-page documents require the asynchronous operations |
| Textract specialised APIs | AnalyzeExpense (invoices/receipts), AnalyzeID (licences/passports), Queries, Analyze Lending |
| Rekognition vs Textract | Rekognition = images/video scenes **and text detection, including handwritten text**; Textract = documents — **structure**: forms, key-value pairs, tables, multipage. The axis is **structure**, not handwriting: AWS says Rekognition detects "printed and handwritten text". *(Corrected 2026-10-07.)* |
| Does ML appear in an SAA-C03 task statement? | **Yes, once** — **Task Statement 2.2** (Domain 2, resilient architectures, **26%** of scored content) lists "AWS managed services with appropriate use cases (for example, **Amazon Comprehend, Amazon Polly**)" |
| Transcribe vs Polly direction | Transcribe: audio → text. Polly: text → speech |
| Comprehend outputs | Entities, key phrases, PII, dominant language, sentiment, targeted sentiment, syntax, topic modeling |
| Comprehend vs Kendra | Comprehend analyses text; Kendra searches it (natural-language Q&A, semantic similarity) |

**Step Functions**

| | |
|---|---|
| Express workflow maximum duration | 5 minutes (Standard: 1 year) |
| Standard vs Express execution semantics | Standard = **exactly-once**. Express splits: **Asynchronous = at-least-once** (a step may run more than once), **Synchronous = at-most-once** (it may run fewer). Neither Express flavour is exactly-once. *(Corrected 2026-10-07 — this row gave only the async half.)* |
| Step Functions throughput quotas | `StateTransition`: Standard **5,000/sec** in N. Virginia / Oregon / Ireland, **800/sec** elsewhere; Express **unlimited**. `StartExecution`: Standard refills **300/sec** / **150/sec** on the same Region split; Express **6,000/sec**. Synchronous Express calls don't count against account capacity. **"2,000/sec" and "100,000/sec" are legacy figures AWS no longer publishes** |
| Services shut down that you may still meet on the exam | **QLDB** (end of support 31 Jul 2025) · **Elastic Transcoder** (13 Nov 2025 → MediaConvert) · **DMS Fleet Advisor** (20 May 2026) · **MediaStore** (12 Nov 2025). **Snow Family**: closed to *new* customers only — existing Snowball Edge users unaffected. Learn the concepts |
| Execution rate limits | Standard StartExecution 300/sec (150 most Regions); Express 6,000/sec |
| Pricing basis, Standard vs Express | Standard priced per state transition; Express by execution count + duration |
| Which pattern does human-in-the-loop approval | Wait for Callback (.waitForTaskToken) — Standard only; Express is Request Response only |
| Where Express execution history goes | CloudWatch Logs (Standard keeps it in Step Functions) |

**Directory Service**

| | |
|---|---|
| Directory option for RDS SQL Server | Managed Microsoft AD (or self-managed AD direct); not AD Connector, not Simple AD |
| Managed Microsoft AD object limits by edition | Standard ~30,000 objects; Enterprise ~500,000 (approximate) |
| Simple AD underlying technology and gaps | Samba 4; no MFA, trusts, schema extensions, LDAPS, or PowerShell AD cmdlets |
| AD Connector in three words | Proxy to on-premises — stores nothing, no sync, no federation |
| Identity service for a SaaS app's own end users | Amazon Cognito, not Directory Service |

**Transfer Family**

| | |
|---|---|
| FTP/FTPS data channel port range | Ports 8192–8200 |
| Protocols and targets | SFTP (v3)/FTPS/FTP → S3 or EFS; AS2 → S3 only; up to 3 AZs |
| Which protocol means B2B/EDI | AS2 |

**Batch & Beanstalk**

| | |
|---|---|
| Batch vs Lambda time limit | Batch has no time limit; Lambda caps at 15 minutes |
| What AWS Batch runs jobs on | Containers on Amazon ECS and EKS, over EC2, Fargate, and Spot/On-Demand |
| Elastic Beanstalk service charge | No additional charge — you pay only for the underlying AWS resources |
| Beanstalk supported platforms | Go, Java, .NET, Node.js, PHP, Python, Ruby, plus Docker |

**DMS**

| | |
|---|---|
| Heterogeneous migration needs which second tool | AWS SCT / DMS Schema Conversion for the schema; DMS moves only the data |
| On-prem DB inventory tool | DMS Fleet Advisor (ended 20 May 2026) |

**Well-Architected**

| | |
|---|---|
| Pillars with no exam domain of their own | Operational Excellence and Sustainability |
| The six pillars | Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability |
| SAA-C03 domain weightings | D1 Secure 30%, D2 Resilient 26%, D3 High-Performing 24%, D4 Cost-Optimized 20%; 14 task statements |
| Well-Architected Tool cost | No charge, in the AWS Management Console |

**Trusted Advisor**

| | |
|---|---|
| Checks available on Basic/Developer Support | All Service limits checks + EBS/RDS public snapshots, S3 bucket permissions, MFA on root, SG ports, STS endpoint |
| Number and names of check categories | Six: cost optimization, performance, security, fault tolerance, service limits, operational excellence |
| Support-plan restructuring | From **1 January 2027** Developer and Business are discontinued → **Business Support+**; Enterprise On-Ramp is auto-upgraded to **Enterprise Support**. **The exam still uses the old Business / Enterprise framing — answer with that** |
| Which plan gets the full Trusted Advisor check set | **Business Support+, Enterprise Support or Unified Operations** — "paid plan" is the wrong axis, since **Developer Support is paid and does not get it**. **Basic and Developer** get all **Service limits** checks plus six named Security/Fault-Tolerance checks (EBS/RDS public snapshots, S3 bucket permissions, MFA on root, Security Groups – Specific Ports Unrestricted, STS global endpoint usage). The Trusted Advisor **API** and EventBridge monitoring also need Business Support+ and above |
| Trusted Advisor Performance category — what it actually flags | High-CPU-utilisation EC2 instances, CloudFront cache-hit-ratio and content-delivery optimisation. **"Unrestricted" is Security vocabulary** ("Security Groups – Specific Ports Unrestricted"), not Performance |
| Trusted Advisor → CloudWatch alarms | **Yes, this works** — Trusted Advisor publishes to the **`AWS/TrustedAdvisor`** namespace (`RedResources`, `YellowResources`, `ServiceLimitUsage`; dimension `CheckName`), and AWS documents building an alarm → SNS on it. Metrics live in **us-east-1**; no metrics are sent for GreenResources. Eliminate Trusted Advisor for *coarseness*, never on "you can't alarm on it" |
| Systems Manager — which tool | **Run Command** = one-time at scale, against targets resolved *now*. **State Manager** = continuous desired state, re-applied to new nodes. **Patch Manager** = OS **and application** patching against a baseline (Windows app support = Microsoft-released apps only). **Maintenance Windows** = the *when*: a schedule with registered **targets and tasks** that invokes Run Command / Automation / Lambda / Step Functions — so it does cause work, it just isn't the thing that installs |
| "…and on every instance launched from now on" | That phrase moves the answer from **Run Command** to **State Manager**. Run Command does not re-run on instances created later |
| WA Tool vs Trusted Advisor vs Config | WA Tool reviews design; Trusted Advisor inspects resources; Config continuously evaluates + remediates |

| EMR runtime roles | An IAM role passed **at job-submission** time (`--execution-role-arn` on `add-steps`), so each job gets its own permissions instead of the cluster's **EC2 instance profile** — the multi-tenant-EMR answer. Needs a security configuration with `EnableApplicationScopedIAMRole: true`, plus `sts:AssumeRole` **and `sts:TagSession`**. Which role a submitter may pass is gated by **`elasticmapreduce:ExecutionRoleArn`**. A job under a runtime role **cannot reach IMDS**. `emr-6.7.0`+ |
| Transcribe Call Analytics does sentiment itself | **No Comprehend needed.** Native insight in both modes (*"Speaker sentiment"* / *"Real-time speaker sentiment"*): score **5 to −5** per quarter and overall, plus **positive/neutral/mixed/negative** per turn; usable as a custom-category rule. Not customisable. So: plain Transcribe or Transcribe Medical → sentiment needs **Comprehend**; **Call Analytics** → already included |

| Redshift DR across Regions | **Cross-Region snapshot copy** — a **cluster setting**, not a scheduled job you build. Copies **automated *or* manual** snapshots to **one destination Region at a time**; copied automated snapshots get **their own retention, default 7 days**; change destination = **disable then re-enable**; **KMS-encrypted** cluster needs a **snapshot copy grant** for a CMK **in the destination Region** |
| Redshift snapshot retention | Automated: Redshift-managed S3, default **1 day**, settable **1–35** on RA3/RG, `0` disables (not allowed on RA3/RG). Only Redshift deletes automated ones, and it *"retains the latest automated snapshot until you disable automated snapshots or delete the cluster."* **Manual: retained indefinitely**, even after the cluster is deleted |
| AppSync unit vs pipeline resolver | **Unit** = one operation, one data source. **Pipeline** = a request/response handler plus *"a list of functions"* run in sequence, each result passed on as `ctx.prev.result`; the pipeline resolver itself *"is not linked to any data source"*. So **one client call reads/writes across several DynamoDB tables server-side** — the answer for "aggregate multiple tables without hurting baseline performance". Not Lambda fan-out, not Athena Federated Query (analytical), not CloudFront Functions (can't reach DynamoDB) |

↳ [[22-analytics]] · [[23-machine-learning]] · [[24-other-services]] · [[25-well-architected]]
