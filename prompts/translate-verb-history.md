# Translate the verb-history essay into Spanish and ship both languages

## Goal

`docs/verb_history.txt` holds "A History of the Spanish Verb System", a 6,346-word essay
that is **not currently in the app**. The catalog still carries a pre-correction English
version, and there is no Spanish version at all. This session:

1. Extends `scripts/sync_verb_history.py` to handle a second language.
2. Translates the essay into Spanish as `docs/verb_history_es.txt`.
3. Writes both languages into `Conjugar/Supporting/Localizable.xcstrings`.
4. Verifies both render correctly in the running app.

Do all four. The English half is the cheap part and is a prerequisite for the rest, so do
not skip it on the theory that translation is the interesting work.

## Verified current state

Everything in this section was checked against the repo on 2026-07-28. Re-check anything
that looks stale rather than trusting it.

- **The English essay is corrected and final.** `docs/verb_history.txt` had 44 findings from
  `docs/history_corrections.md` applied (20 factual errors, 24 hedges) plus 38 of its 40
  nitpicks, a vowel-quantity sweep over all Latin citations, a pronoun sweep, and Josh's own
  read-through edits. Commits `16bbe44` and `5fff2e4`.
- **The catalog is stale.** `Info.verbHistoryText` holds 34,961 characters of *pre-correction*
  English. The corrected body is 38,746 characters. Syncing is step one, not an afterthought.
- **Two keys have no `es` localization**, and they are the only two of 34 `Info.*` keys in
  that state: `Info.verbHistoryText` and `Info.verbHistoryHeading`. The English heading is
  `A History of the Spanish Verb System`.
- **`scripts/sync_verb_history.py` is English-only.** Its `write()` hardcodes the `"en"`
  localization and edits that one value line in place. It has no `--lang` option.
- **All 11 distinct `%…%` link targets are language-independent.** Every one resolves to a
  string literal in `Conjugar/Models/Info.swift` rather than to a localized heading:
  `%condicional%`, `%futuro de indicativo%`, `%futuro de subjuntivo%`,
  `%imperfecto de subjuntivo 1%`, `%imperfecto de subjuntivo 2%`,
  `%perfecto de indicativo%`, `%presente de indicativo%`, `%presente de subjuntivo%`,
  `%pretérito%`, `%raíz futura%`, `%voseo%`. **They must survive translation byte-identical.**
  Translating `%pretérito%` to anything else, or "fixing" its capitalization, dead-ends the tap.
- **Sibling Spanish articles run 1.04 to 1.10 times the English length**, so expect roughly
  40,000 to 43,000 characters of Spanish.

### Invariants of the English body

Assert these against your Spanish draft. Three of the four must match exactly.

| Quantity | English | Spanish must be |
|---|---|---|
| `^…^` section headings | 25 | **exactly 25** |
| `$…$` irregularity spans | 58, of which 48 distinct | **exactly 58 / 48**, character-identical |
| `%…%` links | 14, of which 11 distinct | **exactly 14 / 11**, character-identical |
| `~…~` emphasis spans | 321 | may drift, and should **fall**; see "The glosses are the real work" |
| Paragraphs | 101 | should match; the sync script ships blank-line-separated paragraphs |

`$…$` and `%…%` are character-identical because both contain **Spanish**, not English:
the irregularity spans are conjugated Spanish forms and the links are Spanish tense names.
Only the prose around them changes.

## Step 1 — Sync the corrected English

```bash
python3 scripts/sync_verb_history.py --check   # expect: markup OK — 6346 words, 25 sections
python3 scripts/sync_verb_history.py           # writes Info.verbHistoryText (en)
python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"
```

If `--check` reports problems, stop and fix `docs/verb_history.txt` first. Do not proceed to
translation with a failing English source.

## Step 2 — Teach the sync script Spanish

Extend `scripts/sync_verb_history.py` rather than writing a second script or hand-editing the
catalog. The script exists precisely because hand-editing a 40,000-character value on one JSON
line is a foot-gun, and that argument is stronger in Spanish, not weaker.

Required changes:

- Add `--lang en|es`, defaulting to `en`, selecting source `docs/verb_history.txt` or
  `docs/verb_history_es.txt` and catalog localization `"en"` or `"es"`.
- `write()` currently locates the `"en" : {` line by scanning a fixed window after the key.
  Generalize it to the requested language. **A new `es` block may not exist yet**, so it must
  be able to insert one rather than only replace an existing value, and the inserted block
  needs `"state" : "translated"` so Xcode does not treat it as stale and fall back to English.
- `headings()` builds the set of legal `%…%` targets from Info.swift literals plus the `en`
  value of each `L.Info.<name>Heading` key. Make the localized half follow `--lang`. This does
  not change today's answer, since all 11 targets are literals, but a future link to an About
  article would silently mis-validate otherwise.
- Keep every existing validation unchanged: balanced markers, no nesting, legal links, and the
  lone-capital `$Xy$` check.

Verify the round-trip on English before translating anything: run `--lang en`, confirm the
catalog is byte-identical to what step 1 produced, and confirm `json.load` still parses.

## Step 3 — Translate

Write `docs/verb_history_es.txt` with the **same header-plus-separator structure** as the
English file: the instructional header, the dashed line, then the body. The sync script finds
the body by the first line matching `^-{20,}$`, so the separator is load-bearing. Adapt the
header's prose to Spanish or keep it in English as editor-facing notes, but keep the rules.

### Register: settled, do not relitigate

Josh decided this on 2026-07-28: **keep the learner framing, drop the presupposition that
the reader is a learner.** The article is a history, and its appeal to a native speaker is
"here is where your language came from", which survives intact. Do not rewrite the essay's
argument and do not drop its jokes. If a passage genuinely will not carry over, flag it for
Josh rather than inventing a replacement.

In practice this costs less than it sounds, because the essay was already built that way.
An audit of every reader-facing address found:

- **The learner references are already third person** and need no change: "the reason a
  student has to memorize that the preterite of ~hacer~ is $hICE$", "a learner will
  eventually meet one on a lease", "The commonest thing learners call an irregularity". They
  describe learners rather than addressing one. That is exactly the target form.
- **Most of the second-person "you" is app-user address or generic-speaker address**, and
  several instances read *better* to a native speaker: "If the two forms feel subtly
  different to you, you are not imagining it" is an appeal to an intuition a native has and a
  learner does not; likewise "~hoy he comido~ is what you say about lunch" and the closing
  "When you conjugate a Spanish verb". Keep all of these.
- The one place the essay leans on English as the reference language is the ablaut section's
  "the pattern still audible in English sing, sang, sung". It still works, since the example
  is doing comparative-linguistic duty rather than assuming the reader is anglophone, but
  consider whether a Spanish reader is better served by naming the alternation than by
  hearing it.

### The glosses are the real work

The body carries **47 single-quoted glosses**, and they do not all behave the same way under
translation. Sort each one by the language of the form being glossed.

**Foreign form, English gloss: translate the gloss into Spanish.** These stay glosses; only
the target language changes. `~agere~, ‘to drive’` becomes `~agere~, ‘conducir’`. The set
includes every Latin citation, plus `~law šā’ Allāh~, ‘if God should will’` and the Russian
word for ‘pit’ behind ~Yamnaya~.

**Spanish or Old Spanish form, English gloss: the gloss is redundant in Spanish.** Glossing
Spanish into Spanish is tautological at best and condescending at worst. Two options, and the
choice is per item:

- *Drop it.* `~vuestras mercedes~, ‘your graces’` needs nothing in Spanish. The proverbs need
  nothing: `~Adonde~ $FUeres$~, haz lo que vieres~, ‘wherever you go, do as you see’` and
  `~sea lo que~ $FUere$, ‘be it as it may’` are transparent to any Spanish speaker.
- *Replace the translation with a modern equivalent*, which is more informative than a gloss
  and preserves the sentence's rhythm. `~dar vos he~, ‘I will give you’` becomes
  `~dar vos he~, ‘os daré’`; `~es venido~, ‘he has come’` becomes `~es venido~, ‘ha venido’`;
  `~son idos~, ‘they have gone’` becomes `~son idos~, ‘se han ido’`. This is the better answer
  wherever the form is archaic, because the archaism is the point and a modern paraphrase
  shows the reader exactly what changed.

`~Hay~, ‘there is’` is the awkward middle case: the gloss exists to set up the ~ibi~ fossil
two clauses later, so it cannot simply vanish. Recast rather than delete.

Note that dropping glosses will reduce the `~…~` count, which is expected and allowed; the
`$…$` and `%…%` counts must still match exactly.

### Rules that must not be broken

1. **Markers never nest.** `~Adonde $FUeres$, haz lo que vieres~` renders wrong. Close and
   reopen: `~Adonde~ $FUeres$~, haz lo que vieres~`. The sync script enforces this.
2. **`%…%` targets are copied verbatim**, including accents and lowercase. See the list above.
3. **`$…$` spans are copied verbatim.** They encode, per letter, how a Spanish form differs
   from its regular composition, computed by `IrregularityMarker`. They are already Spanish
   and must not be retranslated, recapitalized, or re-spanned.
4. **A `$…$` span whose first letter is irregular can never open a sentence.** Spanish word
   order will move forms around, so this must be re-checked in translation even where the
   English was fine. `$andUVE$`, `$FUere$`, `$VOY$` and friends cannot lead; recast so
   something else does. A span whose first letter is regular may lead and renders lowercase,
   which is deliberate. See the header of `docs/verb_history.txt` for the full statement.
5. **Latin citations carry vowel quantity.** `~habēre~`, `~cantāre habeō~`, `~vādere~`,
   `~fēcī~`. The sweep is complete in English, so an unmarked vowel asserts shortness; keep it
   that way in Spanish. The single knowing exception is `~arrugia~`, pre-Roman and unattested.
   Beware Spanish forms that look Latin: `~cantare~` in "The Tense That Went to the Lawyers"
   is the Spanish futuro de subjuntivo, and every `~vos~` but the one introduced as "Late
   Latin" is the Spanish pronoun. Those stay bare.
6. **Prefer curly quotes `‘ ’` for glosses**, as the English does. `Info.terminologyText`
   uses ASCII `"` in its Spanish, which is legal but walks straight into the catalog foot-gun
   below. Curly quotes need no JSON escaping and cannot be corrupted by the Edit tool.
7. **Section headings `^…^` are free to translate.** They are not link targets; the 11 links
   all point at Info articles, not at the essay's own sections.

### Content notes

- `docs/history_corrections.md` is the fact-check behind the current text. **Its line numbers
  are 23 lines low** relative to today's file, because the header grew; it quotes the text
  above every finding, so locate by quote. Read the relevant cluster before rephrasing any
  hedge. Several sentences are hedged precisely, "the usual explanation", "one popular
  reading", "may have been among the first", and a translation that firms them up
  reintroduces an error the fact-check removed.
- The essay's Spanish and Latin example words are already correct. Do not "improve" them.
- The opening cosmological section is a deliberate homage to the film *The Tree of Life*.
  Keep the scale and the tone; it is the essay's signature and it is why the piece works.

## Step 4 — Validate and write

```bash
python3 scripts/sync_verb_history.py --check --lang es
python3 scripts/sync_verb_history.py --lang es
python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"
```

Then assert the invariants table above with a throwaway script comparing the two bodies:
identical multisets of `$…$` and `%…%` spans, 25 headings each, equal paragraph counts.
Report any mismatch rather than silently accepting it.

Also add the `es` value for **`Info.verbHistoryHeading`**. Match the app's existing Spanish
heading style, which is title case: `Valor y Uso`, `Terminología`, `Créditos`,
`Preguntas y Respuestas`. Something like `Historia del Sistema Verbal Español`. This one is
short enough to add with a small Python edit; do not use the Edit tool on `.xcstrings`.

### Catalog foot-guns, from CLAUDE.md

- **The Edit tool corrupts `.xcstrings` values containing ASCII quotes.** It operates on
  rendered text, so JSON's `\"` displays as a bare `"`, and an edit writes it back unescaped.
  Edit `.xcstrings` values through `python3` on the raw file.
- **Grep is useless inside `.xcstrings`**; each value is one enormous line. Find a line number,
  then Read at that offset.
- **Always `json.load` after any edit.**
- Both `en` and `es` need `"state" : "translated"`.

## Step 5 — Verify in the app

Build, then read the article in both languages. The article is reachable from the Info tab.

```bash
S=~/.claude/skills/ios-build-verify/scripts
"$S/build_app.sh"
"$S/launch_app.sh"
"$S/tap_tab.sh" info
"$S/screenshot.sh" verb-history-en
```

Then relaunch the simulator in Spanish and repeat. Confirm, in both languages:

- The article opens and scrolls, with 25 headings rendered as headings.
- Irregular letters show **red**, and no literal `$` or `%` character appears anywhere in the
  rendered text. A stray marker on screen means the parser gave up, which it does silently.
- At least three `%…%` terms are tappable and land on the right Info article. Test
  `%raíz futura%`, `%voseo%`, and one `%imperfecto de subjuntivo …%`.
- The Spanish heading appears in the Info list.

Screenshots go in `docs/screenshots/`.

## Step 6 — Journal and commit

Append a dated entry to `docs/blog_notes.md` under a `## <Title> (YYYY-MM-DD)` heading,
newest at the bottom, written as narrative for a future reader: what the translation had to
preserve, what did not survive contact with Spanish, and anything the sync-script extension
taught you. Then commit and push to the `migration` branch.

## Acceptance criteria

- [ ] `Info.verbHistoryText` has `en` and `es`, both `"state" : "translated"`, `en` matching
      the corrected 38,746-character body.
- [ ] `Info.verbHistoryHeading` has `en` and `es`.
- [ ] `sync_verb_history.py` round-trips both languages and still validates markup.
- [ ] Spanish body: 25 headings, 58 `$…$` spans and 14 `%…%` links identical to English.
- [ ] `json.load` parses the catalog.
- [ ] `build_app.sh` succeeds; `swiftlint` clean.
- [ ] Both languages verified on screen, with tappable links confirmed.
- [ ] Journal entry appended; work committed and pushed.

## Do not

- Do not hand-edit `Info.verbHistoryText` in the catalog. Use the script.
- Do not change `docs/verb_history.txt`'s **content**. It is fact-checked and settled. If you
  find a genuine error, flag it for Josh rather than fixing it silently, and note that the
  corrections document records 104 proposed corrections that were investigated and dismissed,
  several of them for firming up a hedge that was correct as written.
- Do not translate `%…%` link targets or `$…$` spans.
- Do not regenerate or renumber `docs/history_corrections.md`; it is produced by
  `scratchpad/gen_corrections.py` from workflow journals.
