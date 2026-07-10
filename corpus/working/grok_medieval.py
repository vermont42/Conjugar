#!/usr/bin/env python3
"""Grok the three medieval editions into verse-only text + a ref map for the medieval index.

The medieval `.txt` files under corpus/originals/medieval still carry their MODERN editorial
apparatus — Menéndez Pidal's interspersed footnotes and section headings in the Cid, the
Cláusicos-Castellanos prose + `[Nota …]` notes in the Libro de buen amor, page-running headers
in Berceo. That apparatus is modern Castilian; if it fed the medieval index it would inject
modern verb forms into "medieval example" lookups (the single biggest correctness risk of the
tier — see prompts/example-uses-pipeline.md §A / Foot-guns). This script isolates the verse and
emits, per surviving verse line, a citation ref the app can show:

  * Cid    → "Cantar {I,II,III}, v. N"   (running verse counter, snapped to the OCR's own
                                          marginal verse numbers; cantar by Menéndez Pidal range)
  * Berceo → "estrofa N"                 (cuaderna-vía stanzas counted in order)
  * LBA    → "copla N"                   (N read straight from the edition's own [N] marker)

Outputs (all tracked under corpus/grokked/ — irreplaceable verified work):
  * <slug>.txt            one verse line per row, for human inspection / diffing
  * medieval_verses.json  [ {work, ref, text, cantar?} ] consumed by build_medieval_index.py

Run:  python3 grok_medieval.py   (idempotent; rewrites corpus/grokked/*)
"""
import json
import os
import re
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.path.dirname(HERE)
MEDIEVAL = os.path.join(CORPUS, "originals", "medieval")
GROKKED = os.path.join(CORPUS, "grokked")

CID_TXT = os.path.join(MEDIEVAL, "cantar-de-mio-cid-menendezpidal-1913.txt")
BERCEO_TXT = os.path.join(MEDIEVAL, "milagros-berceo.txt")
LBA_TXT = os.path.join(MEDIEVAL, "libro-de-buen-amor-juan-ruiz-1330.txt")


def nfc(s):
    return unicodedata.normalize("NFC", s)


def read_lines(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return [nfc(ln.rstrip("\n")) for ln in fh]


def blocks(lines):
    """Yield blank-line-separated blocks as lists of (physical_lineno, text)."""
    cur = []
    for i, ln in enumerate(lines, start=1):
        if ln.strip():
            cur.append((i, ln))
        elif cur:
            yield cur
            cur = []
    if cur:
        yield cur


# ---------------------------------------------------------------------------------------------
# Cantar de Mio Cid
# ---------------------------------------------------------------------------------------------
CID_BODY_START = 184     # verse 1: "De los sos ojos tan fuertemientre llorando,"
CID_BODY_END = 10025     # verse 3730: "373° en este logar se acaba esta razón."
# Menéndez Pidal cantar boundaries (last verse of each cantar).
CID_CANTAR_END = [(1084, "I"), (2277, "II"), (3730, "III")]

LEAD_NUM = re.compile(r"^\s*([0-9iIlojctS¡]{1,4})\s+")
_DIGITMAP = str.maketrans({"i": "1", "I": "1", "l": "1", "j": "1", "t": "1",
                           "o": "0", "c": "0", "S": "5", "¡": "1"})

# The OCR spells the poem's own "Cid" as £id / Qid / Cjd / CJd; a CLEAN "Cid" token betrays
# editorial (heading or footnote) text, since the verse never has it un-garbled.
GARBLED_CID = re.compile(r"[£Q]id|C[Jj]d", re.IGNORECASE)

# High-precision APPARATUS signals — Menéndez Pidal's footnotes + editorial headings are modern
# scholarly prose that essentially never appears in the verse. Applied to a block AFTER its
# marginal verse numbers are stripped, so the only surviving digits are footnote cross-references.
APPARATUS = re.compile(
    r"\bv\.\s*\d"          # verse cross-ref  "v. 29"
    r"|\bp\.\s*\d|\bpág"   # page cross-ref   "p. 84", "pág."
    r"|\bcomp\.|\bvéase|\bCant\.|\bCrón|\bPrim\.|\bn\.\s*\d|\betc\."  # scholarly abbrevs
    r"|\bnota\b|Refundición|Menéndez|Bertoni|Fuero|Leyenda"
    r"|\bsignifica\b|\badverbio\b|reflexivo|imperativo|\bverbo\b|dialectal"
    r"|subjuntivo|\bpresente\b|\bforma\b|epíteto|traduce|neologismo|paragoge"
    r"|\b1\d{3}\b"         # a bare 4-digit year / cross-ref number (1896, 1232, 842…)
    r"|'[^']{2,40}'"       # single-quoted modern gloss  'quedase plantada'
    r"|\bCid\b",           # clean editorial "Cid" spelling
    re.IGNORECASE,
)


# POSITIVE verse test — medieval orthography a modern footnote block essentially never shows.
# A verse tirada (even a short one) almost always carries at least one of these; Menéndez Pidal's
# modern-Castilian footnote prose does not. This catches footnote *continuation* blocks that carry
# no scholarly cross-reference marker (e.g. "...iba ya haciéndose arcaica cuando se escribió").
MEDIEVAL = re.compile(
    r"£id|Qid|Cjd|CJd"                 # the OCR's garbled poem "Cid"
    r"|ç|ss|·|\""                      # medieval sibilants / geminate / enclitic dot / dialogue "
    # medieval-DISTINCTIVE words (avoid modern function words like e/y/al/el that footnotes share)
    r"|\bmi[óo]\b|\bmyo\b|\bmíos?\b|\bassí\b|\bnon\b|\bnin\b|\bca\b|\bsos\b|\bnol\b|\bnadi\b"
    r"|\bquel\b|\bqui\b|\bý\b|\bpora\b|\bond\b|\bondr|\bfincar|\blidi"
    r"|\bove\b|\bovo\b|\bavi[eéí]|\bfaz|\bfiz|\bdix|\bfabl|\bfer[ií]|\bcavall|\bvassall"
    r"|\byent|\bmoros\b|\bcristian|\bseñor\b|\bnasco\b|\bpendon|\bminaya|\bximena|\bcampeador"
    # medieval verb morphology: -ades/-edes, strong-pret -iesse/-iéremos, -ié/-ién imperfect, -udo
    r"|ades\b|edes\b|iemos\b|iesse|iéssemos|iéremos|ólos\b|áronse\b|i[eé]n\b|i[eé]\b|udo\b",
    re.IGNORECASE,
)


def degarble_num(tok):
    t = tok.translate(_DIGITMAP)
    return int(t) if t.isdigit() else None


def cid_is_apparatus(block):
    """True if the block is a footnote or editorial heading (drop it). A block is verse only when
    it (a) carries no modern-scholarly apparatus marker AND (b) shows medieval orthography; the
    positive (b) test rejects marker-less footnote *continuation* prose. Scored with marginal verse
    numbers stripped, so the verse's own numbering can't masquerade as a cross-reference."""
    stripped = " ".join(strip_lead_num(t)[1] for _, t in block)
    if APPARATUS.search(stripped):
        return True
    return not MEDIEVAL.search(stripped)


def strip_lead_num(line):
    """Remove a leading (possibly OCR-garbled) marginal verse number; return (number|None, text)."""
    m = LEAD_NUM.match(line)
    if not m:
        return None, line.strip()
    n = degarble_num(m.group(1))
    return n, line[m.end():].strip()


# Per-line modern-editorial lexemes that the 12th-c. verse never contains — catches the rare
# footnote line that shares a blank-separated block with a quoted verse fragment (so the block was
# kept) yet is itself modern prose ("…aún vigente en algunos pueblos…", "…decirse abusivamente…").
MODERN_LINE = re.compile(
    r"\bvigente\b|\babusivamente\b|\bsegún\b|\brealmente\b|\bsignifica\b|\bdialectal\b|"
    r"\barcaica?\b|\bescrib[ií]|\bmoderno|\bsinónim|\betimolog|\bortograf",
    re.IGNORECASE,
)


def is_cid_running_header(line):
    """An ALL-CAPS running header ('CANTAR DEL DESTIERRO', 'CANTA?. DE CORPES 357',
    'POEMA DE MIÓ CID') leaks through block filtering because it carries no scholarly marker."""
    s = strip_lead_num(line)[1]
    letters = [c for c in s if c.isalpha()]
    return bool(letters) and all(c.isupper() for c in letters) and len(s) <= 40


def cantar_for(v):
    for end, roman in CID_CANTAR_END:
        if v <= end:
            return roman
    return "III"


def grok_cid():
    lines = read_lines(CID_TXT)
    body = lines[CID_BODY_START - 1:CID_BODY_END]
    verse, out = [], []
    counter = 0
    last_snapped = 0
    for block in blocks(body):
        if cid_is_apparatus(block):
            continue
        for _ln, raw in block:
            if is_cid_running_header(raw) or MODERN_LINE.search(raw):
                continue
            num, text = strip_lead_num(raw)
            if len(text) < 4:
                continue
            counter += 1
            # Re-anchor the running counter to the OCR's own marginal number whenever a plausible,
            # monotonically-increasing one appears within reach. Because OCR line-splits make the
            # counter run AHEAD of the true verse number, allow it to snap DOWN (num <= counter),
            # which keeps Cantar III from drifting; monotonicity guards against a garbled small num.
            if num is not None and last_snapped < num <= 3730 and num <= counter + 4:
                counter = num
                last_snapped = num
            verse.append(text)
            out.append({
                "work": "cid",
                "ref": f"Cantar {cantar_for(counter)}, v. {counter}",
                "cantar": cantar_for(counter),
                "text": text,
            })
    return verse, out


# ---------------------------------------------------------------------------------------------
# Berceo, Milagros de Nuestra Señora  (cuaderna vía: 4-line blank-separated stanzas)
# ---------------------------------------------------------------------------------------------
# Header/running-header lines to drop: ALL-CAPS titles (incl. letter-spaced "E L C L É R I G O"),
# "INTRODUCCIÓN", "ÍNDICE", the milagro-number markers ("2."), and the front cover lines.
BERCEO_DROP = re.compile(
    r"^(LOS MILAGROS|DE NUESTRA SEÑORA|Gonzalo de Berceo|ÍNDICE|INDICE|INTRODUCCIÓN|"
    r"INTRODUCCION)\s*$"
)


def is_berceo_header(line):
    s = line.strip()
    if BERCEO_DROP.match(s):
        return True
    if re.match(r"^\d+\.?\s*$", s):            # standalone milagro number "2."
        return True
    letters = [c for c in s if c.isalpha()]
    if letters and all(c.isupper() for c in letters) and len(s) <= 60:
        return True                            # ALL-CAPS title (spaced or not)
    if s == "(Amén.)":
        return True
    return False


def grok_berceo():
    lines = read_lines(BERCEO_TXT)
    verse, out = [], []
    estrofa = 0
    for block in blocks(lines):
        kept = [t for _, t in block if not is_berceo_header(t)]
        if not kept:
            continue
        # a real stanza is 3–5 verse lines; header-only blocks were emptied above
        if not (2 <= len(kept) <= 6):
            # occasional prose/description block — skip (keeps modern intro prose out)
            if len(kept) == 1 and len(kept[0]) < 40:
                continue
        estrofa += 1
        for text in kept:
            verse.append(text)
            out.append({"work": "berceo", "ref": f"estrofa {estrofa}", "text": text})
    return verse, out


# ---------------------------------------------------------------------------------------------
# Juan Ruiz, Libro de buen amor  (Cejador 1913 ed.: each copla opens "[N] <verse>")
# ---------------------------------------------------------------------------------------------
COPLA_HEAD = re.compile(r"^\s*\[(\d{1,4})\]\s+(.*)$")


def grok_lba():
    lines = read_lines(LBA_TXT)
    verse, out = [], []
    for block in blocks(lines):
        m = COPLA_HEAD.match(block[0][1])
        if not m:
            continue                            # prose, [Nota …] footnote, heading, front matter
        copla = int(m.group(1))
        first = m.group(2).strip()
        stanza = [first] + [t.strip() for _, t in block[1:]]
        for text in stanza:
            if len(text) < 3:
                continue
            verse.append(text)
            out.append({"work": "lba", "ref": f"copla {copla}", "text": text})
    return verse, out


def main():
    os.makedirs(GROKKED, exist_ok=True)
    combined = []
    for slug, fn in (("cantar-de-mio-cid", grok_cid),
                     ("milagros-berceo", grok_berceo),
                     ("libro-de-buen-amor", grok_lba)):
        verse, records = fn()
        with open(os.path.join(GROKKED, f"{slug}.txt"), "w", encoding="utf-8") as fh:
            fh.write("\n".join(verse) + "\n")
        combined.extend(records)
        refs = {r["ref"] for r in records}
        print(f"{slug:20s}: {len(verse):5d} verse lines, {len(refs):5d} distinct refs")

    with open(os.path.join(GROKKED, "medieval_verses.json"), "w", encoding="utf-8") as fh:
        json.dump(combined, fh, ensure_ascii=False, indent=1)
    print(f"\nmedieval_verses.json: {len(combined)} records "
          f"-> {os.path.relpath(os.path.join(GROKKED, 'medieval_verses.json'), CORPUS)}")


if __name__ == "__main__":
    main()
