---
topic: 16-kinesis
domain: performance
related_note: 16-kinesis
tags: [flashcards/kinesis]
---

# Cards for [[16-kinesis]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What happens to a Kinesis record after a consumer reads it?
?
Nothing — it stays. There is no delete operation for a Kinesis record. It ages out only when the retention period expires. That is the fundamental difference from SQS, where processing deletes the message: SQS is a to-do list, Kinesis is a ledger where each reader keeps its own bookmark.

What is the Kinesis Data Streams retention period?
?
Default AND minimum 24 hours — you cannot go below it. Maximum 8,760 hours (365 days). Anything above 24 hours costs extra. That retention is what makes replay possible: a new consumer can start reading from any point still inside the window.

What are a single shard's throughput limits?
?
Writes: 1 MB/sec OR 1,000 records/sec — whichever you hit FIRST, not "equals". Reads: 2 MB/sec, with at most 5 GetRecords calls per second. A stream's total capacity is the sum of its shards, which is also how provisioned mode bills you (per shard-hour).

Why can a stream throttle while carrying well under 1 MB/sec?
?
Because the record-count ceiling binds first. 800 records/sec of 500-byte records is only 400 KB/sec — comfortably under the 1 MB/sec byte limit — but already 80% of the 1,000 records/sec limit. Always size against BOTH per-shard limits and provision for whichever binds first.

How does Kinesis decide which shard a record goes to?
?
Every record carries a partition key (a Unicode string up to 256 characters). Kinesis runs it through an MD5 hash and maps the result onto the shards' hash-key ranges. Same key always lands on the same shard. A partition key is required on every write.

Is ordering guaranteed across a Kinesis stream?
?
No — only WITHIN a shard. Records in a shard have increasing sequence numbers so a consumer reads them in order, but two records that hashed to different shards have no defined order relative to each other. To guarantee order for a logical entity, give all its records the SAME partition key. This is exactly the same mechanic as MessageGroupId in a FIFO SQS queue.

What is a hot shard and why doesn't adding shards fix it?
?
A low-cardinality partition key (device_type, region, event_type) only produces a handful of hash values, so records concentrate on a few shards while the rest sit idle. The stream throttles far below nominal capacity. Adding shards doesn't help — the key still hashes to the same few values. The fix is a HIGH-cardinality key such as device_id or user_id, which spreads load while still keeping each entity's records ordered.

Kinesis Data Streams vs Amazon Data Firehose — the one-sentence difference?
?
Data Streams is a place data is KEPT; Firehose is a way data is MOVED. Streams has shards you size, a retention period, and consumers you write and run. Firehose has no shards, no retention, and no consumers — you pick a destination and it delivers, buffering first.

What does Firehose buffer on, and what does that mean for latency?
?
Buffer size (in MB) and buffer interval (in seconds) — it delivers when EITHER threshold is reached, whichever comes first. Because it always buffers, Firehose is NEAR real-time (seconds to minutes), not real-time. Any requirement for sub-second reaction rules it out.

What destinations can Firehose deliver to?
?
Amazon S3, Amazon Redshift (delivered to S3 first, then loaded with a COPY command), OpenSearch Service and OpenSearch Serverless, Splunk, Apache Iceberg tables, any custom HTTP endpoint, and partners including Datadog, Dynatrace, MongoDB, New Relic, Coralogix and Elastic.

Can Firehose and Data Streams be used together?
?
Yes, and it's the standard production shape. Firehose can take a Kinesis data stream as its SOURCE. Producers write once to the stream; your real-time consumers read it, and a Firehose quietly archives everything to S3 with no consumer code at all.

Can Firehose replay data?
?
No. Firehose has no retention period and no concept of re-reading — it buffers briefly and delivers. Once delivered, the data is only wherever it was sent. Anything needing replay, history, or multiple independent consumers is Data Streams.

Shared fan-out vs enhanced fan-out?
?
Shared fan-out (the default) splits a shard's 2 MB/sec read throughput across ALL consumers — add a third consumer and each gets roughly 700 KB/sec. Enhanced fan-out gives each REGISTERED consumer its own 2 MB/sec per shard, pushed via SubscribeToShard rather than polled, with lower latency. Up to 20 registered consumers per stream. It costs more.

Provisioned vs on-demand capacity mode?
?
Provisioned: you set the shard count and are billed per shard-hour; you reshard yourself with UpdateShardCount, split and merge. On-demand: AWS manages shards automatically and bills per GB, starting at 4 MB/sec write and 8 MB/sec read and scaling far higher. You can switch between the two modes twice in any 24 hours.

Where does the Kinesis Client Library store its progress?
?
In DynamoDB — it creates three tables per application. So a Kinesis consumer has a quiet DynamoDB dependency, and its IAM role needs DynamoDB permissions as well as Kinesis ones. The KCL also guarantees one record processor per shard.

SQS or Kinesis: several teams need to read the same events, and one wants to reprocess last week's?
?
Kinesis. SQS deletes a message once processed, so a second consumer never sees it, and nothing can be re-read. SNS fan-out into two queues solves the sharing but still not the replay. Kinesis keeps every record for its retention period, and each consumer tracks its own position independently.
