# Line-by-line note audit — progress

Three agents per note, one note at a time:
- **truth** — every checkable claim verified against first-party AWS docs. Opus, high effort.
- **consistency** — self-contradiction, cross-note contradiction, duplication, links, structure, Terraform leftovers. Sonnet.
- **clarity** — cold read: can this be understood from the page alone, months later, with nothing else open? Sonnet.

Harness: `Workflow` with the saved script, `args: {notes:[...], lenses:[...]}`.
Rules that bind the edits: CLAUDE.md §13.10, §13.10a (asymmetry), §13.10b (seams), §13.10c (who verifies).

**Every change is re-verified by me against the AWS page before it is written.** Agents over-flag
on purpose; a citation that does not resolve, or does not contain the quoted text, is discarded.

| Note | truth | consistency | clarity | committed |
|---|---|---|---|---|
| 01-iam.md | 3 WRONG · 7 OVERSTATED · 1 UNVERIFIABLE | 11 | 10 | `13e94e6`, `0091f77` |
| 01-iam-advanced.md | 128 claims · 29 pages · 4 WRONG · 7 OVERSTATED · 1 STALE · 1 UNVERIFIABLE | 13 | 8 | `40ab3c3` + truth |
| 02-ec2.md | 168 claims · 33 pages · 2 WRONG · 8 OVERSTATED · 1 STALE · 4 UNVERIFIABLE | 19 | 10 | `pending` |
| 04-alb-asg.md | 158 claims · 34 pages · 3 WRONG · 6 OVERSTATED · 1 STALE · 3 citation/UNVERIFIABLE | 13 | 10 | `pending` |
| 05-vpc-core.md | | | | |
| 05-vpc-security.md | | | | |
| 05-vpc-endpoints-peering.md | | | | |
| 05-vpc-hybrid.md | | | | |
| 05-vpc.md | | | | |
| 07-rds-aurora.md | | | | |
| 08-elasticache.md | | | | |
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
