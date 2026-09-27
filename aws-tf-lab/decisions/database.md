---
decision: database
question: Which data store should this use?
spans: [07-rds-aurora, 08-elasticache, 19-serverless, 22-analytics, 24-other-services]
tags: [decision, domain/performance]
---

# Which data store should this use?

The notes explain each engine. This routes you to one. Work top-down — the first
question that applies settles it; a scenario often needs two stores, not one.

## 1. What is being asked of the store?

**Read shape decides the service**; volume only decides the instance size.

| The workload is | Shape | Go to |
|---|---|---|
| the app's live path — single rows, reads and writes | **OLTP** | §2 |
| the same answer requested over and over | **cache** | §5 |
| aggregates over months of history | **OLAP** | §6 |
| free-text search, relevance, log dashboards | **search** | §6 |
| append-only, and you must later *prove* it wasn't altered | **ledger** | QLDB, nothing else |

↳ [[24-other-services#The long tail — recognise and eliminate]]

## 2. OLTP — relational or DynamoDB

One question, and it is not about scale: **do you know every query before the table
exists?**

- **Yes**, and they are key lookups → **DynamoDB**. The key schema *is* the query plan.
- **No** — joins, aggregates, analysts writing new `SELECT`s → **relational**, §3.

Both scale, so "which one scales" settles nothing. A later access pattern on DynamoDB is
an index question — and **an LSI can only be created with the table.**

↳ [[19-serverless#DynamoDB vs relational (RDS / Aurora, including Serverless)]] · [[19-serverless#Global secondary index vs local secondary index]]

## 3. Relational — RDS or Aurora

The engine settles it first: **Aurora is MySQL- and PostgreSQL-compatible only**, so
Oracle, SQL Server and MariaDB mean **RDS**, full stop. Where both are possible, Aurora
earns its higher price for one reason — shared storage. Pick it for **auto-scaling storage
(10 GB → 128 TB)**, **replica lag under 10 ms**, **failover faster than Multi-AZ's 1–2
minutes**, **Serverless v2**, or **Global Database**. Otherwise RDS.

↳ [[07-rds-aurora#RDS vs Aurora]]

## 4. The database exists and something hurts. What?

Name the symptom — each has one answer, and they are not substitutes.

- **"Survive an AZ failure"** → **Multi-AZ**. Synchronous standby, **not readable**.
- **"Offload reads / reporting"** → **read replicas**, or Aurora's reader endpoint.
- **"Idle all week, spiky on Monday"** → **Aurora Serverless v2**.
- **"Readers in another region"** → cross-region read replica, or **Aurora Global
  Database** — one writable region, up to 10 read-only.
- **"No password anywhere in the app"** → **IAM database authentication**.

↳ [[07-rds-aurora#Multi-AZ vs Read Replica (memorize)]] · [[07-rds-aurora#Database authentication — password vs IAM vs Secrets Manager]]

## 5. Cache — and which engine

Reach for a cache when the **same** answer is being recomputed, not merely when reads
are heavy. In front of DynamoDB that is **DAX**; in front of RDS/Aurora, **ElastiCache**.
For the engine, ignore the use case — it is the distractor — and find the capability only
one side has. Persistence, replication, Multi-AZ failover, backup and sorted sets are
Redis-only; multi-threaded and Auto Discovery are Memcached-only. **Valkey** ≈ Redis.

↳ [[08-elasticache#Reading the engine question the right way round]] · [[08-elasticache#Redis vs Memcached (the exam table)]]

## 6. Analytics — the store is S3, so this is "which engine"

Once the answer is OLAP the data lives in an **S3 data lake** and the question collapses
to which compute reads it. The axis is **cadence and concurrency**, not size: occasional
ad-hoc SQL → **Athena**; sustained BI, many concurrent users, complex joins → **Redshift**;
existing Spark or Hadoop code → **EMR**; full-text search or a log dashboard →
**OpenSearch**.

↳ [[22-analytics#Which engine does the exam mean?]] · [[22-analytics#Redshift vs RDS/Aurora]] · [[22-analytics#OpenSearch — search and logs, not reporting]]

## 7. The data is already in a database elsewhere

Not a selection question but a migration. **DMS** moves the data and can keep replicating
with CDC, so the cutover — not the copy — is the downtime. **Different engines on each end
need the schema converted first (SCT).**

↳ [[24-other-services#AWS DMS — the migration answer, and the biggest gap here]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **A cache where a read replica belongs.** ElastiCache helps when the *same* query
  repeats; replicas help when many *different* heavy queries compete.
- **DynamoDB versus Aurora Serverless v2 because both "scale".** Scale is the one thing
  they share. The fork is *when* you commit to your queries.
- **Picking by data volume.** A 200 TB OLTP app is still relational; a 50 GB
  aggregate-only workload is still OLAP. Shape decides the service, size only the bill.
- **Redshift Spectrum instead of Athena.** Both query S3 in place, but **Spectrum requires
  a cluster** in the same Region. With no warehouse in the picture it is the distractor.
- **OpenSearch as the reporting layer.** "Dashboard" pulls people there and "SQL" pulls
  them to Athena — the words are doing the work, not the requirement. Free text and
  relevance → OpenSearch; business aggregates → a query engine plus QuickSight.
- **Multi-AZ to make reads faster.** The standby is not readable: it buys availability
  and zero throughput. The inverse is as common — replicas added to survive an AZ outage.
- **"Migrate to Aurora" treated as like-for-like.** From MySQL or PostgreSQL it nearly
  is; from Oracle or SQL Server it is an engine change. "Same engine, less operational
  work" was RDS.
