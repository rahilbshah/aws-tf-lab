# SAA-C03 Notes — Vault Home

This `notes/` folder **is** an Obsidian vault (open it via *Open folder as vault*). Per-topic files live at the vault root (`[[01-iam]]`, `[[02-ec2]]`…) and follow `_templates/topic-template.md` (the structure in `CLAUDE.md §13.5`).

- **Flashcards** live inside each topic note (Spaced Repetition plugin, `Q` / `?` / `A` syntax). Frontmatter `tags: [flashcards/<topic>]` files them under that sub-deck. Review via *Spaced Repetition: Review flashcards*.
- **Weak spots** carry the `#weak-spot` tag — click it in the Tag pane for a vault-wide auto-aggregated view. The list below is the curated, actively-drilled subset.
- **Traps** carry `#trap`. The old `notes/anki/` TSV pipeline is **deprecated** (legacy deck only).

## Master index

| #   | Topic | Status | Last updated |
|-----|-------|--------|--------------|
| 01  | [[01-iam]] | reviewed | 2026-05-23 |
| 02  | [[02-ec2]] | reviewed | 2026-05-30 |
| 03  | [[03-ami-bake]] (job-skill, non-exam) | reference | 2026-05-31 |

## 🔴 Cumulative weak spots (across all topics)

Curated checklist of concepts being actively drilled. (The `#weak-spot` tag in Obsidian's Tag pane gives the full auto-aggregated view across every note.) Tick items off as they become reliable.

### 01 – IAM ([[01-iam]])

- [ ] Enumerating IAM core objects under "list them" framing (forgot Role despite using it correctly elsewhere)
- [ ] HCL: spotting a quoted "reference" (literal string) vs an unquoted reference
- [ ] `.arn` vs `.name` pattern in IAM Terraform cross-references (principals → `.name`, policies → `.arn`)
- [ ] Reading plan symbols: `~` (in-place) vs `-/+` (destroy-and-recreate) vs `+`/`-`
- [ ] Scope of `aws_iam_policy_attachment` — per-policy exclusive, NOT per-group/per-principal

### 02 – EC2 ([[02-ec2]])

- [ ] `aws_subnets.X.id` vs `.ids` — plural data sources return lists, no singular `.id` exists; pick one with `tolist(...)[0]`
- [ ] AWS instance types are dot-separated (`t3.micro`), not hyphens (`t3-micro`)
- [ ] `ip_protocol` in SG rules takes IP-layer names only (`tcp`/`udp`/`icmp`/`-1`), NOT application names like `"ssh"`
- [ ] IMDSv2 token flow — IMDSv1-style raw curl returns empty silently on modern AMIs
- [ ] `terraform console` reads state, not plan-in-memory — needs `apply` or `apply -refresh-only` to see data source values
- [ ] Ubuntu 24.04 dropped `awscli` from `apt` repos — use AWS official installer or snap
- [ ] Stop vs terminate — which attributes persist (EBS, instance ID, private IP, EIP) vs change (auto-assigned IP) vs always die (instance store)
- [ ] Trust policy vs permissions policy on a Role (continued from [[01-iam]]; reinforced by ec2-to-s3 setup in [[02-ec2]])
