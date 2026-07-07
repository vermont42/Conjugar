# Conjugar Code Review — Recommendations

**Date:** July 7, 2026
**Scope:** Full codebase — app target, `ConjugarWidget` extension, `Shared/`, `ConjugarTests/`, build settings, localization catalog. (Conjuguer/Konjugieren consulted for context only, per the prompt.)
**Baseline:** Full test suite passes (403 tests, 17 suites, 0 failures). SwiftLint: 0 violations in 162 files. Build settings verified: Swift 6, iOS 26, MainActor default isolation.
**Carve-out honored:** the deliberate `ModelBrowseView`/`VerbBrowseView` mirroring is not flagged.

Items are ranked highest impact → lowest. Impact = user-visible correctness first, then crash/concurrency risk, then code health, then modernization and polish. Each item cites evidence (`file:line`), explains why it matters, and sketches a fix.

---

## 1. ✅ Game Center is inert — and its auth flow is structurally unsafe · **bug (feature-dead) + crash risk**

The Game Center integration cannot activate for any user, and the code that would run if it did has a latent crash. Four interlocking problems:

**a) The gating condition is inverted.** `QuizView.maybePromptGameCenter()` (`Conjugar/Views/QuizView.swift:300`):

```swift
guard !Current.gameCenter.isAuthenticated, Current.settings.userRejectedGameCenter else { return }
```

Authentication proceeds only when `userRejectedGameCenter` is **true** — i.e., only users who said *No* ever get prompted (and then get force-authenticated on every Quiz visit, against their stated wish). For a fresh install (`userRejectedGameCenterDefault = false`, `Settings.swift:114`) the guard always fails: no dialog, no auth, ever. The only escape is the Settings-tab **Enable** button — which is broken too (see *b*). This is not a migration regression: the identical condition exists in the deleted `QuizVC` and traces back to commit `cc4a651` — it has been shipping this way for years. The condition should be `!Current.settings.userRejectedGameCenter`.

**b) `Current.parentViewController` is never assigned.** `World.swift:27` declares it; the only other references are the two *reads* at `QuizView.swift:311` and `SettingsView.swift:250`, both falling back to `?? UIViewController()`. Presenting GameKit's login sheet (or the failure alert, `GameCenterReal.swift:50`) on a freshly-created, never-installed view controller silently does nothing. So even the Settings **Enable Game Center** button (`SettingsView.swift:245`) — and the `EnableGameCenterTip` that points users at it — leads nowhere on a device that isn't already signed in.

**c) `withCheckedContinuation` wraps a long-lived, multi-shot handler.** `GameCenterReal.authenticate` (`GameCenterReal.swift:23`) resumes a checked continuation from inside `localPlayer.authenticateHandler`. GameKit documents that it may invoke this handler repeatedly (e.g. on foregrounding or auth-state changes) for the lifetime of the process. After the first `resume`, any subsequent invocation that reaches a `resume` path is a **fatal error (continuation resumed twice)**. Conversely, the "present the login VC" branch never resumes, so a user who dismisses the sheet leaks the continuation and the caller's `Task` hangs forever. Re-calling `authenticate` also replaces the handler while an old continuation may still be pending.

**d) Small rot in the same file.** The stored `onViewController` property (`GameCenterReal.swift:16`) is written but never read (the closure captures the parameter). `leaderboardIdentifier` is loaded in a fire-and-forget `Task` (`:39-45`), so a `reportScore` racing right after auth submits to `[""]`; on failure it becomes the sentinel string `"ERROR"` and `reportScore`'s `catch {}` (`:70`) swallows everything silently.

**Fix (one coherent rewrite, ~a day):**
- Set `authenticateHandler` **once** at startup; treat it as a stream of state changes, not a one-shot call. Derive `isAuthenticated` from `GKLocalPlayer.local.isAuthenticated` and publish it (make the conformer `@Observable`, or expose a callback World wires up).
- When GameKit hands you a login VC, present it from the real hierarchy — `UIApplication.topViewController()` (`Conjugar/Utils/UIApplicationExtensions.swift:12`) already exists and is scene-aware. Then delete `World.parentViewController` and drop `UIViewController` from the `GameCenter` protocol entirely (it's the last UIKit type in a service seam).
- Fix the inverted guard in `QuizView` and re-test the No→don't-nag / Yes→authenticate / Settings-Enable→re-opt-in flows.
- Await the leaderboard-ID load before the first `reportScore` (or load lazily inside it), replace the `"ERROR"` sentinel with `nil`, and log the `reportScore` failure instead of `catch {}`.
- The failure alert should become SwiftUI state, not `UIAlertController.showMessage` on a detached VC.

Verification note: the simulator Worlds use `GameCenterFake`, so this must be exercised on a device.

Reference implementation: none of this bug exists in the siblings, and **Konjugieren's `GameCenterReal`** (`Konjugieren/Utils/GameCenterReal.swift`) already embodies the recommended shape — a set-once, `[weak self]` `authenticateHandler` installed at app init, `@Observable` with `isAuthenticated` mirroring `GKLocalPlayer`, a scene-aware top-view-controller lookup for the login sheet, and logged (not swallowed) submit failures. Port that file and wrap Conjugar's opt-in dialog around it rather than designing from scratch. (Conjuguer solves the presentation differently — a real zero-size VC mounted via `UIViewControllerRepresentable` — workable, but the Konjugieren approach needs no view-hierarchy plumbing.)

## 2. ✅ The quiz can teach wrong Spanish — `VerbFamilies` data bugs · **bug (content)**

`Quiz` builds questions from the hand-curated lists in `Conjugar/Models/VerbFamilies.swift`, and the engine conjugates whatever it's given. Three data problems (verified against `verbModelMap.xml`):

- **`manecer` is not in the verb map — and isn't standard Spanish** (`VerbFamilies.swift:26`, in `irregularPresenteDeSubjuntivoVerbs`). Unmapped verbs fall back to a *regular* model (`Conjugator.swift:151-158`), so a Moderate/Difficult quiz that draws it asks for the presente de subjuntivo of a nonexistent verb and displays the incorrect regular form (*"maneza"*, not even the *-zc-* form a real *-ecer* verb would take). With 3 draws from a 37-item shuffled list, roughly 1 quiz in 12 hits it. It was a parent-verb artifact of the legacy `verbs.xml` engine; delete it (the list already has `amanecer`/`anochecer`, both mapped as class 7A).
- **`helar` is misfiled as a regular -ar verb** (`VerbFamilies.swift:10`). The map classifies it 4A (e→ie diphthong: *hielo*, *HIELa*). Easy-difficulty "regular -ar" questions can therefore demand an irregular form from a learner who was promised a regular drill. Move it out (or swap in a truly regular verb).
- **`esconder` appears twice in `regularErVerbs`** (`VerbFamilies.swift:14`), skewing the cycle.

Also: `thirdPersonSingularOnlyVerbs` (`VerbFamilies.swift:36`) is dead — no references.

**Fix + guard-rail:** correct the three entries, then add a Swift Testing suite that pins the lists to the map — every entry must (a) resolve in `VerbMap.shared`, and (b) match its list's intent (`regular*` lists → classes 1/2/3; `irregular…` lists → anything else). That test is ~20 lines and would have caught all three (and will catch future edits). Today's `QuizTests` can't: it compares the quiz's answer to the same engine's output, so it verifies self-consistency, not linguistic truth.

## 3. Browse search does its filtering (twice) and plays sounds inside `body` · **perf + SwiftUI-purity**

`VerbBrowseView.filteredVerbs` (`Conjugar/Views/VerbBrowseView.swift:35-40`) is a computed property that scans all 4,811 entries with two `.range(of:options:[.caseInsensitive,.diacriticInsensitive])` probes per entry — and `body` reads it **twice** per render (the count banner at `:47` and the `ForEach` at `:70`), so every keystroke does the full scan twice on the main thread. Worse, the helper it calls, `BrowseSearch.results` (`Conjugar/Utils/BrowseSearch.swift:27-29`), **plays the sad trombone as a side effect of view evaluation** — the `SoundPlayer` debounce comment even admits body runs "several times per keystroke". Side effects in `body` are the canonical SwiftUI anti-pattern: any unrelated re-render while a no-match query sits in the field re-fires the sound. `ModelBrowseView` mirrors both issues (`:34-39`, `:46`, `:65`) — flagged here as the *same mechanism*, not as duplication.

**Fix:** compute the filtered array in `.onChange(of: searchText)` (and `.onChange(of: sort)`) into a `@State private var filtered: [VerbMapEntry]`, and fire the no-results sound there, where it belongs (`if filtered.isEmpty && !trimmed.isEmpty` — the one-shot transition, not every evaluation). `BrowseSearch` then loses its `playSoundIfEmpty` parameter and becomes a pure function. This drops per-keystroke work by half and makes render side-effect-free; 4,811 × 2 probes once per keystroke is fine after that (no debounce needed).

## 4. ✅ `applicationDidBecomeActive` never fires — became-active analytics are dead · **latent bug**

Under the SwiftUI `App` lifecycle the app adopts scenes, and UIKit then delivers activation to the *scene*, not the app delegate — `AppDelegate.applicationDidBecomeActive` (`Conjugar/Supporting/AppDelegate.swift:48-50`) is never called, so `recordBecameActive()` (and the device-model/locale payload built in `AnalyticsService.swift:78-87`) never runs. Harmless today because analytics is a print-only spy, but it's a trap for the planned TelemetryDeck integration (`World.swift:78`): launch/activation metrics would silently be zero.

**Fix:** delete the empty delegate lifecycle methods and move the call into the existing scene-phase observer — `MainTabView.onChange(of: scenePhase)` (`MainTabView.swift:48-52`) already runs on `.active`. While there, note `DeviceUtility.swift`'s 100-line hand-maintained device table exists *only* for this event; TelemetryDeck reports model identifiers natively, so the whole file can likely go when the integration lands.

## 5. ✅ `InfoView`'s reading-width logic is inverted · **UI bug (iPad)**

`InfoView.swift:49`:

```swift
.frame(maxWidth: horizontalSizeClass == .regular ? .infinity : Layout.readingWidth, alignment: .leading)
```

On iPad (**regular**) this removes the measure cap and lets article text sprawl the full window — the exact case `Layout.readingWidth`'s doc comment says it exists for. On iPhone (compact, ~390 pt) the 680 pt cap is a no-op. Every sibling screen applies the cap unconditionally (`QuizView.swift:105-106`, `ResultsView.swift:47-48`, `SettingsView` via `.readingWidth()`). Replace the conditional with the standard `.frame(maxWidth: Layout.readingWidth)` + `.frame(maxWidth: .infinity)` pair (i.e. the `readingWidth()` modifier).

## 6. `ConjugationTool`'s call counter is a shared mutable static marked `nonisolated(unsafe)` · **concurrency**

`LanguageModelServiceReal.swift:227`:

```swift
nonisolated(unsafe) private static var callCount = 0
```

`call(arguments:)` increments it from wherever the FoundationModels runtime invokes tools; `resetCallCount()` zeroes it from the MainActor before each send (`:148`). That's an unsynchronized read-modify-write across actors — a real data race the annotation merely silences — and it's *global*: the chat session and a concurrently-running `TutorTestView` batch share one counter, so one session's calls can trip the other's limit.

**Fix:** make the limit per-tool-instance — a fresh `ConjugationTool()` is already created per session (`:150`, `:171`), so an instance `let counter = OSAllocatedUnfairLock(initialState: 0)` (or `Mutex<Int>` from `Synchronization`) gives you a correctly-scoped, race-free count and deletes the static + reset dance entirely.

## 7. ✅ Review-prompt bookkeeping: locale-fragile date round-trip, time frozen at launch, and a second `Settings` instance · **minor bugs**

Three small correctness issues in one feature:

- **`Settings.lastReviewPromptDate` uses a bare `DateFormatter`** (`Conjugar/Utils/Settings.swift:103-104`) — no `locale`, no `timeZone`, and a format whose `'Z'` is a literal. Per Apple's QA1480, a user's 12/24-hour override or non-Gregorian calendar can make `HH` formatting/parsing fail or write non-Gregorian years; a failed parse falls back to the epoch default, making the review prompt eligible again. Set `locale = Locale(identifier: "en_US_POSIX")` + `timeZone = UTC`, or better, store `timeIntervalSince1970` and delete the formatter.
- **`ReviewPrompterReal` captures `now` once** (`ReviewPrompterReal.swift:27-29`): `now: Date = Date()` is evaluated when `World.device` is built at launch, and `promptableActionHappened()` both compares against and *records* that stale timestamp (`:38-40`). The `now` parameter is a test seam; production should read `Date()` at call time (e.g. `now: () -> Date = { Date() }`).
- **It also constructs its own `Settings`** (`ReviewPrompterReal.swift:27` default argument) instead of receiving `World.device`'s instance (`World.swift:80`). Two live `Settings` objects cache the same UserDefaults keys independently — harmless today only because their key usage happens to be disjoint. Inject `settings` explicitly in `World.device`.

## 8. ✅ Widget nits: "deterministic" shuffle isn't, and midnight refresh ignores DST · **minor bugs**

- **`QuizWidgetView.shuffledAnswers`** (`ConjugarWidget/Views/QuizWidgetView.swift:92-100`) seeds its RNG from `Hasher`, which is **randomly seeded per process**. Widget-extension processes are killed and respawned between timeline renders, so the answer order the comment promises is "stable across reloads" actually reshuffles whenever the extension relaunches. Correctness is unaffected (the intent carries the answer string) but the button order visibly jumps. Seed deterministically — e.g. FNV-1a over `questionID.utf8` — and keep the nice `SeededRNG`.
- **Both timeline providers compute the next refresh as `startOfDay + 86_400`** (`VerbOfTheDayWidget.swift:33`, `QuizWidget.swift:32`). On DST-change days that's 11 PM or 1 AM, so the verb of the day rolls over an hour early/late twice a year. Use `Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)`.

## 9. ✅ `CommunGetterReal` compares app versions as `Double`s · **latent bug**

`CommunGetterReal.swift:64-66` parses both the CloudKit-pushed version and `CFBundleShortVersionString` with `Double(...)`: version `"2.10"` becomes 2.1 and compares *older* than `"2.9"`, and any future two-dot version (`"2.8.1"`) fails to parse and drops the commun entirely. Marketing version is currently `2.8`, so this bites exactly when you ship a `x.10` or adopt patch versions. Compare numeric components instead (split on `"."`, compare lexicographically), or `String.compare(options: .numeric)`.

## 10. ✅ Delete the dead UIKit stratum · **code health (large, zero-risk)**

The SwiftUI migration finished, but its fossil record remains in the app target. All of the following have **no callers in app code** (verified by project-wide search); together they're ~500 lines that mislead readers (and CLAUDE.md) about what the app still uses:

| Dead code | Where | Note |
|---|---|---|
| `StringExtensions.swift` — `conjugatedString`, `coloredString`, `replaceFirstOccurence` | `Conjugar/Utils` | whole file; superseded by `RichText`/`ConjugationText`; referenced only in comments |
| `NSAttributedStringExtension.swift` (`+`, `+=`) | `Conjugar/Utils` | only consumer was `conjugatedString` |
| `UILabelExtension.swift` (`titleLabel(title:)`) | `Conjugar/Utils` | |
| `UISegmentedControlExtension.swift` (`yellowfyText`) | `Conjugar/Utils` | |
| `UIViewExtensions.swift` (`pulsate`, `setAccessibilityLabelInSpanish`) | `Conjugar/Utils` | kept alive only by its own test |
| `NSCoderExtension.swift` (`fatalErrorNotImplemented`) | `Conjugar/Utils` | |
| `UsesAutoLayout.swift` | `Conjugar/Utils` | kept alive only by its own test; **CLAUDE.md's claim that AppDelegate still needs it is stale** |
| `Fonts.swift` (UIFont table) | `Conjugar/Utils` | app-side users are all on this list; last reference is the dead test-support `TestingRootViewController` |
| `FontExtensions.swift` — `heading`, `subheading`, `smallBody` | `Conjugar/Utils` | keep `button` (used by `PrimaryButtonStyle`/`LinkButtonStyle`) and `heroNumeral` |
| `Modifiers.swift:82-123` — `HeadingLabel`, `SubheadingLabel`, `BodyLabel`, `StandardButton`, `SegmentedPicker` | `Conjugar/Utils` | never applied via `.modifier(...)`; the "kept for SettingsView" comment predates the rebuild |
| `UIAlertControllerExtension.okTitle()` | `Conjugar/Utils` | the rest of the file dies with the Game Center rewrite (item 1) |
| `Quiz.pauseTimer()` / `resumeTimer()` | `Models/Quiz.swift:368-374` | no callers since the VC lifecycle went away |
| `DisplayTense.conjugationCount(secondSingularBrowse:)` | `Models/DisplayTense.swift:41` | legacy table-view row math |
| `DisplayPersonNumber.actualPersonNumbers` | `Models/DisplayPersonNumber.swift:61` | |
| `VerbFamilies.thirdPersonSingularOnlyVerbs` | `Models/VerbFamilies.swift:36` | |
| `World.parentViewController` | `Models/World.swift:27` | dies with item 1 |
| **Test target:** `TestingAppDelegate`, `TestingRootViewController`, `NavigationCSpy`, `Helpers/UIColorExtension` | `ConjugarTests` | the `@objc` delegate selection died with `main.swift`; `NavigationCSpy` is referenced by nothing; delete the tests-of-dead-code (`UsesAutoLayoutTests`, `UIViewExtensionsTests`) alongside |

Do this as one commit ("remove the post-migration dead code"), then update CLAUDE.md's `@UsesAutoLayout` sentence and, if `Colors`' UIKit bridge shrinks to just AppDelegate/`SettingsView.init` usage, revisit it after item 13.

## 11. ✅ Make `Settings` `@Observable`, retire the `SelectionStore` bridge, and collapse the persistence boilerplate · **architecture**

Three reinforcing problems in the settings layer:

- **Staleness by construction.** `Settings` is a plain class, so views that read it get no invalidation. `QuizView.briefing` renders `Current.settings.difficulty/region` pills (`QuizView.swift:94-97`); after changing either in the Settings tab, the Quiz briefing updates only if something *else* happens to re-render it. Any future screen that reads a setting inherits the same trap.
- **A bridge that exists only to work around it.** `SelectionStore` (`SettingsView.swift:266-292`) plus the copy-in dance in `.onAppear` (`:54-58`) — including the nilable `current: World?` — is scaffolding for the missing observability, and its header comment says as much.
- **~90 lines of clone-stamped persistence.** Twelve identical `didSet`-guard-persist blocks and twelve identical read-or-default `init` stanzas (`Settings.swift:14-224`). Every new setting costs ~16 copied lines.

**Fix:** mark `Settings` `@MainActor @Observable`; bind pickers straight to it (`@Bindable var settings = Current.settings`), delete `SelectionStore` and the onAppear copying; the stale-pill bug disappears. Collapse storage with one generic private helper pair, e.g. `read(_ key:, default:)` + `persist(_ key:, _ value:)` over a `RawRepresentable<String>` constraint (Region/Difficulty/sorts are all string-backed; Int/Bool/Date get tiny adapters). `SettingsTests`/`SettingsViewTests` keep passing; `GetterSetter` stays the seam.

## 12. `Quiz` internals: impossible optionals, 13 copy-pasted cyclers, double shuffle · **code health**

`Models/Quiz.swift` works (and is now well-covered by `QuizTests`), but it fights itself:

- `settings`/`gameCenter` are stored as optionals and then `fatalError`-guarded (`:53-54`, `:95-97`, `:302-304`) even though the initializer always sets them — make them non-optional `let` and delete three crash paths.
- The 13 identical cycling accessors + parallel index vars (`:26-51`, `:414-516`, ~130 lines) are one abstraction: a tiny `Cycler` struct (`mutating func next() -> Element`, wrap + shuffle-on-start). Quiz then holds `var regularAr = Cycler(VerbFamilies.regularArVerbs)` etc., and `start()`'s 13-line shuffle block (`:104-116`) and 12-line index-reset block (`:119-130`) collapse to one loop.
- `questions.shuffled().shuffled()` (`:272`) — one shuffle is already uniform.
- `process()`'s `default: fatalError()` (`:337-339`) crashes the app if the engine ever returns `.failure` for a quiz slot. After item 2's guard test this is "can't happen" — but prefer degrading gracefully (skip the question, log) over crashing a learner mid-quiz.

Pure refactor; `QuizTests`' six region/difficulty score invariants are the safety net (consider running it with `shouldShuffle: false` for deterministic coverage — see item 19).

## 13. Retire or consolidate the legacy UIKit appearance layer · **code health / UI correctness**

Two remnants configure UIKit appearance in ways that are either inert or misplaced on iOS 26:

- `AppDelegate.configureTabBar/configureNavBar` (`AppDelegate.swift:31-40`) set `barTintColor` and `titleTextAttributes` — pre-iOS-13 appearance APIs that modern (`UI*Appearance`-based, Liquid-Glass) bars largely ignore. The nav-bar line even builds `NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue)` — a no-op round-trip. Meanwhile every screen already styles itself in SwiftUI.
- `SettingsView.init` mutates **global** `UISegmentedControl.appearance()` (`SettingsView.swift:31-34`) — a side effect that runs every time the struct is created (each `MainTabView` body evaluation) and silently themes every segmented control app-wide from a view initializer.

**Fix:** verify on-simulator what each line actually changes on iOS 26 (screenshot with/without via the `ios-build-verify` skill). Keep what's needed, but move it to one place (`AppDelegate.didFinishLaunching`) using the non-deprecated appearance APIs — or better, replace with SwiftUI-side styling and delete. `Colors`' UIKit bridge shrinks accordingly.

## 14. Launch-path main-actor work: verb-map parse + widget snapshot · **performance**

`MainTabView.task` (`MainTabView.swift:41-46`) calls `WidgetSnapshotWriter.refresh()`, which — on the MainActor, since a nonisolated sync function runs on its caller's executor — parses `verbModelMap.xml` (231 KB, 4,816 elements) on first `VerbMap.shared` touch, sorts the ~1,000 ranked verbs, runs ~50 engine conjugations, encodes JSON, writes the App Group file, and calls `WidgetCenter.reloadAllTimelines()`. It runs again on **every** foreground activation (`:50`). Two cheap wins, no behavior change:

- The writer's own doc comment says it exists to be run off-main: wrap the call sites in `Task.detached { WidgetSnapshotWriter.refresh() }` (everything it touches is `nonisolated`/`Sendable`), keeping post-launch taps responsive while the map parses.
- Skip the rewrite + timeline reload when the existing snapshot's `dateString` already matches today (`WidgetSnapshotWriter.swift:47-50` → read-before-write) — `reloadAllTimelines` on every activation spends WidgetKit's refresh budget for content that changes once a day.

Related, lower priority: `VerbView` precomputes its ~130 forms in `init` (fine), while `ModelView.gridCell` re-conjugates its 36 grid slots on every body evaluation (`ModelView.swift:128-169`) — cache them in `init` for consistency. And `ModelInfo.all` (`ModelInfo.swift:39-62`) conjugates ~13k slots to score 102 exemplars on first Models-tab visit; fine one-time, but worth knowing it's there before adding to it.

## 15. Tutor service: an every-5-seconds-forever poll · **efficiency**

`LanguageModelServiceReal.init` (`LanguageModelServiceReal.swift:45-53`) starts an unconditional infinite loop — wake every 5 s, re-check `SystemLanguageModel.availability` — for the entire app lifetime, on every launch, even when the user never opens the Info tab, and it keeps polling after availability settles. It exists so the Info-tab row flips live, which only matters while that screen is visible.

**Fix:** poll only while someone is looking — start/stop from `InfoBrowseView.onAppear/onDisappear` (or `.task` on the tutor section, which auto-cancels), and/or stop once `.available` is observed. Also fold item 6's per-instance tool counter into this file's cleanup pass.

## 16. Audio: two owners of the shared `AVAudioSession` with conflicting configs · **UX**

`Utterer.setup` sets category `.playback` **with** `.mixWithOthers` at launch (`Utterer.swift:20-27`); `SoundPlayer`'s lazy `init` later sets `.playback` **without** it (`SoundPlayer.swift:23`, comment: "was ambient"). Whichever runs last wins on the *shared* session — in practice the first quiz chime re-configures the session and **stops the user's podcast/music**, and (`.playback`) sounds also play through the silent switch. For feedback chirps in a study app, that's usually the wrong contract.

**Fix:** one audio-session owner, configured once at launch; decide the contract deliberately (`.ambient` = respect silent switch and mix — the likely intent for chimes; keep speech working with it). Replace the `print`s with `Logger`. While there: `Utterer`'s `SoundPlayer.play(.silence)` workaround (`Utterer.swift:42`) cites a 2016 forum thread — verify it's still needed on iOS 26, and `Utterer.settings` + `fatalError` (`:30-32`) can become a non-optional injected default. (`Int.random(in: 0...count-1)` → `randomElement()` in `SoundPlayer:51-61` while passing.)

## 17. Adopt the iOS 18+ `Tab` API and unify tab iconography · **modernization**

`MainTabView` uses `.tabItem` (`MainTabView.swift:21-38`), soft-deprecated since iOS 18 in favor of `Tab(_:image:value:) { }` builders — on an iOS-26-only app there's no reason not to move (it also unlocks the newer tab-bar behaviors and reads cleaner with `AppTab` as the selection value). While there: four tabs use custom PNG assets ("Browse", "Quiz", "Info", "Settings") while Models uses an SF Symbol (`key.fill`) — on the iOS 26 tab bar the mismatch is visible. Pick SF Symbols for all five (e.g. `book`, `key.fill`, `graduationcap.fill`, `info.circle`, `gearshape`) and delete the bitmap assets, or supply the missing custom glyph.

## 18. Browse/detail rows aren't buttons, and Spanish forms lose their speech language · **accessibility**

- List rows navigate via `.onTapGesture` (`VerbBrowseView.swift:114-123`, `ModelBrowseView.swift:66-68`, `ModelView.swift:65-71`): no `.isButton` trait, no press highlight, weaker VoiceOver semantics. `VerbBrowseView`'s rows can be plain `NavigationLink(value:)` (its `navigationDestination` already handles `String`); `ModelView`'s closure-based design keeps working with a `Button` wrapper.
- The UIKit app marked conjugations with `accessibilitySpeechLanguage` es (the now-dead `setAccessibilityLabelInSpanish`). The SwiftUI screens set no speech language, so VoiceOver reads *hablo* with English pronunciation rules. `AttributedString(...).languageIdentifier`/`accessibilitySpeechLanguage` on the conjugation `Text` (or `.accessibilityLabel(Text(attributed))`) restores it — a real win for a language-learning app. The `.speakOnTapFlash` tap targets should also expose an accessibility action name.

## 19. Test-suite depth: pin linguistic truth, drop tautologies, make the quiz run deterministic · **tests**

The engine suites are excellent (oracle-pinned, exhaustive). The app-layer tests are thinner:

- **Add the `VerbFamilies`↔`VerbMap` guard test** (item 2) and a handful of golden-form quiz-slot tests (hand-written expected strings for, say, 20 (verb, tense, person) triples drawn from the quiz lists) so quiz content is pinned to *Spanish*, not to the engine's own output.
- `SettingsViewTests.initializationProducesABody` asserts `settingsView.body is (any View)` (`SettingsViewTests.swift:22`) — true by construction. Keep the instantiation (it's a crash smoke test) but drop the vacuous `#expect`, or assert something real via the store.
- `QuizTests` runs with `shouldShuffle: true` (`QuizTests.swift:36`), so which verbs each 50-question run exercises is random — a bad list entry can dodge CI for weeks (this is exactly how `manecer` survived). Use `shouldShuffle: false` (the fixture Worlds already do) or iterate both.
- After item 1, add `GameCenter`-flow tests around the corrected gating logic (the fake already exists; also note `GameCenterFake.authenticate` returns `false` when *already* authenticated — surprising semantics worth straightening while touching it).

## 20. Micro cleanups · **polish (grab-bag)**

Small, independent; batch them opportunistically:

- **Localization:** the catalog contains a junk `""` key (auto-extracted from unlabeled `Picker(""...)`/`TextField(""...)`); use explicit empty labels (`Text(verbatim:)` / labeled initializers) and delete it. `RatingsFetcher.swift:51` hardcodes the Spanish exhortation `" ¡Sé la primera o el primero!"` outside the catalog — deliberate flavor or not, it belongs in `L`/xcstrings so the decision is visible to translation.
- **`RatingsFetcher`:** callback + `JSONSerialization` → `async`/`await` + `Codable`; surface the error case (today the Settings row silently stays empty).
- ✅ **`ConjugationResult.compare`** (`ConjugationResult.swift:27`) folds `á é í ó ú` but not `ü`, so *averigue* vs *averigüé* scores `noMatch` instead of `partialMatch`. Add `("ü","u")` (leave `ñ` strict — it's a distinct letter).
- **`AppRouter.handle`** uses soft-deprecated `url.host` (`AppRouter.swift:33`) → `url.host()`.
- **Build settings:** the widget target lacks `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` that app+test set — add for consistency.
- **Entitlements:** `aps-environment: development` is present but nothing registers for push; if the CloudKit commun fetch stays poll-at-launch, drop it (one less provisioning variable).
- **`SecondSingularQuiz`/`SecondSingularBrowse`** use display strings (`"Tú"`) as persisted raw values — works, but renaming a label would silently reset user prefs; worth a comment or decoupling if ever touched.
- **`DisplayPersonNumber.pronoun`** pairs `él` (3s) with `ellas` (3p) (`DisplayPersonNumber.swift:28,34`) — if the mixed-gender pairing is deliberate, a comment would stop it reading as a typo.
- **Style:** the diacritic identifiers (`viewContröller`, `scöre`, `identifīer`, `delegāte`, the flag-emoji constant in `AnalyticsLocale.swift:24`) are charming but hostile to search and code review — consider retiring them as files get touched (the `AnalyticsService` protocol's string-constant *requirements* can become one private enum when TelemetryDeck lands).

---

## Proposed implementation phases

Ordered so every step ships green (build + 403 tests + lint), bugs land before refactors, and refactors before modernization. Each step is a natural commit (or two) on `migration`, with a `docs/blog_notes.md` note per chunk.

1. ✅ **Data + one-liner bug fixes** *(items 2, 5, 7, 8, 9, plus item 20's `ü`)* — fix `VerbFamilies` (manecer/helar/esconder), add the VerbFamilies↔VerbMap guard test, invert `InfoView`'s width conditional, POSIX/UTC (or epoch) date storage + call-time `now` + injected settings in the review prompter, FNV seed + DST-safe midnight in the widgets, numeric version compare in `CommunGetterReal`. Small, independent, high confidence — do first while the tree is quiet.
2. ✅ **Dead-code purge** *(item 10)* — one sweeping deletion commit + CLAUDE.md correction. Zero behavior change; shrinks everything after it (and removes files later steps would otherwise have to edit).
3. ✅ **Game Center rewrite** *(item 1, folding in the relevant bits of items 19 and 10)* — the gate fix, the once-set `authenticateHandler`, top-VC presentation, protocol cleanup (`UIViewController` out, `parentViewController` deleted), leaderboard-ID await, SwiftUI failure alert, fake-backed tests. Verify on a physical device (simulator Worlds use the fake). *(Done: `authenticate()` is fire-and-forget with a set-once handler; the gate is a pure, unit-tested `GameCenterPrompt.decision`; login sheet presents via `UIApplication.topViewController()`; `World.parentViewController` + `UIViewController` protocol dependency + the dead `UIAlertControllerExtension` are gone; leaderboard ID is lazy-loaded/cached with logged failures. Following the cited Konjugieren port, the detached-VC failure alert is replaced by `os.Logger` + GameKit's own sheet rather than a new modal. **Still needs a physical-device pass** for the live sign-in flow.)*
4. ✅ **Settings observability** *(item 11, then item 4)* — `@Observable Settings`, delete `SelectionStore`, collapse the persistence boilerplate; then move became-active analytics to `scenePhase` and delete the dead delegate methods. (Doing 4 after 11 keeps all Settings churn in one window.) *(Done: `Settings` is `@MainActor @Observable`; the stale-pill bug is fixed for free via Observation tracking; `SettingsView` binds pickers to `Current.settings` through `@Bindable` and `SelectionStore` + its `onAppear` copy-in are deleted; the ~90 lines of `didSet`/`init` boilerplate collapse into `static` `read`/`persist` helper families; `recordBecameActive()` now rides `MainTabView`'s `scenePhase == .active` observer and the dead `AppDelegate` lifecycle stubs are gone. Build green, 411 tests / 0 failures, SwiftLint clean.)*
5. **View-layer hygiene** *(items 3, 13, 14)* — browse filtering into `onChange` state + sound out of `body`; appearance config consolidated/retired after on-simulator verification; snapshot refresh off-main + date-gated; `ModelView` grid cached in `init`.
6. **Quiz + services internals** *(items 12, 15, 16, 6)* — `Cycler`, non-optional dependencies, single shuffle, graceful `process` failure; tutor poll scoped to visibility + per-instance tool counter; single audio-session owner with an explicit category decision.
7. **Modernization + accessibility + polish** *(items 17, 18, 19-remainder, 20)* — `Tab` API + unified icons, row semantics + Spanish speech attributes, golden-form tests + deterministic `QuizTests`, and the micro grab-bag.

Steps 1–2 are a comfortable afternoon; step 3 is the one requiring device time; steps 4–7 are each independently shippable. After step 7, the remaining known debt is the deliberate kind: the planned TelemetryDeck `AnalyticsServiceReal`, and the widget's richer large-size content once Spanish etymology/example data exists.
