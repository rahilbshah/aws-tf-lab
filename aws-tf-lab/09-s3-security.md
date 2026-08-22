---
topic: 09-s3-security
domain: secure
status: reviewed
services: [S3, KMS]
related: [09-s3, 09-s3-intro, 09-s3-advanced, 01-iam]
cards: cards/09-s3-security-cards
tags: [topic, domain/secure]
---

# 09.3 – S3 Security (access, encryption, immutability)

Who can reach an object, how it's encrypted, and how to make it undeletable. The largest exam domain (Secure, 30%) leans on this heavily. Part of [[09-s3]].

> [!info] Exam TL;DR
> - **Three access mechanisms:** **IAM policies** (identity-based — "what may *this principal* do?"), **bucket policies** (resource-based — "who may touch *this bucket*?"), **ACLs** (legacy, now discouraged — disable with `BucketOwnerEnforced`).
> - **Block Public Access = 4 settings** (new/existing × ACL/policy). It **overrides policy** — a valid public policy simply won't take effect. Settable per-bucket **and account-wide**.
> - **Encryption at rest:** **SSE-S3** (AWS keys, AES-256, the automatic default since Jan 2023) · **SSE-KMS** (your KMS key, CloudTrail-audited) · **DSSE-KMS** (two independent AES-256 layers) · **SSE-C** (you supply the key per request) · **client-side** (encrypt before upload). ⚠️ **SSE-C is disabled by default on new buckets since April 2026.**
> - **Changing default encryption does NOT re-encrypt existing objects** — use **S3 Batch Operations Copy**.
> - **Presigned URL** carries the **permissions of whoever generated it**, is time-limited, and works for **anyone holding the link**. Max **7 days** via CLI/SDK, **12 hours** via console.
> - **Object Lock = WORM.** **GOVERNANCE** = overridable with `s3:BypassGovernanceRetention`; **COMPLIANCE** = nobody can delete, *including root*. **Legal hold** = no expiry, removed explicitly. Requires **versioning**.
> - **MFA Delete** can only be configured by the **root account** with an MFA device — not via IAM users, not via Terraform.

## Concept (plain English)

S3 objects are private by default; everything here is about deliberately widening or narrowing that. Access is decided by policies — an **IAM policy** attached to a user/role saying what they may do, and a **bucket policy** attached to the bucket saying who may touch it. (ACLs are the old per-object mechanism and should simply be turned off.) On top of those sits **Block Public Access**, a guardrail that ignores any policy that would make the bucket public — so a mistake can't expose you. Encryption is orthogonal: everything is encrypted at rest automatically, and the choice is really *who holds the key* and *how auditable that is*. Finally, **Object Lock** answers a different question — not "who can read this?" but "can this be deleted at all?" — which is what regulators and ransomware defence care about.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| Bucket policy | `aws_s3_bucket_policy` + `data.aws_iam_policy_document` | Resource-based. Explicit `Deny` beats any Allow ([[01-iam]]). |
| Block Public Access | `aws_s3_bucket_public_access_block` | All four `true` for normal buckets. |
| Account-wide BPA | `aws_s3_account_public_access_block` | The recommended account default. |
| Disable ACLs | `aws_s3_bucket_ownership_controls` | `object_ownership = "BucketOwnerEnforced"`. |
| Default encryption | `aws_s3_bucket_server_side_encryption_configuration` | `AES256` (SSE-S3) or `aws:kms` (+ `bucket_key_enabled`). |
| KMS key | `aws_kms_key` + `aws_kms_alias` | Destroy only *schedules* deletion (7–30 days). |
| Object Lock (create-time) | `object_lock_enabled` on `aws_s3_bucket` | Forces a new bucket if changed. Needs versioning. |
| Object Lock retention | `aws_s3_bucket_object_lock_configuration` | `mode` GOVERNANCE/COMPLIANCE + `days`/`years`. |
| Presigned URL | **none** — runtime, not infrastructure | `aws s3 presign …` / SDK. |
| MFA Delete | **none** — root + MFA via CLI only | Cannot be Terraformed. |
| Access Point | `aws_s3_access_point` | Named entry point with its own policy, for shared buckets. |

## Architecture diagram

```mermaid
flowchart TB
    REQ[Request for an object] --> BPA{Block Public Access}
    BPA -->|blocks public paths| EVAL[Policy evaluation]
    EVAL --> IAM[IAM policy<br/>identity-based]
    EVAL --> BP[Bucket policy<br/>resource-based]
    IAM --> DEC{explicit Deny?<br/>then Allow?}
    BP --> DEC
    DEC -->|allowed| ENC[Encryption layer]
    DEC -->|denied| NO[403]
    ENC --> OL{Object Lock?}
    OL -->|retention / legal hold| WORM[Cannot delete the version]
    OL -->|none| OK[Read / write]
```

## Key facts, limits & pricing

### Access control
- **IAM policy** = attached to a *principal*, answers "what can this user/role do?" Use for your own account's identities.
- **Bucket policy** = attached to the *bucket*, answers "who may act on this bucket?" Required for **cross-account** access and for **anonymous/public** access. Max size **20 KB**.
- **ACLs** = legacy, per-object, pre-IAM. AWS now recommends disabling them; **`BucketOwnerEnforced`** ignores ACLs entirely and makes the bucket owner own every object — the default for buckets created since April 2023.
- **Evaluation** follows the [[01-iam]] rule: explicit **Deny** > explicit **Allow** > implicit deny. For **cross-account**, the request must be allowed by **both** the caller's IAM policy *and* the bucket policy.
- **Access Points** — named endpoints on a shared bucket, each with its own policy and optional VPC restriction. Simplifies "one bucket, many teams" without one giant bucket policy.

### Block Public Access — the four settings
| Setting | Blocks |
|---|---|
| `block_public_acls` | **New** public ACLs |
| `ignore_public_acls` | **Existing** public ACLs |
| `block_public_policy` | **New** public bucket policies |
| `restrict_public_buckets` | **Existing** public policies |

Two ways to become public (ACL, policy) × two timings (new, existing). All four on = the bucket cannot be made public even by a valid policy. Available at **bucket** and **account** level; account level wins.

### Encryption at rest (verified 2026-08)
| Option | Who holds/manages the key | Notes |
|---|---|---|
| **SSE-S3** (`AES256`) | AWS | **The automatic base level for every bucket since 5 Jan 2023.** Free, no audit trail of key use. |
| **SSE-KMS** (`aws:kms`) | You, in KMS | Key policy, rotation, and **every use logged in CloudTrail**. KMS request costs → use **S3 Bucket Keys**. |
| **DSSE-KMS** | You, in KMS | **Two independent AES-256 layers** (KMS data key + separate S3-managed key) for multi-layer compliance mandates. |
| **SSE-C** | **You** — supplied on every request | S3 encrypts/decrypts but never stores your key. ⚠️ **Disabled by default on all new general-purpose buckets since April 2026** — must be deliberately re-enabled via `PutBucketEncryption`. |
| **Client-side** | You, before upload | S3 never sees plaintext or the key. Maximum control, all key management is yours. |

- The four server-side options are **mutually exclusive** per object.
- **Default encryption may be SSE-S3, SSE-KMS or DSSE-KMS — not SSE-C.**
- **Changing the default does not re-encrypt existing objects.** Re-encrypt with **S3 Batch Operations → Copy**.
- **S3 Bucket Keys** — a short-lived bucket-level data key that cuts SSE-KMS request calls (and cost) dramatically.
- **In transit:** enforce TLS with a bucket policy denying `aws:SecureTransport = false`.

### Presigned URLs
- Grants **time-limited** access to a private object using **the credentials of whoever generated it** — the URL inherits *their* permissions, not the recipient's.
- **Anyone holding the link can use it** until it expires. It is a bearer token; treat it like one.
- Max expiry: **7 days (604800s)** via CLI/SDK, **12 hours** via the console.
- If signed with **temporary/role credentials**, it dies when those credentials expire, regardless of `--expires-in`.
- Works for **uploads** too (presigned `PUT`), which is the standard "let a browser upload directly to S3" pattern.

### Object Lock (WORM) — verified 2026-08
- **Requires versioning**; locks a specific object **version**. `object_lock_enabled` is a **create-time** bucket property.
- **Retention period** — fixed "retain until" date. Can be **extended**, never shortened.
- **Legal hold** — same protection, **no expiry**, independent of retention, removed explicitly (`s3:PutObjectLegalHold`).
- **GOVERNANCE mode** — overridable by a principal with **`s3:BypassGovernanceRetention`** plus the `x-amz-bypass-governance-retention:true` header.
- **COMPLIANCE mode** — *"a protected object version can't be overwritten or deleted by any user, including the root user"*; AWS states the only way out before expiry is **closing the AWS account**.
- **Deletes behave differently** (exam-critical): a **permanent** `DELETE` (with a version id) → **403 AccessDenied**; a **simple** `DELETE` (no version id) → **200 OK and a delete marker**. The locked version survives underneath — the object is hidden, not destroyed.

### MFA Delete
- Requires the **root** account with an MFA device, configured via CLI. **Not** possible from an IAM user, the console, or Terraform.
- Protects permanent version deletion and disabling versioning. Rare in practice; exam-relevant precisely because of the root-only constraint.

## Comparisons

### IAM policy vs bucket policy vs ACL

|   | IAM policy | Bucket policy | ACL (legacy) |
|---|---|---|---|
| Attached to | A user/group/role | The bucket | Bucket or object |
| Answers | "What can this principal do?" | "Who can touch this resource?" | "Who can read/write this object?" |
| Cross-account | Needs the resource side too | **Yes — the usual mechanism** | Yes, but discouraged |
| Anonymous/public | No | **Yes** | Yes |
| Recommended | ✅ | ✅ | ❌ disable via `BucketOwnerEnforced` |

### GOVERNANCE vs COMPLIANCE

|   | GOVERNANCE | COMPLIANCE |
|---|---|---|
| Who can delete early | Anyone with `s3:BypassGovernanceRetention` | **Nobody — including root** |
| Retention can be shortened | Yes (with bypass) | **No** |
| Use for | Internal policy, testing settings first | Regulatory WORM (SEC 17a-4, FINRA) |
| Escape hatch | The bypass permission | Close the AWS account |

## Worked examples

> [!example] Worked example — the bucket that cannot leak
> A data bucket must never be public, must never accept plaintext traffic, and must never hold an unencrypted object. Three independent layers do it, and none relies on the others: **(1) Block Public Access**, all four on, so any public policy is inert regardless of what a developer writes. **(2)** A bucket policy that **denies** `s3:*` when `aws:SecureTransport = false`, so HTTP requests fail before anything else is considered. **(3)** A bucket policy that **denies** `s3:PutObject` when `s3:x-amz-server-side-encryption != aws:kms`, so an unencrypted upload is rejected even from an admin. Plus `BucketOwnerEnforced` so no ACL can quietly grant access. Built in `09-s3/security.tf` — and note the leverage: these are **Deny** statements, so they hold no matter how generous someone's IAM policy is.

> [!failure] Failure mode — "the bucket policy grants access, so cross-account works"
> A partner account is given `s3:GetObject` in your bucket policy and still gets `AccessDenied`. Cross-account access needs **both sides**: your bucket policy must allow their principal **and** their IAM policy must allow the call. Either one missing = denied. A second, sneakier version: the bucket policy is right, but **Block Public Access → `restrict_public_buckets`** is neutralising a policy that names a wildcard principal. Debug order: is it a *public* grant (BPA will kill it) or a *named-principal* grant (BPA doesn't apply, so check the other account's IAM).

> [!failure] Failure mode — Object Lock in COMPLIANCE mode on a test bucket
> Someone enables Object Lock with **COMPLIANCE** mode and a 1-year retention "to see how it works", then uploads files. Those objects **cannot be deleted by anyone, including the account root**, for a year — and the bucket cannot be deleted while they exist. AWS's documented escape is *closing the AWS account*. In this lab we deliberately used **GOVERNANCE, 1 day**, which teaches the same mechanics and stays reversible. Never demo COMPLIANCE mode on an account you intend to keep.

> [!example] Worked example — sharing one private object without giving away credentials
> A user needs to download one report from a private bucket. Options that are *wrong*: making the bucket public (exposes everything), creating an IAM user for them (a permanent identity for a one-off), or emailing the file (no audit, no revocation). The right answer is a **presigned URL**: `aws s3 presign s3://bucket/report.pdf --expires-in 3600` produces a link that works for one hour, for that one object, carrying *your* permissions. The trade-off to state out loud: it's a **bearer token** — anyone who gets the link has it until expiry, so keep the window short.

## The Terraform I wrote

Code: [`09-s3/security.tf`](../09-s3/security.tf) (secure-by-default bucket) + [`09-s3/objectlock.tf`](../09-s3/objectlock.tf) (WORM bucket).

*(Written collaboratively — reviewed, applied and verified by me; the exam value here is conceptual rather than in the HCL.)*

- **Secure bucket:** Block Public Access ×4, `BucketOwnerEnforced`, customer-managed KMS key + default SSE-KMS with `bucket_key_enabled`, versioning, and a bucket policy of pure **Deny**s (non-TLS, non-SSE-KMS uploads). Verified live: `aws s3 cp` succeeded and `head-object` showed `aws:kms`; the same upload with `--sse AES256` was **denied** by the policy.
- **Object Lock bucket:** `object_lock_enabled` at create time, versioning, GOVERNANCE default retention of 1 day. Verified the delete asymmetry — permanent delete (`--version-id`) → **403**, simple `rm` → **200 + delete marker** with the version intact underneath.

Non-obvious things:
- `object_lock_enabled` is **create-time**; it can't be toggled on a live bucket in Terraform without replacement.
- A KMS customer-managed key costs ~$1/month and `terraform destroy` only **schedules** deletion (7-day minimum) — by design, so you can't destroy the key that decrypts your data.
- Presigned URLs and MFA Delete have **no Terraform surface at all** — the first is runtime, the second is root-only.

> [!warning] Trap — Block Public Access can be overridden by a bucket policy
> Backwards. **BPA overrides the policy.** A perfectly valid public bucket policy is simply ignored while BPA is on. That's the point — it's a guardrail, not a permission.

> [!warning] Trap — enabling default encryption encrypts what's already there
> It doesn't. Default encryption applies to **new** objects only. Existing objects keep their previous encryption until you rewrite them — **S3 Batch Operations → Copy**.

> [!warning] Trap — a presigned URL uses the recipient's permissions
> It uses **the generator's**. That's why it works for someone with no AWS account at all — and why generating one from an over-privileged role is dangerous.

> [!warning] Trap — Object Lock stops the object being deleted
> It stops that **version** being deleted. A simple `DELETE` still returns **200 OK** and adds a **delete marker**, hiding the object. Nothing was destroyed, but "it disappeared" panic is real.

> [!warning] Trap — MFA Delete can be set up like any other bucket setting
> Only the **root account** with an MFA device can enable it, via CLI. Not IAM users, not the console, not Terraform.

> [!example]- Recreate-from-memory drill
> Build a bucket that: blocks all public access, disables ACLs, encrypts by default with a KMS key, refuses non-HTTPS requests, and refuses any upload that isn't SSE-KMS. Then prove the last one by uploading with `--sse AES256` and getting denied. Separately, build an Object Lock bucket in GOVERNANCE mode and demonstrate that a permanent delete fails while a simple delete adds a marker.
> > [!success]- Reference solution
> > `09-s3/security.tf` + `09-s3/objectlock.tf`. Key points: all four BPA flags, `BucketOwnerEnforced`, two Deny statements (`aws:SecureTransport`, `s3:x-amz-server-side-encryption`), `depends_on` the BPA before the policy, `object_lock_enabled` at create time with versioning.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **The four Block Public Access settings** — why four (new/existing × ACL/policy), and that BPA **overrides** policy rather than the other way round.
- [ ] **Which encryption option means what** — especially **DSSE-KMS** (two layers) and that **SSE-C is now off by default (April 2026)**.
- [ ] **Default encryption doesn't touch existing objects** — needs S3 Batch Operations Copy.
- [ ] **Presigned URLs carry the generator's permissions**, are bearer tokens, max 7 days CLI / 12 hours console.
- [ ] **Object Lock delete asymmetry** — permanent delete 403, simple delete 200 + delete marker.
- [ ] **COMPLIANCE mode is irreversible even for root** — never demo it on a real account.
- [ ] **MFA Delete is root-only**, no Terraform path.

## 🔗 Docs

- [Server-side encryption overview](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html) — the four SSE options, SSE-S3 default since Jan 2023, **SSE-C disabled by default April 2026**; verified 2026-08
- [Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html) — WORM, GOVERNANCE vs COMPLIANCE, legal holds, delete behaviour; verified 2026-08
- [Sharing objects with presigned URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ShareObjectPreSignedURL.html) — generator's credentials, 7-day CLI / 12-hour console limits; verified 2026-08
- [Blocking public access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [Bucket policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-policies.html) / [Object Ownership](https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html)
- [Terraform `aws_s3_bucket_public_access_block`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) / [`aws_s3_bucket_object_lock_configuration`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration)

---
**Cards for this topic:** [[cards/09-s3-security-cards]]
