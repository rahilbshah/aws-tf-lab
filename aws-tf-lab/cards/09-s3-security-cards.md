---
topic: 09-s3-security
domain: secure
related_note: 09-s3-security
tags: [flashcards/s3]
---

# Cards for [[09-s3-security]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What are the three S3 access-control mechanisms, and which is identity- vs resource-based?
?
IAM policies — identity-based, attached to a user/group/role, answer "what can this principal do?". Bucket policies — resource-based, attached to the bucket, answer "who may act on this bucket?" (required for cross-account and anonymous/public access; max 20 KB). ACLs — legacy, per-object, pre-IAM; AWS recommends disabling them with BucketOwnerEnforced.

Why does Block Public Access have four separate settings?
?
Because a bucket can become public two ways (an ACL or a bucket policy) and for each you may want to block NEW ones or neutralise EXISTING ones: block_public_acls (new ACLs), ignore_public_acls (existing ACLs), block_public_policy (new policies), restrict_public_buckets (existing policies). All four on = the bucket cannot be made public.

Does a bucket policy override Block Public Access, or the other way round?
?
Block Public Access OVERRIDES the policy. A perfectly valid public bucket policy is simply ignored while BPA is on. It's a guardrail, not a permission — which is the point: a developer's mistake can't expose the bucket. It can be set per-bucket AND account-wide.

Name the four server-side encryption options and who holds the key.
?
SSE-S3 (AES256) — AWS manages the keys; the automatic base level for every bucket since 5 Jan 2023. SSE-KMS — your KMS key; key policy, rotation, and every use logged in CloudTrail. DSSE-KMS — two independent AES-256 layers (KMS data key + separate S3-managed key) for multi-layer compliance. SSE-C — YOU supply the key on every request; S3 encrypts but never stores it. (Plus client-side: you encrypt before upload, S3 never sees plaintext.) They're mutually exclusive per object.

What changed for SSE-C in April 2026?
?
SSE-C is now DISABLED BY DEFAULT for all new general-purpose buckets (and for existing buckets in accounts with no SSE-C objects). Applications needing it must deliberately re-enable it via the PutBucketEncryption API. Most course material predates this.

If you change a bucket's default encryption to SSE-KMS, what happens to objects already in it?
?
Nothing — default encryption applies only to NEW objects. Existing objects keep their previous encryption. To re-encrypt them you must rewrite them, typically with S3 Batch Operations → Copy (which writes them back into the same bucket under the new encryption).

What is an S3 Bucket Key and what does it save?
?
A short-lived, bucket-level data key that S3 uses instead of calling KMS for every single object operation. It can cut SSE-KMS request costs dramatically (up to ~99%). Enable with bucket_key_enabled = true on the encryption configuration.

Whose permissions does a presigned URL carry?
?
The permissions of whoever GENERATED it — not the recipient's. That's why it works for someone with no AWS account at all, and why generating one from an over-privileged role is dangerous. Anyone holding the link can use it until it expires: treat it as a bearer token.

What are the maximum expiry times for a presigned URL?
?
7 days (604800 seconds) when generated via the CLI or SDK; 12 hours via the S3 console. Also: if the URL was signed with temporary/role credentials, it stops working when those credentials expire, regardless of the requested expiry.

What does S3 Object Lock do, and what does it require?
?
It enforces WORM (write-once-read-many): an object VERSION cannot be deleted or overwritten, either for a fixed retention period or indefinitely via a legal hold. It requires S3 Versioning, and object_lock_enabled is a create-time bucket property (you can't casually toggle it on a live bucket).

GOVERNANCE vs COMPLIANCE retention mode?
?
GOVERNANCE: most users can't delete, but a principal with s3:BypassGovernanceRetention (plus the x-amz-bypass-governance-retention:true header) can override or shorten it. COMPLIANCE: NO ONE can overwrite or delete the version — including the AWS account root — and the retention can't be shortened. AWS states the only way out before expiry is closing the AWS account. Use GOVERNANCE for internal policy, COMPLIANCE for regulatory WORM (SEC 17a-4, FINRA).

What is a legal hold, and how does it differ from a retention period?
?
A legal hold gives the same protection but has NO expiry date — it stays until someone with s3:PutObjectLegalHold explicitly removes it. It's independent of any retention period: if retention expires while a legal hold is on, the object stays protected, and vice versa. Use it when you don't know how long immutability is needed (audit, litigation).

With Object Lock on, what happens if you delete an object with vs without a version id?
?
Permanent DELETE (with --version-id) → 403 AccessDenied; the locked version is protected. Simple DELETE (no version id) → 200 OK and S3 adds a DELETE MARKER; the object disappears from a normal listing but the locked version survives underneath. Object Lock protects a VERSION, not a name.

Who can enable MFA Delete on a bucket?
?
Only the AWS account ROOT user, with an MFA device, via the CLI. It cannot be done by an IAM user, through the console, or with Terraform. It protects permanently deleting object versions and disabling versioning.

How do you force all S3 requests to use HTTPS?
?
A bucket policy statement with Effect: Deny on s3:* for everyone, conditioned on Bool aws:SecureTransport = false. Because explicit Deny beats every Allow, this holds regardless of how permissive anyone's IAM policy is. Apply it to both the bucket ARN and bucket/* .

What does BucketOwnerEnforced object ownership do?
?
It disables ACLs entirely — they're ignored — and makes the bucket owner automatically own every object, including ones uploaded by another account. All access is then decided by policies alone, which is far easier to audit. It has been the default for new buckets since April 2023.

What does an S3 Access Point give you?
?
A named endpoint attached to a shared bucket, each with its own access policy and optionally restricted to a VPC. It lets many teams/apps share one bucket without a single enormous bucket policy — you give each consumer its own access point with just the permissions it needs.

For cross-account S3 access, what must be true?
?
BOTH sides must allow it: the bucket policy in the owning account must allow the other account's principal, AND that principal's IAM policy in their own account must allow the S3 call. Either one missing = AccessDenied. (And check Block Public Access isn't neutralising a wildcard-principal policy.)
