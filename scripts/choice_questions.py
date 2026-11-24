#!/usr/bin/env python3
"""Review and approve the quiz's choice questions, in which the learner picks the tense a speaker
would use.

Consumes: Conjugar/Models/ChoiceQuestions.json, a JSON array in which each item carries id, verb,
  person (a DisplayPersonNumber raw value; ss is shown in tu or vos as the learner's setting
  chooses), level (the QuizLevel from which it is asked), region (spain or latinAmerica, only for
  an item whose answer is one region's usage), reason (a ChoiceReason raw value), right and other
  (each a tense, a DisplayTense case name, and es, the Spanish with the form in braces), en
  (American English), and reviewed. It also reads the reasons' English lines from
  Conjugar/Supporting/Localizable.xcstrings, so the sheet shows what the card shows.

Produces, by subcommand:
  review [--all] [--out PATH]
      A Markdown sheet of the drafts (or, with --all, every item), grouped by level, with each
      form in bold, the right sentence first, and the reason the card shows after the choice.
      Prints to stdout unless --out is given.
  approve ID [ID ...] | approve --all [--except ID ...]
      Marks items reviewed. The app's release build asks only reviewed items; a debug build asks
      drafts too and marks them "Draft" on the card.
  status
      Counts of reviewed and draft items, by level and by reason.

Run from the repo root:  python3 scripts/choice_questions.py review --out plans/choice_questions_batch_1.md

Why it rewrites the whole file: ChoiceQuestions.json is written by json.dumps(indent=2,
ensure_ascii=False) and nothing else, so a load-and-dump round trip reproduces it byte for byte
apart from the changed flags. Never point this script at Localizable.xcstrings, which uses " : "
separators.

The machine check lives in ConjugarTests/Models/ChoiceQuestionTests.swift, which conjugates both
sentences of every item with the app's own engine, in tu and in vos. Run it after any edit:
  "$IBV_SCRIPTS/run_tests.sh" --only-testing ConjugarTests/ChoiceQuestionTests
"""

import argparse
import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PATH = ROOT / "Conjugar" / "Models" / "ChoiceQuestions.json"
CATALOG = ROOT / "Conjugar" / "Supporting" / "Localizable.xcstrings"
LEVELS = ["beginner", "elementary", "intermediate", "advanced"]
REGIONS = {"spain": "Spain only", "latinAmerica": "Latin America only"}
PERSONS = {"fs": "yo", "ss": "tú or vos", "ts": "él, ella, usted", "fp": "nosotros", "tp": "ellos, ellas, ustedes"}

# The tenses' names as the card shows them. Either imperfect subjunctive is named without its number.
TENSE_NAMES = {
    "presenteDeIndicativo": "presente de indicativo",
    "pretérito": "pretérito",
    "imperfectoDeIndicativo": "imperfecto de indicativo",
    "futuroDeIndicativo": "futuro de indicativo",
    "condicional": "condicional",
    "presenteDeSubjuntivo": "presente de subjuntivo",
    "imperfectoDeSubjuntivo1": "imperfecto de subjuntivo",
    "imperativoPositivo": "imperativo positivo",
    "imperativoNegativo": "imperativo negativo",
    "perfectoDeIndicativo": "perfecto de indicativo",
    "pluscuamperfectoDeIndicativo": "pluscuamperfecto de indicativo",
    "futuroPerfecto": "futuro perfecto",
    "condicionalCompuesto": "condicional compuesto",
    "perfectoDeSubjuntivo": "perfecto de subjuntivo",
    "pluscuamperfectoDeSubjuntivo1": "pluscuamperfecto de subjuntivo",
}


def load():
    return json.loads(PATH.read_text())


def save(items):
    PATH.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n")


def reason_lines():
    """Each reason's English line, keyed by its raw value, from the catalog's Choice.reason… keys."""
    strings = json.loads(CATALOG.read_text())["strings"]
    lines = {}
    for key, entry in strings.items():
        match = re.fullmatch(r"Choice\.reason(\w+)( %@)+", key)
        if match:
            raw = re.sub(r"(?<!^)([A-Z])", r"_\1", match.group(1)).lower()
            lines[raw] = entry["localizations"]["en"]["stringUnit"]["value"]
    return lines


def reason_line(item, lines):
    line = lines.get(item["reason"], item["reason"])
    right = TENSE_NAMES.get(item["right"]["tense"], item["right"]["tense"])
    other = TENSE_NAMES.get(item["other"]["tense"], item["other"]["tense"])
    return line.replace("%1$@", right).replace("%2$@", other).replace("%@", right)


def bold(spanish):
    return re.sub(r"\{([^}]*)\}", r"**\1**", spanish)


def review(items, include_all, out):
    shown = [i for i in items if include_all or not i["reviewed"]]
    lines_by_reason = reason_lines()
    title = "Choice questions" if include_all else "Choice questions: items to review"
    lines = [f"# {title} ({len(shown)})", ""]
    lines.append("Each item is the same sentence in two tenses. The learner picks the one a speaker would")
    lines.append("use, then sees the English and the reason. Both forms have passed the machine check,")
    lines.append("which confirms them against the engine in tú and in vos. What it cannot judge is the")
    lines.append("rest: whether the right sentence is what a speaker would say, whether the other is plainly")
    lines.append("worse in that context, whether the reason is true of the item, and whether the English")
    lines.append("says the same thing. A tú item is shown in vos to a learner whose setting is vos, so it")
    lines.append("names no tú, ti, or contigo. A region item is asked only in its region.")
    for level in LEVELS:
        group = [i for i in shown if i["level"] == level]
        if not group:
            continue
        lines += ["", f"## {level.capitalize()} ({len(group)})", ""]
        for item in group:
            mark = "" if item["reviewed"] else " (draft)"
            region = f", {REGIONS[item['region']]}" if item.get("region") else ""
            person = PERSONS.get(item["person"], item["person"])
            lines.append(f"- `{item['id']}`{mark}, {person}{region}  ")
            lines.append(f"  Right ({TENSE_NAMES.get(item['right']['tense'], item['right']['tense'])}): {bold(item['right']['es'])}  ")
            lines.append(f"  Other ({TENSE_NAMES.get(item['other']['tense'], item['other']['tense'])}): {bold(item['other']['es'])}  ")
            lines.append(f"  {item['en']}  ")
            lines.append(f"  *{reason_line(item, lines_by_reason)}*")
    text = "\n".join(lines) + "\n"
    if out:
        pathlib.Path(out).write_text(text)
        print(f"wrote {len(shown)} items to {out}")
    else:
        sys.stdout.write(text)


def approve(items, ids, approve_all, excepted):
    known = {i["id"] for i in items}
    unknown = [i for i in ids + excepted if i not in known]
    if unknown:
        sys.exit(f"unknown ids: {', '.join(unknown)}")
    chosen = known - set(excepted) if approve_all else set(ids)
    changed = 0
    for item in items:
        if item["id"] in chosen and not item["reviewed"]:
            item["reviewed"] = True
            changed += 1
    save(items)
    print(f"approved {changed}; {sum(not i['reviewed'] for i in items)} drafts remain")


def status(items):
    reviewed = sum(i["reviewed"] for i in items)
    print(f"{len(items)} items: {reviewed} reviewed, {len(items) - reviewed} drafts")
    levels = collections.Counter(i["level"] for i in items)
    print("by level: " + ", ".join(f"{level} {levels[level]}" for level in LEVELS if levels[level]))
    reasons = collections.Counter(i["reason"] for i in items)
    print("by reason: " + ", ".join(f"{reason} {count}" for reason, count in sorted(reasons.items())))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    r = sub.add_parser("review")
    r.add_argument("--all", action="store_true")
    r.add_argument("--out")
    a = sub.add_parser("approve")
    a.add_argument("ids", nargs="*")
    a.add_argument("--all", action="store_true")
    a.add_argument("--except", dest="excepted", nargs="*", default=[])
    sub.add_parser("status")
    args = parser.parse_args()
    items = load()
    if args.command == "review":
        review(items, args.all, args.out)
    elif args.command == "approve":
        if not args.all and not args.ids:
            sys.exit("name ids to approve, or pass --all")
        approve(items, args.ids, args.all, args.excepted)
    else:
        status(items)


if __name__ == "__main__":
    main()
