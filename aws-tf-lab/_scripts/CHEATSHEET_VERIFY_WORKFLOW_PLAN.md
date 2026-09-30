# Cheatsheet verification workflow — plan (drafted 2026-09-30, not yet run)

`cheatsheet.md` is the last thing read before the exam. A wrong fact there does more
damage than a wrong fact anywhere else in the vault, because it is read late, trusted
completely, and never cross-checked.

It has never been verified.

## What is actually in it, measured 2026-09-30

| | |
|---|---|
| Fact rows | **677** |
| Words | 12,968 across 1,475 lines |
| Areas (H2) | 14 |
| **Citations in the entire file** | **1** |

677 facts, one URL. That single number is the whole reason this workflow exists.

Every fact is a two-column row — `\| claim \| value \|` — so batching is trivial and
needs no parsing heuristics.

### Risk classes

| Class | Count | Why it matters |
|---|---|---|
| **numeric / limit / price** | **185** | rots fastest, and is exactly what the exam asks |
| **absolute claim** — only, always, never, cannot, free, no charge | **119** | one counter-example makes it false, and these are written as certainties |
| naming or conceptual | 373 | mostly stable; the risk is **renames**, not errors |
| | **677** | |

**304 facts are high-risk.** That is the number that makes this tractable — the answer
is not "verify 677 facts against AWS docs".

---

## Stage 1 — reconcile against the notes first (cheap, no web)

The cheatsheet was **derived from the notes**. So there are two distinct failure modes,
and they cost very different amounts to find:

| Failure | How it happened | How to find it |
|---|---|---|
| **Compression error** | the note is right; the fact was garbled, rounded or lost a qualifier on the way into a table cell | **diff against the note** — no web access needed |
| **Inherited error** | the note is wrong too | doc verification (Stage 2) |

Compression errors are both **more likely** and **far cheaper to detect**, so they go
first. One agent per area (14 agents, ~48 facts each) gets its area's rows plus the
notes those rows came from, and returns per fact:

- `MATCHES` — the note says the same thing
- `CONTRADICTS` — the note says something different (quote both, with `file:line`)
- `NO-BASIS` — nothing in any note supports this; it appeared from nowhere
- `LOST-QUALIFIER` — directionally right but the note's condition was dropped
  (*"30-day minimum storage duration"* compressed to *"30 days"* is the canonical shape
  of this, and it is precisely the confusion that produced a false stale-fact report
  against `09-s3-intro.md` in August)

Stage 1 needs **no AWS docs and no internet**. It is a text reconciliation, and it
triages 677 facts down to the ones that actually need verifying.

## Stage 2 — verify against first-party docs

Verify only:

1. everything Stage 1 marked `CONTRADICTS`, `NO-BASIS` or `LOST-QUALIFIER`
2. **all 185 numeric/limit/price facts** regardless of Stage 1 — these rot without
   anyone being wrong at the time of writing
3. **all 119 absolute claims** regardless of Stage 1 — "only" and "never" are the two
   words most likely to have quietly acquired an exception

Naming/conceptual facts that `MATCH` a note are not re-verified here; they are covered
by the currency pass in `NOTE_INTEGRITY_WORKFLOW_PLAN.md`, and doing them twice is the
kind of duplicated effort that produced the retired flashcards.

Each verification carries the **`.md`-twin check** — fetch `<page>.md`, require 200 —
because a 200 on `.html` proves nothing. That rule exists because a removed DMS chapter
was cited as live on 2026-09-30 after its `.html` returned 200.

## Stage 3 — synthesis

One table, ordered by blast radius: **wrong** facts first, then **unqualified**, then
**uncited**. Per row: the cheatsheet line, the verdict, the correct value, the live URL,
and whether the **note** needs the same fix.

That last column is the one that matters — an inherited error must be fixed in **both**
places, or the next regeneration reintroduces it.

## Then I write

Same gate as everywhere: first-party source fetched, `.md` twin 200, dated and linked.
And one rule specific to this artifact:

> **Every corrected cheatsheet fact gets a citation.** Going from 1 citation to ~300 is
> the point of the exercise. An uncitable fact does not belong on the page someone reads
> an hour before the exam — it gets removed or marked `⚠️ verify:`.

## Cost and sequencing

| Stage | Agents | Web | Notes |
|---|---|---|---|
| 1 — reconcile | 14 (one per area) | no | cheap; run in two waves of 7 |
| 2 — verify | sized by Stage 1 output, floor of 304 facts | yes | the expensive stage; batch ~25 facts per agent |
| 3 — synthesis | 1 | no | |

**When: after the A0 citation sweep, before the exam.** This is the one pre-exam
verification job I would not skip, because the cheatsheet is the artifact with the worst
ratio of trust to evidence in the whole vault — and unlike the readability work, fixing
a fact costs you no relearning.
