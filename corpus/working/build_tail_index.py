#!/usr/bin/env python3
"""Build a candidate index for the UNCOVERED tail (pipeline step D — tail rescue).

`build_corpus_index.py` fills each verb's 5 candidate slots literature-first, in line order. For
verbs whose surface form collides with a common noun/adjective (`cocinar`↔*cocina*, `dudar`↔*duda*,
`sumar`↔*suma*, `curar`↔*cura*, `secar`↔*seco*, `forzar`↔*fuerza*, `viajar`↔*viaje*), literature
drains all five slots with *noun* uses and crowds out the genuine *verbal* uses that exist
elsewhere — so those verbs came back null and the step-C mine dropped them.

This tool targets exactly those uncovered ranked verbs (ranked verbs with no entry in
`corpus/json/ExampleUses.json`) and rebuilds their candidates ranked by how unambiguously each
matched token is a *conjugated form* rather than the same-spelled noun (`verbalness` below), so the
infinitive / gerund / participle / non-present inflections float to the top and the noun-shaped
present forms sink. It scans all three modern tiers (literature → government → technology): the
Conjugar tail set mixes administrative-register collisions (Conjuguer's case) with everyday verbs
(*comer, cocinar, viajar, caminar*) whose verbal uses live in the 19th-c. novels — verbalness
ranking surfaces both. Output: `corpus/working/tail_index.json` + `shards/tail_NNN.json`.

Reuses the tokenizer / Gutenberg gating / snippet helpers from build_corpus_index.py.
"""
import json
import os
import shutil
from collections import defaultdict

from build_corpus_index import (
    MAX_OCCURRENCES, TOKEN_RE, gutenberg_bounds, nfc, ordered_docs, snippet,
)

HERE = os.path.dirname(os.path.abspath(__file__))
FORMS_JSON = os.path.join(HERE, "forms.json")
PLACED_JSON = os.path.join(os.path.dirname(HERE), "json", "ExampleUses.json")
TAIL_JSON = os.path.join(HERE, "tail_index.json")
SHARDS_DIR = os.path.join(HERE, "shards")
SHARD_SIZE = 30
# Gather generously per doc so a rare verbal form is not capped out by the frequent colliding noun.
# The cap is split by verbalness: a noun-shaped (score-0) collision like the article *una* or the
# noun *documento* appears hundreds of times per document and would otherwise fill the whole cap
# before the rare *unido* / *documentando* is ever scanned. Keep verbal forms generously and
# noun-shaped forms barely (just enough that a verb with ONLY noun uses is still visible → dropped).
TAIL_PER_DOC_VERBAL_CAP = 20
TAIL_PER_DOC_NOUN_CAP = 2
# Keep more candidates than the main index so the selector has genuinely-verbal options to choose.
TAIL_MAX = 8


def verbalness(token, verb):
    """Rank a matched token by how unambiguously it is a *conjugated* form rather than the
    same-spelled noun/adjective. The collision is almost always a present-tense form equal to the
    noun stem (*cocina*, *suma*, *duda*, *fuerza*); the infinitive, gerund, participle and the
    non-present inflections (imperfect/preterite/future/conditional/subjunctive) are unmistakable."""
    if token == verb:                                   # infinitive: cocinar, viajar, comer
        return 3
    if token.endswith(("ando", "iendo", "yendo")):      # gerund, any conjugation: cocinando
        return 3
    if token.endswith(("ándo", "iéndo")) or "ándo" in token or "iéndo" in token:
        return 3                                        # gerund + enclitic: mirándolo, haciéndose
    stem = verb[:-2] if len(verb) > 2 else verb
    if verb.endswith("ar"):
        # Present-ish forms that also spell a noun/adjective — the collision we are demoting.
        noun_like = {stem, stem + "a", stem + "as", stem + "o", stem + "os",
                     stem + "e", stem + "es", stem + "an", stem + "en"}
        if token in noun_like:
            return 0
        if token.endswith(("ado", "ada", "ados", "adas")):   # participle (can read adjectival)
            return 2
        return 1                                        # imperfect/preterite/future/cond/subj: clearly verbal
    else:  # -er / -ir
        noun_like = {stem, stem + "o", stem + "a", stem + "e", stem + "es",
                     stem + "os", stem + "as", stem + "en", stem + "an"}
        if token in noun_like:
            return 0
        if token.endswith(("ido", "ida", "idos", "idas")):   # participle
            return 2
        return 1


def rank_candidates(occ, verb):
    """Put the most distinctively verbal occurrence first (stable sort preserves tier/doc/line
    order within a verbalness tier), dedup by (doc, line), keep the first TAIL_MAX."""
    occ = sorted(occ, key=lambda o: -verbalness(o["token"], verb))
    seen, chosen = set(), []
    for o in occ:
        key = (o["doc"], o["line"])
        if key in seen:
            continue
        seen.add(key)
        chosen.append(o)
        if len(chosen) >= TAIL_MAX:
            break
    return chosen


def main():
    forms = json.load(open(FORMS_JSON, encoding="utf-8"))
    with open(PLACED_JSON, encoding="utf-8") as handle:
        placed = set(json.load(handle))
    ranked = sorted({v for ids in forms.values() for v in ids})
    uncovered = set(v for v in ranked if v not in placed)

    raw = defaultdict(list)                 # verb → [occurrence]
    per_doc_seen = defaultdict(set)         # (verb, doc) → {line}
    per_doc_verbal = defaultdict(int)       # (verb, doc) → count of score>0 kept
    per_doc_noun = defaultdict(int)         # (verb, doc) → count of score-0 kept

    for _tier, _work, rel, abspath in ordered_docs():
        lo, hi = gutenberg_bounds(abspath)
        with open(abspath, encoding="utf-8", errors="replace") as handle:
            for lineno, raw_line in enumerate(handle, start=1):
                if lineno <= lo or lineno >= hi:
                    continue
                line = nfc(raw_line.rstrip("\n"))
                hits = {}
                for token in TOKEN_RE.findall(line.lower()):
                    if len(token) < 2:
                        continue
                    for verb in forms.get(token, ()):
                        if verb in uncovered:
                            # Prefer the most-verbal token if a line has several hits for one verb.
                            prev = hits.get(verb)
                            if prev is None or verbalness(token, verb) > verbalness(prev, verb):
                                hits[verb] = token
                for verb, token in hits.items():
                    key = (verb, rel)
                    if lineno in per_doc_seen[key]:
                        continue
                    if verbalness(token, verb) > 0:
                        if per_doc_verbal[key] >= TAIL_PER_DOC_VERBAL_CAP:
                            continue
                        per_doc_verbal[key] += 1
                    else:
                        if per_doc_noun[key] >= TAIL_PER_DOC_NOUN_CAP:
                            continue
                        per_doc_noun[key] += 1
                    per_doc_seen[key].add(lineno)
                    raw[verb].append(
                        {"doc": rel, "line": lineno, "token": token, "text": snippet(line, token)}
                    )

    tail = {v: rank_candidates(raw[v], v) for v in sorted(raw) if raw[v]}
    # Drop verbs whose only candidates are the score-0 noun collision (nothing to rescue).
    tail = {v: occs for v, occs in tail.items()
            if any(verbalness(o["token"], v) > 0 for o in occs)}
    json.dump(tail, open(TAIL_JSON, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    # Shard for the mining subagents (same layout build_examples.py emits: shards/tail_NNN.json).
    verbs = list(tail)
    for name in os.listdir(SHARDS_DIR) if os.path.isdir(SHARDS_DIR) else []:
        if name.startswith("tail_"):
            os.remove(os.path.join(SHARDS_DIR, name))
    os.makedirs(SHARDS_DIR, exist_ok=True)
    shard_count = 0
    for shard_count, start in enumerate(range(0, len(verbs), SHARD_SIZE)):
        chunk = {v: tail[v] for v in verbs[start:start + SHARD_SIZE]}
        path = os.path.join(SHARDS_DIR, f"tail_{shard_count:03d}.json")
        json.dump(chunk, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    total_shards = shard_count + 1 if verbs else 0

    still_absent = sorted(uncovered - set(tail))
    print(f"uncovered ranked verbs      : {len(uncovered)}")
    print(f"  with verbal candidates    : {len(tail)}  (-> {total_shards} shards to re-mine)")
    print(f"  still absent (authored)   : {len(still_absent)}")
    print(f"\ntail_index.json + {total_shards} shards written under corpus/working/")
    if still_absent:
        print(f"\nstill absent (-> step D authored residue):\n  " + ", ".join(still_absent))


if __name__ == "__main__":
    main()
