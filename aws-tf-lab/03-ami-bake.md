---
topic: 03-ami-bake
status: reference
exam: false
services: [Packer, EC2, AMI]
related: [02-ec2]
tags: [job-skill, packer]
---

# 03 – AMI Baking with Packer (job-skills side-quest)

> [!note] Not an SAA-C03 exam topic
> Packer doesn't appear on the exam. This note is a job-skills reference, so it skips the full §13 layered template (no flashcards/MCQs/traps) and carries `exam: false` so the mock-exam generator never pulls from it. Kept short on purpose.

## What Packer is

HashiCorp's tool for **building machine images** (AMIs, Docker images, VM images) as code. Same HCL syntax family as Terraform, same company. It launches a temporary instance from a base image, runs your provisioners over SSH, snapshots the result into a new image, and tears the temp instance down.

## The core idea: build artifacts vs manage infrastructure

| | **Packer** | **Terraform** |
|---|---|---|
| Job | Build images (artifacts) | Deploy & manage running infra |
| Lifecycle | Short-lived: launch → provision → snapshot → destroy temp | Long-lived: keeps state, manages updates |
| Output | An image (`ami-…`) | Running resources |
| Pipeline stage | Build/CI | Deploy/operate |
| State | Stateless | Stateful (`.tfstate`) |

**Production pattern: "Packer bakes, Terraform deploys."** Packer builds a tagged golden AMI on a schedule (CI, or when deps change); Terraform consumes the latest tagged AMI via `data "aws_ami"` and deploys many instances from it. Separation of concerns — image builds and infra deploys happen on different cadences.

## Bake-at-build vs install-at-boot (`user_data`)

| | Bake into AMI (Packer) | Install via `user_data` at boot |
|---|---|---|
| Boot time | ~30 sec | 2–5 min (`apt install` on every launch) |
| Reproducibility | High (fixed snapshot) | Depends on repos being up at boot |
| Iteration speed | Slow (rebuild AMI per change) | Fast (edit script) |
| External deps at boot | None | Package mirrors, network |

> [!tip] Production gap — why this matters with an Auto Scaling Group
> When an ASG scales out 5 instances under load, baked instances serve traffic in seconds; `user_data` instances each burn 3 min installing first. **Rule of thumb:** bake the stable layer (docker, git, awscli, runtime), boot-install only instance-specific config/secrets.

## Packer HCL anatomy

| Block | Purpose | Terraform analogue |
|---|---|---|
| `packer { required_plugins {} }` | Plugin + version pins | `terraform { required_providers {} }` |
| `data "amazon-ami" "<name>" {}` | Look up the base AMI to build on | `data "aws_ami"` (same filter syntax) |
| `source "amazon-ebs" "<name>" {}` | Defines the temp instance + the AMI to create (name, tags, snapshot_tags) | (no direct analogue) |
| `build { sources = [...] provisioner "shell" {} }` | Orchestrator: for each source, run these provisioners | (no direct analogue) |

- Reference shape inside `build`: `source.amazon-ebs.ubuntu` (i.e. `source.<builder>.<name>`).
- `ami_name` must be unique — use `formatdate("YYYY-MM-DD-hhmm", timestamp())` to datestamp each build (Packer refuses to overwrite an existing name).
- Tag **both** the AMI (`tags`) and the underlying snapshot (`snapshot_tags`) — otherwise the snapshot is untagged and cost-tracking is painful.
- A final `git --version && docker --version && aws --version` provisioner line is a free self-test: Packer fails the build on any non-zero exit, so a successful build *proves* the tools installed.

## Commands

```bash
packer init .        # download plugins (like terraform init)
packer fmt .         # auto-format
packer validate .    # schema/syntax check, no AWS calls — your safety net (no Packer IntelliSense in editors)
packer build .       # launch temp instance → provision → snapshot → AMI → terminate temp (~5 min)
```

**Editor note:** there is **no Packer language server**, so VSCode gives syntax highlighting (set language mode to **HCL**) but **no schema-aware autocomplete** like `terraform-ls` gives `.tf` files. Lean on `packer validate .` instead of inline hints.

## The Packer I wrote

Code: [`03-ami-bake/image.pkr.hcl`](../03-ami-bake/image.pkr.hcl)

Baked a golden Ubuntu 24.04 AMI with **git, docker.io, awscli** pre-installed:
- `data "amazon-ami"` looks up latest Canonical Ubuntu 24.04 noble (owner `099720109477`) — cleaner than the inline `source_ami_filter` alternative.
- `source "amazon-ebs" "ubuntu"` — `t3.micro` temp builder, datestamped `ami_name`, tags + snapshot_tags `{Project, BakedBy=packer, BaseAmi}`.
- `build` runs one shell provisioner: `apt install git docker.io unzip`, AWS CLI v2 via the **official installer** (Ubuntu 24.04 dropped `awscli` from apt — see [[02-ec2]]), `usermod -aG docker ubuntu` so the default user runs docker without sudo, then the version self-test.

Result (this build): `ami-0eb8b6bc66b38afcf`, snapshot `snap-0044e28129eba85b3`, state `available`. **Kept** (not destroyed) — it's the launch image for the ALB+ASG topic.

Non-obvious bits:
- Used a `data "amazon-ami"` block + `source_ami = data.amazon-ami.ubuntu.id` instead of an inline `source_ami_filter {}`. Both valid; the data source reads cleaner.
- `region` is duplicated in the data source and the source block — harmless; a `variable`/`local` would DRY it.

## Cleanup (when done with the AMI)

An AMI and its snapshot are **two separate things** — deleting one doesn't delete the other:
```bash
aws ec2 deregister-image --image-id ami-0eb8b6bc66b38afcf --region us-east-1
aws ec2 delete-snapshot   --snapshot-id snap-0044e28129eba85b3 --region us-east-1
```
Until then it costs ~$0.05/GB-month of snapshot storage (cents). Keep it for now — ALB+ASG needs it.

## 🔗 Docs

- [Packer AWS (amazon-ebs) builder](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs)
- [Packer `amazon-ami` data source](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/data-source/ami)
- [Packer shell provisioner](https://developer.hashicorp.com/packer/docs/provisioners/shell)
