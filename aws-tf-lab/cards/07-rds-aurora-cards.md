---
topic: 07-rds-aurora
domain: resilient
related_note: 07-rds-aurora
tags: [flashcards/database]
---

# Cards for [[07-rds-aurora]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

Which database engines does Amazon RDS support?
?
MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, and Amazon Aurora (MySQL- and PostgreSQL-compatible).

RDS Multi-AZ vs Read Replica — purpose and readability?
?
Multi-AZ: a SYNCHRONOUS standby in another AZ for HIGH AVAILABILITY / automatic failover — NOT readable. Read Replica: ASYNCHRONOUS copies you CAN read from, for READ SCALING (up to 5, can be cross-region, manually promotable). Multi-AZ = survive AZ failure; Read Replica = offload reads. You can use both together.

How does RDS point-in-time recovery work, and what does restore produce?
?
RDS takes a daily snapshot plus streams transaction logs to S3 every ~5 minutes. That lets you restore to ANY second within the retention window (1–35 days), not just backup time. A restore always creates a BRAND-NEW instance with a new endpoint — it never overwrites in place.

Automated backups vs manual snapshots in RDS?
?
Automated backups: enabled via retention (1–35 days), give point-in-time recovery, and are DELETED when the instance is deleted (unless you take a final snapshot). Manual snapshots: user-triggered, kept until you delete them, and SURVIVE instance deletion.

When can you enable RDS/Aurora encryption at rest, and how do you encrypt an existing unencrypted DB?
?
Only at creation (storage_encrypted = true, KMS). You cannot encrypt an existing unencrypted DB in place — snapshot it, COPY the snapshot with encryption enabled, then restore from the encrypted copy.

How does Aurora store data (copies, AZs, scaling)?
?
6 copies across 3 Availability Zones (2 per AZ), on a shared, self-healing cluster volume that auto-scales from 10 GB to 128 TB. Compute and storage are separated and scale independently.

How do Aurora Replicas differ from RDS Read Replicas?
?
Aurora Replicas connect to the SAME shared cluster volume (no data copy) → typically <10 ms lag, up to 15 of them, with automatic fast failover. RDS Read Replicas each hold their own asynchronously-copied data (can lag seconds), up to 5, and are manually promoted.

What are the four Aurora cluster endpoint types?
?
Cluster/Writer endpoint (always the primary — for writes), Reader endpoint (load-balances across all read replicas — for reads), Custom endpoint (a subset of instances you define), Instance endpoint (one specific instance).

Why choose Aurora over RDS MySQL/PostgreSQL?
?
~5x MySQL / 3x Postgres throughput, up to 15 low-lag replicas (vs 5), faster failover, 6-copy/3-AZ durability, storage auto-scaling to 128 TB, plus Serverless v2 and Global Database options. Trade-off: higher per-hour cost, and it's MySQL/Postgres-compatible only.

What is Aurora Serverless v2 for?
?
Automatic, fine-grained scaling of a cluster's compute capacity (ACUs) up and down in-place to match load, with pay-for-use billing. Best for variable, unpredictable, intermittent, or spiky workloads (dev/test, infrequently used apps) where a fixed provisioned instance would waste money.

What is an Aurora Global Database?
?
One primary region plus up to 5 read-only secondary regions with typically <1 second cross-region replication. Used for low-latency global reads and cross-region disaster recovery (a secondary can be promoted in under a minute).

What is RDS Proxy and when is it useful?
?
A managed connection pooler in front of RDS/Aurora. It pools and reuses DB connections, which is important for serverless/Lambda apps that can open huge numbers of short-lived connections and exhaust the DB — RDS Proxy also speeds failover and can enforce IAM auth.
