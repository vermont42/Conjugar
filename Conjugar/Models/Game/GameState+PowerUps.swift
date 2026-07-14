//
//  GameState+PowerUps.swift
//  Conjugar
//
//  La Subida — the three-kind power-up system (see prompts/game_la_subida.md,
//  Phase 2). Each stage spawns exactly one kind, drawn from a shuffle bag so no kind
//  repeats until all three have appeared:
//
//    • cape     — the original muleta: invulnerability + smash (GameState+Obstacles).
//    • speed ⚡ — walk AND climb speed ×2 for the same 7 s + expiry-blink envelope.
//    • serenata 🎸 — the bull drops its guard and DANCES instead of pacing/throwing;
//                    in-flight obstacles keep rolling, but no new ones spawn.
//
//  This file owns the bag, the per-stage assignment, the collection effects, and the
//  serenata dance loop. The stored timers (`speedRemaining` / `serenataRemaining` /
//  `serenataDanceTimer`) and the bag live on `GameState`; they tick in `update`.
//

import CoreGraphics

extension GameState {
  // MARK: Shared blink envelope

  /// Whether a power-up whose timer is `remaining` should render this frame: solid
  /// until its final `capeBlinkDuration` seconds, then flashing ~5×/s to warn of
  /// imminent expiry, then gone. Shared by the cape overlay (`isCapeVisible`) and the
  /// speed badge (`isSpeedBadgeVisible`) so the two blink identically.
  func powerUpVisible(remaining: Double) -> Bool {
    guard remaining > 0 else { return false }
    guard remaining <= Self.capeBlinkDuration else { return true }
    return Int(remaining * 10) % 2 == 0
  }

  /// Whether the ⚡ badge above the dancer should be drawn this frame (same blink
  /// envelope as the cape).
  var isSpeedBadgeVisible: Bool { powerUpVisible(remaining: speedRemaining) }

  /// The walk/climb speed multiplier in effect right now — ×`speedFactor` while the
  /// speed power-up is active, otherwise ×1. Multiplied into `updatePlayer`'s walk
  /// line and `updateClimb`'s climb line.
  var speedFactorNow: CGFloat { speedRemaining > 0 ? Self.speedFactor : 1 }

  // MARK: Per-stage assignment (shuffle bag)

  /// Draw the next stage's power-up kind: honor the `CONJUGAR_GAME_POWERUP` override
  /// if set, otherwise pull from the shuffle bag (refill + reshuffle through
  /// `bossRNG` when empty).
  func drawStagePowerUpKind() -> PowerUpKind {
    if let forced = Self.debugForcedPowerUp { return forced }
    if powerUpBag.isEmpty {
      powerUpBag = PowerUpKind.allCases.shuffled(using: &bossRNG)
    }
    return powerUpBag.removeLast()
  }

  /// Draw and store this stage's power-up kind, then (re)place the pickups. Called
  /// from `reset()` (stage 1) and `advanceToNextStage()` (every later stage).
  func assignStagePowerUp() {
    stagePowerUpKind = drawStagePowerUpKind()
    rebuildPowerUps(kind: stagePowerUpKind)
  }

  /// Rebuild the stage's two pickups at their platform spawn points (the same two
  /// mid-platforms the cape always used), all of the drawn `kind` and uncollected.
  func rebuildPowerUps(kind: PowerUpKind) {
    let w = screenSize.width
    powerUps = [
      PowerUp(id: 0, x: w * 0.4, y: platforms[1].surfaceY - Self.capeSize / 2, kind: kind, collected: false),
      PowerUp(id: 1, x: w * 0.6, y: platforms[3].surfaceY - Self.capeSize / 2, kind: kind, collected: false)
    ]
  }

  // MARK: Collection

  /// Apply the effect of collecting a pickup of `kind` (called from
  /// `resolveCollisions`). Each starts its own timer and plays its cue.
  func collectPowerUp(_ kind: PowerUpKind) {
    switch kind {
    case .cape:
      capedRemaining = Self.capeDuration
      Current.soundPlayer.play(.shieldActivate, shouldDebounce: false)   // cape power-up
    case .speed:
      speedRemaining = Self.speedDuration
      Current.soundPlayer.play(.speedWhoosh, shouldDebounce: false)      // speed power-up
    case .serenata:
      serenataRemaining = Self.serenataDuration
      serenataDanceTimer = 0                                             // start dancing at once
      Current.soundPlayer.play(.guitarStrum, shouldDebounce: false)      // La Serenata
    }
  }

  // MARK: Serenata dance

  /// While La Serenata plays the bull stands still and dances random bursts from the
  /// end-scene repertoire (foreshadowing the boss dance-off + the dancing-bull end
  /// scene). Called by `updateBull` in place of pacing/throwing; `bullMoveTimer` is
  /// decremented here because the climb pipeline otherwise never ticks it (only the
  /// boss path does). `derivedBullAction` then shows the commanded move while the
  /// burst runs, `.idle` between bursts.
  func updateSerenataDance(dt: CGFloat) {
    if bullMoveTimer > 0 { bullMoveTimer -= Double(dt) }
    serenataDanceTimer -= Double(dt)
    if serenataDanceTimer <= 0 {
      serenataDanceTimer = Self.serenataDanceInterval
      let move = Self.endSceneDanceMoves.randomElement(using: &bossRNG) ?? .stomp
      commandBullMove(move, duration: Self.danceBurstDuration)
    }
  }
}
