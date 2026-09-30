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
| simulate-principal-policy verdict values | allowed / implicitDeny / explicitDeny (S3 returns a flat AccessDenied for both denials) |
| Does order, count or specificity matter? | No to all three — no specificity rule exists in IAM (that is NTFS ACLs) |

**Policy types & limits**

| | |
|---|---|
| Managed policy versions retained | Up to 5 versions, can roll back; inline policies have no versioning |
| AWS-managed policy ARN namespace | arn:aws:iam::aws:policy/… (customer-managed live in your account namespace) |
| Inline vs managed policy lifecycle | Inline dies with the principal, one principal only; managed is standalone and reusable |
| ListBucket scoping | `s3:ListBucket` is a **bucket-level** action — it takes the bare bucket ARN, **no `/*`**; object actions need `/*`. Getting it wrong fails silently. ⚠️ verify: that restricting a listing to a folder is done with a condition on `s3:prefix` |

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
| Which directory works with RDS for SQL Server | AWS Managed Microsoft AD only — AD Connector and Simple AD are not compatible |
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
| Boundary implicit deny vs resource policy | Implicit deny in a boundary does not limit resource-based policies; an explicit Deny does |
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
| Control types and their implementation | Preventive = SCPs; detective = AWS Config rules; proactive = CloudFormation hooks |
| SCP vs RCP scope | SCP limits principals in member accounts; RCP limits resources — both need Organizations all features |

↳ [[01-iam]] · [[01-iam-advanced]]


## EC2, EBS & AMIs

**EBS delete_on_termination**

| | |
|---|---|
| Extra EBS data volume — delete_on_termination default | **Console** at launch, or attached after launch: **Preserve** (false). At launch via **CLI/API**: **Delete** (true). Answer `false` on the exam; set it explicitly in practice |
| Data volume attached at launch via CLI/API — default | Delete |
| Data volume added via console at launch, or attached after launch | Preserve |
| Additional EBS volume default (the exam answer) | false — survives termination, still billing, attachable in the same AZ |
| Root volume default | true — deleted with the instance |

**T-family CPU credits**

| | |
|---|---|
| t3.micro max banked CPU credits | 288 (24h of earnings) |
| t3.micro CPU credit earn rate | 12 CPU credits/hour |
| T-family baseline CPU | **Varies by size** — baseline % per vCPU = (credits earned per hour ÷ vCPUs) ÷ 60. `t3.nano` **2.5%**, `t3.micro` **10%**, `t3.small`/`medium` **20%**, `t3.large` **30%**. Never quote one size's baseline for the family |
| T3 default credit mode | **unlimited** (T2 defaults to *standard*). The burst always succeeds and is **free while average CPU stays at or below baseline over a rolling 24 hours**; only sustained excess bills, at a flat rate per vCPU-hour |
| Metric to alarm on for surplus billing | CPUSurplusCreditsCharged |
| The three burstable CloudWatch metric names | CPUCreditBalance, CPUSurplusCreditBalance, CPUSurplusCreditsCharged |
| Standard mode at zero credit balance | pinned at baseline (~10% CPU on t3.micro) — CPUCreditBalance flatlined at 0 |

**IMDS**

| | |
|---|---|
| IMDSv2 PUT response IP hop limit | 1 — the token cannot leave the instance |
| IMDSv2 token max lifetime | up to 6h, and instance-specific |
| IMDSv2 token request header name | X-aws-ec2-metadata-token-ttl-seconds (on the PUT); example value 21600 |
| IMDSv2 header carried on every GET | X-aws-ec2-metadata-token |
| IMDSv2 rejects a PUT carrying which header? | X-Forwarded-For |
| Symptom of skipping the IMDSv2 token | empty / 401, silently — not a permissions error |
| IMDS endpoint address | 169.254.169.254, link-local, reachable only from inside the instance |
| Token flow order | PUT /latest/api/token first, then GET with the token header |
| IMDSv1 vs IMDSv2 default | v1 was default until ~2023; v2 required by default on Ubuntu 24.04 noble, recent AL2023 |

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
| Which wins, subnet map_public_ip_on_launch or instance setting? | associate_public_ip_address at launch overrides the subnet in either direction |
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
| Instance ID after terminate | released, can never be reused |
| Private IP on stop vs terminate | preserved on stop; released on terminate |
| EIP on terminate | disassociated; the EIP is retained in your account |
| Only way to move an instance to another AZ | snapshot and relaunch — stop/start cannot change AZ |

**Instance types**

| | |
|---|---|
| Family letters | t burstable, m general, c compute, r memory, g/p GPU, i storage |
| Generation suffixes a and g | t3a = AMD, t4g = Graviton/ARM |
| Instance type separator | family.size with a literal period; t3-micro is rejected with InvalidParameterValue |
| Instance-type change vs AMI change | Instance type: **stop-modify-start**, ~1–3 min downtime, same instance ID, EBS and EIP kept. AMI: **cannot** change in place — launch a replacement |
| Attributes that force instance replacement | ami, subnet_id, key_name, associate_public_ip_address; in-place: instance_type, SG ids, instance profile |

**AMI**

| | |
|---|---|
| AMI scope and how to move one | region-scoped — ami-… is unique per region; copy with aws ec2 copy-image |
| What an EBS-backed AMI actually is | metadata (kernel, architecture, virtualization type) plus references to EBS snapshots |
| Accepted ip_protocol values | tcp, udp, icmp, icmpv6, -1 — never "ssh"/"http" |

**EC2 identity**

| | |
|---|---|
| What EC2 is handed — role or instance profile? | instance profile wrapping the role; Lambda and ECS take a role directly |

**AMI baking (Packer)**

| | |
|---|---|
| Deleting an AMI leaves what behind? | the backing EBS snapshot — needs both deregister-image and delete-snapshot |
| Boot time baked vs user_data install | ~30 sec vs 2–5 min |
| ami_name collisions | must be unique — Packer refuses to overwrite an existing name |
| Tag argument for the snapshot, not the AMI | snapshot_tags (AMI uses tags) |
| AWS-native managed equivalent of a Packer pipeline | EC2 Image Builder — test-before-distribute, multi-region, cross-account via AWS RAM, STIG components |
| Currency warning — apt install awscli on Ubuntu 24.04 | no longer available; use the AWS official installer or snap install aws-cli --classic |

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
| Putting an ALB behind an NLB | Target group target_type = "alb", protocol TCP, one ALB per target group |
| Static IP — ALB vs NLB | ALB: DNS name only. NLB: one static IP per AZ, can attach an EIP |
| Client source IP — ALB vs NLB | ALB terminates the connection, adds X-Forwarded-For; NLB preserves source IP natively |
| NLB flow hash inputs | ⚠️ verify: protocol + source/destination IP + source/destination port — and whether the **TCP sequence number** is included (the notes state it both ways). GWLB uses a 5-tuple flow hash |
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
| ASG health_check_type default | EC2 — hypervisor status checks only; ELB must be set explicitly |
| Which check decides what | Target-group health check = routing; ASG health_check_type = replacement |
| Does the ALB terminate an unhealthy instance | No — it only stops routing; termination is the ASG's job, only with health_check_type ELB |
| When a failed health check is user-visible | Only when NO targets are healthy; with ≥1 healthy the ALB routes around it silently |
| Time to ELB-healthy with boot-time apt install | ~180s = boot ~30s + apt install nginx ~60s + health-check convergence ~90s |
| Health-check convergence arithmetic | HealthyThresholdCount × HealthCheckIntervalSeconds. **ALB defaults: 5 × 30s = 150s** to be marked healthy; UnhealthyThresholdCount default **2** (so ~60s to be pulled). Thresholds range 2–10, interval 5–300s |
| Safe health_check_grace_period values | ~300s with boot-time install; ~40s time-to-healthy with a baked AMI |

**Target tracking**

| | |
|---|---|
| Predefined metrics | ASGAverageCPUUtilization, ASGAverageNetworkIn, ASGAverageNetworkOut, ALBRequestCountPerTarget |
| Alarms it auto-creates for a CPU target of 50 | AlarmHigh at 50% (scale out), AlarmLow at 35% (scale in) — AWS-managed, don't edit |
| Can lowering target_value force a scale-out | No — it never scales out while the metric is below target; only triggers scale-in |
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
| ASG detection lag after out-of-band termination | ~1–2 min periodic health-check cycle; Activity tab is the authoritative log |

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
| The two conditions for a subnet to be public | 0.0.0.0/0 → IGW in its route table AND a public IP (map_public_ip_on_launch or EIP) |
| IGW count, direction and cost | One per VPC, bidirectional, no bandwidth limit, free (pay data transfer only) |

**NAT**

| | |
|---|---|
| NAT gateway bandwidth | 5 Gbps, scaling automatically to 100 Gbps |
| NAT gateway security group | None — there is nothing to attach |
| The one IPv6 job a NAT gateway does | NAT64 (always on), paired with DNS64 on the subnet |
| NAT instance's required non-default setting | Source/destination check disabled (legacy option; gateway has no equivalent) |
| Which subnet the NAT gateway lives in | A public subnet |
| NAT gateway resilience scope | AZ-scoped; redundant only within its own AZ — one per AZ for HA |
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
| OS-specific ephemeral port ranges | Linux 32768–60999; Windows 2008+ 49152–65535; ELB/Lambda/NAT 1024–65535 |
| Which direction the ephemeral rule goes | Receiving requests → outbound; initiating requests → inbound |
| Ephemeral range to open on a NACL | 1024–65535 |
| Traffic a NACL cannot filter at all | Amazon-provided DNS resolver (VPC+2) and the Amazon Time Sync Service |

**Flow Logs**

| | |
|---|---|
| max_aggregation_interval values | 600s default, or 60s — no other value |
| Delivery lag on top of the aggregation interval | ~5 more minutes to CloudWatch Logs, ~10 to S3 |
| Protocol numbers in a flow log record | 6 = TCP, 17 = UDP, 1 = ICMP |
| Traffic never logged by flow logs | Amazon DNS (custom DNS is logged), DHCP, 169.254.169.254, 169.254.169.123, Windows activation, VPC router IP |
| Third destination, and its rename | Amazon Data Firehose — renamed from Kinesis Data Firehose; older material uses the old name |
| Attachment levels | VPC, subnet, or ENI |
| What they contain vs never contain | Connection metadata + ACCEPT/REJECT; never payload (that's Network Firewall / Traffic Mirroring) |

**Network Firewall**

| | |
|---|---|
| Rule engine it is built on | Suricata — stateful IPS, deep packet inspection + domain filtering |
| Where the endpoint sits | Its own dedicated firewall subnet; route tables must redirect traffic to it |

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
| The three peering limits | Non-transitive, no overlapping CIDRs, no edge-to-edge routing (no peer's IGW/NAT/VPN/endpoints) |
| Transit Gateway shape and scale | Regional hub, one attachment per VPC/VPN/DX, transitive, scales to thousands of attachments |

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
| Hosted DX connection speeds | 50 Mbps–25 Gbps via a partner — the only route to a sub-1 Gbps link |
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
| Transport encryption | **With IAM DB authentication: always SSL/TLS** (the token is only valid over TLS). With a native password or Secrets Manager, TLS is **optional** — you must require it |
| PostgreSQL rds_iam role precedence | IAM auth takes precedence over password auth for that user; no Kerberos, no replication connections |
| Default state of the feature | Off by default |

**Aurora storage**

| | |
|---|---|
| Cluster volume auto-scaling range | 10 GB → 128 TiB (256 TiB on the newest engine versions) |
| Copies and AZ spread | 6 copies across 3 AZs — 2 per AZ, one shared cluster volume |
| Loss tolerance for reads | A whole AZ plus one more copy |

**Aurora features**

| | |
|---|---|
| Aurora replica lag | <10 ms typical (note also states "well under 100 ms") |
| Global Database secondary regions | 1 primary + up to 10 read-only secondary regions, <1s replication |
| The four endpoint types | writer/cluster, reader (LB'd reads), custom, instance |
| Serverless v2 capacity unit and instance class | Capacity is measured in **ACUs** (minimum 0.5). ⚠️ verify: the instance class name `db.serverless` |
| Backtrack engine support | Aurora MySQL only — rewinds the DB in place, no restore |
| Throughput claim vs stock engines | ~5× MySQL / 3× PostgreSQL |
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
| Free Plan backup retention guardrail | retention 7 fails with FreeTierRestrictionError; 1 is accepted |

**ElastiCache engines**

| | |
|---|---|
| Threading, per engine | Redis single-threaded (one core/node); Memcached multi-threaded |
| Auto Discovery availability | Memcached only — AWS states it is NOT available for Valkey or Redis OSS |
| Auto Discovery client requirement | An ElastiCache client library with Auto Discovery support |
| Memcached persistence | **None at all** — no replication, no failover, no persistence, no backup. A dead node's data is gone |
| What Memcached lacks, exactly | No replication, no failover, no persistence, no backup |
| Valkey, one line | AWS-backed open-source Redis fork after Redis's licence change; ≈ Redis, minus Auto Discovery |

**ElastiCache Redis HA**

| | |
|---|---|
| Replication group size | 1 primary + up to 5 read replicas |
| Minimum nodes for auto-failover / Multi-AZ | **2** — Multi-AZ with automatic failover requires a cluster **with at least one replica**, so 1 primary + 1 replica. Max **5** read replicas per shard |
| Redis port | ⚠️ verify: 6379 (Memcached 11211) — widely known but not confirmed against AWS docs in this vault |

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
| Glacier Flexible vs Deep Archive retrieval times | Flexible: Expedited 1–5 min, Standard 3–5 h, Bulk 5–12 h · Deep Archive: no Expedited, Std ~12 h, Bulk ~48 h |
| One Zone-IA vs Standard-IA | Same 11 nines; One Zone-IA = 1 AZ, 99.5% availability, re-creatable data only |
| Glacier Instant Retrieval speed | Milliseconds — no restore job at all |
| Durability and AZ count | **"Designed for"** 99.999999999% (11 nines) on every current class; **≥3 AZs**. One Zone classes: **1 AZ**, same 11 nines **but the data is lost if that AZ is destroyed**. Legacy exception: Reduced Redundancy Storage, **99.99%** |

**S3 encryption**

| | |
|---|---|
| SSE-C availability change | ⚠️ Disabled by default on all new general-purpose buckets since April 2026; must be re-enabled deliberately |
| DSSE-KMS | Two independent AES-256 layers |
| Which options can be bucket default encryption | SSE-S3, SSE-KMS, DSSE-KMS — never SSE-C |
| Re-encrypt objects already in the bucket | S3 Batch Operations → Copy (changing the default only affects new writes) |
| Encryption automatic since when | SSE-S3 on every object since 5 January 2023 |
| Header value: SSE-S3 vs SSE-KMS | AES256 = SSE-S3; aws:kms = SSE-KMS |
| Cut SSE-KMS request cost | S3 Bucket Keys — short-lived bucket-level data key |
| Condition key that enforces TLS | aws:SecureTransport = false (deny it in the bucket policy) |

**S3 Object Lock**

| | |
|---|---|
| Object Lock delete asymmetry | DELETE with a version id → 403 AccessDenied; DELETE without → 200 OK + delete marker |
| GOVERNANCE mode bypass requirements | s3:BypassGovernanceRetention + header x-amz-bypass-governance-retention:true |
| Retention vs legal hold | Retention = a fixed *Retain Until Date*; **extend always, shorten only in GOVERNANCE mode with `s3:BypassGovernanceRetention`** — in COMPLIANCE mode nobody, not even root, can shorten it. Legal hold = no expiry, removed by an explicit call |
| COMPLIANCE mode escape hatch | None — not even root; AWS's documented way out before expiry is closing the AWS account |
| When Object Lock can be enabled / disabled | At bucket creation or on an existing versioned bucket; can never be turned off, versioning can't be suspended |
| MFA Delete — who can configure it | **Root** account with an MFA device, via the **CLI only** — not an IAM user, not the console |

**S3 replication**

| | |
|---|---|
| Batch Replication — the four cases it covers | Pre-existing objects, FAILED replications, newly-added destination, replicas-of-replicas |
| What a live replication rule copies | Only objects created or updated AFTER the rule existed |
| S3 RTC guarantee | 99.99% of new objects replicated within 15 minutes, SLA-backed + CloudWatch replication metrics |
| Is replication chained / transitive? | No — A→B and B→C does not get A's objects to C |
| Delete replication behaviour | Delete markers not replicated unless opted in; deleting a specific version is NEVER replicated |
| Replication prerequisites | Versioning on BOTH buckets + an IAM role S3 assumes; replication is asynchronous |

**S3 access control**

| | |
|---|---|
| Block Public Access — the four setting names | BlockPublicAcls · IgnorePublicAcls · BlockPublicPolicy · RestrictPublicBuckets (new vs existing × ACL vs policy) |
| Bucket policy max size | 20 KB |
| BPA vs a public bucket policy | BPA overrides the policy; settable per-bucket and account-wide, most restrictive combination wins |
| Setting that disables ACLs | BucketOwnerEnforced — the default for buckets created since April 2023 |
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
| Failover time formula | (health check interval × failure threshold) + TTL; default-ish (30s × 3) + TTL |

**Route 53 routing policies**

| | |
|---|---|
| The eight routing policies | simple · weighted · latency · failover · geolocation · geoproximity · multivalue answer · IP-based |
| Multivalue answer — how many records returned | Up to 8 healthy records, randomly ordered |
| Meaning of weight 0 | Never return this record |
| Geolocation catch-all for unmatched locations | A record with country `*` as the default |
| Simple routing — health checks? | None; returns all values in random order, client picks |
| Geolocation vs geoproximity | Geolocation reads where the USER is; geoproximity reads where your RESOURCES are, plus a bias |

**Route 53 alias vs CNAME**

| | |
|---|---|
| TTL on an alias record | You cannot set one — it uses the target's TTL |
| Query cost: alias vs CNAME | Alias to AWS resources is free; a CNAME to another Route 53 record bills as two queries |
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
| What skips the regional edge cache | Dynamic requests and PUT/POST go straight to the origin |
| Free invalidation allowance | First 1,000 paths per month per AWS account; a path containing `*` counts as one path |
| Price class coverage | PriceClass_100 = US/Canada/Europe/Israel; _200 adds most of Asia, Middle East, Africa; _All = everywhere |
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
| Functions vs Lambda@Edge — language | JavaScript (ECMAScript 5.1) vs Node.js and Python |

**Global Accelerator**

| | |
|---|---|
| Addresses it gives you | Two static anycast IPs (four dual-stack), and they never change |
| Valid endpoint types | NLB, ALB, EC2, Elastic IP |
| Caching and protocols | Caches nothing; routes any TCP/UDP |

**CloudFront private content**

| | |
|---|---|
| Signed URL vs signed cookies | Signed URL = one individual file; signed cookies = multiple files |

↳ [[10-route53]] · [[11-cloudfront]]


## EFS, FSx, Gateway & Transfer

**Snow Family**

| | |
|---|---|
| Snowball Edge current availability | No longer available to new customers — AWS directs to DataSync, AWS Data Transfer Terminal, or Outposts |
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
| FSx for NetApp ONTAP protocols | Both NFS and SMB |
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
| The four gateway types | S3 File Gateway, FSx File Gateway, Volume Gateway, Tape Gateway |

**DataSync**

| | |
|---|---|
| DataSync sources | On-prem NFS, SMB, HDFS, object storage; and other clouds (Azure Blob/Files, GCS) |
| DataSync destinations | S3, EFS, FSx for Windows / Lustre / OpenZFS / NetApp ONTAP |
| DataSync vs Storage Gateway | DataSync transfers (one-off or scheduled); Storage Gateway is a permanent bridge |

**AWS Backup**

| | |
|---|---|
| Vault Lock compliance mode grace time minimum | 3 days |
| Vault Lock governance vs compliance mode | **Governance**: unlockable by anyone holding the IAM permission. **Compliance**: unlockable by nobody, including AWS — **but only once the grace period expires** (minimum **3 days**). During that window it is still cancellable, which is what an "accidentally locked vault" question turns on |
| AWS Backup cross-account copy requirement | An AWS Organizations structure |
| AWS Backup incremental vs full | Incremental for supported resource types; others are full copies each time |
| AWS Backup resource assignment method | By tag (plus Vault Lock = WORM) |

**Storage shapes**

| | |
|---|---|
| Block / file / object → services | Block = EBS, instance store; File = EFS, FSx; Object = S3, Glacier |

↳ [[12-storage-extras]]


## Cost & Disaster Recovery

**Savings Plans**

| | |
|---|---|
| Does a Savings Plan reserve capacity? | No — billing discount only, never reserves capacity |
| EC2 Instance Savings Plan max discount | up to 72% — locked to one instance family in one Region |
| Compute Savings Plan max discount | up to 66% — flexible on family, size, Region, OS, tenancy |
| Which purchases actually reserve capacity | only zonal Reserved Instances and Capacity Reservations |
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
| Compute Optimizer metric lookback | last 14 days of CloudWatch metrics; 93 days with paid enhanced infrastructure metrics |
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
| S3 Replication Time Control SLA | 99.9% of objects within 15 minutes |
| S3 CRR and delete markers | not replicated by default |
| DynamoDB Global Tables conflict handling | multi-active read/write everywhere; last writer wins |
| Elastic Disaster Recovery (DRS) RTO/RPO | RTO of minutes, RPO of seconds; implements pilot light; does not cover RDS |
| CloudFront origin failover granularity | per request — later requests still try the primary first |

**DR operations**

| | |
|---|---|
| Data plane vs control plane failover | data: Route 53 health checks, Application Recovery Controller; control: R53 weights, GA traffic dial, Auto Scaling |
| What is inside the RTO clock | detection, notification, escalation, evaluation, declaration — clock starts at the failure |
| Static stability | provision full capacity so recovery doesn't depend on Auto Scaling |
| DR-Region drift tooling | AWS Config detects, SSM Automation remediates, CloudFormation drift detection for stacks |

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
| Deduplication window | 5 minutes |
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
| ActiveMQ wire protocols | AMQP, MQTT, OpenWire, STOMP (plus MQTT and STOMP over WebSocket) |
| RabbitMQ wire protocol | AMQP 0-9-1 |
| Storage per deployment mode | single-instance: EBS or EFS, one AZ; active/standby: EFS only, two AZs, one active |
| Supported engines | Apache ActiveMQ Classic or RabbitMQ |
| Billing unit | per broker-hour — a running server, not serverless |

**Kinesis Data Streams**

| | |
|---|---|
| Record size — AWS pages disagree | concepts page says up to 1 MB, quotas page says 10 MiB burst; 1 MB is the classic exam answer |
| Single GetRecords call max return | 10 MB or 10,000 records; if it returns 10 MB, calls in the next 5 seconds throw |
| Capacity mode switches allowed | twice in 24 hours |
| On-demand starting throughput | 4 MB/sec write, 8 MB/sec read for a new stream |
| On-demand maximum throughput | 10 GB/s write / 20 GB/s read in N. Virginia, Oregon, Ireland; 200 MB/s / 400 MB/s elsewhere |
| Partition key — length and hash | Unicode string up to 256 characters, mapped to a shard by MD5 hash; required on every write |
| Retention — default / min / max | default and minimum 24 hours; maximum 8,760 hours (365 days); above 24 h costs extra |
| Per-shard write limit | 1 MB/sec OR 1,000 records/sec — whichever binds first |
| Per-shard read limit | **2 MB/sec out** per shard, max **5 `GetRecords`/sec** — **shared across all consumers only under the default shared fan-out**. With **enhanced fan-out** each registered consumer gets its own 2 MB/sec per shard (`SubscribeToShard`, pushed). "Several consumers each needing full throughput" → enhanced fan-out |
| Free tier | none — Kinesis Data Streams has no free tier |

**Kinesis consumers**

| | |
|---|---|
| Where the KCL stores consumption state | DynamoDB — three tables per application |
| Registered (enhanced fan-out) consumers per stream | up to 20 (50 on On-demand Advantage) |
| Enhanced fan-out API and throughput | SubscribeToShard, pushed; own 2 MB/sec per shard per registered consumer |

**Firehose**

| | |
|---|---|
| Firehose max record size | 1,000 KB |
| Firehose buffering trigger | size (MB) or interval (seconds) — whichever threshold trips first |
| Firehose Redshift delivery path | delivered to S3 first, then loaded with a COPY |
| Firehose destinations | S3, Redshift, OpenSearch Service/Serverless, Splunk, Apache Iceberg, custom HTTP endpoints, partners |
| Firehose shards and retention | none of either — no replay |

**Messaging discriminators**

| | |
|---|---|
| SQS vs Kinesis after a consumer reads | SQS: deleted. Kinesis: stays until retention expires (no delete operation) |
| Data Streams vs Firehose | Streams stores, you build the consumer; Firehose delivers, you build nothing |
| Kinesis ordering scope | within a shard, not across the stream |
| Standard vs FIFO delivery guarantee | Standard: **at-least-once**, best-effort order. FIFO: **exactly-once**, strict order **per `MessageGroupId`** — *not* across the queue. Different groups have no defined order relative to each other and process in parallel |
| SQS vs SNS delivery direction | SQS: consumer pulls, one consumer. SNS: pushes to every subscriber |
| A2A vs A2P support | SNS: A2A and A2P. SQS: A2A only |
| Amazon MQ vs SQS/SNS trigger | existing app on a standard broker protocol, no rewrite → MQ; anything new → SQS/SNS |

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
| Valid memory values when Fargate cpu = 256 | 512, 1024, 2048 MiB only; an invalid pair fails at apply with ClientException, not at plan |
| ALB target group algorithms | round_robin, least_outstanding_requests, weighted_random — default round_robin |
| Fargate network mode | awsvpc only — every task gets its own ENI and private IP |
| ALB target_type for Fargate | ip — never instance; wrong value applies cleanly, registers nothing, ALB returns 503 |
| Task definition identifier format | family:revision — immutable; you register a new revision, never edit one |
| Fargate Spot discount | Up to 70% off for interruption-tolerant tasks |
| ECS containment hierarchy | Cluster → Service → Task → Container(s) |

**ECS vs EKS**

| | |
|---|---|
| Control plane cost, ECS vs EKS | ECS control plane free; EKS $0.10 per cluster per hour (standard support) whether or not anything runs |

**ECS IAM**

| | |
|---|---|
| Execution role vs task role — who uses it | Execution role = the ECS/Fargate agent; task role = your application code |
| What the execution role is actually required for | Private ECR pulls, the awslogs driver, Secrets Manager/SSM refs — NOT for a public Docker Hub pull |
| Execution role trust principal and managed policy | Trusts ecs-tasks.amazonaws.com; attach AmazonECSTaskExecutionRolePolicy |
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
| Timeout ceiling | 900 seconds (15 minutes) |
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
| Default throttle limits | 10,000 requests/second per account per Region, burst bucket 5,000 |
| Features that force REST over HTTP API | Caching, API keys/usage plans, WAF, private VPC-only endpoint, edge-optimized, request validation, canary, X-Ray |
| Feature HTTP API has and REST does not | Native JWT authorizer (REST needs a Lambda authorizer) |
| The three authorizer types | IAM (AWS principal), Cognito (logged-in end user), Lambda authorizer (your own scheme) |
| What API keys and usage plans actually do | "Track and limit usage" — metering and throttling only; they are not authentication |
| Does API Gateway load balance across targets? | No — exactly one integration per route; an ALB does load balance |

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
| Valid alarm / metric periods | 1, 5, 10, 30, or any multiple of 60 seconds |
| High-resolution alarm periods | 10 or 30 seconds (costs more) |
| Alarm history retention / max alarms | history kept 30 days; no limit on number of alarms |
| When an alarm invokes its actions | only on state CHANGE; states OK / ALARM / INSUFFICIENT_DATA; ASG actions repeat once a minute |
| Composite alarm cannot do | EC2 actions or Auto Scaling actions (SNS only) |

**CloudWatch Logs**

| | |
|---|---|
| Alarm on a log line containing ERROR | not possible directly — metric filter → metric → alarm |
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
| Keys that cannot auto-rotate | Automatic rotation works **only on symmetric encryption keys whose key material AWS KMS generated**. So asymmetric, HMAC, custom-key-store **and imported (BYOK) key material** are all manual-only — the list is a rule, not three exceptions |
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
| CloudHSM exam trigger phrase | single-tenant dedicated HSM, "we must control the keys", FIPS 140-3 Level 3 |

↳ [[20-monitoring]] · [[21-security]]


## Analytics, ML & Other Services

**Athena**

| | |
|---|---|
| Athena federated query minimum data scan | 10 MB minimum per query |
| Athena cost reduction, AWS's worked example | 12x cut: 3:1 compression, then Parquet columnar (~4x further) |
| Athena billing unit | Data scanned off S3 (per TB) — nothing to resize, it is serverless |
| Where a per-query data scan limit is set | On the Athena workgroup |

**Redshift**

| | |
|---|---|
| Redshift Spectrum Region constraint | Cluster and the S3 data must be in the same AWS Region |
| Spectrum fact vs dimension table placement | Large fact tables in S3, smaller dimension tables in the cluster |
| Does Spectrum work without a cluster? | No — Spectrum is a Redshift feature and requires a running cluster |
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
| Which EMR node type stores HDFS data | Core (task nodes store none; primary coordinates) — task is the Spot node |
| Instance groups vs instance fleets — when chosen | At cluster creation, and cannot be changed afterwards |
| Transient vs long-running cluster | Transient auto-terminates after its steps; long-running stays in WAITING |
| What stops a failed cluster deleting its data | Termination protection enabled |

**QuickSight**

| | |
|---|---|
| SPICE stands for | Super-fast, Parallel, In-memory Calculation Engine |
| SPICE capacity allocation scope | Per AWS Region, shared across everyone using QuickSight in that account+Region |

**Glue & Lake Formation**

| | |
|---|---|
| Which engines read the Glue Data Catalog | Athena, EMR and Redshift Spectrum — one catalog, three engines |
| Lake Formation — what it actually is | An authorization layer over the Glue Data Catalog; stores no data itself |
| Glue visual editor vs no-code data prep | Glue Studio = visual job editor; Glue DataBrew = no-code data prep |

**Analytics renames & retirements**

| | |
|---|---|
| Kinesis Data Analytics is now called | Amazon Managed Service for Apache Flink — renamed 30 August 2023 |
| AWS Data Pipeline status | Closed to new customers, maintenance mode; console removed 30 April 2023 (CLI/API only) |
| QuickSight rename | Now "Amazon Quick Sight", a feature within Amazon Quick; exam still says QuickSight |
| Only analytics service explicitly out of scope | Amazon CloudSearch |
| Exam task statement covering analytics | Task Statement 3.5 — determine high-performing data ingestion and transformation solutions |

**ML exam scope**

| | |
|---|---|
| How many ML services are in scope, and task statements | 11 in-scope ML services; zero task statements name machine learning |
| Amazon Personalize exam status | Explicitly OUT of scope (with Ground Truth, Data Wrangler, DeepRacer, Lookout family, Monitron) |

**ML currency**

| | |
|---|---|
| SageMaker rename | Amazon SageMaker AI as of 3 December 2024; "SageMaker" reused for the unified platform |
| Amazon Forecast status | Closed to new customers 29 July 2024 → SageMaker Canvas; still exam-answerable |
| Amazon Fraud Detector status | Closed to new customers 7 November 2025 → SageMaker, AutoGluon, AWS WAF. **Still in the SAA-C03 exam guide — still answer it on the exam.** Legacy in the real world, not in the question bank |
| Amazon Kendra status | Closed to new customers → Amazon Bedrock Knowledge Bases. **Still in the SAA-C03 exam guide — still answer it on the exam**, e.g. natural-language enterprise search. Do not eliminate it for being legacy |

**ML services**

| | |
|---|---|
| Textract sync vs async limit | Synchronous = single-page only; multi-page documents require the asynchronous operations |
| Textract specialised APIs | AnalyzeExpense (invoices/receipts), AnalyzeID (licences/passports), Queries, Analyze Lending |
| Rekognition vs Textract | Rekognition = images/video scenes; Textract = documents, forms, tables, handwriting |
| Transcribe vs Polly direction | Transcribe: audio → text. Polly: text → speech |
| Comprehend outputs | Entities, key phrases, PII, dominant language, sentiment, targeted sentiment, syntax, topic modeling |
| Comprehend vs Kendra | Comprehend analyses text; Kendra searches it (natural-language Q&A, semantic similarity) |

**Step Functions**

| | |
|---|---|
| Express workflow maximum duration | 5 minutes (Standard: 1 year) |
| Standard vs Express execution semantics | Standard = exactly-once; Express = at-least-once |
| Execution rate limits | Standard 2,000/sec (4,000 state transitions/sec); Express 100,000/sec |
| Pricing basis, Standard vs Express | Standard priced per state transition; Express by execution count + duration |
| Which pattern does human-in-the-loop approval | Wait for Callback (.waitForTaskToken) — Standard only; Express is Request Response only |
| Where Express execution history goes | CloudWatch Logs (Standard keeps it in Step Functions) |

**Directory Service**

| | |
|---|---|
| Which directory option works with RDS for SQL Server | Only AWS Managed Microsoft AD — AD Connector and Simple AD are both incompatible |
| Managed Microsoft AD object limits by edition | Standard ~30,000 objects; Enterprise ~500,000 (approximate) |
| Simple AD underlying technology and gaps | Samba 4; no MFA, trusts, schema extensions, LDAPS, or PowerShell AD cmdlets |
| AD Connector in three words | Proxy to on-premises — stores nothing, no sync, no federation |
| Identity service for a SaaS app's own end users | Amazon Cognito, not Directory Service |

**Transfer Family**

| | |
|---|---|
| FTP/FTPS data channel port range | Ports 8192–8200 |
| Protocols and targets | SFTP (v3), FTPS, FTP, AS2 → into Amazon S3 or Amazon EFS; up to 3 AZs |
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
| Tool that inventories on-prem database estate | DMS Fleet Advisor |

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
| Support-plan restructuring | Developer, Business and Enterprise On-Ramp discontinued 1 January 2027, replaced by Business Support+ |
| What requires a paid support plan | Full check set, the Trusted Advisor API, and EventBridge monitoring |
| WA Tool vs Trusted Advisor vs Config | WA Tool reviews design; Trusted Advisor inspects resources; Config continuously evaluates + remediates |

↳ [[22-analytics]] · [[23-machine-learning]] · [[24-other-services]] · [[25-well-architected]]
