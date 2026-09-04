#!/usr/bin/env python3
"""
Generate exam-night.md — a single revision sheet DERIVED from the topic notes.

Never edit exam-night.md by hand. It is a view, not a source. Edit the notes
and re-run this, so the sheet can't drift away from what the notes actually say.

    python3 _scripts/build_exam_night.py

What it harvests from each note:
  > In one line: ...            -> the recall hook, linked to the section that
                                   explains it (the whole point: if the hook
                                   doesn't fire, you jump straight to the
                                   explanation, not the top of a 300-line note)
  > [!warning] Trap — NAME      -> title only, as a pointer
  > [!failure] Failure mode — N -> title only, as a pointer
  ### X vs Y   (under Comparisons) -> title only, as a pointer
"""
import re, glob, io, os, datetime

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP = {'README.md', 'exam-prep.md', 'exam-night.md'}

H_RE     = re.compile(r'^(#{2,3})\s+(.*\S)\s*$')
HOOK_RE  = re.compile(r'^>\s*In one line:\s*(.+?)\s*$')
TRAP_RE  = re.compile(r'^>\s*\[!warning\]\s*Trap\s*[—\-–]\s*(.+?)\s*$')
FAIL_RE  = re.compile(r'^>\s*\[!failure\]\s*Failure mode\s*[—\-–]\s*(.+?)\s*$')

def clean(s):
    """Strip markdown emphasis for display text; link targets keep the original."""
    s = re.sub(r'`([^`]*)`', r'\1', s)
    s = re.sub(r'\*\*([^*]*)\*\*', r'\1', s)
    s = re.sub(r'\*([^*]*)\*', r'\1', s)
    return s.strip()

def link(note, heading=None, display=None):
    tgt = f'{note}#{heading}' if heading else note
    return f'[[{tgt}|{display}]]' if display else f'[[{tgt}]]'

def harvest(path):
    name = os.path.basename(path)[:-3]
    text = io.open(path, encoding='utf-8').read()
    if re.search(r'^tags:.*\bmoc\b', text, re.M):      # skip map-of-content notes
        return None
    m = re.search(r'^# (.+)$', text, re.M)
    title = clean(m.group(1)) if m else name

    hooks, traps, fails, comps = [], [], [], []
    h2 = h3 = None
    in_comparisons = False
    has_traps_heading = bool(re.search(r'^## Traps\s*$', text, re.M))

    for line in text.splitlines():
        h = H_RE.match(line)
        if h:
            level, txt = len(h.group(1)), h.group(2)
            if level == 2:
                h2, h3 = txt, None
                in_comparisons = txt.lower().startswith('comparison')
            else:
                h3 = txt
                if in_comparisons:
                    comps.append(txt)
            continue
        for rx, bucket in ((HOOK_RE, hooks), (TRAP_RE, traps), (FAIL_RE, fails)):
            m = rx.match(line)
            if m:
                bucket.append((m.group(1), h3 or h2))
                break
    return dict(name=name, title=title, hooks=hooks, traps=traps,
                fails=fails, comps=comps, traps_heading=has_traps_heading)

def main():
    notes = sorted(p for p in glob.glob(os.path.join(VAULT, '*.md'))
                   if os.path.basename(p) not in SKIP)
    out, n_hooks, n_ptrs = [], 0, 0
    body = []
    for p in notes:
        d = harvest(p)
        if not d or not (d['hooks'] or d['traps'] or d['fails'] or d['comps']):
            continue
        body.append(f"\n## {link(d['name'], display=d['title'])}\n")
        if d['hooks']:
            for hook, sect in d['hooks']:
                n_hooks += 1
                h = clean(hook)
                h = h[:1].upper() + h[1:]
                body.append(f"- {h}  \n  ↳ {link(d['name'], sect, 'explain')}")
            body.append('')
        else:
            body.append("*No recall hooks yet — this note hasn't had the comprehension pass.*\n")
        ptr = []
        if d['traps']:
            tgt = 'Traps' if d['traps_heading'] else None
            ptr.append('**Traps** ' + link(d['name'], tgt, 'open') + '\n' +
                       '\n'.join(f'- {clean(t)}' for t, _ in d['traps']))
            n_ptrs += len(d['traps'])
        if d['fails']:
            ptr.append('**Failure modes**\n' +
                       '\n'.join(f'- {clean(t)}  ↳ {link(d["name"], s, "open")}'
                                 for t, s in d['fails']))
            n_ptrs += len(d['fails'])
        if d['comps']:
            ptr.append('**Comparisons**\n' +
                       '\n'.join(f'- {link(d["name"], c, clean(c))}' for c in d['comps']))
            n_ptrs += len(d['comps'])
        body += [b + '\n' for b in ptr]

    stamp = datetime.date.today().isoformat()
    words = sum(len(l.split()) for l in body)
    out = [
        '---', 'tags: [exam-prep, generated]', f'generated: {stamp}', '---', '',
        '# 🌙 Exam-night revision sheet', '',
        '> [!warning] Generated file — do not edit',
        '> Built from the topic notes by `_scripts/build_exam_night.py`. Edit the',
        '> **notes**, then re-run the script. Editing this file directly means it',
        '> drifts from what the notes say, and you revise from something wrong.', '',
        '**How to use it.** Read a hook. If the concept comes straight back, move on.',
        'If it doesn\'t, follow the ↳ link — it lands on the section that *explains*',
        'that idea, not the top of the note. Trap and comparison entries are titles',
        'only, on purpose: the name is the hook, and if it doesn\'t fire you want the',
        'full wording anyway.', '',
        f'*{n_hooks} recall hooks · {n_ptrs} pointers · ~{max(1, words // 200)} min read*',
    ] + body
    dest = os.path.join(VAULT, 'exam-night.md')
    io.open(dest, 'w', encoding='utf-8').write('\n'.join(out).rstrip() + '\n')
    print(f'wrote exam-night.md — {n_hooks} hooks, {n_ptrs} pointers')

if __name__ == '__main__':
    main()
