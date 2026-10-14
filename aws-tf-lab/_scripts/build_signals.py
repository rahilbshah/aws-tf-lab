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
    """
    return re.sub(r'\s+', ' ', _lib.clean(s)).strip().lower()

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

    for sect in sorted(groups):
        rows = groups[sect]
        out.append(f'\n## {sect}\n')
        out.append('| The stem says | The answer is | Not — because |')
        out.append('|---|---|---|')
        for e in sorted(rows, key=lambda r: r['signal'].lower()):
            tgt = _lib.link(e['note'][:-3], e.get('heading') or None,
                            _lib.clean(e['answer']), table=True)
            against = _lib.clean(e.get('against') or '')
            out.append(f"| {_lib.clean(e['signal'])} | {tgt} | {against or '—'} |")

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
