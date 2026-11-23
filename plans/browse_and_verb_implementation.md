# Plan: Build the Browse and Verb Ideas in Conjugar

**For:** a series of fresh Claude Code sessions, one phase per session as a rule. **Kind of work:**
app code, one build-time tool, localized strings, one Info article, and tests. **Written:**
2026-11-22, by porting Konjugieren's finished plan for the same goal,
[`../Konjugieren/plans/browse_and_verb_implementation.md`](../../Konjugieren/plans/browse_and_verb_implementation.md),
and the ideas document it sprang from,
[`../Konjugieren/docs/browse_and_verb_ideas.md`](../../Konjugieren/docs/browse_and_verb_ideas.md),
to Conjugar's code as it stands on `master` today. **Goal:** improve the experience of the Verbs
and Models tabs, as Konjugieren's plan improved its Verbs and Families tabs.

A companion plan, [`pedagogy_implementation.md`](pedagogy_implementation.md), rebuilds the quiz
and runs after this one. Several pieces built here exist mainly so that plan can extend them:
the accent key row, the conjugation map, the key conjugations, the learner's record of verbs,
the scoped quiz, the frequency bands, and the review card's schedule. Build each so it can be
extended rather than replaced.

## Status

Each session that finishes a phase fills in its row, changes the **Status** line under the
phase's heading to match, and writes the phase's **How it differed** note. Leave rows for phases
not yet started as they are. A finished phase is "Awaiting Josh" until Josh has tried it and
committed it. Sessions never commit (see step 9 below), so the Commit cell is filled by the next
session, which reads the hash from `git log` once Josh's commit exists.

| Phase | Status | Date | Commit | Ideas |
|---:|---|---|---|---|
| 0 | Done | 2026-11-22 | f27a7a6 | A1, A2, A3, A8 |
| 1 | Done | 2026-11-22 | 7c34a17 | A4, C4 |
| 2 | Done | 2026-11-22 | 49b9f19 | Signals |
| 3 | Done | 2026-11-22 | 49b9f19 | B2 (the reflexive analog) |
| 4 | Done | 2026-11-22 | fe24e92 | A5 (the map) |
| 5 | Done | 2026-11-22 | 6c0ed97 | A5 (the search) |
| 6 | Done | 2026-11-22 | 6c0ed97 | B3, B5's tip |
| 7 | Done | 2026-11-22 | 048f585 | B7's article |
| 8 | Awaiting Josh | 2026-11-22 | | B4, A9 |
| 9 | Not started | | | B6 |
| 10 | Not started | | | C1 (links, control, quick action) |
| 11 | Not started | | | C1 (the intent), C2 |
| 12 | Not started | | | D1, D2 |
| 13 | Not started | | | D2's quiz scope, D3 |
| 14 | Not started | | | D5 |
| 15 | Not started | | | D4 |
| 16 | Not started | | | D6 |
| Closing | Not started | | | Audit, handoff to the pedagogy plan |

## How to Work This Plan

**Choosing a phase.** Take the lowest-numbered phase that is not done and whose dependencies are.
The numbering is a suggested order. Phases 6 to 9 depend on nothing after Phase 2 and may be
taken in any order. If a phase proves too large for one session, split it, say so in its row, and
leave the remainder marked "Partly done".

**Read Konjugieren's version first.** Every phase here ports a phase of Konjugieren's plan, named
under the heading. Konjugieren numbers its phases from 1 and this plan from 0, so the numbers
differ; go by the name. Before starting, read that phase's text and its **How it differed** note.
The notes record what failed on iOS 26, what Josh decided after trying a screen, and where the
phase text was wrong. The **From Konjugieren** bullets below each phase summarize the lessons
that apply here, but the notes have more. Konjugieren's code is in `../Konjugieren`; read its
implementation of the same piece when it helps, then port the design, not the German specifics.
Never edit Konjugieren's files from a Conjugar session.

**What this plan leaves to you.** The phases say what to build and what Josh decided. They do not
say how. Read the code, choose the implementation, and record in **How it differed** anything that
departs from the phase as written: a scope change, a decision Josh made during the session, a
dependency that turned out wrong, or a piece deferred to a later phase. A later session relies on
that note more than on the phase text above it. Read the notes of every phase this one depends on
before starting.

**Ask Josh when a verdict does not settle a question.** Phases list such questions under **Ask
Josh**. Do not guess at them. Ask before building the part that depends on the answer, and record
the answer and its date in **How it differed**. Josh's verdicts on Konjugieren carry over (see
[Decisions Carried Over](#decisions-carried-over-from-konjugieren)), so most questions here are
about what is different in Spanish.

**Subagents run on Sonnet.** No phase requires subagents, but a session may delegate work to them.
Any subagent it launches uses Sonnet (`model: "sonnet"` on the Agent tool), as Josh decided for
Konjugieren on 2026-11-15. The session still reads and checks the subagent's work itself.

**Every phase finishes the same way.**

1. Build and run the tests with the `ios-build-verify` skill, as `CLAUDE.md` describes. New logic
   gets Swift Testing tests that follow [`.claude/rules/testing.md`](../.claude/rules/testing.md).
   Read the run's `Test run with N tests` line, not only its exit status; a `--only-testing`
   selector that names a suite by its display string runs zero tests and still says "Test
   Succeeded". Read the per-suite times too: Konjugieren once had a refactor take a suite from 3
   seconds to 688 while every test passed. If the simulator's system language is not English,
   English-expecting tests fail; check with `xcrun simctl spawn <udid> defaults read -g
   AppleLanguages`, and run with `xcodebuild -testLanguage en` if needed, saying so in the note.
2. For any visible change, launch the app and look at it on both Conjugar simulators, the iPhone
   and the iPad. Josh tries changes on an iPhone, so the session's check is the only one the iPad
   gets. Exercise the phase's new states, not just its first screen. Between the two devices,
   cover English and Spanish, light and dark, and both size classes, and say in **How it
   differed** what was tried on each.
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
3. Localize every new string in English and Spanish, following `CLAUDE.md` and
   [`.claude/rules/localization.md`](../.claude/rules/localization.md). Never use the Edit tool to
   add or change an ASCII `"` inside an `.xcstrings` value; use `python3`. Strings used by
   `Shared/` or widget code belong in the widget's catalog too.
4. Make anything tappable on the verb page or the verb list usable with VoiceOver. Conjugar has no
   VoiceOver guide of its own; Konjugieren's
   [`docs/voiceover.md`](../../Konjugieren/docs/voiceover.md) states the rules both apps follow (an
   element speaks one language; a tap that speaks needs an `accessibilityAction`). If a phase
   needs a rule specific to Spanish, start `docs/voiceover.md` here and list it in
   `docs/project_structure.md`.
5. Add or extend analytics as Phase 2's convention says, once Phase 2 is done, and stage the
   privacy-policy lines Phase 2 describes. Never put a new line straight into
   `docs/privacy_policy3.txt`.
6. Update [`docs/project_structure.md`](../docs/project_structure.md) for new, renamed, or
   repurposed files, and keep `docs/feature_architecture.md` (created in Phase 2) true.
7. Fill in the Status row and the phase's Status line, write **How it differed**, and append a
   journal entry to `docs/blog_notes.md` (`## <Title> (YYYY-MM-DD)`, narrative, no em dashes
   between clauses).
8. If the phase changed something that [`pedagogy_implementation.md`](pedagogy_implementation.md)
   expects (its section **What the Browse Plan Leaves for This One** names each piece), add a line
   there saying what actually landed, with the date and this phase's number.
9. **Stop before git.** `CLAUDE.md` says sessions do not commit, push, or create branches. Leave
   the changes in the working tree and tell Josh what changed and how to try it: which screens to
   open, and what to type or tap. He commits with his own `/commit-and-push` skill when he is
   satisfied. The next session records his commit's hash in the Status row.

**No release before 2027.** Josh cannot release Conjugar, Conjuguer, or Konjugieren from his
present MacBook until he replaces it in 2027 (Konjugieren's `CLAUDE.md`, 2026-11-10). Every phase
accumulates on `master`. Nothing here reaches a learner or produces a number until a release
ships, so no phase should wait on evidence from another. Work that must happen on release day is
written down where the release will find it: a privacy-policy line in
`docs/privacy_policy_pending.md` (Phase 2 creates it), and every other step, such as an App Store
Connect step or a check on a device, in [`docs/release.md`](../docs/release.md).

**Conjugar only.** This plan ports Konjugieren's work and does not change Konjugieren or Conjuguer.
Another session is writing the analogous plan for Conjuguer. Where a choice here would make the
three apps differ for no Spanish reason, prefer Konjugieren's choice.

## Decisions Carried Over from Konjugieren

Josh's verdicts on Konjugieren's ideas, and his answers during that plan, are the defaults here.
Josh may overrule any of them for Conjugar when he reviews this plan.

- **Rejected there, not built here:** A6 (sentence mode), A7 (verbs outside the corpus), B1 (key
  conjugations at the top of the page), B5 (teasers near the top), B7 (new sections on the verb
  page), C3 (shortcut phrases in the app's second language), and every entry in the ideas
  document's "Smaller and Later Ideas".
- **Search** ranks the language being learned above English, with the exceptions Phase 0 found
  necessary, and searches glosses by default. Conjugar already searches glosses, with no setting.
- **The sad trombone stays** on a failed search, because it is funny.
- **The conjugation map** is generated at build time by a host tool that shares the engine's
  sources, and regenerates only when an input is newer than the output.
- **Section order.** Simple tenses stay ahead of compound tenses, every section stays visible, and
  within each block tenses are ordered by frequency of use.
- **Signals.** All three proposed signals are built, with their privacy lines staged for the
  release.
- **Quiz pieces.** This plan builds minimal versions of what its ideas need from the quiz: a quiz
  over a given list of verbs, and a due date per verb. The pedagogy plan extends them.
- **No web domain for universal links.** Shared text carries the App Store link and, where useful,
  a `conjugar://` link. Josh later decided that a shared verb page carries the App Store link
  only (Konjugieren Phase 10), and that a shared collection carries both (Phase 16).
- **Key conjugations appear with no label.** Learners do not know the term "principal parts", so
  it appears nowhere, in the interface or in code names. A verb's key conjugations stand alone,
  as in "tener: tengo · tuve · tendré · tenido". They are four: the yo presente, the yo
  pretérito, the yo futuro, and the participio (Josh, 2026-11-22; see Phase 9).
- **Scoped quizzes do not rank.** Neither a My Verbs quiz nor a three-question quiz posts to the
  Game Center leaderboard (Konjugieren Phase 13, 2026-11-13).
- **Layout.** Josh liked the top of Konjugieren's verb page as it was, so new things went in the
  navigation bar or at the bottom of the page. Propose any change to the top of Conjugar's page
  with a screenshot first.

**Decided for Conjugar (Josh, 2026-11-22).** Josh accepted every recommendation this plan made when
he reviewed it. Each is written into its phase:

- `CLAUDE.md` gains a "No Release Before 2027" section. **Done on 2026-11-22**, at Josh's
  request, ahead of Phase 2; Phase 2 only checks its wording. Release-day steps go in a separate
  `docs/release.md` (created the same day), and privacy-policy lines in
  `docs/privacy_policy_pending.md`.
- Phase 3, reflexive-only verbs shown with their pronouns, is built.
- Phase 7's Info article is written, on ir a + infinitivo and estar + gerundio.
- Phase 9's key conjugations are four: tengo · tuve · tendré · tenido.
- Phase 15's review card offers irregular verbs only, from the start.
- Phase 16's collections are derived from the engine, with `VerbFamilies` kept as a test that the
  derivation finds its verbs.

## Where Conjugar Starts

What the code does on 2026-11-22, read for this plan. Line numbers drift; names do not.

- **The verb list** (`Views/VerbBrowseView.swift`) filters with `BrowseSearch.results`, keeping
  every verb whose infinitive or **first** gloss (`VerbMapEntry.gloss` is `glosses[0]`) contains
  the query, case- and diacritic-insensitively, in the list's sort order (frequency by default,
  or Spanish alphabetical). There is no ranking. `.diacriticInsensitive` folds ñ to n as well as
  the accents. A failed search plays the sad trombone and shows "No verbs found". The sort picker
  sits below the list. Every verb has a frequency rank (`#168`), 1 to 4,811.
- **The verb page** (`Views/VerbView.swift`) shows the gloss, a pill ("Regular AR", or "Irregular
  (like tener)", which is plain text and links nowhere), a Defective pill where it applies, the
  participle, gerund, and future stem, then one card per tense in `DisplayTense.conjugatedTenses`
  order (nine simple tenses, the two imperatives, nine compound tenses), then the etymology, the
  modern example, and the medieval examples. Tense names are Spanish only and there is no setting
  for them. Uppercase letters in a form mark what is irregular and render red. A tap speaks a
  form. On iPad the cards sit in two columns.
- **Reflexive-only verbs** are flagged `rx="1"` in `verbModelMap.xml` (114 verbs, such as
  arrepentir and abstener) and stored under the bare infinitive. Nothing in the UI reads
  `VerbMapEntry.isReflexive`, so arrepentir's page shows "arrepiento" with no pronoun.
- **The Models tab** (`ModelBrowseView`, `ModelView`) lists 102 models by irregularity,
  alphabetically, or by class number. A model's page shows a six-tense grid of the exemplar and
  every verb using the model, alphabetically. A model has no description.
- **Analytics** sends one signal per screen and no parameters on views. Only the quiz signals
  carry parameters (`difficulty`, `elapsedTime`, `questionNumber`, `score`). The policy is
  `docs/privacy_policy3.txt`, English and Spanish.
- **Deeplinks** (`Views/AppRouter.swift`): `conjugar://verb/<infinitive>`, `verb/random` (drawn
  uniformly from all 4,811 verbs), `quiz` (opens the tab and starts a quiz at once), and the
  `game` routes. There is no `info` route and no query item is read.
- **Outside the app:** the widget extension's Verb of the Day (drawn from the top 1,000 by
  `(days × 127) % 1000`), the quiz widget, two Control Center controls (Quick Quiz, Random Verb),
  and the Live Activity. There are no App Shortcuts, no App Entities, no Spotlight entries, no
  Home Screen quick actions, and no keyboard commands.
- **Info** has an article for every conjugated tense and the non-finite forms, each with a
  `stableKey` (`Models/Info.swift`), plus About articles (Voseo, the verb history).
- **The engine** is `nonisolated` and `Sendable` throughout, so a macOS tool can compile it
  without touching `@MainActor` code, which is the risk Konjugieren's Phase 5 had to clear first.
  `CorpusFormsDumpTests`, a disabled harness, writes `corpus/working/forms.json` (the top 1,000)
  and `forms_all.json` (every verb: 254,328 single-word forms, of which 293 belong to more than
  one infinitive, such as fue, fui, ve, sé, and siento). `frequency/aggregate_gbooks.py` reads
  `forms_all.json`.
- **Content:** `ExampleUses.json` holds 1,340 modern examples, each with the `token` that is the
  verb's form in the sentence, which makes a ready test set for the map.
- **The quiz** builds 30 questions from hand-curated lists (`Models/VerbFamilies.swift`) by
  difficulty. The pedagogy plan rebuilds it; this plan only adds a scope (Phase 13).
- **Docs Konjugieren had that Conjugar lacks:** `docs/feature_architecture.md`,
  `docs/voiceover.md`, `docs/privacy_policy_pending.md`, `docs/release.md`, and
  `scripts/check_docs.py`. `docs/release.md` was created on 2026-11-22; Phase 2 creates
  `docs/feature_architecture.md` and `docs/privacy_policy_pending.md`. The checker is not ported
  unless Josh asks.

## Idea Index

The IDs are Konjugieren's, from its ideas document, so its reasoning can be found by ID.

| ID | Idea | Konjugieren verdict | Conjugar phase |
|---|---|---|---:|
| A1 | Fold umlauts and digraphs | Yes | 0 (accents, ñ, and -se) |
| A2 | Search glosses by default, whole words first | Yes | 0 |
| A3 | Rank the exact match first | Yes | 0 |
| A4 | A useful empty state | Yes, trombone kept | 1 |
| A5 | Reverse lookup from a conjugation | Yes | 4, 5 |
| A8 | Search-field hygiene and a letter-key row | Yes | 0 |
| A9 | Browse a family by frequency | Yes | 8 (a model's verbs) |
| B2 | Separable verbs as a main clause writes them | Yes | 3 (reflexive-only verbs) |
| B3 | Order sections by use, name them twice, link articles | Yes, amended | 6 |
| B4 | Related verbs | Yes | 8 |
| B5 | Bring the etymology and example within reach | Only the tip | 6 |
| B6 | Copy and share | Yes | 9 |
| B7 | Sections the page lacks | Only an article | 7 (periphrasis) |
| C1 | A way to open search from outside | Yes | 10, 11 |
| C2 | Spotlight that finds conjugations and glosses | Yes | 11 |
| C4 | Keyboard lookup on iPad and Mac | Yes | 1 |
| D1 | Recents | Yes | 12 |
| D2 | My Verbs | Yes | 12, 13 |
| D3 | "Test me on this verb" | Yes | 13 |
| D4 | A review card on the landing screen | Yes | 15 |
| D5 | A verb of the day worth opening | Yes | 14 |
| D6 | Collections | Yes | 16 |

## Phase 0: Search Finds What People Type

**Ideas:** A1, A2, A3, A8. **Ports:** Konjugieren Phase 1. **Depends on:** nothing. **Status:**
Done (2026-11-22, f27a7a6).

- **A1, folding.** Conjugar already folds case and every diacritic. Keep that, but rank a literal
  match above a folded one, so that "sonar" gives sonar before soñar, and "anadir" still finds
  añadir. Also strip a trailing "se" from the query ("levantarse", "arrepentirse") and a leading
  "se " before matching, since learners type the dictionary form of a pronominal verb. Strip the
  trailing "se" only when what remains ends in -ar, -er, -ir, or -ír, and match the remainder as an
  infinitive, so that "base" and "clase" are searched as typed.
- **A2, glosses.** Search every gloss in `VerbMapEntry.glosses`, not only the first, so a homonym's
  second sense is found. Glosses are often comma lists ("arrive, come"). Rank a whole-word gloss
  match above a match inside a word, and ignore a leading "to ".
- **A3, ranking.** Rank the exact infinitive first, then the other kinds of match, each kind by
  frequency whatever the list's sort order. Make the list and every later caller (Phase 5's
  lookup, Phase 11's intent) share one matching and ranking function, so they cannot drift.
- **A8, the field.** Turn off autocapitalization and autocorrection in the search field if they
  are on, say in the placeholder what can be typed ("Verb or English meaning"), and add a row of
  keys for á, é, í, ó, ú, ü, and ñ. Build the row as a component that takes an `insert` closure,
  so that the quiz's answer field can adopt it (pedagogy Phase 0).
- **The Models tab.** `BrowseSearch` is shared with `ModelBrowseView`, which matches a model's
  exemplar or class number. Let it share the new folding helper, so "sonar" behaves alike in both
  tabs, and change nothing else there: no ranking, glosses, or key row.

**The ranking needs Josh's eye, because Spanish differs from German here.** Konjugieren's final
order was: exact infinitive, exact after folding, infinitive prefix, whole-word gloss,
infinitive substring, folded prefix, folded substring, gloss substring. Applied to Conjugar, it
fails the commonest English queries: 39 infinitives begin with "go", "be", or "do" (gobernar,
gozar, beber, besar, dormir, doblar), so "go" would list them all above ir, "be" above ser and
estar, and "do" above hacer. The likely fix is a kind above the infinitive prefix for a gloss
that equals the whole query ("be" is estar's whole gloss), but "come" then puts venir above
comer, which a learner typing "come" may mean. Build the ranking, show Josh a table of these
queries (go, be, do, come, have, see, ver, comer, sonar, levantarse) with what each returns
first, and let him choose before writing the tests that pin it.

**From Konjugieren:**

- `ToolbarItemGroup(placement: .keyboard)` never appeared for a navigation-bar search field on the
  iOS 26 simulator. Konjugieren's key row instead replaces the sort picker while the field is
  focused (`.searchFocused`), which puts it directly above the keyboard. Conjugar's picker is in
  the same place. Search ignores the sort order, so hiding the picker costs nothing.
- **Check the iPad in this phase.** iPadOS 26 shrinks `.automatic` search into a toolbar button
  that ignores `.searchFocused` and `.searchable(isPresented:)`, which Konjugieren found only in its
  Phase 2. If the key row does not appear on "Conjugar iPad Pro 11", bring Phase 1's fix forward:
  on iPad and Mac only, put the field under the title with
  `.navigationBarDrawer(displayMode: .always)`, leaving the iPhone's placement alone. Record it in
  **How it differed** so that Phase 1 does not redo it, and ask Josh to judge the iPad layout.
- Make the match kinds an enum (`VerbSearch.MatchKind` there). Phase 2 sends them by name, and
  Phase 5 adds kinds.
- The placeholder should depend on what is searched; Phase 5 extends it once a conjugation finds
  its verb.
- Autocorrection was switched off in code but never checked on a device with an English keyboard.
  Say whether you could.

**Done when** each query in the table above returns what Josh chose first, a literal match leads
its folded twin, every gloss of a homonym is searched, the key row inserts into the field, and
tests pin each case.

**How it differed:**

- **The ranking (Josh, 2026-11-22).** Josh saw four candidate orders as a table and chose one new
  kind above the infinitive prefix: a gloss *sense* equal to the whole query, where a sense is a
  comma item, so llegar's "arrive, come" counts for "come". The order, in
  `VerbSearch.MatchKind`, is exact infinitive, exact after folding, exact gloss sense, infinitive
  prefix, whole-word gloss, infinitive substring, folded prefix, folded substring, gloss
  substring; within a kind, frequency decides. What each table query gives first: go → ir; be →
  ser, estar; do → hacer; come → llegar, venir, acudir, then comenzar, comer; have → tener,
  haber; see → ver; ver → ver; comer → comer; sonar → sonar, soñar; levantarse → levantar; to go
  → ir; drive → conducir. He turned down three alternatives: a whole gloss ahead of a sense (venir
  before llegar, but rare arrear and aballar before conducir for "drive"), a whole gloss only
  (llegar falls below every come- prefix), and every whole-word gloss above the prefix (English
  wins outright, so "be" gives gustar and nacer before beber and comer sinks below provenir).
  `VerbSearchTests.chosenFirstResults` pins the table.
- **What the code looks like.** `VerbSearch` (`Models/`, `nonisolated`) owns the matching:
  `matches(for:in:)` returns one `Match` (entry plus kind) per verb. It caches each verb's
  lowercased, folded, and split keys once, in a static built from `VerbMap.shared`, because a
  mutable static cache like Konjugieren's is an error under strict concurrency. `VerbMapEntry`
  became `Equatable` so that `Match` could be. The Verbs tab no longer goes through
  `BrowseSearch`; the Models tab still does, now matching through `VerbSearch.fold`.
- **Pronominal queries.** Besides "levantarse" and "se levantar", "levantar(se)" also searches for
  levantar, since some word lists write it that way. The gloss side keeps the query as typed, so
  "sparse" still finds a gloss while its Spanish side is "spar".
- **The letter row** is `SpanishLetterKeyRow`, seven keys with an `insert` closure. Seven
  `.bordered` keys would overflow an iPhone, so the keys use a private tinted rounded-rectangle
  style, 40 points square. Each letter is tagged Spanish (`languageIdentifier = "es"`) so
  VoiceOver says eñe. As in Konjugieren, it replaces the sort picker while the field is focused.
- **The iPad drawer came forward from Phase 1, for a different reason.** On "Conjugar iPad Pro
  11" the key row did appear when the toolbar search button was tapped. But a key tapped while
  the field was empty ended the search at touch-down, and the letter was lost: Konjugieren's
  later finding. Its fix sets the letter after the search is gone and then refocuses the field,
  which needs programmatic focus, and iPadOS 26's `.automatic` search ignores that. So iPad and
  Mac now use `.navigationBarDrawer(displayMode: .always)`, a field under the title, and the
  iPhone keeps `.automatic`. Ported with it: the 700 ms lingering `searchIsEngaged` and
  `Utils/ViewControllerTransitions.swift`. Josh approved the iPad layout on 2026-11-22, from
  `docs/screenshots/20261122-123044-p0-ipad-drawer-resting.png`. Phase 1 should not redo the
  drawer; it still owns Command-F, Return, and the arrow keys.
- **The placeholder** is "Verb or English meaning" / "Verbo o significado en inglés", under the
  renamed key `BrowseVerbs.searchPromptVerbOrMeaning`. Phase 5 should extend it.
- **What was tried where.** iPhone, English, light: the "come" table row, the picker returning
  when the field lost focus, and the ñ key turning "a" into "añ" with añadir first. iPad, Spanish,
  dark, regular width: the toolbar search, the empty-field key loss, then after the fix the
  resting drawer and á typed into an empty field with the search reopened. The software keyboard
  never showed, because the simulators have a hardware keyboard attached, so the row sat above
  the tab bar rather than the keyboard. Konjugieren checked that placement on the keyboard.
- **Autocorrection and autocapitalization** are off in code (`.autocorrectionDisabled()`,
  `.textInputAutocapitalization(.never)`). They could not be checked on a device with an English
  keyboard.
- **Tests.** The 18 tests of `VerbSearchTests` (41 cases with the parameterized ones) and the
  whole suite pass: 611 Swift Testing tests in 32 suites, plus the XCTest suites. The simulator
  language was English, so no `-testLanguage` was needed.
- **A data glitch noticed, not fixed:** one gloss in `verbModelMap.xml` reads "wrinkle (brow",
  with no closing parenthesis.

## Phase 1: When Search Finds Nothing, and Keyboard Lookup

**Ideas:** A4, C4. **Ports:** Konjugieren Phase 2. **Depends on:** Phase 0. **Status:**
Done (2026-11-22, 7c34a17).

- **A4.** Keep the sad trombone. Below "No verbs found", offer the single closest verb by fuzzy
  matching over the folded infinitives, and say plainly that it is a guess. Add a line saying that
  if the learner believes the verb is real, the learner should email vermontcoder@gmail.com, as a
  link with the query filled in. Conjugar already has `Utils/Emailer.swift` for Settings'
  feedback; use it or a `mailto:` link, whichever behaves better in a sheet-free list.
- **C4.** On iPad and Mac, Command-F focuses the search field, Return opens the first result, and
  the arrow keys move through results.

Phase 5 changes when the empty state appears, since a conjugation will then find its verb. Note
anything Phase 5 must revisit.

**From Konjugieren:**

- The guess there is an optimal-string-alignment distance (Levenshtein plus an adjacent swap)
  between folded strings, ties broken by frequency, allowed one edit per three letters and never
  more than three. "gehn" found gehen and "xyzzyq" found nothing. Try "hablr", "tenr", and
  "xyzzyq" here.
- The simulator has no Mail app, so a device that cannot open the link copies the address and
  says so for four seconds, at Josh's request.
- Command-F works as a top-level `CommandMenu` (Verbs › Find a Verb); a `CommandGroup` beside
  `.textEditing` never fired, because the system's own Find claims ⌘F there.
- iPadOS 26 shrinks `.automatic` search into a toolbar button that ignores `.searchFocused`, so on
  iPad and Mac the field became `.navigationBarDrawer(displayMode: .always)`. **Josh judged that
  layout there; ask him to judge it here.** Phase 0 may already have made this change for its key
  row; read its note first.
- A focused text field consumes ↑ and ↓, which outranks `.onKeyPress`, `.keyboardShortcut`, and a
  menu command. `UIKeyCommand`s with `wantsPriorityOverSystemBehavior`, installed only while the
  field is focused, worked. Return acts only on the iPad idiom, so the iPhone's Search key behaves
  as before.
- Test with AXe's hardware key events (`axe key`, `axe key-combo`) on the iPad simulator. Keys
  sent to Simulator.app through computer use did not reach the device.

**Done when** a misspelling shows a guess, nonsense shows none, the mail line works or copies, and
Command-F, Return, and the arrows work on the iPad simulator.

**How it differed:**

- **The guess.** `VerbSearch.closestVerb(to:in:)` reads the query as the infinitive search does
  (so "-se" goes), folds it, and measures optimal-string-alignment distance
  (`VerbSearch.editDistance`) to each folded infinitive, within one edit per three letters and
  never more than three (`maxGuessDistance`), as in Konjugieren. Konjugieren breaks a tie by
  frequency alone, which failed the plan's first test case: "hablr" is one edit from haber as well
  as from hablar, and haber is the more frequent. So a tie now goes first to the verb that shares
  more of the query's beginning, then to frequency, because a learner usually gets the start of a
  word right. "hablr" gives hablar, "tenr" tener, "hbalar" hablar, "anadri" añadir, and "xyzzyq"
  nothing. `VerbSearchTests` pins these, the tie-breaks, and the distance itself.
- **The empty state.** Under "No verbs found" (the trombone still plays), "A guess at the verb you
  meant:" / "Una conjetura sobre el verbo que buscabas:" and the guess as an ordinary verb row,
  then the mail line: "If you believe that “hablr” is a Spanish verb, please email
  vermontcoder@gmail.com." / "Si crees que «hablr» es un verbo español, escribe a …". With no
  guess, only the mail line. The block is held to the reading width, so on iPad it sits centered
  under the empty-state icon rather than spanning the grid.
- **`mailto:` rather than `Emailer`.** `Emailer` presents `MFMailComposeViewController`, which
  needs Apple's Mail app set up with an account; a `mailto:` link opens whatever mail app the
  learner chose as default. So the address is a link built by the new `URL.mailto`
  (`Utils/URLExtension.swift`), with subject and body naming the query in the learner's language.
  The address now lives once, as `URL.developerEmail`, which `Emailer` also reads. A device that
  cannot open the link copies the address and says so for four seconds, also announced to
  VoiceOver. Checked on the iPhone simulator, which has no Mail app: the note appeared and the
  simulator's pasteboard held the address. Not tried on a device with a mail app.
- **Command-F** is `VerbSearchCommands`, a top-level `CommandMenu` (Verbs › Find a Verb / Verbos ›
  Buscar un verbo), as Konjugieren found necessary. A menu command needs the router, which
  `MainTabView` owned, so `ConjugarApp` now owns the `AppRouter` and passes it to `MainTabView`.
  `AppRouter.openSearch()` selects the Verbs tab and sets a one-shot `pendingSearchFocus`, which
  `VerbBrowseView` consumes: it pops to the list, waits 500 ms if it popped (Konjugieren's hack),
  and focuses the field.
- **Return and the arrows**, as in Konjugieren. Return acts only on the iPad idiom and opens the
  highlighted row, else the first result, else the guess. `Utils/VerbSearchArrowKeys.swift`
  installs priority `UIKeyCommand`s for ↑ and ↓ while the field is focused. The highlight is the
  red tint Konjugieren uses on a list row and on the guess; on the iPad grid's cards it is a red
  outline, because a tint behind a card does not show. The list scrolls to the highlighted row.
- **The iPad drawer** was not redone; Phase 0 brought it forward and Josh approved it.
- **What was tried where.** iPhone, English, light, compact: "hablr" (guess hablar, row opens it),
  the mail link's copy fallback, and "xyzzyq" (no guess). That check caught the mail line sitting
  indented when no guess row widened its stack; it now aligns left either way. iPad, Spanish, dark,
  regular, with AXe hardware keys: ⌘F from the Quiz tab switched tabs and focused the field;
  "tenr" showed tener, ↓ highlighted it, Return opened it; ⌘F from tener's page popped and
  focused; "come" with ↓↓↓↑ outlined venir in the grid and Return opened it; "drive" with Return
  and no highlight opened conducir. Not tried on a Mac or a real iPad.
- **Tests.** New: the guess cases in `VerbSearchTests`, `URLExtensionTests` (mailto encoding),
  `VerbBrowseKeyboardTests` (the selection's movement and its stops), and Command-F's request in
  `AppRouterTests`. The whole suite passes: 624 Swift Testing tests in 34 suites, plus the XCTest
  suites. No suite slowed; `VerbSearchTests` takes about 1.2 seconds. The simulator language was
  English.
- **For Phase 2 (signals).** Konjugieren gives a page opened from the guess its own `source`
  value (`searchGuess`) and counts a Return or arrow-key open as an ordinary search open. The guess
  opens through `navigationPath.append` like every other row, so Phase 2 must tell them apart.
- **For Phase 5 to revisit.** The empty state, and with it the guess, will appear only when the
  conjugation lookup also fails. `closestVerb` considers infinitives only; decide whether a
  misspelled conjugation (tenjo) should guess too, as Konjugieren's later `guess(for:)` does.
  `keyboardTargetCount` and `openKeyboardSelection` in `VerbBrowseView` assume one row per verb,
  which conjugation rows will change. The placeholder still names only verbs and meanings.

## Phase 2: Lookup Signals

**Ideas:** the three signals in Konjugieren's ideas document, "What to Measure". **Ports:**
Konjugieren Phase 3. **Depends on:** Phase 0, so that the match kinds exist. **Status:**
Done (2026-11-22, 49b9f19).

- `finishSearch`, sent once per search, with banded `outcome`, `queryLength`, `resultCount`,
  `matchKind`, and `resultPosition`.
- A `source` parameter on `viewVerbView`.
- `leaveVerbView`, sent once per verb view, with `deepestSection` and a banded `dwell`.

Define the full vocabulary of `source` and `matchKind` values in one place now, including values
for surfaces later phases build (`search`, `browse`, `searchGuess`, `model`, `related`, `widget`,
`control`, `deeplink`, `spotlight`, `lookup`, `quickAction`, `recent`, `myVerbs`, `reviewCard`,
`list`, `sharedLink`, `resume`, and whatever else this plan's phases need). Never send a verb or
any typed text: the policy promises that.

**Two pieces of infrastructure Conjugar lacks, made here:**

- **`docs/feature_architecture.md`**, with an Analytics section: the signal table, each
  parameter's values, and which phase sends which `source`. Later phases add the deeplink grammar
  (Phase 10), the learner record (Phase 12), and the review card (Phase 15), and the pedagogy plan
  adds the quiz. List it in `docs/project_structure.md`.
- **`docs/privacy_policy_pending.md`**, where each new signal's policy line waits, in English and
  Spanish, with instructions for release day. Josh may deploy `privacy_policy3.txt` at any time,
  and a line belongs in the deployed policy only on the day the release that sends it ships.
- **Check `CLAUDE.md`'s "No Release Before 2027" section.** It was added on 2026-11-22 at Josh's
  request, ahead of this phase, so do not add it again. It sends privacy-policy lines to
  `docs/privacy_policy_pending.md` and every other release-day step to `docs/release.md` (Josh,
  2026-11-22), which already exists. Once the pending file exists, check that the section still
  describes both files truly, and add a step to `docs/release.md` § On Release Day for applying it
  if the existing one needs more.

**The convention for later phases.** Each phase that adds a way to reach a verb page sets its
`source` value and stages its line. Phase 5 adds conjugation match kinds. Phases 9, 12, and 13
add `tapShareVerb`, `tapStarVerb`, and `tapTestVerb`. Phase 13 adds `source` to the quiz signals.

**From Konjugieren:**

- `viewVerbView` already fired again whenever a page reappeared after a tab switch, so "once per
  view" needed a definition: a visit is one stretch on screen with the app in the foreground
  (`VerbVisit`). It ends, sending `leaveVerbView`, when the page leaves the screen or the app goes
  to the background, and a page that returns starts a visit whose source is `resume`.
- Reaching a section means a third of its block's first card on screen
  (`onScrollVisibilityChange`). Conjugar's sections: the header, the simple tenses, the compound
  tenses, the etymology, and the examples.
- A search (`SearchTracker`) begins with the first non-blank letter and ends once: opened, cleared,
  or the app backgrounded with text in the field.
- Deeplinks carry `source` as a query item (`conjugar://verb/hablar?source=widget`), since a widget
  or a control can pass the app only a URL. Fall back to `deeplink`. The widgets and both controls
  should name themselves.
- If the Random Verb control and any later shortcut run the same intent, the intent cannot tell
  them apart; give the control its own hidden intent.
- `AnalyticsTests` pins wire names here; extend it. Konjugieren added a test that no parameter can
  echo the query.

**Done when** the three signals fire as designed in the simulator (log them temporarily; the
simulator world uses `AnalyticsSpy`), tests pin the bands and parameters, and the two documents
exist.

**How it differed:**

- **Where things live.** Every key and value is in `Analytics/Analytics.swift`: the new
  `ParameterKey` cases, `AnalyticsSource`, `SearchOutcome`, `SearchMatchKind`, `VerbPageSection`,
  and the bands in `AnalyticsBand`, all `nonisolated` like the rest of the family. `VerbVisit` and
  `VerbDestination` are in `Models/VerbVisit.swift`; `SearchTracker`, `SearchReport`, and
  `MatchKind.analyticsValue` in `Models/SearchReport.swift`. `docs/feature_architecture.md`
  § Analytics has the signal table and the `source` vocabulary, with which values are sent today
  and which phase sends the rest.
- **The vocabulary.** `source` has 21 values: the plan's list plus `shortcut`, `tab`, `verbPage`,
  and `infoLink` (reserved, as Konjugieren has it). Sent today: `browse`, `search`, `searchGuess`,
  `model`, `widget`, `control`, `shortcut`, `deeplink`, and `resume`. `matchKind` sends the search's
  nine kinds by name (`exactGlossSense` included, which Konjugieren lacks), plus `guess` and
  `none`. `conjugation` and `foldedConjugation` wait in the enum for Phase 5, which should check
  whether its kinds need other names.
- **`finishSearch` has no `source`.** Konjugieren added one in its Phase 11 (where the search
  began). Today every search here begins in the Verbs tab, so it would always say `tab`. Phase 10
  or 11, which build the outside ways in, should add it then, with `SearchTracker` learning the
  surface that opened the field as Konjugieren's does.
- **The rows became buttons.** The verb list's rows and the guess were `NavigationLink(value:)`s,
  which push without a hook, so an open could not send `finishSearch` or tell its match kind. They
  are now buttons calling `openRow(at:wasSearching:)` and `openGuess(_:)`, which report and then
  push a `VerbDestination`. `wasSearching` is read as the row is drawn. That reopened Konjugieren's
  iPad bug, a push dropped while an empty search animates away, which the links had dodged, so
  `push(_:)` ports Konjugieren's `pushFromSearch` (wait for `ViewControllerTransitions` when the
  field just lost focus with nothing typed). The Models tab pushes `VerbDestination(…, source:
  .model)` from `ModelView`'s closure; its stack's destination type changed from `String`.
- **The sections.** `simple` and `compound` are marked by the first simple and the first compound
  card in `DisplayTense.conjugatedTenses` (Presente de Indicativo and Perfecto de Indicativo
  today), found by `VerbView.section(markedBy:)` through a new `DisplayTense.isCompound`, so Phase
  6's reordering moves the marks with the cards. The threshold is 0.3, as in Konjugieren.
- **The control's own intent.** `OpenRandomVerbIntent` is discoverable in the Shortcuts app, so the
  Random Verb control now runs `Shared/OpenRandomVerbControlIntent.swift` (hidden with
  `isDiscoverable = false`, same title key), which stashes `?source=control`. The original
  stashes `?source=shortcut`. `WidgetDeeplink.verb(_:)` adds `?source=widget`, which covers every
  widget, the quiz widget and the Lock Screen accessories included. `AppRouter.pendingVerb` is now
  a `VerbDestination`.
- **Documents.** `docs/feature_architecture.md` and `docs/privacy_policy_pending.md` are new. The
  staged text adds three bullets in each language and rewrites the paragraph after the list, whose
  "the verbs you look up" stays true but now needs "That you searched is recorded…". `CLAUDE.md`'s
  No Release Before 2027 section was right except that it spoke of the pending file as future; it
  now links the file and says that `docs/release.md` applies it. Its analytics line ("update
  `docs/privacy_policy3.txt`") contradicted the staging rule, so it and
  `.claude/rules/analytics.md` now say to stage lines instead. `docs/release.md` gained a Before
  Submitting step: check the signals on a device, since the simulator never sends them.
- **What was tried where.** iPhone, English, light, compact, with signals logged temporarily
  (an `NSLog` in `AnalyticsSpy`, since removed): a browse open (`browse`); a leave at `compound`
  on a tab switch; `resume` on the return; a leave at `example` after scrolling ser to the bottom
  and backgrounding; `resume` on returning to the foreground; "come" opening venir (`opened`,
  `exactGlossSense`, `3-5`, `11+`, `2-5`); a second open (llegar) from the same results sending no
  second `finishSearch`; the guess for "hablr" (`guess`, `0`, `1`, page `searchGuess`); "xyzzyq"
  cleared (`noResult`, `none`); "tener" left in the background (`abandoned`, `exactInfinitive`);
  deeplinks with `?source=widget`, with `?source=control` on `verb/random`, and with none
  (`deeplink`); and a verb from decir's model page (`model`). Over the session the views and
  leaves paired, ten and ten. iPad, Spanish, dark, regular: a card tapped right after focusing the
  empty field (pushed, `browse`); ⌘F, "come", ↓↓, Return opening venir from the grid (`2-5`); ⌘F
  from that page, "tenr", and Return opening the guess; and a leave at `example` on backgrounding.
  The widgets and the control were tried through their URLs only, not by tapping them, and nothing
  was tried on a device.
- **A simulator note.** `simctl openurl` raised an "Open in Conjugar?" prompt every time, even
  with the app in front, and the prompts queue. The prompt makes the app inactive, not
  backgrounded, so no visit ends.
- **Behavior to know.** A search that the background ended is not restarted when the app returns
  with its text still in the field, so an open from those results sends no `finishSearch` (the
  page still reports `search`). Konjugieren behaves the same. `viewVerbBrowseView` still fires on
  every return to the list, as before.
- **Tests.** New: `LookupSignalsTests` (wire names, the 21 sources, the sections, each match kind
  sent by name, the four bands, the tracker's lifecycle, every report's parameters, that no
  parameter can echo the query, visits, the section marks, and link sources) and four cases in
  `AppRouterTests` (a verb link's source, the fallback, the control's random verb, an unknown
  verb). The whole suite passes: 652 Swift Testing tests in 35 suites, plus the XCTest suites. No
  suite slowed; `LookupSignals` takes about half a second. The simulator language was English.

## Phase 3: Reflexive-Only Verbs with Their Pronouns

**Ideas:** B2, by analogy. **Ports:** Konjugieren Phase 4. **Depends on:** nothing. **Status:**
Done (2026-11-22, 49b9f19). **Accepted** (Josh, 2026-11-22). Konjugieren's ideas document called B2 not
applicable to Spanish and named the reflexive pronoun as "a separate question"; this phase is that
question's answer.

Konjugieren's Phase 4 made the verb page show a separable verb as a main clause writes it (ich
stehe auf), and made the quiz accept either order. The Spanish counterpart is the 114 verbs that
exist only as pronominal verbs. A learner looks up arrepentirse and finds a page titled
"Arrepentir" that conjugates "arrepiento", a form no one uses.

- For a verb with `isReflexive`, show the infinitive with its pronoun (arrepentirse) as the
  page's title, and every finite form with its pronoun in the place Spanish puts it: proclitic
  before a finite form (me arrepiento, me he arrepentido, no te arrepientas) and enclitic after an
  affirmative imperative and the gerund (arrepiéntete, arrepintámonos, arrepentíos,
  arrepintiéndose), with the written accent that enclisis requires and the dropped -s and -d of
  the nosotros and vosotros imperatives. The participle takes no pronoun.
- The quiz accepts the form with and without its pronoun (pedagogy Phase 0 grades it, and
  pedagogy Phase 1's frame shows it).
- Add a function that returns a verb's form as it is written with its pronoun, beside the bare
  form, in the nonisolated engine layer, with tests over every slot.

For the session to decide and record: whether `TenseBridge`'s output changes or only its callers'
(Konjugieren kept the engine's default and changed the callers, which kept every engine test and
the corpus dumps unchanged); what the widgets and the tutor's `ConjugationTool` show (the tutor
already strips a leading "se"); what search finds once titles change; and whether any Info article
contradicts the new display. Verbs that are often but not only pronominal (levantarse, irse,
quedarse) are out of scope; note how many there are.

**Ask Josh:** whether gustar-like verbs in the list (antojarse, whose real use is "se me antoja")
should show the reflexive paradigm or stay bare.

**From Konjugieren:** a default argument that keeps the engine's output as it was (`clause:
.subordinate` there) let every surface that shows a form to a learner switch at once through one
wrapper, while the oracle tests and the corpus pipelines kept the form they expect.

**Done when** arrepentirse's page reads as Spanish writes it, the enclitic accents are right in
every slot under test, and the quiz accepts both forms.

**How it differed:**

- **antojarse (Josh, 2026-11-22).** Asked before building: antojar shows the reflexive paradigm
  like the other 113 (me antojo, te antojas, se antoja), as the RAE's own tables do. A
  gustar-style table (se me antoja, se te antoja) was offered and declined. pirrar, the other
  borderline verb, is treated the same way.
- **The engine's output does not change; its callers' does, as in Konjugieren.**
  `TenseBridge.conjugate` gained `pronoun: ReflexivePronoun`, defaulting to `.omitted`, the bare
  form. The oracle tests, `CorpusFormsDumpTests`, and `CompoundTense`'s auxiliary keep it. With
  `.written`, a verb flagged `isReflexive` gets its pronoun; any other verb is unchanged. That is
  the function this phase was to add. The placement and the accent rule are in
  `Models/ReflexivePronoun.swift`, `nonisolated`. The pronoun goes on after the irregularity
  marking, keeping each letter's case, so arrepIente becomes arrepIéntete with its red I.
- **The accent rule is general, not a table.** `ReflexivePronoun.enclitic(_:attachedTo:droppingLast:)`
  finds the bare form's stressed vowel, joins the clitic, and writes an accent only if the
  general rules then call for one, or to mark a stressed i or u in hiatus (arrepentíos). It
  syllabifies with diphthongs, hiatus, and the silent u of que/gue. So it also gives deme,
  estate, dime, ríete, vámonos, and sígueme, which Phase 5's pronoun stripping can reuse in
  reverse. The nosotros command drops -s before nos and the vosotros command -d before os.
- **Which surfaces switched.** Every one that shows a form to a learner passes `.written`: the
  verb page (title "Arrepentirse", every card, the gerund arrepintiéndose; the participle and
  future stem stay bare), the widget snapshot (paradigm, gerund, quiz answers and distractors),
  the tutor's `ConjugationTool` (which names the verb arrepentirse in its result), and the quiz's
  shown answer and screenshot fixture. Rows in the Verbs list, the guess, and a model's verb list
  show `VerbMapEntry.citationForm` (arrepentirse), and so do the quiz question and results. The
  Models tab's six-tense grid conjugates only exemplars, and no exemplar is reflexive-only, so it
  was left alone.
- **Search.** "arrepentirse" already found arrepentir (Phase 0 strips "se"), but "arrepentirs"
  partway through typing found nothing. `VerbSearch.Keys` now carries a reflexive-only verb's
  citation form, and the prefix and folded-prefix kinds also match it. Nothing else in the
  ranking moved.
- **Deeplinks.** The widgets now name a reflexive-only verb arrepentirse, so `AppRouter`'s verb
  route accepts an infinitive with "se" and opens the bare one (`conjugar://verb/arrepentirse`,
  and also `verb/levantarse` for levantar). `docs/feature_architecture.md` says so for Phase 10.
- **The quiz.** `Quiz.grade` accepts the written form and the bare one, taking the better result,
  and collapses runs of spaces. Grades are now kept in `Quiz.results`, because the results screen
  used to regrade each answer against the shown answer alone and would have marked a correct bare
  "arrepiento" wrong. **No quiz list holds a reflexive-only verb today**, so a learner meets none
  of this until the pedagogy plan widens the lists; tests cover it.
- **No Info article contradicts the display.** None mentions pronominal verbs; the imperative
  articles' examples (levanten la mano) use levantar transitively.
- **Often but not only pronominal (levantarse, irse, quedarse): not measurable from the data.**
  CORPES lemmatizes nearly every such use under the bare verb, so `hi` cannot tell them apart:
  only 8 verbs outside the 114 have a "-se" lemma in CORPES at all. Six of those have no bare
  lemma (alcoholizar, encorbatar, descompasar, acorchar, encenagar, adinerar), which makes them
  candidates for `rx="1"` that Annex B did not mark. They were not changed. How many verbs are often
  pronominal (levantarse, irse, quedarse, sentarse, llamarse) would need a dictionary source;
  the map has no field for it.
- **What was tried where.** iPhone, English, light, compact: `conjugar://verb/arrepentirse`
  opening arrepentir's page (title, gerund, presente, pretérito, both command cards, perfecto),
  and "arrepentirs" in the search field finding one row, arrepentirse. iPad, Spanish, dark,
  regular, with Explorar Tú y/o Vos set to Ambas: arrepentirse's two-column page, then quejarse's
  with its vos rows (te quejás) and commands (quéjate, quejate, quéjese, quejémonos, quejaos,
  quéjense). The widgets, the tutor (unavailable in the simulator), and the quiz (no reflexive
  verb to draw) were checked by tests only. The iPad simulator was left in dark appearance.
- **VoiceOver.** No new control. The forms are still one `ConjugationText` each, tagged Spanish,
  so "me arrepiento" is read as one Spanish phrase, and a tap speaks it whole.
- **Tests.** New: `ReflexivePronounTests` (arrepentirse in every finite and non-finite slot, four
  verbs' commands and gerunds, all 114 verbs in every slot checked for placement and for at most
  one accent, the accent rule on 13 words, the marking, the citation round trip, search, and quiz
  grading) and a pronominal deeplink case in `AppRouterTests`. The whole suite passes: 668 Swift
  Testing tests in 36 suites, plus the XCTest suites. `ReflexivePronoun` takes about 1.5 seconds,
  most of it the 114-verb sweep; no other suite slowed. The simulator language was English.

## Phase 4: The Conjugation Map as a Build Product

**Ideas:** A5, first half. **Ports:** Konjugieren Phase 5. **Depends on:** nothing (Phase 3 only
if it changes what a form is). **Status:** Done (2026-11-22, fe24e92).

- A macOS command-line target that compiles the engine's sources and writes a compact
  form-to-cells map for the app bundle: each single-word form with its infinitives, tenses, and
  persons, vos forms included.
- A Run Script build phase that regenerates the map only when `verbModelMap.xml` or an engine
  source is newer than the output. A build with no changed input must not run the tool.
- A loader in the app, and a function that answers "which cells of this verb equal this text?"
  It matches exactly by default, with an option to fold accents, because the pedagogy plan's
  Phase 3 must tell a missing accent (a slip) from an accent that marks another tense (hablo for
  habló, a real error).

**Measure first.** `forms_all.json` already holds 254,328 forms for every verb, about 9.7 MB as
pretty JSON. Measure the map as one sorted line per form, compressed (Konjugieren used LZFSE: 1.4
MB of text, 173 KB in the bundle, for 50,056 forms), and tell Josh the size before shipping it.
Konjugieren's in-tool build took about 2 seconds; Conjugar has roughly five times the forms.

**Risks to settle first:** the engine is `nonisolated`, but find whether `DisplayPersonNumber`,
`DisplayTense`, `VerbMap`, or `TenseBridge` reach `L`, `Current`, or `Bundle.main`, and move or
parameterize what they do. A new target needs `project.pbxproj` changes; if that has to happen in
Xcode's interface, ask Josh. If the refactor looks large (a local Swift package, say), stop and ask
before starting it.

Also decide whether the tool replaces `CorpusFormsDumpTests` as the writer of
`corpus/working/forms.json` and `forms_all.json`. Konjugieren's tool did, after its first output
proved byte-identical to the harness's last, and the harness was deleted. Record the decision in
`docs/project_structure.md`, `docs/example_corpus_sources.md`, and `frequency/README.md` wherever
they name the harness.

**From Konjugieren:**

- A tool's executable can stand for the engine sources as a Run Script input, so a code change
  that relinks the tool reruns the phase and a comment-only change does not. Judge "skipped" by
  file timestamps, not by the build log, which carries forward earlier builds' records.
- Write the map straight into the app bundle so nothing generated is committed. Build the tool for
  the host architecture only, with no dSYM and `SKIP_INSTALL`, and check that an unsigned
  `xcodebuild archive` holds only the app with the map inside.
- A second test compares the bundled map with a fresh in-process build, which catches an engine
  dependency the tool does not compile.
- "Which cells equal this text" made six engine calls per cell there; compute it lazily.

**Done when** a clean build produces the map, an unchanged rebuild skips the tool, and a test
confirms that the map finds the verb of at least 99% of `ExampleUses.json`'s 1,340 examples by
their `token`. State the measure exactly (folding or not, what counts), since Konjugieren's first
version of the test came out at 98.99% for want of one fold.

**How it differed:**

- **The risks were smaller than in Konjugieren.** The engine already compiled for macOS as it
  stands: 26 files from `Models/` (the feature family, `Conjugator`, `ModelCatalog`, `VerbModel`,
  `VerbMap`, `VerbType`, `RegularRoot`, `TenseBridge`, `CompoundTense`, `IrregularityMarker`,
  `ReflexivePronoun`, `DisplayTense`, `DisplayPersonNumber`, the engine's tense and person types,
  the two error types) plus `ConjugationMap.swift`. None of them reaches `L`, `Current`, or
  `Settings`, so nothing moved and no stand-in World was needed. The one seam is
  `VerbMap.resourceURLOverride`, a `nonisolated(unsafe) static var` that the tool sets before
  touching `VerbMap.shared`, because a command-line tool has no bundle. Josh did not need to do
  anything in Xcode.
- **The target was added by editing `project.pbxproj`**, as in Konjugieren: a synchronized
  `ConjugationMapTool/` folder for `main.swift`, and a membership exception on the `Models`
  folder listing the engine files. The app target depends on the tool, and its "Generate
  Conjugation Map" Run Script phase (after Resources) declares `verbModelMap.xml` and the tool's
  executable as inputs and the bundle's `ConjugationMap.lzfse` as output. Measured by
  timestamps: an unchanged rebuild touched neither the tool nor the map; touching
  `verbModelMap.xml` reran the phase; a code change to `ConjugationMap.swift` relinked the tool
  and reran it; a comment added to `VerbType.swift` recompiled without relinking and did not. An
  unsigned `xcodebuild archive` for a generic iOS device produced `Products/Applications/
  Conjugar.app` only, with the map inside, byte-identical to the one a standalone build wrote.
  **Not tried:** Xcode's own interface, and an Apple Silicon Mac.
- **Two settings Konjugieren's tool lacks.** The tool is built `-O` and whole-module even in
  Debug: unoptimized it took 9.8 seconds to write the map, optimized 2.9, and it runs on every
  build whose input changed. And `ENABLE_CODE_COVERAGE = NO`, because the scheme's test coverage
  instrumented the tool even in a plain build, and every run of the phase then dropped a
  `default.profraw` into the repository root. (`CLANG_ENABLE_CODE_COVERAGE` was tried first and
  changes nothing.) Konjugieren's tool may have the same profraw problem if its scheme gathers
  coverage.
- **The measure, and a new format.** As the plan asked, the map was measured before anything else.
  One sorted line per form, Konjugieren's format with each cell written as a four-letter code
  (`fue	ir ptts	ser ptts`), came to 7.1 MB of text and 1.41 MB as LZFSE, eight times
  Konjugieren's map, because Conjugar has five times the forms and every cell needs naming. One
  line per verb with the forms in a fixed cell order was 740 KB. **Writing each form as a delta
  from its infinitive** (hablar's hablo is `2o`, drop two letters and add "o"; ir's voy is
  `2voy`) makes every regular verb's line identical after the infinitive, and the file came to
  **1.8 MB of text and 43 KB as LZFSE** (28 KB as LZMA, not worth a second codec). Loading
  inverts it into the form index, about 0.6 seconds on this Mac, so Phase 5 should load it from
  a background task as the plan says. 254,328 forms from 4,811 verbs, 293 forms shared by two
  verbs, exactly the counts of the old `forms_all.json`.
- **What a form is.** The map's cells (`ConjugationMap.oneWordCells`, 72) are the infinitive, the
  gerund, the participle, the nine simple tenses in seven persons with vos, and the imperativo
  positivo's six. Compounds and the imperativo negativo are left out, since their last word is
  already a participle or a subjunctive cell. A cell is a `ConjugationCell` (a `DisplayTense` and a
  `DisplayPersonNumber`), so Phase 5 can name a row in the page's own tense names. Phase 3 did not
  change what a form is: the map holds the bare forms (arrepiento), as the corpus dumps always
  did, so Phase 5's pronoun stripping must run before the lookup, for arrepiéntete as for
  dímelo.
- **"Which cells of this verb equal this text" does not read the map.**
  `ConjugationMatch.cells(of:equalTo:accents:)` conjugates every displayed cell of the one verb
  (about 150 engine calls), because the pedagogy plan's diagnoses need compound cells (ha hablado
  for he hablado) and negative commands, which the map leaves out. `.exact` is the default;
  `.folded` drops acute accents and the diaeresis and keeps ñ, which pedagogy Phase 3 may revisit
  when it asks Josh about ñ. A reflexive-only verb matches with its pronoun or without. A verb
  outside `VerbMap` matches nothing, because the engine otherwise conjugates "xyzzar" as a
  regular verb, which the first test run caught. A test checks that the matcher and the map agree
  on every one-word form of seven verbs.
- **The tool replaces `CorpusFormsDumpTests`.** Its `forms_all.json` was byte-identical to the
  harness's last output (August 30). Its `forms.json` differed, but only because the harness had
  last run before the ranking of August 30: the old file held 988 verbs, the new one the 1,000 most
  common by today's ranks (52,825 forms). Restricted to the old 988 verbs, the new forms are
  identical. The harness is deleted, and `scripts/write_forms_json.sh` writes both files. Updated
  where the harness was named: `docs/project_structure.md`, `docs/example_corpus_sources.md`,
  `frequency/README.md`, `frequency/aggregate_gbooks.py`, `corpus/working/build_corpus_index.py`,
  `docs/verb_frequency_sources.md`, `plans/example_uses_pipeline.md`, `scripts/README.md`, and two
  test comments that borrowed its `#filePath` idiom. Older plans and audits that mention it as
  history were left alone. `CLAUDE.md` § Core Models names the tool and warns that an engine file
  reaching another app file breaks its build. `docs/feature_architecture.md` § Conjugation Map
  describes the whole piece.
- **The 99% measure, stated exactly.** Each of `ExampleUses.json`'s 1,340 examples is found when
  its `token`, lowercased and with nothing else folded or stripped, is a map key whose entries
  name the example's verb. **1,339 of 1,340 (99.9%).** The one miss is especializar's token
  "especializarse", an infinitive with an enclitic, which Phase 5 is to strip. Since the tokens
  were chosen with the old harness's forms, a second test scans every word of each sentence
  instead of trusting the token. It also finds 1,339 of 1,340.
- **Tests.** New: `ConjugationMapTests` (26 tests in five suites: the bundled map against a fresh
  in-process build of all 4,811 verbs in eight parallel shards, both example measures, shared
  forms, accents and case, vos, non-finite and reflexive-only forms, compounds, defective slots,
  the delta format and its round trip, cell codes, and `ConjugationMatch`). The whole suite passes:
  692 Swift Testing tests in 40 suites, plus the XCTest suites, in 25 seconds. `ConjugationMap`
  takes 10.5 seconds, 7 of them the fresh build, which is the price of comparing every verb; no
  other suite slowed. The simulator language was English.
- **Nothing visible changed**, so the app was not driven in the simulator: the tests run inside
  the app as host and load the map from its bundle. No string, signal, or VoiceOver element was
  added.

## Phase 5: Reverse Lookup in Search

**Ideas:** A5, second half. **Ports:** Konjugieren Phase 6. **Depends on:** Phases 0 and 4.
**Status:** Done (2026-11-22, 6c0ed97).

Konjugieren's ideas document rated this highest for Conjugar, whose American learners read Spanish
and meet forms before infinitives.

- A form finds its verb. Each result row names the match, as in "fue: Pretérito (él)". When a
  form belongs to two verbs (fue and fui of ser and ir, ve of ir and ver, siento of sentir and
  sentar), show both.
- Accents rank as Phase 0 ranks them: "hablo" shows hablar's presente (yo) first and its pretérito
  (habló, él) after it, each named. An accentless "se" or "de" should not bury sé and dé, and
  should not list every verb.
- **Pronouns, the Spanish counterpart of Konjugieren's stranded particles.** Strip up to two
  enclitic pronouns from an imperative, a gerund, or an infinitive, remove the accent that
  enclisis added, and confirm the remainder is such a cell: dímelo and dámelo find decir and dar,
  levántate finds levantar, diciéndole finds decir. Drop leading pronouns and a leading "no":
  "me levanto", "se lo dije", and "no hables" find their verbs.
- **Compounds and periphrases.** "he hablado" and "habría dicho" look up the participle and
  confirm the haber form. A leading subject pronoun ("yo hablo") is dropped.
- **Vos forms** (hablás, tenés, sos) find their verbs and are named as vos cells.
- **Participles with gender and number** (hecha, rotos, dichas) strip to the -o form before lookup,
  and only if what remains is a participle cell of the verb.
- Opening a result lands on the matching section of the verb page with the form marked.

The empty state from Phase 1 now appears only when this lookup also fails. Decide whether its
guess should consider forms too (Konjugieren's did: ginng guessed gehen through ging).

**From Konjugieren:**

- Josh's ranking there put conjugation kinds after the two exact-infinitive kinds and a folded
  conjugation after every literal kind, so that war found sein before warten. Check the Spanish
  equivalents: "ve" should not bury ver under verter, and "come" should show comer's él come.
- Name rows in the tense names the page uses, with persons in parentheses rather than "and", which
  needs no localized conjunction inside a Spanish line.
- The landing scroll must use the page's own order of sections. Phase 6 reorders the page, so
  derive the order from one place, as Konjugieren's `ConjugationTable` became, or Phase 6 will
  break the landing.
- Build the index on a background task when the list first appears, and memoize the last query's
  results, since SwiftUI evaluates the body several times per keystroke.
- Konjugieren's "Look Up" intent (Phase 11 here) reads the verb list's own results type, so design
  it to be called from outside the view.

**Done when** each example above finds its verb, tests pin them, and opening a result lands on the
marked form.

**How it differed:**

- **The ranking, decided in session rather than asked.** The two new kinds, `conjugation` and
  `foldedConjugation`, sit after `exactGlossSense` and before `infinitivePrefix`. Below the gloss
  sense, because 168 English gloss senses are also Spanish forms, and a form above them would have
  undone Josh's Phase 0 choice for "come" and sent "listen" to listar, "load" to loar, "tire" to
  tirar, and "dance" to danzar before escuchar, cargar, cansar, and bailar. Above the prefix,
  because "ve" must find ir and ver before venir and verter. So "come" gives llegar, venir,
  acudir, then comer (él come, and tú's command), now ahead of comenzar. **Unlike Konjugieren**, a
  folded form ranks right after a literal one, not below every literal kind: Spanish learners leave
  accents out, and "se", "de", and "esta" must find saber and ser, dar, and estar before the
  hundreds of verbs that begin with those letters. Konjugieren's reason for ranking it low (zahl is
  zahlen's literally, zählen's only folded) still holds, because a literal form still leads. Josh
  may want to see this; the queries are in `ReverseLookupTests`.
- **What the code looks like.** `ConjugationIndex` (`Models/`) indexes the map by folded spelling
  and, for the guess, by first letter and length. `FormLookup` (`Models/`) finds the forms, and
  `MatchedForm` names them. `VerbSearch.Match` gained `forms`, and `VerbSearch.matches(for:in:index:)`
  merges conjugation matches into the per-verb best. Rows and verbs still correspond one to one, so
  Phase 1's keyboard code (`keyboardTargetCount`, `openKeyboardSelection`) needed no change, unlike
  Konjugieren's folded row. The index is built in a detached task when the Verbs tab appears
  (about a second); the list already memoized its results in `@State`, recomputing only when the
  text changes, so no cache type was needed. In a Debug build a search takes about 20 ms, as before
  Phase 5 (the infinitive scan dominates); a several-word query adds a few milliseconds.
- **More than the phase named.** Up to two enclitics come off a command, a gerund, or an infinitive,
  and each candidate is confirmed by rejoining it with Phase 3's `ReflexivePronoun.enclitic`, so the
  accent rule runs only forward and nothing merely shaped like a form matches: dime finds decir's
  command, never dar's pretérito di. The nosotros command's dropped -s before nos and se
  (vámonos, démoselo) and the vosotros command's -d before os (levantaos, but idos) are restored.
  "dimelo" without its accent finds dímelo as a folded match. A subject pronoun narrows the persons
  ("ella hable" names only the él and usted cells) unless nothing would remain. A periphrasis that
  no cell confirms finds the verb of its non-finite last word ("estoy hablando", "voy a comer"),
  since Phase 7's article is on periphrasis. A reflexive-only verb matches with its pronoun ("me
  arrepiento") through `ConjugationMatch`. Participle endings are tried always, not only when
  nothing else matches as in Konjugieren, because the participle check keeps them honest and a word
  such as "rota" is both a form of one verb (rotar) and a participle of another (romper).
- **"no hables"** is first confirmed whole, so it is named "no hables: Imperativo Negativo (tú)", not
  as the presente de subjuntivo; "no hablo" falls back to "hablo".
- **Naming.** "hablo: Presente de Indicativo (yo)" then, on its own line, "habló: Pretérito (él)":
  one line per spelling, literal first, tense groups joined by " · ". Every word is Spanish, the
  tense names being Spanish only in this app, so each line is one element tagged Spanish, simpler
  than Konjugieren's two. A command's third persons are named usted and ustedes; finite tenses use
  the page's pronouns (él, ellas). Persons go in parentheses, as Konjugieren found. The lines are
  caption-sized in the rank badge's blue.
- **Vos.** The map has a vos cell in every tense, so most tú forms are also vos forms. Where tú and
  vos share a spelling in a tense, the person the browse setting hides is left out of the name, so a
  learner who never chose vos does not read "(tú, vos)" everywhere. A folded form all of whose
  cells are hidden (ver's vé for "ve") is dropped when another form remains. A vos-only form
  (hablás, sos, or "tenes" for tenés) always shows, and **the page then shows the vos row too**,
  whatever the setting, so the mark has a row to sit on; likewise tú for a learner who chose vos.
  The first version dropped "tenes" entirely, which the simulator check caught.
- **Landing.** `VerbDestination` carries `marks`, a set of `ConjugationCell`s. The page tints marked
  forms (yellow, as Konjugieren does), VoiceOver reads "Matches your search" / "Coincide con tu
  búsqueda" as their value, and on first appearance the page scrolls to the first card in its own
  `sections` order with a marked row. **For Phase 6:** the landing reads the page's actual cards, so
  a reordering cannot misdirect it; but a row's names, and the order of its lines, follow
  `ConjugationMatch.allCells`, which is built from `DisplayTense.conjugatedTenses`. If Phase 6
  reorders the page through a new owner of the order, derive `allCells` from it too.
- **The guess considers forms**, as Konjugieren's did: "tenjo" guesses tener and shows "tengo:
  Presente de Indicativo (yo)", and opening it marks tengo. An infinitive wins any tie, so "hablr"
  and "tenr" keep their Phase 1 guesses. Scanning every form made a nonsense query take 1.8 seconds
  in Debug, so a form must begin with the query's first letter (Conjugar's guess already assumes a
  learner gets the start right), forms are compared as bytes, and `editDistance(_:_:limit:)` gives
  up past the limit: 85 ms for "xyzzyq", 38 ms for "tenjo". Forms are not scanned at all when an
  infinitive is one edit away. `VerbSearch.guess(for:in:index:)` returns a `Guess`; `closestVerb`
  remains as its infinitive half.
- **Phase 1's notes, settled.** The empty state appears only when every lookup fails. The keyboard
  code needed nothing. The placeholder is now "Verb, conjugation, or English meaning" / "Verbo,
  conjugación o significado en inglés" (key `BrowseVerbs.searchPromptVerbConjugationOrMeaning`),
  as Konjugieren's says "conjugation". The Spanish one just fits the iPhone 17's field; "forma"
  was the fallback if it had not.
- **Analytics.** `conjugation` and `foldedConjugation` are now sent as `matchKind`. The staged
  privacy bullet's examples gained "a conjugation such as fue" / "una forma conjugada como fue".
  No signal or parameter was added.
- **The example measure.** Every one of `ExampleUses.json`'s 1,340 tokens, typed into the search as
  it stands, finds the example's verb among the results (1,340 of 1,340). Phase 4's one miss,
  especializarse, is found by Phase 0's "-se" stripping and by the enclitic split.
- **What was tried where.** iPhone, English, light, compact: "hablo" (two lines; opening hablar
  scrolled to the presente with hablo and habló tinted), "tenes" (tenés named; the page added vos
  rows and tinted tenés), "habria dicho" (condicional compuesto (yo, él), landing far down the page),
  and "tenjo" (the guess with its tengo line). iPhone, Spanish, dark: the placeholder, "dimelo"
  (dímelo named, landing on the imperativo positivo with di tinted). iPad, English, dark, regular,
  with the browse setting at Both: "siento" (sentir and sentar cards, each with its line) and
  "hubieran dicho" (landing on the grid's pluscuamperfecto de subjuntivo 1 card, at the bottom of
  the scroll). Once, a tap on the iPhone right after a cold launch and typing opened tener unmarked,
  because the first search waits for the index and the tap reached the row first; on a second try,
  and in every later one, the marks arrived. Not tried: VoiceOver, keyboard Return on a form row,
  and a device.
- **Tests.** New: `ReverseLookupTests` (32 tests, several parameterized: the plan's
  examples, naming, the ranking beside Phase 0's table, enclitics forward, vos, participles,
  periphrasis, the guess, and the example measure). The whole suite passes: 723 Swift Testing
  tests in 41 suites, plus the XCTest suites, in 36 to 46 seconds over two runs (25 before). `ReverseLookupTests`
  takes about 8 seconds, 6 of them the example measure; `LookupSignals` went from half a second to
  3, probably because whichever suite searches first builds the index. The simulator language was English.

## Phase 6: The Verb Page's Sections

**Ideas:** B3 as Josh amended it, and the tip from B5's verdict. **Ports:** Konjugieren Phase 7.
**Depends on:** Phase 4 for the count's cells. **Status:** Done (2026-11-22, 6c0ed97).

- **Order by frequency within each block.** Keep the simple tenses before the compound ones, and
  within each block order the tenses by how often they occur in Conjugar's corpus:
  `corpus/originals/government`, `literature`, and `technology` (not `medieval`). Write the
  counting method and its results in a doc (`docs/tense_frequency.md`), with a script that
  reproduces them (`scripts/count_tenses.py`, reading a `--cells-json` output of Phase 4's tool, as
  Konjugieren's did). Spanish makes this harder than German in two ways the doc must address:
  many forms belong to two tenses (hablamos is presente and pretérito; hable is presente de
  subjuntivo and the usted imperative), and the literature folder is mostly nineteenth-century
  novels plus the 1605 *Quijote*, whose tense mix is not today's. Say how each was handled.
  Change the order on the verb page only, not in Info, the quiz, the Models grid, or the widgets,
  unless Josh says otherwise. Ask Josh where the imperatives belong once the numbers are in.
- **Second names.** Beside or under each heading, give the other name a learner will meet. Spanish
  has several naming systems: the RAE's (pretérito perfecto simple, pretérito imperfecto,
  pretérito perfecto compuesto), Andrés Bello's, used in Mexican and other Latin American schools
  (copretérito, pospretérito, antepresente), the older "pretérito indefinido", and the English
  textbook names (preterite, present perfect). "Imperfecto de Subjuntivo 1" and "2" could say "the
  -ra form" and "the -se form". Draft the list in both languages, with a recommendation of which
  systems to show, and show Josh before committing it.
- **Article buttons.** An info-in-a-circle button at the right of every tense heading opens that
  tense's Info article (`Info.infos`, by `stableKey`).
- **Red-letter tip.** A TipKit tip on the verb page explains what red letters mean. Once dismissed,
  it never reappears.
- **Scroll tip.** After the red-letter tip is dismissed, a second tip encourages scrolling to the
  bottom for the etymology and the example sentences. It also never reappears.

**From Konjugieren:**

- Count with the tool's own cells so the count and the page agree on what a form is. Read samples
  of each count before trusting it; three fixes there came from reading samples.
- Josh first placed the participles where their count put them, then, after trying the page, moved
  them to the end of the simple block, because one-line cards between six-row tables looked wrong.
  Conjugar's non-finite forms already sit in the header, so the question here is the imperatives.
- On iPad the grid flows row by row, so a one-row card beside a six-row card leaves a hole.
  Konjugieren stacked short tables in the grid cell above them and aligned rows to the top.
- One type should own the page's order, each table's second names, and its article
  (`ConjugationTable` there), and Phase 5's landing should read it.
- The article opened in a sheet over the verb page rather than switching tabs, so closing it
  returned to the same verb; a link to another article opened inside the sheet; a link to a verb
  closed the sheet and opened the verb. `InfoView` gained an optional `openLink`. A new signal
  counted the taps (`tapConjugationgroupArticle` there; `tapTenseArticle` here).
- The red-letter tip appears only on a page with red letters, since a regular verb's page leaves it
  nothing to point at. The scroll tip is unlocked by a persisted TipKit parameter on the next verb
  page that appears, and reaching the etymology or the examples retires it. Both obey
  `TipDisplay.tipsEnabled` (`Utils/KillSwitches.swift`), the screenshot kill switch.
- VoiceOver should hear a second name alone, in its own language, because one element cannot speak
  English and Spanish.

**Done when** the page shows the new order with second names and article buttons, both tips behave
as described on a fresh install, the doc and script reproduce the count, and tests pin the order.

**How it differed:**

- **Josh's decisions (2026-11-22), asked once the numbers were in.** (1) The order weighs official
  prose and literature equally ("by register"), not each folder a third. The technology folder is
  governments' digital strategies, so equal folders let planning prose outvote the novels two to
  one, which put the futuro second and the pretérito fifth. (2) The two imperatives stay together
  at the end of the simple block; the counts put the positivo one row higher. (3) The second names
  as drafted, below. The page now reads Presente de Indicativo, Imperfecto de Indicativo, Pretérito,
  Presente de Subjuntivo, Futuro de Indicativo, Condicional, Imperfecto de Subjuntivo 1 and 2,
  Futuro de Subjuntivo, Imperativo Positivo and Negativo; then Perfecto de Indicativo,
  Pluscuamperfecto de Indicativo, Perfecto de Subjuntivo, Pluscuamperfecto de Subjuntivo 1,
  Condicional Compuesto, Pluscuamperfecto de Subjuntivo 2, Futuro Perfecto, Pretérito Anterior, and
  Futuro Perfecto de Subjuntivo.
- **The count.** `scripts/count_tenses.py` reads `ConjugationMapTool --cells-json` (new,
  `ConjugationMapTool/CellsJSON.swift`), as Konjugieren's did. No tagger was installed, so Spanish's
  real problem, verb forms that are also nouns (desarrollo, condiciones, valores), is handled by
  context rules found by reading samples: the first run gave the imperativo positivo 13% of the
  government folder, all of it adjectives such as resultados and generales split as a command plus
  "os" or "les". Enclitics are now confirmed forward by the accent rule, as `FormLookup` does.
  The doc's two required problems: spellings of two tenses (hablamos) are split by the proportion
  of unambiguous forms of the same cells, 0.5% of verb words; the old literature, the 1605 Quijote
  included, was kept, since weighing by register already halves it and dropping the Quijote moves
  no card under Josh's imperative choice.
  [`docs/tense_frequency.md`](../docs/tense_frequency.md) has all of it.
- **A corpus file was English.** `corpus/originals/literature/marianela-galdos-1878.txt` was Clara
  Bell's 1883 translation, not Galdós's Spanish, though `docs/example_corpus_sources.md` called it
  "clean Spanish-only". No shipped example came from it. At Josh's word (2026-11-22) it was deleted
  and dropped from `corpus/working/fetch_corpus.sh`, the two index builders' `LIT_WORKS`,
  `ExampleSource`'s table, and the Info credits (English and Spanish), which had named *Marianela*
  as a source. `count_tenses.py` keeps its English-file check as a guard. The gitignored pipeline
  intermediates in `corpus/working/` still mention it until they are rebuilt.
- **`ConjugationTable`** (`Models/ConjugationTable.swift`) is a struct over `DisplayTense`, not an
  enum of its own as in Konjugieren, because Conjugar's cards already correspond one to one with
  tenses. It owns the order, the second names, and `articleKey`. `ConjugationMatch.allCells` is
  derived from it, as Phase 5's note asked, so a search row now names tenses in the page's order;
  `VerbView.section(markedBy:)` reads its first simple and first compound tense.
  `DisplayTense.conjugatedTenses` is unchanged, because the map's file format depends on it.
- **Second names follow the interface, not the heading language.** Konjugieren's headings switch
  language; Conjugar's are always Spanish, so the English interface gets the English textbook name
  and the RAE name where it differs ("also preterite · pretérito perfecto simple"), and the Spanish
  one gets the RAE and Bello names ("también pretérito imperfecto · copretérito"). The two presentes
  have none in Spanish. VoiceOver gets each name as its own element in its own language through
  `accessibilityRepresentation`, and the heading is now tagged Spanish too.
- **The article sheet** is Konjugieren's, simpler: Conjugar's articles link only to other articles,
  so a link pushes inside the sheet and nothing has to leave it. `InfoView` already took a
  `navigate` closure, so it needed no change. The ⓘ glyph was 17 points; `Layout.tapTargetInset`
  grows its hit area to about 47 without moving the heading. New signal `tapTenseArticle`, no
  parameters, with its policy lines staged.
- **The tips** match Konjugieren's: `RedLettersTip` only on a page with a red letter (the header's
  forms count, so tener's raíz futura tendr- would do), `ScrollToBottomTip` unlocked on the next
  page after the first is closed and retired by reaching the etymology or examples.
- **iPad.** `BrowseLayout.detailColumns` now aligns to the top, so a five-row imperative starts
  level with the seven-row card beside it. With 20 cards, Imperativo Negativo shares a row with
  Perfecto de Indicativo, as it shared one before this phase.
- **What was tried where.** iPhone, English, light, fresh install: tener's page in the new order
  with second names and the red-letter tip; the Presente de Indicativo article from its ⓘ, closed
  with Done; closing the tip; hablar's page next showing the scroll tip; scrolling to the bottom;
  comer's page then showing neither tip. iPhone, Spanish, dark: decir's page ("también pretérito
  perfecto · antepresente", "también antepospretérito"), the Pluscuamperfecto de Subjuntivo 1
  article ("Listo"), a link inside it to Condicional Compuesto pushing within the sheet, and Listo
  returning to decir. iPad, English, dark, regular, vos rows shown: tener's two-column grid with the
  red-letter tip, and the imperatives' rows aligned to the top. Not tried: VoiceOver itself (the
  accessibility tree was read with `describe-ui`), the Spanish interface on the iPad, the kill
  switch off, and a device.
- **Tests.** New: `ConjugationTableTests` (12 tests: the order, one card per tense, simple first,
  the other screens' order unchanged, the landing marks, search names in page order, every article,
  the second names in both interfaces, and the signal's wire name). The whole suite passes: 735
  Swift Testing tests in 42 suites, plus the XCTest suites, in 39.5 seconds. The simulator language
  was English.

## Phase 7: An Article on Periphrasis

**Ideas:** B7's verdict, by analogy. **Ports:** Konjugieren Phase 8. **Depends on:** nothing.
**Status:** Done (2026-11-22, 048f585). **Accepted** (Josh, 2026-11-22), on ir a + infinitivo and
estar + gerundio.

Konjugieren's B7 found the verb page lacking two constructions a learner meets every day (the Futur
II and the passive). Josh rejected new sections on the page and accepted an Info article that shows
the construction by example. Conjugar's page has every tense, but it lacks the constructions that
carry much of spoken Spanish: the periphrastic future (voy a hablar), the progressive (estoy
hablando), and the passive (fue escrito, se venden).

Write one Info article in English and Spanish, on ir a + infinitivo and estar + gerundio, the two
constructions a beginner needs (the passive is left out). Follow the existing tense articles'
structure and Info markup (`.claude/rules/localization.md`), with full examples for a regular and an
irregular verb, when each construction is preferred, how it differs by region, and authentic
examples found in `corpus/originals` and translated. Cross-link it from the Futuro de Indicativo and
Gerundio articles. Add a test that every Info link (`%…%`) in both languages opens an article or a
verb.

Choose where in the Info list it goes, and record why.

**From Konjugieren:** that article ran about 2,800 words in each language. Its link test found three
broken links on its first run, so expect some. Phase 10 gives Info a `stableKey` route; until then,
check how articles are addressed before choosing a position in the list.

**Done when** the article exists in both languages, its cross-links work, and the link test passes.

**How it differed:**

- **The heading** is "Perífrasis Verbales", the same in both interfaces, like the tense headings
  beside it, with the key `perifrasis_verbales`. The Gerundio article already called the progressive
  a "verbal periphrasis", so the term was the app's own. Since the heading is general, the article
  ends with a short list of the other periphrases a learner meets first (tener que, haber de, deber,
  acabar de, volver a, empezar a and ponerse a, dejar de, seguir, llevar, ir, and andar + gerundio).
  The passive is still left out.
- **Placement.** Conjugar has no `info` deeplink yet; articles are found by `stableKey` (the
  screenshot driver, `ConjugationTable.articleKey`) or by heading (the `%…%` links), never by
  position, so any position was safe. The article sits in the Tenses section after Raíz Futura and
  before Perfecto de Indicativo: after the non-finite forms it is built from and before the compound
  tenses, which share its shape of helper plus form. It is `.easy`, because a beginner needs both
  constructions, so it shows under every filter. The filter counts are now 11, 19, and 30. The
  screenshot driver's Info shots scroll to the About header, above it, so they are unaffected.
- **The article** runs about 2,300 words in English and 2,400 in Spanish, between the tense articles
  (about 250) and the About essays. Sections: the two constructions; ir a, its form (hablar and
  tener), its uses, and the futuro as its rival (register, conjecture, commands, iba a against the
  condicional); estar + gerundio, its form (hablar and decir) and uses; what the progressive does not
  do that English -ing does; where pronouns go; regional variation (voseo, vosotros, the American
  preference for ir a, the commercial "le estaremos enviando", Ecuador's dar + gerundio, Mexico's
  "ha de ser"); the other periphrases; and the cantare habeo cycle, linked to the verb history.
  Irregular letters are marked as the engine marks them (VOY, VAs; estoY, estÁs; dIciendo),
  checked with a throwaway test that printed the engine's forms. The Spanish version keeps English
  glosses, as the Spanish tense articles do.
- **The examples are authentic**, found in `corpus/originals` and translated by Claude: Galdós's
  *Fortunata y Jacinta* (Fortunata mixing querré, viviré, vamos a ser, and tendremos in one breath;
  "iba a tener … y adquiriría" in one sentence; Maxi's "la idolatraré... no, que ya la estoy
  idolatrando"; Juanito's "Te vas a reír de mí … ya te estás riendo", which shows both pronoun
  placements; "se está vistiendo"), the *Quijote*'s second part (Sancho's "Voy a buscar … a una
  princesa" and "mientras estoy cavando"), *La Regenta* ("estará rezando"), *Pepita Jiménez* ("iba
  a venir", and "la hemos de decir" for haber de), Spain's Movilidad 2030 strategy ("va a
  licitar"), and España Digital 2026 ("están siendo"). Every source was already in the Credits.
  The register figures were counted from the corpus with rough patterns: official prose has 3,807
  synthetic futures to 32 ir a, about 120 to one; the novels 5,234 to 508, about ten to one. The
  article says "more than a hundred" and "about ten".
- **Cross-links.** The Futuro de Indicativo article's ir a paragraph now ends by pointing to the new
  article, and the Gerundio article's line about the progressive links it, in both languages. The
  Futuro paragraph's example was missing its closing quotation mark in both languages, now fixed.
- **No link was broken.** `InfoTests.everyLinkInAnArticleOpensAnArticle` checks every `%…%` target
  in both compiled catalogs against that language's headings (the Spanish tense headings plus the
  localized About headings). Conjugar's links open only articles, never verbs, so the test checks
  articles only. It passed on its first run, unlike Konjugieren's; a Python check of the catalog
  confirms that all 136 cross-references in each language resolve, so the pass is not vacuous. Three
  more tests: unique stable keys, the article's position and difficulty, and the two cross-links.
- **How it was tested.** 739 Swift Testing tests in 42 suites pass, plus the XCTest suites (43.9
  seconds; the simulator language was English). iPhone, English, light: the row after Raíz Futura,
  the article, its tables with red letters, and its links. iPhone, Spanish, dark: the Gerundio
  article, its new link tapped through to the Spanish article. iPad, Spanish, light, regular width:
  the row and the article at reading width. Not tried: VoiceOver, every link in the article, and a
  device.

## Phase 8: Ways Between Verbs

**Ideas:** B4, A9. **Ports:** Konjugieren Phase 9. **Depends on:** nothing; Phase 2's `related` and
`model` sources apply if it is done. **Status:** Awaiting Josh (2026-11-22).

- **B4.** The verb page leads to related verbs: the model's page (make the existing "Irregular
  (like tener)" or "Regular AR" pill a link, which Konjugieren's ideas document sized as small),
  the base verb and its prefixed compounds (tener with contener, detener, mantener, obtener,
  retener, and sostener; decir with bendecir, contradecir, and predecir), and other verbs of the
  same model. Some models hold hundreds of verbs, so the page needs a short list with a way to see
  all. Propose a placement with a screenshot before building it.
- **A9.** On a model's page in the Models tab, a segmented control above "Verbs using this model"
  chooses Alphabetical, the default and today's behavior, or Frequency, most frequent first. The
  choice is not stored.

The base-verb relation is the engine's own: a prefixed verb resolves by its end-anchored base
(`Conjugator`'s comment names detener and reconocer). Compute it from the verb map rather than by
hand, and say how many verbs have a base, and how many bases are not themselves verbs.

**From Konjugieren:**

- Josh chose, from screenshots of a prototype, a Related Verbs card at the bottom of the page,
  below the example sentence, so the top of the page stayed unchanged. The card showed the base
  first, up to six more by frequency, then "All 40", which opened every verb of the relation with
  an Alphabetical/Frequency control, Frequency first.
- Group relatives so a large model is not a wall: one verb per other base, by frequency.
- The verb page is pushed from two stacks here too (Verbs and Models). Konjugieren's `VerbPagePush`
  environment action, injected by each stack, made the card work in both, and the Verbs tab gained
  destinations for a model page and the full list, so a learner who arrives from a widget reaches
  them without switching tabs.
- `ModelView` navigates through an `onSelectVerb` closure today; replace or keep it, but use one
  mechanism for both screens.
- With about 1,000 rows in a non-lazy stack, an accessibility query pegged Konjugieren's CPU for 45
  seconds. Conjugar's regular -ar model holds thousands of verbs; keep every such list lazy.

**Done when** the pill opens the model, the card or chosen placement lists base, compounds, and
model relatives, the model page sorts both ways, and tests pin the relations for tener, decir, and
a regular verb.

**How it differed:**

- **Josh's decisions (2026-11-22), from screenshots of the built card.** (1) The Related Verbs card
  stays at the bottom of the page, below the examples, and the top changes only by a chevron in the
  pill. (2) Only verbs count as bases; see below.
- **The base relation** is `VerbRelations` (`Models/RelatedVerbs.swift`), computed once from the
  verb map. A base is the longest verb of the map that ends the verb after a known prefix (a list of
  56) and whose class number has the same leading number: contener (31-1) on tener (31), predecir
  (28-1) and bendecir (28-2) on decir (28). That is the engine's relation stated in the book's terms,
  and the class rule does real work: it keeps presentar (1) off sentar (4A) and andar off dar. Without
  a prefix list the rule matched -izar and -ear verbs to anything (realizar on "alizar"), so the list
  is needed; res- and tra- were dropped from it because they mostly matched by accident (respetar on
  petar, trabajar on bajar). Reading every pair among the 2,000 most frequent verbs found more false
  ones (escapar on capar, solicitar on licitar, estimar on timar, comparar on parar), and a few
  bases that no real compound uses (piar, pirar, timar), whose rarer verbs were added too;
  `falseCompounds` lists 59 verbs in all.
  Rarer verbs were sampled, not read, so a few false pairs remain there. **976 verbs have a base, and
  605 roots have at least one other verb built on them.** A root follows bases inward (desaparecer →
  aparecer → parecer).
- **No base that is not a verb.** The plan asked how many bases are not verbs. A tail such as -ducir
  or -scribir, shared by two or more verbs of one class after a prefix, gives 257 groups, and many
  are noise (esperar, imperar, operar, and superar on "-perar"; abultar, exultar, and resultar on
  "-ultar"). The good ones, -ducir (34) and -scribir (3-11), already share a model, so the model row
  shows them. Josh chose verbs only (2026-11-22). escribir therefore has no "Built on" row.
- **The card** has up to two rows: "Built on tener" (the root first, then by frequency, six chips,
  then "All N" to `RelatedVerbListView`, Frequency first) and "Conjugated like cantar" (one verb per
  other root among the model's verbs, by frequency, then "All N" to the **model's page** rather than
  a separate list, since that page now sorts both ways). Konjugieren's third row, its family chips,
  has no analog, because the pill already opens the model. The model row is absent when every verb of
  the model shares the root (tener's, decir's). In Spanish: "Verbos Relacionados", "Formados con
  tener", "Se conjugan como cantar", "Ver los 9".
- **The pill** ("Regular AR ›", "Irreg. ☛ tener ›") pushes the model's page, found by
  `ModelInfo.row(for:)`, which folds the alias classes into their parents as the Models tab does. Its
  hit area grows to 44 points with `Layout.pillTapInset`, without moving the rows below. VoiceOver
  hears a hint, "Shows every verb of this model".
- **Navigation** is Konjugieren's `VerbPagePush`, injected by the Verbs and Models stacks, with
  `verbPageDestinations()` registering `ModelInfo` and `RelatedVerbListDestination` in both. The Verbs
  tab can now show a model's page. `ModelView`'s `onSelectVerb` closure is gone; it pushes through
  the same action. Where no stack injects the action (none today), the pill is plain text and the
  card is hidden.
- **A9.** The model page's Frequency/Alphabetical control sits above "N verbs use this model",
  Alphabetical by default, not stored, with both orders sorted once in `init`. The list moved into
  `VerbEntryList`, lazy in both size classes, which the full related list shares.
- **Analytics.** A verb opened from the card or its full list reports `source` `related`, now marked
  sent in `docs/feature_architecture.md`; one opened from a model's page reports `model`, whichever
  tab shows it. The staged privacy bullet's examples now name "another verb's page" / "la página de
  otro verbo". No new signal or section: reaching the card is not a `deepestSection` value.
- **Speed.** The relation index takes about 0.15 seconds to build in the simulator, so
  `ContentCaches.warm()` now builds it at launch, off the main actor. `ModelInfo.all` (the model rows
  and their irregularity percents, about as long) is MainActor and is still built by the first verb
  page or the Models tab, whichever comes first.
- **What was tried where.** iPhone, English, light: detener's pill and card (tener first, "All 9");
  formar's card with both rows; "All 2,968" opening the cantar page in the Verbs tab; hablar's pill
  opening the same page; its control switched to Frequency (pasar, dejar, llevar, quedar, hablar,
  tomar). iPad, Spanish, dark, regular: decir's page with its "Formados con decir" row and no model
  row; poner's "Ver los 22" opening the two-column list and suponer opened from it; then in the
  Models tab, tener's model page, mantener opened from it, and its "Ver los 9" pushing the list inside
  the Models tab. Not tried: VoiceOver itself (the tree was read with `describe-ui`), the iPad in
  English, and a device.
- **Tests.** New: `RelatedVerbsTests` (12 tests: tener, detener, decir, nested roots, formar as the
  regular verb, model relatives one per root by frequency, the class and prefix rules, the
  false-compound list, every base's invariants, the pill's model row, an empty card, and the two
  counts above). The whole suite passes: 751 Swift Testing tests in 43 suites, plus the XCTest
  suites, in 34.6 seconds. No suite slowed; the new one takes about 0.1 seconds. The simulator
  language was English.

## Phase 9: Copy and Share

**Ideas:** B6. **Ports:** Konjugieren Phase 10. **Depends on:** nothing. **Status:** Not started.

- A long press on a form opens a context menu with Copy. A tap still speaks it.
- A share button on the verb page sends a short text: the verb, its gloss, its key conjugations
  with no label, and the App Store link,
  `https://apps.apple.com/app/conjugar/id1236500467` (no storefront, so the App Store opens the
  reader's own).
- Build the key-conjugations function here. Phases 11 and 15 reuse it, and the pedagogy plan
  builds its practice record (Phase 10 there) and its key-conjugations exercise (Phase 14) on it.

**The key conjugations are four** (Josh, 2026-11-22), each the stem a family of tenses is built
on: the yo presente (tengo, which the present subjunctive and most imperatives follow), the yo
pretérito (tuve, which the imperfect and future subjunctives follow), the yo futuro (tendré, which
the conditional shares), and the participle (tenido, which every compound tense uses): "tener:
tengo · tuve · tendré · tenido". Konjugieren's were the er form of three tenses (steht auf · stand
auf · ist aufgestanden); Spanish has no single textbook set, and the pedagogy plan maps its
practice items onto these four, so do not change the set without asking Josh. Say in the
function's comment which tenses each one stands for.

**From Konjugieren:**

- `ShareLink` in the navigation bar reported no tap (so the share signal could not be sent), and
  giving it a `SharePreview` removed Copy from the sheet. `ShareSheet.swift` there presents
  `UIActivityViewController` from a plain `Button` with an `LPLinkMetadata` header (the verb and
  the learner's chosen app icon). On iPad the popover anchors to the button.
- A long press copies the form alone, lowercased, without its pronoun or the ¡…! that wraps an
  imperative, since the capitals only mark red letters. The infinitive copies too. A dash copies
  nothing. VoiceOver gets a named Copy action. The menu's lifted preview cropped the first and last
  letters until the row was padded for the menu and the padding taken back after.
- Return the key conjugations mixed case, so Phase 15's card can show red letters, and lowercase
  them for the share text. A form that fails to conjugate is left out, not returned as a dash. The
  quotation marks around the gloss follow the learner's language.
- The signal is `tapShareVerb`, with no parameters. Copying sends nothing.

**Done when** a long press copies, the share sheet sends the agreed text with Copy available, and
tests pin the key conjugations of a regular, a stem-changing, an irregular, and a defective verb.

**How it differed:** _Not started._

## Phase 10: Links into the App: the Grammar, Search, a Control, and a Quick Action

**Ideas:** C1, first part. **Ports:** Konjugieren Phase 11, which this plan splits in two because
Conjugar has no App Shortcuts to build on. **Depends on:** Phase 5 for the search it opens.
**Status:** Not started.

- **The grammar.** Before adding a route, write down one deeplink grammar in
  `docs/feature_architecture.md` § Deeplinks, and point `CLAUDE.md`'s Deeplinks section at it.
  Konjugieren's: `<scheme>://<route>[/<target>][?items]`, at most one path segment, text only in
  query items, `source` on any route that leads to a page, a search, or a quiz. It should cover
  `search?q=`, `verb/<infinitive>?match=` (a form the page marks, as a search's match is marked),
  `info/<stableKey>` (accepting a position too), and reserve `list/<key>` for Phase 16. Keep
  every existing link working: `quiz` still opens the tab and starts a quiz, because the Quick
  Quiz control uses it, and the `game` routes are untouched.
- A Control Center control that opens a focused, empty search, beside the two controls in
  `ConjugarWidget/`.
- A Home Screen quick action, "Find a Verb", that does the same. Command-F (Phase 1) should go
  through the same `openSearch`.

**From Konjugieren:**

- Install the quick action at launch rather than in Info.plist, so its title comes from the string
  catalog. Receiving it needed an `AppDelegate` and a scene delegate, since SwiftUI has no hook.
  Conjugar already has `Supporting/AppDelegate.swift`. `.onOpenURL` must keep working beside them.
- Give `URL` builders so no app code interpolates a link.
- `finishSearch` there gained `source` (where the search began: `control`, `quickAction`,
  `lookup`, `deeplink`, `tab`), since a page reached through the control's search would otherwise
  report only `search`.

**Done when** the grammar is written, each new route and the old ones work by `simctl openurl` with
the device's UDID, the control and the quick action open a focused search, and tests pin the
routes and their round trips.

**How it differed:** _Not started._

## Phase 11: Look Up a Verb, and Spotlight

**Ideas:** C1's intent, C2. **Ports:** Konjugieren Phase 11, second part. **Depends on:** Phases 5,
9, and 10. **Status:** Not started.

- **App Shortcuts.** Conjugar has none. Add an `AppShortcutsProvider` with English phrases only, as
  Konjugieren's convention is (C3, phrases in the app's second language, was rejected). Ask Josh
  whether the existing intents (`OpenQuizIntent`, `OpenRandomVerbIntent` in `Shared/`) should
  become shortcuts too.
- **Look Up a Verb**, an App Intent that takes a word, answers in the manner of "fue: Pretérito of
  ser and of ir", and opens the page (or the search, when the word has several answers).
- **C2, Spotlight.** A verb entity in a named index, with every gloss and the verb's forms as
  keywords and alternate names, and the key conjugations as its description. Developers report
  that keywords match less reliably than titles, so test on a device if Josh can install a
  development build, and record whether the test ran on a device or in the simulator.

**From Konjugieren:**

- A shortcut's phrase can carry only an entity or an enum, not free text, so the phrase asks
  "Which word should Conjugar look up?". Turn off autocorrection in its prompt; the simulator
  turned ging into Going.
- The intent answers with `.result(opensIntent:dialog:)`, naming a hidden intent that opens the
  result, since a result can open the app only that way. In the simulator the app opened but the
  answer did not show first. Josh should try it with Siri on a device.
- One verb answers when the word is an infinitive or a form of one verb; otherwise open the search.
  Pronoun-stripped matches (Phase 5) should not count against a single answer.
- Spotlight in the iOS 26.3 simulator matched titles only, for entities and classic
  `CSSearchableItem`s alike. Deleting entities from the default index also emptied the named
  index, so do that first, not after indexing.

**Done when** the shortcut answers and opens the page in the simulator's Shortcuts app, Spotlight
finds a verb by its title, and the device test is recorded as done or pending.

**How it differed:** _Not started._

## Phase 12: Recents and My Verbs

**Ideas:** D1, D2 apart from its quiz scope. **Ports:** Konjugieren Phase 12. **Depends on:**
nothing. **Status:** Not started.

- One on-device record of the learner's verbs: each verb opened, with dates and a count, and each
  verb starred. Phases 13 to 16 read it, and the pedagogy plan will. Put it in the App Group
  (`Shared/WidgetConstants.swift` has the group and the shared defaults), because Phase 14's widget
  reads it. iCloud sync was rejected.
- **D1.** When the search field is focused and empty, show the last 20 or so verbs opened.
- **D2.** A star on the verb page, and a My Verbs filter in the verb list that holds starred verbs
  and recent lookups.

**From Konjugieren:**

- The record was `LearnerVerbs` in `Shared/`, Codable, keyed by infinitive, saved as JSON through a
  `GetterSetterReal` given the App Group's defaults. **Every field added later must be optional**,
  because synthesized decoding requires every non-optional key and an older record would decode as
  nothing. Pin that with a test.
- An open is a page's arrival by any route, recorded where `viewVerbView` is sent with a source
  other than `resume`.
- "The list" became a third segment of the verb list's picker, My Verbs, beside the two sorts, with
  Starred then Recent and an empty state. **Josh was asked to judge it** against a star button in
  the navigation bar that toggles the filter; ask again here.
- Added at Josh's request after trying it: a Clear button on the Recent heading (forgets opens,
  keeps stars), and swipe to delete, which forgets a verb entirely and asks first for a starred
  one. Swipe actions exist only on a `List`'s rows, so My Verbs became a `List` beside the
  `ScrollView`.
- **An iPad bug:** a tap outside an empty search field ended its focus at touch-down, so the recents
  vanished under the finger, and the push then arrived while iPadOS was animating the search away,
  and UIKit dropped it. The fixes were a short delay before letting go of the recents
  (`searchIsEngaged`) and waiting until no view controller is presenting or dismissing before the
  push. Try a recent verb on the iPad with a real click.
- The star sits in the navigation bar, reads "Add to My Verbs" or "Remove from My Verbs", and sends
  `tapStarVerb` with `starred` (the state after the tap). AXe could not see the navigation bar's
  buttons on iOS 26, so they were tapped by position.
- Stage a change of the policy's "does not record … the verbs you look up" to "does not send", with
  a paragraph saying the list stays on the device.

**Done when** opens and stars survive a relaunch, recents appear in the focused empty field, My
Verbs lists both, Clear and delete work, and tests pin the record's decoding of an older form.

**How it differed:** _Not started._

## Phase 13: A Quiz over Chosen Verbs

**Ideas:** D2's quiz scope, D3. **Ports:** Konjugieren Phase 13. **Depends on:** Phase 12.
**Status:** Not started.

- A minimal ability for the quiz to take a list of verbs and draw its questions from them.
- A My Verbs scope on the Quiz tab.
- **D3.** A "Test me on this verb" button on the verb page that asks three questions about the
  verb in view.
- The quiz signals gain `source`.

Conjugar's quiz builds every question from a curated list per tense (`VerbFamilies`, through
`Cycler`s), so a scoped quiz needs another draw: for the given verbs, cells from the tenses the
current difficulty asks, distinct within a short quiz, skipping cells a defective verb lacks and
vosotros in the Latin America region. Keep the change small. The pedagogy plan's Tiers 2 to 6 will
reshape the quiz, and this phase should give them something to build on, not compete with. If the
quiz's `(String, DisplayTense, DisplayPersonNumber)` tuples get in the way, a small question type is
fine, and pedagogy Phase 0 will want one.

**From Konjugieren:**

- `QuizScope` carried the verbs (nil for every verb), the reading, the question count, and the
  source; `Quiz.start(scope:)` defaulted to every verb so the tab's old path was unchanged; and
  `QuizScope.isRanked` (every verb, the full length) decided the leaderboard. The quiz's own
  `questionCount` replaced the static count wherever the progress, results, and VoiceOver read it.
- A three-question quiz asked distinct cells and no participle questions, since a quiz's full
  proportions would make three questions all one kind.
- Test Me opened a sheet with its own `Quiz`, so the learner closed it onto the same page and a quiz
  in progress in the tab was not disturbed. The sheet started its quiz as it appeared, focused the
  field, could not be swiped away mid-quiz, started no Live Activity, and donated nothing to the
  difficulty tip. **Conjugar's finish shows the leaderboard automatically**
  (`Current.gameCenter.showLeaderboard()` in `QuizView.finish()`); a scoped quiz must not.
- The Quiz tab gained an All Verbs / My Verbs picker above Start, with a note of how many verbs the
  quiz will ask about, and Start disabled while the list is empty.
- Josh then found too much empty space on the start screen and asked for big yellow SF Symbols: a
  hero symbol for the scope, its name, a line saying what the quiz asks, and three tiles. Ask Josh
  whether Conjugar's start screen, which already has a pulsing symbol and two pills, should follow.
- `source` went on all three quiz signals, not only `startQuiz`, so that three-question completions
  do not raise the completion rate of the full quiz.

**Done when** Test Me asks three questions about the page's verb in a sheet that closes onto the
page, a My Verbs quiz draws only those verbs, neither posts a score or shows the leaderboard, and
tests pin the scoped draw.

**How it differed:** _Not started._

## Phase 14: A Verb of the Day Worth Opening

**Ideas:** D5. **Ports:** Konjugieren Phase 14. **Depends on:** Phase 12 for the My Verbs part.
**Status:** Not started.

Draw the widget's daily verb, and every random verb (the Random Verb control, the `verb/random`
deeplink, `OpenRandomVerbIntent`), from the 1,000 most frequent verbs, favoring irregular verbs and
verbs that are not prefixed compounds, and from My Verbs once it has entries. Today the widget walks
the top 1,000 by `(days × 127) % 1000`, which favors nothing, and a random verb is drawn from all
4,811, so most are rare. The widget's choice must stay stable through the day. Define the frequency
bands once (`FrequencyBand`: top 100, 300, and 1,000), since the pedagogy plan's levels use them.
The quiz widget's question sampling belongs to the pedagogy plan (its Phase 23) and is out of scope.

**From Konjugieren:**

- Josh decided that My Verbs supplies one draw in three, and that "My Verbs" means what the filter
  shows (starred verbs, then the last 20 opened). Confirm both.
- A one-in-three chance each day left gaps of up to 19 days in ten simulated years, so the widget
  gave My Verbs every third day and took its verbs in turn, while a random verb on demand kept the
  chance.
- "Favoring" became a weight, 2 for strong or mixed and 2 for unprefixed, multiplied. Here the
  analog is 2 for irregular (`Conjugator.verbType`) and 2 for a verb that is not a prefixed
  compound of another verb (Phase 8's relation).
- Konjugieren's widget bundle covered ten days and was rewritten at each activation, so stability
  needed care. Conjugar writes one snapshot per date and skips the write when the date matches
  (`WidgetSnapshotWriter.refresh`), so check whether that already suffices once My Verbs can
  change during the day.
- A random verb opened is a recent verb, so it joins My Verbs and can return as a My Verbs draw.
- Konjugieren checked the written bundle against an independent Python reimplementation of the
  draw.

**Done when** the widget's verbs for the next ten days and a run of random verbs come from the band
or My Verbs with the agreed weights, the widget's verb holds through a day, and tests pin the draw.

**How it differed:** _Not started._

## Phase 15: The Review Card

**Ideas:** D4. **Ports:** Konjugieren Phase 15. **Depends on:** Phases 9 (the key conjugations)
and 12. **Status:** Not started.

When the app opens, one card above the verb list offers a verb looked up some days earlier, with its
key conjugations hidden until tapped. One tap reveals them; one dismisses the card. This needs a
simple due date per verb in the learner's record.

**Build the schedule for the pedagogy plan, which will absorb it.** In Konjugieren, the pedagogy
plan's Phase 11 later folded the card's per-verb schedule into the quiz's practice record, so that
the card and the quiz share one schedule, and in doing so Josh restricted the card to strong and
mixed verbs, because a weak verb's conjugations are patterns shared by every weak verb and its
lookup had nothing of its own to schedule. Conjugar's regular verbs are the same case:
"hablo · hablé · hablaré · hablado" teaches nothing a learner of one regular -ar verb lacks.
**The card offers irregular verbs only** (Josh, 2026-11-22), from the start, which spares the
pedagogy plan a migration: a lookup of a regular verb schedules nothing. Put the schedule in
`Shared/` as a type the practice record can generalize (a box, a due date, and operations for a
lookup, a reveal, and a dismissal), not as fields scattered over the learner record.

**From Konjugieren:**

- Josh's rules: dismissing before revealing is no review, so the verb keeps its box and returns the
  next day; a later lookup by any route but the card sends the verb back to the first box; a card
  may appear at each launch and each return from the background. The ladder is 1, 3, 7, 14, and 30
  days, the last repeating, and due dates fall at the start of a day.
- The card chosen is the longest overdue, ties by infinitive, chosen once per opening so a reveal
  does not swap it.
- The card shows "Looked up 3 days ago", the infinitive, the gloss, and the key conjugations under a
  redacted placeholder with "Recall its conjugations, then tap to check." After the reveal a second
  tap opens the page (source `reviewCard`), which is added beyond the phase text and worked well.
  The card hides while a search, the recents, or My Verbs shows, and on iPad stops at 560 points.
- Josh added a **Suppress Review Card** setting after reading the summary, Off by default, under the
  search settings. Offer it here from the start.
- Seed the record for testing through `xcrun simctl spawn <udid> defaults write
  <container>/Library/Preferences/<group>`; a plist written straight into the App Group container
  does not reach `cfprefsd`, which keeps its cache.
- Signals: `viewReviewCard` once per card shown and `tapRevealReviewCard` once per reveal, with no
  parameters.

**Done when** a seeded overdue verb appears as a card, reveal and dismissal move its schedule as
decided, a later lookup resets it, the setting hides it, and tests pin the schedule.

**How it differed:** _Not started._

## Phase 16: Collections

**Ideas:** D6. **Ports:** Konjugieren Phase 16. **Depends on:** Phases 10 (the grammar), 12, and 13.
**Status:** Not started.

Fixed lists as places to go. A list shows how many of its verbs have been opened, can be shared as a
link, and can start a quiz on itself. Konjugieren's lists were the 100 most frequent verbs, the modal
verbs, the verbs that take sein, and each ablaut group, at the top of the Families tab, with each
ablaut group's bar inside the Ablaut page.

The Spanish counterparts, for Josh to choose from:

- The 100 most frequent verbs.
- Verbs with an irregular future and conditional (tener, poner, salir, hacer, decir, and the rest of
  `VerbFamilies.irregularRaizFuturaVerbs`, with or without their compounds).
- Verbs with a strong preterite (tuve, estuve, pude, puse, supe, quise, vine, dije, traje, conduje).
- The -go verbs (tengo, pongo, salgo, hago, digo, vengo, traigo, caigo, oigo, valgo).
- Verbs with an irregular participle (abierto, escrito, hecho, roto, visto, vuelto).
- **Each model**, in the role Konjugieren's ablaut groups played: a bar on every model's page in the
  Models tab ("3 of 70 looked up", a progress bar, Quiz, and Share). Stem-changing verbs (e to ie,
  o to ue, e to i) are models already, so they come with this.

**Collections are derived from the engine** (Josh, 2026-11-22), within a band where a list needs
one (every verb in the top 1,000 whose pretérito is irregular, say). `VerbFamilies` already holds
hand-made lists for several of these, written for the quiz; keep them as a test that each
derivation finds their verbs. The pedagogy plan's Phase 5 draws the quiz the same way, so build the
derivation where both can use it.

**Propose to Josh** where collections live (the top of the Models tab is the analog) and which of
the lists above to offer, before building.

**From Konjugieren:**

- A collection is keyed (`top100`, `modals`, `ablaut-<exemplar>` there; `model-<class>` would suit
  here, with care for the class numbers' hyphens, which already bit the screenshot driver's
  identifiers), shared as `conjugar://list/<key>` together with the App Store link.
- Progress counts verbs with a last open, shown as "3 of 100 looked up" with a check on each row
  looked up. A star alone does not count, and Clear resets every collection's progress.
- The quiz was a full-length unranked scope in the same sheet as Test Me (`QuizSheet`, moved out of
  the verb page), titled with the collection's name.
- A route reserved for a collection's quiz (`quiz/start?list=<key>`) was not built, since a shared
  link opens the collection, where Quiz is one tap.
- On iPad the share sheet anchors to the bar's own Share button, which needed an anchor rectangle
  because the button is in the page, not the navigation bar.
- Signals: `viewCollection` (`collection`, `source`), `tapShareCollection` (`collection`), and
  `collection` on `startQuiz`.

**Done when** the chosen collections show progress, share, and quiz, a shared link opens the
collection, every model page has its bar, and tests pin membership and keys.

**How it differed:** _Not started._

## Closing

- Run the full suite, and read the count.
- Confirm that every idea in the Idea Index is built or recorded as cut, and that
  `docs/privacy_policy_pending.md` stages a line for every signal and parameter added: diff
  `Analytics/Analytics.swift` against the commit before Phase 0 and read every call site.
- Bring the pedagogy plan's **What the Browse Plan Leaves for This One** up to date with what
  actually landed, phase by phase, in the manner of Konjugieren's "built on `main`" lines, and say
  there which of its expectations did not hold.
- Write a short list, at the end of this plan, of anything Conjugar did differently that Konjugieren
  or Conjuguer could adopt.
- Mark this plan finished in its Status section.

**How it differed:** _Not started._

