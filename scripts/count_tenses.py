#!/usr/bin/env python3
# Copyright © 2026 Josh Adams. All rights reserved.
"""Count how often each tense occurs in a sample of the text corpus.

The verb page orders its simple tenses, and then its compound ones, by these counts (Phase 6 of
plans/browse_and_verb_implementation.md). docs/tense_frequency.md gives the method and the
results, and should be updated if this script changes.

Consumes
  * The Spanish texts in corpus/originals/government, literature, and technology (the .txt files;
    the PDFs they were extracted from are skipped, and so is corpus/originals/medieval). The texts
    are gitignored; corpus/README.md says where they came from.
  * A cells table: every one-word form of every verb in the app, with the cells (tense and person)
    it fills. ConjugationMapTool writes it with --cells-json (ConjugationMapTool/CellsJSON.swift),
    so the counter and the app agree on what a form is. Without --cells, this script builds the
    tool and runs it.

Produces
  A table on stdout, and with --json a machine-readable copy of every count.

Run
  python3 scripts/count_tenses.py [--cells cells.json] [--json out.json]
                                  [--examples TENSE] [--folder FOLDER] [--no-quijote]

  --examples prints the forms counted most often under one tense (for instance pretérito or
  imperativoPositivo), with a few sentences for each, which is how the stoplist and the context
  rules below were found. --folder limits a run to one folder. --no-quijote leaves out the 1605
  Quijote, to show what it does to the literature count.

The method, in brief (the doc has the reasoning):
  1. Clean each text: drop Project Gutenberg boilerplate and rejoin words hyphenated across a
     line break.
  2. Split into sentences and clauses at punctuation. A capitalized word that does not open a
     sentence is a name or a title (Estado, Plan, Desarrollo), never a verb.
  3. Decide whether a word that spells a verb form is a verb here. A word right after an article,
     a determiner, a preposition, or a form of ser or estar is not (el desarrollo, de cambio, es
     claro). Neither is a word that the corpus mostly uses in those places, unless a pronoun or
     "no" stands before it (yo desarrollo, lo cambio). A short stoplist covers the function words
     that are also verb forms: como, para, sobre, entre, bajo.
  4. Pair each finite form of haber with a following participle to find the compound tenses:
     "ha dicho" is the perfecto de indicativo, "hubiera dicho" the pluscuamperfecto de subjuntivo 1.
  5. Find the commands: "no" plus a tú or vosotros subjunctive at a clause's start (no hables) is
     the imperativo negativo; a subjunctive that opens a sentence with no word to govern it
     (Venga usted, No diga) is a command to usted, ustedes, or nosotros; a command with an
     enclitic (dime, levántate) or a spelling only a command has (haz, pon, hablad) is the
     imperativo positivo, and so is a tú command after "¡" (¡Mira!).
  6. Count every other verb word under the tense its spelling belongs to. A spelling shared by a
     common verb and one a tenth as common is the common verb's (podría is poder's, not
     podrir's). Where one spelling still belongs to two tenses (hablamos is presente and
     pretérito), split it in the proportion that the unambiguous forms of the same cells show in
     the same folder.

Every number this produces is an estimate. The rules err in known directions, which the doc
lists, and none of those errors is large enough to change the order of the top of each block.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
FOLDERS = ["government", "literature", "technology"]
QUIJOTE = "quijote-cervantes-1605.txt"

SIMPLE = [
    "presenteDeIndicativo",
    "pretérito",
    "imperfectoDeIndicativo",
    "futuroDeIndicativo",
    "condicional",
    "presenteDeSubjuntivo",
    "imperfectoDeSubjuntivo1",
    "imperfectoDeSubjuntivo2",
    "futuroDeSubjuntivo",
    "imperativoPositivo",
    "imperativoNegativo",
]
COMPOUND = [
    "perfectoDeIndicativo",
    "pretéritoAnterior",
    "pluscuamperfectoDeIndicativo",
    "futuroPerfecto",
    "condicionalCompuesto",
    "perfectoDeSubjuntivo",
    "pluscuamperfectoDeSubjuntivo1",
    "pluscuamperfectoDeSubjuntivo2",
    "futuroPerfectoDeSubjuntivo",
]
# Counted so the doc can say how large they are. The page shows neither as a card, and their
# first words are counted under their own tenses too (voy is the presente de indicativo).
OFF_PAGE = ["irAInfinitivo", "estarGerundio"]

# The tense of haber that makes each compound tense, as DisplayTense.haberTenseForCompoundTense.
COMPOUND_OF_HABER = {
    "presenteDeIndicativo": "perfectoDeIndicativo",
    "pretérito": "pretéritoAnterior",
    "imperfectoDeIndicativo": "pluscuamperfectoDeIndicativo",
    "futuroDeIndicativo": "futuroPerfecto",
    "condicional": "condicionalCompuesto",
    "presenteDeSubjuntivo": "perfectoDeSubjuntivo",
    "imperfectoDeSubjuntivo1": "pluscuamperfectoDeSubjuntivo1",
    "imperfectoDeSubjuntivo2": "pluscuamperfectoDeSubjuntivo2",
    "futuroDeSubjuntivo": "futuroPerfectoDeSubjuntivo",
}
FINITE = set(SIMPLE) - {"imperativoNegativo"}

# A word straight after one of these is a noun or an adjective, not a finite verb: el cambio,
# de uso, muy claro. La, lo, los, and las are left out, because they are also object pronouns
# (la cuenta, he tells it), and so is "que".
DETERMINERS = set("""
el un una unos unas del al este esta estos estas ese esa esos esas aquel aquella aquellos aquellas
su sus mi mis tu tus nuestro nuestra nuestros nuestras vuestro vuestra vuestros vuestras cada otro
otra otros otras cualquier dicho dicha dichos dichas mucho mucha muchos muchas poco poca pocos pocas
todo toda todos todas cuyo cuya cuyos cuyas ningún ninguna algún alguna algunos algunas tal tales
mismo misma mismos mismas varios varias diversos diversas primer primera segundo segunda tercer
nuevo nueva nuevos nuevas gran grandes buen mal muy tan
de en con por para sin sobre entre desde hasta hacia según ante tras contra durante mediante a
""".split())

# Finite forms of ser and estar: a word right after one is an adjective or a participle (es claro,
# está ligado, son parte), or a noun, not a second finite verb.
COPULAS = set("""
es son era eran fue fueron sea sean será serán sería serían fuera fueran fuese fuesen
está están estaba estaban estuvo estuvieron esté estén estará estarán estaría estarían
""".split())

# Articles that are also object pronouns. A spelling the corpus mostly uses after these and the
# determiners above is a noun (las condiciones, los valores), even though "la cuenta" can also be
# "he tells it".
ARTICLE_PRONOUNS = {"la", "las", "lo", "los"}

# A word after one of these is a verb even if the corpus mostly uses its spelling as a noun:
# yo trabajo, no paso, se casa. The article pronouns are not among them, so "lo cambio" is lost
# with "las condiciones".
VERB_SIGNALS = set("""
yo tú él ella usted nosotros nosotras vosotros vosotras ellos ellas ustedes vos
no me te se nos os le les ya nunca jamás también tampoco
""".split())

# Function words that are also verb forms, and never mean the verb in this corpus.
STOPLIST = set("""
como para sobre entre bajo solo salvo medio nada junto cerca mientras pese incluso cara vino río
media mitad vista una uno unas clave ambiente libertad intimidad aparte caliente transparente
dios así adelante abajo libre alegre firme impaciente conforme fría
""".split())

# Nouns that spell a tú subjunctive (interacciones, of interaccionar) or a vos command with an
# enclitic, whatever stands before them.
NOUN_ENDINGS = re.compile(r"(ciones|siones)$")

# A word whose every finite reading is tú or vos (las cuentas, los valores, las condiciones are
# also tú forms) counts only where a tú form is likely: after one of these, or opening a sentence.
SECOND_PERSON_LICENSE = set("""
tú vos no me te se nos le les que qué si cuando aunque ojalá quizá quizás porque cómo dónde
cuándo ya también nunca jamás tampoco
""".split())

# The same, but only before the word that makes them a preposition or an adverb.
BEFORE = {
    "fuera": {"de"},
    "frente": {"a"},
    "dentro": {"de"},
    "acerca": {"de"},
    "respecto": {"a", "de"},
    "pese": {"a"},
    "junto": {"a", "con"},
    "cerca": {"de"},
    "luego": {"de"},
    "conforme": {"a", "al", "con"},
}

# A spelling the corpus uses this often after a determiner is a noun or an adjective. The share
# and the floor were chosen by reading the forms on either side of them (see the doc).
NOMINAL_SHARE = 0.25
NOMINAL_FLOOR = 4

FREQUENCIES = {}

ENCLITICS = ["nos", "os", "me", "te", "se", "lo", "la", "le", "los", "las", "les"]
ACUTE = {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u"}

WORD = re.compile(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+|[.!?¡¿;:,()«»\"“”—–]")
CLAUSE_BREAK = set(",;:()«»\"“”—–")
SENTENCE_BREAK = set(".!?¿¡")


def load_cells(path):
    """form → list of (infinitive, tense, person)."""
    with open(path, encoding="utf-8") as handle:
        raw = json.load(handle)
    cells = {form: [tuple(row) for row in rows] for form, rows in raw.items()}
    # hay is haber's impersonal presente, which the engine does not conjugate.
    cells["hay"] = [("haber", "presenteDeIndicativo", "thirdSingular")]
    return cells


def load_frequencies():
    """infinitive → CORPES XXI lemma hits, from verbModelMap.xml's hi attribute."""
    text = (REPO / "Conjugar/Models/verbModelMap.xml").read_text(encoding="utf-8")
    return {m.group(1): int(m.group(2)) for m in re.finditer(r'<verb in="([^"]+)"[^>]*? hi="(\d+)"', text)}


# A spelling shared by two verbs is read as the commoner verb's when that verb is this many times
# as frequent: podría is poder's condicional, not podrir's imperfecto. The commonest such spellings
# were read to check the rule (see the doc).
DOMINANCE = 10


def dominant_entries(entries, frequencies):
    """The readings of the verb a reader would take the spelling for. Where the verbs are of
    similar frequency (fue of ser and ir, siento of sentir and sentar), every reading stays."""
    verbs = sorted({infinitive for infinitive, _, _ in entries}, key=lambda v: -frequencies.get(v, 0))
    if len(verbs) < 2:
        return entries
    top, runner_up = frequencies.get(verbs[0], 0), frequencies.get(verbs[1], 0)
    dominant = [entry for entry in entries if entry[0] == verbs[0]]
    # Not when the commoner verb's only finite reading is a command: sé is saber's yo sé far more
    # often than ser's command, though ser is the commoner verb.
    finite = [entry for entry in dominant if entry[1] in FINITE]
    if finite and all(tense == "imperativoPositivo" for _, tense, _ in finite):
        return entries
    if top >= DOMINANCE * max(runner_up, 1):
        return dominant
    return entries


def build_cells():
    build_root = Path(os.environ.get("TMPDIR", "/tmp")) / "ConjugarConjugationMapTool-build"
    subprocess.run(
        ["xcodebuild", "-project", str(REPO / "Conjugar.xcodeproj"), "-target", "ConjugationMapTool",
         "-configuration", "Release", f"SYMROOT={build_root}/Products", f"OBJROOT={build_root}/Intermediates",
         "-quiet", "build"],
        check=True,
    )
    out = Path(tempfile.mkdtemp()) / "cells.json"
    subprocess.run(
        [str(build_root / "Products/Release/ConjugationMapTool"), "--verb-map",
         str(REPO / "Conjugar/Models/verbModelMap.xml"), "--cells-json", str(out)],
        check=True,
    )
    return out


def clean(text):
    start = re.search(r"\*\*\* ?START OF.*?\*\*\*", text)
    if start:
        text = text[start.end():]
    end = re.search(r"\*\*\* ?END OF", text)
    if end:
        text = text[:end.start()]
    # Rejoin a word broken across a line: desa-\nrrollo.
    text = re.sub(r"([a-záéíóúüñ])-\s*\n\s*([a-záéíóúüñ])", r"\1\2", text)
    return text


def sentences(text):
    """Each sentence as a list of clauses, each clause a list of (word, capitalized) pairs. A
    paragraph break ends a sentence, so a heading never runs into the next line."""
    for paragraph in re.split(r"\n\s*\n", text):
        sentence, clause = [], []
        for token in WORD.findall(paragraph):
            if token in SENTENCE_BREAK:
                if clause:
                    sentence.append(clause)
                if sentence:
                    yield sentence
                sentence, clause = [], []
                if token == "¡":
                    clause.append(("¡", False))
            elif token in CLAUSE_BREAK:
                if clause:
                    sentence.append(clause)
                clause = []
                if token in "—–":
                    # A dialogue dash opens a new utterance.
                    if sentence:
                        yield sentence
                    sentence = []
            else:
                clause.append((token.lower(), token[0].isupper() and not token.isupper()))
        if clause:
            sentence.append(clause)
        if sentence:
            yield sentence


def fold_one_accent(word):
    return "".join(ACUTE.get(char, char) for char in word)


class Counter3:
    """The counts for one folder."""

    def __init__(self):
        self.tokens = []          # (frozenset of (tense, person)), one per verb word
        self.forms = defaultdict(Counter)  # tense → Counter of forms, for --examples
        self.samples = defaultdict(list)   # (tense, form) → sentences
        self.off_page = Counter()
        self.words = 0
        self.rejected = Counter()

    def add(self, candidates, form, sentence_text):
        self.tokens.append(frozenset(candidates))
        tenses = {tense for tense, _ in candidates}
        for tense in tenses:
            self.forms[tense][form] += 1 / len(tenses)
            key = (tense, form)
            if len(self.samples[key]) < 3:
                self.samples[key].append(sentence_text)

    def ambiguous(self):
        """How many words were split between tenses, and the commonest such cell pairs."""
        pairs = Counter()
        for candidates in self.tokens:
            tenses = tuple(sorted({tense for tense, _ in candidates}))
            if len(tenses) > 1:
                pairs[tenses] += 1
        return sum(pairs.values()), pairs

    def allocate(self):
        """Split each ambiguous word among its cells in proportion to the unambiguous words of the
        same cells, refined a few times as the ambiguous words are added in (EM)."""
        weights = Counter()
        for candidates in self.tokens:
            if len({tense for tense, _ in candidates}) == 1:
                for cell in candidates:
                    weights[cell] += 1 / len(candidates)
        totals = Counter()
        for _ in range(5):
            totals = Counter()
            new_weights = Counter()
            for candidates in self.tokens:
                mass = sum(weights[cell] for cell in candidates)
                for cell in candidates:
                    share = weights[cell] / mass if mass else 1 / len(candidates)
                    totals[cell[0]] += share
                    new_weights[cell] += share
            weights = new_weights
        return totals


def nominal_spellings(all_sentences, cells):
    """The verb spellings that the corpus mostly uses after a determiner: el desarrollo."""
    after_determiner, total = Counter(), Counter()
    for sentence in all_sentences:
        for clause in sentence:
            for index, (word, _) in enumerate(clause):
                if word in cells:
                    total[word] += 1
                    if index > 0 and (clause[index - 1][0] in DETERMINERS or clause[index - 1][0] in ARTICLE_PRONOUNS):
                        after_determiner[word] += 1
    return {
        word for word, count in after_determiner.items()
        if count >= NOMINAL_FLOOR and count / total[word] >= NOMINAL_SHARE
    }


def is_participle(word, cells):
    return any(tense == "participio" for _, tense, _ in cells.get(word, []))


def is_infinitive(word, cells):
    return any(tense == "infinitivo" for _, tense, _ in cells.get(word, []))


def is_gerund(word, cells):
    return any(tense == "gerundio" for _, tense, _ in cells.get(word, []))


STRONG = set("aeoáéóíú")
VOWELS = set("aeiouáéíóúü")
ADD_ACUTE = {v: k for k, v in ACUTE.items()}


def nuclei(word):
    """The index ranges of the word's syllable nuclei. Two strong vowels, or an accented weak one,
    are two syllables (le-er, rí-o); anything else in a run of vowels is one (cuen, siem)."""
    ranges, index = [], 0
    while index < len(word):
        if word[index] not in VOWELS:
            index += 1
            continue
        start = index
        index += 1
        while index < len(word) and word[index] in VOWELS:
            if word[index - 1] in STRONG and word[index] in STRONG:
                break
            index += 1
        ranges.append((start, index))
    return ranges


def stressed_nucleus(word):
    """The nucleus that carries the stress: the one with a written accent, or by the default
    rule, the next-to-last for a word ending in a vowel, n, or s, and the last otherwise."""
    ranges = nuclei(word)
    for number, (start, end) in enumerate(ranges):
        if any(char in ACUTE for char in word[start:end]):
            return number, ranges
    if len(ranges) < 2:
        return len(ranges) - 1, ranges
    return (len(ranges) - 2 if word[-1] in "aeiouns" else len(ranges) - 1), ranges


def with_enclitics(command, pronouns):
    """The command written with its pronouns, as a reader would see it: di + me + lo is dímelo,
    levanta + te is levántate, da + me is dame, levantad + os is levantaos, vamos + nos is
    vámonos."""
    base = command
    if pronouns[0] in {"nos", "se"} and base.endswith("mos"):
        base = base[:-1]
    if pronouns[0] == "os" and base.endswith("d") and base != "id":
        base = base[:-1]
    # The stress is the command's own: levantad is stressed on -tad, so levantaos on -ta-.
    number, _ = stressed_nucleus(command)
    # An accented í or ú beside another vowel marks a hiatus, and keeps its accent whatever the
    # word's length (actúa + les is actúales); so does the i of an -ir verb's vosotros command
    # before os (vestid + os is vestíos), though idos is the exception.
    plain = "".join(
        char if char in "íú" and ((i > 0 and base[i - 1] in VOWELS) or (i + 1 < len(base) and base[i + 1] in VOWELS)) else ACUTE.get(char, char)
        for i, char in enumerate(base)
    )
    if pronouns[0] == "os" and command.endswith("id") and command != "id":
        plain = plain[:-1] + "í"
    joined = plain + "".join(pronouns)
    if any(char in "íú" for char in plain):
        return joined
    ranges = nuclei(joined)
    if number < 0 or len(ranges) - number < 3:
        return joined
    start, end = ranges[number]
    nucleus = joined[start:end]
    strong = [i for i, char in enumerate(nucleus) if char in "aeo"]
    mark = start + (strong[0] if strong else len(nucleus) - 1)
    return joined[:mark] + ADD_ACUTE.get(joined[mark], joined[mark]) + joined[mark + 1:]


def enclitic_command(word, cells, folded_commands):
    """The command cells of a word with one or two enclitic pronouns: dime, levántate, dámelo,
    vámonos. Each way of peeling pronouns off the end is checked forward: the command and its
    pronouns, rejoined by the accent rule, must spell the word exactly, so that resultados is
    not resultad + os and generales is not genera + les."""
    for first in ENCLITICS:
        if not word.endswith(first):
            continue
        rest = word[:-len(first)]
        splits = [(rest, [first])]
        for second in ENCLITICS:
            if rest.endswith(second):
                splits.append((rest[:-len(second)], [second, first]))
        for stem, pronouns in splits:
            if not stem:
                continue
            folded = fold_one_accent(stem)
            for candidate in {folded, folded + "s", folded + "d"}:
                for command, cell_list in folded_commands.get(candidate, ()):
                    if with_enclitics(command, pronouns) == word:
                        return cell_list
    return None


def command_index(cells):
    """Accent-folded spelling → [(command, its command cells)], for enclitic_command. Vos
    commands are left out: medí + os and ambientá + les spell medios and ambientales, and the
    corpus has a hundred adjectives like them for every decime."""
    index = defaultdict(list)
    for form, rows in cells.items():
        found = [(tense, person) for _, tense, person in rows if tense == "imperativoPositivo" and person != "secondSingularVos"]
        if found:
            index[fold_one_accent(form)].append((form, found))
    return index


def count_folder(folder_sentences, cells, nominal, folded_commands, result):
    for sentence in folder_sentences:
        sentence_text = " ".join(word for clause in sentence for word, _ in clause)
        result.words += sum(len(clause) for clause in sentence)
        for clause_index, clause in enumerate(sentence):
            count_clause(clause, clause_index, sentence, sentence_text, cells, nominal, folded_commands, result)


def count_clause(clause, clause_index, sentence, sentence_text, cells, nominal, folded_commands, result):
    exclaimed = bool(clause) and clause[0][0] == "¡"
    words = [(word, capitalized) for word, capitalized in clause if word != "¡"]
    sentence_initial = clause_index == 0
    skip = set()
    for index, (word, capitalized) in enumerate(words):
        if index in skip:
            continue
        previous = words[index - 1][0] if index > 0 else None
        following = words[index + 1][0] if index + 1 < len(words) else None
        opens_sentence = sentence_initial and index == 0

        if capitalized and not opens_sentence:
            continue
        if word in STOPLIST or NOUN_ENDINGS.search(word) or following in BEFORE.get(word, ()):
            result.rejected[word] += 1
            continue
        entries = cells.get(word)
        if entries is None:
            command = enclitic_command(word, cells, folded_commands)
            if command:
                result.add(command, word, sentence_text)
            continue

        entries = dominant_entries(entries, FREQUENCIES)

        # Off-page constructions, counted beside their first word's own tense.
        if following == "a" and index + 2 < len(words) and is_infinitive(words[index + 2][0], cells):
            if any(infinitive == "ir" and tense == "presenteDeIndicativo" for infinitive, tense, _ in entries):
                result.off_page["irAInfinitivo"] += 1
        if following and is_gerund(following, cells):
            if any(infinitive == "estar" and tense in FINITE for infinitive, tense, _ in entries):
                result.off_page["estarGerundio"] += 1

        # A compound tense: a finite form of haber and a participle.
        # hay is impersonal, and never an auxiliary.
        haber = [(tense, person) for infinitive, tense, person in entries if infinitive == "haber" and tense in COMPOUND_OF_HABER and word != "hay"]
        if haber and following and is_participle(following, cells):
            result.add([(COMPOUND_OF_HABER[tense], person) for tense, person in haber], f"{word} …", sentence_text)
            skip.add(index + 1)
            continue

        if previous in DETERMINERS or previous in COPULAS:
            result.rejected[word] += 1
            continue
        if word in nominal and previous not in VERB_SIGNALS:
            result.rejected[word] += 1
            continue

        # A spelling that is also a participle, a gerund, or an infinitive is that, not the
        # finite form of a rarer verb: visto is ver's participle, not vestir's yo visto, and
        # haciendo is hacer's gerund, not hacendar's yo haciendo.
        if any(tense in {"participio", "gerundio", "infinitivo"} for _, tense, _ in entries):
            continue
        finite = [(tense, person) for _, tense, person in entries if tense in FINITE]
        if not finite:
            continue
        if all(person in {"secondSingularTú", "secondSingularVos"} for _, person in finite):
            if not (sentence_initial and index == 0) and previous not in SECOND_PERSON_LICENSE:
                result.rejected[word] += 1
                continue

        # Where does the word stand? Before it, at most "no" and object pronouns.
        lead = [w for w, _ in words[:index]]
        bare_lead = all(w in {"no", "me", "te", "se", "nos", "os", "lo", "la", "le", "los", "las", "les"} for w in lead)
        negated = "no" in lead and bare_lead
        initial = sentence_initial and bare_lead

        subjunctive = [(t, p) for t, p in finite if t == "presenteDeSubjuntivo"]
        commands = [(t, p) for t, p in finite if t == "imperativoPositivo"]

        if negated and initial and subjunctive:
            # No hables; no lo digas; no diga usted.
            cells_here = [("imperativoNegativo", p) for _, p in subjunctive if p != "firstSingular"]
            if cells_here:
                result.add(cells_here, f"no {word}", sentence_text)
                continue
        if initial and not negated and subjunctive and not exclaimed and commands:
            # Venga usted; Digamos; Siéntense: a subjunctive that nothing governs.
            positive = [(t, p) for t, p in commands if p in {"thirdSingular", "firstPlural", "thirdPlural"}]
            if positive:
                result.add(positive, word, sentence_text)
                continue
        only_commands = all(t == "imperativoPositivo" for t, _ in finite)
        if only_commands:
            # haz, pon, hablad, sabed: no other tense spells them.
            result.add(finite, word, sentence_text)
            continue
        if exclaimed and initial and not negated and commands:
            # ¡Mira! ¡Calla!
            result.add(commands, word, sentence_text)
            continue

        # Otherwise every reading but the command one: habla is él habla, not the command.
        declarative = [(t, p) for t, p in finite if t != "imperativoPositivo"]
        result.add(declarative or finite, word, sentence_text)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--cells", help="A ConjugationMapTool --cells-json file. Built if omitted.")
    parser.add_argument("--json", help="Write every count here.")
    parser.add_argument("--examples", help="Print the forms most often counted under this tense.")
    parser.add_argument("--folder", choices=FOLDERS, help="Count one folder only.")
    parser.add_argument("--no-quijote", action="store_true", help="Leave out the 1605 Quijote.")
    args = parser.parse_args()

    cells = load_cells(args.cells or build_cells())
    FREQUENCIES.update(load_frequencies())
    folders = [args.folder] if args.folder else FOLDERS

    texts = {}
    for folder in folders:
        directory = REPO / "corpus/originals" / folder
        names = sorted(name for name in os.listdir(directory) if name.endswith(".txt"))
        if args.no_quijote:
            names = [name for name in names if name != QUIJOTE]
        texts[folder] = []
        for name in names:
            raw = (directory / name).read_text(encoding="utf-8", errors="replace")
            # A guard: marianela-galdos-1878.txt, removed on 2026-11-22, was an English translation.
            if len(re.findall(r"\bthe\b", raw)) > len(re.findall(r"\bque\b", raw)):
                print(f"Skipping {folder}/{name}, which is in English.", file=sys.stderr)
                continue
            texts[folder].append(list(sentences(clean(raw))))

    all_sentences = [s for folder in texts.values() for text in folder for s in text]
    nominal = nominal_spellings(all_sentences, cells)

    folded_commands = command_index(cells)
    results = {}
    for folder in folders:
        result = Counter3()
        for text in texts[folder]:
            count_folder(text, cells, nominal, folded_commands, result)
        results[folder] = result

    totals = {folder: results[folder].allocate() for folder in folders}
    shares = {}
    for folder, total in totals.items():
        verb_words = sum(total[t] for t in SIMPLE + COMPOUND)
        shares[folder] = {t: total[t] / verb_words for t in SIMPLE + COMPOUND}
    weighted = {t: sum(shares[f][t] for f in folders) / len(folders) for t in SIMPLE + COMPOUND}
    # By register: the government and technology folders are one register, official planning
    # prose (the technology texts are governments' digital strategies), so they are pooled and
    # weighed equally against the literature.
    official_folders = [f for f in folders if f != "literature"]
    by_register = None
    if official_folders and "literature" in folders:
        official_total = Counter()
        for f in official_folders:
            official_total.update(totals[f])
        official_words = sum(official_total[t] for t in SIMPLE + COMPOUND)
        by_register = {t: (official_total[t] / official_words + shares["literature"][t]) / 2 for t in SIMPLE + COMPOUND}
    order_by = by_register or weighted
    pooled_total = Counter()
    for total in totals.values():
        pooled_total.update(total)
    pooled_words = sum(pooled_total[t] for t in SIMPLE + COMPOUND)
    pooled = {t: pooled_total[t] / pooled_words for t in SIMPLE + COMPOUND}

    if args.examples:
        merged = Counter()
        for folder in folders:
            merged.update(results[folder].forms[args.examples])
        for form, count in merged.most_common(60):
            print(f"{count:8.0f}  {form}")
            for folder in folders:
                for sample in results[folder].samples.get((args.examples, form), [])[:1]:
                    print(f"            [{folder}] {sample[:160]}")
        return

    print(f"Words read: " + ", ".join(f"{f} {results[f].words:,}" for f in folders))
    print(f"Verb words counted: " + ", ".join(f"{f} {sum(totals[f][t] for t in SIMPLE + COMPOUND):,.0f}" for f in folders))
    print(f"Spellings treated as nouns or adjectives: {len(nominal)}")
    print()
    header = f"{'tense':32}" + "".join(f"{f:>12}" for f in folders) + f"{'by register':>13}{'by folder':>11}{'pooled':>8}"
    for block_name, block in (("Simple", SIMPLE), ("Compound", COMPOUND)):
        print(f"{block_name} tenses, ordered by register (share of every counted verb word, %)")
        print(header)
        for tense in sorted(block, key=lambda t: -order_by[t]):
            row = f"{tense:32}" + "".join(f"{100 * shares[f][tense]:12.2f}" for f in folders)
            register = f"{100 * by_register[tense]:13.2f}" if by_register else f"{'':13}"
            print(row + register + f"{100 * weighted[tense]:11.2f}{100 * pooled[tense]:8.2f}")
        print()
    print("Off the page (occurrences, also counted under their first word's tense)")
    for construction in OFF_PAGE:
        print(f"{construction:32}" + "".join(f"{results[f].off_page[construction]:13,}" for f in folders))
    print()
    print("Words split between tenses (share of the folder's verb words, and the commonest pairs)")
    for folder in folders:
        count, pairs = results[folder].ambiguous()
        verb_words = len(results[folder].tokens)
        top = "; ".join(f"{' / '.join(pair)} {n:,}" for pair, n in pairs.most_common(3))
        print(f"  {folder}: {count:,} of {verb_words:,} ({100 * count / verb_words:.1f}%). {top}")
    print()
    print("Raw counts")
    for folder in folders:
        print(f"  {folder}: " + ", ".join(f"{t} {totals[folder][t]:,.0f}" for t in SIMPLE + COMPOUND))

    if args.json:
        with open(args.json, "w", encoding="utf-8") as handle:
            json.dump({
                "folders": folders,
                "counts": {f: {t: totals[f][t] for t in SIMPLE + COMPOUND} for f in folders},
                "shares": shares,
                "byRegister": by_register,
                "byFolder": weighted,
                "pooled": pooled,
                "offPage": {f: dict(results[f].off_page) for f in folders},
                "simpleOrder": sorted(SIMPLE, key=lambda t: -order_by[t]),
                "compoundOrder": sorted(COMPOUND, key=lambda t: -order_by[t]),
            }, handle, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    sys.exit(main())
