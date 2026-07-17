//
//  GameModels.swift
//  Conjugar
//
//  Value-type entities and action enums for the Donkey-Kong-inspired flamenco/bull
//  game prototype. Kept as plain structs (no Sendable needed — they live on the
//  `@MainActor` `GameState`), mirroring the sibling apps' `GameModels.swift`.
//

import CoreGraphics

/// A horizontal girder the player and flags stand on. `level` 0 is the bottom
/// (player start), the highest level is the top (bull).
struct Platform: Identifiable {
  let id: Int
  let level: Int
  let rect: CGRect
  /// The y of the beam's top face — where entities' feet rest.
  var surfaceY: CGFloat { rect.minY }
}

/// A ladder connecting `lowerLevel`'s girder to `upperLevel`'s girder.
struct Ladder: Identifiable {
  let id: Int
  let lowerLevel: Int
  let upperLevel: Int
  let x: CGFloat
  /// Top-face y of the upper platform (climb destination going up).
  let topY: CGFloat
  /// Top-face y of the lower platform (climb destination going down).
  let bottomY: CGFloat
}

/// How an obstacle glyph is oriented as it travels (see the "Per-set rendering"
/// spec in prompts/game_la_subida.md). Apple's animal/vehicle emoji face LEFT and
/// would hide any facing under the barrel tumble, so each stage's set declares a
/// style: flags/balls spin like barrels, animals/vehicles stay upright and mirror to
/// face their travel, sky glyphs (sun/clouds) neither spin nor mirror.
enum ObstacleStyle {
  case spin, face, upright
}

/// An obstacle "barrel" thrown by the bull — a country flag, animal, ball, vehicle,
/// or sky glyph depending on the stage (see `GameState.stageObstacleEmojis`). Either
/// rolling along `level`'s girder or `falling` toward `level - 1`.
struct Obstacle: Identifiable {
  let id: Int
  var x: CGFloat
  var y: CGFloat
  var velocityX: CGFloat
  var velocityY: CGFloat
  var falling: Bool
  var level: Int
  let emoji: String
  var rotation: Double
  /// The stage set's render style, fixed at spawn (all obstacles on screen share a
  /// stage, so a set's style never mixes).
  var style: ObstacleStyle = .spin
  /// Which way the glyph faces (+1 right / −1 left) for `.face` sets, updated from the
  /// sign of horizontal motion. A purely vertical fall keeps the last facing.
  var facing: CGFloat = -1
  var despawn: Bool = false

  // MARK: La Subida — extra power-up / mechanic state (see the game-powerups plan)
  // Value-type fields so babies (`camada`) and chasers (`cortejo`) reuse the existing
  // obstacle render + collision path instead of introducing a new entity type.

  /// Render/collision scale — 1 = full obstacle, `GameState.babyScale` = a `camada` baby.
  var scale: CGFloat = 1
  /// A `camada` baby's parent obstacle id (nil for a normal obstacle). A baby mirrors
  /// its parent's motion after a short birth slide.
  var parentID: Int?
  /// Seconds left in a baby's birth-slide animation (0 once it has settled behind its parent).
  var birthRemaining: Double = 0
  /// The locked trailing offset a baby slides out to, then holds relative to its parent.
  var birthOffset: CGSize = .zero
  /// Sympathetic / catch fade-out (`camada` baby-hit, `cortejo` catch): non-colliding
  /// while > 0, removed when it reaches 0.
  var fadeRemaining: Double = 0
  /// A `cortejo` chaser's pre-chase shiver-in-place window (0 once it starts pursuing).
  var vibrateRemaining: Double = 0
  /// True once a `cortejo`-possessed obstacle begins pursuing its target.
  var isChaser: Bool = false
  /// The obstacle a `cortejo` chaser is pursuing (retargeted if it despawns).
  var chaseTargetID: Int?
  /// True while an obstacle is arcing over a finished `terremoto` gap (lands back on the
  /// same girder rather than falling to the level below).
  var hopping: Bool = false

  /// Obstacles driven by the power-up / mechanic subsystems rather than the ordinary
  /// roll/fall pipeline — `updateObstacles` (and the zombie homing) skip their motion so
  /// `updateBabies` / `updateCortejo` / the fade ager own them.
  var isSpecial: Bool {
    parentID != nil || isChaser || fadeRemaining > 0 || vibrateRemaining > 0
  }
}

/// A homing ❤️ projectile fired by a qualifying jump while the `flechazo` power-up is
/// active — it pursues the nearest obstacle and destroys it on contact (see
/// `GameState.updateHeartMissiles`). Rendered at half scale in `GameView`.
struct HeartMissile: Identifiable {
  let id: Int
  var x: CGFloat
  var y: CGFloat
  var velocityX: CGFloat
  var velocityY: CGFloat
  var targetID: Int
  var lifeRemaining: Double
}

/// A small yellow particle in the burst thrown off when an obstacle is destroyed
/// (see `GameState.spawnHitParticles` / `updateHitParticles`). Scatters outward under
/// gravity and fades over its short life; rendered as a yellow dot in `GameView`.
struct HitParticle: Identifiable {
  let id: Int
  var x: CGFloat
  var y: CGFloat
  var velocityX: CGFloat
  var velocityY: CGFloat
  var ttl: Double
  let initialTTL: Double
  let size: CGFloat
}

/// A hole punched in a girder by the `terremoto` (earthquake) mechanic. It fades in over
/// `fadeRemaining` seconds and is **still solid to stand/cross while it fades**; only once
/// `fadeRemaining` reaches 0 is it a true hole an entity falls through (see
/// `GameState.openPlatformGaps` / `hasFinishedGap`).
struct PlatformGap: Identifiable {
  let id: Int
  let level: Int
  let xRange: ClosedRange<CGFloat>
  var fadeRemaining: Double
}

/// A 🐂 charger in the El Encierro stampede (see GameState+Mechanics.swift, Phase 4):
/// it runs straight across a single girder at 2× the stage's obstacle speed and
/// despawns off-screen — no falling. Same damage/cape rules as an obstacle, with a
/// tight `chargerHitSize` box. `direction` is +1 (moving right) / −1 (moving left);
/// the glyph (left-facing) mirrors to face its travel.
struct Charger: Identifiable {
  let id: Int
  var x: CGFloat
  let y: CGFloat
  let level: Int
  let direction: CGFloat
  var despawn: Bool = false
}

/// Which of La Subida's three power-ups a pickup grants (one kind per stage, drawn
/// from a shuffle bag — see `GameState.powerUpBag`). `cape` is the original muleta
/// (invulnerability + smash); `speed` doubles walk AND climb speed; `serenata` makes
/// the bull drop its guard and dance instead of throwing.
enum PowerUpKind: CaseIterable {
  case cape, speed, serenata, flechazo, cortejo
}

/// A collectable power-up sitting on a platform. A stage spawns only its drawn
/// `kind` (`GameState.stagePowerUpKind`); collecting it starts that kind's timer.
struct PowerUp: Identifiable {
  let id: Int
  let x: CGFloat
  let y: CGFloat
  let kind: PowerUpKind
  var collected: Bool
}

/// One of La Subida's three challenge mechanics — a timed disruption that fires once
/// (then periodically) within a stage, drawn per stage from a shuffle bag (see
/// `GameState.mechanicBag`), exactly like the power-ups:
///
///   • zombie   — obstacles slow to half speed and home toward the player (they keep
///                their own emojis — no 🧟 swap; see GameState+Mechanics.swift).
///   • encierro — 🐂 chargers stampede across the girders (Phase 4).
///   • apagon   — the lights cut to a spotlight on the dancer (Phase 5).
enum ChallengeMechanic: CaseIterable {
  case zombie, encierro, apagon, terremoto, camada
}

/// Which frame-count table the player's sprite flipbook cycles through. Every action
/// — including the boss fight's `ole`/`stomp` dance moves — has its own hand-keyed
/// rendered imageset (see GameState+Animation).
enum PlayerAction {
  case idle, walk, climb, jump, cape, capeWalk, ole, stomp
}

/// Which frame-count table the bull's sprite flipbook cycles through. Every action —
/// including the boss fight's `stomp`/`rear`/`bow` — has its own hand-keyed rendered
/// imageset (see GameState+Animation).
enum BullAction {
  case idle, walk, `throw`, stomp, rear, bow
}

// MARK: Boss fight — La Llamada (the dance-off duel)

/// The game's top-level phase. `climb` is the whole original prototype — its update
/// pipeline runs only there. `escape` is the between-stage beat (the bull flees
/// upward carrying the matador; see `GameState+Stages.swift`). Everything else is the
/// boss fight, driven by `GameState+BossFight.swift`.
enum GamePhase {
  case climb, escape, bossIntro, duel, victory, endScene
}

/// How a `DanceMove` is drawn — the glyph vocabulary of the dance pad and its cue
/// chips. Identity only; the two rendering sites apply their own sizes and styles.
enum DanceGlyph {
  case systemSymbol(String)
  case customSymbol(String)
  case sprite(String)
  case emoji(String)
}

/// The dance vocabulary of the duel. `freeze` is the round-3 fake-out: the correct
/// response is to input *nothing* for its hold window.
enum DanceMove: CaseIterable, Hashable {
  case pasoLeft, pasoRight, ole, stomp, cape, freeze

  /// The moves a phrase is rolled from — everything but `freeze`, which round 3
  /// injects into exactly one non-first slot.
  static let phraseMoves: [DanceMove] = [.pasoLeft, .pasoRight, .ole, .stomp, .cape]

  /// The glyph the pad button and the cue chip both render for this move. The echo
  /// is from memory — the pad must show exactly what the cue showed — so the
  /// identity lives here and the two sites can't diverge. `ole` is the custom `ole`
  /// symbol (Assets.xcassets), a solid arms-up desplante silhouette derived from
  /// the `dancer_ole_3` sprite's peak frame. `freeze` appears only in cues: the
  /// correct echo is no input, so it has no pad button.
  var glyph: DanceGlyph {
    switch self {
    case .pasoLeft: return .systemSymbol("arrowtriangle.left.fill")
    case .pasoRight: return .systemSymbol("arrowtriangle.right.fill")
    case .ole: return .customSymbol("ole")
    case .stomp: return .systemSymbol("shoeprints.fill")
    case .cape: return .sprite("cape_pickup")
    case .freeze: return .emoji("🔥")
    }
  }

  /// The Pixabay SFX that punctuates this move — played on the bull's demo cue and
  /// again on the dancer's correct echo, so each move has its own voice (the two
  /// pasos are one castanet click pitched low/high). `freeze`'s cue is an ominous
  /// tension sting on the bull's demo, warning the player this slot is different;
  /// the *echo* freeze is silent by design (the response is to hold still — the
  /// `.warning` haptic marks the hold). Pack logged in
  /// `asset-licenses/pixabay-game-sfx.txt`.
  var cueSound: Sound? {
    switch self {
    case .pasoLeft: return .castanetLow
    case .pasoRight: return .castanetHigh
    case .ole: return .palmas
    case .stomp: return .stompThud
    case .cape: return .capeWhoosh
    case .freeze: return .tensionSting
    }
  }
}

/// Sub-state while `phase == .duel`.
enum DuelState: Equatable {
  case bullDemo(step: Int)             // bull performs; cue chips accumulate
  case playerEcho(step: Int)           // input unlocked; compás bar sweeping
  case phraseResult(success: Bool)     // jaleo pop, meter move, brief hold
  case showboat                        // between rounds / after a fail; bull struts
}

/// A floating, fading feedback shout (¡Olé! / ¡Uy! / ¡Eso!…) — the sibling apps'
/// score-pop idiom. Spawned by the boss judge, rendered as drifting `Text`.
/// `size` is the font point size: per-move jaleos are modest, phrase-level events
/// (¡Tu turno!, ¡Olé!) render big so they carry the dark mid-screen on device.
struct JaleoPop: Identifiable {
  let id: Int
  let text: String
  let x: CGFloat
  let y: CGFloat
  var ttl: Double
  let initialTTL: Double
  let size: CGFloat
  /// Upward drift speed in points/second (the pop's y decreases by `age * riseRate`).
  /// The default is a gentle score-pop drift; the dancer's spoken jaleos use a much
  /// larger rate so they climb all the way to the sight-line high in the empty field.
  let riseRate: CGFloat
  /// Seconds the pop holds fully-opaque and stationary before it begins fading and
  /// rising (0 = start at once). Bull speech uses a 1 s hold so its announcement is
  /// readable before it drifts off.
  var hold: Double = 0
}

/// A tiny seedable RNG (SplitMix64) so boss tests can script exact dance phrases.
/// Production uses `SystemRandomNumberGenerator`; tests inject this with a seed.
struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E3779B97F4A7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
  }
}
