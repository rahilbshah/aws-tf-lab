---
topic: 06-capstone
domain: resilient
related_note: 06-capstone
tags: [flashcards/capstone]
---

# Cards for [[06-capstone]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What is a Terraform module, structurally?
?
Just a directory of .tf files. Its `variable` blocks are its inputs (its API), its `output` blocks are its return values. Any config is already the "root module"; a child module is called with `module "name" { source = "./path" }` and its outputs read as module.name.output.

How far do a module's outputs travel, and what does that mean for `terraform output`?
?
Outputs bubble up exactly ONE level — a child's output is visible only to its direct caller (as module.<name>.<output>). To see it on the CLI via `terraform output`, or to pass it to another module, the caller must RE-DECLARE it as its own output. Modules are black boxes; you explicitly expose what should pass up.

Where is the provider configured in a modular Terraform project?
?
Once, in the ROOT module. Child modules INHERIT it — you do not put a provider (or terraform) block inside a module. After adding/changing a module block or its source, re-run `terraform init` to register it.

In a 3-tier VPC, which subnet tier holds the ALB, the app servers, and the database?
?
ALB → public subnets (internet-facing). App servers (ASG) → private app subnets (no public IP; reach internet via NAT). Database (RDS) → private data subnets (publicly_accessible = false). Security-group chain: internet → alb-sg → app-sg → db-sg, each tier allowing only the one in front (by SG ID, not CIDR).

RDS Multi-AZ vs Read Replica — purpose and readability?
?
Multi-AZ: a SYNCHRONOUS standby in another AZ for HIGH AVAILABILITY / automatic failover — NOT readable. Read Replica: ASYNCHRONOUS copies you CAN read from, for READ SCALING (can be cross-region, manually promotable). Multi-AZ = survive AZ failure; Read Replica = offload reads. The #1 RDS exam trap.

When must RDS encryption at rest be enabled, and how do you encrypt an existing unencrypted DB?
?
At creation only (storage_encrypted = true). You cannot encrypt an existing unencrypted RDS in place — you snapshot it, copy the snapshot WITH encryption enabled, then restore from the encrypted copy.

What is a DB subnet group?
?
A named set of subnets (spanning 2+ AZs) that tells RDS which subnets it may place the instance (and any standby/replica) into. Required to run RDS inside a VPC; point it at your private data subnets.

Why does an egress rule with ip_protocol = "-1" and from_port/to_port = 0 fail?
?
AWS: "You may not specify all protocols and specific ports." All-protocols (-1) means no port range is allowed — you must OMIT from_port/to_port. It can sneak through create (AWS normalizes 0/0 to "all") but the update is rejected. Rule: all protocols ⇒ no ports; specific ports ⇒ a specific protocol.

How should a database password be provided to Terraform (not hardcoded)?
?
Declare a variable with sensitive = true (keeps it out of plan/log output), pass db_password = var.db_password in the module block, and set the value in terraform.tfvars (gitignored) or the TF_VAR_db_password env var. Never write it in a committed .tf file. Production: AWS Secrets Manager / SSM Parameter Store.

What are the RDS master username and password constraints that bit this build?
?
Username: some names are reserved (e.g. root, rdsadmin, and admin on some engines) — use a custom name like dbadmin. Password: 8–128 chars and cannot contain /, ", @, or spaces (the original @ password would have failed).

Why does the app-tier SG reference the ALB's SG by ID instead of a CIDR?
?
Because instances scale in/out and their IPs change — an SG-to-SG reference ("allow from alb-sg") keeps working regardless of which IPs the ALB currently has. It also expresses intent ("only the load balancer") precisely. This SG reference chain is the whole 3-tier security model.

When should you refactor flat Terraform into modules, and when NOT?
?
DO when you've repeated a pattern (2–3×) or need reuse across environments/teams — modularize the pattern with clear inputs/outputs. DON'T wrap a single resource in a module, and don't modularize prematurely. Standard module files: main.tf / variables.tf / outputs.tf.
