//
//  GameStateTests.swift
//  ConjugarTests
//
//  Unit tests for the pure helpers of the game prototype: the placeholder
//  flipbook index math, AABB overlap, platform snap, ladder entry/climb, and the
//  flag/cape/bull collision outcomes. Swift Testing (never XCTest) per the repo's
//  isolated-deinit landmine; `@MainActor` because `GameState` is MainActor.
//

import CoreGraphics
import Testing
@testable import Conjugar

@Suite("GameState")
@MainActor
struct GameStateTests {
  private static let size = CGSize(width: 400, height: 800)

  private func configured() -> GameState {
    let gameState = GameState()
    gameState.configure(screenSize: Self.size)
    return gameState
  }

  // MARK: Flipbook frame index

  @Test func frameCyclesOneToCountAndWraps() {
    // fps == 10, so phase seconds * 10 == frame ordinal.
    #expect(GameState.frame(phase: 0.0, count: 6) == 1)
    #expect(GameState.frame(phase: 0.12, count: 6) == 2)
    #expect(GameState.frame(phase: 0.55, count: 6) == 6)
    #expect(GameState.frame(phase: 0.65, count: 6) == 1)   // wraps past 6
    #expect(GameState.frame(phase: 0.05, count: 2) == 1)
    #expect(GameState.frame(phase: 0.15, count: 2) == 2)
  }

  @Test func frameGuardsAgainstZeroCount() {
    #expect(GameState.frame(phase: 3.3, count: 0) == 1)
  }

  @Test func playerAndBullFramesStayInRange() {
    let gameState = configured()
    for hundredths in 0..<200 {
      gameState.playerPhase = Double(hundredths) / 100.0
      gameState.bullPhase = Double(hundredths) / 100.0
      let pCount = GameState.playerFrameCounts[gameState.playerAction] ?? 1
      let bCount = GameState.bullFrameCounts[gameState.bullAction] ?? 1
      #expect((1...pCount).contains(gameState.playerFrame))
      #expect((1...bCount).contains(gameState.bullFrame))
    }
  }

  // MARK: AABB

  @Test func aabbDetectsOverlapAndSeparation() {
    let gameState = GameState()
    #expect(gameState.rectsIntersect(0, 0, 10, 10, 5, 5, 10, 10))       // overlapping
    #expect(!gameState.rectsIntersect(0, 0, 10, 10, 100, 100, 10, 10))  // far apart
    #expect(!gameState.rectsIntersect(0, 0, 10, 10, 10, 0, 10, 10))     // just touching edges
  }

  // MARK: Level geometry

  @Test func configureBuildsLevelAndPlacesPlayer() {
    let gameState = configured()
    #expect(gameState.platforms.count == GameState.levelCount)
    #expect(gameState.ladders.count == GameState.levelCount - 1)
    #expect(gameState.capes.count == 2)
    #expect(gameState.playerGrounded)
    #expect(gameState.playerLevel == 0)
    let feet = gameState.playerY + GameState.playerHeight / 2
    #expect(abs(feet - gameState.platforms[0].surfaceY) < 0.5)
  }

  // MARK: Physics

  @Test func playerFallsUnderGravityAndSnapsToPlatform() {
    let gameState = configured()
    gameState.playerGrounded = false
    gameState.playerVelocityY = 0
    // Lift the player 30 pt above its resting height on the bottom platform.
    gameState.playerY = gameState.platforms[0].surfaceY - GameState.playerHeight / 2 - 30
    for _ in 0..<120 { gameState.updatePlayer(dt: 1.0 / 60.0) }
    #expect(gameState.playerGrounded)
    let feet = gameState.playerY + GameState.playerHeight / 2
    #expect(abs(feet - gameState.platforms[0].surfaceY) < 1.0)
  }

  @Test func jumpOnlyLaunchesWhenGrounded() {
    let gameState = configured()
    gameState.jump()
    #expect(gameState.playerVelocityY < 0)       // launched upward
    #expect(!gameState.playerGrounded)

    // A second jump mid-air is ignored.
    let vy = gameState.playerVelocityY
    gameState.jump()
    #expect(gameState.playerVelocityY == vy)
  }

  // MARK: Ladders

  @Test func pressingUpAtLadderEntersClimb() {
    let gameState = configured()
    let ladder = gameState.ladders.first { $0.lowerLevel == 0 }!
    gameState.playerX = ladder.x
    gameState.playerLevel = 0
    gameState.playerGrounded = true
    gameState.movingUp = true
    gameState.updatePlayer(dt: 1.0 / 60.0)
    #expect(gameState.playerClimbing)
    #expect(gameState.climbingLadder == ladder.id)
  }

  @Test func climbingUpReachesTheUpperPlatform() {
    let gameState = configured()
    let ladder = gameState.ladders.first { $0.lowerLevel == 0 }!
    gameState.playerX = ladder.x
    gameState.playerLevel = 0
    gameState.playerGrounded = true
    gameState.movingUp = true
    for _ in 0..<600 {
      gameState.updatePlayer(dt: 1.0 / 60.0)
      if !gameState.playerClimbing { break }
    }
    #expect(!gameState.playerClimbing)
    #expect(gameState.playerGrounded)
    #expect(gameState.playerLevel == 1)
  }

  // MARK: Collisions

  private func obstacleOnPlayer(_ gameState: GameState) -> Obstacle {
    Obstacle(
      id: 999, x: gameState.playerX, y: gameState.playerY,
      velocityX: 0, velocityY: 0, falling: false, level: 0,
      emoji: "🏳️", rotation: 0
    )
  }

  @Test func obstacleHitCostsOnePipAndConsumesTheObstacle() {
    let gameState = configured()
    let start = gameState.health
    gameState.damageCooldown = 0
    gameState.obstacles.append(obstacleOnPlayer(gameState))
    gameState.resolveCollisions()
    #expect(gameState.health == start - 1)
    #expect(gameState.obstacles.isEmpty)
  }

  @Test func capedPlayerSmashesObstacleWithoutDamage() {
    let gameState = configured()
    let start = gameState.health
    gameState.capedRemaining = 5
    gameState.obstacles.append(obstacleOnPlayer(gameState))
    gameState.resolveCollisions()
    #expect(gameState.health == start)
    #expect(gameState.obstacles.isEmpty)
  }

  @Test func capePickupCapesThePlayer() {
    let gameState = configured()
    let cape = gameState.capes[0]
    gameState.playerX = cape.x
    gameState.playerY = cape.y
    #expect(!gameState.isCaped)
    gameState.resolveCollisions()
    #expect(gameState.isCaped)
    #expect(gameState.capes[0].collected)
  }

  @Test func jumpClearingAnObstacleCostsNoHealth() {
    let gameState = configured()
    gameState.damageCooldown = 0
    let start = gameState.health
    // Obstacle horizontally aligned but a jump-arc's clearance above the honest hit
    // box — a gap the old full-size box would have wrongly counted as a hit.
    let clearance = (GameState.playerHeight + GameState.obstacleHitSize) / 2 + 2
    let obstacle = Obstacle(
      id: 1, x: gameState.playerX, y: gameState.playerY + clearance,
      velocityX: 0, velocityY: 0, falling: false, level: 0, emoji: "🏳️", rotation: 0
    )
    gameState.obstacles.append(obstacle)
    gameState.resolveCollisions()
    #expect(gameState.health == start)        // cleared — no damage
    #expect(gameState.obstacles.count == 1)   // obstacle untouched
  }

  @Test func capeBlinksInFinalSecondsButStaysActive() {
    let gameState = configured()
    gameState.capedRemaining = 5          // solid phase (beyond the blink window)
    #expect(gameState.isCaped)
    #expect(gameState.isCapeVisible)
    // In the final capeBlinkDuration seconds the overlay flashes on/off while the
    // power-up itself stays active.
    gameState.capedRemaining = 1.0
    #expect(gameState.isCapeVisible)      // Int(10) % 2 == 0 → shown
    gameState.capedRemaining = 1.5
    #expect(!gameState.isCapeVisible)     // Int(15) % 2 == 1 → blinked out
    #expect(gameState.isCaped)            // gameplay unaffected during the blink
  }

  @Test func fifthSummitTriggersTheBossFight() {
    // Summit 5 (summitsToBoss = 5) enters the boss intro; the earlier four are escape
    // beats. Pre-set summitCount = 4 so this summit is the fifth. The boss machinery
    // itself is covered in GameBossTests.
    let gameState = configured()
    gameState.summitCount = 4
    gameState.playerX = gameState.bullX
    gameState.playerY = gameState.bullY
    gameState.obstacles.append(obstacleOnPlayer(gameState))
    gameState.checkReachedBull()
    #expect(gameState.summitCount == 5)
    #expect(gameState.phase == .bossIntro)
    #expect(gameState.obstacles.isEmpty)               // field cleared for the stage
  }

  // MARK: Stage system (La Subida)

  @Test func obstacleSpeedCompoundsPerStage() {
    let gameState = configured()
    gameState.stage = 1
    #expect(abs(gameState.obstacleSpeed - GameState.obstacleRollSpeed) < 0.001)
    gameState.stage = 5
    let expected = GameState.obstacleRollSpeed * pow(GameState.stageSpeedFactor, 4)
    #expect(abs(gameState.obstacleSpeed - expected) < 0.001)
  }

  @Test func landedObstacleReRollsAtStageSpeed() {
    let gameState = configured()
    gameState.stage = 3
    let top = GameState.levelCount - 1
    // An obstacle a hair above the platform below its current level, falling — one
    // tick should snap it onto that girder and re-roll its speed at the stage rate.
    let target = top - 1
    let surface = gameState.platforms[target].surfaceY
    let obstacle = Obstacle(
      id: 1, x: gameState.screenSize.width / 2,
      y: surface - GameState.obstacleSize / 2 - 0.5,
      velocityX: 0, velocityY: 10, falling: true, level: top,
      emoji: "⚽", rotation: 0, style: .spin
    )
    gameState.obstacles.append(obstacle)
    gameState.updateObstacles(dt: 1.0 / 60.0)
    let landed = gameState.obstacles[0]
    #expect(!landed.falling)
    #expect(landed.level == target)
    #expect(abs(abs(landed.velocityX) - gameState.obstacleSpeed) < 0.001)
  }

  @Test func stageSelectsItsObstacleSetAndStyle() {
    let gameState = configured()
    let expectedSets: [[String]] = [
      GameState.flagEmojis, GameState.animalEmojis, GameState.ballEmojis,
      GameState.vehicleEmojis, GameState.skyEmojis
    ]
    let expectedStyles: [ObstacleStyle] = [.spin, .face, .spin, .face, .upright]
    for stage in 1...GameState.stageCount {
      gameState.stage = stage
      #expect(gameState.stageEmojis == expectedSets[stage - 1])
      #expect(gameState.stageObstacleStyle == expectedStyles[stage - 1])
    }
  }

  // MARK: Per-set rendering (facing / spin)

  @Test func faceObstacleFacesTravelWithoutSpinning() {
    let gameState = configured()
    // Level 0 rolls RIGHT (rollDirection(0) = +1); a `.face` obstacle there faces
    // right (+1) and never accumulates rotation. Placed left of its drop point so it
    // keeps rolling for the tick.
    let surface = gameState.platforms[0].surfaceY
    let obstacle = Obstacle(
      id: 1, x: gameState.screenSize.width * 0.2, y: surface - GameState.obstacleSize / 2,
      velocityX: gameState.obstacleSpeed, velocityY: 0, falling: false, level: 0,
      emoji: "🐎", rotation: 0, style: .face, facing: -1
    )
    gameState.obstacles.append(obstacle)
    gameState.updateObstacles(dt: 1.0 / 60.0)
    #expect(gameState.obstacles[0].facing == 1)          // moving right → faces right
    #expect(gameState.obstacles[0].rotation == 0)        // .face never spins
  }

  @Test func faceObstacleFlipsFacingAtLandingReversal() {
    let gameState = configured()
    // Land onto an odd level (which rolls LEFT), so the re-roll flips facing to −1.
    let target = 3
    let surface = gameState.platforms[target].surfaceY
    let obstacle = Obstacle(
      id: 1, x: gameState.screenSize.width / 2,
      y: surface - GameState.obstacleSize / 2 - 0.5,
      velocityX: 0, velocityY: 10, falling: true, level: target + 1,
      emoji: "🐎", rotation: 0, style: .face, facing: 1
    )
    gameState.obstacles.append(obstacle)
    gameState.updateObstacles(dt: 1.0 / 60.0)
    #expect(!gameState.obstacles[0].falling)
    #expect(gameState.obstacles[0].facing == -1)         // odd level rolls left
  }

  @Test func spinObstacleAccumulatesRotation() {
    let gameState = configured()
    let top = GameState.levelCount - 1
    let surface = gameState.platforms[top].surfaceY
    let obstacle = Obstacle(
      id: 1, x: gameState.screenSize.width / 2, y: surface - GameState.obstacleSize / 2,
      velocityX: 60, velocityY: 0, falling: false, level: top,
      emoji: "🇪🇸", rotation: 0, style: .spin
    )
    gameState.obstacles.append(obstacle)
    gameState.updateObstacles(dt: 1.0 / 60.0)
    #expect(gameState.obstacles[0].rotation != 0)        // .spin tumbles
  }

  // MARK: Escape beat

  @Test func nonFinalSummitEntersEscapeAndClearsField() {
    let gameState = configured()
    gameState.summitCount = 0
    gameState.obstacles.append(obstacleOnPlayer(gameState))
    gameState.playerX = gameState.bullX
    gameState.playerY = gameState.bullY
    gameState.checkReachedBull()
    #expect(gameState.summitCount == 1)
    #expect(gameState.phase == .escape)
    #expect(gameState.obstacles.isEmpty)
  }

  @Test func escapeCompletesIntoTheNextStage() {
    let gameState = configured()
    gameState.summitCount = 1                            // just summited stage 1
    gameState.health = 1
    gameState.enterEscape()
    #expect(gameState.phase == .escape)
    // Drive the escape until the bull + matador clear the top and the stage rebuilds.
    var safety = 0
    while gameState.phase == .escape && safety < 1000 {
      safety += 1
      gameState.updateEscape(dt: 1.0 / 60.0)
    }
    #expect(gameState.phase == .climb)
    #expect(gameState.stage == 2)                        // summitCount + 1
    #expect(gameState.health == GameState.maxHealth)     // hearts refilled
    let feet = gameState.playerY + GameState.playerHeight / 2
    #expect(abs(feet - gameState.platforms[0].surfaceY) < 0.5)   // back at the start
    #expect(abs(gameState.playerX - gameState.screenSize.width * 0.15) < 0.5)
  }

  @Test func nivelBannerFadesDuringTheClimb() {
    let gameState = configured()
    gameState.summitCount = 1
    gameState.enterEscape()
    var safety = 0
    while gameState.phase == .escape && safety < 1000 {
      safety += 1
      gameState.updateEscape(dt: 1.0 / 60.0)
    }
    // A "¡Nivel 2!" banner is present the moment the stage rebuilds…
    #expect(gameState.jaleoPops.count == 1)
    #expect(gameState.phase == .climb)
    // …and the climb pipeline ages it out (banner ttl is 2 s).
    gameState.advanceJaleoPops(dt: 2.1)
    #expect(gameState.jaleoPops.isEmpty)
  }

  // MARK: Soft respawn

  @Test func deathSoftRespawnsKeepingProgress() {
    let gameState = configured()
    gameState.stage = 3
    gameState.summitCount = 2
    gameState.score = 500
    gameState.capedRemaining = 4
    gameState.obstacles.append(obstacleOnPlayer(gameState))
    gameState.respawn()
    #expect(gameState.health == GameState.maxHealth)
    #expect(gameState.stage == 3)                        // progress kept
    #expect(gameState.summitCount == 2)
    #expect(gameState.score == 500)
    #expect(gameState.obstacles.isEmpty)                 // field cleared
    #expect(gameState.capedRemaining == 0)               // power-up timers zeroed
    #expect(gameState.damageCooldown == GameState.respawnGrace)
    let feet = gameState.playerY + GameState.playerHeight / 2
    #expect(abs(feet - gameState.platforms[0].surfaceY) < 0.5)   // bottom-left start
    #expect(abs(gameState.playerX - gameState.screenSize.width * 0.15) < 0.5)
  }

  @Test func lethalHitSoftRespawnsInsteadOfFullReset() {
    let gameState = configured()
    gameState.stage = 2
    gameState.summitCount = 1
    gameState.health = 1
    gameState.damageCooldown = 0
    gameState.obstacles.append(obstacleOnPlayer(gameState))
    gameState.resolveCollisions()
    #expect(gameState.health == GameState.maxHealth)     // respawned, not zeroed out
    #expect(gameState.stage == 2)                        // stage NOT reset to 1
    #expect(gameState.summitCount == 1)
    #expect(gameState.phase == .climb)
  }
}
