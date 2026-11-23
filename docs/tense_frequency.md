# How Often Each Tense Occurs

The verb page orders its cards by these counts: the simple tenses first, then the compound ones,
each block by frequency, with the two imperatives kept together at the end of the simple block
(browse plan, Phase 6; Josh's choices of 2026-11-22). `Models/ConjugationTable.swift` holds the
order. [`scripts/count_tenses.py`](../scripts/count_tenses.py) reproduces every number here:

```bash
python3 scripts/count_tenses.py                 # builds ConjugationMapTool, then counts (~30 s)
python3 scripts/count_tenses.py --examples pretérito          # the forms counted, with a sentence each
python3 scripts/count_tenses.py --no-quijote    # without the 1605 Quijote
```

Change the order here, by changing the script and rerunning it, before changing it in the app.

## The order

| | Simple block | | Compound block |
|---:|---|---:|---|
| 1 | Presente de Indicativo | 12 | Perfecto de Indicativo |
| 2 | Imperfecto de Indicativo | 13 | Pluscuamperfecto de Indicativo |
| 3 | Pretérito | 14 | Perfecto de Subjuntivo |
| 4 | Presente de Subjuntivo | 15 | Pluscuamperfecto de Subjuntivo 1 |
| 5 | Futuro de Indicativo | 16 | Condicional Compuesto |
| 6 | Condicional | 17 | Pluscuamperfecto de Subjuntivo 2 |
| 7 | Imperfecto de Subjuntivo 1 | 18 | Futuro Perfecto |
| 8 | Imperfecto de Subjuntivo 2 | 19 | Pretérito Anterior |
| 9 | Futuro de Subjuntivo | 20 | Futuro Perfecto de Subjuntivo |
| 10 | Imperativo Positivo | | |
| 11 | Imperativo Negativo | | |

Only the verb page uses this order. Info, the quiz, the Models grid, the widgets, and the
conjugation map keep `DisplayTense.conjugatedTenses`. The map's file format depends on that order,
so it must not change.

## What was counted

The `.txt` files in `corpus/originals/government` (five Spanish and Colombian government reports
and a law, 531,000 words), `literature` (seven novels, 1,315,000 words), and `technology` (five
national digital strategies, 75,000 words). The plan named these three folders. The medieval
folder was left out, and so were the PDFs that the text files came from.

**One file was not Spanish.** `literature/marianela-galdos-1878.txt` was Clara Bell's 1883 English
translation, though the corpus docs had described PG 48818 as "clean Spanish-only". The counts
above were made without it. It was removed from the corpus the same day (see
`docs/example_corpus_sources.md`), and the script still skips any file in which "the" outnumbers
"que", saying so when it does.

## The method

The counter needs to know what a form is, and that has to be the app's own answer. So
`ConjugationMapTool` gained `--cells-json` (`ConjugationMapTool/CellsJSON.swift`), which writes
every one-word form of every verb with the cells it fills: "fue" is ir's and ser's pretérito (él).
The script builds the tool and runs it unless it is handed `--cells`.

1. **Cleaning.** Gutenberg boilerplate goes, and a word hyphenated across a line break is rejoined.
2. **Sentences and clauses** split at punctuation, and a paragraph break ends a sentence, so that
   a report's headings do not run into the text. A capitalized word that does not open a sentence
   is a name or a title (Estado, Plan, Desarrollo), not a verb.
3. **Is this word a verb here?** Spanish has no capitalized nouns to help, and thousands of verb
   forms are also nouns and adjectives: desarrollo, cambio, uso, condiciones, valores, presente.
   No part-of-speech tagger was installed, and the rules below did without one:
   - A word right after an article, a determiner, a preposition, *muy*, or *tan* is not a finite
     verb (el desarrollo, de uso, muy claro). Neither is one right after a finite form of *ser*
     or *estar* (es claro, son parte).
   - A spelling that the corpus uses at least four times and a quarter of the time in those
     places, or after *la*, *las*, *lo*, or *los*, is treated as a noun everywhere, unless a
     subject pronoun, a clitic other than those four, or *no* stands before it (yo trabajo, no
     paso, se casa). That makes 2,064 spellings. "Lo cambio" is lost with "las condiciones".
   - A word whose every finite reading is tú or vos (cuentas, valores, interacciones, all plural
     nouns) counts only after a word that licenses a second person (*tú*, *que*, *si*, *no*, a
     clitic, a question word) or at the start of a sentence.
   - A spelling that is also a participle, a gerund, or an infinitive is that: visto is ver's
     participle, not vestir's yo visto; haciendo is hacer's gerund, not hacendar's yo haciendo.
   - A short stoplist holds function words that spell verb forms (como, para, sobre, entre, bajo,
     solo, nada, así, una, dios, adelante), and a few that are prepositions only before a word
     (fuera de, pese a, conforme a). Words ending in *-ciones* and *-siones* are nouns.
   - A spelling shared by a common verb and one a tenth as common is the common verb's: podría is
     poder's condicional, not podrir's imperfecto; venga is venir's, not vengar's. The exception
     is a spelling whose commoner verb offers only a command: sé is saber's yo sé, not ser's
     command, though ser is ten times as common.
4. **Compound tenses.** A finite form of *haber* followed by a participle is the compound tense of
   haber's tense: "ha dicho" is the perfecto de indicativo, "hubiera dicho" the pluscuamperfecto
   de subjuntivo 1. *Hay* is never an auxiliary. A *haber* with no participle after it counts
   under its own tense (había gente is the imperfecto).
5. **Commands.**
   - *No* and a tú or vosotros subjunctive at the start of a clause, with only clitics between,
     is the imperativo negativo (no hables, no lo digas), as is *no* and a usted form there (no
     diga usted).
   - A subjunctive that opens a sentence with nothing to govern it (Venga usted, Digamos,
     Siéntense) is a command to usted, nosotros, or ustedes.
   - A spelling that only a command has (haz, pon, ten, hablad) is a command.
   - A word with enclitic pronouns (dime, levántate, dámelo, vámonos, vestíos) is a command if
     the command and the pronouns, rejoined by the accent rule, spell the word exactly. This is
     the check `FormLookup` makes in the app. Without it, resultados was resultad + os and
     generales was genera + les. Vos commands are left out of this check, because medí + os and
     ambientá + les spell medios and ambientales, and the corpus has a hundred such adjectives for
     every decime.
   - A tú command that is spelled like the él presente (habla, mira) counts as a command only
     after "¡" (¡Mira!). Everywhere else it is the presente.
6. **Two tenses, one spelling.** After those rules, about half a percent of verb words still
   belong to two tenses: hablamos and vivimos (presente and pretérito), and a few spellings such as
   sale (salir's presente, salar's subjunctive) that the frequency rule leaves alone because the
   verbs are close. These are split in the proportion that the unambiguous forms of the same
   cells show in the same folder, refined five times as the split words are added in. For
   hablamos, that proportion comes from comemos against comimos and from irregular verbs, so a
   novel's hablamos leans toward the pretérito and a report's toward the presente.

### Reading samples

Every rule in step 3 and the enclitic check in step 5 came from reading the forms counted most
often under each tense, with `--examples`. The first run gave the imperativo positivo 13% of the
government folder's verbs; the samples were resultados, ambientales, medios, and generales. The
second gave the presente de subjuntivo condiciones, acciones, niveles, and valores. Literature's
imperativo positivo had dios (di + os) and así (asir's vos command). The pretérito had así as
asir's yo, 1,970 times.

## The results

Shares of every counted verb word, in percent. "By register" pools the government and technology
folders, which are one register (official planning prose: the technology texts are governments'
digital strategies), and weighs that pool equally against literature. "By folder" weighs each
folder a third, as Konjugieren weighed its four folders. "Pooled" counts every word once.

| Tense | Government | Literature | Technology | **By register** | By folder | Pooled |
|---|---:|---:|---:|---:|---:|---:|
| Presente de Indicativo | 57.39 | 29.49 | 49.52 | **42.94** | 45.47 | 33.14 |
| Imperfecto de Indicativo | 0.76 | 28.00 | 1.04 | **14.40** | 9.94 | 24.31 |
| Pretérito | 4.03 | 20.64 | 4.21 | **12.34** | 9.62 | 18.38 |
| Presente de Subjuntivo | 14.72 | 4.26 | 13.34 | **9.40** | 10.78 | 5.66 |
| Futuro de Indicativo | 13.77 | 2.65 | 19.81 | **8.59** | 12.07 | 4.26 |
| Condicional | 1.23 | 1.71 | 0.37 | **1.41** | 1.10 | 1.63 |
| Imperfecto de Subjuntivo 1 | 0.42 | 2.08 | 0.28 | **1.24** | 0.93 | 1.86 |
| Imperfecto de Subjuntivo 2 | 0.20 | 2.25 | 0.03 | **1.21** | 0.83 | 1.97 |
| Imperativo Positivo | 0.11 | 2.17 | 0.37 | **1.16** | 0.88 | 1.89 |
| Futuro de Subjuntivo | 0.07 | 0.36 | 0.00 | **0.21** | 0.15 | 0.32 |
| Imperativo Negativo | 0.00 | 0.21 | 0.00 | **0.10** | 0.07 | 0.18 |
| Perfecto de Indicativo | 6.51 | 2.51 | 10.96 | **4.80** | 6.66 | 3.14 |
| Pluscuamperfecto de Indicativo | 0.04 | 2.91 | 0.00 | **1.47** | 0.98 | 2.51 |
| Perfecto de Subjuntivo | 0.60 | 0.09 | 0.06 | **0.31** | 0.25 | 0.15 |
| Pluscuamperfecto de Subjuntivo 1 | 0.09 | 0.34 | 0.00 | **0.21** | 0.14 | 0.30 |
| Condicional Compuesto | 0.01 | 0.12 | 0.00 | **0.06** | 0.04 | 0.10 |
| Pluscuamperfecto de Subjuntivo 2 | 0.05 | 0.08 | 0.00 | **0.06** | 0.04 | 0.07 |
| Futuro Perfecto | 0.02 | 0.09 | 0.00 | **0.05** | 0.04 | 0.08 |
| Pretérito Anterior | 0.00 | 0.03 | 0.00 | **0.02** | 0.01 | 0.03 |
| Futuro Perfecto de Subjuntivo | 0.00 | 0.01 | 0.00 | **0.01** | 0.00 | 0.01 |

Verb words counted: 22,186 in government, 161,852 in literature, 3,256 in technology. The
government and technology counts are low against their word counts because the reports are full
of tables, headings, and noun phrases, and because the noun rules in step 3 discard some real
verbs along with the nouns.

Two constructions that the page does not show as cards were counted beside their first word's
tense: ir a + infinitive (32, 521, and 4 times) and estar + gerund (157, 678, and 54).

### Why by register

Josh chose the by-register order (2026-11-22). Weighing the three folders equally, as Konjugieren
did, lets the two folders of planning prose outvote literature. That puts the futuro second and the
pretérito fifth, because plans say what will be done (será, permitirá, deberá) and rarely what was.
By register, the order is close to the pooled count and to the order textbooks teach.

### The imperatives

By count, the imperativo positivo falls between the imperfecto de subjuntivo 2 and the futuro de
subjuntivo, and the imperativo negativo is last. Josh kept the two together at the end of the
simple block, so that the pair stays a pair, as it was before. The command counts are lower bounds:
a tú command spelled like the él presente counts only after "¡", and a usted command counts only
when it opens a sentence.

## The two problems the plan named

**Forms of two tenses.** Most collisions in Spanish are within a tense (fue of ser and ir, siento of
sentir and sentar), and they do not matter here. Across tenses, the large ones are commands, which
step 5 settles by position, and the nosotros of -ar and -ir verbs (hablamos), which step 6 splits.
After the rules, 0.4% to 0.5% of each folder's verb words are split, too few to move any tense past
its neighbor.

**The literature is old.** Six of the seven novels are from 1874 to 1898, and the seventh is the
1605 *Quijote*, a third of the folder's words. Nineteenth-century narrative leans on the imperfecto
and the -se subjunctive more than today's Spanish does, and the *Quijote* supplies nearly all of the
futuro de subjuntivo (quisiere, fuere, hubiere). Both were kept: the plan names the folder, and
weighing literature against official prose already limits it to half. Without the *Quijote*, by
register, the top eight rows keep their order; the imperativo positivo passes the imperfecto de
subjuntivo 2; and the futuro de subjuntivo drops to last of the simple block (0.04%). In the
compound block, the pretérito anterior and the futuro perfecto de subjuntivo both fall to zero.
None of this moves a card, because Josh's choice puts the imperatives at the end either way.

## Known errors

- Real verbs are lost with the nouns: "lo cambio", "la cuenta" (he tells it), and a tú form that
  opens a clause after a comma.
- Archaic enclisis on a finite verb in the *Quijote* is counted as a command when the verb's form
  is also a command's: paréceme, 33 times.
- The -ra form in nineteenth-century prose sometimes means the pluperfect indicative ("el que fuera
  presidente"). It is counted as the imperfecto de subjuntivo 1, which is the cell its spelling
  fills.
- A few English words in the reports (time, case) spell rare Spanish verbs. They are counted.
