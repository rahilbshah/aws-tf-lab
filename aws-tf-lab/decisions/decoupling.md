---
decision: decoupling
question: How should these components talk?
spans: [15-decoupling, 16-kinesis, 24-other-services]
tags: [decision, domain/resilient]
---

# How should these components talk?

The notes explain each messaging service. This routes you to one. Work top-down — the
first question that applies settles it, and you rarely need more than two.

## 1. Does the caller need the answer to carry on?

The deciding question is **whether the caller can walk away**. If it needs a response in
the same request, no queue helps — you want a synchronous API, and the only thing left to
pick is the API style: REST/HTTP/WebSocket → **API Gateway**; GraphQL over several data
sources → **AppSync**. Everything below assumes the caller writes and moves on.

↳ [[24-other-services#AWS AppSync — managed GraphQL]]

## 2. Is this work to be done, or a record to be read?

The axis is **what should still exist once a consumer has handled it**.

- **Nothing — the item is done** → **SQS**: one consumer takes it, deletes it. Go to §3.
- **The record itself, still readable** → **Kinesis Data Streams**. Nothing is ever
  deleted; it ages out on retention. Go to §5.

"Several consumers" is *not* the tell — fan-out gives each its own copy. **Re-reading**
is: a consumer starting later, or going back over last Tuesday. Only a log does that.

↳ [[16-kinesis#SQS vs SNS vs Kinesis]]

## 3. SQS — how many things care about this message?

- **One** → a queue, directly.
- **Several, independently** → **SNS topic → one SQS queue per consumer.** That queue
  is not decoration: SNS delivers but does not hold, so a Lambda or HTTP subscriber
  that is down loses the message outright.
- **A person, not a system** — email, SMS, push → **SNS** alone. SQS never does this.

↳ [[15-decoupling#SNS is push, SQS is pull — and the pattern that uses both]]

## 4. SQS — standard or FIFO?

The axis is **whether some entity's events must be serialised**, not whether "ordering
matters" in the abstract. Real requirements are per customer or per device, not global.

- **No such entity** → **standard**. Effectively unlimited throughput.
- **There is one** → **FIFO**, with that entity as the `MessageGroupId`. Different
  groups run in parallel, which is how you buy throughput back from the 300 TPS
  per-action ceiling. One *global* order at high volume means you are fighting the
  service: high-throughput FIFO, or challenge the requirement.

↳ [[15-decoupling#Standard vs FIFO — what strict ordering costs]]

## 5. Kinesis — are you writing a consumer, or just landing the data?

- **Writing one** — custom processing, sub-second reaction, replay → **Data Streams**.
- **Landing it** in S3, Redshift, OpenSearch or Splunk with no code → **Firehose**.
  It buffers before delivering, so near-real-time, and it keeps nothing.
- **Both, the usual answer** → a stream, your consumer, and a Firehose archiving to S3.

Then, if you chose Data Streams: **are the consumers starving each other?** A shard's
read throughput is split across all of them by default — **enhanced fan-out**, not shards.

↳ [[16-kinesis#Data Streams vs Firehose — a store versus a pipe]] · [[16-kinesis#Reading: shared fan-out versus enhanced fan-out]]

## 6. Is the conversation actually a sequence?

A queue is a handoff. Several steps with **state between them** — branching, retries, a
step that waits — need an orchestrator instead: **Step Functions**. Pick the type on
**duration and volume**, not on which sounds more robust: waiting on a human, or needing
exactly-once and an audit trail → **Standard**; tens of thousands of short executions a
second → **Express**.

↳ [[24-other-services#Step Functions — orchestration, and one table that gets tested]] · [[24-other-services#Step Functions — Standard vs Express]]

## 7. Can the messaging code be rewritten?

Asked last because it overrides everything above. If an existing application already
speaks **AMQP, MQTT, STOMP or OpenWire** and its messaging code is not being touched,
nothing above is available — SQS and SNS speak only the AWS API. That is **Amazon MQ**, a
broker billed per hour. No named protocol, no legacy system → MQ is the distractor.

↳ [[15-decoupling#When neither fits: Amazon MQ]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **"Two teams need this" routed to SNS fan-out.** Fan-out solves *sharing*; each
  queue's copy still vanishes on processing. If anyone will read from the past, the
  requirement was replay — only Kinesis has it.
- **A queue and a Lambda written to put records into S3.** That is Firehose with extra
  steps. A queue is for when something must *do* work; Firehose is for pure delivery.
- **Step Functions used as a buffer.** Orchestration does not absorb rate. Fast
  producer, slow consumer → a queue; steps that must run in order and can each fail →
  Step Functions. Both is normal — the workflow sits behind the queue.
- **Assuming "exactly-once" is one property.** SQS **FIFO** has it, standard SQS does
  not; Step Functions **Standard** has it, **Express** does not. Pick the component that
  carries the guarantee, and keep the consumer idempotent anyway.
- **Ordering keys chosen for ordering alone.** A FIFO `MessageGroupId` and a Kinesis
  partition key are one mechanic with two failure modes: too few groups serialises you,
  too few key values idles most shards while one throttles. Highest cardinality that
  still keeps the entity together.
- **"Real-time" read as a streaming problem.** A client that must see updates as they
  happen is **AppSync** subscriptions over WebSockets. Kinesis is for a *pipeline* that
  reacts in real time. Same word, different component.
