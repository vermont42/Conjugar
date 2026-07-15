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
    #expect(gameState.powerUps.count == 2)
    #expect(gameState.playerGrounded)
    #expect(gameState.playerLevel == 0)
    let feet = gameState.playerY + GameState.playerHeight / 2
    #expect(abs(feet - gameState.platforms[0].surfaceY) < 0.5)
  }

  @Test func reconfigureRebuildsGeometryForNewSizeAndReseatsPlayer() {
    let gameState = configured()
    let oldPlatformWidth = gameState.platforms[0].rect.width

    // Simulate an iPad rotation to a wider, shorter field.
    let wider = CGSize(width: 700, height: 500)
    gameState.reconfigure(screenSize: wider)

    #expect(gameState.screenSize == wider)
    #expect(gameState.platforms.count == GameState.levelCount)
    #expect(gameState.ladders.count == GameState.levelCount - 1)
    // Platforms span the new width (minus the side margins), not the old.
    #expect(abs(gameState.platforms[0].rect.width - (wider.width - 2 * GameState.sideMargin)) < 0.5)
    #expect(gameState.platforms[0].rect.width != oldPlatformWidth)
    // The climbing player soft-respawns to the bottom platform, within the new bounds.
    #expect(gameState.playerGrounded)
    #expect(gameState.playerLevel == 0)
    #expect(gameState.playerX <= wider.width - GameState.sideMargin)
    let feet = gameState.playerY + GameState.playerHeight / 2
    #expect(abs(feet - gameState.platforms[0].surfaceY) < 0.5)
    // Pickups are re-placed for the new width (both back to uncollected).
    #expect(gameState.powerUps.count == 2)
    #expect(gameState.powerUps.allSatisfy { $0.x <= wider.width })
    // The pacing bull re-seats onto the rebuilt top platform (not left hanging
    // below it), within the new pacing bounds.
    let top = GameState.levelCount - 1
    #expect(abs(gameState.bullY - (gameState.platforms[top].surfaceY - GameState.bullSize / 2)) < 0.5)
    #expect(gameState.bullX >= wider.width * 0.15)
    #expect(gameState.bullX <= wider.width * 0.6)
  }

  @Test func reconfigureDuringBossReseatsMatadorOnItsPedestal() {
    let gameState = configured()
    gameState.enterBossIntro()
    gameState.handleBossTap()   // skip the intro → actors settle at stage marks

    let wider = CGSize(width: 700, height: 500)
    gameState.reconfigure(screenSize: wider)

    // The matador belongs on his pedestal (matadorStage), not the climb home on the
    // top platform — regression guard for the landscape-rotation bug.
    #expect(abs(gameState.bullfighterX - gameState.matadorStageX) < 0.5)
    #expect(abs(gameState.bullfighterY - gameState.matadorStageY) < 0.5)
    // And the bull/dancer sit on the rebuilt bottom tablao floor.
    #expect(abs(gameState.bullY - gameState.bullStageY) < 0.5)
    #expect(abs(gameState.playerY - gameState.dancerStageY) < 0.5)
  }

  @Test func reconfigureIsANoOpForAnUnchangedSize() {
    let gameState = configured()
    gameState.playerX = 123   // a marker the reposition would overwrite
    gameState.reconfigure(screenSize: Self.size)
    #expect(gameState.playerX == 123)
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
    // Force a cape pickup under the player (a stage's kind is otherwise random).
    let cape = PowerUp(id: 0, x: gameState.playerX, y: gameState.playerY, kind: .cape, collected: false)
    gameState.powerUps = [cape]
    #expect(!gameState.isCaped)
    gameState.resolveCollisions()
    #expect(gameState.isCaped)
    #expect(gameState.powerUps[0].collected)
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

  // MARK: Power-ups (La Subida — cape / speed ⚡ / serenata 🎸)

  @Test func powerUpBagExhaustsAllKindsBeforeRepeating() {
    let gameState = configured()
    // Seed a deterministic RNG and empty the bag so the draws are reproducible.
    gameState.bossRNG = SplitMix64(seed: 0xC0FFEE)
    gameState.powerUpBag.removeAll()
    var draws: [PowerUpKind] = []
    for _ in 0..<6 { draws.append(gameState.drawStagePowerUpKind()) }
    // Each consecutive run of three is a full permutation — no kind repeats until the
    // bag exhausts and reshuffles.
    #expect(Set(draws[0..<3]) == Set(PowerUpKind.allCases))
    #expect(Set(draws[3..<6]) == Set(PowerUpKind.allCases))
  }

  @Test func speedPickupDoublesWalkDisplacement() {
    func walkDelta(speed: Double) -> CGFloat {
      let gameState = configured()
      gameState.movingRight = true
      gameState.speedRemaining = speed
      let x0 = gameState.playerX
      gameState.updatePlayer(dt: 1.0 / 60.0)
      return gameState.playerX - x0
    }
    let base = walkDelta(speed: 0)
    let fast = walkDelta(speed: GameState.speedDuration)
    #expect(base > 0)
    #expect(abs(fast - base * GameState.speedFactor) < 0.001)
  }

  @Test func speedPickupDoublesClimbDisplacement() {
    func climbDelta(speed: Double) -> CGFloat {
      let gameState = configured()
      let ladder = gameState.ladders.first { $0.lowerLevel == 0 }!
      gameState.playerX = ladder.x
      gameState.playerLevel = 0
      gameState.playerGrounded = true
      gameState.movingUp = true
      gameState.updatePlayer(dt: 1.0 / 60.0)   // enters the ladder (no vertical move yet)
      #expect(gameState.playerClimbing)
      gameState.speedRemaining = speed
      let y0 = gameState.playerY
      gameState.updatePlayer(dt: 1.0 / 60.0)   // one climb tick
      return y0 - gameState.playerY            // upward is positive
    }
    let base = climbDelta(speed: 0)
    let fast = climbDelta(speed: GameState.serenataDuration)
    #expect(base > 0)
    #expect(abs(fast - base * GameState.speedFactor) < 0.001)
  }

  @Test func speedFactorDropsBackWhenExpired() {
    let gameState = configured()
    gameState.speedRemaining = 3
    #expect(gameState.speedFactorNow == GameState.speedFactor)
    gameState.speedRemaining = 0
    #expect(gameState.speedFactorNow == 1)
  }

  @Test func serenataFreezesPacingAndThrowingThenResumes() {
    let gameState = configured()
    gameState.serenataRemaining = GameState.serenataDuration
    let bullX0 = gameState.bullX
    let spawnTimer0 = gameState.obstacleSpawnTimer
    // Run well past a spawn interval: the bull neither paces nor throws.
    for _ in 0..<300 { gameState.updateBull(dt: 1.0 / 60.0) }
    #expect(gameState.obstacles.isEmpty)              // no new obstacles
    #expect(gameState.obstacleSpawnTimer == spawnTimer0)   // spawn timer frozen
    #expect(gameState.bullX == bullX0)                // stopped pacing
    // Serenata over: pacing (and, on its own timer, throwing) resume.
    gameState.serenataRemaining = 0
    gameState.updateBull(dt: 1.0 / 60.0)
    gameState.advanceAnimations(dt: 1.0 / 60.0)
    #expect(gameState.bullX != bullX0)                // pacing again
    #expect(gameState.bullAction == .walk)            // back to the working stance
  }

  @Test func collectingEachPowerUpAppliesItsEffect() {
    for kind in PowerUpKind.allCases {
      let gameState = configured()
      gameState.powerUps = [PowerUp(id: 0, x: gameState.playerX, y: gameState.playerY, kind: kind, collected: false)]
      gameState.resolveCollisions()
      #expect(gameState.powerUps[0].collected)
      switch kind {
      case .cape:
        #expect(gameState.capedRemaining == GameState.capeDuration)
      case .speed:
        #expect(gameState.speedRemaining == GameState.speedDuration)
      case .serenata:
        #expect(gameState.serenataRemaining == GameState.serenataDuration)
      }
    }
  }

  @Test func advancingToNextStageDrawsAndArmsPowerUps() {
    let gameState = configured()
    gameState.summitCount = 1
    gameState.enterEscape()
    var safety = 0
    while gameState.phase == .escape && safety < 1000 {
      safety += 1
      gameState.updateEscape(dt: 1.0 / 60.0)
    }
    // The next stage re-armed both pickups, all sharing the drawn kind, uncollected.
    #expect(gameState.powerUps.count == 2)
    #expect(gameState.powerUps.allSatisfy { !$0.collected })
    #expect(gameState.powerUps.allSatisfy { $0.kind == gameState.stagePowerUpKind })
  }

  @Test func deathClearsPowerUpsButEscapeKeepsThem() {
    // Death clears every active power-up (respawn)…
    let dying = configured()
    dying.capedRemaining = 4
    dying.speedRemaining = 4
    dying.serenataRemaining = 4
    dying.respawn()
    #expect(dying.capedRemaining == 0)
    #expect(dying.speedRemaining == 0)
    #expect(dying.serenataRemaining == 0)

    // …but a summit's escape beat carries them across into the next stage.
    let summiting = configured()
    summiting.summitCount = 1
    summiting.capedRemaining = 4
    summiting.speedRemaining = 4
    summiting.enterEscape()
    #expect(summiting.capedRemaining == 4)
    #expect(summiting.speedRemaining == 4)
  }

  // MARK: Challenge mechanics (La Subida — framework + zombie attack)

  /// Put a single homing-able obstacle on a girder near the top, mid-field.
  private func obstacleMidField(_ gameState: GameState, style: ObstacleStyle = .spin) -> Obstacle {
    let level = GameState.levelCount - 1
    return Obstacle(
      id: 1, x: gameState.screenSize.width * 0.5,
      y: gameState.platforms[level].surfaceY - GameState.obstacleSize / 2,
      velocityX: 60, velocityY: 0, falling: false, level: level,
      emoji: "🇪🇸", rotation: 0, style: style
    )
  }

  @Test func mechanicBagExhaustsAllKindsBeforeRepeating() {
    let gameState = configured()
    gameState.bossRNG = SplitMix64(seed: 0xF00D)
    gameState.mechanicBag.removeAll()
    var draws: [ChallengeMechanic] = []
    for _ in 0..<6 { draws.append(gameState.drawStageMechanic()) }
    #expect(Set(draws[0..<3]) == Set(ChallengeMechanic.allCases))
    #expect(Set(draws[3..<6]) == Set(ChallengeMechanic.allCases))
  }

  @Test func schedulerFiresWithinTheDelayWindowThenReArms() {
    let gameState = configured()
    gameState.assignedMechanic = .zombie
    // Arm a first-appearance countdown inside `mechanicFirstDelay` (10…18 s).
    gameState.armMechanicCountdown(firstDelay: true)
    #expect(GameState.mechanicFirstDelay.contains(gameState.mechanicCountdown))
    #expect(gameState.activeMechanic == nil)

    // Tick past the countdown: the mechanic fires and its window opens.
    var elapsed = 0.0
    let dt = 1.0 / 60.0
    while gameState.activeMechanic == nil && elapsed < GameState.mechanicFirstDelay.upperBound + 1 {
      gameState.updateMechanicScheduler(dt: dt)
      elapsed += dt
    }
    #expect(gameState.activeMechanic == .zombie)
    #expect(elapsed <= GameState.mechanicFirstDelay.upperBound + 0.5)

    // Tick past the window: it ends and re-arms at the repeat delay.
    while gameState.activeMechanic != nil {
      gameState.updateMechanicScheduler(dt: dt)
    }
    #expect(gameState.activeMechanic == nil)
    #expect(abs(gameState.mechanicCountdown - GameState.mechanicRepeatDelay) < 0.1)
  }

  @Test func startingAMechanicSpawnsAnAnnouncementAtTheBull() {
    let gameState = configured()
    gameState.assignedMechanic = .zombie
    gameState.jaleoPops.removeAll()
    gameState.startMechanic()
    #expect(gameState.activeMechanic == .zombie)
    #expect(gameState.jaleoPops.count == 1)
    // The bull "speaks": the pop sits just below the bull.
    let pop = gameState.jaleoPops[0]
    #expect(abs(pop.x - gameState.bullX) < 0.5)
    #expect(pop.y > gameState.bullY)
  }

  @Test func zombieDriftsObstaclesTowardThePlayerAtHalfSpeed() {
    let gameState = configured()
    gameState.assignedMechanic = .zombie
    gameState.stage = 1
    // Player at bottom-left; an obstacle up and to the right of it.
    var obstacle = obstacleMidField(gameState)
    obstacle.x = gameState.playerX + 100
    gameState.obstacles = [obstacle]
    gameState.startMechanic()

    let before = gameState.obstacles[0]
    let dt: CGFloat = 1.0 / 60.0
    gameState.updateZombieObstacles(dt: dt)
    let after = gameState.obstacles[0]

    // Moved toward the player: leftward (player is to the left) and downward.
    #expect(after.x < before.x)
    #expect(after.y > before.y)
    // Total displacement is (obstacleSpeed × 0.5) × dt, not the full obstacle speed.
    let dx = after.x - before.x
    let dy = after.y - before.y
    let moved = (dx * dx + dy * dy).squareRoot()
    let expected = gameState.obstacleSpeed * GameState.zombieSpeedFactor * dt
    #expect(abs(moved - expected) < 0.01)
  }

  @Test func zombieFacesAFaceObstacleTowardItsDrift() {
    let gameState = configured()
    gameState.assignedMechanic = .zombie
    // A `.face` obstacle to the RIGHT of the player drifts left → faces left (−1); one
    // to the LEFT drifts right → faces right (+1).
    var right = obstacleMidField(gameState, style: .face)
    right.x = gameState.playerX + 120
    right.facing = 1
    gameState.obstacles = [right]
    gameState.startMechanic()
    gameState.updateZombieObstacles(dt: 1.0 / 60.0)
    #expect(gameState.obstacles[0].facing == -1)
    #expect(gameState.obstacles[0].rotation == 0)   // .face never spins, even homing
  }

  @Test func zombieEndReintegratesObstaclesOntoGirders() {
    let gameState = configured()
    gameState.assignedMechanic = .zombie
    gameState.startMechanic()
    // An obstacle floating in a gap (between girders) is relevel'd to fall onto the
    // nearest girder below its feet; one below the bottom girder despawns.
    let midGapY = (gameState.platforms[2].surfaceY + gameState.platforms[1].surfaceY) / 2
    var floating = obstacleMidField(gameState)
    floating.y = midGapY
    floating.level = 5
    var belowFloor = obstacleMidField(gameState)
    belowFloor.y = gameState.platforms[0].surfaceY + 200   // past the bottom girder
    gameState.obstacles = [floating, belowFloor]
    gameState.endMechanic()

    #expect(gameState.activeMechanic == nil)
    #expect(gameState.obstacles.count == 1)               // the below-floor one despawned
    let survivor = gameState.obstacles[0]
    #expect(survivor.falling)                             // dropping onto the girder below
    #expect(survivor.level == 2)                          // nearest girder below its feet, + 1
  }

  @Test func respawnCancelsAnActiveMechanicAndReArms() {
    let gameState = configured()
    gameState.assignedMechanic = .zombie
    gameState.startMechanic()
    #expect(gameState.activeMechanic != nil)
    gameState.respawn()
    #expect(gameState.activeMechanic == nil)
    #expect(gameState.mechanicRemaining == 0)
    #expect(GameState.mechanicFirstDelay.contains(gameState.mechanicCountdown))
  }

  @Test func escapeAndBossEntryCancelAnActiveMechanic() {
    let escaping = configured()
    escaping.summitCount = 1
    escaping.assignedMechanic = .zombie
    escaping.startMechanic()
    escaping.enterEscape()
    #expect(escaping.activeMechanic == nil)

    let bossing = configured()
    bossing.assignedMechanic = .zombie
    bossing.startMechanic()
    bossing.enterBossIntro()
    #expect(bossing.activeMechanic == nil)
  }

  @Test func advancingToNextStageAssignsAFreshMechanic() {
    let gameState = configured()
    gameState.summitCount = 1
    gameState.enterEscape()
    var safety = 0
    while gameState.phase == .escape && safety < 1000 {
      safety += 1
      gameState.updateEscape(dt: 1.0 / 60.0)
    }
    // A fresh stage has no active window and an armed first-appearance countdown.
    #expect(gameState.activeMechanic == nil)
    #expect(GameState.mechanicFirstDelay.contains(gameState.mechanicCountdown))
  }

  // MARK: El Encierro (Phase 4 — the 🐂 charger stampede)

  /// A charger placed on the player, so it registers a hit in `resolveCollisions`.
  private func chargerOnPlayer(_ gameState: GameState) -> Charger {
    Charger(id: 0, x: gameState.playerX, y: gameState.playerY, level: 0, direction: 1)
  }

  @Test func encierroFirstChargerTargetsThePlayersGirder() {
    let gameState = configured()
    gameState.assignedMechanic = .encierro
    gameState.playerLevel = 2
    gameState.startMechanic()
    gameState.updateChargers(dt: 1.0 / 60.0)   // window open → the first charger enters
    #expect(gameState.chargers.count == 1)
    #expect(gameState.chargers[0].level == 2)   // biased onto the player's girder
  }

  @Test func chargerCrossesAtDoubleStageObstacleSpeed() {
    let gameState = configured()
    gameState.stage = 3
    // No active mechanic → `updateChargers` only moves the existing charger (no spawn).
    gameState.chargers = [Charger(id: 0, x: 100, y: 200, level: 0, direction: 1)]
    let dt: CGFloat = 1.0 / 60.0
    let x0 = gameState.chargers[0].x
    gameState.updateChargers(dt: dt)
    let dx = gameState.chargers[0].x - x0
    let expected = gameState.obstacleSpeed * GameState.chargerSpeedFactor * dt
    #expect(abs(dx - expected) < 0.01)
  }

  @Test func chargerDespawnsAfterCrossingOffScreen() {
    let gameState = configured()
    gameState.chargers = [
      Charger(id: 0, x: gameState.screenSize.width + GameState.chargerSize + 5, y: 200, level: 0, direction: 1)
    ]
    gameState.updateChargers(dt: 1.0 / 60.0)
    #expect(gameState.chargers.isEmpty)
  }

  @Test func chargerHitCostsOnePipAndConsumesTheCharger() {
    let gameState = configured()
    gameState.damageCooldown = 0
    let start = gameState.health
    gameState.chargers = [chargerOnPlayer(gameState)]
    gameState.resolveCollisions()
    #expect(gameState.health == start - 1)
    #expect(gameState.chargers.isEmpty)
  }

  @Test func chargerHitRespectsDamageCooldown() {
    let gameState = configured()
    gameState.damageCooldown = 0.5             // still cooling down from a prior hit
    let start = gameState.health
    gameState.chargers = [chargerOnPlayer(gameState)]
    gameState.resolveCollisions()
    #expect(gameState.health == start)         // no second hit during the cooldown
    #expect(gameState.chargers.count == 1)     // and the charger keeps going
  }

  @Test func capedPlayerSmashesChargerWithoutDamage() {
    let gameState = configured()
    gameState.capedRemaining = 5
    let start = gameState.health
    gameState.chargers = [chargerOnPlayer(gameState)]
    gameState.resolveCollisions()
    #expect(gameState.health == start)
    #expect(gameState.chargers.isEmpty)        // smashed
  }

  @Test func jumpClearingAChargerCostsNoHealth() {
    let gameState = configured()
    gameState.damageCooldown = 0
    let start = gameState.health
    // A charger below the honest hit box — a jump-arc's clearance the full box would
    // have wrongly counted (mirrors `jumpClearingAnObstacleCostsNoHealth`).
    let clearance = (GameState.playerHeight + GameState.chargerHitSize) / 2 + 2
    gameState.chargers = [
      Charger(id: 0, x: gameState.playerX, y: gameState.playerY + clearance, level: 0, direction: 1)
    ]
    gameState.resolveCollisions()
    #expect(gameState.health == start)         // cleared — no damage
    #expect(gameState.chargers.count == 1)     // charger untouched
  }

  @Test func encierroEndStopsSpawnsButStragglersKeepCrossing() {
    let gameState = configured()
    gameState.assignedMechanic = .encierro
    gameState.startMechanic()
    gameState.updateChargers(dt: 1.0 / 60.0)   // spawn the window's first charger
    let strays = gameState.chargers.count
    #expect(strays >= 1)

    gameState.endMechanic()                    // window closes naturally
    #expect(gameState.activeMechanic == nil)
    #expect(gameState.chargers.count == strays)   // stragglers are NOT cleared

    // With the window closed, no new chargers spawn — the field only empties as the
    // stragglers cross off-screen.
    gameState.chargers.removeAll()
    for _ in 0..<120 { gameState.updateChargers(dt: 1.0 / 60.0) }
    #expect(gameState.chargers.isEmpty)
  }

  @Test func cancelingEncierroClearsChargers() {
    // A cancel path (here: respawn) clears in-flight chargers, unlike a natural end.
    let gameState = configured()
    gameState.assignedMechanic = .encierro
    gameState.startMechanic()
    gameState.updateChargers(dt: 1.0 / 60.0)
    #expect(!gameState.chargers.isEmpty)
    gameState.respawn()
    #expect(gameState.chargers.isEmpty)
  }

  // MARK: El Apagón (Phase 5 — the lights-out spotlight)

  @Test func apagonEnvelopeRisesHoldsAndFallsOnSchedule() {
    let gameState = configured()
    gameState.assignedMechanic = .apagon
    gameState.startMechanic()
    #expect(gameState.activeMechanic == .apagon)
    #expect(gameState.apagonDim == 0)          // starts dark-off; ramps from here

    let dt = 1.0 / 60.0

    // Fade-in: partway through `apagonFadeIn` the darkness is between 0 and 1.
    gameState.updateMechanicScheduler(dt: GameState.apagonFadeIn / 2)
    #expect(gameState.apagonDim > 0 && gameState.apagonDim < 1)

    // Hold: once past the fade-in (and well before the fade-out) it's fully dark.
    gameState.updateMechanicScheduler(dt: GameState.apagonFadeIn)
    #expect(abs(gameState.apagonDim - 1) < 0.0001)

    // Tick into the fade-out tail: the darkness comes back down below full.
    while gameState.mechanicRemaining > GameState.apagonFadeOut * 0.5 && gameState.activeMechanic != nil {
      gameState.updateMechanicScheduler(dt: dt)
    }
    if gameState.activeMechanic != nil {
      #expect(gameState.apagonDim < 1)
    }

    // Run the window out: the lights come fully back on and the scheduler re-arms.
    while gameState.activeMechanic != nil {
      gameState.updateMechanicScheduler(dt: dt)
    }
    #expect(gameState.apagonDim == 0)
    #expect(abs(gameState.mechanicCountdown - GameState.mechanicRepeatDelay) < 0.1)
  }

  @Test func apagonNeverExceedsFullDarkness() {
    let gameState = configured()
    gameState.assignedMechanic = .apagon
    gameState.startMechanic()
    // Sweep the whole window: `apagonDim` stays within [0, 1] every frame.
    while gameState.activeMechanic != nil {
      gameState.updateMechanicScheduler(dt: 1.0 / 60.0)
      #expect(gameState.apagonDim >= 0 && gameState.apagonDim <= 1)
    }
  }

  @Test func cancelingApagonZeroesTheDarkness() {
    let gameState = configured()
    gameState.assignedMechanic = .apagon
    gameState.startMechanic()
    // Drive into the full-dark hold, then cancel via respawn: the lights snap back on.
    gameState.updateMechanicScheduler(dt: GameState.apagonFadeIn + 0.1)
    #expect(gameState.apagonDim > 0)
    gameState.respawn()
    #expect(gameState.activeMechanic == nil)
    #expect(gameState.apagonDim == 0)
  }

  @Test func escapeAndBossEntryZeroApagonDarkness() {
    let escaping = configured()
    escaping.summitCount = 1
    escaping.assignedMechanic = .apagon
    escaping.startMechanic()
    escaping.updateMechanicScheduler(dt: GameState.apagonFadeIn + 0.1)
    #expect(escaping.apagonDim > 0)
    escaping.enterEscape()
    #expect(escaping.apagonDim == 0)

    let bossing = configured()
    bossing.assignedMechanic = .apagon
    bossing.startMechanic()
    bossing.updateMechanicScheduler(dt: GameState.apagonFadeIn + 0.1)
    #expect(bossing.apagonDim > 0)
    bossing.enterBossIntro()
    #expect(bossing.apagonDim == 0)
  }

  @Test func apagonAnnouncesAtTheBull() {
    let gameState = configured()
    gameState.assignedMechanic = .apagon
    gameState.jaleoPops.removeAll()
    gameState.startMechanic()
    #expect(gameState.jaleoPops.count == 1)
    let pop = gameState.jaleoPops[0]
    #expect(abs(pop.x - gameState.bullX) < 0.5)
    #expect(pop.y > gameState.bullY)
  }
}
