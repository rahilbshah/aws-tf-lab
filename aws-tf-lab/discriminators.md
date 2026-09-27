---
tags: [exam-prep, generated]
---

# ⚖️ Discriminators — "which of these two is it?"

> [!warning] Generated file — do not edit
> Built by `_scripts/build_discriminators.py`. Edit the **notes**, then re-run.
> Every line is lifted verbatim.

Your mock data says what costs you marks is **choosing between two plausible
options**, not recalling facts. This is every such pair in the vault: the
comparison tables to open, and the sentence that separates each trap pair.

*103 comparison tables · 183 discriminators · ~34 min read*

## [[01-iam|01 – IAM (Identity and Access Management)]]

**Compare:** [[01-iam#User vs Role|User vs Role]] · [[01-iam#Inline vs Managed policy|Inline vs Managed policy]] · [[01-iam#Trust policy vs Permissions policy (on a Role)|Trust policy vs Permissions policy (on a Role)]] · [[01-iam#How an application authenticates to RDS|How an application authenticates to RDS]] · [[01-iam#Bringing existing corporate identities into AWS (Directory Service + federation)|Bringing existing corporate identities into AWS (Directory Service + federation)]]

- **"the plan showed the policy was fine"** — It didn't, and it couldn't. Because the policy document interpolates aws_s3_bucket.this.arn, Terraform reports data.aws_iam_policy_document.permissions will be read during apply and the policy renders as (known after apply) — while the trust policy, which references nothing, renders in full.  
  ↳ [[01-iam|note]]
- **Policy order or count matters** — It doesn't. IAM evaluation is order-independent and count-independent. One explicit Deny anywhere is sufficient.  
  ↳ [[01-iam|note]]
- **Specificity wins** — No. IAM has no "more specific resource ARN wins" rule like NTFS ACLs. A plausible-sounding distractor.  
  ↳ [[01-iam|note]]
- **Roles are only for AWS services** — Roles are also used for cross-account access, federated humans (SAML/OIDC → role), and temporary privilege elevation.  
  ↳ [[01-iam|note]]
- **Long-lived access keys are fine for service-to-service** — Strongly discouraged — roles + temporary STS credentials are the secure default. Long-lived keys in env vars are an audit and leak risk.  
  ↳ [[01-iam|note]]
- **IAM is regional** — No — global service. Frequent distractor; almost everything else AWS is regional.  
  ↳ [[01-iam|note]]
- **Attach a role directly to an EC2 instance** — EC2 needs an instance profile in between (see [[02-ec2]]). Lambda doesn't.  
  ↳ [[01-iam|note]]
- **All name arguments on IAM resources behave the same** — They don't — aws_iam_user.name is in-place updatable; aws_iam_policy.name forces destroy-and-recreate (ARN embeds the name).  
  ↳ [[01-iam|note]]
- **validate/plan catch reference bugs (.arn vs .name, quoted strings)** — They don't — both shapes are type-valid strings. The errors surface only at apply (or silently produce wrong results).  
  ↳ [[01-iam|note]]
- **"create IAM users for the on-premises staff"** — Any question that establishes users already exist in Active Directory (or any corporate IdP) and asks how to give them AWS access is testing federation.  
  ↳ [[01-iam|note]]
- **"IAM Groups" in a federation question** — The word group carries two meanings in these questions and only one of them is an answer.  
  ↳ [[01-iam|note]]
- **AD Connector vs AWS Managed Microsoft AD** — If the requirement is "don't store directory data in AWS" or "keep managing users on-premises with our existing tools," that's AD Connector — a proxy that forwards authentication and synchronizes nothing. If they need AD-aware workloads in AWS (RDS for SQL Server, .NET apps, EC2 Windows domain join with a standalone directory) or a trust with on-prem, that's AWS Managed Microsoft AD.  
  ↳ [[01-iam|note]]
- **rds: vs rds-db: for database login** — Giving an application rds:* does not let it log in to a database — that's the RDS management API (create/describe/modify instances). Logging in with IAM auth requires rds-db:connect on an arn:aws:rds-db:…:dbuser:… resource. See [[07-rds-aurora]].  
  ↳ [[01-iam|note]]
- **SSL/TLS is not authentication** — "The application must connect without a stored database password" is answered by IAM database authentication, never by an SSL/TLS option.  
  ↳ [[01-iam|note]]


## [[01-iam-advanced|01b – IAM Advanced (Organizations, SCPs, boundaries, ABAC)]]

**Compare:** [[01-iam-advanced#Which multi-account requirement does this solve?|Which multi-account requirement does this solve?]] · [[01-iam-advanced#The four things that can cap a permission|The four things that can cap a permission]] · [[01-iam-advanced#How policy types combine|How policy types combine]] · [[01-iam-advanced#RBAC vs ABAC|RBAC vs ABAC]] · [[01-iam-advanced#Condition keys worth memorising|Condition keys worth memorising]]

- **"attach an SCP to give that account access"** — SCPs never grant. If a question's correct-sounding answer is "create an SCP allowing the developers to use S3," it's wrong — you also need an IAM policy, and the SCP only ever removes.  
  ↳ [[01-iam-advanced#Traps|note]]
- **root user and SCPs** — Both halves matter and they point opposite ways. The management account is immune to SCPs entirely — including its root user and every IAM principal in it. A member account's root user is not immune — it is capped like everyone else. That's exactly why AWS recommends keeping no workloads in the management account.  
  ↳ [[01-iam-advanced#Traps|note]]
- **permissions boundary vs SCP** — Same idea, different blast radius. SCP = whole account(s), needs Organizations. Boundary = one user or role, works in a standalone account. If the scenario is a single account delegating admin duties → boundary. If it's "enforce across all accounts / prevent anyone in the org" → SCP.  
  ↳ [[01-iam-advanced#Traps|note]]
- **Bool vs BoolIfExists for MFA** — aws:MultiFactorAuthPresent is not present at all for long-term access-key requests. A Deny on Bool: {"aws:MultiFactorAuthPresent": "false"} therefore does not fire for CLI access-key calls (the key is missing, not false), while an Allow gated on Bool ... "true" blocks them.  
  ↳ [[01-iam-advanced#Traps|note]]
- **Control Tower vs Organizations** — Organizations is the primitive: accounts, OUs, SCPs. Control Tower orchestrates it — it builds a landing zone using Organizations + IAM Identity Center + Service Catalog, provides Account Factory for standardised account vending, and applies controls/guardrails (preventive — implemented as SCPs; detective — implemented as AWS Config rules; proactive — CloudFormation hooks), plus drift detection.  
  ↳ [[01-iam-advanced#Traps|note]]
- **aws:SourceIp behind a VPC endpoint** — The key is simply absent for requests that traverse a VPC endpoint, so an IP-allowlist policy silently fails closed for in-VPC traffic.  
  ↳ [[01-iam-advanced#Traps|note]]


## [[02-ec2|02 – EC2 (Elastic Compute Cloud)]]

**Compare:** [[02-ec2#Stop vs Terminate|Stop vs Terminate]] · [[02-ec2#EBS vs Instance Store|EBS vs Instance Store]] · [[02-ec2#The three placement strategies|The three placement strategies]] · [[02-ec2#Auto-assigned Public IP vs Elastic IP|Auto-assigned Public IP vs Elastic IP]] · [[02-ec2#IMDSv1 vs IMDSv2|IMDSv1 vs IMDSv2]]

- **cluster chosen for availability, or spread for scale** — They pull in opposite directions and the wrong one is always offered. Cluster is a single AZ — picking it for "high availability" actively concentrates risk; it is a performance choice.  
  ↳ [[02-ec2|note]]
- **All EC2 attributes can be changed in-place** — No — ami, subnet_id (subnet determines AZ), key_name and associate_public_ip_address all force replacement.  
  ↳ [[02-ec2|note]]
- **ip_protocol accepts "ssh" / "http"** — No — IP-layer protocols only: tcp/udp/icmp/icmpv6/-1. Application-layer names are friendly console labels, not API inputs.  
  ↳ [[02-ec2|note]]
- **t3-micro works** — No — AWS instance types are family.size with a literal dot. Hyphens get rejected at apply.  
  ↳ [[02-ec2|note]]
- **aws_subnets.X.id returns one subnet ID** — No — that data source returns a list under .ids. There is no singular .id on the plural resource.  
  ↳ [[02-ec2|note]]
- **IAM changes are instant** — Often near-instant, but eventually consistent — newly created roles can briefly fail to be assumed (propagation race).  
  ↳ [[02-ec2|note]]
- **EBS volumes can be moved across AZs by detach + attach** — No — EBS is AZ-scoped. Cross-AZ requires snapshot → restore in target AZ.  
  ↳ [[02-ec2|note]]
- **Instance store survives stop** — No — instance store dies on stop AND terminate. EBS is what survives.  
  ↳ [[02-ec2|note]]
- **Long-lived access keys on an instance are fine for service-to-service** — Don't. Use an IAM role + instance profile. Long-lived keys in env files / user data are an audit and leak risk.  
  ↳ [[02-ec2|note]]
- **EIP is free while attached** — Was true pre-Feb 2024. Now every public IPv4 (auto-assigned and EIP) bills hourly regardless of attachment state.  
  ↳ [[02-ec2|note]]


## [[04-alb-asg|04 – ALB + Auto Scaling Group]]

**Compare:** [[04-alb-asg#ALB vs NLB vs GWLB|ALB vs NLB vs GWLB]] · [[04-alb-asg#Scaling policy types|Scaling policy types]] · [[04-alb-asg#Predefined termination policies|Predefined termination policies]] · [[04-alb-asg#Sizing for AZ loss — required capacity × AZ count|Sizing for AZ loss — required capacity × AZ count]]

- **minimum capacity set to N when an AZ must be survivable** — The stem gives a required capacity and an AZ count, and the wrong options are near-misses on the same arithmetic: min set to N (right total, no spare zone) · the correct total parked in one AZ · one instance per AZ across N AZs (total right, per-AZ wrong) · max below the stated peak.  
  ↳ [[04-alb-asg#Comparisons|note]]
- **"the ALB terminates the unhealthy instance"** — It doesn't. The ALB only stops routing to it. Termination is the ASG's job, and only if health_check_type = "ELB".  
  ↳ [[04-alb-asg#The Terraform I wrote|note]]
- **"a failed ALB health check means users get errors"** — Only if no targets are healthy. With ≥1 healthy target the ALB quietly routes around the bad one and users are fine — you're at reduced capacity with nobody alerted.  
  ↳ [[04-alb-asg#The Terraform I wrote|note]]
- **NLB vs ALB for a static IP / source-IP / PrivateLink** — "Need a static IP for the LB" or "must preserve client source IP with no app changes" → NLB (static IP/EIP per AZ, native source-IP preservation). ALB is DNS-only and needs X-Forwarded-For. Frequent distractor pairing. Third trigger, same pairing: "expose one service to another VPC or account without exposing the rest of the VPC" → PrivateLink, and an endpoint service must be fronted by an NLB or a GWLB — never an ALB directly.  
  ↳ [[04-alb-asg#The Terraform I wrote|note]]
- **cross-zone billing** — Cross-zone is free & always-on for ALB, but off by default and inter-AZ-billed for NLB.  
  ↳ [[04-alb-asg#The Terraform I wrote|note]]
- **"scale-in terminates the oldest instance"** — Two errors in one. First, AZ balance is evaluated before the termination policy, so the instance chosen may be a newer one sitting in an over-weighted AZ. Second, the default policy targets the oldest configuration (launch configuration, then non-current launch template, then oldest template version) — not the oldest instance.  
  ↳ [[04-alb-asg#The Terraform I wrote|note]]
- **a scheduled action that also pins min and max** — "Guarantee 10 instances at 9am" and "run exactly 10 instances at 9am" are different requirements.  
  ↳ [[04-alb-asg#The Terraform I wrote|note]]
- **redirect on the wrong load balancer, or the wrong direction** — redirect is an ALB (Layer 7) listener action; an NLB operates at Layer 4 and cannot inspect or rewrite HTTP, so "redirect HTTP to HTTPS on an NLB" is always wrong.  
  ↳ [[04-alb-asg#The Terraform I wrote|note]]


## [[05-vpc-core|05.1 – VPC Core (subnets, routing, IGW, NAT)]]

**Compare:** [[05-vpc-core#NAT Gateway vs NAT Instance|NAT Gateway vs NAT Instance]] · [[05-vpc-core#IGW vs NAT Gateway vs Egress-only IGW|IGW vs NAT Gateway vs Egress-only IGW]]

- **"the default NACL and a new NACL behave the same"** — Opposite. The default NACL allows all traffic both ways; a custom NACL you create denies all until you add numbered rules.  
  ↳ [[05-vpc-core#The Terraform I wrote|note]]
- **"add the IGW route to the main route table to make setup simpler"** — Never. That makes every unassociated subnet public by default — a subnet you forget to wire becomes internet-exposed.  
  ↳ [[05-vpc-core#The Terraform I wrote|note]]


## [[05-vpc-security|05.2 – VPC Security (SG, NACL, Flow Logs, Network Firewall)]]

**Compare:** [[05-vpc-security#Security Group vs Network ACL (the exam's favorite table)|Security Group vs Network ACL (the exam's favorite table)]] · [[05-vpc-security#Where each layer sits|Where each layer sits]]

- **"make the NACL match the SG rules and you're done"** — No — the NACL is stateless, so it needs the ephemeral return rule the SG never required.  
  ↳ [[05-vpc-security#The Terraform I wrote|note]]
- **"use flow logs to see what data was exfiltrated"** — Flow logs are metadata only — IPs, ports, bytes, ACCEPT/REJECT. They never show payload.  
  ↳ [[05-vpc-security#The Terraform I wrote|note]]
- **"a higher NACL rule number can override a lower deny"** — No — first match wins, low number first. A deny at #100 is final; #200 allow never gets evaluated for that packet.  
  ↳ [[05-vpc-security#The Terraform I wrote|note]]


## [[05-vpc-endpoints-peering|05.3 – VPC Endpoints & Peering (+ Transit Gateway)]]

**Compare:** [[05-vpc-endpoints-peering#Gateway vs Interface endpoint|Gateway vs Interface endpoint]] · [[05-vpc-endpoints-peering#VPC Peering vs Transit Gateway|VPC Peering vs Transit Gateway]]

- **VPC sharing confused with peering, or "share the VPC"** — Two errors in one family. **VPC sharing shares subnets, never the whole VPC — an option saying "share the VPC" is wrong even when sharing is the right idea. And sharing is not peering**: peering connects two separate VPCs, while sharing puts several accounts inside one VPC, using its implicit routing.  
  ↳ [[05-vpc-endpoints-peering#Key facts, limits & pricing|note]]
- **"use a gateway endpoint for SQS/KMS/etc."** — Gateway endpoints only exist for S3 and DynamoDB. Every other service uses an interface endpoint (PrivateLink).  
  ↳ [[05-vpc-endpoints-peering#The Terraform I wrote|note]]
- **"reach the S3 gateway endpoint from a peered VPC / on-prem"** — No. Gateway endpoints work only within the same VPC. If you need S3 access from a peered VPC or over VPN/DX, you use an interface endpoint (which is reachable across those).  
  ↳ [[05-vpc-endpoints-peering#The Terraform I wrote|note]]
- **"peering scales fine, just add connections"** — Full mesh is N(N-1)/2 and non-transitive — it explodes past a few VPCs. The intended answer for "many VPCs" is Transit Gateway, not more peerings.  
  ↳ [[05-vpc-endpoints-peering#The Terraform I wrote|note]]


## [[05-vpc-hybrid|05.4 – VPC Hybrid Connectivity (VPN & Direct Connect)]]

**Compare:** [[05-vpc-hybrid#Site-to-Site VPN vs Direct Connect|Site-to-Site VPN vs Direct Connect]] · [[05-vpc-hybrid#Which one? (exam triggers)|Which one? (exam triggers)]]

- **"Direct Connect is encrypted because it's private"** — Private ≠ encrypted. DX carries plaintext over a dedicated circuit. For encryption, run a VPN over DX.  
  ↳ [[05-vpc-hybrid#The Terraform I wrote|note]]
- **"use Direct Connect for a quick or temporary connection"** — DX takes weeks-to-months to provision. Anything "fast," "temporary," or "immediately" is a Site-to-Site VPN.  
  ↳ [[05-vpc-hybrid#The Terraform I wrote|note]]
- **"VGW vs CGW"** — VGW = AWS side (attached to the VPC). CGW = on-prem side (a config object describing your router). Swapping these is a classic mix-up.  
  ↳ [[05-vpc-hybrid#The Terraform I wrote|note]]
- **"Client VPN = Site-to-Site VPN"** — Client VPN = individual users' devices (OpenVPN). Site-to-Site VPN = whole network ↔ VPC (IPsec).  
  ↳ [[05-vpc-hybrid#The Terraform I wrote|note]]


## [[06-capstone|06 – Capstone: 3-Tier VPC with Terraform Modules]]

**Compare:** [[06-capstone#RDS Multi-AZ vs Read Replica (the number-one RDS exam trap)|RDS Multi-AZ vs Read Replica (the number-one RDS exam trap)]] · [[06-capstone#Flat config vs Modules|Flat config vs Modules]] · [[06-capstone#Accessing the private database (bastion vs SSM)|Accessing the private database (bastion vs SSM)]]

- **Multi-AZ to scale reads** — Multi-AZ is HA/failover, the standby is not readable. To offload/scale reads you use read replicas.  
  ↳ [[06-capstone#The Terraform I wrote|note]]
- **"the module output shows in terraform output"** — Only root outputs show on the CLI. A module output must be re-declared at the root. Outputs bubble up one level per caller.  
  ↳ [[06-capstone#The Terraform I wrote|note]]


## [[07-rds-aurora|07 – RDS & Aurora]]

**Compare:** [[07-rds-aurora#Multi-AZ vs Read Replica (memorize)|Multi-AZ vs Read Replica (memorize)]] · [[07-rds-aurora#RDS vs Aurora|RDS vs Aurora]] · [[07-rds-aurora#Database authentication — password vs IAM vs Secrets Manager|Database authentication — password vs IAM vs Secrets Manager]]

- **an IAM role on the app is not, by itself, database authentication** — The distractors are "attach an IAM role to the EC2 instance / Lambda function" and "restrict the security group to the app tier", offered on their own.  
  ↳ [[07-rds-aurora#The Terraform I wrote|note]]
- **"IAM database authentication controls what the user can do in the database"** — It does not. IAM decides whether you may connect as a given database user; everything after that is still the database's own GRANTs.  
  ↳ [[07-rds-aurora#The Terraform I wrote|note]]
- **rds-db: vs rds:** — rds-db:connect is the only action with the rds-db: prefix and it exists solely for IAM DB auth. Everything else (rds:CreateDBInstance, rds:DescribeDBInstances…) is the rds: management API and has nothing to do with logging into the database. An answer that grants rds:* to let an app "connect to the database" is wrong.  
  ↳ [[07-rds-aurora#The Terraform I wrote|note]]
- **"use IAM DB auth so database logins show up in CloudTrail"** — They don't. AWS documents that CloudTrail and CloudWatch do not log generate-db-auth-token.  
  ↳ [[07-rds-aurora#The Terraform I wrote|note]]
- **Multi-AZ to scale reads** — Multi-AZ standby is not readable — it's for failover. Use read replicas to scale reads.  
  ↳ [[07-rds-aurora#The Terraform I wrote|note]]
- **Aurora replica lag is like RDS replica lag** — No — Aurora replicas share one storage volume (no data copy), so lag is ~milliseconds; RDS read replicas copy data asynchronously and can lag seconds.  
  ↳ [[07-rds-aurora#The Terraform I wrote|note]]
- **"RDS is serverless / auto-scales like Aurora"** — Plain RDS is provisioned instances. True serverless + auto-scaling storage + global <1s replication are Aurora features.  
  ↳ [[07-rds-aurora#The Terraform I wrote|note]]


## [[08-elasticache|08 – ElastiCache (Redis / Memcached)]]

**Compare:** [[08-elasticache#Redis vs Memcached (the exam table)|Redis vs Memcached (the exam table)]] · [[08-elasticache#Caching strategies|Caching strategies]]

- **DAX and ElastiCache offered for the same workload** — They front different databases and that alone usually settles it. DAX only accelerates DynamoDB; ElastiCache fronts RDS/Aurora and anything else you write caching logic for.  
  ↳ [[08-elasticache#How it actually works|note]]
- **Memcached for anything needing HA/persistence/complex data** — Memcached is simple, multi-threaded, ephemeral. Need failover, backup, sorted sets, pub/sub, or a session store that survives a node loss → Redis.  
  ↳ [[08-elasticache#The Terraform I wrote|note]]
- **a question that mixes Redis-sounding use cases with Memcached-only features** — The hard version of the engine question doesn't say "pick a cache" — it describes a session store (which your instinct maps to Redis) while also specifying multi-threaded and automatic node discovery (both Memcached-only).  
  ↳ [[08-elasticache#The Terraform I wrote|note]]
- **"add a cache" when the problem is writes** — Caches accelerate reads. If the bottleneck is heavy writes or the data must be strongly consistent per request, a cache doesn't help (and lazy-loading serves stale data).  
  ↳ [[08-elasticache#The Terraform I wrote|note]]
- **Redis is multi-threaded because it's fast** — Redis command execution is single-threaded (one core per node); it scales via cluster-mode sharding, not more cores.  
  ↳ [[08-elasticache#The Terraform I wrote|note]]


## [[09-s3-intro|09.1 – S3 Introduction (buckets, classes, versioning, lifecycle)]]

**Compare:** [[09-s3-intro#Storage classes (verified against AWS docs 2026-08)|Storage classes (verified against AWS docs 2026-08)]] · [[09-s3-intro#Versioning: delete vs permanent delete|Versioning: delete vs permanent delete]]

- **"S3 has folders"** — No. S3 is a flat key→object store; photos/cat.jpg is one key. The console renders "folders" by splitting on /.  
  ↳ [[09-s3-intro#The Terraform I wrote|note]]
- **"Glacier means slow retrieval"** — Glacier Instant Retrieval returns objects in milliseconds. Only Flexible Retrieval (minutes–hours) and Deep Archive (hours) need a restore job.  
  ↳ [[09-s3-intro#The Terraform I wrote|note]]
- **durability vs availability** — Every class is 11 nines durable (won't lose data). What differs is availability (can you reach it right now): Standard 99.99%, IA 99.9%, One Zone-IA 99.5%. Questions about "surviving AZ loss" are about AZ count, not durability.  
  ↳ [[09-s3-intro#The Terraform I wrote|note]]
- **moving to IA/Glacier always saves money** — Minimum storage durations (IA 30 d, Glacier 90 d, Deep Archive 180 d) and a 128 KB minimum billable size mean short-lived or tiny objects can cost more in IA than Standard.  
  ↳ [[09-s3-intro#The Terraform I wrote|note]]


## [[09-s3-advanced|09.2 – S3 Advanced (replication, big files, events)]]

**Compare:** [[09-s3-advanced#CRR vs SRR|CRR vs SRR]] · [[09-s3-advanced#Multipart vs byte-range|Multipart vs byte-range]]

- **replication copies existing objects** — It does not. Live CRR/SRR only handles objects created/updated after the rule. Existing data needs S3 Batch Replication.  
  ↳ [[09-s3-advanced#The Terraform I wrote|note]]
- **replication is transitive** — No. A→B and B→C does not deliver A's objects to C. Replicas can only be re-replicated with Batch Replication.  
  ↳ [[09-s3-advanced#The Terraform I wrote|note]]
- **Transfer Acceleration moves your data closer to users** — It doesn't move the bucket. It changes the path: enter AWS at the nearest edge location, then travel the private backbone to the bucket's region.  
  ↳ [[09-s3-advanced#The Terraform I wrote|note]]
- **"use S3 Select" on a new account** — S3 Select is no longer available to new customers. The modern answer for SQL over S3 is Athena (and it queries many objects, not one).  
  ↳ [[09-s3-advanced#The Terraform I wrote|note]]


## [[09-s3-security|09.3 – S3 Security (access, encryption, immutability)]]

**Compare:** [[09-s3-security#IAM policy vs bucket policy vs ACL|IAM policy vs bucket policy vs ACL]] · [[09-s3-security#GOVERNANCE vs COMPLIANCE|GOVERNANCE vs COMPLIANCE]]

- **Block Public Access can be overridden by a bucket policy** — Backwards. BPA overrides the policy. A perfectly valid public bucket policy is simply ignored while BPA is on.  
  ↳ [[09-s3-security#The Terraform I wrote|note]]
- **enabling default encryption encrypts what's already there** — It doesn't. Default encryption applies to new objects only. Existing objects keep their previous encryption until you rewrite them — S3 Batch Operations → Copy.  
  ↳ [[09-s3-security#The Terraform I wrote|note]]
- **a presigned URL uses the recipient's permissions** — It uses the generator's. That's why it works for someone with no AWS account at all — and why generating one from an over-privileged role is dangerous.  
  ↳ [[09-s3-security#The Terraform I wrote|note]]
- **Object Lock stops the object being deleted** — It stops that version being deleted. A simple DELETE still returns 200 OK and adds a delete marker, hiding the object.  
  ↳ [[09-s3-security#The Terraform I wrote|note]]
- **MFA Delete can be set up like any other bucket setting** — Only the root account with an MFA device can enable it, via CLI. Not IAM users, not the console, not Terraform.  
  ↳ [[09-s3-security#The Terraform I wrote|note]]


## [[10-route53|10 – Route 53 (DNS)]]

**Compare:** [[10-route53#The eight routing policies|The eight routing policies]] · [[10-route53#Alias vs CNAME|Alias vs CNAME]] · [[10-route53#Public vs private hosted zone|Public vs private hosted zone]] · [[10-route53#Route 53 Resolver — get the direction right|Route 53 Resolver — get the direction right]]

- **"use simple routing to distribute traffic across three servers"** — Simple routing returns all the values in random order and the client chooses; Route 53 is not balancing anything and is not health checking.  
  ↳ [[10-route53#Traps|note]]
- **CNAME at the apex** — example.com must carry SOA and NS records, and DNS forbids a CNAME coexisting with any other record at the same name.  
  ↳ [[10-route53#Traps|note]]
- **geolocation vs geoproximity** — Geolocation = where the USER is (continent, country, US state) — content localization, licensing, compliance. Geoproximity = where your RESOURCES are, with a bias to grow or shrink each one's catchment. If the scenario says "users in Germany must get the German site," that's geolocation.  
  ↳ [[10-route53#Traps|note]]
- **"we set up failover but users were down for an hour"** — Route 53 did fail over. The TTL kept resolvers and browsers serving the stale answer. Failover is only as fast as (interval × threshold) + TTL, and the TTL term usually dominates.  
  ↳ [[10-route53#Traps|note]]
- **health check on a private IP** — Route 53 health checkers live on the public internet and cannot reach private, nonroutable or multicast addresses.  
  ↳ [[10-route53#Traps|note]]
- **inbound vs outbound Resolver endpoints** — Inbound = traffic coming INTO AWS to be resolved (on-prem asking about AWS names). Outbound = queries leaving AWS (your VPC asking about on-prem names). Candidates reverse these constantly. Anchor on the direction of the query, not the direction of the answer.  
  ↳ [[10-route53#Traps|note]]
- **"HTTPS health checks prove the certificate is valid"** — They don't. AWS states plainly that HTTPS health checks do not validate SSL/TLS certificates — an expired or invalid cert still passes.  
  ↳ [[10-route53#Traps|note]]


## [[11-cloudfront|11 – CloudFront (CDN)]]

**Compare:** [[11-cloudfront#CloudFront vs S3 Transfer Acceleration vs Global Accelerator|CloudFront vs S3 Transfer Acceleration vs Global Accelerator]] · [[11-cloudfront#CloudFront Functions vs Lambda@Edge|CloudFront Functions vs Lambda@Edge]] · [[11-cloudfront#Signed URLs vs signed cookies (private content)|Signed URLs vs signed cookies (private content)]]

- **"put CloudFront in front of the S3 website endpoint and use OAC"** — You can't. An S3 bucket configured as a website endpoint is a custom origin, and custom origins support neither OAC nor OAI.  
  ↳ [[11-cloudfront#Traps|note]]
- **the ACM certificate in the wrong Region** — A certificate for viewer↔CloudFront HTTPS must be in **us-east-1**, regardless of where the origin, the bucket, or you are.  
  ↳ [[11-cloudfront#Traps|note]]
- **CloudFront vs Global Accelerator** — Both "make it faster globally" and both use the AWS edge network. CloudFront caches HTTP content; Global Accelerator caches nothing and works at TCP/UDP. Trigger words for Global Accelerator: static IP addresses, non-HTTP protocol, gaming / VoIP / IoT, or failover in seconds without waiting for DNS.  
  ↳ [[11-cloudfront#Traps|note]]
- **"invalidate on every deploy"** — It works, and for small sites the free 1,000 paths/month absorbs it. But it doesn't reach browser or corporate-proxy caches, so some users still see stale content, and it makes access logs ambiguous.  
  ↳ [[11-cloudfront#Traps|note]]
- **CloudFront Functions asked to do too much** — CloudFront Functions cannot make network calls, read the request body, or run on origin events, and cap at 10 KB of code.  
  ↳ [[11-cloudfront#Traps|note]]
- **geo restriction vs geolocation routing** — CloudFront geo restriction decides whether a country may access the content at all (allow/block list, enforced at the edge). Route 53 geolocation routing ([[10-route53]]) decides which endpoint a country is sent to. "Block viewers in country X for licensing reasons" → CloudFront.  
  ↳ [[11-cloudfront#Traps|note]]


## [[12-storage-extras|12 – Storage extras (EFS, FSx, Storage Gateway, DataSync, Snow, Backup)]]

**Compare:** [[12-storage-extras#EFS vs FSx vs EBS vs S3|EFS vs FSx vs EBS vs S3]] · [[12-storage-extras#Volume Gateway: cached vs stored|Volume Gateway: cached vs stored]] · [[12-storage-extras#Getting data in: DataSync vs Snow vs Storage Gateway|Getting data in: DataSync vs Snow vs Storage Gateway]]

- **EFS for a Windows workload** — The most reliable elimination in this topic. AWS does not support EFS with Windows EC2 instances. Any question mentioning Windows, SMB, Active Directory, or Windows ACLs is pointing at FSx for Windows File Server, however well "shared file system" seems to fit EFS.  
  ↳ [[12-storage-extras#Traps|note]]
- **cached vs stored Volume Gateway, reversed** — Read where the primary copy lives. Cached = primary in S3, hot subset local — chosen to stop on-premises storage growing. Stored = primary on-premises, snapshots to S3 — chosen when you need low-latency access to the whole dataset and want offsite backups.  
  ↳ [[12-storage-extras#Traps|note]]
- **DataSync vs Storage Gateway** — Both move data between on-premises and AWS, and both need something installed locally. DataSync transfers data — a migration or a scheduled sync, after which the job is done. Storage Gateway is a permanent bridge — the on-premises system keeps using it every day as if it were local storage.  
  ↳ [[12-storage-extras#Traps|note]]
- **Snow when the network would do** — Snow exists for data volumes where transferring over the network would take impractically long, or where connectivity is poor.  
  ↳ [[12-storage-extras#Traps|note]]
- **Lustre scratch vs persistent read as a speed choice** — The difference is durability, not performance. Scratch is not replicated and does not survive a file server failure; persistent is replicated with automatic server replacement. If the question mentions long-running work or data you can't re-create, it's persistent.  
  ↳ [[12-storage-extras#Traps|note]]
- **"EFS One Zone is fine, it's still durable"** — Same shape as the S3 One Zone-IA trap in [[09-s3-intro]]. One Zone stores in a single Availability Zone, and data may be lost if that zone is lost.  
  ↳ [[12-storage-extras#Traps|note]]


## [[13-cost-optimization|13 – Cost optimization]]

**Compare:** [[13-cost-optimization#Savings Plans vs Reserved Instances|Savings Plans vs Reserved Instances]] · [[13-cost-optimization#When each purchasing option is the answer|When each purchasing option is the answer]] · [[13-cost-optimization#The cost tools|The cost tools]]

- **"buy a Savings Plan to guarantee capacity"** — A Savings Plan is only a billing discount. It never reserves capacity. If a scenario needs certainty that an instance can be launched in a specific Availability Zone — a DR standby, a licensed workload — the answer is a Capacity Reservation or a zonal Reserved Instance.  
  ↳ [[13-cost-optimization#Traps|note]]
- **assuming the most flexible option is the cheapest** — EC2 Instance Savings Plans give up to 72%; Compute Savings Plans up to 66%. The less flexible one is cheaper.  
  ↳ [[13-cost-optimization#Traps|note]]
- **Standard vs Convertible RI, exchange vs modify** — **Standard RIs can be modified but never exchanged. Convertible RIs can be exchanged** for a different Convertible RI with different attributes. If the requirement is "we may need to switch instance families later," Standard is wrong however good the discount looks.  
  ↳ [[13-cost-optimization#Traps|note]]
- **Dedicated Host vs Dedicated Instance** — Both give single-tenant hardware. Dedicated Host gives you visibility and control of the physical server — sockets, cores, host affinity — which is what per-socket / per-core BYOL licensing requires. Dedicated Instance gives isolation without host-level visibility.  
  ↳ [[13-cost-optimization#Traps|note]]
- **Spot hibernation and the two minutes** — The two-minute notice applies when the interruption behaviour is stop or terminate. With hibernate, you get an interruption notice but not two minutes of warning — hibernation starts immediately.  
  ↳ [[13-cost-optimization#Traps|note]]
- **Cost Explorer vs Budgets vs Compute Optimizer** — Three tools, three jobs. Cost Explorer analyses what already happened and forecasts. Budgets alerts you when spend or usage crosses a threshold you set. Compute Optimizer looks at CloudWatch metrics and says the resource is the wrong size. "Notify us before we exceed $5,000" → Budgets, not Cost Explorer.  
  ↳ [[13-cost-optimization#Traps|note]]


## [[14-dr-resilience|14 – Disaster recovery & resilience]]

**Compare:** [[14-dr-resilience#The four strategies side by side|The four strategies side by side]] · [[14-dr-resilience#HA vs DR|HA vs DR]] · [[14-dr-resilience#Picking a cross-Region database|Picking a cross-Region database]]

- **pilot light vs warm standby** — The single most-tested pair here. Pilot light cannot serve a request until you switch something on. Warm standby is already running and serving, just small. Both replicate data; both have infrastructure in the DR Region. The only question is whether the compute is running.  
  ↳ [[14-dr-resilience#Traps|note]]
- **treating replication as backup** — Cross-Region replication copies corruption, bad deployments and malicious deletions perfectly.  
  ↳ [[14-dr-resilience#Traps|note]]
- **RTO and RPO swapped** — RPO is data loss. RTO is downtime. A question giving "RPO of 5 minutes" is constraining your replication; "RTO of 5 minutes" is constraining how much capacity is already running.  
  ↳ [[14-dr-resilience#Traps|note]]
- **automatic failover assumed to be the better answer** — AWS explicitly advises caution with automatically initiated failover, because a false alarm makes you incur real downtime and real data loss for nothing.  
  ↳ [[14-dr-resilience#Traps|note]]
- **an RDS read replica used where Aurora Global Database belongs** — Both give cross-Region replication. But an RDS read replica promotion takes a few minutes and includes a reboot, while Aurora Global Database replicates in under a second and promotes in under a minute.  
  ↳ [[14-dr-resilience#Traps|note]]
- **a DR design that depends on the control plane** — Auto Scaling, Route 53 weight changes and Global Accelerator traffic dials are control-plane operations, and control planes are less available than data planes exactly when you need them.  
  ↳ [[14-dr-resilience#Traps|note]]
- **the RTO clock starts before anyone notices** — Candidates budget the RTO for the failover itself and forget everything in front of it. Detection, notification, escalation, evaluation and declaring the disaster are all inside the RTO. A one-hour RTO with a 25-minute alarm has already spent nearly half its budget before a human is involved.  
  ↳ [[14-dr-resilience#Traps|note]]
- **a recovery path that has never been run** — "We have a DR Region" is not the same as "we can recover." Untested paths fail on the details: stale AMIs, service quotas in the DR Region that were never raised, a read-only secondary nobody has ever written to.  
  ↳ [[14-dr-resilience#Traps|note]]
- **assuming DR always means a second Region** — The four strategies are about discrete locations, not Regions specifically. When data-residency or sovereignty rules confine a workload to a country with a single AWS Region, the correct answer implements the same strategy across that Region's Availability Zones.  
  ↳ [[14-dr-resilience#Traps|note]]


## [[15-decoupling|15 – Decoupling (SQS, SNS, Amazon MQ)]]

**Compare:** [[15-decoupling#SQS vs SNS|SQS vs SNS]] · [[15-decoupling#Standard vs FIFO queues|Standard vs FIFO queues]] · [[15-decoupling#SQS vs SNS vs Amazon MQ|SQS vs SNS vs Amazon MQ]]

- **"receiving a message removes it"** — It does not. A received message is hidden for the visibility timeout and comes back unless the consumer explicitly calls DeleteMessage.  
  ↳ [[15-decoupling#Traps|note]]
- **a queue with no dead-letter queue** — Without a DLQ there is no upper bound on retries. A message that always fails is redelivered until retention expires — up to 14 days of consumers repeatedly choking on the same thing.  
  ↳ [[15-decoupling#Traps|note]]
- **DLQ retention set equal to the source queue's** — For standard queues the message keeps its original enqueue timestamp when it moves.  
  ↳ [[15-decoupling#Traps|note]]
- **assuming an empty poll means an empty queue** — Short polling is the default, and it samples only a subset of SQS servers — so it can return nothing while messages are waiting.  
  ↳ [[15-decoupling#Traps|note]]
- **SNS delivering straight to a service instead of into a queue** — SNS delivers, it does not hold. Push it directly at a Lambda or HTTP endpoint that is down and the notification is lost.  
  ↳ [[15-decoupling#Traps|note]]
- **FIFO chosen without noticing the throughput ceiling** — FIFO's strict ordering and exactly-once cost you throughput: 300 TPS per API action, 3,000/second batched, against a standard queue's effectively unlimited rate.  
  ↳ [[15-decoupling#Traps|note]]
- **Amazon MQ picked for a new application** — Amazon MQ exists for migration: an existing app already speaking a standard broker protocol that you don't want to rewrite.  
  ↳ [[15-decoupling#Traps|note]]


## [[16-kinesis|16 – Kinesis (Data Streams & Data Firehose)]]

**Compare:** [[16-kinesis#SQS vs SNS vs Kinesis|SQS vs SNS vs Kinesis]] · [[16-kinesis#Data Streams vs Firehose|Data Streams vs Firehose]]

- **SQS chosen where replay or multiple consumers are needed** — The single most-tested distinction here. SQS deletes a message once processed, so a second consumer can never see it and nothing can be re-read.  
  ↳ [[16-kinesis#Traps|note]]
- **assuming ordering across the whole stream** — Kinesis guarantees order within a shard, not across the stream. Two records with different partition keys may be processed in any relative order.  
  ↳ [[16-kinesis#Traps|note]]
- **a low-cardinality partition key** — Adding shards does nothing if the partition key only produces a handful of hash values. A key like region or event_type concentrates traffic on a few shards while the rest idle, and the stream throttles far below its nominal capacity.  
  ↳ [[16-kinesis#Traps|note]]
- **Firehose expected to store or replay** — Firehose has no retention period and no concept of re-reading. It buffers briefly and delivers.  
  ↳ [[16-kinesis#Traps|note]]
- **Firehose treated as real-time** — Firehose buffers by size or interval before delivering, so it is near real-time — seconds to minutes, not milliseconds.  
  ↳ [[16-kinesis#Traps|note]]
- **forgetting that read throughput is shared** — A shard's 2 MB/sec read is split across all consumers using the default shared fan-out.  
  ↳ [[16-kinesis#Traps|note]]


## [[17-containers|17 – Containers on AWS (ECS, Fargate, ECR, EKS)]]

**Compare:** [[17-containers#ECS vs EKS|ECS vs EKS]] · [[17-containers#EC2 launch type vs Fargate|EC2 launch type vs Fargate]] · [[17-containers#Task execution role vs task role|Task execution role vs task role]] · [[17-containers#ALB target types|ALB target types]] · [[17-containers#ECR vs Docker Hub|ECR vs Docker Hub]]

- **"ECS or Fargate?"** — The question is malformed and the exam knows it. ECS is the orchestrator; Fargate is a launch type / capacity option, and EKS can use Fargate too.  
  ↳ [[17-containers#⚠️ Traps — why the wrong answer looks right|note]]
- **target_type on a Fargate service** — With awsvpc each task has its own ENI, so there is no instance ID to register. Leaving target_type at the default "instance" does not error: terraform apply succeeds, the service creates, no target ever registers, and the ALB serves 503 against a plan that looked clean.  
  ↳ [[17-containers#⚠️ Traps — why the wrong answer looks right|note]]
- **a green apply is not a green deployment** — Terraform reports success once the ECS API accepts the new task definition. Whether containers start is a separate control loop on its own clock.  
  ↳ [[17-containers#⚠️ Traps — why the wrong answer looks right|note]]
- **the execution role is not for the pull** — Nothing in AWS authenticates you to Docker Hub; a public image needs network egress, not IAM.  
  ↳ [[17-containers#⚠️ Traps — why the wrong answer looks right|note]]
- **rollback needs somewhere to roll back to** — The circuit breaker rolls back to the most recent COMPLETED deployment. If the first ever deployment of a new service is broken, there is no such deployment: the breaker trips and the service stalls with zero tasks.  
  ↳ [[17-containers#⚠️ Traps — why the wrong answer looks right|note]]
- **endpoints are not automatically cheaper than NAT** — Three interface endpoints billed per ENI per AZ can cost more than one NAT gateway at $0.045/hr.  
  ↳ [[17-containers#⚠️ Traps — why the wrong answer looks right|note]]


## [[18-containers-capstone|18 – Containers capstone (the services meeting each other)]]

**Compare:** [[18-containers-capstone#Where a task's configuration lives|Where a task's configuration lives]] · [[18-containers-capstone#The two ECS roles, as used in this build|The two ECS roles, as used in this build]] · [[18-containers-capstone#Two independent controls on the isolated tier|Two independent controls on the isolated tier]] · [[18-containers-capstone#Three ways to keep a DB password out of Terraform|Three ways to keep a DB password out of Terraform]] · [[18-containers-capstone#The perpetual-drift pattern — two instances from this build|The perpetual-drift pattern — two instances from this build]]

- **the ALB timed out, so something's broken** — After locking the ALB's ingress to the CloudFront prefix list, a direct curl to the ALB DNS name hangs and times out.  
  ↳ [[18-containers-capstone#⚠️ Traps — why the wrong answer looks right|note]]
- **the autoscaler scaled to 1, so the ALB isn't load balancing** — With no traffic, target-tracking on 50% CPU scaled the service in to its minimum of 1, so every request hit the same task.  
  ↳ [[18-containers-capstone#⚠️ Traps — why the wrong answer looks right|note]]
- **.id on a task definition** — aws_ecs_task_definition.x.id is the family (capstone). ECS accepts a bare family and resolves it to the latest revision — then reads back capstone:1, and the plan drifts forever.  
  ↳ [[18-containers-capstone#⚠️ Traps — why the wrong answer looks right|note]]
- **putting the secret grant on the task role** — The execution role fetches secrets, because the agent injects them before the container exists.  
  ↳ [[18-containers-capstone#⚠️ Traps — why the wrong answer looks right|note]]
- **health check on /** — The ALB health check targets /health, which has no dependencies. Point it at / or /db and a slow RDS marks every task unhealthy, the ALB drains them all, and an outage in one dependency takes down the whole service.  
  ↳ [[18-containers-capstone#⚠️ Traps — why the wrong answer looks right|note]]
- **"the S3 upload went through the NAT gateway"** — It didn't. The S3 gateway endpoint is attached to the private route table, so S3 traffic takes the prefix-list route and never touches the NAT — and never pays $0.045/GB for it.  
  ↳ [[18-containers-capstone#⚠️ Traps — why the wrong answer looks right|note]]


## [[19-serverless|19 – Serverless (Lambda, DynamoDB, API Gateway)]]

**Compare:** [[19-serverless#DynamoDB vs relational (RDS / Aurora, including Serverless)|DynamoDB vs relational (RDS / Aurora, including Serverless)]] · [[19-serverless#Global secondary index vs local secondary index|Global secondary index vs local secondary index]] · [[19-serverless#The three Lambda invocation models|The three Lambda invocation models]] · [[19-serverless#Reserved vs provisioned concurrency|Reserved vs provisioned concurrency]] · [[19-serverless#REST API vs HTTP API|REST API vs HTTP API]] · [[19-serverless#API Gateway vs ALB as a front door|API Gateway vs ALB as a front door]]

- **Lambda in a public subnet** — "Give the VPC-attached function internet access" is not answered by moving it to a public subnet.  
  ↳ [[19-serverless#⚠️ Traps — why the wrong answer looks right|note]]
- **ENI per concurrent execution** — Older material teaches that a VPC Lambda creates one ENI per concurrent execution, making IP exhaustion a scaling risk.  
  ↳ [[19-serverless#⚠️ Traps — why the wrong answer looks right|note]]
- **SQS is not an asynchronous invocation** — S3 and SNS invoke Lambda asynchronously, so Lambda retries twice and then uses a DLQ. SQS is an event source mapping — Lambda polls it — so retry behaviour comes from the queue's visibility timeout and maxReceiveCount, exactly as in [[15-decoupling]].  
  ↳ [[19-serverless#⚠️ Traps — why the wrong answer looks right|note]]
- **API keys are not authentication** — Usage plans and API keys "track and limit usage". They identify a caller for metering and throttling; they prove nothing about identity.  
  ↳ [[19-serverless#⚠️ Traps — why the wrong answer looks right|note]]
- **"ECS-style" two roles on Lambda** — ECS splits an execution role (the agent: pull the image, ship logs) from a task role (your code's AWS permissions).  
  ↳ [[19-serverless#⚠️ Traps — why the wrong answer looks right|note]]
- **more memory is always more expensive** — Not necessarily. Lambda bills GB-seconds, and CPU scales with memory, so doubling memory on a CPU-bound function can more than halve its duration.  
  ↳ [[19-serverless#⚠️ Traps — why the wrong answer looks right|note]]


## [[20-monitoring|20 – Monitoring (CloudWatch, CloudTrail, Config, EventBridge)]]

**Compare:** [[20-monitoring#The four services — the discrimination the exam actually tests|The four services — the discrimination the exam actually tests]] · [[20-monitoring#CloudTrail vs Config, on the same security group change|CloudTrail vs Config, on the same security group change]] · [[20-monitoring#CloudWatch event types|CloudWatch event types]] · [[20-monitoring#Management vs data events (CloudTrail)|Management vs data events (CloudTrail)]] · [[20-monitoring#Getting an alert out of a log line|Getting an alert out of a log line]]

- **a bastion host offered for private-instance access** — Any stem asking to reach an instance in a private subnet lists a bastion/jump host, an inbound SSH rule from the corporate CIDR, or a key-pair distribution scheme.  
  ↳ [[20-monitoring#⚠️ Traps — why the wrong answer looks right|note]]
- **CloudTrail for "what did this resource look like"** — CloudTrail records the API call, not the resulting state. "Was this bucket public at any point last quarter?" or "produce evidence that all volumes have been encrypted since January" is AWS Config — it stores configuration items over time and evaluates rules against them.  
  ↳ [[20-monitoring#⚠️ Traps — why the wrong answer looks right|note]]
- **memory utilisation in the EC2 console** — There is no default memory or disk-space metric for EC2, because the hypervisor cannot see inside the guest.  
  ↳ [[20-monitoring#⚠️ Traps — why the wrong answer looks right|note]]
- **"enable CloudTrail to see who read the S3 object"** — CloudTrail is on by default only for management events. Object-level reads and writes are data events, which "trails and event data stores" do not log by default.  
  ↳ [[20-monitoring#⚠️ Traps — why the wrong answer looks right|note]]
- **CloudWatch Events versus EventBridge** — They are the same service; CloudWatch Events was renamed to EventBridge. If a question offers both as separate options, they are not testing a distinction — look at what else the options differ on.  
  ↳ [[20-monitoring#⚠️ Traps — why the wrong answer looks right|note]]
- **the 90 days** — "CloudTrail keeps 90 days" is true of the free Event history view, per Region, management events only.  
  ↳ [[20-monitoring#⚠️ Traps — why the wrong answer looks right|note]]
- **composite alarms doing Auto Scaling** — Composite alarms exist to reduce noise by combining other alarms' states. They "can send Amazon SNS notifications when they change state... but can't perform EC2 actions or Auto Scaling actions." If the stem needs a scaling action, the alarm doing it must be a metric alarm.  
  ↳ [[20-monitoring#⚠️ Traps — why the wrong answer looks right|note]]


## [[21-security|21 – Security & Encryption]]

**Compare:** [[21-security#KMS key types|KMS key types]] · [[21-security#Secrets Manager vs SSM Parameter Store|Secrets Manager vs SSM Parameter Store]] · [[21-security#Which detection service|Which detection service]] · [[21-security#Shield Standard vs Advanced vs WAF|Shield Standard vs Advanced vs WAF]] · [[21-security#CloudHSM vs KMS|CloudHSM vs KMS]] · [[21-security#ACM — where the certificate has to live|ACM — where the certificate has to live]]

- **a regional certificate offered for CloudFront** — CloudFront is global and takes its certificate only from us-east-1, no matter where the origin or the bucket sits.  
  ↳ [[21-security#⚠️ Traps — why the wrong answer looks right|note]]
- **rotation re-encrypts your data** — It does not. "Key rotation has no effect on the data that the KMS key protects. It does not rotate the data keys that the KMS key generated or re-encrypt any data protected by the KMS key." Old key material is retained so old ciphertext still decrypts, and the key ID is unchanged — which is why rotation is transparent to applications and requires no code change.  
  ↳ [[21-security#⚠️ Traps — why the wrong answer looks right|note]]
- **"rotate this asymmetric key automatically"** — Automatic rotation is "supported only on symmetric encryption KMS keys with key material that AWS KMS generates." Asymmetric keys, HMAC keys and custom-key-store keys cannot auto-rotate — the answer is manual rotation (create a new key, repoint the alias).  
  ↳ [[21-security#⚠️ Traps — why the wrong answer looks right|note]]
- **Parameter Store for a rotating password** — Parameter Store has no rotation. SecureString encrypts a value with KMS; it does not change it on a schedule.  
  ↳ [[21-security#⚠️ Traps — why the wrong answer looks right|note]]
- **Macie on anything other than S3** — Macie is "a data security service that discovers sensitive data" in Amazon S3. It does not scan RDS, EBS, DynamoDB or EFS.  
  ↳ [[21-security#⚠️ Traps — why the wrong answer looks right|note]]
- **WAF on a Network Load Balancer** — A web ACL attaches to an ALB, API Gateway REST API, AppSync, Cognito user pool, App Runner, Amplify, Verified Access — or CloudFront.  
  ↳ [[21-security#⚠️ Traps — why the wrong answer looks right|note]]
- **Shield Advanced to block SQL injection** — Shield is DDoS. SQL injection, XSS and bad bots are WAF. Shield Advanced adds layer-7 DDoS mitigation and covers your standard WAF costs on protected resources, but it is not where you write "block requests containing ' OR 1=1".  
  ↳ [[21-security#⚠️ Traps — why the wrong answer looks right|note]]
- **GuardDuty needs you to turn on flow logs** — It does not. GuardDuty consumes "an independent and duplicated stream" of CloudTrail management events, VPC Flow Logs and Route 53 DNS query logs — "You don't need to enable anything else", and enabling or disabling your own flow logs changes nothing about GuardDuty.  
  ↳ [[21-security#⚠️ Traps — why the wrong answer looks right|note]]


## [[22-analytics|22 – Data & Analytics]]

**Compare:** [[22-analytics#The four query engines|The four query engines]] · [[22-analytics#Which engine does the exam mean?|Which engine does the exam mean?]] · [[22-analytics#Redshift vs RDS/Aurora|Redshift vs RDS/Aurora]] · [[22-analytics#Kinesis vs MSK|Kinesis vs MSK]]

- **Athena vs Redshift** — Both run SQL over big data, so scenarios are written to make you pick on familiarity. The axis is infrastructure and frequency, not capability. Ad-hoc, intermittent, "no infrastructure to manage", "pay only for what you query" → Athena. Sustained load, many concurrent BI users, complex multi-table joins, a dedicated warehouse → Redshift. If the scenario mentions loading/ETL into the engine first, that's Redshift; if the data stays in S3, that's Athena.  
  ↳ [[22-analytics#Traps|note]]
- **reducing Athena cost by resizing something** — Athena has nothing to resize — it's serverless and billed on bytes scanned. Any option offering a bigger instance, more nodes, or provisioned capacity is wrong by construction.  
  ↳ [[22-analytics#Traps|note]]
- **Redshift Spectrum as a standalone service** — Spectrum is a feature of Redshift, not an alternative to it. It requires a running cluster, and the cluster must be in the same Region as the S3 data.  
  ↳ [[22-analytics#Traps|note]]
- **OpenSearch vs Athena for "analyse our logs"** — Both can touch log data and the wording is deliberately close. OpenSearch is for full-text search, relevance ranking, and live operational dashboards over recent logs — near-real-time, always-on cluster. Athena is for SQL aggregates over historical logs already in S3 — nothing running between queries.  
  ↳ [[22-analytics#Traps|note]]
- **EMR core nodes on Spot** — Task nodes are the Spot answer because they store no HDFS data — losing one costs compute only.  
  ↳ [[22-analytics#Traps|note]]
- **AWS Data Pipeline as a live answer** — It still appears in the SAA-C03 exam guide's in-scope list and in older practice questions, but AWS Data Pipeline is closed to new customers and in maintenance mode, with console access removed in April 2023.  
  ↳ [[22-analytics#Traps|note]]
- **building a second catalog per engine** — Athena, EMR and Redshift Spectrum all read the same AWS Glue Data Catalog. Options that propose defining schemas separately for each engine, or syncing metadata between them, are describing work AWS already did.  
  ↳ [[22-analytics#Traps|note]]


## [[23-machine-learning|23 – Machine Learning]]

**Compare:** [[23-machine-learning#Pre-trained AI service vs SageMaker|Pre-trained AI service vs SageMaker]] · [[23-machine-learning#The four modality neighbours|The four modality neighbours]] · [[23-machine-learning#Text services — analyse, search, converse, translate|Text services — analyse, search, converse, translate]] · [[23-machine-learning#Kendra vs OpenSearch|Kendra vs OpenSearch]]

- **Rekognition where Textract belongs** — Both take things that look like images, so scenarios use "scanned" and "uploaded image" interchangeably to bait you.  
  ↳ [[23-machine-learning#Traps|note]]
- **SageMaker as the serious-sounding answer** — SageMaker is correct only when the question calls for a custom model trained on the customer's own data, or says the pre-trained options don't fit.  
  ↳ [[23-machine-learning#Traps|note]]
- **Transcribe and Polly reversed** — They're one word apart in a question and opposite in direction. Transcribe consumes audio and produces text (call recordings, subtitles, meeting notes).  
  ↳ [[23-machine-learning#Traps|note]]
- **Comprehend asked to search, Kendra asked to analyse** — Both take text and both sound like "understand our documents". **Comprehend extracts insights about text** — sentiment, entities, PII, topics — and returns no ranked results.  
  ↳ [[23-machine-learning#Traps|note]]
- **synchronous ML APIs on large inputs** — Textract's synchronous operations handle single-page documents only; multi-page PDFs require the asynchronous API, and long audio in Transcribe works the same way.  
  ↳ [[23-machine-learning#Traps|note]]
- **assuming a retired service is a wrong answer** — Forecast, Fraud Detector and Kendra are all closed to new customers, but all three are still in the SAA-C03 exam guide's in-scope list.  
  ↳ [[23-machine-learning#Traps|note]]


## [[24-other-services|24 – Other Services]]

**Compare:** [[24-other-services#Step Functions — Standard vs Express|Step Functions — Standard vs Express]] · [[24-other-services#Directory Service options|Directory Service options]] · [[24-other-services#Batch vs Lambda|Batch vs Lambda]] · [[24-other-services#Transfer Family vs DataSync|Transfer Family vs DataSync]]

- **user pool offered where an identity pool is needed** — The tell is what the app does after signing in. If it only needs to know who the user is, or to put a token in front of an API, that is a user pool.  
  ↳ [[24-other-services#Traps|note]]
- **DMS alone for a heterogeneous migration** — DMS moves data. It does not translate a schema between different engines. Any Oracle→PostgreSQL or SQL Server→MySQL scenario needs AWS SCT / DMS Schema Conversion first, then DMS.  
  ↳ [[24-other-services#Traps|note]]
- **Standard vs Express workflows** — Decide on duration and volume, not sophistication. Express caps at five minutes and is at-least-once — so anything long-running, anything needing exactly-once, and anything waiting on a human approval (.waitForTaskToken, which Express doesn't support) must be Standard.  
  ↳ [[24-other-services#Traps|note]]
- **AD Connector or Simple AD where RDS for SQL Server is involved** — Only AWS Managed Microsoft AD works with Amazon RDS for SQL Server. AD Connector and Simple AD are both explicitly incompatible.  
  ↳ [[24-other-services#Traps|note]]
- **Lambda for a job that outgrows 15 minutes** — Lambda's 15-minute maximum is a hard ceiling, and scenarios describing genomics processing, video rendering, simulations or multi-hour ETL are built around it.  
  ↳ [[24-other-services#Traps|note]]
- **Transfer Family confused with DataSync** — Both move files into AWS and both appear together as options. Transfer Family is a standing endpoint speaking SFTP/FTPS/FTP/AS2, for external parties using their own clients. DataSync is a transfer job you run to move a dataset between storage systems.  
  ↳ [[24-other-services#Traps|note]]
- **assuming Elastic Beanstalk costs extra or hides the resources** — Beanstalk itself is free — you pay only for the EC2, ELB and other resources it creates, so "additional service cost" is never a reason to reject it.  
  ↳ [[24-other-services#Traps|note]]
- **reaching for Directory Service for a SaaS app's end users** — Directory Service is for corporate/workforce identity — employees, domain-joined machines, AD-aware applications.  
  ↳ [[24-other-services#Traps|note]]


## [[25-well-architected|25 – Well-Architected Framework]]

**Compare:** [[25-well-architected#The six pillars, and where each lives in this vault|The six pillars, and where each lives in this vault]] · [[25-well-architected#WA Tool vs Trusted Advisor vs AWS Config|WA Tool vs Trusted Advisor vs AWS Config]]

- **five pillars instead of six** — Sustainability is a full pillar, and it's the newest. Course material, blog posts and older practice banks written before it was added say five.  
  ↳ [[25-well-architected#Traps|note]]
- **Reliability and Performance Efficiency treated as one thing** — They sound adjacent and are tested apart. Reliability is about surviving and recovering from failure — Multi-AZ, health checks, backups, DR strategy.  
  ↳ [[25-well-architected#Traps|note]]
- **Trusted Advisor assumed to be fully available on any account** — On Basic or Developer Support you get only the full Service Limits category plus a fixed handful of Security and Fault Tolerance checks (MFA on root account, S3 bucket permissions, public EBS/RDS snapshots, unrestricted specific ports, STS global endpoint).  
  ↳ [[25-well-architected#Traps|note]]
- **Trusted Advisor asked to do continuous compliance** — Trusted Advisor recommends; it does not enforce, and on Basic it doesn't even refresh Security checks automatically.  
  ↳ [[25-well-architected#Traps|note]]
