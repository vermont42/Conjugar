# Plan — Boss fight: **La Llamada** (the dance-off duel)

**Goal:** after summiting, the player faces the bull in a call-and-response **dance-off**
(Simon × Space Channel 5, flamenco-themed): the bull dances a phrase move by move, the
player echoes it on a morphed control pad, a tug-of-war **Duende meter** tracks the duel,
and winning makes the bull — impressed — **bow and free the matador**, flowing into a
minimal end scene on `Music.onboarding`. Success = in `conjugar://game` (or the debug
entries) the full arc plays: summit → intro llamada → 3 rounds of echo phrases → bow →
end scene → dismiss, with rendered dance animations for both actors, new SFX, jaleo
feedback, and a green test suite.

Concept selection and rationale: `docs/boss_fight_ideas.md` (Concept 1 won). This plan is
self-contained for a fresh session; the ideas doc is background, not required reading.

---

## Decisions (locked with Josh 2026-07-13 — do not relitigate)

1. **Boss triggers from the FIRST summit** for now. The five-level climb + four escape
   beats don't exist yet (separate roadmap item); park the gate behind
   `static let summitsToBoss = 1` with a TODO to raise to 5 when escapes land.
2. **Minimal end scene included**, playing **`Music.onboarding`** (its long-intended use
   per CLAUDE.md). Item 4 may expand it later; build the seam clean.
3. **Scoring hooks now:** judgments accumulate into a plain `score` var (undisplayed);
   the scoring work item formalizes display/persistence/Game Center later.
4. **Moves:** paso left ⬅️, paso right ➡️, olé pose (arms up), stomp, cape flourish —
   plus a 🔥 **freeze** fake-out slot in round 3 only (input *nothing*).
5. **Structure:** 3 rounds × 2 phrases, sequence lengths 3 → 4 → 5, bull **showboat**
   beats between rounds, ~60–90 s total.
6. **Relaxed timing:** a visible sweeping **compás bar** per echo phrase (generous
   budget); memory is the challenge. No per-move beat windows; the on-beat ¡Olé! bonus
   is a future hard mode. (Round-3 demo playback still speeds up.)
7. **Failure:** one wrong/late move fails the phrase instantly → bull showboats → a
   **fresh random sequence of the same length** (no rote-repeating a failed phrase).
   Duende marker slides back one notch (floor 0).
8. **Hearts hidden during the boss** — the meter is the only currency; retries free.
9. **No outright loss.** The bull never harms the dancer; failure just delays.
10. **Full bull fidelity in this plan:** hand-key **stomp**, **rear** (rear-up), and
    **bow** as new Blender actions.
11. **Dancer gets two new actions:** **ole** (arms up) and **stomp** (gown accent),
    hand-keyed in the established gown style.
12. **New SFX pack from Pixabay** (castanets ×2, palmas, crowd olé, bull snort, stomp
    thud, cape whoosh), logged in `asset-licenses/`.
13. **All the juice:** screen shake on llamadas, floating jaleo pops, emoji crowd row,
    confetti on the win.
14. **Intro beat:** ~2 s "¡El duelo!" card + bull llamada stomp, tap-to-skip.
15. **Both debug entries:** `conjugar://game/boss` deeplink AND a
    `CONJUGAR_GAME_START_BOSS` launch-env var (env composes with
    `CONJUGAR_GAME_TIME_SCALE` for freeze-frame screenshots).
16. **Jaleo strings stay Spanish in BOTH localizations** (¡Olé!/¡Uy!/¡Tu turno!…);
    narrative lines (e.g. "The bull is impressed!") localize normally en/es.

## Where the code is today (verified 2026-07-13)

- **Loop:** `GameState` (`Models/Game/GameState.swift`) is `@MainActor @Observable`,
  ticked by `TimelineView(.animation)` → `update(currentTime:)` (dt clamped to 1/30 s,
  scaled by `debugTimeScale`). Update pipeline: `updatePlayer → updateBull → updateFlags
  → advanceAnimations → resolveCollisions → checkReachedBull`. Mechanics live one-file-
  per-concern (`GameState+Physics/Flags/Animation.swift`); anything extensions touch is
  internal, not private.
- **The summit seam:** `GameState+Physics.swift` → `checkReachedBull()` (~:123)
  currently plays applause and calls `reset()`. This is the boss's front door.
- **Actions/flipbooks:** `GameModels.swift` has `PlayerAction {idle, walk, climb, jump,
  cape, capeWalk}` and `BullAction {idle, walk, throw}`. `GameState+Animation.swift`
  holds `playerFrameCounts` / `bullFrameCounts` (fps = 10), `frame(phase:count:)`, and
  the per-frame `derivedPlayerAction()` / `derivedBullAction()` — during the boss,
  actions must be **commanded** (one-shot bursts with timers, like `bullThrowTimer`),
  not derived; derivation stays for the climb phase only.
- **Sprites:** `Views/GameView.swift` renders per-action flipbooks —
  `spriteActions`/`actionName`/`dancerWidth` (aspects from union-crop px at constant
  `dancerVisualHeight` 57.3, feet via `dancerFeetOffset`) and
  `bullSpriteActions`/`bullActionName`/`bullCrop` (512-render crop px → pt via
  `bullScale` 0.314, per-action `bullFeetOffset`, `.interpolation(.high)`). Renders face
  LEFT; mirror when facing right (never mirror the dancer's climb). Matador is a static
  `Image("matador")`, front-facing, never mirrored.
- **Controls:** D-pad bottom-left (up/down slots appear only at ladders — during the
  boss there are no ladders, so both slots are free real estate); jump button
  bottom-right fires on touch-down (`jumpHeld` re-arm). Directional buttons are
  press-and-hold intents via `DragGesture(minimumDistance: 0)`.
- **Audio:** `Music.bossFight` = `spanishGuitarStandoff.mp3` (bundled, **42.7 s seamless
  loop**, staged for exactly this). `SoundPlayer.startMusic(_:)` fades in;
  `stopMusic(fadeDuration:)` fades out (added for onboarding); `stopMusic()` hard-stops.
  `GameState.startAudio()` warms SFX + flag glyphs (`GlyphWarmer`) and starts
  `.gameLoop`; `GameView.onDisappear` calls `stopAudio()`. SFX mp3s live loose in
  `Conjugar/` (legacy); **put new ones in `Conjugar/Audio/`** (synchronized group — no
  pbxproj edit). `Sound` is `CaseIterable` so new cases warm automatically.
- **Deeplinks:** `Views/AppRouter.swift` → `handle(url:)` switches on `url.host()`;
  `"game"` sets `showGame` (full-screen cover from `MainTabView`). For
  `conjugar://game/boss` the host is still `"game"` with `lastPathComponent == "boss"`.
- **Env-var pattern:** `GameState.debugTimeScale` / `debugFlagsDisabled` statics read
  `ProcessInfo` — copy for `CONJUGAR_GAME_START_BOSS`.
- **Custom SF symbols `bull` and `dancer`** exist in the asset catalog (used by
  `OnboardingView`) — reuse for the Duende meter's end caps.
- **Tests:** `ConjugarTests/Models/GameStateTests.swift` (Swift Testing, `@MainActor`)
  already steps the loop deterministically with scripted `Date`s — extend that pattern.
- **Strings:** `L.Game` exists (`title/play/quit/health/jump/moveUp/…`) backed by
  `Localizable.xcstrings` (en + es, both `"translated"`).

## Read first

1. `Conjugar/Models/Game/GameState.swift` + `GameState+Physics/Flags/Animation.swift` +
   `GameModels.swift` (the whole game core — it's small).
2. `Conjugar/Views/GameView.swift` (sprite sizing discipline, control idioms, HUD).
3. `prompts/game_bull_actions.md` — **the bull-rig reconnaissance is mandatory**: Rigify
   controls are dead post-FBX; hand-key the `DEF-`/`*_fk` bones (Path B), In-Place, one
   FBX per action; and the proven render/crop/wire phases to copy.
4. `prompts/game_dancer_finish_actions.md` — the gown house style ("animate the gown,"
   shoes deleted, world-space rotation keying script skeleton) and dancer render/wire flow.
5. `tools/blender/README.md` — harness args (`--fbx --actor --action --frames --size
   --view --toon --color --outline`), `pack_or_rename.sh`.
6. `CLAUDE.md` — build/test/launch commands, freeze-framing recipe, `.xcstrings`
   foot-guns, Swift-Testing-not-XCTest rule.
7. `docs/boss_fight_ideas.md` (optional background — the three concepts + sources).

---

## Design spec (authoritative)

### Phase machine

```swift
enum GamePhase { case climb, bossIntro, duel, victory, endScene }   // GameModels.swift

enum DanceMove: CaseIterable { case pasoLeft, pasoRight, ole, stomp, cape, freeze }

enum DuelState {                       // sub-state while phase == .duel
  case bullDemo(step: Int)             // bull performs; cue chips accumulate
  case playerEcho(step: Int)           // input unlocked; compás bar sweeping
  case phraseResult(success: Bool)     // jaleo pop, meter move, brief hold
  case showboat                        // between rounds; bull struts, taunt SFX
}
```

All boss logic in a new **`Conjugar/Models/Game/GameState+BossFight.swift`**;
`update(currentTime:)` switches on `phase` — the existing pipeline runs only in
`.climb`, a new `updateBoss(dt:)` runs otherwise. `reset()` returns everything to
`.climb`. Hitting ✕ (dismiss) works in every phase.

### Entry, intro, exit

- `checkReachedBull()` (in `.climb` only): increment `summitCount`; when it reaches
  `summitsToBoss` (**= 1**, TODO → 5 when escape beats land) → `enterBossIntro()`.
- `enterBossIntro()`: clear flags; freeze climb inputs; animate `bossTransition` 0→1
  over ~0.8 s (view fades girders/ladders/capes/flags by `1 − bossTransition`, fades in
  stage dressing by `bossTransition`); crossfade music —
  `stopMusic(fadeDuration: 0.8)` then `startMusic(.bossFight)`; bull walks to his stage
  mark; **llamada**: bull `stomp` burst + stomp SFX + screen shake + "¡El duelo!" card.
  ~2 s total; **any tap skips** to the duel.
- **Stage layout** (portrait, reuse geometry): the tablao floor is **`platforms[0]`**
  (bottom girder — maximum headroom for chips/meter). Bull at `x ≈ 0.28·w` facing
  right; dancer at `x ≈ 0.68·w` facing left; matador on a small pedestal at
  `x ≈ 0.9·w` (static sprite, watching). Crowd row: a strip of emoji
  (`👒 🌹 👏 💃 🕺 👏 🌹`) just below the floor, above the controls.
- **Victory** (meter banks 6): `phase = .victory` — bull plays **bow** and holds the
  final frame (cap `bullPhase` at the last frame after one pass), `randomApplause` +
  confetti; after ~1.5 s → `phase = .endScene`: `stopMusic(fadeDuration: 1.0)` →
  `startMusic(.onboarding)`; the matador sprite **slides** from his pedestal to the
  dancer (simple x-interpolation, ~2 s); ❤️/🌹 burst above the pair; "¡Victoria!" title
  + localized "The bull is impressed — the matador is free!" line + tap-to-exit hint;
  any tap → dismiss the cover (music stops via existing `onDisappear`/`stopAudio()` —
  extend `stopAudio()` to fade rather than hard-stop when in `.endScene`).

### The duel loop

- **Demo:** for each move in the phrase: bull plays its demo burst, a **cue chip** pops
  above him (chips accumulate left→right, SC5-style), its SFX note plays. Step duration
  `demoStep` by round: **0.9 / 0.75 / 0.6 s**. Chips **disappear at "¡Tu turno!"** —
  echoing is from memory (a future easy mode may leave them up).
- **Echo:** input unlocks; the **compás bar** sweeps down from full over
  `moves × 1.5 s + 2 s`. Each input is judged against the expected slot:
  - correct → dancer plays her burst for that move, 🎵 pop + small jaleo
    (random ¡Eso!/¡Bien!/¡Vamos!), advance;
  - wrong move, or bar empties → **phrase fails**: `buzz` + ¡Uy! pop, bull **snort** +
    smug stomp, meter −1 notch, → `showboat`-lite (~1 s) → fresh same-length phrase.
  - **freeze slot** (round 3): the 🔥 chip means *hold still* — any input during its
    **1.2 s** window fails the phrase; surviving it auto-advances with a ✨ pop.
- **Phrase success:** big **¡Olé!** pop + palmas, meter +1 notch (`phraseResult`), then
  next phrase / next round / victory.
- **Rounds** are derived from the meter (below); **between rounds** (banked = 2 and 4):
  `showboat` ~2 s — bull struts (walk-in-place + rear burst), crowd murmurs.

### Duende meter = progression (tug-of-war)

Meter has **6 notches**; `banked` phrases 0…6 **is** the fight's progress:
banked 0–1 → round 1 (length 3), 2–3 → round 2 (length 4), 4–5 → round 3 (length 5,
freeze eligible), 6 → victory. Success +1, failure −1 (floor 0) — a slide-back can
demote a round, which is the tug-of-war working as intended. UI: 6-segment bar top
center, custom `dancer` symbol on the left cap, `bull` on the right, marker fills gold
toward the bull. `healthPips` hides whenever `phase != .climb`.

### Moves ↔ controls ↔ animations ↔ SFX

| Move | Cue chip / button glyph | Input | Dancer anim | Bull demo anim | SFX |
|---|---|---|---|---|---|
| pasoLeft | ◀ (SF `arrowtriangle.left.fill`) | left button | `walk` burst in place, facing left | `walk` burst facing left | castanetLow |
| pasoRight | ▶ | right button | `walk` burst, facing right | `walk` burst facing right | castanetHigh |
| ole | SF `figure.arms.open` | up-slot button (always visible in boss) | **new `ole`** | **new `rear`** | palmas |
| stomp | SF `shoeprints.fill` (or 🦶) | jump button, relabeled | **new `stomp`** | **new `stomp`** | stompThud |
| cape | the `cape_pickup` sprite as icon | **new button** beside the stomp circle | `cape` burst | `throw` head-snap burst | capeWhoosh |
| freeze | 🔥 emoji chip | *no input* for 1.2 s | `idle` (held) | `idle` (held) | tension sting (reuse `chime` low-volume or new) |

- **Boss buttons fire on touch-down** (the jump idiom with a re-arm bool), NOT
  press-and-hold intents — build a `danceButton(...)` sibling of `directionButton` and
  swap the whole control cluster on `phase != .climb`. Down-slot stays hidden. Buttons
  dim/disable during `bullDemo` and `phraseResult`.
- One-shot burst mechanism: `playerMoveTimer`/`bullMoveTimer` countdowns (the
  `bullThrowTimer` pattern); while > 0 the commanded action plays, then falls back to
  `idle`. Sequence generation: uniform over the 5 moves (round 3 injects exactly one
  freeze at a random non-first slot), rerolled fresh on failure. **RNG must be
  injectable** — `var bossRNG: any RandomNumberGenerator = SystemRandomNumberGenerator()`
  + a tiny seedable `SplitMix64` struct so tests can script exact sequences.

### Scoring (decision 3 — accumulate only, no HUD yet)

`var score = 0` on `GameState`: +50 per correct move, +200 × round per phrase, +2,000
boss clear. Tests assert the arithmetic; the scoring work item adds display/persistence.

### New tuning constants (all `static let` on `GameState`, placeholder values)

`summitsToBoss = 1`, `bossTransitionDuration = 0.8`, `introDuration = 2.0`,
`demoStepDurations = [0.9, 0.75, 0.6]`, `echoTimePerMove = 1.5`, `echoGrace = 2.0`,
`freezeHold = 1.2`, `phraseResultHold = 0.9`, `showboatDuration = 2.0`,
`meterNotches = 6`, `phraseLengths = [3, 4, 5]`, `movePoints = 50`,
`phraseBonus = 200`, `bossClearBonus = 2_000`.

---

## Phase 1 — Mechanic core on existing art  [Claude]

The whole state machine, playable end-to-end with **reused animations only** (paso =
walk bursts, ole ≈ cape, stomp ≈ jump pose, bull demos = walk/throw bursts) and SF-symbol
chips. This proves the fun before any Blender work.

- `GameModels.swift`: add `GamePhase`, `DanceMove`, `DuelState` (+ `BullAction.stomp/
  rear/bow` and `PlayerAction.ole/stomp` cases NOW, mapped to reused frames via the
  frame-count tables so Phases 3–4 only swap imagesets).
- New `GameState+BossFight.swift`: entry/intro/duel/victory/endScene per the spec;
  summit counting in `checkReachedBull()`; `reset()` clears to `.climb` and re-shows
  hearts.
- `GameView.swift`: `bossTransition` fades; stage dressing (crowd row, pedestal); Duende
  meter (hide `healthPips` off-climb); cue-chip row; compás bar; jaleo pops (a small
  `struct JaleoPop {text, x, y, ttl}` array rendered as floating fading `Text` — sibling
  score-pop idiom); control morph (`danceButton` cluster + cape button + stomp relabel);
  intro/victory/end-scene cards; tap-to-skip/-exit gestures; confetti on victory (port
  Konjugieren's 40-ellipse `Canvas` confetti); screen shake (deterministic sin-decay
  offset on the field ZStack — Conjuguer idiom).
- Debug entries (decision 15): `AppRouter.handle` — in the `"game"` case, if
  `url.lastPathComponent == "boss"` set a new `pendingBossEntry` flag consumed by
  `GameView`/`GameState` after `configure`; plus
  `static let debugStartAtBoss = ProcessInfo…["CONJUGAR_GAME_START_BOSS"] != nil` that
  jumps straight to `.bossIntro` on configure. Register nothing new in Info.plist (same
  scheme).
- Music wiring per spec (crossfades at intro/victory; `.endScene`-aware `stopAudio()`).
- Scoring accumulation.
- **Tests** (`ConjugarTests/Models/GameBossTests.swift`, Swift Testing, `@MainActor`,
  seeded RNG + scripted `Date` stepping): summit → intro → duel; scripted correct echo
  banks a phrase (+meter, +score); wrong input fails, −notch, same-length reroll (assert
  different-but-equal-length sequence with the seeded RNG); compás expiry fails; freeze:
  input-during fails / waiting passes; banked 2 and 4 trigger showboat + round/length
  changes; banked 6 → victory → endScene; `reset()` restores `.climb` + hearts; climb
  behavior untouched when `phase == .climb` (existing `GameStateTests` still green).
- Build + tests via ios-build-verify; drive `CONJUGAR_GAME_START_BOSS=1` in the sim and
  play a full duel with axe taps. **Commit** ("Boss fight: La Llamada mechanic core").

## Phase 2 — SFX pack + juice polish  [Claude, Josh auditions]

- Source from **Pixabay** (commercial OK, no attribution): two castanet clicks,
  a palmas clap, crowd "¡olé!" shout, bull snort, boot-stomp thud, cape whoosh
  (+ optional tension sting). Trim/normalize → mp3 → **`Conjugar/Audio/`**.
- New `Sound` cases (`castanetHigh, castanetLow, palmas, crowdOle, snort, stompThud,
  capeWhoosh`) — `CaseIterable` warms them automatically. Wire per the moves table +
  crowd reactions; keep volumes low like `cow` (0.15–0.5); debounce per-move sounds.
- Log every file in `asset-licenses/pixabay-game-sfx.txt` (create; mirror the existing
  per-asset provenance format).
- Add the boss's emoji to the `GlyphWarmer` list in `startAudio()`:
  `🔥 🎵 ✨ 🌹 👏 ❤️ 👒 💃 🕺` at their render sizes.
- Optional (nice-to-have): port the siblings' `HapticPlayer` and tap it on judgments.
- **Commit** ("Boss fight: SFX pack + juice").

## Phase 3 — Bull dance actions in Blender  [Claude]

Follow `prompts/game_bull_actions.md` Phases 2–5 verbatim with three new actions in
`tools/blender/source/bull.blend` (Path B: key the `DEF-`/`*_fk` bones; Rigify controls
are dead; **In-Place**; author as separate Blender actions; export one FBX per action):

- **`stomp` (3 frames):** front-hoof raise → strike + head nod. Used for llamadas,
  demo-stomp, showboat accent.
- **`rear` (4 frames):** rear up on hind legs (seed poses from `throw`'s raised
  head/neck keys), forelegs pawing — the "olé" demo and showboat flourish.
- **`bow` (4 frames):** front legs fold, head sweeps low — the win payoff. The final
  frame must read as a held bow (it freezes during `.victory`).

Render at the bull's proven settings (`--size 512 --view side`, default outline-width 2),
`pack_or_rename.sh rename bull <action>`, **record each union-crop W×H**, add the
imagesets (`bull_stomp_1…` etc. under `Assets.xcassets/Game/`), then wire: frame counts
(3/4/4) in `bullFrameCounts`, crops in `bullCrop`, cases in `bullSpriteActions` +
`bullActionName`. One-shot caveat from the bull plan applies: the half-open `[start,end)`
sampling must keep the final pose — nudge `--end` if the bow's held frame gets cut.
Verify each in the sim with `CONJUGAR_GAME_START_BOSS=1 CONJUGAR_GAME_TIME_SCALE=0.2`
freeze-framing. Extend `asset-licenses/sketchfab-bull.txt`'s shipped-frame list.
**Commit** ("Boss fight: bull stomp/rear/bow sprites").

## Phase 4 — Dancer dance actions in Blender  [Claude]

Follow `prompts/game_dancer_finish_actions.md`'s house style (hand-key the gown rig via
the world-space-rotation script skeleton; shoes stay deleted; subtle leg keys drive the
skirt):

- **`ole` (3 frames):** arms sweep up + back arch, gown flare — proud desplante.
- **`stomp` (3 frames):** sharp weight drop + hip accent → visible hem kick (the feet
  are hidden; the *gown and the thud* sell the zapateado).

Render with the dancer's existing toon/gold/outline settings, crop, install
`dancer_ole_*`/`dancer_stomp_*` imagesets, wire: `playerFrameCounts` (+ole 3, +stomp 3),
`spriteActions`, `actionName`, and `dancerWidth` aspects from the recorded crops
(constant `dancerVisualHeight`; widths differ). Extend the CGTrader license note's
frame list. Freeze-frame verify. **Commit** ("Boss fight: dancer ole/stomp sprites").

## Phase 5 — End-scene polish  [Claude]

Phase 1 shipped the skeleton; finish it: matador slide-to-dancer easing, ❤️🌹 burst,
"¡Victoria!" typography (condensed, gold — match the app's display style), the localized
impressed line, tap-to-exit hint after ~2 s, onboarding-music fade-in timing against the
applause, graceful music fade on exit. Keep the whole scene one view-state — item 4
replaces/extends it later. **Commit** ("Boss fight: end scene").

## Phase 6 — Localization + full verification  [Claude, Josh on-device]

- **Strings** (`L.Game` + `Localizable.xcstrings`, en + es both `"translated"`):
  Spanish-in-both (decision 16): `duelTitle` "¡El duelo!", `tuTurno` "¡Tu turno!",
  `jaleoOle/jaleoUy/jaleoEso/jaleoBien/jaleoVamos`, `victoria` "¡Victoria!". Localized
  normally: `bullImpressed` (en "The bull is impressed — the matador is free!" / es
  "El toro está impresionado — ¡el matador está libre!"), `tapToContinue`, plus
  accessibility labels `oleMove`/`stompMove`/`capeMove`/`duendeMeter`. **Use python3 for
  any value containing ASCII quotes; validate the JSON after every edit** (CLAUDE.md).
- Full test run + swiftlint. Drive the complete arc in the sim: climb → summit → intro
  → fail a phrase on purpose → win → end scene → exit; screenshot each beat
  (`screenshot.sh boss-<beat>`); freeze-frame the bow and the ole with
  `TIME_SCALE=0.2`. Verify the deeplink (`xcrun simctl openurl … conjugar://game/boss`)
  and that quitting mid-duel leaves no music playing on relaunch.
- **Josh, on device:** music crossfades + SFX mix feel, flag emoji render (sim shows "?"
  boxes for flag glyphs — device is truth), button reach/size in the boss cluster.

## Phase 7 — Docs + commit  [Claude]

- `CLAUDE.md` game section: boss fight exists (La Llamada), `Music.bossFight` +
  `Music.onboarding` now wired, the two debug entries, new actions inventory, updated
  five-player-actions sentence (now includes ole/stomp; bull has six actions).
- `tools/blender/README.md`: add the three bull + two dancer actions to the done record.
- `docs/blog_notes.md`: the implementation story (mechanic-first-on-reused-art, the
  hand-keyed bow, freeze fake-out, tug-of-war meter, anything learned).
- Final commit; everything to **`migration`** (raw `.blend`/FBX stay git-ignored).

## Definition of done

- Summit (1st, constant-gated) triggers intro → duel → victory → end scene, all phases
  tap-skippable/exitable, hearts hidden off-climb, climb gameplay byte-identical when
  `phase == .climb`.
- The six-move duel judges correctly incl. freeze; meter/rounds/lengths per spec;
  failure rerolls same-length; no lose state; score accumulates per the values.
- Both actors dance with rendered sprites (bull stomp/rear/bow, dancer ole/stomp) —
  numbered-box fallback never appears; bow holds during victory.
- Boss SFX pack wired + licensed; jaleo pops, shake, crowd, confetti all present;
  `Music.bossFight` loops the duel and `Music.onboarding` scores the end scene, with
  clean fades incl. early exit.
- `conjugar://game/boss` and `CONJUGAR_GAME_START_BOSS` both work.
- `GameBossTests` green alongside the whole existing suite; swiftlint clean; strings in
  en+es per decision 16; CLAUDE.md/README/licenses/blog updated; committed to migration.

## Not in scope (later sessions)

- The five-level climb + four escape beats (flip `summitsToBoss` to 5 then) and item 1's
  extra obstacles/power-ups.
- Scoring UI/persistence/Game Center (item 2) — this plan only accumulates `score`.
- Expanded end scene / credits cinematic (item 4 builds on Phase 5's seam).
- On-beat ¡Olé! timing bonus (hard mode), easy mode with visible chips during echo,
  Info-tab game instructions writeup.

## Gotchas

- **Write tests in Swift Testing, never XCTest** (`@MainActor` suite) — the
  XCTest/isolated-deinit double-free landmine (CLAUDE.md).
- **Boss inputs are taps, not held intents** — reuse the jump touch-down/re-arm idiom;
  a held paso must not fire twice.
- **Frame counts must match the tables exactly** (bull 3/4/4, dancer 3/3) — a mismatch
  silently mis-indexes the flipbook.
- **One-shot bursts:** command the action + set its timer; don't let
  `derivedPlayerAction()`/`derivedBullAction()` run outside `.climb` or they'll stomp
  the commanded poses; cap `bullPhase` on the held bow.
- **In-Place every Blender action** (no root translation) or the auto-fit shrinks the
  sprite; keep the release/held pose inside the half-open `[start,end)` sampling.
- **512-render sprites need `.interpolation(.high)`** (nearest-neighbor frays the cel
  outline — the bull lesson).
- **`.xcstrings`:** never Edit values containing ASCII quotes (use python3); validate
  JSON after every edit; Grep is useless inside it (one-line values).
- **Sim renders flag emoji as "?" boxes** in screenshots — expected; device is truth.
- **New mp3s/imagesets go in synchronized groups** (`Conjugar/Audio/`,
  `Assets.xcassets/Game/`) — zero `project.pbxproj` edits.
- **No `timeout` binary on this machine** — rely on the Bash tool's timeout for
  headless Blender.
- **SourceKit false positives** editing `GameView.swift`/`GameState*` — `build_app.sh`
  is authoritative.
- **Don't regress the climb:** flags/capes/hearts logic is untouched; `reset()` must
  fully restore it (tests cover this).
- **Music on early exit:** ✕ works in every phase — `stopAudio()` must stop whichever
  track is current (fade in `.endScene`, hard-stop elsewhere is fine).
