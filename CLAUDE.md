# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Conjugar is an iOS app for learning Spanish verb conjugations. It conjugates regular and irregular Spanish verbs in all tenses with quiz mode (3 difficulty levels), verb browsing, tense information, and Game Center integration.

**Developer:** Josh Adams (vermontcoder@gmail.com), who released the app in 2017.
**Target:** iOS 17+
**License:** GNU Affero General Public License

As of 2026, a project is underway to modernize and improve Conjugar. The engine migration is **done**: the app conjugates exclusively through the new `Conjugator2` engine (4,811 verbs from `verbModelMap.xml`, all 16+ tenses — regular and irregular verbs, homonyms, defectives, prefixed compounds, with compound tenses composed in-app by `CompoundTense` and the UI's `DisplayTense`/`PersonNumber` vocabulary mapped by `TenseBridge`). Browse Verbs is an all-verbs list sortable by Frequency/Alphabetical. The legacy `Conjugator` engine, `verbs.xml`, and their tests were **removed** in July 2026. Next planned step (separate effort): converting the UIKit UI to SwiftUI. The modernization/improvement work lives in this folder, /Users/josh/Desktop/workspace/Conjugar.mig . Commits in this folder should be pushed to the migration branch. Eventually, the migration branch will be folded into Conjugar's master branch.

As you, Claude, complete chunks of work on the modernization/improvement project, please add a note to docs/blog_notes.md . Eventually, Josh will generate a blog post from this work.

## Build and Test Commands

This is an Xcode project (project `Conjugar.xcodeproj`, scheme `Conjugar`). Use the following commands:

```bash
# Build the app
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all tests (disable parallel testing to avoid simulator flakiness)
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test

# Run a single test suite
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test -only-testing:ConjugarTests/Conjugator2Tests

# Run a single test method (Swift Testing — note the trailing, shell-escaped parentheses)
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test -only-testing:ConjugarTests/Conjugator2Tests/oirPresent\(\)

# Lint
swiftlint
```

> **`-only-testing:` format — the suite is mixed.** The path is `Target/Suite/method`. Do **not** include filesystem subdirectories (`Models/`, `Utils/`). The new-engine suites (`Conjugator2Tests`, `VerbMap2Tests`, `Resolver2Tests`) use **Swift Testing**, so a method name must end in `()` (e.g. `oirPresent()`, shell-escaped as `oirPresent\(\)`) — omitting it makes xcodebuild silently run zero tests. The older suites (`QuizTests`, `BrowseVerbsVCTests`, etc.) use **XCTest**, whose method names take **no** parentheses (e.g. `testBrowseVerbsVC`).

## Running the App in the Simulator

To launch and drive the built app (screenshots, taps, verifying UI behavior — not just tests), use the project skill **`run-in-simulator`** (`.claude/skills/run-in-simulator/SKILL.md`). It captures the verified recipe: resolving the built `.app`, pinning a booted-simulator UDID (several devices are named "iPhone 17"), `simctl` install/launch/screenshot, tapping with `idb` in points (screenshot pixels ÷ 3), and the pitfalls (launch-screen delay, `simctl spawn defaults write` not reaching the app's sandboxed UserDefaults). This skill is interim: after the planned SwiftUI conversion, the `ios-build-verify` skill will replace it.

## Architecture

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

**No Storyboards** - All UI is programmatic using NSLayoutConstraint.

Naming conventions:
- View Controllers: `*VC` (e.g., `BrowseVerbsVC`)
- UIKit Views: `*UIV` (e.g., `BrowseVerbsUIV`)
- Table Cells: `*Cell` (e.g., `VerbCell`)

The `@UsesAutoLayout` property wrapper automatically sets `translatesAutoresizingMaskIntoConstraints = false`.

Layout constants are in `Layout.swift` (defaultSpacing = 8.0, tripleDefaultSpacing = 24.0, defaultHorizontalMargin = 16.0).

### Tab Structure (MainTabBarVC)

1. **Browse Verbs** - `BrowseVerbsVC` → `VerbVC`
2. **Quiz** - `QuizVC` → `ResultsVC`
3. **Browse Info** - `BrowseInfoVC` → `InfoVC`
4. **Settings** - SwiftUI `SettingsView` via UIHostingController

### Core Models

- **Conjugator2.swift** (+ the `*2.swift` family and `ModelCatalog2`/`VerbMap2`) - The conjugation engine: composition of feature rules over a book-class model catalog, resolving each verb's model from `verbModelMap.xml` (4,811 verbs). The app UI conjugates through it via `TenseBridge` (maps the UI's `DisplayTense`/`PersonNumber` vocabulary to `EngineTense`, the simple-tense-plus-person slots the engine consumes) and `CompoundTense` (composes perfect tenses as *haber* + participle, and imperativo negativo as "no" + subjunctive — the engine itself models only simple tenses). The legacy `Conjugator`/`verbs.xml` engine was removed in July 2026; `DisplayTense.swift` (formerly `Tense.swift`) and `PersonNumber.swift` remain as the UI's vocabulary, covering the full displayed tense set including compounds.
- **Quiz.swift** - Quiz state management with QuizDelegate protocol for updates. Handles scoring, timing, difficulty levels.
- **Settings.swift** - User preferences with GetterSetter protocol abstraction.

## Testing

Tests are in `ConjugarTests/` organized by layer:
- `Analytics/`, `Controllers/`, `Models/`, `UIViews/`, `Utils/`, `Views/`

Test infrastructure:
- `TestingAppDelegate` loads for test environments via `main.swift`
- `URLProtocolStub` for network mocking
- Stub classes (`AnalyticsLocaleStub`, `CommunGetterStub`) for isolation

## Localization

Supported languages: English, Spanish. String constants are in `Localizations.swift` (auto-generated from `Localizable.strings`).
