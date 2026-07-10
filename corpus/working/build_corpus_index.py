#!/usr/bin/env python3
"""Build an inverted verb→occurrences index over the MODERN example corpus (literature +
government + technology tiers). Port of Conjuguer's build_corpus_index.py, adapted for Conjugar.

This is the cheap, deterministic *retrieval* half of the example-mining pipeline: it locates
candidate sentences for the 988 usage-ranked Spanish verbs so that LLM subagents (pipeline step
C) only do the expensive *selection + translation* on a handful of pre-found lines, instead of
reading whole novels.

Inputs
  - corpus/working/forms.json : { "<surface form>": ["<infinitive>", …] } from the
    `CorpusFormsDumpTests` Swift tool driving the app's own engine. Exact whole-token matching
    against this map handles irregular stems and avoids substring false positives. (52,166 forms
    → 988 ranked verbs; verbs are bare infinitives.)
  - corpus/originals/{literature,government,technology}/*.txt : the source texts (cleaned by
    clean_corpus.py — Gutenberg boilerplate already removed).

Output
  - corpus/working/corpus_index.json : { "<infinitive>": [ {doc, line, token, text}, … ] }
  - a coverage report to stdout (per-tier split, per-work balance, zero-coverage tail).

Design points (mirrors the Conjuguer flow; see prompts/example-uses-pipeline.md §B)
  * ONE tokenizing pass over each document, not 988 passes.
  * Candidates are gathered from each of the 8 LITERATURE works independently, then merged
    round-robin with a per-verb ROTATING LEAD WORK, so the first candidate (the one selectors
    reach for) is spread evenly across Galdós / Clarín / Pardo Bazán / … instead of always
    draining from whichever file is scanned first. Government then technology append as fallback.
  * Up to MAX_OCCURRENCES distinct lines per verb; the LLM step is where work is actually capped.
  * A token mapping to several verbs (homographs) is recorded under each; context disambiguates.

The medieval tier is built separately by build_medieval_index.py (Old-Spanish spelling needs the
oldspanish.py canonicalizer + forms_all.json, and a reflex-only attachment policy).
"""
import json
import os
import re
import unicodedata
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.path.dirname(HERE)
ROOT = os.path.dirname(CORPUS)
FORMS_JSON = os.path.join(HERE, "forms.json")
OUT_JSON = os.path.join(HERE, "corpus_index.json")
ORIGINALS = os.path.join(CORPUS, "originals")

# Final distinct lines kept per verb, and the per-document ceiling gathered before balancing.
MAX_OCCURRENCES = 5
PER_DOC_CAP = 4
# Stored context width (chars) centered on the matched token.
SNIPPET_WIDTH = 200

# Tier priority for the ranked modern index: literature → government → technology.
TIERS = ("literature", "government", "technology")

# The 8 literature works are the balancing buckets (each is a distinct "work"; two are Galdós,
# but we still spread the lead candidate across all eight files). Discovered from the folder at
# runtime, but pinned here as the canonical rotation order for reproducibility.
LIT_WORKS = [
    "fortunata-y-jacinta-galdos-1887",
    "la-barraca-blasco-ibanez-1898",
    "la-regenta-clarin-1885",
    "marianela-galdos-1878",
    "pazos-de-ulloa-pardo-bazan-1886",
    "pepita-jimenez-valera-1874",
    "quijote-cervantes-1605",
    "sombrero-tres-picos-alarcon-1874",
]

# Unicode-aware word tokens: runs of letters only, so apostrophes/hyphens/digits separate.
# Accented letters are letters. "qu'el" → ["qu", "el"], "río-Jalón" → ["río", "jalón"].
TOKEN_RE = re.compile(r"[^\W\d_]+", re.UNICODE)

# Safety net: if a source still carried Project Gutenberg markers we'd index only the body
# between them (clean_corpus.py already strips these, so bounds are normally (0, inf)).
GUTENBERG_START = re.compile(r"\*\*\* ?START OF THE PROJECT GUTENBERG EBOOK")
GUTENBERG_END = re.compile(r"\*\*\* ?END OF THE PROJECT GUTENBERG EBOOK|End of (the )?Project Gutenberg")


def nfc(text):
    return unicodedata.normalize("NFC", text)


def stem(name):
    """Filename → work slug (drop .txt)."""
    return name[:-4] if name.endswith(".txt") else name


def gutenberg_bounds(abspath):
    """(lo, hi) physical line bounds of real body text; (0, inf) when no markers are present."""
    lo, hi = 0, float("inf")
    with open(abspath, encoding="utf-8", errors="replace") as handle:
        for n, line in enumerate(handle, start=1):
            if GUTENBERG_START.search(line):
                lo = n
            elif GUTENBERG_END.search(line):
                hi = n
                break
    return lo, hi


def ordered_docs():
    """(tier, work, relpath, abspath) for every source .txt, in tier priority order. `work` is the
    file slug for literature and the tier name for government/technology (used for balancing)."""
    docs = []
    for tier in TIERS:
        tier_dir = os.path.join(ORIGINALS, tier)
        if not os.path.isdir(tier_dir):
            continue
        for name in sorted(os.listdir(tier_dir)):
            if not name.endswith(".txt"):
                continue
            work = stem(name) if tier == "literature" else tier
            rel = os.path.join("corpus", "originals", tier, name)
            docs.append((tier, work, rel, os.path.join(tier_dir, name)))
    return docs


def snippet(line, token):
    low = line.lower()
    i = low.find(token)
    if i < 0:
        return line.strip()[:SNIPPET_WIDTH]
    half = SNIPPET_WIDTH // 2
    start, end = max(0, i - half), min(len(line), i + len(token) + half)
    frag = line[start:end].strip()
    return ("…" if start > 0 else "") + frag + ("…" if end < len(line) else "")


def merge_balanced(by_work, gov, tech, rank):
    """Round-robin the per-work literature candidate lists, leading with a verb-specific rotated
    work, then top up from government, then technology. `by_work` maps work slug → [occurrence]."""
    rotation = rank % len(LIT_WORKS)
    order = LIT_WORKS[rotation:] + LIT_WORKS[:rotation]
    queues = [list(by_work.get(work, [])) for work in order]
    out = []
    pos = 0
    while len(out) < MAX_OCCURRENCES and any(queues):
        queue = queues[pos % len(order)]
        if queue:
            out.append(queue.pop(0))
        pos += 1
    for fallback in (gov, tech):
        if len(out) < MAX_OCCURRENCES:
            out.extend(fallback[: MAX_OCCURRENCES - len(out)])
    return out


def main():
    with open(FORMS_JSON, encoding="utf-8") as handle:
        forms = json.load(handle)
    all_verbs = sorted({v for ids in forms.values() for v in ids})

    # verb → {work: [occurrence]} preserving scan order (government/technology keyed by tier name).
    raw = defaultdict(lambda: defaultdict(list))
    per_doc_seen = defaultdict(set)  # (verb, doc) → {line} for distinct-line dedup + per-doc cap

    for _tier, work, rel, abspath in ordered_docs():
        lo, hi = gutenberg_bounds(abspath)
        with open(abspath, encoding="utf-8", errors="replace") as handle:
            for lineno, raw_line in enumerate(handle, start=1):
                if lineno <= lo or lineno >= hi:
                    continue
                line = nfc(raw_line.rstrip("\n"))
                low = line.lower()
                hits = {}
                for token in TOKEN_RE.findall(low):
                    if len(token) < 2:
                        continue
                    for verb in forms.get(token, ()):
                        hits.setdefault(verb, token)
                for verb, token in hits.items():
                    seen = per_doc_seen[(verb, rel)]
                    if lineno in seen or len(seen) >= PER_DOC_CAP:
                        continue
                    seen.add(lineno)
                    raw[verb][work].append({
                        "doc": rel,
                        "line": lineno,
                        "token": token,
                        "text": snippet(line, token),
                    })

    index = {}
    for rank, verb in enumerate(all_verbs):
        by_work = raw.get(verb, {})
        if not by_work:
            continue
        lit = {w: occs for w, occs in by_work.items() if w in LIT_WORKS}
        gov = by_work.get("government", [])
        tech = by_work.get("technology", [])
        merged = merge_balanced(lit, gov, tech, rank)
        if merged:
            index[verb] = merged

    out = {verb: index[verb] for verb in sorted(index)}
    with open(OUT_JSON, "w", encoding="utf-8") as handle:
        json.dump(out, handle, ensure_ascii=False, indent=1)

    # ---- coverage + balance report ----
    total = len(all_verbs)
    covered = len(out)
    zero = [v for v in all_verbs if v not in index]

    lead = defaultdict(int)
    cand_by_bucket = defaultdict(int)
    for occs in out.values():
        lead[bucket_of(occs[0]["doc"])] += 1
        for o in occs:
            cand_by_bucket[bucket_of(o["doc"])] += 1

    print(f"forms.json forms          : {len(forms)}")
    print(f"usage-ranked verbs        : {total}")
    print(f"verbs with >=1 example    : {covered}  ({100 * covered / total:.1f}%)")
    print(f"total occurrences recorded: {sum(len(v) for v in out.values())}")
    print(f"zero-coverage verbs       : {len(zero)}  (-> tail rescue / authored residue)")
    print(f"\nJSON written to {os.path.relpath(OUT_JSON, ROOT)}")

    buckets = LIT_WORKS + ["government", "technology"]
    print("\nLEAD candidate (what selectors reach for first) by work — should be an even mix:")
    for b in buckets:
        print(f"  {lead.get(b, 0):4d}  {b}")
    print("\nAll candidates by work:")
    for b in buckets:
        print(f"  {cand_by_bucket.get(b, 0):4d}  {b}")

    if zero:
        shown = ", ".join(zero[:40])
        print(f"\nZero-coverage verbs ({len(zero)}):\n  {shown}" + (" …" if len(zero) > 40 else ""))


def bucket_of(rel):
    name = os.path.basename(rel)
    if os.sep + "literature" + os.sep in rel:
        return stem(name)
    if os.sep + "technology" + os.sep in rel:
        return "technology"
    return "government"


if __name__ == "__main__":
    main()
