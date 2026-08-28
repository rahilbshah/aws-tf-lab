---
topic: 01-iam
domain: secure
related_note: 01-iam
tags: [flashcards/iam]
---

# Cards for [[01-iam]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What is IAM's policy evaluation order?
?
Implicit deny (default) → explicit Allow lifts the implicit deny → explicit Deny overrides everything. One explicit Deny anywhere = access denied. Order/source of policies, count of Allows vs Denies, and specificity all *don't matter*.

Which AWS region does IAM live in?
?
None — IAM is a global service. No region selection. (API endpoint runs from `us-east-1` infrastructure, but conceptually global.)

What's the credential difference between a User and a Role?
?
**User**: long-lived credentials (password for console, access key + secret for CLI/SDK). Sit on disk, in vaults, in CI. Leak = persistent risk until rotated.
**Role**: no permanent credentials. On assume, AWS STS issues temporary credentials (access key + secret + session token) that auto-expire — default 1h, configurable up to 12h.

What two policies does a Role need to be useful?
?
**Trust policy** (`assume_role_policy` on `aws_iam_role`) — declares WHO can assume the role (an AWS service, another account, a federated identity).
**Permissions policy** (attached separately via `aws_iam_role_policy_attachment` or inline) — declares WHAT the role can do once assumed. Either half missing = role is broken.

Why doesn't EC2 attach to a role directly?
?
EC2 attaches to an instance profile — a thin container that wraps an IAM role — so the EC2 metadata service can vend role credentials cleanly. The console silently creates an instance profile with the same name as the role; Terraform requires `aws_iam_instance_profile` explicitly, referenced from `aws_instance.iam_instance_profile`. Lambda/ECS take a role directly — EC2 is the special case.

In Terraform IAM, when do cross-references use `.name` vs `.arn`?
?
`.name` when the AWS API identifies the thing by name — principals (users, groups, roles) in management calls within your account. `.arn` when the thing might exist outside your account or needs globally unambiguous identification — policies (`policy_arn` arguments), since managed policies can be AWS-published or customer-owned. Plan/validate do not catch mistakes here because both are strings.

`aws_iam_user_group_membership` vs `aws_iam_group_membership` — what's the trap?
?
`aws_iam_user_group_membership` — user-side, additive ("put this user in these groups"); doesn't touch other members. Use 95% of the time. `aws_iam_group_membership` — group-side, exclusive ("these are the ONLY members"); anyone not listed is removed on next apply. Dangerous in shared environments.

`aws_iam_group_policy_attachment` vs `aws_iam_policy_attachment` — what's the difference?
?
`aws_iam_group_policy_attachment` (with prefix) manages one (group, policy) pair; safe. `aws_iam_policy_attachment` (no prefix) manages ALL attachments of one specific policy across users/groups/roles — if anyone else attaches that policy anywhere, Terraform rips it off on next apply. For exclusive management of all policies on one principal, use `aws_iam_{user,group,role}_policy_attachments_exclusive`.

In HCL, what's the difference between `aws_iam_group.developers` and `"aws_iam_group.developers"`?
?
Without quotes: an HCL reference expression, evaluated to a resource object (then dot into `.name`/`.arn`/`.id`). With quotes: a literal string passed through unchanged. Quoting a reference is the most common HCL beginner bug — both pass `validate`.

What do `+`, `-`, `~`, and `-/+` mean in a `terraform plan`?
?
`+` = create. `-` = destroy. `~` = in-place update (attribute changed without recreation). `-/+` = destroy and recreate, because an attribute has `ForceNew: true`; the plan annotates `# forces replacement` next to it. Reading the symbols beats memorizing which arguments force replacement.

Does changing `name` on `aws_iam_user` destroy and recreate?
?
No — `aws_iam_user.name` is in-place updatable in the v6 provider (calls AWS `UpdateUser` with `NewUserName`). But `aws_iam_policy.name` IS `ForceNew` — destroys and recreates. Different IAM resources behave differently; always read the plan. (Verified against provider source.)

What's the IAM policy `Version` field (e.g. `"2012-10-17"`)?
?
The IAM policy language version — always `"2012-10-17"` for modern IAM policies. It is NOT a free-form version field, it's the policy schema version. The `aws_iam_policy_document` data source adds it automatically.

A company has users and groups in on-premises Active Directory and wants them to access AWS without creating IAM users. What is the shape of the answer?
?
Federation, ending at a ROLE. Directory Service (AWS Managed Microsoft AD, or AD Connector to keep using on-prem AD) → IAM Identity Center → map AD GROUPS to permission sets, which become IAM roles in each account. Users get short-term credentials for console/CLI/SDK. The older equivalent is a SAML 2.0 identity provider in IAM plus roles trusting `Federated:` for `sts:AssumeRoleWithSAML`.

AWS Managed Microsoft AD vs AD Connector vs Simple AD?
?
Managed Microsoft AD — a REAL Microsoft AD run by AWS; supports trusts with on-prem, MFA, schema extensions, LDAPS, and RDS for SQL Server. AD Connector — a PROXY that forwards sign-ins to your on-prem domain controllers; stores no directory data in AWS and does no synchronization. Simple AD — Samba 4, AD-compatible not real AD; no trusts, no MFA, no schema extensions, no LDAPS, no RDS SQL Server.

Which Directory Service option stores no directory data in AWS?
?
AD Connector. It's a proxy — it forwards authentication requests to your existing on-premises domain controllers and synchronizes nothing. Pick it when the requirement is "keep managing users on-premises" or "don't store directory data in AWS."

What immediately disqualifies Simple AD in a question?
?
Any mention of trust relationships with another domain, MFA, schema extensions, LDAPS/secure LDAP, PowerShell AD cmdlets, FSMO role transfer, or RDS for SQL Server. Simple AD supports none of these — it's the low-cost basic option.

An application needs to log in to an RDS database using its IAM role. Which IAM action?
?
`rds-db:connect` — on a resource ARN of the form `arn:aws:rds-db:{region}:{account}:dbuser:{DbiResourceId}/{db-user}`. Note the `rds-db:` prefix is separate from `rds:`, which is the RDS management API (CreateDBInstance, DescribeDBInstances…). Granting `rds:*` does NOT let anything log in to a database.
