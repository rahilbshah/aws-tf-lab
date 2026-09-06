---
topic: 15-decoupling
domain: resilient
related_note: 15-decoupling
tags: [flashcards/decoupling]
---

# Cards for [[15-decoupling]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What does putting a queue between two services actually buy you?
?
Decoupling in TIME and in RATE. They no longer have to be healthy at the same instant — if the consumer is down the messages wait — and they no longer have to be fast at the same rate, because the queue absorbs a spike the consumer can't keep up with. Without it, one component's outage blocks the caller too and becomes two outages.

What are the SQS retention limits?
?
Default 4 days. Minimum 60 seconds. Maximum 14 days (1,209,600 seconds). That retention is your outage budget: as long as consumers come back inside it, nothing is lost.

A consumer receives a message. Is it removed from the queue?
?
No. It becomes INVISIBLE to other consumers for the visibility timeout (default 30 seconds, maximum 12 hours). The consumer must explicitly call DeleteMessage. If it never does — crash, slow processing, terminated instance — the message becomes visible again for someone else. That is why SQS is at-least-once and consumers must be idempotent.

What do you need to delete an SQS message, and why is it not the message ID?
?
The RECEIPT HANDLE. A receipt handle is issued per RECEIVE, not per message, so it changes every time the message reappears after a visibility timeout. Using a stale handle fails.

What happens to a message that always fails, if the queue has no dead-letter queue?
?
It loops. Received, fails, reappears after the visibility timeout, received again — until the retention period expires, up to 14 days later. It never fails loudly; it just consumes a worker every cycle. Observed live: one queue with maxReceiveCount=3 moved its message to a DLQ after 3 receives, while an identical queue with no redrive policy was still holding the same message at receive count 14.

What is a redrive policy?
?
The configuration attaching a dead-letter queue to a source queue. It names the DLQ's ARN and a maxReceiveCount — the number of times a message may be received without deletion before SQS moves it to the DLQ instead of returning it to the queue. It is the circuit breaker on a poison message.

Why should a dead-letter queue have LONGER retention than its source queue?
?
Because for STANDARD queues a message keeps its ORIGINAL enqueue timestamp when it moves to the DLQ. A message that spent 3 days in the source arrives in the DLQ already 3 days old — with equal retention you'd have one day to investigate before it's deleted. FIFO queues reset the timestamp on the move, so this doesn't apply there.

Short polling or long polling — which is the SQS default, and why does it matter?
?
SHORT polling is the default (WaitTimeSeconds = 0). It samples only a SUBSET of SQS servers, so it can return an empty response while messages are waiting — AWS calls these "false empty responses". Long polling queries ALL servers and waits up to 20 seconds, reducing empty responses and cost. Any question about wasted API calls or empty receives points at long polling.

SQS vs SNS — the core difference?
?
SQS is a queue: one message is consumed by ONE consumer, which PULLS it, and it's held until then. SNS is publish/subscribe: one message published to a topic is PUSHED to EVERY subscriber, and SNS does not hold anything. SQS is application-to-application only; SNS does both A2A and application-to-person (email, SMS, push).

What endpoints can subscribe to an SNS topic?
?
Amazon SQS, Lambda, HTTP(S) endpoints, email, SMS, mobile push notifications, Amazon Data Firehose, and service providers such as Datadog, MongoDB and Splunk.

What is the fan-out pattern and why is the queue necessary?
?
Publish once to an SNS topic with several SQS queues subscribed, so each consumer gets its own independent copy. The queue is necessary because SNS DELIVERS but does not HOLD — a direct push to a Lambda or HTTP endpoint that is down loses the notification. A queue in front of each consumer gives it a buffer, its own retries, and its own backlog, so one slow consumer can't affect the others.

When SNS delivers to an SQS queue, what does the queue actually receive?
?
A JSON envelope — Type, MessageId, TopicArn, Timestamp, Signature, UnsubscribeURL — with your payload nested inside the .Message field. Consumers have to unwrap it. Enabling RAW MESSAGE DELIVERY on the subscription turns that off so the queue gets the bare payload.

What permission does SNS need to deliver into an SQS queue?
?
A queue resource policy allowing sqs:SendMessage to the service principal sns.amazonaws.com, with a condition on aws:SourceArn pinning it to your topic (ArnEquals). A queue rejects everything by default. Without the policy the subscription exists, the publish succeeds, and the message silently never arrives — and without the condition, any AWS customer's topic could write to your queue.

Standard vs FIFO queues — what does FIFO buy and what does it cost?
?
Buys strict ordering (per message group) and exactly-once processing, replacing standard's best-effort ordering and at-least-once delivery. Costs throughput: 300 transactions per second per API action, or 3,000 messages/second with batching, against standard's effectively unlimited rate. High-throughput FIFO mode lifts this considerably but is opt-in.

What are MessageGroupId and MessageDeduplicationId for?
?
MessageGroupId is REQUIRED on FIFO queues — messages sharing a group are strictly ordered, and DIFFERENT GROUPS PROCESS IN PARALLEL, which is how you recover throughput. MessageDeduplicationId gives a 5-minute deduplication window; alternatively content-based deduplication has SQS hash the message BODY (SHA-256, body only, not attributes) to generate it.

What is the maximum SQS message size?
?
1 MiB (1,048,576 bytes). Note that most course material and many practice questions still say 256 KB — AWS raised it. For larger payloads the Extended Client Library stores the object in S3 and puts a reference in the message, up to 2 GB.

What is Amazon MQ and when do you choose it over SQS/SNS?
?
A managed message broker running Apache ActiveMQ Classic or RabbitMQ. You choose it to MIGRATE an existing application that already speaks a standard broker protocol, "without rewriting messaging code" — AWS's own framing. For anything new on AWS, SQS and SNS are cheaper, serverless and scale far better. No legacy system in the question means MQ is the distractor.

What are Amazon MQ's deployment modes?
?
Single-instance — one broker in one Availability Zone, using EBS or EFS storage. Active/standby — two brokers in two AZs backed by EFS, only one active at a time, with two endpoints per wire protocol (-1 and -2 suffixes) and failover in seconds. Unlike SQS it is a running broker, billed per broker-hour, not serverless.
