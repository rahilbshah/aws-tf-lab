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
| 01-iam-advanced.md | *running* | 13 | 8 | `40ab3c3` (2 lenses) |
| 02-ec2.md | | | | |
| 04-alb-asg.md | | | | |
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

## Known limitation, not a defect
The generators cannot anchor a heading that contains an inline tag, so every note's
`## ⚠️ Traps … #trap` section is linked bare (`[[note|note]]`) in `discriminators.md`
and `exam-night.md` rather than deep-linked. Affects all 33 notes equally.
