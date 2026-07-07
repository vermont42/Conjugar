# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Conjugar is an iOS app for learning Spanish verb conjugations. It conjugates regular and irregular Spanish verbs in all tenses with quiz mode (3 difficulty levels), verb browsing, tense information, and Game Center integration.

**Developer:** Josh Adams (vermontcoder@gmail.com), who released the app in 2017.
**Target:** iOS 26+ (raised from 17 in July 2026 to match Konjugieren, ahead of the SwiftUI migration)
**Language:** Swift 6 language mode, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (see **Concurrency model** below)
**License:** GNU Affero General Public License

As of 2026, a project is underway to modernize and improve Conjugar. The engine migration is **done**: the app conjugates exclusively through the new `Conjugator` engine (4,811 verbs from `verbModelMap.xml`, all 16+ tenses — regular and irregular verbs, homonyms, defectives, prefixed compounds, with compound tenses composed in-app by `CompoundTense` and the UI's `DisplayTense`/`DisplayPersonNumber` vocabulary mapped by `TenseBridge`). Browse Verbs is an all-verbs list sortable by Frequency/Alphabetical. The legacy engine (the original `Conjugator`), `verbs.xml`, and their tests were **removed** in July 2026; the new engine's types then dropped their interim `2` suffixes (`Conjugator2` → `Conjugator`, etc.), so the plain names now always mean the new engine. The **UIKit-to-SwiftUI UI migration is also done** (July 2026): every screen is now a native SwiftUI view (`Views/`), the app shell is a `MainTabView` `TabView`, and no `UIViewController` subclass remains in the app target — see the Step-4 notes in `docs/blog_notes.md`. The modernization/improvement work lives in this folder, /Users/josh/Desktop/workspace/Conjugar.mig . Commits in this folder should be pushed to the migration branch. Eventually, the migration branch will be folded into Conjugar's master branch.

As you, Claude, complete chunks of work on the modernization/improvement project, please add a note to docs/blog_notes.md . Eventually, Josh will generate a blog post from this work.

## Build and Test Commands

This is an Xcode project (project `Conjugar.xcodeproj`, scheme `Conjugar`). Use the following commands:

```bash
# Build the app
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all tests (disable parallel testing to avoid simulator flakiness)
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test

# Run a single test suite
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test -only-testing:ConjugarTests/ConjugatorTests

# Run a single test method (Swift Testing — note the trailing, shell-escaped parentheses)
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test -only-testing:ConjugarTests/ConjugatorTests/oirPresent\(\)

# Lint
swiftlint
```

> **`-only-testing:` format — the suite is mixed.** The path is `Target/Suite/method`. Do **not** include filesystem subdirectories (`Models/`, `Utils/`). The engine suites (`ConjugatorTests`, `ConjugatorAccessorsTests`, `ConjugatorResolverTests`, `VerbMapTests`, `TenseBridgeTests`) the migrated service suites (`SettingsTests`, `GetterSetterRealTests`, `ReviewPrompterRealTests`, `GameCenterFakeTests`), and the SwiftUI-migration suites (`InfoTests`, `ConjugationTextTests`, `QuizTests`, `SettingsViewTests`) use **Swift Testing**, so a method name must end in `()` (e.g. `oirPresent()`, shell-escaped as `oirPresent\(\)`) — omitting it makes xcodebuild silently run zero tests. The remaining lower-level suites like `ConjugationCellTests` / `AnalyticsServiceTests` are still **XCTest**, whose method names take **no** parentheses (e.g. `testConjugationCell`). New tests should be Swift Testing — see **XCTest + MainActor: the isolated-deinit crash** below.

## Running the App in the Simulator

To launch and drive the built app (screenshots, taps, verifying UI behavior — not just tests), use the project skill **`run-in-simulator`** (`.claude/skills/run-in-simulator/SKILL.md`). It captures the verified recipe: resolving the built `.app`, pinning a booted-simulator UDID (several devices are named "iPhone 17"), `simctl` install/launch/screenshot, tapping with `idb` in points (screenshot pixels ÷ 3), and the pitfalls (launch-screen delay, `simctl spawn defaults write` not reaching the app's sandboxed UserDefaults). This skill was written as interim tooling; now that the SwiftUI conversion is complete, the `ios-build-verify` skill can supersede it, but `run-in-simulator` remains the verified, working recipe until that swap is made.

## Architecture

### Concurrency model (Swift 6 / strict concurrency)

The project builds under **Swift 6** with `SWIFT_STRICT_CONCURRENCY = complete`,
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`,
and `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` (adopted July 2026 to
match the sibling app Konjugieren, ahead of the SwiftUI migration). The settings are
placed like Konjugieren's: strict-concurrency at the **project** level; default-actor
isolation on the **app** target only; the rest on app + test. Consequences to work with:

- **Default isolation is `@MainActor`.** Any type with no explicit annotation is
  MainActor-isolated. UIKit VCs and the DI services (`World`, `Settings`, `Quiz`, the
  `…Real`/`…Fake`/`…Stub` service conformers) live here and want it.
- **The engine and its vocabulary are `nonisolated` + `Sendable`, on purpose.** The
  whole `Conjugator` engine — the `ConjugationFeature` types, `Slot`, `EngineTense`/
  `EnginePersonNumber`, `ModelCatalog`, `VerbModel`, `VerbMap`, `CompoundTense`,
  `TenseBridge`, `IrregularityMarker`, and the UI vocabulary `DisplayTense`/
  `DisplayPersonNumber` — is pure value-type computation, marked `nonisolated`
  throughout. `ConjugationFeature` is `: Sendable` (so `[any ConjugationFeature]` in a
  `VerbModel`, and `ModelCatalog`'s static exemplars, are Sendable); stored slot
  predicates are `@Sendable (EngineTense) -> Bool`; `VerbMap` is a load-once
  `@unchecked Sendable` cache. **When adding to the engine, keep new types
  `nonisolated`** so they compose with the rest and their Swift Testing suites stay
  parallel. MainActor UI calls into the nonisolated engine synchronously — always fine.
- **`MEMBER_IMPORT_VISIBILITY`** means transitive imports no longer leak members: a
  file using `String.replacingOccurrences`, `compare(_:options:…)`, etc. needs its own
  explicit `import Foundation`.
- **`Current` is explicitly `@MainActor`** (in `World.swift`) so the DI global's
  isolation is unambiguous to both the app and the test target.

### Dependency Injection via World Singleton

The app uses a DI container pattern through `World.swift`. All services are accessed via the global `Current` variable:

```swift
var Current = World.device  // Production
// or World.simulator, World.unitTest, World.uiTest
```

Services provided by World:
- `analytics: AnalyticsService` - no-op spy (AWS Pinpoint removed; TelemetryDeck planned)
- `gameCenter: GameCenter` - Game Center integration
- `reviewPrompter: ReviewPrompter` - App Store review prompting
- `settings: Settings` - User preferences (wraps UserDefaults)
- `communGetter: CommunGetter` - CloudKit-based messaging
- `locale: AnalyticsLocale` - language/region codes

### Protocol-Based Abstractions

All external services have protocol abstractions with production and test implementations, named in the Fowler test-double convention — `…Real` for the production conformer, `…Fake`/`…Stub`/`…Spy` for the double:
- `AnalyticsService` → `AnalyticsServiceSpy` (the only implementation, a spy; a TelemetryDeck-backed `AnalyticsServiceReal` is planned)
- `GameCenter` → `GameCenterReal` / `GameCenterFake`
- `ReviewPrompter` → `ReviewPrompterReal` / `ReviewPrompterStub`
- `GetterSetter` → `GetterSetterReal` / `GetterSetterFake`
- `CommunGetter` → `CommunGetterReal` / `CommunGetterStub`
- `AnalyticsLocale` → `AnalyticsLocaleReal` / `AnalyticsLocaleStub` (protocol renamed from `Locale` to avoid shadowing `Foundation.Locale`)

> **Convention — adding a new behavior protocol with real + test-double conformances.** Name the protocol a **plain role noun** — no `-able`/`-Protocol`/`-ing` suffix (`GetterSetter`, `CommunGetter`, `GameCenter`). Name the production conformer `<Protocol>Real` and the test double `<Protocol><Role>`, where `<Role>` is the [Fowler test-double type](https://martinfowler.com/bliki/TestDouble.html) that matches what the double actually *does*:
> - **`Fake`** — a working implementation with a production-unsuitable shortcut, e.g. an in-memory store (`GetterSetterFake`).
> - **`Stub`** — returns canned answers, no real logic (`CommunGetterStub`).
> - **`Spy`** — a stub that *also records* how it was called, for assertions (`AnalyticsServiceSpy`).
> - **`Mock`** — pre-programmed with expectations it verifies. **`Dummy`** — passed to fill a slot but never exercised.
>
> Because the protocol and all its conformers share a prefix, they **sort together in Xcode's Project Navigator** — the point of the convention (and consistent with the `CatFancy-final` app). One type per file, filename = type name. **Check for a system-API collision** before settling on the protocol name: `Locale` had to become `AnalyticsLocale` because it shadowed `Foundation.Locale` module-wide. Wire the real conformer into `World.device` and the double into `World.simulator` / `.unitTest` / `.uiTest`.

### View Architecture

**All SwiftUI** (since the July 2026 migration — Step 4). The UI lives in `Conjugar/Views/`
as native SwiftUI: an `@main App` → `MainTabView` (`TabView`) whose tabs are each a
SwiftUI screen using `NavigationStack` + value-based navigation. Shared design-system
primitives are in `Utils/Modifiers.swift` (`.card()`, `.metadataPill()`, `.linguistic()`,
`.numeric()`, `.speakOnTapFlash()`, `PrimaryButtonStyle`, …) and read the adaptive color
assets, so every screen is light/dark correct. Marked-up Info bodies parse via
`Utils/RichText.swift` → `Views/RichTextView.swift`; conjugation forms (uppercase =
irregular) render via `Views/ConjugationText.swift`. The old UIKit `*VC`/`*UIV`/`*Cell`
files, the `MainTabBarVC` shell, and the `NavHostedVC` hosting bridge are all gone; **no
`UIViewController` subclass remains in the app target.**

Layout constants are in `Layout.swift` (defaultSpacing = 8.0, doubleDefaultSpacing = 16.0,
tripleDefaultSpacing = 24.0, defaultHorizontalMargin = 16.0, readingWidth = 680,
cornerRadius = 12). The `@UsesAutoLayout` property wrapper survives only for the few
remaining UIKit *extensions* (appearance config in `AppDelegate`), not for screen layout.

The mapped UI audit that drove the migration is `docs/conjugar-ui-issues.md`.

### Tab Structure (`MainTabView`)

1. **Browse Verbs** — `VerbBrowseView` → `VerbView`
2. **Models** — `ModelBrowseView` → `ModelView` (→ `VerbView`)
3. **Quiz** — `QuizView` → `ResultsView`
4. **Info** — `InfoBrowseView` → `InfoView`
5. **Settings** — `SettingsView`

`CommunView` (the CloudKit message) is a `.fullScreenCover` presented from `MainTabView`,
not a tab.

### Core Models

- **Conjugator.swift** (+ the feature-file family, `ModelCatalog`, and `VerbMap`) - The conjugation engine: composition of feature rules over a book-class model catalog, resolving each verb's model from `verbModelMap.xml` (4,811 verbs). The app UI conjugates through it via `TenseBridge` (maps the UI's `DisplayTense`/`DisplayPersonNumber` vocabulary to `EngineTense`, the simple-tense-plus-person slots the engine consumes) and `CompoundTense` (composes perfect tenses as *haber* + participle, and imperativo negativo as "no" + subjunctive — the engine itself models only simple tenses). The legacy `Conjugator`/`verbs.xml` engine was removed in July 2026; `DisplayTense.swift`/`DisplayPersonNumber.swift` (formerly `Tense.swift`/`PersonNumber.swift`) remain as the UI's vocabulary, covering the full displayed tense set including compounds.
- **Quiz.swift** - A `@MainActor @Observable` quiz state model (scoring, closure-based timer, difficulty levels), observed directly by `QuizView`/`ResultsView`. The old `QuizDelegate` was removed in the SwiftUI migration.
- **Settings.swift** - User preferences with GetterSetter protocol abstraction.

## Testing

Tests are in `ConjugarTests/` organized by layer:
- `Analytics/`, `Controllers/`, `Models/`, `UIViews/`, `Utils/`, `Views/`

Test infrastructure:
- The test environment is selected in `World.chooseWorld()` (a simulator process with the
  XCTest runtime loaded gets `World.unitTest`) — the SwiftUI `@main App` lifecycle replaced
  the old custom `main.swift`/`TestingAppDelegate` selection during the migration.
- `URLProtocolStub` for network mocking
- Stub classes (`AnalyticsLocaleStub`, `CommunGetterStub`) for isolation

### XCTest + MainActor: the isolated-deinit crash (write new tests in Swift Testing)

> **Landmine (Xcode 26.3, seen July 2026).** Under `SWIFT_DEFAULT_ACTOR_ISOLATION =
> MainActor`, every pure-Swift `@MainActor` class gets an *isolated deinit*, and this
> toolchain's `swift_task_deinitOnExecutorImpl` **double-frees** (`malloc: pointer being
> freed was not allocated` → SIGABRT) when **XCTest** deallocates such an object at
> teardown. It fires mostly through `World.deinit` releasing its `@MainActor` service
> members when a test reassigns `Current` in `setUp`. It is **test-only** — the shipping
> app never deallocates `World` (a `Current` singleton) — and **Swift Testing does not
> trigger it** (Konjugieren's all–Swift Testing suite is why it never hit this).
>
> **Convention: write new tests as Swift Testing** (`@Suite`/`@Test`/`#expect`), not
> XCTest. Add `@MainActor` to a suite that touches MainActor types; leave engine suites
> nonisolated (they touch only the nonisolated engine). `@Test(arguments:)` collections
> are evaluated *outside* the suite's isolation, so any static data they reference must
> be `nonisolated`.
>
> **Resolved (July 2026):** the five formerly-*doomed* UIKit XCTest suites that crashed on
> teardown (`BrowseModelsVCTests`, `BrowseVerbsVCTests`, `CommunVCTests`, `ModelVCTests`,
> `SettingsViewTests`) are gone — the first four were deleted with their VCs during the
> SwiftUI migration, and `SettingsViewTests` was converted to Swift Testing. A full
> `xcodebuild … test` run is now **TEST SUCCEEDED** (all XCTest + Swift Testing, 0
> failures). The general rule still stands, since MainActor default isolation remains: a
> new pure-Swift `@MainActor` object deallocated by XCTest will hit the same double-free —
> so **write new tests in Swift Testing.** (The service suites `SettingsTests`,
> `GetterSetterRealTests`, `ReviewPrompterRealTests`, `GameCenterFakeTests` were converted
> earlier, and `AnalyticsServiceSpy` made `nonisolated`.)

## Localization

Supported languages: English (base), Spanish. The system is two parts, mirroring the
sibling apps Conjuguer and Konjugieren:

- **`Conjugar/Supporting/L.swift`** — a type-safe `enum L` of scoped accessors backed by
  `String(localized:)`. Keys mirror the Swift path exactly: `L.Quiz.start` →
  `String(localized: "Quiz.start")`. Parameterized strings are **functions**, and the key
  is built by interpolation: `L.Model.numberAndPercent(model:percent:)` →
  `String(localized: "Model.numberAndPercent \(model) \(percent)")`, whose runtime key is
  `"Model.numberAndPercent %@ %lld"`.
- **`Conjugar/Supporting/Localizable.xcstrings`** — one JSON string catalog holding **both**
  `en` and `es`, `sourceLanguage: en`. This replaced the legacy `NSLocalizedString` calls +
  the UTF-16 `es.lproj/Localizable.strings` (removed July 2026). `LaunchScreen.strings`
  stays in `es.lproj` and is unrelated.

Both files live in `Supporting/`, a **`PBXFileSystemSynchronizedRootGroup`** — new files
dropped there are auto-added to the target, so adding a catalog or a Swift file needs **no
`project.pbxproj` edit**. (Removing an *old-style* explicit reference like the legacy
`.strings` variant group still does — that one wasn't synchronized.)

### Adding / changing a localized string

1. Add the accessor to `L.swift` in the right scope (`Feature.purpose`); use a `static func`
   for parameterized strings.
2. Add the key + `en`/`es` translations to `Localizable.xcstrings` (both `"state":
   "translated"` so Xcode doesn't treat `es` as stale and fall back to English).
3. Use via `L.Feature.name` in code.

### Editing `Localizable.xcstrings` safely (the foot-guns)

- **The Edit tool corrupts `.xcstrings` values with ASCII quotes.** Edit operates on
  *rendered* text, so JSON's `\"` displays as a plain `"`; any edit adding/removing/changing
  an ASCII `"` (U+0022) inside a value writes an **unescaped** quote and breaks the catalog.
  Rule: edit `.xcstrings` values containing ASCII quotes via `python3` on the raw file, not
  Edit. Unicode curly quotes `" " „` need no escaping and are safe with Edit.
- **Always validate after any edit:**
  `python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"`.
- **Grep is useless inside `.xcstrings`** — each value is one very long JSON line, so the
  Grep tool truncates matches to `[Omitted long matching line]`. To find a phrase: Grep for
  the line number, then Read at that offset. To replace: Python with a unique nearby word as
  an anchor to hit the correct language section (e.g. a Spanish word to target `es`, not
  `en`).

### `.strings` vs `.xcstrings` escaping & newlines

If you ever re-derive the catalog from a legacy `.strings` file, do **not** hand-translate
escaping — use real parsers (`plutil -convert json` to read, `json.dump` to write). The
rules differ:

- **`.strings`** (old, UTF-16, C-style): interior quotes `\"`; **literal newlines allowed**
  inside a value; a naive UTF-8 read produces garbage.
- **`.xcstrings`** (new, JSON, UTF-8): interior `"` must be `\"`, backslash `\\`; **literal
  newlines are illegal** — every newline must be `\n`, so each rich-text block is one
  physical JSON line. A serializer emits both correctly; string-concatenation does not.

### Percent signs — two different kinds

- **Rich-text markup** like `%terminología%`, `%voseo%`, `%presente de indicativo%` is the
  Info parser's *tappable-term* syntax, a **single** `%…%` looked up with no format
  arguments — the `%` passes through literally. Do **not** double it. URLs in Info bodies are
  also wrapped in single `%…%` (e.g. `%https://…%`).
- **Format specifiers** (`%@`, `%lld`) are the real ones. Prefer `%lld` over `%d` for `Int`
  (what the catalog generates). Multi-arg strings use **positional** specifiers so
  translators can reorder: `Model %1$@ · %2$lld%% irregular` (note `%%` for a literal
  percent). Pluralized strings use xcstrings plural **variations** (`one`/`other`), provided
  for both `en` and `es`; where a distinct zero sentence is needed (e.g. ratings), keep it a
  separate key and pick it at the call site, because CLDR maps `0 → other` for en/es.

### Info rich-text markup (parsed by `StringExtensions`, rendered by the Info screens)

Other markup in the long Info/tense bodies is literal text needing no escaping in either
format:

| Marker | Purpose | Example |
|--------|---------|---------|
| `^…^` | Section heading | `^Purpose^`, `^Conjugation^` |
| `~…~` | Emphasis/italic | `~Conjugar~`, `~vosotros~` |
| `$…$` | Irregularity highlight (uppercase letters = the irregular part, shown red) | `$voY$`, `$soY$`, `$habRá$` |
| `%…%` | Tappable term (links to another tense/terminology) or URL | `%voseo%`, `%https://…%` |

When relocalizing an Info body, preserve every marker in the equivalent position and keep
example Spanish/English words and irregular-highlight casing intact.
