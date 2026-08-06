# Add search bars to the Browse Verbs and Models tabs (SwiftUI)

Add a `.searchable` search bar to Conjugar's two list screens — **Browse Verbs**
(`Conjugar/Views/VerbBrowseView.swift`) and **Models** (`Conjugar/Views/ModelBrowseView.swift`)
— so the user can filter the ~4,811 verbs / 102 models by typing. This is the clean
follow-up that the SwiftUI migration (Step 4) deliberately deferred; the migration's audit
already calls for it (`docs/conjugar-ui-issues.md` §6 and §11 list a search **empty-state**,
and the Part-B Browse rebuild note flagged the missing search bar as "a clean follow-up").

## Where things stand (read first)

The UIKit→SwiftUI migration is **done** — both browse screens are native SwiftUI and were
built to mirror Conjugar's French sibling **Conjuguer**, so the port target is close. The
one abstraction Conjuguer extracted for exactly this task is
`/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/Views/BrowseSearch.swift` — a tiny
generic `enum BrowseSearch` with a single `results(in:query:playSoundIfEmpty:matches:)`
function that both of its browse screens share. **Port and adapt it** rather than writing
two bespoke filters.

Current shape of each Conjugar screen (both already exist and are green):

- **`VerbBrowseView`** — `NavigationStack(path:)` → `VStack(spacing: 0)` of
  `ScrollViewReader { ScrollView { count-banner + LazyVStack(VerbRow) } }` then a `Divider`
  and a bottom **segmented `Picker`** for `VerbSort` (Frequency / Alphabetical). Both sorts
  are precomputed once in `static let verbsBySort`; `private var verbs: [VerbMapEntry]`
  returns the current sort. Rows navigate via `onTapGesture { navigationPath.append(entry.infinitive) }`
  → `.navigationDestination(for: String.self) { VerbView(verb:) }`. The count banner reads
  `L.BrowseVerbs.verbCount(count: verbs.count)`. The shared row visual is
  `struct VerbRowLabel` (also reused by `ModelView`).
- **`ModelBrowseView`** — same shape with `ModelSort` (Irregularity / Alphabetical /
  Number), `static let modelsBySort`, `ModelRowLabel`, and **two** destinations
  (`ModelInfo.self` → `ModelView`, `String.self` → `VerbView`). Count banner:
  `L.BrowseModels.modelCount(count:)`.

Relevant model facts:
- `VerbMapEntry` (nonisolated struct): `.infinitive: String`, `.gloss: String`
  (`glosses[0]`), `.frequencyRank: Int?`.
- `ModelInfo` (Identifiable/Hashable): `.exemplar: String`, `.classNumber: String`,
  `.irregularityPercent: Int`.

## What to build

### 1. Port `BrowseSearch` (the shared filter)

Create `Conjugar/Utils/BrowseSearch.swift`, adapting Conjuguer's enum. Keep the generic
signature so both screens share it:

```swift
enum BrowseSearch {
  static func results<Item>(
    in items: [Item],
    query: String,
    playSoundIfEmpty: Bool,
    matches: (Item, String) -> Bool
  ) -> [Item] { … }
}
```

Behavior: empty/whitespace-only query → return `items` unchanged; otherwise
`items.filter { matches($0, query) }`, and if the result is empty **and**
`playSoundIfEmpty`, play the sad-trombone once.

**Adapt to Conjugar's APIs** (they differ from Conjuguer's):
- Sound is **static**: `SoundPlayer.play(.sadTrombone)` — Conjugar has no `Current.soundPlayer`
  and no `.randomSadTrombone` case (its `Sound` enum has `sadTrombone`).
- `BrowseSearch` is pure value computation, but it reads `SoundPlayer` (a `@MainActor` UI
  helper), so leave it **`@MainActor`** (the default) — both call sites are `@MainActor`
  views. Add an explicit `import Foundation` (MEMBER_IMPORT_VISIBILITY).

### 2. Wire `.searchable` into each screen

For each screen:
- Add `@State private var searchText = ""`.
- Add a `filteredVerbs` / `filteredModels` computed property that runs the **current sort's**
  array through `BrowseSearch.results(in:query:playSoundIfEmpty:matches:)`.
  - **Verb match:** infinitive matches, and (per the scope decision below) optionally the
    gloss. Use **case- and diacritic-insensitive** matching so `esta` finds `está` and
    `Ser`/`ser` both hit: `text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil`.
  - **Model match:** `exemplar` matches, or `classNumber` matches (so typing `28` or `4B`
    finds a model by its book number).
- Drive the `ForEach` and the **count banner** off the filtered array (the banner should
  read "12 verbs" while filtering).
- Attach `.searchable(text: $searchText, prompt: …)` to the `NavigationStack`'s content
  (inside the stack). Verify it coexists with the bottom sort `Picker` and the
  `ScrollView`/`LazyVStack` — the search field lives in the nav bar, the sort control stays
  pinned at the bottom.
- **Empty-state** (audit K8 / §6 / §11): when `!searchText.isEmpty && filtered.isEmpty`,
  render a `ContentUnavailableView(L.…searchNoResults, systemImage: "magnifyingglass")`
  in place of the `LazyVStack`. (The sad-trombone from `BrowseSearch` plays once when the
  filter empties.)
- Keep sort + search composable (filter the already-sorted array) and keep
  `.selectionFeedback`/animation on the sort control unchanged.

### 3. A search-scope decision (verbs only)

Conjuguer offers a **search scope** (infinitive-only vs. infinitive + translation) persisted
in `Settings.searchScope`, surfaced via `.searchScopes`. Decide one:
- **(a, simplest — recommended):** always match infinitive **+** gloss. No new setting, no
  scope UI. Most useful default (a user can find "have" → haber/tener).
- **(b, Conjuguer-parity):** add a `SearchScope` enum + `Settings.searchScope`
  (GetterSetter-backed, like `verbSort`), a `.searchScopes { … }` control, and match
  infinitive-only or infinitive+gloss accordingly.

If unsure, do **(a)** and note (b) as a further follow-up. Models don't need a scope
(exemplar + class number is the whole surface).

### 4. Localization

Add prompt + empty-state strings (both **en** and **es**) — follow the `.xcstrings`
foot-guns in `CLAUDE.md` (edit values with ASCII quotes via `python3`, curly-quote/plain
values are Edit-safe, always `json.load`-validate after):
- `L.BrowseVerbs.searchPrompt` — e.g. "Search verbs" / "Buscar verbos".
- `L.BrowseModels.searchPrompt` — "Search models" / "Buscar modelos".
- `L.BrowseVerbs.searchNoResults` / `L.BrowseModels.searchNoResults` — e.g.
  "No verbs found" / "No se encontraron verbos" (and the model analog). A single shared
  `L.Search.noResults` is fine too — your call.

### 5. Tests (Swift Testing — see CLAUDE.md, never XCTest)

`BrowseSearch` is pure logic, so it's the testable seam. Add
`ConjugarTests/Utils/BrowseSearchTests.swift` (`@Suite`, `@MainActor` since it touches the
`@MainActor` enum; `import Foundation`/`import Testing`):
- empty query returns the input unchanged (identity, order preserved);
- a matching query returns only the matches;
- a no-match query returns `[]` (call with `playSoundIfEmpty: false` so tests stay silent);
- diacritic/case-insensitivity of your `matches` predicate (e.g. `está` found by `esta`),
  if you factor the predicate out where it's reachable.

Optionally add a light `VerbBrowse`/`ModelBrowse` filter test if you extract the
`filteredVerbs`/`filteredModels` logic into a testable static — not required if the view
just composes `BrowseSearch` + a trivial predicate.

## Verification (per `CLAUDE.md` + the migration's bar)

- **Build clean; SwiftLint clean** (`swiftlint` → 0 violations).
- **Full test suite green** — `xcodebuild -project Conjugar.xcodeproj -scheme Conjugar
  -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test`
  should stay **TEST SUCCEEDED** (it is today).
- **Drive it in the simulator** with the **`run-in-simulator`** skill, in **both light and
  dark**: on Browse Verbs, type `ten` → list narrows (tener…), the count banner updates,
  clearing restores the full list; type gibberish → the `ContentUnavailableView` shows and
  the sad-trombone plays once; tapping a filtered row still pushes `VerbView`. Repeat on
  Models (`28` or `hacer`). Confirm the bottom sort control still works while a query is
  active.
- Add a dated note to `docs/blog_notes.md` (per `CLAUDE.md`).

## Gotchas

- **Write tests in Swift Testing**, `@MainActor` on suites touching MainActor types.
- **`import Foundation`** explicitly wherever you rely on its members (MEMBER_IMPORT_VISIBILITY).
- **`.xcstrings` editing** — Python for ASCII-quote values; `json.load`-validate; Grep is
  useless inside the one-line-per-value JSON (find the line number, then Read at that offset).
- `Conjugar/Supporting/` and `Conjugar/Utils/`, `Conjugar/Views/`, `ConjugarTests/Utils/`
  are **`PBXFileSystemSynchronizedRootGroup`s**, so new files auto-join the target — no
  `project.pbxproj` edit needed.
- Keep the change **two small commits** (shared `BrowseSearch` + tests, then the two
  screens), on the `migration` branch.
