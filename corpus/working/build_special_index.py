#!/usr/bin/env python3
"""Build a modern-corpus verb→occurrences index for the STEP-F "special" verbs — the
medieval-example verbs that fall OUTSIDE the usage-ranked 988 (pipeline step F).

This is the step-F analogue of build_corpus_index.py. The difference: the ranked index keys
off forms.json (988 verbs); step F's verbs are unranked, so they only appear in forms_all.json
(all 4,811 verbs). We therefore tokenize the same modern corpus but restrict the recorded
verbs to the step-F set (prompts/example-uses-stepF-verbs.json). The medieval examples for
these verbs already exist (MedievalExamples.json); step F adds a MODERN example (this index
feeds the mining) + an etymology (separate etymology pipeline).

Inputs
  - corpus/working/forms_all.json : { "<surface form>": ["<infinitive>", …] } over all 4,811 verbs.
  - prompts/example-uses-stepF-verbs.json : the 352 special verbs (infinitive + gloss).
  - corpus/originals/{literature,government,technology}/*.txt : cleaned source texts.

Output
  - corpus/working/special_index.json : { "<infinitive>": [ {doc, line, token, text}, … ] }
  - a coverage report (per-work balance, zero-coverage tail → Claude-authored residue).

Mirrors build_corpus_index.py's design (one tokenizing pass, round-robin author balance with a
per-verb rotating lead work, per-doc cap, homograph recording). Only the verb universe differs.
"""
import json
import os
import re
import unicodedata
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.path.dirname(HERE)
ROOT = os.path.dirname(CORPUS)
FORMS_JSON = os.path.join(HERE, "forms_all.json")
WORKLIST = os.path.join(ROOT, "prompts", "example-uses-stepF-verbs.json")
OUT_JSON = os.path.join(HERE, "special_index.json")
ORIGINALS = os.path.join(CORPUS, "originals")

MAX_OCCURRENCES = 5
PER_DOC_CAP = 4
SNIPPET_WIDTH = 200

TIERS = ("literature", "government", "technology")

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

TOKEN_RE = re.compile(r"[^\W\d_]+", re.UNICODE)
GUTENBERG_START = re.compile(r"\*\*\* ?START OF THE PROJECT GUTENBERG EBOOK")
GUTENBERG_END = re.compile(r"\*\*\* ?END OF THE PROJECT GUTENBERG EBOOK|End of (the )?Project Gutenberg")


def nfc(text):
    return unicodedata.normalize("NFC", text)


def stem(name):
    return name[:-4] if name.endswith(".txt") else name


def gutenberg_bounds(abspath):
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


def bucket_of(rel):
    name = os.path.basename(rel)
    if os.sep + "literature" + os.sep in rel:
        return stem(name)
    if os.sep + "technology" + os.sep in rel:
        return "technology"
    return "government"


def main():
    with open(FORMS_JSON, encoding="utf-8") as handle:
        forms = json.load(handle)
    with open(WORKLIST, encoding="utf-8") as handle:
        special = [v["infinitive"] for v in json.load(handle)["verbs"]]
    target = set(special)

    raw = defaultdict(lambda: defaultdict(list))
    per_doc_seen = defaultdict(set)

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
                        if verb in target:
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
    for rank, verb in enumerate(special):
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

    total = len(special)
    covered = len(out)
    zero = [v for v in special if v not in index]

    lead = defaultdict(int)
    for occs in out.values():
        lead[bucket_of(occs[0]["doc"])] += 1

    print(f"step-F special verbs      : {total}")
    print(f"verbs with >=1 example    : {covered}  ({100 * covered / total:.1f}%)")
    print(f"total occurrences recorded: {sum(len(v) for v in out.values())}")
    print(f"zero-coverage verbs       : {len(zero)}  (-> Claude-authored residue)")
    print(f"\nJSON written to {os.path.relpath(OUT_JSON, ROOT)}")

    buckets = LIT_WORKS + ["government", "technology"]
    print("\nLEAD candidate by work (should be an even mix):")
    for b in buckets:
        print(f"  {lead.get(b, 0):4d}  {b}")

    if zero:
        shown = ", ".join(zero)
        print(f"\nZero-coverage verbs ({len(zero)}):\n  {shown}")


if __name__ == "__main__":
    main()
