# Comprehension pass — spec

Add a plain-language teaching layer to the **head** of a topic note. Nothing else changes.

## Why

The notes were written in a *reference* register: compressed, precise, ideal for
someone who already holds the concept and needs a fact checked. They fail for
someone learning it. The reader was pasting them into a separate assistant and
asking for a simpler explanation.

Diagnosis: a "remember it" layer with no "understand it" layer.

## The reference implementation

**Read `01-iam-advanced.md` first.** It has already had this pass. Match its
register, its rhythm, and its section shape. Do not invent a different format.

## Required structure

Replace everything between the `# Title` line and the first `##` heading that is
NOT `## Concept (plain English)` with:

```
# <existing title, unchanged>

<one or two sentences orienting the reader — what this note is about>

<any existing safety/build-tier callout, moved here verbatim if present>

## What problem does this solve?

<Plain language. Why does this service exist? What was painful before it?
Short sentences. No AWS jargon until you've earned it. 2-5 short paragraphs.>

> In one line: <the compressed version — the retrieval handle>

## How it actually works

### <A concrete sub-mechanism>

<Walk the reader through it. Use a small table or a worked trace where it
genuinely helps. Explain WHY a rule is the way it is, not just that it is —
rules with a reason attached stick, bare facts don't.>

> In one line: <handle>

### <2 to 5 such subsections, chosen by what is genuinely hard in this topic>

...

## Exam recap

*Now that the mechanisms are clear, this is the compressed version to revise from.*

<the note's existing `> [!info] Exam TL;DR` callout, VERBATIM, not retyped>
```

Then `## AWS console ↔ Terraform map` (or whatever the next section is) continues
exactly as it already is.

## HARD RULES — a violation fails the pass

1. **Invent nothing.** Every factual claim in your new text must already be
   somewhere in this note. You are re-explaining existing content, not
   researching. If something feels missing, leave it missing.
2. **Change nothing below the fold.** Everything from the first structural
   section (`## AWS console ↔ Terraform map`, `## Key facts`, or whichever comes
   first after the head) to the end of the file must be **byte-identical**. This
   is checked mechanically. The revision docs are generated from those sections.
3. **Move the TL;DR, don't rewrite it.** Copy the existing callout verbatim under
   `## Exam recap`. Do not reword, reorder, or "improve" it.
4. **Delete `## Concept (plain English)`** — its content is absorbed into your
   new sections. Nothing it said may be lost.
5. **Frontmatter untouched.**
6. **No backticks in headings** — they break Obsidian wikilink targets.

## Register

- Short sentences. Concrete over abstract.
- An analogy only if it genuinely helps; a forced one is worse than none.
- Prefer a worked trace ("walk a real one") over a definition.
- Explain the *exception* — why is this rule odd? That is usually the thing that
  makes it memorable.
- Expect roughly 4x the words of the section you are replacing. Length is fine;
  vagueness is not.

## Output

Write the file. Then reply with a JSON object only.
