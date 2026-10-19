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

**No em dashes between clauses.** Generated prose (release notes, journal entries, docs,
Info bodies, drafts of emails) must never use an em dash to separate two clauses that each
have a subject and a predicate. Start a new sentence instead; that is usually best. Less
often, a semicolon is appropriate. (Older entries in `docs/blog_notes.md` predate this rule
and are left as they are.)

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

> **`-only-testing:` format — the suite is mixed.** The path is `Target/Suite/method`. Do **not** include filesystem subdirectories (`Models/`, `Utils/`). The engine suites (`ConjugatorTests`, `ConjugatorAccessorsTests`, `ConjugatorResolverTests`, `VerbMapTests`, `TenseBridgeTests`) the migrated service suites (`SettingsTests`, `GetterSetterRealTests`, `ReviewPrompterRealTests`, `GameCenterFakeTests`), and the SwiftUI-migration suites (`InfoTests`, `ConjugationTextTests`, `QuizTests`, `SettingsViewTests`) use **Swift Testing**, so a method name must end in `()` (e.g. `oirPresent()`, shell-escaped as `oirPresent\(\)`) — omitting it makes xcodebuild silently run zero tests. The handful of older suites still on **XCTest** (`ConjugationResultTests`, `DisplayTenseTests`, `DisplayPersonNumberTests`, `IntExtensionTests`, `RatingsFetcherTests`) take method names with **no** parentheses (e.g. `testFetchRatings`). New tests should be Swift Testing; see **Testing** below.
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

### Analytics (TelemetryDeck)

Analytics goes through the `Analytics` protocol (`Conjugar/Analytics/`). Its gotchas (wire-name enums, the `nonisolated` family, the off-main queue, the gitignored app ID, and why simulator and Debug signals never show in the live dashboard) are in [`.claude/rules/analytics.md`](.claude/rules/analytics.md). **When you add or remove a signal, update `docs/privacy_policy3.txt`.**

### Protocol-Based Abstractions

All external services have protocol abstractions with production and test implementations, named in the Fowler test-double convention — `…Real` for the production conformer, `…Fake`/`…Stub`/`…Spy` for the double.

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

### Conjugation Tutor (on-device LLM)

A Spanish conjugation tutor: a chat screen (`Views/TutorView.swift`) backed by
`LanguageModelServiceReal`, which wraps Apple's **on-device** `SystemLanguageModel` from the
**Foundation Models** framework. It is grounded in the app's own engine via a `ConjugationTool`,
so it never invents forms, and it is **unavailable in the simulator**. Reached from a section at
the top of the Info tab. See [`docs/conjugation-tutor.md`](docs/conjugation-tutor.md).

## Testing

**Write new tests in Swift Testing, not XCTest.** Under default MainActor isolation, XCTest double-frees `@MainActor` objects at teardown (Xcode 26.3). The details and the suite-isolation rules are in [`.claude/rules/testing.md`](.claude/rules/testing.md).

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

**Never use the Edit tool to add, remove, or change an ASCII `"` inside an `.xcstrings` value** (the app's catalog or `ConjugarWidget/Localizable.xcstrings`). Edit writes the quote unescaped and breaks the JSON, so use `python3` on the raw file. The workflow for adding a string, the escaping and percent-sign rules, and the Info rich-text markup table are in [`.claude/rules/localization.md`](.claude/rules/localization.md). Read it before editing either catalog.