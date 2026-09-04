---
topic: 03-ami-bake
status: reference
exam: false
services: [Packer, EC2, AMI]
related: [02-ec2]
tags: [job-skill, packer]
---

# 03 – AMI Baking with Packer (job-skills side-quest)

Packer is the tool that makes an AMI. This note is the job-skills companion to [[02-ec2]]: how a server image gets built once, deliberately, instead of being reassembled on every single boot.

> [!note] Not an SAA-C03 exam topic
> Packer doesn't appear on the exam. This note is a job-skills reference, so it skips the full §13 layered template (no flashcards/MCQs/traps) and carries `exam: false` so the mock-exam generator never pulls from it. Kept short on purpose.

## What problem does this solve?

A server needs software on it. Git, Docker, the AWS CLI, your app's runtime. Something has to put them there.

The obvious way is to install them while the machine boots. You hand EC2 a startup script — `user_data` — and every new instance runs `apt install` on its way up. It works. It is also the same work, repeated forever, once per instance.

Two costs come with that. The first is time: installing at boot takes 2–5 minutes, against roughly 30 seconds for a machine that already has everything. The second is fragility: at boot the instance has to reach package mirrors over the network. If a repo is down or the network isn't there, the launch that worked yesterday fails today.

Packer flips the order. Do the install **once**, at build time, and take a picture of the finished disk. Every instance afterwards launches from that picture with the software already on it — nothing to download, no mirrors to depend on, no external dependencies at boot.

It's HashiCorp's tool, from the same company and the same HCL syntax family as Terraform, and it builds machine images generally: AMIs, Docker images, VM images.

> In one line: install once at build time and snapshot the result, instead of re-installing on every boot.

## How it actually works

### The build is a throwaway instance

There is no magic image factory. Packer does exactly what you would do by hand, then cleans up after itself:

1. Launch a **temporary** EC2 instance from a base image — here a `t3.micro` off the latest Canonical Ubuntu 24.04.
2. Connect to it over SSH and run your provisioners — the shell script that installs git, docker.io, the AWS CLI.
3. Snapshot the resulting disk into a new AMI.
4. Terminate the temporary instance.

About five minutes end to end.

That shape explains every difference from Terraform. Terraform keeps a state file because it owns resources that go on existing and need managing. Packer's only lasting output is the image; the instance it borrowed is gone. So there is nothing to track, and Packer is stateless. It belongs to the build stage of a pipeline, Terraform to the deploy stage.

Two build-time details fall straight out of "it's a real instance running a real script":

- Ending the provisioner with `git --version && docker --version && aws --version` is a free self-test. Packer fails the build on any non-zero exit, so a build that *succeeds* has proved the tools installed.
- `ami_name` must be unique — Packer refuses to overwrite an existing name. That is why builds datestamp themselves with `formatdate("YYYY-MM-DD-hhmm", timestamp())`.

> In one line: Packer launches a temp instance, provisions it over SSH, snapshots it, and destroys it — the image is the only thing that survives.

### Bake at build, or install at boot

Baking is not simply better. The two options trade the same cost around, and which one hurts depends on what you are doing.

Baking is slow to iterate: change one package and you rebuild the whole AMI. Editing a `user_data` script is instant. That is the one row of the comparison where boot-install comes out ahead — everywhere else (boot time, reproducibility, boot-time dependencies) baking does.

Then look at the same choice under an Auto Scaling Group. Load spikes, the ASG launches five instances. Baked ones serve traffic in seconds. `user_data` ones each spend about 3 minutes running `apt install` before they are any use — precisely during the window you needed the capacity for.

Hence the rule of thumb: **bake the stable layer** (docker, git, awscli, the runtime), **boot-install only the instance-specific config and secrets**. The stable layer changes rarely, so a slow rebuild costs you almost nothing; the per-instance config differs by instance, so it could never have lived in a shared image anyway.

> In one line: bake what rarely changes, boot-install what differs per instance.

### Why "use the latest image" is the dangerous setting

This is the counter-intuitive one. Terraform's `data "aws_ami"` offers `most_recent = true`, and taking the newest image sounds obviously right.

Trace it through. Packer bakes nightly and tags each AMI `BakedBy=packer`. Terraform filters on that tag with `most_recent = true`. A build lands at 2 a.m. — broken, unvetted, nobody has looked at it yet. The next `terraform plan` now resolves a *different* AMI ID. On its own that is only a diff. Paired with an ASG **instance refresh** or a launch-template update, it is Terraform rolling your entire fleet onto that untested image automatically.

The defect isn't `most_recent`. It is that baking an image and releasing it have become the same event. Separate them and the danger goes away:

- Tag on build, then set a **promotion tag** such as `Release=stable` only *after* tests pass, and filter on the promotion tag instead. Baking no longer implies releasing.
- Or **pin the AMI ID** in a variable the pipeline sets after validation, so bumping the image is a reviewable, deliberate change rather than a side effect of "latest wins."

That is also the shape of a healthy pipeline: bake → tag `Release=candidate` → smoke-test (launch one instance, hit a health endpoint) → retag `Release=stable` → let the instance refresh roll the fleet. Servers are never patched in place; they are replaced wholesale from a new image.

> In one line: filter on a tag you set *after* testing, not on whichever image happens to be newest.

### An AMI and its snapshot are two separate objects

Deleting one does not delete the other. Deregister the AMI and the backing EBS snapshot stays behind, still billing. Cleanup takes two calls: `aws ec2 deregister-image` **and** `aws ec2 delete-snapshot`.

What makes this a silent leak is visibility. Snapshots don't appear in the EC2 *instances* view, so nothing ever reminds you they're there. Every Packer build creates one AMI plus one snapshot, so a nightly pipeline with no retention policy leaves 365 AMIs and 365 snapshots after a year, most unused, each charging snapshot storage (~$0.05/GB-month) indefinitely. Teams typically discover this when a cost review flags a growing EBS-snapshot line item.

It is also why you tag **both** — `tags` on the AMI and `snapshot_tags` on the snapshot. An untagged snapshot is exactly the one nobody can attribute six months later.

The fix is a retention policy — keep the last N stable images, deregister and delete the rest — automated with **Amazon Data Lifecycle Manager**, rather than left as a manual chore.

> In one line: every build leaves two billable objects behind, and only one of them is visible.

## The core idea: build artifacts vs manage infrastructure

| | **Packer** | **Terraform** |
|---|---|---|
| Job | Build images (artifacts) | Deploy & manage running infra |
| Lifecycle | Short-lived: launch → provision → snapshot → destroy temp | Long-lived: keeps state, manages updates |
| Output | An image (`ami-…`) | Running resources |
| Pipeline stage | Build/CI | Deploy/operate |
| State | Stateless | Stateful (`.tfstate`) |

**Production pattern: "Packer bakes, Terraform deploys."** Packer builds a tagged golden AMI on a schedule (CI, or when deps change); Terraform consumes the latest tagged AMI via `data "aws_ami"` and deploys many instances from it. Separation of concerns — image builds and infra deploys happen on different cadences.

## Bake-at-build vs install-at-boot (user_data)

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

## Worked examples

> [!example] Worked example — golden-image CI pipeline feeding an ASG
> A team runs a nightly (or on-dependency-change) pipeline: Packer bakes an Ubuntu image with the app runtime + agents (CloudWatch agent, SSM agent, the app's Docker image pre-pulled), tags it `Release=candidate`, and a smoke-test job launches an instance from it and hits a health endpoint. If green, the pipeline retags it `Release=stable`. Terraform's launch template uses `data "aws_ami"` filtered on `tag:Release=stable` (**not** `most_recent` alone — see failure mode), so an ASG **instance refresh** rolls the fleet onto the freshly-vetted image in seconds per instance, with no boot-time `apt install`. This is the [[02-ec2]] instance-profile + [[01-iam]] role model composed with immutable infrastructure: servers are never patched in place, they're replaced wholesale from a new image.
> The fully-managed AWS-native version of this whole pipeline is **EC2 Image Builder** (verified): recipes (base image + build components), scheduled builds, a **test stage that only distributes the image if tests pass**, multi-region distribution, cross-account sharing via **AWS RAM**, and AWS-managed **STIG hardening** components for compliance. Packer is the portable/multi-cloud choice; Image Builder is the zero-maintenance AWS-only choice.

> [!failure] Failure mode — `most_recent = true` silently ships an untested image
> The tempting `data "aws_ami"` filter is `most_recent = true` on `tag:BakedBy=packer`. The trap: the moment a new Packer build lands (even a broken or unvetted one), the *next* `terraform plan` sees a different AMI ID. On its own that's just a diff — but paired with an ASG **instance refresh** or a launch-template update, Terraform will **roll your entire fleet onto that brand-new image automatically**, before anyone has vetted it. One bad bake at 2 a.m. → a fleet-wide outage at the next apply.
> Fixes: (1) filter on a **promotion tag** you only set *after* tests pass (`tag:Release=stable`), so baking ≠ releasing; or (2) **pin the AMI ID explicitly** via a variable the pipeline sets after validation, making the image bump a reviewable, deliberate change rather than an implicit side effect of "latest wins."

> [!failure] Failure mode — AMI/snapshot sprawl (the silent cost leak)
> Every Packer build creates a new AMI **and** a backing EBS snapshot, and they are independent objects (deregistering the AMI leaves the snapshot behind — see Cleanup below). A nightly pipeline running for a year with no retention policy = 365 AMIs + 365 snapshots, most unused, each costing snapshot storage (~$0.05/GB-month) indefinitely. Because snapshots don't show up in the EC2 *instances* view, teams forget they exist until a cost review flags a growing EBS-snapshot line item. Fix: a retention policy (keep last N stable + deregister/delete the rest) automated with **Amazon Data Lifecycle Manager** or an EC2 Image Builder distribution retention setting — never leave AMI cleanup as a manual chore.

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
- [EC2 Image Builder — what is it](https://docs.aws.amazon.com/imagebuilder/latest/userguide/what-is-image-builder.html) — managed golden-image pipelines, test-before-distribute, STIG components; verified 2026-06
- [Terraform `aws_ami` data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) — `most_recent` / `filter` behaviour behind the failure mode above
