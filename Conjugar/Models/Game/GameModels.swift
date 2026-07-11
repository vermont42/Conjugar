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
enum PlayerAction {
  case idle, walk, climb, jump, cape
}

/// Which frame-count table the bull's placeholder flipbook cycles through.
enum BullAction {
  case idle, walk, `throw`
}
