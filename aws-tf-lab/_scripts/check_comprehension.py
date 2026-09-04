#!/usr/bin/env python3
"""
My own structural check on the comprehension pass — independent of what the
workflow's verify agents reported. A script answers "did these bytes change"
more reliably than a model does.

    python3 _scripts/check_comprehension.py
"""
import io, os, re, subprocess, sys, glob

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO  = os.path.dirname(VAULT)
# the note is considered "below the fold" from the first of these that appears
ANCHORS = ['## AWS console', '## Architecture diagram', '## Key facts', '## Comparisons']

def head_version(note):
    r = subprocess.run(['git', '-C', REPO, 'show', f'HEAD:aws-tf-lab/{note}.md'],
                       capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None

def fold(old, new):
    """Everything from the first '## ' heading the two versions SHARE.

    The head sections get renamed by the pass, so the first shared heading is
    exactly where the untouched region begins. More general than a fixed anchor
    list — some notes (03-ami-bake) have their own structure."""
    new_heads = set(re.findall(r'^## .+$', new, re.M))
    for m in re.finditer(r'^## .+$', old, re.M):
        if m.group(0) in new_heads:
            return old[m.start():]
    return None

def check(note):
    new = io.open(os.path.join(VAULT, note + '.md'), encoding='utf-8').read()
    old = head_version(note)
    P, F = [], []

    if old is None:
        return ['(new file — no HEAD version to compare)'], []

    # 1. frontmatter untouched
    fm = lambda t: t.split('---')[1] if t.startswith('---') else None
    (P if fm(new) == fm(old) else F).append('frontmatter identical')

    # 2. title untouched
    t = lambda x: (re.search(r'^# (.+)$', x, re.M) or [None, ''])[1]
    (P if t(new) == t(old) else F).append('title identical')

    # 3. BELOW THE FOLD byte-identical — the one that protects revision/
    tail = fold(old, new)
    (P if tail and tail in new else F).append('below-fold byte-identical')

    # 4. required new sections
    needed = ['## What problem does this solve?', '## How it actually works']
    if '[!info] Exam TL;DR' in old:      # notes without a TL;DR have nothing to move
        needed.append('## Exam recap')
    for h in needed:
        (P if h in new else F).append(f'has "{h}"')

    # 5. TL;DR moved verbatim, not reworded
    tl = lambda x: (re.search(r'(> \[!info\] Exam TL;DR\n(?:> .*\n?)+)', x) or [None, None])[1]
    if tl(old):
        (P if tl(new) and tl(new).strip() == tl(old).strip() else F).append('TL;DR verbatim')

    # 6. Concept section absorbed
    (P if '## Concept (plain English)' not in new else F).append('Concept section removed')

    # 7. teaching subsections
    sec = re.search(r'## How it actually works(.*?)(?=\n## )', new, re.S)
    n_sub = len(re.findall(r'^### ', sec.group(1), re.M)) if sec else 0
    (P if n_sub >= 2 else F).append(f'{n_sub} teaching subsections (need >=2)')

    # 8. recall hooks (these feed exam-night.md)
    n_hooks = len(re.findall(r'^> In one line:', new, re.M))
    (P if n_hooks >= 2 else F).append(f'{n_hooks} recall hooks (need >=2)')

    # 9. no backticks in headings — they break Obsidian wikilink targets
    bad = [h for h in re.findall(r'^#{2,6} (.+)$', new, re.M) if '`' in h]
    (P if not bad else F).append(f'no backticks in headings ({len(bad)} bad)' if bad else 'no backticks in headings')

    # 10. fences balanced
    (P if new.count('```') % 2 == 0 else F).append('code fences balanced')

    return P, F

if __name__ == '__main__':
    notes = sys.argv[1:] or sorted(
        os.path.basename(p)[:-3] for p in glob.glob(os.path.join(VAULT, '*.md'))
        if os.path.basename(p) not in {'README.md', 'exam-prep.md', 'exam-night.md'}
        and 'moc' not in (io.open(p, encoding='utf-8').read().split('---')[1] if
                          io.open(p, encoding='utf-8').read().startswith('---') else ''))
    bad = 0
    for n in notes:
        P, F = check(n)
        if F:
            bad += 1
            print(f'  FAIL {n}')
            for f in F: print(f'         - {f}')
        else:
            print(f'  ok   {n}  ({len(P)} checks)')
    print(f'\n{len(notes) - bad}/{len(notes)} notes structurally clean')
