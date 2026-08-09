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

  @Test func obstacleHitCostsOnePipAndFadesTheObstacle() {
    let gameState = configured()
    let start = gameState.health
    gameState.damageCooldown = 0
    gameState.obstacles.append(obstacleOnPlayer(gameState))
    gameState.resolveCollisions()
    #expect(gameState.health == start - 1)
    // The struck obstacle now fades out over 1 s (non-colliding while it fades) instead of
    // vanishing instantly, and throws a yellow particle burst at its position.
    #expect(gameState.obstacles.count == 1)
    #expect(gameState.obstacles[0].fadeRemaining == GameState.obstacleFadeDuration)
    #expect(!gameState.hitParticles.isEmpty)
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
    let bag = PowerUpKind.allCases.count
    var draws: [PowerUpKind] = []
    for _ in 0..<(bag * 2) { draws.append(gameState.drawStagePowerUpKind()) }
    // Each consecutive run of `bag` draws is a full permutation — no kind repeats until
    // the bag exhausts and reshuffles.
    #expect(Set(draws[0..<bag]) == Set(PowerUpKind.allCases))
    #expect(Set(draws[bag..<(bag * 2)]) == Set(PowerUpKind.allCases))
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
      case .flechazo:
        #expect(gameState.flechazoRemaining == GameState.flechazoDuration)
      case .cortejo:
        // Cortejo starts no timer — it possesses an obstacle. With none present here the
        // collection is a graceful no-op; its behavior is covered by the cortejo tests.
        break
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
    let bag = ChallengeMechanic.allCases.count
    var draws: [ChallengeMechanic] = []
    for _ in 0..<(bag * 2) { draws.append(gameState.drawStageMechanic()) }
    #expect(Set(draws[0..<bag]) == Set(ChallengeMechanic.allCases))
    #expect(Set(draws[bag..<(bag * 2)]) == Set(ChallengeMechanic.allCases))
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

  // MARK: El Terremoto (earthquake mechanic)

  @Test func terremotoOpensGapsRoughlyTenPercentOfEachGirder() {
    let gameState = configured()
    gameState.assignedMechanic = .terremoto
    gameState.startMechanic()
    #expect(gameState.activeMechanic == .terremoto)
    #expect(!gameState.platformGaps.isEmpty)
    // Each girder's holes sum to ~earthquakeGapFraction of its width.
    for platform in gameState.platforms {
      let gapsHere = gameState.platformGaps.filter { $0.level == platform.level }
      guard !gapsHere.isEmpty else { continue }
      let removed = gapsHere.reduce(CGFloat(0)) { $0 + ($1.xRange.upperBound - $1.xRange.lowerBound) }
      let fraction = removed / platform.rect.width
      #expect(abs(fraction - GameState.earthquakeGapFraction) < 0.01)
    }
  }

  @Test func terremotoNeverOpensAGapUnderALadderMouth() {
    let gameState = configured()
    gameState.assignedMechanic = .terremoto
    gameState.startMechanic()
    #expect(!gameState.platformGaps.isEmpty)
    let clearance = GameState.ladderWidth / 2 + GameState.playerWidth / 2
    // No hole may straddle a ladder that rises from or arrives at that girder — the climb
    // route must stay intact and the player must be able to stand at every ladder base.
    for gap in gameState.platformGaps {
      let mouths = gameState.ladders
        .filter { $0.lowerLevel == gap.level || $0.upperLevel == gap.level }
        .map { ($0.x - clearance)...($0.x + clearance) }
      #expect(!mouths.contains { $0.overlaps(gap.xRange) })
    }
  }

  @Test func terremotoSparesAStandingStillPlayersFootprint() {
    let gameState = configured()
    // Idle player on the bottom girder — no horizontal intent, grounded, not climbing.
    gameState.playerLevel = 0
    gameState.playerGrounded = true
    gameState.playerClimbing = false
    gameState.movingLeft = false
    gameState.movingRight = false
    gameState.assignedMechanic = .terremoto
    gameState.startMechanic()
    let clearance = GameState.playerWidth / 2 + 4
    let footprint = (gameState.playerX - clearance)...(gameState.playerX + clearance)
    // No hole on her girder may open under a standing-still dancer.
    for gap in gameState.platformGaps where gap.level == 0 {
      #expect(!gap.xRange.overlaps(footprint))
    }
  }

  @Test func fadingGapIsSolidButAFinishedGapDropsThePlayer() {
    let gameState = configured()
    gameState.assignedMechanic = .terremoto
    gameState.startMechanic()
    // Put a gap directly under the player on the bottom girder.
    gameState.playerLevel = 0
    let px = gameState.playerX
    gameState.platformGaps = [
      PlatformGap(id: 0, level: 0, xRange: (px - 15)...(px + 15), fadeRemaining: 1.0)
    ]
    // While the gap is still fading it is SOLID — the player stays grounded over it.
    gameState.playerGrounded = true
    gameState.playerVelocityY = 0
    gameState.playerY = gameState.platforms[0].surfaceY - GameState.playerHeight / 2
    gameState.updatePlayer(dt: 1.0 / 60.0)
    #expect(gameState.playerGrounded)

    // Once the gap finishes fading it is a true hole — the player falls through it.
    gameState.platformGaps[0].fadeRemaining = 0
    gameState.playerGrounded = true
    gameState.playerVelocityY = 0
    gameState.playerY = gameState.platforms[0].surfaceY - GameState.playerHeight / 2
    gameState.updatePlayer(dt: 1.0 / 60.0)
    #expect(!gameState.playerGrounded)   // no support over the finished hole
  }

  @Test func fallingThroughTheFloorCostsExactlyOnePipAndRepositions() {
    let gameState = configured()
    gameState.damageCooldown = 0
    let start = gameState.health
    // Drop the player below the bottom girder through a finished gap.
    gameState.platformGaps = [PlatformGap(id: 0, level: 0, xRange: 0...400, fadeRemaining: 0)]
    gameState.playerGrounded = false
    gameState.playerY = gameState.platforms[0].surfaceY + 40
    gameState.fellThroughFloor()
    #expect(gameState.health == start - 1)              // exactly one heart
    #expect(gameState.playerGrounded)                   // back on the bottom platform
    #expect(gameState.playerLevel == 0)
    #expect(gameState.damageCooldown == GameState.respawnGrace)
    let feet = gameState.playerY + GameState.playerHeight / 2
    #expect(abs(feet - gameState.platforms[0].surfaceY) < 0.5)
  }

  @Test func terremotoEndHealsTheGirders() {
    let gameState = configured()
    gameState.assignedMechanic = .terremoto
    gameState.startMechanic()
    #expect(!gameState.platformGaps.isEmpty)
    gameState.endMechanic()
    #expect(gameState.activeMechanic == nil)
    #expect(gameState.platformGaps.isEmpty)             // beams restored
    #expect(gameState.earthquakeShakeOffsetY == 0)      // jiggle stops with the window
  }

  @Test func obstacleHopsOverAFinishedGapStayingOnItsGirder() {
    let gameState = configured()
    let level = GameState.levelCount - 1
    let surface = gameState.platforms[level].surfaceY
    let gapX = gameState.screenSize.width * 0.5
    // A finished hole on the obstacle's girder, with the obstacle rolling into it.
    gameState.platformGaps = [PlatformGap(id: 0, level: level, xRange: (gapX - 10)...(gapX + 10), fadeRemaining: 0)]
    let obstacle = Obstacle(
      id: 1, x: gapX, y: surface - GameState.obstacleSize / 2,
      velocityX: gameState.obstacleSpeed, velocityY: 0, falling: false, level: level,
      emoji: "🇪🇸", rotation: 0, style: .spin
    )
    gameState.obstacles.append(obstacle)
    gameState.updateObstacles(dt: 1.0 / 60.0)
    // It launched into a hop rather than falling to the girder below.
    #expect(gameState.obstacles[0].hopping)
    #expect(gameState.obstacles[0].velocityY < 0)       // arcing upward
    #expect(gameState.obstacles[0].level == level)       // still bound to the same girder
    #expect(!gameState.obstacles[0].falling)
  }

  // MARK: La Camada (obstacles multiply)

  private func fullObstacleMidField(_ gameState: GameState) -> Obstacle {
    let level = GameState.levelCount - 1
    return Obstacle(
      id: 42, x: gameState.screenSize.width * 0.5,
      y: gameState.platforms[level].surfaceY - GameState.obstacleSize / 2,
      velocityX: gameState.obstacleSpeed, velocityY: 0, falling: false, level: level,
      emoji: "🐎", rotation: 0, style: .face, facing: 1
    )
  }

  @Test func camadaSpawnsOneHalfSizeBabyPerEligibleParent() {
    let gameState = configured()
    gameState.assignedMechanic = .camada
    gameState.obstacles = [fullObstacleMidField(gameState)]
    gameState.obstacleCounter = 100
    gameState.startMechanic()
    let babies = gameState.obstacles.filter { $0.parentID != nil }
    #expect(babies.count == 1)                            // one baby for the one parent
    #expect(babies[0].parentID == 42)
    #expect(babies[0].scale == GameState.babyScale)       // half size
    #expect(babies[0].birthRemaining == GameState.babyBirthSlide)
    // A baby is NOT itself eligible to breed: a re-fire spawns more children of the FULL
    // parent (42), never a grandchild whose parent is a baby.
    gameState.startMechanic()
    #expect(gameState.obstacles.filter { $0.parentID != nil }.allSatisfy { $0.parentID == 42 })
  }

  @Test func babyMirrorsItsParentAfterTheBirthSlide() {
    let gameState = configured()
    gameState.assignedMechanic = .camada
    var parent = fullObstacleMidField(gameState)
    parent.velocityX = gameState.obstacleSpeed   // rolling right → baby slides left
    gameState.obstacles = [parent]
    gameState.startMechanic()
    // Finish the birth slide, then move the parent and confirm the baby tracks it.
    guard let bi = gameState.obstacles.firstIndex(where: { $0.parentID != nil }) else {
      Issue.record("no baby spawned"); return
    }
    gameState.obstacles[bi].birthRemaining = 0
    gameState.updateBabies(dt: 1.0 / 60.0)
    let baby = gameState.obstacles.first { $0.parentID != nil }!
    let parentNow = gameState.obstacles.first { $0.parentID == nil }!
    // Locked to the trailing offset (opposite the parent's rightward travel → to its left).
    #expect(baby.x < parentNow.x)
    #expect(abs(baby.x - (parentNow.x + baby.birthOffset.width)) < 0.5)
  }

  @Test func aBabyHitFadesAllBabiesButNotTheParents() {
    let gameState = configured()
    gameState.damageCooldown = 0
    let level = GameState.levelCount - 1
    let surface = gameState.platforms[level].surfaceY - GameState.obstacleSize / 2
    // A full-size parent plus two babies (children of it); one baby sits on the player.
    let parent = Obstacle(id: 10, x: 150, y: surface, velocityX: 0, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0)
    let babyOnPlayer = Obstacle(id: 11, x: gameState.playerX, y: gameState.playerY, velocityX: 0, velocityY: 0, falling: false, level: 0, emoji: "⚽", rotation: 0, scale: GameState.babyScale, parentID: 10)
    let babyElsewhere = Obstacle(id: 12, x: 250, y: surface, velocityX: 0, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0, scale: GameState.babyScale, parentID: 10)
    gameState.obstacles = [parent, babyOnPlayer, babyElsewhere]
    gameState.resolveCollisions()
    let babies = gameState.obstacles.filter { $0.parentID != nil }
    let parents = gameState.obstacles.filter { $0.parentID == nil }
    #expect(!babies.isEmpty)                               // the un-hit baby survives (fading)
    #expect(babies.allSatisfy { $0.fadeRemaining > 0 })   // every remaining baby is fading
    #expect(parents.allSatisfy { $0.fadeRemaining == 0 }) // the parent is untouched
  }

  // MARK: El Flechazo (heart missiles on jump)

  @Test func armedJumpFiresAHeartMissileWithOneSecondCooldown() {
    let gameState = configured()
    gameState.flechazoRemaining = GameState.flechazoDuration
    gameState.flechazoCooldown = 0
    gameState.obstacles = [fullObstacleMidField(gameState)]
    gameState.jump()
    #expect(gameState.heartMissiles.count == 1)
    #expect(gameState.flechazoCooldown == GameState.flechazoCooldownDuration)

    // A jump within the cooldown window fires no second missile.
    gameState.playerGrounded = true
    gameState.playerClimbing = false
    gameState.jump()
    #expect(gameState.heartMissiles.count == 1)
  }

  @Test func armedJumpWithNoTargetConsumesNoCooldown() {
    let gameState = configured()
    gameState.flechazoRemaining = GameState.flechazoDuration
    gameState.flechazoCooldown = 0
    gameState.obstacles.removeAll()
    gameState.jump()
    #expect(gameState.heartMissiles.isEmpty)
    #expect(gameState.flechazoCooldown == 0)   // no target → no cooldown spent
  }

  @Test func heartMissileFadesItsTargetOnContact() {
    let gameState = configured()
    var target = fullObstacleMidField(gameState)
    target.velocityX = 0
    gameState.obstacles = [target]
    // A missile essentially on top of the target.
    gameState.heartMissiles = [
      HeartMissile(id: 0, x: target.x, y: target.y, velocityX: 0, velocityY: 0, targetID: target.id, lifeRemaining: GameState.heartMissileLife)
    ]
    gameState.updateHeartMissiles(dt: 1.0 / 60.0)
    // The target now fades out over 1 s (non-colliding while it fades) with a yellow particle
    // burst, rather than vanishing instantly; the missile is consumed.
    #expect(gameState.obstacles.count == 1)
    #expect(gameState.obstacles[0].fadeRemaining == GameState.obstacleFadeDuration)
    #expect(!gameState.hitParticles.isEmpty)
    #expect(gameState.heartMissiles.isEmpty)    // missile consumed
  }

  // MARK: El Cortejo (mushroom chaser)

  @Test func cortejoPossessesThenChasesAfterTheVibrateWindow() {
    let gameState = configured()
    gameState.bossRNG = SplitMix64(seed: 0x5EED)
    let level = GameState.levelCount - 1
    let surface = gameState.platforms[level].surfaceY - GameState.obstacleSize / 2
    gameState.obstacles = [
      Obstacle(id: 1, x: 120, y: surface, velocityX: 40, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0),
      Obstacle(id: 2, x: 300, y: surface, velocityX: -40, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0)
    ]
    gameState.collectPowerUp(.cortejo)
    // One obstacle is now shivering (velocity zeroed, vibrate window running).
    let possessed = gameState.obstacles.first { $0.vibrateRemaining > 0 }
    #expect(possessed != nil)
    #expect(possessed?.isChaser == false)
    // Run out the vibrate window: it becomes a chaser.
    gameState.obstacles.indices.forEach { gameState.obstacles[$0].vibrateRemaining = min(gameState.obstacles[$0].vibrateRemaining, 0.001) }
    gameState.updateCortejo(dt: 1.0 / 60.0)
    #expect(gameState.obstacles.contains { $0.isChaser })
  }

  @Test func cortejoCatchFadesBothChaserAndQuarry() {
    let gameState = configured()
    let level = GameState.levelCount - 1
    let surface = gameState.platforms[level].surfaceY - GameState.obstacleSize / 2
    // A chaser essentially on top of its quarry → an immediate catch.
    gameState.obstacles = [
      Obstacle(id: 1, x: 200, y: surface, velocityX: 0, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0, isChaser: true, chaseTargetID: 2),
      Obstacle(id: 2, x: 205, y: surface, velocityX: 0, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0)
    ]
    gameState.updateCortejo(dt: 1.0 / 60.0)
    #expect(gameState.obstacles.first { $0.id == 1 }?.fadeRemaining ?? 0 > 0)
    #expect(gameState.obstacles.first { $0.id == 2 }?.fadeRemaining ?? 0 > 0)
    // Red confetti (jaleo-pop emoji) blooms at the meeting point.
    #expect(!gameState.jaleoPops.isEmpty)
  }

  @Test func cortejoFizzlesGracefullyWithFewerThanTwoObstacles() {
    let gameState = configured()
    let level = GameState.levelCount - 1
    let surface = gameState.platforms[level].surfaceY - GameState.obstacleSize / 2
    gameState.obstacles = [
      Obstacle(id: 1, x: 200, y: surface, velocityX: 40, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0)
    ]
    gameState.collectPowerUp(.cortejo)
    // The lone obstacle is possessed but has no quarry — after its vibrate it despawns.
    gameState.obstacles.indices.forEach { gameState.obstacles[$0].vibrateRemaining = 0.001 }
    gameState.updateCortejo(dt: 1.0 / 60.0)   // vibrate → chaser
    gameState.updateCortejo(dt: 1.0 / 60.0)   // chaser with no target → fizzle
    #expect(gameState.obstacles.isEmpty)
  }

  private func twoObstacles(_ gameState: GameState) -> [Obstacle] {
    let level = GameState.levelCount - 1
    let surface = gameState.platforms[level].surfaceY - GameState.obstacleSize / 2
    return [
      Obstacle(id: 1, x: 120, y: surface, velocityX: 40, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0),
      Obstacle(id: 2, x: 300, y: surface, velocityX: -40, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0)
    ]
  }

  @Test func cortejoPickupGrantsThreeChargesSpendingOneWhenIdle() {
    let gameState = configured()
    gameState.obstacles = twoObstacles(gameState)
    gameState.collectPowerUp(.cortejo)
    // Three granted, one spent immediately (the field was idle) → two banked for later jumps.
    #expect(gameState.cortejoCharges == 2)
    #expect(gameState.obstacles.contains { $0.vibrateRemaining > 0 })   // a possession started
  }

  @Test func cortejoJumpSpendsAChargeOnlyWhenNoChaseIsActive() {
    let gameState = configured()
    let level = GameState.levelCount - 1
    let surface = gameState.platforms[level].surfaceY - GameState.obstacleSize / 2
    gameState.cortejoCharges = 1
    // A chase in flight → a jump must NOT spend the charge (the chase time is the cooldown).
    gameState.obstacles = [
      Obstacle(id: 9, x: 200, y: surface, velocityX: 0, velocityY: 0, falling: false, level: level, emoji: "⚽", rotation: 0, isChaser: true)
    ]
    gameState.playerGrounded = true
    gameState.playerClimbing = false
    gameState.jump()
    #expect(gameState.cortejoCharges == 1)   // debounced by the active chase

    // Field idle again with targetable obstacles → the next jump spends the charge.
    gameState.obstacles = twoObstacles(gameState)
    gameState.playerGrounded = true
    gameState.playerClimbing = false
    gameState.jump()
    #expect(gameState.cortejoCharges == 0)
    #expect(gameState.obstacles.contains { $0.vibrateRemaining > 0 })   // re-possession started
  }

  @Test func cortejoSecondPickupBanksChargesOntoTheRemainder() {
    let gameState = configured()
    gameState.obstacles = twoObstacles(gameState)
    gameState.collectPowerUp(.cortejo)     // +3, fires one (idle) → 2 left, chase now active
    #expect(gameState.cortejoCharges == 2)
    #expect(gameState.isCortejoActive)
    // A second mushroom mid-chase banks its 3 onto the remaining 2 (debounced — no immediate fire).
    gameState.collectPowerUp(.cortejo)
    #expect(gameState.cortejoCharges == 5)
  }

  @Test func cortejoChargesPersistAcrossAStageSummit() {
    let gameState = configured()
    gameState.summitCount = 1
    gameState.cortejoCharges = 2
    // Drive a real summit (escape beat → next stage rebuild), as `escapeCompletesIntoTheNextStage`.
    gameState.enterEscape()
    var safety = 0
    while gameState.phase == .escape && safety < 1000 {
      safety += 1
      gameState.updateEscape(dt: 1.0 / 60.0)
    }
    #expect(gameState.stage == 2)
    #expect(gameState.cortejoCharges == 2)   // banked charges survive a summit (death clears them)
  }

  // MARK: The carried cape and its jump turn

  /// Turn the cape until it settles (0.25 s at `capeRotationRate`; a generous 20 frames).
  private func settleCape(_ gameState: GameState) {
    for _ in 0..<20 { gameState.updateCapeRotation(dt: 1.0 / 60.0) }
  }

  @Test func aCapedJumpTurnsTheCapeAQuarterTurnAndUnwindsOnLanding() {
    let gameState = configured()
    gameState.capedRemaining = GameState.capeDuration
    gameState.playerFacing = 1
    gameState.jump()
    #expect(gameState.capeRotationDirection == 1)   // facing right → clockwise
    settleCape(gameState)
    #expect(gameState.capeRotation == GameState.capeJumpRotation)
    // Landing unwinds it back to the standard orientation.
    gameState.playerGrounded = true
    settleCape(gameState)
    #expect(gameState.capeRotation == 0)
    #expect(gameState.capeRotationDirection == 0)
  }

  @Test func aCapedJumpFacingLeftTurnsTheOtherWay() {
    let gameState = configured()
    gameState.capedRemaining = GameState.capeDuration
    gameState.playerFacing = -1
    gameState.jump()
    #expect(gameState.capeRotationDirection == -1)   // facing left → counter-clockwise
    settleCape(gameState)
    #expect(gameState.capeRotation == -GameState.capeJumpRotation)
  }

  @Test func anUncapedJumpLeavesTheCapeAlone() {
    let gameState = configured()
    gameState.capedRemaining = 0
    gameState.jump()
    settleCape(gameState)
    #expect(gameState.capeRotationDirection == 0)
    #expect(gameState.capeRotation == 0)
  }

  @Test func collectingASecondCapeResetsTheRotationToStandard() {
    let gameState = configured()
    gameState.capedRemaining = GameState.capeDuration
    gameState.jump()
    settleCape(gameState)
    #expect(gameState.capeRotation == GameState.capeJumpRotation)
    // A second cape arrives in its standard orientation, cancelling the turn in progress.
    gameState.collectPowerUp(.cape)
    #expect(gameState.capeRotation == 0)
    #expect(gameState.capeRotationDirection == 0)
    // The NEXT jump turns it again as normal.
    gameState.playerGrounded = true
    gameState.jump()
    settleCape(gameState)
    #expect(gameState.capeRotation == GameState.capeJumpRotation)
  }

  @Test func theCarriedCapeFillsInOnlyWhereTheSpriteIsCapeless() {
    let gameState = configured()
    gameState.capedRemaining = GameState.capeDuration
    // Standing/walking: the muleta is baked into the sprite, so no separate cape.
    gameState.playerAction = .cape
    #expect(!gameState.isCarriedCapeVisible)
    gameState.playerAction = .capeWalk
    #expect(!gameState.isCarriedCapeVisible)
    // Airborne and climbing render capeless, so the carried cape shows there.
    gameState.playerAction = .jump
    #expect(gameState.isCarriedCapeVisible)
    gameState.playerAction = .climb
    #expect(gameState.isCarriedCapeVisible)
    // …and never without the power-up.
    gameState.capedRemaining = 0
    #expect(!gameState.isCarriedCapeVisible)
  }

  // MARK: Speed ⚡ — the bull quickens too

  @Test func speedPickupDoublesBullPacingButNotItsAnimation() {
    func paceDelta(speed: Double) -> CGFloat {
      let gameState = configured()
      gameState.speedRemaining = speed
      let x0 = gameState.bullX
      gameState.updateBull(dt: 1.0 / 60.0)
      return gameState.bullX - x0
    }
    let base = paceDelta(speed: 0)
    let fast = paceDelta(speed: GameState.speedDuration)
    #expect(base > 0)
    #expect(abs(fast - base * GameState.speedFactor) < 0.001)

    // The flipbook is on the fixed `fps` clock, so the walk cycle itself is untouched.
    let plain = configured()
    let quick = configured()
    quick.speedRemaining = GameState.speedDuration
    plain.advanceAnimations(dt: 1.0 / 60.0)
    quick.advanceAnimations(dt: 1.0 / 60.0)
    #expect(plain.bullPhase == quick.bullPhase)
  }

  // MARK: La Serenata — the strummed jump

  @Test func aJumpDuringLaSerenataSendsANoteToTheBull() {
    let gameState = configured()
    gameState.serenataRemaining = GameState.serenataDuration
    gameState.jump()
    #expect(gameState.serenataNotes.count == 1)
    #expect(gameState.serenataNotes[0].x == gameState.bullX)
    // Half a glyph above his center, so it sounds over him rather than out of him.
    #expect(gameState.serenataNotes[0].y == gameState.bullY - GameState.serenataNoteLift)

    // Without the power-up a jump sends nothing.
    let silent = configured()
    silent.jump()
    #expect(silent.serenataNotes.isEmpty)
  }

  @Test func aSerenataNoteRidesTheBullThenBurstsYellowAndBlue() {
    let gameState = configured()
    gameState.serenataRemaining = GameState.serenataDuration
    gameState.jump()
    // The bull dances on; the note tracks him.
    gameState.bullX += 50
    gameState.bullY -= 10
    gameState.updateSerenataNotes(dt: 1.0 / 60.0)
    #expect(gameState.serenataNotes[0].x == gameState.bullX)
    #expect(gameState.serenataNotes[0].y == gameState.bullY - GameState.serenataNoteLift)
    #expect(gameState.hitParticles.isEmpty)   // still ringing

    // A second in, it bursts in the two-color fanfare.
    gameState.serenataNotes[0].remaining = 0.001
    gameState.updateSerenataNotes(dt: 1.0 / 60.0)
    #expect(gameState.serenataNotes.isEmpty)
    #expect(gameState.hitParticles.contains { $0.tint == .yellow })
    #expect(gameState.hitParticles.contains { $0.tint == .blue })
  }

  @Test func anObstacleSmashStaysAllYellow() {
    let gameState = configured()
    gameState.spawnHitParticles(x: 100, y: 100)
    #expect(!gameState.hitParticles.isEmpty)
    #expect(gameState.hitParticles.allSatisfy { $0.tint == .yellow })
  }

  // MARK: El Cortejo — the mushroom thrown at the possessed obstacle

  @Test func aCortejoPossessionThrowsAMushroomAtTheClaimedObstacle() {
    let gameState = configured()
    gameState.obstacles = twoObstacles(gameState)
    gameState.collectPowerUp(.cortejo)
    let possessed = gameState.obstacles.first { $0.vibrateRemaining > 0 }
    #expect(gameState.cortejoMushrooms.count == 1)
    #expect(gameState.cortejoMushrooms[0].targetID == possessed?.id)
    // It leaves from the dancer, as her hearts do.
    #expect(gameState.cortejoMushrooms[0].x == gameState.playerX)
    #expect(gameState.cortejoMushrooms[0].y == gameState.playerY)
  }

  @Test func aCortejoMushroomClosesOnItsTargetThenRetiresHarmlessly() {
    let gameState = configured()
    gameState.obstacles = twoObstacles(gameState)
    let target = gameState.obstacles[0]
    gameState.cortejoMushrooms = [
      CortejoMushroom(id: 0, x: target.x - 60, y: target.y, targetID: target.id, lifeRemaining: GameState.cortejoMushroomLife)
    ]
    gameState.updateCortejoMushrooms(dt: 1.0 / 60.0)
    #expect(gameState.cortejoMushrooms.count == 1)
    #expect(gameState.cortejoMushrooms[0].x > target.x - 60)   // closing on it

    // On arrival it retires — and, being cosmetic, harms nothing.
    gameState.cortejoMushrooms[0].x = target.x
    gameState.cortejoMushrooms[0].y = target.y
    gameState.updateCortejoMushrooms(dt: 1.0 / 60.0)
    #expect(gameState.cortejoMushrooms.isEmpty)
    #expect(gameState.obstacles.count == 2)
    #expect(gameState.obstacles.allSatisfy { $0.fadeRemaining == 0 })
  }

  // MARK: El Flechazo — the matador's hearts

  @Test func firingAMissileBloomsAHeartBesideTheMatador() {
    let gameState = configured()
    gameState.flechazoRemaining = GameState.flechazoDuration
    gameState.flechazoCooldown = 0
    gameState.obstacles = [fullObstacleMidField(gameState)]
    gameState.jump()
    #expect(gameState.matadorHearts.count == 1)
    #expect(gameState.matadorHearts[0].missileID == gameState.heartMissiles[0].id)
    // It grows in from nothing over `matadorHeartGrow`…
    #expect(gameState.matadorHeartOpacity(gameState.matadorHearts[0]) == 0)
    gameState.updateMatadorHearts(dt: GameState.matadorHeartGrow)
    #expect(gameState.matadorHeartOpacity(gameState.matadorHearts[0]) == 1)
    // …to the matador's right, at his sprite's vertical center (above the box center).
    let point = gameState.matadorHeartPosition(slot: 0)
    #expect(point.x > gameState.bullfighterX)
    #expect(point.y < gameState.bullfighterY)
  }

  @Test func aMissileStrikePopsTheMatadorHeartYellowAndBlue() {
    let gameState = configured()
    var target = fullObstacleMidField(gameState)
    target.velocityX = 0
    gameState.obstacles = [target]
    gameState.heartMissiles = [
      HeartMissile(id: 0, x: target.x, y: target.y, velocityX: 0, velocityY: 0, targetID: target.id, lifeRemaining: GameState.heartMissileLife)
    ]
    gameState.matadorHearts = [MatadorHeart(id: 0, missileID: 0)]
    gameState.updateHeartMissiles(dt: 1.0 / 60.0)
    #expect(gameState.matadorHearts.isEmpty)                        // popped by the strike
    // The obstacle's own smash burst is all yellow, so a blue dot can only be the fanfare.
    #expect(gameState.hitParticles.contains { $0.tint == .blue })
  }

  @Test func aMissileThatNeverStrikesRetiresItsHeartQuietly() {
    let gameState = configured()
    gameState.matadorHearts = [MatadorHeart(id: 0, missileID: 7)]   // its missile is gone
    gameState.updateMatadorHearts(dt: 1.0 / 60.0)
    #expect(gameState.matadorHearts.first?.fadeRemaining != nil)    // fading, not popping
    #expect(gameState.hitParticles.isEmpty)                         // no burst
    gameState.updateMatadorHearts(dt: GameState.matadorHeartFade)
    #expect(gameState.matadorHearts.isEmpty)
  }
}
