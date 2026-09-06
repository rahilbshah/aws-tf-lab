---
topic: 16-kinesis
domain: performance
status: reviewed
services: [Kinesis, Firehose]
related: [15-decoupling, 09-s3-advanced, 12-storage-extras]
cards: cards/16-kinesis-cards
tags: [topic, domain/performance]
---

# 16 – Kinesis (Data Streams & Data Firehose)

Streaming data: a continuous, ordered log that several consumers read independently and can re-read. The service SQS is most often confused with, and the confusion is worth resolving precisely.

> [!warning] Build tier — **conceptual-only (blocked on this account)**
> Kinesis Data Streams and Amazon Data Firehose are **both unavailable on this AWS account's Free plan** — even a read-only `ListStreams` returns `SubscriptionRequiredException`. This is a plan-level block, not a quota or a cost limit. Learned from the docs; the exam tests the *decisions* here, not the HCL.

## What problem does this solve?

You've already got SQS. Something writes a message, something else processes it, and the message is deleted. That works beautifully for **work** — a job someone needs to do exactly once.

Now change the requirement. Clickstream events are arriving continuously. **Two separate teams** need them: a fraud detector reading in real time, and a batch analytics job that runs hourly. Later, a third team wants to reprocess last week's events against a new model.

SQS cannot do that. A message consumed by the fraud detector is **gone** — analytics never sees it. You could fan out with SNS into two queues, but each still gets its own copy that vanishes on processing, and nothing can go back and re-read last Tuesday.

Kinesis inverts the model. It's an **append-only log**:

> **SQS is a to-do list.** You take an item, do it, tear it off. It's gone.
> **Kinesis is a ledger.** Records are written in order and **stay**. Each reader keeps its own bookmark. Reading changes nothing.

There is no delete operation for a Kinesis record. It ages out on **retention** — default and minimum **24 hours**, maximum **365 days** — and until then anyone can read it, as many times as they like.

> In one line: SQS deletes a message when it's done; Kinesis keeps every record for its retention period so any number of consumers can read, and re-read, the same data.

## How it actually works

### Shards — capacity and partitioning in one thing

If you know database sharding, the intuition transfers exactly. A shard is a **partition of the stream**, and it is also a **fixed unit of throughput**.

Per shard, verified:

| Direction | Limit |
|---|---|
| **Write** | **1 MB/sec** _or_ **1,000 records/sec** |
| **Read** | **2 MB/sec**, and at most **5 `GetRecords` calls/sec** |

Note the **or** on the write side. It's whichever ceiling you hit first — a thousand tiny records per second maxes out a shard long before you approach 1 MB. Sizing a stream by data volume alone is how people under-provision.

A stream's total capacity is just the sum of its shards, so you scale by adding them. That's also how you're billed in **provisioned** mode: per shard-hour, regardless of traffic.

That read limit matters more than it looks: **2 MB/sec is shared across every consumer on the shard.** Two consumers means roughly 1 MB/sec each, and they compete. That's "shared fan-out", the default.

> In one line: a shard is one partition and one fixed slice of throughput — 1 MB/sec or 1,000 records/sec in, 2 MB/sec out shared between all consumers.

### The partition key decides both placement and ordering

Every record you write carries a **partition key** — a string up to 256 characters. Kinesis runs it through an **MD5 hash** and maps the result onto the shards' hash-key ranges. Same key, same shard, always.

Now the consequence that gets tested:

> **Ordering is guaranteed within a shard, not across the stream.**

Records in a shard carry increasing **sequence numbers**, so a single consumer reads that shard in order. But two records that hashed to different shards have no defined order relative to each other.

If that sounds familiar, it should — it is **the same idea as `MessageGroupId` in a FIFO SQS queue** ([[15-decoupling]]). In both services:

- same key/group → strictly ordered, processed serially
- different keys/groups → independent, processed in parallel

And in both, choosing that key well is how you get ordering **and** throughput at once. Partition by `customer_id` and every customer's events stay in order while different customers spread across shards. Partition by something with only a few distinct values and you get a **hot shard**: one partition saturated while the others idle.

> In one line: the partition key hashes to a shard, order is guaranteed only inside a shard, and picking a high-cardinality key is what buys you ordering and parallelism together.

### Data Streams vs Firehose — a store versus a pipe

This is the pair that causes the most trouble, and one sentence resolves it:

> **Kinesis Data Streams is a place data is kept. Amazon Data Firehose is a way data is moved.**

**Data Streams** is the log described above. It has shards you size, a retention period, sequence numbers, and **no consumers of its own** — you write and operate them. In exchange you get real-time reads, several independent consumers, and the ability to replay history.

**Firehose** has none of that. No shards. No retention. No consumers to write. You point it at a **destination** and it delivers there, **buffering** first — by size (MB) or by interval (seconds), whichever threshold trips first. AWS's framing: *"you don't need to write applications or manage resources."*

Destinations include **S3, Redshift, OpenSearch Service and Serverless, Splunk, Apache Iceberg tables**, any custom **HTTP endpoint**, and partners like Datadog, New Relic and MongoDB. It can also run a **Lambda transform** on records before delivering, and optionally back the raw source up to a second S3 bucket.

Because it buffers, Firehose is **near**-real-time, not real-time. And because it has no retention, once delivered the data is wherever you sent it — there is nothing to replay from.

**They compose.** Firehose can take a **Data Stream as its source**, which is the standard production shape: producers write once to a stream, your real-time consumer reads it, and a Firehose quietly archives everything to S3 for later.

> In one line: Data Streams stores and you build the consumer; Firehose delivers to a destination and you build nothing — and Firehose can read from a stream, so it's usually both.

### Reading: shared fan-out versus enhanced fan-out

The default is **shared fan-out**: consumers call `GetRecords` and split that 2 MB/sec per shard between them. Cheap, and fine for one or two consumers.

**Enhanced fan-out** gives each *registered* consumer its **own 2 MB/sec** pipe per shard, pushed to it rather than polled, with lower latency. You can register up to **20** consumers per stream on standard modes. It costs more.

The trigger in a question: *"multiple consumers, each needing full throughput"* or *"consumers are starving each other"* → **enhanced fan-out**.

One operational detail worth knowing because it surprises people: the **Kinesis Client Library stores its consumption state in DynamoDB** — it creates three tables per application. So a Kinesis consumer quietly has a DynamoDB dependency, and its IAM role needs DynamoDB permissions.

> In one line: shared fan-out splits one shard's 2 MB/sec between all consumers; enhanced fan-out gives each registered consumer its own 2 MB/sec, pushed rather than polled.

## Exam recap

> [!info] Exam TL;DR
> - **SQS deletes on processing; Kinesis keeps everything for its retention period.** Multiple consumers read the same records independently, and can **replay**. There is no delete-a-record operation.
> - **Retention: default and minimum 24 hours, maximum 8,760 hours (365 days).** Anything above 24 hours costs extra.
> - **Per shard: 1 MB/sec _or_ 1,000 records/sec in; 2 MB/sec out** (max 5 `GetRecords`/sec). Read throughput is **shared across all consumers** unless you use enhanced fan-out.
> - **Partition key → MD5 hash → shard.** **Ordering is guaranteed within a shard, not across the stream** — the same idea as `MessageGroupId` in FIFO SQS. Low-cardinality keys create a **hot shard**.
> - **Capacity modes:** *provisioned* (you set shard count, billed per shard-hour) or *on-demand* (AWS manages shards, billed per GB). You may switch **twice per 24 hours**.
> - **Data Streams = a store you build consumers for. Firehose = a delivery pipe with nothing to manage.** Firehose has **no shards and no retention**, buffers by **size or interval**, and can run a **Lambda transform**.
> - **Firehose destinations:** S3, Redshift (via S3 then `COPY`), OpenSearch, Splunk, Iceberg, HTTP endpoints, partners. **Firehose can read from a Data Stream** — the two are usually combined.
> - **Enhanced fan-out** = each registered consumer gets its own 2 MB/sec per shard, pushed; up to **20** consumers.
> - The **KCL tracks progress in DynamoDB** (three tables per application).
> - **SQS vs Kinesis:** one consumer per message and delete-when-done → SQS. Several independent consumers, ordering, or replay → Kinesis.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| The stream | `aws_kinesis_stream` | `shard_count`, `retention_period` (hours), `stream_mode_details { stream_mode = "PROVISIONED" \| "ON_DEMAND" }`. |
| Registered consumer (EFO) | `aws_kinesis_stream_consumer` | Enhanced fan-out. |
| Delivery pipeline | `aws_kinesis_firehose_delivery_stream` | `destination = "extended_s3"`, `kinesis_source_configuration`, `extended_s3_configuration { buffering_size, buffering_interval }`. |
| Firehose's permissions | `aws_iam_role` + policy | Needs **both** stream reads (`GetRecords`, `GetShardIterator`, `DescribeStream`, `ListShards`) **and** destination writes. |

## Key facts, limits & pricing

- **A stream is a set of shards**; a shard is a uniquely identified sequence of records. A **record** = sequence number + partition key + data blob.
- **Retention:** default **24 hours**, **minimum 24 hours** (you cannot go below), maximum **8,760 hours / 365 days**. Above 24 hours incurs an additional charge.
- **Per-shard throughput:** writes **1 MB/sec** or **1,000 records/sec**; reads **2 MB/sec** with at most **5 `GetRecords` transactions/sec**. A single `GetRecords` call returns at most **10 MB** or **10,000 records**; if it returns 10 MB, calls in the next 5 seconds throw.
- **Partition keys** are Unicode strings up to **256 characters**, mapped to shards by an **MD5 hash** over the shards' hash-key ranges. A partition key is **required** on every write.
- **Sequence numbers** are unique per partition key within a shard and generally increase over time. AWS warns they must **not** be used as indexes into a dataset.
- **Capacity modes:** *provisioned* — you set the shard count, billed hourly per shard, and reshard with `UpdateShardCount` / split / merge. *On-demand* — AWS scales shards automatically; new streams start at **4 MB/sec write and 8 MB/sec read**, scaling to **10 GB/s write / 20 GB/s read** in N. Virginia, Oregon and Ireland (200 MB/s / 400 MB/s elsewhere). You can switch modes **twice in 24 hours**.
- **Consumers:** *shared fan-out* splits the shard's 2 MB/sec; *enhanced fan-out* gives each registered consumer its own 2 MB/sec, pushed via `SubscribeToShard`. **Up to 20 registered consumers per stream** (50 on On-demand Advantage). Multiple applications can consume one stream **independently and concurrently**.
- **Kinesis Client Library** stores consumption metadata in **DynamoDB** — three tables per application — and guarantees one record processor per shard.
- **Server-side encryption** uses KMS; producers and consumers both need permission on the key.
- **Firehose:** fully managed, **no shards and no retention**. Buffers by **size (MB)** or **interval (seconds)**, delivering when either threshold is reached. A record may be up to **1,000 KB**. Can invoke a **Lambda** to transform records before delivery, and optionally back up the untransformed source to a second S3 bucket.
- **Firehose destinations:** Amazon S3, Amazon Redshift (delivered to S3 first, then loaded with a `COPY`), OpenSearch Service and OpenSearch Serverless, Splunk, Apache Iceberg tables, custom HTTP endpoints, and partners including Datadog, Dynatrace, LogicMonitor, MongoDB, New Relic, Coralogix and Elastic.
- **Firehose can read directly from a Kinesis data stream** as its source.
- **Pricing:** Kinesis Data Streams has **no free tier**. Provisioned is **$0.015 per shard-hour** (~$10.80/month for one shard) plus PUT payload units; on-demand is **$0.040/hour per stream** plus $0.08/GB in and $0.040/GB out. Firehose bills per GB ingested. ⚠️ check current pricing.
- ⚠️ **Record size — AWS's own pages disagree.** The concepts page says a data blob may be **up to 1 MB**; the quotas page says the payload may be **up to 10 MiB**, handled with burst capacity for intermittent large records. **1 MB is the classic exam answer**; know the 10 MiB burst allowance exists.

## Comparisons

### SQS vs SNS vs Kinesis

|   | **SQS** | **SNS** | **Kinesis Data Streams** |
|---|---|---|---|
| Model | queue | pub/sub | **append-only log** |
| After a consumer reads | **deleted** | delivered, gone | **stays until retention expires** |
| Consumers per message | **one** | every subscriber, once | **many, independently, repeatedly** |
| Replay history | ❌ | ❌ | ✅ up to 365 days |
| Ordering | FIFO queues only | ❌ | **within a shard** |
| Scaling unit | none — automatic | none | **shards** |
| Reach for it when | work to be done once | notify several things now | analytics, real-time processing, replay |

### Data Streams vs Firehose

|   | **Kinesis Data Streams** | **Amazon Data Firehose** |
|---|---|---|
| Nature | a durable **store** | a **delivery pipeline** |
| You manage | shards, consumers | **nothing** |
| Retention / replay | 24 h – 365 days | **none** |
| Latency | real time | **near** real time (buffered) |
| Consumers | you write them | you pick a destination |
| Transform | in your consumer | built-in **Lambda transform** |
| Trigger phrase | "custom processing", "multiple consumers", "replay" | "no code", "just land it in S3/Redshift/OpenSearch/Splunk" |

## Worked examples

> [!example] Worked example — the clickstream two teams need
> Clickstream events must feed a real-time fraud detector *and* an hourly batch analytics job, and a third team will later reprocess last week's data against a new model. **SQS is wrong**: a message consumed by fraud detection is deleted and analytics never sees it. SNS fan-out into two queues fixes the sharing but not the replay — nothing can re-read last Tuesday. **Kinesis Data Streams** is the fit: both consumers read the same shards independently at their own position, and with retention set beyond a week the third team can start from an older point in the stream. Partition by `user_id` so one user's events stay ordered while users spread across shards. If the batch job simply needs the raw events in S3 rather than custom processing, attach a **Firehose** to the same stream and let it archive — no consumer code at all.

> [!failure] Failure mode — the hot shard
> A team streams IoT telemetry and picks `device_type` as the partition key. There are four device types and eight shards. Every record hashes to one of four shards; the other four sit idle, and one popular device type saturates its shard's 1 MB/sec while the stream as a whole is at a quarter of capacity. `ProvisionedThroughputExceededException` appears under a load the stream should handle easily, and adding shards **doesn't help** because the key still only produces four hash values. The fix is a **high-cardinality** partition key — `device_id` — which spreads records evenly while still keeping each individual device's events in order.

> [!example] Worked example — sizing by the right ceiling
> An application produces 800 records per second, each about 500 bytes — 400 KB/sec in total. By data volume, one shard (1 MB/sec) looks like plenty. But the other ceiling is **1,000 records/sec**, and at 800 the stream is already at 80% of it. A modest traffic increase starts throttling writes despite the stream carrying less than half its byte capacity. Always size against **both** limits and provision for whichever binds first.

## Traps

> [!warning] Trap — SQS chosen where replay or multiple consumers are needed
> The single most-tested distinction here. SQS **deletes** a message once processed, so a second consumer can never see it and nothing can be re-read. Any scenario with "several teams need the same data", "reprocess historical events", or "replay the last N days" is **Kinesis**, not SQS — and SNS fan-out only solves the sharing half, never the replay.

> [!warning] Trap — assuming ordering across the whole stream
> Kinesis guarantees order **within a shard**, not across the stream. Two records with different partition keys may be processed in any relative order. Guaranteeing order for a logical entity means giving all its records the **same partition key** — exactly like `MessageGroupId` in FIFO SQS ([[15-decoupling]]).

> [!warning] Trap — a low-cardinality partition key
> Adding shards does nothing if the partition key only produces a handful of hash values. A key like `region` or `event_type` concentrates traffic on a few shards while the rest idle, and the stream throttles far below its nominal capacity. High cardinality is the requirement.

> [!warning] Trap — Firehose expected to store or replay
> Firehose has **no retention period** and no concept of re-reading. It buffers briefly and delivers. If a question needs data kept, re-read, or consumed by several independent applications, that is **Data Streams** — Firehose is only the pipe that gets it to a destination.

> [!warning] Trap — Firehose treated as real-time
> Firehose buffers by size *or* interval before delivering, so it is **near** real-time — seconds to minutes, not milliseconds. A requirement for sub-second reaction rules it out on its own; that's Data Streams with a consumer, or enhanced fan-out if latency really matters.

> [!warning] Trap — forgetting that read throughput is shared
> A shard's **2 MB/sec read is split across all consumers** using the default shared fan-out. Add a third consumer and each gets roughly 700 KB/sec, and they'll start hitting `ProvisionedThroughputExceeded` on reads. "Multiple consumers each needing full throughput" points at **enhanced fan-out**, not more shards.

> [!example]- Recall drill
> (1) What happens to a Kinesis record once a consumer reads it? (2) A shard's write and read limits? (3) How is a record assigned to a shard, and what does that mean for ordering? (4) Data Streams or Firehose: "land these logs in S3, we don't want to write or run anything"? (5) Why might adding shards fail to fix throttling? (6) What does enhanced fan-out change?
> > [!success]- Answers
> > (1) Nothing — it stays until the retention period expires (24 h default, up to 365 days). There is no delete. (2) Write **1 MB/sec or 1,000 records/sec**; read **2 MB/sec**, shared across consumers. (3) The **partition key** is MD5-hashed onto the shards; ordering is guaranteed **only within a shard**. (4) **Firehose** — no code, no consumers, no shards. (5) A **low-cardinality partition key** still hashes to only a few shards, so the new ones stay empty. (6) Each registered consumer gets its **own 2 MB/sec per shard**, pushed rather than polled, up to 20 consumers.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Shards** — I knew the database-sharding idea but not that a shard is *both* a partition and a fixed throughput unit, and I had the limit as "1 MB/s equals 1,000 records/s" when it is **either/or**, whichever binds first.
- [ ] **Data Streams vs Firehose** — I was genuinely confused between them. The resolution: **Streams stores and you build the consumer; Firehose delivers and you build nothing.**
- [ ] **Ordering is per shard, not per stream** — and it is the same mechanic as `MessageGroupId` in FIFO SQS, which I already knew.
- [ ] **Read throughput is shared between consumers** unless enhanced fan-out is used.
- [ ] ⚠️ **Never built** — Kinesis and Firehose are blocked on this AWS account's Free plan (`SubscriptionRequiredException`), so none of this has been observed live.

## 🔗 Docs

- [Kinesis Data Streams terminology and concepts](https://docs.aws.amazon.com/streams/latest/dev/key-concepts.html) — shards, partition keys and the MD5 mapping, sequence numbers, retention 24 h–365 days, capacity modes, KCL/DynamoDB; verified 2026-09-06
- [Kinesis Data Streams quotas and limits](https://docs.aws.amazon.com/streams/latest/dev/service-sizes-and-limits.html) — per-shard write/read limits, `GetRecords` sizes, enhanced fan-out consumer counts, on-demand throughput by Region, the 10 MiB payload note; verified 2026-09-06
- [What is Amazon Data Firehose](https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html) — destinations, buffer size and interval, Lambda transform, the Redshift-via-S3 path, reading from a data stream; verified 2026-09-06
- [Kinesis Data Streams pricing](https://aws.amazon.com/kinesis/data-streams/pricing/) — $0.015/shard-hour, on-demand rates, **no free tier**; verified 2026-09-06
- [Terraform `aws_kinesis_stream`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream) / [`aws_kinesis_firehose_delivery_stream`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream)

---
**Cards for this topic:** [[cards/16-kinesis-cards]]
