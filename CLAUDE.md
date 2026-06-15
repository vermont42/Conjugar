# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Conjugar is an iOS app for learning Spanish verb conjugations. It conjugates regular and irregular Spanish verbs in all tenses with quiz mode (3 difficulty levels), verb browsing, tense information, and Game Center integration.

**Developer:** Josh Adams (vermontcoder@gmail.com), who released the app in 2017.
**Target:** iOS 17+
**License:** GNU Affero General Public License

As of 2026, a project is underway to modernize and improve Conjugar. A new conjugation engine, which can conjugate more than 4,800 verbs, has already landed. The modernization/improvement work lives in this folder, /Users/josh/Desktop/workspace/Conjugar.mig . Commits in this folder should be pushed to the migration branch. Eventually, the migration branch will be folded into Conjugar's master branch.

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

> **`-only-testing:` format — the suite is mixed.** The path is `Target/Suite/method`. Do **not** include filesystem subdirectories (`Models/`, `Utils/`). The new-engine suites (`Conjugator2Tests`, `VerbMap2Tests`, `Resolver2Tests`) use **Swift Testing**, so a method name must end in `()` (e.g. `oirPresent()`, shell-escaped as `oirPresent\(\)`) — omitting it makes xcodebuild silently run zero tests. The legacy suites (`ConjugatorTests`, etc.) use **XCTest**, whose method names take **no** parentheses (e.g. `testRegularARVerb`).

## Architecture

### Dependency Injection via World Singleton

The app uses a DI container pattern through `World.swift`. All services are accessed via the global `Current` variable:

```swift
var Current = World.device  // Production
// or World.simulator, World.unitTest, World.uiTest
```

Services provided by World:
- `analytics: AnalyticsServiceable` - no-op test stub (AWS Pinpoint removed; TelemetryDeck planned)
- `gameCenter: GameCenterable` - Game Center integration
- `reviewPrompter: ReviewPromptable` - App Store review prompting
- `settings: Settings` - User preferences (wraps UserDefaults)
- `communGetter: CommunGetter` - CloudKit-based messaging

### Protocol-Based Abstractions

All external services have protocol abstractions with test implementations:
- `AnalyticsServiceable` → `TestAnalyticsService` (the only implementation; a TelemetryDeck-backed one is planned)
- `GameCenterable` → `GameCenter` / `TestGameCenter`
- `ReviewPromptable` → `ReviewPrompter` / `TestReviewPrompter`
- `GetterSetter` → `UserDefaultsGetterSetter` / `DictionaryGetterSetter`

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

- **Conjugator.swift** - Verb conjugation engine using stem-based transformations. Handles 16+ tenses, regular/irregular verbs, with recursive parent verb inheritance. Parses `verbs.xml`.
- **Quiz.swift** - Quiz state management with QuizDelegate protocol for updates. Handles scoring, timing, difficulty levels.
- **Settings.swift** - User preferences with GetterSetter protocol abstraction.

## Testing

Tests are in `ConjugarTests/` organized by layer:
- `Analytics/`, `Controllers/`, `Models/`, `UIViews/`, `Utils/`, `Views/`

Test infrastructure:
- `TestingAppDelegate` loads for test environments via `main.swift`
- `URLProtocolStub` for network mocking
- Stub classes (`StubLocale`, `StubCommunGetter`) for isolation

## Localization

Supported languages: English, Spanish. String constants are in `Localizations.swift` (auto-generated from `Localizable.strings`).
