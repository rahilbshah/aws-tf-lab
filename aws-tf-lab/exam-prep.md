---
status: living
tags: [exam-prep, moc]
---

# 🎯 SAA-C03 Exam Prep — blueprint & readiness tracker

The single dashboard for "how ready am I?" Covered topics link to their vault notes; the rest are the gap. **Verified against the official AWS exam guide — the current exam is SAA-C03** (not C04, despite some blogs; checked AWS directly 2026-07).

> [!info] Exam facts
> - **Code:** SAA-C03 · **Length:** 130 min · **Questions:** 65 (multiple choice / multiple response) · **Cost:** $150 · **Pass:** 720/1000
> - **Domains (weighting):** Secure **30%** · Resilient **26%** · High-Performing **24%** · Cost-Optimized **20%** → *security is the single biggest domain; weight your study accordingly.*

## Resource stack (the plan)

- **Breadth:** Stephane Maarek Udemy course (owned) — **complete**, all 25 sections noted in this vault.
- **Depth (career-grade):** Adrian Cantrill SAA-C03 (optional now) — the "understand, not just pass" layer for Backend+DevOps.
- **Readiness:** `../aws-saa-trainer` — **1,156 serveable questions** (1,168 in the bank, less 7 quarantined and 5 near-duplicates) from three third-party practice sets (Tutorials Dojo / Jon Bonso included), audited against AWS docs. This replaced the planned TD purchase.
- **Reference:** this vault, in three tiers — **notes** (`NN-topic.md`, how it works) → **decision pages** (`decisions/`, 13 pages routing you to which service) → **[[cheatsheet]]** (677 exact facts). Plus [[discriminators]], [[exam-night]], AWS FAQs (S3/EC2/VPC/RDS) and the Well-Architected whitepaper. *`revision/` was deleted 2026-09-27 — it was the note with the explanation removed, i.e. summarization + rereading, both rated low-utility.*
- **Retention / real skill:** this vault + the Terraform builds (the hands-on layer).

> [!tip] Readiness gate
> The live gate is the trainer's `CLAUDE.md` §12, scored from `state/mastery.json`: **≥80% on 3 consecutive full timed mocks**, **no domain below 70%** on those mocks, `mistakes.md` substantially cleared, confidence calibrated (no cluster of confident-wrong), and a final capstone mock in one sitting. Note the real exam is *compensatory* — AWS says "you do not need to achieve a passing score in each section" — so this gate is deliberately stricter than the exam.

## Coverage tracker

Legend: ✅ built + noted in this vault · 🔨 in progress · ☐ not started

### Compute
- [x] ✅ EC2 (instances, AMIs, storage, purchasing) — [[02-ec2]]
- [x] ✅ Golden AMIs / Packer (job skill) — [[03-ami-bake]]
- [x] ✅ ELB (ALB/NLB) + Auto Scaling — [[04-alb-asg]]
- [x] ✅ Lambda (invocation models, reserved vs provisioned concurrency, limits) — [[19-serverless]]
- [x] ✅ Containers — ECS / EKS / Fargate / ECR — [[17-containers]] + [[18-containers-capstone]]
- [x] ✅ Elastic Beanstalk — [[24-other-services]]

### Storage
- [x] ✅ EBS + Instance Store (covered under EC2) — [[02-ec2]]
- [x] ✅ **S3 intro** (buckets/keys, durability, storage classes, versioning, lifecycle, static hosting) — [[09-s3-intro]]
- [x] ✅ S3 advanced (replication + Batch, multipart, Transfer Acceleration, S3 Select, events, Glacier tiers) — [[09-s3-advanced]]
- [x] ✅ S3 security (bucket policies vs IAM vs ACLs, Block Public Access, encryption, presigned URLs, Object Lock, MFA delete) — [[09-s3-security]]
- [x] ✅ EFS (shared NFS) — [[12-storage-extras]]
- [x] ✅ FSx (Windows / Lustre / NetApp / OpenZFS) — [[12-storage-extras]]
- [x] ✅ Storage Gateway (File / Volume / Tape) — [[12-storage-extras]]
- [x] ✅ AWS Backup — [[12-storage-extras]]
- [x] ✅ Snow Family (migration) + DataSync — [[12-storage-extras]] *(note: Snowball Edge closed to new customers)*

### Database
- [x] ✅ RDS (Multi-AZ vs read replicas, backups/PITR, encryption) — [[07-rds-aurora]]
- [x] ✅ Aurora (6-copy storage, endpoints, Serverless v2, Global DB) — [[07-rds-aurora]]
- [x] ✅ DynamoDB (DAX, GSI vs LSI, streams, on-demand vs provisioned) — [[19-serverless]]
- [x] ✅ ElastiCache (Redis vs Memcached, caching strategies) — [[08-elasticache]]
- [x] ✅ Redshift (warehouse vs Athena, when you actually need one) — [[22-analytics]]

### Networking & Content Delivery
- [x] ✅ VPC core (subnets, routing, IGW/NAT) — [[05-vpc-core]]
- [x] ✅ VPC security (SG/NACL, Flow Logs, Network Firewall) — [[05-vpc-security]]
- [x] ✅ VPC endpoints + peering (+ Transit Gateway, conceptual) — [[05-vpc-endpoints-peering]]
- [x] ✅ VPC hybrid (VPN, Direct Connect, VGW/CGW, DX Gateway) — [[05-vpc-hybrid]] *(conceptual)*
- [x] ✅ Route 53 (routing policies, health checks, alias vs CNAME, private zones, Resolver) — [[10-route53]]
- [x] ✅ CloudFront (CDN, OAC, caching, edge functions, Global Accelerator comparison) — [[11-cloudfront]] *(note written 2026-09-04; lab written but not yet applied)*
- [x] ✅ API Gateway (REST vs HTTP API, API Gateway vs ALB as a front door) — [[19-serverless]]
- [x] ✅ Global Accelerator (anycast, why it fails over faster than DNS) — [[11-cloudfront]]

### Application Integration / Messaging
- [x] ✅ SQS (standard / FIFO, visibility timeout, DLQ) — [[15-decoupling]]
- [x] ✅ SNS (fan-out) — [[15-decoupling]]
- [x] ✅ EventBridge (the reaction layer; = CloudWatch Events renamed) — [[20-monitoring]]
- [x] ✅ Step Functions (Standard vs Express, orchestration vs choreography) — [[24-other-services]]
- [x] ✅ Amazon MQ (when a migration needs AMQP/MQTT, not SQS) — [[15-decoupling]]
- [x] ✅ Kinesis (Data Streams / Firehose) — [[16-kinesis]] *(conceptual-only: both services are blocked on this account's AWS Free plan)*

### Security, Identity & Compliance
- [x] ✅ IAM (users/groups/roles/policies, evaluation) — [[01-iam]]
- [x] ✅ **IAM advanced** (Organizations, SCPs, permissions boundaries, ABAC, condition keys, Control Tower) — [[01-iam-advanced]] *(conceptual-only — never build SCPs in a learning account)*
- [x] ✅ KMS (key types, envelope encryption, rotation, multi-Region, CloudHSM) — [[21-security]]
- [x] ✅ Secrets Manager vs SSM Parameter Store — [[21-security]]
- [x] ✅ Cognito (user pools vs identity pools) — [[21-security]] + [[19-serverless]]
- [x] ✅ WAF / Shield (Standard vs Advanced, WAF vs Shield, Firewall Manager) — [[21-security]]
- [x] ✅ GuardDuty / Inspector / Macie / Security Hub / Detective — [[21-security]]
- [x] ✅ ACM (certificates, Private CA) — [[11-cloudfront]] + [[21-security]]

### Management & Governance
- [x] ✅ CloudWatch (metrics/alarms/logs, event types, getting an alert out of a log line) — [[20-monitoring]]
- [x] ✅ CloudTrail (API audit, management vs data events) — [[20-monitoring]]
- [x] ✅ AWS Config (configuration drift; CloudTrail vs Config on the same change) — [[20-monitoring]]
- [x] ✅ Organizations / SCPs / Control Tower — [[01-iam-advanced]] *(was the biggest untracked gap; the Udemy IAM Advanced section had been skipped)*
- [ ] ☐ Systems Manager (Session Manager, Patch Manager, Run Command) — *wrongly ticked on 2026-09-27 and corrected the same day. `20-monitoring` does not mention SSM at all (`services: [CloudWatch, CloudTrail, Config, EventBridge, XRay]`) and [[14-dr-resilience]] has only two passing mentions of SSM **Automation** inside a drift bullet. **Parameter Store is genuinely covered — in [[21-security]]**, not in either note originally cited. **10 questions in the bank, never served.** Session Manager is the high-yield one: reach a private instance with no bastion, no SSH key and no inbound rule.*
- [x] ✅ Well-Architected Tool / Trusted Advisor — [[25-well-architected]]

### Analytics
- [x] ✅ Athena (SQL on S3, pay per byte scanned) — [[22-analytics]]
- [x] ✅ Glue (+ Lake Formation) — [[22-analytics]]
- [x] ✅ EMR (when you genuinely need Hadoop/Spark) — [[22-analytics]]
- [x] ✅ QuickSight (SPICE) / OpenSearch — [[22-analytics]]

### Machine Learning (recognition-level — the exam only asks "which service")
- [x] ✅ The pre-trained AI services vs SageMaker, and the modality neighbours — [[23-machine-learning]]

### Migration & Transfer
- [x] ✅ DMS (+ SCT; homogeneous vs heterogeneous) — [[24-other-services]]
- [x] ✅ DataSync — [[12-storage-extras]]
- [x] ✅ Snow Family (also under Storage) — [[12-storage-extras]]
- [x] ✅ Transfer Family (managed SFTP) — [[24-other-services]]
- [x] ✅ Directory Service (Managed AD vs AD Connector vs Simple AD) — [[24-other-services]]

### Cost Optimization
- [x] ✅ **EC2 purchasing (On-Demand/Reserved/Spot/Savings Plans/Dedicated)** — [[13-cost-optimization]] — *was wrongly ticked as covered by [[02-ec2]]; audit on 2026-09-04 found no Spot/Reserved/Savings Plans content anywhere in the vault. Corrected.*
- [x] ✅ Database & network cost (gateway endpoints vs NAT, data transfer, unattached EIPs, orphaned snapshots) — [[13-cost-optimization]] *("The bill that isn't compute"). Still the thinnest area in the trainer's bank — 15 questions for cost-optimized database, 25 for network, vs 59–135 for every other task statement — so drilling cannot cover it. Cost sits at 58.3% in the trainer; re-read this one rather than expecting exams to teach it.*
- [x] ✅ Cost Explorer / Budgets / Cost Allocation Tags — [[13-cost-optimization]]
- [x] ✅ Compute Optimizer — [[13-cost-optimization]]

### Cross-cutting (whitepaper-level)
- [x] ✅ Disaster Recovery strategies (backup-restore → pilot light → warm standby → multi-site) + RTO/RPO — [[14-dr-resilience]]
- [x] ✅ Well-Architected Framework (the 6 pillars, WA Tool vs Trusted Advisor vs Config) — [[25-well-architected]]
- [x] ✅ Decoupling & serverless reference architectures — [[15-decoupling]] + [[19-serverless]]
- [x] ✅ AppSync (managed GraphQL) · AWS Batch — [[24-other-services]]

## Progress snapshot

_Reconciled against the vault and the trainer's `state/mastery.json` on 2026-09-27. The tracker had drifted six sections behind reality: sections 17–25 were all written but none were ticked, and the snapshot still listed S3, DynamoDB, Route 53, CloudFront, SQS/SNS, Lambda and KMS as un-started._

- **Reading coverage: all 25 sections have notes**, the last of them — monitoring, security, analytics, ML, other services, Well-Architected — written 25–26 Sept. **One topic gap remains: Systems Manager** (see Management & Governance above). Otherwise the syllabus is read.
- **Testing coverage: 23.3%.** 269 of 1,156 serveable questions answered, at **71.4%** overall.
- **The real gap is now tested-vs-untested, not read-vs-unread.** 15 topics have never been served a single question — **183 questions** — and the largest block is security and monitoring, i.e. D1.

**Never served a single question** *(recounted 2026-09-27; serveable pool only — excludes the 7 quarantined and 5 near-duplicate questions, which §3.1 forbids serving)*

| Topic | Pool | Topic | Pool |
|---|---:|---|---:|
| KMS | 25 | Config | 10 |
| CloudWatch | 23 | Glue | 10 |
| WAF/Shield | 22 | SSM | 10 |
| DMS | 15 | Athena | 10 |
| CloudTrail | 13 | Secrets Manager | 6 |
| GuardDuty/Inspector/Macie | 12 | Cognito | 5 |
| EventBridge | 12 | Redshift | 5 |
| | | EMR | 5 |

- **Domains (trainer):** D1 **70.7%** · D2 **69%** · D3 **74.6%** · D4 **71.7%**. Flat, and all four below the 80% bar.
- **Weakest topics, ranked by questions actually missed** (= answered × miss rate): **IAM 14 missed** (54.8% of 31) · Aurora 12 (53.8% of 26) · **AutoScaling 10** (66.7% of 30) · Route 53 6 (53.8% of 13) · Cost 5 (58.3% of 12) · Organizations/SCP · DataSync · Snow 4 each (50% of 8). Sample sizes matter — SG/NACL 50% is 4 questions and Kinesis 50% is **2**, which is noise, not a signal. **AutoScaling is the third-worst topic and was missing from this list until 2026-09-27**; it is also where 6 of the 22 multi-response misses sit. Perfect so far: EFS, FSx, Backup, DynamoDB, SQS, SNS.
- **Session trend:** 67.7 → 75.0 → 72.3 → 75.4. Four review exams, no upward trend — which is why the next step is timed mocks, not a fifth review paper.
- **Thin-bank warning:** Secrets Manager has 6 questions and only **2** survive concept-collision filtering — the six test essentially one idea. Cost-optimized database (15) and network (25) are similarly thin. These areas have to be *read*; drilling cannot cover them.

> [!warning] Readiness: not yet — 0 of 3
> `mocks: []`. The gate needs **three consecutive full timed mocks at ≥80% with no domain below 70%**, plus a capstone sitting. Zero have been taken. `sure_wrong` is at **43** with `unsure_right` at **1** — confidence is not yet calibrated, and "unsure" has not been pressed since session 2.

_Update the checkboxes as each section is completed. Booking decision belongs to the trainer's §12 gate, not to this checklist._
