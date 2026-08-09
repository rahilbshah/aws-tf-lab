---
topic: 09-s3-intro
domain: performance
related_note: 09-s3-intro
tags: [flashcards/s3]
---

# Cards for [[09-s3-intro]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

In S3, what is a "key"?
?
The object's full name/path within the bucket — e.g. `photos/cat.jpg` is one key, not a folder plus a file. Bucket + key uniquely identifies an object. The leading part (`photos/`) is called a PREFIX. (Not an encryption key.)

Is S3 hierarchical, and what are console "folders"?
?
No — S3 is a FLAT key→object map. There is no real directory tree. The console fakes folders by splitting keys on `/`. You emulate directories by listing objects with a prefix.

Is the S3 bucket namespace global or regional?
?
Bucket NAMES are globally unique across ALL AWS accounts (no two accounts can have the same name). The bucket itself is a REGIONAL resource that lives in one region.

What durability is S3 designed for, and how does it achieve it?
?
99.999999999% — eleven nines — for EVERY storage class. It stores objects redundantly across at least 3 Availability Zones (except the One Zone classes, which use 1 AZ).

Durability vs availability in S3 — what's the difference and which varies by class?
?
Durability = won't lose the data (11 nines, same for all classes). Availability = can you reach it right now, and it DOES vary: S3 Standard 99.99%, Standard-IA / Intelligent-Tiering / Glacier Instant 99.9%, One Zone-IA 99.5%, Glacier Flexible & Deep Archive 99.99% after restore.

Name the S3 storage classes from most-frequent to most-archival access.
?
S3 Standard → S3 Intelligent-Tiering → S3 Standard-IA → S3 One Zone-IA → S3 Glacier Instant Retrieval → S3 Glacier Flexible Retrieval → S3 Glacier Deep Archive. (Plus S3 Express One Zone for single-digit-ms latency.)

What are the minimum storage durations per storage class?
?
Standard and Intelligent-Tiering: none. Standard-IA and One Zone-IA: 30 days. Glacier Instant Retrieval and Glacier Flexible Retrieval: 90 days. Glacier Deep Archive: 180 days. Delete before the minimum and you're still billed for the full period — a classic cost trap.

What's the catch with S3 One Zone-IA?
?
It stores data in only ONE Availability Zone. It's as durable as Standard-IA on paper (11 nines) and ~20% cheaper, but if that AZ is physically destroyed the data is GONE, and availability is only 99.5%. Use it only for re-creatable data (thumbnails, derived files, replica copies) — never the only copy.

Which Glacier class gives millisecond retrieval?
?
S3 Glacier Instant Retrieval — archive pricing with millisecond access, no restore job. Glacier Flexible Retrieval takes minutes to hours and Glacier Deep Archive takes hours; both require restoring the object first. "Archive but must be instantly available" → Glacier Instant Retrieval.

When do you use S3 Intelligent-Tiering?
?
When access patterns are unknown, changing, or unpredictable. It auto-moves objects between tiers (Frequent → Infrequent after 30 days → Archive Instant Access after 90 days, plus optional archive tiers) for a small per-object monitoring fee and NO retrieval fees. Objects under 128 KB aren't monitored and stay in Frequent Access.

What happens when you delete an object in a versioned bucket?
?
S3 adds a DELETE MARKER as the new latest version. The object disappears from a normal listing (`s3 ls`) but nothing is destroyed — all prior versions remain. Deleting the delete marker restores the object. To permanently remove data you must delete a specific `--version-id`.

Can S3 versioning be turned off once enabled?
?
No — it can only be SUSPENDED, never disabled. Objects that existed before versioning was enabled have `VersionId = null`. Suspending stops new versions being created but keeps existing ones.

What can S3 lifecycle rules do?
?
Transition objects between storage classes on a schedule (e.g. 30d → Standard-IA, 90d → Glacier), EXPIRE (delete) current objects, expire NONCURRENT versions, and abort incomplete multipart uploads. It's the main S3 cost-control tool.

Why must you pair versioning with noncurrent_version_expiration?
?
Because every overwrite keeps the old version forever, so storage and cost grow without bound while `s3 ls` (which shows only current versions) looks unchanged. A lifecycle rule expiring noncurrent versions after N days prevents runaway bills. It's also why a versioned bucket won't delete until all versions and delete markers are purged.

What protocol does an S3 static website endpoint support?
?
HTTP only. For HTTPS (and a custom domain plus caching) you must put CloudFront in front of the bucket. Static hosting also requires public read access — Block Public Access disabled plus a public bucket policy.

In Terraform, why is `etag = filemd5(path)` needed on an `aws_s3_object` using `source`?
?
Without it Terraform tracks only the file PATH, not its contents — so editing the file and re-applying produces "no changes" and the upload is silently skipped. `filemd5()` hashes the contents so a change shows up as a diff.

Why set `content_type` on an `aws_s3_object` for a website?
?
Otherwise S3 serves a generic content type (binary/octet-stream) and browsers DOWNLOAD the file instead of rendering it. HTML objects need `content_type = "text/html"`.
