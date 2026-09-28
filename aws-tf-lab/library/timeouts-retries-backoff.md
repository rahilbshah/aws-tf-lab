---
kind: reading
source: Amazon Builders' Library
article: Timeouts, retries and backoff with jitter
author: Marc Brooker
url: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
tags: [reading, resilience, distributed-systems]
---

# Timeouts, retries and backoff with jitter

*Reading [[00-index|2 of 2]] · source: Marc Brooker, **"Timeouts, retries, and backoff with
jitter"**, [Amazon Builders' Library](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/)*

Read this one after [[shuffle-sharding]], which depends on clients retrying. This is the
article about how retrying goes wrong.

## The sentence to remember

> **"Retries are 'selfish.'"**

A retry is a client spending *more of the server's time* to raise its own chance of
success. When failures are rare and transient, that trade is excellent. When failures are
caused by **overload**, it is poison: retries add load to something already drowning, and
*"can even delay recovery by keeping the load high long after the original issue is
resolved."*

Brooker's framing: retries are *"similar to a powerful medicine — useful in the right
dose, but can cause significant damage when used too much."* And in a distributed system
there is almost no way for clients to coordinate the right dose between themselves.

## The number that should frighten you

A customer call goes through **five layers** of services and ends at a database. Each layer
retries **three** times. The database starts failing under load.

Each layer multiplies the one below: 3 → 9 → 27 → 81 → **243×**.

> *"the load on the database will increase 243x, making it unlikely to ever recover."*

Nobody designed that. Every individual layer made a reasonable local choice. The failure is
**emergent**, and it's why the guidance is blunt: for low-cost control-plane and data-plane
operations, **retry at a single point in the stack**, not at every layer that could.

## Timeouts are harder than they look

Every remote call needs one — *"generally on any call across processes even on the same
box."* But picking the value is the hard part, and both directions hurt:

- **Too high** and the timeout is useless; resources stay held while you wait.
- **Too low** and you get *"increased traffic on the backend"* from spurious retries — and
  worse, *"increased small backend latency leading to a complete outage, because all
  requests start being retried."* A small latency blip becomes a full outage.

The method Amazon uses: pick an acceptable rate of false timeouts — say **0.1%** — then set
the timeout at the matching latency percentile of the downstream service, **p99.9** in that
example. Start from the dependency's measured behaviour, not from a round number.

Two caveats they name: it breaks down over the **internet**, where client latency varies
wildly, and it breaks down for services with **tight latency bounds** where p99.9 sits
close to p50 — there you need padding, or every small blip trips everything.

## Backoff, and why it isn't enough on its own

**Exponential backoff** — wait longer after each attempt — is the standard answer, and it
works until it doesn't. Exponential functions grow fast, so implementations **cap** the
wait. That gives you *capped exponential backoff*… and a new problem: *"Now all of the
clients are retrying constantly at the capped rate."* You have built a synchronised herd.

## Jitter, which is the actual fix

The reason backoff underperforms is **correlation**: *"If all the failed calls back off to
the same time, they cause contention or overload again when they are retried."*

Jitter adds randomness to the delay so retries spread out in time. It is a two-line change
that outperforms almost any amount of extra capacity.

And then the point that separates people who have read this from people who haven't:

**Jitter is not only for retries.** Apply it to *"all timers, periodic jobs, and other
delayed work."* Clients that poll once a minute line up on the first second of the minute;
daily jobs line up at midnight. Brooker reports that on **EBS and Lambda**, jittering
clients' periodic work meant *"the same amount of work with less server capacity."* Spikes
you never see in aggregated metrics are real at per-second resolution.

## The counter-intuitive bit worth stealing

When you jitter **scheduled** work, don't pick randomly per host.

> *"we use a consistent method that produces the same number every time on the same host…
> We humans are good at identifying patterns… Using a random method ensures that if a
> resource is being overwhelmed, it only happens — well, at random. This makes
> troubleshooting much more difficult."*

Random jitter spreads load and destroys reproducibility. **Consistent** jitter — same host,
same offset, every time — spreads the load *and* keeps failures debuggable. That is an
operability argument beating a purity argument, and it is the kind of judgement the exam
will never ask you for.

## Circuit breakers get a colder reception than you'd expect

The usual industry answer to retry storms is a **circuit breaker**: stop calling a
downstream entirely once errors cross a threshold. Amazon is lukewarm — they
*"introduce modal behavior into systems that can be difficult to test, and can introduce
significant addition time to recovery."*

Their preference is a **token bucket**: retry freely while tokens remain, then retry at a
fixed low rate once they're gone. It degrades smoothly instead of flipping between two
modes, and it is testable because there is only one mode. **AWS put this in the SDK in
2016**, so if you use the AWS SDKs you already have it.

## When a retry is safe at all

Only when the call is **idempotent** — the side effect happens once no matter how many
times you send it. Reads usually are; resource-creation calls usually aren't. Well-designed
APIs give you a token to make them safe, the way **EC2 `RunInstances`** does.

The other half is knowing *which* failures deserve a retry. HTTP's client-vs-server error
split is the intended guide — 4xx won't succeed later, 5xx might — except that
**eventual consistency blurs it**: *"A client error one moment may change into a success
the next moment as state propagates."*

## What to take from it

- **Count your retry layers and multiply.** If the number isn't 1, you have an
  amplification factor, and you can compute it.
- **Derive timeouts from the dependency's p99.9**, not from a round number you like.
- **Backoff without jitter is a synchronised herd**, and jitter belongs on every timer and
  cron job, not just on retries.
- **Make scheduled jitter consistent per host** so outages stay reproducible.
- **Prefer a token bucket to a circuit breaker** — one mode beats two.
- **Idempotency is what makes retries legal.** Design for it or you cannot retry safely.

## Where it touches the exam

More than the last one. **Idempotency** is why SQS standard queues need idempotent
consumers ([[15-decoupling]]). **Exponential backoff with jitter** is the documented answer
to API throttling and `ProvisionedThroughputExceeded` on DynamoDB ([[19-serverless]]). And
the 243× story is the mechanism behind the DR note's point that a **control-plane
dependency at the worst moment** is how recovery fails ([[14-dr-resilience]]).

## Source

- Marc Brooker, **"Timeouts, retries, and backoff with jitter"**, Amazon Builders' Library — <https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/>
- Follow-up with the actual maths: **"Exponential Backoff and Jitter"**, AWS Architecture Blog — <https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/>
- The SDK behaviour: **"Introducing retry throttling"**, AWS Developer Blog (2016)
