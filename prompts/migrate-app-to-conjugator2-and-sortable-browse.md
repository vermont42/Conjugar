# Task: Migrate the app to Conjugator2 + make Browse Verbs an all-verbs, sortable list

You are starting a fresh session on the **Conjugar modernization project** (see
`CLAUDE.md`). Two related pieces of work, both in the **UIKit** app (Josh will convert
Conjugar to SwiftUI as a *later, separate* step — **do not** SwiftUI-ify anything here):

1. **Migrate the running app from the legacy `Conjugator` engine to the new
   `Conjugator2` engine.** The new engine is complete and tested (4,811 verbs, ~350
   passing tests) but **nothing in the app/UI uses it yet** — the UI still conjugates
   through `Conjugator.shared`, which parses the 214-verb `verbs.xml`.
2. **Rebuild Browse Verbs as a single all-verbs list, sortable by Frequency and
   Alphabetical**, modeled on the behavior of Josh's French app **Conjuguer**
   (`/Users/josh/Desktop/workspace/Conjuguer`, which is SwiftUI — copy the *UX and
   sort logic*, not the SwiftUI code).

Do these in the order below (Part A then Part B): Browse Verbs' new data source *is*
the new engine's verb map, so migrating first makes Part B fall out naturally.

## Ground rules

- **Stay in UIKit.** Conjugar's views are programmatic UIKit (`*VC` controllers,
  `*UIV` views, `Layout.swift` constants, `@UsesAutoLayout`). Match that. No SwiftUI.
- **Do not delete the legacy `Conjugator` / `verbs.xml` yet.** Keep them compiling
  until you've confirmed the new engine reaches display parity for the verbs the app
  shows. Removing the legacy engine is a *follow-up* once Josh is happy. (Note the
  legacy `Conjugator.regularVerbs`/`irregularVerbs`/`allVerbs` derive the browse list
  from `verbs.xml`; after Part B nothing should call them, but leave them in place.)
- Follow the **World DI** pattern (`Current.settings`, etc.) and the Fowler
  test-double naming convention documented in `CLAUDE.md`.
- Commit to the **migration** branch. Add a `docs/blog_notes.md` entry when done.
- Build/test (simulator `iPhone 17`, parallel testing off):
  ```bash
  xcodebuild -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,name=iPhone 17' build
  xcodebuild -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test
  ```
  See `CLAUDE.md` for the `-only-testing:` format (the suite is mixed XCTest / Swift
  Testing). Use `/run` to launch the app in the simulator and eyeball the two screens.

---

## Part A — Migrate the app to Conjugator2

### The two engines' APIs

**Legacy (being replaced):** `Conjugator.shared.conjugate(infinitive:tense:personNumber:)
-> Result<String, ConjugatorError>`, using the legacy `Tense` (raw-value string enum,
`Tense.swift`) and `PersonNumber` enums. Also exposes `allVerbs`, `regularVerbs`,
`irregularVerbs`, `isDefective(infinitive:)`, `verbType(infinitive:)`,
`parent(infinitive:)`, and pseudo-"tenses" `.translation`, `.raízFutura`, `.participio`.

**New:** `Conjugator2` is an **enum with static methods**:
```swift
Conjugator2.conjugate(infinitive: String, tense: Tense2) -> Result<String, Conjugator2Error>
Conjugator2.conjugateAll(infinitive: String, tense: Tense2) -> Result<[String], Conjugator2Error>
```
`Tense2` (`Tense2.swift`) **bundles the person/number into the tense case** — e.g.
`.presenteDeIndicativo(PersonNumber2.firstSingular)` — and the person-less cases are
`.participioPasado` and `.gerundio`. The resolver looks the verb's model up from
`VerbMap2` automatically, so you just pass infinitive + `Tense2`. `PersonNumber2`
(`PersonNumber2.swift`) has the seven persons **including `secondSingularVos`** (voseo
is supported — `ModelCatalog2` carries explicit `ves`/`sos` forms).

### Every legacy call site you must migrate (the full surface)

```
Conjugar/Models/ConjugationDataSource.swift : 31, 40, 48, 66   (per-tense conjugation grid)
Conjugar/Models/Quiz.swift                  : 300              (quiz correct-answer)
Conjugar/Controllers/VerbVC.swift           : 40, 47, 54, 61, 68, 74, 83
Conjugar/Controllers/QuizVC.swift           : 44, 126          (verb translation)
Conjugar/Controllers/BrowseVerbsVC.swift    : 43, 44, 45       (verb lists — replaced in Part B)
```
`grep -rn 'Conjugator\.shared' Conjugar --include=*.swift` is your checklist; when it
returns nothing but the legacy definition, Part A's swap is complete.

### ⚠️ The central risk — tense coverage gap (decided: compose in app)

`Tense2` only models **simple** tenses plus participle and gerundio:
presente/pretérito/imperfecto/futuro/condicional (indicativo), presente + imperfecto
(-ra / -se) de subjuntivo, imperativo afirmativo, participio pasado, gerundio.

The legacy `Tense` (and therefore `ConjugationDataSource` / `Quiz`) **also** renders,
via `Tense.conjugatedTenses`:
- **Compound/perfect tenses** — perfecto de indicativo, pretérito anterior,
  pluscuamperfecto de indicativo, futuro perfecto, condicional compuesto, perfecto de
  subjuntivo, pluscuamperfecto de subjuntivo (I/II). Conjugator2 does **not** produce
  these.
- **futuro de subjuntivo** (I/II) and **imperativo negativo** — also absent from `Tense2`.

A naïve swap would silently drop rows from the conjugation table. **Josh has decided:
compose the compound tenses in the app** — keep the full displayed tense set, do not
shrink it, and do not extend the engine's tense model.

The compounds are mechanical: `auxiliary(haber) in tense T + participioPasado`.
Conjugate `haber` via `Conjugator2.conjugate(infinitive: "haber", tense: <simple tense>)`
and append the invariant `participioPasado`. E.g. *perfecto de indicativo* = presente de
indicativo of *haber* + participle; *pluscuamperfecto* = imperfecto of *haber* +
participle; *futuro perfecto* = futuro of *haber* + participle; the subjunctive perfects
use the subjunctive of *haber*. Imperativo negativo = "no" + presente de subjuntivo. Put
this in a small `CompoundTense` helper — well unit-tested against the legacy engine's
output for a sample of verbs — so `ConjugationDataSource` stays clean.

Also build a small **bridge** from the legacy `Tense` + `PersonNumber` the UI is
structured around to `Tense2` cases (or refactor `ConjugationRow`/`ConjugationDataSource`
to speak `Tense2` directly — your call; the bridge is lower-risk). `Quiz.swift:300`
and `QuizVC` need the same bridge.

### VerbVC's non-conjugation affordances (map or fill the gaps)

`VerbVC.loadView()` uses several legacy-only accessors. New-engine equivalents:

| Legacy call | Replacement |
|---|---|
| `conjugate(.translation)` | `VerbMap2.shared.entry(for: verb)?.gloss` |
| `conjugate(.gerundio)` | `Conjugator2.conjugate(infinitive:, tense: .gerundio)` |
| `conjugate(.participio)` | `.participioPasado` |
| `conjugate(.raízFutura)` | **No public accessor.** The future root lives in `RegularRoot2`/`FutureFeature2`. Add a small public accessor on `Conjugator2` (preferred) or derive it; don't fake it. |
| `isDefective(infinitive:)` | **No public accessor.** Defectiveness is known to the model/catalog (`Feature2` defective slots). Add an accessor or derive from `VerbMap2`/`ModelCatalog2`. |
| `verbType(infinitive:)` → regular AR/ER/IR vs irregular | Derive from the verb's **class number** (`VerbMap2` `classNumber`) + infinitive ending. Define the mapping (e.g. class 1 = regular -ar, 2 = regular -er, 3 = regular -ir; everything else irregular — **verify** these class numbers against `ModelCatalog2` before relying on them). |
| `parent(infinitive:)` | **No equivalent** — "parent verb" is a legacy modeling concept; the new engine uses class numbers, not parent inheritance. **Decided:** replace the `parentOrType` label with a **class/model-based label** — show the verb's model/class (from `VerbMap2` `classNumber` → its `ModelCatalog2` model, e.g. the representative/model verb or class name) instead of a parent verb. Keep it human-readable; this is a deliberate UX semantics change from "parent X" to "model/class". |

Keep VerbVC's tap-to-hear-Spanish behavior and attributed-string formatting
(`.conjugatedString`) intact.

### Part A acceptance

- `grep -rn 'Conjugator\.shared' Conjugar --include=*.swift` shows only the legacy
  class's own definition — no app/UI call sites.
- App builds; full test suite green (`-parallel-testing-enabled NO test`).
- **Parity spot-check:** for a spread of verbs (a regular -ar/-er/-ir, a stem-changer
  like `pensar`, an orthographic like `pagar`, an irregular like `tener`/`ir`, a
  reflexive-capable one, and a compound-tense check on any), the Verb screen's grid
  matches the legacy engine's output. A quick way: keep both engines temporarily and
  assert equality in a throwaway test over `VerbMap2` ∩ legacy verbs, then delete it.
- Quiz still produces correct answers.

---

## Part B — Browse Verbs: all verbs, sortable by Frequency / Alphabetical

### Current state

`BrowseVerbsVC` (`Controllers/`) + `BrowseVerbsUIV` (in `UIViews/BrowseVerbsView.swift`)
+ `VerbCell` (`UIViews/`). Today a 3-segment control (**irregular / regular / both**)
switches between `Conjugator.shared.irregularVerbs / regularVerbs / allVerbs` (≈214
verbs from `verbs.xml`). Tapping a row pushes `VerbVC(verb:)`.

### Target (mirror Conjuguer's `VerbBrowseView`)

Read these Conjuguer files for the exact behavior to reproduce (SwiftUI — adapt, don't
copy): `Views/VerbBrowseView.swift`, `Utils/BrowseStore.swift`, `Utils/VerbSort.swift`.

1. **Data source = the new engine's map.** List **all `VerbMap2.shared.entries`**
   (4,811 verbs), not the legacy lists. Each `VerbMapEntry2` gives `infinitive`,
   `gloss`, and `frequencyRank: Int?` (nil for verbs outside the top ~1000).
2. **Two sorts** (define a `VerbSort` enum, `.frequency` / `.alphabetical`,
   `CaseIterable`, with localized display names — mirror Conjuguer's `VerbSort`):
   - **Frequency:** ranked verbs first, ascending by `frequencyRank`; verbs with
     `nil` rank come **after**, alphabetized among themselves. (This is exactly
     Conjuguer's `VerbBrowse.makeStore` comparator — replicate its nil-handling.)
   - **Alphabetical:** locale-aware compare (use a Spanish locale; Conjuguer uses
     `String.compare(_:locale:)` — do the Spanish equivalent so ñ etc. sort correctly).
   Precompute both arrays once (like Conjuguer's `BrowseStore` holding `itemsBySort`);
   don't re-sort on every reload.
3. **Replace the 3-segment control** with a 2-segment Frequency/Alphabetical
   `UISegmentedControl`. Reloading on `.valueChanged` (the existing wiring) still
   applies — just swap which pre-sorted array `currentVerbs` returns.
4. **Persist the choice** in `Settings` (Conjuguer stores `settings.verbSort`). Follow
   how `Settings.swift` already persists `secondSingularBrowse` (GetterSetter-backed
   UserDefaults) and add a `verbSort`. Default to `.frequency` (that's Conjuguer's
   feel and the more useful default for learners).
5. **Cell content (decided).** `VerbCell` currently shows only the infinitive. Extend
   it to show **infinitive + `gloss` + `#<rank>`** (matches Conjuguer's row). Show the
   `#<rank>` only for verbs that have a `frequencyRank` (nil-rank verbs show no number).
   Keep it accessible (`setAccessibilityLabelInSpanish`) and keep the existing
   `Colors`/`Fonts`/`Layout` styling.
6. **Search (optional, nice-to-have).** Conjuguer has a `.searchable` field. A UIKit
   `UISearchController` filtering by infinitive would be a welcome parallel, but it's
   secondary to the sort requirement — only add it if time allows, and mention it.

### Part B acceptance

- Browse Verbs lists ~4,811 verbs (spot-check the count and that e.g. `ser` is #1 in
  Frequency sort and low-frequency verbs sink below the ranked block).
- Toggling the segmented control re-sorts instantly and resets scroll to top (the
  existing `reloadTableData()` already does `setContentOffset(.zero)`).
- Sort choice persists across launches.
- Tapping a verb still pushes a working `VerbVC` (now powered by Conjugator2).
- No call site references `Conjugator.shared.allVerbs/regularVerbs/irregularVerbs`.

---

## Tests & verification

- Run the full suite green. The new-engine suites (`Conjugator2Tests`, `VerbMap2Tests`,
  `Resolver2Tests`, Swift Testing) must stay green; legacy `ConjugatorTests` (XCTest)
  should also stay green as long as the legacy engine remains.
- Add tests for the **new** code: the compound-tense composition helper (assert against
  known-correct forms — you can generate expectations from the legacy engine for verbs
  both engines know), the `VerbSort` comparators (frequency nil-handling; Spanish
  alphabetical order), and any new `Conjugator2` accessors (raízFutura / isDefective /
  class→verbType).
- `/run` the app: verify the Verb screen renders a full conjugation table (compound
  tenses included) and Browse Verbs sorts both ways.

## Deliverables

- App fully on Conjugator2 (legacy engine dormant but still present).
- Browse Verbs = sortable all-verbs list.
- New tests passing; full suite green.
- `docs/blog_notes.md` entry describing the migration, the compound-tense decision, and
  the browse redesign.

## Decisions already made by Josh (baked into the sections above — no need to re-ask)

1. **Compound tenses:** **compose them in-app** (`haber` + participle) — keep the full
   tense set. See the tense-gap section.
2. **`parentOrType` label:** **replace with a class/model-based label** (show the verb's
   model/class, not a parent verb). See VerbVC affordances.
3. **Browse cell:** **infinitive + gloss + `#rank`** (Conjuguer-style). See Part B step 5.
4. **Legacy engine:** **leave** `Conjugator` + `verbs.xml` in place — retiring them is a
   separate later cleanup, not part of this task.
