---
tags: [exam-prep, generated]
---

# 🌙 Exam-morning skim sheet

> [!warning] Generated file — do not edit
> Built by `_scripts/build_exam_night.py`. Edit the **notes**, then re-run.

**How to use it.** Read a hook. If the concept comes straight back, move on.
If it doesn't, follow the ↳ link — it lands on the section that *explains*
that idea. Trap and comparison entries are titles only, on purpose.
For the longer night-before read see **[[revision/00-index]]**.

*127 recall hooks · 213 pointers · ~21 min read*

## [[01-iam|01 – IAM (Identity and Access Management)]]

- IAM decides who you are and what you may do on every AWS API call — global, free, and never optional.  
  ↳ [[01-iam#What problem does this solve?|explain]]
- The default is no, an Allow lifts it, and an explicit Deny puts it back forever — order, count and specificity change nothing.  
  ↳ [[01-iam#Explicit Deny wins, and nothing else counts|explain]]
- A role is a credential-less hat — the trust policy says who may wear it, the permissions policy says what it can do, and either half missing breaks it differently.  
  ↳ [[01-iam#A role is a hat, and it needs two policies|explain]]
- EC2 wears the hat through an instance profile; the console hides the wrapper, Terraform makes you write it.  
  ↳ [[01-iam#The instance profile — the wrapper the console hides|explain]]
- Principals go by name, policies go by ARN — and both are strings, so nothing but your own eyes will catch the swap.  
  ↳ [[01-iam#Why a principal is named but a policy is an ARN|explain]]
- If the users already exist, don't copy them — federate, and the AD group ends up wearing an IAM role.  
  ↳ [[01-iam#When the users already exist somewhere else|explain]]

**Traps** [[01-iam|open]]
- "the plan showed the policy was fine"
- Policy order or count matters
- Specificity wins
- Roles are only for AWS services
- Long-lived access keys are fine for service-to-service
- IAM is regional
- Attach a role directly to an EC2 instance
- All name arguments on IAM resources behave the same
- validate/plan catch reference bugs (.arn vs .name, quoted strings)
- "create IAM users for the on-premises staff"
- AD Connector vs AWS Managed Microsoft AD
- rds: vs rds-db: for database login

**Failure modes**
- confused deputy (the missing ExternalId)  ↳ [[01-iam#Worked examples|open]]

**Comparisons**
- [[01-iam#User vs Role|User vs Role]]
- [[01-iam#Inline vs Managed policy|Inline vs Managed policy]]
- [[01-iam#Trust policy vs Permissions policy (on a Role)|Trust policy vs Permissions policy (on a Role)]]
- [[01-iam#Bringing existing corporate identities into AWS (Directory Service + federation)|Bringing existing corporate identities into AWS (Directory Service + federation)]]


## [[01-iam-advanced|01b – IAM Advanced (Organizations, SCPs, boundaries, ABAC)]]

- Many accounts limit the damage; SCPs enforce the rules across all of them.  
  ↳ [[01-iam-advanced#What problem does this solve?|explain]]
- IAM grants, the SCP caps, and you get whichever is smaller.  
  ↳ [[01-iam-advanced#The one idea: granting versus capping|explain]]
- Every level in the chain has to say yes; one silent level means no.  
  ↳ [[01-iam-advanced#Why an Allow has to exist at every level|explain]]
- The account that writes the rules is exempt from them; every other account's root user is not.  
  ↳ [[01-iam-advanced#The root-user rule that catches everyone|explain]]
- An SCP caps an account, a boundary caps one identity, and neither one grants anything.  
  ↳ [[01-iam-advanced#Permissions boundaries — the same idea, one identity at a time|explain]]
- Resource policies add access, everything else subtracts it, and an explicit Deny beats the lot.  
  ↳ [[01-iam-advanced#Why one combining rule is the odd one out|explain]]

**Traps** [[01-iam-advanced#Traps|open]]
- "attach an SCP to give that account access"
- root user and SCPs
- permissions boundary vs SCP
- Bool vs BoolIfExists for MFA
- Control Tower vs Organizations
- aws:SourceIp behind a VPC endpoint

**Failure modes**
- the deny-only SCP that locked out the whole organization  ↳ [[01-iam-advanced#Worked examples|open]]

**Comparisons**
- [[01-iam-advanced#The four things that can cap a permission|The four things that can cap a permission]]
- [[01-iam-advanced#How policy types combine|How policy types combine]]
- [[01-iam-advanced#RBAC vs ABAC|RBAC vs ABAC]]
- [[01-iam-advanced#Condition keys worth memorising|Condition keys worth memorising]]


## [[02-ec2|02 – EC2 (Elastic Compute Cloud)]]

- EC2 rents you a virtual server by the second and hands you every decision a physical one would have made for you.  
  ↳ [[02-ec2#What problem does this solve?|explain]]
- The AMI is regional and the subnet fixes the AZ — those are the two parts you cannot swap under a live instance.  
  ↳ [[02-ec2#What an instance is actually made of|explain]]
- Stop keeps EBS and kills instance store; terminate kills the root volume too but leaves extra volumes behind.  
  ↳ [[02-ec2#Stop is not terminate, and only part of it survives|explain]]
- An auto-assigned IP belongs to the instance and changes on stop, an EIP belongs to you and doesn't — and since Feb 2024 both are billed.  
  ↳ [[02-ec2#Why the public IP walks away when you stop|explain]]
- EC2 gets its permissions from a role, but the thing you hand the instance is the instance profile wrapping that role.  
  ↳ [[02-ec2#Giving the instance an identity without putting a secret on it|explain]]
- IMDSv2 wants a PUT for a token before any GET, and skipping it fails quietly instead of loudly.  
  ↳ [[02-ec2#Why a plain curl to the metadata endpoint returns nothing|explain]]

**Traps** [[02-ec2|open]]
- All EC2 attributes can be changed in-place
- ip_protocol accepts "ssh" / "http"
- t3-micro works
- aws_subnets.X.id returns one subnet ID
- IAM changes are instant
- EBS volumes can be moved across AZs by detach + attach
- Instance store survives stop
- Long-lived access keys on an instance are fine for service-to-service
- EIP is free while attached

**Failure modes**
- credit exhaustion (it bites two different ways)  ↳ [[02-ec2#Worked examples|open]]

**Comparisons**
- [[02-ec2#Stop vs Terminate|Stop vs Terminate]]
- [[02-ec2#EBS vs Instance Store|EBS vs Instance Store]]
- [[02-ec2#Auto-assigned Public IP vs Elastic IP|Auto-assigned Public IP vs Elastic IP]]
- [[02-ec2#IMDSv1 vs IMDSv2|IMDSv1 vs IMDSv2]]


## [[04-alb-asg|04 – ALB + Auto Scaling Group]]

- The ALB decides which instance gets a request, the ASG decides how many instances exist, and the target group is the only thing connecting the two.  
  ↳ [[04-alb-asg#What problem does this solve?|explain]]
- The ALB reads the request, so it can route on anything inside it and answer some requests itself; the NLB can't, but hands you a static IP and the true client IP.  
  ↳ [[04-alb-asg#The ALB opens your HTTP request, and everything follows from that|explain]]
- The ASG registers instances into the target group, but only acts on the ALB's health verdict when health_check_type = "ELB" — and only after the grace period expires.  
  ↳ [[04-alb-asg#The target group is the joint — and two health checks meet inside it|explain]]
- Target tracking is asymmetric on purpose — nothing below the target will ever scale you out, only real load above it will.  
  ↳ [[04-alb-asg#Target tracking scales out fast and scales in slowly, deliberately|explain]]
- AZ balance first, then oldest configuration, then billing hour, then random — and unhealthy instances bypass the whole ordering.  
  ↳ [[04-alb-asg#Which instance dies when it scales in|explain]]
- Schedule desired capacity only, so dynamic scaling keeps working — and in Terraform write min_size = -1 / max_size = -1, because omitted means zero, not unchanged.  
  ↳ [[04-alb-asg#Scheduling capacity without freezing the group|explain]]

**Traps** [[04-alb-asg#The Terraform I wrote|open]]
- "the ALB terminates the unhealthy instance"
- "a failed ALB health check means users get errors"
- NLB vs ALB for a static IP / source-IP
- cross-zone billing
- "scale-in terminates the oldest instance"
- a scheduled action that also pins min and max
- redirect on the wrong load balancer, or the wrong direction

**Failure modes**
- the grace-period boot loop  ↳ [[04-alb-asg#Worked examples|open]]
- aws_autoscaling_schedule silently scaling your group to zero  ↳ [[04-alb-asg#Worked examples|open]]

**Comparisons**
- [[04-alb-asg#ALB vs NLB vs GWLB|ALB vs NLB vs GWLB]]
- [[04-alb-asg#Scaling policy types|Scaling policy types]]
- [[04-alb-asg#Predefined termination policies|Predefined termination policies]]


## [[05-vpc-core|05.1 – VPC Core (subnets, routing, IGW, NAT)]]

- A VPC is a network you define; whether any part of it is public is a routing decision, not a property of the subnet.  
  ↳ [[05-vpc-core#What problem does this solve?|explain]]
- A subnet is one AZ, a VPC is one region, and every subnet is five addresses smaller than it looks.  
  ↳ [[05-vpc-core#The address space, and the five IPs you never get|explain]]
- Public = IGW route + public IP, both required; the route table decides, and the main route table must never be the one that says yes.  
  ↳ [[05-vpc-core#There is no public subnet checkbox|explain]]
- The NAT needs its own door to the internet, so it lives in a public subnet — the private RT points at the NAT, and the NAT's RT points at the IGW.  
  ↳ [[05-vpc-core#Why the NAT gateway has to live in a public subnet|explain]]
- A NAT gateway is redundant inside its AZ and nowhere else — one per AZ, or you have built a single point of failure with a cross-AZ bill attached.  
  ↳ [[05-vpc-core#Why one NAT gateway is not enough|explain]]
- AWS's own defaults are open, anything you create is closed, and Terraform ignores the defaults until you adopt them.  
  ↳ [[05-vpc-core#The defaults that behave backwards from what you create|explain]]

**Traps** [[05-vpc-core#The Terraform I wrote|open]]
- "the default NACL and a new NACL behave the same"
- "add the IGW route to the main route table to make setup simpler"

**Failure modes**
- NAT gateway in the wrong subnet (the routing loop)  ↳ [[05-vpc-core#Worked examples|open]]
- single NAT gateway as an AZ SPOF  ↳ [[05-vpc-core#Worked examples|open]]

**Comparisons**
- [[05-vpc-core#NAT Gateway vs NAT Instance|NAT Gateway vs NAT Instance]]
- [[05-vpc-core#IGW vs NAT Gateway vs Egress-only IGW|IGW vs NAT Gateway vs Egress-only IGW]]


## [[05-vpc-security|05.2 – VPC Security (SG, NACL, Flow Logs, Network Firewall)]]

- The SG guards the instance and can only allow, the NACL guards the subnet and can deny, and Flow Logs record whether the traffic was allowed or rejected.  
  ↳ [[05-vpc-security#What problem does this solve?|explain]]
- The SG remembers the conversation, the NACL sees one packet at a time — so on a NACL you must write both halves.  
  ↳ [[05-vpc-security#Stateful versus stateless|explain]]
- Replies land on 1024–65535 — outbound if you're answering, inbound if you're asking — and a TCP-only rule set silently drops UDP.  
  ↳ [[05-vpc-security#Ephemeral ports, and which direction to open them|explain]]
- Lowest matching number wins and stops the search — and a custom NACL starts closed while the default one starts open.  
  ↳ [[05-vpc-security#Numbered rules, and first match wins|explain]]
- Flow logs give you who-to-whom-on-what-port plus ACCEPT or REJECT — never the contents.  
  ↳ [[05-vpc-security#What flow logs can and cannot tell you|explain]]
- SG and NACL filter addresses, Network Firewall inspects contents — and it only sees what your route tables send it.  
  ↳ [[05-vpc-security#Network Firewall, and why it needs a subnet of its own|explain]]

**Traps** [[05-vpc-security#The Terraform I wrote|open]]
- "make the NACL match the SG rules and you're done"
- "use flow logs to see what data was exfiltrated"
- "a higher NACL rule number can override a lower deny"

**Failure modes**
- the stateless NACL that "half works"  ↳ [[05-vpc-security#Worked examples|open]]

**Comparisons**
- [[05-vpc-security#Security Group vs Network ACL (the exam's favorite table)|Security Group vs Network ACL (the exam's favorite table)]]
- [[05-vpc-security#Where each layer sits|Where each layer sits]]


## [[05-vpc-endpoints-peering|05.3 – VPC Endpoints & Peering (+ Transit Gateway)]]

- Endpoints get you privately to AWS services; peering and Transit Gateway get you privately to other VPCs.  
  ↳ [[05-vpc-endpoints-peering#What problem does this solve?|explain]]
- A gateway endpoint is a free route-table entry for S3/DynamoDB, usable only from inside the VPC that owns the route table.  
  ↳ [[05-vpc-endpoints-peering#The gateway endpoint is a route, not a box|explain]]
- An interface endpoint is a PrivateLink ENI with a private IP — most services, billed per AZ per hour, and reachable across peering/VPN/DX.  
  ↳ [[05-vpc-endpoints-peering#The interface endpoint is an IP, not a route|explain]]
- Peering is a private 1-to-1 link with routes on both sides, no overlapping CIDRs, and no path through it to anywhere else.  
  ↳ [[05-vpc-endpoints-peering#Why peering never becomes a hub|explain]]
- Peering is O(N²) and non-transitive, so at many VPCs / hybrid at scale the answer becomes one Transit Gateway hub.  
  ↳ [[05-vpc-endpoints-peering#The mesh math, and what Transit Gateway replaces|explain]]

**Traps** [[05-vpc-endpoints-peering#The Terraform I wrote|open]]
- "use a gateway endpoint for SQS/KMS/etc."
- "reach the S3 gateway endpoint from a peered VPC / on-prem"
- "peering scales fine, just add connections"

**Failure modes**
- assuming peering is transitive (the hub that isn't)  ↳ [[05-vpc-endpoints-peering#Worked examples|open]]

**Comparisons**
- [[05-vpc-endpoints-peering#Gateway vs Interface endpoint|Gateway vs Interface endpoint]]
- [[05-vpc-endpoints-peering#VPC Peering vs Transit Gateway|VPC Peering vs Transit Gateway]]


## [[05-vpc-hybrid|05.4 – VPC Hybrid Connectivity (VPN & Direct Connect)]]

- A VPN rents an encrypted tunnel across the internet; Direct Connect buys a private wire that avoids it.  
  ↳ [[05-vpc-hybrid#What problem does this solve?|explain]]
- VGW is AWS's end, CGW is a description of your end, and every connection ships with two tunnels whether you asked for them or not.  
  ↳ [[05-vpc-hybrid#The two endpoints, and why one of them isn't a device|explain]]
- DX gives you a private path, not a secret one — layer a VPN on top when the auditor asks.  
  ↳ [[05-vpc-hybrid#Private is not the same as encrypted|explain]]
- The fiber is the port; the VIF declares whether it lands in a VPC, on AWS's public services, or on a Transit Gateway.  
  ↳ [[05-vpc-hybrid#What a Direct Connect port actually carries|explain]]
- A DXGW fans one circuit out to VPCs in many regions; a TGW is what lets those VPCs talk to each other.  
  ↳ [[05-vpc-hybrid#One circuit, many VPCs — and the limit of that|explain]]
- Throughput argues for Direct Connect, but the calendar picks the VPN.  
  ↳ [[05-vpc-hybrid#The calendar usually decides, not the bandwidth|explain]]

**Traps** [[05-vpc-hybrid#The Terraform I wrote|open]]
- "Direct Connect is encrypted because it's private"
- "use Direct Connect for a quick or temporary connection"
- "VGW vs CGW"
- "Client VPN = Site-to-Site VPN"

**Failure modes**
- betting a launch on Direct Connect lead time  ↳ [[05-vpc-hybrid#Worked examples|open]]

**Comparisons**
- [[05-vpc-hybrid#Site-to-Site VPN vs Direct Connect|Site-to-Site VPN vs Direct Connect]]
- [[05-vpc-hybrid#Which one? (exam triggers)|Which one? (exam triggers)]]


## [[06-capstone|06 – Capstone: 3-Tier VPC with Terraform Modules]]

- Tiers limit the blast radius of a breach; modules turn one untouchable file into composable, reusable pieces.  
  ↳ [[06-capstone#What problem does this solve?|explain]]
- Each tier only accepts the group in front of it, referenced by SG ID so it survives every scale event.  
  ↳ [[06-capstone#The security-group chain is the architecture|explain]]
- A module is a directory with variables in and outputs out, and its outputs reach the caller and stop there.  
  ↳ [[06-capstone#Modules, and the output that goes missing|explain]]
- Multi-AZ is a standby you cannot read that fails over automatically; a read replica is a copy you can read but must promote by hand.  
  ↳ [[06-capstone#Multi-AZ and read replicas solve different problems|explain]]
- Encryption is decided at creation and the only way back is snapshot-copy-restore; the username and password just have to survive RDS's validation rules.  
  ↳ [[06-capstone#The RDS setting you can only get right once|explain]]
- A bastion opens a door and guards it; Session Manager opens no door and dials out instead.  
  ↳ [[06-capstone#Reaching a database that has no way in|explain]]

**Traps** [[06-capstone#The Terraform I wrote|open]]
- Multi-AZ to scale reads
- "the module output shows in terraform output"

**Failure modes**
- the all-protocols-with-ports egress error  ↳ [[06-capstone#Worked examples|open]]
- secret in a committed .tf file  ↳ [[06-capstone#Worked examples|open]]

**Comparisons**
- [[06-capstone#RDS Multi-AZ vs Read Replica (the number-one RDS exam trap)|RDS Multi-AZ vs Read Replica (the number-one RDS exam trap)]]
- [[06-capstone#Flat config vs Modules|Flat config vs Modules]]
- [[06-capstone#Accessing the private database (bastion vs SSM)|Accessing the private database (bastion vs SSM)]]


## [[07-rds-aurora|07 – RDS & Aurora]]

- RDS hands AWS the operational chores; Aurora hands them over too, and re-architects the storage underneath so the limits of a single volume stop applying.  
  ↳ [[07-rds-aurora#What problem does this solve?|explain]]
- The standby is unreadable on purpose, because its job is to be identical rather than useful.  
  ↳ [[07-rds-aurora#Multi-AZ and read replicas are two different jobs|explain]]
- The instances share one 6-copy volume instead of each owning a copy, and every Aurora advantage is a consequence of that.  
  ↳ [[07-rds-aurora#Why Aurora's storage layer changes everything above it|explain]]
- Automated backups die with the instance, manual snapshots don't, every restore is a new endpoint, and encryption at rest is creation-time only.  
  ↳ [[07-rds-aurora#Backups, restores, and the encryption rule with no undo|explain]]
- A 15-minute signed token used as the password, gated by rds-db:connect on the instance's resource id — nothing stored, nothing rotated, nothing in CloudTrail.  
  ↳ [[07-rds-aurora#Logging in with an IAM role instead of a password|explain]]

**Traps** [[07-rds-aurora#The Terraform I wrote|open]]
- "IAM database authentication controls what the user can do in the database"
- rds-db: vs rds:
- "use IAM DB auth so database logins show up in CloudTrail"
- Multi-AZ to scale reads
- Aurora replica lag is like RDS replica lag
- "RDS is serverless / auto-scales like Aurora"

**Failure modes**
- "we'll encrypt the database later"  ↳ [[07-rds-aurora#Worked examples|open]]
- the connection pool that dies 15 minutes after deploy  ↳ [[07-rds-aurora#The Terraform I wrote|open]]

**Comparisons**
- [[07-rds-aurora#Multi-AZ vs Read Replica (memorize)|Multi-AZ vs Read Replica (memorize)]]
- [[07-rds-aurora#RDS vs Aurora|RDS vs Aurora]]
- [[07-rds-aurora#Database authentication — password vs IAM vs Secrets Manager|Database authentication — password vs IAM vs Secrets Manager]]


## [[08-elasticache|08 – ElastiCache (Redis / Memcached)]]

- A cache stores answers in RAM so the database stops re-answering the same question.  
  ↳ [[08-elasticache#What problem does this solve?|explain]]
- The cache fills on misses, TTL bounds how stale it may get, and none of it helps writes.  
  ↳ [[08-elasticache#The hit, the miss, and why the cache starts empty|explain]]
- Memcached is the multi-threaded one; Redis buys throughput with shards, not cores.  
  ↳ [[08-elasticache#Redis is single-threaded — and that is not a bug|explain]]
- Memcached forgets on node loss; Redis replicates, fails over, persists and backs up.  
  ↳ [[08-elasticache#What Memcached simply does not have|explain]]
- One endpoint gets you every endpoint — Memcached only, and AWS says so in writing.  
  ↳ [[08-elasticache#Auto Discovery, the odd Memcached-only feature|explain]]
- Find the capability only one engine has; the use case is the distractor.  
  ↳ [[08-elasticache#Reading the engine question the right way round|explain]]

**Traps** [[08-elasticache#The Terraform I wrote|open]]
- Memcached for anything needing HA/persistence/complex data
- a question that mixes Redis-sounding use cases with Memcached-only features
- "add a cache" when the problem is writes
- Redis is multi-threaded because it's fast

**Failure modes**
- Memcached for a session store  ↳ [[08-elasticache#Worked examples|open]]

**Comparisons**
- [[08-elasticache#Redis vs Memcached (the exam table)|Redis vs Memcached (the exam table)]]
- [[08-elasticache#Caching strategies|Caching strategies]]


## [[09-s3-intro|09.1 – S3 Introduction (buckets, classes, versioning, lifecycle)]]

- Durable file storage addressed by name, with tiers and automatic ageing so old data gets cheap instead of getting expensive.  
  ↳ [[09-s3-intro#What problem does this solve?|explain]]
- A bucket is a globally-unique name for a regional flat key→object map, and folders are a console illusion.  
  ↳ [[09-s3-intro#The key is the whole name, and there are no folders|explain]]
- Every class is eleven-nines durable, availability and AZ count are what actually differ, and One Zone-IA sits in a single AZ.  
  ↳ [[09-s3-intro#Durability and availability are two different numbers|explain]]
- Cheaper classes charge a minimum stay and a minimum object size, so short-lived or tiny objects can cost more down the ladder, not less.  
  ↳ [[09-s3-intro#Why moving data to a cheaper class can cost you more|explain]]
- With versioning on, delete only hides; old versions bill forever until a noncurrent-version expiration rule removes them.  
  ↳ [[09-s3-intro#Versioning, delete markers, and the bill that grows in the dark|explain]]

**Traps** [[09-s3-intro#The Terraform I wrote|open]]
- "S3 has folders"
- "Glacier means slow retrieval"
- durability vs availability
- moving to IA/Glacier always saves money

**Failure modes**
- versioning without noncurrent-version expiration  ↳ [[09-s3-intro#Worked examples|open]]
- One Zone-IA for the only copy  ↳ [[09-s3-intro#Worked examples|open]]

**Comparisons**
- [[09-s3-intro#Storage classes (verified against AWS docs 2026-08)|Storage classes (verified against AWS docs 2026-08)]]
- [[09-s3-intro#Versioning: delete vs permanent delete|Versioning: delete vs permanent delete]]


## [[09-s3-advanced|09.2 – S3 Advanced (replication, big files, events)]]

- Copy it elsewhere, move it efficiently, and react when it changes.  
  ↳ [[09-s3-advanced#What problem does this solve?|explain]]
- Replication only copies what happens next; everything else — pre-existing, failed, or a replica — needs Batch Replication.  
  ↳ [[09-s3-advanced#Replication starts from now, not from the beginning|explain]]
- Parts upload in parallel and retry individually — and the ones you never finish keep billing invisibly.  
  ↳ [[09-s3-advanced#Why a big upload is many small ones|explain]]
- Nearest edge, then AWS's private backbone — the bucket stays exactly where it was.  
  ↳ [[09-s3-advanced#Transfer Acceleration moves the path, not the bucket|explain]]
- The destination must grant S3 permission, and the output must never land where the trigger is watching.  
  ↳ [[09-s3-advanced#Events, and the two ways they fail|explain]]

**Traps** [[09-s3-advanced#The Terraform I wrote|open]]
- replication copies existing objects
- replication is transitive
- Transfer Acceleration moves your data closer to users
- "use S3 Select" on a new account

**Failure modes**
- "replication is on, so we're backed up"  ↳ [[09-s3-advanced#Worked examples|open]]
- the invisible multipart bill  ↳ [[09-s3-advanced#Worked examples|open]]

**Comparisons**
- [[09-s3-advanced#CRR vs SRR|CRR vs SRR]]
- [[09-s3-advanced#Multipart vs byte-range|Multipart vs byte-range]]


## [[09-s3-security|09.3 – S3 Security (access, encryption, immutability)]]

- Three unrelated questions — who may read it, who holds the key, can it be deleted at all — with three unrelated mechanisms, plus one guardrail over the first.  
  ↳ [[09-s3-security#What problem does this solve?|explain]]
- IAM policy asks what a principal may do, bucket policy asks who may touch the bucket, cross-account needs both, and an explicit Deny beats everything.  
  ↳ [[09-s3-security#Two policies pointing at each other|explain]]
- Two ways to become public × two timings = four switches, and BPA overrides policy rather than the other way round.  
  ↳ [[09-s3-security#Block Public Access, and why there are exactly four switches|explain]]
- Everything is encrypted anyway, so the choice is whose key and whether CloudTrail sees it — and changing the default only affects new objects.  
  ↳ [[09-s3-security#Encryption is a question about custody, not about whether|explain]]
- Time-limited, carries the generator's permissions, and works for anyone holding the link — so keep the window short.  
  ↳ [[09-s3-security#A presigned URL is a bearer token wearing your permissions|explain]]
- The lock protects a version, so a permanent delete gets 403 while a simple delete happily adds a delete marker over the top.  
  ↳ [[09-s3-security#Object Lock, and the delete that succeeds anyway|explain]]

**Traps** [[09-s3-security#The Terraform I wrote|open]]
- Block Public Access can be overridden by a bucket policy
- enabling default encryption encrypts what's already there
- a presigned URL uses the recipient's permissions
- Object Lock stops the object being deleted
- MFA Delete can be set up like any other bucket setting

**Failure modes**
- "the bucket policy grants access, so cross-account works"  ↳ [[09-s3-security#Worked examples|open]]
- Object Lock in COMPLIANCE mode on a test bucket  ↳ [[09-s3-security#Worked examples|open]]

**Comparisons**
- [[09-s3-security#IAM policy vs bucket policy vs ACL|IAM policy vs bucket policy vs ACL]]
- [[09-s3-security#GOVERNANCE vs COMPLIANCE|GOVERNANCE vs COMPLIANCE]]


## [[10-route53|10 – Route 53 (DNS)]]

- DNS is a search for who to ask; Route 53 is the server being asked, and the routing policy decides which answer comes back.  
  ↳ [[10-route53#What problem does this solve?|explain]]
- A hosted zone makes you able to answer; delegation is the only thing that makes anyone ask you.  
  ↳ [[10-route53#Owning a name and answering for it are two different things|explain]]
- A CNAME at the apex is illegal DNS, and an alias is Route 53 dressing a redirect up as an A record so the apex can point at an ALB anyway.  
  ↳ [[10-route53#Why a CNAME cannot sit at the apex|explain]]
- Simple hands out everything blind, multivalue hands out only what's alive; geolocation reads the user, geoproximity reads your resources.  
  ↳ [[10-route53#The two policy pairs everyone swaps|explain]]
- Route 53 notices the failure in (interval × threshold) seconds; the TTL decides when anybody else does.  
  ↳ [[10-route53#What a health check can see, and how fast failover really is|explain]]
- A private zone answers only inside its associated VPCs; inbound lets on-prem ask AWS, outbound lets AWS ask on-prem.  
  ↳ [[10-route53#Private zones, and which way the Resolver points|explain]]

**Traps** [[10-route53#Traps|open]]
- "use simple routing to distribute traffic across three servers"
- CNAME at the apex
- geolocation vs geoproximity
- "we set up failover but users were down for an hour"
- health check on a private IP
- inbound vs outbound Resolver endpoints
- "HTTPS health checks prove the certificate is valid"

**Failure modes**
- the geolocation record with no default  ↳ [[10-route53#Worked examples|open]]

**Comparisons**
- [[10-route53#The eight routing policies|The eight routing policies]]
- [[10-route53#Alias vs CNAME|Alias vs CNAME]]
- [[10-route53#Public vs private hosted zone|Public vs private hosted zone]]
- [[10-route53#Route 53 Resolver — get the direction right|Route 53 Resolver — get the direction right]]


## [[11-cloudfront|11 – CloudFront (CDN)]]

- A copy of your content near the user, and AWS's own network for everything that can't be copied.  
  ↳ [[11-cloudfront#What problem does this solve?|explain]]
- Edge first, regional edge cache second, origin last — a miss at the edge doesn't mean a trip home.  
  ↳ [[11-cloudfront#Two caches sit between the viewer and your origin|explain]]
- The service principal names the service, never the customer — the SourceArn condition is the part that names you.  
  ↳ [[11-cloudfront#Why the S3 bucket policy needs a condition to actually be safe|explain]]
- Change the name, not the cache — invalidation can't reach caches you don't own.  
  ↳ [[11-cloudfront#Why AWS tells you not to invalidate|explain]]
- The certificate viewers see lives in us-east-1 whatever the origin does; the origin-facing one is the exception.  
  ↳ [[11-cloudfront#Why the certificate has to be in one specific Region|explain]]
- CloudFront caches, Global Accelerator doesn't — its trick is IPs that never change, so DNS never has to catch up.  
  ↳ [[11-cloudfront#Why Global Accelerator fails over faster than DNS can|explain]]

**Traps** [[11-cloudfront#Traps|open]]
- "put CloudFront in front of the S3 website endpoint and use OAC"
- the ACM certificate in the wrong Region
- CloudFront vs Global Accelerator
- "invalidate on every deploy"
- CloudFront Functions asked to do too much
- geo restriction vs geolocation routing

**Failure modes**
- the bucket policy that trusts every CloudFront distribution on earth  ↳ [[11-cloudfront#Worked examples|open]]

**Comparisons**
- [[11-cloudfront#CloudFront vs S3 Transfer Acceleration vs Global Accelerator|CloudFront vs S3 Transfer Acceleration vs Global Accelerator]]
- [[11-cloudfront#CloudFront Functions vs Lambda@Edge|CloudFront Functions vs Lambda@Edge]]
- [[11-cloudfront#Signed URLs vs signed cookies (private content)|Signed URLs vs signed cookies (private content)]]


## [[12-storage-extras|12 – Storage extras (EFS, FSx, Storage Gateway, DataSync, Snow, Backup)]]

- EBS is one disk for one server, S3 is an API, and everything in this note exists because real workloads need a shared file system or a bridge to a building.  
  ↳ [[12-storage-extras#What problem does this solve?|explain]]
- Block is one disk for one server, file is one file system many servers mount, object is an API — and the question's verbs tell you which.  
  ↳ [[12-storage-extras#Block, file, object — the distinction the exam is really testing|explain]]
- EFS is an elastic NFS file system many Linux machines mount at once — and it does not work with Windows.  
  ↳ [[12-storage-extras#EFS: the file system with no size|explain]]
- FSx is AWS running a named file system for you — Windows/SMB/Active Directory for lift-and-shift, Lustre for speed and S3-backed compute.  
  ↳ [[12-storage-extras#FSx: when the workload demands a *specific* file system|explain]]
- Storage Gateway is an on-prem appliance that looks like NFS, SMB, iSCSI or a tape library locally while storing in AWS — and for Volume Gateway, cached keeps the primary in S3 while stored keeps it on site.  
  ↳ [[12-storage-extras#Storage Gateway: making cloud storage look local|explain]]
- DataSync goes over the wire and can repeat on a schedule; Snow goes in a truck because the wire would take too long.  
  ↳ [[12-storage-extras#Moving bulk data in: over the wire, or in a truck|explain]]
- AWS Backup is a policy engine over every service's own backups, with tag-based assignment, cross-Region and cross-account copies, and a vault lock that makes them WORM.  
  ↳ [[12-storage-extras#AWS Backup: one place instead of six|explain]]

**Traps** [[12-storage-extras#Traps|open]]
- EFS for a Windows workload
- cached vs stored Volume Gateway, reversed
- DataSync vs Storage Gateway
- Snow when the network would do
- Lustre scratch vs persistent read as a speed choice
- "EFS One Zone is fine, it's still durable"

**Failure modes**
- Lustre scratch for data that mattered  ↳ [[12-storage-extras#Worked examples|open]]

**Comparisons**
- [[12-storage-extras#EFS vs FSx vs EBS vs S3|EFS vs FSx vs EBS vs S3]]
- [[12-storage-extras#Volume Gateway: cached vs stored|Volume Gateway: cached vs stored]]
- [[12-storage-extras#Getting data in: DataSync vs Snow vs Storage Gateway|Getting data in: DataSync vs Snow vs Storage Gateway]]


## [[13-cost-optimization|13 – Cost optimization]]

- You pay the most for committing to nothing, and the exam's cost questions are asking which commitment the scenario can afford to make.  
  ↳ [[13-cost-optimization#What problem does this solve?|explain]]
- On-Demand commits to nothing, Savings Plans commit to spend, Reserved Instances commit to a configuration, Spot commits to nothing but accepts eviction — and only Capacity Reservations and zonal RIs actually hold capacity for you.  
  ↳ [[13-cost-optimization#The ways to pay for a server|explain]]
- Reserved Instances commit to a configuration, Savings Plans commit to a spend — and in both, giving up flexibility buys a bigger discount, which is the opposite of what most people guess.  
  ↳ [[13-cost-optimization#Savings Plans vs Reserved Instances — and why *more* flexible costs *more*|explain]]
- Spot is spare capacity at a steep discount, and the two-minute notice via EventBridge or instance metadata is what makes fault-tolerant workloads able to use it.  
  ↳ [[13-cost-optimization#Spot, and the two minutes that make it usable|explain]]
- A large share of real savings is architectural, not contractual — endpoints instead of NAT, lifecycle instead of Standard, gp3 instead of oversized gp2, and one bill instead of ten.  
  ↳ [[13-cost-optimization#The bill that isn't compute|explain]]
- Cost Explorer analyses, Budgets alert, Anomaly Detection watches, tags slice, and Compute Optimizer says the instance is too big.  
  ↳ [[13-cost-optimization#The tools that tell you where the money went|explain]]

**Traps** [[13-cost-optimization#Traps|open]]
- "buy a Savings Plan to guarantee capacity"
- assuming the most flexible option is the cheapest
- Standard vs Convertible RI, exchange vs modify
- Dedicated Host vs Dedicated Instance
- Spot hibernation and the two minutes
- Cost Explorer vs Budgets vs Compute Optimizer

**Failure modes**
- Spot for the wrong tier  ↳ [[13-cost-optimization#Worked examples|open]]

**Comparisons**
- [[13-cost-optimization#Savings Plans vs Reserved Instances|Savings Plans vs Reserved Instances]]
- [[13-cost-optimization#When each purchasing option is the answer|When each purchasing option is the answer]]
- [[13-cost-optimization#The cost tools|The cost tools]]


## [[14-dr-resilience|14 – Disaster recovery & resilience]]

- HA survives losing a component, DR survives losing a Region — and the exam's DR questions are asking you to assemble services you already know.  
  ↳ [[14-dr-resilience#What problem does this solve?|explain]]
- RPO is how much data you can lose, RTO is how long you can be down, and the two together pick the strategy.  
  ↳ [[14-dr-resilience#Two numbers decide everything: RTO and RPO|explain]]
- The four strategies differ only in how much is already running in the recovery Region, and cost and recovery speed rise together.  
  ↳ [[14-dr-resilience#The four strategies, and what's actually running|explain]]
- Pilot light needs switching on before it can serve anything; warm standby is already serving, just small.  
  ↳ [[14-dr-resilience#Pilot light vs warm standby — the distinction that gets tested|explain]]
- Prefer data-plane operations for failover, because control planes are likelier to be degraded exactly when you need them.  
  ↳ [[14-dr-resilience#Data plane vs control plane — why some failovers are more reliable|explain]]
- Your RPO target picks the replication mechanism, and Aurora Global Database is the strongest answer whenever the question pairs cross-Region with a tight recovery window.  
  ↳ [[14-dr-resilience#Which service buys you which RPO|explain]]

**Traps** [[14-dr-resilience#Traps|open]]
- pilot light vs warm standby
- treating replication as backup
- RTO and RPO swapped
- automatic failover assumed to be the better answer
- an RDS read replica used where Aurora Global Database belongs
- a DR design that depends on the control plane

**Failure modes**
- replication that faithfully copied the disaster  ↳ [[14-dr-resilience#Worked examples|open]]

**Comparisons**
- [[14-dr-resilience#The four strategies side by side|The four strategies side by side]]
- [[14-dr-resilience#HA vs DR|HA vs DR]]
- [[14-dr-resilience#Picking a cross-Region database|Picking a cross-Region database]]


## [[15-decoupling|15 – Decoupling (SQS, SNS, Amazon MQ)]]

- A queue means the two services no longer have to be healthy at the same moment, or fast at the same rate.  
  ↳ [[15-decoupling#What problem does this solve?|explain]]
- The producer writes and forgets, the queue holds for up to 14 days, and consumers can come and go without the producer knowing.  
  ↳ [[15-decoupling#The queue is a shock absorber, not a pipe|explain]]
- A received message is hidden, not deleted, and it comes back if you never delete it — which is why consumers must be idempotent.  
  ↳ [[15-decoupling#Receiving is not deleting — and that's deliberate|explain]]
- Without a DLQ a poison message loops until retention expires; with one it steps aside after maxReceiveCount — and the DLQ needs longer retention because a standard-queue message arrives carrying its original age.  
  ↳ [[15-decoupling#What stops the loop: the dead-letter queue|explain]]
- SNS pushes one message to every subscriber, SQS holds one message for one consumer, and fan-out puts a queue in front of each service so one being down doesn't lose anything.  
  ↳ [[15-decoupling#SNS is push, SQS is pull — and the pattern that uses both|explain]]
- FIFO buys strict ordering and exactly-once with two to three orders of magnitude less throughput, and message groups are how you buy some of it back.  
  ↳ [[15-decoupling#Standard vs FIFO — what strict ordering costs|explain]]
- Amazon MQ exists so a legacy app speaking a standard broker protocol can move to AWS without a rewrite — and that migration framing is the only reason to pick it.  
  ↳ [[15-decoupling#When neither fits: Amazon MQ|explain]]

**Traps** [[15-decoupling#Traps|open]]
- "receiving a message removes it"
- a queue with no dead-letter queue
- DLQ retention set equal to the source queue's
- assuming an empty poll means an empty queue
- SNS delivering straight to a service instead of into a queue
- FIFO chosen without noticing the throughput ceiling
- Amazon MQ picked for a new application

**Failure modes**
- the poison message, observed both ways  ↳ [[15-decoupling#Worked examples|open]]

**Comparisons**
- [[15-decoupling#SQS vs SNS|SQS vs SNS]]
- [[15-decoupling#Standard vs FIFO queues|Standard vs FIFO queues]]
- [[15-decoupling#SQS vs SNS vs Amazon MQ|SQS vs SNS vs Amazon MQ]]


## [[16-kinesis|16 – Kinesis (Data Streams & Data Firehose)]]

- SQS deletes a message when it's done; Kinesis keeps every record for its retention period so any number of consumers can read, and re-read, the same data.  
  ↳ [[16-kinesis#What problem does this solve?|explain]]
- A shard is one partition and one fixed slice of throughput — 1 MB/sec or 1,000 records/sec in, 2 MB/sec out shared between all consumers.  
  ↳ [[16-kinesis#Shards — capacity and partitioning in one thing|explain]]
- The partition key hashes to a shard, order is guaranteed only inside a shard, and picking a high-cardinality key is what buys you ordering and parallelism together.  
  ↳ [[16-kinesis#The partition key decides both placement and ordering|explain]]
- Data Streams stores and you build the consumer; Firehose delivers to a destination and you build nothing — and Firehose can read from a stream, so it's usually both.  
  ↳ [[16-kinesis#Data Streams vs Firehose — a store versus a pipe|explain]]
- Shared fan-out splits one shard's 2 MB/sec between all consumers; enhanced fan-out gives each registered consumer its own 2 MB/sec, pushed rather than polled.  
  ↳ [[16-kinesis#Reading: shared fan-out versus enhanced fan-out|explain]]

**Traps** [[16-kinesis#Traps|open]]
- SQS chosen where replay or multiple consumers are needed
- assuming ordering across the whole stream
- a low-cardinality partition key
- Firehose expected to store or replay
- Firehose treated as real-time
- forgetting that read throughput is shared

**Failure modes**
- the hot shard  ↳ [[16-kinesis#Worked examples|open]]

**Comparisons**
- [[16-kinesis#SQS vs SNS vs Kinesis|SQS vs SNS vs Kinesis]]
- [[16-kinesis#Data Streams vs Firehose|Data Streams vs Firehose]]


## [[17-containers|17 – Containers on AWS (ECS, Fargate, ECR, EKS)]]

- You never tell ECS to start a container — you declare how many should be running, and a loop closes the gap forever.  
  ↳ [[17-containers#What problem does this solve?|explain]]
- ECS decides what runs; the launch type decides who owns the servers it runs on — two different questions, not two alternatives.  
  ↳ [[17-containers#What problem does this solve?|explain]]
- A task definition is an AMI for containers — immutable and versioned, and pointing the service at a new revision is the deployment.  
  ↳ [[17-containers#How it actually works|explain]]
- Awsvpc gives every task its own ENI, so the load balancer registers IP addresses — there is no instance to register.  
  ↳ [[17-containers#How it actually works|explain]]

**Traps** [[17-containers#⚠️ Traps — why the wrong answer looks right|open]]
- "ECS or Fargate?"
- target_type on a Fargate service
- a green apply is not a green deployment
- the execution role is not for the pull
- rollback needs somewhere to roll back to
- endpoints are not automatically cheaper than NAT

**Failure modes**
- the private subnet that can't pull  ↳ [[17-containers#Worked examples|open]]

**Comparisons**
- [[17-containers#ECS vs EKS|ECS vs EKS]]
- [[17-containers#EC2 launch type vs Fargate|EC2 launch type vs Fargate]]
- [[17-containers#Task execution role vs task role|Task execution role vs task role]]
- [[17-containers#ALB target types|ALB target types]]
- [[17-containers#ECR vs Docker Hub|ECR vs Docker Hub]]
