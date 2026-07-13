//
//  GameState+Animation.swift
//  Conjugar
//
//  The placeholder-flipbook machinery: a per-action frame-count table, the phase
//  advance, action derivation, and the `currentFrame` helper. This is the exact
//  index logic real sprite frames will later plug into — the view renders
//  `Text("\(playerFrame)")` today; `Image(frames[playerFrame - 1])` swaps in later
//  with no change to this file.
//

import CoreGraphics

extension GameState {
  /// Reasonable placeholder frame counts per action.
  static let playerFrameCounts: [PlayerAction: Int] = [
    .idle: 2, .walk: 6, .climb: 4, .jump: 3, .cape: 4, .capeWalk: 6
  ]
  static let bullFrameCounts: [BullAction: Int] = [
    .idle: 2, .walk: 6, .throw: 5
  ]

  /// Map a flipbook phase (seconds into the cycle) to a 1-based frame index that
  /// wraps at `count`.
  static func frame(phase: Double, count: Int) -> Int {
    guard count > 0 else { return 1 }
    return Int(phase * Double(fps)) % count + 1
  }

  /// The number the player's placeholder box displays this frame.
  var playerFrame: Int {
    Self.frame(phase: playerPhase, count: Self.playerFrameCounts[playerAction] ?? 1)
  }

  /// The number the bull's placeholder box displays this frame.
  var bullFrame: Int {
    Self.frame(phase: bullPhase, count: Self.bullFrameCounts[bullAction] ?? 1)
  }

  /// Advance flipbook phases and derive the current action for each actor.
  func advanceAnimations(dt: CGFloat) {
    playerPhase += Double(dt)
    bullPhase += Double(dt)
    playerAction = derivedPlayerAction()
    bullAction = derivedBullAction()
  }

  private func derivedPlayerAction() -> PlayerAction {
    if playerClimbing { return .climb }
    if !playerGrounded { return .jump }
    // Caped: hold the muleta out in front while walking, swing it up/down while still.
    if movingLeft != movingRight { return isCaped ? .capeWalk : .walk }
    if isCaped { return .cape }
    return .idle
  }

  private func derivedBullAction() -> BullAction {
    bullThrowTimer > 0 ? .throw : .walk
  }
}
