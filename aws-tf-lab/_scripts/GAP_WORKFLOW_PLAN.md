# Coverage-gap workflow — plan (drafted 2026-09-30, not yet run)

Find every place the question bank asks something the notes do not teach, with
citations, and **decide whether it is worth teaching** before anything is written.

The failure this exists to prevent: sitting an exam and meeting a concept for the
first time. The failure it must not cause: bloating 33 notes with trivia the real
SAA-C03 never asks.

---

## Stage 0 — build the pool (deterministic script, no agent)

Agents never choose their own questions. A script filters and batches, so a
re-run is comparable and nothing is silently included.

**"Proper questions only" filter**, measured 2026-09-30 against `bank/questions.json` (1,168):

| Filter | Remaining |
|---|---|
| all questions | 1,168 |
| drop `verification.status == "quarantined"` (7) and `near_dup_of != null` (5) — the app's own serve rule | **1,156** |
| drop `verification.status == "caveated"` (223) | **933** |
| drop `stale_in_answer` (13) | **920** |

**Pool = 920.** Statuses kept: `verified` (924 of which most) and `corrected` (14 —
these are the ones whose keys were fixed, so they are *more* trustworthy, not less).

> [!warning] Do NOT filter on `xcheck_refuted`
> It is **not** a defect flag. `xcheck_refuted: [0,1,2]` with `xcheck_endorsed: [3]`
> are **option indices** — the distractors the cross-check knocked down and the key
> it endorsed. Excluding on it drops the pool to 405 and throws away 411 sound
> questions. Checked and rejected 2026-09-30.
>
> `stale_flags` (186) is likewise **not** an automatic exclusion — it flags aging
> language that is often in a distractor only. Only `stale_in_answer` touches the key.

Batching: 25 questions per batch → **37 batches**. Stable sort by id so batch
membership is reproducible.

### Stage 0b — harvest the caveats (do not just discard them)

The 223 `caveated` questions are excluded from the **ADD** pool — their keys are not
trustworthy enough to justify writing a note. But `verification.caveat` is prose written
by a reviewer who checked the question against current AWS behaviour, and it frequently
carries a **currency correction** worth more than the question.

So caveated questions feed a second, separate output: a **currency list** of claims to
re-check in the notes. No note is written *from* a caveat either — it points at something
to verify against AWS docs.

> [!example] This is not hypothetical — the pilot proved it on 2026-09-30
> Two of five control questions turned out to be `caveated`. One of them,
> `2025-8-T4-Q09`, carried this caveat: *"that entire path is now retired — Snowball Edge
> is closed to new customers and **AWS has removed the DMS large-database/Snowball Edge
> chapter from its documentation**."*
>
> I had already written that path into `24-other-services.md` as current, from an archived
> **2022** copy, after reading a 404 as a JS-rendering failure. The check that settles it:
> every live AWS docs page serves a `.md` twin, so `CHAP_Serverless.md` → 200 while
> `CHAP_LargeDBs.md` → **404** means the chapter is gone, not merely unparseable. The
> caveat caught a §13.10 violation that my own doc verification had missed.
>
> Two rules follow: **(1)** confirm a doc page exists by fetching its `.md` twin, never by
> trusting a 200 from the docs SPA or a search index; **(2)** read the caveat text of every
> caveated question touching a topic being edited.

## Stage 1 — coverage agents (1 per batch)

Input: 25 questions (full stem, all options, the key, the explanation) + read
access to the vault. Output, per question:

- `qid`
- **`discriminator`** — one sentence naming the knowledge the question actually
  turns on. Not the topic; the deciding fact.
- `verdict` — `COVERED` · `PARTIAL` · `ABSENT`
- `evidence` — for COVERED/PARTIAL, **exact `file:line` quotes**. For ABSENT, the
  list of files and search terms tried.

**The rule that makes this worth running:** a service name appearing in a note is
not coverage. `SSM` appeared in two notes that never taught it; Cognito the same.
An agent must quote the sentence that *teaches the discriminator*, or the verdict
is ABSENT. Unquoted COVERED claims are discarded at Stage 2.

## Stage 2 — verify agents (adversarial)

Every `ABSENT` and `PARTIAL` goes to a second agent whose job is to **refute** it —
find the content the first agent missed. Also re-reads the **full asking sentence**
of each question and flags **inverted polarity** ("which is NOT suitable", "EXCEPT"),
because a truncated stem already produced one false gap report (`2025-7-T3-Q26`).

Output: `CONFIRMED` / `OVERTURNED`, with evidence either way.

## Stage 3 — exam-relevance gate (the step that protects the notes)

For each `CONFIRMED` gap, decide **ADD** or **SKIP**:

| Signal | How it is measured |
|---|---|
| **Frequency** | how many *distinct* questions in the 920 pool turn on it — counted via **`topics[]`**, never `services[]` |
| **Exam-guide scope** | is it in the official SAA-C03 exam guide? (Amazon Personalize precedent: the bank asked it, the guide lists it out of scope, so it was dropped) |
| **Discriminator or trivia** | does it decide between two plausible answers, or is it a lookup nobody is asked to recall? |

`SKIP` is the default for a gap appearing in **one** question with no exam-guide
backing. The report must state the verdict and the reason for every gap — a SKIP
is a finding, not a silence.

> [!warning] Counting caution
> `services[]` lists every service a question *names*, including inside its wrong
> answers. Two earlier analyses over-reported by counting mentions as subjects.
> Every count states whether it counts **questions** or **tag-instances**.

## Stage 4 — synthesis agent

One report, gaps ranked by (exam-relevance × frequency):

- the discriminator sentence
- **question ids** that turn on it
- current coverage verdict + the quotes behind it
- target note **and section**
- proposed treatment: **comparison-table row**, **trap callout**, or **key fact** —
  never loose prose, because §13.7 only drills tables and traps
- Stage 3 verdict with its reason

**The report changes no notes.** Writing stays manual: I verify each fact against
first-party AWS docs at write time and link the source, per §13.10.

---

## Hard rules for every agent

1. **Read-only on the vault.** No agent edits a note.
2. **Never touch `bank/questions.json`.** It is audited; answer keys are load-bearing.
3. **Prove a citation is live** by fetching the page's `.md` twin and requiring HTTP 200.
   A 200 on `.html` proves nothing — the docs SPA serves a shell for removed paths, and search
   indexes keep dead URLs. If only an archive copy exists, the note must say so.
4. **Never search the open web for exam content.** Braindump sites violate the AWS
   Certification Agreement and risk certification revocation. Fact-checking against
   `docs.aws.amazon.com` happens at write time, by me, not by these agents.
5. **Quote or it did not happen.** Every coverage claim carries `file:line`.
6. **Question ids stay out of the notes.** §13.12: the bank may shape *emphasis*,
   never supply *facts*. Ids belong in the report and the commit message.

## What it actually cost and found — RUN 2026-09-30/10-01

| | wave 1 | wave 2 |
|---|---|---|
| coverage model | session model | **Sonnet**, `effort: low` |
| questions | 200 | 175 |
| gaps claimed | 54 | 29 |
| **confirmed** | **52** | **22** |
| overturned | 2 (**4%**) | 7 (**24%**) |
| agents | 62 | 36 |
| subagent tokens | **5,576,870** | **2,725,695** |
| tokens / question | 27,884 | **15,575** |

**The model split is worth keeping.** Sonnet on coverage with the strong model on
verify roughly **halved cost per question** and took the overturn rate from 4% to
24% — i.e. the adversarial stage started doing visible work instead of
rubber-stamping. Note the wave-2 verify prompt also *told* the verifier the
upstream stage was cheap and over-flagging, so prompt and model changed together.

**Do not read wave 2's lower yield (0.126 confirmed/question vs 0.260) as Sonnet
missing things.** Two variables moved at once: the cheaper coverage model, and
the 52 facts written into the notes between the waves, which genuinely left less
to find.

### Decision 2026-10-01: stop here. Waves 3–5 will not run.

385 of the 920-question pool intersected the measured-weak topics; waves 1 and 2
covered all of it. The remaining **535 questions are on topics already scoring
70%+**, which is the lowest-yield third of the bank, and each wave costs ~2.7M
subagent tokens. Agreed with the human: the constraint is no longer coverage.

### What the hunt was actually worth

73 confirmed gaps written. But the highest-value findings were not gaps at all —
they were **four places where the vault taught the wrong thing**:

- `01-iam-advanced:129` — "identity + resource policy → either one allowing is
  enough" with no KMS carve-out, when a KMS key policy is the one resource policy
  that must independently allow.
- `07-rds-aurora:422` — storage autoscaling called an Aurora-only feature.
- `13-cost-optimization:118` — "cross-AZ traffic is charged" stated flat, when
  same-Region read-replica replication is free across AZs.
- `04-alb-asg:303` — taught suspending `ScheduledActions`, which is the
  *distractor* for protecting an instance during maintenance; the answer is
  `ReplaceUnhealthy` or Standby.

**Lesson for any future audit: ask agents to report where the vault is WRONG, not
only where it is silent.** A missing fact costs a question; a confidently wrong
one costs the question and the trust.

## Scale and cost

37 batches is far past the 10-agent guideline, so it runs in **waves**, each a
separate invocation that can be stopped:

| Wave | Batches | Questions | Purpose |
|---|---|---|---|
| **Pilot** | 1 | 25 | validate the procedure end to end (includes control questions whose answers were *just* added — the pilot must mark those COVERED) |
| **Wave 1** | 8 | 200 | weakest topics first |
| **Waves 2–5** | ~7 each | rest | full sweep |

## How we know the procedure works

The pilot batch seeds **control questions** whose knowledge was added on
2026-09-29/30 (Babelfish, Enhanced Monitoring, DMS Serverless, Run Command vs
Patch Manager). A procedure that marks a control `ABSENT` is broken and must not
be scaled up. A procedure that marks a known-uncovered question `COVERED` is worse,
and Stage 2 exists to catch exactly that.
