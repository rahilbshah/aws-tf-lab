---
topic: 07-rds-aurora
domain: resilient
status: reviewed
services: [RDS, Aurora]
related: [06-capstone, 08-elasticache, 05-vpc-core]
cards: cards/07-rds-aurora-cards
tags: [topic, domain/resilient]
---

# 07 – RDS & Aurora

The managed relational database tier. **RDS** = AWS runs standard engines for you; **Aurora** = AWS's cloud-native re-architecture of MySQL/Postgres with separated compute/storage. Built hands-on in [[06-capstone]]; this is the exam depth.

> [!info] Exam TL;DR
> - **RDS engines:** MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, + **Aurora**.
> - **Multi-AZ = HA/failover** (synchronous standby, NOT readable). **Read Replica = read scaling** (async, readable, cross-region-capable, manual promote). The #1 RDS trap.
> - **Backups:** automated (daily snapshot + ~5-min transaction logs → **PITR to any second**, 1–35 day retention, deleted with the instance) vs manual snapshots (survive deletion). Restore always creates a **new instance**.
> - **Aurora storage:** **6 copies across 3 AZs**, self-healing, shared **cluster volume** auto-scaling **10 GB → 128 TB**; compute/storage **separated**.
> - **Aurora replicas share the storage** (no copy) → **<10 ms** lag, auto-failover, up to **15** (vs 5 RDS). Endpoints: **writer/cluster**, **reader** (LB'd reads), **custom**, **instance**.
> - **Aurora Serverless v2** = auto-scaling capacity for variable workloads. **Aurora Global Database** = 1 primary + up to 5 read-only regions, <1s replication (DR + global reads).
> - **Encryption at rest** = set at **creation only**. Keep DBs `publicly_accessible = false` in private subnets.
> - **Three ways to authenticate:** native DB password · **IAM database authentication** (`rds-db:connect`, 15-minute token, nothing stored) · **Secrets Manager** (stored password + automatic rotation). "No password in the app / use the EC2 role" → **IAM DB auth**.

## Concept (plain English)

RDS takes the operational pain out of relational databases: AWS handles patching, backups, failover, and provisioning of standard engines (MySQL, Postgres, etc.). You still pick an instance size and manage schema/queries. **Aurora** goes further — AWS rebuilt the storage layer so it's a distributed, self-healing volume spread across AZs, decoupled from the compute instances. That decoupling is why Aurora scales storage automatically, spins up read replicas that share the same data (tiny lag), fails over fast, and offers serverless and global-database modes that plain RDS can't.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| RDS instance | `aws_db_instance` | engine, instance_class, storage, subnet group, SG, credentials, `multi_az`, `storage_encrypted`. |
| DB subnet group | `aws_db_subnet_group` | The 2+ AZ (private) subnets RDS may use. |
| RDS read replica | `aws_db_instance` with `replicate_source_db` | Async read copy. |
| Aurora cluster | `aws_rds_cluster` | The cluster (storage + endpoints + engine `aurora-mysql`/`aurora-postgresql`). |
| Aurora instance(s) | `aws_rds_cluster_instance` | Writer + reader instances attached to the cluster. |
| Aurora Serverless v2 | `aws_rds_cluster` + `serverlessv2_scaling_configuration` (min/max ACU) | Instances with class `db.serverless`. |
| Log in with an IAM role instead of a password | `iam_database_authentication_enabled = true` on `aws_db_instance` / `aws_rds_cluster` | Terraform only flips the switch — you still need an IAM policy granting `rds-db:connect` **and** a DB user mapped to IAM inside the database. |

## Architecture diagram

```mermaid
flowchart TB
    App[App] -->|writes| WEP[Writer / Cluster endpoint]
    App -->|reads| REP[Reader endpoint - load-balances replicas]
    WEP --> PRI[Primary / writer instance]
    REP --> R1[Aurora Replica 1]
    REP --> R2[Aurora Replica 2 ... up to 15]
    subgraph VOL["Shared cluster volume (auto-scales 10GB-128TB)"]
      direction LR
      C1[(copy)]:::az1
      C2[(copy)]:::az1
      C3[(copy)]:::az2
      C4[(copy)]:::az2
      C5[(copy)]:::az3
      C6[(copy)]:::az3
    end
    PRI --- VOL
    R1 --- VOL
    R2 --- VOL
    classDef az1 fill:#123
    classDef az2 fill:#132
    classDef az3 fill:#231
```
*6 copies across 3 AZs; all instances read the same volume (why replica lag is tiny).*

## Key facts, limits & pricing

- **RDS Multi-AZ:** a **synchronous** standby in another AZ; **not readable**; automatic failover (~60–120s) via DNS CNAME swap. For HA only. Doubles cost; not Free-Tier.
- **RDS Read Replicas:** **asynchronous**; ⚠️ verify: **up to 5 per source** (MySQL/Postgres) — AWS may have raised this to **15**; confirm against the RDS docs before relying on the number. **readable**; can be **cross-region**; can be **promoted** to a standalone DB (manual, breaks replication). For read scaling / reporting. (You can combine: a Multi-AZ primary *with* read replicas.)
- **Backups:** automated backups enabled by setting retention 1–35 days → **point-in-time recovery** (daily snapshot + transaction logs every ~5 min). Deleted when the instance is deleted (unless you take a final snapshot). **Manual snapshots** are kept until you delete them and survive instance deletion. **Restore = new instance / new endpoint.**
- **Encryption at rest** (`storage_encrypted`, KMS): **only at creation**. To encrypt an existing unencrypted DB: snapshot → copy the snapshot **with encryption** → restore. Encryption in transit = SSL/TLS.
- **Aurora storage:** **6-way replication across 3 AZs** (2 copies/AZ); tolerates losing a whole AZ + one more copy for reads; self-healing; **cluster volume auto-scales 10 GB → 128 TB**. Compute and storage bill/scale independently.
- **Aurora Replicas:** up to **15**, share the cluster volume (**<10 ms** typical lag), **automatic failover** with priority tiers (much faster than RDS Multi-AZ). Aurora also keeps 6 storage copies regardless of instance count.
- **Aurora extras:** **Backtrack** (rewind the DB in place without restore, Aurora MySQL); **Aurora Serverless v2** (fine-grained auto-scaling ACUs for variable load); **Aurora Global Database** (1 primary + up to **5 secondary read-only regions**, **<1s** replication, cross-region DR); **Aurora Machine Learning**, **RDS Proxy** (connection pooling for Lambda/serverless).
- **Why Aurora over RDS MySQL/Postgres:** ~**5× MySQL / 3× Postgres** throughput, 15 vs 5 replicas, faster failover, 6-copy durability, auto-scaling storage, serverless + global options. Trade-off: pricier per-hour, MySQL/Postgres-compatible only.
- **RDS Free Tier:** `db.t2/t3/t4g.micro`, single-AZ, 750 hrs/mo, 20 GB, 12 months.
- **IAM database authentication** works on **MariaDB, MySQL, PostgreSQL** (and Aurora MySQL/PostgreSQL). You call `aws rds generate-db-auth-token` and pass the returned string **as the password**. Each token lives **15 minutes**; traffic is **always SSL/TLS**. The token is typically **~1 KB minimum** — drivers/tools that truncate long passwords will break it.
- **IAM DB auth costs memory on the instance:** AWS states you need **300–1000 MiB of extra memory** for reliable connectivity — a real consideration on burstable `t`-class instances.
- **CloudTrail does not log IAM DB authentication.** `generate-db-auth-token` is signed locally and is not tracked. Do not answer "use IAM DB auth to get an audit trail of database logins."
- **Some global condition keys don't work** with IAM DB auth: `aws:SourceIp`, `aws:SourceVpc`, `aws:SourceVpce`, `aws:UserAgent`, `aws:Referer`, `aws:VpcSourceIp`.
- **PostgreSQL specifics:** granting the `rds_iam` role to a user makes IAM auth **take precedence over password auth** for that user; IAM auth can't be combined with Kerberos, and can't be used for a replication connection.

## Comparisons

### Multi-AZ vs Read Replica (memorize)

|   | Multi-AZ | Read Replica |
|---|---|---|
| Purpose | HA / failover | Read scaling |
| Sync | Synchronous | Asynchronous |
| Readable | **No** | **Yes** |
| Region | Same region (other AZ) | Same or **cross-region** |
| Failover | Automatic | Manual promote |
| Trigger words | "survive AZ failure", "HA" | "offload reads", "reporting", "scale reads" |

### RDS vs Aurora

|   | RDS (MySQL/Postgres) | Aurora |
|---|---|---|
| Storage | Single EBS volume (+ standby copy) | Distributed 6-copy/3-AZ cluster volume |
| Storage scaling | Manual/auto up to limit | Auto 10 GB–128 TB |
| Read replicas | Up to 5, copy data (lag) | Up to 15, share storage (<10 ms) |
| Failover | ~1–2 min (Multi-AZ) | Faster (shared storage) |
| Serverless | RDS has no true serverless | Aurora Serverless v2 |
| Global | Cross-region read replica | Aurora Global Database (<1s) |
| Cost | Lower | Higher, more performance |

### Database authentication — password vs IAM vs Secrets Manager

|   | Native DB password | **IAM database authentication** | Secrets Manager |
|---|---|---|---|
| Where the credential lives | in the DB **and** your app config | **nowhere** — minted on demand | encrypted in Secrets Manager |
| How the app authenticates | username + password | `generate-db-auth-token` → use the token **as the password** | fetch the secret, then use the password |
| Credential lifetime | until someone rotates it by hand | **15 minutes** | until rotated (**automatic** rotation available) |
| Who is allowed to connect | database `GRANT`s only | IAM policy: `rds-db:connect` on a `dbuser` ARN | IAM policy on `secretsmanager:GetSecretValue` |
| Transport | TLS optional | **always SSL/TLS** | TLS optional |
| Best for | legacy / simple setups | **EC2, Lambda, ECS with a role — no secret to leak or rotate** | apps or third-party tools that need a *real* password |

The IAM policy — note the `rds-db:` prefix, which is **not** the `rds:` prefix used by the RDS management API:

```json
{
  "Effect": "Allow",
  "Action": ["rds-db:connect"],
  "Resource": ["arn:aws:rds-db:us-east-1:111122223333:dbuser:db-ABCDEFGHIJKL01234/db_user"]
}
```

ARN shape: `arn:aws:rds-db:{region}:{account-id}:dbuser:{DbiResourceId}/{db-user-name}`

- `DbiResourceId` is the instance's **resource id** (`db-ABC…`), **not** the DB identifier you named it. It's Region-unique and never changes. Aurora uses the `DbClusterResourceId`; through RDS Proxy it's `prx-…`.
- The last segment is the **database** user, which must already exist and be mapped to IAM — `AWSAuthenticationPlugin` on MySQL, `GRANT rds_iam TO <user>` on PostgreSQL.
- Wildcards work: `dbuser:*/jane_doe` means that DB user on any instance in the account + Region.

## Worked examples

> [!example] Worked example — an EC2 app that connects to RDS with no password anywhere
> The app runs on EC2 behind an ASG and must reach a private PostgreSQL instance. Instead of a password in a config file (or in Terraform state), enable `iam_database_authentication_enabled` on the instance, create the DB user and `GRANT rds_iam TO appuser`, and attach a policy allowing `rds-db:connect` on `arn:aws:rds-db:us-east-1:…:dbuser:db-ABC…/appuser` to the **instance profile role** the ASG's launch template already assigns (see [[02-ec2]], [[01-iam]]). At connect time the SDK calls `generate-db-auth-token`, signs it with the role's temporary credentials from IMDSv2, and hands the token to the driver as the password over TLS. Nothing is stored, nothing is rotated, and revoking access is a one-line IAM change — no database restart, no redeploy. This is the canonical exam answer to "remove hard-coded database credentials without managing a secret."

> [!example] Worked example — read-heavy app with a reporting team
> An app's primary DB is fine for writes, but a BI/reporting team runs heavy analytical queries that slow production. Solution: add **read replicas** and point the reporting tools at them (or Aurora's **reader endpoint**), isolating analytics from the write path. If they *also* need to survive an AZ outage, that's a **separate** feature — **Multi-AZ** — layered on the primary. The exam tests whether you know these are two different tools: replicas = scale reads, Multi-AZ = availability.

> [!failure] Failure mode — "we'll encrypt the database later"
> A team launches RDS unencrypted to move fast, planning to enable `storage_encrypted` later. There is no "encrypt in place" — encryption is **creation-time only**. Fixing it means: snapshot the DB → **copy the snapshot with encryption enabled** → restore from the encrypted copy → repoint the app (downtime/cutover). Design encryption in from day one. Same gotcha bit the [[06-capstone]] build's mental model.

> [!example] Worked example — spiky dev/test database → Aurora Serverless v2
> A team runs dozens of dev/test databases that are idle most of the day and busy in bursts. Provisioned instances waste money sitting idle; right-sizing each by hand is toil. **Aurora Serverless v2** auto-scales each cluster's capacity (ACUs) up during bursts and down to a floor when idle, in-place, per-second billing — you pay for actual usage. Trigger phrase: "unpredictable / intermittent / variable workload, minimize cost" → Aurora Serverless.

## The Terraform I wrote

Built a standard `aws_db_instance` (postgres, single-AZ, encrypted, private) twice — in [[06-capstone]] and again as a **best-practices standalone** in `07-rds-elasticache/` (encrypted, `publicly_accessible = false`, automated backups, SG-from-app-tier, sensitive password from tfvars). Aurora/Serverless/Global were studied conceptually (they bill, and the exam tests the *decisions*, not the HCL). Aurora in Terraform would be `aws_rds_cluster` + `aws_rds_cluster_instance` (writer + readers) rather than a single `aws_db_instance`.

> [!tip] Real gotcha — AWS Free Plan caps backup retention
> On the new AWS **Free Tier "Free Plan"**, `backup_retention_period = 7` failed with `FreeTierRestrictionError`; had to drop to `1`. The current free tier has service guardrails (backup retention, sometimes instance types) the old 12-month one didn't — dial settings down rather than upgrading the plan.

> [!failure] Failure mode — the connection pool that dies 15 minutes after deploy
> A team enables IAM DB auth and their app works perfectly in testing. Fifteen minutes after each deploy, new database connections start failing with an authentication error while **existing connections keep working fine** — which makes it look like a random, partial outage. The cause: the connection pool minted **one** token at startup and cached it as "the password." AWS is explicit that the token is used only to *establish* the session and has a **15-minute lifetime** — an open session is unaffected, but every new connection needs a **fresh** token. Fix: generate the token inside the pool's connection factory, not once at boot. (Related: if you mint the token with temporary role credentials, those credentials must still be valid at connect time.)

> [!warning] Trap — "IAM database authentication controls what the user can do in the database"
> It does not. IAM decides **whether you may connect as a given database user**; everything after that is still the database's own `GRANT`s. AWS says it plainly: a role that connects as `jane_doe` gets exactly the tables and schemas `jane_doe` has. So IAM DB auth is **authentication**, not in-database **authorization** — pairing it with an over-privileged DB user gains you nothing.

> [!warning] Trap — `rds-db:` vs `rds:`
> `rds-db:connect` is the **only** action with the `rds-db:` prefix and it exists solely for IAM DB auth. Everything else (`rds:CreateDBInstance`, `rds:DescribeDBInstances`…) is the `rds:` management API and has nothing to do with logging into the database. An answer that grants `rds:*` to let an app "connect to the database" is wrong.

> [!warning] Trap — "use IAM DB auth so database logins show up in CloudTrail"
> They don't. AWS documents that CloudTrail and CloudWatch **do not log** `generate-db-auth-token`. For database-level audit you need the engine's own audit plugin / `pgaudit` and Database Activity Streams — not CloudTrail.

> [!warning] Trap — Multi-AZ to scale reads
> Multi-AZ standby is **not readable** — it's for failover. Use **read replicas** to scale reads. Reversed constantly on the exam.

> [!warning] Trap — Aurora replica lag is like RDS replica lag
> No — Aurora replicas **share one storage volume** (no data copy), so lag is ~milliseconds; RDS read replicas copy data asynchronously and can lag seconds. Different mechanism.

> [!warning] Trap — "RDS is serverless / auto-scales like Aurora"
> Plain RDS is provisioned instances. True serverless + auto-scaling storage + global <1s replication are **Aurora** features. "Serverless relational" → Aurora Serverless v2.

> [!example]- Recall drill
> (1) Multi-AZ vs read replica — purpose + readable? (2) How many storage copies/AZs does Aurora keep? (3) Aurora's four endpoint types? (4) When Aurora Serverless v2? (5) How do you encrypt an existing unencrypted RDS?
> > [!success]- Answers
> > (1) Multi-AZ = HA/failover, NOT readable; read replica = read scaling, readable. (2) 6 copies / 3 AZs. (3) writer/cluster, reader, custom, instance. (4) variable/unpredictable/spiky workloads, pay-per-use. (5) snapshot → copy with encryption → restore.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Aurora storage architecture** (6 copies/3 AZs, shared volume, compute/storage separation) — knew replicas differ but not the why.
- [ ] **Aurora endpoints** (writer/cluster vs reader vs custom vs instance).
- [ ] **Aurora Serverless v2** (variable-workload auto-scaling) and **Global Database** (<1s cross-region).
- [ ] **PITR mechanics** — daily snapshot + ~5-min transaction logs = restore to any second; restore = new instance.
- [ ] **Encryption at creation only** — no in-place encryption.
- [ ] **IAM database authentication — missed twice, both marked _sure_** (mock 2026-08-28, trainer-sourced). Discriminators that beat me: "short-lived IAM database credentials instead of passwords" and "token-based DB auth tied to an instance profile." The concept was **absent from this note entirely** until 2026-08-29 — see the new authentication comparison above.
- [ ] **Aurora Replicas double as failover targets** — missed while marked _sure_ (mock 2026-08-28, trainer-sourced). An Aurora Replica is not read-scaling *or* HA; it is **both at once**, which is exactly what makes it different from an RDS read replica.

## 🔗 Docs

- [Aurora DB clusters](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.html) — verified 2026-07
- [RDS Multi-AZ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html) / [Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- [RDS backups & PITR](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html)
- [Aurora Serverless v2](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.html) / [Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html)
- [IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html) — engines, 15-min token lifetime, SSL/TLS, 300–1000 MiB memory, CloudTrail non-logging, unsupported condition keys; verified 2026-08-29
- [IAM policy for IAM database access](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html) — `rds-db:connect`, the `dbuser` ARN format, DbiResourceId; verified 2026-08-29
- [Terraform `aws_rds_cluster`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster)

---
**Cards for this topic:** [[cards/07-rds-aurora-cards]]
