# Task: Add a Models tab (browse the engine's verb models, Conjuguer-style)

You are starting a fresh session on the **Conjugar modernization project** (see
`CLAUDE.md`). Add a **Models** tab to Conjugar, modeled on the Models tab of Josh's
French app **Conjuguer** (`/Users/josh/Desktop/workspace/Conjuguer` — SwiftUI; copy the
*UX*, not the SwiftUI code). The tab lists every verb model in the engine's
`ModelCatalog`; tapping a model opens a detail screen showing the model's exemplar,
class number, and the verbs that conjugate with it.

**Tab position:** immediately to the **right of Browse** — the new tab order is
**Browse, Models, Quiz, Info, Settings** (insert at index 1 of
`MainTabBarVC.viewControllers`).

## Read these Conjuguer files first (the UX to reproduce)

- `Conjuguer/Views/ModelBrowseView.swift` — the list: segmented sort control
  (Irregularity / Alphabetical / Identifier), rows showing exemplar (+ class-id
  decorator in Identifier sort) and an irregularity-percent badge, search field.
- `Conjuguer/Views/ModelView.swift` — the detail: header (exemplar + id), endings,
  and a "Verbs using this model" section whose verbs deep-link to the verb screen.
- `Conjuguer/Utils/ModelSort.swift` — the three sorts and their persistence.

Adapt, don't copy: Conjugar's equivalents are UIKit, and Conjugar's models are
feature stacks resolved by book class number, not Conjuguer's XML models.

## Ground rules

- **Stay in UIKit.** Programmatic views (`*VC` + `*UIV` + `*Cell`, `Layout.swift`
  constants, `@UsesAutoLayout`, `Colors`/`Fonts`). The SwiftUI conversion is a later,
  separate step. Match `BrowseVerbsVC` / `BrowseVerbsUIV` (in
  `UIViews/BrowseVerbsView.swift`) / `VerbCell` file-for-file as the pattern.
- Follow the **World DI** pattern (`Current.settings`, `Current.analytics`, …) and the
  conventions in `CLAUDE.md`.
- Localize everything new in **both** `Base.lproj/Localizable.strings` and
  `es.lproj/Localizable.strings`, with accessors added to
  `Supporting/Localizations.swift` (tab title "Models" / "Modelos", sort names,
  detail-screen labels).
- Commit to the **migration** branch. Add a `docs/blog_notes.md` entry when done.
- Build/test commands and the `-only-testing:` format are in `CLAUDE.md`. Use `/run`
  (the `run-in-simulator` skill) to eyeball the new tab.

---

## Part A — Data layer: the model list

### A1. Expose the catalog's rows

`ModelCatalog`'s `byClassNumber` / `exemplarByClassNumber` maps are `private`; only
`model(forClass:)`, `exemplar(forClass:)`, and `classNumbers` (an unordered `Set`) are
public. Add a public accessor that yields every **displayable model row** — one per
class number, carrying at least `(classNumber, exemplar)`.

**Alias classes (decided: fold them).** `29-2`, `30-1`, `31-1`, and `32-1`
(satisfacer / suponer / obtener / convenir) alias their parents' models and exemplars
(29 hacer / 30 poner / 31 tener / 32 venir) — see the comments in
`ModelCatalog.swift`. Showing them as separate rows would duplicate "hacer",
"poner", … in the list. **Do not** give them rows; instead fold their verbs into the
parent row's verb list/count. That yields **102 rows** (106 class numbers − 4
aliases). Assert the 102 in a test so a future catalog edit can't silently change it.

### A2. Verbs per model (reverse map)

Build the reverse index once from `VerbMap.shared.entries`: for each entry, every
element of `classNumbers` (homonyms carry two) contributes the infinitive to that
class's verb list — with the four alias classes redirected to their parents per A1.
Sort each list alphabetically with the Spanish locale (`VerbSort.spanish`). Every one
of the 4,811 verbs must land in some row's list; test that the counts sum to the
number of (verb, sense) pairs.

### A3. Irregularity percent

Conjuguer's signature Models-tab affordance is the **irregularity badge** (percent of
slots that deviate from the regular conjugation) and the default
sort-by-irregularity. Conjugar has no stored score, but it is computable: for a row's
exemplar, conjugate every simple-tense slot twice — once normally and once with an
explicit feature-less model — and count differing slots:

```swift
Conjugator.conjugate(infinitive: exemplar, tense: slot)                                  // the model's form
Conjugator.conjugate(infinitive: exemplar, tense: slot, model: VerbModel(base: base))    // the regular baseline
```

(`TenseBridge.regularForm` already uses exactly this `model:` override — mirror it.)
The slot set: all `EngineTense` person-bearing cases across the seven
`EnginePersonNumber`s, plus `participioPasado` and `gerundio`; skip slots where either
side fails (defectives return errors for missing slots — a failed *model-side* slot on
a defective is itself a deviation only if the regular side succeeds; simplest honest
rule: count a slot as irregular when the two results differ, treating error as a
distinct value). Percent = differing ÷ compared, rounded to an `Int`, computed once at
list construction (102 exemplars × ~100 slots is fast, but do it lazily/off the main
path if `loadView` feels sluggish). Class "1"/"2"/"3" must come out **0%**; `ser`
should be the max or near it. Pin a few known values in tests (0 for cantar; > 0 for
pensar; large for ser/ir).

Wrap A1–A3 in a small value type + builder — e.g. `ModelInfo` (`classNumber`,
`exemplar`, `verbs`, `irregularityPercent`) with a `ModelInfo.all` built once — in
`Models/ModelInfo.swift`.

### A4. `ModelSort`

Mirror `VerbSort.swift`: a `String`-raw-value `CaseIterable` enum with the three
Conjuguer sorts and localized display names:

- **`.irregularity`** (default, as in Conjuguer): descending percent; ties broken
  alphabetically by exemplar (Spanish locale).
- **`.alphabetical`**: exemplar, Spanish locale.
- **`.classNumber`** (Conjuguer's "Identifier"): **book order**, which is *not*
  string order ("2" < "10", "4A-2" < "4B", "6B-4" < "6C"). Parse the class number
  into (leading integer, letter suffix, sub-number) and compare component-wise;
  Conjuguer dodged this with a stored `position` — Conjugar must sort properly. Test
  the comparator against a hand-ordered sample including "1", "1-10" vs "1-2", "4A"
  vs "4B-1", "9-2" vs "10".

Persist the selection as `Settings.modelSort` exactly the way `verbSort` is persisted
(GetterSetter-backed, `didSet` guard, default `.irregularity`, read in `init`).

---

## Part B — The Models tab (list screen)

New files, matching the Browse Verbs trio:

- `Controllers/BrowseModelsVC.swift` — clone `BrowseVerbsVC`'s shape: pre-sorted
  arrays per sort (`modelsBySort`), `currentSort` from the segmented control,
  `Current.settings.modelSort` persistence on `.valueChanged`,
  `recordVisitation(viewController:)` in `viewWillAppear`, row tap pushes the detail
  VC (Part C) and hides the view during the push like `BrowseVerbsVC` does.
- `UIViews/BrowseModelsView.swift` (`BrowseModelsUIV`) — clone `BrowseVerbsUIV`: a
  3-segment sort control above a table, same `Layout`/`Colors` styling, same
  `reloadTableData()` scroll-to-top behavior.
- `UIViews/ModelCell.swift` — mirror `VerbCell`'s three-label layout:
  **exemplar** (large, yellow, Spanish accessibility label), **class number** shown
  as e.g. `4B-1` (small, blue — always visible, unlike Conjuguer's
  Identifier-sort-only decorator; it doubles as the "model number" learners see on
  the Verb screen), and a right-aligned **`N%`** irregularity label in place of
  `VerbCell`'s `#rank`. Optionally include the verb count (e.g. `12 verbs`) if it
  fits cleanly; skip it rather than crowd the cell.

Wire the tab in `MainTabBarVC`: a `UINavigationController(rootViewController:
BrowseModelsVC())` inserted **between** `browseVerbsNavC` and `quizNavC`. Title
`Localizations.BrowseModels.localizedTitle`. **Icon:** the existing tabs use asset-
catalog imagesets (`Browse.imageset` etc.); there is no Models art. Use the SF Symbol
`key.fill` (`UIImage(systemName: "key.fill")`) — the same icon Conjuguer's Models tab
uses — rather than blocking on custom art; Josh can swap in a PNG later.

**Search is out of scope** (Browse Verbs has none either; adding it to both is a
possible follow-up — mention it in blog notes, don't build it).

---

## Part C — Model detail screen

New `Controllers/ModelVC.swift` + `UIViews/ModelUIV.swift`, the UIKit reduction of
Conjuguer's `ModelView`. Conjugar's models have no prose description, endings tables,
or stem-alteration metadata to render (those are Conjuguer XML concepts), so the
detail screen is simpler:

1. **Header** — exemplar as the nav title (tappable to hear via `Utterer.utter`, like
   `VerbVC`'s title), plus a line with the class number and the irregularity percent,
   and the exemplar's gloss from `VerbMap.shared.entry(for:)`.
2. **Verbs using this model** — a table of the row's `verbs` (count in a section
   header or label: localized "%d verbs use this model"). Each row is the infinitive
   (reuse `VerbCell` with gloss + rank if convenient, or a minimal cell); tapping
   pushes `VerbVC(verb:)` — the UIKit equivalent of Conjuguer's deep links. For
   big classes (class "1" has thousands of verbs) a plain `UITableView` handles it;
   just make sure the verb list is the *scrolling* element, not a stack in a scroll
   view.
3. `recordVisitation(viewController: "\(ModelVC.self)")` in `viewWillAppear`.

Note the existing affordance this completes: `VerbVC` already shows "irregular, like
*conocer*" via `ModelCatalog.exemplar(forClass:)`. The Models tab is the reverse
navigation — from a model to all its verbs. (Making that `VerbVC` label itself tap
through to `ModelVC` is a nice bonus if cheap; otherwise skip.)

---

## Tests & verification

Add to `ConjugarTests` (match each suite's neighborhood — new-engine model tests in
Swift Testing style, VC tests in XCTest style, per `CLAUDE.md`):

- **`ModelInfoTests`** (Swift Testing, `Models/`): 102 rows; alias folding
  (satisfacer's row is hacer's, and "satisfacer" appears in hacer's verb list); verb
  lists cover all entries; pinned irregularity percents (cantar 0, ser high).
- **`ModelSortTests`**: the three comparators, especially the book-order
  class-number comparator edge cases listed in A4.
- **`BrowseModelsVCTests`** (XCTest, `Controllers/`): clone `BrowseVerbsVCTests` —
  row count, cell configuration, sort toggle persists to `Current.settings`,
  selection pushes `ModelVC`.
- **`ModelVCTests`**: loads for a small class (e.g. "31" tener) and a huge one
  ("1"); verb tap pushes `VerbVC`.
- Update **`MainTabBarVCTests`** for the new tab count and order (Models at
  index 1).
- Full suite green (`-parallel-testing-enabled NO test`), `swiftlint` clean.
- `/run` the app: Models tab appears right of Browse; the three sorts reorder
  correctly; tapping *conocer (7A)* shows its verbs including *reconocer*; tapping
  *reconocer* lands on the normal Verb screen.

## Deliverables

- Models tab live at index 1 with sortable model list and detail screens.
- `ModelInfo` / `ModelSort` data layer with `Settings.modelSort` persistence.
- New tests passing; full suite green.
- `docs/blog_notes.md` entry (mention the alias-folding decision, the computed
  irregularity score, and the book-order comparator).

## Decisions already made (baked in above — don't re-ask)

1. **Tab order:** Browse, **Models**, Quiz, Info, Settings.
2. **Alias classes 29-2/30-1/31-1/32-1:** folded into their parent rows; 102 rows.
3. **Sorts:** Irregularity (default) / Alphabetical / Class number, persisted as
   `Settings.modelSort`.
4. **Irregularity percent:** computed by diffing against the feature-less regular
   model (A3). *Fallback if this turns into a rabbit hole:* ship with Alphabetical +
   Class number only, no badge, and note the deferral in blog notes — don't let the
   score block the tab.
5. **Tab icon:** SF Symbol `key.fill` for now (custom PNG later).
6. **Search:** out of scope.
