---
topic: 01-iam
type: revision
source: 01-iam
tags: [revision, generated]
---

# Revision — 01 – IAM (Identity and Access Management)

> [!abstract] Night-before read · ~11 min · self-contained
> Everything you need is here — no need to jump back mid-revision.
> Full teaching explanations, Terraform and diagrams: **[[01-iam]]**
> *Generated from the note by `_scripts/build_revision.py` — do not edit.*
## The shape of it

> [!info] Exam TL;DR
> - **IAM is global, free, and always-on.** No region selection. Same identities and policies seen from every region.
> - **Four core objects:** User, Group, Role, Policy. Groups can't log in; only Users can.
> - **Explicit Deny always wins.** Evaluation: implicit deny (default) → explicit Allow lifts it → explicit Deny overrides everything. One Deny anywhere in any attached policy = no access. Order, count, and specificity all don't matter.
> - **Users have long-lived credentials** (password, access key). **Roles have none** — on assume, AWS STS issues temporary credentials (default 1h, max 12h). Prefer Roles + federation for both humans and services.
> - **Roles use two distinct policies:** *trust policy* (`assume_role_policy` — WHO can assume) + *permissions policy* (attached separately — WHAT can be done once assumed). Either half missing = role doesn't work.
> - **Roles reach past AWS APIs.** With **IAM database authentication** an EC2/Lambda role can log in to RDS with a 15-minute token instead of a password — the IAM action is `rds-db:connect` (note: *not* the `rds:` management prefix). See [[07-rds-aurora]].
> - **Existing corporate users?** Don't create IAM users — federate. **AD groups map to IAM roles** via IAM Identity Center (or SAML 2.0), backed by AWS Managed Microsoft AD or AD Connector.
> - **EC2 doesn't attach to a role directly** — it attaches to an *Instance Profile*, a thin wrapper around a role (see [[02-ec2]]). Console hides this; Terraform makes it explicit. (Lambda, ECS, etc. take roles directly.)

## Facts, limits & pricing

- **Global service** — no region picker. Same IAM seen from every region. (The IAM API endpoint historically lives in `us-east-1` infrastructure, but the concept and the data are global.)
- **Free** — no per-user, per-policy, or per-API-call charge. STS calls are free too. Only some advanced features (IAM Identity Center premium features, IAM Access Analyzer findings) have separate pricing.
- **Eventually consistent** — newly created users/roles/policies may take a few seconds to become globally visible. A `terraform apply` that creates a role and immediately tries to use it can race; usually a retry resolves it. Worth knowing for real-world AND exam scenarios.
- **Principal identification is by name; policy identification is by ARN.** Reason: principals only exist within your account (name is unambiguous in that scope); policies may live in the `aws` account namespace (AWS-managed, e.g. `arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess`) or your account namespace, so the full ARN with account ID is needed for disambiguation.
- **Inline vs managed policies:**
  - *Managed* — standalone, reusable, versioned (up to 5 versions retained, can roll back), attachable to many principals.
  - *Inline* — embedded directly on one principal; deleted when the principal is deleted; not reusable; no versioning.
- **`aws_iam_user.name` is in-place updatable** in the v6 provider (uses AWS `UpdateUser` API). **`aws_iam_policy.name` is NOT** — it has `ForceNew: true`, so renaming a policy destroys and recreates it (the policy ARN embeds the name, so AWS can't rename in place). **Lesson:** behavior is NOT consistent across the IAM resource family; read the plan.
- **Service quotas** (max users per account, max policies per principal, policy size limits, etc.) change over time. ⚠️ Don't memorize specific numbers — refer to the AWS service quotas page (linked in Docs).

## Comparisons

### User vs Role

|   | User | Role |
|---|---|---|
| Credentials | Long-lived (password and/or access key + secret) | None of its own; temporary credentials via STS on assume (default 1h, configurable to 12h) |
| "Owned" by | A specific identity (usually a human) | Nobody — a hat anyone allowed can wear |
| When to use | A specific human (legacy), a specific service account (legacy) | AWS services accessing other AWS services; cross-account access; federated humans; temporary privilege elevation |
| Modern best practice | **Avoid for humans** — prefer IAM Identity Center (federation → role) | Default for everything else |
| Leak risk | Until you rotate the long-lived key, attacker has access | Temporary credentials expire on their own (≤ 12h) |

### Inline vs Managed policy

|   | Inline | Managed (Customer- or AWS-) |
|---|---|---|
| Lifecycle | Lives and dies with the principal | Standalone resource; survives reattach |
| Reusability | One principal only | Attachable to many principals |
| Versioning | None | Up to 5 versions retained; can roll back |
| Use case | Truly one-off (a single role's bespoke permission) | Default; anything reusable |

### Trust policy vs Permissions policy (on a Role)

|   | Trust policy | Permissions policy |
|---|---|---|
| Lives on | The role itself (`assume_role_policy` argument on `aws_iam_role`) | Attached separately (`aws_iam_role_policy_attachment` for managed, `aws_iam_role_policy` for inline) |
| Answers | **Who is allowed to assume me?** | **What can I do once assumed?** |
| Without it | Nobody can assume the role | Role can be assumed but does nothing |
| Common values | `Service: ec2.amazonaws.com`, `Service: lambda.amazonaws.com`, `AWS: arn:aws:iam::<acct>:root` (cross-account), `Federated: <SAML/OIDC provider ARN>` | Standard policy JSON over S3, DynamoDB, etc. |

### Bringing existing corporate identities into AWS (Directory Service + federation)

The exam's phrasing is almost always *"we already have users/groups in on-premises Active Directory — give them AWS access **without creating IAM users**."* The answer is never "create IAM users"; it's federation, and AD groups get **mapped to IAM roles**.

| | **AWS Managed Microsoft AD** | **AD Connector** | **Simple AD** |
|---|---|---|---|
| What it is | a **real** Microsoft AD, run by AWS in your VPC | a **proxy** to your existing on-prem AD | Samba 4, AD-**compatible** (not real AD) |
| Stores directory data in AWS? | ✅ yes | ❌ **no** — forwards sign-in to your on-prem DCs, no sync | ✅ yes (standalone) |
| Trust with on-prem AD? | ✅ yes | n/a (it *is* your on-prem AD) | ❌ **not supported** |
| MFA | ✅ | ✅ (via your existing RADIUS) | ❌ |
| Schema extensions / LDAPS | ✅ | via on-prem | ❌ |
| RDS for SQL Server | ✅ | ❌ not compatible | ❌ not compatible |
| Pick it when | you need actual AD in the cloud, AD-aware apps, or a standalone AD | you *only* need on-prem users to sign in to AWS, no data in AWS | small, cheap, basic AD features / LDAP for Linux |

**How AD groups become AWS permissions.** Either route ends at a role:
- **IAM Identity Center** (the successor to AWS SSO, and the modern answer) connects to AD (or an external IdP), and you map **AD groups → permission sets**, which become IAM roles provisioned into each account. Users get short-term credentials for the console, CLI and SDK.
- **SAML 2.0 federation direct to IAM** — an IAM SAML identity provider plus roles whose trust policy trusts `Federated: <provider ARN>` for `sts:AssumeRoleWithSAML`. Older, more moving parts, still valid.

Either way the AD group is the unit of assignment and the IAM **role** is what actually carries the permissions — the same trust-policy mechanic as the EC2 instance profile and the GitHub OIDC example below, only the trusted principal differs.

> [!tip] Production gap
> For human access, **IAM Identity Center + your existing IdP** (Entra ID, Okta, or AWS Managed Microsoft AD) is the target state — no IAM users, no long-lived access keys, centrally revocable. IAM users survive in production mainly for break-glass and for a few legacy service accounts that can't assume a role.

## Worked examples

> [!example] Worked example — third-party auditor via cross-account role + ExternalId
> Acme Corp hires a cost-optimization vendor that needs read-only access to Acme's account. The vendor monitors many customers, so the trust must be scoped tightly:
> 1. The vendor provides their **AWS account ID** and a **unique customer identifier** — the *ExternalId*. Crucially, the vendor generates it (one per customer); it is *not* a secret, just unique (AWS treats it as viewable by anyone who can see the role).
> 2. Acme creates a role. Trust policy: `"Principal": {"AWS": "<vendor account ID>"}` **plus** `"Condition": {"StringEquals": {"sts:ExternalId": "<id>"}}`. Permissions policy: read-only (e.g. the AWS-managed `ReadOnlyAccess`, or scoped down to Cost Explorer/billing APIs).
> 3. Acme hands the vendor the role ARN; the vendor calls `sts:AssumeRole` with ARN + ExternalId and receives temporary credentials.
>
> In Terraform this is the exact `aws_iam_role` + `data.aws_iam_policy_document` pattern from `01-iam/`, with a `condition {}` block added inside the trust-policy `statement`.

> [!failure] Failure mode — confused deputy (the missing ExternalId)
> The vendor stores role ARNs for hundreds of customers. An attacker signs up as a *legitimate customer* of the vendor, then feeds the vendor **someone else's role ARN** (ARNs are guessable: account ID + role name). The vendor's system dutifully calls `AssumeRole` on the victim's role — and it *works*, because the victim's trust policy trusts the vendor's whole account. The vendor just became a **confused deputy**: tricked into using its legitimate access on behalf of the wrong principal.
> With one ExternalId per customer, the vendor attaches the *attacker's* ExternalId to the call, the victim's trust policy condition fails, and the assume is rejected with `AccessDenied`. This is why AWS docs say the third party must generate the ExternalId — if customers chose their own, an attacker could supply the victim's.

> [!example] Worked example — CI deploys with zero long-lived keys (GitHub Actions OIDC)
> The modern answer to "how does CI get AWS credentials?" — federation, not access keys in CI secrets:
> 1. Register GitHub's OIDC provider in IAM: URL `https://token.actions.githubusercontent.com`, audience `sts.amazonaws.com` (Terraform: `aws_iam_openid_connect_provider`).
> 2. Create a deploy role whose trust policy trusts `Federated: <provider ARN>` for action `sts:AssumeRoleWithWebIdentity`, with a condition on the token's `sub` claim, e.g. `repo:acme/platform:ref:refs/heads/main` — only workflows from *that repo, that branch* can assume it.
> 3. The workflow exchanges its short-lived OIDC token for temporary AWS credentials. Nothing stored, nothing to rotate, nothing to leak.
>
> Same mental model as the EC2 instance profile in [[02-ec2]] — a role with a trust policy — only the trusted principal differs (federated IdP vs `ec2.amazonaws.com`).

## Traps & failure modes

> [!warning] Trap — "the plan showed the policy was fine"
> It didn't, and it couldn't. Because the policy document interpolates `aws_s3_bucket.this.arn`, Terraform reports `data.aws_iam_policy_document.permissions will be read during apply` and the policy renders as `(known after apply)` — while the **trust** policy, which references nothing, renders in full. For any IAM policy built from references to resources created in the same apply, **the plan is not the artifact**. Read it after apply with `aws iam get-policy-version`, or simulate it.

> [!warning] Trap — Policy order or count matters
> It doesn't. IAM evaluation is order-independent and count-independent. One explicit Deny anywhere is sufficient.

> [!warning] Trap — Specificity wins
> No. IAM has no "more specific resource ARN wins" rule like NTFS ACLs. A plausible-sounding distractor.

> [!warning] Trap — Roles are only for AWS services
> Roles are also used for cross-account access, federated humans (SAML/OIDC → role), and temporary privilege elevation. Modern best practice prefers roles even for humans.

> [!warning] Trap — Long-lived access keys are fine for service-to-service
> Strongly discouraged — roles + temporary STS credentials are the secure default. Long-lived keys in env vars are an audit and leak risk.

> [!warning] Trap — IAM is regional
> No — global service. Frequent distractor; almost everything else AWS is regional.

> [!warning] Trap — Attach a role directly to an EC2 instance
> EC2 needs an instance profile in between (see [[02-ec2]]). Lambda doesn't.

> [!warning] Trap — All `name` arguments on IAM resources behave the same
> They don't — `aws_iam_user.name` is in-place updatable; `aws_iam_policy.name` forces destroy-and-recreate (ARN embeds the name). Always read the plan for `~` vs `-/+`.

> [!warning] Trap — `validate`/`plan` catch reference bugs (`.arn` vs `.name`, quoted strings)
> They don't — both shapes are type-valid strings. The errors surface only at apply (or silently produce wrong results).

> [!warning] Trap — "create IAM users for the on-premises staff"
> Any question that establishes users **already exist** in Active Directory (or any corporate IdP) and asks how to give them AWS access is testing federation. Creating IAM users duplicates the identity source, and you now have two places to deprovision someone — the exact failure the question is built around. Correct shape: directory (AWS Managed Microsoft AD / AD Connector) → **IAM Identity Center** → AD group mapped to a permission set → **IAM role**. "No new IAM users / no long-term credentials / use existing corporate credentials" are all the same trigger.

> [!warning] Trap — AD Connector vs AWS Managed Microsoft AD
> If the requirement is "**don't store directory data in AWS**" or "keep managing users on-premises with our existing tools," that's **AD Connector** — a proxy that forwards authentication and synchronizes nothing. If they need AD-aware workloads *in* AWS (RDS for SQL Server, .NET apps, EC2 Windows domain join with a standalone directory) or a **trust** with on-prem, that's **AWS Managed Microsoft AD**. **Simple AD** is the cheap one, and it's disqualified the moment a question mentions **trusts, MFA, schema extensions, LDAPS, or RDS SQL Server** — it supports none of them.

> [!warning] Trap — `rds:` vs `rds-db:` for database login
> Giving an application `rds:*` does **not** let it log in to a database — that's the RDS *management* API (create/describe/modify instances). Logging in with IAM auth requires `rds-db:connect` on an `arn:aws:rds-db:…:dbuser:…` resource. See [[07-rds-aurora]].
