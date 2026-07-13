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

/// A country-flag "barrel" thrown by the bull. Either rolling along `level`'s
/// girder or `falling` toward `level - 1`.
struct Flag: Identifiable {
  let id: Int
  var x: CGFloat
  var y: CGFloat
  var velocityX: CGFloat
  var velocityY: CGFloat
  var falling: Bool
  var level: Int
  let emoji: String
  var rotation: Double
  var despawn: Bool = false
}

/// A pickup that capes the player for a few seconds (smashes flags on contact).
struct CapePickup: Identifiable {
  let id: Int
  let x: CGFloat
  let y: CGFloat
  var collected: Bool
}

/// Which frame-count table the player's placeholder flipbook cycles through.
/// `ole`/`stomp` are the boss fight's dance moves — mapped to reused rendered
/// frames for now (ole ≈ cape, stomp ≈ jump); Phase 4 of the boss plan swaps in
/// hand-keyed imagesets without touching the mechanic code.
enum PlayerAction {
  case idle, walk, climb, jump, cape, capeWalk, ole, stomp
}

/// Which frame-count table the bull's placeholder flipbook cycles through.
/// `stomp`/`rear`/`bow` are boss-fight actions — mapped to reused rendered frames
/// for now (stomp/rear ≈ throw, bow ≈ idle); Phase 3 of the boss plan swaps in
/// hand-keyed imagesets without touching the mechanic code.
enum BullAction {
  case idle, walk, `throw`, stomp, rear, bow
}

// MARK: Boss fight — La Llamada (the dance-off duel)

/// The game's top-level phase. `climb` is the whole original prototype — its update
/// pipeline runs only there. Everything else is the boss fight, driven by
/// `GameState+BossFight.swift`.
enum GamePhase {
  case climb, bossIntro, duel, victory, endScene
}

/// The dance vocabulary of the duel. `freeze` is the round-3 fake-out: the correct
/// response is to input *nothing* for its hold window.
enum DanceMove: CaseIterable, Hashable {
  case pasoLeft, pasoRight, ole, stomp, cape, freeze

  /// The moves a phrase is rolled from — everything but `freeze`, which round 3
  /// injects into exactly one non-first slot.
  static let phraseMoves: [DanceMove] = [.pasoLeft, .pasoRight, .ole, .stomp, .cape]
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
struct JaleoPop: Identifiable {
  let id: Int
  let text: String
  let x: CGFloat
  let y: CGFloat
  var ttl: Double
  let initialTTL: Double
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
