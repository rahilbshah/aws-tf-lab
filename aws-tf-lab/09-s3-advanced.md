---
topic: 09-s3-advanced
domain: performance
status: reviewed
services: [S3]
related: [09-s3, 09-s3-intro, 09-s3-security, 01-iam]
cards: cards/09-s3-advanced-cards
tags: [topic, domain/performance]
---

# 09.2 – S3 Advanced (replication, big files, events)

Moving data around and reacting to it: replication for DR/latency, multipart & byte-range for big objects, Transfer Acceleration for distance, and event notifications for automation. Part of [[09-s3]].

> [!info] Exam TL;DR
> - **Replication:** **CRR** = different region (DR, latency, compliance), **SRR** = same region (log aggregation, prod↔test). Requires **versioning on BOTH buckets** + an **IAM role**. It is **asynchronous**.
> - Live replication only copies **new/updated** objects. Pre-existing objects (or previously failed ones) need **S3 Batch Replication** — an on-demand job.
> - **Replication is not chained**: A→B and B→C does *not* get A's objects to C.
> - **S3 RTC** = SLA-backed **99.99% replicated within 15 minutes** (the "predictable replication time / compliance" answer).
> - **Multipart upload:** recommended ≥ **100 MB**, **required > 5 GB** (single-PUT max). Parallel parts, retry only the failed part. **Incomplete parts keep billing** → lifecycle `AbortIncompleteMultipartUpload`.
> - **Byte-range fetch** = the download mirror: fetch only part of an object (headers, or parallel chunks).
> - **Transfer Acceleration:** upload to the nearest **CloudFront edge**, then over AWS's **private backbone** to the bucket's region. Same bucket, faster path — for long-distance/large uploads.
> - **Event notifications:** on object created/removed/restored → **SNS, SQS, Lambda, EventBridge**. Destination needs a **resource policy** allowing S3.
> - **Glacier retrieval tiers** (Flexible): Expedited **1–5 min**, Standard **3–5 h**, Bulk **5–12 h**. Deep Archive: **no Expedited**, Standard **~12 h**, Bulk **~48 h**.
> - ⚠️ **S3 Select is no longer available to new customers** — learn the concept; use **Athena** in practice.

## Concept (plain English)

Once objects are in S3, the advanced features are about three problems. **Getting a second copy somewhere else** — replication automatically and asynchronously copies objects to another bucket, in another region (DR, closer users, compliance) or the same one (aggregating logs, syncing prod to test). **Moving big objects efficiently** — multipart upload splits a large file into parts you can send in parallel and retry individually, and byte-range fetch does the reverse for downloads; Transfer Acceleration shortens the *path* by entering AWS's network at a nearby edge location. And **reacting to change** — event notifications turn "an object was created" into a message to SQS/SNS/Lambda/EventBridge, which is how S3 becomes the trigger for event-driven pipelines.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| Replication rule | `aws_s3_bucket_replication_configuration` | On the **source**; needs `role`, versioning both sides. |
| Destination in another region | `provider` **alias** + `provider = aws.dest` | How one config spans regions. |
| Replication IAM role | `aws_iam_role` + `aws_iam_role_policy` | Trust `s3.amazonaws.com`; 3 statements (list source / read versions / replicate to dest). |
| Event notification | `aws_s3_bucket_notification` | **One per bucket** — it owns the whole notification config. |
| Event destination policy | `aws_sqs_queue_policy` / `aws_sns_topic_policy` / `aws_lambda_permission` | Required, or apply fails validating the destination. |
| Transfer Acceleration | `aws_s3_bucket_accelerate_configuration` | One setting; costs extra per GB. |
| Abort stale multipart uploads | `abort_incomplete_multipart_upload` in the lifecycle rule | Pure cost hygiene. |

## Architecture diagram

```mermaid
flowchart LR
    CL[Client] -->|multipart parts in parallel| SRC[(Source bucket<br/>us-east-1)]
    CL -.->|Transfer Acceleration:<br/>nearest edge -> AWS backbone| SRC
    SRC -->|async replication<br/>versioning + IAM role| DST[(Destination bucket<br/>us-west-2, can be cheaper class)]
    SRC -->|ObjectCreated / ObjectRemoved| EV{Event notification}
    EV --> SQS[SQS]
    EV --> SNS[SNS]
    EV --> LAM[Lambda]
    EV --> EB[EventBridge]
```

## Key facts, limits & pricing

### Replication
- **Two live types:** **CRR** (cross-region) and **SRR** (same-region). Both are **asynchronous**. Buckets may be in **different AWS accounts**.
- **Requirements:** versioning **enabled on source *and* destination**, plus an **IAM role** S3 assumes (read source versions, write destination).
- **Only new/updated objects** are replicated after you enable a rule. For anything else use **S3 Batch Replication** (on-demand): existing objects, objects whose replication **FAILED**, objects already replicated (e.g. to a newly added destination), and replicas-of-replicas.
- **Not transitive/chained** — replicas created by a rule can only be re-replicated via Batch Replication.
- **Delete markers** are **not** replicated unless you opt in (`delete_marker_replication`). Deleting a *specific version* is never replicated (protects the copy).
- Replicas can land in a **different (cheaper) storage class**, and ownership can be overridden to the destination account.
- **S3 RTC (Replication Time Control):** replicates **99.99% of new objects within 15 minutes**, backed by an SLA + CloudWatch replication metrics. Doesn't apply to Batch Replication.
- **CRR use cases:** compliance/geographic distance, lower latency for users in another region, cross-region DR. **SRR use cases:** aggregate logs into one bucket, replicate prod→test accounts, data-sovereignty copies within a region.

### Big objects
- **Multipart upload:** AWS **recommends ≥ 100 MB**; **required above 5 GB** (max single-PUT). Up to **10,000 parts** (numbers 1–10,000); max object **5 TB**. Parts upload in **parallel** and a failed part is retried alone.
- **Incomplete multipart uploads keep billing you** for the stored parts until you complete or abort them — and they're invisible in a normal listing. Always add **`AbortIncompleteMultipartUpload`** to a lifecycle rule.
- **Byte-range fetch:** request only a byte range of an object — used to read just a header/metadata, resume a broken download, or parallelize a big download into ranges.

### Speed & query
- **Transfer Acceleration:** client uploads to the **nearest CloudFront edge location**, which forwards over **AWS's private backbone** to the bucket's region. The bucket does **not** move. Best for long-distance transfers of large objects; costs extra per GB. (Not a CDN for reads — that's CloudFront itself.)
- **S3 Select:** SQL over a **single object** (CSV/JSON/Parquet), returning only matching rows/columns so less data crosses the wire. ⚠️ **AWS: "Amazon S3 Select is no longer available to new customers."** Existing users keep it; new work should use **Athena** (multi-object SQL over S3). Know the concept for the exam.

### Events & automation
- **Triggers:** `s3:ObjectCreated:*` (Put/Post/Copy/CompleteMultipartUpload), `s3:ObjectRemoved:*`, `s3:ObjectRestore:*`, replication events, and more. Can filter by **prefix** and **suffix**.
- **Destinations:** **SNS**, **SQS**, **Lambda**, **EventBridge**. EventBridge adds rich filtering, archive/replay and 20+ further targets.
- Each destination needs a **resource policy** allowing `s3.amazonaws.com` (with an `aws:SourceArn` condition) — otherwise S3 can't publish and setup fails validation.
- Delivery is typically seconds but **not guaranteed instant**; design consumers to be idempotent.

### Glacier retrieval tiers (verified)

| Storage class | Expedited | Standard | Bulk |
|---|---|---|---|
| **Glacier Flexible Retrieval** | **1–5 min** | **3–5 hours** | **5–12 hours** (free) |
| **Glacier Deep Archive** | **not available** | **~12 hours** | **~48 hours** |

*(Glacier **Instant** Retrieval needs no restore at all — millisecond GET.)*

### Other advanced bits
- **S3 Batch Operations:** run one action (copy, tag, restore, invoke Lambda, ACL change) across **millions of objects** from a manifest, with retries and a completion report. Powers Batch Replication.
- **Storage Lens:** org-wide storage analytics dashboard (usage, activity, cost-optimization recommendations); free metrics tier + paid advanced.
- **Storage Class Analysis:** watches access patterns and recommends when to transition to IA.
- **Requester Pays:** the *requester*, not the bucket owner, pays for requests + transfer — for sharing large datasets.

## Comparisons

### CRR vs SRR

|   | CRR | SRR |
|---|---|---|
| Destination | **Different** region | **Same** region |
| Typical use | DR, compliance distance, low latency for far users, cross-region analytics | Log aggregation, prod↔test sync, in-region data-sovereignty copies |
| Cross-account | Yes | Yes |

### Multipart vs byte-range

|   | Multipart upload | Byte-range fetch |
|---|---|---|
| Direction | **Upload** | **Download** |
| Splits | Object into parts sent in parallel | Request into ranges |
| Wins | Throughput + retry one part | Fetch only what you need / parallel download / resume |

## Worked examples

> [!example] Worked example — the event-driven thumbnail pipeline
> Users upload photos to `uploads/`. An **`s3:ObjectCreated:*` notification** (prefix-filtered) fires a **Lambda**, which reads the object, generates a thumbnail and writes it to `thumbs/`. No polling, no server, and it scales with upload volume. Two production details: the destination needs a **resource policy** letting S3 invoke it, and the thumbnail must be written to a **different prefix or bucket** — writing back into `uploads/` would re-trigger the same rule and **recurse infinitely** (a real and expensive mistake). In this build we pointed events at **SQS** instead of Lambda so the raw event JSON is readable with one CLI call — that JSON is exactly what a Lambda would receive.

> [!failure] Failure mode — "replication is on, so we're backed up"
> A team enables CRR for DR and assumes the destination now mirrors the bucket. It doesn't: live replication copies only objects written **after** the rule existed, so years of existing data are missing — discovered during an actual regional failover. Worse, if they'd enabled **delete-marker replication**, an accidental delete would propagate to the "backup" too. Fixes: run **S3 Batch Replication** to backfill existing objects, keep delete-marker replication **off** for DR copies, and monitor with **replication metrics / S3 RTC**. Replication is a *copy*, not a *backup* — versioning + Object Lock are what protect against deletion.

> [!failure] Failure mode — the invisible multipart bill
> A nightly job uploads multi-GB files and sometimes crashes mid-upload. Each crash leaves an **incomplete multipart upload**: the uploaded parts are stored and **billed**, but they don't appear in `s3 ls` or the bucket's object count. Months later, storage cost far exceeds the visible data. Diagnose with `aws s3api list-multipart-uploads`; fix permanently with a lifecycle rule containing **`abort_incomplete_multipart_upload { days_after_initiation = 7 }`**. This is why that clause is in our lifecycle rule.

## The Terraform I wrote

Code: `09-s3/events.tf` + `09-s3/replication.tf` (+ the `aws.dest` provider alias in `versions.tf`).

*(Written collaboratively — I reviewed and applied; the code was walked through line by line rather than hand-typed, since the exam value here is conceptual.)*

- **Events:** `aws_sqs_queue` → `aws_sqs_queue_policy` (principal `s3.amazonaws.com`, **`aws:SourceArn` condition** scoping it to the one bucket — the confused-deputy fix from [[01-iam]]) → `aws_s3_bucket_notification` on `ObjectCreated:*`/`ObjectRemoved:*` filtered to `uploads/`, with `depends_on` the queue policy.
- **Replication:** a **second provider alias** (`aws.dest`, us-west-2), destination bucket + versioning there, an IAM role trusted by `s3.amazonaws.com` with **three** statements (bucket-level list/config on the source ARN, object-version reads on `source/*`, replicate actions on `dest/*`), and `aws_s3_bucket_replication_configuration` on the source with `storage_class = "STANDARD_IA"` and delete-marker replication off.

Non-obvious things:
- **One `aws_s3_bucket_notification` per bucket** — it owns the entire config; a second resource silently overwrites the first.
- Event setup **fails at apply** without the destination's resource policy (`Unable to validate the following destination configurations`).
- Replication IAM: **bucket-level actions use the bucket ARN, object-level actions use `<arn>/*`** — mixing them fails silently.
- Both buckets are versioned, so **neither will `terraform destroy`** until versions and delete markers are purged (or `force_destroy = true`).

> [!warning] Trap — replication copies existing objects
> It does **not**. Live CRR/SRR only handles objects created/updated **after** the rule. Existing data needs **S3 Batch Replication**.

> [!warning] Trap — replication is transitive
> No. A→B and B→C does **not** deliver A's objects to C. Replicas can only be re-replicated with Batch Replication.

> [!warning] Trap — Transfer Acceleration moves your data closer to users
> It doesn't move the bucket. It changes the **path**: enter AWS at the nearest **edge location**, then travel the **private backbone** to the bucket's region. For serving *reads* globally you want **CloudFront**.

> [!warning] Trap — "use S3 Select" on a new account
> S3 Select is **no longer available to new customers**. The modern answer for SQL over S3 is **Athena** (and it queries many objects, not one).

> [!example]- Recall drill
> (1) What must be enabled on both buckets for replication, and what copies pre-existing objects? (2) Multipart: recommended vs required size? (3) What does Transfer Acceleration actually change? (4) Name the four event destinations. (5) Glacier Flexible retrieval times for Expedited/Standard/Bulk?
> > [!success]- Answers
> > (1) Versioning on both (+ an IAM role); **S3 Batch Replication**. (2) ≥100 MB recommended, >5 GB required. (3) The network path — nearest edge then AWS backbone; the bucket stays put. (4) SNS, SQS, Lambda, EventBridge. (5) 1–5 min / 3–5 h / 5–12 h.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **S3 Batch Replication** — the name for replicating pre-existing/failed objects (blanked on it in orient).
- [ ] **Transfer Acceleration mechanism** — thought it fetched from a nearer bucket; it's edge entry + AWS backbone to the *same* bucket.
- [ ] **S3 Select is deprecated for new customers** — use Athena; know the concept only.
- [ ] **Replication is not transitive**, and **delete markers aren't replicated by default**.
- [ ] **S3 RTC = 15-minute SLA** — the "predictable replication time" answer.
- [ ] **Glacier retrieval tiers/times** (Expedited 1–5 min, Standard 3–5 h, Bulk 5–12 h; Deep Archive has no Expedited).
- [ ] **Incomplete multipart uploads bill invisibly** — lifecycle abort rule is mandatory hygiene.

## 🔗 Docs

- [Replicating objects](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html) — CRR/SRR, Batch Replication, RTC 15-min SLA; **verified 2026-08**
- [Multipart upload overview](https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html) — 100 MB recommendation, 10,000 parts, incomplete-upload billing; **verified 2026-08**
- [Archive retrieval options](https://docs.aws.amazon.com/AmazonS3/latest/userguide/restoring-objects-retrieval-options.html) — Expedited/Standard/Bulk times; **verified 2026-08**
- [S3 Select](https://docs.aws.amazon.com/AmazonS3/latest/userguide/selecting-content-from-objects.html) — *"no longer available to new customers"*; **verified 2026-08**
- [Event notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html) / [Transfer Acceleration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/transfer-acceleration.html)
- [Terraform `aws_s3_bucket_replication_configuration`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) / [`aws_s3_bucket_notification`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification)

---
**Cards for this topic:** [[cards/09-s3-advanced-cards]]
