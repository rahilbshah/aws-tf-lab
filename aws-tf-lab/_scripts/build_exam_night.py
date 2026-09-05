#!/usr/bin/env python3
"""Generate exam-night.md — the fast morning skim.

    python3 _scripts/build_exam_night.py
"""
import re, io, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOOK = re.compile(r'^>\s*In one line:\s*(.+?)\s*$')
TRAP = re.compile(r'^>\s*\[!warning\]-?\s*Trap\s*[—\-–]\s*(.+?)\s*$')
FAIL = re.compile(r'^>\s*\[!failure\]-?\s*Failure mode\s*[—\-–]\s*(.+?)\s*$')

def harvest(path, text):
    name = os.path.basename(path)[:-3]
    title = _lib.clean((re.search(r'^# (.+)$', text, re.M) or [None, name])[1])
    anchor = _lib.traps_anchor(text)
    hooks, traps, fails, comps = [], [], [], []
    h2 = h3 = None
    for line in text.splitlines():
        m = re.match(r'^(#{2,3})\s+(.*\S)\s*$', line)
        if m:
            if len(m.group(1)) == 2:
                h2, h3 = m.group(2), None
                if re.search(r'\bvs\b|\bversus\b', h2, re.I): comps.append(h2)
            else:
                h3 = m.group(2)
                if _lib.heading_matches(h2 or '', 'comparison'): comps.append(h3)
            continue
        for rx, bucket in ((HOOK, hooks), (TRAP, traps), (FAIL, fails)):
            mm = rx.match(line)
            if mm:
                bucket.append((mm.group(1), h3 or h2, anchor or h2)); break
    return dict(name=name, title=title, hooks=hooks, traps=traps,
                fails=fails, comps=comps)

def main():
    body, n_hooks, n_ptrs, no_hooks = [], 0, 0, []
    for path, text in _lib.notes(VAULT):
        d = harvest(path, text)
        if not any((d['hooks'], d['traps'], d['fails'], d['comps'])): continue
        body.append(f"\n## {_lib.link(d['name'], display=d['title'])}\n")
        if d['hooks']:
            for hook, sect, _ in d['hooks']:
                n_hooks += 1
                h = _lib.clean(hook); h = h[:1].upper() + h[1:]
                body.append(f"- {h}  \n  ↳ {_lib.link(d['name'], sect, 'explain')}")
            body.append('')
        else:
            no_hooks.append(d['name'])
            body.append("*No recall hooks yet — this note hasn't had the comprehension pass.*\n")
        blocks = []
        if d['traps']:
            n_ptrs += len(d['traps'])
            blocks.append('**Traps** ' + _lib.link(d['name'], d['traps'][0][2], 'open') + '\n'
                          + '\n'.join(f'- {_lib.clean(t)}' for t, _, _ in d['traps']))
        if d['fails']:
            n_ptrs += len(d['fails'])
            blocks.append('**Failure modes**\n' + '\n'.join(
                f'- {_lib.clean(t)}  ↳ {_lib.link(d["name"], s, "open")}' for t, s, _ in d['fails']))
        if d['comps']:
            n_ptrs += len(d['comps'])
            blocks.append('**Comparisons**\n' + '\n'.join(
                f'- {_lib.link(d["name"], c, _lib.clean(c))}' for c in d['comps']))
        body += [b + '\n' for b in blocks]

    # count words WITHOUT wikilink syntax — the old estimate counted link targets
    words = sum(len(re.sub(r'\[\[[^\]]*\]\]', '', b).split()) for b in body)
    out = ['---', 'tags: [exam-prep, generated]', '---', '',
           '# 🌙 Exam-morning skim sheet', '',
           '> [!warning] Generated file — do not edit',
           '> Built by `_scripts/build_exam_night.py`. Edit the **notes**, then re-run.', '',
           '**How to use it.** Read a hook. If the concept comes straight back, move on.',
           "If it doesn't, follow the ↳ link — it lands on the section that *explains*",
           'that idea. Trap and comparison entries are titles only, on purpose.',
           'For the longer night-before read see **[[revision/00-index]]**.', '',
           f'*{n_hooks} recall hooks · {n_ptrs} pointers · ~{max(1, words//200)} min read*',
           ] + body
    io.open(os.path.join(VAULT, 'exam-night.md'), 'w', encoding='utf-8').write(
        '\n'.join(out).rstrip() + '\n')
    print(f'wrote exam-night.md — {n_hooks} hooks, {n_ptrs} pointers')
    if no_hooks:
        print(f'  note: {len(no_hooks)} note(s) have no recall hooks: {", ".join(no_hooks)}')

if __name__ == '__main__':
    main()
