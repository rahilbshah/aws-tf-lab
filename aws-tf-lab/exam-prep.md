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

- **Breadth:** Stephane Maarek Udemy course (owned) — full blueprint coverage.
- **Depth (career-grade):** Adrian Cantrill SAA-C03 (planned purchase) — the "understand, not just pass" layer for Backend+DevOps.
- **Readiness (must-buy):** Tutorials Dojo (Jon Bonso) practice exams (~$15, planned) — runs harder than the real exam.
- **Reference:** AWS FAQs (S3/EC2/VPC/RDS) + Well-Architected whitepaper (free).
- **Retention / real skill:** this vault + the Terraform builds (the hands-on layer).

> [!tip] Readiness gate
> Don't book the exam until you're consistently scoring **~80%+ on fresh Tutorials Dojo sets** (a TD ~75% ≈ real-exam pass). Buy TD + Cantrill after we finish the build sections, per the plan.

## Coverage tracker

Legend: ✅ built + noted in this vault · 🔨 in progress · ☐ not started

### Compute
- [x] ✅ EC2 (instances, AMIs, storage, purchasing) — [[02-ec2]]
- [x] ✅ Golden AMIs / Packer (job skill) — [[03-ami-bake]]
- [x] ✅ ELB (ALB/NLB) + Auto Scaling — [[04-alb-asg]]
- [ ] ☐ Lambda (serverless, triggers, limits)
- [ ] ☐ Containers — ECS / EKS / Fargate
- [ ] ☐ Elastic Beanstalk

### Storage
- [x] ✅ EBS + Instance Store (covered under EC2) — [[02-ec2]]
- [ ] ☐ **S3** (storage classes, lifecycle, versioning, encryption, replication, static hosting, presigned URLs, bucket policies, Object Lock) — *big; high exam weight*
- [ ] ☐ EFS (shared NFS)
- [ ] ☐ FSx (Windows / Lustre / NetApp / OpenZFS)
- [ ] ☐ Storage Gateway (File / Volume / Tape)
- [ ] ☐ AWS Backup
- [ ] ☐ Snow Family (migration)

### Database
- [x] ✅ RDS (Multi-AZ vs read replicas, backups/PITR, encryption) — [[07-rds-aurora]]
- [x] ✅ Aurora (6-copy storage, endpoints, Serverless v2, Global DB) — [[07-rds-aurora]]
- [ ] ☐ DynamoDB (DAX, global tables, streams)
- [x] ✅ ElastiCache (Redis vs Memcached, caching strategies) — [[08-elasticache]]
- [ ] ☐ Redshift

### Networking & Content Delivery
- [x] ✅ VPC core (subnets, routing, IGW/NAT) — [[05-vpc-core]]
- [x] ✅ VPC security (SG/NACL, Flow Logs, Network Firewall) — [[05-vpc-security]]
- [x] ✅ VPC endpoints + peering (+ Transit Gateway, conceptual) — [[05-vpc-endpoints-peering]]
- [x] ✅ VPC hybrid (VPN, Direct Connect, VGW/CGW, DX Gateway) — [[05-vpc-hybrid]] *(conceptual)*
- [ ] ☐ Route 53 (routing policies, health checks) — *high exam weight*
- [ ] ☐ CloudFront (CDN, OAI/OAC, caching)
- [ ] ☐ API Gateway
- [ ] ☐ Global Accelerator

### Application Integration / Messaging
- [ ] ☐ SQS (standard / FIFO, visibility timeout, DLQ) — *high exam weight*
- [ ] ☐ SNS (fan-out)
- [ ] ☐ EventBridge
- [ ] ☐ Step Functions
- [ ] ☐ Kinesis (Data Streams / Firehose)

### Security, Identity & Compliance
- [x] ✅ IAM (users/groups/roles/policies, evaluation) — [[01-iam]]
- [ ] ☐ KMS (encryption keys, envelope encryption)
- [ ] ☐ Secrets Manager vs SSM Parameter Store
- [ ] ☐ Cognito (user pools / identity pools)
- [ ] ☐ WAF / Shield
- [ ] ☐ GuardDuty / Inspector / Macie / Security Hub
- [ ] ☐ ACM (certificates)

### Management & Governance
- [ ] 🔨 CloudWatch (metrics/alarms/logs — partly seen in ASG + Flow Logs)
- [ ] ☐ CloudTrail (API audit)
- [ ] ☐ AWS Config
- [ ] ☐ Organizations / SCPs / Control Tower — *C03 emphasizes multi-account*
- [ ] ☐ Systems Manager (SSM — Session Manager, Parameter Store, Patch)

### Analytics
- [ ] ☐ Athena (+ S3 query)
- [ ] ☐ Glue
- [ ] ☐ EMR
- [ ] ☐ QuickSight / OpenSearch

### Migration & Transfer
- [ ] ☐ DMS (Database Migration Service)
- [ ] ☐ DataSync
- [ ] ☐ Snow Family (also under Storage)

### Cost Optimization
- [x] ✅ EC2 purchasing (On-Demand/Reserved/Spot/Savings) — [[02-ec2]]
- [ ] ☐ Cost Explorer / Budgets / Cost Allocation Tags
- [ ] ☐ Compute Optimizer / Trusted Advisor

### Cross-cutting (whitepaper-level)
- [ ] ☐ Disaster Recovery strategies (backup-restore → pilot light → warm standby → multi-site) + RTO/RPO
- [ ] ☐ Well-Architected Framework (the 6 pillars)
- [ ] ☐ Decoupling & serverless reference architectures

## Progress snapshot

- **Done:** IAM, EC2 (+storage/purchasing), ELB+ASG, Packer, the full VPC topic (core/security/endpoints/hybrid), the modular 3-tier capstone, RDS, Aurora, ElastiCache. ~**13 topic areas**.
- **Honest estimate:** roughly **40%** of the exam surface, with the whole networking + compute + relational-data + caching foundation solid. Heaviest un-started high-yield gaps: **S3, DynamoDB, Route 53, CloudFront, SQS/SNS, Lambda, KMS**.
- **Weakest domain vs weighting:** the exam is 30% *Secure* — IAM + VPC security are strong, but **KMS / Secrets Manager / Cognito / WAF** are still open and should be prioritized.

_Update the checkboxes as we complete each section. When most boxes are ticked and TD sits ~80%, book the exam._
