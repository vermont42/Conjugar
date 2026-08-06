# Toreo por Amor — Conjugar's built-in game

Conjugar ships a small arcade game, **Toreo por Amor**, reached from Settings ▸ Play or by
deeplink. It has two phases: **La Subida**, a five-stage climb, and **La Llamada**, a
call-and-response flamenco dance-off against the bull.

Code: `Conjugar/Views/GameView.swift` (the whole UI) and `Conjugar/Models/Game/`
(`GameModels.swift`, `GameState.swift`, and the `GameState+…` extensions). Strings live in
`L.Game`. The original design documents are `prompts/game_la_subida.md` and
`prompts/game_boss_llamada.md`.

## Running the game in the simulator

`conjugar://game` is the fast path: it presents `GameView` full-screen via `AppRouter.showGame`
from `MainTabView` (tab-independent), so no Settings→scroll→Play dance.

```bash
UDID=$(xcrun simctl list devices booted -j | python3 -c "import sys,json;print(json.load(sys.stdin)['devices'].popitem()[1][0]['udid'])")
xcrun simctl openurl "$UDID" conjugar://game            # → full-screen game
xcrun simctl openurl "$UDID" conjugar://game/boss       # → jump straight to the boss fight
xcrun simctl openurl "$UDID" conjugar://game/end        # → jump straight to the end scene
```

Every actor is a rendered cel-shaded sprite. The **dancer** has eight actions
(`idle`/`walk`/`climb`/`jump`/`cape`/`capeWalk` from the climb, plus `ole`/`stomp` for the boss
dance-off) and the **bull** has six (`idle`/`walk`/`throw` from the climb, plus
`stomp`/`rear`/`bow` for the boss); the **matador** is a static front-facing
`Image("matador")`. During the climb, hold a direction button to walk, tap jump, hold up at a
ladder to climb, etc. Example hold-and-capture (logical points; right arrow ≈ `131,767`):

```bash
axe touch -x 131 -y 767 --down --up --delay 2.5 --udid "$UDID" &   # hold right ~2.5 s
sleep 1.1; "$S/screenshot.sh" walking                              # capture mid-walk
```

To reach the climb state, the D-pad **up** button only appears when the player is aligned at
a ladder base — poll `describe_ui.sh` for the `Move up` label to know you're on it.

### Freeze-framing a fast animation (jump apex, climb/cape pose)

The game loop honors two **launch environment variables**, both default-off so **normal play is
unaffected** — `CONJUGAR_GAME_TIME_SCALE` scales the loop's `dt` (`0.2` = 5× slow, `0.1` = 10×,
so a ~0.5 s jump lasts several seconds and is trivially screenshot-able) and
`CONJUGAR_GAME_DISABLE_FLAGS` stops the bull throwing obstacles (a calm field; the var keeps its
legacy `FLAGS` name as a documented contract). They're read via `ProcessInfo` in `GameState`
(`debugTimeScale` / `debugFlagsDisabled`). `openurl` can't pass env, so launch the process
**with** them, then route via the deeplink:

```bash
APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/Conjugar-*/Build/Products/Debug-iphonesimulator/Conjugar.app | head -1)
xcrun simctl terminate "$UDID" biz.joshadams.Conjugar 2>/dev/null; xcrun simctl install "$UDID" "$APP"
SIMCTL_CHILD_CONJUGAR_GAME_TIME_SCALE=0.2 SIMCTL_CHILD_CONJUGAR_GAME_DISABLE_FLAGS=1 \
  xcrun simctl launch "$UDID" biz.joshadams.Conjugar
sleep 2; xcrun simctl openurl "$UDID" conjugar://game
```

## La Subida — the five-stage climb

The climb is split across `GameState+Obstacles.swift` (the rolling obstacle sets),
`GameState+Stages.swift` (stages, escape beats, soft respawn), `GameState+PowerUps.swift`, and
`GameState+Mechanics.swift`. Key facts:

- **Five stages** (`stage` 1…5, invariant `stage == summitCount + 1`). Each stage has its own
  **obstacle set** (flags → animals → balls → vehicles → sky, `stageObstacleEmojis`) and a
  **render style** (`ObstacleStyle`: `.spin` for flags/balls, `.face` — upright but mirrored to
  face its travel — for animals/vehicles, `.upright` for sky). Obstacle speed compounds
  **+5 %/stage** (`obstacleSpeed = obstacleRollSpeed · 1.05^(stage−1)`). Only the
  `CONJUGAR_GAME_DISABLE_FLAGS` env var and `debugFlagsDisabled` keep the pre-rename `Flag`
  vocabulary (a documented external contract); everything else says `Obstacle`.
- **Escape beats (summits 1–4).** Touching the bull on a non-final stage enters
  `GamePhase.escape` (`enterEscape`/`updateEscape`): the bull flees upward carrying the matador
  off-screen, then `advanceToNextStage` rebuilds the field (fresh set/speed/pickups, hearts
  refilled, **"¡Nivel N!"** banner + applause). The **5th** summit triggers the boss.
- **No lose state.** At 0 health the player **soft-respawns** (`respawn()`) at the bottom of the
  current stage with full health — `stage`/`summitCount`/`score`/collected pickups persist; a
  brief `respawnGrace` follows. `reset()` (a full restart to stage 1) is only for the configure
  path, not death.
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

The power-up and mechanic SFX (`guitarStrum`, `speedWhoosh`, `zombieGroan`, `stampede`,
`lightsOut`) are Pixabay MP3s bundled in `Conjugar/Audio/`, logged in
`asset-licenses/pixabay-mpg-sfx.txt`.

**Debug env vars** (read via `ProcessInfo`; compose with `CONJUGAR_GAME_TIME_SCALE` /
`CONJUGAR_GAME_DISABLE_FLAGS` and the `conjugar://game` launch pattern above):

- `CONJUGAR_GAME_STAGE=N` (1…5) — start the climb at stage N (`summitCount = N−1`).
- `CONJUGAR_GAME_POWERUP=cape|speed|serenata` — force every stage's power-up draw.
- `CONJUGAR_GAME_MECHANIC=zombie|encierro|apagon` — force every stage's mechanic draw AND
  shorten its countdowns to ~2 s for fast verification.

## La Llamada — the boss fight (`GameState+BossFight.swift`)

Summiting (touching the bull) triggers a call-and-response flamenco **dance-off**: the bull
dances a phrase move-by-move (cue chips accumulate), the player echoes it from memory on a
morphed dance pad while a compás bar sweeps, and a 6-notch **Duende meter** (banked phrases) is
both a tug-of-war and the fight's progression — banked 0–1 round 1 (length 3), 2–3 round 2
(length 4), 4–5 round 3 (length 5, with a 🔥 **freeze** fake-out where the correct input is
*nothing*), 6 → victory → an end scene on `Music.onboarding`. Failure slides the meter back a
notch and rerolls a fresh phrase; there is **no lose state**.

All boss logic is in `GameState+BossFight.swift` (`update(currentTime:)` routes every
non-`.climb` phase to `updateBoss`); the climb pipeline is byte-identical when `phase == .climb`.
Hearts are hidden off-climb (the meter is the only currency). Six dance moves (`DanceMove`):
paso left/right, ole, stomp, cape, freeze. Each move's pad-button/cue-chip glyph is
single-sourced by `DanceMove.glyph` and rendered by `GameView.moveIcon`; the olé glyph is the
custom **`ole`** symbol (`Assets.xcassets/ole.symbolset` — a solid arms-up-V dancer silhouette
derived from the `dancer_ole_3` sprite, on the same SF-template scaffold as the `dancer`/`bull`
symbols, so it tints and font-scales like a system symbol). Boss buttons fire on touch-down (the
jump idiom), not held intents. The jaleo shouts and title cards stay Spanish in **both**
localizations; the narrative line and a11y labels localize en/es.

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
continue" prompt — any tap dismisses.

## Music (`Music` enum + `SoundPlayer`)

The game's looping background music is the `Music` enum (`Models/Music.swift`), each case a
bundled MP3 base name that `SoundPlayerReal.startMusic(_:)` loops via `numberOfLoops = -1`.

- **`Music.gameLoop`** — Pond5's "Flamenco Adventure", bundled as `flamencoLoop.mp3` (a legacy
  filename). This one file sits at the target root (`Conjugar/flamencoLoop.mp3`), **not** in the
  `Conjugar/Audio/` group. Played from `GameState` during the climb.
- **`Music.bossFight`** — Pond5's "Spanish Guitar Standoff" (`Conjugar/Audio/spanishGuitarStandoff.mp3`).
  Crossfades in on the boss intro's llamada and loops the duel, then fades out into
  `Music.onboarding` at the end scene.
- **`Music.onboarding`** — Pond5's "Spanish Tension" (`Conjugar/Audio/spanishTension.mp3`).
  Scores both the onboarding flow (see [`docs/onboarding.md`](onboarding.md)) and the boss
  fight's end scene. `GameState.stopAudio()` **fades** (rather than hard-stops) when the player
  exits from `.endScene`; the climb still uses the plain `stopMusic()` hard-stop.

The WAV masters live in git-ignored `audio-sources/`; only the 192 kbps MP3s are committed.
Pond5's Content License requires no attribution (the game-music credit in `Localizable.xcstrings`
is a courtesy note).
