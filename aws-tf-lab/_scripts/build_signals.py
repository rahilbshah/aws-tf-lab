#!/usr/bin/env python3
"""Generate signals.md — the stem-phrase -> answer index.

    python3 _scripts/build_signals.py [--strict]

WHY THIS EXISTS, AND WHY IT IS NOT LIKE THE FLASHCARDS
------------------------------------------------------
The notes are indexed by SERVICE. An exam question is indexed by WHAT IT SAYS.
You cannot get from one to the other by reading, which is the one derived view
that is not redundant with the notes (see the no-redundant-views rule).

The retired flashcards drifted because nothing ever checked them against the
notes. So every entry here carries a VERBATIM quote from the note that owns it,
and this generator REFUSES to emit an entry whose quote no longer appears in
that note. Edit a note and contradict an entry, and the next build says so by
name instead of lying quietly. Drift becomes a build error.

Source of truth is still the note. _data/signals.json holds only the index:
the stem wording, the answer, the wrong neighbour, and a pointer.
"""
import re, io, os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA  = os.path.join(VAULT, '_data', 'signals.json')
OUT   = os.path.join(VAULT, 'signals.md')

def norm(s):
    """Whitespace-insensitive, emphasis-insensitive comparison form.

    A quote copied out of a note keeps its ** and its line wrapping; the note
    wraps at a different column than the JSON does. Neither difference means
    the fact changed, so both are normalised away before comparing. Nothing
    ELSE is normalised — if a word, number or negation differs, it fails.

    Emphasis markers are stripped WHOLESALE rather than via _lib.clean(). A
    quote that starts or ends inside a **bold** span carries one orphaned '**'
    that clean() cannot pair off, so it survives on the quote side while the
    note's balanced span is removed — and the comparison fails on a fact that
    is verbatim present. That cost 6 of the first 8 rejections on 2026-10-14.
    Stripping is safe here because this string is only ever compared, never
    rendered; _lib.clean still guards the output path, where `rds:*` matters.
    """
    s = re.sub(r'[*_`]+', '', s)          # see below
    return re.sub(r'\s+', ' ', s).strip().lower()

def main():
    strict = '--strict' in sys.argv
    if not os.path.exists(DATA):
        sys.exit(f'missing {DATA} — nothing to build')
    entries = json.load(io.open(DATA, encoding='utf-8'))

    texts, heads = {}, {}
    for path, text in _lib.notes(VAULT, include_non_exam=True):
        n = os.path.basename(path)
        texts[n] = text
        heads[n] = {_lib.clean(h).strip() for h in re.findall(r'^#{1,6}\s+(.+?)\s*$', text, re.M)}

    live, stale = [], []
    for e in entries:
        note = e['note'] if e['note'].endswith('.md') else e['note'] + '.md'
        if note not in texts:
            stale.append((e, f'no such note: {note}')); continue
        if norm(e['quote']) not in norm(texts[note]):
            stale.append((e, 'quote no longer in the note')); continue
        h = _lib.clean(e.get('heading', '')).strip()
        if h and h not in heads[note]:
            e = dict(e, heading='')          # heading moved; link to the note
        live.append(dict(e, note=note))

    groups = {}
    for e in live:
        groups.setdefault(e.get('section') or 'Unsorted', []).append(e)

    out = ['---', 'tags: [exam-prep, generated]', '---', '',
           '# 🎯 Signals — what the question says → what the answer is', '',
           '> [!warning] Generated file — do not edit',
           '> Built by `_scripts/build_signals.py` from `_data/signals.json`.',
           '> Every row is checked against a verbatim quote in the note that owns it;',
           '> an entry whose note stops supporting it is dropped and named below.', '',
           'Your notes are organised by **service**. A question is organised by **what it',
           'says**. This is the bridge: read the left column the way a stem reads, take the',
           'middle column as the answer, and use the right column to kill the neighbour you',
           'would otherwise pick.', '']

    # NOT a table. A three-column table of prose does not fit Obsidian's reading
    # width, so columns 2 and 3 — the answer and the eliminated neighbour — are
    # cut off entirely and the page shows only the question half. Reported
    # 2026-10-14 with a screenshot. Stacked lines wrap at any width, and survive
    # GitHub's renderer and a phone screen too.
    for sect in sorted(groups):
        rows = sorted(groups[sect], key=lambda r: r['signal'].lower())
        out.append(f'\n## {sect}  ·  {len(rows)}\n')
        for e in rows:
            # Two trailing spaces = a HARD line break. Without them Markdown
            # joins these three lines into one paragraph and the entry reads as
            # a wall of text with the answer buried mid-sentence (reported with
            # a screenshot, 2026-10-14). The answer is plain text and the note
            # link is a short tag at the end, so the eye lands on the answer
            # rather than on a long blue wikilink running into the next clause.
            note = e['note'][:-3]
            out.append(f"**{_lib.clean(e['signal'])}**  ")
            out.append(f"→ **{_lib.clean(e['answer'])}** "
                       f"{_lib.link(note, e.get('heading') or None, note)}  ")
            against = _lib.clean(e.get('against') or '')
            if against:
                out.append(f"✗ {against}")
            out.append('')

    if stale:
        out += ['', '---', '', '## ⚠️ Dropped — the note no longer supports these', '']
        for e, why in stale:
            out.append(f"- **{_lib.clean(e['signal'])}** → {_lib.clean(e['answer'])} "
                       f"(`{e['note']}`) — {why}")

    io.open(OUT, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
    print(f'signals.md: {len(live)} live in {len(groups)} sections, {len(stale)} dropped')
    for e, why in stale:
        print(f'  DROPPED  {e["note"]:28} {why}: {e["signal"][:60]}')
    if stale and strict:
        sys.exit(1)

if __name__ == '__main__':
    main()
