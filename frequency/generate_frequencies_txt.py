#!/usr/bin/env python3
"""verbModelMap.xml -> docs/frequencies.txt, the ordered verb list.

The ordering is `VerbMap.ranked(_:)`'s, attribute for attribute, so "verb 400" names the
same verb to a script here as to the app. `VerbMapRankingTests` asserts the two agree line
for line, which is the only thing that keeps this file's collation honest: Python's idea of
Spanish alphabetical order is a hand-rolled imitation of ICU's, and where the two disagree
it is this script that is wrong.

Ranks are over distinct infinitives, so the four doubled entries (apostar, asolar, aterrar,
atestar) occupy one rank each -- the counts belong to the spelling, not to the sense.

Run from the repo root:  python3 frequency/generate_frequencies_txt.py [--check]
"""

import argparse
import os
import re
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERB_MAP = os.path.join(ROOT, "Conjugar", "Models", "verbModelMap.xml")
OUT = os.path.join(ROOT, "docs", "frequencies.txt")

# U+007F sorts above every ASCII letter, so an infinitive's enye becomes `n` + this and
# lands after every n-word; the leading `n` keeps it below every o-word.
AFTER_LETTERS = "\u007f"


def spanish_key(word):
    """Mirrors `compare(_:locale:)` under `Locale(identifier: "es")`.

    CLDR's Spanish collation makes enye a letter of its own, ordered between `n` and `o`
    (`&N < ñ`), so `ñoñear` sorts after `nadar` and before `obrar` rather than among the
    n-words. Accents and the dieresis are secondary differences, so they separate only
    spellings that are otherwise identical.
    """
    folded = word.replace("ñ", "n" + AFTER_LETTERS)
    stripped = "".join(
        character for character in unicodedata.normalize("NFD", folded)
        if not unicodedata.combining(character)
    )
    return (stripped.lower(), word)


def ordered_verbs():
    text = open(VERB_MAP, encoding="utf-8").read()
    verbs = {}
    for tag in re.findall(r"<verb [^>]*/>", text):
        infinitive = re.search(r'\bin="([^"]+)"', tag).group(1)

        def count(name):
            match = re.search(r'\b%s="(-?\d+)"' % name, tag)
            return int(match.group(1)) if match else None

        verbs.setdefault(infinitive, (count("hi"), count("gb"), 'hp="y"' in tag))

    # An absent count sorts below a measured zero, matching the parser's `nil`-below-`0` rule.
    def sort_key(infinitive):
        hits, book_hits, _ = verbs[infinitive]
        return (
            -(hits if hits is not None else -1),
            -(book_hits if book_hits is not None else -1),
            spanish_key(infinitive),
        )

    return sorted(verbs, key=sort_key), verbs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="compare without writing")
    arguments = parser.parse_args()

    ordered, verbs = ordered_verbs()
    provisional = sum(1 for infinitive in ordered if verbs[infinitive][2])
    rendered = "".join(f"{rank} {infinitive}\n" for rank, infinitive in enumerate(ordered, start=1))

    print(f"{len(ordered):,} ranked infinitives; {provisional} rest on an estimated (hp) count.")

    if arguments.check:
        existing = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
        if existing == rendered:
            print(f"{OUT} is up to date.")
            return
        sys.exit(f"{OUT} disagrees with verbModelMap.xml; re-run without --check.")

    open(OUT, "w", encoding="utf-8").write(rendered)
    print(f"Wrote {OUT}.")


if __name__ == "__main__":
    main()
