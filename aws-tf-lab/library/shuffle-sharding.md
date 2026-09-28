---
kind: reading
source: Amazon Builders' Library
article: Workload isolation using shuffle-sharding
author: Colm MacCárthaigh
url: https://aws.amazon.com/builders-library/workload-isolation-using-shuffle-sharding/
tags: [reading, resilience, multi-tenancy]
---

# Shuffle sharding

*Reading [[00-index|1 of 2]] · source: Colm MacCárthaigh, **"Workload isolation using
shuffle-sharding"**, [Amazon Builders' Library](https://aws.amazon.com/builders-library/workload-isolation-using-shuffle-sharding/)*

## The problem they actually had

When AWS started, customers wanted to point `amazon.com` — the bare root, not
`www.amazon.com` — at S3, CloudFront and ELB. DNS can't do that: `CNAME` doesn't work at
the root of a domain. The only way to serve it was for AWS to host the customer's DNS
itself. That became Route 53.

Hosting DNS means owning a uniquely nasty problem. DNS runs over UDP, so requests are
trivially spoofable, and DNS is critical infrastructure — take it down and the business is
simply gone. Every day there are thousands of DDoS attacks against domains.

The obvious defences didn't work. Adding servers loses by arithmetic: *"Every server that
a provider adds costs thousands of dollars, but attackers can add more fake clients for
pennies if they are using compromised botnets."* Buying the specialised scrubbing
appliances of the day would have cost **tens of millions of dollars** and added months.

So they invented something instead.

## Ordinary sharding, and why it isn't enough

Start with eight workers and no sharding at all. Efficient, redundant — but a poisonous
request or a flood takes out one worker, the load moves to the remaining seven, and the
failure **cascades through all of them**. Scope of impact: everyone.

Split into **4 shards of 2 workers**. Now a bad customer takes out their shard and nobody
else. Scope of impact drops from 100% to **25%**. Better, and it costs you efficiency —
with only two workers per shard you must hold more slack capacity.

That's where most systems stop.

## The move

Don't assign customers to a *fixed* shard. Assign each customer a **random combination**
of workers — their own **virtual shard**.

With 8 workers and 2 workers per customer, the rainbow customer gets workers 1 and 4. The
rose customer also gets worker 1, but its second is worker 8. Their shards **overlap
without being identical**.

Now attack rainbow. Workers 1 and 4 fall over. Rose has lost worker 1 — but still has
worker 8, and keeps serving. In MacCárthaigh's words: *"at most one of another shuffle
shard's workers will be affected."*

**The arithmetic is the whole idea.** Eight workers taken two at a time is **28 unique
combinations**, so 28 possible shuffle shards. With hundreds of customers spread across
them, the scope of impact for one bad customer is **1/28 — seven times better than the
1/4 you got from regular sharding.** Same hardware. The only thing that changed is *how
you assigned it*.

And it gets better with scale, which is the rare part: *"Most scaling challenges get
harder in those dimensions, but shuffle sharding gets more effective. In fact, with enough
workers, there can be more shuffle shards than there are customers, and each customer can
be isolated."*

## What Route 53 actually does

**2,048 virtual name servers**, and every customer domain assigned a shuffle shard of
**four** of them. That's **730 billion possible shuffle shards** — so many that every
domain gets a unique one, and AWS can go further and guarantee **no two customer domains
ever share more than two virtual name servers**.

So when a domain is attacked, four virtual name servers spike and *no other customer
notices*. Better still, the blast radius is now small enough to **identify the targeted
customer and move them to dedicated attack-absorbing capacity**.

## The condition everyone skips

Shuffle sharding only works if **the client retries**. Rose survives because when
worker 1 fails, something tries worker 8. Without a retry, rose's request simply fails
and the isolation bought you nothing.

That is not a footnote — it is the load-bearing assumption. Which is why the very next
article in the library is about retries, and why that one is [[timeouts-retries-backoff|number 2 on this list]].

## What to take from it

- **Isolation is an assignment problem, not a capacity problem.** No new servers were
  bought. The blast radius fell 7× because of how work was *distributed*.
- **Combinatorics is a resilience tool.** "How many distinct subsets can I make?" is a
  design question worth asking whenever you have many tenants and shared workers.
- **Multi-tenant can feel single-tenant.** This is the pattern that lets AWS charge
  multi-tenant prices for a single-tenant blast radius — *"a core pattern that makes it
  possible for AWS to deliver cost-effective multi-tenant services."*
- **It needs fault-tolerant clients.** Design the retry with the shard, or neither works.

## Where it touches the exam

Barely — and that's fine. Route 53's resilience is assumed rather than examined. The one
real connection is **blast radius**, which is the same instinct behind Multi-AZ, cell-based
designs and the DR strategies in [[14-dr-resilience]]: the question is never only "will it
fail?" but "**when it fails, who notices?**"

## Source

- Colm MacCárthaigh, **"Workload isolation using shuffle-sharding"**, Amazon Builders' Library — <https://aws.amazon.com/builders-library/workload-isolation-using-shuffle-sharding/>
- AWS open-sourced their implementation as the **Route 53 Infima** library
- There is a hands-on Well-Architected lab: *Fault isolation with shuffle sharding*
