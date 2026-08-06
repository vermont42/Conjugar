# Plan — Sound & Music Integration (Conjugar game)

**Goal:** add sound effects + looping flamenco background music to the Conjugar game,
using **Conjuguer's proven, performance-safe audio architecture** — so the implementing
session does **not** reintroduce the launch stall / in-game freeze that Conjuguer already
fixed. Reuse SFX from the sibling apps + Pixabay, source permissively-licensed flamenco
music, wire everything into the game, and update the existing `Info.creditsText` with
licenses. Fresh-session task; read the context first.

## Read first (the "why" and the reference implementation)
1. **`/Users/josh/Desktop/workspace/Blog/ideation/ai-doomers-are-wrong.md`** — the
   first-hand debugging story of *this exact class of freeze*. The lessons: (a) the first
   `AVAudioPlayer` cold-starts the whole audio stack **on the main thread (~1.6 s stall)** →
   warm it **off-main**; (b) first rasterization of a large **color emoji glyph (flags!)**
   stalls the render thread ~0.5 s → **pre-warm glyphs off-main**; (c) **pre-decode SFX
   off-main** to kill the last blips. This is the performance mandate.
2. **Conjuguer's audio code** (the gold standard to port), all under
   `/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/`:
   `Utils/SoundPlayer.swift` (protocol), **`Utils/SoundPlayerReal.swift`** (the important
   one, 168 lines), `Utils/SoundPlayerDummy.swift`, `Utils/AudioSession.swift`,
   `Models/Sound.swift`, and the DI wiring in `Utils/World.swift` + the launch call in
   `App/ConjuguerApp.swift`.
3. **The commits to cite** (in Conjuguer's git history):
   - **`9bb4f3e`** (Jun 26 2026, *"game: fix soccer-ball overdamage and eliminate launch
     and in-game freezes"*) — **THE performance commit.** Introduced the off-main audio-stack
     warm-up, off-main SFX pre-decode (`warmUpSounds`, `Sound: CaseIterable`), the concurrent
     `playbackQueue` that absorbs the blocking `play()`, and `GlyphWarmer`.
   - **`270052a`** (Jul 8 2026) — per-sound debounce clocks (`instantOfLastPlayBySound`).
   - **`5d5beba`** (Jun 24 2026) — where the protocol-injected design + looping music were
     born (context).
   Inspect with e.g. `git -C /Users/josh/Desktop/workspace/Conjuguer show 9bb4f3e -- Conjuguer/Utils/SoundPlayerReal.swift`.
4. `docs/game_design_research.md` **§4** (SFX-reuse + CC-BY music decision), and
   `prompts/game_prototype.md` / `prompts/game2.md` (the game this wires into).

## Conjugar's current state (the "before" picture — must be replaced)
- **`Conjugar/Utils/SoundPlayer.swift`** is a **static** class that **lazily creates each
  `AVAudioPlayer` on first play, on the main thread** (`SoundPlayer.swift:40-49`) — literally
  the anti-pattern the blog describes. It caches players and has a single-clock debounce.
- **`Conjugar/Utils/Utterer.swift`** is the **single owner of the shared `AVAudioSession`**,
  configured **once** at launch as **`.ambient`** (`Utterer.swift:27-37`) — the app's
  deliberate contract: respect the silent switch, mix with the user's music. It also plays
  `SoundPlayer.play(.silence)` after each utterance (Apple-forum warm-up trick).
- **`Conjugar/Models/Sound.swift`** — `enum Sound: String` with applause1-3, chime, chirp,
  buzz, gun, sadTrombone1-4, silence. **Not** `CaseIterable`. `mp3` files in the bundle.
- **No looping-music player exists.** Existing static call sites to be aware of:
  `GameCenterReal.swift:56`, `CommunView.swift:109`, `TutorView.swift:290,300`,
  `TutorTestView.swift:203,219,227`, `QuizView.swift:64,245`, `Utterer.swift:49`.

---

## The performance recipe (non-negotiable — port all five from Conjuguer `9bb4f3e`)
1. **One cached `AVAudioPlayer` per sound**, created once and reused — never one-per-play.
2. **Warm the audio stack off the main thread at app launch.** `setup()` keeps only the
   cheap session config synchronous, then `Task.detached(priority: .userInitiated)` →
   `warmUpAudioStack()` (create a silent primer player, `prepareToPlay()`, `play()` at
   volume 0). This **replaces** the old synchronous `play(.silence)` prime.
3. **Pre-decode + `prepareToPlay()` all SFX off-main at game start.** `warmUpSounds()`
   iterates `Sound.allCases` on a background queue, builds+prepares each player, then merges
   them back on the main actor (`PreparedSoundsBox`). Called from the game's `configure()`.
4. **Dispatch the blocking `play()` to a concurrent background queue.**
   `AVAudioPlayer.play()` blocks its caller ~20–87 ms (audio-server round trip) and stutters
   the game loop. Configure the player (volume) on the main actor, then `playbackQueue.async
   { box.player.play() }` (concurrent queue so rapid SFX don't serialize). Cross the
   isolation boundary with an `@unchecked Sendable` `PlayerBox` (mutation of the `sounds`
   dict stays on the main actor; `play()` is documented safe off-main).
5. **Per-sound debounce clocks** (`instantOfLastPlayBySound: [Sound: TimeInterval]`, 1 s
   window) so a chatty non-debounced SFX can't reset a debounced one's window (`270052a`).

**Music:** a plain `AVAudioPlayer`, `numberOfLoops = -1` (gapless infinite loop), a ~2 s
fade-in, an optional random start offset, and save/restore of the playhead across
stop/start. Created lazily in `startMusic()` (the one-time decode happens on the "start
game" tap, not in the loop — acceptable). Lifecycle tied to the **game view**: start on
`configure()`/`restart()`, stop on game-over and in `GameView.onDisappear`.

---

## Phase 0 — Architecture decisions (SETTLED by Josh)

**A — Full DI port (DECIDED).** Port Conjuguer's **protocol-injected** design: a
`SoundPlayer` protocol + `SoundPlayerReal` + `SoundPlayerDummy`, wired into `World` as
`Current.soundPlayer` (`Real` in `.device`/`.simulator`, **`Dummy` in `.unitTest`/`.uiTest`**
so tests never touch CoreAudio — matches the `LanguageModelService…Real/Dummy` convention and
CLAUDE.md's DI rules). **Migrate every existing static `SoundPlayer.play(…)` call site** —
`GameCenterReal.swift:56`, `CommunView.swift:109`, `TutorView.swift:290,300`,
`TutorTestView.swift:203,219,227`, `QuizView.swift:64,245`, `Utterer.swift:49` — to
`Current.soundPlayer.play(…)`, then **delete the old static `SoundPlayer`**. No static
fallback; the DI seam is the entire audio system.

**B — Keep `.ambient` (DECIDED).** `Utterer` remains the **single** `AVAudioSession` owner,
configured once as **`.ambient`** (respects the silent switch, mixes with the user's music) —
the game's music/SFX inherit that contract. **Do not add a second session owner** (that
last-writer-wins race was deliberately removed), and **do not port Conjuguer's `.playback`
`AudioSession.configure()`** as a competing owner. *(Future option, not now: if the game
should play over a muted ring switch, do a **scoped** switch — `.playback` on
`GameView.onAppear`, restore `.ambient` on `.onDisappear` — never a global change.)*

## Phase 1 — Port the performant audio core
- Copy/adapt `SoundPlayer.swift`, `SoundPlayerReal.swift`, `SoundPlayerDummy.swift` into
  `Conjugar/Utils/` (Utils is a synchronized group → files auto-add, no `project.pbxproj`
  edit). **Do not port `AudioSession.swift`** (Decision B): `Utterer` already owns the session
  as `.ambient`, so the ported `SoundPlayerReal.setup()` must **drop its
  `AudioSession.configure()` call** and only do the off-main warm-up — and `Utterer.setup()`
  must run first, so the session is configured before any play.
- Extend `Conjugar/Models/Sound.swift`: add `: CaseIterable`, and the new game cases (see
  Phase 3). Keep `silence`.
- Wire `var soundPlayer: SoundPlayer` into `Conjugar/Models/World.swift` (Real for
  device/simulator, Dummy for unitTest/uiTest). Call `Current.soundPlayer.setup()` at app
  launch, **after `Utterer.setup`** (so the `.ambient` session is configured first).
- Migrate the existing static call sites to `Current.soundPlayer`. Reconcile `Utterer`'s
  post-utterance `.silence` play with the new off-main warm-up (the launch warm-up now
  primes the stack; keep or drop the per-utterance `.silence` as needed).

## Phase 2 — Identify game sound touchpoints + reuse map
Reusable from the siblings **today** (SFX are mostly byte-identical between the two repos;
pull from either — `coin`/`cow`/`horse`/etc. are Konjugieren-only):

| Game event | Reuse | Notes |
|---|---|---|
| **Jump** | `pop` (0.72 s) | short punchy blip |
| **Flag hits player / cape-smash** | `soccerKick` (whack) or `chomp` | impact; `soccerKick` reads most physical |
| **Cape pickup** | `coin` (Konj.) or `chime` | classic collectible cue |
| **Bull throws flag** | `cow` or `horse` (Konj.) | bull-bellow stand-in; or a Pixabay bull snort |
| **Ladder climb** | `chirp` retriggered low-volume, **debounced** | no perfect loop; or author one |
| **Reach bull / rescue / level clear** | `randomApplause` | celebration |
| **Health 0 / reset** | `randomSadTrombone` (Conjugar already has 1-4) or `playerHit` | sad-trombone = the classic loss cue |
| **Cape active / power-up** | `shieldActivate` / `magicActivate` | optional flourish |
| **Background music** | flamenco loop (Phase 3) | port the loop mechanism verbatim |

Conjugar already ships `applause1-3`, `chime`, `chirp`, `buzz`, `gun`, `sadTrombone1-4` —
reuse those directly; import `pop`, `chomp`, `soccerKick`, `playerHit`, `coin`, `cow`/`horse`
(and any others chosen) from the siblings.

## Phase 3 — Acquire assets
- **From the siblings:** copy the chosen `.mp3`s from
  `…/Conjuguer/Conjuguer/Assets/Sounds/` and/or `…/Konjugieren/Konjugieren/Assets/Sounds/`
  into Conjugar's bundle **beside its existing sound files** (locate them first, e.g.
  `git -C . ls-files '*.mp3'`, and co-locate / match how they're referenced by
  `Bundle.main.url(forResource:withExtension:"mp3")`).
- **From Pixabay** (`pixabay.com`), for anything the siblings lack (bull snort/bellow,
  flamenco *olé*/hand-claps, castanets, cape *whoosh*): Pixabay Content License — commercial
  OK, **no attribution required**, don't redistribute the raw file standalone. **If Pixabay
  is blocked via WebSearch/WebFetch, use the Claude-in-Chrome MCP** to search/download.
- **Flamenco music** (decision from research §4.1 — **CC-BY is acceptable**): the primary
  pick is a **CC-BY** track — **casimps1 "Vaguely Spanish Guitar" (CC-BY 3.0, ccMixter)** or
  **BFCMUSIC "Luna de Fuego" (CC-BY 4.0, FMA)** — loop-edited to a clean 8–16-bar section in
  Audacity (zero-crossing cut + tail crossfade). A **Pixabay** flamenco track (no
  attribution) is the no-credit alternative. Prefer a **short purpose-made loop** over a
  full 6-minute track (the siblings loop full classical pieces, but a tight loop suits a
  game better). Add as `mp3` (matches `soundExtension`). Keep the licence certificate/deed.
- **Format note:** mp3 + the off-main pre-decode is proven fine. Optionally use
  **`.wav`/`.caf` for SFX** to drop the decode step entirely (then `warmUpSounds` mainly does
  `prepareToPlay`). Music stays a compressed format (size).

## Phase 4 — Wire it in
- Call `Current.soundPlayer.play(.x)` at the Phase-2 touchpoints in `GameState`/`GameView`.
  Pass `shouldDebounce: true` for anything that can fire every frame (climb, continuous flag
  contact); `false` for discrete events (jump, pickup, reach-bull).
- Music: `startMusic()` in `GameState.configure()`/`restart()`, `stopMusic()` on game-over
  and in `GameView.onDisappear` (mirror Conjuguer's lifecycle).
- Call `warmUpSounds()` from the game's `configure()` (off-main pre-decode at game start).
- **Also warm the emoji glyphs off-main** (flags/cape/bullfighter) via a `GlyphWarmer` at
  game start — same commit `9bb4f3e`, same blog lesson (flag emoji are the worst offender).
  If the prototype (game2.md) already does this, confirm it; otherwise port `GlyphWarmer`.
- **Optional settings gate** (Konjugieren's pattern): add a "Sounds" on/off toggle to
  `Settings` and early-return in `play`/`startMusic` when disabled. Fits Conjugar's existing
  Settings pickers; recommended but not required.
- **Same-sound overlap:** one player per sound means the *same* SFX won't layer on itself.
  Fine for this game (flags mostly hit one at a time). Only if you need many *identical*
  simultaneous impacts, add a small per-sound voice pool — the one thing Conjuguer's design
  doesn't provide.

## Phase 5 — Credits + license paper trail
Append to the existing **`Info.creditsText`** (an Info-tab entry; `L.Info.creditsText`,
key in `Conjugar/Supporting/Localizable.xcstrings` ~line 660) — **both `en` and `es`**.
- Use the **exact TASL template already in the credits' "App Preview" section** for the
  music (it credits Kevin MacLeod's "Arroz Con Pollo" as `Track by Artist / Link: / License:`).
  Add a **"Game Music"** block in that form for the flamenco track.
- Add a **"Game Sounds"** block: for each reused SFX, **trace its original license** (check
  the siblings' own credits / `asset-licenses`) and mirror that credit; for Pixabay grabs,
  add a courtesy Pixabay note (no attribution legally required). The existing **"Sound Jay"**
  block covers the *original* Conjugar sounds — leave it; new game sounds get their own block.
- Preserve the Info rich-text markup (`^heading^`, `~emphasis~`, `%url%`, `\n\n` blocks).
- **Edit `.xcstrings` via `python3`, not the Edit tool** (the ASCII-quote foot-gun — see
  CLAUDE.md "Editing `Localizable.xcstrings` safely"), and validate:
  `python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"`.
- Add each sourced asset (music deed, Pixabay certificates) to an **`asset-licenses/`**
  folder (per research §4).

## Phase 6 — Verify (performance IS the acceptance criterion)
- Build (`~/.claude/skills/ios-build-verify/scripts/build_app.sh`), run, open **Settings →
  Play**. Confirm SFX fire at the right events and the flamenco music loops with a fade-in.
- **The bar is: no launch stall, and no mid-game freeze** on the first sound / first flag
  emoji. If any hitch appears, use the blog's method: temporary timestamped `@@@` logs around
  first-play / first-glyph-draw / each subsystem, find the cold path, move it off-main, then
  strip the instrumentation. Don't guess — measure.
- **Tests (Swift Testing, never XCTest):** the unitTest world uses `SoundPlayerDummy`, so
  suites stay silent and fast. Add a small check that `Current.soundPlayer` is the Dummy in
  the test world.
- Lint: `swiftlint`.

## Definition of done
- Game has event SFX + looping flamenco music, all through a **protocol-injected**
  `Current.soundPlayer` (Real/Dummy), matching Conjuguer.
- **Warm-off-main everywhere** (audio stack at launch, SFX pre-decode + emoji glyphs at game
  start); blocking `play()` dispatched to the concurrent `playbackQueue`. **No launch stall,
  no in-game freeze.**
- `Info.creditsText` (en + es) updated with Game Music (TASL) + Game Sounds credits;
  `asset-licenses/` holds the deeds/certificates. `.xcstrings` validates.
- Build green, SwiftLint clean, tests silent (Dummy in test worlds).

## Gotchas
- **Never** create an `AVAudioPlayer` on the main thread on demand / per-frame — that's the
  regression this whole plan exists to prevent.
- **Don't add a second `AVAudioSession` owner** — `Utterer` owns it; decide the category
  there (Decision B).
- Music is a long file → decode once, lazily, at the start-game tap (never in the loop). A
  short purpose-made loop is better than looping a 6-minute track.
- `.xcstrings` foot-guns: `python3` only, validate JSON, target the correct `en`/`es`
  section via a unique nearby anchor word.
- Cite **`9bb4f3e`** (perf) and **`270052a`** (debounce) in the commit message when you land
  this, and add a `docs/blog_notes.md` entry (per CLAUDE.md).
