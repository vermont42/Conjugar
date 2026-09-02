# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Conjugar is a universal iOS app for learning Spanish verb conjugations. It conjugates 4,811 regular and irregular verbs in all tenses, and offers a searchable verb browser, verb-model reference, tense essays, a three-difficulty quiz with Game Center leaderboards and a Live Activity, an on-device AI tutor, Home/Lock Screen widgets and Control Center controls, and an arcade minigame. `README.md` has the user-facing feature list.

**Developer:** Josh Adams (vermontcoder@gmail.com), who released the app in 2017.
**Target:** iOS 26+
**Language:** Swift 6 language mode, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (see **Concurrency model** below)
**License:** GNU Affero General Public License

As you, Claude, complete chunks of work on Conjugar, append a note to docs/blog_notes.md. Give each entry a `##` heading
that includes the date — `## <Title> (YYYY-MM-DD)` — with newest entries at the bottom (the earliest entries use a leading
`## YYYY-MM-DD — <Title>` form; write new ones in the trailing form). Write narrative for a future reader (what was tried,
what failed, why decisions changed), not a bare changelog: Josh will eventually generate blog posts from these notes, and
future Claude sessions may use them as dated project memory. When older docs conflict, the journal shows which truth is
more current. That said, the current state of the codebase is the ultimate source of truth.

When you create a new plan (typically in the `prompts/` folder), open it in Visual Studio
Code so Josh can read it immediately: `code <path-to-plan>` (the VS Code CLI binary is
`code`).

**Do not commit or push, and do not create branches.** Leave changes in the working tree on
`master`. Josh reviews them and runs his own `/commit-and-push` skill when he is ready; he
does not use feature branches. Commit only when he asks explicitly in the current message.

## Build and Test Commands

This is an Xcode project (project `Conjugar.xcodeproj`, scheme `Conjugar`). Build and
test go through the **`ios-build-verify`** Claude Code skill, which pipes `xcodebuild`
through `xcbeautify` (concise output, raw `build.log` fallback) and disables parallel
testing. The per-project config lives at `.claude/ios-build-verify.config.sh` (sourced
by every script; hand-editable, and **committed** — it holds only project facts, so a
fresh clone builds without re-running the skill's `setup_project.sh`). The skill is installed via Claude Code's plugin
marketplace from [vermont42/ios-build-verify](https://github.com/vermont42/ios-build-verify).

**Resolve the scripts directory once per session**, then invoke through `$IBV_SCRIPTS`:

```bash
export IBV_SCRIPTS=$(dirname "$(find ~/.claude/plugins/marketplaces -path '*ios-build-verify*' -name build_app.sh 2>/dev/null | head -1)")
```

Search `plugins/marketplaces`, **not `~/.claude` broadly**. The marketplace clone is a
single git checkout with no version segment, refreshed to the latest release by
`claude plugin marketplace update`, so it yields exactly one match. The broader glob also
reaches the per-version `plugins/cache/ios-build-verify/<version>/` directories, which are
shared with Josh's other apps and can pin older releases — an unsorted `head -1` there
resolves nondeterministically to a stale version. (`scripts/take_screenshots.sh` carries
the same resolver, for the same reason; see `docs/screenshot-playbook.md`.)

```bash
# Build the app — this is the COMPILE step
"$IBV_SCRIPTS/build_app.sh"

# Run all tests
"$IBV_SCRIPTS/run_tests.sh"

# Run a single test suite
"$IBV_SCRIPTS/run_tests.sh" --only-testing ConjugarTests/ConjugatorTests

# Run a single test method (Swift Testing — note the trailing, shell-escaped parentheses)
"$IBV_SCRIPTS/run_tests.sh" --only-testing ConjugarTests/ConjugatorTests/oirPresent\(\)

# Lint
swiftlint
```

> **Testing an unpublished change to the skill itself.** The skill is developed locally at
> `~/Desktop/workspace/ios-build-verify` but consumed from GitHub, so the resolved copy is
> always the *published* one. To exercise local edits, point the variable at the dev repo —
> `export IBV_SCRIPTS=~/Desktop/workspace/ios-build-verify/skills/ios-build-verify/scripts` —
> and unset it to return to the published copy. `take_screenshots.sh` honors a pre-set
> `IBV_SCRIPTS` too, so one export covers both.

The skill also drives the running app in the simulator (launch, tap, screenshot, verify)
— see **Running the App in the Simulator** below. Its full operation surface is documented
in `$IBV_SCRIPTS/../SKILL.md`.

> **Diagnostic fallback — raw `xcodebuild`.** When `xcbeautify`'s lossy filter drops an
> early-stage error, or the skill scripts are unavailable, the underlying commands still
> work directly. Prefer the skill scripts so future sessions exercise them.
>
> ```bash
> xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' build
> xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test -only-testing:ConjugarTests/ConjugatorTests/oirPresent\(\)
> ```

> **`-only-testing:` format — the suite is mixed.** The path is `Target/Suite/method`. Do **not** include filesystem subdirectories (`Models/`, `Utils/`). The engine suites (`ConjugatorTests`, `ConjugatorAccessorsTests`, `ConjugatorResolverTests`, `VerbMapTests`, `TenseBridgeTests`) the migrated service suites (`SettingsTests`, `GetterSetterRealTests`, `ReviewPrompterRealTests`, `GameCenterFakeTests`), and the SwiftUI-migration suites (`InfoTests`, `ConjugationTextTests`, `QuizTests`, `SettingsViewTests`) use **Swift Testing**, so a method name must end in `()` (e.g. `oirPresent()`, shell-escaped as `oirPresent\(\)`) — omitting it makes xcodebuild silently run zero tests. The handful of older suites still on **XCTest** (`ConjugationResultTests`, `DisplayTenseTests`, `DisplayPersonNumberTests`, `IntExtensionTests`, `RatingsFetcherTests`) take method names with **no** parentheses (e.g. `testFetchRatings`). New tests should be Swift Testing — see **XCTest + MainActor: the isolated-deinit crash** below.
>
> **The `Suite` segment is the Swift *type* name, never the `@Suite("…")` display name.** `struct GameBossTests` decorated `@Suite("GameBoss")` is selected as `ConjugarTests/GameBossTests` — passing the display string `ConjugarTests/GameBoss` matches **nothing**, and (same failure mode as an omitted `()`) xcodebuild prints **`Test Succeeded` while running zero tests**. This is the single most dangerous test-runner trap here: a green run that tested nothing. **Always confirm real execution by the count line** — Swift Testing prints `✔ Test run with N tests in M suites passed` (its own reporter; the XCTest summary's `Executed 0 tests … passed` is only the XCTest half and says nothing about Swift Testing). `run_tests.sh` echoes that `Test run with N tests …` line when tests run, so its **absence after a `--only-testing` filter means the selector matched nothing** — treat that as a failure, not a pass, and re-check the suite is spelled as its type name.

## Running the App in the Simulator

To launch and drive the built app (screenshots, taps, verifying UI behavior — not just
tests), use the **`ios-build-verify`** skill. It wraps the `simctl` lifecycle plus **AXe**
for observation and HID dispatch.

```bash
S="$IBV_SCRIPTS"                  # resolved once per session — see Build and Test Commands
"$S/build_app.sh"                 # COMPILE (launch_app.sh does NOT compile — run this first)
"$S/launch_app.sh"                # install last build + launch; polls FIRST_SCREEN_ID for render
"$S/screenshot.sh" my-label       # PNG into docs/screenshots/ (pixels, 3× — AXe taps use points)
"$S/tap_tab.sh" settings          # tap a main-tab by name (browse | models | quiz | info | settings)
"$S/describe_ui.sh" --point 200,540   # inspect the element under a logical-points coordinate
```

### Project config for `ios-build-verify`

Conjugar-specific facts baked into `.claude/ios-build-verify.config.sh`:

- **Launch anchor** `FIRST_SCREEN_ID = browse_verb_count` — the `.accessibilityIdentifier`
  on the Browse tab's verb-count banner (`VerbBrowseView.swift`), a stable launch-screen
  **leaf** (not a container — SwiftUI rolls a parent's id onto every descendant). It's the
  app's only accessibility identifier; add more leaf anchors when you need to verify a
  deeper screen with `tap_id.sh` / `--verify-anchor`.
- **Five-tab pill needs explicit coords.** The shipped centroid detector calibrates the
  canonical 3-tab pill; Conjugar's 5-tab pill under-segments, so `MAIN_TABS_COORDS` is set
  by hand (`63,822 131,822 200,822 269,822 337,822`, logical points, verified by tapping
  each tab). Re-measure via `screenshot.sh` + manual centering if the tab bar geometry
  changes; don't trust `calibrate.sh`'s auto-measure for 5 tabs.
- **AXe coordinates are logical points, not screenshot pixels.** iPhone 17 is 3× — divide
  a pixel coordinate by 3 before passing it to a tap.
- **SourceKit false positives.** Editing a view file spams `Cannot find 'X' in scope` /
  `has no member` diagnostics for same-module symbols; `build_app.sh` is authoritative —
  trust it, don't "fix" the SourceKit-only noise.

### Deeplinks (jump straight to a screen)

The app registers the **`conjugar://`** URL scheme (`Conjugar/Info.plist`), routed by
`AppRouter.handle(url:)` (`Views/AppRouter.swift`). Open one with `simctl` to skip manual
navigation — it cold-launches the app and routes on arrival:

```bash
UDID=$(xcrun simctl list devices booted -j | python3 -c "import sys,json;print(json.load(sys.stdin)['devices'].popitem()[1][0]['udid'])")
xcrun simctl openurl "$UDID" conjugar://game            # → full-screen game (Settings ▸ Play, skipped)
xcrun simctl openurl "$UDID" conjugar://game/boss       # → jump straight to the boss fight (La Llamada)
xcrun simctl openurl "$UDID" conjugar://quiz/start      # → Quiz tab, starts a quiz
xcrun simctl openurl "$UDID" conjugar://verb/hablar     # → Browse tab, pushes a verb (or verb/random)
```

**`conjugar://game`** is the fast path to the game: it presents `GameView` full-screen via
`AppRouter.showGame` from `MainTabView` (tab-independent), so no Settings→scroll→Play dance.
The game has its own deeplinks, debug environment variables, and animation freeze-framing
recipes — see [`docs/game.md`](docs/game.md).

## Project Structure

See [`docs/project-structure.md`](docs/project-structure.md) for the full annotated directory tree.

**Cache maintenance:** When you add, remove, or rename a source file, update `docs/project-structure.md` to match. This doc is a cache. Future contexts rely on it to orient quickly, so staleness has a real cost. The two staleness modes are not equally bad: a *missing* entry costs a session one `find`, because it sees the gap and reads the file, while a *wrong* entry gets believed. Prioritize renames and repurposed files.

## Architecture

### Concurrency model (Swift 6 / strict concurrency)

The project builds under **Swift 6** with `SWIFT_STRICT_CONCURRENCY = complete`,
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`,
and `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`. The settings are
placed like the sibling app Konjugieren's: strict-concurrency at the **project** level;
default-actor isolation on the **app** target only; the rest on app + test. Consequences to
work with:

- **Default isolation is `@MainActor`.** Any type with no explicit annotation is
  MainActor-isolated. The SwiftUI views and the DI services (`World`, `Settings`, `Quiz`, the
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
- `analytics: Analytics` - TelemetryDeck-backed usage analytics (see **Analytics (TelemetryDeck)** below)
- `gameCenter: GameCenter` - Game Center integration
- `reviewPrompter: ReviewPrompter` - App Store review prompting
- `settings: Settings` - User preferences (wraps UserDefaults)
- `languageModelService: LanguageModelService` - the on-device conjugation tutor (see **Conjugation Tutor** below)
- `getterSetter: GetterSetter` - shared string key-value store (same instance `Settings` wraps); the tutor persists chat history through it
- `soundPlayer: SoundPlayer` / `hapticPlayer: HapticPlayer` - SFX, looping music, and haptics
- `quiz: Quiz` - the shared quiz state model
- `session: URLSession` - injected so `RatingsFetcher` can be tested through `URLProtocolStub`

### Analytics (TelemetryDeck)

Conjugar uses the same analytics schema as the sibling apps Conjuguer and Konjugieren.
Files: `Analytics/Analytics.swift` (the `Analytics`
protocol plus the `AnalyticsName` / `ParameterKey` enums), `AnalyticsReal.swift`,
`AnalyticsSpy.swift`.

- **Event names are an enum, not strings.** `Current.analytics.signal(name: .viewVerbView)`;
  parameters are `[String: String]` keyed by `ParameterKey.…rawValue`. **A raw
  value is a wire name** — renaming a case orphans its dashboard history, which is why
  `AnalyticsTests` pins the parameter-carrying ones.
- **The whole family is `nonisolated`,** like the engine. Without it the module's default
  MainActor isolation would make the protocol — and by witness inference every conformer's
  methods — MainActor-isolated, contradicting `AnalyticsReal`'s off-main design and making
  the spy unusable from a nonisolated test suite.
- **`AnalyticsReal` funnels every TelemetryDeck call onto a serial GCD queue.** TelemetryDeck
  2.14.1 uses blocking `DispatchQueue.sync` internally, so calling it from a `@MainActor`
  call site would run that blocking work on the main thread. The queue also orders
  `initialize` ahead of signals and confines `isInitialized` to one thread.
- **The app ID is kept out of the working tree.** It lives in gitignored
  `Conjugar/Secrets.xcconfig` as `TELEMETRY_DECK_APP_ID` (copy `Secrets.example.xcconfig`),
  reaches the bundle through the `TelemetryDeckAppID` Info.plist key — the xcconfig is the
  app target's `baseConfigurationReference` for both Debug and Release — and is read in
  `ConjugarApp.init()` → `Current.analytics.initialize(appID:)`. An empty ID leaves the
  service uninitialized so it silently drops signals; **a fresh clone with no
  `Secrets.xcconfig` still builds and runs.**
- **Only `World.device` gets `AnalyticsReal`;** simulator/unit-test/UI-test worlds get
  `AnalyticsSpy`, which records `signalNames`/`signalParameters` for assertions. So
  **signals never reach the dashboard from a normal simulator run** — the spy is a dead end
  by design.
- **Debug builds land in the dashboard's Test Mode, not the live view.** The SDK's
  `TelemetryDeck.Config.testMode` defaults to the `DEBUG` flag, so everything from Xcode —
  device or simulator — is tagged `isTestMode == true` and is **invisible until you flip the
  Test Mode toggle** (top-left of the dashboard, above the sidebar; a "Test Data" banner
  confirms it). This is the first thing to check when signals seem missing; it is not a bug.
  TestFlight and App Store builds go to the live view with no code change.
- **No `becameActive` signal.** TelemetryDeck records launches and sessions itself, and
  reports app version, device model, and country/language natively.

The published policy describing what is collected is `docs/privacy_policy3.txt` (English
plus a Spanish translation); **update it when you add or remove a signal.**

### Protocol-Based Abstractions

All external services have protocol abstractions with production and test implementations, named in the Fowler test-double convention — `…Real` for the production conformer, `…Fake`/`…Stub`/`…Spy` for the double:
- `Analytics` → `AnalyticsReal` (TelemetryDeck) / `AnalyticsSpy`
- `GameCenter` → `GameCenterReal` / `GameCenterFake`
- `ReviewPrompter` → `ReviewPrompterReal` / `ReviewPrompterStub`
- `GetterSetter` → `GetterSetterReal` / `GetterSetterFake`
- `LanguageModelService` → `LanguageModelServiceReal` / `LanguageModelServiceDummy` (the double is a `Dummy` — always reports unavailable and is never exercised; the test/UI-test worlds must not touch the on-device model)

> **Convention — adding a new behavior protocol with real + test-double conformances.** Name the protocol a **plain role noun** — no `-able`/`-Protocol`/`-ing` suffix (`GetterSetter`, `Analytics`, `GameCenter`). Name the production conformer `<Protocol>Real` and the test double `<Protocol><Role>`, where `<Role>` is the [Fowler test-double type](https://martinfowler.com/bliki/TestDouble.html) that matches what the double actually *does*:
> - **`Fake`** — a working implementation with a production-unsuitable shortcut, e.g. an in-memory store (`GetterSetterFake`).
> - **`Stub`** — returns canned answers, no real logic (`ReviewPrompterStub`).
> - **`Spy`** — a stub that *also records* how it was called, for assertions (`AnalyticsSpy`).
> - **`Mock`** — pre-programmed with expectations it verifies. **`Dummy`** — passed to fill a slot but never exercised.
>
> Because the protocol and all its conformers share a prefix, they **sort together in Xcode's Project Navigator** — the point of the convention (and consistent with the `CatFancy-final` app). One type per file, filename = type name. **Check for a system-API collision** before settling on the protocol name — a type named plainly `Locale`, say, would shadow `Foundation.Locale` module-wide. Wire the real conformer into `World.device` and the double into `World.simulator` / `.unitTest` / `.uiTest`.

### View Architecture

**All SwiftUI**. The UI lives in `Conjugar/Views/`
as native SwiftUI: an `@main App` → `MainTabView` (`TabView`) whose tabs are each a
SwiftUI screen using `NavigationStack` + value-based navigation. Shared design-system
primitives are in `Utils/Modifiers.swift` (`.card()`, `.metadataPill()`, `.linguistic()`,
`.numeric()`, `.speakOnTapFlash()`, `PrimaryButtonStyle`, …) and read the adaptive color
assets, so every screen is light/dark correct. Marked-up Info bodies parse via
`Utils/RichText.swift` → `Views/RichTextView.swift`; conjugation forms (uppercase =
irregular) render via `Views/ConjugationText.swift`. **No `UIViewController` subclass remains
in the app target.**

Layout constants are in `Layout.swift` (defaultSpacing = 8.0, doubleDefaultSpacing = 16.0,
tripleDefaultSpacing = 24.0, defaultHorizontalMargin = 16.0, readingWidth = 680,
cornerRadius = 12). Screen layout is all SwiftUI; the only UIKit that remains is appearance
config in `AppDelegate` and a small set of service-seam extensions.

### Tab Structure (`MainTabView`)

1. **Verbs** — `VerbBrowseView` → `VerbView` (the displayed label is *Verbs* / *Verbos*, but the code says *browse* throughout: `VerbBrowseView`, the `L.BrowseVerbs` scope and its catalog keys, the `.viewVerbBrowseView` analytics case, the `browse_verb_count` anchor, and `tap_tab.sh browse`)
2. **Models** — `ModelBrowseView` → `ModelView` (→ `VerbView`)
3. **Quiz** — `QuizView` → `ResultsView`
4. **Info** — `InfoBrowseView` → `InfoView` (and → `TutorView`, the conjugation tutor, from a section at the top of the list)
5. **Settings** — `SettingsView`


### Onboarding

A first-launch welcome tour: a paged `.fullScreenCover` (`Views/OnboardingView.swift`) with a
Settings-driven reshow, gated by `Settings.hasSeenOnboarding` and the `OnboardingDisplay` kill
switch. See [`docs/onboarding.md`](docs/onboarding.md).

### Widget extension

The project has a second target, **`ConjugarWidgetExtension`** (`ConjugarWidget/`): a "Verb of
the Day" widget, an interactive daily-quiz widget, Lock Screen accessories, two Control Center
controls, and the quiz **Live Activity** / Dynamic Island. The app and the extension share data
through an **App Group** — `Utils/WidgetSnapshotWriter.swift` picks and conjugates the daily
verb and quiz question and writes JSON that the widgets read; `Shared/` holds the ActivityKit
contract and the App Group constants. The widget target has its **own** `Localizable.xcstrings`
and its own copies of the conjugation- and etymology-rendering helpers, so a change to the app's
render conventions has to be mirrored there. See
[`docs/project-structure.md`](docs/project-structure.md) for the file-by-file map.

### The game — Toreo por Amor

Conjugar ships a small arcade game, **Toreo por Amor**: a five-stage climb (*La Subida*)
followed by a flamenco dance-off boss fight (*La Llamada*). The UI is `Views/GameView.swift`
and the state machine is `Models/Game/` (`GameState.swift` plus its `GameState+…` extensions);
strings live in `L.Game`. Full mechanics, sprite/animation notes, the `Music` enum, and the
debug deeplinks and environment variables are in [`docs/game.md`](docs/game.md).

### Core Models

- **Conjugator.swift** (+ the feature-file family, `ModelCatalog`, and `VerbMap`) - The conjugation engine: composition of feature rules over a book-class model catalog, resolving each verb's model from `verbModelMap.xml` (4,811 verbs). The app UI conjugates through it via `TenseBridge` (maps the UI's `DisplayTense`/`DisplayPersonNumber` vocabulary to `EngineTense`, the simple-tense-plus-person slots the engine consumes) and `CompoundTense` (composes perfect tenses as *haber* + participle, and imperativo negativo as "no" + subjunctive — the engine itself models only simple tenses). `DisplayTense.swift`/`DisplayPersonNumber.swift` are the UI's vocabulary, covering the full displayed tense set including compounds.
- **Quiz.swift** - A `@MainActor @Observable` quiz state model (scoring, closure-based timer, difficulty levels), observed directly by `QuizView`/`ResultsView`.
- **Settings.swift** - User preferences with GetterSetter protocol abstraction.

### Conjugation Tutor (on-device LLM)

A Spanish conjugation tutor: a chat screen (`Views/TutorView.swift`) backed by
`LanguageModelServiceReal`, which wraps Apple's **on-device** `SystemLanguageModel` from the
**Foundation Models** framework. It is grounded in the app's own engine via a `ConjugationTool`,
so it never invents forms, and it is **unavailable in the simulator**. Reached from a section at
the top of the Info tab. See [`docs/conjugation-tutor.md`](docs/conjugation-tutor.md).

## Testing

Tests are in `ConjugarTests/` organized by layer:
- `Analytics/`, `Models/`, `Utils/`, `Views/`

Test infrastructure:
- The test environment is selected in `World.chooseWorld()`: a simulator process with the
  XCTest runtime loaded gets `World.unitTest`.
- `URLProtocolStub` for network mocking
- Test doubles (`AnalyticsSpy`, `GetterSetterFake`, `GameCenterFake`) for isolation

### XCTest + MainActor: the isolated-deinit crash (write new tests in Swift Testing)

> **Landmine (Xcode 26.3).** Under `SWIFT_DEFAULT_ACTOR_ISOLATION =
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
> A full `xcodebuild … test` run passes today (all XCTest + Swift Testing, 0 failures), but
> the rule still stands, since MainActor default isolation remains: a new pure-Swift
> `@MainActor` object deallocated by XCTest will hit the same double-free — so **write new
> tests in Swift Testing.**

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
  `en` and `es`, `sourceLanguage: en`. There are no `NSLocalizedString` calls and no
  `es.lproj/Localizable.strings`. `LaunchScreen.strings` stays in `es.lproj` and is unrelated.

Both files live in `Supporting/`, a **`PBXFileSystemSynchronizedRootGroup`** — new files
dropped there are auto-added to the target, so adding a catalog or a Swift file needs **no
`project.pbxproj` edit**. (Removing an *old-style* explicit file reference still does.)

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
