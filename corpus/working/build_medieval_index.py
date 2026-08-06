#!/usr/bin/env python3
"""Build the MEDIEVAL verb→occurrences index over the grokked verse (Cid, Berceo, LBA).

Unlike the modern index, medieval verse is spelled in 12th–14th-c. Castilian (*ferir, dixo, ovo,
auer*), which never matches the engine's modern conjugation tables directly. So we reduce **both**
sides to a shared canonical key with oldspanish.canon() and match canonical↔canonical, applying
the **reflex-only attachment policy**: a verse line attaches to a modern verb only when the line
genuinely contains that verb's own ancestor word-form (its etymological reflex) — never a synonym.
We use forms_all.json (all 4,811 verbs), because medieval reflexes routinely fall outside the
usage-ranked 988 (these are the "medieval-only special verbs", Conjuguer's Chanson-only analogue).

Inputs
  - corpus/grokked/medieval_verses.json : [ {work, ref, text, cantar?} ] from grok_medieval.py.
  - corpus/working/forms_all.json       : { "<modern surface>": ["<infinitive>", …] } (engine dump).
  - corpus/working/oldspanish.py        : the Old→Modern canonicalizer (canon / variants).

Output
  - corpus/working/medieval_index.json : { "<infinitive>": [ {work, ref, os, token}, … ] }
    keyed by infinitive; `os` is the Old-Spanish verse line, `ref` the citation. Candidates are
    ranked most-distinctively-verbal first and capped per verb; the mining step (pipeline C)
    selects + translates them into MedievalExamples.json (an array per verb — the app taps
    through *all* medieval examples for the verb).
  - a coverage report (verbs covered, ranked vs medieval-only split, per-work balance, top verbs).

Notes
  * Recall-favoring: variants() also tries enclitic-stripped and apocope-restored forms, and a
    token is attached to every verb its canonical key hits (homographs disambiguated downstream).
  * Precision guard: a canonical key shared by more than MAX_AMBIG verbs is over-merged by the
    lossy canonicalizer, so it's dropped rather than attached to a dozen verbs. Ranking then
    prefers longer, less-homographic tokens so the strongest reflex leads.
"""
import json
import os
import re
import unicodedata
from collections import defaultdict

from oldspanish import canon, variants

HERE = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.path.dirname(HERE)
ROOT = os.path.dirname(CORPUS)
FORMS_ALL_JSON = os.path.join(HERE, "forms_all.json")
VERSES_JSON = os.path.join(CORPUS, "grokked", "medieval_verses.json")
FORMS_RANKED_JSON = os.path.join(HERE, "forms.json")   # to tag ranked vs medieval-only
OUT_JSON = os.path.join(HERE, "medieval_index.json")

TOKEN_RE = re.compile(r"[^\W\d_]+", re.UNICODE)
MIN_TOKEN = 3          # skip 1–2 char tokens (function words; noisy canonical collisions)
MAX_AMBIG = 8          # drop a canonical key shared by more than this many verbs (over-merged)
MAX_PER_VERB = 20      # candidates kept per verb (the app taps through all; bound mining cost)
PER_WORK_CAP = 12      # gathered per (verb, work) before ranking, so one work can't crowd out


def build_canon_map(forms_all):
    """canonical key → sorted list of verbs whose modern surface forms reduce to it."""
    cmap = defaultdict(set)
    for surface, verbs in forms_all.items():
        key = canon(surface)
        if len(key) < MIN_TOKEN:
            continue
        for v in verbs:
            cmap[key].add(v)
    # drop over-merged keys (lossy canon collapsed unrelated verbs onto one key)
    return {k: sorted(vs) for k, vs in cmap.items() if len(vs) <= MAX_AMBIG}


def token_verbs(token, canon_map):
    """The verbs whose reflex the corpus token realizes (via itself / apocope / enclitic-strip)."""
    hits = set()
    for variant in variants(token):
        verbs = canon_map.get(canon(variant))
        if verbs:
            hits.update(verbs)
    return hits


def rank_key(occ):
    """Sort key: longer tokens and less-homographic ones are the more distinctive reflexes."""
    return (-len(occ["token"]), occ["_ambig"], occ["work"], occ["ref"])


def main():
    forms_all = json.load(open(FORMS_ALL_JSON, encoding="utf-8"))
    ranked = set()
    if os.path.exists(FORMS_RANKED_JSON):
        ranked = {v for ids in json.load(open(FORMS_RANKED_JSON, encoding="utf-8")).values()
                  for v in ids}
    verses = json.load(open(VERSES_JSON, encoding="utf-8"))
    canon_map = build_canon_map(forms_all)

    # verb → {work: [occurrence]}   (dedup by (verb, work, ref))
    raw = defaultdict(lambda: defaultdict(list))
    seen = defaultdict(set)         # (verb, work) → {ref}
    for rec in verses:
        text = unicodedata.normalize("NFC", rec["text"])
        work, ref = rec["work"], rec["ref"]
        line_hits = {}              # verb → (token, ambiguity) — one occurrence per verse line
        for token in TOKEN_RE.findall(text.lower()):
            if len(token) < MIN_TOKEN:
                continue
            for verb in token_verbs(token, canon_map):
                # keep the longest token that hit this verb on this line
                prev = line_hits.get(verb)
                if prev is None or len(token) > len(prev[0]):
                    line_hits[verb] = (token, len(canon_map.get(canon(token), [1])))
        for verb, (token, ambig) in line_hits.items():
            if ref in seen[(verb, work)] or len(seen[(verb, work)]) >= PER_WORK_CAP:
                continue
            seen[(verb, work)].add(ref)
            raw[verb][work].append(
                {"work": work, "ref": ref, "os": rec["text"], "token": token, "_ambig": ambig}
            )

    index = {}
    for verb, by_work in raw.items():
        occs = [o for work_occs in by_work.values() for o in work_occs]
        occs.sort(key=rank_key)
        trimmed = [{k: o[k] for k in ("work", "ref", "os", "token")} for o in occs[:MAX_PER_VERB]]
        index[verb] = trimmed

    out = {v: index[v] for v in sorted(index)}
    json.dump(out, open(OUT_JSON, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    # ---- report ----
    covered = len(out)
    ranked_covered = sum(1 for v in out if v in ranked)
    medieval_only = sorted(v for v in out if v not in ranked)
    per_work = defaultdict(int)
    for occs in out.values():
        for o in occs:
            per_work[o["work"]] += 1
    print(f"medieval verse records    : {len(verses)}")
    print(f"canonical keys (<= {MAX_AMBIG} verbs): {len(canon_map)}")
    print(f"verbs with >=1 medieval ex : {covered}")
    print(f"  usage-ranked (of 988)    : {ranked_covered}")
    print(f"  medieval-only 'special'  : {len(medieval_only)}  (unranked verbs w/ a medieval reflex)")
    print(f"total occurrences recorded : {sum(len(v) for v in out.values())}")
    print(f"\nJSON written to {os.path.relpath(OUT_JSON, ROOT)}")

    print("\nOccurrences by work:")
    for w in ("cid", "berceo", "lba"):
        print(f"  {per_work.get(w, 0):5d}  {w}")

    counts = sorted(((len(v), k) for k, v in out.items()), reverse=True)
    print("\nTop 15 verbs by medieval-example count:")
    for c, k in counts[:15]:
        print(f"  {c:3d}  {k}")
    print(f"\nSample medieval-only special verbs ({len(medieval_only)}):")
    print("  " + ", ".join(medieval_only[:40]) + (" …" if len(medieval_only) > 40 else ""))


if __name__ == "__main__":
    main()
