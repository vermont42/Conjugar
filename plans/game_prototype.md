# Plan — Conjugar Game Prototype (placeholder art, pure SwiftUI)

**Goal:** stand up a playable, placeholder-art prototype of the Donkey-Kong-inspired
flamenco/bull game, launched from the Settings tab, to lock in the *feel* (platforms,
ladders, gravity, jump, buttons, flag "barrels", cape power-up) and — critically — to
**prove the frame-animation machinery** before any real art exists. No real sprites, no
sound. This is a fresh-session task; read the context below first.

## Read first (in this order)
1. `prompts/game.md` — the game spec (Donkey-Kong mechanic, flamenco dancer, bull,
   flags-as-barrels, capes-as-hammer, 5-ascent + final fight *(out of scope here)*).
2. `docs/game_design_research.md` — the architecture decision and rationale. This
   prototype implements **§2 (Recommended architecture)** and **§2.3 (Donkey-Kong
   specifics)**. Stack is **settled: pure SwiftUI** (§2.2 — no SpriteKit).
3. **Reference implementations** in the sibling apps (same house architecture Conjugar
   adopts). Skim, don't copy blindly:
   - Controls / press-and-hold buttons: `/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/Views/GameView.swift`
     (`arrowButton`, `DragGesture(minimumDistance: 0)`) and `…/Models/Game/GameState.swift`
     (`updatePlayer`, intent booleans consumed as `speed·dt`).
   - Game loop: `/Users/josh/Desktop/workspace/Konjugieren/Konjugieren/Views/GameView.swift`
     (`TimelineView(.animation)` → `.onChange(of: timeline.date)`) and `…/Models/Game/GameState.swift`
     (`update(currentTime:)`, delta-time, `GameState+*.swift` split).

## Reference image
`~/Desktop/Kong.png` — the classic Donkey Kong 25m level: ~6 red sloped girders, blue
ladders (some broken), Kong + barrel-stack top-left, Pauline top-right, player bottom-left.
Match this **layout/feel** with SwiftUI drawing primitives (details in "Platforms &
ladders" below). Sloped girders are optional polish; horizontal beams are fine for the
prototype's collision.

---

## Scope

**In scope**
- Launch from the **Settings tab** via `.fullScreenCover` (like the siblings).
- Platforms + ladders drawn with **SwiftUI primitives** (`Rectangle`/`RoundedRectangle`/
  `Capsule`/`Path`), styled roughly like `Kong.png`, in **Conjugar's palette**.
- Player (flamenco dancer) with **placeholder numbered-frame animation** (see below),
  moved by a **4-direction D-pad + jump button** at the bottom-left.
- Bull on the top platform with **placeholder numbered-frame animation**; a **bullfighter
  emoji** beside it.
- Bull throws **flag "barrels"** (country emojis) that descend/roll down the platforms.
- **Cape power-up** (emoji) pickups that let the player smash flags.
- A **Quit button** (dismisses the cover). **Reaching the bull restarts** the level.

**Out of scope** (explicitly, per Josh)
- No sound, no music.
- No real sprite art (numbers stand in for animation frames).
- No win/lose *game-over*, no 5-ascent/bull-escape sequence, no final bullfight scene.
- **No scoring and no score label.**
- No Game Center, no analytics requirement (optional to add a `recordVisitation`, but not
  needed).

---

## Placeholder art — the point of the prototype

- **Player and bull "sprites" are their current frame number**, rendered as `Text("\(n)")`
  centered in a tinted rounded box. As an action plays, the number **cycles `1…n` and
  wraps** — so Josh can literally watch the flipbook index advance (walk cycles, freezes on
  idle, cycles differently while climbing, etc.). This is the exact index logic real sprite
  frames will later plug into (`Image(frames[i])` swaps in for `Text("\(i+1)")`).
  - Player box ≈ 44×60 pt, `Color.customRed` fill, white number. Bull box ≈ 72×72 pt,
    `Color.customYellow` fill (or a brown), dark number.
  - **Reasonable frame counts per action** (n): player — idle 2, walk 6, climb 4, jump 3,
    cape 4; bull — idle 2, walk 6, throw 5. (Pick these as constants; they're placeholders.)
  - `currentFrame = Int(phase * fps) % count + 1`, `fps ≈ 10` (RaceRunner's rate).
  - **Facing:** don't mirror the number (a mirrored "3" looks wrong). Indicate facing with
    a small `◀`/`▶` chevron overlaid at the top edge of the box, driven by
    `facing: CGFloat (±1)`.
- **Bullfighter:** a single scratch emoji beside the bull — e.g. `🤺` (fencer, closest to a
  matador) or `🧍`. One frame only.
- **Flags:** country emojis of Spanish-speaking nations — e.g.
  `🇪🇸 🇲🇽 🇦🇷 🇨🇴 🇵🇪 🇨🇱 🇻🇪 🇪🇨 🇬🇹 🇨🇺 🇧🇴 🇩🇴 🇭🇳 🇵🇾 🇸🇻 🇳🇮 🇨🇷 🇺🇾 🇵🇦`.
  Rendered as `Text(flag).font(.system(size: 28))`, cycled through the list for variety.
- **Cape power-up:** an appropriate emoji — `🧣` (scarf ≈ cape) or `🟥`. Pickups sit on a
  couple of mid platforms.

---

## Architecture & files

Follow the sibling house pattern (see `docs/game_design_research.md` §2.1/§2.4). **Models/
and Views/ are `PBXFileSystemSynchronizedRootGroup`s**, so new files auto-add to the target
— no `project.pbxproj` edit needed.

Create:
- `Conjugar/Models/Game/GameState.swift` — `@MainActor @Observable final class GameState`:
  all state, tuning constants (`static let`), lifecycle (`configure(screenSize:)`,
  `reset()`), and `update(currentTime:)`.
- `Conjugar/Models/Game/GameModels.swift` — value-type structs: `Platform`, `Ladder`,
  `Flag`, `CapePickup`, and `enum PlayerAction` / `enum BullAction`. (Player/bull state can
  live as fields on `GameState`, or as `Player`/`Bull` structs — your call.)
- `Conjugar/Models/Game/GameState+Physics.swift` — gravity, platform-snap, ladder climb,
  jump, horizontal move from intent booleans.
- `Conjugar/Models/Game/GameState+Flags.swift` — bull spawns flags on a timer; flag descent
  + roll; flag↔player and flag↔cape collisions.
- `Conjugar/Models/Game/GameState+Animation.swift` — per-action frame-count table + phase
  advance + `currentFrame` helper (returns the number to display).
- `Conjugar/Views/GameView.swift` — `GeometryReader → TimelineView(.animation) → ZStack`,
  the D-pad + jump + quit overlays, and all drawing.

The game loop mirrors the siblings exactly:
```swift
TimelineView(.animation) { timeline in
  gameField
    .onChange(of: timeline.date) { _, now in gameState.update(currentTime: now) }
}
```
`update(currentTime:)` computes its own `dt` (discard `dt <= 0` or `>= 1`, clamp to
`1/30` floor), then runs: move player → move flags → advance animation phases → resolve
collisions → check "reached bull". No fixed timestep.

---

## System specs

### Platforms & ladders (SwiftUI primitives, `Kong.png` feel)
- **6 platform levels**, level 0 = bottom (player start), level 5 = top (bull). Compute
  geometry from the `GeometryReader` size in `configure(screenSize:)`; store `[Platform]`
  and `[Ladder]` as rects.
- Platforms span most of the width; **stagger the ladders** so the player must traverse
  each level to find the next ladder (DK zig-zag). One (occasionally two) ladder per gap,
  at alternating x-positions. (Optional polish: alternate a slight girder slope and/or an
  end-gap per the reference; not required — horizontal beams keep collision trivial.)
- **Girder drawing:** a `RoundedRectangle`/`Rectangle` filled `Color.customRed`, ~14 pt
  tall, optionally overlaid with a faint repeating rung pattern (an `HStack`/`Path` of thin
  bars) to evoke the DK hatch.
- **Ladder drawing:** two vertical `Capsule`/`Rectangle` rails + a `ForEach` of thin
  horizontal rung `Rectangle`s, in `Color.customBlue` (or `.customYellow`).
- Background: `Color.customBackground` (black in dark mode — matches DK).

### Player + controls
- State: `x, y, velocityX, velocityY, facing, grounded, climbing, action, animPhase`,
  plus cape state (`capedUntil` or a countdown).
- **Controls, bottom-left**, using the Conjuguer idiom: each directional button is an
  SF-Symbol `Image` in a ~56–64 pt frame with `.contentShape(Rectangle())`, driven by a
  **`DragGesture(minimumDistance: 0)`** that sets an intent boolean on `.onChanged(true)` /
  `.onEnded(false)`. Lay them out as a **cross D-pad** (`arrow.up`/`down`/`left`/`right`)
  with a separate **Jump** button (`arrow.up.circle.fill` or `figure.jump`) beside it.
  - `movingLeft/Right` → horizontal `velocityX` intent (as in Conjuguer's `updatePlayer`).
  - `movingUp/Down` → only act when the player overlaps a ladder → climb.
  - **Jump is an impulse, not held:** on touch-down, if `grounded`, set
    `velocityY = -jumpImpulse`. A plain tap gesture is fine for jump.
- **Action derivation** (drives which frame-count to cycle): `climbing` → `.climb`;
  `!grounded` → `.jump`; `grounded && velocityX != 0` → `.walk`; else `.idle`. Advance
  `animPhase += dt` while the action is "moving" (freeze on idle if you like).

### Physics (`GameState+Physics.swift`)
- **Gravity** each tick when `!grounded && !climbing`: `velocityY += gravity·dt`.
- **Platform snap:** if the player is falling and its feet cross a platform's top while
  horizontally overlapping it, snap feet to the platform top, `velocityY = 0`,
  `grounded = true`. Otherwise `grounded = false`.
- **Ladders:** if the player's center-x is within a ladder's x ± tolerance and `movingUp`/
  `movingDown` is held, enter `climbing` (gravity off), move `y ∓ climbSpeed·dt`, clamp to
  the ladder's vertical span; exit `climbing` at the ends, or on jump/horizontal input.
- **Horizontal:** `x += velocityX·dt` from the intent booleans (both pressed cancels);
  clamp to the platform's/screen's x-range.

### Flags — the "barrels" (`GameState+Flags.swift`)
- The bull spawns a flag every ~2 s (play the bull's `.throw` cycle when it does).
- Flags **descend under gravity**; when a flag lands on a platform, give it a horizontal
  roll velocity; at the platform end (or at a ladder, optionally) it falls to the next
  platform. Continue to the bottom, then despawn. (Simple DK-barrel behavior.)
- **Flag ↔ player (AABB):** if the player is **caped**, destroy the flag; otherwise the
  flag costs the player **25 % health** (see below).
- **Flag ↔ cape-pickup:** n/a; capes are picked up by the player, not hit by flags.

### Cape power-up
- A `CapePickup` on ~2 mid platforms. Player overlap → consume it and set
  `caped` for ~8 s (show the cape emoji on/near the player while active). While caped,
  flag contact smashes the flag instead of damaging the player.

### Health & restart (4-pip health — CONFIRMED by Josh; the only status, and NOT a score)
- Player has **4 pips of health, −1 per flag hit** (25 % each), matching the spec's "each
  flag takes 25 %." Show it as **4 small pips/hearts** in a top-trailing corner — a status
  indicator, **not** a score label.
- **Reset triggers:** (a) health reaches 0 → `reset()` player to the bottom start; (b)
  **player reaches the bull** (AABB overlap on the top platform) → `reset()`. `reset()`
  returns the player to start, clears flags, restores all 4 pips, keeps platforms/ladders.

### Quit
- Top-leading **Quit** button (`xmark.circle.fill`) → `@Environment(\.dismiss)`. No score.

---

## Launch wiring (SettingsView)
Add a game section to `Conjugar/Views/SettingsView.swift` using its **existing helpers**
(`settingsCard`, `settingSection`, `TintedCapsuleButtonStyle`) — do **not** hand-roll a new
card style:
```swift
@State private var showingGame = false          // add near the other @State
// …a new card (or a section in actionsCard):
settingSection(icon: "figure.flamenco",         // or "gamecontroller.fill"
               tint: .customRed,
               heading: L.Game.title,
               description: L.Game.description) {
  Button(L.Game.play) { showingGame = true }
    .buttonStyle(TintedCapsuleButtonStyle(tint: .customRed))
}
// …on the NavigationStack/ScrollView:
.fullScreenCover(isPresented: $showingGame) { GameView() }
```
**Localization (follow the house convention — see CLAUDE.md "Localization"):** add an
`enum Game` scope to `Conjugar/Supporting/L.swift` (mirroring `enum Settings` at ~line 383)
with `title`, `description`, `play`, `quit`; add those keys with `en` + `es` values to
`Conjugar/Supporting/Localizable.xcstrings` (both `"state": "translated"`). Suggested:
`Game.title` = "Game"/"Juego", `Game.play` = "Play"/"Jugar", `Game.quit` = "Quit"/"Salir",
`Game.description` = a one-liner. **Edit `.xcstrings` values via `python3`, not the Edit
tool** (the ASCII-quote foot-gun), and validate with
`python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"`.

---

## Concurrency / conventions
- `GameState` is `@MainActor @Observable` (Conjugar's default isolation is `@MainActor`);
  entities are value-type structs. Nothing here needs `nonisolated`.
- Use `Layout.*` constants (`Conjugar/Utils/Layout.swift`) and the palette
  (`Color.customRed/Yellow/Blue/Green/Background/Foreground`). Design-system helpers like
  `.card()` live in `Conjugar/Utils/Modifiers.swift`.
- Portrait suits the tall platform stack; locking orientation is optional (Konjugieren locks
  via `AppDelegate.orientationLock` — not required for the prototype).

## Build, verify, test
- **Compile:** `~/.claude/skills/ios-build-verify/scripts/build_app.sh` (authoritative —
  ignore SourceKit "cannot find in scope" noise on view files).
- **Run it:** `…/launch_app.sh`, then use the skill to tap the **Settings** tab
  (`tap_tab.sh settings`) and the **Play** button, and `screenshot.sh` the game. Consider
  adding an `.accessibilityIdentifier("game_root")` (or on the player box) so a future
  `--verify-anchor` can confirm the game rendered. (The only existing a11y id is
  `browse_verb_count` on the Browse tab.)
- **Tests (optional but encouraged, Swift Testing — never XCTest, per CLAUDE.md):** a small
  `@MainActor @Suite` for the pure helpers — platform-snap math, ladder enter/exit,
  flag↔player AABB, and `currentFrame` wrapping (`1…n`). Add under `ConjugarTests/`.
- **Lint:** `swiftlint`.

## Definition of done
- From a running app: **Settings → Play** opens a full-screen game; **Quit** returns.
- The player moves with the D-pad, climbs ladders, jumps, and is stopped by platforms
  (gravity feels right).
- The **player's and bull's numbers visibly cycle** as they animate (the core validation).
- The bull throws **flag emojis** that fall/roll down; a **cape emoji** pickup lets the
  player pass through flags; a flag otherwise costs 25 % health.
- **Reaching the bull resets** the level. No sound, no score, no win/lose screen.
- Build is green, SwiftLint clean.

## Notes / gotchas
- Keep the frame-swap path identical to how real sprites will render, so swapping
  `Text("\(currentFrame)")` → `Image("dancer_walk_\(currentFrame)")` later is a one-line
  change. See `docs/game_design_research.md` §2.1 for the target snippet, and §2.2 for the
  "pre-decode frames once" performance note (irrelevant while frames are numbers, relevant
  the moment real art lands).
- Don't reach for SpriteKit/`SpriteView` (decision in §2.2). ZStack is more than enough for
  ~2 animated actors + a handful of flags.
