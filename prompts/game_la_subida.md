# Plan — Main game finalization: **La Subida** (five stages, power-ups, challenge mechanics)

Source ask: `prompts/main_game.md` (Josh, 2026-07). Suggestions researched and locked with Josh
on 2026-07-14 (power-up **La Serenata**; mechanics **El Encierro** + **El Apagón**; obstacle-set
assignment). This plan turns the single-screen climb into the full five-stage main game and wires
in the escape beats that `prompts/game.md` (decision 1) always called for. It complements
`prompts/game_boss_llamada.md` (the boss fight, DONE) and reuses its structure.

**Multi-session execution:** each Phase below is a session-sized unit that leaves the app
building, testing green, and committable to the `migration` branch. Do them in order; any phase
can be a fresh session (each has its own "read first" pointers). Build/test/drive via the
`ios-build-verify` skill per CLAUDE.md.

> **⚠️ DO NOT COMMIT OR PUSH until Josh says so (2026-07-14).** Josh tests each phase on a real
> device before it's blessed, and device testing may surface fixes. Leave completed work in the
> working tree — build green, tests green, blog note written — and **wait for Josh's explicit
> go-ahead** before running `git commit`/`git push`. (Phases 0 and 1 were committed before this
> rule; from Phase 2 on, hold all commits.) This overrides the "commit per phase" line in
> **Gotchas** below.

---

## Decisions (locked with Josh 2026-07-14 — do not relitigate)

1. **Five stages.** Josh's prompt calls them "levels"; in code call them **`stage`** (1…5) —
   "level" already means a platform/girder index (`playerLevel`, `Platform.level`). Same screen
   geometry every stage; what changes per stage: obstacle emoji set, obstacle speed, the stage's
   power-up kind, and the stage's challenge mechanic.
2. **Obstacle sets** (locked via AskUserQuestion; faces dropped):
   - Stage 1 — country flags (as today, `flagEmojis`)
   - Stage 2 — animals `🐎 🐖 🐑 🐐 🐄` (Konjugieren's zigzagger set)
   - Stage 3 — sports balls `⚽ 🏀 🎾 ⚾ 🏐 🏉`
   - Stage 4 — vehicles `🚗 🚕 🚌 🏎️ 🛵 🚜`
   - Stage 5 — clouds & sun `☀️ ⛅ ☁️ 🌧️ 🌩️ 🌪️`
   Exact emojis within a set are tweakable at implementation time (avoid plain `⚡` anywhere —
   it's the speed pickup). Apple's animal/vehicle glyphs face LEFT: those sets don't spin like
   barrels — they stay upright and mirror to face their travel (see **Per-set rendering** in the
   design spec; Josh 2026-07-14).
3. **Obstacle speed** +5% per stage, compounding: `flagRollSpeed × 1.05^(stage−1)`. Stage 1 =
   current speed. Applies at spawn and at every landing re-roll.
4. **Power-ups (3 kinds, one kind per stage):**
   - **Cape** (existing) — invulnerability + smash, 7 s (5 solid + 2 blink), `Image("cape_pickup")`.
   - **Speed `⚡`** — walk AND climb speed ×2, same 7 s + expiry-blink envelope as the cape.
   - **La Serenata `🎸`** — for the same envelope the bull stops pacing and throwing and
     **dances** (random bursts from the end-scene repertoire); obstacles already in flight keep
     rolling. Foreshadows the dance-off boss and the dancing-bull end scene.
5. **Challenge mechanics (3, one per stage):**
   - **Zombie attack** (Josh's spec): announcement, then for 3 s every on-screen obstacle slows
     to half speed and homes toward the player. **Obstacles keep their own emojis — no 🧟 swap
     (Josh explicit).**
   - **El Encierro**: for ~4 s, `🐂` chargers stampede horizontally across random girders at 2×
     the stage's obstacle speed. Jumpable; same damage/cape rules as obstacles.
   - **El Apagón**: for ~3.5 s the lights cut — near-black overlay with a soft spotlight
     following the dancer. HUD/controls stay lit. (DKC "Blackout Basement" lineage.)
6. **Random without repeats**: per-stage power-up kind and mechanic are drawn from **shuffle
   bags** (Konjugieren's `mechanicBag` idiom) that refill+reshuffle when empty, rolled through
   the injectable `bossRNG` so tests can script draws.
7. **No lose state in the climb**: at 0 health the player soft-respawns at the **bottom-left of
   the current stage with full health** (stage, `summitCount`, score, collected pickups persist;
   field cleared; brief damage grace). `Sound.randomSadTrombone` still plays.
8. **Summits 1–4 are escape beats**: the bull flees **upward** off-screen carrying the matador
   (per `prompts/game.md` decision 1 — the TODOs at `GameState+Physics.swift:133` and
   `GameView.swift:396` anticipate exactly this), then the next stage rebuilds: player back at
   start, bull/matador return, fresh obstacle set/speed/pickups, banner **"¡Nivel N!"** +
   applause, hearts refilled. **Summit 5 triggers the boss** (`summitsToBoss` → 5).
9. **Announcements** ride the existing jaleo-pop idiom as **bull speech** (spawn just below the
   bull, big type, gentle rise). Localization: the zombie line is a narrative sentence and
   localizes (en "Your obstacles are now zombies!" / es "¡Tus obstáculos ahora son zombis!");
   "¡El encierro!", "¡Apagón!", "¡Nivel %lld!" stay Spanish in BOTH locales (title-card policy —
   boss-plan decision 16).
10. **Sounds**: reuse `shieldActivate` (cape), `moo`, `snort`, `applause`, `sadTrombone`, `pop`,
    `chomp`, `soccerKick`; five NEW Pixabay SFX (already downloaded — see the table below).
    `tensionSting` stays boss-only.
11. **Speed pickup emoji is `⚡`**; serenata pickup is `🎸`; both rendered as `Text` glyphs at
    `capeSize`-ish scale (the cape keeps its rendered sprite).
12. Defaults chosen by Claude, cheap to change: hearts refill at each stage transition; active
    power-up timers carry across an escape beat but clear on death; a mechanic re-fires every
    ~25 s within a stage after a first random 10–18 s delay.

---

## New SFX (sourced from Pixabay 2026-07-14 — files already on disk)

Raw downloads are staged in git-ignored **`audio-sources/pixabay-mpg/`** (primary + one
audition alternate per slot). Pixabay Content License — commercial use OK, no attribution
required, don't redistribute raw files standalone.

| `Sound` case | Use | Primary (id · uploader · title) | Audition alternate |
|---|---|---|---|
| `guitarStrum` | Serenata pickup | 86108 · freesound_community · "intro_flameco3" (7.4 s → trim opening rasgueado ~2.3 s) | 299648 · AhmadMousaviPour · "4)Soleá Rasgueado (Flamenco stock)" (30.9 s) |
| `zombieGroan` | Zombie announcement | 450451 · DRAGON-STUDIO · "Zombie Groan SFX" (3.9 s → ~2 s) | 95051 · freesound_community · "Zombie Groan" (5.1 s) |
| `stampede` | Encierro window | 359257 · PWLPL · "Horses Galloping Sound Effect" (8.1 s → ~4 s) | 102046 · freesound_community · "Horses Galloping" (3.9 s) |
| `speedWhoosh` | Speed pickup | 118248 · StudioKolomna · "Fast Whoosh" (1.2 s, near as-is) | 352855 · Universfield · "Fast Swoosh 02" (1.2 s) |
| `lightsOut` | Apagón lights-cut | 48657 · freesound_community · "Turning down power" (2.8 s → ~1.6 s) | 386180 · DRAGON-STUDIO · "Power Off" (1.3 s) |

Detail-page URLs (for the license log):

- https://pixabay.com/sound-effects/musical-intro-flameco3-86108/
- https://pixabay.com/sound-effects/musical-4sole%C3%A1-rasgueado-flamenco-stock-299648/
- https://pixabay.com/sound-effects/horror-zombie-groan-sfx-450451/
- https://pixabay.com/sound-effects/horror-zombie-groan-95051/
- https://pixabay.com/sound-effects/nature-horses-galloping-sound-effect-359257/
- https://pixabay.com/sound-effects/nature-horses-galloping-102046/
- https://pixabay.com/sound-effects/film-special-effects-fast-whoosh-118248/
- https://pixabay.com/sound-effects/film-special-effects-fast-swoosh-02-352855/
- https://pixabay.com/sound-effects/film-special-effects-turning-down-power-48657/
- https://pixabay.com/sound-effects/film-special-effects-power-off-386180/

Also available for optional per-animal hit flavor (NOT in scope, see the end):
Konjugieren's `horse/pig/sheep/goat/cow.mp3` under
`../Konjugieren/Konjugieren/Assets/Sounds/` (same Pixabay-reuse pattern as
`asset-licenses/game-sounds-pixabay.txt`).

---

## Where the code is today (verified 2026-07-14)

- **`Conjugar/Models/Game/GameState.swift`** — tuning constants (`flagRollSpeed: 95`,
  `flagSpawnInterval: 2.0`, `capeDuration: 7`, `capeBlinkDuration: 2`, `maxHealth: 4`,
  `summitsToBoss: 1` with a raise-to-5 TODO), world/player/bull/boss state, `configure` /
  `buildLevel` / `reset()` / `update(currentTime:)` (routes every non-`.climb` phase to
  `updateBoss`), `startAudio()` (SFX warm-up + `GlyphWarmer` emoji pre-rasterization +
  `Music.gameLoop`), debug env vars (`CONJUGAR_GAME_TIME_SCALE`, `CONJUGAR_GAME_DISABLE_FLAGS`,
  `CONJUGAR_GAME_START_BOSS`, `CONJUGAR_GAME_BOSS_BANKED`, `CONJUGAR_GAME_START_END`).
- **`GameState+Flags.swift`** — bull AI (`updateBull`: pace + throw every 2 s with a low `moo`),
  `spawnFlag`, roll/fall pipeline (`updateFlags` — DK zig-zag via `rollDirection`/`dropX`),
  `resolveCollisions` (cape pickups → `capedRemaining`; flag hits → damage / cape-smash; **death
  currently calls `reset()`** — this is the branch the soft respawn replaces).
- **`GameState+Physics.swift`** — movement/climb (`playerSpeed`/`climbSpeed` consumed here),
  `jump()`, `checkReachedBull()` (**the escape-beat TODO branch**: non-final summits currently
  `reset()` + applause).
- **`GameState+Animation.swift`** — flipbook tables + `derivedPlayerAction()` (isCaped → cape
  poses) and `derivedBullAction()` (`throw`/`walk` only — serenata hooks in here).
- **`GameState+BossFight.swift`** — `enterBossIntro` (guards `phase == .climb`, clears field:
  `flags.removeAll()` etc.), `updateBoss` (switch on phase), `commandBullMove(_:duration:)`,
  `spawnJaleo(_:x:y:size:riseRate:ttl:)`, `spawnPlayerSpeech`, `triggerScreenShake`, RNG idiom
  `randomElement(using: &bossRNG)` / `Double.random(in:using:&bossRNG)`.
- **`GameModels.swift`** — `Platform`/`Ladder`/`Flag`/`CapePickup`, `PlayerAction`, `BullAction`,
  `GamePhase { climb, bossIntro, duel, victory, endScene }`, `DanceMove`, `JaleoPop`,
  `SplitMix64` (seedable RNG for tests).
- **`Views/GameView.swift`** — render order inside the shaken playfield ZStack: platforms →
  ladders → cape pickups → flags → stage dressing → matador → bull → player → cue chips →
  jaleo pops; outside it: confetti, boss tap layer, quit button, `healthPips`
  (**shown only when `phase == .climb`**), boss cards, D-pad/jump controls. Matador escape-beat
  TODO at ~line 396.
- **`Models/Sound.swift`** — `CaseIterable`; game SFX at `Conjugar/` root (legacy) and
  `Conjugar/Audio/` (boss pack). New MP3s dropped in `Conjugar/Audio/` are auto-added
  (synchronized group — no pbxproj edit).
- **Tests** — `ConjugarTests/Models/GameStateTests.swift` (Swift Testing, `@MainActor`; drives
  `updatePlayer(dt:)` per-frame, asserts collisions/climb/cape; `reachingBullTriggersTheBossFight`
  assumes `summitsToBoss == 1` — **will need updating**), `GameBossTests.swift` (scripted phrases
  via `SplitMix64` seeds into `bossRNG`).
- **Localization** — `L.Game` in `Conjugar/Supporting/L.swift` + `Localizable.xcstrings` (both
  en/es, `state: translated`). Jaleos/title cards stay Spanish in both locales.
- **License logs** — `asset-licenses/pixabay-game-sfx.txt` is the format to copy (per-file id ·
  uploader · title · URL + processing note).

## Read first (any session)

1. `CLAUDE.md` — build/test/simulator commands, xcstrings foot-guns, Swift Testing rule.
2. This file, top to bottom.
3. `prompts/main_game.md` (the ask) and skim `prompts/game.md` decision 1 (escape beats).
4. The five game source files + `GameView.swift` (they're short).
5. `~/.claude/skills/ios-build-verify/SKILL.md` if driving the simulator.

---

## Design spec (authoritative)

### Stage system

- `var stage = 1` (1…`stageCount = 5`). Invariant during the climb: `stage == summitCount + 1`.
- Per-stage obstacle emoji table (order matches decision 2):

  ```swift
  static let stageObstacleEmojis: [[String]] = [flagEmojis, animalEmojis, ballEmojis, vehicleEmojis, skyEmojis]
  var stageEmojis: [String] { Self.stageObstacleEmojis[stage - 1] }
  ```

- Obstacle speed: `var obstacleSpeed: CGFloat { Self.flagRollSpeed * pow(Self.stageSpeedFactor, CGFloat(stage - 1)) }`
  — used by `spawnObstacle` AND the landing re-roll in `updateObstacles`.
- `startAudio()` glyph warm-up: warm **all five sets** plus `🐂`, `⚡`, `🎸` (cheap, ~40 glyphs).
- **Per-set rendering — spin vs facing (Josh 2026-07-14).** Apple's animal and vehicle emojis
  face LEFT, and the barrel spin would hide any facing, so each set declares a style:

  ```swift
  enum ObstacleStyle { case spin, face, upright }
  // flags    → .spin     (the barrel tumble, as today)
  // balls    → .spin     (they're balls — rotation is the point)
  // animals  → .face
  // vehicles → .face
  // sky      → .upright  (☀️/clouds have no facing; a spinning rain-cloud reads wrong)
  ```

  - `.spin` — current behavior: rotation accumulates from `velocityX`, view applies
    `rotationEffect`; no mirroring.
  - `.face` — upright, no rotation accumulation. Add `facing: CGFloat` to `Obstacle`, updated
    from the sign of each frame's horizontal motion (spawn roll direction, landing reversals,
    and the zombie drift all update it; a purely vertical fall keeps the last facing). View
    applies `scaleEffect(x: facing > 0 ? -1 : 1, y: 1)` — mirror when moving RIGHT, the same
    left-facing convention as the dancer/bull renders (`GameView.dancerMirror`).
  - `.upright` — no rotation, no mirroring.

  The `🐂` charger is also a left-facing glyph: mirror it by the same rule
  (`direction > 0` → `scaleEffect(x: -1)`).

### Escape beat (summits 1–4)

New `GamePhase.escape`, driven by a new `updateEscape(dt:)` in a new file
**`GameState+Stages.swift`** (bags, stage config, escape, respawn all live there).
`update(currentTime:)` routing becomes:

```swift
guard phase == .climb else {
  if phase == .escape { updateEscape(dt: dt) } else { updateBoss(dt: dt) }
  return
}
```

(Add a defensive `case .escape: return` to `updateBoss`'s switch; `handleBossTap` already has a
default.) Timeline of `enterEscape()` (called from `checkReachedBull`'s non-final branch, which
today calls `reset()`):

1. `phase = .escape`; clear input intents, obstacles, chargers, any active mechanic window
   (`apagonDim = 0`), `bullThrowTimer = 0` (mirror `enterBossIntro`'s field-clearing).
2. `Sound.randomApplause` + a `moo`; bull action `.walk`.
3. Each frame: `bullY -= escapeRiseSpeed * dt`; `bullfighterY` rises in lockstep (the bull
   carries him off — resolves the `GameView.swift:396` TODO). When both are fully above the top
   edge (y < −100):
4. `summitCount` already incremented; set `stage = summitCount + 1`, rebuild: player to start
   position, `health = maxHealth`, bull + matador restored to home spots, draw the stage's
   power-up kind + mechanic from the bags, re-arm pickups (`powerUps` rebuilt at the two spawn
   points with the new kind), reset `mechanicCountdown` to a fresh first-delay roll, banner
   `spawnJaleo(L.Game.nivel(stage), …, size: 44)` centered mid-field, `phase = .climb`.

Hearts visibility: change `GameView`'s condition to `phase == .climb || phase == .escape` so the
pips don't blink out during the beat.

### Soft respawn (death)

Replace the `reset()` call in `resolveCollisions`'s death branch with `respawn()`:

- keep: `stage`, `summitCount`, `score`, bags, assigned kind/mechanic, pickup collected-state,
  bull position/timers.
- reset: `health = maxHealth`; player to start position (bottom-left, the existing
  `w * 0.15` start); clear obstacles + chargers; cancel any active mechanic window and re-roll
  `mechanicCountdown` (first-delay range); clear `capedRemaining`/`speedRemaining`/
  `serenataRemaining`; `damageCooldown = respawnGrace`.
- `Sound.randomSadTrombone` (already played at the call site — keep exactly one play).

`reset()` (full rebuild) remains for `configure()`/boss-exit paths; since death no longer uses
it, it should now also zero `summitCount` and stage state (audit its callers — the "deliberately
keeps summitCount" comment was for the death path and is now stale).

### Power-up system

```swift
enum PowerUpKind: CaseIterable { case cape, speed, serenata }
struct PowerUp: Identifiable { let id: Int; let x, y: CGFloat; let kind: PowerUpKind; var collected: Bool }
```

- `CapePickup`/`capes` → `PowerUp`/`powerUps` (same two spawn points on platforms 1 and 3).
  A stage spawns ONLY its drawn kind (`stagePowerUpKind`, from `powerUpBag`).
- Collection effects (in `resolveCollisions`):
  - `.cape` → `capedRemaining = capeDuration`, `Sound.shieldActivate` (unchanged).
  - `.speed` → `speedRemaining = speedDuration`, `Sound.speedWhoosh`.
  - `.serenata` → `serenataRemaining = serenataDuration`, `Sound.guitarStrum`.
- **Speed**: `var speedFactorNow: CGFloat { speedRemaining > 0 ? Self.speedFactor : 1 }`;
  multiply into the walk line (`playerSpeed * speedFactorNow`) in `updatePlayer` and the climb
  line (`climbSpeed * speedFactorNow`) in `updateClimb`. Visual: a `⚡` badge floating just
  above the dancer (`Text("⚡")` positioned at `playerY − playerHeight`), with an
  `isSpeedBadgeVisible` mirroring `isCapeVisible`'s last-2 s blink (generalize the blink helper
  rather than copy-pasting it).
- **Serenata**: while `serenataRemaining > 0`, `updateBull` skips pacing AND the whole
  spawn-timer block (the bull stands and dances; no new obstacles; in-flight ones keep going).
  Dance bursts: a `serenataDanceTimer` rolls every `serenataDanceInterval`, calling the existing
  `commandBullMove(Self.endSceneDanceMoves.randomElement(using: &bossRNG) ?? .stomp, duration: danceBurstDuration)`;
  decrement `bullMoveTimer` in the climb path (it currently only ticks in the boss path) and
  make `derivedBullAction()` return the commanded action while `serenataRemaining > 0 &&
  bullMoveTimer > 0`, `.idle` between bursts, unchanged otherwise. On expiry: `Sound.snort`
  (the bull, annoyed, gets back to work). Timers tick next to `capedRemaining` in `update`.

### Challenge-mechanic framework

```swift
enum ChallengeMechanic: CaseIterable { case zombie, encierro, apagon }
```

- Per-stage `assignedMechanic` drawn from `mechanicBag` (same shuffle-bag as power-ups).
- Scheduler (ticks only in `.climb`): `mechanicCountdown` starts at
  `Double.random(in: mechanicFirstDelay, using: &bossRNG)`; at 0 → `startMechanic()` sets
  `activeMechanic = assignedMechanic`, `mechanicRemaining = <duration>`, fires the announcement
  (below) + sound; when `mechanicRemaining` hits 0 → `endMechanic()` cleans up and re-arms
  `mechanicCountdown = mechanicRepeatDelay`.
- Announcement helper `spawnBullSpeech(_ text: String)`: `spawnJaleo(text, x: bullX,
  y: bullY + bullSize, size: 30, riseRate: jaleoDriftRise, ttl: 2.0)` — the bull "speaks" like
  the dancer's boss jaleos, per Josh's prompt ("Note how speech is animated in the boss fight").

Per-mechanic behavior:

- **Zombie** (`zombieDuration = 3`, Josh's spec): announcement `L.Game.zombieAnnouncement` +
  `Sound.zombieGroan`. While active, `updateObstacles` bypasses the roll/fall state machine:
  each obstacle moves straight toward the player at `obstacleSpeed * zombieSpeedFactor` (0.5) —
  normalize `(playerX − x, playerY − y)`; `.spin` sets keep the cosmetic spin, `.face` sets face
  the drift direction. On end (or respawn-cancel),
  re-integrate each obstacle: `relevel(_:)` sets `level` to the nearest girder at/below its
  feet, `falling = true`, `velocityY = 0` (the existing landing code then re-rolls
  `velocityX`); obstacles below the bottom girder despawn. Cape still smashes on contact.
- **Encierro** (`encierroDuration = 4`): announcement `L.Game.encierroAnnouncement` +
  `Sound.stampede` (one ~4 s bed). New entity:
  `struct Charger: Identifiable { let id: Int; var x: CGFloat; let y: CGFloat; let level: Int; let direction: CGFloat }`
  rendered as `Text("🐂")` (flip horizontally by `direction` so it faces its travel). Spawns:
  every `chargerSpawnInterval` (0.8 s) during the window, pick a random girder from levels
  0…top−1 **biased to include the player's girder at least once per window**, spawn at the
  girder edge opposite its direction; speed `obstacleSpeed * chargerSpeedFactor` (2×), a quiet
  `snort` per spawn. Chargers run straight across (no falling) and despawn off-screen; window
  end stops spawning but lets stragglers finish crossing. Collision = obstacle rules (tight
  `chargerHitSize` box; cape → `chomp` smash; else damage + `soccerKick`).
- **Apagón** (`apagonDuration = 3.5`): announcement `L.Game.apagonAnnouncement` +
  `Sound.lightsOut`; `Sound.pop` when the lights return. State: `apagonDim` (0…1) fades in over
  `apagonFadeIn` (0.3), holds, fades out over `apagonFadeOut` (0.4) — drive the envelope in the
  update loop, no per-frame randomness. Render (in `GameView`, inside the shaken playfield
  ZStack, **after** the player/bull sprites but **before** `cueChips`/`jaleoPopViews`, so
  announcements float above the darkness and HUD/controls outside the group stay lit):

  ```swift
  if gameState.apagonDim > 0 {
    Color.black.opacity(GameState.apagonDimOpacity * gameState.apagonDim)
      .mask {
        ZStack {
          Rectangle()
          RadialGradient(colors: [.black, .clear], center: .center,
                         startRadius: GameState.apagonSpotlightRadius * 0.55,
                         endRadius: GameState.apagonSpotlightRadius)
            .frame(width: GameState.apagonSpotlightRadius * 2, height: GameState.apagonSpotlightRadius * 2)
            .position(x: gameState.playerX, y: gameState.playerY)
            .blendMode(.destinationOut)
        }
        .compositingGroup()
      }
      .allowsHitTesting(false)
  }
  ```

  Free depth: the bull's throw `moo` keeps firing in the dark — a sonar cue. Note the irony
  pairing when the stage-5 clouds/sun set rolls an apagón; no code needed.

Interactions (all "just work", but assert in tests): mechanics only tick in `.climb`; escape,
boss entry, and respawn cancel an active window (restore zombie obstacles via the same
`relevel` path, clear chargers, zero `apagonDim`); serenata + zombie may overlap (no new spawns,
existing obstacles still home); cape smashing works during every mechanic.

### New tuning constants (all `static let` on `GameState`, placeholder values — tune in Phase 6)

```swift
static let stageCount = 5
static let stageSpeedFactor: CGFloat = 1.05
static let speedDuration: Double = 7            // matches capeDuration incl. 2 s blink
static let speedFactor: CGFloat = 2
static let serenataDuration: Double = 7
static let serenataDanceInterval: Double = 1.2
static let escapeRiseSpeed: CGFloat = 260
static let mechanicFirstDelay: ClosedRange<Double> = 10...18
static let mechanicRepeatDelay: Double = 25
static let zombieDuration: Double = 3           // Josh's spec
static let zombieSpeedFactor: CGFloat = 0.5     // Josh's spec
static let encierroDuration: Double = 4
static let chargerSpeedFactor: CGFloat = 2
static let chargerSize: CGFloat = 30
static let chargerHitSize: CGFloat = 20         // honest hitbox, the flagHitSize rule
static let chargerSpawnInterval: Double = 0.8
static let apagonDuration: Double = 3.5
static let apagonFadeIn: Double = 0.3
static let apagonFadeOut: Double = 0.4
static let apagonDimOpacity: Double = 0.88
static let apagonSpotlightRadius: CGFloat = 120
static let respawnGrace: Double = 1.0
```

### Localization additions (`L.Game` + `Localizable.xcstrings`, both en/es `translated`)

| Key | en | es |
|---|---|---|
| `Game.nivel %lld` | `¡Nivel %lld!` | `¡Nivel %lld!` |
| `Game.zombieAnnouncement` | `Your obstacles are now zombies!` | `¡Tus obstáculos ahora son zombis!` |
| `Game.encierroAnnouncement` | `¡El encierro!` | `¡El encierro!` |
| `Game.apagonAnnouncement` | `¡Apagón!` | `¡Apagón!` |

Accessor style: `static func nivel(_ n: Int) -> String { String(localized: "Game.nivel \(n)") }`;
plain `static var` for the rest. Remember the xcstrings foot-guns (CLAUDE.md): no Edit-tool
changes near ASCII quotes; validate with `python3 -c "import json; json.load(open(...))"`.

### Debug hooks (env vars, `ProcessInfo` statics like the existing ones; document in CLAUDE.md in Phase 6)

- `CONJUGAR_GAME_STAGE=N` (1…5) — start the climb at stage N (sets `summitCount = N−1` +
  stage config at configure).
- `CONJUGAR_GAME_POWERUP=cape|speed|serenata` — force every stage's power-up draw.
- `CONJUGAR_GAME_MECHANIC=zombie|encierro|apagon` — force every stage's mechanic draw AND
  shorten the first delay to ~2 s (fast verification).
- All compose with `CONJUGAR_GAME_TIME_SCALE` / `CONJUGAR_GAME_DISABLE_FLAGS`
  (**keep the `DISABLE_FLAGS` name** even after the rename — it's a documented external
  contract) and the `conjugar://game` deeplink launch pattern from CLAUDE.md.

---

## Phase 0 — SFX pack: process, bundle, wire `Sound` cases  [Claude; Josh auditions]  ✅ DONE (2026-07-14)

**Complete.** All five primaries processed into `Conjugar/Audio/` at 192 kb/s / 44.1 kHz,
peak −1 dBFS (no alternate substituted — Josh auditioned and approved all five primaries);
`Sound` cases wired; `asset-licenses/pixabay-mpg-sfx.txt` written; build + 466 tests green;
blog note appended; committed to `migration` (b402022). See `docs/blog_notes.md`, "La Subida
Phase 0 — the SFX pack".

Small, standalone, everything later depends on it.

1. Process the five primaries from `audio-sources/pixabay-mpg/` into `Conjugar/Audio/`
   (192 kb/s, 44.1 kHz, stereo, peak −1 dBFS, trimmed + faded — the boss-pack recipe). Two-pass
   per file: measure `max_volume` with
   `ffmpeg -i in.mp3 -af volumedetect -f null - 2>&1 | grep max_volume`, then e.g.

   ```bash
   ffmpeg -i freesound_community-intro_flameco3-86108.mp3 -ss 0 -t 2.3 \
     -af "afade=t=out:st=2.0:d=0.3,volume=<(-1 − max_volume)>dB" \
     -ar 44100 -ac 2 -b:a 192k ../../Conjugar/Audio/guitarStrum.mp3
   ```

   Suggested windows (adjust by ear): guitarStrum `-ss 0 -t 2.3`; zombieGroan `-t 2.0`
   (fade 0.4); stampede `-ss 1.0 -t 4.0` (fade in 0.25, out 0.5); speedWhoosh as-is
   (silence-trim only); lightsOut `-t 1.6` (fade 0.3).
2. **Josh auditions** each processed file (`afplay Conjugar/Audio/guitarStrum.mp3` …). If one
   disappoints, process its alternate from the same folder and re-audition. Delete nothing from
   `audio-sources/` (masters stay).
3. Add the five cases to `enum Sound` with a comment block mirroring the boss pack's
   (`// La Subida — main-game SFX (Pixabay, Conjugar/Audio/)`). `CaseIterable` warm-up is
   automatic.
4. Create `asset-licenses/pixabay-mpg-sfx.txt` in the exact format of
   `asset-licenses/pixabay-game-sfx.txt`, using the per-file id/uploader/title/URLs from the
   table above (log which alternates, if any, shipped).
5. Verify: `build_app.sh` green; `run_tests.sh` green (nothing behavioral changed).

**DoD:** five MP3s in `Conjugar/Audio/`, `Sound` cases compile, license log written, build+tests
green, `docs/blog_notes.md` entry appended, committed to `migration`.

## Phase 1 — Rename, stage system, escape beat, soft respawn  [Claude]  ✅ DONE (2026-07-14)

**Complete.** Flag→Obstacle rename (file `GameState+Flags.swift`→`+Obstacles.swift`);
`stage` (1…5) driving per-stage emoji set, compounding speed, and `ObstacleStyle`
(spin/face/upright with `Obstacle.facing`); `summitsToBoss`→5; `GamePhase.escape` +
`GameState+Stages.swift` (`enterEscape`/`updateEscape` — bull+matador flee upward, both
escape-beat TODOs resolved); soft `respawn()` replacing the death `reset()`;
`CONJUGAR_GAME_STAGE` debug entry; `L.Game.nivel` + xcstrings. Ten new tests; build +
SwiftLint + all 476 tests green; committed to `migration` (bb8b748). Power-ups and
mechanics keep cape pickups / no mechanic until Phases 2–5. Simulator screenshots show the
new emoji sets as "?" tofu (known iOS-sim emoji bug — verify on device); geometry/actors/
escape render correctly. See `docs/blog_notes.md`, "La Subida Phase 1".

The foundation. Three commit-sized steps:

**1a — Rename `Flag` → `Obstacle`** (now that flags are 1 of 5 sets): `Flag`→`Obstacle`,
`flags`→`obstacles`, `flagCounter`→`obstacleCounter`, `flagSpawnTimer`→`obstacleSpawnTimer`,
`flagSize/flagHitSize/flagRollSpeed/flagSpawnInterval`→`obstacle…`, `spawnFlag`→`spawnObstacle`,
`updateFlags`→`updateObstacles`, file `GameState+Flags.swift`→`GameState+Obstacles.swift`
(synchronized folder — no pbxproj edit). Keep `flagEmojis` as the stage-1 set's name or fold it
into the stage table. **Do NOT rename** the `CONJUGAR_GAME_DISABLE_FLAGS` env var or the
`debugFlagsDisabled` doc contract (tooling references it) — a comment noting the rename is
enough. Compiler-guided; update `GameStateTests` + `GameView` references. Build + tests green
before moving on.

**1b — Stages.** New `GameState+Stages.swift`: stage state + emoji table + `obstacleSpeed`
multiplier (wire into `spawnObstacle` AND the landing re-roll), `summitsToBoss` → 5,
`GamePhase.escape` + `enterEscape()`/`updateEscape(dt:)` per the spec (resolve both escape-beat
TODOs — delete their comments), `checkReachedBull` non-final branch → `enterEscape()`, stage
banner + applause + moo, hearts refill, `healthPips` visibility includes `.escape`,
`CONJUGAR_GAME_STAGE`. Glyph-warm all sets. Implement `ObstacleStyle` + `Obstacle.facing` per
the **Per-set rendering** spec (view: `rotationEffect` only for `.spin`, mirror for `.face`). (Bags land in Phase 2/3; until then stage
transitions keep cape pickups and no mechanic.)

**1c — Soft respawn.** `respawn()` per the spec; death branch calls it; `reset()` caller audit
(zero `summitCount` there now; fix the stale comment).

Tests (extend `GameStateTests`, add a `GameStagesTests` suite if it reads better):
- speed multiplier: stage 1 == `flagRollSpeed`; stage 5 == `flagRollSpeed * 1.05^4` (±ε), and a
  landed obstacle re-rolls at the stage speed.
- stage emoji set selection per stage.
- per-set rendering: a `.face` obstacle's `facing` matches its spawn roll direction and flips at
  a landing reversal; `.spin` sets accumulate rotation; `.upright`/`.face` sets don't.
- summit at `summitCount < 4` → `.escape`, field cleared; escape completes → `stage` advanced,
  player at start, `health == maxHealth`, `phase == .climb`.
- 5th summit → `.bossIntro` (update `reachingBullTriggersTheBossFight` to pre-set
  `summitCount = 4`).
- respawn: health refilled, position bottom-left, stage/summitCount/score kept, obstacles
  cleared, power-up timers zeroed, `damageCooldown == respawnGrace`.

Verify in simulator (`ios-build-verify`): `CONJUGAR_GAME_STAGE=2..5` + `conjugar://game` —
screenshot each stage's obstacle set; drive a summit with `CONJUGAR_GAME_TIME_SCALE=0.2` and
screenshot the bull+matador mid-escape.

**DoD:** build+tests+`swiftlint` green, per-stage screenshots captured, blog notes appended,
committed.

## Phase 2 — Power-up system: speed ⚡ + La Serenata 🎸  [Claude; Josh plays]  ✅ DONE (2026-07-14)

**Complete.** `CapePickup`/`capes` → `PowerUp`/`powerUps` with `kind`
(cape/speed/serenata); `powerUpBag` no-repeat shuffle bag through `bossRNG`, assigned
in `reset()` (stage 1) + `advanceToNextStage()`; new `GameState+PowerUps.swift`. Speed
⚡ (`speedFactorNow` ×2 into walk + climb; ⚡ badge with generalized
`powerUpVisible(remaining:)` blink) and La Serenata 🎸 (bull dances `endSceneDanceMoves`
bursts instead of pacing/throwing — reuses `commandBullMove`, now internal; `snort` on
expiry). Decision 12 wired: power-ups carry across the escape beat, clear on death.
`CONJUGAR_GAME_POWERUP` override. Build + SwiftLint clean; 485 tests (7 new, 2 updated);
committed + pushed to `migration` (f7a89bc). Simulator confirms pickup placement; the
⚡/🎸 glyphs + serenata bull-dance are Josh's on-device check (sim renders single-scalar
emoji as "?" tofu). See `docs/blog_notes.md`, "La Subida Phase 2".

1. `CapePickup` → `PowerUp(kind:)`; `capes` → `powerUps`; view renders by kind (cape sprite /
   `Text("⚡")` / `Text("🎸")`).
2. `powerUpBag` shuffle-bag (`&bossRNG`), drawn per stage in the escape rebuild (+ initial
   configure); `CONJUGAR_GAME_POWERUP` override.
3. Speed + serenata effects, visuals, and sounds per the spec (incl. the generalized expiry
   blink, `bullMoveTimer` ticking in the climb path, `snort` on serenata end).
4. Tests: bag exhausts all three kinds before repeating (seeded RNG); speed doubles walk AND
   climb displacement while active and expires; serenata suppresses pacing/throwing (no new
   obstacles for its duration; `obstacleSpawnTimer` frozen) and the bull returns to `.walk`
   after; collecting each kind plays its effect (state-level assertions).
5. Simulator verify: force each kind, `TIME_SCALE=0.2`, screenshots — ⚡ badge on the dancer,
   bull mid-dance during serenata.

**DoD:** as Phase 1 (build/tests/lint/screenshots/blog/commit).

## Phase 3 — Mechanic framework + Zombie attack  [Claude; Josh plays]  ✅ DONE (2026-07-14)

**Complete.** `ChallengeMechanic { zombie, encierro, apagon }` + a new
`GameState+Mechanics.swift` owning the whole framework: a `mechanicBag` no-repeat shuffle
bag (through `bossRNG`), per-stage `assignedMechanic`, and a scheduler
(`updateMechanicScheduler`, ticks only in `.climb`) that fires once after a random
`mechanicFirstDelay` (10–18 s) then re-fires every `mechanicRepeatDelay` (25 s). Lifecycle
seams wired to match Phases 1–2: `reset()`/`advanceToNextStage()` draw a fresh mechanic;
escape, boss entry, and death-respawn all `cancelActiveMechanic()` (respawn re-arms). Zombie
attack live (obstacles home at half speed keeping their own emoji + spin/face style;
`relevel` re-integration onto the nearest girder below when the window ends);
encierro/apagón announce-only until Phases 4/5. `spawnBullSpeech` announcements (zombie line
localizes en/es; "¡El encierro!"/"¡Apagón!" stay Spanish both locales).
`CONJUGAR_GAME_MECHANIC` override. Build + SwiftLint clean; 494 tests (12 new); committed +
pushed to `migration`. Simulator confirms announcement/homing/recovery; the "?" tofu
obstacles are the known iOS-sim emoji bug (Josh's on-device check). See
`docs/blog_notes.md`, "La Subida Phase 3".

1. `ChallengeMechanic` + `mechanicBag` + scheduler + `spawnBullSpeech` + L strings
   (`zombieAnnouncement`, `encierroAnnouncement`, `apagonAnnouncement`, `nivel` — add all four
   now, one xcstrings edit) + `CONJUGAR_GAME_MECHANIC`.
2. Zombie behavior per the spec (homing drift, `relevel(_:)` re-integration, groan, cancel
   paths). Encierro/apagón cases announce but no-op until Phases 4/5 (bag draws still work —
   note the temporary no-op in a comment).
3. Tests: scheduler fires within the delay window and re-arms (tick `update` with scripted dt);
   bag no-repeat; zombie flips obstacle velocities toward the player at half speed; zombie ends
   after 3 s and obstacles land back on girders (`relevel` correctness: obstacle mid-gap →
   nearest girder below; below bottom → despawned); a `.face` obstacle's `facing` tracks the
   drift direction toward the player; respawn/escape/boss-entry cancel cleanly;
   announcements spawn a jaleo at the bull.
4. Simulator verify: `CONJUGAR_GAME_MECHANIC=zombie`, watch the announcement + homing +
   recovery; screenshot mid-zombie.

**DoD:** standard.

## Phase 4 — El Encierro 🐂  [Claude; Josh plays]  ✅ DONE (2026-07-14)

**Complete.** `Charger` entity (id/x/y/level/direction/despawn) + the whole stampede in
`GameState+Mechanics.swift`: `updateChargers(dt:)` (spawns on the 0.8 s interval only while the
window is open, then runs every charger straight across its girder at 2× the stage's obstacle
speed and culls off-screen ones), `spawnCharger` (the window's FIRST charger targets the player's
girder — a guaranteed threat via `encierroCoveredPlayerLevel` — the rest pick random girders
0…top−1), and `resolveChargerCollisions` (obstacle hit rules with the tight `chargerHitSize` box;
cape → chomp smash, else −1 pip + soccerKick gated by the cooldown, lethal → soft respawn; returns
a `Bool` so the caller bails after a respawn). End-vs-cancel diverges: a natural `endMechanic` lets
stragglers finish crossing, a cancel (escape/boss/respawn) clears them. Rendered `Text("🐂")`
mirrored by direction. Also (Josh mid-phase): the game is now pinned always-dark
(`.environment(\.colorScheme, .dark)` on `GameView`) so the `Color.custom*` assets never resolve
light. Build + SwiftLint clean; 503 tests (8 new encierro tests); committed + pushed to `migration`.
Simulator (`CONJUGAR_GAME_MECHANIC=encierro`) confirms the "¡El encierro!" announcement + chargers
crossing on a black background even in light mode; the "?"/red-shape tofu emoji are the known
iOS-sim bug (Josh's on-device check). See `docs/blog_notes.md`, "La Subida Phase 4 — El Encierro".

1. `Charger` entity + spawn/update/collision loops + window lifecycle + `stampede`/`snort`
   sounds + render (`Text("🐂")`, mirrored by direction) per the spec.
2. Tests: window spawns ≥1 charger on the player's girder; charger speed = 2× stage obstacle
   speed; crossing despawns off-screen; hit damages once (cooldown respected); caped contact
   smashes (charger removed, no damage); window end stops spawns but stragglers finish; jump
   clears a charger (the honest-hitbox test, mirroring `jumpClearingAFlagCostsNoHealth`).
3. Simulator verify: `CONJUGAR_GAME_MECHANIC=encierro` (+`TIME_SCALE`), screenshot the stampede.

**DoD:** standard.

## Phase 5 — El Apagón 💡  [Claude; Josh plays]

1. `apagonDim` envelope in the update loop; `lightsOut`/`pop` sounds; the spotlight overlay in
   `GameView` per the spec (verify layer order: obstacles/sprites darken, jaleo announcement
   and HUD/controls stay legible; overlay `allowsHitTesting(false)`).
2. Tests (state-level): envelope rises to 1, holds, returns to 0 on schedule; cancel paths zero
   it; scheduler re-arms.
3. Simulator verify: `CONJUGAR_GAME_MECHANIC=apagon`, screenshots dark + spotlight (this is the
   money shot — capture for the blog), confirm D-pad visibly lit and hearts legible.

**DoD:** standard.

## Phase 6 — Balance, polish, docs  [Claude + Josh on-device]

1. Full-game playthrough (Josh on device if possible; Claude in simulator): tune the constants
   table (speeds, delays, durations, dim opacity, spotlight radius) to taste. Check stage-5 +
   apagón and encierro-at-2× don't tip unfair — remember there's no lose state, only re-climb
   time.
2. Sweep stale comments/TODOs touched by this work (the two escape TODOs must be gone;
   `GameState.swift` header's "placeholder-art prototype" para is long stale — refresh it).
3. Docs: update CLAUDE.md's game section (five stages, power-ups, mechanics, new env vars,
   updated sound list) and append the capstone `docs/blog_notes.md` entry (narrative: research →
   Pixabay sourcing via Chrome → phased build).
4. Full `run_tests.sh` (all suites) + `swiftlint` + a final `build_app.sh`.
5. Commit + push `migration`.

**Definition of done (whole plan):** five stages with distinct obstacle sets and compounding
speed; escape beats 1–4 (bull + matador flee upward) and boss at summit 5; three power-ups and
three mechanics rotating with no repeats until exhaustion; zombie/encierro/apagón behave per
spec with announcements and SFX; death soft-respawns; all strings localized per policy; the five
new sounds bundled + licensed; tests cover every bullet above; CLAUDE.md + blog notes updated;
everything on `migration`.

## Not in scope (candidates for later prompts)

- Score HUD/persistence and Game Center for the game (existing roadmap item; `score` keeps
  accumulating silently).
- Per-animal hit sounds on stage 2 (copy Konjugieren's `horse/pig/sheep/goat/cow.mp3` — the
  `game-sounds-pixabay.txt` reuse pattern) — cute, cheap, optional.
- An Info-tab article documenting the game (Konjugieren precedent: `Info.gameText`).
- Onboarding game-preview copy mentioning five stages.
- Difficulty settings / obstacle-density scaling.

## Gotchas (learned the hard way — read before coding)

- **Swift Testing only** (isolated-deinit XCTest crash — CLAUDE.md). Suites touching
  `GameState` are `@MainActor`.
- `-only-testing:` paths are `Target/Suite/method()` with escaped parens, no subdirectories.
- **xcstrings**: never Edit near ASCII quotes; python3 for those edits; validate JSON after; Grep
  is useless inside it (single-line values).
- The game loop bans wall-clock randomness sources in view code; state randomness goes through
  `bossRNG` (`randomElement(using: &bossRNG)` / `Double.random(in:using:&bossRNG)`) so tests can
  seed `SplitMix64`. The escape/mechanic timers are dt-countdowns like every existing timer.
- `update` clamps dt to 1/30 s and multiplies by `debugTimeScale` — new per-frame logic must use
  the passed `dt`, never raw time deltas.
- Keep the `.climb` pipeline byte-identical when no new feature is active: zombie/serenata/etc.
  guard with `> 0` checks, not restructured control flow — the boss fight relies on the same
  discipline.
- `enterBossIntro` guards `phase == .climb`; `enterEscape` must guard the same way (a summit
  during `.escape` is impossible but cheap to assert).
- SourceKit will spray false "cannot find in scope" diagnostics while editing game files —
  `build_app.sh` is authoritative.
- AXe taps use logical points (divide screenshot pixels by 3); the D-pad's right arrow ≈
  `131,767`; hold-direction via `axe touch --down --up --delay`.
- New emoji must be glyph-warmed or the first spawn stutters (the flags lesson).
- The overlay/mask `compositingGroup` + `destinationOut` idiom is required — a plain overlay
  can't punch a soft hole.
- **Do NOT commit or push until Josh says so** (see the ⚠️ note at the top — he device-tests
  each phase first and fixes may be needed). Finish a phase in the working tree with a
  blog-notes entry per session (dated `##` heading, trailing-form title), then wait for his
  go-ahead before `git commit`/`git push` to `migration`.
