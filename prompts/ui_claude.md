# Migrate Conjugar to SwiftUI (prep + migration)

The time has come to migrate Conjugar's UI from UIKit to SwiftUI, the framework its
brethren **Conjuguer** (French) and **Konjugieren** (German) already use. This is a
redesign, not a transliteration: both siblings started with a UI nearly identical to
Conjugar's, then had it audited and improved with the `ios-design-agent-skill`. We want
Conjugar to land where they landed — including **proper light and dark mode**, which
Conjugar lacks today.

Reference apps and their (already-implemented) UI audits:
- Conjuguer — `/Users/josh/Desktop/workspace/Conjuguer` · audit: `Conjuguer/docs/conjuguer-ui-issues.md`
- Konjugieren — `/Users/josh/Desktop/workspace/Konjugieren` · audit: `Konjugieren/docs/ui-audit.md`
- Blog on applying the design skill: https://racecondition.software/blog/ios-design-agent-skill/

Konjugieren is the **primary template** — it's the most recently built and closest in
structure. Prefer **porting and adapting** its already-shipping SwiftUI over re-deriving
anything from scratch.

---

## What is already done (do not redo)

The July 2026 build-settings migration (see `docs/blog_notes.md` and the **Concurrency
model** section of `CLAUDE.md`) laid the foundation this work depends on:

- **Swift 6 + `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** — every new SwiftUI view is
  born under modern concurrency; no retrofit needed.
- **The `Conjugator` engine + its vocabulary are `nonisolated` + `Sendable`** — SwiftUI
  views (MainActor) call `Conjugator` / `TenseBridge` / `CompoundTense` synchronously.
- **Localization is done** — use `L.*` (backed by `Localizable.xcstrings`) for all
  strings; never add `NSLocalizedString`. Read the xcstrings foot-guns in `CLAUDE.md`
  before touching the catalog.
- **A SwiftUI beachhead exists**: `Conjugar/Views/SetttingsView.swift` is already SwiftUI
  + `@Observable`, and `Conjugar/Utils/Modifiers.swift` + `FontExtensions.swift` hold the
  current (thin, UIKit-color-based) shared code. You are **evolving** these, not starting
  from zero.

Current UI to be replaced (`Conjugar/Controllers/`): `MainTabBarVC`, `BrowseVerbsVC`,
`VerbVC`, `BrowseModelsVC`, `ModelVC`, `BrowseInfoVC`, `InfoVC`, `QuizVC`, `ResultsVC`,
`CommunVC` (+ `CommunViewModel`). Plus `*UIV` views and `*Cell` cells. `SettingsView` is
already SwiftUI.

---

## Do this in order

### Step 0 — Settle the app skeleton and state model (this, not colors, is what the migration hinges on)

The visual steps are easy; the risk lives here. Land these five decisions — and the app
skeleton they imply — before migrating any individual screen. Konjugieren is a working
reference for every one of them; when in doubt, do what it does.

1. **App entry point + test-`World` injection (the one real wrinkle).** Replace the custom
   `Conjugar/Supporting/main.swift` (`UIApplicationMain` + `NSClassFromString("Testing`
   `AppDelegate")`) with `@main struct ConjugarApp: App { WindowGroup { MainTabView() } }`,
   keeping an `AppDelegate` only via `@UIApplicationDelegateAdaptor` if you still need
   delegate hooks (Konjugieren does this for orientation lock). The trap: the App lifecycle
   can't use the custom-`main.swift` trick that today selects `TestingAppDelegate` (which
   sets `Current = World.unitTest`). Move that selection **into `World`/`Current`
   initialization** — detect the test environment there and return `World.unitTest`/
   `.uiTest`, exactly as Konjugieren's `World.swift` does (`return World.unitTest`). Then
   confirm a test run still gets `World.unitTest` before proceeding; getting this wrong
   silently runs tests against the production `World`.

2. **Coexistence: go SwiftUI-first immediately.** Flip the shell to SwiftUI (`App` +
   `TabView`) up front and host each not-yet-migrated UIKit screen via
   `UIViewControllerRepresentable`, retiring them one at a time. Do **not** keep the UIKit
   `MainTabBarVC` shell and bolt SwiftUI on with `UIHostingController` (today's arrangement
   — `MainTabBarVC` hosts `SettingsView`). SwiftUI-first means the end state needs no
   un-migration and every screen swap stays local to that screen.

3. **Navigation container.** `TabView` + a per-tab `NavigationStack`, using value-based
   navigation (`navigationDestination(for:)`) in place of `UINavigationController` push.
   Template: Konjugieren's `MainTabView` and `App/KonjugierenApp.swift`
   (`WindowGroup { MainTabView() }`). Map the four existing tabs across
   (Browse Verbs · Quiz · Info · Settings), plus the Models entry point.

4. **DI: keep the `Current` global — do not introduce `@Environment` for `World`.**
   Konjugieren's SwiftUI reaches its DI container through the same global `Current`
   (`Current.settings`, `Current.handleURL`, …) that Conjugar already has, and `Current`
   is already `@MainActor` (from the concurrency migration). Match that: one DI pattern
   across the whole codebase, no environment object threaded through every view. Reserve
   `@State`/`@Observable` for *screen-local* state, not the container.

5. **State model: `@Observable` replaces the UIKit delegates.** Conjugar's delegate
   protocols (`QuizDelegate`, `InfoDelegate`) and its `CommunViewModel` dissolve into
   observation. Convention: an `@MainActor @Observable` model for a screen with non-trivial
   state, plain `@State` otherwise; the already-migrated `SettingsView` + its
   `SelectionStore` is the reference. The flagship — and hardest — case is **Quiz**:
   convert `Conjugar/Models/Quiz.swift` from `QuizDelegate` + `Timer.scheduledTimer(target:`
   `selector:)` to an `@MainActor @Observable class Quiz` with a closure-based timer
   (`Timer.scheduledTimer(withTimeInterval:repeats:) { [weak self] _ in … }`) plus
   `start`/`stop`/`pause`/`resumeTimer`, per Konjugieren's `Models/Quiz.swift` (and see its
   `QuizView` for how the view binds). Do this conversion **before** migrating
   `QuizVC`/`ResultsVC`.

The deliverable of Step 0 is a launchable SwiftUI-shell app: `@main App` → `TabView` whose
tabs are still the old screens wrapped in `UIViewControllerRepresentable`, tests still
injecting `World.unitTest`, and `Quiz` already an `@Observable` model. From there, Step 4
swaps one wrapped VC at a time for a real SwiftUI screen.

### Step 1 — Codify the design system (port + adapt, don't invent)

Conjugar is **dark-only today**: `Conjugar/Utils/Colors.swift` hardcodes a black
background and four fixed `UIColor`s (red `193,0,29` · yellow `205,165,27` · blue
`85,135,255` · black), and there are **zero color assets**. Adding light mode is
genuine new design, not a free by-product — a yellow-on-black scheme does not trivially
invert.

- **Port Konjugieren's color assets** as the starting point. It has 7 light/dark
  colorsets in `Konjugieren/Konjugieren/Assets/Assets.xcassets`: `customBackground`,
  `customCardBackground`, `customCardBorder`, `customForeground`, `customRed`,
  `customYellow`, `AccentColor` (each with a `luminosity: dark` appearance). Create the
  analogous asset catalog in Conjugar, seeded with Conjugar's brand hues (its red/yellow
  differ slightly from Konjugieren's — keep Conjugar's identity), and give every color a
  legible **light** variant. Conjuguer's palette (`customBlue`/`customSurface`/… with
  `Reversed` pairs) is a second reference for handling reversed/emphasis colors.
- Replace `Colors.swift`'s fixed `UIColor`s with a SwiftUI-facing palette that reads from
  the assets, so light/dark is automatic. Retire hardcoded `Color.black` backgrounds.
- Verify **both appearances** on every screen as you go (see Verification).

### Step 2 — Audit by *mapping*, not fresh discovery

Conjugar's UIKit UI is nearly identical to the siblings' *pre-improvement* UI, so most
findings already exist. Don't burn effort re-auditing a UI you're about to delete.

- **Map the sibling audits onto Conjugar's screens.** Konjugieren's `ui-audit.md` has 18
  numbered items (quiz card framing + progress bar, correct/incorrect micro-interactions
  and `.sensoryFeedback()`, conjugation-section cards + accent bars, serif titles /
  reading width for linguistic content via `.fontDesign(.serif)`, settings section
  grouping, large results score, list empty-states, metadata pills, sort animation, verb-
  count banner, …). Most apply directly. Produce a `docs/conjugar-ui-issues.md` that ties
  each relevant item to the concrete Conjugar screen.
- **Hunt fresh only for Conjugar-specific screens the siblings lack** — chiefly the
  **Models tab** (`BrowseModelsVC`/`ModelVC`) and the **Commun/messaging** screen
  (`CommunVC`). Those need their own audit.
- Use the **`run-in-simulator`** skill to capture before-screenshots of the current UIKit
  screens for the record and for side-by-side comparison. (That skill is interim; after
  the migration the `ios-build-verify` skill replaces it.)

### Step 3 — Build the shared SwiftUI code (port + adapt)

- Grow `Conjugar/Utils/Modifiers.swift` from its current ~6 thin modifiers toward
  Konjugieren's ~186-line `Konjugieren/Konjugieren/Utils/Modifiers.swift`: card
  containers, section headers, accent bars, button styles, reading-width wrappers, serif
  linguistic text, sensory-feedback helpers — whatever the mapped audit items call for.
  Point them at the new color assets, not `Colors.yellow` etc.
- Keep `FontExtensions.swift` as the type ramp; add `.fontDesign(.serif)` where the audit
  wants linguistic content set in serif.
- Follow the project's naming/DI conventions in `CLAUDE.md` (test doubles Fowler-named,
  one type per file, services wired through `World`).

### Step 4 — Migrate screens, lowest-risk first, retiring test debt as you go

Suggested order (build momentum on easy wins; save the stateful/timed screen for last):

1. Info screens (`BrowseInfoVC` → list, `InfoVC` → detail) — mostly text, exercises the
   rich-text markup (`^…^`, `~…~`, `$…$`, `%…%` per `CLAUDE.md`).
2. Browse lists (`BrowseVerbsVC`, `BrowseModelsVC`).
3. Detail screens (`VerbVC`, `ModelVC`) — conjugation tables, irregularity highlighting.
4. `CommunVC` / messaging.
5. **Quiz** (`QuizVC` → `ResultsVC`) — last, on top of the Step-0 `@Observable Quiz`.

`SettingsView` is already SwiftUI — use it as the reference pattern.

**Fold in the test cleanup.** As each VC is replaced, delete it (and its `*UIV`/`*Cell`)
and **rewrite its test as Swift Testing**. This is exactly what retires the five UIKit
XCTest suites that currently crash on teardown (the Xcode 26.3 isolated-deinit bug
documented in `CLAUDE.md`): `BrowseModelsVCTests`, `BrowseVerbsVCTests`, `CommunVCTests`,
`ModelVCTests`, `SettingsViewTests`. By the end, `xcodebuild … test` should be fully
green again.

---

## Gotchas the executing session must know (all detailed in `CLAUDE.md`)

- **Write new tests in Swift Testing, not XCTest.** Under MainActor default isolation,
  XCTest deallocating a pure-Swift `@MainActor` object hits an Xcode 26.3 isolated-deinit
  double-free. Swift Testing sidesteps it. `@MainActor` on suites that touch MainActor
  types; `@Test(arguments:)` data must be `nonisolated`.
- **Keep new engine/pure types `nonisolated`**; views and view-models are `@MainActor`.
- **`MEMBER_IMPORT_VISIBILITY`**: add explicit `import Foundation` / `import Observation`
  where you rely on their members.
- **`.xcstrings` editing foot-guns** (ASCII-quote corruption via the Edit tool, Grep
  truncation, always `json.load`-validate) — see the Localization section of `CLAUDE.md`.
- **`Supporting/` is a synchronized group** — new files there auto-join the target with no
  `project.pbxproj` edit; new asset catalogs / Swift files elsewhere may still need target
  membership checked.

## Verification (per screen, before moving on)

- Build clean; SwiftLint clean.
- Drive the screen with the **`run-in-simulator`** skill and screenshot it in **both light
  and dark** mode — light mode is a first-class deliverable here, not an afterthought.
- Confirm behavior against the old screen (conjugation forms, quiz scoring/timing,
  navigation).
- Add/rewrite the screen's tests in Swift Testing; keep the suite green.
- Add a note to `docs/blog_notes.md` per `CLAUDE.md`.

## Process

Work on the `migration` branch; commit in logical chunks (design system, shared code,
then screen-by-screen). Don't try to land the whole migration in one commit.
