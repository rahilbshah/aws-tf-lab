# Line-by-line note audit — progress

Three agents per note, one note at a time:
- **truth** — every checkable claim verified against first-party AWS docs. Opus, high effort.
- **consistency** — self-contradiction, cross-note contradiction, duplication, links, structure, Terraform leftovers. Sonnet.
- **clarity** — cold read: can this be understood from the page alone, months later, with nothing else open? Sonnet.

Harness: `Workflow` with the saved script, `args: {notes:[...], lenses:[...]}`.

> **2026-10-05 — process correction.** The user asked for strictly one note at a time: do not run a
> second note's audit while the first is still open. I had overlapped `05-vpc-endpoints-peering`
> with `05-vpc-security`; the second was stopped and will be resumed from
> `wf_e506dc95-340` (completed agents replay from cache) once `05-vpc-security` is closed out.
>
> **2026-10-05 — holding commits.** The user asked that nothing be committed until they are back,
> then one consolidated report. Work continues in the working tree. Last commit: `4cb4cc7`.
Rules that bind the edits: CLAUDE.md §13.10, §13.10a (asymmetry), §13.10b (seams), §13.10c (who verifies).

**Every change is re-verified by me against the AWS page before it is written.** Agents over-flag
on purpose; a citation that does not resolve, or does not contain the quoted text, is discarded.

| Note | truth | consistency | clarity | committed |
|---|---|---|---|---|
| 01-iam.md | 3 WRONG · 7 OVERSTATED · 1 UNVERIFIABLE | 11 | 10 | `13e94e6`, `0091f77` |
| 01-iam-advanced.md | 128 claims · 29 pages · 4 WRONG · 7 OVERSTATED · 1 STALE · 1 UNVERIFIABLE | 13 | 8 | `40ab3c3` + truth |
| 02-ec2.md | 168 claims · 33 pages · 2 WRONG · 8 OVERSTATED · 1 STALE · 4 UNVERIFIABLE | 19 | 10 | `pending` |
| 04-alb-asg.md | 158 claims · 34 pages · 3 WRONG · 6 OVERSTATED · 1 STALE · 3 citation/UNVERIFIABLE | 13 | 10 | `pending` |
| 05-vpc-core.md | 96 claims · 26 pages · 4 STALE · 8 OVERSTATED | 13 | 9 | `pending` |
| 05-vpc-security.md | 137 claims · 18 pages · 3 WRONG · 7 OVERSTATED · 2 UNVERIFIABLE | 15 | 10 | **UNCOMMITTED** |
| 05-vpc-endpoints-peering.md | 94 claims · 15 pages · 1 WRONG · 1 STALE · 6 OVERSTATED · 1 UNVERIFIABLE | 14 | 10 | **UNCOMMITTED** |
| 05-vpc-hybrid.md | 103 claims · 20 pages · 2 STALE · 3 OVERSTATED | — | — | **UNCOMMITTED** |
| 05-vpc.md | done by hand (index note, 313w) | — | — | **UNCOMMITTED** |
| 07-rds-aurora.md | 190 claims · 39 pages · 3 WRONG · 5 OVERSTATED · 3 STALE · 5 UNVERIFIABLE | 16 | 10 | `pending` |
| 08-elasticache.md | 83 claims · 13 pages · 2 WRONG · 7 OVERSTATED · 3 STALE · 1 UNVERIFIABLE | 10 | 9 | `pending` |
| 09-s3-intro.md | | | | |
| 09-s3-advanced.md | | | | |
| 09-s3-security.md | | | | |
| 09-s3.md | | | | |
| 10-route53.md | | | | |
| 11-cloudfront.md | | | | |
| 12-storage-extras.md | | | | |
| 13-cost-optimization.md | | | | |
| 14-dr-resilience.md | | | | |
| 15-decoupling.md | | | | |
| 16-kinesis.md | | | | |
| 17-containers.md | | | | |
| 19-serverless.md | | | | |
| 20-monitoring.md | | | | |
| 21-security.md | | | | |
| 22-analytics.md | | | | |
| 23-machine-learning.md | | | | |
| 24-other-services.md | | | | |
| 25-well-architected.md | | | | |

Not audited on purpose — `exam: false`, excluded from every generator:
`03-ami-bake.md`, `06-capstone.md`, `18-containers-capstone.md`.

## Two errors I introduced and then had caught (2026-10-05)
Recorded because the pattern matters more than the two facts.

On `05-vpc-security.md` I wrote two claims that the truth agent then refuted against first-party
docs, and **both were negatives or absolutes I asserted without hunting for the counter-example** —
the exact failure §13.10a(a) was added to prevent, committed by me:

1. I wrote that AWS *"does not commit to a steady-state figure"* for flow-log delivery, and demoted
   the vault's own correct "~5 min to CloudWatch, ~10 min to S3" to "a lab observation, not a
   published number". AWS publishes exactly those numbers, verbatim, on `flow-log-records.html`:
   *"typically delivers logs to CloudWatch Logs in about 5 minutes and to Amazon S3 in about 10
   minutes"*. I had fetched `flow-logs.html`, not found it there, and generalised to "AWS does not
   state it". **I made the note worse than it was** — it had the right numbers and I labelled them
   folklore.
2. I wrote "every current-generation instance type is Nitro" to argue the 600s aggregation interval
   is moot. **T2 is current-generation and still runs on Xen** (`instancetypes/gp.html` lists
   "T2 | Xen"), and `t2.micro` is this repo's own declared free-tier default — so the claim failed
   precisely in the learner's own lab.

**Operational lesson:** when about to write "AWS does not state X", one page not containing X is not
evidence. Either find the page that would carry it, or write the positive claim and stop.

## Judgment calls made, so they are not re-litigated
- **Layered repetition is by design, not duplication.** An agent flagged placement-group facts
  appearing in the body prose, the Key facts bullets and the Comparisons table as triplication.
  Declined: the body is the comprehension layer, the table is the drillable compression, and the
  Key facts bullets carry limits the table does not (free, one group at a time, cannot merge,
  no Dedicated Hosts, peered VPCs, the 10/5 Gbps split, T-family unsupported). Same reasoning
  applies to TL;DR bullets that restate body facts.
- **Note titles that look mis-numbered may be load-bearing.** `01b – IAM Advanced` sorts after
  `01 – IAM` in the generated views, which sort by title. Renaming it to `01` pushed Advanced
  ahead of basic IAM. Left as `01b`.

## Still outstanding across the vault
- `cheatsheet.md` (672 facts) has never been truth-checked against AWS docs.
- 91 medium-value gaps from wave 3 remain unwritten (deliberately deferred).
- `⚠️ verify:` markers still unresolved (25 total, as of 2026-10-04). Each one is a claim nobody
  has confirmed, so each is a candidate wrong fact. The truth pass for a note should resolve its
  markers — either verify and assert the fact, or delete it.

  | Note | markers |
  |---|---|
  | 07-rds-aurora.md | 3 |
  | 04-alb-asg.md · 05-vpc-security.md · 13-cost-optimization.md · 19-serverless.md · 20-monitoring.md · 21-security.md | 2 each |
  | 02-ec2.md · 05-vpc-hybrid.md · 17-containers.md · 22-analytics.md | 1 each |
  | cheatsheet.md | 6 |

## Carry-forward defects found while auditing another note
Fix these when that note's own turn comes, not before.

- **`17-containers.md:173`** — a surviving Terraform leftover: `target_type`, `"instance"` and
  `terraform apply` inside a trap callout. §13.5 says the notes carry no Terraform. Restate the
  AWS fact (an `awsvpc` task registers by IP, so the target group must be IP-type) and drop the
  tooling framing.

- **`cheatsheet.md`** — six entries are IaC argument names rather than AWS facts: lines 155, 159
  (`delete_on_termination`), 207 (`map_public_ip_on_launch` / `associate_public_ip_address`), 375
  (same), and two that have no exam value at all and should simply go: line 238 ("Attributes that
  force instance replacement") and line 246 ("Accepted `ip_protocol` values"). The matching traps
  were removed from `02-ec2.md` on 2026-10-04; the cheatsheet still asserts them.

- **`13-cost-optimization.md:120`** and **`09-s3-security.md:265-272`** — both restate facts
  `02-ec2.md` owns (public IPv4 hourly billing; EBS snapshot-encryption inheritance). 02-ec2 now
  links out to both; on their own passes they should link back rather than restate. Note
  13-cost-optimization also still carries the pre-correction form of the public-IPv4 rule
  ("whether attached or not") without the BYOIP and 750-hour Free Tier exemptions.

- **HELD BACK, `05-vpc-endpoints-peering.md` (same VPC instruction).** Two structural findings
  recorded not applied: (a) the gateway-vs-interface comparison appears both at the top of "How it
  actually works" and under `## Comparisons`, and only the latter is harvested — one copy should go;
  (b) the cross-Region security-group-reference fact sits in Key facts but is a *peering* limit and
  reads better inside "Why peering never becomes a hub". Both need the user's read first.

- **HELD BACK on the user's instruction (VPC/S3).** The user asked that the VPC and S3 notes not be
  *restructured* until they have read them. Two structural findings on `05-vpc-core.md` are
  therefore recorded rather than applied: (a) the two-hop route-table table (private RT → NAT, NAT's
  RT → IGW) sits outside `## Comparisons`, so no generator harvests it, and (b) the two
  public-subnet failure cases would be drillable as a two-row table. Both are additive moves, not
  rewrites. Raise them once the user has read the VPC notes.

- **`05-vpc-core.md` duplication, also held back.** The default-vs-custom NACL/SG flip is stated
  five times in this note (TL;DR, prose section, key facts, a trap, weak spots) and
  `05-vpc-security.md:17` owns it. A pointer was added; the trimming needs the user's read first.
  Separately, the NAT-gateway facts appear four or five times within this one note.

- **`17-containers.md:108,163,185`**, **`18-containers-capstone.md:58`** and
  **`13-cost-optimization.md:116`** all restate the NAT gateway `$0.045/hr` figure that
  `05-vpc-core.md` owns. Link, don't restate.

- **`README.md`** still refers to "cards", which were retired. `05-vpc.md` had the same stale
  reference plus a claim that `05-vpc-core` covers "bastion" (it does not); both fixed 2026-10-04.

- **`cheatsheet.md:282`** — an open `⚠️ verify:` on whether the NLB flow hash includes the TCP
  sequence number. Settled 2026-10-04: it does — AWS lists *"The protocol, The source IP address
  and source port, The destination IP address and destination port, The TCP sequence number"*.
  `04-alb-asg.md` now states it both places; remove the cheatsheet marker on its pass.

- **`cheatsheet.md:309-315`** — same IaC argument spellings (`health_check_type`,
  `health_check_grace_period`) that were converted to console names in `04-alb-asg.md`, plus
  `target_type` at :279. Lines 312-313 also carry the **old, wrong** time-to-ELB-healthy
  arithmetic that was corrected in the note (a new target needs **one** passing health check,
  not `HealthyThresholdCount` of them).

- **`15-decoupling.md:146`** — owns SQS, and restates the backlog-per-consumer formula that
  `04-alb-asg.md` also gives in full. 04 now links out to it; on 15's pass, decide which holds
  the formula and which links. Also reconcile "running consumers" vs "`InService` instances".

- **`19-serverless.md:20,194`** and **`18-containers-capstone.md:58`** — all three restate the ALB
  `$0.0225/hr` figure that `04-alb-asg.md` owns. Link, don't restate, so one price change is one
  edit.

- **`19-serverless.md:132`** — the trap *"the certificate Region for a custom domain"* opens an
  italic quote (`AWS: to use an ACM certificate with a …`) that the discriminators generator
  truncates mid-quote, so `discriminators.md:419` ends with a dangling unclosed quote. The lesson
  generalises: **a trap body's first sentence is what gets harvested, so never let a quote span
  sentences inside a trap** — the same thing happened to the Control Tower trap in
  `01-iam-advanced.md` and was rewritten as a single sentence.

## Known limitation, not a defect
The generators cannot anchor a heading that contains an inline tag, so every note's
`## ⚠️ Traps … #trap` section is linked bare (`[[note|note]]`) in `discriminators.md`
and `exam-night.md` rather than deep-linked. Affects all 33 notes equally.

### 09-s3-intro (2026-10-05) — held back pending the user's read of the S3 family

The user said: *"not until I read both vpc and s3 if needed we will do it otherwise
I don't want you to change anything."* Read as: fix facts, do not restructure. These
are structural and are therefore **not applied**, only recorded:

- Two orphaned tables that no generator harvests, because they sit under an H3 in
  *How it actually works* rather than under `## Comparisons`:
  the versioning action table (a strict subset of the harvested one in Comparisons)
  and the minimum-storage-duration table (fully covered by the Comparisons table's
  `Min duration` column). Deleting both loses nothing and removes two drift sites.
- Minimum storage durations are stated **six** times in this one note (TL;DR, prose
  table, key fact, Comparisons column, trap, weak spot). The Comparisons table is the
  drillable copy; the rest could be pointers.
- Object-size / multipart limits (50 TB, 48.8 TiB, 5 GB single PUT) are owned by
  `09-s3-advanced` and restated in full here twice.
- Static website hosting has no prose section, though the title and `09-s3.md`
  both claim the note covers it. Currently two key-fact bullets only.
- No `> [!tip] Production gap` callout — but `09-s3-advanced` and `09-s3-security`
  have none either, so this is vault-consistent, not a defect in this note.

### 09-s3-advanced (2026-10-06) — partial pass, truth lens pending

**The truth lens failed on this note.** Run `wf_5e47515c-444` ran 2h 6m and stalled on all
six retries, returning nothing. Cause is unconfirmed but the note is large and the agent was
fetching without a budget; the audit script now caps the truth lens at **18 pages** and
no longer forces `effort: 'high'`. Re-run is `wf_f90cb933-4da` (truth only).

Applied in this commit are the consistency and clarity findings plus two corrections I
verified first-hand. Structural items held back (S3 notes, pending the user's read):

- The **Glacier retrieval tiers** table (H3 under `## Key facts`) and the **live rule vs
  Batch Replication** table (H3 under `## How it actually works`) are both orphaned from the
  generators, which only harvest H3s under `## Comparisons` or H2s containing "vs". The
  Batch Replication one is the exam answer to the single most-missed trap in the topic and
  currently reaches no generated view.
- Ownership overlaps with `09-s3-intro`, now that both notes have been edited: per-prefix
  request rates (intro carries the gradual-scaling/503 qualifier, this note does not),
  max object size 50 TB (intro has the 48.8 TiB detail, this note does not), incomplete
  multipart billing, and Glacier retrieval speed. Each is stated in full in both places.

### Why the overnight run produced one note instead of twelve (2026-10-06)

Two independent failures, recorded so neither is mis-diagnosed later:

1. **The machine slept at 00:53 despite `caffeinate -dimsu`.** `pmset -g log` shows
   "Entering Sleep state due to 'Sleep Service Back to Sleep' … **Using Batt (Charge:69%)**".
   caffeinate held `PreventSystemSleep` for 8h42m — the assertion was live the whole time —
   but it only binds **on AC power**. Unplugged, macOS overrides it. If an unattended run is
   attempted again, check `pmset -g batt` for "AC Power" first; do not rely on having asked.
2. **The truth agent stalled while the machine was awake**, so power was not its cause. See
   the 09-s3-advanced entry above for the mitigation.

### 09-s3-security (2026-10-06) — 16 truth findings, 2 of them internal contradictions

140 claims, 18 AWS pages (hard cap hit). 12 of 16 findings were absolutes, negatives or
eliminations; only one was a plain number and it was right. Two were places where the
Key-facts line contradicted the note's own teaching prose four screens earlier — and the
Key-facts line is the one that gets memorised.

Structural items held back (S3 notes, pending the user's read):
- The orphaned comparison tables under `## Comparisons` H3s are fine, but the per-service
  encryption menus sit under a heading whose title the generators do harvest — verified
  present in discriminators.md, so no action needed.
- `09-s3-security:265-272` duplicating EBS encryption with `12-storage-extras` is still on
  the carry-forward list; not touched this pass.

Agent reliability note, worth keeping: on `09-s3-advanced` the truth agent listed
"RTC = 99.99% in 15 min" among facts it had VERIFIED, with no URL. The RTC user-guide page
says "99.9 percent" verbatim; the S3 FAQ does not mention RTC; aws.amazon.com/s3/sla-replication
404s. The uncited claim in an agent's prose summary is the one to distrust — its cited
findings have all held up so far.

### 09-s3 index (2026-10-06) — and one carry-forward item that was a FALSE POSITIVE

51 claims, 7 pages. The index note's TL;DR had packed four absolutes, three of them broken
by AWS's own docs — all the same errors found in `09-s3-intro`, which is a good sign the
corrections are consistent rather than ad hoc: "every class is 11 nines" (RRS is 99.99%),
"S3 is a flat key→object map" (directory buckets are hierarchical), "turns deletes into
delete markers" (only a DELETE *without* a version id), "globally unique" (partition-scoped).

**The carry-forward item "README.md still refers to retired cards" was wrong.** README does
mention `cards/`, but only to say it was deleted on 2026-09-06 and why — accurate history,
not a dangling promise. `07-rds-aurora.md:457` was a substring match inside "Wildcards".
The only real dangling promise was `09-s3.md:12` ("each sub-note is self-contained with its
own cards"), now fixed. Same shape as the §13.12 worked example: a plausible report that
would have deleted correct content. Grep hits are not findings.

### 10-route53 (2026-10-06) — the weight-0 absolute, and a "famous fact" AWS retired

138 claims, 17 pages. First non-S3 note of this run, and the error profile was the same:
absolutes and negatives, no wrong plain numbers.

Two findings I verified first-hand and would call the most valuable of the whole audit so far:

1. **"weight 0 means never return this"** — false, and AWS contradicts it on two pages with a
   truth table. A zero-weight record is the last-resort fallback: if every nonzero-weight
   record is unhealthy, Route 53 returns the zero-weighted ones. It was stated twice, once
   inside a worked example. Both fixed, plus a trap so it is drillable.
2. **"Route 53 carries a 100% availability SLA"** — the single most-repeated Route 53 trivia
   line in every course, and AWS has restructured the page. The commitment is now
   "commercially reasonable efforts … with the Monthly Uptime Percentages set forth in the
   table", with no 100% figure stated. The credit bands are 10/25/100, and coverage is
   hosted zones only — not the API or console. The note's second clause (credits begin below
   100%) survived, which is why this is a rewrite rather than a deletion.

Also: a failover **alias** to an AWS resource must use Evaluate Target Health, not a health
check on the record — AWS says "don't create health checks for those resources" and its own
walkthrough sets Associate with Health Check = No.

Terraform leftovers found and removed here too: `set_identifier`, `weighted_routing_policy`.
That is the fourth note in a row carrying them, so the earlier Terraform-removal pass was
not as complete as its commit implied — expect more in the remaining notes.

---

## RESUME POINT — stopped 2026-10-06 (user went to work)

**Done: 18 of 30 exam notes.** Last commit `f981d3d` (10-route53). Working tree clean,
nothing half-applied. The `11-cloudfront` audit was launched and then **stopped mid-run**
(task `wiqge6zl1`, run `wf_dc293044-f43`) — it produced no usable result, so just relaunch
it from scratch.

**Completed:** 01-iam, 01-iam-advanced, 02-ec2, 04-alb-asg, 05-vpc-core, 05-vpc-security,
05-vpc, 05-vpc-endpoints-peering, 05-vpc-hybrid, 07-rds-aurora, 08-elasticache, 09-s3,
09-s3-intro, 09-s3-advanced, 09-s3-security, 10-route53. Plus cheatsheet.md kept in sync
per-note.

**Remaining queue, in order:** 11-cloudfront, 12-storage-extras, 13-cost-optimization,
14-dr-resilience, 15-decoupling, 16-kinesis, 17-containers, 19-serverless, 20-monitoring,
21-security, 22-analytics, 23-machine-learning, 24-other-services, 25-well-architected.
(03-ami-bake, 06-capstone, 18-containers-capstone are `exam: false` and excluded.)

**How to restart, exactly:**
1. `Workflow({scriptPath: "<scratchpad>/note-audit.js", args: {notes:["11-cloudfront.md"]}})`
   — the script is at the session scratchpad path; if the session is new, recreate it from
   the copy in the transcript or re-author it (prompts are in the git history of this file's
   commits). The truth lens is capped at **18 pages** and must stay capped: uncapped it ran
   2h 6m on 09-s3-advanced and returned nothing.
2. Wait for the workflow to COMPLETE, take over its results, then launch the next note's
   audit, then edit the current note. One workflow in flight at a time — the user was
   explicit about this.
3. Verify every citation first-hand before editing (§13.10c). Two concrete reasons from this
   run: an agent claimed RTC was "verified" at 99.99% with no URL when the page says 99.9%,
   and separately I introduced two unearned absolutes myself that the next lens caught.
4. Grep every note for Terraform leftovers explicitly — four consecutive notes had them
   despite an earlier pass claiming they were all removed.
5. Sync `cheatsheet.md` in the SAME commit as each note, not at the end.

**Still open, carried forward:**
- Terraform leftover at `17-containers.md:173`; truncated-quote trap at `19-serverless.md:132`.
- ALB `$0.0225/hr` restated in `19-serverless` (x2) and `18-containers-capstone`; NAT
  `$0.045/hr` in `17-containers` (x3), `18-containers-capstone`, `13-cost-optimization`.
- `13-cost-optimization:120` still carries the pre-correction public-IPv4 rule.
- `09-s3-security:265-272` duplicates EBS encryption with `12-storage-extras`.
- `15-decoupling:146` duplicates the SQS backlog formula.
- `06-capstone` contradictions on replica caps and backup retention (non-exam, low priority).
- 2 honest `⚠️ verify` markers in cheatsheet.md (ElastiCache default ports — no AWS page
  states them; ECS task trust principal — `17-containers` will cover it).
- Structural changes to the VPC and S3 notes are still HELD pending the user reading them.

**Do not attempt another unattended overnight run without checking `pmset -g batt` shows
"AC Power" first.** caffeinate's PreventSystemSleep does not bind on battery; that is why
the 2026-10-05 overnight run produced one note instead of twelve.

### 12-storage-extras (2026-10-07) — a hard date the note invented, and AWS contradicting itself

132 claims, 18 pages. Notably, this note's load-bearing *eliminations* all held up, which is
worth recording because they are the §13.10a shapes most likely to be wrong: "EFS is not
supported with Windows EC2 instances" is AWS's verbatim wording, and "ONTAP is the only FSx
with iSCSI block" survived an active counter-example hunt (OpenZFS is NFS-only, Windows SMB,
Lustre Lustre).

The failure was a **dated absolute with a consequence**: "AWS will discontinue support for
Snowball devices in all commercial Regions on 2026-12-31, after which the Snow Console and
Snowball resources become inaccessible." That date is on **no** AWS page. I fetched the
dedicated availability-change page and the General Reference shutdown table myself.

And AWS genuinely contradicts itself, which is now recorded in the note rather than resolved:
- Snowball developer guide: the change "will not impact customers currently using AWS
  Snowball Edge", and AWS "continues to invest in security and availability improvements".
- AWS General Reference, *Services in Full Shutdown* (defined as "completely removed from the
  AWS portfolio and… no longer available or supported in any capacity"): "AWS Snowball Edge |
  November 12, 2025".

Both cannot be true. Left as `⚠️ verify` with both citations, in the note and the cheatsheet.

Also: the closure is **family-wide** ("AWS will no longer offer any AWS Snow Family devices
for new customers to order"), so the Snowcone row in the device-selection table was reading
as a live option. Now a trap.

Side benefit: the same General Reference table lists "AWS Elemental MediaStore | November 12,
2025", which independently confirms dropping MediaStore from the CloudFront origin list in
the previous commit was right.

### 13-cost-optimization (2026-10-07) — healthiest note so far; 0 confirmed-wrong facts

124 claims, 19 pages, and **no confirmed-wrong fact**. The things most likely to be invented
all checked out verbatim: the 66/72/35/64% Savings Plans discounts and their flexibility
axes, the existence and full service list of **Database** Savings Plans, Compute Optimizer's
14-day / 93-day-with-paid-metrics windows and its surprising resource list (NAT Gateway,
DynamoDB, MemoryDB, WorkSpaces...), the Spot two-minute notice and its 404-when-not-marked
behaviour, and Domain 4 = 20% from the exam guide PDF.

Three overstatements, all the predicted shapes:
1. "**Only** zonal RIs and Capacity Reservations reserve capacity" — false twice over
   (Capacity Blocks reserve GPU clusters, a Dedicated Host is a host held for you), and the
   note contradicted itself: its own purchasing-options line already said so.
2. Savings Plans / reservation purchase recommendations are **not** Cost Explorer's alone —
   **Cost Optimization Hub** produces them and AWS steers you there first.
3. RIs labelled "legacy". AWS recommends SPs *over* RIs but RIs remain the only route to
   zonal capacity, the RI Marketplace and RDS/Redshift/ElastiCache reservations.

**Second false positive in my own carry-forward list.** The entry claiming
`13-cost-optimization:120` carried a pre-correction public-IPv4 rule was wrong: the note says
public IPv4 bills "whether attached or not", and AWS charges $0.005/hr for **both in-use and
idle** addresses — so the note was right and my note about it was not. Combined with the
README/cards false positive, the carry-forward list is now measurably less reliable than the
agents' cited findings. Verify carry-forward items before acting on them, same as agent
findings.

Resolved a pre-existing verify marker with a fetch: Spot one-time vs persistent is confirmed
verbatim, including the tie between request type and interruption behaviour (Stop/Hibernate
persistent-only; Terminate one-time-only and the default, so a persistent request left on
the default errors). The "cancelling a request doesn't terminate the instance" half is still
unsourced and stays marked.

### 14-dr-resilience (2026-10-07) — and a self-correction on the S3 RTC percentage

129 claims, 16 pages. Another strong note: the pilot-light/warm-standby wording, the whole
data-plane vs control-plane assignment, hot standby as active/passive, the Aurora figures
(10 secondaries, <1 min promotion, sub-second lag) and the detection/testing sections all
matched the DR whitepaper almost word for word. The note was even *ahead* of the whitepaper
on bidirectional S3 replication ("two or more buckets" per the current S3 User Guide, vs the
whitepaper's "between two Regions").

**Self-correction that matters.** On 09-s3-advanced I changed RTC from 99.99% to 99.9%, and
told the user it was "settled" because the agent's 99.99% claim carried no URL and I could
not reproduce it. This note's audit pointed at `replication.html`, and it is right:

- `replication-time-control.html`: "99.9 percent of those objects within 15 minutes"
- `replication.html` prose, twice: "S3 RTC replicates 99.99 percent of new objects…"
- `replication.html`'s OWN TABLE on the same page: "replicate 99.9 percent of objects…"

AWS contradicts itself within a single page. The earlier agent was not hallucinating; I was
over-confident in dismissing it. All three places (09-s3-advanced, cheatsheet x2,
14-dr-resilience x2) now carry the 15-minute threshold and explicitly refuse the percentage.

Lesson recorded: "I fetched a page and it said X" does not settle a fact when another page
may say Y. For a number the user will memorise, check whether AWS states it in more than one
place before declaring it resolved.

Other fixes: DynamoDB global tables now have two consistency modes (MREC default, MRSC for a
zero RPO, chosen at creation and immutable, MRSC same-account only) — the note taught
"seconds / last-writer-wins" as a flat property; "backup & restore is the ONLY copy the
disaster didn't reach" is an unearned absolute AWS's own whitepaper contradicts; warm standby
was described as "already serving" in two places and "not taking traffic" in two others;
ElastiCache Global Datastore is Valkey *or* Redis OSS and node-based only; availability is
"available-for-use time / total time", with MTBF/(MTBF+MTTR) only an estimate for
dependencies that publish no figure.
