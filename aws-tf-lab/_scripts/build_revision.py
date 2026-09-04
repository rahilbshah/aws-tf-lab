#!/usr/bin/env python3
"""
Generate revision/NN-topic.md — the night-before read, one file per service.

SELF-CONTAINED by design: everything you need is in the file, so you don't have
to jump back to the note mid-revision. Content is lifted VERBATIM from the note,
never paraphrased, so no fact can drift and nothing new can be invented.

Keeps:  Exam TL;DR · Key facts · Comparisons · Worked examples · Traps
Drops:  teaching walk-through, Terraform map, architecture diagrams,
        "The Terraform I wrote", drills, weak spots, doc links

    python3 _scripts/build_revision.py [note-name ...]
"""
import re, io, os, sys, glob

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT   = os.path.join(VAULT, 'revision')
SKIP  = {'README.md', 'exam-prep.md', 'exam-night.md'}

# section heading -> heading to use in the revision file
KEEP = [
    (r'^## Key facts.*$',      '## Facts, limits & pricing'),
    (r'^## Comparisons\s*$',   '## Comparisons'),
    (r'^## Worked examples\s*$','## Worked examples'),
    (r'^## Traps\s*$',         '## Traps'),
]

def sections(text):
    """Split a note into {h2_heading: body} preserving order."""
    parts, cur, buf = [], None, []
    for line in text.splitlines():
        if re.match(r'^## ', line):
            if cur is not None: parts.append((cur, '\n'.join(buf).strip()))
            cur, buf = line, []
        elif cur is not None:
            buf.append(line)
    if cur is not None: parts.append((cur, '\n'.join(buf).strip()))
    return parts

def loose_callouts(text, kinds=('warning', 'failure')):
    """Trap/failure callouts that aren't under a ## Traps heading."""
    out, buf, grab = [], [], False
    for line in text.splitlines():
        m = re.match(r'^>\s*\[!(\w+)\][-]?\s*(Trap|Failure mode)\b', line)
        if m and m.group(1) in kinds:
            if buf: out.append('\n'.join(buf))
            buf, grab = [line], True
        elif grab and line.startswith('>'):
            buf.append(line)
        elif grab:
            out.append('\n'.join(buf)); buf, grab = [], False
    if buf: out.append('\n'.join(buf))
    return out

def build(path):
    name = os.path.basename(path)[:-3]
    text = io.open(path, encoding='utf-8').read()
    if re.search(r'^tags:.*\bmoc\b', text, re.M): return None
    title = (re.search(r'^# (.+)$', text, re.M) or [None, name])[1]

    tldr = re.search(r'(> \[!info\] Exam TL;DR\n(?:> .*\n?)+)', text)
    secs = sections(text)
    body, seen_traps = [], False

    if tldr:
        body.append('## The shape of it\n\n' + tldr.group(1).rstrip())
    for pat, newhead in KEEP:
        for head, content in secs:
            if re.match(pat, head) and content:
                if newhead == '## Traps': seen_traps = True
                body.append(f'{newhead}\n\n{content}')
    if not seen_traps:
        # only callouts we haven't already captured inside a kept section —
        # otherwise failure modes living under "Worked examples" appear twice
        already = '\n'.join(body)
        loose = [c for c in loose_callouts(text)
                 if c.splitlines()[0] not in already]
        if loose:
            body.append('## Traps & failure modes\n\n' + '\n\n'.join(loose))

    if not body: return None
    words = sum(len(b.split()) for b in body)
    hdr = [
        '---', f'topic: {name}', 'type: revision', f'source: {name}',
        'tags: [revision, generated]', '---', '',
        f'# Revision — {title}', '',
        f'> [!abstract] Night-before read · ~{max(1, round(words/200))} min · self-contained',
        f'> Everything you need is here — no need to jump back mid-revision.',
        f'> Full teaching explanations, Terraform and diagrams: **[[{name}]]**',
        f'> *Generated from the note by `_scripts/build_revision.py` — do not edit.*', '',
    ]
    dest = os.path.join(OUT, name + '.md')
    io.open(dest, 'w', encoding='utf-8').write('\n'.join(hdr) + '\n\n'.join(body).rstrip() + '\n')
    return name, max(1, round(words/200))

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    targets = ([os.path.join(VAULT, a + '.md') for a in sys.argv[1:]] if len(sys.argv) > 1
               else [p for p in sorted(glob.glob(os.path.join(VAULT, '*.md')))
                     if os.path.basename(p) not in SKIP])
    total, rows = 0, []
    for p in targets:
        r = build(p)
        if r:
            print(f'  {r[0]:26} ~{r[1]:2} min'); total += r[1]; rows.append(r)

    # index — only rebuilt on a full run, so a single-note run can't truncate it
    if len(sys.argv) == 1:
        idx = ['---', 'tags: [revision, generated]', '---', '',
               '# 🌙 Night-before revision — index', '',
               f'**{len(rows)} topics · ~{total} min total.** Each one is self-contained;',
               'you should not need the full note. Tick them off as you go.', '',
               '> [!tip] Order',
               '> This lists them in vault order. The night before, start with whatever',
               '> your last mock said was weakest — read those while you are freshest.', '',
               '| ✓ | Topic | Read | Full note |', '|---|---|---|---|']
        for name, mins in rows:
            idx.append(f'| [ ] | [[revision/{name}\\|{name}]] | ~{mins} min | [[{name}]] |')
        idx += ['', '*Generated by `_scripts/build_revision.py` — do not edit.*']
        io.open(os.path.join(OUT, '00-index.md'), 'w', encoding='utf-8').write('\n'.join(idx) + '\n')
        print('  wrote revision/00-index.md')
    print(f'total ~{total} min')
