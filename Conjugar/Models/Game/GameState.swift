//
//  GameState.swift
//  Conjugar
//
//  The @Observable core of the Donkey-Kong-inspired flamenco/bull game — the
//  five-stage climb "La Subida" (per-stage obstacle sets + compounding speed, three
//  rotating power-ups, three rotating challenge mechanics, and between-stage escape
//  beats) capped by the "La Llamada" dance-off boss. Follows the sibling apps' house
//  pattern (Conjuguer/Konjugieren): a single `@MainActor @Observable final class`
//  holding all state and tuning constants, driven by `TimelineView(.animation)` via
//  `update(currentTime:)`. Entities are value-type structs (see GameModels.swift).
//  The logic is split across extensions — `GameState+Physics` (movement/climb/jump),
//  `GameState+Obstacles` (the rolling obstacle sets), `GameState+Stages` (the five
//  stages, escape beats, soft respawn), `GameState+PowerUps` (cape/speed/serenata),
//  `GameState+Mechanics` (zombie/encierro/apagón), `GameState+BossFight` (La Llamada),
//  and `GameState+Animation` (the sprite flipbook) — so any state those extensions
//  touch is declared internal (not private).
//
//  The player and bull are rendered cel-shaded sprite flipbooks (see GameView and
//  GameState+Animation); a numbered-box fallback survives only as a safety net for an
//  uncovered action. The matador is a static `Image("matador")`.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class GameState {
  // MARK: Tuning constants (placeholders — tweak to taste)

  static let levelCount = 6
  static let sideMargin: CGFloat = 8
  static let platformThickness: CGFloat = 14
  static let ladderWidth: CGFloat = 34

  static let playerWidth: CGFloat = 44
  static let playerHeight: CGFloat = 30
  static let bullSize: CGFloat = 70
  static let bullfighterSize: CGFloat = 40
  static let obstacleSize: CGFloat = 30
  /// Collision size for an obstacle — deliberately smaller than its drawn box.
  /// Obstacle emoji sit inside transparent glyph padding, so the full 30 pt box
  /// registers "phantom" hits when a jump has visually cleared the obstacle. This
  /// tighter box makes the rule honest: if the player's arc doesn't touch the
  /// obstacle, it doesn't cost health.
  static let obstacleHitSize: CGFloat = 20
  static let capeSize: CGFloat = 34

  static let gravity: CGFloat = 1400
  static let playerSpeed: CGFloat = 150
  static let climbSpeed: CGFloat = 110
  // Jumping is for dodging enemies only — deliberately too weak to reach the
  // next platform up (max hop ≈ jumpImpulse² / 2·gravity, kept below the gap).
  static let jumpImpulse: CGFloat = 360
  static let climbTolerance: CGFloat = 34

  /// Stage-1 obstacle roll speed; each later stage multiplies by `stageSpeedFactor`
  /// (see `obstacleSpeed`).
  static let obstacleRollSpeed: CGFloat = 95
  static let obstacleSpawnInterval: Double = 2.0
  static let bullThrowDuration: Double = 0.5
  static let bullPaceSpeed: CGFloat = 42

  // MARK: Stage system (La Subida — five stages; see GameState+Stages.swift)

  static let stageCount = 5
  /// Obstacle speed grows +5% per stage, compounding (`obstacleSpeed`).
  static let stageSpeedFactor: CGFloat = 1.05
  /// Upward flee speed of the bull + matador during a between-stage escape beat.
  static let escapeRiseSpeed: CGFloat = 260
  /// Post-respawn damage grace so the player isn't hit again the instant it reappears.
  static let respawnGrace: Double = 1.0

  // 5 s solid, then a 2 s expiry blink that ends the power-up (see `isCapeVisible`).
  static let capeDuration: Double = 7
  static let capeBlinkDuration: Double = 2
  static let maxHealth = 4
  static let damageCooldownDuration: Double = 1.0

  // MARK: Power-ups (La Subida — speed ⚡ + La Serenata 🎸; see GameState+PowerUps.swift)

  /// Speed pickup lasts the same 7 s (5 s solid + 2 s expiry blink) as the cape.
  static let speedDuration: Double = 7
  /// Speed pickup multiplier: walk AND climb speed ×2 while active.
  static let speedFactor: CGFloat = 2
  /// La Serenata lasts the same envelope: the bull dances instead of throwing.
  static let serenataDuration: Double = 7
  /// Seconds between the bull's serenata dance bursts.
  static let serenataDanceInterval: Double = 1.2

  // MARK: Challenge mechanics (La Subida — one kind per stage; see GameState+Mechanics.swift)

  /// A mechanic's first appearance within a stage lands at a random point in this
  /// window (a fresh climb has a little breathing room before the first disruption).
  static let mechanicFirstDelay: ClosedRange<Double> = 10...18
  /// After a mechanic's window ends it re-arms this many seconds later (it re-fires
  /// through the rest of the stage).
  static let mechanicRepeatDelay: Double = 25
  /// Zombie attack (Josh's spec): for `zombieDuration` seconds every on-screen
  /// obstacle slows to `zombieSpeedFactor`× and homes toward the player.
  static let zombieDuration: Double = 3
  static let zombieSpeedFactor: CGFloat = 0.5
  /// El Encierro window: 🐂 chargers stampede across the girders for this long.
  static let encierroDuration: Double = 4
  /// A charger crosses at this multiple of the stage's obstacle speed (2× — fast).
  static let chargerSpeedFactor: CGFloat = 2
  static let chargerSize: CGFloat = 30
  /// Collision size for a charger — deliberately smaller than its drawn box (the
  /// honest-hitbox rule, mirroring `obstacleHitSize`): a jump that visually clears the
  /// 🐂 costs no health.
  static let chargerHitSize: CGFloat = 20
  /// A fresh charger enters this often while the encierro window is open.
  static let chargerSpawnInterval: Double = 0.8
  /// El Apagón window: for `apagonDuration` seconds the lights cut to a near-black
  /// overlay with a soft spotlight tracking the dancer (`updateApagon` drives the
  /// envelope; `GameView` renders the mask). HUD/controls stay lit.
  static let apagonDuration: Double = 3.5
  /// The darkness fades in over this long, holds, then fades back out over `apagonFadeOut`.
  static let apagonFadeIn: Double = 0.3
  static let apagonFadeOut: Double = 0.4
  /// Peak opacity of the blackout overlay (0.88 = near-black, a sliver of ambience left).
  static let apagonDimOpacity: Double = 0.88
  /// Radius (pt) of the soft spotlight the overlay punches around the dancer.
  static let apagonSpotlightRadius: CGFloat = 120

  /// Sprite flipbook speed (RaceRunner's rate).
  static let fps = 10

  // MARK: Boss-fight tuning (La Llamada — see prompts/game_boss_llamada.md)

  /// Summits before the boss triggers: five stages, so summits 1–4 are escape beats
  /// (the bull flees upward carrying the matador) and the 5th triggers La Llamada.
  static let summitsToBoss = 5
  static let bossTransitionDuration = 0.8
  static let introDuration = 2.0
  /// Bull-demo seconds per move, indexed by round (0-based) — playback speeds up.
  static let demoStepDurations = [0.9, 0.75, 0.6]
  /// After the bull demos the LAST move, the full sequence of cue chips lingers this
  /// much longer before "¡Tu turno!" clears them — a recall beat so the final step is
  /// memorable, which matters most for the 5-step round-3 phrases.
  static let demoRecallHold = 1.0
  static let echoTimePerMove = 1.5
  static let echoGrace = 2.0
  static let freezeHold = 1.2
  static let phraseResultHold = 0.9
  static let showboatDuration = 2.0
  /// The shorter strut after a failed phrase.
  static let showboatLiteDuration = 1.0
  static let meterNotches = 6
  /// Phrase length per round (0-based). Round 3 (index 2) is freeze-eligible.
  static let phraseLengths = [3, 4, 5]
  static let movePoints = 50
  static let phraseBonus = 200
  static let bossClearBonus = 2_000
  /// How long an actor holds a commanded dance burst before falling back to idle.
  static let danceBurstDuration = 0.5
  static let screenShakeDuration = 0.25
  static let screenShakeMagnitude: CGFloat = 9
  static let jaleoPopDuration = 1.2
  /// Default jaleo drift speed (pt/s) — the gentle score-pop rise.
  static let jaleoDriftRise: CGFloat = 26
  /// The dancer's spoken jaleos (¡Eso!/¡Bien!/¡Olé!…) float from just above her head up
  /// to this fraction of the screen height (the sight-line marked in the design
  /// annotation) over `jaleoSpeechDuration`, filling the otherwise-dead upper field.
  static let jaleoRiseTargetFraction: CGFloat = 0.42
  /// The slower fade for the dancer's spoken jaleos, so a word stays legible the whole
  /// long climb to the sight-line.
  static let jaleoSpeechDuration = 2.6
  static let victoryHold = 1.5
  /// A held beat after the end scene opens before the freed matador starts walking
  /// over — the applause + confetti land first, then he moves.
  static let matadorSlideDelay = 0.6
  static let matadorSlideDuration = 2.0
  static let endSceneMusicFade = 1.0
  /// Two seconds into the end scene the dancer turns to face the matador sliding in
  /// from her right.
  static let endSceneDancerTurnDelay = 2.0
  /// The end scene keeps living after the couple reunites: the freed bull dances —
  /// every `endSceneDanceInterval` it performs one randomly-chosen animated move (its
  /// position never changes; one option is walking in place) held for
  /// `endSceneDanceMoveDuration`, and moos at a random cadence in `endSceneMooIntervalRange`.
  /// Hearts/roses keep flying up from the pair at a random cadence in
  /// `endSceneBurstIntervalRange` (re-rolled each firing so the loop never feels metronomic).
  static let endSceneDanceInterval = 2.0
  static let endSceneDanceMoveDuration = 1.6
  static let endSceneMooIntervalRange = 4.0...8.0
  /// The bull's celebratory-dance repertoire: every animated move he has, including
  /// `walk` (danced in place). Re-rolled each `endSceneDanceInterval`.
  static let endSceneDanceMoves: [BullAction] = [.walk, .stomp, .rear, .bow, .throw]
  static let endSceneBurstIntervalRange = 2.0...4.0
  static let bossPedestalSize = CGSize(width: 48, height: 12)

  /// Global time multiplier for the game loop — 1 in normal play. Setting the
  /// `CONJUGAR_GAME_TIME_SCALE` launch environment variable (e.g. `0.1`) slows
  /// the whole simulation down uniformly, so individual animation frames (a
  /// jump's apex, a climb/cape pose) can be caught in a screenshot.
  static let debugTimeScale: CGFloat = {
    if let raw = ProcessInfo.processInfo.environment["CONJUGAR_GAME_TIME_SCALE"],
       let value = Double(raw), value > 0 {
      return CGFloat(value)
    }
    return 1
  }()

  /// When the `CONJUGAR_GAME_DISABLE_FLAGS` launch environment variable is set,
  /// the bull throws no flags — a calmer field for capturing player animations.
  static let debugFlagsDisabled = ProcessInfo.processInfo.environment["CONJUGAR_GAME_DISABLE_FLAGS"] != nil

  /// When the `CONJUGAR_GAME_START_BOSS` launch environment variable is set, the
  /// game jumps straight to the boss intro on configure — the fast path for driving
  /// the duel in the simulator (composes with `CONJUGAR_GAME_TIME_SCALE`).
  static let debugStartAtBoss = ProcessInfo.processInfo.environment["CONJUGAR_GAME_START_BOSS"] != nil

  /// When the `CONJUGAR_GAME_START_END` launch environment variable is set, the game
  /// jumps straight to the boss's end scene on configure (the couple reunited, bull
  /// bowing) — the fast path for tuning the end-scene loop. Also reachable via the
  /// `conjugar://game/end` deeplink.
  static let debugStartAtEnd = ProcessInfo.processInfo.environment["CONJUGAR_GAME_START_END"] != nil

  /// With `CONJUGAR_GAME_START_BOSS`, the `CONJUGAR_GAME_BOSS_BANKED` launch
  /// environment variable pre-fills the Duende meter (clamped to 0…5) — e.g. `5`
  /// starts the duel one phrase from victory, for testing the win/end-scene beats
  /// without playing the whole fight.
  static let debugBossBanked: Int? = {
    guard let raw = ProcessInfo.processInfo.environment["CONJUGAR_GAME_BOSS_BANKED"],
          let value = Int(raw) else {
      return nil
    }
    return value
  }()

  /// When the `CONJUGAR_GAME_STAGE` launch environment variable is set (1…`stageCount`),
  /// the climb starts at that stage — `configure` sets `summitCount = N − 1` and
  /// `stage = N` so the stage's obstacle set/speed take effect immediately. Composes
  /// with `CONJUGAR_GAME_TIME_SCALE` / `CONJUGAR_GAME_DISABLE_FLAGS`.
  static let debugStartStage: Int? = {
    guard let raw = ProcessInfo.processInfo.environment["CONJUGAR_GAME_STAGE"],
          let value = Int(raw), (1...stageCount).contains(value) else {
      return nil
    }
    return value
  }()

  /// When the `CONJUGAR_GAME_POWERUP` launch environment variable is set to
  /// `cape` / `speed` / `serenata`, every stage's power-up draw is forced to that
  /// kind (the shuffle bag is bypassed) — the fast path for verifying one effect.
  static let debugForcedPowerUp: PowerUpKind? = {
    switch ProcessInfo.processInfo.environment["CONJUGAR_GAME_POWERUP"] {
    case "cape": return .cape
    case "speed": return .speed
    case "serenata": return .serenata
    default: return nil
    }
  }()

  /// When the `CONJUGAR_GAME_MECHANIC` launch environment variable is set to
  /// `zombie` / `encierro` / `apagon`, every stage's challenge-mechanic draw is forced
  /// to that mechanic (the shuffle bag is bypassed) AND its countdowns are shortened
  /// to ~2 s (both the first delay and the re-arm) so the effect fires almost at once
  /// and loops quickly — the fast path for verifying one mechanic in the simulator.
  static let debugForcedMechanic: ChallengeMechanic? = {
    switch ProcessInfo.processInfo.environment["CONJUGAR_GAME_MECHANIC"] {
    case "zombie": return .zombie
    case "encierro": return .encierro
    case "apagon": return .apagon
    default: return nil
    }
  }()

  // The five stages' obstacle sets (decision 2). Stage 1 is the original flags; the
  // rest were locked with Josh 2026-07-14. Avoid plain ⚡ anywhere — it's the speed
  // pickup. `stageObstacleEmojis` indexes these by `stage - 1`.
  static let flagEmojis = [
    "🇪🇸", "🇲🇽", "🇦🇷", "🇨🇴", "🇵🇪", "🇨🇱", "🇻🇪", "🇪🇨", "🇬🇹", "🇨🇺",
    "🇧🇴", "🇩🇴", "🇭🇳", "🇵🇾", "🇸🇻", "🇳🇮", "🇨🇷", "🇺🇾", "🇵🇦"
  ]
  static let animalEmojis = ["🐎", "🐖", "🐑", "🐐", "🐄"]
  static let ballEmojis = ["⚽", "🏀", "🎾", "⚾", "🏐", "🏉"]
  static let vehicleEmojis = ["🚗", "🚕", "🚌", "🏎️", "🛵", "🚜"]
  static let skyEmojis = ["☀️", "⛅", "☁️", "🌧️", "🌩️", "🌪️"]

  /// Per-stage obstacle emoji, indexed by `stage - 1`.
  static let stageObstacleEmojis: [[String]] = [flagEmojis, animalEmojis, ballEmojis, vehicleEmojis, skyEmojis]
  /// Per-stage render style (decision "Per-set rendering"): flags/balls spin like
  /// barrels, animals/vehicles face their travel, sky glyphs stay upright.
  static let stageObstacleStyles: [ObstacleStyle] = [.spin, .face, .spin, .face, .upright]

  // MARK: World

  var screenSize: CGSize = .zero
  var didConfigure = false
  var platforms: [Platform] = []
  var ladders: [Ladder] = []
  var obstacles: [Obstacle] = []
  var powerUps: [PowerUp] = []
  var obstacleCounter = 0
  /// The kind of power-up this stage spawns, drawn from `powerUpBag` at each stage
  /// transition (and the initial stage). All of a stage's pickups share this kind.
  var stagePowerUpKind: PowerUpKind = .cape
  /// Shuffle bag for the per-stage power-up kinds (Konjugieren's `mechanicBag`
  /// idiom): drawn one per stage, refilled + reshuffled through `bossRNG` when empty,
  /// so a kind never repeats until all three have appeared.
  var powerUpBag: [PowerUpKind] = []
  /// The current stage, 1…`stageCount`. Invariant during the climb: `stage ==
  /// summitCount + 1`. Drives the obstacle set (`stageEmojis`), speed
  /// (`obstacleSpeed`), and render style (`stageObstacleStyle`).
  var stage = 1

  // MARK: Challenge-mechanic state (see GameState+Mechanics.swift)

  /// This stage's challenge mechanic, drawn from `mechanicBag` at each stage
  /// transition (and the initial stage). It's what `startMechanic` fires.
  var assignedMechanic: ChallengeMechanic = .zombie
  /// Shuffle bag for the per-stage mechanics (Konjugieren's `mechanicBag` idiom):
  /// drawn one per stage, refilled + reshuffled through `bossRNG` when empty, so a
  /// mechanic never repeats until all three have appeared.
  var mechanicBag: [ChallengeMechanic] = []
  /// The mechanic currently disrupting the climb, or nil when none is active. While
  /// non-nil the scheduler counts down `mechanicRemaining` instead of `mechanicCountdown`.
  var activeMechanic: ChallengeMechanic?
  /// Seconds until the next mechanic fires (ticks only while `activeMechanic == nil`).
  var mechanicCountdown: Double = 0
  /// Seconds left in the active mechanic's window (ticks only while one is active).
  var mechanicRemaining: Double = 0

  // El Encierro (Phase 4): the 🐂 charger stampede. Chargers run straight across a
  // girder; they spawn only while the window is open but stragglers keep crossing
  // after it closes (see GameState+Mechanics.swift).
  var chargers: [Charger] = []
  var chargerCounter = 0
  /// Countdown to the next charger spawn (ticks only while the encierro window is open).
  var chargerSpawnTimer: Double = 0
  /// Whether this encierro window has already sent a charger down the player's girder
  /// — the window's first charger targets it (the stampede must threaten the player at
  /// least once), the rest pick a random girder. Reset at each window start.
  var encierroCoveredPlayerLevel = false

  // El Apagón (Phase 5): the lights-out spotlight. `apagonDim` is the 0…1 darkness of
  // the blackout overlay, driven by `updateApagon` from the active window's remaining
  // time and snapped to 0 whenever the window ends or is cancelled.
  var apagonDim: CGFloat = 0

  // MARK: Player state

  var playerX: CGFloat = 0
  var playerY: CGFloat = 0
  var playerVelocityY: CGFloat = 0
  var playerGrounded = true
  var playerClimbing = false
  var climbingLadder: Int?
  var playerLevel = 0
  var playerFacing: CGFloat = 1
  var playerPhase: Double = 0
  var playerAction: PlayerAction = .idle

  // Intent booleans set by the on-screen controls, consumed each frame.
  var movingLeft = false
  var movingRight = false
  var movingUp = false
  var movingDown = false

  var capedRemaining: Double = 0
  /// Seconds of the speed power-up (⚡) remaining — while > 0, walk + climb double.
  var speedRemaining: Double = 0
  /// Seconds of La Serenata (🎸) remaining — while > 0, the bull dances instead of
  /// pacing/throwing (see GameState+PowerUps.swift).
  var serenataRemaining: Double = 0
  /// Countdown to the bull's next serenata dance burst (the `bullThrowTimer` idiom).
  var serenataDanceTimer: Double = 0
  var health = GameState.maxHealth
  var damageCooldown: Double = 0

  var isCaped: Bool { capedRemaining > 0 }

  /// Whether the cape overlay should be drawn this frame. Gameplay (`isCaped`) stays
  /// true for the whole `capeDuration`; only the *visual* blinks. During the power-up's
  /// final `capeBlinkDuration` seconds it flashes ~5×/s to warn the player it's about
  /// to expire, then "blinks out of existence" when the cape ends. Shares the blink
  /// envelope with the speed badge via `powerUpVisible(remaining:)`.
  var isCapeVisible: Bool { powerUpVisible(remaining: capedRemaining) }

  /// Whether the up control should be shown: the player is standing in front of a
  /// ladder whose base is on this level (so pressing up would start a climb), or is
  /// already climbing. Drives the up button's appearance (per the game2 tweaks).
  var canClimbUp: Bool {
    if playerClimbing { return true }
    guard playerGrounded else { return false }
    return ladders.contains { abs(playerX - $0.x) < Self.climbTolerance && $0.lowerLevel == playerLevel }
  }

  /// Whether the down control should be shown: the player is standing directly above
  /// a ladder whose top is on this level, or is already climbing.
  var canClimbDown: Bool {
    if playerClimbing { return true }
    guard playerGrounded else { return false }
    return ladders.contains { abs(playerX - $0.x) < Self.climbTolerance && $0.upperLevel == playerLevel }
  }

  // MARK: Bull state

  var bullX: CGFloat = 0
  var bullY: CGFloat = 0
  var bullDirection: CGFloat = 1
  var bullFacing: CGFloat = 1
  var bullPhase: Double = 0
  var bullAction: BullAction = .idle
  var bullThrowTimer: Double = 0
  var obstacleSpawnTimer: Double = GameState.obstacleSpawnInterval

  var bullfighterX: CGFloat = 0
  var bullfighterY: CGFloat = 0
  /// The matador's climb-phase perch beside the bull (set by `buildLevel`); the boss
  /// moves him to a pedestal, and `reset()` restores him here.
  var bullfighterHomeX: CGFloat = 0
  var bullfighterHomeY: CGFloat = 0

  // MARK: Boss-fight state (La Llamada — mechanics in GameState+BossFight.swift)

  var phase: GamePhase = .climb
  var summitCount = 0
  /// Accumulating score (decision 3: undisplayed for now; +50/move, +200×round/phrase,
  /// +2,000 boss clear). The scoring work item adds display/persistence later.
  var score = 0
  /// Banked phrases 0…meterNotches — the Duende meter AND the fight's progress.
  var banked = 0
  var duelState: DuelState = .bullDemo(step: 0)
  var phraseSequence: [DanceMove] = []
  /// 0→1 progress of the climb→stage crossfade (view fades scenery by it).
  var bossTransition: Double = 0
  /// Counts down the intro card + llamada beat; any tap skips.
  var introTimer: Double = 0
  /// Whether the llamada beat (stomp + shake + music start) has fired this intro.
  var didLlamada = false
  /// Generic countdown for the current duel sub-state (demo step, result hold, showboat).
  var duelTimer: Double = 0
  /// The compás bar: seconds remaining / total budget for the current echo.
  var echoRemaining: Double = 0
  var echoTotal: Double = 1
  /// Counts down the freeze fake-out's hold window while its slot is current.
  var freezeTimer: Double = 0
  /// One rear-up flourish per showboat, fired at its midpoint.
  var showboatDidRear = false
  /// The 🔥 freeze fake-out's correct input is *nothing*, and no button says so —
  /// so the first freeze slot of each boss run pops a "🔥 = ¡quieta!" hint.
  var didShowFreezeHint = false
  /// One-shot dance-burst countdowns (the `bullThrowTimer` pattern): while > 0 the
  /// commanded action plays, then the actor falls back to idle.
  var playerMoveTimer: Double = 0
  var bullMoveTimer: Double = 0
  var screenShake: Double = 0
  /// Monotonic clock for deterministic sin-decay shake (the Conjuguer idiom).
  var sineTime: Double = 0
  var jaleoPops: [JaleoPop] = []
  var jaleoCounter = 0
  var victoryTimer: Double = 0
  var endSceneTime: Double = 0
  var bossMusicStarted = false
  var endSceneMusicStarted = false
  var endSceneBurstDone = false
  /// Countdowns for the living end scene's recurring bull dance move, moo, and
  /// heart/rose burst (re-rolled each firing).
  var endSceneDanceTimer: Double = 0
  var endSceneMooTimer: Double = 0
  var endSceneBurstTimer: Double = 0
  /// Latches true the moment the player wins, hiding the Duende meter for the rest of
  /// the boss sequence (victory + end scene) — a cleaner curtain call. Cleared by
  /// `reset()`.
  var hasWon = false
  /// Intro lerp anchors: where each actor stood when the boss triggered.
  var introFromPlayerX: CGFloat = 0
  var introFromPlayerY: CGFloat = 0
  var introFromBullX: CGFloat = 0
  var introFromBullY: CGFloat = 0
  var introFromMatadorX: CGFloat = 0
  var introFromMatadorY: CGFloat = 0
  /// Injectable RNG so tests can script exact phrases (seeded `SplitMix64`).
  var bossRNG: any RandomNumberGenerator = SystemRandomNumberGenerator()

  // MARK: Loop bookkeeping

  private var lastUpdateTime: Date?

  // MARK: Lifecycle

  /// Build the level geometry from the on-screen size (once) and place entities.
  func configure(screenSize: CGSize) {
    guard !didConfigure, screenSize.width > 0, screenSize.height > 0 else { return }
    self.screenSize = screenSize
    buildLevel()
    reset()
    if let startStage = Self.debugStartStage {
      summitCount = startStage - 1
      stage = startStage
    }
    didConfigure = true
    startAudio()
    if Self.debugStartAtEnd {
      debugJumpToEndScene()
    } else if Self.debugStartAtBoss {
      enterBossIntro()
      if let prefill = Self.debugBossBanked {
        banked = min(max(prefill, 0), Self.meterNotches - 1)
      }
    }
  }

  // MARK: Audio

  /// Kick off the game's audio at entry: warm every SFX player and the flag/cape
  /// emoji glyphs off the main thread (so the first flag thrown never stalls the
  /// render or audio path — see SoundPlayerReal / GlyphWarmer), then start the
  /// looping flamenco music. Called once from `configure`. The audio-stack itself
  /// was already warmed at app launch by `SoundPlayerReal.setup()`.
  private func startAudio() {
    // Pre-decode every SFX off-main (skips ones already prepared).
    Current.soundPlayer.warmUpSounds()

    // Pre-rasterize the emoji this game rains (obstacles are the worst first-draw
    // offender) into the process-wide glyph cache, off the main actor. All five
    // stages' obstacle sets are warmed up front (~40 glyphs, cheap), plus the
    // encierro charger (🐂) and the speed/serenata pickup glyphs (⚡/🎸). The boss
    // fight adds the freeze chip (🔥), the survive sparkle (✨), and the reunion
    // burst (🌹/❤️) — warm those so the first duel frame is a cache hit. (The jaleo
    // pops are Spanish words, not emoji; the clashing emoji crowd row was removed.)
    let obstacleGlyphs = Self.stageObstacleEmojis.flatMap { $0 }
    let subidaGlyphs = obstacleGlyphs + ["🐂", "⚡", "🎸"]
    let bossGlyphs: [(String, CGFloat)] = ["🔥", "✨", "🌹", "❤️"].map { ($0, 30) }
    let glyphs: [(String, CGFloat)] = subidaGlyphs.map { ($0, 28) } + bossGlyphs
    Task.detached(priority: .userInitiated) {
      GlyphWarmer.warm(glyphs)
    }

    Current.soundPlayer.startMusic(.gameLoop)
  }

  /// Stop the looping music. Called from `GameView.onDisappear` when the player
  /// leaves the game (the playhead is saved so a later entry resumes it). Leaving
  /// from the boss's end scene fades gracefully instead of hard-stopping.
  func stopAudio() {
    if phase == .endScene {
      Current.soundPlayer.stopMusic(fadeDuration: Self.endSceneMusicFade)
    } else {
      Current.soundPlayer.stopMusic()
    }
  }

  private func buildLevel() {
    let w = screenSize.width
    let h = screenSize.height

    // Platforms: level 0 (bottom, player) at ~78% height, level 5 (top, bull) at
    // ~14%, evenly spaced. Beams span the width minus a small side margin.
    let topY = h * 0.16
    let bottomY = h * 0.78
    let spacing = (bottomY - topY) / CGFloat(Self.levelCount - 1)
    let platformWidth = w - 2 * Self.sideMargin
    platforms = (0..<Self.levelCount).map { level in
      let centerY = bottomY - CGFloat(level) * spacing
      let rect = CGRect(
        x: Self.sideMargin,
        y: centerY - Self.platformThickness / 2,
        width: platformWidth,
        height: Self.platformThickness
      )
      return Platform(id: level, level: level, rect: rect)
    }

    // Ladders: one per gap, staggered left/right so the player must traverse each
    // level to reach the next ladder (the Donkey-Kong zig-zag).
    ladders = (0..<(Self.levelCount - 1)).map { gap in
      let x = w * (gap % 2 == 0 ? 0.75 : 0.25)
      return Ladder(
        id: gap,
        lowerLevel: gap,
        upperLevel: gap + 1,
        x: x,
        topY: platforms[gap + 1].surfaceY,
        bottomY: platforms[gap].surfaceY
      )
    }

    // Power-up pickups are placed (and their kind drawn from the bag) in `reset()` /
    // `advanceToNextStage` via `assignStagePowerUp()` — the two spawn points live in
    // `rebuildPowerUps` (GameState+PowerUps.swift), which needs the platforms above.

    // Bullfighter: one static frame beside the bull on the top platform.
    bullfighterHomeX = w * 0.72
    bullfighterHomeY = platforms[Self.levelCount - 1].surfaceY - Self.bullfighterSize / 2
    bullfighterX = bullfighterHomeX
    bullfighterY = bullfighterHomeY
  }

  /// Full restart to a fresh game: return the player and bull to their starting
  /// state, clear obstacles, restore all health, re-arm the cape pickups, and reset
  /// the stage back to 1. Keeps platforms/ladders geometry. Also clears any
  /// boss-fight state back to `.climb` (re-showing the hearts). Used by `configure()`.
  /// Death no longer routes here — it soft-respawns via `respawn()`, which keeps
  /// `stage`/`summitCount`/`score`.
  func reset() {
    let w = screenSize.width
    let top = Self.levelCount - 1
    stage = 1
    summitCount = 0
    score = 0

    phase = .climb
    banked = 0
    duelState = .bullDemo(step: 0)
    phraseSequence = []
    bossTransition = 0
    introTimer = 0
    didLlamada = false
    duelTimer = 0
    echoRemaining = 0
    echoTotal = 1
    freezeTimer = 0
    showboatDidRear = false
    didShowFreezeHint = false
    playerMoveTimer = 0
    bullMoveTimer = 0
    screenShake = 0
    jaleoPops.removeAll()
    victoryTimer = 0
    endSceneTime = 0
    bossMusicStarted = false
    endSceneMusicStarted = false
    endSceneBurstDone = false
    endSceneDanceTimer = 0
    endSceneMooTimer = 0
    endSceneBurstTimer = 0
    hasWon = false
    bullfighterX = bullfighterHomeX
    bullfighterY = bullfighterHomeY

    playerX = w * 0.15
    playerY = platforms[0].surfaceY - Self.playerHeight / 2
    playerVelocityY = 0
    playerGrounded = true
    playerClimbing = false
    climbingLadder = nil
    playerLevel = 0
    playerFacing = 1
    playerPhase = 0
    playerAction = .idle

    movingLeft = false
    movingRight = false
    movingUp = false
    movingDown = false

    capedRemaining = 0
    speedRemaining = 0
    serenataRemaining = 0
    serenataDanceTimer = 0
    health = Self.maxHealth
    damageCooldown = 0

    obstacles.removeAll()
    obstacleCounter = 0
    obstacleSpawnTimer = Self.obstacleSpawnInterval
    // Fresh game: empty both shuffle bags and draw stage 1's power-up (rearms the
    // pickups) and challenge mechanic (arms the first-appearance countdown).
    powerUpBag.removeAll()
    mechanicBag.removeAll()
    activeMechanic = nil
    mechanicRemaining = 0
    apagonDim = 0
    chargers.removeAll()
    chargerCounter = 0
    assignStagePowerUp()
    assignStageMechanic()

    bullX = w * 0.4
    bullY = platforms[top].surfaceY - Self.bullSize / 2
    bullDirection = 1
    bullFacing = 1
    bullPhase = 0
    bullAction = .idle
    bullThrowTimer = 0

    lastUpdateTime = nil
  }

  // MARK: Frame tick

  func update(currentTime: Date) {
    let rawDt: CGFloat
    if let last = lastUpdateTime {
      rawDt = CGFloat(currentTime.timeIntervalSince(last))
    } else {
      rawDt = 0
    }
    lastUpdateTime = currentTime

    // Skip the first frame and any big hitch (returning from background).
    guard didConfigure, rawDt > 0, rawDt < 1 else { return }

    // Clamp so a sub-second hitch isn't applied in one giant step (prevents
    // tunneling through platform/flag collision tests).
    let dt = min(rawDt, 1.0 / 30.0) * Self.debugTimeScale

    sineTime += Double(dt)

    // The original climb pipeline runs only in `.climb`; the between-stage escape
    // beat is driven by `updateEscape` (GameState+Stages.swift), and every boss phase
    // by `updateBoss` (GameState+BossFight.swift) — so the climb's derived actions
    // never stomp the escape rise or the boss's commanded dance bursts.
    guard phase == .climb else {
      if phase == .escape {
        updateEscape(dt: dt)
      } else {
        updateBoss(dt: dt)
      }
      return
    }

    if damageCooldown > 0 { damageCooldown = max(0, damageCooldown - Double(dt)) }
    if capedRemaining > 0 { capedRemaining = max(0, capedRemaining - Double(dt)) }
    if speedRemaining > 0 { speedRemaining = max(0, speedRemaining - Double(dt)) }
    if serenataRemaining > 0 {
      serenataRemaining = max(0, serenataRemaining - Double(dt))
      if serenataRemaining == 0 {
        // The bull, annoyed the song is over, snorts and gets back to work.
        Current.soundPlayer.play(.snort, shouldDebounce: false, volume: 0.4)
      }
    }

    // The up/down buttons vanish when not at a ladder; if one is removed mid-press
    // its gesture may never fire `.onEnded`, so clear a stranded climb intent here.
    if !canClimbUp { movingUp = false }
    if !canClimbDown { movingDown = false }

    updatePlayer(dt: dt)
    updateBull(dt: dt)
    // Fire / age the stage's challenge mechanic (zombie/encierro/apagón) before the
    // obstacles move — an active zombie window re-routes `updateObstacles` to homing.
    updateMechanicScheduler(dt: dt)
    updateObstacles(dt: dt)
    // El Encierro: spawn (while the window is open) and advance the 🐂 chargers.
    updateChargers(dt: dt)
    advanceAnimations(dt: dt)
    // Age any drifting jaleo pops during the climb too (the "¡Nivel N!" stage banner
    // is spawned here) — otherwise they never fade and stack across stages.
    advanceJaleoPops(dt: Double(dt))
    resolveCollisions()
    checkReachedBull()
  }

  /// Drift-age the jaleo pops toward expiry and drop the dead ones. Shared by the
  /// climb pipeline and the boss cosmetics so a pop fades wherever it was spawned.
  func advanceJaleoPops(dt: Double) {
    for i in jaleoPops.indices {
      jaleoPops[i].ttl -= dt
    }
    jaleoPops.removeAll { $0.ttl <= 0 }
  }

  // MARK: Collision helper

  /// Centered-rectangle AABB overlap test.
  func rectsIntersect(
    _ ax: CGFloat, _ ay: CGFloat, _ aw: CGFloat, _ ah: CGFloat,
    _ bx: CGFloat, _ by: CGFloat, _ bw: CGFloat, _ bh: CGFloat
  ) -> Bool {
    abs(ax - bx) < (aw + bw) / 2 && abs(ay - by) < (ah + bh) / 2
  }
}
