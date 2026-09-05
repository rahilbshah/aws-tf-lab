#!/usr/bin/env python3
"""Generate discriminators.md — every "which of these two is it?" pair.

    python3 _scripts/build_discriminators.py

Verbatim extraction only. See _lib.py for the audit findings this fixes.
"""
import re, io, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRAP = re.compile(r'^>\s*\[!warning\]-?\s*Trap\s*[—\-–]\s*(.+?)\s*$')   # -? = foldable

def harvest(path, text):
    name = os.path.basename(path)[:-3]
    title = _lib.clean((re.search(r'^# (.+)$', text, re.M) or [None, name])[1])
    anchor = _lib.traps_anchor(text)

    pairs = [h for h, _ in _lib.find_sections(text, 'comparison')]
    pairs = [m.group(1).strip()
             for sec in [b for _, b in _lib.find_sections(text, 'comparison')]
             for m in re.finditer(r'^### (.+)$', sec, re.M)]
    # comparisons written at H2 (e.g. "## Bake-at-build vs install-at-boot")
    pairs += [h.strip() for h in re.findall(r'^## (.+)$', text, re.M)
              if re.search(r'\bvs\b|\bversus\b', h, re.I)]

    # track the enclosing H2 so a trap that lives inline still gets a useful
    # anchor instead of degrading to the top of a 400-line note
    traps, cur, buf, h2, cur_h2 = [], None, [], None, None
    for line in text.splitlines():
        if line.startswith('## '):
            h2 = line[3:].strip()
        m = TRAP.match(line)
        if m:
            if cur: traps.append((cur, _lib.discriminating_text(buf, cur), cur_h2))
            cur, buf, cur_h2 = m.group(1), [], anchor or h2
        elif cur is not None and line.startswith('>'):
            buf.append(line)
        elif cur is not None:
            traps.append((cur, _lib.discriminating_text(buf, cur), cur_h2))
            cur, buf = None, []
    if cur: traps.append((cur, _lib.discriminating_text(buf, cur), cur_h2))

    return dict(name=name, title=title, pairs=pairs, traps=traps, anchor=anchor)

def main():
    body, n_pairs, n_traps, unanchored = [], 0, 0, []
    for path, text in _lib.notes(VAULT):
        d = harvest(path, text)
        if not (d['pairs'] or d['traps']): continue
        body.append(f"\n## {_lib.link(d['name'], display=d['title'])}\n")
        if d['pairs']:
            n_pairs += len(d['pairs'])
            body.append('**Compare:** ' + ' · '.join(
                _lib.link(d['name'], p, _lib.clean(p)) for p in d['pairs']) + '\n')
        if not d['anchor'] and d['traps']: unanchored.append(d['name'])
        for name, sent, sect in d['traps']:
            if not sent: continue
            n_traps += 1
            body.append(f"- **{_lib.clean(name)}** — {sent}  \n"
                        f"  ↳ {_lib.link(d['name'], sect, 'note')}")
        body.append('')

    words = sum(len(re.sub(r'\[\[[^\]]*\]\]', '', b).split()) for b in body)
    out = ['---', 'tags: [exam-prep, generated]', '---', '',
           '# ⚖️ Discriminators — "which of these two is it?"', '',
           '> [!warning] Generated file — do not edit',
           '> Built by `_scripts/build_discriminators.py`. Edit the **notes**, then re-run.',
           '> Every line is lifted verbatim.', '',
           'Your mock data says what costs you marks is **choosing between two plausible',
           'options**, not recalling facts. This is every such pair in the vault: the',
           'comparison tables to open, and the sentence that separates each trap pair.', '',
           f'*{n_pairs} comparison tables · {n_traps} discriminators · ~{max(1, words//200)} min read*',
           ] + body
    io.open(os.path.join(VAULT, 'discriminators.md'), 'w', encoding='utf-8').write(
        '\n'.join(out).rstrip() + '\n')
    print(f'wrote discriminators.md — {n_pairs} comparison tables, {n_traps} discriminators')
    if unanchored:
        print(f'  note: no traps heading found in {len(unanchored)} note(s), '
              f'links land at note top: {", ".join(unanchored)}')

if __name__ == '__main__':
    main()
