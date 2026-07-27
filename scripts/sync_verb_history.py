#!/usr/bin/env python3
"""Push docs/verb_history.txt into Localizable.xcstrings as Info.verbHistoryText (en).

The verb-history essay is ~5,500 words on a single JSON line in the string catalog,
which makes it miserable to edit there and easy to corrupt (an ASCII quote written
unescaped breaks the catalog). docs/verb_history.txt is the editable copy; this script
validates it against Conjugar's Info markup and writes it back.

    python3 scripts/sync_verb_history.py            # validate, then write
    python3 scripts/sync_verb_history.py --check    # validate only, write nothing

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
SOURCE = ROOT / "docs/verb_history.txt"
CATALOG = ROOT / "Conjugar/Supporting/Localizable.xcstrings"
INFO_SWIFT = ROOT / "Conjugar/Models/Info.swift"
KEY = "Info.verbHistoryText"

MARKERS = {"^": "heading", "~": "emphasis", "$": "irregularity", "%": "link"}
SEPARATOR = re.compile(r"^-{20,}$")


def body_of(source: str) -> str:
    """The article: everything after the dashed separator line in the header."""
    lines = source.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if SEPARATOR.match(line.rstrip("\n")):
            return "".join(lines[i + 1:]).strip("\n")
    sys.exit(f"{SOURCE}: no dashed separator line found; cannot tell header from body.")


def headings(catalog: dict) -> set[str]:
    """Every Info article heading, lowercased — the legal targets of a `%…%` link.

    Tense headings are Spanish literals in Info.swift; About headings are localized, so
    they come from the catalog via their L.Info.<name>Heading key.
    """
    swift = INFO_SWIFT.read_text(encoding="utf-8")
    found = set(re.findall(r'Info\(heading: "([^"]+)"', swift))
    for name in re.findall(r"Info\(heading: L\.Info\.(\w+)", swift):
        entry = catalog["strings"].get(f"Info.{name}")
        if entry:
            found.add(entry["localizations"]["en"]["stringUnit"]["value"])
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


def write(body: str) -> bool:
    """Replace the `en` value line of KEY in place, preserving Xcode's formatting."""
    lines = CATALOG.read_text(encoding="utf-8").splitlines(keepends=True)
    try:
        start = lines.index(f'    "{KEY}" : {{\n')
    except ValueError:
        sys.exit(f"{CATALOG}: key {KEY} not found.")

    english = next(i for i in range(start, start + 8) if lines[i].strip() == '"en" : {')
    value = next(i for i in range(english, english + 6) if lines[i].startswith('            "value" : '))

    replacement = '            "value" : ' + json.dumps(body, ensure_ascii=False) + "\n"
    if lines[value] == replacement:
        return False
    lines[value] = replacement
    CATALOG.write_text("".join(lines), encoding="utf-8")

    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    stored = catalog["strings"][KEY]["localizations"]["en"]["stringUnit"]["value"]
    assert stored == body, "catalog round-trip mismatch after write"
    return True


def main() -> None:
    body = body_of(SOURCE.read_text(encoding="utf-8"))
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))

    problems = validate(body, headings(catalog))
    if problems:
        print(f"{len(problems)} problem(s) in {SOURCE.relative_to(ROOT)}:", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        sys.exit(1)

    sections = len(re.findall(r"\^([^^]*)\^", body))
    print(f"markup OK — {len(body.split())} words, {sections} sections")

    if "--check" in sys.argv:
        return
    if write(body):
        print(f"wrote {KEY} (en) into {CATALOG.relative_to(ROOT)}")
    else:
        print(f"{CATALOG.relative_to(ROOT)} already up to date")


if __name__ == "__main__":
    main()
