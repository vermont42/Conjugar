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
  (`powerUpBag`, through `bossRNG`); all five share the cape's 7 s (5 solid + 2 blink)
  envelope, and each shows a badge on the dancer's leading side at her sprite's vertical
  center. Every jump-triggered effect below hangs off `jump()` in `GameState+Physics.swift`.
  - **cape** — invuln + smash, `Image("cape_pickup")`. The muleta is baked into the
    `.cape`/`.capeWalk` sprites, so a **carried cape** overlay fills in exactly where those
    aren't showing (mid-jump and on a ladder, which render capeless) — `isCarriedCapeVisible`,
    so the two are never on screen together. It swings a **quarter-turn through a jump**:
    clockwise facing right, counter-clockwise facing left, unwinding on landing
    (`updateCapeRotation` at `capeRotationRate` deg/s). Collecting a cape while already caped
    snaps it back to standard orientation; the next jump turns it again.
  - **speed ⚡** — the dancer's walk + climb ×2 (`speedFactorNow`) **and the bull's pacing ×2**
    (`bullSpeedFactorNow`), so the whole scene quickens. Translation only: both flipbooks stay
    on the fixed `fps` clock, so no animation speeds up. `Sound.speedWhoosh`.
  - **La Serenata 🎸** — the bull stops pacing/throwing and dances the end-scene repertoire
    instead (`Sound.guitarStrum`, `Sound.snort` on expiry). A **jump strums a chord**: the
    quiz's correct-answer `Sound.chime` plus a 🎵 that **rides the bull** (re-seated on him
    every frame, `serenataNoteLift` = half a glyph above his center) for `serenataNoteLife`,
    then bursts into yellow-and-blue particles. The lift lives in `GameState`, not the view,
    so the burst blooms exactly where the note was.
  - **El Flechazo ❤️** — a jump fires a homing heart missile at a random obstacle (1 s
    cooldown). Each shot also blooms a ❤️ beside the **captive matador**, growing in over
    `matadorHeartGrow` off his right side at his sprite's vertical center; when that missile
    strikes, his heart **bursts yellow-and-blue** (`popMatadorHeart`). A missile that expires
    un-struck retires its heart quietly instead.
  - **El Cortejo 🍄** — a jump spends a banked charge to possess an obstacle, which shivers,
    then chases and annihilates another. A cosmetic 🍄 **flies from the dancer to the obstacle
    she just claimed** (`updateCortejoMushrooms`), arriving during the shiver — the visible
    link between jump and possession, mirroring the way her hearts fly.
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
the matador sliding in from her pedestal, with a shout of *¡Olé!* (`Sound.ole`, full volume); once he reaches her, the freed **bull breaks into a
dance** — every 2 s it performs a randomly-chosen animated move (`endSceneDanceMoves` = walk /
stomp / rear / bow / throw, walk danced *in place* so its position never changes) and moos
(`Sound.moo`) every 4–8 s — while hearts/roses fly up from the couple every 2–4 s (random). The
Duende meter is hidden the moment the player wins (`GameState.hasWon`).

**The slideshow.** Five seconds after the reunion burst, an **iris wipe** (a circle growing from
the column's center, a 3 pt yellow ring riding its edge) opens on a still portrait, **Los
toreros** (the dancer, the bull, and the matador), then **La familia** (Amanda, their horse Vegas,
and Josh), then the live scene again, cycling until the player quits. The live scene holds 5 s
once its iris has fully opened; the wipe takes 0.9 s. The state machine is
`GameState+Slideshow.swift` (`EndSceneSlide`, advanced from `updateEndScene`, so
`CONJUGAR_GAME_TIME_SCALE` slows the iris and the camera for freeze-framing);
`GameView.endSceneSlideLayer` draws it.

Each portrait gets a **Ken Burns** camera over 9 s: 1 s on the wide shot (the whole 3:2 image,
letterboxed, with the end scene's confetti floating in the bars), a 2 s push-in that zooms and
pans together onto the left subject, a 0.75 s dwell, a 1.5 s pan to the animal, a 1 s dwell on
it, a 1.5 s pan to the right subject, and a 1.25 s dwell before the next wipe. The subjects' positions are
`EndSceneSlide.subjectFocusX` (fractions of the image's width, measured on the art). The model
exposes a framing (`EndSceneFraming`: zoom 0 = wide, 1 = full column height, plus a focus point);
the view interpolates zoom on a log scale and clamps the focus so no edge of the image pulls inside
the column. Full height is the tightest zoom, because on an iPad Pro the art is already about one
image pixel per screen pixel there.

**Captions.** Both portraits carry a caption along the column's bottom: *La Bailaora, El Toro, El
Matador* and *Amanda, Vegas, Josh (The Developer)* (Spanish: *Josh (El Desarrollador)*), one
`L.Game` string per name. The name the camera is showing is bold, and each handoff trades weight
between two names over 1 s (`endSceneCaptionBoldness`), using SF's variable weight axis so the
change is continuous. The left name is bold from the wide shot on; the handoffs fall halfway
through each pan leg, where the focus crosses halfway between two subjects.

**Subject sounds.** As the camera turns to each subject, it makes a sound
(`EndSceneSlide.subjectCalls`, played once per showing from `advanceEndSceneSlideshow`): a
castanet (`castanetPortrait`) for the dancer and Amanda halfway through the push-in, then the
animal's voice (`moo` for the bull, `neigh` for Vegas) and a shouted *¡Olé!* (`ole`) for the
matador and Josh at the caption's handoffs. Under Reduce Motion each plays on the cut onto its
subject. Volumes even out the sources' loudness, then Josh's ear: castanet 1.0, moo 0.5, neigh
1.0 (a quiet file), olé 0.42. `castanetPortrait.mp3` is `castanetHigh.mp3` made 17% louder with a
soft limiter, because the castanet wanted more than the 1.0 volume ceiling allows. `neigh.mp3` is Konjugieren's `horse.mp3`. `ole.mp3` is the first of three shouts in a
Pixabay clip by Ai_mee_Universe, credited in the Info tab's credits. (Don't confuse it with
`crowdOle`, which despite its name is a generic crowd cheer used in the boss fight.)

During an image the ¡Victoria! title, the bull line, and the playfield confetti fade out, and the
live bull's moos and the reunion chimes go quiet (the live simulation keeps running underneath). A wipe
back to the live scene cuts a growing hole in the outgoing image instead. Under **Reduce Motion**
the iris becomes a 0.4 s crossfade, and the camera becomes four stills (wide, left, middle, and
right subject, 2.25 s each) joined by the same crossfade, with the bold handing off on the cuts.
Under **VoiceOver** each image has a descriptive label, and the caption is hidden as redundant.
The two JPEGs are decoded off the main thread as the end scene opens and held in a small
`@Observable` `PreparedSlideImages` object, not a plain `@State` dictionary, because the
slideshow is drawn inside `TimelineView`'s content closure (see the 2026-09-30 journal entry).
The art, its prompts, and the generation story are in
[`prompts/end_scene_plan.md`](../prompts/end_scene_plan.md) (Phase 1) and
`prompts/end_scene_images/`. (The plan's Phase 2 describes the first, draggable version, which
the Ken Burns camera replaced.)

**Only the X button leaves the end scene.** Taps do nothing there; there is no tap layer in
`.endScene`.

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
