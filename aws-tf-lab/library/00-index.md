---
kind: reading-index
tags: [reading]
---

# 📚 The library — reading to become an architect, not to pass an exam

> [!info] This is deliberately not part of the exam vault
> The notes, decision pages and cheatsheet at the vault root exist to get you
> through SAA-C03. **They are optimised for recall under time pressure and nothing
> else.** This folder is the opposite: things worth reading slowly, that will still
> matter in five years when the exam is a line on a CV.
>
> Nothing here is wired into the generators. It will never appear in
> [[exam-night]], [[discriminators]] or [[cheatsheet]], and it carries no
> `topic:` frontmatter so the README dashboards ignore it. Read it when you want
> to, not when you're revising.

## Why these sources

The **Amazon Builders' Library** is written by Amazon's own principal engineers and
senior architects about how AWS services are actually built — the failure modes they
hit, and the patterns they invented in response. It is free, first-party, and almost
none of it is examinable. It is the closest thing to sitting next to someone who has
run a service at Amazon scale.

Every note here cites its source: title, author, and the original URL.

> [!warning] A note on the links
> AWS moved the Builders' Library to `builder.aws.com` in 2025 and the new site is
> JavaScript-rendered, so the text is hard to reach programmatically. The canonical
> `aws.amazon.com/builders-library/<slug>/` links still redirect correctly **in a
> browser** — those are the ones cited. Where I needed the text to write a note, I
> read it through the Internet Archive.

## The reading list

Ordered so each builds on the last.

| # | Note | Source article | Author | Why it matters |
|---|---|---|---|---|
| 1 | [[shuffle-sharding]] | *Workload isolation using shuffle-sharding* | Colm MacCárthaigh | The most original idea in AWS architecture, and the reason Route 53 survives DDoS |
| 2 | [[timeouts-retries-backoff]] | *Timeouts, retries and backoff with jitter* | Marc Brooker | Why well-meaning retries take systems down, and the arithmetic of it |

**Queued** — extracted and waiting to be written up: *Using load shedding to avoid
overload* (David Yanacek) · *Static stability using Availability Zones* (Becky Weiss)
· *Avoiding fallback in distributed systems* (Jacob Gabrielson) · *Implementing health
checks* (David Yanacek).

## How to use this

Read one when you want a break from drilling. There is nothing to memorise and no
self-test. If a piece connects to something examinable, the note says so and links to
it — but that connection is a bonus, not the point.
