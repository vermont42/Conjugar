# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Conjugar is an iOS app for learning Spanish verb conjugations. It conjugates regular and irregular Spanish verbs in all tenses with quiz mode (3 difficulty levels), verb browsing, tense information, and Game Center integration.

**Target:** iOS 17+
**License:** GNU Affero General Public License

## Build Commands

```bash
# Build the project
xcodebuild -scheme Conjugar build

# Run tests
xcodebuild test -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 16'

# Lint
swiftlint
```

## Architecture

### Dependency Injection via World Singleton

The app uses a DI container pattern through `World.swift`. All services are accessed via the global `Current` variable:

```swift
var Current = World.device  // Production
// or World.simulator, World.unitTest, World.uiTest
```

Services provided by World:
- `analytics: AnalyticsServiceable` - AWS Pinpoint or test stub
- `gameCenter: GameCenterable` - Game Center integration
- `reviewPrompter: ReviewPromptable` - App Store review prompting
- `settings: Settings` - User preferences (wraps UserDefaults)
- `communGetter: CommunGetter` - CloudKit-based messaging

### Protocol-Based Abstractions

All external services have protocol abstractions with test implementations:
- `AnalyticsServiceable` → `AWSAnalyticsService` / `TestAnalyticsService`
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
