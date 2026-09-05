"""Shared helpers for the three study-artifact generators.

Every function here exists because the 2026-09-06 audit found a real defect:

- heading matching was EXACT, so "## ⚠️ Traps & why the wrong answers are wrong"
  never matched "## Traps" and 64% of trap back-links pointed at the top of a
  400-line note instead of its traps.
- clean() stripped emphasis with a naive regex that ate the `*` out of `rds:*`
  and left a dangling "management*".
- sentence extraction stopped at 90 chars, so half of every "X vs Y" trap was
  cut — including one that inverted the most-tested SCP fact.
- a hard character cut truncated mid-word.
- headings containing '#' were interpolated straight into wikilink anchors,
  which Obsidian parses as a nested subpath.
- notes sorted by filename, so 01b came before 01 and 05.2 came after 05.4.
"""
import re

# --- text cleaning ------------------------------------------------------------

def clean(s):
    """Strip markdown emphasis WITHOUT touching inline code spans.

    The old version applied \\*([^*]*)\\* across the whole string, which paired
    the '*' of `rds:*` with the opening '*' of *management* and destroyed both.
    """
    spans, out = [], []
    for i, part in enumerate(re.split(r'(`[^`]*`)', s)):
        if i % 2:                       # inside backticks — leave alone
            out.append(part[1:-1])
        else:
            part = re.sub(r'\*\*([^*]+)\*\*', r'\1', part)
            part = re.sub(r'(?<!\*)\*([^*\s][^*]*?)\*(?!\*)', r'\1', part)
            out.append(part)
    return ''.join(out).strip()

# --- headings -----------------------------------------------------------------

# a heading "matches" if the keyword appears in it once decoration is removed
def heading_matches(heading, keyword):
    h = clean(heading).lower()
    h = re.sub(r'[^a-z0-9 &]+', ' ', h)          # drop emoji, #tags, punctuation
    return keyword.lower() in h

def find_sections(text, keyword, level=2):
    """All (heading, body) pairs whose heading contains `keyword`, fuzzily."""
    out = []
    pat = re.compile(rf'^{"#"*level} ', re.M)
    parts = []
    cur, buf = None, []
    for line in text.splitlines():
        if pat.match(line):
            if cur is not None: parts.append((cur, '\n'.join(buf).strip()))
            cur, buf = line, []
        elif cur is not None:
            buf.append(line)
    if cur is not None: parts.append((cur, '\n'.join(buf).strip()))
    for h, b in parts:
        if heading_matches(h, keyword):
            out.append((h, b))
    return out

def traps_anchor(text):
    """The heading to anchor trap links at, or None if traps live inline."""
    for m in re.finditer(r'^## (.+)$', text, re.M):
        if heading_matches(m.group(1), 'trap'):
            return m.group(1).strip()
    return None

# --- links --------------------------------------------------------------------

def anchor_safe(heading):
    """Obsidian splits a wikilink subpath on every '#', so a heading containing
    one can never resolve. Refuse rather than emit a broken link."""
    return heading is not None and '#' not in heading and '|' not in heading

def link(note, heading=None, display=None, table=False):
    if heading is not None and not anchor_safe(heading):
        heading = None                      # degrade to a note-level link
    tgt = f'{note}#{heading}' if heading else note
    if display:
        sep = r'\|' if table else '|'       # '|' must be escaped inside a table
        return f'[[{tgt}{sep}{display}]]'
    return f'[[{tgt}]]'

# --- sentences ----------------------------------------------------------------

# (?<![.]) and (?![.]) stop '...' being read as a sentence end — several notes
# contain a literal ellipsis inside a quoted expression, e.g. Bool ... "true"
_SENT = re.compile(r'(.+?(?<![.])[.!?](?![.…]))(?:\s|$)', re.S)

def discriminating_text(lines, title='', min_chars=90, max_chars=420):
    """Opening sentences of a callout, verbatim, cut only at a sentence boundary.

    Two audit findings drive this:
      - a trap titled "X vs Y" must carry BOTH sides; stopping at 90 chars gave
        one side and invited the opposite generalisation.
      - the old code fell back to rest[:300], truncating mid-word.
    """
    body = ' '.join(l.lstrip('> ').strip() for l in lines).strip()
    if not body:
        return None
    # a two-sided pair needs enough room for both halves
    two_sided = bool(re.search(r'\bvs\b|\bversus\b', title, re.I)) or \
                bool(re.search(r'\bboth halves\b|\btwo errors\b|\bthree tools\b', body, re.I))
    target = 260 if two_sided else min_chars
    if two_sided:
        max_chars = max(max_chars, 620)   # the second half can be long

    out = ''
    for m in _SENT.finditer(body):
        nxt = (out + ' ' + m.group(1)).strip()
        if out and len(nxt) > max_chars:
            break
        out = nxt
        if len(out) >= target:
            break
    if not out:                                   # no sentence terminator at all
        cut = body[:max_chars]
        out = cut.rsplit(' ', 1)[0] + '…' if len(body) > max_chars else cut
    return clean(out)

# --- note discovery -----------------------------------------------------------

GENERATED = {'README.md', 'exam-prep.md', 'exam-night.md', 'discriminators.md'}

def _order_key(path, text):
    """Sort by the NUMBER IN THE TITLE, not the filename.

    Filename order put 01b before 01 and 05.2 after 05.4.
    """
    m = re.search(r'^#\s*([\d]+(?:\.[\d]+)*)\s*([a-z]?)', text, re.M)
    if not m:
        return ((999,), 'z', path)
    nums = tuple(int(x) for x in m.group(1).split('.'))
    return (nums, m.group(2) or '', path)

def notes(vault, include_non_exam=False):
    """Topic notes in study order, skipping MOCs, generated files, and
    (unless asked) notes whose frontmatter says exam: false."""
    import glob, io, os
    found = []
    for p in glob.glob(os.path.join(vault, '*.md')):
        if os.path.basename(p) in GENERATED:
            continue
        t = io.open(p, encoding='utf-8').read()
        fm = t.split('---')[1] if t.startswith('---') else ''
        if re.search(r'^tags:.*\bmoc\b', fm, re.M):
            continue
        if not include_non_exam and re.search(r'^exam:\s*false\s*$', fm, re.M):
            continue
        found.append((p, t))
    found.sort(key=lambda pt: _order_key(*pt))
    return found
