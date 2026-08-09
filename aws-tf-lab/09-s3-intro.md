---
topic: 09-s3-intro
domain: performance
status: reviewed
services: [S3]
related: [09-s3, 09-s3-security, 05-vpc-endpoints-peering]
cards: cards/09-s3-intro-cards
tags: [topic, domain/performance]
---

# 09.1 – S3 Introduction (buckets, classes, versioning, lifecycle)

The foundation: what S3 stores and how, the storage-class spectrum, and the two data-management features that save you money and mistakes — versioning and lifecycle. Part of [[09-s3]].

> [!info] Exam TL;DR
> - **Bucket names are GLOBALLY unique** (across all AWS accounts); buckets themselves live in **one region**.
> - The **key** is the object's full name (`photos/cat.jpg`). S3 is a **flat key→object map** — "folders" are a console illusion over the `/` in keys; the leading part is a **prefix**.
> - **Durability = 99.999999999% (11 nines)** for *every* storage class, stored across **≥3 AZs** — *except* One Zone classes (**1 AZ**). **Availability differs by class** (Standard 99.99%, IA 99.9%, One Zone-IA 99.5%).
> - **Storage classes:** Standard → Intelligent-Tiering → Standard-IA → One Zone-IA → Glacier Instant → Glacier Flexible → Glacier Deep Archive. **Minimum storage durations:** IA classes **30 d**, Glacier Instant/Flexible **90 d**, Deep Archive **180 d** (delete early = still billed).
> - **Versioning** keeps every version; a delete creates a **delete marker** (nothing is really removed). Deleting the marker restores the object.
> - **Lifecycle rules** transition objects between classes and **expire** them (incl. noncurrent versions + incomplete multipart uploads) — pure cost control.
> - **Static website hosting** serves objects over **HTTP only** — HTTPS needs CloudFront in front.

## Concept (plain English)

S3 is object storage: you put whole files ("objects") into containers ("buckets") and address them by a **key** — the object's full name. There is no real directory tree; `photos/cat.jpg` is just a key that happens to contain a slash, and the console groups on those slashes to fake folders. AWS replicates every object across at least three Availability Zones, which is where the famous eleven-nines durability comes from. Because storage costs money forever, S3 gives you **storage classes** (cheaper per GB the slower/rarer the access) and **lifecycle rules** to move data down that ladder automatically. **Versioning** turns the bucket into an append-only history so an overwrite or delete never actually loses data.

## AWS console ↔ Terraform map

| Console / concept | Terraform | Notes |
|---|---|---|
| Create a bucket | `aws_s3_bucket` | Just the container now — settings are **separate resources** in the modern provider (inline blocks are deprecated). |
| Enable versioning | `aws_s3_bucket_versioning` | `versioning_configuration { status = "Enabled" }`. |
| Lifecycle rules | `aws_s3_bucket_lifecycle_configuration` | `transition`, `expiration`, `noncurrent_version_expiration`, `abort_incomplete_multipart_upload`. |
| Upload an object | `aws_s3_object` | `content = "..."` (inline) **or** `source = path` + **`etag = filemd5(path)`**; set `content_type`. |
| Static website | `aws_s3_bucket_website_configuration` | `index_document` + `error_document`. |
| Public-access safety net | `aws_s3_bucket_public_access_block` | 4 flags; **all true** normally, all false only for a real public site. |
| Bucket policy | `aws_s3_bucket_policy` (+ `data.aws_iam_policy_document`) | Resource-based policy; see [[09-s3-security]]. |
| Default encryption | `aws_s3_bucket_server_side_encryption_configuration` | See [[09-s3-security]]. |

## Architecture diagram

```mermaid
flowchart LR
    UP[PUT object] --> B[(Bucket)]
    B --> V{Versioning on?}
    V -->|yes| NEW[New VersionId kept<br/>old version retained]
    V -->|no| OVER[Overwrites in place]
    DEL[DELETE object] --> V2{Versioning on?}
    V2 -->|yes| DM[Delete marker added<br/>object hidden, not gone]
    V2 -->|no| GONE[Object destroyed]
    LC[Lifecycle rule] -->|30d| IA[Standard-IA]
    IA -->|90d| GL[Glacier]
    GL -->|365d| EXP[Expire / delete]
```

## Key facts, limits & pricing

- **Namespace:** bucket names are **globally unique across all AWS accounts**; buckets are **regional** resources. Names are DNS-compatible (3–63 chars, lowercase, no underscores).
- **Object size:** 0 bytes to **5 TB**. A single `PUT` maxes at **5 GB** — beyond that you must use **multipart upload** (see [[09-s3-advanced]]).
- **Durability: 99.999999999% (11 nines)** — *designed for* — on **every** storage class. Achieved by redundantly storing across **≥3 AZs** (One Zone classes: **1 AZ**, same 11-nines durability but **lost if that AZ is destroyed**).
- **Availability (designed for), verified:** Standard **99.99%** · Standard-IA **99.9%** · Intelligent-Tiering **99.9%** · One Zone-IA **99.5%** · Glacier Instant **99.9%** · Glacier Flexible / Deep Archive **99.99% (after restore)**.
- **Minimum storage durations (billed even if you delete early):** Standard & Intelligent-Tiering **none** · Standard-IA & One Zone-IA **30 days** · Glacier Instant & Glacier Flexible **90 days** · Glacier Deep Archive **180 days**.
- **Minimum billable object size:** Standard/Intelligent-Tiering **none**; Standard-IA, One Zone-IA, Glacier Instant **128 KB**. (Storing many tiny files in IA can cost *more* than Standard.)
- **Intelligent-Tiering:** auto-moves objects between Frequent → Infrequent (**30 d** no access) → Archive Instant Access (**90 d**), plus optional Archive Access (90 d) and Deep Archive Access (180 d) tiers. **Monitoring fee per object, no retrieval fees.** Objects **< 128 KB are not monitored** and stay in Frequent Access.
- **Consistency:** S3 provides **strong read-after-write consistency** for all PUTs and DELETEs (since Dec 2020) — no more eventual-consistency caveats.
- **Versioning:** enabled at the **bucket** level; can be **suspended but never disabled** once enabled. Pre-versioning objects have `VersionId = null`. Every version costs storage → pair with `noncurrent_version_expiration`.
- **Static website hosting:** the S3 website endpoint is **HTTP only**; for HTTPS/custom domain/caching put **CloudFront** in front. Requires public read access (Block Public Access off + public bucket policy).

## Comparisons

### Storage classes (verified against AWS docs 2026-08)

| Class | For | Availability | AZs | Min duration | Min billable size | Retrieval |
|---|---|---|---|---|---|---|
| **S3 Standard** | Frequent access | 99.99% | ≥3 | none | none | ms |
| **Intelligent-Tiering** | Unknown/changing patterns | 99.9% | ≥3 | none | none | ms (monitoring fee, no retrieval fee) |
| **Standard-IA** | Infrequent, must not lose | 99.9% | ≥3 | 30 d | 128 KB | ms (+ retrieval fee) |
| **One Zone-IA** | Infrequent, **re-creatable** | 99.5% | **1** | 30 d | 128 KB | ms (+ retrieval fee) |
| **Glacier Instant Retrieval** | Archive, quarterly, instant | 99.9% | ≥3 | 90 d | 128 KB | **milliseconds** |
| **Glacier Flexible Retrieval** | Archive, yearly | 99.99% (post-restore) | ≥3 | 90 d | — | **minutes–hours** (restore first) |
| **Glacier Deep Archive** | Archive, <1×/year | 99.99% (post-restore) | ≥3 | **180 d** | — | **hours** (restore first) |

*(Also exists: **S3 Express One Zone** — single-digit-ms, 1 AZ, 99.95% — for latency-critical workloads.)*

### Versioning: delete vs permanent delete

| Action | Versioning OFF | Versioning ON |
|---|---|---|
| `DELETE object` | Object destroyed | **Delete marker** added; object hidden, versions retained |
| `DELETE object --version-id` | n/a | **Permanently** removes that version |
| Delete the delete marker | n/a | Object **reappears** |
| Overwrite | Replaces in place | New version; old version kept |

## Worked examples

> [!example] Worked example — a lifecycle policy that pays for itself
> Log files land in S3 daily. They're queried constantly for the first month, occasionally for a quarter, then kept years for compliance and almost never read. One lifecycle rule handles the whole journey: **Standard** on write → **Standard-IA at 30 days** → **Glacier Flexible at 90 days** → **expire at 7 years**, plus `noncurrent_version_expiration` to purge old versions and `abort_incomplete_multipart_upload` after 7 days. Storage cost drops by an order of magnitude with no application change. Exam trigger: *"data accessed frequently at first then rarely, minimize cost"* → **lifecycle transitions**, not manual copies.

> [!failure] Failure mode — versioning without noncurrent-version expiration
> A team enables versioning "for safety" on a bucket where a job rewrites the same objects hourly. Every rewrite keeps the old version forever, so storage (and the bill) grows without bound while the bucket "looks" the same size in the console — `s3 ls` shows only current versions. Months later the bill is 20× expected. Fix: always pair versioning with a lifecycle rule containing **`noncurrent_version_expiration`** (e.g. 30 days), and use `list-object-versions` (not `s3 ls`) to see true usage. *(Also why a versioned bucket refuses to `terraform destroy` with `BucketNotEmpty` until every version and delete marker is purged — hit live in this build.)*

> [!failure] Failure mode — One Zone-IA for the only copy
> One Zone-IA is ~20% cheaper than Standard-IA and equally durable *on paper* (11 nines) — so a team moves its only backup copy there. Both classes are 11-nines durable, but One Zone-IA stores in a **single AZ**: if that AZ is physically destroyed, **the data is gone**, and its availability is only 99.5%. Rule: One Zone-IA is only for **re-creatable** data (thumbnails, derived files, secondary replicas). The primary/only copy belongs in a ≥3-AZ class.

## The Terraform I wrote

Code: `09-s3/` — `main.tf` (bucket + versioning + lifecycle + objects), `website.tf` (static site), plus `data.txt` / `index.html` / `error.html`.

- Bucket named with `data.aws_caller_identity.current.account_id` as a suffix (bucket names are **globally unique** — a plain name fails).
- `aws_s3_bucket_versioning` enabled, then **verified live**: edited the object, re-applied, and `list-object-versions` showed **two versions** with different `VersionId`s and `IsLatest` on the newer. Deleted it → a **delete marker** appeared and the object vanished from `s3 ls` while both versions remained; removing the marker restored it.
- `aws_s3_bucket_lifecycle_configuration` with transitions (30 d → STANDARD_IA, 90 d → GLACIER), `expiration`, `noncurrent_version_expiration` and `abort_incomplete_multipart_upload`.
- Static site: second bucket + `website_configuration` (index + error), `public_access_block` all-false, a public-read `bucket_policy` (with `depends_on` on the access block so ordering is right), and objects uploaded with **`content_type = "text/html"`**. Verified in a browser, including the 404 page.

Non-obvious things:
- **Modern provider splits bucket config into separate resources** — `aws_s3_bucket` no longer takes inline `versioning`/`lifecycle_rule`/`website` blocks.
- **`etag = filemd5(path)`** is required with `source`, or Terraform won't notice the file's *contents* changed and silently skips the upload.
- **`content_type`** must be set or browsers download instead of rendering.
- A public bucket policy is **rejected while Block Public Access is on** → `depends_on` the access block.

> [!warning] Trap — "S3 has folders"
> No. S3 is a flat key→object store; `photos/cat.jpg` is one key. The console renders "folders" by splitting on `/`. Listing by **prefix** is how you emulate a directory.

> [!warning] Trap — "Glacier means slow retrieval"
> **Glacier Instant Retrieval** returns objects in **milliseconds**. Only **Flexible Retrieval** (minutes–hours) and **Deep Archive** (hours) need a restore job. "Archive but must be instantly available" → Glacier Instant Retrieval.

> [!warning] Trap — durability vs availability
> Every class is **11 nines durable** (won't lose data). What differs is **availability** (can you reach it *right now*): Standard 99.99%, IA 99.9%, One Zone-IA 99.5%. Questions about "surviving AZ loss" are about **AZ count**, not durability.

> [!warning] Trap — moving to IA/Glacier always saves money
> Minimum storage durations (IA 30 d, Glacier 90 d, Deep Archive 180 d) and a **128 KB minimum billable size** mean short-lived or tiny objects can cost **more** in IA than Standard. Transition only data that will genuinely sit there.

> [!example]- Recreate-from-memory drill
> Build a bucket with versioning + a lifecycle rule (30 d → IA, 90 d → Glacier, expire 365 d, noncurrent 30 d), upload an object from a file (with `etag`), then edit + re-apply and prove two versions exist. Delete the object and find the delete marker; restore it. Then a second bucket serving a static site (index + error, public policy, `content_type`).
> > [!success]- Reference solution
> > See `09-s3/main.tf` + `website.tf`. Gotchas: globally-unique bucket name, `etag = filemd5(...)`, `content_type`, `depends_on` the public-access block, and `force_destroy`/manual purge to delete a versioned bucket.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **"Key" = the object's full name/path**, not an encryption key. Bucket + key identifies an object; the leading part is a **prefix**.
- [ ] **Durability 11 nines / ≥3 AZs, and availability differs per class** (Standard 99.99, IA 99.9, One Zone-IA 99.5) — needed the numbers.
- [ ] **Minimum storage durations** (IA 30 d, Glacier 90 d, Deep Archive 180 d) + **128 KB minimum billable size** — the cost traps.
- [ ] **Glacier Instant Retrieval is millisecond access** — not all Glacier tiers are slow.
- [ ] **Versioned buckets need noncurrent-version expiration** (cost) and can't be destroyed while versions/markers remain.
- [ ] **`etag = filemd5()`** required with `source`, and **`content_type`** required for browser rendering.

## 🔗 Docs

- [S3 storage classes comparison](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html) — durability/availability/AZs/min-duration/min-size table; **verified 2026-08**
- [Using versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html) — delete markers
- [Managing object lifecycle](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [Hosting a static website](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Terraform `aws_s3_bucket`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) / [`aws_s3_object`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)

---
**Cards for this topic:** [[cards/09-s3-intro-cards]]
