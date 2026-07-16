# Plan — Two new power-ups + two new mechanics (kill the per-run repetition)

## Why

The climb (`La Subida`) has **5 stages** (`stage == summitCount + 1`, stages 1…5), but the
power-up and challenge draws each come from a **no-repeat shuffle bag of only 3**
(`PowerUpKind` / `ChallengeMechanic`, both `CaseIterable`, both drawn via
`bossRNG.shuffled(...)`). A 3-item bag drawn 5 times gives a full shuffle for stages 1–3,
then reshuffles and hands out two more — so **every run guarantees two repeats in each
family**. Growing each bag to **5** makes bag-size == stage-count: each run becomes a clean
permutation — all five appear once, in **pure-random order** (no difficulty weighting, per
decision), zero repetition.

This plan adds **two power-ups** and **two challenge mechanics**, plus the small foundation
work to size the bags and the shared `Obstacle` fields the new effects reuse.

## How to work this plan (implementer instructions)

- **Implement all four items (plus the foundation) in one pass** — don't ship them one at a
  time. They share the F3 `Obstacle` fields and the same render/collision seams, so doing them
  together avoids reworking those seams four times.
- **Build and run the unit tests** (`build_app.sh` → `run_tests.sh`) and get them green.
- **Do NOT launch the app in the simulator.** Josh will ask Claude to hard-code a specific power-up + mechanic
  combination and play-test each himself, then give feedback. Skip the sim-verification steps
  below — they're reference for Josh's manual testing, not a step for the implementer.

---

## Naming

Existing cases: `PowerUpKind { cape, speed, serenata }`, `ChallengeMechanic { zombie, encierro, apagon }`.
The set already mixes English (`cape`, `speed`, `zombie`) with Spanish (`serenata`, `encierro`,
`apagon`); the flamenco/`por Amor` theme leans Spanish. Confirmed case names (the fallback
column is kept only as a reference to the English alternatives that were considered):

| # | Kind | Case | English alternative | Rationale |
|---|------|------|---------------------|-----------|
| 1 | Mechanic — earthquake | `terremoto` | `earthquake` | Matches `encierro`/`apagon` Spanish register |
| 2 | Mechanic — obstacles multiply | `camada` (a *litter/brood*) | `multiply` | Parents spawn babies |
| 3 | Power-up — heart missiles on jump | `flechazo` | `heartMissile` | *flechazo* = Cupid's arrow-strike / love-at-first-sight — literally heart-arrows |
| 4 | Power-up — mushroom chaser | `cortejo` (*courtship*) | `mushroom` | One obstacle courts/pursues another; they unite and vanish — on-theme for *por Amor* |

---

## Foundation (do first)

### F1 — Grow both bags to 5
- `Conjugar/Models/Game/GameModels.swift:83-85` — add `flechazo, cortejo` to `PowerUpKind`.
- `Conjugar/Models/Game/GameModels.swift:105-107` — add `terremoto, camada` to `ChallengeMechanic`.
- **No draw-logic change needed.** `drawStagePowerUpKind()` (`GameState+PowerUps.swift:48-54`)
  and `drawStageMechanic()` (`GameState+Mechanics.swift:33-39`) already do
  `allCases.shuffled(using: &bossRNG)` → `removeLast()`; a 5-item bag over 5 stages
  auto-yields a no-repeat permutation. (Fix the malformed `/`-comment lines at
  `GameModels.swift:65,99,123` while touching this file — cosmetic.)

### F2 — Debug env parsers (so each new item is force-testable)
- `debugForcedPowerUp` (`GameState.swift:249-256`): accept `flechazo` / `cortejo` for
  `CONJUGAR_GAME_POWERUP`.
- `debugForcedMechanic` (`GameState.swift:263-270`): accept `terremoto` / `multiply`(→`camada`)
  for `CONJUGAR_GAME_MECHANIC` (forced mechanics already shorten the countdown to ~2 s via
  `armMechanicCountdown`).

### F3 — Shared `Obstacle` fields (used by items 2 & 4)
Extend `struct Obstacle` (`GameModels.swift:46-63`) with value-type state so babies/chasers
**reuse the existing obstacle render + collision path** (no new entity type — per Josh):
```swift
var scale: CGFloat = 1          // 1 = full, 0.5 = baby (item 2)
var parentID: Int? = nil        // baby → its parent obstacle (item 2)
var birthRemaining: Double = 0  // baby birth-slide animation (item 2)
var fadeRemaining: Double = 0   // sympathetic / catch fade-out; non-colliding while > 0
var vibrateRemaining: Double = 0 // cortejo pre-chase shiver (item 4)
var isChaser: Bool = false      // cortejo chaser (item 4)
var chaseTargetID: Int? = nil   // cortejo target (item 4)
```
Render + collide consequences (one place each):
- **Render** (`GameView` obstacle `ForEach`, near `GameView.swift:277-294` style block): multiply
  emoji font/frame by `scale`; multiply opacity by `fadeRemaining > 0 ? fadeRemaining : 1`; add a
  small horizontal jitter while `vibrateRemaining > 0`.
- **Collide** (`resolveCollisions`, `GameState+Obstacles.swift:156-177`): skip the obstacle-hit
  test when `fadeRemaining > 0` (fading = harmless) and scale `obstacleHitSize` by `scale` for babies.

---

## Item 1 — `terremoto` mechanic (earthquake)

**Behavior.** Bull shouts *"I summon an earthquake!"*. For **5 s**: haptics pulse + the whole
screen **jiggles vertically (±5 px start value)**, and **~10 % of each girder** vanishes as
random segment(s) that **fade out over 1 s** — a fading segment stays **traversable while it
fades**. Miss a real (finished) gap → fall to the girder below. Fall **through the bottom
girder** → **−1 heart** + reset to a safe spot on the bottom platform.

**Timed window.** Add `.terremoto` to `mechanicDuration(_:)` (`GameState+Mechanics.swift:145-151`)
→ `earthquakeDuration = 5`. Fire in `startMechanic()` switch (`:87-108`):
`spawnBullSpeech(L.Game.earthquakeAnnouncement)` + rumble SFX (**recommend `.stampede`** —
already bundled, is literally a rumble; note it's shared with `encierro`, acceptable, or pick a
sibling file and log it). All window teardown happens in `finishActiveMechanic()` (`:135-142`).

**Haptics (5 s).** The only haptic API here is UIKit discrete generators
(`Current.hapticPlayer`, `Haptic` enum — `Utils/HapticPlayerReal.swift`), **no CoreHaptics**.
Simulate continuous rumble by **pulsing** `.impactMedium` on a ~0.18 s timer for the window
(add `quakeHapticTimer` decremented in `updateMechanicScheduler`; call
`Current.hapticPlayer.prepare()` at `startMechanic` for `.terremoto`). *(Future polish:
CoreHaptics continuous rumble — out of scope; note only.)*

**Screen jiggle (5 px, vertical).** A shake machine exists but is **boss-only**
(`screenShake`/`shakeOffset`, `GameState+BossFight.swift:628-630`, `GameView.swift:562-570`,
decayed only in `updateBoss`). Don't overload it. Add a dedicated vertical quake:
`earthquakeJiggle: CGFloat = 5`, a phase accumulator advanced during the window, and a computed
`earthquakeShakeOffsetY = sin(phase) * earthquakeJiggle`. Apply `.offset(y:)` to the **climb
content group** in `GameView` (the group holding platforms + actors + obstacles). Goes to 0 at
window end.

**Platform gaps — the main new engineering.** Girders are **single continuous `CGRect` spans**
(`struct Platform`, `GameModels.swift:14-20`; built in `buildLevel()`, `GameState.swift:597-641`)
— there is **no segmentation and no gap concept today**. Add one:
- State: `var platformGaps: [PlatformGap]` where
  `struct PlatformGap: Identifiable { let level: Int; let xRange: ClosedRange<CGFloat>; var fadeRemaining: Double }`.
- **On `terremoto` start:** for each girder, remove **10 % of its width spread across 2 gaps**
  (each gap `= (earthquakeGapFraction / earthquakeGapCount) * rect.width` = 5 % of the beam, at
  random non-overlapping x positions). Expose both as **tunable constants**:
  `earthquakeGapFraction: CGFloat = 0.10` and `earthquakeGapCount = 2`. Each gap starts
  `fadeRemaining = 1.0`.
- **Fade + traversability:** decrement `fadeRemaining` each frame. **While `fadeRemaining > 0`
  the segment is still SOLID for support** (rendered fading, but you can stand/cross it — per
  Josh's clarification). Only once `fadeRemaining == 0` is it a true hole.
- **Player support** (`updatePlayer` snap, `GameState+Physics.swift:46-59`): when testing a
  landing on `platform.level`, if the landing x lies inside a **finished** gap
  (`fadeRemaining == 0`) on that level, **do not land** — let her keep falling to the level below.
  Also un-ground her if she's standing where a gap just finished fading.
- **Fall through the bottom girder:** new `fellThroughFloor()` — when the player's feet pass
  below `platforms[0].surfaceY` through a finished gap: `health -= 1` (respect `damageCooldown`
  so one fall = one heart), reposition to the **safe spot** (`playerX = w*0.15`,
  `playerY = platforms[0].surfaceY - playerHeight/2`, `playerLevel = 0`, grounded), grant
  `respawnGrace`. This is **lighter than `respawn()`** (`GameState+Stages.swift:149-183`) — it
  must **not** refill health / clear obstacles / reset power-ups. If `health <= 0`, fall back to
  the existing full `respawn()`.
- **Obstacles jump the gaps** (decided — not player-only). A rolling obstacle
  (`updateObstacles`, `GameState+Obstacles.swift:87-140`) that reaches a **finished** gap on its
  girder **hops over it on a parabolic arc** rather than falling through: on entering the gap's
  x-range, kick a short vertical launch (`velocityY = -gapHopImpulse`) under the existing
  `gravity`, landing back on the same girder just past the gap (a `hopping` flag so the landing
  snap re-seats it on `level` instead of `level-1`). Tune `gapHopImpulse` so the arc clears a
  5 %-width gap. A **fading** gap (`fadeRemaining > 0`) is still solid — the obstacle rolls
  straight across, no hop.
- **Healing:** on `finishActiveMechanic()` for `.terremoto`, clear `platformGaps` (beams restored).
  *(Optional polish: heal with a 1 s fade-in instead of an instant restore.)*

**Decisions (item 1):** obstacles **jump** gaps (parabolic, above); **10 % across 2 gaps**, both
constants tunable; rumble SFX **`.stampede`**.

---

## Item 2 — `camada` mechanic (obstacles multiply)

**Behavior.** Bull shouts *"The obstacles multiply!"*. At the **center of each on-screen
`Obstacle`**, spawn a **baby** of the same emoji at **½ width/height**. Over **0.5 s** the baby
slides **one emoji-width** away from the parent, **opposite the parent's travel** (rolling right →
baby left; rolling left → baby right; falling down → baby up), then **mirrors the parent exactly**
(locked trailing offset), riding along and **dropping off the bottom girder with it**. A baby does
**1 heart**; on any baby hit, **all babies fade out over 1 s** and vanish.

**One-shot, not a real window.** In `startMechanic()` for `.camada`: announce + SFX + spawn
babies **immediately**, and set `mechanicRemaining` to a tiny value (`multiplyBirthDuration ≈ 0.6`)
purely so the scheduler re-arms via `endMechanic()` (25 s). **Babies live independently** in
`obstacles` afterward. Eligible parents = obstacles with `parentID == nil` **at trigger time**
(obstacles spawned later get none; babies aren't eligible).

**Spawn.** For each eligible parent, append an `Obstacle` copy: same `emoji`, `scale = 0.5`,
`parentID = parent.id`, `x/y = parent center`, `birthRemaining = 0.5`, and a stored
`birthOffset` = one obstacle-draw-width (~30 pt) in the direction **opposite** the parent's travel
(`velocityX` sign, or up if `falling`).

**Update** (new `updateBabies(dt:)`, called in the climb pipeline right after
`updateObstacles`, `GameState.swift:786`):
- While `birthRemaining > 0`: interpolate from 0 → `birthOffset`, decrement.
- After birth: look up the parent by `parentID`; set `baby.x/y = parent.x/y + birthOffset`
  each frame. If the parent is gone (despawned off the bottom), mark the baby `despawn = true`.
- The trailing `obstacles.removeAll { $0.despawn || ... }` (`GameState+Obstacles.swift:139`)
  already cleans them up.

**Sympathetic fade on hit.** In `resolveCollisions` obstacle-hit branch
(`GameState+Obstacles.swift:166-177`): when the hitting obstacle is a baby (`parentID != nil`),
after the normal `health -= 1` + `damageCooldown`, set `fadeRemaining = 1.0` on **all** babies
(the full-size parents are untouched). Fading babies are non-colliding (F3) and are removed when
`fadeRemaining` hits 0.

**SFX.** Announcement pairs a light "poof/multiply" cue — **recommend `.chirp`** (bundled;
avoid `.pop`, which is the jump sound). Optional soft per-baby pop is skippable.

**Decisions (item 2):** **one-shot** modeling (no re-fire during the babies' lifetime); babies
are valid `flechazo`/`cortejo` targets (they're `Obstacle`s) — harmless, left as-is.

---

## Item 3 — `flechazo` power-up (heart missiles on jump)

**Behavior.** Pickup is a **❤️ emoji** (text, no image asset). For the **standard 7 s envelope**
(5 s solid + 2 s blink), **each qualifying jump** fires a **½-size ❤️ missile** that **homes on the
nearest `Obstacle`** and destroys it (roughly parabolic, since the target moves). **1 s cooldown**
on missile *creation*: a jump < 1 s after the last fired missile does **not** fire.

**Envelope.** Add `.flechazo` to `PowerUpKind`; add `flechazoRemaining` (mirror
`speedRemaining`, `GameState.swift:366`) + `flechazoDuration = 7`; decrement in the power-up
countdown block (`GameState.swift:768-776`); `var isFlechazoActive { flechazoRemaining > 0 }`.
Collect in `collectPowerUp` (`GameState+PowerUps.swift:77-90`) sets the timer + a fire SFX cue.
Pickup render: `.flechazo → Text("❤️")` in `GameView.powerUpView` (`GameView.swift:457-478`).
**Dancer badge** for parity with speed's ⚡: a blinking `Text("❤️")` over the dancer using the
shared `powerUpVisible(remaining:)` helper (`GameState+PowerUps.swift:28-32`), mirroring
`GameView.speedBadge` (`GameView.swift:482-491`).

**Fire on jump.** Hook `jump()` (`GameState+Physics.swift:63-68`): if `isFlechazoActive` **and**
`flechazoCooldown <= 0` **and** a target exists, spawn a missile aimed at the **nearest obstacle
to the player** and set `flechazoCooldown = 1.0` (new field, decremented in `update`). No target
→ no missile, **no cooldown consumed**.

**Missile entity (new).** No projectile type exists today (confirmed). Add
`struct HeartMissile: Identifiable { let id: Int; var x, y, velocityX, velocityY: CGFloat; var targetID: Int; var lifeRemaining: Double }`
and `var heartMissiles: [HeartMissile] = []`. New `updateHeartMissiles(dt:)` in the climb
pipeline (after `updateObstacles`):
- Steer toward the target obstacle's **current** position (pursuit → parabolic-ish) at
  `heartMissileSpeed ≈ 400 pt/s`.
- On AABB intersect / distance threshold: despawn the target obstacle (play `.chomp`, the
  existing smash cue), remove the missile.
- If the target vanished before impact: retarget to the new nearest obstacle; if none, fade out
  after `lifeRemaining` (≈1.5 s) expires.
- Render a new `ForEach(heartMissiles)` as `Text("❤️")` at 0.5 scale in `GameView`.

**SFX (fire).** **`.brainLockOn`** (decided upgrade — a "lock-on" cue, thematically apt for a
homing missile). Copy `…/Conjuguer/Conjuguer/Assets/Sounds/brainLockOn.mp3` into
`Conjugar/Audio/`, add a `brainLockOn` case to the `Sound` enum (auto-warmed by
`warmUpSounds()`), and log it in `asset-licenses/game-sounds-pixabay.txt`. Kill SFX on contact
stays `.chomp`.

**Decision (item 3):** target = **nearest obstacle to the player** at jump time; missiles may
target babies (harmless).

---

## Item 4 — `cortejo` power-up (mushroom chaser)

**Behavior.** Pickup is a **🍄 emoji** (red cap/white dots; text, no image asset). On pickup, a
**random on-screen `Obstacle`** stops translating and **vibrates in place for 1.5 s**. Then it
becomes a **chaser**: it pursues **another random `Obstacle`** at **1.5× obstacle speed** and
gains **upward** movement (on top of left/right/down). On catch: **red confetti** over both, both
**fade out over 1 s** and disappear, and a celebratory SFX plays.

**Not an envelope effect** — a fire-and-forget event sequence. Collect in `collectPowerUp`
(`GameState+PowerUps.swift:77-90`) for `.cortejo`: require **≥ 2** obstacles; pick a random one as
chaser (`vibrateRemaining = 1.5`, velocities zeroed), record its future `chaseTargetID` = another
random obstacle's id, play a possession cue (**recommend `.chime`**). Pickup render:
`.cortejo → Text("🍄")` in `GameView.powerUpView`. No dancer badge (no ongoing player effect).

**Update** (new `updateCortejo(dt:)` in the climb pipeline, or fold into `updateObstacles`):
- `vibrateRemaining > 0`: hold position (render jitter via F3), decrement; at 0 set
  `isChaser = true`.
- `isChaser`: each frame steer toward the target obstacle's current position at
  `obstacleSpeed * 1.5`, **up allowed** (`velocityY` may be negative); bypass normal roll/fall.
  On intersect target: emit **red confetti** at the meeting point, set `fadeRemaining = 1.0` on
  **both** chaser and target (non-colliding while fading, F3), play the catch SFX **`.coin`**
  (decided upgrade — a bright sparkle/success ding; copy
  `…/Konjugieren/Konjugieren/Assets/Sounds/coin.mp3` into `Conjugar/Audio/`, add a `coin`
  `Sound` case, log in `asset-licenses/game-sounds-pixabay.txt`).
- If the target despawns before the catch: retarget to nearest other obstacle; if none remain,
  despawn the chaser.

**Red confetti (new visual).** Check the **end scene** first — it already flies hearts/roses
upward from the couple (`GameState+BossFight.swift` end-scene particles). **Reuse that emitter**
if it's a reusable particle list; else add a small `struct ConfettiParticle` + `var confetti`
(red bits, short TTL, gravity/scatter) rendered by a `ForEach` in `GameView`. Prefer reuse.

**Decisions (item 4):** **< 2 obstacles at pickup** → simple fizzle (possess one, despawn after
its vibrate); confetti **reuses** the end-scene particle emitter.

---

## Localization (mechanics only)

Power-up pickups are silent (no bull speech), so **only the two mechanics** need strings. Both
are **narrative bull sentences** → follow the **localized en/es** precedent of
`Game.zombieAnnouncement` (`L.swift:238-240`; xcstrings has en/es), **not** the Spanish-in-both
title-card pattern (`encierro`/`apagon`).

- `L.swift` `enum Game` (near `:248`): add `earthquakeAnnouncement` + `multiplyAnnouncement`
  accessors (`String(localized: "Game.earthquakeAnnouncement")` etc.).
- `Localizable.xcstrings`: add both keys (alphabetically among `Game.*`), each with `en` + `es`,
  both `"state": "translated"`:
  - `Game.earthquakeAnnouncement` — en `"I summon an earthquake!"` / es `"¡Invoco un terremoto!"`
  - `Game.multiplyAnnouncement` — en `"The obstacles multiply!"` / es `"¡Los obstáculos se multiplican!"`
- **Edit `.xcstrings` safely:** these values contain no ASCII `"`, so Edit is OK, **but validate**
  after: `python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"`.

---

## Audio & licensing

`Sound` raw value == mp3 basename; play via `Current.soundPlayer.play(.x, shouldDebounce: false)`.
Two effects use **copied-in sibling upgrades** (decided); the rest reuse bundled cases:

| Effect | Sound | Source |
|--------|-------|--------|
| terremoto rumble | `.stampede` | bundled (shared w/ encierro) |
| camada announce | `.chirp` | bundled |
| flechazo fire | `.brainLockOn` ⬆ | copy `…/Conjuguer/…/Sounds/brainLockOn.mp3` |
| flechazo kill | `.chomp` | bundled (existing smash) |
| cortejo possess | `.chime` | bundled |
| cortejo catch | `.coin` ⬆ | copy `…/Konjugieren/…/Sounds/coin.mp3` |

For each ⬆ upgrade: drop the mp3 in `Conjugar/Audio/`, add a `Sound` case (auto-warmed by
`warmUpSounds()`), and **log it in `asset-licenses/game-sounds-pixabay.txt`** (siblings track no
provenance in-repo; all trace to the Pixabay Content License — commercial OK, no attribution
required, don't redistribute the raw file standalone).

---

## Tests (Swift Testing, `@MainActor` — never XCTest for MainActor types)

Add a `@Suite @MainActor` alongside the existing game suites (e.g. `GameBossTests`). Seed
`bossRNG` with the test `SplitMix64` (`GameModels.swift:215`) for determinism.
- **Bags:** over 5 draws each, `PowerUpKind`/`ChallengeMechanic` yield a **no-repeat permutation**
  (Set of 5 draws has count 5).
- **terremoto:** gaps created ~10 % width; a finished gap un-grounds the player; falling through
  the bottom girder deducts exactly **one** heart and repositions to the safe spot; window end
  clears `platformGaps`.
- **camada:** spawns one baby per eligible parent at ½ scale; baby mirrors parent after birth; a
  baby hit sets `fadeRemaining` on **all** babies but not the parents.
- **flechazo:** a jump within 1 s of a fired missile does **not** create a second missile; a
  missile removes its target obstacle on contact.
- **cortejo:** after 1.5 s the possessed obstacle becomes a chaser; catch removes **both** chaser
  and target.

Run: `~/.claude/skills/ios-build-verify/scripts/build_app.sh` then
`run_tests.sh --only-testing ConjugarTests/<SuiteTypeName>` — **confirm the
`✔ Test run with N tests …` line** (absence after a `--only-testing` filter means the selector
matched nothing → treat as failure, not a pass).

---

## Sim verification (per item) — Josh's manual pass, NOT an implementer step

> The implementer stops after a green unit-test run and does **not** launch the simulator.
> Josh hard-codes a power-up + mechanic combination and play-tests each of these himself.

```bash
# force a specific power-up / mechanic across all stages, freeze-frame with time-scale:
SIMCTL_CHILD_CONJUGAR_GAME_MECHANIC=terremoto SIMCTL_CHILD_CONJUGAR_GAME_TIME_SCALE=0.2 \
  xcrun simctl launch "$UDID" biz.joshadams.Conjugar; sleep 2; xcrun simctl openurl "$UDID" conjugar://game
# also: CONJUGAR_GAME_MECHANIC=multiply, CONJUGAR_GAME_POWERUP=flechazo|cortejo
```
Haptics won't be felt in the simulator — verify the terremoto haptic pulse on a device.

---

## Decisions (resolved by Josh 2026-07-16)

- terremoto: obstacles **jump** gaps on a parabolic arc (not player-only); **10 % across 2 gaps**,
  both `earthquakeGapFraction`/`earthquakeGapCount` tunable; rumble SFX **`.stampede`**.
- camada: **one-shot**; babies are valid missile/chaser targets (harmless).
- flechazo: missile targets the **nearest obstacle to the player** at jump time.
- cortejo: **< 2 obstacles** at pickup → graceful fizzle; confetti **reuses** the end-scene emitter.
- **Case names confirmed:** `terremoto` / `camada` / `flechazo` / `cortejo`.
- **SFX upgrades confirmed:** flechazo fire → **`.brainLockOn`** (copy from Conjuguer), cortejo
  catch → **`.coin`** (copy from Konjugieren); both copied to `Conjugar/Audio/`, new `Sound` cases,
  logged in `asset-licenses/game-sounds-pixabay.txt`.

All open decisions are resolved — the plan is ready to implement.

## Housekeeping
- Append a dated entry to `docs/blog_notes.md` (trailing `## <Title> (YYYY-MM-DD)` form) when
  the work lands — what was built, and any decisions that shifted mid-implementation.
- `swiftlint` clean; ignore SourceKit false positives on view files — `build_app.sh` is authoritative.
