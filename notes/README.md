# SAA-C03 Notes — Master Index

Entry point for all per-topic notes in this repo. Updated at the end of every topic per `CLAUDE.md §13.4`.

Per-topic files live alongside this one (`01-iam.md`, `02-vpc.md`, …) and follow the layered template in `CLAUDE.md §13.3`. Anki-importable flashcards mirror each topic file under `notes/anki/`.

## Master index

| #   | Topic                          | Status      | Last updated |
|-----|--------------------------------|-------------|--------------|
| 01  | [IAM](01-iam.md)               | ✅ Complete | 2026-05-23   |

## 🔴 Cumulative weak spots (across all topics)

A running checkbox list of concepts the learner has gotten wrong or hesitated on, aggregated from each topic's `🔴 My weak spots` section. These get re-surfaced during quizzes and mock exams; tick them off as they're mastered.

### 01 – IAM

- [ ] Enumerating IAM core objects under "list them" framing (forgot Role despite using it correctly elsewhere)
- [ ] HCL: spotting a quoted "reference" (literal string) vs an unquoted reference
- [ ] `.arn` vs `.name` pattern in IAM Terraform cross-references (principals → `.name`, policies → `.arn`)
- [ ] Reading plan symbols: `~` (in-place) vs `-/+` (destroy-and-recreate) vs `+`/`-`
- [ ] Scope of `aws_iam_policy_attachment` — per-policy exclusive, NOT per-group/per-principal
