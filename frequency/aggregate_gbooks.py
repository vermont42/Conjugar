#!/usr/bin/env python3
"""frequency/gbooks/*.tsv + corpus/working/forms_all.json -> gbooks-verb-lemmas.json.

Google Books counts word *forms*, not lemmas, so the tie-breaker has to be summed through
Conjugar's own paradigms. `corpus/working/forms_all.json` (written by
`ConjugarTests/CorpusFormsDumpTests`, gitignored, regenerate it when the verb map changes)
maps each of the 254,328 surface forms the engine can produce to the verbs that produce it.

Two wrinkles the sum has to handle:

* **Only 1950-2019.** The shards reach back to the 1500s, where the OCR and the orthography
  are both unreliable and the register is nothing like a learner's. The modern slice agrees
  with CORPES at rho = 0.945; the all-years slice only manages 0.820.
* **264 forms belong to more than one verb** -- `fui`/`fue` (ser and ir), `era` (ser and
  erar), `nada` (nadar), `casa` (casar) -- and they carry 3.4% of the tokens. Splitting them
  evenly would hand `unir` the mass of *una*/*uno*. Instead the ambiguous mass is split by
  expectation-maximization: start from the unambiguous mass each verb already has, split each
  ambiguous form in proportion to its candidates' current mass, re-total, repeat. Fifteen
  passes is far past convergence for this shape of problem.

The result is a tie-breaker, never a ranking: Google's tagger marks nouns and adjectives
`_VERB` whenever they coincide with a form of a rare verb (`versar` 4.1M against CORPES's
1,337, thanks to *verso*), so used alone it would be badly wrong. Ordering verbs CORPES has
already tied, the contamination can move a verb inside its tie group and no further.

Run from the repo root:  python3 frequency/aggregate_gbooks.py
"""

import collections
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FREQ = os.path.join(ROOT, "frequency")
SHARDS = [os.path.join(FREQ, "gbooks", f"verb_{index}.tsv") for index in range(3)]
FORMS = os.path.join(ROOT, "corpus", "working", "forms_all.json")
OUT = os.path.join(FREQ, "gbooks-verb-lemmas.json")

FIRST_YEAR = 1950
EM_PASSES = 15
SPANISH_WORD = re.compile(r"^[a-záéíóúüñ]+$")


def form_counts(forms):
    """Sum the 1950-2019 tokens of every shard row whose form the engine can produce."""
    counts = collections.Counter()
    rows = kept = 0
    for shard in SHARDS:
        if not os.path.exists(shard):
            sys.exit(f"missing {shard} — run frequency/extract_gbooks_verbs.sh first")
        with open(shard, encoding="utf-8", errors="replace") as handle:
            for line in handle:
                rows += 1
                token, _, rest = line.partition("\t")
                form = token[:-5].lower()          # strip the _VERB tag
                if not SPANISH_WORD.match(form) or form not in forms:
                    continue
                total = 0
                for triple in rest.split("\t"):
                    parts = triple.split(",")
                    if len(parts) == 3 and int(parts[0]) >= FIRST_YEAR:
                        total += int(parts[1])
                if total:
                    counts[form] += total
                    kept += 1
    return counts, rows, kept


def split_ambiguous(counts, forms):
    """EM over the forms with more than one candidate verb. Returns {infinitive: mass}."""
    unambiguous = collections.Counter()
    ambiguous = []
    for form, count in counts.items():
        candidates = forms[form]
        if len(candidates) == 1:
            unambiguous[candidates[0]] += count
        else:
            ambiguous.append((count, candidates))

    mass = unambiguous.copy()
    for _ in range(EM_PASSES):
        share = collections.Counter()
        for count, candidates in ambiguous:
            # +1 keeps a verb whose every form is ambiguous from being frozen at zero.
            total = sum(mass[verb] + 1.0 for verb in candidates)
            for verb in candidates:
                share[verb] += count * (mass[verb] + 1.0) / total
        mass = unambiguous + share
    return mass, len(ambiguous), sum(count for count, _ in ambiguous)


def main():
    forms = json.load(open(FORMS, encoding="utf-8"))
    verbs = sorted({verb for candidates in forms.values() for verb in candidates})

    counts, rows, kept = form_counts(forms)
    mass, ambiguous_forms, ambiguous_tokens = split_ambiguous(counts, forms)

    table = {verb: int(round(mass.get(verb, 0.0))) for verb in verbs}
    counted = sum(1 for value in table.values() if value)
    total = sum(table.values())

    print(f"{rows:,} shard rows; {kept:,} matched a form the engine produces.")
    print(f"{total:,} tokens from {FIRST_YEAR} on, over {len(verbs):,} verbs "
          f"({counted:,} with a nonzero count).")
    print(f"{ambiguous_forms:,} ambiguous forms carried {ambiguous_tokens:,} tokens "
          f"({100 * ambiguous_tokens / max(total, 1):.1f}%), split by {EM_PASSES} EM passes.")
    print("Top 15: " + ", ".join(sorted(table, key=lambda v: -table[v])[:15]))

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(table, handle, ensure_ascii=False, indent=1, sort_keys=True)
        handle.write("\n")
    print(f"Wrote {OUT}.")


if __name__ == "__main__":
    main()
