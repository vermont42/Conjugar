#!/usr/bin/env python3
"""Review and approve Complete the Sentence's authored sentences.

Consumes: Conjugar/Models/GapSentences.json, a JSON array in which each sentence carries id, verb,
  tense (a DisplayTense case name), person (a DisplayPersonNumber raw value, absent for the
  gerundio; ss is asked in tu or vos as the learner's setting chooses), es (the Spanish with the
  words of the answer in braces), en (American English), and reviewed.

Produces, by subcommand:
  review [--all] [--out PATH]
      A Markdown sheet of the drafts (or, with --all, every sentence), grouped by verb, with the
      blank filled in bold, for the reviewer to read. Prints to stdout unless --out is given.
  approve ID [ID ...] | approve --all [--except ID ...]
      Marks sentences reviewed. The app's release build asks only reviewed sentences; a debug
      build asks drafts too and marks them "Draft" on the card (GapSentences.includesDrafts).
  status
      Counts of reviewed and draft sentences, and the verbs covered.

Run from the repo root:  python3 scripts/gap_sentences.py review --out plans/gap_sentences_batch_1.md

Why it rewrites the whole file: GapSentences.json is written by json.dumps(indent=2,
ensure_ascii=False) and nothing else, so a load-and-dump round trip reproduces it byte for byte
apart from the changed flags. Localizable.xcstrings uses " : " separators instead; this script's
dump would reformat it, so never point it there.

The machine check lives in ConjugarTests/Models/GapSentenceTests.swift, which conjugates each
sentence's cell with the app's own engine, in tu and in vos. Run it after any edit to the file:
  "$IBV_SCRIPTS/run_tests.sh" --only-testing ConjugarTests/GapSentenceTests
"""

import argparse
import json
import pathlib
import re
import sys

PATH = pathlib.Path(__file__).resolve().parent.parent / "Conjugar" / "Models" / "GapSentences.json"

# Spanish names for the sheet, as the quiz card shows them. A sentence takes either imperfect
# subjunctive, so the card names neither's number.
TENSE_NAMES = {
    "presenteDeIndicativo": "presente de indicativo",
    "pretérito": "pretérito",
    "imperfectoDeIndicativo": "imperfecto de indicativo",
    "futuroDeIndicativo": "futuro de indicativo",
    "condicional": "condicional",
    "presenteDeSubjuntivo": "presente de subjuntivo",
    "imperfectoDeSubjuntivo1": "imperfecto de subjuntivo",
    "futuroDeSubjuntivo": "futuro de subjuntivo",
    "imperativoPositivo": "imperativo positivo",
    "imperativoNegativo": "imperativo negativo",
    "perfectoDeIndicativo": "perfecto de indicativo",
    "pretéritoAnterior": "pretérito anterior",
    "pluscuamperfectoDeIndicativo": "pluscuamperfecto de indicativo",
    "futuroPerfecto": "futuro perfecto",
    "condicionalCompuesto": "condicional compuesto",
    "perfectoDeSubjuntivo": "perfecto de subjuntivo",
    "pluscuamperfectoDeSubjuntivo1": "pluscuamperfecto de subjuntivo",
    "futuroPerfectoDeSubjuntivo": "futuro perfecto de subjuntivo",
    "gerundio": "gerundio",
}
PERSONS = {"fs": "yo", "ss": "tú or vos", "ts": "él, ella, usted", "fp": "nosotros", "tp": "ellos, ellas, ustedes"}


def load():
    return json.loads(PATH.read_text())


def save(sentences):
    PATH.write_text(json.dumps(sentences, ensure_ascii=False, indent=2) + "\n")


def review(sentences, include_all, out):
    shown = [s for s in sentences if include_all or not s["reviewed"]]
    title = "Complete the Sentence" if include_all else "Complete the Sentence: sentences to review"
    lines = [f"# {title} ({len(shown)})", ""]
    lines.append("Each blank has passed the machine check, which confirms it against the engine in tú")
    lines.append("and in vos. What it cannot judge is the rest: whether the Spanish is natural in both")
    lines.append("Spain and Latin America, whether the sentence makes its person plain, and whether the")
    lines.append("English says the same thing. A tú sentence is asked in vos to a learner whose setting is")
    lines.append("vos, so it names no tú, ti, or contigo.")
    verb = None
    for s in shown:
        if s["verb"] != verb:
            verb = s["verb"]
            lines += ["", f"## {verb}", ""]
        cell = TENSE_NAMES.get(s["tense"], s["tense"])
        if "person" in s:
            cell += f", {PERSONS.get(s['person'], s['person'])}"
        spanish = re.sub(r"\{([^}]*)\}", r"**\1**", s["es"])
        mark = "" if s["reviewed"] else " (draft)"
        lines.append(f"- `{s['id']}`{mark}, {cell}: {spanish}  ")
        lines.append(f"  {s['en']}")
    text = "\n".join(lines) + "\n"
    if out:
        pathlib.Path(out).write_text(text)
        print(f"wrote {len(shown)} sentences to {out}")
    else:
        sys.stdout.write(text)


def approve(sentences, ids, approve_all, excepted):
    known = {s["id"] for s in sentences}
    unknown = [i for i in ids + excepted if i not in known]
    if unknown:
        sys.exit(f"unknown ids: {', '.join(unknown)}")
    chosen = known - set(excepted) if approve_all else set(ids)
    changed = 0
    for s in sentences:
        if s["id"] in chosen and not s["reviewed"]:
            s["reviewed"] = True
            changed += 1
    save(sentences)
    print(f"approved {changed}; {sum(not s['reviewed'] for s in sentences)} drafts remain")


def status(sentences):
    reviewed = sum(s["reviewed"] for s in sentences)
    verbs = sorted({s["verb"] for s in sentences})
    print(f"{len(sentences)} sentences: {reviewed} reviewed, {len(sentences) - reviewed} drafts")
    print(f"{len(verbs)} verbs: {', '.join(verbs)}")


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
    sentences = load()
    if args.command == "review":
        review(sentences, args.all, args.out)
    elif args.command == "approve":
        if not args.all and not args.ids:
            sys.exit("name ids to approve, or pass --all")
        approve(sentences, args.ids, args.all, args.excepted)
    else:
        status(sentences)


if __name__ == "__main__":
    main()
