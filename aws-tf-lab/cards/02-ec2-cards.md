---
topic: 02-ec2
domain: resilient
related_note: 02-ec2
tags: [flashcards/ec2]
---

# Cards for [[02-ec2]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What are the main "ingredients" of an EC2 instance?
?
AMI (template), instance type (sizing), subnet (which determines VPC + AZ), security group(s) (stateful firewall), key pair (SSH access), EBS volumes (root + optional extras), optional user data (boot script), optional IAM instance profile (AWS API access), tags. The console launch wizard reflects exactly this list.

Is an AMI the same as an EBS snapshot?
?
No. For modern EBS-backed AMIs, the AMI is metadata + a reference to one or more EBS snapshots. The snapshots hold the disk data; the AMI wraps them with launchable metadata (kernel, architecture, virtualization-type). A snapshot on its own is not launchable; an AMI is.

What scope does an AMI live in?
?
Region. An `ami-…` ID is unique to one region. To use the same image in another region, `aws ec2 copy-image` — costs snapshot storage in the target region plus cross-region transfer. The #1 gotcha when hardcoding AMI IDs in multi-region Terraform.

When you stop an instance and start it again, what changes and what stays?
?
Stays: EBS root volume contents, instance ID, private IP, AMI ID, Elastic IP (if associated), additional EBS volumes. Changes: auto-assigned public IP (released, new one on start), instance store contents (gone — host may change). Always lost when stop OR terminate: instance store data.

`delete_on_termination` defaults — root vs additional volumes?
?
Root volume defaults to `true` (deleted with the instance). Additional EBS volumes default to `false` (survive termination, accrue storage charges, can be attached to another instance in the same AZ). Asymmetric — exam-frequent. Override per `root_block_device` / `ebs_block_device` block on `aws_instance`.

Why doesn't EC2 attach an IAM role directly?
?
EC2 attaches an instance profile — a thin container wrapping a role. The console silently creates an instance profile with the same name as the role; Terraform requires `aws_iam_instance_profile` explicitly, referenced from `aws_instance.iam_instance_profile`. Lambda, ECS tasks, etc. take a role directly — EC2 is the special case.

What's IMDSv2 and why does it matter?
?
Instance Metadata Service v2 — required on most modern AMIs. To query metadata you must first PUT `/latest/api/token` (gets a session token), then GET `/latest/meta-data/...` with the `X-aws-ec2-metadata-token: <token>` header. Purpose: defends against SSRF (most SSRF primitives only allow GET; tokens are TTL-limited). If you query without the token, IMDSv2 returns empty silently — easy to mistake for "no instance profile attached."

In Terraform, does changing `instance_type` on `aws_instance` force replace?
?
No — in-place update (`~`). The provider calls `StopInstance` → `ModifyInstanceAttribute` → `StartInstance`. ~1–3 min downtime; instance ID, EBS, EIP preserved; auto-assigned public IP changes; instance store dies. But `ami` IS ForceNew (`-/+`) — can't swap OS on a running instance. Always read the plan symbols, never assume.

How is `aws_subnets` (plural data source) different from `aws_subnet` (singular)?
?
`aws_subnets` returns a list/set of subnet IDs matching a filter, exposed as `.ids`. There is NO `.id` attribute. To pick one: `tolist(data.aws_subnets.X.ids)[0]`. `aws_subnet` returns full attributes for ONE subnet looked up by `id` or `filter`. Common pattern: use `aws_subnets` for the IDs in a VPC, then chain into `aws_subnet` per ID for details.

What's the difference between an auto-assigned public IP and an Elastic IP?
?
Auto-assigned: from AWS's public IPv4 pool, released on stop, new one on start (different IP). Elastic IP: allocated to your account, sticky across stop/start, movable between instances, soft limit 5/region. Both cost ~$0.005/hour since Feb 2024. For "I need a fixed IP" use EIP; for stateless instances behind an LB, auto-assigned is fine.

In `aws_vpc_security_group_ingress_rule`, what value does `ip_protocol` take?
?
`"tcp"`, `"udp"`, `"icmp"`, `"icmpv6"`, or `"-1"` (all). Does NOT take application-protocol names like `"ssh"` or `"http"` — those are just port-22-TCP and port-80-TCP. The AWS console *labels* the rule "SSH" once you set port 22 + TCP — friendly display, not API input.

How do you scope SSH access in a security group ingress rule safely?
?
Use your own public IP as the CIDR with a `/32` suffix (= "exactly this one IP"). Get it with `curl -s checkip.amazonaws.com`. Never `0.0.0.0/0` on port 22 — bots brute-force within minutes. Better real-world patterns: bastion host, AWS Systems Manager Session Manager (no SSH at all), or a VPN. Home IP rotates (ISP DHCP); use a variable so you can update it quickly.
