# Plan: Build the Pedagogy Suggestions in Conjugar

**For:** a series of fresh Claude Code sessions, one phase per session as a rule. **Kind of work:**
quiz logic, new practice modes, a persistent practice record, localized strings, Game Center
configuration, a little authored Spanish content, and tests. **Written:** 2026-11-22, by porting
Konjugieren's finished plan for the same goal,
[`../Konjugieren/plans/pedagogy_implementation.md`](../../Konjugieren/plans/pedagogy_implementation.md),
and the report it sprang from,
[`../Konjugieren/docs/pedagogy_research.md`](../../Konjugieren/docs/pedagogy_research.md), to
Conjugar's quiz as it stands on `master` today. **Goal:** improve Conjugar's pedagogical
performance, on the Quiz tab and wherever else the quiz reaches, as Konjugieren's plan did there.

**This plan runs after [`browse_and_verb_implementation.md`](browse_and_verb_implementation.md)**
(the browse plan), which builds pieces this one extends: the accent key row, the conjugation map,
the key conjugations, the learner's record of verbs, a scoped quiz, frequency bands, and the review
card's schedule. Its section [What the Browse Plan Leaves for This One](#what-the-browse-plan-leaves-for-this-one)
says what to expect, and the browse plan's sessions correct it as they finish. Read that section,
and the browse plan's **How it differed** notes for the phases it names, before Phase 0.

## Status

Each session that finishes a phase fills in its row, changes the **Status** line under the phase's
heading to match, and writes the phase's **How it differed** note. A finished phase is "Awaiting
Josh" until Josh has tried it and committed it. Sessions never commit, so the Commit cell is filled
by the next session, which reads the hash from `git log` once Josh's commit exists.

| Phase | Status | Date | Commit | Suggestions |
|---:|---|---|---|---|
| 0 | Done | 2026-11-22 | 8518921 | T1.3, T1.4, T1.5, Conjugar's defects |
| 1 | Done | 2026-11-23 | 30822ac | T1.2 |
| 2 | Done | 2026-11-23 | df7633c | T4.1, T4.4, T4.5 |
| 3 | Done | 2026-11-23 | 8bd27c4 | T1.6 |
| 4 | Done | 2026-11-23 | 17aab3e | T2.3, T2.6, T6.7, M1 |
| 5 | Done | 2026-11-23 | c4d16e2 | T2.1, T2.2, T2.5 |
| 6 | Done | 2026-11-23 | dd360ca | T2.7, T3.1, T6.5, M2, M3 |
| 7 | Done | 2026-11-23 | bcf9356 | Decision 4 |
| 8 | Done | 2026-11-23 | 5ffc73a | T2.8 |
| 9 | Done | 2026-11-23 | 37c3149 | T2.9, Decision 8 |
| 10 | Done | 2026-11-23 | 16e92b3 | T3.3 (the record), T3.4, T3.5, T6.4 |
| 11 | Done | 2026-11-23 | 5a40257 | T3.2, T3.3 (the session) |
| 12 | Awaiting Josh | 2026-11-23 | | T6.1, T6.6 (the leaderboard's place) |
| 13 | Not started | | | T4.2, T4.3 |
| 14 | Not started | | | T5.1 |
| 15 | Not started | | | T5.2 |
| 16 | Not started | | | T5.4 |
| 17 | Not started | | | T5.5 |
| 18 | Not started | | | T5.6 |
| 19 | Not started | | | T6.2 |
| 20 | Not started | | | T5.7 |
| 21 | Not started | | | T6.3 |
| 22 | Not started | | | T6.6 (personal bests and achievements) |
| 23 | Not started | | | T6.8 |
| Closing | Not started | | | Audit, porting notes |

## How to Work This Plan

**Choosing a phase.** Take the lowest-numbered phase that is not done and whose dependencies are.
The numbering follows Konjugieren's order of leverage (correct grading, then what the quiz asks,
then memory, then feedback, then new directions, then motivation), adjusted where one phase needs
another's pieces. It is a suggested order. If a phase proves too large for one session, split it,
say so in its row, and leave the remainder marked "Partly done". Phases 10, 17, and 18 are the
likeliest to split. **Phase 9 is the exception to the order:** take it last, after Phase 23, if at
all (Josh, 2026-11-22). No other phase depends on it.

**Read Konjugieren's version first.** Every phase here ports the phase one number higher in
Konjugieren's plan, which starts at Phase 1 (Phase 0 here is its Phase 1, and Phase 23 its Phase
24); each phase names it under its heading. Before starting, read that phase's text and its **How it
differed** note, which record what Josh decided, what broke, and what the phase text got wrong. The
**From Konjugieren** bullets below summarize the lessons that apply here, but the notes have more.
Konjugieren's code is in `../Konjugieren`; read its implementation of the same piece when it helps,
then port the design, not the German specifics. Never edit Konjugieren's files from a Conjugar
session.

**What this plan leaves to you.** The phases say what to build and what Josh decided. They do not
say how. Read the code, choose the implementation, and record in **How it differed** anything that
departs from the phase as written. A later session relies on that note more than on the phase text
above it. Read the notes of every phase this one depends on before starting.

**Subagents run on Sonnet.** No phase requires subagents, but a session may delegate work to them,
such as drafting a large batch of Phase 17's sentences or Phase 18's items. Any subagent it launches
uses Sonnet (`model: "sonnet"` on the Agent tool), as Josh decided for Konjugieren on 2026-11-15.
The session still runs the machine check and reads the drafts itself before Josh sees them.

**Ask Josh when a verdict does not settle a question.** Phases list such questions under **Ask
Josh**. Do not guess at them. Ask before building the part that depends on the answer, and record
the answer and its date in **How it differed**. Konjugieren's sessions usually asked with two or
three mockups and a recommendation; that worked well.

**Comments say why the code is as it is, never how it came to be.** Josh is comment-averse; write a
comment only for durable, non-obvious rationale or domain knowledge, and lean toward none. Never put
build provenance in code, test names, or long-lived docs (`docs/project_structure.md`,
`docs/feature_architecture.md`, `docs/release.md`): no "(pedagogy plan, Phase 6)", "added in Phase
12", or "browse plan"; no "ported from Konjugieren", "as in Conjuguer", or other sibling-app
attributions (keep the reason the sibling found, stated as a fact about this code); no "(Josh,
2026-11-22)" or other decision attributions and change dates (keep the rule, drop who and when); no
commit hashes, audit item numbers, or pointers to `plans/` or `docs/blog_notes.md`; no `// MARK:`
lines. A date may stay where it records when a measurement was taken. That history belongs in the
phase's **How it differed** note and the journal. `plans/sweep_comments.md` has the full rule; on
2026-11-22 a sweep removed some 180 such citations that the browse plan's phases had left, so do not
put them back.

**Every phase finishes the same way.**

1. Build and run the tests with the `ios-build-verify` skill, as `CLAUDE.md` describes. New logic
   gets Swift Testing tests that follow [`.claude/rules/testing.md`](../.claude/rules/testing.md).
   Read the `Test run with N tests` line and the per-suite times, not only the exit status.
   Question generation is random, so make the random source injectable (a seeded generator, as
   Konjugieren's `SeededRNG`) and test proportions with a fixed seed, not with luck. If the
   simulator's system language is not English, English-expecting tests fail; Konjugieren's later
   phases ran `xcodebuild -testLanguage en` for that reason. Say which way the suite ran.
2. For any visible change, launch the app and look at it on both Conjugar simulators, the iPhone
   and the iPad. Josh tries changes on an iPhone and leaves the iPad to the session, so the
   session's check is the only one the iPad gets. Exercise the phase's new states there too.
   Between the two devices, cover English and Spanish, light and dark, and both size classes, and
   say in **How it differed** what was tried on each.
   **Use only Conjugar's own simulators** (set up 2026-11-22 so that sessions on Conjugar and
   Conjuguer can run at once): "Conjugar iPhone 17" (`6318CA93-7FB5-4E19-B318-915010531F76`) and
   "Conjugar iPad Pro 11", an iPad Pro 11-inch (M5) (`3033197E-B596-4C49-AAD8-43373B9D254C`).
   Never use "Conjuguer iPhone 17" or "Conjuguer iPad Pro 11", which are Conjuguer's, or the plain
   "iPhone 17" and "iPad Pro 11-inch (M5)", which are kept for Konjugieren and other work.
   - `.claude/ios-build-verify.config.sh` sets `TARGET_SIM="${TARGET_SIM:-Conjugar iPhone 17}"`,
     so `build_app.sh`, `run_tests.sh`, and `launch_app.sh` use the iPhone by default. For the
     iPad, prefix the script: `TARGET_SIM="Conjugar iPad Pro 11" "$IBV_SCRIPTS/launch_app.sh"`.
   - `tap_tab.sh` uses the config's iPhone tab coordinates, so on the iPad tap by identifier
     (`tap_id.sh`) or by the frames `describe_ui.sh` reports.
   - Always name the UDID in `simctl` commands. With several simulators booted, `simctl openurl
     booted` reaches the wrong one.
   - Boot the iPad only for its check and shut it down afterward (`xcrun simctl shutdown
     3033197E-B596-4C49-AAD8-43373B9D254C`). This Intel Mac may be running two projects' builds
     and simulators at once.
   - If a simulator hangs, ask Josh before restarting CoreSimulator (`killall -9
     com.apple.CoreSimulator.CoreSimulatorService`), because that stops every simulator,
     Conjuguer's included.
   The quiz has a DEBUG launch default, `CONJUGAR_QUIZ_FIXTURE`, which today offers `screenshot`.
   Extend it with a named fixture per phase rather than tapping through random quizzes, and remove
   a fixture default from a simulator when done.
3. Localize every new string in English and Spanish, following `CLAUDE.md` and
   [`.claude/rules/localization.md`](../.claude/rules/localization.md). A new setting's description
   begins as the existing ones do. Strings used by `Shared/` code belong in the widget's catalog
   too.
4. VoiceOver: every new quiz state (a hold on a wrong answer, a second attempt, a diagnosis, a
   choice) needs an announcement that a learner who cannot see the screen can act on. Konjugieren's
   [`docs/voiceover.md`](../../Konjugieren/docs/voiceover.md) states the rules; one element speaks
   one language, so a Spanish form and an English explanation are separate elements.
5. Add analytics by the browse plan's convention (`docs/feature_architecture.md` § Analytics), and
   stage every new signal, parameter, or value in `docs/privacy_policy_pending.md` in both
   languages. **No new signal or parameter may carry an answer, a count of right or wrong answers,
   or which verb or item was asked.** Conjugar's quiz signals already send `score` and
   `elapsedTime`, which its policy discloses. Josh decided on 2026-11-22 that `score` stays only on
   the default quiz's ranked round and is sent by no other mode, and that Phase 6's duration bands
   replace `elapsedTime`. That a mode was started, quit, or finished, and from where, is fine.
6. Update [`docs/project_structure.md`](../docs/project_structure.md) for new, renamed, or
   repurposed files, and keep `docs/feature_architecture.md` § Quiz true (create the section in
   Phase 4 if the browse plan has not).
7. Fill in the Status row and the phase's Status line, write **How it differed**, and append a
   journal entry to `docs/blog_notes.md` (`## <Title> (YYYY-MM-DD)`, narrative, no em dashes
   between clauses).
8. **Stop before git.** Sessions do not commit, push, or create branches (`CLAUDE.md`). Tell Josh
   what changed and how to try it: which screens to open, and what to type or tap. He commits with
   his own skill. The next session records the hash.

**No release before 2027.** Josh cannot release Conjugar from his present MacBook until he replaces
it in 2027. Every phase accumulates on `master`. Nothing here reaches a learner or produces a number
until a release ships, so no phase should wait on evidence from another, and App Store Connect work
(Phases 7 and 22) prepares for that release. Write every step left for release day in
[`docs/release.md`](../docs/release.md), and every privacy-policy line in
`docs/privacy_policy_pending.md`.

**Conjugar only.** Konjugieren went first (its Decision 6). Another session is planning the same
work for Conjuguer. Where a choice here would make the three apps differ for no Spanish reason,
prefer Konjugieren's choice, which the Closing's porting notes will compare.

## Decisions Carried Over from Konjugieren

Josh's answers to the report's "Decisions for Josh" and his verdicts on its suggestions are the
defaults here. He may overrule any of them for Conjugar when he reviews this plan.

- **Practice, not examination** (Decision 2). Where a choice between the two arises, choose
  practice.
- **The leaderboard is re-scoped by level** (Decision 4), in Phase 7.
- **No accuracy signals** (Decision 5): nothing new reports how well a learner did. Conjugar's
  existing `score` stays on the default quiz's ranked round only (below). The practice record is
  kept on the device and sent nowhere.
- **The arcade game is left as play** (Decision 7, T6.9). Toreo por Amor does not conjugate.
- **Schools are a channel** (Decision 8), but mostly Conjuguer's, whose Swiss institution bought
  more than half its downloads. Phase 9 is therefore taken last here, after Phase 23, if at all.
- **The sad trombone stays** on quitting, because it is fun and silly (T6.4).
- **Levels are chosen, not earned.** What a learner has opened does not shape quizzes (T2.4's
  "No"). The learner picks a level, and nothing unlocks.
- **The default quiz is the classic quiz, modified** by this plan (levels, frequency bands, ten
  questions). Scopes are choices beside it, not replacements (T2.8).
- **Re-ask a missed question once, not until correct** (T3.1).
- **A right second attempt earns half points** (T1.6).
- **No "principal parts" label** anywhere, in the interface or in code names. A verb's key
  conjugations stand alone, as in "tener: tengo · tuve · tendré · tenido" (the set is the browse
  plan's Phase 9 decision).
- **Only a default session's first ten questions rank** (Konjugieren Phases 7 and 8). Scoped,
  custom, and practice sessions never post a score.
- **Claude drafts authored content, a machine check confirms every form against the engine, and
  Claude rereads every item** (Josh's final rule for Konjugieren's Phase 18 second batch and Phase
  19). Josh reviews the first batch of each kind; after that, ask whether he wants to keep
  reviewing. He asked for American English in the English lines.

**Decided for Conjugar (Josh, 2026-11-22).** Josh accepted every recommendation this plan made when
he reviewed it. Each is written into its phase:

- **The score signal** (step 5 above, Phases 6 and 11): `score` is sent only with the default
  quiz's ranked round, and by no other mode; record sessions, the speed round, and mixed model
  practice send neither `score` nor counts. Phase 6's duration bands replace `elapsedTime`.
- **The levels** (Phase 4): the draft ladder, with Easy migrating to Level 2, Moderate to Level 3,
  Difficult to Level 4, and a new install starting at Level 1.
- **The verbs asked** (Phase 5): drawn from the engine's per-cell irregularity within the band,
  with `VerbFamilies` kept as a test oracle.
- **Practice sets** (Phase 9): taken last, after Phase 23, if at all.
- **The kinds of practice item** (Phase 10): an irregular verb's key conjugations and a regular
  pattern, as that phase sets out.
- **The two imperfect subjunctives** (Phases 0 and 13): neither is accepted for the other, and
  Phase 13 names the swap.

## Where Conjugar's Quiz Starts

What the code does on 2026-11-22, read for this plan, plus what Konjugieren's report observed in
Conjugar on 2026-11-13 (its section "Conjugar and Conjuguer").

- **The session** (`Models/Quiz.swift`, `Views/QuizView.swift`, `Views/ResultsView.swift`) is 30
  typed questions, no retry, no re-asking, no memory. Questions are `(verb, DisplayTense,
  DisplayPersonNumber)` tuples drawn from hand-curated lists (`Models/VerbFamilies.swift`) through
  shuffled `Cycler`s, with persons rotated evenly.
- **Three difficulties**, stored as `Settings.difficulty`, default Easy: Easy asks the presente,
  futuro, and pretérito, ten each, five regular and five irregular; Moderate asks ten tenses plus
  the gerundio and both imperatives, with fixed per-tense counts; Difficult asks the simple tenses
  plus five of the nine compound tenses.
- **Grading** is `ConjugationResult.compare`: 10 points for an exact match (case-insensitive), 5 for
  a match after folding accents and ü, 0 otherwise. An accent error earns half credit **even where
  the accent marks another tense** (hablo for habló). ñ is strict. Answers are not trimmed, so a
  trailing space is wrong. A leading pronoun ("yo hablo") is wrong.
- **What is never asked.** With the tú setting, the regular tú imperative and every tú negative
  imperative (no hables) are never asked, because every general imperative draw skips tú
  (`personNumber(skipYo:skipTu:)`). The negative imperative must be typed with its "no", and
  nothing on screen says so. Imperative questions show the pronoun "él" or "ellas" where the form
  asked is usted's or ustedes'.
- **Region and vos.** `Settings.region` (default Latin America) drops vosotros questions there;
  `Settings.secondSingularQuiz` asks tú or vos.
- **Feedback** shows below the field after each answer, while the next question is already on
  screen, so the correction for question n sits under question n + 1 with the clock running.
- **Score** is the sum of points, normalized to 50 questions (`Quiz.scoreScale`, kept when the quiz
  dropped from 50 to 30 so old leaderboard entries stayed comparable), times a region modifier
  (Latin America 0.833) and a difficulty modifier (0.5, 1, 1.5). The defaults cap a perfect run at
  208. One Game Center leaderboard mixes every combination, and `QuizView.finish()` presents it
  automatically.
- **Analytics:** `startQuiz` (`difficulty`), `quitQuiz` (`difficulty`, `elapsedTime`,
  `questionNumber`, `score`), `completeQuiz` (`difficulty`, `elapsedTime`, `score`), and
  `viewResultsView`. The policy (`docs/privacy_policy3.txt`) discloses the score and elapsed time.
- **Elsewhere:** a Live Activity (`QuizActivityAttributes`, carrying the difficulty);
  `ChangeDifficultyTip` after a first finished quiz; the onboarding quiz page; the Quick Quiz
  control and the `conjugar://quiz` link, which start a quiz at once; and the quiz widget, whose
  daily question is the verb of the day in one of six tenses with three distractors.
- **A trap:** the Info tab's filter (`Settings.infoDifficulty`, default Difficult) uses the same
  `Difficulty` enum, and every Info article has a difficulty. Phase 4 must decouple the two.
- **What Konjugieren's report credits Conjugar with:** fixed per-tense quotas and a regular and
  irregular mix are most of Tier 2, done by hand, and Conjugar is the app where quizzes get
  finished. Its "regular" lists include verbs the engine treats as non-base models (buscar, leer,
  romper).

## What the Browse Plan Leaves for This One

**Reconciled by the browse plan's Closing (2026-11-22).** The browse plan is finished, and every
piece below is built on `master`. Each bullet's first sentences are what this plan expected; the
*Landed* lines under it are what the browse session that built it found, checked against the code at
the Closing. Where an expectation and a *Landed* line disagree, the *Landed* line wins, and
[Expectations That Did Not Hold](#expectations-that-did-not-hold) at the end of this section lists
each disagreement. The browse plan's **How it differed** notes have the detail.

**Built on `master`, by code name:**

- **Grading.** `Quiz.grade(_:infinitive:tense:personNumber:writtenAnswer:)` trims, collapses runs of
  spaces, and accepts a reflexive-only verb's form with or without its pronoun. `Quiz.results`
  holds each grade, so the results screen does not regrade. A question is still the tuple
  `Quiz.Question`.
- **Folding.** `VerbSearch.fold` folds accents and ñ, for search only. `ConjugationMatch`'s
  `.folded` folds acute accents and the diaeresis and keeps ñ strict, the narrower rule grading
  wants.
- **Edit distance.** `VerbSearch.editDistance(_:_:)` (optimal string alignment, over
  `[Character]`), and a bounded byte version, `editDistance(_:_:limit:)`.
- **Which cell is this text?** `ConjugationMatch.cells(of:equalTo:accents:)`, over every displayed
  cell, compounds and negative commands included.
- **The map and reverse lookup.** `ConjugationMap.bundled` (one-word forms only) and
  `ConjugationIndex.bundled`, built by `ConjugationMapTool`; `FormLookup.forms(for:index:)` for
  pronouns, enclitics, and compounds, with search's folding.
- **Key conjugations.** `KeyConjugation` (four keys, each with its cell), `forms(of:)`, and
  `line(for:)`, all `nonisolated`.
- **The verb page's order.** `ConjugationTable`, from `docs/tense_frequency.md`; the quiz keeps
  `DisplayTense.conjugatedTenses`.
- **Links into a verb's world.** `VerbPagePush` and `.verbPageDestinations()`;
  `VerbRelations.shared` (`baseByVerb`, `rootByVerb`); `ModelInfo.row(for:)`.
- **Deeplinks.** The grammar in `docs/feature_architecture.md` § Deeplinks, with `URL`'s builders,
  `deeplinkQueryValue(named:)`, and `analyticsSource`.
- **The learner's record.** `LearnerVerbs` in `Shared/`, read through `Current.learnerVerbs`
  (`LearnerVerbStore`), with the optional `ReviewSchedule` on each entry for irregular verbs.
- **Scopes.** `QuizScope` (`verbs`, `questionCount`, `source`, `title`, `collectionKey`) with
  `.allVerbs`, `.myVerbs`, `.verbPage`, and `.collection`; `isRanked` and `startsLiveActivity`;
  `QuizSheet` for a scoped quiz in a sheet.
- **Bands and collections.** `FrequencyBand` (`.top100`, `.top300`, `.top1000`) with
  `VerbMapEntry.isIn(_:)` and `VerbMap.entries(in:)`; `VerbDraw`; `VerbCollection`, with the
  pattern tests `hasGoPresent`, `hasStrongPreterite`, `hasIrregularFuture`, and
  `hasIrregularParticiple`, shared as `conjugar://list/<key>`.
- **The letter keys.** `SpanishLetterKeyRow(insert:)`. Only the search field shows it.
- **Thirty is wired in.** `QuizScope.fullLength` (30) gates `isRanked`, `startsLiveActivity`, the
  `ChangeDifficultyTip` donation, and the full-length scoped draw in `Quiz`. Phases 4, 6, and 7 must
  revisit each.
- **Analytics.** `source` on `startQuiz`, `quitQuiz`, and `completeQuiz`, and `collection` on a
  collection's `startQuiz`, beside the `difficulty` the quiz signals already sent.

- **The accent key row** (browse Phase 0): á, é, í, ó, ú, ü, and ñ, with an `insert` closure so
  this plan's answer field can insert at the cursor. Only the search field shows it.
  - *Landed 2026-11-22 (browse Phase 0):* `Views/SpanishLetterKeyRow.swift`,
    `SpanishLetterKeyRow(insert:)`, with `SpanishLetterKeyRow.letters`. In the verb list it takes
    the sort picker's place while the search is focused, because a keyboard toolbar never
    appeared for the navigation bar's search field. On iPad, a key tapped while a field is empty
    can end that field's editing first; see the browse plan's Phase 0 note. Search folding is
    `VerbSearch.fold`, which drops ñ's tilde, so grading must not reuse it.
- **Folding and edit distance** (browse Phases 0 and 1): search folds ñ along with the accents,
  which is right for search and wrong for grading. Grading needs its own narrower rule (Phase 0 and
  Phase 3 here). An optimal-string-alignment distance exists for the search guess.
  - *Landed 2026-11-22 (browse Phase 1):* `VerbSearch.editDistance(_:_:)`, over `[Character]`,
    `nonisolated`, with insertion, deletion, substitution, and an adjacent swap each costing one.
    It compares whatever it is given, so grading can pass unfolded, accented text. The guess,
    `VerbSearch.closestVerb(to:in:)`, folds first and is for search only.
- **The conjugation map** (browse Phase 4) ships in the app, with a function that answers "which
  cells of this verb equal this text", exact by default and folding accents on request. Phases 3,
  13, and 16 here call it.
  - *Landed 2026-11-22 (browse Phase 4):* `ConjugationMatch.cells(of:equalTo:accents:)`
    (`Models/ConjugationMatch.swift`, `nonisolated`) returns the `ConjugationCell`s (a
    `DisplayTense` and a `DisplayPersonNumber`) of one verb whose form equals a text, in page
    order. It conjugates every displayed cell rather than reading the map, so compounds ("ha
    hablado") and negative commands ("no hables") count, which Phase 13's other-cell diagnosis
    needs. `.exact` is the default; `.folded` ignores acute accents and the diaeresis but keeps ñ
    strict, so Phase 3's question to Josh about ñ would change `foldingAccents(_:)`. Case and runs
    of spaces never count, and a reflexive-only verb matches with or without its pronoun. It costs
    about 150 engine calls, fine once per answer. The map itself (`ConjugationMap.bundled`, one-word
    forms only) is for search.
- **Reverse lookup** (browse Phase 5) strips pronouns and handles compounds, which Phase 16's
  prompts and Phase 13's diagnoses can reuse.
  - *Landed 2026-11-22 (browse Phase 5):* `FormLookup.forms(for:index:)` (`Models/FormLookup.swift`,
    `nonisolated`) returns, per infinitive, the `MatchedForm`s a text is: the app's spelling, the
    cells in page order, and whether it matched only after folding. It drops a leading subject
    pronoun (narrowing the persons), a leading "no", and object pronouns; splits up to two enclitics
    from a command, gerund, or infinitive (dímelo, vámonos, levantaos), confirming each by rejoining
    it with `FormLookup.attach(_:to:at:)`; reads hecha, rotos as participles; and confirms
    compounds through `ConjugationMatch`. Its folding is search's (`VerbSearch.fold`, ñ included),
    so it suits finding a verb, not grading. `MatchedForm.cellNames(hiding:)` names cells as the
    result rows do ("Presente de Subjuntivo (yo, él) · Imperativo Positivo (usted)").
    `VerbSearch.editDistance(_:_:limit:)` is a bounded byte version of the distance.
- **The tense count** (browse Phase 6, `docs/tense_frequency.md`), which orders the verb page by use
  and is the best evidence for Phase 4's ladder and weights.
  - *Landed 2026-11-22 (browse Phase 6):* `docs/tense_frequency.md` and `scripts/count_tenses.py`,
    which reads `ConjugationMapTool --cells-json` (every one-word form with its cells). The table
    gives each tense's share of verb words per folder (government, literature, technology), by
    register (official prose and literature weighed equally, the order Josh chose), by folder, and
    pooled. By register: presente 42.9%, imperfecto 14.4, pretérito 12.3, presente de subjuntivo
    9.4, futuro 8.6, then condicional, the two imperfectos de subjuntivo, and the imperativo
    positivo near 1.2 each; the perfecto de indicativo is 4.8 and the pluscuamperfecto 1.5. The
    folders disagree sharply (the pretérito is 4% of official prose and 21% of the novels), so a
    ladder should say which register it serves. `ConjugationTable` (`Models/`) holds the page order
    only; the quiz keeps `DisplayTense.conjugatedTenses`. `ConjugationMatch.allCells`, which
    `cells(of:equalTo:)` filters, now lists cells in the page's new order.
- **The reflexive display** (browse Phase 3, accepted 2026-11-22): the quiz must accept a
  reflexive-only verb's form with and without its pronoun (Phase 0), and the frame shows the
  pronoun (Phase 1).
  - *Landed 2026-11-22 (browse Phase 3):* `TenseBridge.conjugate(…, pronoun: .written)` returns a
    reflexive-only verb's form with its pronoun (me arrepiento, arrepiéntete, no te arrepientas);
    the default `.omitted` stays bare. `ReflexivePronoun` (`Models/`) holds the placement, the
    enclisis accent rule (`enclitic(_:attachedTo:droppingLast:)`), and `citationForm(of:)`.
    `Quiz.grade(_:infinitive:tense:personNumber:writtenAnswer:)` already accepts both answers and
    collapses runs of spaces, and `Quiz.results` holds each grade so the results screen no longer
    regrades. The quiz question shows the citation form (arrepentirse) and the shown answer has the
    pronoun. No quiz list holds a reflexive-only verb today, so nothing a learner meets changed;
    Phase 0 and Phase 1 here should keep calling `grade` and `.written` when they rebuild grading
    and the frame.
- **The periphrasis article** (browse Phase 7, on ir a + infinitivo and estar + gerundio), which
  Phase 18's choice between the
  futuro and ir a + infinitivo could link.
  - *Landed 2026-11-22 (browse Phase 7):* the article is `Info` "Perífrasis Verbales", key
    `perifrasis_verbales`, in the Tenses section after Raíz Futura. Its section "Ir a or the Futuro?"
    ("¿Ir a o el futuro?") covers register, conjecture, commands, and iba a against the condicional,
    which is what Phase 18's choice would link to. Articles are addressed by `stableKey`
    (`Info.infos.first { $0.stableKey == … }`, as `ConjugationTable.article` does) until browse
    Phase 10 gives Info a deeplink.
  - *Landed 2026-11-22 (browse Phase 10):* `conjugar://info/perifrasis_verbales` opens it, built
    with `URL.infoDeeplink(stableKey:)`; `Info.info(deeplinkTarget:)` resolves a key.
- **The model link and related verbs** (browse Phase 8), which Phase 2's correction links reuse.
  - *Landed 2026-11-22 (browse Phase 8):* a verb page's pill pushes its `ModelInfo` (found by
    `ModelInfo.row(for:)`), and a correction link can push the same way: any view under the Verbs or
    Models stack reads `@Environment(\.verbPagePush)` and pushes a `VerbDestination`, a `ModelInfo`,
    or a `RelatedVerbListDestination`. A stack elsewhere (the Quiz tab) must inject `VerbPagePush`
    and call `.verbPageDestinations()` before a pushed verb page's pill and card work there; without
    it the pill is plain text and the card is hidden. For T2.2, `VerbRelations.shared.baseByVerb`
    says whether a verb is a prefixed compound (976 are), and `rootByVerb` gives its root.
- **Key conjugations** (browse Phase 9): four, tengo · tuve · tendré · tenido (Josh, 2026-11-22),
  and a function returning them. Phases
  10, 14, 15, and 19 build on it.
  - *Landed 2026-11-22 (browse Phase 9):* `KeyConjugation` (`Models/KeyConjugation.swift`), an
    enum of `yoPresente`, `yoPretérito`, `yoFuturo`, and `participio`, each with its cell (`tense`,
    `personNumber`), so Phase 10's mapping can say which key a cell falls under by case.
    `KeyConjugation.forms(of:)` returns `[KeyConjugation.Form]` (key plus the engine's mixed-case
    form: tenGo, tUVE, tenDré, tenido), leaving out a form the engine cannot give (abolir has no yo
    presente). A reflexive-only verb's forms carry their pronoun (me arrepiento); grading that
    accepts the bare form needs its own rule, as Phase 3 of the browse plan found for the quiz.
    `line(for:)` gives the lowercased "tengo · tuve · tendré · tenido". All `nonisolated`.
- **The deeplink grammar** (browse Phase 10, `docs/feature_architecture.md` § Deeplinks). Phases 9,
  21, and 23 add quiz targets under it.
  - *Landed 2026-11-22 (browse Phase 10):* the grammar and route table are in that section. The
    `quiz` route still starts a quiz for any target (`quiz/start` by convention), so a new quiz
    target (`set`, `daily`, `challenge`) must be matched before that fallback in
    `AppRouter.handle(url:)`; read its text with `url.deeplinkQueryValue(named:)` and `source` with
    `url.analyticsSource`, and add a builder beside `URL.searchDeeplink`. `finishSearch` now carries
    `source`, and `SearchTracker.fieldOpened(from:)` is how a new surface that opens the search names
    itself.
- **The learner's record** (browse Phase 12): `LearnerVerbs` in `Shared/`, recents, stars, and the My
  Verbs filter.
  - *Landed 2026-11-22 (browse Phase 12):* `LearnerVerbs` (`Shared/LearnerVerbs.swift`,
    `nonisolated`, Codable) keys an `Entry` by bare infinitive (arrepentir, not arrepentirse): first
    and last opened, `openCount`, and the date starred. `starred`, `recent(limit:)` (20 by default),
    and `myVerbs` (starred, then recent unstarred) answer in infinitives. The app reads it through
    `Current.learnerVerbs`, a `LearnerVerbStore` (`Models/`, `@Observable`) that answers in
    `VerbMapEntry`s and saves each change as JSON in the App Group's defaults
    (`WidgetConstants.sharedDefaults`, key `LearnerVerbs.storageKey`), so the widget can decode it
    with `LearnerVerbs(json:)`. **A field added to `Entry`, such as a due date or a practice box,
    must be optional**, or every record written before it decodes as nothing;
    `LearnerVerbsTests.anEntryWithoutItsOptionalFieldsDecodes` pins this. An open is recorded where
    `viewVerbView` is sent with any source but `resume`. Phase 10 here may prefer to keep its
    practice record beside this one, as Konjugieren's `PracticeRecord` is, rather than in it.
- **A scoped quiz** (browse Phase 13): `QuizScope`, Test Me in a sheet, a My Verbs scope on the Quiz
  tab, `source` on the three quiz signals, and the rule that scoped quizzes do not rank.
  - *Landed 2026-11-22 (browse Phase 13):* `QuizScope` (`Models/QuizScope.swift`, `nonisolated`):
    `verbs` (nil for every verb, else bare infinitives), `questionCount`, `source`; `allVerbs`,
    `allVerbs(source:)` (a `quiz` link), `myVerbs(_:)`, `verbPage(_:)`; `QuizScope.fullLength` is
    30, and `isRanked` (every verb, full length) gates both the Game Center report and the
    leaderboard shown at the end. `Quiz.start(scope:)` returns false when a scope gives no question.
    The difficulty's plan is `Quiz.standardQuestions()`, unshuffled; a full-length scoped quiz keeps
    its tenses and persons and fills the slots with the scope's verbs in turn, and a shorter one
    takes distinct cells one tense at a time. Both skip cells the engine does not give (defective
    verbs) and follow the tab's tú/vos and vosotros rules (`scopedPersonNumbers(for:)`). A question
    is still a tuple, `Quiz.Question`, so Phase 0's question type replaces it. Test Me opens
    `QuizSheet` (`Views/QuizSheet.swift`) with its own `Quiz`; `QuizView(quiz:sheetScope:)` and
    `ResultsView(quiz:)` take their quiz. Only a full-length quiz starts the Live Activity
    (`Quiz.hasLiveActivity`) or counts toward `ChangeDifficultyTip`. `startQuiz`, `quitQuiz`, and
    `completeQuiz` carry `source` (`tab`, `myVerbs`, `verbPage`, or a `quiz` link's own, `deeplink`
    by default; `AppRouter.pendingQuizStart` is an `AnalyticsSource?`). The Quiz tab's start screen
    is Konjugieren's redesign (scope symbol, picker, three tiles: questions, difficulty, region), which
    Phases 4 and 8 here will rework when levels replace the difficulties and the learner chooses a
    scope.
- **Frequency bands** (browse Phase 14): top 100, 300, and 1,000, defined once.
  Landed 2026-11-22 (browse Phase 14): `FrequencyBand` (`Models/FrequencyBand.swift`, `nonisolated`)
  with `VerbMapEntry.isIn(_:)` and `VerbMap.entries(in:)`, most frequent first. `VerbDraw` draws the
  widget's verb and random verbs from `.top1000` and My Verbs; the quiz widget's verb is therefore
  that draw's, and its question sampling is unchanged (pedagogy Phase 23's). `SplitMix64` is now
  `nonisolated` and seeds the widget's daily draw, so a seeded generator for the quiz can reuse it.
- **The review card's schedule** (browse Phase 15): a box and a due date on the 1, 3, 7, 14, and 30
  day ladder, in `Shared/`, for irregular verbs only (Josh, 2026-11-22). Phase 10 here absorbs it.
  Landed 2026-11-22 (browse Phase 15): `ReviewSchedule` (`Shared/ReviewSchedule.swift`,
  `nonisolated`, Codable), a `box` and a `due` date with `lookedUp(at:calendar:)`,
  `revealed(at:calendar:)`, `dismissed(at:calendar:)`, and `isDue(at:)`; due dates fall at the start
  of a day. It is the optional `review` on `LearnerVerbs.Entry`, so Phase 10 here can move it into
  the practice record or generalize it (Konjugieren's later version adds `answered(correctly:)`,
  which moves up only when due, and `new(at:)`). Only irregular verbs are scheduled, as the verb
  page's pill counts them (`VerbDraw.isIrregular`, so buscar too): `LearnerVerbStore.isReviewable`
  decides and `LearnerVerbs.recordOpen(_:at:schedulesReview:)` obeys, so a regular verb's entry
  never has a `review` and nothing needs migrating. An open by any route but the card restarts the
  verb in box 0; an open with source `reviewCard` leaves it. A record written before Phase 15 is
  scheduled once as the store loads (`scheduleUnscheduledReviews(where:)`), not by a read-time
  fallback as in Konjugieren. `docs/feature_architecture.md` § The Review Card has the rules.
- **Collections** (browse Phase 16): fixed lists derived from the engine, and a bar on every model's
  page, shared as
  `conjugar://list/<key>`. Phases 8 and 15 here use them. *Landed 2026-11-22:* `VerbCollection`
  (`Models/VerbCollection.swift`, `nonisolated`) holds the top 100, four pattern lists (base verbs of
  the top 1,000 only: -go, strong preterite, irregular future, irregular participle), and every
  model (`.model(classNumber)`, key `model-<class>`), most frequent first. The pattern tests are
  static functions of an infinitive (`hasGoPresent`, `hasStrongPreterite`, `hasIrregularFuture`,
  `hasIrregularParticiple`), which Phase 5's draw can ask of any verb; `VerbCollectionTests` already
  uses `VerbFamilies` as their oracle, as Phase 5's decision wants. A collection's quiz is
  `QuizScope.collection(_:title:)`: thirty unranked questions in `QuizSheet`, in the difficulty's
  tenses (a -go verb may be asked its pretérito; a collection does not yet steer the tenses), with
  `title` and `collectionKey` on `QuizScope`. It starts no Live Activity
  (`QuizScope.startsLiveActivity`), because it runs in a sheet over a quiz the tab may hold; Phase 6's
  Ten More should keep that. `docs/feature_architecture.md` § Collections has the design.
- **`docs/privacy_policy_pending.md` and `docs/feature_architecture.md`** (browse Phase 2). Landed
  2026-11-22: both exist. `AnalyticsSource` in `Analytics.swift` already holds `tab` and
  `verbPage` for the quiz signals' `source`, and `AnalyticsBand` is where new bands (the quiz's
  duration bands, pedagogy Phase 6) belong. The quiz signals send `source` since browse Phase 13.

### Expectations That Did Not Hold

Found at the browse plan's Closing (2026-11-22), by comparing the expectations above, and this
plan's phases that lean on them, with what landed.

- **The key row inserts nowhere by itself.** `SpanishLetterKeyRow` hands its caller the letter, and
  the search appends it; nothing inserts at a cursor yet. Nor has the row ever sat in a keyboard
  toolbar: a toolbar never appeared for the navigation bar's search field, so it replaces the sort
  picker instead. T1.4's row above the quiz's keyboard is therefore new work. The answer field is
  an ordinary `TextField`, where a keyboard toolbar may behave, and inserting at the cursor needs a
  text selection binding.
- **Trimming is already done.** "Where Conjugar's Quiz Starts" says answers are not trimmed, and
  Phase 0 asks to trim and collapse spaces. Since browse Phase 3, `Quiz.grade` does both. Phase 0
  keeps the job of stripping a subject pronoun.
- **The map is not the whole answer for Phases 3, 13, and 16.** The map holds one-word forms only,
  bare (arrepiento, never me arrepiento), and no compound or negative command. Grading and
  diagnosis therefore call `ConjugationMatch`, which conjugates the verb's every cell, rather than
  the map. Phase 16's recognition can draw its forms from the map, but a prompt such as "ha hablado"
  or "no hables" must come from `ConjugationMatch` or `FormLookup`.
- **Reverse lookup's folding is not grading's.** `FormLookup` folds ñ, as search does. Phase 13's
  diagnoses should take a verb from it only when the question's verb is not already known, and
  otherwise ask `ConjugationMatch` with `.exact`, then `.folded`.
- **Key conjugations are not always four, and may carry a pronoun.** abolir's set has three, and a
  reflexive-only verb's set reads "me arrepiento · me arrepentí · me arrepentiré · arrepentido".
  Phase 14's exercise needs a rule for each: a missing key is not asked, and a bare answer is
  accepted as `Quiz.grade` accepts one.
- **The review schedule is narrower than Konjugieren's.** Its operations are `lookedUp`,
  `revealed`, and `dismissed`; Konjugieren's later `answered(correctly:)` and `new(at:)` were not
  ported, so Phase 10 adds them. It lives on `LearnerVerbs.Entry`, not in a practice record of its
  own. Records from before browse Phase 15 were scheduled once as the store loaded, so Phase 10's
  migration meets only irregular verbs' schedules.
- **A collection does not steer the tenses.** A collection's quiz asks the difficulty's tenses, so
  a -go verb may be asked its pretérito. The pattern lists hold base verbs of the top 1,000 only;
  a model's collection holds every verb of the model. Phases 8 and 15 should decide whether a
  pattern collection asks its pattern's tenses.
- **The `VerbFamilies` oracle covers three lists, not all.** `VerbCollectionTests` checks the
  derivations against the irregular future, preterite, and participle lists. The derivations leave
  out ser, ir, and dar, which the preterite list holds for the quiz but which are not strong.
  Phase 5's draw needs its own oracle for the lists it replaces beyond those three.
- **Correction links need the Quiz tab to opt in.** T4.5's links to a verb's page and its model's
  page work only under a stack that injects `VerbPagePush` and calls `.verbPageDestinations()`.
  The Quiz tab's stack does neither yet.
- **Two quiz surfaces share a source.** The Quick Quiz control and the Start a Quiz shortcut both
  run `OpenQuizIntent` and report `deeplink`. Telling them apart takes a second intent, as Random
  Verb has.
- **`docs/feature_architecture.md` has no § Quiz.** The browse plan wrote § The Scoped Quiz. Phase 4
  should grow it into § Quiz, or create § Quiz beside it, as step 6 of How to Work This Plan says.
- **"Where Conjugar's Quiz Starts" predates browse Phases 3 and 13.** Besides trimming, the start
  screen lost its graduation cap and pills to Konjugieren's redesign (a scope symbol, the All Verbs
  / My Verbs picker, and three tiles), and the quiz signals now carry `source`. The section's
  account of the session, the difficulties, the score, and what is never asked still holds.

## Suggestion Index

The IDs and verdicts are Konjugieren's, from its plan's index. The Conjugar column says where each
lands here, and what differs.

| ID | Suggestion | Konjugieren verdict | Conjugar phase |
|---|---|---|---:|
| T1.1 | Decide the separable-verb convention | Accept both | Browse Phase 3's reflexive analog |
| T1.2 | Show the shape of the expected answer | Yes | 1 |
| T1.3 | Strip a leading pronoun before grading | Yes | 0 |
| T1.4 | Accept digraphs; letter keys on the answer field | Yes | 0 (accent keys) |
| T1.5 | Audit optional variants and accept every standard one | Yes | 0 |
| T1.6 | A one-letter slip is "almost", with one more attempt | Yes, half points | 3 |
| T2.1 | Draw from frequency bands | Yes, by level | 5 |
| T2.2 | Prefer base verbs | Yes, one to three derivatives a quiz | 5 |
| T2.3 | Levels ordered by use, replacing the difficulties | Yes | 4 |
| T2.4 | Weight a newly opened tense | **No** | Not built |
| T2.5 | Guarantee a mix; the core verbs recur | Yes | 5 |
| T2.6 | Thin the auxiliary-only tenses | Yes | 4 |
| T2.7 | Ten questions, with an offer to continue | Reluctantly, yes | 6 |
| T2.8 | Learner-chosen scope | Yes | 8 |
| T2.9 | A scope shareable as a link or QR code | Yes | 9 (lower priority) |
| T3.1 | Re-ask a missed question | Re-ask once | 6 |
| T3.2 | Practice my mistakes | Yes | 11 |
| T3.3 | A box and a due date per item, and a Review session | Yes | 10, 11 |
| T3.4 | A ladder of 1, 3, 7, 14, and 30 days | Yes | 10 |
| T3.5 | Kinds of item | Yes | 10 |
| T4.1 | Stay on a missed question until Continue | Yes | 2 |
| T4.2 | Diagnose the error in one templated line | Yes | 13 |
| T4.3 | Prompt a repair before revealing | Yes | 13 |
| T4.4 | Mark where the answer differs | Yes | 2 |
| T4.5 | Link the correction to the verb's page and model | Yes | 2 |
| T4.6 | A language model that words a diagnosis | **Not at this time** | Not built |
| T5.1 | A key-conjugations exercise | Yes | 14 |
| T5.2 | Group practice, one then mixed | Yes | 15 (models) |
| T5.3 | Test yourself on this verb | Yes | Browse Phase 13 |
| T5.4 | Recognition questions | Yes | 16 |
| T5.5 | Sentence frames for the core verbs | Yes | 17 |
| T5.6 | Choice questions between two tenses | Yes | 18 |
| T5.7 | A speed round over mastered items | Yes | 20 |
| T6.1 | The Quiz tab as a practice hub | Yes | 12 |
| T6.2 | Show mastery | Yes | 19 |
| T6.3 | A daily session, a repairable streak, a reminder | Yes | 21 |
| T6.4 | Keep partial work | Partial: the trombone stays | 10 |
| T6.5 | Hide the clock by default | Yes, as a setting | 6 |
| T6.6 | Leaderboard out of the main path; bests and achievements | Yes | 12, 22 |
| T6.7 | Rename the levels | Yes | 4 |
| T6.8 | A daily shared challenge | Yes | 23 |
| T6.9 | Make the arcade game conjugate | Outside this project | Not built |
| M1 | Send the level with `startQuiz` | Built | 4 (Conjugar already sends the difficulty) |
| M2 | Report the question reached by a quiz abandoned by leaving the app | Built | 6 |
| M3 | Report the time from start to quit in bands | Built | 6 |
| M4, M5 | Questions answered and correct; accuracy by interval | **No** | Not built |

## Phase 0: Accept What Is Right

**Ports:** Konjugieren Phase 1. **Suggestions:** T1.3, T1.4, T1.5, and two Conjugar defects.
**Depends on:** nothing. **Status:** Done.

- **Trim the answer.** Neither sibling trims whitespace, so a trailing space is wrong today. Trim
  and collapse runs of spaces before grading.
- **T1.3.** Strip a leading subject pronoun before grading, so "yo hablo" passes. Strip only a
  pronoun that matches the question's person: yo; tú or vos, whichever is asked; él, ella, or
  usted; nosotros or nosotras; vosotros or vosotras; ellos, ellas, or ustedes. Strip nothing in
  front of an imperative except what Phase 1's frame decides.
- **T1.4.** Show the browse plan's accent key row above the keyboard while the answer field is
  focused, inserting at the cursor. German needed digraphs accepted (ue for ü); Spanish has no such
  convention, so a missing accent stays wrong here and Phase 3 makes it a near miss.
- **T1.5.** Audit optional standard forms and accept each one Josh rules standard. Candidates:
  participle doublets (freído and frito, imprimido and impreso, proveído and provisto); the forms
  the 2010 *Ortografía* stripped of their accent (rio and rió, guio and guió, fie and fié, crie and
  crié), which a learner taught either way may type; the vosotros imperative of irse (idos) and of
  other pronominal verbs; and any alternate forms the engine already models (`conjugateAll`). Check
  each against the RAE's *Diccionario de la lengua española* conjugation tables or the
  *Diccionario panhispánico de dudas*.
- **The reflexive forms**, if the browse plan's Phase 3 was built: accept a reflexive-only verb's
  form with or without its pronoun.
- **Conjugar's other defect: what is never asked.** Fix the person rotation so that, with the tú
  setting, regular tú imperatives and tú negative imperatives are asked as often as other persons.

**Ask Josh:** before accepting any variant, show the audited list with its sources and let him rule
on each. Variants become accepted answers only, not new forms on the verb page, unless he says
otherwise.

**Decided (Josh, 2026-11-22):** the -ra and -se imperfect subjunctives do not accept each other,
since the quiz names them as separate tenses ("Imperfecto de Subjuntivo 1" and "2"). Phase 13 names
the swap.

**From Konjugieren:**

- Grading moved into one place (`QuizItem.accepts` there), which every later phase extends. Do the
  same now; Conjugar's tuples and `ConjugationResult` are the place to start.
- Expanding the accepted answers (every acceptable spelling of each answer) was safer than folding
  the learner's answer, because a fold applied to both sides accepts misspellings.
- The audit was its own file (`plans/pedagogy_phase1_variant_audit.md` there), with method, links
  per row, and Josh's rulings. Wiktionary alone was wrong twice against Duden; check more than one
  source here too.
- A right answer typed another accepted way showed the canonical spelling quietly beside the check.
- The key row as a keyboard toolbar worked for an ordinary `TextField` with a hardware keyboard,
  where iOS drew it as a floating bar. The software keyboard was never tried; try it.

**Done when** "yo hablo", "  hablo ", and each ruled variant pass, a missing accent still fails, the
key row inserts at the cursor, tú imperatives are asked, and tests pin each.

**How it differed:**

- **Grading lives in `QuizQuestion`** (`Models/QuizQuestion.swift`), a `nonisolated` struct that
  replaces the `Quiz.Question` tuple (the typealias remains) and holds `writtenAnswer`,
  `acceptedAnswers`, `grade(_:)`, and `currentSpelling(of:)`. `Quiz.grade` is gone. Accepted
  answers are expanded, never folded: the written answer, a reflexive-only verb's bare form, and
  `StandardVariants` (`Models/StandardVariants.swift`). An answer right but for its accents keeps
  `.partialMatch`, so "a missing accent still fails" means "is not counted right" until Phase 3
  replaces partial credit. `ConjugationResult` became `nonisolated`.
- **The pronoun rule** (`Models/AnswerSpelling.swift`) strips any pronoun of the asked person, not
  only the one shown: él, ella, or usted; ellos, ellas, or ustedes; nosotros or nosotras. It also
  strips tú and él typed without their accents (tu hablas), since the pronoun is not what is asked.
  Nothing is stripped before a command, a gerundio, or a participio, pending Phase 1's frame.
- **The audit** is [`pedagogy_variant_audit.md`](pedagogy_variant_audit.md). rae.es refused
  scripted fetches, so a Sonnet research pass worked from search extracts. Josh accepted every
  recommended row, accepted the Río de la Plata's vos subjunctive (hablés, no hablés, hayás
  hablado; the DLE's table lists only hables, the DPD's voseo entry both), and had the unconfirmed
  rows checked in Chrome; all held, so desdeciré, palío, repatrio, historío, vidrío, proscripto,
  transcripto, and adscripto are accepted too.
- **The verb page changed, at Josh's ruling.** The engine wrote the pre-2010 accents (rió, guió,
  fiás, huí, riáis), which the RAE no longer admits. `Orthography.currentSpelling(of:)` (in
  `Conjugator.swift`, so `ConjugationMapTool` compiles it) now respells every composed form, and
  `Conjugator.conjugateAll` lists the retired spelling last, which is how the quiz still takes
  rió. ver's vos imperative is ve, not vé (a residue entry on ver's model). A right answer in the
  retired spelling shows the current one quietly beside the check, read by VoiceOver as "Correct.
  Spelled: rio" (`L.Quiz.correctSpelled`, the form tagged Spanish). Side effects, each handled:
  `TenseBridge` marks irregularity against both spellings of the regular baseline, since ir's
  bare ending áis became ais and marked VAYÁis; `VerbCollection.hasStrongPreterite` checks every
  spelling, since guie now ends in -e; oracle tests for reír and freír and the ve lookup tests now
  expect the new forms. Not handled: `Etymologies.json` writes "crió" in seven entries of Spanish
  prose, and the corpus pipelines' `forms.json` will hold the new spellings the next time they
  run, though older texts write rió. Both are Josh's to schedule.
- **The person rotation was worse than the tú skip.** One rotation over every tense fell into step
  with a quiz's length: in the Latin America region the Moderate quiz's commands met only nosotros
  and tú, quiz after quiz, and the other regions had the same kind of lock. Each tense now has a
  rotation of its own (`Quiz.personNumber(for:)`, drawn from `scopedPersonNumbers(for:)`, which the
  scoped draw already used), carried across quizzes and started at a random person when
  shuffling. Tú commands, negative ones included, are asked, and a scoped quiz asks tú or vos in
  a negative command too.
- **The key row** inserts at the cursor through a `TextSelection` binding. On the iPhone it is a
  keyboard toolbar on the quiz screen: above the software keyboard, or floating at the bottom with
  a hardware keyboard. Typing "ro", Left arrow, then í gave "río"; typing fu on the software
  keyboard and tapping í gave "fuí". iPadOS's keyboard showed no toolbar items at all, with either
  keyboard and either way of starting, so on the iPad (regular width) the row sits under the
  answer field instead; there a key tapped into an empty field inserted without ending editing,
  and "deber", á, "n" on the software keyboard scored deberán. Trying the software keyboard (with
  computer use, through Simulator's I/O menu) also found that a quiz started by a link, as the tab
  appears, focused the field before it was on screen, and the row never joined the keyboard. The
  question view now takes the focus again as it appears. **Left for Josh:** on the iPhone, the row
  above the software keyboard covers the score and clock line once a correction shows beneath the
  field. Phase 2's held correction rebuilds that area.
- **A fixture**, `CONJUGAR_QUIZ_FIXTURE grading` (`Quiz.Fixture`, which now also names
  `screenshot`): ten questions whose comments give an answer beside the shown one.
- **Verified:** 945 tests in 56 suites, in the simulator's default language (English). On the
  iPhone, in English and light mode, the fixture quiz scored the maximum with yo hablo, rió, yo he
  frito, no hables, arrepiento, satisface, predeciré, huí, adecúo, and ustedes tienen, and reír's
  page reads rio and riais. On the iPad, in Spanish and dark mode, with the software keyboard, the
  quiz started by link and by Start, with the keys under the field. VoiceOver's label on the spelling line was read from the
  accessibility tree, not spoken.
- **Analytics:** none added, so nothing is staged in `docs/privacy_policy_pending.md`.

## Phase 1: The Shape of the Answer

**Ports:** Konjugieren Phase 2. **Suggestions:** T1.2. **Depends on:** Phase 0. **Status:** Done.

Show the shape of the expected answer around the field, with the fixed words outside it: `yo [ ]`
for a finite form; `(tú) ¡[ ]!` and `(usted) ¡[ ]!` for an affirmative imperative, naming the
person asked; `no [ ]` for a negative imperative, which settles the "no" that must be typed today
and is nowhere said; `yo [ ]` for a compound tense, taking "he hablado"; no pronoun for the gerundio
or participio. If the browse plan's Phase 3 was built, a reflexive-only verb shows its pronoun where
Spanish puts it (`yo me [ ]`), and an affirmative imperative's enclitic is part of the answer. Fix
the imperative's displayed person at the same time: it shows "él" and "ellas" today where usted and
ustedes are asked. Vos questions show vos.

Build the frame as a component later question types reuse: Phase 14's blanks and Phase 17's
sentence frames are the same idea at a larger scale.

**Ask Josh** to choose among two or three mockups before building.

**From Konjugieren:**

- Josh chose inline rounded fields with the fixed words on the same line, and Return moving to the
  next empty blank. Spanish probably needs only one blank per question, which makes this simpler.
- **Key the frame's fields by blank index**, not by position or by question. Keying by position
  rebuilt the field when a pronoun appeared in front of it, and the keyboard lost focus.
- The frame's pronoun is not part of the graded answer, so a learner who also types the pronoun
  into the blank is still right (Phase 0's stripping).
- Each field's VoiceOver label reads the whole frame ("yo, blank"); the frame's other text is hidden.
- The screenshot driver types into the field by its identifier (`input_quiz_conjugation`); keep it,
  and check `scripts/take_screenshots.sh` still works.

**Done when** every tense and person shows a frame, the negative imperative's "no" is outside the
field, imperatives name usted and ustedes, VoiceOver reads the frame as one prompt, and tests pin
the frame for each kind of question.

**How it differed:**

- **Josh chose on 2026-11-23**, from three mockups: the fixed words inline on the field's line, as
  in Konjugieren (over a fill-in-the-blank caption above today's full-width field, and over the
  fixed words drawn inside the field's border).
- **One blank, always.** `AnswerFrame` (`Models/AnswerFrame.swift`, `nonisolated`) holds segments
  (`addressee`, `pronoun`, `word`, `punctuation`, `blank`) and `quizFrame(tense:personNumber:
  isReflexiveOnly:)`; `QuizQuestion.frame` builds it. A finite form, compound tenses included,
  shows its subject pronoun (yo, tú, vos, él, nosotros, vosotros, ellas, as the quiz showed
  before); a command shows `(tú) ¡[ ]!`, with usted and ustedes named for the third persons
  (`DisplayPersonNumber.commandAddressee`); a negative command supplies its "no"; the gerundio and
  participio show the field alone. A reflexive-only verb's pronoun is a supplied word before the
  blank (`yo me [ ]`, `(usted) ¡no se [ ]!`), and an enclitic is typed (arrepiéntete). Nothing
  here needed Return to move between blanks, so the multi-blank machinery Konjugieren built was
  not ported; Phase 14 and Phase 17 add it if they need it.
- **The answer a blank gives.** `QuizQuestion.answer(filling:)` drops a typed subject pronoun of
  the asked person, then `AnswerFrame.answer(filling:)` puts the frame's supplied words in front,
  without doubling any the learner also typed: "hables", "no hables", "te arrepientas", and "no te
  arrepientas" all become the right answer, and "¡habla!" loses its marks. What the quiz records
  and shows as "Your answer" is that composed answer (no hables), so the results read whole.
  "no arrepientas" typed into `¡no te [ ]!` is still wrong; nothing tolerates a frame word typed
  out of order.
- **The question card lost its person.** The tense line no longer reads "él · presente de
  indicativo", since the frame shows the person, so the "él" that misnamed usted's command is gone
  from the screen. `ResultsView` still labels rows 3S and 3P.
- **Accessibility text sizes.** At those sizes the frame's words would leave the field no width
  ("(nosotros) ¡no nos"), so they take a line of their own above the field. The layout switches
  between `HStackLayout` and `VStackLayout` through `AnyLayout`, and the field keeps its structural
  identity whether or not words precede it, so focus survives every change of frame. That is the
  Konjugieren focus bug's lesson; there was no ForEach to key.
- **VoiceOver.** The field's label reads the frame, its Spanish tagged Spanish: "yo, blank", "tú,
  no, espacio en blanco" (new `L.Quiz.blank`). A frame with no words keeps the old label,
  "conjugation". The frame's text is hidden. Read from the accessibility tree, not heard.
- **A fixture**, `CONJUGAR_QUIZ_FIXTURE frames`: 21 questions, one per kind of frame, each with its
  answer in a comment.
- **Verified:** 958 tests in 57 suites, in the simulator's default language (English). One failure,
  `GameStateTests.terremotoOpensGapsRoughlyTenPercentOfEachGirder`, is random and unrelated; that
  suite passed twice on rerun. On the iPhone, in English and light mode with a hardware keyboard,
  the fixture scored a perfect 208, typing only each blank's part (and "no sean" whole into `¡no
  [ ]!`); at accessibility-extra-large the pronoun sat above the field. On the iPad, in Spanish
  and dark mode, the frames drew beside the field with the keys under it, and the á key inserted
  at the cursor in `vos [ ]`. The software keyboard was not tried. `scripts/take_screenshots.sh`
  was not run: it still finds the field by `input_quiz_conjugation`, and its fixture's answers
  (he querido among them) still grade right in their frames, but the App Store's quiz screenshot
  will show the frame when next captured.
- **Found, not fixed:** a `quiz` link that arrives while the results screen is pushed starts a new
  quiz behind it, so the results of an unanswered quiz show until the learner goes back. That
  predates this phase.
- **Analytics:** none added, so nothing is staged in `docs/privacy_policy_pending.md`.

## Phase 2: A Correction That Stays

**Ports:** Konjugieren Phase 3. **Suggestions:** T4.1, T4.4, T4.5. **Depends on:** nothing; Phase 1
preferably. **Status:** Done.

Today `Quiz.process` advances before the view redraws, so the correction for question n appears
under question n + 1 while the clock runs.

- **T4.1.** After a wrong answer, stay on the missed question: its prompt, the learner's answer, the
  correct answer, and a Continue button, which Return also triggers. Pause the clock while the
  correction shows. After a right answer, advance at once.
- **T4.4.** Mark where the learner's answer differs. Red letters already mark what is irregular, so
  the difference needs a visibly different treatment, and an accent is a difference worth marking
  (habló against hablo). It must read sensibly to VoiceOver.
- **T4.5.** Link the correction to the verb's page and to its model's page (browse Phase 8).
  Opening one must not end the quiz; it pauses the clock and returns to the held question. In a
  quiz begun from a verb's own page, leave the verb link out.

The `feedbackReveal` rows under the next question are replaced, not supplemented.

**Ask Josh** to judge the layout of the held correction on a device-sized screen before polishing.

**From Konjugieren:**

- Show the nearest of the accepted spellings as the correct answer, and drop a leading pronoun from
  the learner's answer as grading drops it.
- The difference came from an alignment with the edit distance's costs. A missing letter has
  nothing to mark in the learner's answer, so it showed as an underlined letter of the right
  answer. Case is not a difference, so a red letter is never marked for being a capital.
- **Two focus bugs:** Return resigns a `TextField`, so a held question lost the keyboard and Return
  did nothing until the view refocused the field on holding; and after Back from a linked page,
  setting the focus state to the value it still held changed nothing, so it was cleared and set
  again once the pop finished.
- Pages pushed over a held question hid "Test me on this verb" and a collection's Quiz button
  (`isBeneathQuiz`), so there is no quiz inside a quiz. Phase 16 there later narrowed it to "while a
  quiz is in progress".
- A wrong last answer must show its correction before the results.
- VoiceOver moved focus to the correction ("Incorrect. Your answer: …. Correct answer: ….
  Letters that differ: …"), and a Magic Tap continued.

**Done when** a wrong answer holds with the clock stopped, Continue and Return advance, the
difference is marked accents included, both links work and return, and tests pin the state machine.

**How it differed:**

- **The layout is built, not yet judged.** The correction is a card under the answer field, where
  the old rows were: a line for half points when only accents differ, Your Answer and Correct
  Answer stacked under their labels, a row of two link capsules, and a full-width Continue capped
  at 400 points (`Views/QuizCorrectionView.swift`). The field keeps the learner's answer and the
  keyboard, so Return continues; it stays editable, and nothing typed there is graded. Josh has
  still to judge it on a device (the Ask Josh above). A right answer still shows its green check
  under the next question, with Phase 0's retired-spelling line; only the wrong-answer rows went.
- **A partial match holds too.** The phase says to hold "after a wrong answer". An answer right but
  for its accents (`.partialMatch`, 5 points) is the case T4.4 names (hablo for habló), so it holds
  with its half points already scored and the line "Half points: only the accent marks differ."
  Phase 3 replaces partial credit, and with it that line.
- **The state machine.** `Quiz.correction` (a `QuizCorrection`: the grade and an
  `AnswerDifference`) holds the question; `process(proposedAnswer:)` now returns only the
  `ConjugationResult`, stops the clock on any other than `.totalMatch`, and advances on a right
  answer; `continueAfterCorrection()` clears the hold, advances or finishes, and restarts the
  clock. Advancing and finishing moved into `advance()` and `finish()`. `isHeld` and
  `isClockRunning` let the tests read the state. A wrong last answer shows its correction before
  the results. The clock is stopped for the whole hold, so a visit to a linked page cannot run it.
- **The marking** is Konjugieren's `AnswerDifference`, ported (`Models/AnswerDifference.swift`). Its
  `QuizQuestion.difference(from:)` picks the nearest of a new `QuizQuestion.shownSpellings` (the
  accepted answers before lowercasing, so the written answer keeps its red letters and wins a
  tie); `acceptedAnswers` is now that list lowercased. The learner's answer is the composed one
  that Phase 1's frame gives (no hablas, me arepiento), so a frame's supplied words are never
  marked. Learner letters are struck through on a red tint, missing or wrong letters of the right
  answer underlined on a green one, and a red letter stays red. The red tint was raised from 0.25
  to 0.35 after the iPad's dark card made it faint.
- **The links.** The verb link opens the verb's page scrolled to the asked cell and marked (a
  `VerbDestination` with `marks`); the model link opens "Verbs Like cantar", the model's page,
  through a new `QuizCorrectionModel` so that it reports its own source, since the stack's
  `ModelInfo` destination is the pill's. The quiz's `NavigationStack` now has a path, injects
  `VerbPagePush`, and registers `VerbDestination`, `QuizCorrectionModel`, and
  `verbPageDestinations()`, in the tab and in `QuizSheet` alike. The verb link is left out of a
  quiz begun from that verb's page, as the phase says, and, not in the phase, the model link out of
  a quiz over that model's own collection. Opening a verb from a correction records an open in the
  learner's record and restarts an irregular verb's review in box 0, as any open but the card's
  does.
- **No quiz inside a quiz.** Not in the phase: `isBeneathQuiz`, true while a quiz is in progress,
  hides Test Me on a pushed verb page and the Quiz button on a pushed model's collection bar. This
  is the narrower rule Konjugieren reached in its Phase 16, used from the start.
- **Two focus bugs.** Return resigns the field, so the hold refocuses it, as in Konjugieren. The
  Back bug was different here: on the pop, UIKit gave the field its keyboard back without telling
  `@FocusState`, which read false, so setting it true did nothing and the field's border stayed
  grey while its cursor blinked. Logging the focus state showed it. `refocusAnswer(after:)` now
  clears the state and sets it again 50 ms apart once the pop has finished.
- **An isolation crash, found by the tests.** The `QuizQuestion` extension in
  `AnswerDifference.swift` took the app's default MainActor isolation, though the struct is
  `nonisolated`, and its closure trapped in `dispatch_assert_queue` when a nonisolated test called
  it. The test runner restarted after each crash and still exited green on the Swift Testing line,
  with `QuizCorrectionTests` never run; the 65 exit code and the "Restarting after unexpected exit"
  line gave it away. The extension is `nonisolated` now. An extension of an engine type in another
  file needs its own `nonisolated`.
- **VoiceOver.** Focus moves to the correction, which reads "Incorrect. Your Answer: hablo. Correct
  Answer: habló. Letters that differ: ó." (half points read in place of "Incorrect."; the letters
  only when three or fewer), with the answers tagged Spanish in one attributed label, and the hint
  "Swipe right for links to the verb, then Continue." Each link and Continue has a hint, and a
  Magic Tap continues. Nobody has listened to it.
- **A fixture**, `CONJUGAR_QUIZ_FIXTURE corrections`: eight questions, each with a wrong answer in a
  comment that shows one kind of marking (an accent, a red letter, a missing, extra, or swapped
  letter, a negative command's "no", the nearer of freído and frito, a compound).
- **Verified:** 976 tests in 59 suites, in the simulator's default language (English), 18 of them
  new (`AnswerDifferenceTests`, `QuizCorrectionTests`). On the iPhone, in English and light mode
  with a hardware keyboard, all eight fixture answers held and continued by Return; the clock stood
  still through a hold and through a visit to the verb's page; the verb page hid Test Me and marked
  tengo; the model page hid its Quiz button; Back returned the keyboard and a focused border; the
  last wrong answer held, then Return showed the results. On the iPad, in Spanish and dark mode, the
  hold drew beside the letter keys with Continue capped, and Test Me's sheet left out the verb link
  and pushed the model's page inside the sheet. Not tried: the software keyboard, so Phase 0's note
  that the key row covers the score line is unchecked against the new layout; accessibility text
  sizes; VoiceOver by ear.
- **Analytics:** one new value, `quizCorrection`, the `source` of `viewVerbView` and
  `viewCollection`, staged in `docs/privacy_policy_pending.md` as a new kind of surface for both
  bullets.


## Phase 3: One More Try

**Ports:** Konjugieren Phase 4. **Suggestions:** T1.6. **Depends on:** Phase 2. **Status:** Done.

Treat a slip as "almost" and allow one more attempt. A right second attempt earns half the points
(5 where a first attempt earns 10). A wrong second attempt goes to Phase 2's correction. **This
replaces `ConjugationResult.partialMatch`**, which gives half credit for any accent error at once.

- A slip is one edit by the edit distance, or a difference only in accents (any number of them, and
  ü), against any accepted spelling. Decide with Josh whether ñ for n is an accent slip; today ñ is
  strict.
- **An answer that is itself another cell of the verb is not a slip.** hablo for habló is one accent
  away and is the presente for the pretérito; canto for cantó and hable for hablé
  likewise. Check the browse plan's "which cells equal this text" first, exact and with accents
  folded, and treat a match as a real error, which Phase 13 names.
- A question gets at most one second attempt, whatever triggered it. Phase 13 adds diagnosable
  errors as a second trigger and must share this mechanism.
- The results list and the progress show which answers were right on the second attempt.

**Decided for Konjugieren (Josh, 2026-11-13), proposed here:** a slip earns a second attempt only in
an answer of four or more letters; a right second attempt is counted apart ("8 correct, 1 on the
second try") with its own color; and the first attempt stays in the field to edit.

**Ask Josh** to approve the wording of the "almost" line in both languages. Konjugieren's was
"Almost! Try once more."

**From Konjugieren:**

- The textbook slip there (a missing umlaut) turned out to be a person error in its commonest case,
  and the rule held: another cell is a real error. Expect the same here with accents, where the
  accent often is the tense.
- Count the four letters in the accepted spelling, spaces excluded, so compound answers never fall
  under the limit.
- `QuizItem.firstAttempt` held the slip, with no separate state on the quiz. Phase 13 set the same
  field for a diagnosed error.
- Feedback for a slip was a pop and a light tap, not the buzz of a wrong answer. The clock kept
  running, since the learner is still answering.

**Done when** a one-letter slip and an accent-only slip each prompt one more try, hablo for habló
does not, half points are scored and shown, and tests pin each case.

**How it differed:**

- **Josh chose on 2026-11-23**, taking every recommendation: Konjugieren's wording, "Almost! Try
  once more." / "¡Casi! Inténtalo una vez más.", with "Second Try" / "Segundo intento" and "First
  Try" / "Primer intento" in the results; ñ typed as n counts like a missing accent in deciding a
  slip (enseñaría typed ensenaria earns a second try), though grading stays strict; the
  four-letter limit applies to a one-letter slip only, so an accent-only slip earns a second try at
  any length (ire for iré, de for dé), since Spanish has many short accented forms and a missing
  accent is never a different letter; and a new count line on the results card, "Correct: 8 / 10 ·
  Second Try: 1", since the card showed no count before. Konjugieren's other two proposals were
  taken as written: a right second attempt is counted apart, and the first attempt stays in the
  field to edit.
- **The rule** (`Models/AnswerSlip.swift`). `AnswerSlip.isSlip(_:of:)` compares a normalized
  answer with each accepted spelling: equal once accents, the diaeresis, and ñ's tilde are dropped,
  or, where the accepted spelling has four letters or more (spaces excluded), one edit by
  `VerbSearch.editDistance`. `QuizQuestion.isSlip(_:)` then refuses any answer that is another
  cell of the verb, compared with accents and tildes ignored, through a new
  `ConjugationMatch.Accents.bare`. The cells whose forms are right answers for the question are
  subtracted first, since esté is yo's and él's presente de subjuntivo and usted's command, and
  este for esté is a slip of all three. The phase asked for the cells "exact and with accents
  folded"; the folded comparison is what catches comio for comí (comió, the wrong person), and
  enseno for enseñó turned out to be enseño, the presente, so the fixture uses the condicional for
  its ñ example. **Not caught:** a standard variant of another cell is not a cell the engine
  writes, so hablés (vos) typed for tú's hables is a slip and earns a second try.
- **The mechanism.** `ConjugationResult.partialMatch` became `.secondAttemptMatch` (still 5), and
  `ConjugationResult.compare` went, with the XCTest `ConjugationResultTests` that tested only it
  (`CLAUDE.md`'s list of XCTest suites is updated). `QuizQuestion.grade(_:)` now gives only
  `.totalMatch` or `.noMatch`. `Quiz.firstAttempt` holds the slip, as `QuizItem.firstAttempt` did
  in Konjugieren; `process(proposedAnswer:)` returns nil while a question waits for its second
  attempt and records nothing until the attempt that settles it. `firstAttempts` (parallel to
  `results`) keeps each slip for the results, and `secondAttemptCount` counts the half-point
  answers, which `correctCount` (and so the Live Activity's count) leaves out. **Phase 13** should
  set `firstAttempt` for a diagnosed error too, so the one-attempt limit holds whatever earned it.
  `QuizCorrection` lost its `result`, and the correction's half-points line and
  `L.Quiz.halfPoints` went with partial credit.
- **The progress.** Conjugar's progress is a bar with no per-question marks, so nothing there shows
  a second attempt. The results do: a half-filled yellow circle (labeled "Second Try" for
  VoiceOver), the count line, and a yellow "First Try:" line under the row's answer.
- **Feedback.** A pop and a light impact, not the chime or the buzz. The clock runs on. The line
  sits where the green check would, with a raised-hand symbol in yellow, and VoiceOver announces
  it. Return resigns the field, so the view refocuses it as the held correction does
  (`refocusAnswer(after:)` now serves both).
- **Phase 2's `corrections` fixture** changed meaning: most of its wrong answers (teno, arepiento,
  comíamoss, vivne) are now slips, so each must be typed twice to reach its correction. Its
  comment says so.
- **A fixture**, `CONJUGAR_QUIZ_FIXTURE slips`: six slips and four near misses that are real
  errors, each named in a comment. `QuizSecondAttemptTests` checks the fixture against its comments.
- **Verified:** 985 tests in 61 suites, in the simulator's default language (English), with two new
  suites (`AnswerSlipTests`, `QuizSecondAttemptTests`), up from 976 in 59. On the iPhone, in English and light
  mode with a hardware keyboard, the fixture prompted one more try for cantaria, tengp, ire,
  ensenaria, hablez, and han dicjo, with the slip still in a focused field and the clock running;
  Left arrow, Backspace, and the í key turned cantaria into cantaría, which scored 5; a second
  ensenaria went to the correction; hablo, comio, hablé, and sot went to the correction at once.
  The results read "Correct: 0 / 10 · Second Try: 5" with five First Try lines. On the iPad, in
  Spanish and dark mode, "¡Casi! Inténtalo una vez más." showed under the key row, the í key fixed
  the slip, and the results read "Correctas: 0 / 10 · Segundo intento: 2". Not tried: the software
  keyboard, accessibility text sizes, and VoiceOver by ear.
- **Analytics:** none added, so nothing is staged in `docs/privacy_policy_pending.md`.

## Phase 4: Levels

**Ports:** Konjugieren Phase 5. **Suggestions:** T2.3, T2.6, T6.7, M1. **Depends on:** nothing,
though Phases 0 to 3 come first by leverage. **Status:** Done.

Replace Easy, Moderate, and Difficult, and the score modifiers for difficulty and region, with
levels ordered by use, each adding to the one before. **Josh accepted the ladder below as drafted**
(2026-11-22). Still check it against the *Plan curricular del Instituto Cervantes* (its A1 to C2
inventories of verb tenses) and the browse plan's tense count, and bring Josh any disagreement
before building on it.

| Level | Roughly | Tenses added |
|---|---|---|
| 1 | A1 | Presente de indicativo; imperativo positivo for tú (or vos), usted, and ustedes |
| 2 | A2 | Pretérito; imperfecto de indicativo; perfecto de indicativo; futuro de indicativo; gerundio |
| 3 | B1 | Presente de subjuntivo; imperativo negativo; imperativo positivo for nosotros and vosotros; condicional; pluscuamperfecto de indicativo; futuro perfecto |
| 4 | B2 and above | Imperfecto de subjuntivo (both forms); perfecto de subjuntivo; pluscuamperfecto de subjuntivo (both); condicional compuesto; futuro de subjuntivo; futuro perfecto de subjuntivo; pretérito anterior |

- Some cells may be restricted to certain verbs, as Konjugieren's Level 2 asked the Präteritum only
  of sein, haben, and the modals. A Spanish candidate is the courteous condicional (me gustaría,
  podría, querría) at Level 2, before the condicional proper. If any restriction is adopted, the
  generator must draw a verb that fits the cell, not a cell that fits a random verb.
- **T2.6.** Give fixed lower weights to tenses that a learner gets right by knowing something else.
  Every compound tense is a form of haber plus a participle that never changes, so the nine compound
  tenses are the analog of Konjugieren's three Futurs. The futuro de subjuntivo and the pretérito
  anterior are also rare outside legal and literary prose. Weights are fixed per level, never
  adjusted by what the learner has done (T2.4's "No").
- **T6.7.** The new names must not tell a learner that part of the app is a joke.
- Replace the fixed per-tense counts with the weighted draw, but keep what Conjugar's design did
  well: the regular and irregular balance (Phase 5) and the even rotation of persons.
- Score 10 points a right answer at every level, and retire `Quiz.scoreScale` and both modifiers.
  Each level gets its own leaderboard in Phase 7, so scores never compare across levels.
- Migrate the stored `difficulty`. Revisit `ChangeDifficultyTip`, the briefing's difficulty pill,
  the results' pill, `QuizActivityAttributes`, and the `difficulty` parameter on the three quiz
  signals, which becomes `level`. **M1** is already half done: `startQuiz` sends the difficulty
  today.
- **Decouple the Info filter.** `Settings.infoDifficulty` and every article's difficulty use the
  same `Difficulty` enum. Keep Info on its own enum (renamed, so the two cannot be confused) unless
  Josh prefers Info to filter by level.

**Decided for Konjugieren (Josh, 2026-11-13), proposed here:** levels are named with words, not
numbers or CEFR labels (Beginner, Elementary, Intermediate, Advanced there; propose Spanish names,
such as Inicial, Elemental, Intermedio, Avanzado); a new install starts at Level 1; every level
scores 10 a right answer; scoped quizzes use the learner's level.

**Decided (Josh, 2026-11-22):** the stored difficulty migrates Easy to Level 2 (Easy already asks
the pretérito and futuro), Moderate to Level 3, and Difficult to Level 4, and a new install starts
at Level 1.

**Ask Josh:** any restricted cells; the weights (Konjugieren's were 3 for the Präsens and Perfekt, 2
for other finite tenses, and 1 for the Futurs and participles; the analog here is 3 for the
presente and pretérito, 2 for other simple tenses, 1 for the compounds and the two rare tenses); and
the names in both languages.

**From Konjugieren:**

- `QuizLevel.pool` listed each level's tenses written out per level, rather than built by
  accumulation, so each level reads like the table. `QuizDraw` drew a tense by weight, then a verb
  that the restriction admits, then a cell. A tense that no verb of a scope admits was left out.
- **Make the random source injectable** (`Quiz(randomSource:)`), and sort the verbs before drawing,
  since a dictionary's order changes between launches and a seed must draw the same quiz in every
  process. `VerbMap.shared.entries` is a dictionary.
- A four-segment picker truncated the names on an iPhone, so the levels became tiles with a gauge
  symbol (`gauge.with.dots.needle.0percent` to `100percent`). Spanish names may be longer still.
- Renaming the tip (`ChangeLevelTip`) makes TipKit treat it as new, so learners see it once more,
  which suits a new setting. Settings attached its popover tips to views that stayed alive after
  the tab's first visit, so on iPad a tip appeared over the Quiz tab's results; attach tips only
  while Settings is on screen.
- Text that named the old difficulties: the onboarding quiz page, `docs/app_description.txt`, and
  the tip. Find them all.

**Done when** each level draws only its own cells, any restricted cells draw only their verbs, the
low-weight tenses appear at their weight under a fixed seed, settings migrate, the Info filter still
works, the quiz signals carry `level`, and tests pin each level's pool.

**How it differed:**

- **Josh chose on 2026-11-23**, taking every recommendation: the ladder as drafted, with no
  restricted cells (the courteous condicional is a few phrases, and me gustaría does not fit the
  quiz's `yo [ ]` frame, so the condicional waits for Intermediate for every verb); the weights 3
  for the presente, pretérito, and imperfecto (the tense count puts the imperfecto, 14.4%, above the
  pretérito, 12.3%, so it joined the plan's draft 3s), 2 for the other simple tenses and both
  imperatives, 1 for the gerundio, every compound, and the futuro de subjuntivo; the names
  Beginner, Elementary, Intermediate, Advanced and Inicial, Elemental, Intermedio, Avanzado
  (adjectives agreeing with an implied nivel, over Principiante, which names a person, and over the
  Instituto Cervantes's Acceso, Plataforma, Umbral, Avanzado); and Info on its own enum.
- **The Plan curricular was not checked.** Every cvc.cervantes.es page redirected to a maintenance
  page that day, so the ladder was checked only against `docs/tense_frequency.md`. A later session
  could still compare it with the PCIC's A1 to C2 inventories and bring Josh any disagreement.
- **The draw.** `QuizLevel` (`Models/QuizLevel.swift`, `nonisolated`) writes out each level's
  `pool` of `QuizPoolEntry` values (a tense, the persons it leaves out, its weight). Beginner and
  Elementary leave nosotros and vosotros out of the imperativo positivo. Each question of the
  default quiz draws a tense by weight, a person from the tense's rotation (filtered by the level),
  and a verb from the curated lists, regular and irregular in turn, so the old balance holds at
  fifteen of thirty. The irregular list follows the cell (the imperfecto de subjuntivo and futuro
  de subjuntivo take the pretérito's, the condicional the futuro's, a compound the participle's,
  usted's and the plural commands the presente de subjuntivo's); the regular verbs now take turns
  by ending, which Easy did and Moderate and Difficult did not. Phase 5 replaces all of this with
  per-cell irregularity from the engine. Until then the lists' flaws show: buscar is a "regular"
  verb asked its buscase, and an Elementary quiz asks about three irregular imperfectos, which are
  always ser, ir, and ver.
- **The random source is injectable**: `Quiz(randomSource:)`. Without one, a shuffling quiz uses
  the system's generator and an unshuffled one (`shouldShuffle: false`, which tests and UI tests
  use) `SplitMix64(seed: 0)`, so both stay deterministic. Every shuffle and the rotation's random
  start go through it. The default quiz's verbs come from arrays, not a dictionary, so nothing
  needed sorting.
- **Scoped quizzes use the level.** A full-length one (My Verbs, a collection) draws tenses by weight
  and drops a tense none of its verbs has. Test Me's three take distinct cells in a weighted order,
  so a beginner's span two tenses (the old test asked for three distinct tenses; it now asks for
  as many as the level has, up to three). Two fixes came with it, found by the tests at Beginner,
  whose few cells force repeats. When every verb had already been asked a cell, the fallback never
  passed the turn, so tener took 21 of 30 questions beside ir. And abolir, which has only the
  nosotros and vosotros presente at Beginner, never came up, since its turn rarely met a cell it
  has. A cell now goes to a verb not yet asked it, then the verb asked least, then the next in
  turn.
- **Scoring.** 10 a right answer and 5 a second try at every level, summed. `Quiz.scoreScale` and
  both modifiers (`Region.scoreModifier`, `Difficulty.scoreModifier`) are gone, and a perfect run
  is 300. Until Phase 7 every level posts to the one leaderboard, whose old entries reach 750;
  nothing ships before then.
- **The setting** moved to a new key, `quizLevel`. On a launch without it, a stored `difficulty`
  (Easy, Moderate, Difficult) becomes Elementary, Intermediate, or Advanced; the old key stays,
  since `GetterSetter` has no removal, and is never read again once a level exists. Both paths
  ran on real installs: the iPhone's stored Easy became Elementary, and the iPad's, set to
  Difficult for the test (it was Easy), became Advanced. `World.uiTest` reads a level's raw value
  from the launch arguments in place of a difficulty's.
- **Info** keeps `InfoDifficulty` (the renamed `Models/Difficulty.swift`, cases and raw values
  unchanged, so `infoDifficulty` needs no migration); its score modifier and localized names went
  with the quiz's. `L.Difficulty` and its three strings are gone.
- **Settings' tiles.** As in Konjugieren, the levels are four tiles with a gauge
  (`gauge.with.dots.needle.0percent` to `100percent`), and the Quiz tab's middle tile shows the
  level with its gauge. Settings now attaches `ChangeLevelTip` only while it is on screen
  (`isOnScreen`), the bug Konjugieren found. The renamed tip appeared at once on the iPhone, whose
  `quizCompleted` donation survived, so learners who have finished a quiz will see it once more.
- **Text that named the difficulties:** the Quiz tab's line (now "Conjugate 30 Spanish verbs at your
  level. A right answer earns 10 points, and a right second try earns 5."), the onboarding quiz
  page, the tip, `docs/app_description.txt`, the README, the 3.0 release notes (which said scores
  were scaled to fifty questions), and `CLAUDE.md`'s overview.
- **Analytics.** `difficulty` became `level` on `startQuiz`, `quitQuiz`, and `completeQuiz`, with a
  `QuizLevel` raw value. Staged in `docs/privacy_policy_pending.md` as a rewritten bullet in both
  languages. `QuizActivityAttributes.difficulty` became `level`; the widget never showed it, and the
  Live Activity was not looked at.
- **`docs/feature_architecture.md` § The Scoped Quiz became § Quiz**, with the levels, the weights,
  and the draw.
- **No fixture.** What needed seeing was the random draw, so the check typed a wrong answer into
  thirty real questions per level and read each question from the accessibility tree.
- **Verified:** 999 tests in 63 suites, in the simulator's default language (English), with two new
  suites (`QuizLevelTests`, `QuizLevelSettingTests`), up from 985 in 61; `QuizLevelTests` took 1.4
  seconds. On the iPhone, in English and light mode: Settings' tiles and the tip, the Quiz tab's
  tile, a Beginner quiz (eighteen presentes and twelve commands, every command tú, usted, or
  ustedes), and its results' Beginner pill. On the iPad, in Spanish and dark mode: the tiles
  (Inicial … Avanzado), the tip, the Quiz tab's Avanzado tile, an Advanced quiz (fifteen tenses in
  thirty questions, compounds among them, no vosotros in América Latina), and its results. Not
  tried: VoiceOver by ear (each tile reads its name with the selected trait), accessibility text
  sizes, and the Live Activity.

## Phase 5: Which Verbs Are Asked

**Ports:** Konjugieren Phase 6. **Suggestions:** T2.1, T2.2, T2.5. **Depends on:** Phase 4.
**Status:** Done.

For the default quiz (not My Verbs, a collection, or a verb's page, whose verbs are chosen):

- **T2.1.** Draw from the level's frequency band: proposed, as Josh decided for Konjugieren, the 100
  most frequent verbs at Level 1, 300 at Level 2, 1,000 at Level 3, and every verb at Level 4. Check
  that no verb sits in a band only because its count is an estimate (`hitsAreProvisional`, the `hp`
  attribute; Konjugieren found 56 inflated estimates in its top 1,000).
- **T2.2.** Prefer base verbs. Every quiz includes one to three prefixed compounds (detener,
  componer, deshacer) to practice them, and otherwise draws unprefixed verbs and frequent compounds.
  The base-verb relation is the browse plan's Phase 8. *Landed 2026-11-22:*
  `VerbRelations.shared.baseByVerb[verb] != nil` marks a prefixed compound; see
  `docs/feature_architecture.md` § Ways between verbs for what it misses.
- **T2.5.** Keep Conjugar's balance and make it exact: half of a default quiz's questions ask a cell
  in which the verb is irregular. Judge irregularity per cell, not per verb, since tener is
  irregular in the presente and regular in the imperfecto; the engine already marks an irregular
  span with capitals (`IrregularityMarker`), so a cell is irregular when its form has one. Make sure
  that ser, estar, haber, tener, ir, and hacer recur: at least two questions a session.

**The curated lists.** `VerbFamilies` was the pre-engine way to know which verbs are irregular in
which tense, and its "regular" lists hold verbs the engine treats otherwise (buscar's busqué, leer's
leyó, romper's roto). With per-cell irregularity from the engine and bands from the map, the lists
are no longer needed to draw. **Decided (Josh, 2026-11-22):** draw from the engine, and keep the
lists only as a test oracle that the engine's draw can reach their verbs, which the browse plan's
Phase 16 collections may already provide. **Ask Josh** whether
a spelling change (busqué, llegué, cojo) counts as irregular for the balance; the capitals probably
mark it, and a learner does have to learn it.

**From Konjugieren:**

- Josh chose the looser reading of "one to three derivatives": a prefixed verb in the top 300 draws
  freely, and beyond it exactly one to three questions ask one.
- `QuizDraw.questions(mixesVerbs:)` drew every slot's tense by weight, then gave slots roles (core,
  rare derivative, derivative, free) and split the halves exactly, and only then drew each slot's
  verb, so the counts were exact, not likely. A bug that thirty-question tests hid was caught by a
  ten-question test at two seeds of forty: test at the length Phase 6 will use.
- A refactor made `QuizLevelTests` go from 3 seconds to 688 while passing. Read per-suite times.

**Done when** a default quiz under a fixed seed draws only from the band, holds one to three
prefixed compounds, asks irregular cells for exactly half its questions, includes the core verbs,
leaves scoped quizzes unaffected, and tests pin each.

**How it differed:**

- **Josh chose on 2026-11-23**, taking both recommendations. A spelling change (llegué, busque,
  cojo, creyó, continúo) counts as irregular for the half: a cell is irregular when the engine's
  form shows red on the verb page. A probe before asking found spelling-only changes to be a third
  of the marked presente de subjuntivo cells in the top 300 and a quarter of the pretérito's. And a
  tense with few irregular verbs asks at most one irregular question, a question the phase text did
  not raise: only ser, ir, and ver are irregular in the imperfecto, so an even spread would have put
  era, iba, and veía into three of an Elementary quiz's six imperfectos, every quiz. "Few" is fewer
  than five roots among the band's irregular verbs, so that prever and entrever count with ver at
  Advanced; in practice it is only the imperfecto. The option Josh chose said ser, ir, and ver would
  come "in turn". The draw picks among them at random each quiz, not by a turn kept across quizzes.
- **No provisional count reaches a band.** The highest verb with `hp="y"` is podrir, near #1454, so
  nothing in the top 1,000 rests on an estimate, unlike Konjugieren's 56. `QuizVerbMixTests` pins it.
- **The draw** is `QuizDraw` (`Models/QuizDraw.swift`, `nonisolated`). `Quiz.levelQuestions` still
  draws the cells (tense by weight, person by the tense's rotation) and hands them over. Then, as in
  Konjugieren, every slot gets a role (core, compound or rare compound, free) and an irregularity
  before any verb is drawn, so the counts are exact. Josh's looser reading of T2.2 carried over:
  a compound in the top 300 (`VerbRelations.shared.baseByVerb`) draws freely; beyond it, exactly
  one to three questions ask a rare compound at Intermediate and Advanced; at Beginner and
  Elementary, at least one question asks a compound. The top 100 holds six (mantener, entender,
  aparecer, conseguir, desarrollar, reconocer) and the top 300 fifty-three. The core verbs are ser,
  estar, haber, tener, ir, and hacer, at least two questions a quiz. The regular questions still take
  the -ar, -er, and -ir endings in turn, which Phase 4 kept from Easy.
- **A compound tense is judged by its participle.** The engine's regular composition of a compound
  is a regular haber plus a regular participle, so "he hablado" marks hE, and judging by capitals
  alone would have made nearly every perfecto irregular.
- **Irregularity by class.** Judging every verb of the band in a cell costs 0.14 s at Advanced in a
  debug build (28 µs an engine call), and a quiz has up to thirty cells. A model's features are
  end-anchored, so a class's verbs are irregular in the same cells: a probe over sixteen cells and all
  106 classes found only two exceptions (prever and entrever in the pretérito, pudrir and podrir in
  the participle). So the draw judges one verb per class per cell, caches that for the process, and
  confirms the verb it finally chooses with the engine.
- **Two bugs the exact tests caught, both of crowding.** The first version assigned the irregular
  half without asking whether a cell had the verbs for it: Beginner's presente has only sois and vais
  irregular for vosotros among the top 100, so a third irregular vosotros slot fell back to a regular
  verb (seed 17: 14 of 30). Then two core slots landed in the presente's tú, where haces is the only
  regular core form (seed 38: 16 of 30). A role now goes to different cells where it can, each side
  of the split respects how many verbs a cell has for a role, and a slot that still cannot be filled
  gives up its ending, then its role, and only last its irregularity.
- **A slowdown, read in the per-suite times.** The first working version made `QuizLevelTests`, which
  draws 560 quizzes, go from 1.4 seconds to 28. Copying candidate lists per slot, and a root count
  whose `where` clause filtered without stopping, were most of it. Candidate sets now hold the band's
  own per-class lists unjoined. A quiz costs about 5 ms at Beginner and 18 ms at Advanced in a debug
  build. `QuizLevelTests` takes 4.5 seconds in the full run and `QuizVerbMixTests` 2.
- **`VerbFamilies` moved to the test target** (`ConjugarTests/Models/VerbFamilies.swift`) as the
  oracle Josh chose. `VerbFamiliesTests` now also checks that the draw's per-cell judgment finds every
  listed irregular verb irregular in its list's tense, and every listed regular verb of a plain class
  (1, 2, 3) regular in every cell Advanced asks. It found one true exception: ser's vos command *sé*
  is the stem s- with the regular vos ending -é, so the engine rightly marks nothing; the test names
  it. The rename script rewrote a sentence in `docs/code_review_recommendations.md` into something
  false ("Quiz builds questions from the lists in ConjugarTests/…"); that historical review was
  restored as it was.
- **Text.** Settings' level description gained a sentence on the bands in both languages ("Beginner
  asks the 100 most used verbs, Elementary the 300 most used, Intermediate the 1,000 most used, and
  Advanced every verb."). The App Store description's quiz paragraph now names the verbs too. Its
  Spanish half still said "tres niveles de dificultad", which Phase 4 had missed; it now says four
  levels. The onboarding page is still true and was left alone.
- **No analytics and no privacy lines.** Nothing new is sent. **VoiceOver:** nothing new to say.
- **Verified:** 1,016 tests in 64 suites, in the simulator's default language (English), up from 999
  in 63. One new suite (`QuizVerbMixTests`, 15 tests over forty seeds per level), two new oracle tests,
  and the old turn-taking test retired. On the iPhone, in English and light mode, a real Beginner quiz
  answered wrongly thirty times and read from the accessibility tree: every verb in the top 100,
  exactly 15 irregular cells, five core verbs, five frequent compounds, and the regular half split
  five -ar, five -er, five -ir. Also Settings' new description. On the iPad, in Spanish and dark mode
  at Advanced: fifteen questions of a real quiz (half the typings were lost to the transition after
  Continue), with rare verbs such as añorar, deglutir, fusilar, and desvergonzarse beside hacer and
  venir, compounds, and the rare tenses. AXe's tap by identifier failed on the iPad with a decoding
  error, so taps there went by the frames `describe_ui.sh` reports. Not seen: Settings' description
  in Spanish on a device (the iPad's tab bar hid Configuración), and the Live Activity.
- **For Phase 6:** the rules are per draw, so a quiz of ten gets five irregular questions, two core,
  and one to three rare compounds (a test pins it at ten). Phase 6 should decide, as Konjugieren's
  note said, whether Ten More draws a fresh mix of ten or one mix for the session.

## Phase 6: Ten Questions, Then Ten More

**Ports:** Konjugieren Phase 7. **Suggestions:** T2.7, T3.1, T6.5, M2, M3. **Depends on:** Phases 2
and 4. **Status:** Done.

- **T2.7.** The default session is ten questions, with an offer to continue. Josh agreed
  reluctantly for Konjugieren, in the hope that a shorter quiz is started and finished more often.
  Continuing should feel like the same session growing, not a new quiz.
- **T3.1.** Re-ask a missed question once, a few questions later, and not again whatever the second
  answer. A question missed near the end is re-asked before the results.
- **T6.5.** A setting, default off, that shows the clock. While it is off, the quiz screen and the
  results show no time.
- Revisit what the question count gates: the Live Activity, the tip donation, and ranking.
- **M2 and M3.** On the next launch after a quiz was abandoned by leaving the app, report the
  question reached (`abandonQuiz`); and report the time from start to quit in bands (0-3s, 3-15s,
  15-40s, 40s-2m, 2m+). The bands replace Conjugar's raw `elapsedTime` on every quiz signal (Josh,
  2026-11-22); stage the changed policy line, since the policy names the elapsed time. `score` stays
  on `completeQuiz` and `quitQuiz` for a default session's ranked round only.

**Decided for Konjugieren (Josh, 2026-11-13 and 14), proposed here:** the first ten's results offer
"Ten More", which continues the session and adds to its score; a re-ask is added beyond the ten and
earns half points when right; no thirty-question choice remains; with the clock hidden the results
show no time; a default session posts its first round's score only, re-asks not counted; My Verbs
and collection quizzes become ten with Ten More, and a verb page keeps three with none; the Live
Activity runs for each round of ten.

**From Konjugieren:**

- The session's `questionCount` became the questions asked so far, re-asks excluded, and the score
  and counts were computed from each item's points rather than kept alongside, which made re-asks
  and Ten More free of bookkeeping.
- A wrong answer inserts its re-ask three questions on, or at the round's end, and the correction
  says "This question will come up again."
- **A privacy leak found in the Closing:** `questionNumber` on `quitQuiz` and `abandonQuiz` counted
  the list position, into which re-asks are inserted, so a quit at 13 in a round of ten revealed
  three wrong answers. Count the round's original questions only.
- The results' header and the dot row had to wrap once five items and thirty dots appeared.
- `QuizActivityAttributes`' total moved into the content state, since re-asks grow it.

**Done when** the default quiz is ten questions and can continue, a missed question returns once,
the clock hides by default, the Live Activity and tip follow the new length, the abandonment signal
fires on the next launch, and tests pin re-ask placement and the continuation.

**How it differed:**

- **Nothing was asked.** The phase had no **Ask Josh**, so its "proposed here" decisions, which
  were Konjugieren's, became Conjugar's: Ten More continues the session and adds to its score; a
  re-ask comes beyond the ten and earns 5 when right; no thirty-question choice remains; with the
  clock hidden the results show no time; a default session posts its first round's score only, re-asks
  not counted; My Verbs and collection quizzes are ten with Ten More, and a verb page keeps three
  with none; the Live Activity runs for each round. The bands are 0-3s, 3-15s, 15-40s, 40s-2m, and
  2m+.
- **Decided in the session, as Konjugieren did.** Each Ten More draws a fresh mix of ten (the
  question Phase 5 left), so every round has the first round's balance. Ten More has no limit. A
  verb page's quiz re-asks too. A re-ask may still earn a slip's second attempt, and a right re-ask
  earns 5 on either attempt. `completeQuiz` is sent at each round's results with `questionCount`
  (10, 20, …), so Ten More shows without a signal of its own; the phase text did not ask for
  `questionCount`, but Konjugieren sends it. A later round over My Verbs or a collection is handed
  the session's questions so far, so it goes on taking turns with them and avoids a cell already
  asked.
- **How it works.** `QuizScope.fullLength` (30) became `roundLength` (10), and `continues` joined
  `isRanked` and `startsLiveActivity`. A re-ask is the same `QuizQuestion` with `isReask` set
  (`reasked()`), inserted into `Quiz.questions` `Quiz.reaskGap` (3) on, or at the end. Conjugar's
  quiz keeps parallel arrays (`proposedAnswers`, `results`, …) rather than Konjugieren's items, and
  an insertion always lands after the question on screen, so the arrays stay aligned by index.
  `score`, `correctCount`, and `secondAttemptCount` stopped being stored and are computed, re-asks
  apart (`reaskCount`, `reaskCorrectCount`, `points(at:)`, `maximumScore`, `firstRoundScore`).
  `questionCount` counts no re-ask. `continueSession()` appends the round, keeps the clock's
  seconds, and starts a Live Activity. `QuizActivityAttributes.totalQuestions` moved into the
  content state, since a re-ask grows it, and `elapsedTime` became optional, nil while the clock is
  hidden.
- **The privacy leak Konjugieren found in its Closing was avoided from the start.**
  `quitQuiz` and `abandonQuiz` send `Quiz.questionReached`, which counts no re-ask, and a test pins
  it (a quit at the fifth position after three misses reports 4).
- **`score`** now goes only on a ranked session's first round: `completeQuiz` at its results, and
  `quitQuiz` during it, as `firstRoundScore`. A scoped quiz and Ten More's rounds send none. The
  exact `elapsedTime` is gone from every signal, replaced by `duration`, wall-clock from the
  session's start (`AnalyticsBand.quizDuration`). `ParameterKey.elapsedTime` was removed; nothing
  else sent it.
- **The abandonment record.** `QuizAbandonment` keeps one entry per quiz in the defaults (key
  `quizzesInProgress`). `GetterSetter` has no removal, so an empty record is an empty string, as
  `TutorChatHistory` clears. It is reported in `ConjugarApp.init`, after analytics starts and
  before any view can start a quiz, rather than in `MainTabView`'s `.task`, where a quiz started by
  a cold-launch link could already have written an entry to be misreported.
- **What a learner sees.** The correction says "This question will come up again." / "Esta pregunta
  volverá a salir.", spoken with the correction. A re-ask's card has an "Asked Again" / "Pregunta
  repetida" pill, announced as the question comes, and its results row says so too. The results add
  "Asked Again: 1 / 2" / "Repetidas: 1 / 2" and a Ten More / Diez más button. The counts and the
  pills now wrap through `FlowLayout`. The new setting is Quiz Clock / Reloj del test, Hide / Show
  (Ocultar / Mostrar), under Quiz Tú or Vos. Josh has not judged any of the wording.
- **Found by looking.** On the iPhone, Ten More popped the results onto a question whose field had no
  keyboard, since the focus was set before the pop ended. The view now focuses the field after
  450 ms, the delay the correction's Back already used.
- **Text that said 30 or "timed":** the Quiz tab's line (now "Conjugate 10 Spanish verbs at your
  level, then ten more if you like. …", naming the re-ask's 5), the start screen's tile (10),
  the onboarding quiz page ("Take ten-question quizzes"), `TryQuizTip` ("with a ten-question
  quiz"), the collection Quiz button's VoiceOver hint (from `roundLength`), the App Store
  description, and the README. The screenshot fixture lost two questions (hablar's presente and
  saber's futuro, each a second of its tense) to hold one round of ten.
- **Tests that changed their claim.** `QuizVerbMixTests` and `QuizLevelTests`'s weight test draw
  thirty-question quizzes explicitly, as before, since proportions need the sample. `QuizScopeTests`'s
  check that five My Verbs all come up, abolir among them, now runs over three rounds through Ten
  More, since abolir has only two cells at Beginner and ten questions did not always reach it; the
  even-share test expects 4 to 6 of ten.
- **Analytics and privacy** are staged in `docs/privacy_policy_pending.md` (the score, progress, and
  after-list bullets and section 7's Game Center paragraph, in both languages). A device check of the
  Live Activity and the new signals is item 6 of `docs/release.md` § Before Submitting.
- **Verified:** 1,034 tests in 65 suites, in the simulator's default language (English), up from
  1,016 in 64, with one new suite (`QuizRoundTests`, 16 tests, 0.2 seconds) and a test of the
  duration bands. `QuizLevelTests` took 4.3 seconds and `QuizVerbMixTests` 2.7, as before.
  On the iPhone, in English and light mode, with the `grading` and `slips` fixtures: the start
  screen's line and tile, a miss's correction with its come-up-again line and no clock, the re-ask
  four places on with its pill, 5 points for it, the results (5, "Correct: 0 / 10 · Asked Again: 1 /
  10", no time pill, Ten More), and Ten More resuming at the eleventh place with the score, the
  longer bar, and the keyboard. On the iPad, in Spanish and dark mode at Advanced: the Reloj del test
  setting, the quiz with the clock shown, "Esta pregunta volverá a salir.", the Pregunta repetida
  pill, and the results (Repetidas, the time pill, Diez más, the rows' badges). Not tried: VoiceOver
  by ear, the Live Activity, a real abandonment across a relaunch (unit-tested), Game Center, and
  accessibility text sizes.

## Phase 7: Leaderboards by Level

**Ports:** Konjugieren Phase 8. **Suggestions:** Decision 4. **Depends on:** Phases 4 and 6.
**Status:** Done.

Re-scope the Game Center leaderboard by level: one leaderboard per level, posting the score of a
default session's first ten questions, so every ranked score has the same ceiling, 100. Scoped
quizzes stay unranked. Stop presenting the leaderboard automatically at the end of a quiz
(`QuizView.finish()` does today); Phase 12 gives it a modest place.

- `GameCenter.reportScore` needs the leaderboard to post to. Update `GameCenterReal`,
  `GameCenterFake`, and the leaderboard buttons, which open the level's board.
- Write `docs/game_center_setup.md`, a step-by-step walkthrough for creating the per-level
  leaderboards in App Store Connect: each ID exactly as the code uses it, score format, sort order,
  range, and the English and Spanish names. Read Apple's current documentation for the steps rather
  than writing them from memory.
- The existing leaderboard is retired on release day, not now, since the shipped app posts to it.
  Add that step, and adding the new boards to the version for review, to `docs/release.md`.

**Ask Josh** whether he wants Claude to create the leaderboards in App Store Connect by driving his
Chrome, as Konjugieren's session did, or to follow the walkthrough himself.

**From Konjugieren:**

- IDs were `konjugieren.level.<level>`; here `conjugar.level.<level>`, pinned literally by a test,
  since App Store Connect makes an ID permanent.
- App Store Connect's form defaults to Low to High; each board needs High to Low, 0 to 100, Best
  Score, Integer.
- Konjugieren's repo held a local Game Center configuration (`GameCenterResources.gamekit`), copied
  into the app by the build. Conjugar has none; ask Josh whether to add one.
- The new boards were invisible to a development build until they are added to an app version,
  which waits for 2027, so posting a score could not be confirmed. Put the test in `docs/release.md`
  § Before Submitting.
- The test double became a spy that records submissions (`GameCenterSpy`), and `submitScore` stopped
  being `async`, so a test sees the call at once.
- Nothing broke ties at 100, by Josh's choice.

**Done when** a ranked session posts to its level's board through the double, an unranked one posts
nowhere, the walkthrough exists, and tests pin which sessions rank.

**How it differed:**

- **Josh chose on 2026-11-23**, taking two recommendations and declining one: Claude created the
  leaderboards in App Store Connect by driving his Chrome; Conjugar got a local Game Center
  configuration after all (the recommendation was to skip it); and, since Conjugar had no
  leaderboard button and this phase removed the only way to the board, a ranked round's results
  offer View Leaderboard (the level's board) and Settings offers View Leaderboards (the list of
  every board), as Konjugieren's Phase 8 did, until Phase 12 gives the leaderboard its place on the
  hub. Nothing breaks ties at 100, as in Konjugieren; it was not asked.
- **The four leaderboards exist in App Store Connect**, in "Prepare for Submission": Beginner,
  Elementary, Intermediate, and Advanced, IDs `conjugar.level.<level>`, each Classic, Integer, 0 to
  100, Best Score, High to Low, not hidden, no suffix, no image. Each has three localizations,
  English (U.S.), Spanish (Spain), and Spanish (Mexico), the Spanish two identical (Inicial,
  Elemental, Intermedio, Avanzado), with a description of the first ten questions at that level.
  The live board turned out to be `biz.joshadams.Conjugar.leaderboard` (reference name
  "leaderboard", English only, the Default), which the shipped app found through
  `loadDefaultLeaderboardIdentifier()`. Each board's range and sort order were read back from its
  page afterward. None was added for review.
- **`Conjugar/GameCenterResources.gamekit`** holds the five leaderboards in the JSON shape of
  Konjugieren's (App Store Connect's API attributes), written by hand, and is in the app target's
  Copy Bundle Resources by an explicit file reference (four `project.pbxproj` lines), since
  `Conjugar/` itself is not a synchronized folder. The build copies it into the app. Josh should
  open it in Xcode once to confirm the editor reads it. The live board's image (`flag.png`) is not
  in it.
- **The protocol** became Konjugieren's: `submitScore(_:level:)` (no longer `async`;
  `GameCenterReal` starts its own task, so a test sees the call at once), `showLeaderboard(level:)`
  (`GKAccessPoint.trigger(leaderboardID:playerScope:timeScope:)`), and `showLeaderboards()`.
  `QuizLevel.leaderboardID` sits in `GameCenter.swift`. The cached default-leaderboard lookup is
  gone. `GameCenterFake` stays in the simulator and test worlds; the new `GameCenterSpy` records
  submissions and shown boards and replaced the two private spies in `QuizScopeTests` and
  `QuizRoundTests`, whose yield loops went with `async`. `QuizView.finish()` no longer opens the
  leaderboard.
- **The results' button** shows while the player is signed in and the session ranks
  (`scope.isRanked`), so it stays after Ten More, opening the board of the level the session began
  at. Settings' Game Center card shows Enable while signed out and View Leaderboards once signed
  in (its `isGameCenterUIHidden` became `isSignedInToGameCenter`).
- **Analytics.** A new `tapViewLeaderboard`: from the results with `level`, from Settings with no
  parameter. Staged in `docs/privacy_policy_pending.md` as a rewritten in-app-actions bullet and a
  rewritten section 7 paragraph ("one for each quiz level"), in both languages, and pinned in
  `AnalyticsTests`.
- **Strings.** New: View Leaderboard / Ver clasificación, View Leaderboards / Ver clasificaciones,
  their hints, and Settings' description of the boards. Rewritten: Settings' Enable description
  ("which keeps a leaderboard for each level") and the onboarding quiz page ("compete on your
  level's Game Center leaderboard"). Josh has not judged the wording.
- **Docs.** [`docs/game_center_setup.md`](../docs/game_center_setup.md) records the boards, their
  settings, the steps as App Store Connect showed them, release day, and testing. Apple's help
  pages were read for it through a Sonnet subagent: a new component goes in the same submission as
  its first app version; Make Default is a hover action in the Default column; archiving takes up
  to 24 hours; prerelease testing needs the boards added to the version under test. The release
  steps (test before submitting, submit with the version, make Beginner the default, archive the
  old board) are in `docs/release.md`. Conjugar's shared scheme has no GameKit debug mode, the
  setting that hid every board in Konjugieren.
- **Not verified:** posting a real score. As in Konjugieren, the new boards are presumably invisible
  to a development build until a 2027 version holds them, so the test waits for release day.
- **Verified:** 1,039 tests in 66 suites in the full run, in the simulator's default language
  (English), up from 1,034 in 65: the new `QuizLeaderboardTests` (6 tests: each ID pinned, a
  perfect hundred to each level's own board, the level fixed at the start, a second attempt's 5
  counted and a re-ask's not, Ten More posting nothing more, scoped quizzes posting nothing), with
  `GameCenterFakeTests`' two exercise tests merged into one. The `tapViewLeaderboard` pin was added
  after, and its suite rerun with the other two (16 tests). `QuizLevelTests` took 9.1 seconds, up
  from 4.3, while Chrome was busy beside it; nothing in this phase touches the draw. On the iPhone,
  in English and light mode: Settings' new Enable description, then (the fake signed in by Enable)
  View Leaderboards with its description, and a real Beginner quiz answered wrongly, whose results
  showed View Leaderboard under Ten More and no sheet. On the iPad, in Spanish and dark mode at
  Avanzado: Configuración's Permitir description, then Ver clasificaciones, and a real quiz's
  results with Ver clasificación. Not tried: VoiceOver by ear, the Game Center sheets themselves
  (the simulator's fake shows nothing), and accessibility text sizes.


## Phase 8: Choosing What to Practice

**Ports:** Konjugieren Phase 9. **Suggestions:** T2.8. **Depends on:** Phases 4 and 5. **Status:**
Done.

Let the learner choose the scope: tenses, a verb set (a frequency band, a collection or model, My
Verbs when it has entries), or both. The default remains the classic quiz with this plan's changes.
The browse plan's All Verbs / My Verbs picker is the place to start.

- A chosen scope is unranked.
- A beginner opening the tab should not meet a wall of options. Keep the custom choice one step away
  from Start.

**Decided for Konjugieren (Josh, 2026-11-13), proposed here:** a custom scope is remembered between
launches and offered beside the default quiz; it may include any tense, above the learner's level or
not.

**Ask Josh** to judge the layout on a phone and an iPad before polishing.

**From Konjugieren:**

- A third segment, Custom, with a summary card and Choose or Change, which pushed an editor of
  tables and verb sets. Check the Spanish label fits its segment on an iPhone.
- A part left unchosen was the level's; a chosen tense was asked of every verb at any level.
- Store the choice in a form a link can carry (`groups=…&verbs=…` with permanent keys), so Phase 9
  can share it unchanged.
- Inside a `Button`, `.secondary` derives from the button's tint, so secondary text rendered in the
  app's red; `Color.secondary` is fixed.
- A new `source`, `custom`, and a `customChoice` parameter saying what kind of choice, never which.

**Done when** a learner can start a quiz over chosen tenses, a chosen verb set, or both, the default
is unchanged, and tests pin scope construction.

**How it differed:**

- **Josh has not judged the layout**, which the phase asks for before polishing. It was built as
  Konjugieren's and is waiting for his verdict on a phone and an iPad.
- **The layout.** The Quiz tab's picker gained a third segment, Custom (Personalizado), which fits
  on the iPhone 17 beside Todos los verbos and Mis verbos. Its start screen shows
  `slider.horizontal.3`, "Custom Quiz" / "Test personalizado", a summary card (Tenses, Verbs) in
  place of the three fact tiles, and Choose or Change, which pushes `CustomQuizEditor`
  (`Views/CustomQuizView.swift`) onto the tab's stack. The editor's Tenses section opens with "Set
  by Your Level" and lists every tense in the order the levels add them, each with the level that
  adds it ("From Intermediate" / "Desde Intermedio"), where Konjugieren showed a table's second
  name. The Verbs section is "Set by Your Level", the three bands, All Verbs, My Verbs, the four
  pattern lists, and Models, a further push listing the Models tab's rows in the learner's own
  Models-tab sort (first drawn in `ModelInfo.all`'s order, which no screen uses, and changed after
  looking). Choosing a model returns to the editor, which names it beside Models. Empty, the
  segment says what to choose and Start is disabled. The tab still opens on All Verbs.
- **Decided in the session, as Konjugieren's were, and open to Josh's overrule.** (1) A part left
  unchosen is the level's. (2) A chosen tense is asked as Advanced asks it, so a chosen imperativo
  positivo asks nosotros and vosotros at Beginner too. (3) A band or All Verbs is mixed as the
  default quiz is (half irregular, the core verbs, compounds); a collection or My Verbs is not.
  (4) The top 100 is offered only as the band. (5) My Verbs is listed only while it has verbs or is
  the stored choice. (6) One verb set at a time. (7) **A pattern list asks the chosen or the
  level's tenses, not its pattern's**, the question the browse plan's Closing left for Phases 8
  and 15. A learner who picks -go verbs can choose the presente and presente de subjuntivo
  alongside; steering the tenses automatically would hide what the quiz asks. Phase 15 may still
  decide otherwise for its model practice.
- **How it works.** `CustomQuiz` (`Models/CustomQuiz.swift`, `nonisolated`) holds a set of tenses
  and an optional `QuizVerbSet` (`all`, `band`, `collection`, `myVerbs`). `QuizScope` gained
  `custom`, `pool(level:)`, and `band(level:)`; `isRanked` requires `custom == nil`, and
  `startsLiveActivity` now lets a custom quiz over a collection start one, since it runs on the tab,
  not in the collection sheet. `Quiz.start` and `continueSession` share one `draw(_:after:)`, which
  hands the scope's pool to the scoped draw or to `mixedQuestions(count:pool:band:)` (the old
  `levelQuestions`). `QuizDraw` now keys its per-band data and caches by `FrequencyBand?` rather
  than by level, so a Beginner can draw a mixed quiz from the top 1,000; `questions(cells:level:)`
  stays as a wrapper. The fixtures stay with the default quiz only.
- **Kept between launches** in `Settings.customQuiz` (key `customQuiz`), not shown in Settings, as
  `tenses=presente_de_indicativo,preterito&verbs=goVerbs`. A tense's key is its Info article's
  stable key (`ConjugationTable.articleKey`), already permanent because `conjugar://info/…` links
  name it, or `gerundio`, which has no article. A verb set's key is `all`, `top100`, `top300`,
  `top1000`, `myVerbs`, or a collection's (`goVerbs`, `model-31`). Phase 9 can put the string in a
  link unchanged. Konjugieren's later `infinitives=` list, for a shared My Verbs, is Phase 9's
  work and was not ported.
- **Analytics.** A new `source`, `custom`, and a new `startQuiz` parameter, `customChoice`
  (`tenses`, `verbs`, or `both`). A custom quiz over a collection sends `collection` as a
  collection's quiz does. Staged in `docs/privacy_policy_pending.md` in both languages (the
  quiz-lifecycle bullet and section 7's Game Center paragraph), and pinned in `AnalyticsTests` and
  `LookupSignalsTests`.
- **Text.** New strings in `L.CustomQuiz`; Josh has not judged the wording. The App Store
  description (both languages) and the README gained a sentence on the custom quiz. The onboarding
  page and `TryQuizTip` are still true and were left alone.
- **VoiceOver.** The summary card reads as one element; each editor row reads its name and detail
  with the button trait, and `isSelected` when checked; tense names and model exemplars are marked
  Spanish. Choose / Change has a hint. Not tried by ear.
- **Tests:** `CustomQuizTests`, 15 tests in 1 second: the stored form pinned and round-tripped,
  every tense key and every verb-set key (every model included), unknown keys dropped alone, the
  setting's persistence, the choice parameter, each part left to the level, a chosen tense of every
  person, never ranked, and sessions over tenses alone, a verb set alone, and both (with Ten More
  keeping the choice), a band mixed as the default quiz is (exactly five irregular, two core), every
  tense alone filling a round from every band in Latin America, and an empty My Verbs starting
  nothing.
- **Verified:** 1,054 tests in 67 suites in the simulator's default language (English), up from
  1,039 in 66. `QuizLevelTests` took 5.0 seconds and `QuizVerbMixTests` 3.6, so the `QuizDraw`
  rekeying cost nothing. On the iPhone, in English and light mode: the three segments, the empty
  Custom state, the editor, the Models list, choosing a model and a pattern list, the summary, and a
  quiz over Strong Preterites in the pretérito and imperfecto (poner, andar, traer, producir, venir,
  tener, introducir, with re-asks). On the iPad, in Spanish and dark mode at Avanzado: Personalizado,
  the empty state, the editor, the 300 band chosen with the condicional, the summary card, and a
  quiz that asked only the condicional of top-300 verbs. The summary card first rendered with double
  padding (`.card()` pads already), fixed after the iPhone check. Not tried: VoiceOver by ear, the
  Live Activity, a relaunch to see the choice kept (unit-tested), accessibility text sizes, and the
  Models list in its new sort (built, not opened again).

## Phase 9: Practice Sets to Share

**Ports:** Konjugieren Phase 10. **Suggestions:** T2.9, Decision 8. **Depends on:** Phase 8.
**Status:** Done. **Taken last**, after Phase 23, if at all (Josh, 2026-11-22): schools are
mostly Conjuguer's channel. Before starting, ask Josh whether he still wants it. (He did, and asked
for it after Phase 8, on 2026-11-23.)

Make a chosen scope shareable as a link and as a QR code, so a teacher can hand a class one practice
set without accounts or a server. Encode the scope in a `conjugar://quiz/set?…` link under the
browse plan's grammar; opening it shows the set with Start rather than starting unasked. Shared text
carries the `conjugar://` link and the App Store link. Generate the QR code on the device, with a
full-screen view a teacher can project. Ask Josh to try the Camera app on a `conjugar://` code on his
phone, since the simulator has no camera.

**From Konjugieren:** a sheet with Start and "Keep as My Custom Quiz"; a shared My Verbs carried its
verbs by infinitive, capped at 100 so a projected code stays scannable; the length did not travel;
an invalid link opened "Practice Set Not Found" rather than doing nothing; the QR code drew dark on
white in both appearances and kept the screen awake; the code's link said `source=qrCode` and the
text's `sharedLink`; and a test read the generated code back with Core Image's detector.

**Done when** a shared link and a scanned code open the same set, an invalid link fails gracefully,
and tests pin encoding and decoding of every scope.

**How it differed:**

- **Taken out of order, by Josh's choice (2026-11-23).** Asked whether he still wanted it, he chose
  to build it now, after Phase 8, and to keep Konjugieren's three decisions: a sheet with Start and
  Keep as My Custom Quiz that never starts a quiz unasked; a shared My Verbs that travels as its
  infinitives, at most 100; and no length in the link (every set is ten, then Ten More).
- **The route** is `conjugar://quiz/set?` followed by Phase 8's stored form unchanged, then `level`
  and `source` (`sharedLink` in the text, `qrCode` in the code). `quiz/start` and every other quiz
  target still start a quiz on the tab. `PracticeSet` (`Models/PracticeSet.swift`) reads and writes
  it; `AppRouter.pendingPracticeSet` carries it, with the source, to a sheet in `MainTabView` over
  whatever tab is open, page-sized on iPad. Any other link clears a pending set.
- **Decided in the session, as Konjugieren's were, and open to Josh's overrule.** (1) The level
  travels only while a part is left to it, and a set's quiz asks at it through a new
  `QuizScope.level` without touching the learner's setting; a kept set uses the learner's level,
  as any custom quiz does. (2) A list of verbs is `QuizVerbSet.list`, stored as
  `infinitives=tener,a%C3%B1adir` rather than in `verbs=`. Spanish has no collision like German's
  `sein`, but a separate item costs nothing and keeps the two apps' links alike. The editor lists a
  kept list only while it is the choice. (3) A link naming `verbs=myVerbs` drops that part.
  (4) Share is on the Custom segment only, a menu of Share Link and Show QR Code beside Change, and
  only while Start is enabled; the set's sheet does not share onward. (5) The QR view draws dark on
  white in both appearances, keeps the screen awake, and puts the tenses and the verbs on two lines
  beneath the code, as two elements, since the tenses are Spanish and the verbs the learner's
  language. (6) A set's quiz runs in a `QuizSheet` over the set's sheet, so it starts **no Live
  Activity** (`QuizScope.isPracticeSet`), as a collection's sheet quiz does not; Konjugieren's did
  not say. (7) Spanish names it *Serie de práctica*.
- **Conjugar's own problem: the welcome tour.** The likeliest opener of a shared link is a student
  who has just installed the app from the link's App Store line, and the first launch shows the
  onboarding cover, under which a sheet cannot present. `AppRouter.presentablePracticeSet` returns
  nil while the tour or the game covers the tabs, so the set waits and appears once the cover is
  gone. Seen on the iPhone: a link sent while the tour was up showed nothing until Skip, then the
  set. **Not handled:** a link arriving while some other sheet is up (Test Me's or a
  collection's quiz) finds the presenter busy, and SwiftUI drops the set's sheet.
  Konjugieren has the same gap.
- **Invalid links** open "Practice Set Not Found" / "Serie de práctica no encontrada", and send
  `viewPracticeSet` with `outcome` `invalid`. Unknown keys, infinitives, and levels are dropped and
  the rest kept.
- **Analytics.** `tapSharePracticeSet` (`method`, `customChoice`), `viewPracticeSet` (`outcome`,
  `source`), `tapKeepPracticeSet`, a new `method` key, and the `qrCode` source; the quiz signals
  carry `sharedLink` or `qrCode` and `customChoice` for a set's quiz. Staged in
  `docs/privacy_policy_pending.md` in both languages (the in-app-actions bullet, the quiz-lifecycle
  bullet, and section 7's Game Center paragraph), and pinned in `AnalyticsTests` and
  `LookupSignalsTests`. None names a tense or a verb.
- **Text.** New strings in `L.PracticeSet` and `L.CustomQuiz.verbList`; Josh has not judged the
  wording. The README and the App Store description (both languages, 3,476 and 3,838 characters)
  gained a clause on sharing with a class.
- **Tests:** `PracticeSetTests`, 22 tests in 2.5 seconds: the link's pinned form (with añadir
  percent-encoded), every set round-tripped by both sources, every tense and every verb set (every
  model included) through a link, the list's stored form, unknown and repeated infinitives, a list's
  order, My Verbs shared as a list and capped at 100, an empty My Verbs leaving the verbs to the
  level, the level travelling only when needed, nine links that name nothing, a link keeping what it
  can read, a link naming My Verbs, every set's scope (unranked, no Live Activity, its level), the
  share text, the summary naming the set's level, the generated code read back by Core Image's
  detector, a hundred of the longest infinitives with every tense still fitting a code, a kept list
  surviving a relaunch, a session at the set's level, and a session posting no score and taking Ten
  More. In `AppRouterTests`, 4 more: the route without a tab change, its failure, a later link
  replacing a set, and a set waiting out a cover.
- **Verified:** 1,080 tests in 68 suites in the simulator's default language (English), up from
  1,054 in 67. `QuizLevelTests` took 7.8 seconds (5.0 in Phase 8) and `QuizVerbMixTests` 4.9 (3.6);
  nothing in this phase touches the draw beyond which level it reads. On the iPhone, in English and
  light mode: a set opened by `simctl openurl` (the -go verbs in the pretérito), its quiz in the
  sheet (satisfacer), Quit back to the set, Keep, the kept set on the Custom segment, Share's menu,
  Show QR Code, Share Link's sheet (Copy gave the expected text), a set carrying a level ("Set by
  Level: Elementary"), the invalid link, and a link held behind the welcome tour. On the iPad, in
  Spanish and dark mode: a 14-verb list set (chips, "y 2 más"), Keep, the Personalizado segment
  with Cambiar and Compartir, the share popover anchored to Compartir (Copiar gave the Spanish text
  with `infinitives=`), and the QR view. Both screens' QR codes decode to the exact link. The
  iPad's share popover takes about four seconds to appear in this simulator. Not tried: VoiceOver by
  ear, accessibility text sizes, and Ten More in a set's sheet (unit-tested).
- **Waiting on Josh's phone:** whether the Camera app offers to open a `conjugar://` QR code. The
  simulator has no camera. Record the result here.

## Phase 10: The Practice Record

**Ports:** Konjugieren Phase 11. **Suggestions:** T3.3 (the record), T3.4, T3.5, T6.4. **Depends
on:** Phase 6. **Status:** Done.

Give the quiz a memory: a small record per item, a box and a due date, moved up the ladder of 1, 3,
7, 14, and 30 days by a right answer and back to the start by a wrong one. Josh's verdict on the
intervals: do not agonize over the numbers.

- **T3.5, the kinds of item.** Spanish differs from German here. Josh accepted this design on
  2026-11-22:
  - **An irregular verb's key conjugation.** A question whose cell is irregular (its form has the
    engine's capitals) maps to the key conjugation whose stem the cell is built on. With the
    browse plan's four: the presente de subjuntivo and the usted, nosotros, ustedes,
    and negative imperatives map to the yo presente (tengo, tenga); the pretérito and both
    imperfect subjunctives and the futuro de subjuntivo map to the yo pretérito (tuve, tuviera); the
    futuro and condicional map to the yo futuro (tendré, tendría); the participio and every compound
    tense map to the participio (tenido).
  - **A regular pattern**, shared by every verb in a cell where it is regular: a tense, a person, and
    a conjugation class (-ar, -er, -ir). tener's imperfecto (tenía) moves the -er imperfecto
    pattern, as hablar's moves the -ar one.
  - **What the four stems do not cover maps to the nearest key conjugation**, accepting that a
    slip in tienes counts against tengo, as Konjugieren accepted the same cost for wir fahren: the
    stem change of the presente's other persons (tienes, piensas, duermes), the irregular tú
    imperatives (ten, pon, haz, di), and the three irregular imperfectos (era, iba, veía) map to the
    yo presente; the -ir gerunds (durmiendo, pidiendo), which share the stem of the third-person
    pretérito (durmió), map to the yo pretérito. Record any cell whose nearest key is unclear.
  - **Spelling changes** (busqué, llegué, cojo) are items of their verb, like any irregular cell.
  Document the mapping and test it across tenses, persons, regular, stem-changing, -go,
  strong-preterite, prefixed, and defective verbs.
- **Reuse the browse plan's `ReviewSchedule`**, generalizing it rather than writing a second
  ladder, and store the record in the App Group, since Phases 21 and 23 need it outside the app.
- **T6.4.** Record each answer as it is given, so a learner who quits after six questions has still
  practiced six. The trombone stays.
- Every scope writes to the record, unless Josh decides otherwise.
- Stage the privacy change: the policy's "does not record your quiz answers" becomes "does not send",
  with a sentence that the practice record stays on the device.

**Decided for Konjugieren (Josh, 2026-11-13 and 14), proposed here:**

- **One schedule.** The review card above the verb list reads the practice record: a looked-up
  verb enters the record, and the card offers whatever is due there. The browse plan's per-verb
  schedule is folded in, with a migration for existing entries. In Konjugieren the merge made weak
  verbs meaningless on the card (their answers move shared patterns), so the card offered strong
  and mixed verbs only. Here the browse plan's Phase 15 offers irregular verbs only from the start
  (Josh, 2026-11-22), so the migration has no regular verbs to drop.
- A default session mixes in up to three due items of its ten, so a learner who never opens Review
  still relearns.
- Settings gains a Reset Practice control, behind a confirmation.

**From Konjugieren:**

- Keys are strings (`key:fahren:0:praeteritum`, `pattern:praeteritum_indikativ:ss`) built from
  permanent keys, so the widget, which has no corpus, can read the record. Pin them with tests.
- A right answer moves an item up **only when it is due**, so a pattern asked three times in one
  session cannot climb three boxes in an afternoon. A new item answered right enters the second box,
  wrong the first. A slip's right second attempt counts as right. A consequence Josh kept: a verb
  looked up today and answered right today stays in the first box.
- Due items in the default quiz were skipped when the level did not ask their cell or the band did
  not hold their verb; Review (Phase 11) asks those.
- Reset saved an empty record rather than removing the key, so a second migration could not undo it.
- Seed records through `simctl spawn <udid> defaults write`, since `cfprefsd` caches the App Group's
  plist.

**Done when** every answer updates its item, the ladder advances and resets as specified, quitting
keeps what was answered, the record survives a relaunch, the card reads it, and tests pin the item
mapping and the schedule.

**How it differed:**

- **Nothing was asked of Josh.** The phase's decisions were his from 2026-11-22 (the kinds of item)
  and Konjugieren's (one schedule, three due items, Reset Practice), and none of the merge's
  consequences needed a ruling: the card already offered irregular verbs only, so no verb lost its
  card. Every scope writes to the record, as proposed.
- **The mapping (T3.5)** is the accepted design, judged per cell by `QuizDraw.isIrregular(_:in:)`,
  which Phase 5 built: a capital in the engine's form, a compound judged by its participle. An
  irregular cell exercises its verb's key conjugation by tense (presente, presente de subjuntivo,
  both imperatives, and the imperfecto to the yo presente; pretérito, both imperfectos de
  subjuntivo, the futuro de subjuntivo, and the gerundio to the yo pretérito; futuro and condicional
  to the yo futuro; the participio and every compound to the participio). A regular cell exercises
  a pattern of tense, person, and ending (`pattern:imperfecto_de_indicativo:fs:er`), so the vos
  presente (tenés) and nosotros (tenemos) of an irregular verb are patterns. **No cell's nearest key
  was unclear**; the irregular imperfectos and the gerundio went where the phase text put them.
- **A problem the phase text missed, and its fix.** A key conjugation's own cell can be regular for
  its verb: pedí (pedir's yo pretérito), busco, pensé, tenido. Asked as a review, such a cell would
  record a pattern and leave the key conjugation due forever, so the default quiz would ask it in
  every round. Two rules fix it. A lookup schedules only the key conjugations that some irregular
  cell of the verb is built on (`PracticeItem.keyConjugations(of:)`): tener three (not tenido),
  pensar one, pedir two, escribir only escrito. And a review of a key conjugation asks the first
  irregular cell built on it that the level asks (`irregularCells(of:builtOn:)`), its own cell
  first, so pedir's yo pretérito is reviewed as pidió. `PracticeItemTests` checks, over 34 verbs
  of every kind, that every cell exercising a key conjugation is one its review can ask. **Phase 11's
  Review should use `irregularCells` for a key conjugation**, not the key's own cell, as the phase
  text says.
- **The participio is no level's tense** (Phase 4 left it out), so a participio key conjugation is
  reviewed in the default quiz through a compound tense the level asks (he escrito at Elementary),
  and at Beginner it waits for Phase 11.
- **Keys.** `key:tener:yo_presente`, `pattern:<tense>:<person>:<ending>`, with the gerundio and
  participio having no person. Tense keys are the custom quiz's (`CustomQuiz.key(for:)`, already
  permanent) plus `participio`; persons are `DisplayPersonNumber` raw values, which the map's file
  format already fixes. `PracticeItem.Key` lives in `Shared/` beside the record, mirrored by
  `KeyConjugation` in the app, since the widget cannot see `KeyConjugation`.
- **The ladder** is Konjugieren's: `ReviewSchedule` generalized (`lookedUp` became `start`,
  `revealed` `reviewed`, `dismissed` `snoozed`; `new` and `answered(correctly:)` added). A right
  answer moves an item up only when due; a new item answered right enters box 1. A re-ask is
  another answer.
- **Where it lives.** `Shared/PracticeRecord.swift` (`PracticeItem`, `PracticeRecord`),
  `Models/PracticeStore.swift` (`Current.practice`, in the App Group under `practiceRecord`),
  `Models/PracticeItemMapping.swift`, and `Models/QuizDueItems.swift`. `LearnerVerbs` lost its
  `review` field, `dueForReview`, the reveal and dismissal, and `scheduleUnscheduledReviews`;
  `LearnerVerbStore` lost `isReviewable` (now `PracticeItem.isReviewable`) and the review methods,
  and `recordOpen` lost its `source`. `VerbView` records the open and the lookup separately.
  `Quiz(practice:)` takes a store; nil reads `Current.practice`, since a world's quiz is built
  before `Current` exists.
- **The migration** runs once, when no record is stored, reading `LearnerVerbs`' old `review` (or a
  start at the last open) through a private decoder. On the iPhone's real install it carried poner
  (overdue, offered at once), reír, traer, and tener; on the iPad's, arrepentir, ir, and tener.
- **Clear in My Verbs no longer ends a verb's reviews**, which the browse plan's Phase 15 made it
  do. The schedule now also holds quiz answers, so Clear and a swipe leave it, and Reset Practice
  is the way to empty it, as in Konjugieren. Josh may want Clear to reach the record too.
- **Due items in the default quiz**: up to three a round, the most overdue first, placed at random,
  in Ten More rounds too, only in the ranked scope (`QuizScope.mixesDueItems`). Skipped when no
  irregular cell built on the key is one the level asks (with tú or vos, the region, and the
  level's persons), or the verb is beyond the band. A pattern asks a fully regular verb of its
  ending from the band (`VerbDraw.isIrregular` false). Due questions sit outside Phase 5's mix.
- **The card** reads `PracticeStore.cardOffer()`: the verb whose key conjugation is longest overdue,
  with its due key conjugations in the card's order. Its caption says "Practiced 3 days ago"
  ("Practicado hace 3 días") when an answer came after the last lookup. The Suppress Review Card
  description now says "looked up or practiced" ("consultaste o practicaste").
- **Reset Practice** ("Restablecer práctica") sits at the foot of Settings' quiz card, under the
  heading Practice Record ("Registro de práctica"), only while the record holds anything, with a
  red tint, a hint, and an alert. Its description begins "This button erases", as Konjugieren's
  settled on. Josh has not judged the wording.
- **Analytics.** `tapResetPractice`, no parameters, on confirmation. Staged in
  `docs/privacy_policy_pending.md` in both languages: the in-app-actions bullet, and the paragraph
  after the list with "does not record" become "does not send" and a sentence that the practice
  record stays on the device. Not pinned in `AnalyticsTests`, which pins only signals that carry
  parameters.
- **VoiceOver.** No new quiz state: recording is silent, and a due item is an ordinary question.
  The card's caption is read as before; the alert is the system's. Not tried by ear.
- **Tests:** 1,101 in 71 suites in the simulator's default language (English), up from 1,080 in
  68. New: `PracticeItemTests` (pinned and round-tripped keys, ten unreadable keys, 23 irregular
  cells across every tense family and spelling changes, 10 regular cells, prefixed and
  reflexive-only verbs, a defective verb's missing cell, what a lookup schedules, what a review
  asks, and the 34-verb round trip), `PracticeRecordTests` (13: the ladder, due and missed order, a
  lookup from the card, reveal and snooze, JSON, an unreadable key skipped, the store's mapping, the
  card's offer and both captions, regular verbs never on the card, a relaunch, the migration, a
  reset that stays), and `QuizPracticeTests` (answers kept on quit, a slip recording nothing until
  its second attempt, five scopes writing, due items in the default quiz and in Ten More, the
  level's cells only, the band, a pattern's verb, none in a scoped quiz). `ReviewScheduleTests` was
  rewritten for the ladder alone. `QuizLevelTests` took 5.6 seconds and `QuizVerbMixTests` 3.3.
- **Verified on the iPhone**, in English and light mode: the real record's migration and poner's
  card; the reveal moving poner's four key conjugations to box 1; a Beginner quiz answered wrongly
  (nothing within reach was due, correctly, since tener's and traer's migrated dates fall due
  tomorrow and reír is beyond the top 100); a seeded record's hacer card, "Practiced 3 days ago";
  a Beginner quiz that asked the three seeded due items (hacer, tener, ir) and recorded each; and
  Reset Practice, its alert, an empty record, and the section hiding. **On the iPad**, in Spanish
  and dark mode: the migration and ir's card ("Consultado ayer"), a seeded salir card ("Practicado
  hace 2 días"), Configuración's Registro de práctica, its alert, and Cancelar keeping the record.
  Not tried: VoiceOver by ear, accessibility text sizes, a real day passing, and the widget, which
  reads nothing of the record yet. The iPad's appearance was left light.

## Phase 11: Review and My Mistakes

**Ports:** Konjugieren Phase 12. **Suggestions:** T3.2, T3.3 (the session). **Depends on:** Phase
10. **Status:** Done.

- **Review.** A session of whatever items are due: a key conjugation asks its own cell, and a
  pattern asks its cell of a regular verb from the learner's band.
- **Practice My Mistakes.** A session of the items whose most recent answer was wrong. An item leaves
  the list once answered right.
- Entry points on the Quiz tab, each with an empty state that says why it is empty. Phase 12 moves
  them into the hub.
- New `source` values for the quiz signals; stage their lines.

**Decided for Konjugieren, proposed here:** a Review is ten due items, the most overdue first, with
Ten More.

**From Konjugieren:** neither session was held to the level's pool or band, so Review asks what the
default quiz's due items left out; a verb's due key conjugations sat together in the page's order;
fewer than ten made a shorter round; My Mistakes needed an exclusion so a mistake missed again did
not come straight back; and **a record session sent no counts**, because a session shorter than ten
is exactly as long as the learner's due or missed items, so its length would report wrong answers.
A record session sends no `score` either (Josh, 2026-11-22).

**Done when** both sessions draw the right items under test, update the record, and show sensible
empty states.

**How it differed:**

- **Nothing was asked of Josh.** The phase lists no Ask Josh items, and every question below was
  decided in the session, as Konjugieren's were. Each is a guess he can overrule.
- **Where the entry points live.** A From Your Practice (De tu práctica) section below the start
  screen's tiles, on every segment, with one row each for Review (Repaso) and Practice My Mistakes
  (Practicar mis errores). A row with questions shows the count and a play symbol, and a tap starts
  the session on the tab at once. An empty row is not a button and says why it is empty: Review
  gives the days to the next due item ("Nothing is due today. The next review is in 3 days."), or,
  with nothing scheduled, says that quiz answers and irregular verbs looked up come due a day or
  more later; My Mistakes says a missed question waits there until answered right. A fourth and
  fifth segment would not fit the iPhone beside Personalizado. **On an iPhone the section is below
  the fold**, under the hero and the tiles, as in Konjugieren; Phase 12's hub should fix that. On
  the iPad it is above the fold.
- **What each asks.** Review: the record's due items, most overdue first. My Mistakes: items whose
  last answer was wrong, most recently missed first (`PracticeRecord.missedItems()`, which Phase 10
  already wrote). A key conjugation asks the first irregular cell built on it, its own cell first, as
  Phase 10's note asked, so pedir's yo pretérito was asked as él pidió on the iPhone. A pattern asks
  its cell of a regular verb of its ending from the learner's band. **Neither is held to the level's
  tenses or band**, so a Beginner's Review asked escrito and tuve. **The tú or vos setting and the
  region still hold**: a vosotros pattern missed in Spain is neither counted nor asked while the
  region is Latin America (`QuizDraw.canAsk`). Konjugieren has no such setting, so this is new. A
  verb's due key conjugations sit together in the verb page's order at the place of the first
  drawn, and a record session is never shuffled (`QuizScope.shufflesQuestions`).
- **How it works.** `QuizRecordSession` (`Models/QuizRecordSession.swift`) and
  `QuizScope.recordSession`, a new optional field on `QuizScope`. `QuizDraw.dueQuestions` became a
  wrapper over `recordQuestions(for:keyConjugationBand:patternBand:asks:limit:using:)`, which the
  default quiz's due items and `QuizDraw.sessionQuestions` share. `Quiz`'s persons split into
  `personNumbers(in:region:)` (the settings' rule) and the level's filter over it.
  `Quiz.askableCount(for:)` reads the settings' region before a session; the draw and Ten More read
  the session's, as the default quiz's do.
- **Rounds.** Ten items, then Ten More while an askable item remains that the session has not
  asked; fewer make a shorter round, with no Ten More. Each round skips the items the session has
  already asked, for both sessions. `Quiz.questionCount` already counted questions asked (Phase 6),
  so a short Review's results read "Correct: 4 / 5". A record session is never ranked, mixes in no
  due items, and does not donate to `ChangeLevelTip`. It starts the Live Activity, since it runs on
  the tab; `startsLiveActivity` needed no change.
- **The bar's title** reads Review or Practice My Mistakes while a session runs on the iPhone. The
  iPad's top tab bar shows no navigation title at all, which predates this phase.
- **Analytics.** New `source` values `review` and `mistakes`. **A record session sends no counts**
  (`QuizScope.sendsQuestionCounts`): `completeQuiz` omits `questionCount`, and `quitQuiz` and
  `abandonQuiz` omit `questionNumber`; `QuizAbandonment.Entry.questionNumber` became optional, which
  still decodes stored entries. No `score` either. Staged in `docs/privacy_policy_pending.md` in both
  languages: the quiz-lifecycle bullet, the score bullet, the progress bullet, and section 7's Game
  Center paragraph. `LookupSignalsTests` pins the two new values.
- **Text.** New strings in `L.PracticeSession`; Josh has not judged the wording. The README and the
  App Store description (both languages) gained a sentence on the two sessions. The Spanish
  description is now 3,966 characters of the 4,000 allowed, so the next addition must trim.
- **VoiceOver.** No new quiz state. Each row reads as one element, its title and its count or
  reason, and a startable row has a hint ("Starts a quiz of the questions due for review."). Not
  tried by ear.
- **Tests:** `QuizRecordSessionTests`, 15 tests in 0.4 seconds: days to the next due item, a
  session beyond the level's tenses and band, a key conjugation asked by an irregular cell built on
  it (pidió) and a participio as itself, a pattern's verb from the band, a verb's key conjugations
  together, excluded and unaskable items within the limit, the scope's flags, twelve due items asked
  as ten then two and nothing more, a short Review that does not continue, an empty record starting
  nothing, a mistake leaving once answered right, a mistake missed again not returning in Ten More,
  no score and no question number recorded, an abandoned record session reported without one, and
  the region deciding what can be asked.
- **Verified:** 1,116 tests in 72 suites in the simulator's default language (English), up from
  1,101 in 71; the one failure, `LookupSignalsTests`' pinned `source` list, was updated and its suite
  rerun with the new one (43 tests). On the iPhone, in English and light mode, with a seeded record
  (the real one was empty, and restored after): both rows (5 due; 2 missed, the third a vosotros
  pattern hidden by Latin America), a Review titled Review asking escuchábamos (the most overdue
  pattern), tengo and tuve together, escrito, and pidió, a miss on tuve with its correction and
  re-ask, results of 4 / 5 with no Ten More and no leaderboard, then both rows after (Review "next
  review is tomorrow", My Mistakes 1). On the iPad, in Spanish and dark mode at Avanzado, with its
  real record: De tu práctica above the fold (1 and 1), Practicar mis errores asking salgo, results
  of 1 / 1, both empty states after ("dentro de 3 días" and the mistakes line), and, with the record
  emptied for a moment and then restored, "Aún no hay nada que repasar". Not tried: VoiceOver by
  ear, accessibility text sizes, the Live Activity of a record session, and Ten More from a real
  record of more than ten (unit-tested).

## Phase 12: The Practice Hub

**Ports:** Konjugieren Phase 13. **Suggestions:** T6.1, T6.6 (the leaderboard's place). **Depends
on:** Phases 6, 7, 10, and 11. **Status:** Awaiting Josh.

Turn the Quiz tab into a practice hub: what a session is, how long it takes, the current level, what
is due for review, and the last result. The browse plan's start screen is the base.

- Move the leaderboard out of the main path: a modest control on the hub, shown only while signed
  in to Game Center, not a sheet at the end of every quiz.
- Rewrite the quiz's onboarding page and `TryQuizTip` to describe practice rather than a timed,
  scored test.
- The last result is kept on the device, under the privacy change staged in Phase 10.

**Ask Josh** to judge the hub on a phone and an iPad, in light and dark, before polishing.

**From Konjugieren:** what a session is came before Start; a "2–3 Minutes" tile replaced points per
answer; the level tile opened a menu of the levels; the last result kept a kind and a key rather
than a title, so it reads in the current language; on an iPhone, Review had to fit above the fold;
the leaderboard became a small bordered button at the hub's foot; and starting a quiz from the hub
did not focus the answer field until Phase 21 there fixed it, so focus it from the start here.

**Done when** the hub shows each item with real data, the onboarding page and tip are rewritten in
both languages, and the leaderboard is one tap away but not in the way.

**How it differed:**

- **Josh has not judged the hub yet**, which the phase asks for before polishing. It was built as
  Konjugieren's and waits for his verdict on a phone and an iPad, in light and dark. Every choice
  below was made in the session and is open to his overrule.
- **The layout.** What a session is now comes before Start: the scope's symbol (64 points on an
  iPhone, down from 96; still 180 on an iPad), its name and line, the picker, three tiles (or the
  custom summary, or the My Verbs chips after the tiles), Start, then From Your Practice with Review,
  My Mistakes, and a new Last Quiz row, and last a small bordered View Leaderboard button. **On the
  iPhone 17, Review is now above the fold**, which Phase 11 could not manage; My Mistakes is below
  it. The All Verbs line (`Quiz.briefing`) no longer explains points. It says ten questions at your
  level, ten more whenever you like, and that a missed question comes back a few questions later and
  again on a later day for review. It runs to four lines on the iPhone, which Josh may want shorter.
- **The tiles: Questions, 2–3 Minutes, and the level as a menu.** Konjugieren's Minutes tile
  replaced its points per answer. Conjugar's third tile was the region, which the browse plan chose
  in place of points per answer because points then depended on the region. Since Phase 4 they do
  not, so **the region tile gave way to Minutes**. The region still decides whether vosotros is
  asked, and it remains in Settings and on the results' pills. Josh may want it back, as a fourth
  tile or as a second menu. The minutes are a fixed estimate (VoiceOver: "Two to three minutes"),
  since showing the learner's own times would undo the hidden clock. The level tile opens a menu of
  the four levels, with a chevron to say so, and sets the same `Settings.quizLevel` as Settings'
  level picker. It sends no signal, as Settings' picker sends none, and it retires `ChangeLevelTip`,
  as a change in Settings does.
- **The last result** (`LastQuizResult`, `Models/LastQuizResult.swift`, kept by `PracticeStore`
  under `lastQuizResult` in the App Group) is written by `Quiz.finish()` for every scope, a verb
  page's three and a collection's or practice set's sheet included. After Ten More it is the session
  so far; a quit writes nothing. It keeps a kind (`allVerbs`, `myVerbs`, `custom`, `practiceSet`,
  `collection`, `verbPage`, `review`, `mistakes`) and a subject (a verb or a collection's key)
  rather than a title, so it reads in the current language: "All Verbs · Beginner · today", then
  "Correct: 0 / 10 · Score: 0", with Second Try when there was one. A verb page's infinitive is read
  in Spanish. Review and My Mistakes keep no level. The row is absent until a round has finished.
  `GetterSetter` has no remove, so Reset Practice saves an empty string, which reads as none.
  `PracticeStore.isEmpty` now counts the last result, so Settings' Reset Practice shows while either
  exists, and its description and alert now name the last quiz's results.
- **The leaderboard (T6.6).** The results' View Leaderboard button is gone. Conjugar's quiz never
  showed a sheet at the end (Phase 7 removed that), so the button was the whole of the leaderboard's
  place in the main path. The hub's button shows only while signed in, opens the board of the
  learner's current level, and sends `tapViewLeaderboard` with `level` and `source` `tab`.
  Settings' View Leaderboards is unchanged. `docs/release.md` and `docs/game_center_setup.md` now
  say to test it from the Quiz tab.
- **Still in the main path, and left for Josh:** the Game Center alert that the Quiz tab shows on
  its first visit (`maybePromptGameCenter`), which asks a new learner to sign in to compete before
  the first question. It is shown once, and Konjugieren has no such alert to compare. Josh may want
  it moved, perhaps to the first finished round.
- **Focus from the start.** Konjugieren's hub did not focus the answer field until its Phase 21.
  Here, Start and a `quiz` link both left the field focused, because `inProgress` already clears
  and resets the focus once it appears. Seen on the iPhone after Start and on the iPad after a
  link, where typing went straight into the field. A row's play button starts its session through
  the same `startQuiz`, but was not tried. No change was needed.
- **Onboarding and tip.** The quiz page is now "Practice Conjugating" / "Practica la conjugación",
  with `pencil.and.list.clipboard` in place of the trophy and a button reading "Start Practicing" /
  "Empezar a practicar". Its body names ten questions in two or three minutes, the held correction,
  the re-ask, and review from a record kept on the device, and drops points and the leaderboard.
  `TryQuizTip` keeps its title and now says "Practice Spanish verb conjugations ten questions at a
  time. What you miss comes back for review." Josh has not judged the wording.
- **Analytics and privacy.** No new signal; `tapViewLeaderboard` gains `source` (`tab`). Staged in
  `docs/privacy_policy_pending.md` in both languages: the in-app-actions bullet already names the
  leaderboard and its level, so it is unchanged, and the paragraph after the list now names the
  last quiz's results as kept on the device and never sent. The README and the App Store
  description were left alone, since neither mentions the results' button.
- **VoiceOver.** No new quiz state. Each tile and the Last Quiz row read as one element; the
  level menu has the hint "Changes the quiz level." and the leaderboard button "Opens the Game
  Center leaderboard for your level." The accessibility tree read "De dos a tres minutos" and
  "Avanzado, Nivel" on the iPad. Not tried by ear.
- **Tests:** `QuizHubTests`, 14 tests in 0.7 seconds: the stored form pinned, a round trip, a
  result with no level and two unreadable ones, every scope's kind (a deeplink's quiz, a custom
  quiz over a collection, and a practice set among them), every kind's title, the store keeping the
  result across a launch, Reset forgetting it, a finished quiz keeping its result, Ten More
  replacing it with the session so far, a quit keeping nothing, a quit keeping the earlier result,
  a Review keeping no level, a verb page naming its verb, and a collection naming its key.
- **Verified:** 1,130 tests in 73 suites in the simulator's default language (English), up from
  1,116 in 72. **On the iPhone**, in English and light mode: the hub with Review above the fold, a
  round started with Start (field focused) and answered wrongly to the results (no leaderboard
  button), the hub after it (Practice My Mistakes 10, Last Quiz "All Verbs · Beginner · today",
  "Correct: 0 / 10 · Score: 0", and View Leaderboard, which the simulator world's
  `GameCenterFake` shows once Enable has signed it in, and whose tap shows nothing there), the
  level menu and Elementary chosen, and the onboarding page through Settings' Show Onboarding.
  **On the iPad**, in Spanish and dark mode at Avanzado: a round started by `conjugar://quiz` with
  the field focused, its results, and the hub with Último test ("Todos los verbos · Avanzado ·
  hoy"). Both simulators' practice records were restored afterward to what they held before (the
  iPhone's empty, the iPad's one `salir` entry), the last result deleted, the iPhone's level set
  back to Beginner, and the iPad's appearance back to light. Not tried: VoiceOver by ear,
  accessibility text sizes, the real Game Center sheet from the hub's button, and a record session's
  Last Quiz from the device (unit-tested).

## Phase 13: Naming the Error

**Ports:** Konjugieren Phase 14. **Suggestions:** T4.2, T4.3. **Depends on:** Phases 2 and 3.
**Status:** Not started.

Diagnose a wrong answer from the engine's own knowledge and say it in one templated line, shown with
Phase 2's correction. No language model. A wrong diagnosis is worse than none: say only what is
certain, check from most to least certain, and stop at the first that applies. Candidate classes for
Spanish:

- **Another cell of the same verb**, by the browse plan's "which cells equal this text": "That is
  the pretérito (él). The presente (yo) was asked." Accent errors that mark a tense land here
  (hablo for habló), as do person errors, the indicative for the subjunctive (hablas for hables),
  the wrong haber form in a compound (ha hablado for he hablado), and the -ra form for the -se form
  or the reverse, which Phase 0 keeps apart ("That is the -ra form. The -se form was asked.").
- **A negative imperative written as affirmative** (no habla for no hables): "Negative commands use
  the subjunctive." A special case of another cell, worth its own line.
- **A regular form of an irregular verb** (tení for tuve, sabo for sé, hacido for hecho,
  escribido for escrito, poní for puse): the engine can conjugate any verb against a feature-less
  regular model, as `ModelInfo.irregularityPercent` already does.
- **A stem change missing or misplaced** (penso for pienso, dormo for duermo; piensamos for
  pensamos): conjugate with the model's stem-vowel feature removed, or applied to every person.
- **A spelling change missing** (buscé for busqué, llegé for llegué, escogo for escojo).
- **The tú form for vos, or the reverse** (hablas for hablás), unless Josh rules it acceptable.
- **A spelling slip**, which Phase 3 already catches.

**T4.3.** For a diagnosable error, prompt a repair before revealing the answer ("Remember the stem
change. Try once more."), through Phase 3's single second attempt with half points.

**Ask Josh** which classes prompt a repair and which reveal at once, and to review the templates in
both languages. For Konjugieren he chose that every class prompts, and that one line serves both the
prompt (with "Try once more.") and the correction (without it).

**From Konjugieren:** each class was an exact construction compared against every accepted spelling,
never a resemblance; rules came before the cell match, since an answer can fit both and the rule
says more; the hypothetical weak conjugation needed a new engine entry point
(`conjugate(reading:…)`); `QuizItem.firstAttemptDiagnosis` sat beside Phase 3's `firstAttempt`; a
repaired answer wrong in an undiagnosable way got no line; and a fixture with one question per class
made the check fast.

**Done when** each class is diagnosed for real verbs under test, an undiagnosable answer gets no
line, and the prompted second attempt shares Phase 3's mechanism.

**How it differed:** _Not started._

## Phase 14: Key Conjugations

**Ports:** Konjugieren Phase 15. **Suggestions:** T5.1. **Depends on:** Phases 1 and 10. **Status:**
Not started.

An exercise for irregular verbs: given the infinitive, supply its key conjugations (with the
browse plan's four, "tener: tengo · tuve · tendré · tenido"). The browse plan's key-conjugations
function supplies the answers, and Phase 1's frame supplies the blanks, one row per conjugation.
Each blank is graded alone and updates its own item in the record. Offer it on the hub over the
irregular verbs of the learner's band, and wherever Phase 15 needs it.

**Decided for Konjugieren (Josh, 2026-11-13 and 14), proposed here:** the exercise is called "Verb
Essentials" (propose the Spanish name, perhaps "Lo esencial del verbo"); blanks are graded one at a
time with every row on screen; a round is five verbs; it starts from an "Exercises" section of the
hub, where Phases 15 to 20 add rows; the results offer "Five More Verbs". **No "principal parts"
label.**

**From Konjugieren:** a verb was several quiz items sharing a step ID, so every mechanism (slips,
diagnoses, corrections, the record) applied per blank unchanged; the field stayed in one place in
the view hierarchy, with rows before and after it as separate children, so the keyboard kept focus
as it moved down; a missed blank was re-asked after the next verb with its other rows given; and
each row was labeled with its tense.

**Done when** the exercise asks, grades each blank, and records each item, with tests for a -go
verb, a strong preterite, an irregular future, an irregular participle, and a prefixed compound.

**How it differed:** _Not started._

## Phase 15: Models, One Then Mixed

**Ports:** Konjugieren Phase 16. **Suggestions:** T5.2. **Depends on:** Phases 10 and 14.
**Status:** Not started.

Work through one model's verbs, then mix them with models already practiced. Konjugieren did this
with ablaut groups; Conjugar's models (the Models tab, the browse plan's Phase 16 bars) are the
analog, and the stem-changing models (pensar, volver, pedir) are the clearest patterns. The support
is Pan et al. (2019), on blocked-then-mixed practice; for verb families as such the report found no
study, so treat it as a bet.

**Decided for Konjugieren, proposed here:** the practice uses Phase 14's exercise; a group is its ten
most frequent verbs; a group is "known" once at least half its items have moved past the first box;
a single-verb group (ser, ir, haber, and the other one-verb models) offers no solo practice and joins
mixes once its verb's items have climbed; Mixed opens for a group once another group is known; and a
mixed round of five verbs is three of the group's own and two from known groups.

**Ask Josh** which models offer practice: probably every model with an irregularity above zero, with
the regular models and those whose only change is a spelling change left out.

**From Konjugieren:** known was computed from the record, never stored, so a wrong answer could make
a group unknown; a key conjugation counted once per verb across its readings; the practice card sat
on each group in the Families tab and in a hub list ordered by use; a mixed session sent no counts,
since which groups are known comes from the learner's answers.

**Done when** a learner can practice one model, then a mix with known models, and tests pin which
models count as known and how the mix is drawn.

**How it differed:** _Not started._

## Phase 16: Recognition

**Ports:** Konjugieren Phase 17. **Suggestions:** T5.4. **Depends on:** Phase 2 and the browse
plan's map. **Status:** Not started.

Show a form, such as fuera, and ask for the infinitive, the tense, and the person. This is the
direction a reader needs, and Konjugieren's report rated it highest for Conjugar, whose American
learners read Spanish. The bundled map gives every form's verbs and cells.

- The infinitive is typed. The tense and person are chosen, since typing their names would test the
  metalanguage.
- Spanish forms are often several cells at once (hablamos is presente and pretérito; hable is
  presente de subjuntivo for yo and él and the usted imperative; fuera is ser's and ir's -ra
  imperfect subjunctive for yo and él). Konjugieren accepted every right reading and avoided no
  prompt, since deciding which cells a text can be is the skill.
- Accents matter in the prompt: habló and hablo are different questions.
- Draw from the learner's level and band.

**Decided for Konjugieren (Josh, 2026-11-13 and 15), proposed here:** a mode of its own on the hub;
the choosing is chips (the level's tenses, then the chosen tense's persons); an answer with any part
right gets one more try at half points, with a line naming what to check; recognition answers are
**not** recorded in the practice record, since recognizing a form is not evidence of producing it;
the name was "Name the Conjugation" ("Konjugationen bestimmen"), after the classroom's "Bestimme die
Verbform". Propose a Spanish name (perhaps "Identifica la forma").

**From Konjugieren:** a question held every cell of every verb that writes its prompt; a part was
called wrong only when changing it could make the answer right, so a repair line never sends the
learner to change what was right; the chips sat above the field so they stay in sight above the
keyboard; a wrong infinitive that only lacks letters was marked red throughout; and the quiz scrolls
a second attempt's line into sight.

**Done when** recognition questions ask, accept every right reading, and grade by part, with tests
on ambiguous forms.

**How it differed:** _Not started._

## Phase 17: Sentences with a Blank

**Ports:** Konjugieren Phase 18. **Suggestions:** T5.5. **Depends on:** Phases 1 and 2. **Status:**
Not started.

Short authored sentences for the core verbs, with the verb blanked, so the form is tied to a
meaning. Spanish gives the blank more to do than German did: a subjunctive trigger (quiero que,
cuando, ojalá, es importante que) is a sentence's whole reason for its tense.

- **The content.** A JSON resource: for each sentence, the Spanish with each word of the answer
  marked, the verb, its tense and person, and an American English translation. A machine check
  confirms that each blank's answer is the engine's form of that cell, so no sentence can teach a
  wrong form.
- **Regions and the second person.** A sentence must read correctly in both regions. Avoid
  vosotros unless the sentence is asked only in Spain, and decide how a tú sentence behaves when the
  quiz asks vos (carry both answers, or ask 2s sentences only in the setting they were written for).
- **The app.** A sentence prompt built on Phase 1's frame.
- **The literary reward.** On the results screen, a right answer's row can show its verb's modern
  example from `ExampleUses.json`. The quiz itself never pauses after a right answer.

**Decided for Konjugieren (Josh, 2026-11-13 and 15), proposed here:** a mode of its own in the hub's
Exercises; three sentences for each of verbs 26 to 100 and two for each of 101 to 300, with a first
batch of the 25 most frequent at about four each; Claude drafts, the machine check confirms, Claude
rereads every sentence, and Josh reviews the first batch (he did that one in five minutes, judging
the English and the meaning). The name there was "Sentences" ("Lückensätze"); propose a Spanish one.

**From Konjugieren:** the file was written only by `json.dumps(indent=2, ensure_ascii=False)` through
a script (`scripts/gap_sentences.py`) with review and approve commands; braces around the answer, not
a separate field, so the reviewer reads the sentence as the learner will; drafts shown in debug
builds with a "Draft" label; the check was tested by breaking it; eleven Sonnet subagents drafted
ranges of about 25 verbs from a self-contained brief, a script merged them, and the reread changed 61
of 619; one drafter transliterated characters in its ids, so build ids from the verb.

**Done when** the sentences exist for the agreed verbs and pass the machine check in both regions,
sentence questions appear where decided, and tests pin the check.

**How it differed:** _Not started._

## Phase 18: Which Tense Would a Speaker Use?

**Ports:** Konjugieren Phase 19. **Suggestions:** T5.6. **Depends on:** Phase 17 for its content
pipeline. **Status:** Not started.

A context and two sentences, each in a different tense, with the learner choosing the one a speaker
would use. Spanish has the classic contrasts: the pretérito or the imperfecto; the subjuntivo or the
indicativo (creo que against no creo que); the condicional or the imperfecto de subjuntivo in a si
clause; the futuro, the presente, or ir a + infinitivo for future time. Each item carries a one-line
reason shown after the choice, and items are leveled with Phase 4.

**One contrast depends on the region.** The perfecto de indicativo for today's events (hoy he comido)
is the Spanish norm in Spain and much less used in most of Latin America (hoy comí). Items on it must
follow `Settings.region`, or be left out; say which in the item data.

**Decided for Konjugieren (Josh, 2026-11-13 and 15), proposed here:** one choice question per default
round from Level 2 up, Ten More's included, rather than a mode; two named sentences, the form in bold
yellow and its tense beneath; the card holds after every choice, right or wrong, with the reason and
Continue (the one place the quiz pauses after a right answer); a first batch of about 40 items,
reviewed by Josh.

**From Konjugieren:** 10 points if right and none if wrong, with no second attempt and no re-ask;
choosing is not producing, so the record is untouched; never first in a round, so a round opens with
the keyboard up; reasons are a handful of strings with the tenses' names filled in; `.disabled`
dimmed the right sentence just when it should be read, so the buttons stopped taking taps without
dimming; the machine check caught a draft on its first run.

**Done when** the items exist and are reviewed, the choice and its reason appear as decided, region
items follow the setting, and tests pin the item data's integrity.

**How it differed:** _Not started._

## Phase 19: Mastery

**Ports:** Konjugieren Phase 20. **Suggestions:** T6.2. **Depends on:** Phases 4, 10, and 12.
**Status:** Not started.

Show mastery, modestly: the report warns that progress displays are unproven for persistence. The
two kinds of item complicate a verb-by-tense grid, since a regular pattern is shared by every verb in
its class.

**Decided for Konjugieren (Josh, 2026-11-15), proposed here:** a split display, the regular patterns
first (one row per tense, a mark under each person, here perhaps per conjugation class), then the 50
most frequent irregular verbs, each with its key conjugations; a row in the hub's "From Your
Practice" that pushes the page; mastered means the third box (seven days); three states (mastered,
learning, not yet practiced), each its own shape.

**Ask Josh** to confirm the layout from mockups, and the names in both languages.

**From Konjugieren:** a verb row opened nothing, because opening a verb page records a lookup, which
sends its key conjugations back to the first box, so admiring a mastered verb would undo it; every
German word was its own VoiceOver element; the counts change with the level.

**Done when** the display reflects the record under test and Josh has judged it on a device-sized
screen.

**How it differed:** _Not started._

## Phase 20: Speed Round

**Ports:** Konjugieren Phase 21. **Suggestions:** T5.7. **Depends on:** Phases 10 and 19.
**Status:** Not started.

A speed round over items already mastered, the one place where the clock counts: Paul Nation's
fluency strand, speed for material already accurate.

**Decided for Konjugieren (Josh, 2026-11-13 and 15), proposed here:** 60 seconds, counting right
answers; a personal best kept on the device, nothing ranked; mastered is the third box; a miss does
not move an item down and does not stop the round (the next question appears at once with the
missed one's answer above it); the round opens at five mastered items and repeats them; a mastered
key conjugation asks any cell of its stem the level asks; the round records nothing.

**From Konjugieren:** the timer's tick became a method so tests run a minute without waiting one;
the countdown first read "1:00" then "59" because the time formatter drops minutes below one; the
round sends no counts, since its length is how many were answered in a minute; starting from the hub
had to focus the field, as Phase 12 here should already do.

**Done when** the round draws only mastered items, times as decided, and tests pin the drawing and
scoring.

**How it differed:** _Not started._

## Phase 21: A Daily Session and a Streak

**Ports:** Konjugieren Phase 22. **Suggestions:** T6.3. **Depends on:** Phases 10, 11, and 12.
**Status:** Not started.

A short daily session, a streak that can be repaired, and an optional reminder at a time the learner
picks. About 37% of iOS education-app users allow notifications (secondhand, in the report), so the
session and the streak must work without the reminder.

**Decided for Konjugieren (Josh, 2026-11-13), proposed here:** the daily session is ten questions at
the learner's level, due items first; finishing it extends the streak; a streak broken by one missed
day is repaired by two sessions the next day; the widgets do not show the streak; three signals (the
reminder turned on or off, a `reminder` source, and the streak's length in bands of 1, 2 to 6, 7 to
29, and 30 or more).

**From Konjugieren:** permission asked only on turning the reminder on; one notification a day for 14
days, each saying what that day will have due, and none on a day already done; tapping a reminder
started a daily session through a deeplink (`quiz/daily?source=reminder`); a streak counted days
practiced, not the bridged day; passing a method as a `Binding` setter crashed the compiler in IR
generation, and a closure did not; tests ran under a fixed calendar with an injectable `now`.

**Done when** the session, the streak with its repair, and the reminder work across days under a
controllable clock in tests, and the reminder fires on the simulator at the chosen time.

**How it differed:** _Not started._

## Phase 22: Personal Bests and Achievements

**Ports:** Konjugieren Phase 23. **Suggestions:** T6.6 (personal bests and achievements). **Depends
on:** Phases 7, 19, and 21. **Status:** Not started.

Personal bests per level, kept on the device, and Game Center achievements for mastery milestones,
not for volume of play. Comparisons with one's own past motivate weaker performers better than
rankings do.

- Propose a short list of achievements to Josh, tied to mastery (every Level 1 pattern in the third
  box, the key conjugations of the 10, 25, and 50 most frequent irregular verbs, the core verbs ser,
  estar, haber, tener, ir, and hacer).
- Extend `docs/game_center_setup.md` with the achievements: IDs as the code uses them
  (`conjugar.achievement.…`), English and Spanish titles and descriptions, points, and artwork.
  Read Apple's current requirements.
- `GameCenter` gains a way to report achievement progress.

**Decided for Konjugieren (Josh, 2026-11-13 and 15), proposed here:** the artwork is generated with
the `gpt-image` skill, every prompt naming colors from the app's palette (here the colorsets in
`Conjugar/Assets.xcassets`: `customBackground`, `customBlue`, `customCardBackground`,
`customCardBorder`, `customForeground`, `customGreen`, `customRed`, `customYellow`; read each
`Contents.json` for the light and dark hex values), and Josh picks among drafts; the personal best is
the best ranked score per level; Reset Practice forgets the bests.

**Ask Josh** to approve the list and a theme before any artwork is made. Konjugieren's was
architectural (Foundation Stones to Keystone) in the German flag's colors; Conjugar's red and yellow
suggest its own.

**From Konjugieren:** progress was reported as a percentage, held until signed in and loaded, and
only rises were sent, so a fall in the record never reached Game Center; sixteen PNG drafts added 17
MB to the app and Josh chose JPEG at quality 92; nothing signed in to Game Center could be tried on a
simulator.

**Done when** each achievement reports when its milestone is reached, under test with the double,
and the walkthrough covers achievements.

**How it differed:** _Not started._

## Phase 23: The Daily Challenge

**Ports:** Konjugieren Phase 24. **Suggestions:** T6.8. **Depends on:** Phases 4 and 21. **Status:**
Not started.

A daily shared challenge built on the quiz widget's daily question: the same short set for everyone
that day, seeded by the date, with a result the learner can share as text with the App Store link.
The report rates the basis as speculative. Make the quiz widget's question follow the challenge, and
its level, which today asks the verb of the day in a tense chosen by the day's offset
(`WidgetSnapshotWriter.makeQuizQuestion`).

**Decided for Konjugieren (Josh, 2026-11-13 and 15), proposed here:** one challenge per level per day,
five questions; the shared text names the date and level, shows a dot per question in the quiz's
colors with the points out of 50, and carries a link that opens the same challenge
(`conjugar://quiz/challenge?date=…&level=…`) above the App Store link; once a day per level, after
which the hub's row shows the result and shares it.

**Ask Josh** to approve the shared text, from a drafted example in both languages.

**From Konjugieren:** the key was the day in the learner's calendar and the level, so time zones
share by date; nothing on the device entered the draw; "the same for everyone" held within a build
and a corpus, so tests pinned determinism and the seed rather than a golden list; no re-ask in a
challenge; emoji dots drew as tofu on the iOS 26 simulator (Konjugieren's `docs/emoji_assets.md`),
so the app drew circles and kept emoji only in the shared text; the widget's wrong answers had to
avoid giving the answer away.

**Done when** two devices on the same date get the same challenge, the widget's question agrees with
it, sharing produces the agreed text, and tests pin the seeding.

**How it differed:** _Not started._

## Tasks for Josh Outside the Code

- **Leaderboards and achievements** in App Store Connect, by the walkthrough Phases 7 and 22 write,
  or by a session driving his Chrome if he prefers. On release day, add them for review with the
  version and retire the old leaderboard; `docs/release.md` lists these steps once Phases 7 and 22
  have written them there.
- **Checks on his phone**, which the simulator cannot make: posting a score signed in to Game Center,
  the Camera app opening a `conjugar://` QR code (Phase 9), the reminder notification's tap, and
  anything a phase marks "not tried on a device".

## Not Built

- **T2.4**, weighting a newly opened tense: Josh said no.
- **T4.6**, a language model wording a diagnosis: not applicable at this time. The tutor stays
  separate from the quiz.
- **T6.9**, making Toreo por Amor conjugate: outside this project.
- **M4 and M5**, accuracy signals: Decision 5.
- **Retiring the sad trombone**: Josh keeps it.

## Closing

- Run the full suite and read the count.
- Confirm that every suggestion in the index marked for a phase is built or recorded as cut.
- Audit the privacy staging: diff `Analytics/Analytics.swift` against the commit before Phase 0,
  read every call site, and confirm that each new signal, parameter, and value has its lines in
  `docs/privacy_policy_pending.md` in both languages, and that none carries an answer, a count of
  right or wrong answers, or a verb. Check `questionNumber` against re-asks, as Konjugieren's
  Closing found it leaking.
- Write a short list, at the end of this plan, of what Conjugar did differently from Konjugieren
  that the siblings could adopt.
- Mark this plan finished in its Status section.

**How it differed:** _Not started._

