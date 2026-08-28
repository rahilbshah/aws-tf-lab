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
Multi-AZ: a SYNCHRONOUS standby in another AZ for HIGH AVAILABILITY / automatic failover — NOT readable. Read Replica: ASYNCHRONOUS copies you CAN read from, for READ SCALING (⚠️ verify the max — long-standing figure is 5, AWS may have raised it to 15 for MySQL/PostgreSQL; can be cross-region, manually promotable). Multi-AZ = survive AZ failure; Read Replica = offload reads. You can use both together.

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
Aurora Replicas connect to the SAME shared cluster volume (no data copy) → typically <10 ms lag, up to 15 of them, with automatic fast failover. RDS Read Replicas each hold their own asynchronously-copied data (can lag seconds), ⚠️ verify the max (5, possibly now 15), and are manually promoted.

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

Which RDS engines support IAM database authentication, and how does the app actually log in?
?
MariaDB, MySQL and PostgreSQL (plus Aurora MySQL/PostgreSQL). The app calls `aws rds generate-db-auth-token`, then passes the returned token **as the password**. No password is stored anywhere; connections are always encrypted with SSL/TLS.

How long is an RDS IAM authentication token valid, and what happens to a session already open when it expires?
?
15 minutes. The token authenticates only when the session is ESTABLISHED — an already-open connection is unaffected and keeps working. But every NEW connection needs a fresh token, which is why a connection pool that caches one token at startup begins failing about 15 minutes after deploy.

What IAM action grants database login, and what does the resource ARN look like?
?
`rds-db:connect` — the only action with the `rds-db:` prefix, which is separate from the `rds:` management API. Resource: `arn:aws:rds-db:{region}:{account-id}:dbuser:{DbiResourceId}/{db-user-name}`. Note DbiResourceId is the instance's resource id (`db-ABC…`), not the name you gave the instance; Aurora uses DbClusterResourceId, RDS Proxy uses `prx-…`.

Does IAM database authentication control what a user can DO inside the database?
?
No. IAM controls only WHETHER you may connect as a given database user. Once connected, the database's own GRANTs decide everything — a role connecting as `jane_doe` gets exactly what `jane_doe` was granted. IAM DB auth is authentication, not in-database authorization.

Do database logins via IAM database authentication appear in CloudTrail?
?
No. AWS documents that CloudTrail and CloudWatch do NOT log IAM DB authentication — `generate-db-auth-token` is signed locally and isn't tracked. For database-level auditing use the engine's audit plugin / pgaudit or Database Activity Streams. Don't pick IAM DB auth as the "audit trail of logins" answer.

Password vs IAM DB auth vs Secrets Manager — when do you pick each?
?
Native password: legacy/simple. IAM DB auth: workloads with a role (EC2 instance profile, Lambda, ECS) where you want NO stored secret and 15-minute credentials. Secrets Manager: when the app or a third-party tool genuinely needs a real password, and you want automatic rotation.

What resource cost does enabling IAM DB authentication add to the instance?
?
AWS states you need 300–1000 MiB of extra memory on the DB instance for reliable connectivity. That matters on burstable t-class instances — reduce buffers/cache by the same amount or you risk running out of memory.

Terraform: what one argument enables IAM database authentication, and what does it NOT do?
?
`iam_database_authentication_enabled = true` on `aws_db_instance` / `aws_rds_cluster`. It only flips the feature on — you must separately attach an IAM policy allowing `rds-db:connect` AND create the database user mapped to IAM inside the DB (AWSAuthenticationPlugin for MySQL, `GRANT rds_iam` for PostgreSQL).

An Aurora Replica serves reads. What ELSE does it do that an RDS read replica does not?
?
It doubles as the automatic failover target. Aurora Replicas share the cluster volume, so one set of instances gives you read scaling AND high availability at the same time, with failover in seconds and priority tiers deciding who gets promoted. With RDS you need a Multi-AZ standby (HA, not readable) and read replicas (readable, manual promote) as two separate things.
