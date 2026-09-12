"""Build the '## Self-test' section appended to each revision doc.

Replaces the hand-written SR cards deleted on 2026-09-06. Two reasons they went:

  * 368 cards were written, 3 were ever scheduled for review — 0.8% adoption.
  * Being hand-written, they were a FOURTH copy of every fact and drifted from
    the notes. The 2026-09-06 currency sweep fixed 58 facts in the notes; every
    card kept asserting the old ones.

So this generator takes nothing on faith and invents nothing: every answer is
lifted VERBATIM from the revision body the reader has just finished, which is
itself lifted verbatim from the note. It cannot disagree with the note.

It also drills the right thing. The measured failure mode is DISCRIMINATION —
answers marked 'sure' and wrong, where the fact was known but the wrong one of
two neighbours was retrieved. A definition card ("what is X?") does not test
that. A comparison table with the cells blanked does: you must produce both
sides and the axis that separates them.
"""
import re

def _tables(md):
    """(caption, header_line, sep_line, [body_rows]) for each comparison table.

    A comparison table has >=3 columns and >=2 body rows — a 2-column table is
    a glossary, not a discrimination.
    """
    out, lines = [], md.splitlines()
    i = 0
    while i < len(lines):
        if lines[i].startswith('|') and i + 1 < len(lines) and re.match(r'^\|[\s:|-]+\|$', lines[i+1]):
            hdr, sep, j = lines[i], lines[i+1], i + 2
            rows = []
            while j < len(lines) and lines[j].startswith('|'):
                rows.append(lines[j]); j += 1
            if hdr.count('|') >= 4 and len(rows) >= 2:
                cap = ''
                for k in range(i - 1, max(-1, i - 4), -1):     # nearest heading above
                    if lines[k].startswith('#'):
                        cap = lines[k].lstrip('# ').strip(); break
                out.append((cap, hdr, sep, rows))
            i = j
        else:
            i += 1
    return out

def _blank(row):
    """Keep the row label, blank every other cell."""
    cells = row.split('|')
    inner = cells[1:-1] if row.rstrip().endswith('|') else cells[1:]
    return '| ' + inner[0].strip() + ' |' + '|'.join('   ' for _ in inner[1:]) + '|'

def _traps(md):
    """(title, body-lines) for each trap callout, verbatim."""
    out, cur, buf = [], None, []
    for line in md.splitlines():
        m = re.match(r'^>\s*\[!warning\]-?\s*(?:Trap\s*[—:-]\s*)?(.+?)\s*$', line)
        if m:
            if cur: out.append((cur, buf))
            cur, buf = m.group(1), []
        elif cur is not None and line.startswith('>'):
            buf.append(line)
        elif cur is not None:
            out.append((cur, buf)); cur, buf = None, []
    if cur: out.append((cur, buf))
    return [(t, b) for t, b in out if b]

def _weakspots(md):
    """(prompt, answer) for each recorded weak spot.

    These are the human's OWN past mistakes, and until 2026-09-12 they were the
    only part of a note that reached neither the revision doc nor the self-test -
    build_revision.py dropped the section outright. A lesson written down after
    missing a question, then never drilled, is how the same question gets missed
    twice; 02-ec2's instance-store-vs-io2 note did exactly that.

    The house bullet style splits cleanly into a drill:
        - [ ] **the thing** - why it bites
    so the bold lead becomes the prompt and the rest becomes the answer.
    """
    m = re.search(r'^##[^\n]*weak spot[^\n]*$', md, re.M | re.I)
    if not m:
        return []
    body = re.split(r'^## ', md[m.end():], maxsplit=1, flags=re.M)[0]
    out = []
    for line in body.splitlines():
        s = line.strip()
        if not s.startswith('- '):
            continue
        s = re.sub(r'^-\s*(\[[ xX]\]\s*)?', '', s).strip()
        if not s:
            continue
        # The BOLD lead is the prompt whenever there is one, whether or not a
        # dash follows it. Splitting only on '** - ' produced prompts that
        # restated the whole fact, which is not a drill - you cannot test
        # recall with a question that contains its own answer.
        bold = re.match(r'^\*\*(.+?)\*\*\s*(?:[\u2014\u2013-]\s*)?(.*)$', s)
        if bold and bold.group(1).strip():
            prompt = bold.group(1).strip()
            rest = bold.group(2).strip()
            out.append((prompt, rest if rest else s))
        else:
            # no bold lead at all - keep a short hook, hide the rest
            cut = re.split(r'\s[\u2014\u2013-]\s', s, maxsplit=1)
            hook = cut[0].strip()
            if len(hook) > 70:
                hook = hook[:70].rsplit(' ', 1)[0] + '…'
            out.append((hook, s))
    return out

def section(body, note, full_text=None):
    """The '## Self-test' markdown, or None if the note yields nothing to drill.

    `full_text` is the ORIGINAL note, needed because weak spots may have been
    filtered out of `body` by the caller's section handling.
    """
    tabs, traps = _tables(body), _traps(body)
    weak = _weakspots(full_text if full_text is not None else body)
    if not tabs and not traps and not weak:
        return None

    out = ['## Self-test',
           '',
           '> [!question] Close the doc first.',
           '> Reading a comparison and being able to *produce* it are different skills, and',
           '> only the second one survives a question written to make two answers look alike.',
           '> Say each answer out loud before you unfold it — if you can only recognise it,',
           '> you do not know it yet.',
           '']

    if weak:
        out += ['### You have got these wrong before', '',
                '*Your own recorded misses. Answer each one before unfolding it — these are,'
                ' by definition, the ones that have already cost you marks.*', '']
        for prompt, answer in weak:
            out.append(f'> [!question]- {prompt}')
            out.append(f'> {answer}')
            out.append('')

    n = 0
    for cap, hdr, sep, rows in tabs:
        n += 1
        out.append(f'**{n}. {cap or "Fill in the grid"}** — fill the blank cells from memory.')
        out += ['', hdr, sep] + [_blank(r) for r in rows] + ['']
        out.append('> [!success]- Answer')
        out += [f'> {l}' for l in [hdr, sep] + rows]
        out.append('')

    if traps:
        out += ['### The traps', '',
                '*Each of these is a place a plausible-looking answer is wrong. Say why before unfolding.*', '']
        for title, blines in traps:
            out.append(f'> [!question]- {title}')
            out += [('> ' + l.lstrip('>').strip()).rstrip() for l in blines]
            out.append('')

    out.append(f'*Answers are lifted verbatim from [[{note}]]. '
               'Generated by `_scripts/build_revision.py` — do not edit.*')
    return '\n'.join(out).rstrip()
