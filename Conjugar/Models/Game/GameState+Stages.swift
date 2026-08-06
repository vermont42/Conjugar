//
//  GameState+Stages.swift
//  Conjugar
//

import CoreGraphics
import Foundation

extension GameState {
  // MARK: Stage config (derived from `stage`)

  /// The current stage's obstacle emoji set.
  var stageEmojis: [String] {
    Self.stageObstacleEmojis[stageIndex]
  }

  /// The current stage's obstacle render style (spin / face / upright).
  var stageObstacleStyle: ObstacleStyle {
    Self.stageObstacleStyles[stageIndex]
  }

  /// Obstacle roll speed for the current stage: +5% per stage, compounding.
  var obstacleSpeed: CGFloat {
    Self.obstacleRollSpeed * pow(Self.stageSpeedFactor, CGFloat(stage - 1))
  }

  /// `stage` clamped to a valid array index (defensive against an out-of-range stage).
  private var stageIndex: Int {
    min(max(stage - 1, 0), Self.stageCount - 1)
  }

  // MARK: Escape beat (summits 1–4)

  /// A non-final summit: the bull flees UPWARD carrying the matador off the top of the
  /// screen (resolving the long-standing escape-beat TODO), then `advanceToNextStage`
  /// rebuilds the field for the next stage. Guards `.climb` like `enterBossIntro` (a
  /// summit during `.escape` is impossible, but the guard is cheap).
  func enterEscape() {
    guard phase == .climb else { return }
    phase = .escape

    // Clear input + field, mirroring `enterBossIntro`'s field-clearing.
    movingLeft = false
    movingRight = false
    movingUp = false
    movingDown = false
    playerClimbing = false
    climbingLadder = nil
    playerVelocityY = 0
    playerGrounded = true
    damageCooldown = 0
    // Active power-up timers (cape/speed/serenata) are deliberately NOT cleared here:
    // they carry across the escape beat into the next stage (decision 12). Death
    // clears them (`respawn`), a summit does not.
    obstacles.removeAll()
    // Any in-flight ❤️ missiles have no targets once the field clears; the flechazo
    // *timer* itself carries across the escape beat like the other power-ups.
    heartMissiles.removeAll()
    obstacleSpawnTimer = Self.obstacleSpawnInterval
    bullThrowTimer = 0
    // A summit interrupts any active mechanic window (the next stage re-arms its own).
    cancelActiveMechanic()

    // The summit's celebration: applause + a triumphant moo as the bull turns to flee.
    Current.soundPlayer.play(Sound.randomApplause, shouldDebounce: false)
    Current.soundPlayer.play(.moo, shouldDebounce: false, volume: 0.3)
    bullAction = .walk
    bullPhase = 0
    playerAction = .idle
    playerPhase = 0
  }

  /// One frame of the escape beat: advance the flipbooks and lift the bull + matador
  /// in lockstep until both clear the top edge, then rebuild for the next stage.
  func updateEscape(dt: CGFloat) {
    playerPhase += Double(dt)
    bullPhase += Double(dt)
    bullAction = .walk

    let rise = Self.escapeRiseSpeed * dt
    bullY -= rise
    bullfighterY -= rise

    if bullY < -100 && bullfighterY < -100 {
      advanceToNextStage()
    }
  }

  /// Rebuild the field for the stage the player just unlocked: player back at the
  /// start, health refilled, bull + matador restored home, a fresh (faster) obstacle
  /// set, and the "¡Nivel N!" banner — then hand control back to `.climb`.
  private func advanceToNextStage() {
    let w = screenSize.width
    let top = Self.levelCount - 1
    stage = summitCount + 1
    // `summitCount` is the number of stages cleared, so it names the stage just finished.
    Current.analytics.signal(
      name: .completeStage,
      parameters: [ParameterKey.stage.rawValue: "\(summitCount)"]
    )

    // Player back to the bottom-left start.
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
    health = Self.maxHealth
    damageCooldown = 0

    // Bull + matador return to their home marks on the top girder.
    bullX = w * 0.4
    bullY = platforms[top].surfaceY - Self.bullSize / 2
    bullDirection = 1
    bullFacing = 1
    bullPhase = 0
    bullAction = .idle
    bullThrowTimer = 0
    bullfighterX = bullfighterHomeX
    bullfighterY = bullfighterHomeY

    // Fresh field: obstacles cleared, and the next stage's power-up drawn from the
    // bag + its pickups re-armed. Active power-up timers (cape/speed/serenata) carry
    // across the escape beat by design (decision 12) — they're never cleared here.
    obstacles.removeAll()
    obstacleCounter = 0
    obstacleSpawnTimer = Self.obstacleSpawnInterval
    assignStagePowerUp()
    // Draw the new stage's challenge mechanic and arm its first-appearance countdown.
    assignStageMechanic()

    // The between-stage banner, centered mid-field; fades out over two seconds.
    spawnJaleo(L.Game.nivel(stage), x: w / 2, y: screenSize.height * 0.4, size: 44, ttl: 2.0)

    phase = .climb
  }

  // MARK: Soft respawn (death)

  /// 0 health: soft-respawn at the bottom-left of the current stage with full health.
  /// Keeps `stage` / `summitCount` / `score` (and the bull's position/timers, and
  /// pickup collected-state) — only the player, obstacles, and power-up timers reset.
  /// A brief damage grace keeps a lingering obstacle from immediately re-killing. The
  /// sad trombone is played at the call site (once). There is no lose state.
  func respawn() {
    let w = screenSize.width
    health = Self.maxHealth

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

    obstacles.removeAll()
    obstacleSpawnTimer = Self.obstacleSpawnInterval

    // Death cancels any active mechanic window and re-arms a fresh first-appearance
    // countdown (the same mechanic is kept — it's still this stage's assignment).
    cancelActiveMechanic()
    armMechanicCountdown(firstDelay: true)

    // Death clears every active power-up (the escape beat, by contrast, carries them).
    capedRemaining = 0
    speedRemaining = 0
    serenataRemaining = 0
    serenataDanceTimer = 0
    flechazoRemaining = 0
    flechazoCooldown = 0
    heartMissiles.removeAll()
    cortejoCharges = 0
    damageCooldown = Self.respawnGrace
  }
}
