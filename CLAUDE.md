# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Conjugar is an iOS app for learning Spanish verb conjugations. It conjugates regular and irregular Spanish verbs in all tenses with quiz mode (3 difficulty levels), verb browsing, tense information, and Game Center integration.

**Developer:** Josh Adams (vermontcoder@gmail.com), who released the app in 2017.
**Target:** iOS 26+ (raised from 17 in July 2026 to match Konjugieren, ahead of the SwiftUI migration). **Universal (device family `1,2`)** as of 2026-07-15 — the app target was iPhone-only (family `1`, running letterboxed in iPad compatibility mode) until the round-2 review's item 8 surfaced it; it's now a native iPad app. The per-screen iPad-layout audit/fix is round-2 review **item 15** (tracked, done in separate sessions like the sibling apps Conjuguer/Konjugieren). `Info.plist`'s `UISupportedInterfaceOrientations~ipad` already allows all four iPad orientations.
**Language:** Swift 6 language mode, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (see **Concurrency model** below)
**License:** GNU Affero General Public License

As of 2026, a project is underway to modernize and improve Conjugar. The engine migration is **done**: the app conjugates exclusively through the new `Conjugator` engine (4,811 verbs from `verbModelMap.xml`, all 16+ tenses — regular and irregular verbs, homonyms, defectives, prefixed compounds, with compound tenses composed in-app by `CompoundTense` and the UI's `DisplayTense`/`DisplayPersonNumber` vocabulary mapped by `TenseBridge`). Browse Verbs is an all-verbs list sortable by Frequency/Alphabetical. Every screen is now a native SwiftUI view (`Views/`), the app shell is a `MainTabView` `TabView`, and no `UIViewController` subclass remains in the app target. A **Spanish conjugation tutor** backed by Apple's on-device `SystemLanguageModel` (Foundation Models) was added July 2026 — a chat screen reached from the Info tab, grounded in the app's own engine so it never invents forms (see **Conjugation Tutor** below). The modernization/improvement work lives in this folder, /Users/josh/Desktop/workspace/Conjugar.mig . Commits in this folder should be pushed to the migration branch. Eventually, the migration branch will be folded into Conjugar's master branch.

As you, Claude, complete chunks of work on the modernization/improvement project, append
a note to docs/blog_notes.md. Give each entry a `##` heading that includes the date —
`## <Title> (YYYY-MM-DD)` — with newest entries at the bottom (the earliest entries use
a leading `## YYYY-MM-DD — <Title>` form; write new ones in the trailing form). Write
narrative for a future reader (what
was tried, what failed, why decisions changed), not a bare changelog: Josh will
eventually generate blog posts from these notes, and future Claude sessions rely on them
as dated project memory — when older docs conflict, the journal shows which truth is
current.

When you create a new plan (typically in the `prompts/` folder), open it in Visual Studio
Code so Josh can read it immediately: `code <path-to-plan>` (the VS Code CLI binary is
`code`).

## Build and Test Commands

This is an Xcode project (project `Conjugar.xcodeproj`, scheme `Conjugar`). Build and
test go through the **`ios-build-verify`** Claude Code skill, which pipes `xcodebuild`
through `xcbeautify` (concise output, raw `build.log` fallback) and disables parallel
testing. The per-project config lives at `.claude/ios-build-verify.config.sh` (sourced
by every script; hand-editable). The skill is installed via Claude Code's plugin
marketplace; a stable symlink (`~/.claude/skills/ios-build-verify`) points at the
versioned cache so the terminal path survives plugin updates.

```bash
# Build the app — this is the COMPILE step
~/.claude/skills/ios-build-verify/scripts/build_app.sh

# Run all tests
~/.claude/skills/ios-build-verify/scripts/run_tests.sh

# Run a single test suite
~/.claude/skills/ios-build-verify/scripts/run_tests.sh --only-testing ConjugarTests/ConjugatorTests

# Run a single test method (Swift Testing — note the trailing, shell-escaped parentheses)
~/.claude/skills/ios-build-verify/scripts/run_tests.sh --only-testing ConjugarTests/ConjugatorTests/oirPresent\(\)

# Lint
swiftlint
```

The skill also drives the running app in the simulator (launch, tap, screenshot, verify)
— see **Running the App in the Simulator** below. Its full operation surface is documented
in `~/.claude/skills/ios-build-verify/SKILL.md`.

> **Diagnostic fallback — raw `xcodebuild`.** When `xcbeautify`'s lossy filter drops an
> early-stage error, or the skill scripts are unavailable, the underlying commands still
> work directly. Prefer the skill scripts so future sessions exercise them.
>
> ```bash
> xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' build
> xcodebuild -project Conjugar.xcodeproj -scheme Conjugar -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test -only-testing:ConjugarTests/ConjugatorTests/oirPresent\(\)
> ```

> **`-only-testing:` format — the suite is mixed.** The path is `Target/Suite/method`. Do **not** include filesystem subdirectories (`Models/`, `Utils/`). The engine suites (`ConjugatorTests`, `ConjugatorAccessorsTests`, `ConjugatorResolverTests`, `VerbMapTests`, `TenseBridgeTests`) the migrated service suites (`SettingsTests`, `GetterSetterRealTests`, `ReviewPrompterRealTests`, `GameCenterFakeTests`), and the SwiftUI-migration suites (`InfoTests`, `ConjugationTextTests`, `QuizTests`, `SettingsViewTests`) use **Swift Testing**, so a method name must end in `()` (e.g. `oirPresent()`, shell-escaped as `oirPresent\(\)`) — omitting it makes xcodebuild silently run zero tests. The remaining lower-level suites like `ConjugationCellTests` / `RatingsFetcherTests` are still **XCTest**, whose method names take **no** parentheses (e.g. `testConjugationCell`). New tests should be Swift Testing — see **XCTest + MainActor: the isolated-deinit crash** below.
>
> **The `Suite` segment is the Swift *type* name, never the `@Suite("…")` display name.** `struct GameBossTests` decorated `@Suite("GameBoss")` is selected as `ConjugarTests/GameBossTests` — passing the display string `ConjugarTests/GameBoss` matches **nothing**, and (same failure mode as an omitted `()`) xcodebuild prints **`Test Succeeded` while running zero tests**. This is the single most dangerous test-runner trap here: a green run that tested nothing. **Always confirm real execution by the count line** — Swift Testing prints `✔ Test run with N tests in M suites passed` (its own reporter; the XCTest summary's `Executed 0 tests … passed` is only the XCTest half and says nothing about Swift Testing). `run_tests.sh` echoes that `Test run with N tests …` line when tests run, so its **absence after a `--only-testing` filter means the selector matched nothing** — treat that as a failure, not a pass, and re-check the suite is spelled as its type name.

## Running the App in the Simulator

To launch and drive the built app (screenshots, taps, verifying UI behavior — not just
tests), use the **`ios-build-verify`** skill. It was verified end-to-end against Conjugar
in July 2026 (build → launch → per-tab tap-and-screenshot). It wraps the `simctl`
lifecycle plus **AXe** for observation and HID dispatch.

```bash
S=~/.claude/skills/ios-build-verify/scripts
"$S/build_app.sh"                 # COMPILE (launch_app.sh does NOT compile — run this first)
"$S/launch_app.sh"                # install last build + launch; polls FIRST_SCREEN_ID for render
"$S/screenshot.sh" my-label       # PNG into docs/screenshots/ (pixels, 3× — AXe taps use points)
"$S/tap_tab.sh" settings          # tap a main-tab by name (browse | models | quiz | info | settings)
"$S/describe_ui.sh" --point 200,540   # inspect the element under a logical-points coordinate
```

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
Every actor is a rendered cel-shaded sprite now — no numbered placeholder boxes remain. The
**dancer** has eight actions (`idle`/`walk`/`climb`/`jump`/`cape`/`capeWalk` from the climb,
plus `ole`/`stomp` for the boss dance-off) and the **bull** has six (`idle`/`walk`/`throw`
from the climb, plus `stomp`/`rear`/`bow` for the boss); the **matador** is a static
front-facing `Image("matador")`. During the climb, hold a direction button to walk, tap jump,
hold up at a ladder to climb, etc. Example hold-and-capture (logical points;
right arrow ≈ `131,767`):

```bash
axe touch -x 131 -y 767 --down --up --delay 2.5 --udid "$UDID" &   # hold right ~2.5 s
sleep 1.1; "$S/screenshot.sh" walking                              # capture mid-walk
```

**Freeze-framing a fast animation (jump apex, climb/cape pose).** The game loop honors two
**launch environment variables**, both default-off so **normal play is unaffected** —
`CONJUGAR_GAME_TIME_SCALE` scales the loop's `dt` (`0.2` = 5× slow, `0.1` = 10×, so a
~0.5 s jump lasts several seconds and is trivially screenshot-able) and
`CONJUGAR_GAME_DISABLE_FLAGS` stops the bull throwing obstacles (a calm field; the var keeps
its legacy `FLAGS` name as a documented contract). They're read via
`ProcessInfo` in `GameState` (`debugTimeScale` / `debugFlagsDisabled`). `openurl` can't pass
env, so launch the process **with** them, then route via the deeplink:

```bash
APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/Conjugar-*/Build/Products/Debug-iphonesimulator/Conjugar.app | head -1)
xcrun simctl terminate "$UDID" biz.joshadams.Conjugar 2>/dev/null; xcrun simctl install "$UDID" "$APP"
SIMCTL_CHILD_CONJUGAR_GAME_TIME_SCALE=0.2 SIMCTL_CHILD_CONJUGAR_GAME_DISABLE_FLAGS=1 \
  xcrun simctl launch "$UDID" biz.joshadams.Conjugar
sleep 2; xcrun simctl openurl "$UDID" conjugar://game
```

To reach the climb state, the D-pad **up** button only appears when the player is aligned at
a ladder base — poll `describe_ui.sh` for the `Move up` label to know you're on it.

### The main game — La Subida (the five-stage climb)

The climb is a full five-stage game (`prompts/game_la_subida.md`), split across
`GameState+Obstacles.swift` (the rolling obstacle sets — formerly `GameState+Flags.swift`),
`GameState+Stages.swift` (stages, escape beats, soft respawn), `GameState+PowerUps.swift`,
and `GameState+Mechanics.swift`. Key facts:

- **Five stages** (`stage` 1…5, invariant `stage == summitCount + 1`). Each stage has its own
  **obstacle set** (flags → animals → balls → vehicles → sky, `stageObstacleEmojis`) and a
  **render style** (`ObstacleStyle`: `.spin` for flags/balls, `.face` — upright but mirrored to
  face its travel — for animals/vehicles, `.upright` for sky). Obstacle speed compounds
  **+5 %/stage** (`obstacleSpeed = obstacleRollSpeed · 1.05^(stage−1)`). The `Flag`→`Obstacle`
  rename swept the whole family (`flags`→`obstacles`, `spawnFlag`→`spawnObstacle`, …); only the
  `CONJUGAR_GAME_DISABLE_FLAGS` env var + `debugFlagsDisabled` keep their **legacy names**
  (documented external contract).
- **Escape beats (summits 1–4).** Touching the bull on a non-final stage enters
  `GamePhase.escape` (`enterEscape`/`updateEscape`): the bull flees upward carrying the matador
  off-screen, then `advanceToNextStage` rebuilds the field (fresh set/speed/pickups, hearts
  refilled, **"¡Nivel N!"** banner + applause). The **5th** summit triggers the boss.
- **No lose state.** At 0 health the player **soft-respawns** (`respawn()`) at the bottom of the
  current stage with full health — `stage`/`summitCount`/`score`/collected pickups persist; a
  brief `respawnGrace` follows. `reset()` (a full restart to stage 1) is only for the
  configure path now, not death.
- **Power-ups (one kind per stage, `PowerUpKind`).** Drawn from a no-repeat shuffle bag
  (`powerUpBag`, through `bossRNG`): **cape** (invuln + smash, `Image("cape_pickup")`), **speed
  ⚡** (walk + climb ×2, `Sound.speedWhoosh`, a ⚡ badge over the dancer), **La Serenata 🎸** (the
  bull stops pacing/throwing and dances the end-scene repertoire instead, `Sound.guitarStrum`,
  `Sound.snort` on expiry). All share the cape's 7 s (5 solid + 2 blink) envelope.
- **Challenge mechanics (one per stage, `ChallengeMechanic`).** Also a no-repeat bag
  (`mechanicBag`); a scheduler fires the stage's mechanic after a random 10–18 s, then re-arms
  every 25 s. Announcements ride the jaleo idiom as **bull speech** (`spawnBullSpeech`).
  - **zombie** — 3 s; every obstacle slows to ½ speed and homes on the player (it keeps its own
    emoji — no 🧟 swap; `relevel`-re-integrates onto girders when the window ends).
    `Sound.zombieGroan`.
  - **encierro** — 4 s; 🐂 `Charger`s stampede across the girders at 2× obstacle speed (the
    window's first charger targets the player's girder). `Sound.stampede`.
  - **apagón** — 3.5 s; the lights cut to a near-black overlay with a soft spotlight tracking
    the dancer (an `apagonDim` envelope + a `compositingGroup`/`.destinationOut` mask in
    `GameView`); HUD/controls stay lit. `Sound.lightsOut` in, `Sound.pop` on a natural end.

The five new SFX (`guitarStrum`, `speedWhoosh`, `zombieGroan`, `stampede`, `lightsOut`) are
Pixabay MP3s bundled in `Conjugar/Audio/`, logged in `asset-licenses/pixabay-mpg-sfx.txt`.

**Debug env vars** (read via `ProcessInfo`; compose with `CONJUGAR_GAME_TIME_SCALE` /
`CONJUGAR_GAME_DISABLE_FLAGS` and the `conjugar://game` launch pattern above):

- `CONJUGAR_GAME_STAGE=N` (1…5) — start the climb at stage N (`summitCount = N−1`).
- `CONJUGAR_GAME_POWERUP=cape|speed|serenata` — force every stage's power-up draw.
- `CONJUGAR_GAME_MECHANIC=zombie|encierro|apagon` — force every stage's mechanic draw AND
  shorten its countdowns to ~2 s for fast verification.

### The boss fight — La Llamada (`GameState+BossFight.swift`)

Summiting (touching the bull) triggers a call-and-response flamenco **dance-off** (see
`prompts/game_boss_llamada.md`): the bull dances a phrase move-by-move (cue chips accumulate),
the player echoes it from memory on a morphed dance pad while a compás bar sweeps, and a
6-notch **Duende meter** (banked phrases) is both a tug-of-war and the fight's progression —
banked 0–1 round 1 (length 3), 2–3 round 2 (length 4), 4–5 round 3 (length 5, with a 🔥
**freeze** fake-out where the correct input is *nothing*), 6 → victory → an end scene on
`Music.onboarding`. Failure slides the meter back a notch and rerolls a fresh phrase; there is
**no lose state**. All boss logic is in `GameState+BossFight.swift` (`update(currentTime:)`
routes every non-`.climb` phase to `updateBoss`); the climb pipeline is byte-identical when
`phase == .climb`. Hearts are hidden off-climb (the meter is the only currency). Six dance
moves (`DanceMove`): paso left/right, ole, stomp, cape, freeze. Each move's pad-button/cue-chip
glyph is single-sourced by `DanceMove.glyph` and rendered by `GameView.moveIcon`; the olé
glyph is the custom **`ole`** symbol (`Assets.xcassets/ole.symbolset` — a solid arms-up-V
dancer silhouette derived from the `dancer_ole_3` sprite, on the same SF-template scaffold as
the `dancer`/`bull` symbols, so it tints and font-scales like a system symbol). Boss buttons
fire on touch-down (the jump idiom), not held intents. Strings live in `L.Game` — the jaleo shouts and
title cards stay Spanish in **both** localizations, the narrative line + a11y labels localize
en/es.

Debug entries jump straight into the boss (all compose with `CONJUGAR_GAME_TIME_SCALE` for
freeze-framing the `stomp`/`rear`/`bow`/`ole` bursts):

- **`conjugar://game/boss`** deeplink — `AppRouter.handle` sets `pendingBossEntry`, consumed by
  `GameView` after configure to call `enterBossIntro()`.
- **`conjugar://game/end`** deeplink (and the **`CONJUGAR_GAME_START_END=1`** env var) — jumps
  all the way to the **end scene** (couple reunited, bull bowing on a random cadence,
  hearts/roses flying up, onboarding music) via `debugJumpToEndScene()`, the fast path for
  tuning the end-scene loop.
- **`CONJUGAR_GAME_START_BOSS=1`** launch env var — jumps to `.bossIntro` on configure. Its
  companion **`CONJUGAR_GAME_BOSS_BANKED=N`** (0…5) pre-fills the Duende meter, so `=5` starts
  one phrase from victory (the fast path for verifying the win / end-scene beats without
  grinding all six phrases). `openurl` can't pass env, so launch **with** the vars, then route:

```bash
SIMCTL_CHILD_CONJUGAR_GAME_START_BOSS=1 SIMCTL_CHILD_CONJUGAR_GAME_BOSS_BANKED=5 \
  xcrun simctl launch "$UDID" biz.joshadams.Conjugar
sleep 2; xcrun simctl openurl "$UDID" conjugar://game    # tap to skip the intro, then echo the phrase
```

The **end scene is a living loop**, not a still: two seconds in, the dancer turns right to face
the matador sliding in from her pedestal; once he reaches her, the freed **bull breaks into a
dance** — every 2 s it performs a randomly-chosen animated move (`endSceneDanceMoves` = walk /
stomp / rear / bow / throw, walk danced *in place* so its position never changes) and moos
(`Sound.moo`) every 4–8 s — while hearts/roses fly up from the couple every 2–4 s (random). The
Duende meter is hidden the moment the player wins (`GameState.hasWon`). There is no "tap to
continue" prompt (removed July 2026 as noise — any tap still dismisses).

### Game music (`Music` enum + `SoundPlayer`)

The game's looping background music is the `Music` enum (`Models/Music.swift`), each case a
bundled MP3 base name that `SoundPlayerReal.startMusic(_:)` loops via `numberOfLoops = -1`.
Gameplay plays `Music.gameLoop` from `GameState` — bundled as `flamencoLoop.mp3` (legacy
name) but holding Pond5's "Flamenco Adventure" since July 2026. This one file sits at the
target root (`Conjugar/flamencoLoop.mp3`), **not** in the `Conjugar/Audio/` group. Two more
Pond5 tracks *are* in the synchronized `Conjugar/Audio/` group: `spanishTension.mp3`
(`Music.onboarding`, wired into both the onboarding flow — see below — and the boss fight's
end scene) and `spanishGuitarStandoff.mp3` (`Music.bossFight`, now wired: it crossfades in on
the boss intro's llamada and loops the duel, then fades out into `Music.onboarding` at the end
scene). The WAV masters
live in git-ignored `audio-sources/`; only the 192 kbps MP3s are committed. Pond5's Content
License requires no attribution (the game-music credit in `Localizable.xcstrings` is a
courtesy note).

> **Onboarding music.** The onboarding flow (`Views/OnboardingView.swift`, added July 2026 —
> see **Onboarding** below) plays `Music.onboarding` (Pond5's "Spanish Tension",
> `Conjugar/Audio/spanishTension.mp3`) as a looping bed: `Current.soundPlayer.startMusic(.onboarding)`
> on the view's `.onAppear`, faded out on dismiss via `Current.soundPlayer.stopMusic(fadeDuration:)`
> (the graceful counterpart to `startMusic`'s fade-in; the plain `stopMusic()` hard-stop is still
> what the climb uses). The same track now also scores the boss fight's **end scene**, faded in as
> `Music.bossFight` ("Spanish Guitar Standoff") fades out on victory — and `GameState.stopAudio()`
> fades (rather than hard-stops) when the player exits from `.endScene`.

Conjugar-specific config facts baked into `.claude/ios-build-verify.config.sh`:

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
- `analytics: Analytics` - TelemetryDeck-backed usage analytics (see **Analytics (TelemetryDeck)** below)
- `gameCenter: GameCenter` - Game Center integration
- `reviewPrompter: ReviewPrompter` - App Store review prompting
- `settings: Settings` - User preferences (wraps UserDefaults)
- `languageModelService: LanguageModelService` - the on-device conjugation tutor (see **Conjugation Tutor** below)
- `getterSetter: GetterSetter` - shared string key-value store (same instance `Settings` wraps); the tutor persists chat history through it

### Analytics (TelemetryDeck)

Adopted July 2026, replacing the no-op spy that stood in for the long-removed AWS
Pinpoint integration and converging Conjugar on the schema the sibling apps Conjuguer
and Konjugieren already use. Files: `Analytics/Analytics.swift` (the `Analytics`
protocol plus the `AnalyticsName` / `ParameterKey` enums), `AnalyticsReal.swift`,
`AnalyticsSpy.swift`.

- **Event names are an enum, not strings.** `Current.analytics.signal(name: .viewVerbView)`;
  parameters are `[String: String]` keyed by `ParameterKey.…rawValue`. The old
  Pinpoint-shaped `AnalyticsService` (`recordEvent(_:parameters:metrics:)` plus a dozen
  `record*` wrappers and umlaut-disambiguated key vars like `scöre`) is gone. **A raw
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
  TestFlight and App Store builds go to the live view with no code change. Delivery was
  confirmed end-to-end in July 2026.
- **No `becameActive` signal.** TelemetryDeck records launches and sessions itself, and
  reports app version, device model, and country/language natively — which is why the
  `AnalyticsLocale` abstraction that fed the old event a locale parameter was deleted.

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
> Because the protocol and all its conformers share a prefix, they **sort together in Xcode's Project Navigator** — the point of the convention (and consistent with the `CatFancy-final` app). One type per file, filename = type name. **Check for a system-API collision** before settling on the protocol name: the since-deleted `AnalyticsLocale` was so named because a plain `Locale` shadowed `Foundation.Locale` module-wide. Wire the real conformer into `World.device` and the double into `World.simulator` / `.unitTest` / `.uiTest`.

### View Architecture

**All SwiftUI**. The UI lives in `Conjugar/Views/`
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
cornerRadius = 12). The `@UsesAutoLayout` property wrapper and the rest of the UIKit
layout/font stratum (`Fonts`, `StringExtensions.conjugatedString`, `UsesAutoLayout`, the
`titleLabel`/`pulsate`/`yellowfyText` helpers) were deleted in the July 2026 post-migration
dead-code purge; screen layout is all SwiftUI. The only UIKit that remains is appearance
config in `AppDelegate` and a shrinking set of service-seam extensions.

The mapped UI audit that drove the migration is `docs/conjugar-ui-issues.md`.

### Tab Structure (`MainTabView`)

1. **Verbs** — `VerbBrowseView` → `VerbView` (the tab was labeled *Browse* / *Explorar* until August 2026, when it was renamed **Verbs** / **Verbos** to match Konjugieren and Conjuguer; only the displayed label changed — `VerbBrowseView`, the `L.BrowseVerbs` scope and its catalog keys, the `.viewVerbBrowseView` analytics case, the `browse_verb_count` anchor, and `tap_tab.sh browse` all keep their names)
2. **Models** — `ModelBrowseView` → `ModelView` (→ `VerbView`)
3. **Quiz** — `QuizView` → `ResultsView`
4. **Info** — `InfoBrowseView` → `InfoView` (and → `TutorView`, the conjugation tutor, from a section at the top of the list)
5. **Settings** — `SettingsView`


### Onboarding

A first-launch welcome tour ported from Conjuguer (July 2026), styled to Conjugar's yellow
design system. Files: `Views/OnboardingView.swift`, the `OnboardingDisplay` kill switch in
`Models/ConjugarTips.swift`, `Settings.hasSeenOnboarding`, `L.Onboarding` +
`Localizable.xcstrings` (`Onboarding.*`). Things to know:

- **A paged `.fullScreenCover`** (`TabView(.page)` with auto page-dots). Sheets: a welcome
  sheet using the custom **`bull`** symbol, four content sheets (Browse/Models/Quiz/Articles,
  each keeping its CTA → tab), a **conditional AI-tutor sheet** shown only when
  `Current.languageModelService.isAvailable` (so never in the simulator), and a **game-preview
  sheet** using the custom **`dancer`** symbol whose CTA launches the game. The final sheet
  shows the animated **"Get Started"** button below the dots; the top-right button reads
  **Skip** (first run) / **Dismiss** (reshow).
- **Presented from two places.** First launch: `MainTabView` trips `router.showOnboarding` once
  in its launch `.task`, gated by `!Settings.hasSeenOnboarding` **and**
  `OnboardingDisplay.onboardingEnabled` (the screenshot kill switch, mirroring
  `TipDisplay.tipsEnabled`; the Settings "Show Onboarding" reshow ignores it). Reshow:
  `SettingsView`'s onboarding card presents it with `isReshow: true`, which does **not** touch
  the flag. Music `Music.onboarding` plays on appear and **fades out** on dismiss.
- **`AppRouter` is passed in explicitly, not via `@Environment`.** A `.fullScreenCover`'s
  content does not inherit a custom `.environment(router)` object (a direct tab child does), so
  `OnboardingView`/`SettingsView` take an explicit `router:` — reading it from the environment
  in the cover traps with "No Observable object of type AppRouter found". Tab-navigation CTAs
  set `router.selectedTab` (and `router.pendingTutor` for the tutor, consumed by
  `InfoBrowseView`); the game CTA defers to each cover's `onDismiss` so two covers never overlap.

### Core Models

- **Conjugator.swift** (+ the feature-file family, `ModelCatalog`, and `VerbMap`) - The conjugation engine: composition of feature rules over a book-class model catalog, resolving each verb's model from `verbModelMap.xml` (4,811 verbs). The app UI conjugates through it via `TenseBridge` (maps the UI's `DisplayTense`/`DisplayPersonNumber` vocabulary to `EngineTense`, the simple-tense-plus-person slots the engine consumes) and `CompoundTense` (composes perfect tenses as *haber* + participle, and imperativo negativo as "no" + subjunctive — the engine itself models only simple tenses). The legacy `Conjugator`/`verbs.xml` engine was removed in July 2026; `DisplayTense.swift`/`DisplayPersonNumber.swift` (formerly `Tense.swift`/`PersonNumber.swift`) remain as the UI's vocabulary, covering the full displayed tense set including compounds.
- **Quiz.swift** - A `@MainActor @Observable` quiz state model (scoring, closure-based timer, difficulty levels), observed directly by `QuizView`/`ResultsView`. The old `QuizDelegate` was removed in the SwiftUI migration.
- **Settings.swift** - User preferences with GetterSetter protocol abstraction.

### Conjugation Tutor (on-device LLM)

A Spanish conjugation tutor, ported from the sibling app Conjuguer (French) and adapted for
Spanish (July 2026). It is a chat screen (`Views/TutorView.swift`) backed by
`LanguageModelServiceReal`, which wraps Apple's **on-device** `SystemLanguageModel` /
`LanguageModelSession` from the **Foundation Models** framework. Reached from a section at the
top of the Info tab (`InfoBrowseView`). Files: `Models/LanguageModelService.swift` (protocol
+ `TutorMessage` + `LanguageModelUnavailability`), `LanguageModelServiceReal.swift`,
`LanguageModelServiceDummy.swift`, `TutorChatHistory.swift`, `Views/TutorView.swift`,
`Views/TutorTestView.swift`. Things to know when working on it:

- **Grounded, never hallucinated.** The model is given one `Tool` (`ConjugationTool`, in
  `LanguageModelServiceReal.swift`) that looks up real forms through the app's own engine —
  `VerbMap.shared.entry(for:)` to validate the verb, then `TenseBridge.conjugate(...)` per
  person. Because the whole engine is `nonisolated`, the tool's `nonisolated` `call` invokes
  it directly (no `@MainActor` hop; the French original needed one). A tolerant
  `displayTense(forName:)` maps a Spanish **or** English tense name onto `DisplayTense`,
  most-specific compound/subjunctive phrases first so "presente de subjuntivo" isn't swallowed
  by "presente". Marked forms are lowercased to strip the red-irregularity UPPERCASE encoding
  before they reach the model.
- **Prompt is localized by *system language*, not the UI locale.** `LanguageModelServiceReal`
  holds two hand-written instruction blocks and picks Spanish when
  `Locale.current.language.languageCode == "es"`, English otherwise — this steers what
  language the model *answers in*, independent of the `.xcstrings` UI localization. **If you
  change tutor behavior, edit both blocks.**
- **Over-refusal workaround.** The on-device model sometimes refuses conjugation content, so
  `sendTutorMessage` retries up to 3× with a fresh session and screens replies through
  `isLikelyRefusal` (English + Spanish canned-refusal phrases); a persistent refusal falls
  back to `L.Tutor.unableToAnswer`.
- **Availability is live.** The service polls `SystemLanguageModel.availability` every 5 s and
  is `@Observable`, so the Info-tab section flips itself between a tappable `NavigationLink`
  (→ `TutorView`) and a reason row (the "Apple Intelligence not enabled" reason deep-links to
  Settings). **In the simulator the model is unavailable**, so the tutor screen isn't even
  reachable there — the chat and the `TutorTestView` batch harness can only be *exercised* on
  a real Apple-Intelligence device.
- **`TutorTestView`** is a batch harness (runs ~30 Spanish/English queries, one per fresh
  session, `ShareLink`-exports the results) reached by a **triple-tap on the tutor's title**.
  It is deliberately **not** behind `#if DEBUG` — it ships. Its hardcoded strings use
  `Text(verbatim:)` to stay out of the string catalog.
- **iOS 26 only.** The Foundation Models types are guarded `@available(iOS 26, *)` +
  `#if canImport(FoundationModels)`, but since the deployment target is already iOS 26 the
  service is instantiated unconditionally in `World`. Editing this code trips a swarm of bogus
  SourceKit "only available in macOS 26 / cannot find type" diagnostics — all stale-index
  noise; trust `xcodebuild`, which compiles it cleanly.

## Testing

Tests are in `ConjugarTests/` organized by layer:
- `Analytics/`, `Controllers/`, `Models/`, `UIViews/`, `Utils/`, `Views/`

Test infrastructure:
- The test environment is selected in `World.chooseWorld()` (a simulator process with the
  XCTest runtime loaded gets `World.unitTest`) — the SwiftUI `@main App` lifecycle replaced
  the old custom `main.swift`/`TestingAppDelegate` selection during the migration.
- `URLProtocolStub` for network mocking
- Test doubles (`AnalyticsSpy`, `GetterSetterFake`, `GameCenterFake`) for isolation

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
> **Status (July 2026):** a full `xcodebuild … test` run is **TEST SUCCEEDED** (all XCTest
> + Swift Testing, 0 failures). The general rule still stands, since MainActor default
> isolation remains: a new pure-Swift `@MainActor` object deallocated by XCTest will hit the
> same double-free — so **write new tests in Swift Testing.**

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
