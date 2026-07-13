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

  private func flagOnPlayer(_ gameState: GameState) -> Flag {
    Flag(
      id: 999, x: gameState.playerX, y: gameState.playerY,
      velocityX: 0, velocityY: 0, falling: false, level: 0,
      emoji: "🏳️", rotation: 0
    )
  }

  @Test func flagHitCostsOnePipAndConsumesTheFlag() {
    let gameState = configured()
    let start = gameState.health
    gameState.damageCooldown = 0
    gameState.flags.append(flagOnPlayer(gameState))
    gameState.resolveCollisions()
    #expect(gameState.health == start - 1)
    #expect(gameState.flags.isEmpty)
  }

  @Test func capedPlayerSmashesFlagWithoutDamage() {
    let gameState = configured()
    let start = gameState.health
    gameState.capedRemaining = 5
    gameState.flags.append(flagOnPlayer(gameState))
    gameState.resolveCollisions()
    #expect(gameState.health == start)
    #expect(gameState.flags.isEmpty)
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

  @Test func jumpClearingAFlagCostsNoHealth() {
    let gameState = configured()
    gameState.damageCooldown = 0
    let start = gameState.health
    // Flag horizontally aligned but a jump-arc's clearance above the honest flag
    // hitbox — a gap the old full-size box would have wrongly counted as a hit.
    let clearance = (GameState.playerHeight + GameState.flagHitSize) / 2 + 2
    let flag = Flag(
      id: 1, x: gameState.playerX, y: gameState.playerY + clearance,
      velocityX: 0, velocityY: 0, falling: false, level: 0, emoji: "🏳️", rotation: 0
    )
    gameState.flags.append(flag)
    gameState.resolveCollisions()
    #expect(gameState.health == start)    // cleared — no damage
    #expect(gameState.flags.count == 1)   // flag untouched
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

  @Test func reachingBullTriggersTheBossFight() {
    // The summit seam changed with La Llamada: the gated summit (summitsToBoss = 1
    // for now) enters the boss intro instead of resetting the level. The boss
    // machinery itself is covered in GameBossTests.
    let gameState = configured()
    gameState.playerX = gameState.bullX
    gameState.playerY = gameState.bullY
    gameState.flags.append(flagOnPlayer(gameState))
    gameState.checkReachedBull()
    #expect(gameState.summitCount == 1)
    #expect(gameState.phase == .bossIntro)
    #expect(gameState.flags.isEmpty)                   // field cleared for the stage
  }
}
