---
topic: 06-capstone
domain: resilient
status: reviewed
services: [VPC, ALB, ASG, RDS, Terraform Modules]
related: [05-vpc-core, 04-alb-asg, 02-ec2, 01-iam, 03-ami-bake]
cards: cards/06-capstone-cards
tags: [topic, domain/resilient, capstone]
---

# 06 – Capstone: 3-Tier VPC with Terraform Modules

The consolidation build: a real secure 3-tier app (ALB → ASG → RDS) in a purpose-built VPC, composed as **three reusable Terraform modules**. Two big lessons: **modules** (the Terraform skill) and **RDS** (the exam service). Ties together [[05-vpc-core]], [[04-alb-asg]], [[02-ec2]], [[01-iam]], [[03-ami-bake]].

## What problem does this solve?

An app that serves the public internet has to be reachable. A database holding that app's data must never be.

Those two sentences are in tension. The way this build resolves them is to split the app into **tiers with different exposure**. The load balancer is the only thing the internet can talk to. The app servers sit behind it in private subnets with no public IP at all. The database sits behind *them*, in its own private subnets, and will only answer the app tier. Each tier is one hop, and each hop is a separate permission. Breaking into one does not hand you the next.

That is the shape. The second problem is how you *write* it.

A build like this is a lot of resources — network, routing, load balancer, scaling group, database — and if they all live in one flat directory you have a file nobody wants to touch and nothing you can reuse for the next environment. So it is split too: three **modules**, each a self-contained directory with typed inputs and explicit outputs, wired together by a thin root config. That is how real Terraform is organized: composable, reusable, testable.

> In one line: tiers limit the blast radius of a breach; modules turn one untouchable file into composable, reusable pieces.

## How it actually works

### The security-group chain is the architecture

The tiers are enforced twice over. Once by placement — the ALB in public subnets, the app instances in private subnets with no public IP, the database in its own private data subnets. And again, on top of that, by security groups pointing at each other. The SG chain is the layer you can trace request by request:

| Hop | Rule that allows it |
|---|---|
| User → ALB | `alb-sg` allows `:80` from `0.0.0.0/0` |
| ALB → app instance | `app-sg` allows `:80` **from `alb-sg`** |
| App → database | `db-sg` allows `:5432` **from `app-sg`** |

Read what each rule *doesn't* say. `app-sg` never mentions the internet, so nothing on the internet can reach an app instance — and the instance has no public IP and lives in a private subnet anyway. `db-sg` names only `app-sg`, so the database can't be reached except from the app tier. Nothing can skip a tier, because no tier will accept traffic from anything except the one directly in front of it.

The detail that makes this work at scale: each rule references the security group **in front of it by SG ID, not by CIDR**. Instances come and go as the ASG scales, and their IPs change every time. An IP-based rule would need rewriting constantly. An SG-ID reference means "whatever is currently wearing that group" — it keeps being correct without being touched. That reference chain *is* the security model.

One rule about writing those rules that bites once and then never again: an egress rule with `ip_protocol = "-1"` (all protocols) **cannot also carry a port range**. Set `from_port`/`to_port` to `0` alongside it and AWS quietly accepts it at **create** time — it normalises `0/0` to "all" — so the apply succeeds and you think you're fine. Every later plan then shows drift (`0` against the stored `-1`), and the **update** is rejected outright. All protocols ⇒ no ports; specific ports ⇒ a specific protocol.

> In one line: each tier only accepts the group in front of it, referenced by SG ID so it survives every scale event.

### Modules, and the output that goes missing

A Terraform module is less exotic than it sounds: **a module is a directory of `.tf` files**. Nothing more. The directory you actually run Terraform in is the **root module**; any other directory you point at with `module "name" { source = "..." }` is a **child module**.

The contract between them is two ordinary things you already use:

- **`variable` blocks are the inputs** — the module's API, the knobs the caller can turn.
- **`output` blocks are the return values** — what the caller is allowed to read back, as `module.<name>.<output>`.

That is how the three modules here are wired. `module.vpc` hands out subnet IDs; `module.compute` takes them and hands back `app_sg_id`; `module.database` takes *that* and builds `db-sg` from it. The root config's job is that wiring — it passes outputs into inputs, and that plumbing is most of what the root file contains.

Now the part that surprises people, and did here: **outputs bubble up exactly one level.**

A child module's output is visible to its **direct caller only**. It does not propagate further on its own. So `terraform output` at the root came back empty even though every module declared outputs — because the root had never re-declared them as its own. The fix is to re-export: the caller writes an `output` block of its own that reads the child's. Once you know it, the rule reads as deliberate — a module's outputs are its API to *its caller*, not a global namespace everything can reach into.

Two smaller mechanics worth holding: the **provider is configured once, in the root**, and child modules inherit it — you do not put a `provider` or `terraform` block inside a module. And after you add a `module` block or change its `source`, you must **re-run `terraform init`** to register it.

Finally, the judgement call: **don't over-modularize.** Wrapping a single resource in a module buys nothing but indirection. You modularize a *pattern you have already repeated*.

> In one line: a module is a directory with variables in and outputs out, and its outputs reach the caller and stop there.

### Multi-AZ and read replicas solve different problems

This is the RDS confusion the exam leans on hardest, and the reason it works is that both features are described as "a copy of your database in another place."

They are not interchangeable.

**Multi-AZ** creates a **synchronous** standby in another AZ. Every write lands on both before it is acknowledged. If the primary dies, RDS fails over to the standby automatically. And the standby is **passive — you cannot read from it.** That feels wasteful: a full second database that serves no traffic. But that is the point of it: Multi-AZ is bought for **availability**, not capacity — the standby is there to take over, not to take load. It also doubles the cost and is **not** Free Tier.

**Read replicas** are **asynchronous** copies that you *can* read from. They exist for **read scaling** — reporting queries, read-heavy traffic you want off the primary. Because replication is async they lag slightly (eventual consistency), which is fine for read traffic. They can be same-AZ, cross-AZ or **cross-region**, and a replica can be **promoted** to a standalone database — but that promotion is **manual**, not an automatic failover.

So the trigger words split cleanly: "survive an AZ failure" / "HA" → **Multi-AZ**. "Offload reads" / "scale read traffic" / "reporting" → **read replicas**.

> In one line: Multi-AZ is a standby you cannot read that fails over automatically; a read replica is a copy you can read but must promote by hand.

### The RDS setting you can only get right once

Encryption at rest is set at creation only — you cannot encrypt an existing unencrypted instance in place.

**Encryption at rest is set at creation only.** `storage_encrypted = true` is decided when the instance is born; you cannot flip it on afterwards for a database that is already running unencrypted. The route back is a three-step dance: **snapshot → copy the snapshot with encryption enabled → restore from that copy.** You end up with a new instance, not a modified one. Worth internalising as a design habit, not a fact: encrypt everything at creation, because "we'll turn it on later" isn't a thing here.

Separate from that, two input rules RDS validates and will bounce your apply over — both hit live during this build:

- **Master username reserved words.** RDS rejects certain names — `root`, `rdsadmin`, `admin` on some engines. Use something like `dbadmin`. (`root` on postgres failed here.)
- **Master password constraints.** 8–128 characters, and it may not contain `/`, `"`, `@`, or spaces. (An `@` in the first password would have been rejected.)

And two placement decisions that belong with them. A VPC database needs a **DB subnet group** — the set of subnets, across **2+ AZs**, that RDS is permitted to place instances in. And `publicly_accessible = false` keeps it off the public internet, which is the only correct answer for something sitting in a data-tier subnet.

> In one line: encryption is decided at creation and the only way back is snapshot-copy-restore; the username and password just have to survive RDS's validation rules.

### Reaching a database that has no way in

Having built a database nothing can reach, you now need to reach it — from a laptop, with a GUI client. Both routes were built and tested here.

**Option A: a bastion.** Put a small EC2 in a **public** subnet with a public IP, let `bastion-sg` accept `:22` from your own `/32`, and add a `db-sg` ingress rule **from `bastion-sg`**. Your client SSHes to the bastion and tunnels through to the RDS endpoint. It works everywhere and it is the classic answer. It also leaves you running and patching a public box, with an SSH port open and keys to manage.

**Option B: SSM Session Manager port forwarding.** No bastion, no public IP, and **no inbound port open at all**. Attach an instance profile carrying the AWS-managed **`AmazonSSMManagedInstanceCore`** policy to the private app instances; the SSM agent already on the AMI registers them with SSM *outbound* over the NAT gateway. You then start a port-forwarding session and `127.0.0.1:5432` on your laptop emerges inside the VPC at RDS. The client connects to `localhost` as a plain connection — no SSH involved.

Notice what changed underneath. The bastion's security model is a network hole plus an SSH key. Session Manager's is **IAM** for authentication and **CloudTrail** for the audit trail, with the connection established from the inside out — which is why nothing has to be opened inbound. Any question phrased as "access private instances without a bastion / without opening ports / with an audit trail" is pointing at Session Manager.

Two Terraform snags on the way: on a **launch template**, `iam_instance_profile` is a **block** (`iam_instance_profile { name = ... }`), not the bare string you use on `aws_instance` — and instances that already exist need an **ASG instance refresh** before they pick up the new profile.

> In one line: a bastion opens a door and guards it; Session Manager opens no door and dials out instead.

## Exam recap

*Now that the mechanisms are clear, this is the compressed version to revise from.*

> [!info] Exam TL;DR
> - **3-tier shape:** ALB in **public** subnets → ASG instances in **private app** subnets → RDS in **private data** subnets. Security-group **chain**: internet → alb-sg → app-sg → db-sg (each tier only reachable from the one in front). This is *the* canonical SAA-C03 architecture.
> - **RDS Multi-AZ = synchronous standby in another AZ for FAILOVER (HA)** — NOT readable. **Read Replicas = async copies for READ SCALING** — readable, can be cross-region. Different problems.
> - **RDS encryption at rest is set at creation only** — can't encrypt an existing unencrypted instance in place (snapshot → copy with encryption → restore).
> - **DB subnet group** tells RDS which (2+ AZ) subnets it may live in. Keep RDS `publicly_accessible = false`.
> - **Terraform modules:** a module is just a directory (variables = inputs, outputs = returns). Outputs bubble up **one level** — re-export at each caller. Provider is configured once in the **root**; child modules inherit it.

## AWS console ↔ Terraform map (new pieces)

| Concept | Terraform | Notes |
|---|---|---|
| A reusable child module | a directory + `module "x" { source = "./modules/x" }` | Inputs = its variables; outputs = its returns. No provider block inside. |
| Read a module's output | `module.x.output_name` | Only visible to the caller; re-export at root for the CLI. |
| DB subnet group | `aws_db_subnet_group` | The 2+ AZ subnets RDS may use. |
| The database | `aws_db_instance` | engine, instance_class, subnet group, SG, credentials, multi_az, storage_encrypted. |
| Secret input | `variable { sensitive = true }` + `terraform.tfvars` (gitignored) | Never hardcode a password in a `.tf` file. |

## Architecture diagram

```mermaid
flowchart TB
    NET([Internet]) --> ALB["ALB (public subnets)<br/>alb-sg: :80 from 0.0.0.0/0"]
    ALB --> ASG["ASG instances (private app subnets)<br/>app-sg: :80 from alb-sg only<br/>no public IP"]
    ASG --> RDS["RDS Postgres (private data subnets)<br/>db-sg: :5432 from app-sg only<br/>publicly_accessible = false"]
    ASG -->|apt install via| NAT["NAT GW (public)"] --> NET

    subgraph MODS["Terraform modules"]
      VPCM["module.vpc<br/>-> subnet IDs"]
      CMPM["module.compute<br/>-> app_sg_id, alb_dns"]
      DBM["module.database"]
      VPCM -->|subnet ids| CMPM
      VPCM -->|data subnet ids| DBM
      CMPM -->|app_sg_id| DBM
    end
```

## Key facts, limits & pricing

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

## The Terraform I wrote

Code: `06-capstone/` — root (`main.tf` wiring, `variables.tf`, `outputs.tf`, `terraform.tfvars` gitignored) + `modules/{vpc,compute,database}/`.

- **module.vpc** — 3-tier network (2 public / 2 app / 2 data subnets, IGW, NAT, route tables), all driven by `var.*`, exposing `vpc_id` + three subnet-ID lists.
- **module.compute** — adapted [[04-alb-asg]]: golden AMI ([[03-ami-bake]]), alb-sg + app-sg chain, launch template (`user_data` via `${path.module}`), ALB/target group/listener, ASG in **private** app subnets, target-tracking policy. Exposes `alb_dns_name` + `app_sg_id`.
- **module.database** — DB subnet group, db-sg (from `var.app_sg_id`), `aws_db_instance` (postgres, single-AZ, encrypted, private, secret password).
- **root** wires it all: `module.vpc` outputs → `module.compute` + `module.database` inputs; `module.compute.app_sg_id` → `module.database`.

Non-obvious things hit:
- **Module outputs don't reach the CLI** until re-exported at the root (`terraform output` was empty).
- **`-1` egress rules must omit ports** (apply error above).
- **Empty SG `description = ""`** fails at apply (AWS requires a non-empty description); `validate`/`plan` don't catch it.
- **RDS reserved username** (`root`) + **forbidden password chars** (`@`).

> [!warning] Trap — Multi-AZ to scale reads
> Multi-AZ is **HA/failover**, the standby is **not readable**. To offload/scale reads you use **read replicas**. Swapping these is the most common RDS exam mistake.

> [!warning] Trap — "the module output shows in `terraform output`"
> Only **root** outputs show on the CLI. A module output must be re-declared at the root. Outputs bubble up one level per caller.

> [!tip] Production gap
> Real version adds: HTTPS listener (ACM cert) + HTTP→HTTPS redirect, RDS **Multi-AZ** + automated backups + `deletion_protection`, the password in **Secrets Manager** (not tfvars), one **NAT gateway per AZ**, remote **S3 state backend** with locking, and the modules pulled from a registry/git with pinned versions.

> [!example]- Recreate-from-memory drill
> Build a 3-module capstone: `vpc` (public/app/data subnets + NAT, outputs subnet IDs), `compute` (ALB public + ASG private + SG chain, outputs app_sg_id), `database` (RDS private, ingress from app_sg_id, sensitive password from tfvars). Wire outputs→inputs in the root, re-export `alb_dns_name` at root. Goal: browse the ALB; instances have no public IP; DB reachable only from app tier.
> > [!success]- Reference solution
> > See `06-capstone/`. Gotchas: `-1` egress omits ports; non-empty SG descriptions; RDS username not `root`, password no `@`; re-export module outputs at root; `terraform init` after adding each module.

## Accessing the private database (bastion vs SSM)

The DB is private (no public IP; `db-sg` allows only the app tier), so reaching it from a laptop needs a jump path. Both were built and tested on this stack.

> [!example] Option A — Bastion host + SSH tunnel
> A small EC2 in a **public** subnet (public IP, `bastion-sg` allowing `:22` from your `/32`), allowed into the DB via a `db-sg` ingress rule **from `bastion-sg`**. A GUI client (TablePlus **"Over SSH"**) SSHes to the bastion and tunnels to the RDS endpoint. The cross-module wiring lived in the root: `security_group_id = module.database.db_sg_id`, `referenced_security_group_id = aws_security_group.bastion.id`. Classic and works everywhere — but it's a public box to run/patch, an open SSH port, and keys to manage.

> [!example] Option B — SSM Session Manager port forwarding (preferred)
> **No bastion, no public IP, no inbound port.** Give the private app instances an instance profile with the AWS-managed **`AmazonSSMManagedInstanceCore`** policy; the SSM agent (pre-installed on Ubuntu AMIs) registers them with SSM over NAT. Then:
> ```
> aws ssm start-session --target <instance-id> \
>   --document-name AWS-StartPortForwardingSessionToRemoteHost \
>   --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["5432"]}'
> ```
> Local `127.0.0.1:5432` emerges *inside the VPC* at RDS; TablePlus connects to `localhost` (a plain connection, no SSH). Auth is **IAM**, and every session is logged in **CloudTrail**. Gotcha: on a *launch template*, `iam_instance_profile` is a **block** (`iam_instance_profile { name = ... }`), not the bare-string attribute used on `aws_instance`. Existing instances need an **instance refresh** to pick up the new profile.

| | Bastion | SSM Session Manager |
|---|---|---|
| Public instance | **Yes** | **No** |
| Inbound port open | SSH :22 | **None** |
| Auth | SSH key | **IAM** |
| Audit | box logs | **CloudTrail** |
| Extra infra | bastion to run/patch | just an instance profile |
| Exam framing | classic | **"access private instances without a bastion / without opening ports / auditable"** → Session Manager |

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Module outputs bubble up one level** — must re-export at the root for `terraform output` / other modules to see them.
- [ ] **`-1` (all protocols) egress can't have a port range** — omit `from_port`/`to_port`.
- [ ] **Empty SG `description = ""` fails at apply** (not caught by validate/plan).
- [ ] **RDS Multi-AZ (HA, not readable) vs Read Replica (read scaling)** — the classic trap.
- [ ] **RDS username/password constraints** — reserved names (`root`), forbidden chars (`@`).
- [ ] **Secrets belong in tfvars (gitignored)/Secrets Manager**, never in a committed `.tf`.
- [ ] **Reaching a private DB: bastion (public, SSH, open port) vs SSM Session Manager (no bastion, IAM auth, CloudTrail)** — SSM is the "no open ports / auditable" exam answer.
- [ ] **`iam_instance_profile` is a BLOCK on a launch template**, a string on `aws_instance`; launch-template changes need an ASG instance refresh to take effect.

## 🔗 Docs

- [Terraform modules — creating & calling](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform module outputs](https://developer.hashicorp.com/terraform/language/values/outputs)
- [RDS Multi-AZ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html) / [Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- [RDS encryption at rest](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html)
- [Terraform `aws_db_instance`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) / [`aws_db_subnet_group`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group)

---
**Cards for this topic:** [[cards/06-capstone-cards]]
