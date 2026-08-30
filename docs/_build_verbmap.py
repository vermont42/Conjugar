#!/usr/bin/env python3
"""Phase 6 (B/B2) — build the verb→model map bundle resource for Conjugar.

Turns `docs/annex_b_verb_models.md` (4,818 verbs → book model number) into an
attribute-based XML resource the app loads at launch:

    <verb in="abrir"   cl="3-9" tn="open" />
    <verb in="abrazar" cl="1-4" tn="hug" />
    <verb in="apostar" cl="4B"  tn="bet" />   <!-- homonym sense (1) -->
    <verb in="apostar" cl="1"   tn="station" /><!-- homonym sense (2) -->

`in` = bare infinitive, `cl` = book class number, `tn` = terse English gloss.
Optional `rx="1"` marks a reflexive-only verb (Annex B `(se)`); the schema
intentionally leaves room for future optional attributes (`tnr` reflexive gloss,
`dg` defect group) to drop in with zero migration.

Reproducible: re-running reproduces the resource byte-for-byte from the markdown
plus the checked-in gloss sources.

Glosses (B2) are sourced in priority order so existing curation is reused and only
the genuinely-missing ones are authored fresh:
  1. oracle class headers (docs/spanish_models.md, "cantar — *to sing*")
  2. the old app's verbs.xml `tn` attribute (~213 verbs)        [oracle wins ties]
  3. Annex B footnotes, for the homonym senses (special-cased table below)
  4. authored side-table(s) in docs/glosses/*.tsv  (infinitive<TAB>gloss[<TAB>flag])

Verbs with no source gloss are written to docs/glosses_missing.txt (the worklist
the gloss-authoring pass fills); the script fails its 0-glossless check until that
worklist is emptied. Authored glosses flagged low-confidence are collected into
docs/glosses_to_review.md.
"""
import glob
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))                 # <repo>/docs
REPO = os.path.dirname(HERE)                                      # <repo>

ANNEX = os.path.join(HERE, "annex_b_verb_models.md")
ORACLE = os.path.join(HERE, "spanish_models.md")
# The legacy engine's verb list, removed in the migration. load_old_xml_glosses()
# returns {} when it is absent, so this stays a soft dependency -- the 149 glosses
# only it supplied were rescued into docs/glosses/legacy_verbs_xml_glosses.tsv, which
# load_authored_glosses() picks up like any other slice.
OLD_VERBS_XML = os.path.join(REPO, "Conjugar", "Models", "verbs.xml")
GLOSS_DIR = os.path.join(HERE, "glosses")                         # authored slice files
VERB_COUNTS = os.path.join(REPO, "frequency", "verb-counts.json")  # see frequency/README.md

OUT_XML = os.path.join(REPO, "Conjugar", "Models", "verbModelMap.xml")
OUT_MISSING = os.path.join(HERE, "glosses_missing.txt")
OUT_REVIEW = os.path.join(HERE, "glosses_to_review.md")
OUT_DEF = os.path.join(HERE, "def_worklist.md")

ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*([\w-]+)\s*\|\s*(.*?)\s*\|$")
# Strip a marker in parens: (se) reflexive-only, (DEF) defective, (1)/(2) homonym.
MARKER_RE = re.compile(r"\s*\((se|DEF|1|2)\)")

# The 4 homonyms: explicit, footnote-glossed, default-sense-first ordering.
# (book sense (1) is NOT always the everyday sense — aterrar defaults to "terrify",
#  the regular sense (2); see docs/annex_b_verb_models.md footnotes 2-9.)
HOMONYMS = {
    "apostar": [("4B", "bet"), ("1", "station")],
    "asolar":  [("4B", "raze"), ("1", "scorch")],
    "aterrar": [("1", "terrify"), ("4A", "demolish")],
    "atestar": [("4A", "stuff"), ("1", "attest")],
}

# Verbs that ship in the legacy Conjugar app
# (Conjugar/Models/verbs.xml) but are ABSENT from Annex B: neologisms /
# slang that post-date the 2010 book (to google, to go viral, …). Appended after the
# Annex B rows so the map is a strict superset of BOTH the book's 4,818 and the
# shipping app's verb list — no app verb regresses in the migration. Each is
# (infinitive, book class number, terse gloss, reflexive); glosses are terse-ified
# from the legacy `tn`. All four are simple -ar verbs (the old engine parents them to
# hablar = regular class 1; viralizar to cazar = 1-4, z->c so viralicé).
EXTRA_VERBS = [
    ("aguachicolear", "1",   "steal water", False),
    ("googlear",      "1",   "google",      False),
    ("ustedear",      "1",   "use usted",   False),
    ("viralizar",     "1-4", "go viral",    False),
]

# Verbs absent from Annex B, surfaced by the 2026 esTenTen frequency pass as gaps in
# the top-1000 coverage and confirmed by hand. That export is retired (CORPES XXI now
# supplies every verb's count — see frequency/README.md), but these six are real verbs
# and stay. Same (infinitive, class, gloss, reflexive) shape as EXTRA_VERBS; the ranks
# in the comments below are the retired export's, kept as the reason each was added.
# Three are everyday verbs (circular, quejarse, egresar); three are rare — respectar
# and adir are DEFECTIVE (see EXTRA_DEFECTIVE → def_worklist.md), hacendar is merely
# archaic. Full defectivity is NOT enforced yet (a later phase, mirroring Conjuguer);
# for now the engine over-generates the missing forms.
FREQ_GAP_VERBS = [
    ("circular",  "1",  "circulate",          False),  # rank 510, regular -ar
    ("quejar",    "1",  "complain",           True),   # rank 693, reflexive (quejarse)
    ("egresar",   "1",  "graduate",           False),  # rank 842, regular -ar (Lat. Am.)
    ("respectar", "1",  "concern",            False),  # rank 970, DEFECTIVE (por lo que respecta a)
    ("adir",      "3",  "accept inheritance", False),  # rank 985, DEFECTIVE (adir la herencia)
    ("hacendar",  "4A", "give property",      False),  # rank 465, e->ie (model acertar)
]

# Of the frequency-gap verbs, those that are DEFECTIVE in standard usage. Listed in
# def_worklist.md beside the Annex B defectives. Not yet enforced by the engine.
EXTRA_DEFECTIVE = {"respectar", "adir"}

# The other half of the same top-990 coverage pass (commit 1276aa5), but these three
# were inserted in ALPHABETICAL position inside the Annex B block rather than appended,
# so they carry the annex row they follow. (infinitive, class, gloss, reflexive, after).
ANNEX_GAP_VERBS = [
    ("matear",   "1",   "drink mate",     False, "matasellar"),  # -ear, Lat. Am.
    ("rodrigar", "1-2", "stake",          False, "rodear"),      # rank 784, g->gu
    ("salgar",   "1-2", "salt livestock", False, "saldar"),      # rank 994, g->gu
]

# Removed from the shipped map by the G-rating pass (commit 1276aa5) so the App Store
# rating stays 4+: vulgar, sexual, or scatological verbs. Core verbs whose vulgarity is
# only dialectal slang (coger, correr, tirar, chupar, ...) deliberately stay. Filtered at
# emit time rather than deleted from annex_b_verb_models.md, which is a faithful
# transcription of the book and must not be edited for editorial reasons.
G_RATED = {
    "cagar", "copular", "desflorar", "desvirgar", "erotizar", "estuprar", "eyacular",
    "follar", "fornicar", "joder", "manosear", "masturbar", "mear", "prostituir",
    "putear", "toquetear",
}


def load_verb_counts():
    """frequency/verb-counts.json -> {infinitive: (hi, gb, provisional)}.

    Frequency-of-use counts, not ranks: the app derives the dense 1..n rank from
    these once per load, so adding a verb never renumbers the others. `hi` is the
    CORPES XXI lemma count (bare infinitive + its `-se` lemma), `gb` the Google
    Books tie-breaker, `provisional` true when `hi` is an estimate rather than a
    measurement. Built by `frequency/build_counts.py`; see frequency/README.md.

    Display-only, like `tn`: a count can never affect a conjugation.
    """
    with open(VERB_COUNTS, encoding="utf-8") as f:
        rows = json.load(f)
    return {
        inf: (row["hits"], row.get("gbooks"), "estimate" in row)
        for inf, row in rows.items()
    }


# Two Annex B cells are not verbs, and no corpus will ever match them. Both are
# faithful transcriptions -- the 2010 book really does print them this way (verified
# against docs/spanish_verbs_made_simpler.pdf, Annex B) -- so the book's text stays as
# it is in annex_b_verb_models.md and the correction happens here.
SPELLING_FIXES = {
    # The book's notation for the spelling pair sobrentender / sobreentender, not a
    # verb. The DLE lists both spellings; CORPES XXI lemmatizes to sobrentender (253
    # hits), so that is the one the map keys on. The parenthesis also made a
    # URL-unfriendly conjugar://verb/ deeplink key.
    "sobre(e)ntender": "sobrentender",
    # A misspelling. The DLE has only reelegir (CORPES XXI: 1,613 hits). The class is
    # unchanged -- 6B-1, the book's "pedir (elegir)" -- because it conjugates exactly
    # like elegir: reelijo, reeligio, reelegido.
    "reeligir": "reelegir",
}


def strip_markers(verb_cell):
    """'aborregar(se)' -> ('aborregar', rx=True); 'acaecer (DEF)' -> ('acaecer', def=True)."""
    rx = bool(re.search(r"\(se\)", verb_cell))
    defective = bool(re.search(r"\(DEF\)", verb_cell))
    bare = MARKER_RE.sub("", verb_cell).strip()
    return bare, rx, defective


def parse_annex():
    rows = []  # (idx, bare, rx, defective, cls, is_homonym)
    with open(ANNEX, encoding="utf-8") as f:
        for line in f:
            m = ROW_RE.match(line.rstrip("\n"))
            if not m:
                continue
            idx, verb_cell, _subclass, cls, _note = m.groups()
            if verb_cell == "Verb":   # header row
                continue
            bare, rx, defective = strip_markers(verb_cell)
            bare = SPELLING_FIXES.get(bare, bare)
            is_homonym = bool(re.search(r"\([12]\)", verb_cell))
            rows.append((int(idx), bare, rx, defective, cls, is_homonym))
    return rows


def load_oracle_glosses():
    glosses = {}
    hdr = re.compile(r"·\s+([a-záéíóúüñ]+)\b.*?—\s+\*([^*]+)\*")
    with open(ORACLE, encoding="utf-8") as f:
        for line in f:
            if not line.startswith("#"):
                continue
            m = hdr.search(line)
            if m:
                verb, gloss = m.group(1), terse(m.group(2))
                glosses.setdefault(verb, gloss)
    return glosses


def load_old_xml_glosses():
    glosses = {}
    if not os.path.exists(OLD_VERBS_XML):
        return glosses
    with open(OLD_VERBS_XML, encoding="utf-8") as f:
        text = f.read()
    for el in re.findall(r"<verb\b[^>]*>", text):
        mi = re.search(r'\bin="([^"]+)"', el)
        mt = re.search(r'\btn="([^"]+)"', el)
        if mi and mt:
            glosses.setdefault(mi.group(1), mt.group(1).strip())
    return glosses


def load_authored_glosses():
    """Merge docs/glosses/*.tsv : infinitive<TAB>gloss[<TAB>flag]."""
    glosses, flagged = {}, []
    for path in sorted(glob.glob(os.path.join(GLOSS_DIR, "*.tsv"))):
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                if not line or line.startswith("#"):
                    continue
                parts = line.split("\t")
                if len(parts) < 2 or not parts[1].strip():
                    continue
                inf, gloss = parts[0].strip(), parts[1].strip()
                flag = len(parts) >= 3 and parts[2].strip() in ("1", "flag", "review")
                glosses[inf] = gloss
                if flag:
                    flagged.append((inf, gloss))
    return glosses, flagged


def terse(gloss):
    """Trim oracle 'to sing' -> 'sing'; keep 'can'; first sense only."""
    g = gloss.strip()
    if g.lower().startswith("to "):
        g = g[3:]
    return g.split(",")[0].strip()


def xml_escape(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
             .replace('"', "&quot;"))


def main():
    rows = parse_annex()
    oracle = load_oracle_glosses()
    oldxml = load_old_xml_glosses()
    authored, flagged = load_authored_glosses()
    counts = load_verb_counts()

    def gloss_for(key):
        if key in oracle:
            return oracle[key]
        if key in oldxml:
            return oldxml[key]
        if key in authored:
            return authored[key]
        return None

    out_rows = []      # (in, cl, tn, rx)
    missing = []       # (in, rx)  -- non-homonym keys lacking any source gloss
    defectives = []    # (in, cl)
    seen_homonym = set()
    seen_missing = set()

    # The three coverage-gap verbs ride along at their alphabetical anchors, so the
    # emitted order matches the annex block they belong to.
    anchored = {}
    for inf, cls, tn, rx, after in ANNEX_GAP_VERBS:
        anchored.setdefault(after, []).append((inf, cls, tn, rx))

    for idx, bare, rx, defective, cls, is_homonym in rows:
        if bare in G_RATED:
            continue
        if defective:
            defectives.append((bare, cls))
        if is_homonym:
            if bare in seen_homonym:
                continue                      # second sense emitted alongside the first
            seen_homonym.add(bare)
            for hcls, hgloss in HOMONYMS[bare]:
                out_rows.append((bare, hcls, hgloss, rx))
            for row in anchored.pop(bare, ()):
                out_rows.append(row)
            continue
        g = gloss_for(bare)
        if g is None:
            out_rows.append((bare, cls, None, rx))
            if bare not in seen_missing:
                seen_missing.add(bare)
                missing.append((bare, rx))
        else:
            out_rows.append((bare, cls, g, rx))
        for row in anchored.pop(bare, ()):
            out_rows.append(row)

    # Append legacy-app-only verbs (neologisms absent from the 2010 book's Annex B),
    # skipping any that the book turns out to list after all. These carry their own
    # gloss, so they bypass the gloss_for() sources.
    existing = {r[0] for r in out_rows}
    extra_added = 0
    for inf, cls, tn, rx in EXTRA_VERBS:
        if inf not in existing:
            out_rows.append((inf, cls, tn, rx))
            existing.add(inf)
            extra_added += 1

    # Frequency-list gaps (absent from Annex B). Defective ones are recorded in the
    # def worklist; defectivity itself is not yet enforced by the engine.
    freq_added = 0
    for inf, cls, tn, rx in FREQ_GAP_VERBS:
        if inf not in existing:
            out_rows.append((inf, cls, tn, rx))
            existing.add(inf)
            freq_added += 1
            if inf in EXTRA_DEFECTIVE:
                defectives.append((inf, cls))

    if anchored:
        raise SystemExit(f"ANNEX_GAP_VERBS anchors not found in Annex B: {sorted(anchored)}")

    # --- write the worklists ---
    with open(OUT_MISSING, "w", encoding="utf-8") as f:
        for inf, rx in missing:
            f.write(f"{inf}\t{'1' if rx else '0'}\n")

    with open(OUT_DEF, "w", encoding="utf-8") as f:
        f.write("# Defective (DEF) verbs\n\n")
        f.write("From Annex B, plus a few frequency-list additions (respectar, adir) "
                "absent from the book. Mapped to their conjugation model; defectivity "
                "is **not** enforced by the engine (out of scope this phase; reserve "
                "the `dg` hook). Worklist for a future defect-group pass.\n\n")
        for inf, cls in defectives:
            f.write(f"- {inf} ({cls})\n")

    with open(OUT_REVIEW, "w", encoding="utf-8") as f:
        f.write("# Authored glosses flagged for human review (B2)\n\n")
        f.write("Model-authored, low-confidence glosses. Display-only; safe to ship, "
                "but a later human pass should confirm.\n\n")
        for inf, g in flagged:
            f.write(f"- {inf}: {g}\n")

    # The counts table is upstream of the map, so a verb here without a row there is a
    # build error, not a verb that quietly ships unranked.
    uncounted = sorted({r[0] for r in out_rows} - set(counts))
    if uncounted:
        raise SystemExit(
            f"{len(uncounted)} infinitives have no row in {VERB_COUNTS}: {uncounted}\n"
            "Re-run `python3 frequency/build_counts.py` (see frequency/README.md).")

    # --- write the XML resource only if every row is glossed ---
    glossless = [r for r in out_rows if r[2] is None]
    lines = ['<?xml version="1.0" encoding="utf-8"?>',
             "<!-- Generated by docs/_build_verbmap.py from docs/annex_b_verb_models.md.",
             "     Do not edit by hand; re-run the script. in=infinitive cl=book class",
             "     number tn=English gloss rx=reflexive-only.",
             "     Frequency of use, from frequency/verb-counts.json (see frequency/README.md):",
             "     hi=CORPES XXI 1.5 lemma hits, the bare infinitive plus its -se lemma;",
             "     gb=Google Books 1950-2019 verb-form tokens, the tie-breaker; hp=y when hi is",
             "     an estimate rather than a measurement. The app derives the 1..n rank from",
             "     these at parse time, so adding a verb never renumbers the others. -->",
             "<verbs>"]
    for inf, cls, tn, rx in out_rows:
        rxattr = ' rx="1"' if rx else ""
        tnattr = f' tn="{xml_escape(tn)}"' if tn else ' tn=""'
        # Counts belong to the spelling, not the sense, so each homonym row repeats them.
        hits, book_hits, provisional = counts[inf]
        hiattr = f' hi="{hits}"'
        gbattr = f' gb="{book_hits}"' if book_hits is not None else ""
        hpattr = ' hp="y"' if provisional else ""
        lines.append(
            f'  <verb in="{xml_escape(inf)}" cl="{cls}"{tnattr}{rxattr}{hiattr}{gbattr}{hpattr} />')
    lines.append("</verbs>")
    if not glossless:
        with open(OUT_XML, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")

    # --- report ---
    keys = {r[0] for r in out_rows}
    print(f"annex rows parsed     : {len(rows)} (expect 4818)")
    print(f"legacy-app verbs added: {extra_added} (expect {len(EXTRA_VERBS)})")
    print(f"freq-gap verbs added  : {freq_added} (expect {len(FREQ_GAP_VERBS)})")
    print(f"G-rated rows dropped  : {len(G_RATED)} (expect {len(G_RATED)})")
    print(f"annex-gap verbs added : {len(ANNEX_GAP_VERBS)} (expect {len(ANNEX_GAP_VERBS)})")
    print(f"verb elements emitted : {len(out_rows)} (expect 4815 = 4818 annex - {len(G_RATED)} G-rated"
          f" + {len(ANNEX_GAP_VERBS)} annex-gap + {len(EXTRA_VERBS)} legacy + {len(FREQ_GAP_VERBS)} freq-gap)")
    print(f"distinct infinitives  : {len(keys)} (expect 4811 = 4814 annex - {len(G_RATED)} G-rated"
          f" + {len(ANNEX_GAP_VERBS)} annex-gap + {len(EXTRA_VERBS)} legacy + {len(FREQ_GAP_VERBS)} freq-gap)")
    print(f"glossed from oracle    : {sum(1 for r in out_rows if r[0] in oracle)}")
    print(f"glossed from old xml   : {sum(1 for r in out_rows if r[0] not in oracle and r[0] in oldxml)}")
    print(f"glossed from authored  : {len(authored)} loaded")
    print(f"homonym senses         : {len(seen_homonym)*2} ({len(seen_homonym)} verbs)")
    print(f"reflexive-only (rx)    : {sum(1 for r in out_rows if r[3])}")
    print(f"counted (hi)           : {sum(1 for k in keys if k in counts)} of {len(keys)}"
          f"  ({sum(1 for k in keys if counts[k][2])} estimated, hp=\"y\")")
    print(f"defective (DEF) logged : {len(defectives)}")
    print(f"flagged for review     : {len(flagged)}")
    print(f"GLOSSLESS (must be 0)  : {len(glossless)}")
    print(f"-> need authoring      : {len(missing)} infinitives  (docs/glosses_missing.txt)")
    if glossless:
        print(f"XML NOT written (still {len(glossless)} glossless). Fill glosses, re-run.")
    else:
        print(f"wrote {OUT_XML}")


if __name__ == "__main__":
    main()
