---
topic: 14-dr-resilience
domain: resilient
related_note: 14-dr-resilience
tags: [flashcards/dr]
---

# Cards for [[14-dr-resilience]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

RTO vs RPO — which is which?
?
RTO (Recovery Time Objective) = how long you may be DOWN. RPO (Recovery Point Objective) = how much DATA you may lose. RPO looks backwards from the disaster (how far back is the last good copy?); RTO looks forwards (how long until we're serving again?). Both are set by the business. RPO is bought with replication; RTO is bought with pre-provisioned capacity.

High availability vs disaster recovery?
?
HA survives losing a COMPONENT — an instance, an Availability Zone. Tools: Multi-AZ, ASG across AZs, ALB. DR survives losing a REGION, or data corruption that replicated everywhere. Tools: cross-Region replication, Route 53 or Global Accelerator failover, backups. Different problem, different services.

Name the four DR strategies and what is running in the DR Region for each.
?
Backup & restore — nothing but backups. Pilot light — data replicating and core infrastructure deployed, but application servers SWITCHED OFF. Warm standby — a scaled-down but fully working copy that takes no traffic. Multi-site active/active — a full copy actively serving users. Cost and recovery speed rise together down that list.

What is the one-sentence test for pilot light vs warm standby?
?
Could it serve a request right now, with no action from you? No — something must be switched on first → pilot light. Yes, just at reduced capacity → warm standby. AWS's own words: pilot light "cannot process requests without additional action taken first"; warm standby "can handle traffic (at reduced capacity levels) immediately". Both replicate data; the difference is whether compute is RUNNING.

Why does backup & restore need infrastructure as code?
?
Because "backup" means more than data. To rebuild in another Region you need the infrastructure, configuration and application code too. AWS is explicit that without CloudFormation/CDK the rebuild is slow and error-prone and will likely blow your RTO. Back up your AMIs as well, and copy them to the recovery Region.

What is the data plane vs control plane distinction, and why does it matter for DR?
?
The data plane does the actual work (routing a packet, serving an object); the control plane changes configuration (creating resources, updating settings). Data planes are designed for HIGHER availability than control planes. So during a disaster prefer data-plane operations — the control plane may be exactly what's degraded when you need it.

Which failover mechanisms are data plane and which are control plane?
?
DATA PLANE: Route 53 health checks driving failover, and Amazon Application Recovery Controller (health checks used as manual on/off switches). CONTROL PLANE: changing Route 53 weights, Global Accelerator traffic dials, and Auto Scaling. A "most resilient failover" question is usually asking you to spot this.

What is static stability, and what does it turn warm standby into?
?
Provisioning enough capacity in the DR Region up front so recovery does NOT depend on Auto Scaling — which is a control-plane operation and therefore a dependency at the worst possible moment. Full capacity deployed but only one Region taking traffic is called HOT STANDBY (an active/passive variant of multi-site).

Is automatic failover always the better answer?
?
No, and AWS explicitly advises caution. Recovery time and recovery point are always greater than zero, so a FALSE ALARM makes you incur real downtime and real data loss for nothing. A fully scripted but MANUALLY triggered failover — "automated, push-button" — is a legitimate and common design.

Why is replication not a backup?
?
Because it copies faithfully — including a bad deployment, a corruption bug, or a malicious deletion. Replication protects against LOSING data, not against data becoming WRONG. Any scenario mentioning corruption, ransomware, accidental deletion or a bad release needs point-in-time recovery, versioning, or immutable backups — not more replication.

Which cross-Region replication mechanism gives which RPO?
?
Aurora Global Database ~1 second (promote a secondary in under a minute, up to 5 secondary Regions). DynamoDB Global Tables seconds and multi-active. S3 Cross-Region Replication seconds to minutes (S3 RTC gives a predictable window). RDS cross-Region read replica seconds to minutes, but promotion takes minutes plus a reboot. ElastiCache Global Datastore seconds. AWS Backup cross-Region copy: hours.

Aurora Global Database vs an RDS cross-Region read replica for DR?
?
Aurora Global Database replicates in under a second and promotes a secondary to read/write in under a minute, even during a full regional outage, across up to 5 secondary Regions. An RDS read replica promotion takes A FEW MINUTES AND INVOLVES A REBOOT. When a question pairs "cross-Region" with an aggressive RTO or RPO, the read replica is the distractor.

What makes DynamoDB Global Tables different from the other replication options?
?
It is MULTI-ACTIVE — you can read AND write in every Region without promoting anything, so there is no failover step for the database at all. Concurrent updates to the same item are reconciled with LAST WRITER WINS, which is the trade-off you accept for write-anywhere.

Does S3 Cross-Region Replication replicate delete markers?
?
Not by default — and that is deliberate. A deletion (accidental or malicious) in the source Region does not destroy the DR copy. Combined with versioning, that's what makes S3 replication useful against human error rather than just infrastructure loss.

Name the three multi-site write strategies.
?
Write global — all writes go to one Region, another is promoted on failure (Aurora Global Database, which also supports write forwarding from secondaries). Write local — write to the nearest Region (DynamoDB Global Tables, last-writer-wins). Write partitioned — writes routed by a partition key such as user ID to avoid conflicts (bidirectional S3 replication, currently two Regions).

How does CloudFront origin failover differ from Route 53 or Global Accelerator failover?
?
CloudFront switches PER REQUEST — if a request to the primary origin fails it retries the secondary, but subsequent requests still try the primary first. Route 53 and Global Accelerator failover move the whole workload to the other endpoint until health recovers.

What is AWS Elastic Disaster Recovery (DRS)?
?
Continuous block-level replication of whole servers from on-premises, another cloud, or EC2 into AWS. It implements a PILOT LIGHT strategy — data plus switched-off resources staged in a VPC, converted into a full-capacity deployment when failover is triggered. It does not cover RDS.

Your workload is highly available across AZs and the disaster you're guarding against is losing one data centre. Which strategy?
?
Backup & restore may be enough. AWS states that for a disaster limited to the disruption or loss of one physical data centre, a well-architected highly available workload may only require backup and restore. Pilot light, warm standby and multi-site are for REGION-level disasters or regulatory requirements.
