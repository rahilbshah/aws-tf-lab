#!/usr/bin/env python3
"""
Generate discriminators.md — every "which of these two is it?" pair in the vault,
in one place, with the sentence that actually separates them.

The human's measured failure mode is discrimination: picking between two
plausible options. This gathers every comparison table and every trap across all
notes so those decisions can be drilled in one pass instead of hunting through 20
notes.

Content is lifted VERBATIM (trap opening sentences, comparison headings). Nothing
is paraphrased, so the sheet cannot say something the notes don't.

    python3 _scripts/build_discriminators.py
"""
import re, io, os, glob

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP  = {'README.md', 'exam-prep.md', 'exam-night.md', 'discriminators.md'}

# Traps only. Failure modes open with narrative setup, not a discriminator —
# they live in full in the revision docs where the story is the point.
TRAP_RE = re.compile(r'^>\s*\[!warning\][-]?\s*Trap\s*[—\-–]\s*(.+?)\s*$')

def clean(s):
    s = re.sub(r'`([^`]*)`', r'\1', s)
    s = re.sub(r'\*\*([^*]*)\*\*', r'\1', s)
    s = re.sub(r'\*([^*]*)\*', r'\1', s)
    return s.strip()

def first_sentence(lines):
    """First sentence of a callout body, verbatim (minus the '> ' prefix)."""
    body = ' '.join(l.lstrip('> ').strip() for l in lines).strip()
    if not body:
        return None
    # keep taking sentences until there is enough to actually discriminate —
    # some traps open with a short punch ("Route 53 did fail over.") that means
    # nothing on its own
    out, rest = '', body
    while len(out) < 90:
        m = re.match(r'(.{10,300}?[.!?])(\s|$)', rest)
        if not m:
            out = (out + ' ' + rest[:300]).strip(); break
        out = (out + ' ' + m.group(1)).strip()
        rest = rest[m.end():]
        if not rest: break
    return clean(out[:340])

def harvest(path):
    name = os.path.basename(path)[:-3]
    text = io.open(path, encoding='utf-8').read()
    if re.search(r'^tags:.*\bmoc\b', text, re.M):
        return None
    title = clean((re.search(r'^# (.+)$', text, re.M) or [None, name])[1])

    pairs, traps = [], []
    in_comparisons = False
    cur_trap, buf = None, []
    has_traps_head = bool(re.search(r'^## Traps\s*$', text, re.M))

    for line in text.splitlines():
        h = re.match(r'^(#{2,3})\s+(.*\S)\s*$', line)
        if h:
            if len(h.group(1)) == 2:
                in_comparisons = h.group(2).lower().startswith('comparison')
            elif in_comparisons:
                pairs.append(h.group(2))
        m = TRAP_RE.match(line)
        if m:
            if cur_trap: traps.append((cur_trap, first_sentence(buf)))
            cur_trap, buf = m.group(1), []
        elif cur_trap is not None and line.startswith('>'):
            buf.append(line)
        elif cur_trap is not None:
            traps.append((cur_trap, first_sentence(buf))); cur_trap, buf = None, []
    if cur_trap: traps.append((cur_trap, first_sentence(buf)))

    return dict(name=name, title=title, pairs=pairs, traps=traps,
                traps_head=has_traps_head) if (pairs or traps) else None

def main():
    notes = sorted(p for p in glob.glob(os.path.join(VAULT, '*.md'))
                   if os.path.basename(p) not in SKIP)
    body, n_pairs, n_traps = [], 0, 0
    for p in notes:
        d = harvest(p)
        if not d: continue
        body.append(f"\n## [[{d['name']}|{d['title']}]]\n")
        if d['pairs']:
            n_pairs += len(d['pairs'])
            body.append('**Compare:** ' + ' · '.join(
                f"[[{d['name']}#{c}|{clean(c)}]]" for c in d['pairs']) + '\n')
        for name, sent in d['traps']:
            if not sent: continue
            n_traps += 1
            tgt = f"{d['name']}#Traps" if d['traps_head'] else d['name']
            body.append(f"- **{clean(name)}** — {sent}  \n  ↳ [[{tgt}|note]]")
        body.append('')

    words = sum(len(b.split()) for b in body)
    out = ['---', 'tags: [exam-prep, generated]', '---', '',
           '# ⚖️ Discriminators — "which of these two is it?"', '',
           '> [!warning] Generated file — do not edit',
           '> Built from the notes by `_scripts/build_discriminators.py`. Edit the',
           '> **notes**, then re-run. Every line is lifted verbatim.', '',
           'Your mock data says the thing costing you marks is **choosing between two',
           'plausible options**, not recalling facts. This is every such pair in the',
           'vault in one place: the comparison tables to open, and the sentence that',
           'actually separates each trap pair.', '',
           f'*{n_pairs} comparison tables · {n_traps} discriminators · ~{max(1, words//200)} min read*',
           ] + body
    io.open(os.path.join(VAULT, 'discriminators.md'), 'w', encoding='utf-8').write(
        '\n'.join(out).rstrip() + '\n')
    print(f'wrote discriminators.md — {n_pairs} comparison tables, {n_traps} discriminators')

if __name__ == '__main__':
    main()
