# Plan: Fix What the Browse and Verb Review Found

**For:** a series of fresh Claude Code sessions, one phase per session as a rule. **Kind of work:**
app code, the widget extension, tests, and prose. **Written:** 2026-11-25, from
[`docs/verb_browse_review.md`](../docs/verb_browse_review.md) and Josh's answers to twelve
questions the same day. Konjugieren's plan for the same job, for comparison, is
[`../Konjugieren/plans/verb_browse_fixes.md`](../../Konjugieren/plans/verb_browse_fixes.md).

The review is the specification. Each phase below names findings by the review's own labels (C1,
P1, D2, and so on). Read the finding there before touching code: it gives the file, the line, the
evidence, and a suggested fix. This plan adds only the order, the grouping, Josh's decisions, and
what counts as done. Line numbers in the review are those of `7811ec9` and will drift as phases
land, so find code by name.

## Status

Each session that finishes a phase fills in its row, changes nothing in other rows, and writes a
**How it differed** note under that phase's heading. A finished phase is "Awaiting Josh" until
Josh has tried it and committed it. Sessions never commit (see step 9 below), so the Commit cell
is filled by the next session, which reads the hash from `git log`.

| Phase | Status | Date | Commit | Findings |
|---:|---|---|---|---|
| 1 | Done | 2026-11-25 | `a5c37cc` | C1, C4, C5, C6, and from C13 the homonym's sense and the guess's cell order |
| 2 | Done | 2026-11-25 | `4d5b2ec` | P1, and the wire names from T1 |
| 3 | Done | 2026-11-25 | `942f3a4` | C9, C12, G1, and from C13 Recent's count |
| 4 | Done | 2026-11-25 | `c0618fe` | C3, and a week of verbs for the widget |
| 5 | Done | 2026-11-25 | `57abe4c` | C2, C7, C8, G2, G3, G4, and from C13 the "All N" chip |
| 6 | Done | 2026-11-26 | `082a446` | From C13 the stashed link, the ignored link, the link beneath the game, and case; F2 (Spotlight); the intents and links of D3 |
| 7 | Done | 2026-11-26 | `1349e60` | D1 (the cheap pieces), D2, G6, G8, S5, and from C13 the Models tab's whitespace and trombone |
| 8 | Done | 2026-11-26 | `73df869` | D3 (the model layer), F2 (repeated work), S8 |
| 9 | Done | 2026-11-26 | `102ab01` | S1 (the search model), C10, C11, F1, S2, S3, S4, S7, and the rest of C13 |
| 10 | Done | 2026-11-26 | `ccfb31c` | S1 (the rest), G9 |
| 11 | Done | 2026-11-27 | `5d399e8` | D1 (`AdaptiveRows` and one row label), the rows' Spanish from G9, the outline's corners from C13 |
| 12 | Awaiting Josh | 2026-11-27 | | S6, and from S8 `mixesChoiceQuestions`' redundant test |
| 13 | Not started | | | T1, T2, T3, less what earlier phases added |
| Closing | Not started | | | The audit, G5's release step, the timed workarounds' list |

## How to Work This Plan

**Choosing a phase.** Take the lowest-numbered phase that is not done and whose dependencies are.
Phase 8 depends on Phase 1, because both edit the search's model files. Phase 10 depends on
Phase 9. Phase 11 depends on Phases 7 and 10. Every other phase stands alone and may be taken in
any order. If a phase proves too large for one session, split it, say so in its row, and leave
the remainder "Partly done". Phases 7 and 9 are the likeliest to need it.

**What this plan leaves to you.** The phases say what to fix and what Josh decided. The review
suggests a fix for each finding, and a better one is welcome. Record in **How it differed**
anything that departs from the phase as written: a scope change, a decision Josh made during the
session, or a piece deferred.

**A finding labeled Suspected or Reviewer in the review is not yet a fact.** Confirm it in the
code, or by running something, before fixing it. If it turns out not to be real, say so in **How
it differed** and under the finding in the review, and move on.

**Ask Josh when a decision here does not settle a question.** Phases 3, 5, and 7 each name one.
Do not guess at them. Ask before building the part that depends on the answer, and record the
answer and its date in **How it differed**.

**Every phase finishes the same way.**

1. Each fix gets a test that fails without it, in Swift Testing, following
   [`.claude/rules/testing.md`](../.claude/rules/testing.md). The review's Tests section names
   the missing ones; a test belongs to the phase that fixes its finding, and Phase 13 takes what
   is left.
2. Build and run the suite with the `ios-build-verify` skill, as `CLAUDE.md` describes. Read the
   run's `Test run with N tests` line, not only its exit status; a `--only-testing` selector that
   names a suite by its display string runs zero tests and still says "Test Succeeded". The
   baseline at `7811ec9` is 1,344 Swift Testing tests in 85 suites, plus 11 XCTest tests, in about
   78 seconds. Read the per-suite times too: the slowest then were "ConjugationMap" (19 s), "The
   bundled map" (13 s), and `ReverseLookupTests` (8 s).
3. Run `swiftlint` from the repo root. The tree stays at zero violations.
4. For any visible change, launch the app and look at it on both of Conjugar's simulators, "Conjugar
   iPhone 17" (`6318CA93-7FB5-4E19-B318-915010531F76`) and "Conjugar iPad Pro 11"
   (`3033197E-B596-4C49-AAD8-43373B9D254C`), as `CLAUDE.md` § Running the App in the Simulator
   describes. Never use another project's simulators. Name the UDID in every `simctl` command.
   Boot the iPad only for its check and shut it down afterward. Josh tries changes on an iPhone,
   so the session's check is the only one the iPad gets. Say in **How it differed** what was tried
   on each. **To seed the App Group's defaults, write the container's own plist with `plutil`
   while the app is terminated.** `simctl spawn defaults write group.biz.joshadams.Conjugar` lands
   in the simulator's ordinary preferences, which the app never reads; the review's session lost
   time to that (`docs/blog_notes.md`, 2026-11-25).
5. Localize any new string in English and Spanish, following `CLAUDE.md` and
   [`.claude/rules/localization.md`](../.claude/rules/localization.md). Never use the Edit tool to
   add or change an ASCII `"` inside an `.xcstrings` value. Strings used by `Shared/` or widget
   code belong in the widget's catalog too.
6. When a signal, parameter, or value is added or removed, stage its policy lines in
   [`docs/privacy_policy_pending.md`](../docs/privacy_policy_pending.md), in English and Spanish,
   and keep the vocabulary table in
   [`docs/feature_architecture.md`](../docs/feature_architecture.md#analytics) true.
7. Update [`docs/project_structure.md`](../docs/project_structure.md) for new, renamed, or
   repurposed files. Under each finding fixed, in `docs/verb_browse_review.md`, add a line saying
   it was fixed on `master`, with the date and this plan's phase. Correct any other doc the fix
   makes untrue.
8. Fill in the Status row, write **How it differed**, and append a journal entry to
   `docs/blog_notes.md` (`## <Title> (YYYY-MM-DD)`, narrative, no em dashes between clauses).
9. **Stop before git.** `CLAUDE.md` says sessions do not commit, push, or create branches. Leave
   the changes in the working tree on `master` and tell Josh what changed and how to try it: which
   screens, what to type or tap, on which device. Each phase's **Tell Josh to try** is the start
   of that message. He commits with his own `/commit-and-push` skill.

**No release before 2027.** Everything accumulates on `master`. A step that must wait for the
release goes in [`docs/release.md`](../docs/release.md).

**Conjugar only.** Do not port a fix to Konjugieren or Conjuguer, and do not edit their files.
The Closing lists what might carry over.

## Decisions Already Made

Josh's answers on 2026-11-25, numbered as the review's Open Questions are.

1. **P1.** When the source is `quizCorrection`, `viewCollection` carries no `collection`
   parameter. The staged privacy text stays as written.
2. **C1.** Clitic agreement is strict: *te* on a tú or vos command, *os* on vosotros, *nos* on
   nosotros, *se* on usted and ustedes; any of them on a gerund or an infinitive; a clitic
   followed by lo, la, los, or las stays free. Rare object uses such as tú + *os* are rejected.
3. **C2.** The red-letter tip appears only where the verb itself has red letters. A marked
   auxiliary in a compound tense does not count.
4. **C4.** Exact spelling wins in Look Up a Verb: "sonar" opens sonar's page and "soñar" opens
   soñar's. A folded infinitive answers only when nothing literal does.
5. **C8.** "Built on" is a claim about etymology. transpirar, contemplar, and impedir lose their
   bases. Pairs that are true by etymology and opaque to a learner (acercar, contestar, preparar,
   revelar) stay.
6. **C9.** Collection progress is separate from My Verbs. A verb counts once it has ever been
   opened. Clear and the swipe forget only what puts a verb in My Verbs. Clear asks first.
7. **A link that arrives during the game closes the game.** Sheets that views own (Test Me, an
   article) are left alone, consistent with Josh's decision of 2026-11-24 about a practice set
   behind a sheet.
8. **G6.** The Models tab's search field stops autocorrecting and autocapitalizing. The iPad
   drawer is shown to Josh as a screenshot before it is kept.
9. **The widget.** The app writes a week of verbs of the day, so that the widget changes at
   midnight without the app being opened.
10. **A stashed link** is drained at once when the app is in front, and one older than a minute
    is dropped unopened.
11. **G5.** The practice record's migration is deleted at release time, by a step in
    `docs/release.md`, not now.
12. **Duplication: everything.** The cheap shared pieces, a search model for `VerbBrowseView` with
    `MyVerbsList` and `FailedSearchHelp` as views of their own, a generic `AdaptiveRows` for the
    grid-or-list block, and one row label with a style for the verb, model, and collection rows.

Defaults this plan chose without asking, because the review left one reasonable course. Josh may
overrule any of them:

- **C6.** A verb link may name the cell to mark, in a new query item, when the text alone is
  ambiguous.
- **C12.** A record that fails to decode is copied to a backup key before anything overwrites it.
- **S7.** The sort picker is disabled while the search field has text.
- **From C13.** The sad trombone plays when the text changes to a failed query, and not on a sort
  change. A link's scheme and route are compared without regard to case; a verb's name is not. A
  `+` in a link's `q` stays a plus sign.
- **F2.** Spotlight is indexed at background priority, and skipped when the app's version and the
  verb count match the last run's.
- **Costs of Settled Decisions.** A lookup from the widget still counts as a lookup, a verb
  deleted from My Verbs can still be offered by the review card, and a third-person-only verb
  still shares as one form. This plan changes none of them.
- **Subagents.** No phase requires them. A session that delegates implementation follows the
  browse plan's rule, Sonnet subagents, and reads and checks their work itself.

## Phase 1: The Lookup Tells the Truth

**Findings:** C1, C4, C5, C6; from C13, the homonym's second sense and the guess's cell order;
from T1, `VerbLookupTests`' assertion that cannot fail. **Depends on:** nothing.

- **C1.** In `FormLookup`'s enclitic branch, a parse is kept only if its first clitic agrees with
  the cell, by the rule in Decision 2. Put the rule in one function beside
  `ReflexivePronoun`'s own pronoun table, so that the two cannot disagree about which pronoun a
  person takes.
- **C4.** In `VerbLookup`, the literal tier is the exact infinitive, the exact gloss sense, and
  the literal conjugation. The folded infinitive answers with the folded conjugation, and only
  when the literal tier is empty. Make the comment and the code say the same thing.
- **C5.** `FormLookup.confirmed` tries `.bare` after `.exact` and `.folded`, and `spelling`
  follows.
- **C6.** `VerbLookup` and the Verbs tab's rows already know the cells they matched. A verb link
  carries them when `match` alone would mark more: add a query item that names cells by
  `ConjugationCell.code`, have `AppRouter` prefer it to `match`, and add the route to the grammar
  in `docs/feature_architecture.md` § Deeplinks and to `CLAUDE.md`'s examples. A link without the
  item behaves as before.
- **The homonym.** Look Up a Verb names the gloss that matched. If answering with that sense's
  key conjugations needs more than `Match` carrying the sense's index, record what it would take
  and leave the conjugations as they are.
- **The guess** names its cells in the page's order, through `FoundForms` or the same ordering.

**Done when** tests pin, by the lines a row shows and not only by its verb:

- hablase and pasase give one line, the Imperfecto de Subjuntivo 2, and no command;
- levantaos gives "Imperativo Positivo (vosotros)" alone;
- levántate, dámelo, dime, siéntese, vámonos, and arrepintiéndose still find their verbs and
  cells;
- "he ensenado" names the Perfecto de Indicativo of enseñar;
- Look Up a Verb gives sonar, soñar, ordenar, and ordeñar each a page as its destination, and
  "sonar" names one verb;
- a lookup of levántate opens a link that marks the imperativo's tú alone, and the page lands on
  that card.

`ReverseLookupTests`, `VerbLookupTests`, and `VerbSearchTests` pass, with any expectation that
changes explained. Replace `VerbLookupTests`' `named.count == maxNamedVerbs ||
named.contains("comer")` with an assertion that can fail.

**Tell Josh to try:** in the Verbs tab, hablase, levantaos, levántate (open it, and see where the
page lands), and "he ensenado"; in the Shortcuts app, Look Up a Verb for soñar and for sonar.

**How it differed:**

- **C1, a decision changed (Josh, 2026-11-25).** Decision 2 named *nos* only on the nosotros
  command. Asked, Josh chose to leave *nos* free on every command, because it is also a common
  object (dinos, danos, ayúdanos, díganos, dadnos), and the strict rule would have sent each of
  them to the guess. *te*, *os*, and *se* agree strictly as decided; *me* was never constrained.
  The rule is `ReflexivePronoun.encliticAgrees(_:with:)`, which reads `pronoun(for:)`.
- **C6.** The new query item is `cells`, a comma-separated list of `ConjugationCell.code`s:
  `conjugar://verb/levantar?source=lookup&match=levanta&cells=ioss`. `VerbLookup` adds it only
  when `match` alone would mark cells the form is not (levántate, dámelo); every link the tests
  pinned before is unchanged. A `cells` whose codes are all junk falls back to `match`. The
  marking function moved from `AppRouter.marks` to `MatchedForm.marks(of:on:hiding:)`, so that the
  nonisolated lookup can ask what a `match` would mark. The Verbs tab's rows push in-app with their
  cells already, so only the lookup builds such links.
- **The homonym.** No `Match` change was needed: `VerbSearch.sense(of:namedBy:)` finds the gloss,
  and `Finding.verb` carries its index, so "station" answers "apostar, “station”: apuesto · …". The
  key conjugations stay the first sense's. Answering with the second sense's would take a
  model-taking `KeyConjugation.forms` (through `TenseBridge.conjugate(…model:)`, which is unmarked,
  and `ModelCatalog.model(forClass: entry.classNumbers[sense])`, with the reflexive pronoun added by
  hand), and it would then disagree with the page the lookup opens, which conjugates only the first
  sense. Doing it right means a sense-aware verb page, which no phase plans.
- **The guess's order is a latent bug.** A probe over all 254,000 map entries found none whose cells
  were out of page order, although the map's own order puts the pretérito before the imperfecto and
  the futuro before the presente de subjuntivo. No verb shares a form across those tenses. The fix
  (`ConjugationMatch.inPageOrder`, which `FoundForms` now uses too) is pinned by a test that builds
  a small map whose order disagrees with the page's.
- **C4.** Beyond the four infinitives named, the tests pin acunar and acuñar as well.
- **Checked in the simulators.** On the iPhone: hablase shows one line (Imperfecto de Subjuntivo 2
  (yo, él)), levantaos one (vosotros), "he ensenado" names he enseñado's Perfecto de Indicativo, and
  the levántate link lands on the Imperativo Positivo card with ¡levanta! marked alone. On the iPad,
  in Spanish with vos shown: levantaos and the levántate link, the same results. The Shortcuts app
  was not tried; `VerbLookupTests` covers soñar and sonar.
- **The suite** is 1,357 Swift Testing tests in 85 suites and 11 XCTest tests, in 107 s against the
  baseline's 78 s. The slowdown sits in suites this phase did not touch ("ConjugationMap" 31 s,
  "The bundled map" 21 s), so it looks like machine load. `ReverseLookupTests` took 9.8 s against
  8 s.

## Phase 2: A Correction's Link Names No Verb

**Findings:** P1; from T1, the wire names. **Depends on:** nothing.

- `VerbCollection.signalView(source:)` omits `collection` when the source is `quizCorrection`. A
  test with `AnalyticsSpy` pins both cases.
- `docs/feature_architecture.md` § Analytics says so beside `viewCollection`. Read the staged
  Collections lines in `docs/privacy_policy_pending.md` and confirm that "never a verb" is now
  true of everything the app sends; Josh decided that the wording stays.
- Pin `SearchMatchKind`'s wire names by a literal list, `guess` and `none` included, as
  `sourceValuesAreStable` pins the sources. The reviewer also found no literal in the tests for
  `startQuiz`, `tapDailyReminder`, `enabled`, or `streak`; confirm that, and extend
  `AnalyticsTests`' tables if it is so.
- Correct `AnalyticsSource.control`'s doc comment, which names only the Random Verb control.

**How it differed:**

- **P1.** `VerbCollection.signalView(source:analytics:)` leaves out `collection` for
  `quizCorrection`, and takes the analytics service as a parameter that defaults to
  `Current.analytics`, so that the test hands it a spy of its own instead of reading the shared one.
  `VerbCollectionTests.aViewNamesItsCollectionExceptFromACorrection` pins five sources, the
  correction's the only one without the key. `ParameterKey.collection`'s and
  `AnalyticsName.viewCollection`'s doc comments, the `viewCollection` and `quizCorrection` rows of
  `docs/feature_architecture.md` § Analytics, and a note under the staged "Links on a quiz's
  correction" section of `docs/privacy_policy_pending.md` say so. The policy's wording is untouched.
- **"Never a verb," checked against all 45 `signal(` calls.** No parameter carries an infinitive
  or anything typed. Two things come close, and neither is new. A model's key names a verb in
  effect for the 29 models of one verb wherever the page is opened from, but there it says what
  the learner chose to open, not what they got wrong. And from a correction's model page, the
  learner may go on to tap Share (`tapShareCollection`) or the collection's quiz (`startQuiz`),
  each carrying the model's key under its own source. Joining either to the correction takes a
  session's sequence of signals, and each is a deliberate act. This phase leaves both alone; Josh
  may want to know.
- **T1's wire names.** `LookupSignalsTests.matchKindValuesAreStable` pins `SearchMatchKind` by a
  literal list, `guess` and `none` included, and the `MatchKind`-to-wire mapping by another, since
  `matchKindIsSentByItsName` passes when both enums are renamed together. I kept that test; it
  still says why the names match. `outcomeValuesAreStable` pins `SearchOutcome` too, which nothing
  pinned. The reviewer was right that `startQuiz`, `tapDailyReminder`, `enabled`, and `streak` had
  no literal anywhere in the tests; `AnalyticsTests`' two tables now carry them. Twenty-four
  parameterless signal names still have no literal. `AnalyticsTests`' comment limits its table to
  the signals that carry parameters, and this phase kept to that.
- **`control`'s doc comment** names both controls that send it and says that the Quick Quiz
  control sends `deeplink`, which `docs/feature_architecture.md` already said.
- **No visible change**, so no simulator check. No new string, file, or signal value.
- **The suite** is 1,360 Swift Testing tests in 85 suites and 11 XCTest tests, in 83 s. The
  slowest suites are "ConjugationMap" (19.5 s), "The bundled map" (12.9 s), and
  `ReverseLookupTests` (10.2 s), back near the baseline after Phase 1's 107 s run.

## Phase 3: The Learner's Record

**Findings:** C9, C12, G1; from C13, Recent's count; from S8, `daysSinceOpened`. **Depends on:**
nothing.

- **C9.** `hasOpened` reads `firstOpened`. `clearRecents` and the swipe's `remove` forget
  `lastOpened` (and the star, for the swipe) and keep `firstOpened`. An entry with only
  `firstOpened` appears in neither Starred nor Recent, and is not dropped by `store`. An entry
  written before this phase still decodes, and one with `lastOpened` but no `firstOpened` counts
  as opened. Tests pin each. Clear asks before it clears, with an alert in the manner of the
  starred row's. The starred row's swipe is labeled for what it now does; propose the English and
  Spanish wording to Josh if "Delete" no longer fits.
- **Ask Josh.** After this change nothing in the app forgets which verbs were ever opened, and
  Phase 12 of the browse plan added Clear partly so that there would be a way. Ask him where a
  full forget should live. Candidates: Settings' existing Reset Practice also forgets
  `firstOpened`; or nowhere, since the record never leaves the device. The staged privacy
  paragraph about the list kept on the device may need a clause either way.
- **C12.** When the stored `learnerVerbs` string fails to decode, `LearnerVerbStore` copies the
  raw string to a backup key before its first save. Confirm the reviewer's account of
  `PracticeStore` (a failed decode runs the migration again), and give the practice record the
  same protection if so. A test feeds each store a corrupt string.
- **Recent** shows up to twenty unstarred verbs, by filtering before taking the limit. Remove
  `recent(limit:)`'s parameter if nothing passes it.
- **G1.** Correct the comments in `Shared/LearnerVerbs.swift`, `World.swift`, and
  `GetterSetterReal.swift`, and `docs/feature_architecture.md`'s paragraph: the widget reads the
  snapshot, not the record. Keep the rule that added fields must be optional, with its true
  reason, an app upgrade.
- Delete `LearnerVerbs.daysSinceOpened` if it still has no caller.

**Tell Josh to try:** open a verb from a collection, swipe it out of My Verbs, and see that the
collection still counts it; Clear, with its new question; a starred verb's swipe.

**How it differed:**

- **The full forget (Josh, 2026-11-25).** Asked where it should live, Josh chose Settings' Reset
  Practice. It now also calls `LearnerVerbStore.forgetOpenHistory()`, which clears every
  `firstOpened` and `openCount` and keeps the stars and Recent, so the collections count nothing
  until a verb is opened again. Reset Practice shows when the practice record holds anything or
  any verb counts as opened, since opening only regular verbs leaves the practice record empty.
  Its description and its alert's message gained a sentence each, in English and Spanish. The
  staged privacy paragraph about the list kept on the device is rewritten in a new section of
  `docs/privacy_policy_pending.md`.
- **The swipes (Josh, 2026-11-25).** Both say Remove / Quitar, in place of Delete / Eliminar; the
  key is now `MyVerbs.remove`. The recent row's icon changed from a trash can to `minus.circle`,
  since nothing is deleted. The starred row's alert keeps its title, and its message now says that
  collections still count the verb. Clear asks "Clear your recent verbs?" with a message saying
  that the stars and the collections' counts stay.
- **"One with `lastOpened` but no `firstOpened` counts as opened" was dropped.** `hasOpened` reads
  `firstOpened` alone. No build ever wrote such an entry: `recordOpen` has set both since the
  record began (`998795b`). After Josh's decision, it is exactly what Reset Practice leaves for a
  verb still in Recent, which must not count. Honoring both would take a second date or a flag,
  for a case nothing produces. A test pins that an entry as earlier builds wrote it decodes and
  counts.
- **`recent(limit:)`** had no caller passing a limit. It is now `recent`, the search field's
  recents (starred verbs included, as before), beside a new `recentUnstarred`, which filters before
  taking twenty and is My Verbs' Recent and the second half of `myVerbs`. `myVerbs` can therefore
  grow by up to the number of starred recents, which is what the docs always said it held.
- **C12.** The reviewer's account of `PracticeStore` was right, and it was worse than written: the
  store saved the migrated record at launch, so a corrupt record was overwritten before anything
  else happened. Both stores now copy an unreadable string to a key of its own
  (`learnerVerbsUnreadable`, `practiceRecordUnreadable`) through a `GetterSetter` extension,
  `backUpUnreadable(_:to:)`. The practice store no longer migrates over an unreadable record; it
  starts empty, since a stored string means that this is not a first launch.
- **G1.** Beyond the three files and the doc paragraph named, `PracticeRecord`'s two comments
  claimed that the widget (or a reminder) reads the practice record. Neither does, and both were
  corrected. `LearnerVerbs.swift` stays in `Shared/`.
- **`daysSinceOpened`** had no caller and is deleted.
- **Checked in the simulators**, with a record seeded by `plutil` (tener and hablar recent, hacer
  starred, salir with only a first open). On the iPhone, in English: the -go collection read "3 of
  11 looked up", salir included and absent from My Verbs; tener's swipe said Remove and took it out
  of Recent; Clear asked its question and emptied Recent; hacer's swipe showed the new alert
  message; the collection still read 3 of 11. Settings ▸ Reset Practice showed the new sentences,
  and afterward the collection read 0 of 11, also after a cold relaunch, with hacer still starred.
  On the iPad, in Spanish: Mis verbos, "¿Borrar tus verbos recientes?" and its message, only hacer
  left after Borrar, and "Consultados: 3 de 11".
- **The suite** is 1,370 Swift Testing tests in 85 suites and 11 XCTest tests, in 80 s. The slowest
  suites are "ConjugationMap" (18.8 s), "The bundled map" (12.5 s), and `ReverseLookupTests`
  (8.7 s). Two expectations changed, both on purpose: `LearnerVerbsTests`' Clear and removal tests,
  and `VerbCollectionTests`' progress test, now say that Clear and a swipe keep a collection's count.

## Phase 4: The Widget's Verb Changes Daily on Its Own

**Findings:** C3; the review's second cost of a settled decision. **Depends on:** nothing.

- **C3.** `VerbDraw.verbOfTheDay` takes My Verbs in turn over an order that opening a verb does
  not change, such as the infinitives sorted. Test with a list that gains a verb, and one that is
  reordered, between My Verbs days: no verb repeats while another waits.
- **A week of verbs.** `WidgetSnapshotWriter` writes the verb of the day for today and the six
  days after, keyed by date, and the Verb of the Day widget's timeline returns one entry per
  midnight. Read `WidgetSnapshot`, the writer, and `ConjugarWidget/VerbOfTheDayWidget.swift`
  first, and the Lock Screen accessories that show the same verb. Things to settle and record:
  - how the snapshot's format grows without breaking a widget that reads an older file, and the
    reverse;
  - what the widget shows on the eighth day (the last verb written, as now, is acceptable);
  - whether the writer's date gate, which skips a refresh the same day, must now also notice that
    My Verbs changed;
  - the reference date and `dateString`, which the reviewer found read `Calendar.current`. Use a
    Gregorian calendar in the current time zone, so that a Buddhist or Japanese calendar setting
    cannot shift the day numbers.
- **The quiz widget's question** has the same limit: `QuizWidget` also returns one entry and
  reloads at midnight. Josh's answer was about the verb of the day. If the challenge's first
  question is as cheap to write a week ahead, do it in the same way and say so; if it is not,
  leave it and record why.
- The widget target has its own copies of the rendering helpers and its own string catalog. A
  change to the snapshot's shape is a change to both targets.

**Done when** tests pin the rotation over a changing list; a test drives the writer for a given
day and reads back seven dated verbs that match `VerbDraw` for each day; and the widget, with the
simulator's clock or a snapshot written for past dates, shows the verb for its own date and not
the first one in the file.

**Tell Josh to try:** add the Verb of the Day widget, note the verb, and leave the app closed
overnight.

**How it differed:**

- **C3 needed a record, not only an order.** Sorting My Verbs stops a reordering from bringing a
  verb back, but any turn taken by position (`turn % count`) still repeats one when the list
  grows, which a newly opened verb does. A turn now goes to the verb whose last turn is oldest, one
  never shown first, ties by infinitive (`VerbDraw.myVerbsTurn(in:lastShown:)`), and the app keeps
  the record of turns in the widgets' file. A verb that leaves My Verbs leaves the record, so one
  that returns counts as new. `myVerbsGetEveryThirdDayInTurn` and
  `theWidgetsNextTenDaysComeFromTheBandOrMyVerbs` changed their expectations: the first turns now
  go in alphabetical order (abolir before churruscar), and they thread the record from day to day.
  Against the old turn, the new rotation tests fail with 1,124 issues on the reviewer's scenario.
- **The file's format.** One day keeps the name `WidgetSnapshot`; a new `WidgetWeek` holds seven.
  It encodes the first day's keys at the top level and the rest under `laterDays`, so a widget that
  knows one day reads the first from a week and a widget that knows the week reads an old file as a
  week of one. App and widget ship together, so only the second case should ever happen, after an
  update and before the app is opened. The app's bookkeeping (`myVerbs`, `myVerbsTurns`,
  `myVerbsShown`) is optional and ignored by the widget.
- **The eighth day** shows the last day written, as accepted. Both widgets' timelines end at the
  midnight after the last day, when WidgetKit asks again.
- **The gate notices My Verbs.** Without it, a verb opened today would wait for the next day the app
  is opened to be planned, and a verb removed could still come up within the week. The gate compares
  the names sorted, without loading the verb map. A rewrite keeps the verb of today if the previous
  week held today, so opening the app never changes the verb the widget showed since midnight, and
  `MainTabView` now also refreshes when the app goes to the background, so a session's change to My
  Verbs reaches the planned days before the learner leaves for a week. The reload happens only when
  something changed, as before.
- **The calendar.** A new `Shared/CalendarDay.swift` names days in the Gregorian calendar and the
  current time zone; `DailyChallenge`'s three day functions now forward to it. The writer's day
  numbers and `dateString` use it, and so do the widgets' midnights. For a Gregorian user every day
  number is unchanged.
- **The quiz widget's question** was as cheap to write ahead: each day carries its own challenge's
  first question, the quiz widget has an entry per midnight, and `AnswerQuizIntent` grades against
  the day whose question ID the tap names.
- **Checked in the simulators.** On the iPhone, the app wrote seven dated days (inscribir on
  2026-11-25). With the app closed, the file's dates were shifted back two days, and the widget
  gallery's preview (the widget's `getSnapshot`) showed identificar, the entry for 2026-11-25, not
  the file's first. Placing the widget on the iPhone's Home Screen crashed SpringBoard twice, in its
  own `SBHRippleSimulation` (iOS 26.3 simulator), so the iPhone's timeline was not seen. On the iPad,
  in Spanish with hacer in My Verbs, the week put hacer on days 330 and 333; with the dates shifted
  back four days, the gallery and the placed widget (its timeline) both showed procesar, the entry
  for today. Opening the app then rewrote the week from today and kept procesar, where a fresh plan
  would have drawn inscribir. A real midnight on a device is left to `docs/release.md` step 11.
- **The suite** is 1,384 Swift Testing tests in 86 suites and 11 XCTest tests, in 84 s. The slowest
  suites are "ConjugationMap" (20.5 s), "The bundled map" (14.2 s), and `ReverseLookupTests`
  (10.2 s). The new `WidgetWeekTests` takes 0.4 s.

## Phase 5: The Verb Page

**Findings:** C2, C7, C8, G2, G3, G4; from C13, the "All N" chip; from F2, `VerbView.init`; from
T1, the reflexive sweep. **Depends on:** nothing.

- **C2.** The red-letter tip's guard looks at the simple tenses and the three header forms only.
  Put the question on a model type so that a test can ask it: false for hablar and abaratar, true
  for tener. Whether a spelling-change verb such as buscar counts follows from what the engine
  marks in its simple tenses; pin whichever it is. Correct `RedLettersTip`'s doc comment.
- **C7.** The scroll tip is drawn, and unlocked, only on a page that has an etymology or an
  example.
- **C8.** Add transpirar, contemplar, and impedir to `VerbRelations.falseCompounds`, and correct
  the comment's claim about pirar. `RelatedVerbsTests` pins the three, and that the opaque pairs
  Josh kept (acercar on cercar, preparar on parar) still hold.
- **G2.** Reword `KeyConjugation`'s comment, the comment on `PracticeItem.Key.init(tense:)`, and
  `docs/feature_architecture.md`: the imperfect and future subjunctives follow the pretérito's
  third-person plural. The four forms do not change.
- **G4.** A `VerbPageSection` for the Related Verbs card, reported like the etymology's. It is a
  new value of `deepestSection`: add it to the vocabulary table, and check that the staged privacy
  line about how far a page was scrolled still covers it.
- **G3.** Move a visit's begin-and-end pairing out of `VerbView`'s body into a small type that a
  test can drive: appear, disappear, each `scenePhase`, and the landing scroll. The landing scroll
  to a marked form should not count as the learner reaching a section. **Ask Josh** about sheets:
  a visit's dwell counts time under the article sheet and the Test Me quiz. The recommendation is
  to end the visit when either presents and begin a `resume` visit when it closes, which matches
  "on screen" in the docs. It raises the count of `resume` views, so he should agree first.
- **The "All N" chip** appears when the model has more verbs than the row shows.
- **`VerbView.init`** (Suspected). Put a temporary print in `init`, open a verb from the search
  field's recents, and star a verb pushed from My Verbs. If the init reruns, move the page's
  content into a value computed once per verb and held in `@State`. If it does not, record that
  and leave it. Do the same check for `ModelView.init`, which Phase 8 lightens either way.
- **The reflexive sweep.** Add a golden table of joined forms, the gerund and the six commands,
  for about a dozen reflexive verbs of different shapes (-ear, -iar, -uir, ue and ie diphthongs,
  ü, qu and gu, a one-syllable command). The reviewer's 46 cases, all right today, are in the
  review's T1; the table is a guard, not a fix.

**Tell Josh to try,** on a fresh install so that TipKit has no history: hablar's page (no
red-letter tip), then tener's (the tip), then close it and open abaratar (no scroll tip) and
tener again (the scroll tip); transpirar's and impedir's Related Verbs; a model with many verbs
over few roots, for the chip.

**How it differed:**

- **G3, the sheets (Josh, 2026-11-25).** Asked, Josh chose the recommendation: a sheet over the
  page (a tense's article, Test Me) ends the visit, and its closing begins a `resume` one. The
  logic is `VerbVisitTracker` (`Models/VerbVisitTracker.swift`), a value type that `VerbView`
  reports to and whose returned events it sends; `VerbVisitTrackerTests` drives the screen, the
  foreground, a sheet, and the landing. A visit begins only when the page is on screen and
  uncovered, so the app returning under a sheet begins nothing.
- **The landing scroll** begins when the page scrolls itself to a marked card and ends at the
  learner's first drag (`onScrollPhaseChange`, phase `interacting`). Until then, a section coming on
  screen is recorded as visible but not reached, and a resumed visit starts from the header. In
  the iPhone simulator, with a temporary log, `conjugar://verb/hablar?match=he%20hablado` landed on
  the Perfecto with the phase still `idle` and nothing reached; a drag reported `interacting`, and
  scrolling down then reached `compound`, `etymology`, `example`, and `related`. A section the
  landing showed and that stays on screen after the drag is never reached in that visit; a learner
  who reads only the landed card reports `header`. That is the plan's wording taken literally.
- **C2.** The page's forms moved into `VerbPageForms` (`Models/VerbPageForms.swift`), with
  `ConjugationSection` and `ConjugationDisplayRow`, and it takes the learner's tú-or-vos choice as
  a parameter so that a test can build it. `hasRedLetters` is computed once there. buscar counts:
  the engine marks busQUé.
- **C7** asks `ScrollToBottomTip.hasTarget(onPageOf:)`, which reads the etymology, the example,
  and the medieval examples. The view computes it once in `init`.
- **The "All N" chip** appears when the model's other verbs outnumber the chips shown
  (`RelatedVerbs.modelHasMore`). The page's own verb is not counted as hidden, since it is the
  page. mover's page (five chips over twelve verbs) now shows "All 12"; hacer's shows "All 3" beside
  one chip, satisfacer, since deshacer sits in the built-on row. `shortListLength` moved to
  `RelatedVerbs`.
- **C8.** `RelatedVerbsTests.theRelationCountsHold` changed on purpose: 973 verbs have a base
  (976 before) and 604 roots have another verb built on them (605). The comment no longer calls
  pirar a base of anything.
- **`VerbView.init` and `ModelView.init` do not rerun.** With a print in each: one init per push,
  and none on starring (from the list and from My Verbs), opening from the search field's recents,
  or returning from a pushed page. Recorded and left.
- **The reflexive sweep** is a golden table of fourteen verbs, every shape the plan named plus
  dar, hacer, and reír: the reflexive-only ones as their page writes them, the others through
  `ReflexivePronoun.attach`. Every expectation, written by hand first, matched (dese, reíte, huite,
  huíos, desvergüénzate among them).
- **G4.** `related` is a new value of `deepestSection`. The staged policy bullet named the sections
  one by one, so a new section of `docs/privacy_policy_pending.md` rewrites it, in both languages,
  and says "in view" for the dwell, which sheets now end.
- **Checked in the simulators.** On the iPhone, after uninstalling for a fresh TipKit store:
  hablar showed no tip; tener showed Red Letters, which I closed; abaratar showed no tip; tener
  then showed Keep Scrolling. transpirar's card has only "Conjugated like cantar"; mover's has
  "All 12". On the iPad, in Spanish: hablar with no tip, tener with Letras rojas, impedir with
  pedir among "Se conjugan como pedir" and no "Formados con", and mover with "Ver los 12".
- **The suite** is 1,404 Swift Testing tests in 88 suites and 11 XCTest tests, in 194 s. The
  slowest suites are "ConjugationMap" (48.4 s), "The bundled map" (32.4 s), and
  `ReverseLookupTests` (21.4 s), all untouched here; a Konjugieren test run was going on the same
  Mac at the time. The targeted run of this phase's six suites took 22 s.

## Phase 6: Links, Intents, and Spotlight

**Findings:** from C13, the stashed link, the ignored link, the link beneath the game, and case;
from F2, Spotlight; from D3, the intents and the links; from G7, the router's prose; from T2, the
widget's literals. **Depends on:** nothing.

- **The stashed link** (Decision 10). The stash carries the time it was written. The app drains
  it on activation, as now, and also when it changes while the app is in front; an intent that
  runs in the app's own process can route directly. A stash older than a minute is removed
  unopened. Tests pin the expiry with an injected clock. To try the in-front case for real, run
  the Open Random Verb shortcut from the Shortcuts app in Split View or Slide Over on the iPad
  simulator, and say whether that was possible.
- **An ignored link** leaves an open practice set alone: `handle(url:)` clears
  `pendingPracticeSet` only once a route has resolved. A test: a set survives
  `conjugar://verb/xyzzyq`.
- **A link during the game** (Decision 7). A route other than `game` sets `showGame` to false.
  Settings' Play button and its tour reshow present from local state (`showingGame`,
  `showingOnboarding`), which the router cannot see, so move both to the router's flags; that
  also makes `presentablePracticeSet`'s guard true of the game Settings opens, which today it is
  not. Check the onboarding's "game after the tour" handoff afterward, since both presenters use
  it.
- **Case.** Compare the scheme and the route without regard to case.
- **The intents.** One protocol in `Shared/` gives the four stashing intents a single
  `perform()`. `WidgetDeeplink` moves to `Shared/`, builds its links from the same constants as
  `URL`'s builders where the widget target can see them, and is pinned by `AppRouterTests`. Count
  the `"conjugar://"` literals before and after. Strings stay in both catalogs.
- **Spotlight.** Index at background priority. Skip the run when a stamp of the app's version and
  the verb count matches the last run's. When the stamp changes, remove by identifier the entries
  of verbs no longer in the map; do not delete by type, which the doc comment warns empties the
  named index. `docs/release.md` already asks for a Spotlight check on a device; add what this
  changes.
- **`VerbEntityQuery.entities(matching:)`** (Suspected) may run its first load on the caller's
  executor. `LookUpVerbIntent` is `@concurrent` for that reason. Measure, and match it if needed.
- **Prose.** `AppRouter`'s header comment, the misplaced doc comment and the "only controls"
  comment in `MainTabView`, and the three rows of `docs/feature_architecture.md` § Deeplinks that
  G7 names.

**Tell Josh to try:** a widget tap during the game; Settings ▸ Play and the tour from Settings;
the Random Verb and Find a Verb controls; a verb found in Spotlight after a second launch.

**How it differed:**

- **The stashed link is announced, not routed directly.** `PendingDeeplink` (`Shared/`) writes the
  link with the time it was written, and the intent posts a Darwin notification
  (`notify_post`), which reaches every process. `MainTabView` listens with
  `PendingDeeplink.announcements()` and drains on each, as well as on activation. The plan allowed an
  intent running in the app's own process to route directly; the notification already reaches that
  process too, so there is one path wherever the intent runs. A stash older than a minute, or
  without a date, as earlier builds wrote it, is removed unopened. `PendingDeeplinkTests` pins the
  expiry with injected dates and a defaults suite of its own.
- **Split View or Slide Over was not tried.** The iPad simulator runs iPadOS 26 in full-screen app
  mode, and getting the Shortcuts app into a side window with AXe would have taken long. Two checks
  stand in for it. With Conjugar in front on the iPad, writing a dated stash through `cfprefsd`
  (`simctl spawn … defaults write <container plist path>`) and posting the announcement with
  `notifyutil -p` from another process opened a random verb (empatar) at once and removed the stash.
  And running Verbo aleatorio from the Shortcuts app opened one (disminuir), which shows that the
  shared `perform()` works for the real intent. Siri with Conjugar in front is in `docs/release.md`
  step 5.
- **One protocol, one grammar.** `LinkStashingIntent` gives the four intents one `perform()`, and
  each names a `link: URL?` in place of the old `pendingDeeplink` string. The grammar's constants,
  `isDeeplink`, and the raw builder moved from `Utils/URLExtension.swift` to
  `Shared/DeeplinkGrammar.swift`, so the intents and `WidgetDeeplink` (now in `Shared/`) build from
  them; only their `source` values are literals, since `AnalyticsSource` stays in the app.
  `URL.quizStartTarget` is new. `"conjugar://` literals in code: seven before, none after.
  `AppRouterTests` pins every intent's and widget's link whole and routes it.
- **The game and the tour moved to the router.** Settings' Play sets `router.showGame`, and Show
  Onboarding calls `router.reshowOnboarding()`, which sets `isOnboardingReshow` for
  `MainTabView`'s one tour cover; `onboardingDismissed()` clears it and makes the game hand-off.
  `GameView.router` is no longer optional. A link that resolves, other than `game`, closes the game;
  a practice set's link does too, and its sheet shows once the cover is gone. A link that resolves
  to nothing leaves both the practice set and the game.
- **Case.** The scheme and the route (the host) ignore case, and so does `PracticeSet(url:)`, which
  checks the host itself. Keywords in the target position (`random`, `set`, `boss`) keep their
  case, as a verb's name does; the plan named only the scheme and the route. In the simulator,
  `CONJUGAR://LIST/goVerbs` made iOS ask "Open in Conjugar?" first, then opened the collection.
- **Spotlight.** The stamp is the version, the build, and the verb count ("3.1 (1), 4811 verbs"),
  kept with the indexed infinitives in `Caches/spotlight_index.json`. Caches, because a backup
  leaves it out: an app restored to a new device, whose Spotlight index starts empty, finds no
  record and indexes. The record is written only after the index takes the entries. On the iPhone
  under very heavy load (a load average near 300, with Konjugieren's and Conjuguer's tests running),
  building the entries at background priority took four and a half minutes and the record appeared
  ten minutes after launch; the next launch skipped the work, Spotlight still found aprender, and
  tapping it opened aprender's page. A development build keeps its stamp, so a change to the
  entries reaches the simulator only after the app is deleted; the doc comment says so.
- **`VerbEntityQuery` was not slow as App Intents calls it.** A temporary probe with a query of the
  same shape ran `entities(matching:)` on the main thread when called directly from the main actor,
  and off it when called through `EntityStringQuery`, as the framework calls it. A cold
  `entities(matching: "fue")` took 7.8 s. The three methods are `@concurrent` anyway, so that a
  direct caller cannot stall.
- **Prose.** Beyond what the phase named: `docs/onboarding.md` and `docs/game.md` describe the one
  presenter, the § Shortcuts paragraph that called the in-front case untried describes the stash,
  and G7's "thirty unranked questions" now says ten, with Ten More. G7's third Deeplinks item, line
  614's "when the search is ending", is S2's and stays for Phase 9.
- **Checked in the simulators.** On the iPhone: `conjugar://game` then a verb link closed the game
  on hablar's page; Settings ▸ Play then `CONJUGAR://LIST/goVerbs` closed the game on -go Verbs;
  Settings ▸ Show Onboarding showed Dismiss, and its Play handed off to the game; a fresh stash
  written with `plutil` opened a random verb on a cold launch, and one two minutes old was dropped.
  On the iPad, in Spanish: the in-front announcement and the Shortcuts run above, and
  `conjugar://game` then `conjugar://info/voseo` closed the game on Voseo. The Control Center
  controls were not tried; they run the same `perform()` as the shortcut.
- **The suite** is 1,428 Swift Testing tests in 89 suites and 11 XCTest tests, in 86 s. The slowest
  suites are "ConjugationMap" (21.0 s), "The bundled map" (14.1 s), and `ReverseLookupTests`
  (9.5 s). No expectation changed; the intent tests now read `link` in place of `pendingDeeplink`.

## Phase 7: The Lists' Shared Pieces

**Findings:** D1 (the cheap pieces), D2, G6, G8, S5; from C13, the Models tab's whitespace query
and trombone; from S8, `englishTitle` and `BrowseSearch`. **Depends on:** nothing.

Everything here is a move or a merge with no change in behavior, except G6 and the two small
fixes named last. The accessibility identifiers `browse_verb_count`, `verb_row_<infinitive>`,
`model_row_<exemplar>`, and `collection_row_<key>` must survive: the launch anchor and
`scripts/take_screenshots.sh` depend on them.

- **One list heading** for the small-caps count lines, used by the Verbs tab (two places), the
  Models tab (two), `ModelView`, and `VerbCollectionView`.
- **One sort picker**, generic over a sort that has a localized name, used by the Verbs tab, the
  Models tab, `ModelView`, `VerbCollectionView`, and `RelatedVerbListView`.
- **One helper for "every sort order, computed once"**, in place of the four copies of the
  `Dictionary(uniqueKeysWithValues:)` expression.
- **One zebra stripe** and **one style for the serif gold title**.
- **`VerbDestination` is registered once**, inside `verbPageDestinations()`, for the Verbs,
  Models, and Quiz stacks, with its marks. That fixes the marks the Models tab drops; a test or a
  simulator check shows a marked destination pushed in the Models stack keeping its mark.
  Consider one modifier that also sets the `verbPagePush` environment, since the three stacks
  repeat that too.
- **D2.** One `SortableVerbList` that owns its sort state, for the model's page, a collection's
  page, and a related verb's full list, with the default sort, heading, source, and looked-up
  checks as parameters. One modifier for "send `viewCollection` once per opening".
- **One `AttributedString` helper for Spanish text**, in place of the fifteen private copies.
- **S5.** Files named for what they hold: the row types out of `VerbBrowseView.swift`,
  `VerbDestination` out of `VerbVisit.swift`, `VerbListMode` out of `VerbSort.swift`,
  `verbPageDestinations()` and the `verbPagePush` key out of `RelatedVerbsView.swift`,
  `DisplayTense.isCommand` into `DisplayTense.swift` (and used in the six places that spell it
  out), `QuizScope.collection(_:title:)` beside `QuizScope`. Check each move against the
  `ConjugationMapTool` target's membership, as `CLAUDE.md` § Core Models warns.
- **G8.** Rewrite the three history-narrating comments to describe the code.
- **S8.** Delete `englishTitle` from the four views if nothing reads it. Inline `BrowseSearch`
  into its one caller, or keep it and say why.
- **G6** (Decision 8). The Models tab's search field gets `.autocorrectionDisabled()` and
  `.textInputAutocapitalization(.never)`. For the iPad, take a screenshot of the Models tab with
  the drawer placement the Verbs tab uses and one without, **show Josh both, and keep the drawer
  only if he says so.**
- **Two small fixes.** The Models tab tests the trimmed text where it now tests
  `searchText.isEmpty`, and it plays the trombone only when the text changes. Fold the query once
  per search, not once per model.

**Done when** the suite passes unchanged apart from moved types, and each screen has been looked
at on both simulators before and after: the Verbs tab, My Verbs, the Models tab with its
collections, a model's page, a collection's page, and a related verb's full list.

**Tell Josh to try:** the six screens above, the sort pickers on each, and a search in the Models
tab.

**How it differed:**

- **G6, the drawer (Josh, 2026-11-26).** Shown the iPad's Models tab with today's toolbar button and
  with the Verbs tab's drawer side by side, Josh chose the drawer. Both tabs now read one
  `BrowseLayout.searchPlacement`, which carries the Verbs tab's comment about why. Autocorrection
  and autocapitalization are off.
- **The shared pieces** are `ListHeading`, `SortPicker` over a `PickerOption`, `ListSort` with
  `sortedLists(of:)` (`VerbSort` and `ModelSort` conform), `zebraStriped(_:)` with
  `Color.zebraStripe(_:)`, and `serifTitle()`, which the review card's title also uses. The
  picker now carries its own selection haptic, which the two tabs had put on their roots. The
  headings of a model's page, a collection's page, and the Models tab's count gained the header
  trait the others had, a VoiceOver-only change.
- **`VerbListMode` is `nonisolated`,** with only `localizedDisplayName` on the main actor. As a
  main-actor enum, its synthesized `Hashable` conformance was isolated and could not serve
  `PickerOption`, a build error. `VerbSort` and `ModelSort` were spared because their `Hashable`
  comes from their raw values.
- **D2.** `SortableVerbList` is the picker, an optional count heading, and the list, and its body is
  several views rather than a stack, so each page keeps its own spacing. It takes the sorted lists
  from its page rather than sorting in its own `init`, which runs with every render of the page;
  the pages sort once in theirs, as before, and the related list now does too instead of in its
  body. `signalsCollectionView(_:source:)` replaces the two `hasSignaledView` flags.
- **`VerbDestination`** is registered only in `verbPageDestinations()`, with its marks, and
  `pushesVerbPages(onto:)` sets the environment in all three stacks. Checked in the iPhone
  simulator with a temporary build whose model-page rows pushed a mark on the futuro's yo: from the
  Models tab, obtener's page landed on Futuro de Indicativo with obtendré marked. The build was
  reverted.
- **The Spanish helper** is `AttributedString(spanish:)` and `Text(spanish:)` in
  `Utils/SpanishText.swift`. All fifteen declarations went; `SpanishLetterKeyRow`'s note about
  eñe now sits at its call site. The places that tag
  only part of an attributed string are left as they were.
- **S5.** New files: `Models/VerbDestination.swift`, `Models/VerbListMode.swift`,
  `Models/ListSort.swift`, `Views/VerbPageNavigation.swift`, `Views/VerbRowLabel.swift` (the four
  row types), and `Views/RelatedVerbListView.swift`, which the plan did not name: the full related
  list and its destination left `RelatedVerbsView.swift` with the navigation pieces. `isCommand`
  sits in `DisplayTense.swift`, which the `ConjugationMapTool` target compiles; it reads nothing
  else, and the tool builds. `ModelRowLabel` stays in `ModelBrowseView.swift` until Phase 11.
- **S8.** `englishTitle` went from all four views. `BrowseSearch` and its tests went into
  `Models/ModelSearch.swift`, a value type that holds the Models tab's text, order, and results, so
  that the two small fixes could be tested: a space alone is not a search, and `update` reports
  the trombone only when the text changes to a failed query. `ModelSearchTests` replaces
  `BrowseSearchTests` with the same cases on real models, plus those two; the trombone test fails
  if a sort change reports one. The query is folded once per search.
- **G8.** `VerbRowLabel`'s story about the tap target went with `ModelRowLabel`'s, since it was the
  same story.
- **Checked in the simulators,** before and after, with the same script: the Verbs tab, My Verbs,
  the Models tab and its list, tener's model page and its verbs, the -go Verbs page and its verbs,
  and poner's full related list. On both the iPhone (English, dark) and the iPad (Spanish, light),
  the unscrolled after shots matched the before shots pixel for pixel, apart from the counts and
  checks that my own opens of poner and obtener changed; the scrolled ones, whose positions vary
  with a swipe's momentum, matched by eye. On the iPhone, a space in the Models tab's field kept
  the collections over all 102 models, and "4b" found the seven 4B models. On the iPad, "hac" in
  the drawer found hacer and rehacer.
- **The suite** is 1,432 Swift Testing tests in 89 suites and 11 XCTest tests, in 125 s, with the
  load average near 290 from other projects' runs. The slowest suites are "ConjugationMap"
  (33.6 s), "The bundled map" (23.9 s), and `ReverseLookupTests` (17.5 s). No expectation changed:
  `BrowseSearchTests`' six tests moved into `ModelSearchTests`' nine, `VerbSortTests` gained
  `sortedLists(of:)`'s, and `QuizGradingTests` reads `isCommand`.

## Phase 8: One Definition Each

**Findings:** D3 (the model layer); from F2, the repeated work; from S8, the cache check and the
tool's flags. **Depends on:** Phase 1.

- **Irregularity.** `isIrregular` has one definition, on `VerbMapEntry` or beside
  `Conjugator.verbType`, which `VerbDraw`, `ModelPractice`, `PracticeItem`, `QuizDueItems`,
  `SpeedRound`, and `VerbCollection` all read. `isCompound` moves off `VerbDraw` likewise.
- **A model's verbs.** `VerbCollection`'s `.model` case reads `ModelInfo.byClassNumber`, and
  `isInModel` and the test that keeps the two definitions equal go. `ModelView`'s bar, quiz, and
  share then use one list.
- **The verbs by frequency.** One cached list on `VerbMap`, of which a band is a prefix.
  `VerbMap.entries(in:)` and the six files that sort every entry by rank read it. `ModelView` and
  `VerbCollectionView` derive their sorted lists by filtering presorted ones where that is
  cheaper than sorting.
- **Edit distance.** One generic function with an optional limit serves `VerbSearch`'s two
  copies. Leave `AnswerDifference`'s, which needs a backtrace, unless it falls out naturally. A
  test pins that the limited and unlimited versions agree. Consider a home other than
  `VerbSearch` for `fold` and the distance, now that the quiz uses both.
- **"-se".** `VerbSearch.spanishQuery` calls `ReflexivePronoun.bareInfinitive(fromCitation:)`,
  and `RelatedVerbsView` calls `ReflexivePronoun.citationForm(of:)`.
- **Recents.** `LearnerVerbStore` does not re-sort the record on every read of `recentVerbs`.
- **The cache check** in `VerbSearch.keys(for:)` compares whole entries.
- **`ConjugationMapTool`** rejects a flag it does not know.

**Done when** `ConjugationMapTests`' fresh-build test passes and `scripts/write_forms_json.sh`
leaves `corpus/working/forms.json` byte-identical (`git diff --stat` shows nothing). Several of
these files compile into the tool, and an identical map is the proof that nothing moved. Search
results and the collections' membership are unchanged: `VerbSearchTests`, `VerbCollectionTests`,
and `VerbDrawTests` pass without edits to their expectations.

**How it differed:**

- **Irregularity and compounds.** `VerbMapEntry.isIrregular` and `isRegularClass(_:)` hold the only
  list of the regular classes. `Conjugator.verbType` now asks `isIrregular` before reading the ending,
  and a new test holds it to `isIrregular` for all 4,811 verbs. `isCompound` had three copies, in
  `VerbDraw`, `QuizDraw`, and `VerbEssentials`. All three went into one
  `VerbRelations.isCompound(_:)`, beside the relation it reads, with `VerbMapEntry.isCompound` over it.
- **A model's verbs.** `ModelInfo` is now `nonisolated`, so `VerbCollection` can read it. Its `verbs` are
  entries ordered by frequency rather than infinitives ordered alphabetically, and two rows are
  equal and hash alike by class number, so pushing a row no longer hashes its 2,968 verbs. The
  plan did not name a third copy, `RelatedVerbs.Index.verbsByModel`, which also went: the Related
  Verbs card reads the row too. `isInModel` and `everyModelsCollectionIsItsPagesVerbs` went as well.
  `ModelInfoTests` loses its alphabetical-order test, the one expectation this phase changed, since
  that order no longer exists. In its place, one test pins frequency order and another pins
  membership against the rule `isInModel` used to state. No row ever listed a homonym twice, but
  `ModelInfo` now takes each verb once on principle.
- **The verbs by frequency.** `VerbMap.entriesByFrequency` comes out of `ranked(_:)` at no extra
  cost, and `entries(in:)` is a prefix of it. Six files no longer sort the map themselves:
  `VerbEntity`, `RelatedVerbs`, `VerbCollection`, `VerbEssentials`, `ModelPractice`, and `QuizDraw`.
  `VerbSort.mapLists` holds the whole map in each order and replaces the Verbs tab's private copy.
  `sortedLists(ofMapEntries:)` filters it for a list longer than 32 verbs and sorts a shorter one.
  The threshold comes from a release-build timing in the scratchpad: sorting 50 verbs in Spanish
  collation took 0.47 ms, filtering the map took about 0.25 ms at any size, and sorting cantar's
  3,000 verbs took 37 ms against 0.5 ms to filter. A model's page, a collection's page, and the
  related verbs' full list all use it.
- **Edit distance and `fold`** moved to a new `Models/SpellingComparison.swift`. Its first name,
  `Spelling`, collided with `ConjugationIndex.Spelling`. One generic function with a limit serves
  both of `VerbSearch`'s former copies, and the unlimited form passes `Int.max`.
  `AnswerDifference` keeps its own, which needs the backtrace. The fold and distance tests moved
  from `VerbSearchTests` to `SpellingComparisonTests`, which also pins that the limited distance
  agrees with the unlimited one, over characters and over folded bytes.
- **The search cache.** `VerbSearch.Keys` keeps its entry and compares it whole. A new test fails
  without that: a hablar marked reflexive, with the bundled glosses, is found by "hablars".
- **Recents.** `LearnerVerbStore` keeps `starredVerbs`, `recentVerbs`, `recentUnstarredVerbs`, and
  `myVerbs` as observed stored properties, derived in `init` and in `save()`, which every change
  goes through. The new test checks all four after each kind of change. That test cannot fail for
  want of the cache; it guards the cache's correctness.
- **`ConjugationMapTool`** fails on a flag it does not know, and also on a repeated one, which the plan
  did not ask for. Checked by hand: `--froms-json` and a doubled `--map` each exit 1 with a message.
  The tool has no test target.
- **The identical-map check.** `corpus/working/forms.json` is gitignored, so `git diff --stat`
  could not have shown a change. I built the tool at `HEAD` in a scratch worktree and ran both builds
  with all four outputs: the `.lzfse` map, `forms.json`, `forms_all.json`, and the cells JSON.
  All four were byte-identical, and `scripts/write_forms_json.sh`'s `forms.json` matched them too.
- **Checked in the simulator,** on the iPhone only, since nothing visible was meant to change. On
  cantar's page, the bar and the heading both read 2,968, the alphabetical list starts at abajar,
  and the frequency list starts at pasar. The iPad was not booted.
- **The suite** is 1,439 Swift Testing tests in 90 suites and 11 XCTest tests, in 145 s, with the
  load average between 150 and 190. The slowest suites were "ConjugationMap" (26.2 s; its
  fresh-build test passed), `QuizLevelTests` (22.8 s), "The bundled map" (19.0 s), and
  `ReverseLookupTests` (14.9 s). `QuizLevelTests` is not among Phase 7's slowest, so I ran it
  alone: 5.8 s here and 9.2 s at `HEAD` under heavier load, which is noise and not a regression.
  `VerbSearchTests`, `VerbCollectionTests`, and `VerbDrawTests` kept their expectations. Only
  call sites changed, such as `entry.isIrregular`, and two tests moved out.

## Phase 9: A Search Model for the Verb List

**Findings:** S1 (the search model), C10, C11, F1, S2, S3, S4, S7; from C13, the linger, the
whitespace query, the trombone, the mail note, and the two suspicions; from F2, the repeated
search. **Depends on:** nothing, but read Phases 0, 1, 2, and 5 of the browse plan first: every
workaround in this view has a recorded reason.

- **The model.** Extract an `@Observable` search model from `VerbBrowseView`. It owns the text,
  the matches (one array of rows, each with its entry and its match, in place of the two parallel
  arrays), the guess, the `SearchTracker`, and the keyboard selection, and it decides what is
  shown: recents, My Verbs, results, or every verb. The view keeps focus, navigation, and the
  UIKit workarounds. The decisions become functions a test can call.
- **C10.** The selection is a verb, not an index. It clears when the shown list changes. Nothing
  is a keyboard target while My Verbs shows. Return acts on any idiom when a row is highlighted,
  so the iPhone's Search key behaves as before.
- **S3.** A row's action carries the entry and the match it was drawn with. `openRow` reads no
  array when the tap fires.
- **C11.** My Verbs' rows, the review card, and a link's pending verb go through `push(_:)`.
- **S2.** Replace `searchFocusLostAt` with state that says what it means and resets when it
  should, and correct `docs/feature_architecture.md`'s sentence about when the push waits.
- **S4.** The linger's task and the mail note's are cancelled when superseded. Try
  `ViewControllerTransitions.waitUntilIdle()` in place of the 500 ms sleep after a pop, on both
  simulators with Command-F from a verb page; keep the sleep if the wait does not make the field
  first responder.
- **S7.** The sort picker is disabled while the field has text.
- **The small ones.** One test of "is searching", the trimmed one, for the tip, the card, and the
  list. The trombone plays when the text changes to a failed query. `signalEndedSearch` reads the
  model's matches. Letters tapped quickly on iPad arrive in order.
- **F1.** Until `ConjugationIndex.bundled` exists, a search matches infinitives and glosses only
  and never waits on the main actor for the index. When the warm-up finishes, the current query
  runs again. A cold `conjugar://search?q=fue` shows the list at once and ser and ir when the
  index is ready. Correct the "about a second" comment with what is measured.
- **The two suspicions.** With AXe on the iPad simulator: Command-F, type, Return, then ↓ on the
  pushed page, to learn whether the arrow commands stay installed; and two letter keys tapped
  quickly. Fix what is real.

**Measure before and after**, with a temporary timing test in the manner of the review's Method
section: the index's first touch, and the time from a cold search link to a first list. Record
the numbers. The review measured 4.6 seconds for the first touch in a Debug build in the
simulator.

**Done when** the model's tests cover typing, clearing, a failed search and its guess, the
recents, My Verbs with and without recents, the selection across each change of list, what Return
opens, opening a result and the guess with the report each sends, a search before the index is
ready, and a requested search from a link.

**Tell Josh to try:** on the iPhone, a search typed in the first second after a cold launch,
xyzzyq, hablr, a cleared field, a space alone; on the iPad with a hardware keyboard, Command-F,
the arrow keys in the results and in the recents, Esc, Return on a result and on the guess, a
letter key tapped into an empty field, and My Verbs' rows with the empty field focused.

**How it differed:**

- **The model** is `Models/VerbBrowseSearch.swift`, an `@Observable` class. It owns the text, the
  list mode and sort, the results, the guess, the tracker, the selection, and the index once it
  exists, and it sends every `finishSearch`. `shown` says which of the four lists shows. The view
  passes the field's text and the picker through bindings that call `setText(_:)` and
  `setListMode(_:)`. Every verb's rows are built once per sort, in a static, so the view's `@State`
  initializer stays cheap. The four keyboard tests moved in from `VerbBrowseKeyboardTests`, which is
  deleted, and `VerbBrowseSearchTests` has 37 tests in all.
- **S3.** A `Row` carries its entry and an origin: every verb, a recent verb, or a result with its
  match, place, and result count. The plan asked for the entry and the match; the place and count
  came along so that the report reads nothing at tap time either.
- **C10.** "Clears when the shown list changes" is three rules: a new search (text, or the index
  arriving), a new sort, and a change of `shown`. A selection gone stale any other way, as when the
  recents change, is not found among the targets, so the next arrow starts from the top.
- **S2.** No state replaced `searchFocusLostAt`. `searchIsEnding` is computed: the field unfocused
  while the linger still holds, with nothing typed. Every push from the tab goes through `push(_:)`,
  which waits only then.
- **F1.** `VerbSearch.matches` and `guess` take an optional index, and nil skips the forms. Before
  the index, a failure shows a spinner, not "No verbs found", and its trombone waits: it plays when
  the index arrives only if the query still fails. The plan did not ask for that wait. Without it,
  "fuimos" would groan and then find ir and ser. I also moved the warm-up's start from the tab's
  `.task` to `ConjugarApp.init`, at user-initiated priority; the tab's task now only waits for it.
  **Measured** in a Debug build on "Conjugar iPhone 17": the index's first touch took 6.2 s before
  and 6.0 s after (map 2.3 to 2.8 s, index 3.2 to 3.8 s). From a cold `search?q=fue`, before: the
  unsearched list at +2.3 s, then the main thread blocked for 5.4 to 6.0 s, and results at +8.0 to
  8.7 s, with the warm-up starting only after. After, with the warm-up in the tab: first results
  (repostar, by its gloss) at +2.8 to 3.2 s, and ser and ir at +8.6 to 10.4 s. After, with the
  warm-up at launch: first results at +3.1 to 3.2 s, and ser and ir at +7.0 to 7.9 s. The load
  average swung between 5 and 400 during the session, from work outside it. I discarded runs taken
  during a spike.
- **S4.** The 500 ms sleep after a pop is now `Task.yield()` and `waitUntilIdle()`. With ⌘F from a
  verb page and typing 1.5 s later, the field took the text 12 times in 12 across both simulators.
  With neither wait nor sleep it took it 5 times in 6, so the trial can tell them apart.
- **The two suspicions.** The letter taps were real. On the iPad, á then é tapped 50 to 300 ms
  apart into the empty field gave "éá" three times in five and lost the á once. The model now queues
  the letters that wait. After the fix, gaps of 80 to 300 ms gave "áé" every time. At 50 ms the á is
  still lost, as before the fix, though 50 ms taps into a field holding text arrive whole. Making the
  first letter always wait in an empty field did not help, so I reverted that. The arrow keys took
  nothing: ↓ did not scroll tener's page after ⌘F, "tener", Return, nor the page opened by a link
  with no search focused. They are now installed only while the field is focused and the stack is
  empty, which costs one line.
- **Return on the iPhone.** With a hardware keyboard, ↓ then Return now opens the highlighted row
  or guess. With nothing highlighted, the Search key only lowers the keyboard, as before.
- **Checked on "Conjugar iPhone 17"** (English, dark): xyzzyq with its mail line, then the picker
  dimmed with the keyboard down; hablr's guess, then ↓ and Return opening hablar; a space alone
  showing the recents; "tuve" typed 3.5 s after a cold launch, arriving whole and finding tener.
  **On "Conjugar iPad Pro 11"** (Spanish, light): ⌘F and ↓↓ outlining the second recent; Esc
  returning to the full list with no outline; "come" with ↓↓↓↑ outlining venir and Return opening
  it; hablr and Return opening the guess; a recent tapped with the empty field focused pushing its
  page three times in three. I did not try My Verbs with the field focused and no recents, which
  needs Clear, nor the mail link.
- **The suite** is 1,472 Swift Testing tests in 90 suites and 11 XCTest tests, in 118 s, under a
  load average above 70. The slowest were "ConjugationMap" (42.3 s), "The bundled map" (35.2 s),
  and `ReverseLookupTests` (11.1 s), which load the map and are not touched by this phase.

## Phase 10: Split the Verb List's View

**Findings:** S1 (the rest), G9. **Depends on:** Phase 9.

- Move out of `VerbBrowseView`, each into its own file: `MyVerbsList` with its alerts,
  `FailedSearchHelp` with the mail link and its copied-address note, and a host for the review
  card's choice, reveal, snooze, and signal. `VerbBrowseView` should end as the navigation stack,
  the list or grid, the picker or letter row, and the router's requests.
- **G9.** The review card is one accessible element with one action, and a real `Button`, so
  that Full Keyboard Access reaches it. The model pill has an accessibility label without the
  glyph, with the exemplar tagged as Spanish. The letter keys are 44 points square if seven still
  fit an iPhone's width; show Josh the row if its look changes. The rows' Spanish tagging waits
  for Phase 11, which rebuilds the rows.
- Conjugar has no VoiceOver guide. Konjugieren's
  [`docs/voiceover.md`](../../Konjugieren/docs/voiceover.md) states the rules both apps follow. If
  this phase needs a rule specific to Spanish, start `docs/voiceover.md` here and list it in
  `docs/project_structure.md`.

**Tell Josh to try:** My Verbs (swipe a recent verb, swipe a starred one and cancel, Clear), a
failed search's mail link in the simulator, and the review card (reveal, open, dismiss, Suppress
Review Card on and off), on both devices; with VoiceOver if he has a device at hand, the card and
the pill.

**How it differed:**

- **The review card's host is two pieces.** Its state must outlive the view that draws it, since
  the card leaves the hierarchy whenever the learner types and a host's `@State` would then choose
  a new verb on its return. So `Models/VerbBrowseReviewCard.swift`, an `@Observable` class like
  `VerbBrowseSearch`, owns the choice, the reveal, the snooze, and the two signals, and
  `Views/ReviewCardHost.swift` draws it. `VerbBrowseView` still forwards the scene phase and the
  suppression setting to it, in two lines, because only a view that stays on screen can see them.
  The model has 9 tests, which the old code, living in the view's body, could not have.
- **`VerbBrowseView`** went from 630 lines to 341 and from 10 `@State` properties to 4: the search,
  the review card, the navigation path, and the linger's task. `MyVerbsList` takes an `open`
  closure and `FailedSearchHelp` takes the search and the tab's `push(_:)`, so every push still goes
  through the one function that waits when a search is ending. `FailedSearchHelp` now cancels its
  note's task when it leaves the screen. The highlight's color became `Color.keyboardSelection`,
  since two files draw it.
- **G9, the card.** The card is a `Button` whose label is the card, with the ✕ in an overlay
  outside it, two points from the card's corner as before. Its accessibility label is one
  `AttributedString`, "tener, have. Looked up 3 days ago." and once revealed the forms, with the
  infinitive and the forms tagged Spanish; the hint is the prompt, or "Opens the verb's page". The
  overlay put the ✕ first in VoiceOver's order, so the card has a sort priority. This departs from
  Konjugieren's `docs/voiceover.md`, whose card is separate elements so that each gets its own
  voice. G9 asked for one element, and Conjugar already tags Spanish by range in an
  `AttributedString` (`ModelPracticeCard`), so no Spanish-specific rule arose and I did not start
  `docs/voiceover.md`. Whether VoiceOver switches voice mid-label is unheard. The identifiers
  `review_card_reveal` and `review_card_conjugations` are gone, since their elements are; nothing
  used them.
- **G9, the pill.** "Irreg. ☛ tener" is read as "Irregular, like tener" ("Irregular, como tener"),
  a new string, with tener tagged Spanish. "Regular AR" and "Irregular" read as they are.
- **G9, the letter keys** are 44 points square and 5 apart, 338 points in all, down from 6 apart
  so that they fit a 375-point iPhone SE's keyboard toolbar in the quiz with its margins. The look
  changes only in size: `docs/screenshots/20261126-145608-phase10_letters_40.png` before and
  `20261126-150255-phase10_letters_44.png` after, on "Conjugar iPhone 17".
- **Checked on "Conjugar iPhone 17"** (English, dark), with a seeded card for tener: the card one
  button and the ✕ second in the accessibility tree; a tap in the card's padding revealing it and
  reading the forms; a second tap opening tener; obtener's pill read as "Irregular, like tener";
  the 44-point letter row; xyzzyq's mail link copying the address, its note gone after four seconds;
  a starred verb's swipe cancelled, a recent verb swiped away, and Clear asking, then leaving only
  the starred verb. **On "Conjugar iPad Pro 11"** (Spanish, light): the card at 560 points, read as
  "tener, have. Consultado hace 9461 días.", revealed by a tap and dismissed by the ✕; the letter
  row. I did not try Suppress Review Card in the simulator, which the model's tests cover, nor My
  Verbs on the iPad. Both simulators' practice records were restored afterward; the iPhone keeps
  the star on hablar and the Clear I did.
- **The suite** is 1,485 Swift Testing tests in 92 suites and 11 XCTest tests, in 142 s, under a
  load average near 100. The slowest were "ConjugationMap" (59.5 s), "The bundled map" (47.8 s),
  and "Which cells a text is" (10.8 s).

## Phase 11: One Grid-or-List, One Row Label

**Findings:** D1 (`AdaptiveRows` and the row label); from G9, the rows' Spanish; from C13, the
selection outline's corners. **Depends on:** Phases 7 and 10.

Josh chose the full refactor. The risk is a generic type that is mostly switches, so build it
from the plainest of its four users outward and stop if it stops being simpler than what it
replaces. Say so in **How it differed** if that happens, with what was tried.

- **`AdaptiveRows`**: a grid of carded cells on regular width and a zebra-striped stack with
  dividers on compact, generic over the item, with a row builder and a cell builder, an optional
  highlight, and an identifier per item. Its users are `VerbEntryList`, the Models tab's models,
  the Models tab's collections, and the Verbs tab's list. The Verbs tab's needs are the hard
  ones: an index for the search report's position, match lines, the keyboard highlight, and
  `scrollTo` by the row's id. The collections' rows have no zebra stripe today; keep that, or ask
  Josh whether they should.
- **One row label** with a row style and a card style, for a verb (infinitive, gloss, match
  lines, the looked-up check, the rank), a model (exemplar, class number, the percent pill), and a
  collection (its symbol, title, examples, and count). A collection's count, text, and
  accessibility label are computed once, not in both its row and its card.
- The label's title is tagged as Spanish for VoiceOver.
- The grid's selection outline uses the card's corner radius.

**Done when** screenshots of the Verbs tab, the Models tab, a model's page, and a collection's
page, on both simulators, match the ones taken before the phase, apart from the outline's
corners; the four identifiers named in Phase 7 still resolve with `tap_id.sh`; and the arrow keys
still scroll the highlighted row into view on the iPad.

**Tell Josh to try:** scrolling each list on the iPhone, a search with match lines, a
collection's checks, and on the iPad the grid in both orientations.

**How it differed:**

- **The refactor held.** Built from `VerbEntryList` outward, `AdaptiveRows` took all four users
  without a switch on which one it serves. Their differences became five parameters: the items
  and their id key path, whether the rows are striped, the highlighted id, the grid's padding, and
  an identifier as a prefix and a key path. The identifier is not a closure because SwiftLint's
  `multiple_closures_with_trailing_closure` rejects one beside the open and label closures. The
  grid strokes its outline with `Layout.cornerRadius`, the card's own.
- **One builder, not two.** The plan named a row builder and a cell builder. `AdaptiveRows` instead
  sets `rowLabelStyle` in the environment (`.row` in the stack, `.card` in the grid), and
  `RowLabel` reads it, so each caller passes one label. `VerbGridCell`, `ModelGridCell`,
  `VerbCollectionRow`, `VerbCollectionCard`, and `zebraStriped(_:)` are gone. The stripe and the
  highlight became `Color.listRow(_:isStriped:isHighlighted:)`.
- **`RowLabel`** is generic over its lines and its trailing part, with a title and an optional
  symbol. `VerbRowLabel`, `ModelRowLabel` (now in its own file, with `ModelPalette`), and
  `VerbCollectionRowLabel` fill it in. Verbs and models fit it exactly. The collections were the
  risk the plan named: their row pads 10 points above and below, not 12, and leaves 12 after the symbol, and their
  card puts the symbol and count on the first line, spaces its lines 8 apart, and adds the
  description and a bar. Those are three conditionals on `symbol` in `RowLabel`, each with its
  reason, plus the collection's own lines, which read the style. I judged that still simpler than
  two parallel twin views and kept it. A verb's infinitive and a model's exemplar are tagged
  Spanish; a collection's title, which is in the app's language, is not.
- **`CollectionProgress`** (`Models/`) counts a collection's opened verbs once and gives the
  fraction, the sentence, and the bar's value; the label and `VerbCollectionBar` both use it, with
  one `CollectionProgressBar`. The collection's label lost its `.accessibilityElement(children:
  .combine)`, since the `Button` around it merges its children already. In the simulator the row
  still reads "-go Verbs, tengo · hago · digo, 2 of 11 looked up" as one button.
- **The Models tab's rows are `Button`s** that append to the path, not `NavigationLink`s, since
  `AdaptiveRows` owns the button. The push is the same.
- **One change in look that no screenshot shows.** A verb's or a model's card now fills its grid
  row's height with its content at the top, as a collection's card always did, so that a card
  beside one with a two-line gloss is as tall rather than centered and shorter. No screen in the
  comparison had such a gloss, so the shots match.
- **Size.** The seven changed files lost 352 lines and gained 102; the four new files have 322, a
  third of them comments. The code is about as long as it was; what went is the duplication.
  `ModelBrowseView` went from 262 lines to 154.
- **Tests.** `RowLabelTests` (7 tests): the title's language, a striped and an unstriped row, the
  highlight over either, and a collection's progress, an empty one included. Nothing tests the
  outline's corners but the screenshots.
- **Checked on both simulators,** with one script before and after: the Verbs tab with its review
  card, a `fue` search with its match lines, tener's model page at its top and scrolled to its
  verbs, the -go Verbs page, and the Models tab at its top and scrolled. On "Conjugar iPhone 17"
  (English, dark) and "Conjugar iPad Pro 11" (Spanish, light), every unscrolled shot matched its
  before shot pixel for pixel, the collections' rows and cards included. The scrolled shots matched
  once shifted by the swipe's momentum (31 and 43 pixels on the iPhone, 6 and 0 on the iPad).
  `browse_verb_count`, `verb_row_ser`, `model_row_decir`, and `collection_row_goVerbs` resolved
  with `tap_id.sh` and opened their pages on the iPhone. On the iPad, the arrow keys outlined
  hablar in the recents with the card's corners, and thirty presses down "ar" results scrolled
  argüir, outlined, into view. The iPhone's record now has ser opened once more.
- **The suite** is 1,492 Swift Testing tests in 93 suites and 11 XCTest tests, in 164 s, under a
  load average near 250. The slowest were "ConjugationMap" (26.9 s), "The bundled map" (18.3 s),
  and `PracticeItemTests` (17.1 s). No expectation changed.

## Phase 12: The Quiz's Scope

**Findings:** S6. **Depends on:** nothing.

This phase touches code the pedagogy plan wrote on top of the browse plan's Phase 13. Read
[`plans/pedagogy_implementation.md`](pedagogy_implementation.md) for the modes before changing
how they are told apart.

- `QuizScope` gains a `kind`, and only the default kind is ranked, mixes due items, and mixes
  choice questions. `isRanked`'s conjunction of negatives, and `mixesChoiceQuestions`' redundant
  test, go. A test builds every scope the app can start and pins which is ranked.
- A quiz that runs in a sheet says so, and `startsLiveActivity` reads that, not `collectionKey`
  and `custom`.
- `showsVerbLink` in `QuizView` reads the scope, not the analytics source.

**Done when** the quiz's suites pass without edits to their expectations, and a ranked quiz, a
collection's quiz, Test Me, and a practice set each start and finish in the simulator, with the
Live Activity only where it was before.

**How it differed:**

- **The kind is the whole mode, not a flag beside the others.** `QuizScope.Kind` has one case per
  quiz the app can start (fourteen), and the stored flags it replaced (`isPracticeSet`,
  `isVerbEssentials`, `isRecognition`, `isSentences`, `isSpeedRound`, `isDaily`) and the optional
  `recordSession`, `modelPractice`, and `challenge` are gone from storage. The last three are
  payloads of their cases, so a scope can no longer be both a record session and a Speed Round. The
  old names survive as computed readers of the kind, so the views and models that read them, and
  every test, did not change. `isVerbEssentials` is true for a model's practice too, as the stored
  flag was. `custom`, `collectionKey`, and `level` stay stored, since several kinds share them.
- **`kind` has no default** in the initializer, so a new mode cannot fall into `allVerbs` by
  forgetting it. The two tests that build a long default quiz for its statistics name
  `.allVerbs`; that is their only edit, and no expectation changed.
- **`isRanked` is `kind == .allVerbs && questionCount == roundLength`.** The length stays because
  `QuizLevelTests` and `QuizVerbMixTests` draw thirty-question default quizzes, which must not mix
  in due items and choice questions. In the app an `allVerbs` scope is always a round.
  `mixesDueItems` and `mixesChoiceQuestions` are both `isRanked`; the latter's `!isPracticeSet`
  was redundant, as the review suspected, because a practice set always carries a custom quiz.
- **`Kind.runsInSheet`** is an exhaustive switch: Test Me, a collection, a model's practice, and a
  practice set. `startsLiveActivity` is `!runsInSheet`, a round's length or more, and not a Speed
  Round. Checked kind by kind against the old expression, it gives the same answer for all
  fourteen.
- **`showsVerbLink`** is a scope property, false only for the `verbPage` kind.
- **Two more chains became switches,** because they were the same smell and a new kind should have
  to decide there too: `LastQuizResult.Kind(scope:)`, an if-chain that told Test Me apart by its
  analytics source, and the DEBUG fixtures' `standsIn(for:)`, a conjunction of five negatives.
  `QuizView`'s title chain and the other readers of single flags were left alone.
- **Tests.** `everyScopeTheAppStartsPinsWhetherItRanks` builds all eighteen scopes the app's
  factories make, every kind and both record sessions and model modes among them, and pins
  `isRanked`, the two mixes, `runsInSheet`, and `startsLiveActivity` for each. A helper with an
  exhaustive switch names each kind, so a new kind does not compile in the test until it is named,
  and fails it until it has a row. `onlyTestMeHidesTheVerbLink` pins the link. Neither fails
  against the old code, which had no wrong answer to fix; S6 was about failing safe, and the
  tests pin today's answers so that the refactor cannot have changed one.
- **The suite** is 1,494 Swift Testing tests in 93 suites and 11 XCTest tests, in 164 s.
  `swiftlint` is clean.
- **Checked on "Conjugar iPhone 17"** only, since nothing on screen changed: a ranked quiz from
  `conjugar://quiz/start`, the -go Verbs collection's quiz, Test Me on tener, and a practice set
  from `conjugar://quiz/set?tenses=preterito&verbs=goVerbs`. Each was answered wrongly to its
  results by a script. Going home mid-quiz showed "1/10" in the Dynamic Island for the ranked quiz
  and an empty island for the other three. Test Me's correction had the model's link and no verb
  link; the practice set's had both. The iPad was not booted. The iPhone's practice record now
  holds the misses from those four quizzes.

## Phase 13: Tests That Prove What They Claim

**Findings:** T1, T2, T3, less whatever earlier phases already added. **Depends on:** nothing,
though it is shortest when taken last.

- **T1.** Repair or delete: `noParameterCanEchoTheQuery`'s arguments that are already in the
  vocabulary, `formsAreEveryOneWordFormOnce`, the `prefix(20)` of a dictionary in
  `ConjugationMapTests`, the test that `allCells` follows the table it is built from, and the two
  pattern lists pinned by count alone, which should be pinned by name.
- **T2.** `ModelView.gridPersons(for:)`, and anything in the review's list that Phases 1 to 12
  left.
- **T3.** `QuizScopeTests` and `VerbCollectionTests` pass a practice store of their own to each
  `Quiz`. `World.unitTest` gives `learnerVerbs` and `practice` one shared fake, as
  `PracticeStore`'s comment requires, or the comment is corrected. `PracticeRecordTests` counts
  days with an injected calendar and date, so that it cannot fail near a daylight-saving change.

**How it differed:**

## Closing

- Run the full suite and `swiftlint`, and compare the suite's time and its slowest suites with
  the baseline in step 2.
- **G5.** Add a step to [`docs/release.md`](../docs/release.md) § Before Submitting: delete
  `PracticeStore.migrated`, `LegacyLearnerVerbs`, their tests, and the paragraphs that describe
  them, since no shipped build wrote the format they read.
- **S4.** List the timed workarounds that remain in one place, in `docs/feature_architecture.md`:
  what each waits for, how long, and how to tell whether a new iOS has made it unnecessary.
- **F2's two unmeasured suspicions.** Time the first visit to the Models tab, and look at the
  memory the conjugation map and its index hold after one search, in Instruments if this Mac
  allows it. Record the numbers, and fix only what is plainly worth it.
- **The Info article "Purpose/Use"** still describes thirty-verb quizzes at three difficulties.
  The review listed it so that it would not be lost. Tell Josh; rewriting it is not this plan's
  work unless he says so.
- Confirm that every finding in `docs/verb_browse_review.md` carries a line: fixed, with date and
  phase; found not to be real; or left, with the reason. The costs of settled decisions get the
  last kind.
- Write a short list of the fixes that might carry over to Konjugieren and Conjuguer. The
  review's section "Found here and not in Konjugieren's review" is the starting point. Do not
  read the siblings' code for it beyond what is needed to say whether a piece exists there.
- Mark this plan finished in its Status section.

**How it differed:**
