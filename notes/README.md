# SAA-C03 Notes — Master Index

Entry point for all per-topic notes in this repo. Updated at the end of every topic per `CLAUDE.md §13.4`.

Per-topic files live alongside this one (`01-iam.md`, `02-vpc.md`, …) and follow the layered template in `CLAUDE.md §13.3`. Anki-importable flashcards mirror each topic file under `notes/anki/`.

## Master index

| #   | Topic                          | Status      | Last updated |
|-----|--------------------------------|-------------|--------------|
| 01  | [IAM](01-iam.md)               | ✅ Complete | 2026-05-23   |
| 02  | [EC2](02-ec2.md)               | ✅ Complete | 2026-05-30   |

## 🔴 Cumulative weak spots (across all topics)

A running checkbox list of concepts the learner has gotten wrong or hesitated on, aggregated from each topic's `🔴 My weak spots` section. These get re-surfaced during quizzes and mock exams; tick them off as they're mastered.

### 01 – IAM

- [ ] Enumerating IAM core objects under "list them" framing (forgot Role despite using it correctly elsewhere)
- [ ] HCL: spotting a quoted "reference" (literal string) vs an unquoted reference
- [ ] `.arn` vs `.name` pattern in IAM Terraform cross-references (principals → `.name`, policies → `.arn`)
- [ ] Reading plan symbols: `~` (in-place) vs `-/+` (destroy-and-recreate) vs `+`/`-`
- [ ] Scope of `aws_iam_policy_attachment` — per-policy exclusive, NOT per-group/per-principal

### 02 – EC2

- [ ] `aws_subnets.X.id` vs `.ids` — plural data sources return lists, no singular `.id` exists; pick one with `tolist(...)[0]`
- [ ] AWS instance types are dot-separated (`t3.micro`), not hyphens (`t3-micro`)
- [ ] `ip_protocol` in SG rules takes IP-layer names only (`tcp`/`udp`/`icmp`/`-1`), NOT application names like `"ssh"`
- [ ] IMDSv2 token flow — IMDSv1-style raw curl returns empty silently on modern AMIs
- [ ] `terraform console` reads state, not plan-in-memory — needs `apply` or `apply -refresh-only` to see data source values
- [ ] Ubuntu 24.04 dropped `awscli` from `apt` repos — use AWS official installer or snap
- [ ] Stop vs terminate — which attributes persist (EBS, instance ID, private IP, EIP) vs change (auto-assigned IP) vs always die (instance store)
- [ ] Trust policy vs permissions policy on a Role (continued from 01-IAM; reinforced by ec2-to-s3 setup in 02-EC2)
