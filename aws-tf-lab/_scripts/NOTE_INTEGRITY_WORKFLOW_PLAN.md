# Note integrity workflow — plan (drafted 2026-09-30, not yet run)

Two different things can be wrong with a note, and they need different readers:

- **Axis A — is it still true?** Dead citations, renamed services, changed limits,
  retired features.
- **Axis B — can it be understood on first read?** A note that has to be explained
  by Claude before it can be used has failed at the only job it has.

One workflow, two passes, one report per note. **Neither pass edits a note.**

---

## The corpus, measured 2026-09-30

| | |
|---|---|
| Topic notes | **33** |
| Words in topic notes | **131,972** |
| Distinct citations | **284** (203 `docs.aws.amazon.com`, 51 `registry.terraform.io`) |
| Prose paragraphs over 25 words | **854** |
| …of those, **over 30% bolded** | **67** |

### The dead-citation rate is not hypothetical

A 20-URL random sample of the AWS citations, checked with the `.md`-twin rule,
**failed 2 of 20 (10%)**. Extrapolated over 203 AWS URLs that is **~20 bad
citations**, and the two that failed were core exam material. They also failed in
two different ways, which the workflow must distinguish:

| URL | Result | What it means | Fix |
|---|---|---|---|
| `AWSEC2/…/ebs-volume-types` | **MOVED** — content now at `ebs/latest/userguide/…` | EBS got its own guide | update the link |
| `efs/…/storage-classes` | **GONE** — 404 while `efs/…/performance` resolves | section reorganised away | **re-verify the fact**, then relink |

A MOVED link is cosmetic. A GONE link means nobody can check the claim any more,
and that is where facts rot silently — the DMS/Snowball error on 2026-09-30 was
exactly this shape.

---

## Axis A — currency

### A0. Citation sweep (deterministic script, no agent)

Fetch the `.md` twin of all 284 citations, require HTTP 200, classify
**OK / MOVED / GONE**. For MOVED, attempt the obvious successor path and record it.

This is the highest signal per token in either plan: minutes to run, exhaustive,
no judgement required. **Run this one first, and separately, before any agent.**

### A1. Claim extraction + verification (1 agent per note)

Each agent gets one note, that note's slice of the A0 report, and the **caveat feed**
(§Stage 0b of `GAP_WORKFLOW_PLAN.md` — reviewer prose on aged bank questions, which
is where the Snowball retirement surfaced).

It extracts every **checkable claim** and verifies each against live first-party docs:

- numbers — limits, quotas, sizes, durations, prices, defaults
- **absolute claims** — "only", "always", "never", "cannot", "free", "no charge"
- service and feature **names** (the rename graveyard: Kinesis Data Analytics →
  Managed Service for Apache Flink, SageMaker → SageMaker AI, QuickSight → Quick Sight)
- anything already marked `⚠️ verify:`

Output per claim: `CONFIRMED` · `STALE` · `UNVERIFIABLE`, each with the live `.md`-verified
URL and the quoted sentence. A claim whose only support is an archive copy is
`UNVERIFIABLE`, not `CONFIRMED`.

## Axis B — comprehension

The test is **not** prose quality. It is the vault's own standing rule: *explain in
plain language before compressing.* A section that opens at full density has failed,
however accurate it is.

### B0. Objective pre-filter (script)

Rank every section by measurable density: bold ratio, mean sentence length, share of
the section that is table versus prose, terms used before they are introduced. The
**67 paragraphs over 30% bold** are the starting worklist.

### B1. Cold-read agents (1 per note, and it must be a *fresh* agent)

The agent is told: you have not studied AWS. Read this note once, top to bottom, no
re-reading, no outside lookups. Then, per section, answer:

1. Could you state what this section is about in one sentence?
2. Was any term used before it was explained? Name it.
3. Where did you have to stop and re-read?
4. Does a plain-language explanation come **before** the compressed version, or is
   the compressed version all there is?

Output: per section, `CLEAR` · `DENSE` · `NEEDS-EXPLAINER`, with the sentence where
comprehension broke. Its answers are **data about the writing**, never facts about AWS —
a cold-read agent's AWS claims are ignored by construction.

> Why a separate agent: the currency reader is checking facts against docs and is
> therefore primed on the subject. It is the worst possible judge of whether the text
> is followable by someone who is not. These two jobs cannot share a context.

## Synthesis

One report per note: stale claims (with live URLs), dead citations split MOVED/GONE,
and the sections that failed the cold read — ordered by **risk**, where a wrong fact
outranks an unclear one.

Then I write, under the same gate as everything else:

1. first-party source, fetched — never recalled, never from an agent's summary
2. the **`.md` twin check** proves the page is live
3. dated in the note, linked under `## 🔗 Docs`; unverifiable → `⚠️ verify:` or it stays out

---

## When to run it — my opinion, and it is not "all of it now"

The exam is targeted for **mid-October 2026**, so roughly two weeks. That changes the
answer completely.

| Now, before the exam | After the exam / between attempts |
|---|---|
| **A0 citation sweep** — it is a script, it takes minutes, and a 10% failure rate means ~20 real problems | **B1 cold-read pass over all 33 notes** |
| **A1 currency**, but only on the notes actually being leaned on — weak topics first, and the notes densest in unverified numbers | Rewriting for comprehension at scale |
| **Surgical** readability fixes: only the worst offenders from B0, and only by adding an explainer sentence — never by restructuring | Restructuring, splitting long notes, re-ordering sections |

**The recommendation I want to argue for: do not run the readability rewrite before the
exam.** Rewriting notes you have partly memorised, two weeks out, costs you recall of
the old wording and pays back comprehension you have no time left to bank. Wrong facts
are worth fixing at any hour; unclear phrasing is not, this close.

The exception is a section you *already know* you cannot read — those are worth one
added explainer sentence each, which is additive and disturbs nothing.

Sequence I would actually run: **A0 today** → **A1 on the weak topics** → cheatsheet
verification (`CHEATSHEET_VERIFY_WORKFLOW_PLAN.md`) → exam → **B1 in full afterwards**.
