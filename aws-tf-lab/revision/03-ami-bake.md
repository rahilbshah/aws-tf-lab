---
topic: 03-ami-bake
type: revision
source: 03-ami-bake
tags: [revision, generated]
---

# Revision — 03 – AMI Baking with Packer (job-skills side-quest)

> [!abstract] Night-before read · ~2 min · self-contained
> Everything you need is here — no need to jump back mid-revision.
> Full teaching explanations, Terraform and diagrams: **[[03-ami-bake]]**
> *Generated from the note by `_scripts/build_revision.py` — do not edit.*
## Worked examples

> [!example] Worked example — golden-image CI pipeline feeding an ASG
> A team runs a nightly (or on-dependency-change) pipeline: Packer bakes an Ubuntu image with the app runtime + agents (CloudWatch agent, SSM agent, the app's Docker image pre-pulled), tags it `Release=candidate`, and a smoke-test job launches an instance from it and hits a health endpoint. If green, the pipeline retags it `Release=stable`. Terraform's launch template uses `data "aws_ami"` filtered on `tag:Release=stable` (**not** `most_recent` alone — see failure mode), so an ASG **instance refresh** rolls the fleet onto the freshly-vetted image in seconds per instance, with no boot-time `apt install`. This is the [[02-ec2]] instance-profile + [[01-iam]] role model composed with immutable infrastructure: servers are never patched in place, they're replaced wholesale from a new image.
> The fully-managed AWS-native version of this whole pipeline is **EC2 Image Builder** (verified): recipes (base image + build components), scheduled builds, a **test stage that only distributes the image if tests pass**, multi-region distribution, cross-account sharing via **AWS RAM**, and AWS-managed **STIG hardening** components for compliance. Packer is the portable/multi-cloud choice; Image Builder is the zero-maintenance AWS-only choice.

> [!failure] Failure mode — `most_recent = true` silently ships an untested image
> The tempting `data "aws_ami"` filter is `most_recent = true` on `tag:BakedBy=packer`. The trap: the moment a new Packer build lands (even a broken or unvetted one), the *next* `terraform plan` sees a different AMI ID. On its own that's just a diff — but paired with an ASG **instance refresh** or a launch-template update, Terraform will **roll your entire fleet onto that brand-new image automatically**, before anyone has vetted it. One bad bake at 2 a.m. → a fleet-wide outage at the next apply.
> Fixes: (1) filter on a **promotion tag** you only set *after* tests pass (`tag:Release=stable`), so baking ≠ releasing; or (2) **pin the AMI ID explicitly** via a variable the pipeline sets after validation, making the image bump a reviewable, deliberate change rather than an implicit side effect of "latest wins."

> [!failure] Failure mode — AMI/snapshot sprawl (the silent cost leak)
> Every Packer build creates a new AMI **and** a backing EBS snapshot, and they are independent objects (deregistering the AMI leaves the snapshot behind — see Cleanup below). A nightly pipeline running for a year with no retention policy = 365 AMIs + 365 snapshots, most unused, each costing snapshot storage (~$0.05/GB-month) indefinitely. Because snapshots don't show up in the EC2 *instances* view, teams forget they exist until a cost review flags a growing EBS-snapshot line item. Fix: a retention policy (keep last N stable + deregister/delete the rest) automated with **Amazon Data Lifecycle Manager** or an EC2 Image Builder distribution retention setting — never leave AMI cleanup as a manual chore.
