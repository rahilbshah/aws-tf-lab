---
topic: 15-decoupling
domain: resilient
status: reviewed
services: [SQS, SNS, AmazonMQ]
related: [04-alb-asg, 14-dr-resilience, 09-s3-advanced, 08-elasticache]
revision: revision/15-decoupling-revision
tags: [topic, domain/resilient]
---

# 15 – Decoupling (SQS, SNS, Amazon MQ)

Getting a message from one component to another without the two having to be up at the same time. The single most-tested *architectural pattern* on SAA-C03 — it shows up inside questions that look like they're about something else.

> [!note] Build tier — **built (free)**
> SQS and SNS are comfortably inside the always-free tier at lab volumes. Built hands-on in `../15-decoupling/`, and the observations below are from that lab, not from the docs.

## What problem does this solve?

Service A calls service B directly. B goes down for ten minutes.

Every request A makes in those ten minutes **fails and is gone**. Worse, A is now stuck too — its threads are blocked waiting on a dead service, so A starts failing for reasons that have nothing to do with A. One component's outage became two.

That's *tight coupling*: A and B have to be healthy **at the same instant**, and A has to be able to handle B's traffic **at the same rate**.

Put a queue between them and both of those go away. A writes a message and moves on. The message sits there. When B recovers, it works through the backlog. Nobody lost anything, and A never noticed.

The same structure absorbs a traffic spike. If A produces 10,000 orders a minute and B can handle 1,000, the queue holds the difference instead of B falling over.

> In one line: a queue means the two services no longer have to be healthy at the same moment, or fast at the same rate.

## How it actually works

### The queue is a shock absorber, not a pipe

A **producer** writes to the queue. A **consumer** polls it. That's it — but note what's absent: the producer has no idea whether a consumer exists, how many there are, or whether any of them are working.

That indifference is the whole point. You can add consumers to drain a backlog faster, take them all offline for a deploy, or have one crash mid-job, and the producer's code never changes.

The messages don't vanish while nobody's looking. SQS keeps them for a **retention period** — **4 days by default**, adjustable from **60 seconds up to 14 days**. That's your outage budget: as long as consumers come back inside it, nothing is lost.

> In one line: the producer writes and forgets, the queue holds for up to 14 days, and consumers can come and go without the producer knowing.

### Receiving is not deleting — and that's deliberate

Here is the mechanic that everything else in SQS hangs off, and it surprises people.

When a consumer receives a message, **the message is not removed**. It becomes **invisible** to other consumers for the **visibility timeout** — 30 seconds by default, up to 12 hours. The consumer is expected to do its work and then explicitly call `DeleteMessage`.

If it never does — because it crashed, or was slow, or the instance was terminated — the timeout expires and **the message becomes visible again** for someone else to pick up.

That's not a bug. It's the only way a queue can survive a consumer dying mid-job. The cost is that SQS is **at-least-once**: a message can be delivered more than once, so consumers must be **idempotent** — processing the same order twice must not charge the customer twice.

Two practical consequences:

- **Set the visibility timeout longer than your processing takes.** Too short and a second consumer picks up a job still being worked on, and you do it twice.
- **Deleting needs the receipt handle, not the message ID.** A receipt handle is issued per *receive*, not per message, so it changes every time the message reappears.

> In one line: a received message is hidden, not deleted, and it comes back if you never delete it — which is why consumers must be idempotent.

### What stops the loop: the dead-letter queue

Now follow that mechanic to its unhappy conclusion. A message that *always* fails — malformed, or triggering a bug — is received, fails, reappears, is received, fails, reappears. Forever, until retention expires days later, burning a consumer every cycle.

A **dead-letter queue** is the circuit breaker. You attach a **redrive policy** naming a second queue and a **`maxReceiveCount`**. After that many receives without a delete, SQS moves the message to the DLQ instead of back to the queue. Your consumers stop choking on it, and you have somewhere to look at what went wrong.

We saw both halves of this live in the lab, side by side:

| | redrive policy | outcome |
|---|---|---|
| **queue A** | `maxReceiveCount = 3` | message moved to the DLQ after 3 receives |
| **queue B** | none | **same message still in the queue at 14 receives and climbing** |

One detail that catches people out. For a **standard** queue, a message keeps its **original enqueue timestamp** when it moves to the DLQ. A message that spent 3 days in the source queue arrives in a DLQ *already 3 days old* — so if both have 4-day retention, you get one day to look at it. Give the DLQ a **longer** retention than the source. (FIFO queues reset the clock instead.)

> In one line: without a DLQ a poison message loops until retention expires; with one it steps aside after maxReceiveCount — and the DLQ needs longer retention because a standard-queue message arrives carrying its original age.

### SNS is push, SQS is pull — and the pattern that uses both

**SQS** is a queue: one message, consumed by **one** consumer, which **pulls** it.

**SNS** is publish/subscribe: one message published to a **topic** is **pushed** to **every** subscriber. Subscribers can be SQS queues, Lambda functions, HTTP(S) endpoints, email, SMS, mobile push, Amazon Data Firehose, and third-party providers. That split is why SNS covers both **application-to-application** and **application-to-person** messaging — SQS only ever does the former.

The pattern that matters is **fan-out**: publish once to a topic, and have several **SQS queues** subscribed to it.

Why put a queue between SNS and each service, rather than letting SNS deliver straight to them? Because **SNS delivers, it doesn't hold**. If a service is down, a direct HTTP or Lambda delivery has nowhere to land. A queue in front of each consumer gives every one of them its own buffer, its own retry behaviour, and its own backlog — so one slow consumer can't affect the others.

One thing you only notice by looking at real data: the queue does **not** receive your raw message. It receives a JSON envelope with the payload nested inside `.Message`, alongside `TopicArn`, `MessageId`, a signature and an unsubscribe URL. Every consumer has to unwrap that — which is what the **raw message delivery** subscription setting turns off.

And SNS won't deliver anywhere it hasn't been allowed to. A queue **rejects everything by default**, so the queue's own resource policy must permit the `sns.amazonaws.com` service principal — pinned with a condition on `aws:SourceArn`, because that principal is identical for every AWS customer. Without the policy the subscription exists, the publish succeeds, and the message **silently never arrives**.

> In one line: SNS pushes one message to every subscriber, SQS holds one message for one consumer, and fan-out puts a queue in front of each service so one being down doesn't lose anything.

### Standard vs FIFO — what strict ordering costs

Standard queues make two compromises you rarely think about: ordering is **best-effort**, and delivery is **at-least-once** (duplicates possible). In exchange, throughput is effectively **unlimited**.

**FIFO queues** remove both compromises. Strict ordering, exactly-once processing. The price is throughput: **300 transactions per second** per API action per partition, or **3,000 messages/second** with batching (300 calls × 10 messages). **High-throughput mode** lifts that a great deal — up to 70,000 TPS in the largest Regions, far less elsewhere — but it's an opt-in you have to know exists.

Two required-ish arguments come with FIFO:

- **`MessageGroupId`** is mandatory. Messages sharing a group are strictly ordered; **different groups process in parallel**. That's how you get throughput back — one group per customer, say, rather than one group for everything.
- **`MessageDeduplicationId`** gives a **5-minute deduplication window**. Or turn on content-based deduplication and SQS hashes the message **body** (SHA-256, body only, not attributes) to build the ID for you.

> In one line: FIFO buys strict ordering and exactly-once with two to three orders of magnitude less throughput, and message groups are how you buy some of it back.

### When neither fits: Amazon MQ

SQS and SNS are excellent and they are also **AWS-proprietary APIs**. If you have an application already speaking a standard broker protocol to ActiveMQ or RabbitMQ on-premises, adopting them means rewriting its messaging code.

**Amazon MQ** is AWS running **Apache ActiveMQ Classic** or **RabbitMQ** for you. AWS's own positioning is the exam trigger: *migrate existing message brokers "without rewriting messaging code."*

The trade-off is that it's a **broker**, not a serverless service. You choose a deployment: a **single-instance broker** (one broker, one AZ, EBS or EFS storage) or an **active/standby pair** (two brokers in two AZs on EFS, only one active, failover in seconds). It runs in your VPC on a private endpoint, and it does not scale the way SQS does.

So: **a new application on AWS → SQS/SNS. An existing application you don't want to rewrite → Amazon MQ.**

> In one line: Amazon MQ exists so a legacy app speaking a standard broker protocol can move to AWS without a rewrite — and that migration framing is the only reason to pick it.

## Exam recap

> [!info] Exam TL;DR
> - **A queue decouples in time and rate.** Producer and consumer no longer need to be healthy at the same moment, or fast at the same rate.
> - **SQS retention:** default **4 days**, min **60 seconds**, max **14 days**.
> - **Receiving is not deleting.** A received message goes invisible for the **visibility timeout** (default **30s**, max **12 hours**) and **reappears** if not deleted. Delivery is therefore **at-least-once** — consumers must be **idempotent**.
> - **Dead-letter queue** = redrive policy + **`maxReceiveCount`**. Without one, a poison message loops until retention expires. Give the DLQ **longer retention**, because a standard-queue message keeps its **original enqueue timestamp** (FIFO resets it).
> - **Short polling is the DEFAULT** and samples only a subset of servers, so it can return empty while messages exist. **Long polling** (`WaitTimeSeconds` up to **20 seconds**) queries all servers, cuts empty responses and costs less.
> - **SNS pushes to every subscriber; SQS holds for one consumer that pulls.** SNS endpoints: SQS, Lambda, HTTP(S), email, SMS, mobile push, Firehose. **A2A and A2P**; SQS is A2A only.
> - **Fan-out** = SNS topic → several SQS queues, so each consumer gets its own buffer and retries.
> - The queue receives an **SNS JSON envelope**, not your raw payload — unless **raw message delivery** is enabled.
> - A queue **rejects SNS by default**: its resource policy must allow `sns.amazonaws.com`, pinned with **`aws:SourceArn`**.
> - **Standard** = unlimited throughput, best-effort order, at-least-once. **FIFO** = strict order, exactly-once, **300 TPS** (**3,000/sec** batched) unless high-throughput mode. **`MessageGroupId`** required; different groups run in parallel. **`MessageDeduplicationId`** = **5-minute** window.
> - **Max message size is 1 MiB** — most course material still says 256 KB. Larger payloads go in S3 via the Extended Client Library (up to 2 GB).
> - **Amazon MQ** = managed ActiveMQ/RabbitMQ, for **migrating an existing app without rewriting its messaging code**. Single-instance or active/standby across two AZs.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| A queue | `aws_sqs_queue` | `visibility_timeout_seconds`, `message_retention_seconds`, `receive_wait_time_seconds` (long polling), `delay_seconds`. |
| A FIFO queue | same, `fifo_queue = true` | Name **must** end `.fifo`. `content_based_deduplication` optional. |
| Dead-letter queue | a second `aws_sqs_queue` + `redrive_policy` on the source | `redrive_policy = jsonencode({ deadLetterTargetArn = …, maxReceiveCount = … })`. |
| A topic | `aws_sns_topic` | `fifo_topic = true` for FIFO. |
| Fan-out wiring | `aws_sns_topic_subscription` | `protocol = "sqs"`, `endpoint` = the queue **ARN**. |
| Letting SNS in | `aws_sqs_queue_policy` + `aws_iam_policy_document` | Service principal + **`aws:SourceArn`** condition. `queue_url` takes the queue's `.id`. |
| Amazon MQ | `aws_mq_broker` | `engine_type`, `deployment_mode` (SINGLE_INSTANCE / ACTIVE_STANDBY_MULTI_AZ). |

## Key facts, limits & pricing

- **Retention:** default **4 days** (345,600s); minimum **60 seconds**; maximum **1,209,600 seconds (14 days)**.
- **Visibility timeout:** default **30 seconds**; minimum 0; maximum **12 hours**.
- **Message size:** minimum 1 byte, **maximum 1,048,576 bytes (1 MiB)**. For larger, the Extended Client Library stores the payload in S3 and puts a reference in the message — up to **2 GB**. ⚠️ Most course material and many practice questions still say **256 KB**; know both.
- **Delay (message timer):** default 0, **maximum 15 minutes**.
- **Batching:** a single batch request carries at most **10 messages**. A message can carry up to **10 metadata attributes**.
- **Polling:** **short polling is the default** (`WaitTimeSeconds = 0`). It samples a *subset* of SQS servers, so it can return an empty response while messages exist — AWS calls these *false empty responses*. **Long polling** queries **all** servers, waits up to **20 seconds**, and reduces both empty responses and cost.
- **Standard queues:** nearly unlimited throughput per API action; **at-least-once** delivery; **best-effort ordering**.
- **FIFO queues:** **300 TPS** per API action per partition; **3,000 messages/second** with batching. **High throughput FIFO** (opt-in) raises this per Region — up to **70,000 TPS** non-batched in N. Virginia / Oregon / Ireland, **19,000** in Ohio and Frankfurt, **9,000** in Mumbai / Singapore / Sydney / Tokyo / Spain, **4,500** in London and São Paulo, **2,400** elsewhere; batching multiplies by 10.
- **`MessageGroupId`** is required on FIFO queues; the send fails without it. On **standard** queues it enables **fair queues**.
- **Deduplication:** FIFO rejects a duplicate `MessageDeduplicationId` sent within a **5-minute** interval. **Content-based deduplication** hashes the message **body** with SHA-256 — *not* the attributes.
- **Dead-letter queues:** the DLQ must be in the **same account and Region** as the source, and must be the **same queue type** — a FIFO queue's DLQ must be FIFO, a standard queue's DLQ must be standard. Separately, AWS advises against a DLQ on a FIFO queue at all if exact ordering matters. A **redrive allow policy** controls which source queues may use it: `allowAll` (default), `byQueue` (up to **10** source ARNs), or `denyAll`. For standard queues with `maxReceiveCount` **greater than 3**, a message received 3+ times without deletion is moved to the **back of the queue**.
- **DLQ retention clock:** **standard** queues keep the **original enqueue timestamp** when a message moves to the DLQ, so set the DLQ's retention **longer** than the source's. **FIFO** queues **reset** the timestamp on the move.
- **SNS subscribers:** Amazon SQS, Lambda, HTTP(S), email, SMS, mobile push, **Amazon Data Firehose**, and service providers such as Datadog, MongoDB and Splunk. Supports **A2A** and **A2P** messaging.
- **SNS FIFO topics deliver only over the SQS protocol** — no email, HTTP or Lambda subscribers — and can fan out to **both FIFO and standard** queues.
- **Subscription filter policies** let a subscriber receive only the messages it cares about, evaluated against message attributes or (with `FilterPolicyScope: MessageBody`) the body itself.
- **Amazon MQ deployment modes:** *single-instance* — one broker, one AZ, **EBS or EFS** storage; *active/standby* — two brokers in two AZs on **EFS**, only one active, with two endpoints per wire protocol (`-1`/`-2` suffixes) and failover in seconds on reboot. RabbitMQ offers **quorum queues** (leader + followers across AZs, good for poison messages); ActiveMQ offers **cross-Region data replication** with API-triggered failover.
- **Amazon MQ wire protocols** — this is the whole point of the service, and why a migration question picks it over SQS. *ActiveMQ*: **AMQP, MQTT, OpenWire, STOMP** (plus MQTT and STOMP over WebSocket). *RabbitMQ*: **AMQP 0-9-1**. If a scenario names a protocol, the answer is Amazon MQ — SQS and SNS speak only the AWS API.
- **Pricing:** SQS and SNS both have an always-free tier that covers lab use comfortably. **Amazon MQ bills per broker-hour** — it is a running server, not serverless.

## Comparisons

### SQS vs SNS

|   | **SQS** | **SNS** |
|---|---|---|
| Model | queue | publish/subscribe |
| Delivery | consumer **pulls** | SNS **pushes** |
| Who gets a message | **one** consumer | **every** subscriber |
| Holds messages | ✅ up to 14 days | ❌ delivers, doesn't hold (FIFO topics can *archive* for replay) |
| Consumer can be offline | ✅ | ❌ (unless the subscriber is a queue) |
| Endpoints | your consumers | SQS, Lambda, HTTP(S), email, SMS, push, Firehose |
| A2P (people) | ❌ | ✅ |

### Standard vs FIFO queues

|   | **Standard** | **FIFO** |
|---|---|---|
| Ordering | best-effort | **strict**, per message group |
| Delivery | **at-least-once** (duplicates) | **exactly-once** |
| Throughput | effectively unlimited | **300 TPS**, 3,000 batched (more with high-throughput mode) |
| Extra arguments | none | **`MessageGroupId`** required; dedup ID or content-based |
| Name | anything | must end **`.fifo`** |

### SQS vs SNS vs Amazon MQ

| The scenario says | Answer |
|---|---|
| buffer work between components, one consumer per message | **SQS** |
| one event, several independent consumers | **SNS** (fan-out into SQS queues) |
| notify *people* — email, SMS, push | **SNS** |
| existing app speaking a standard broker protocol, don't want to rewrite | **Amazon MQ** |
| strict ordering / no duplicates | **SQS FIFO** |

## Worked examples

> [!example] Worked example — the fan-out that made a second team possible
> An order service publishes to an SNS topic. Fulfilment subscribes via its own SQS queue; analytics subscribes via another. When analytics needs a two-hour maintenance window, its queue simply accumulates — fulfilment is untouched and the publisher never knows. Adding a third consumer later is one subscription and one queue, with **no change to the publisher at all**. Contrast the alternative: if SNS delivered straight to each service over HTTP, analytics being down would mean those notifications were simply lost. The queue in front of each subscriber is what turns "delivered" into "will be delivered eventually".

> [!failure] Failure mode — the poison message, observed both ways
> Built in the lab: two queues subscribed to one topic, identical except that queue A had a redrive policy with `maxReceiveCount = 3` and queue B had none. The same message was received repeatedly without being deleted. **Queue A's copy moved to the dead-letter queue after three receives.** **Queue B's copy was still in the queue at an `ApproximateReceiveCount` of 14 and climbing.** That is exactly what a poison message does to a production queue with no DLQ: it never fails loudly, it just consumes a worker every cycle for days until retention expires. The DLQ doesn't fix the message — it gets it out of the way and puts it somewhere you can look at it.

> [!example] Worked example — sizing the visibility timeout
> A consumer takes about 90 seconds to process a job, and the queue is left on the default 30-second visibility timeout. Thirty seconds in, the message becomes visible again and a second consumer starts the same job. Both finish; the customer is charged twice. Nothing errored, and the logs look normal. Two fixes: set the visibility timeout comfortably above the real processing time, or have long-running consumers call `ChangeMessageVisibility` periodically to extend their lease. And regardless — make the consumer **idempotent**, because at-least-once delivery means this can happen anyway.

## Traps

> [!warning] Trap — "receiving a message removes it"
> It does not. A received message is **hidden** for the visibility timeout and **comes back** unless the consumer explicitly calls `DeleteMessage`. Every "why was this processed twice?" scenario traces to this: a consumer that crashed, or took longer than the timeout. And deletion needs the **receipt handle**, which is issued per *receive*, not the message ID.

> [!warning] Trap — a queue with no dead-letter queue
> Without a DLQ there is no upper bound on retries. A message that always fails is redelivered until retention expires — up to 14 days of consumers repeatedly choking on the same thing. Any scenario mentioning messages that repeatedly fail, or a consumer stuck in a loop, is a DLQ question.

> [!warning] Trap — DLQ retention set equal to the source queue's
> For **standard** queues the message keeps its **original enqueue timestamp** when it moves. A message that sat 3 days in the source arrives in the DLQ already 3 days old, so equal retention leaves you a single day to investigate. Set the DLQ **longer**. (FIFO resets the clock, so this doesn't apply there.)

> [!warning] Trap — assuming an empty poll means an empty queue
> **Short polling is the default**, and it samples only a *subset* of SQS servers — so it can return nothing while messages are waiting. AWS calls these *false empty responses*. If a question mentions empty receives, wasted API calls, or unnecessary cost, the answer is **long polling** with `WaitTimeSeconds` up to **20 seconds**.

> [!warning] Trap — SNS delivering straight to a service instead of into a queue
> SNS **delivers, it does not hold**. Push it directly at a Lambda or HTTP endpoint that is down and the notification is lost. The queue in the fan-out pattern is not decoration — it is the buffer and the retry. "Must not lose events if a consumer is unavailable" means SNS **into SQS**, not SNS alone.

> [!warning] Trap — FIFO chosen without noticing the throughput ceiling
> FIFO's strict ordering and exactly-once cost you throughput: **300 TPS** per API action, 3,000/second batched, against a standard queue's effectively unlimited rate. If a scenario stresses very high volume *and* ordering, the answer usually involves **many message groups** (which process in parallel) or **high-throughput FIFO**, not plain FIFO.

> [!warning] Trap — Amazon MQ picked for a new application
> Amazon MQ exists for **migration**: an existing app already speaking a standard broker protocol that you don't want to rewrite. For anything new on AWS, SQS and SNS are cheaper, serverless and scale far better. If the question has no legacy system and no protocol requirement, MQ is the distractor.

> [!example]- Recall drill
> (1) What happens to a received message that is never deleted, and what does that imply about consumers? (2) What stops a poison message looping forever, and why should that queue's retention be longer? (3) Why put an SQS queue between SNS and each consumer? (4) Which polling mode is the default, and why is that a trap? (5) What does FIFO cost you, and how do you get some of it back? (6) When is Amazon MQ the right answer?
> > [!success]- Answers
> > (1) It becomes visible again after the visibility timeout — delivery is at-least-once, so consumers must be **idempotent**. (2) A **dead-letter queue** with `maxReceiveCount`; longer retention because a standard-queue message keeps its **original enqueue timestamp**. (3) SNS delivers but doesn't hold — the queue is the buffer, so a consumer being down loses nothing. (4) **Short polling** is the default and samples a subset of servers, so it can return empty while messages exist; long polling (up to 20s) fixes it. (5) Throughput — 300 TPS vs unlimited; use **multiple message groups** (they run in parallel) or high-throughput mode. (6) Migrating an existing app that speaks a standard broker protocol, without rewriting its messaging code.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Max SQS message size is 1 MiB, not 256 KB** — nearly all course material is stale here. Know both, since a practice question may still key the old figure.
- [ ] **Short polling is the DEFAULT** — I'd have assumed long polling was, and the "empty response with messages present" behaviour follows from it.
- [ ] **DLQ retention must exceed the source's** because of the original-enqueue-timestamp rule on standard queues.
- [ ] **Amazon MQ is a migration answer, not a design answer.**
- [ ] Got right first time and worth keeping: the SNS→SQS queue policy needs `sns.amazonaws.com` pinned with **`ArnEquals` on `aws:SourceArn`** — fourth appearance of the confused-deputy shape.

## 🔗 Docs

- [SQS message quotas](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/quotas-messages.html) — retention, visibility timeout, **1 MiB** message size, delay, batch size, FIFO and high-throughput TPS by Region; verified 2026-09-06
- [Short and long polling](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html) — short is the default, subset sampling, false empty responses, 20-second maximum; verified 2026-09-06
- [Dead-letter queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) — redrive policy, `maxReceiveCount`, redrive allow policy, the retention-timestamp rule and the FIFO caveat; verified 2026-09-06
- [FIFO exactly-once processing](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-exactly-once-processing.html) — 5-minute dedup interval, content-based deduplication; verified 2026-09-06
- [High throughput for FIFO queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/high-throughput-fifo.html) — partitions, message-group distribution; verified 2026-09-06
- [What is Amazon SNS](https://docs.aws.amazon.com/sns/latest/dg/welcome.html) — endpoint types, A2A vs A2P, the fanout scenario; verified 2026-09-06
- [SNS FIFO topic examples](https://docs.aws.amazon.com/sns/latest/dg/fifo-topic-code-examples.html) — FIFO topics deliver only over SQS, to both queue types; filter policies; verified 2026-09-06
- [What is Amazon MQ](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/welcome.html) — ActiveMQ/RabbitMQ, migrate without rewriting messaging code, quorum queues, CRDR; verified 2026-09-06
- [Amazon MQ deployment options](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/amazon-mq-broker-architecture.html) — single-instance vs active/standby, EBS vs EFS storage; verified 2026-09-06
- [Terraform `aws_sqs_queue`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) / [`aws_sns_topic_subscription`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription)

---
**Self-test for this topic:** [[revision/15-decoupling-revision#Self-test]]
