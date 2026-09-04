---
topic: 06-capstone
type: revision
source: 06-capstone
tags: [revision, generated]
---

# Revision — 06 – Capstone: 3-Tier VPC with Terraform Modules

> [!abstract] Night-before read · ~6 min · self-contained
> Everything you need is here — no need to jump back mid-revision.
> Full teaching explanations, Terraform and diagrams: **[[06-capstone]]**
> *Generated from the note by `_scripts/build_revision.py` — do not edit.*
## The shape of it

> [!info] Exam TL;DR
> - **3-tier shape:** ALB in **public** subnets → ASG instances in **private app** subnets → RDS in **private data** subnets. Security-group **chain**: internet → alb-sg → app-sg → db-sg (each tier only reachable from the one in front). This is *the* canonical SAA-C03 architecture.
> - **RDS Multi-AZ = synchronous standby in another AZ for FAILOVER (HA)** — NOT readable. **Read Replicas = async copies for READ SCALING** — readable, can be cross-region. Different problems.
> - **RDS encryption at rest is set at creation only** — can't encrypt an existing unencrypted instance in place (snapshot → copy with encryption → restore).
> - **DB subnet group** tells RDS which (2+ AZ) subnets it may live in. Keep RDS `publicly_accessible = false`.
> - **Terraform modules:** a module is just a directory (variables = inputs, outputs = returns). Outputs bubble up **one level** — re-export at each caller. Provider is configured once in the **root**; child modules inherit it.

## Facts, limits & pricing

### Terraform modules
- A **module = a directory of `.tf` files**. The **root module** is where you run Terraform; **child modules** are called with `module "name" { source = "..." }`. `source` can be a local path, a git URL, or the Terraform Registry.
- **Inputs = `variable` blocks** (the module's API); **outputs = `output` blocks** (its return values). The caller passes inputs as arguments and reads outputs as `module.<name>.<output>`.
- **Outputs bubble up exactly one level.** A child's output is visible to its direct caller only; to expose it further (e.g. to the `terraform output` CLI), the caller **re-declares** it as its own output. *(Learned live: root `terraform output` showed nothing until the root re-exported the modules' outputs.)*
- **Provider is configured once, in the root.** Child modules **inherit** it — no `provider`/`terraform` block inside a module.
- After adding/changing a `module` block or its `source`, **re-run `terraform init`** to register it.
- Resources inside a module are addressed as `module.<name>.<resource>` in plans/state.
- **Don't over-modularize:** don't wrap a single resource; modularize a *pattern* you've repeated. Standard files: `main.tf` / `variables.tf` / `outputs.tf`.

### RDS
- **Managed relational DB**: MySQL, PostgreSQL, MariaDB, Oracle, SQL Server (+ **Aurora**, AWS's cloud-native MySQL/Postgres-compatible engine).
- **Multi-AZ**: a **synchronous** standby replica in another AZ; automatic failover on primary failure. It is **for HA, not reads** — you cannot read from the standby. Doubles cost; NOT Free-Tier.
- **Read Replicas**: **asynchronous** copies you *can* read from — for **read scaling**; up to 15 for Aurora, can be **cross-region**, can be promoted to standalone. Eventual consistency (replica lag).
- **DB subnet group**: the set of (2+ AZ) subnets RDS may place instances in — required for a VPC RDS.
- **Encryption at rest** (`storage_encrypted = true`, KMS): must be enabled **at creation**. To encrypt an existing unencrypted DB: snapshot → copy snapshot **with encryption** → restore.
- **Backups**: automated backups (point-in-time restore, retention 0–35 days) + manual snapshots (kept until deleted). `skip_final_snapshot = true` only for throwaway/learning.
- **`publicly_accessible = false`** keeps the DB off the public internet — correct for a data-tier subnet.
- Master **username reserved words**: RDS rejects some (`root`, `rdsadmin`, `admin` on some engines) — use a custom name like `dbadmin`. *(Hit live: `root` on postgres.)*
- Master **password constraints**: 8–128 chars, and cannot contain `/`, `"`, `@`, or spaces. *(Hit live: `@` in the first password would have been rejected.)*
- **Free Tier**: `db.t2/t3/t4g.micro`, single-AZ, 750 hrs/month, 20 GB storage, first 12 months.

## Comparisons

### RDS Multi-AZ vs Read Replica (the #1 RDS exam trap)

|   | Multi-AZ | Read Replica |
|---|---|---|
| Purpose | **High availability / failover** | **Read scaling** |
| Replication | Synchronous | Asynchronous |
| Readable? | **No** (standby is passive) | **Yes** |
| Same/other AZ | Other AZ (same region) | Same AZ, cross-AZ, or **cross-region** |
| Failover | Automatic | Manual promote (not automatic) |
| Trigger phrase | "survive an AZ failure", "HA" | "offload reads", "scale read traffic", "reporting" |

### Flat config vs Modules

|   | Flat (one dir of resources) | Modules |
|---|---|---|
| Reuse | Copy-paste | `module` block, parameterized |
| Encapsulation | None | Inputs/outputs are the contract |
| When | Learning, one-off, <~10 resources | Repeated patterns, multi-env, teams |

## Worked examples

> [!example] Worked example — the security-group chain is the security model
> Trace a request: a user hits the ALB (`alb-sg` allows :80 from `0.0.0.0/0`). The ALB forwards to an app instance — allowed because `app-sg` permits :80 **from `alb-sg`** (not from the internet; the instance has no public IP and lives in a private subnet). The app queries the database — allowed because `db-sg` permits :5432 **from `app-sg`**. Nothing can skip a tier: the internet can't reach the app SG, the app tier can't be reached except via the ALB, and the DB can't be reached except from the app tier. Each SG references the one in front by **SG ID, not CIDR** — so it keeps working as instances scale and IPs change. That reference chain *is* the 3-tier security model.

> [!failure] Failure mode — the all-protocols-with-ports egress error
> An egress rule with `ip_protocol = "-1"` (all protocols) **and** `from_port = 0` / `to_port = 0` (specific ports) fails: `You may not specify all protocols and specific ports`. It sneaks through **create** (AWS normalizes `0/0` → "all") but then every plan shows drift (`0` vs the stored `-1`) and the **update** is rejected by the stricter `ModifySecurityGroupRules`. Fix: for `-1`, **omit `from_port`/`to_port` entirely**. Rule of thumb: all-protocols ⇒ no port range; specific ports ⇒ a specific protocol.

> [!failure] Failure mode — secret in a committed .tf file
> Hardcoding `db_password = "..."` directly in `main.tf` puts a credential into git history the moment you commit. Fix (the real-world pattern): declare a **`sensitive = true`** variable, pass `db_password = var.db_password` in the module block, and put the value in **`terraform.tfvars`** (gitignored) or `TF_VAR_db_password`. Next level up in production: **AWS Secrets Manager / SSM Parameter Store** so the value never sits in a file at all — RDS can even manage the password in Secrets Manager directly.

## Traps & failure modes

> [!warning] Trap — Multi-AZ to scale reads
> Multi-AZ is **HA/failover**, the standby is **not readable**. To offload/scale reads you use **read replicas**. Swapping these is the most common RDS exam mistake.

> [!warning] Trap — "the module output shows in `terraform output`"
> Only **root** outputs show on the CLI. A module output must be re-declared at the root. Outputs bubble up one level per caller.
