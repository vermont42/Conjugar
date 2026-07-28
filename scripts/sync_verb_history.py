#!/usr/bin/env python3
"""Push the verb-history essay into Localizable.xcstrings as Info.verbHistoryText.

The essay is ~6,300 words on a single JSON line in the string catalog, which makes it
miserable to edit there and easy to corrupt (an ASCII quote written unescaped breaks the
catalog). docs/verb_history.txt (English) and docs/verb_history_es.txt (Spanish) are the
editable copies; this script validates one against Conjugar's Info markup and writes it
back into the matching localization.

    python3 scripts/sync_verb_history.py                # validate, then write en
    python3 scripts/sync_verb_history.py --check        # validate only, write nothing
    python3 scripts/sync_verb_history.py --lang es      # ditto for the Spanish source

Validation mirrors RichText.swift's parser, which fails silently on bad markup rather
than raising: markers must balance, they must not nest (a `$…$` inside a `~…~` clobbers
the shared markupStart and duplicates the run), and every non-URL `%…%` must name a real
Info article. See the header of docs/verb_history.txt for the same rules in prose.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = {
    "en": ROOT / "docs/verb_history.txt",
    "es": ROOT / "docs/verb_history_es.txt",
}
CATALOG = ROOT / "Conjugar/Supporting/Localizable.xcstrings"
INFO_SWIFT = ROOT / "Conjugar/Models/Info.swift"
KEY = "Info.verbHistoryText"

MARKERS = {"^": "heading", "~": "emphasis", "$": "irregularity", "%": "link"}
SEPARATOR = re.compile(r"^-{20,}$")


def body_of(source: Path) -> str:
    """The article: everything after the dashed separator line in the header."""
    lines = source.read_text(encoding="utf-8").splitlines(keepends=True)
    for i, line in enumerate(lines):
        if SEPARATOR.match(line.rstrip("\n")):
            return "".join(lines[i + 1:]).strip("\n")
    sys.exit(f"{source}: no dashed separator line found; cannot tell header from body.")


def headings(catalog: dict, lang: str) -> set[str]:
    """Every Info article heading, lowercased — the legal targets of a `%…%` link.

    Tense headings are Spanish literals in Info.swift; About headings are localized, so
    they come from the catalog via their L.Info.<name>Heading key, in `lang` where that
    localization exists and in English where it does not (which is what the app falls
    back to as well).
    """
    swift = INFO_SWIFT.read_text(encoding="utf-8")
    found = set(re.findall(r'Info\(heading: "([^"]+)"', swift))
    for name in re.findall(r"Info\(heading: L\.Info\.(\w+)", swift):
        entry = catalog["strings"].get(f"Info.{name}")
        if entry:
            localizations = entry["localizations"]
            unit = localizations.get(lang) or localizations["en"]
            found.add(unit["stringUnit"]["value"])
    return {h.lower() for h in found}


def validate(body: str, legal: set[str]) -> list[str]:
    problems = []

    for marker, name in MARKERS.items():
        if body.count(marker) % 2:
            problems.append(f"unbalanced {name} marker {marker} ({body.count(marker)} occurrences)")

    open_marker = None
    for i, char in enumerate(body):
        if char not in MARKERS:
            continue
        if open_marker is None:
            open_marker = char
        elif open_marker == char:
            open_marker = None
        else:
            context = body[max(0, i - 60):i + 30].replace("\n", " ")
            problems.append(
                f"{MARKERS[open_marker]} contains {MARKERS[char]} (markers cannot nest): …{context}…"
            )
            open_marker = None

    for target in re.findall(r"%([^%]*)%", body):
        if not target.startswith("http") and target.lower() not in legal:
            problems.append(f"link %{target}% matches no Info heading")

    for span in re.findall(r"\$([^$]*)\$", body):
        if span[:1].isupper() and span[1:2].islower():
            problems.append(f"irregularity span ${span}$ starts with a lone capital — "
                            "uppercase means 'irregular, shown red', not 'sentence start'")

    return problems


def localization_blocks(lines: list[str], start: int) -> list[tuple[str, int, int]]:
    """The `(lang, first_line, last_line)` of each localization under KEY, in file order.

    Xcode's formatting is regular enough to walk by indentation: the localizations live
    at eight spaces inside `"localizations" : {`, and each one's closing brace sits at the
    same indent. `last_line` is inclusive and is the `        }` or `        },` line.
    """
    opener = next(i for i in range(start, start + 4)
                  if lines[i] == '      "localizations" : {\n')
    blocks, i = [], opener + 1
    while lines[i] != "      },\n" and lines[i] != "      }\n":
        match = re.match(r'        "([\w-]+)" : \{\n$', lines[i])
        if not match:
            sys.exit(f"{CATALOG}: unexpected line in {KEY} localizations: {lines[i]!r}")
        end = next(j for j in range(i + 1, len(lines))
                   if lines[j] in ("        }\n", "        },\n"))
        blocks.append((match.group(1), i, end))
        i = end + 1
    return blocks


def write(body: str, lang: str) -> bool:
    """Set KEY's `lang` value in place, preserving Xcode's formatting.

    Replaces the value line when that localization already exists, and otherwise splices
    a whole new localization block in alphabetical order, since Xcode sorts them and a
    hand-written `es` block that lands out of order gets churned on the next save. A new
    block is written `"state" : "translated"` so Xcode does not read it as stale and fall
    back to English.
    """
    lines = CATALOG.read_text(encoding="utf-8").splitlines(keepends=True)
    try:
        start = lines.index(f'    "{KEY}" : {{\n')
    except ValueError:
        sys.exit(f"{CATALOG}: key {KEY} not found.")

    blocks = localization_blocks(lines, start)
    value_line = '            "value" : ' + json.dumps(body, ensure_ascii=False) + "\n"
    existing = next((b for b in blocks if b[0] == lang), None)

    if existing:
        _, first, last = existing
        value = next(i for i in range(first, last)
                     if lines[i].startswith('            "value" : '))
        if lines[value] == value_line:
            return False
        lines[value] = value_line
    else:
        after = [b for b in blocks if b[0] < lang]
        block = [
            f'        "{lang}" : {{\n',
            '          "stringUnit" : {\n',
            '            "state" : "translated",\n',
            value_line,
            "          }\n",
            "        }\n",
        ]
        if after:
            # Splice in after the last earlier-sorting localization, which must now
            # carry a comma, while the new block ends the list only if nothing follows.
            insert = after[-1][2] + 1
            lines[after[-1][2]] = "        },\n"
            if insert < blocks[-1][2] + 1:
                block[-1] = "        },\n"
        else:
            insert = blocks[0][1]
            block[-1] = "        },\n"
        lines[insert:insert] = block

    CATALOG.write_text("".join(lines), encoding="utf-8")

    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    unit = catalog["strings"][KEY]["localizations"][lang]["stringUnit"]
    assert unit["value"] == body, "catalog round-trip mismatch after write"
    assert unit["state"] == "translated", f"{lang} localization is not marked translated"
    return True


def language() -> str:
    if "--lang" not in sys.argv:
        return "en"
    lang = sys.argv[sys.argv.index("--lang") + 1]
    if lang not in SOURCES:
        sys.exit(f"unknown language {lang!r}; expected one of {', '.join(SOURCES)}")
    return lang


def main() -> None:
    lang = language()
    source = SOURCES[lang]
    if not source.exists():
        sys.exit(f"{source.relative_to(ROOT)} does not exist.")
    body = body_of(source)
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))

    problems = validate(body, headings(catalog, lang))
    if problems:
        print(f"{len(problems)} problem(s) in {source.relative_to(ROOT)}:", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        sys.exit(1)

    sections = len(re.findall(r"\^([^^]*)\^", body))
    print(f"markup OK ({lang}) — {len(body.split())} words, {sections} sections")

    if "--check" in sys.argv:
        return
    if write(body, lang):
        print(f"wrote {KEY} ({lang}) into {CATALOG.relative_to(ROOT)}")
    else:
        print(f"{CATALOG.relative_to(ROOT)} already up to date ({lang})")


if __name__ == "__main__":
    main()
