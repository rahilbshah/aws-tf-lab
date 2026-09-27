---
decision: analytics
question: How should this data be queried?
spans: [22-analytics, 16-kinesis, 09-s3-advanced]
tags: [decision, domain/performance]
---

# How should this data be queried?

The notes explain each engine. This routes you to one. Work top-down — the first
question that applies settles it, and §1–§3 settle most scenarios before you ever
reach the SQL engines.

## 1. Has the data landed yet?

Every engine below reads **stored** data; if the records are still in motion you are
choosing an ingest path, not an engine. The axis is **who reads it, and does
anything need to re-read it?**

| The requirement | Answer |
|---|---|
| Compute *on the stream itself*, continuously | **Managed Service for Apache Flink** (ex-Kinesis Data Analytics) |
| Several independent readers, or replay of past records | **Kinesis Data Streams** — you write the consumers |
| Just land it somewhere queryable, no code | **Firehose** → S3 (or Redshift / OpenSearch) |
| Kafka APIs, tooling or expertise already in play | **MSK** |

Usually it is both: a stream for the real-time consumer, a Firehose off that same
stream archiving to S3 for everything below.

↳ [[16-kinesis#Data Streams vs Firehose — a store versus a pipe]] · [[22-analytics#Kinesis vs MSK]]

## 2. Is this a transaction or an analysis?

Ask **one row at a time, or a scan?** Many small reads and writes against current
state is OLTP — RDS or Aurora, and the wrong page. Few enormous aggregate queries
over history is OLAP, and everything below assumes it. Loading years of history
into RDS to aggregate it is a standing wrong answer; so is putting an
application's live tables in Redshift.

↳ [[22-analytics#Redshift vs RDS/Aurora]]

## 3. What language does the question arrive in?

Not the size of the data — the **shape of the question**. These three aren't ranked
against each other; they answer different kinds of question.

- **Free text, relevance ranking, or a live dashboard over recent logs** →
  **OpenSearch**. It is the only thing here that does search at all.
- **Existing Spark/Hadoop/Hive code, or ML feature prep** → **EMR**. Pick it
  because you have code to run, never because the dataset is large.
- **SQL** → §4.

↳ [[22-analytics#OpenSearch — search and logs, not reporting]] · [[22-analytics#EMR — when you genuinely need the Hadoop/Spark ecosystem]]

## 4. SQL — is there a load step?

- **No load; data stays in S3; queries ad-hoc or intermittent** → **Athena**. Nothing
  runs between queries; "no infrastructure" and "least operational overhead" land here.
- **Loaded into the engine; sustained concurrency; complex multi-table joins** →
  **Redshift**. A cluster earns its keep only under continuous load.
- **Both at once** — hot months in the cluster, cold years in S3, joined in one
  query → **Redshift Spectrum**. It still requires a running cluster, in the
  **same Region** as the data.

↳ [[22-analytics#The four query engines]] · [[22-analytics#Which engine does the exam mean?]]

## 5. Can the engine see the schema?

Ask **does anything already know this is a table?** Raw objects in a prefix aren't
queryable until something describes them: a **Glue Crawler** infers the schema into the
**Glue Data Catalog**, which Athena, EMR and Redshift Spectrum all read. Define it once.
If the restriction is *which columns or rows a person may see*, that is **Lake
Formation** over the catalog — not a bucket policy.

↳ [[22-analytics#The remaining in-scope names, briefly]]

## 6. Who reads the answer?

Ask **a person or a program?** A program takes the result. A person wants a
dashboard — **QuickSight**, on top of whatever §4 chose, not instead of it. If the
source bills per query, **import into SPICE** rather than direct query, so one scan
serves every viewer.

## 7. "It costs too much" is not an engine choice

Athena bills per byte scanned and has nothing to resize, so any answer offering more
nodes or bigger instances is wrong by construction. The fix is **layout** — columnar
format, compression, partition prefixes — decided when the data is *written*, at §1.

↳ [[22-analytics#Athena — SQL on S3, and you pay per byte you touch]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **Firehose treated as a query layer** because it lists Redshift and OpenSearch as
  destinations. It only delivers; picking the destination is still §4's decision, and
  picking wrong just means the wrong engine now owns the data.
- **Stream retention mistaken for a queryable archive.** 365 days sounds like
  history analysts can reach, but nothing runs SQL against a stream. Replay serves a
  consumer reprocessing records; analysts still need the Firehose-to-S3 leg.
- **S3 Select where Athena belongs.** Both are SQL over S3, but S3 Select reads a
  **single object** and is closed to new customers. A prefix or a table means Athena.
- **Replicating data to give a second engine access.** CRR/SRR copies bytes; what was
  missing was a **catalog entry**. One crawler, one catalog, three engines — no copy.
- **Spectrum chosen to avoid provisioning a warehouse.** It *is* the warehouse plus
  an external table. "Query S3 with no cluster" is Athena, full stop.
- **EMR chosen because the data is big.** Volume never decides it — Athena scans
  petabytes happily. EMR is for framework code that must run.
