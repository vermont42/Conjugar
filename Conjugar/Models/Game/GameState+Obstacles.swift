//
//  GameState+Obstacles.swift
//  Conjugar
//
//  The bull's behavior (pacing the top girder + throwing obstacle "barrels"),
//  obstacle descent/rolling down the platforms, and the obstacle↔player /
//  cape-pickup collisions. "Obstacles" are the per-stage thrown glyphs (flags,
//  animals, balls, vehicles, sky — see `GameState.stageObstacleEmojis`); the file
//  and its symbols were renamed from `Flag`/`updateFlags` when flags became one of
//  five sets (La Subida). The `CONJUGAR_GAME_DISABLE_FLAGS` env var keeps its name —
//  it's a documented external contract (see `debugFlagsDisabled`).
//

import CoreGraphics

extension GameState {
  /// One frame of bull AI: pace the top girder, and throw an obstacle on a timer.
  func updateBull(dt: CGFloat) {
    if bullThrowTimer > 0 { bullThrowTimer -= Double(dt) }

    // La Serenata: the bull stops pacing AND throwing and dances instead (obstacles
    // already in flight keep rolling — `updateObstacles` still runs). See
    // GameState+PowerUps.swift.
    if serenataRemaining > 0 {
      updateSerenataDance(dt: dt)
      return
    }

    // Pace left/right along the top platform, staying left of the bullfighter.
    let half = Self.bullSize / 2
    let minX = screenSize.width * 0.15 + half
    let maxX = screenSize.width * 0.6
    bullX += bullDirection * Self.bullPaceSpeed * dt
    if bullX <= minX {
      bullX = minX
      bullDirection = 1
    } else if bullX >= maxX {
      bullX = maxX
      bullDirection = -1
    }
    bullFacing = bullDirection

    if Self.debugFlagsDisabled { return }

    obstacleSpawnTimer -= Double(dt)
    if obstacleSpawnTimer <= 0 {
      spawnObstacle()
      Current.soundPlayer.play(.moo, shouldDebounce: false, volume: 0.15)   // the bull bellows as it throws (kept low)
      obstacleSpawnTimer = Self.obstacleSpawnInterval
      bullThrowTimer = Self.bullThrowDuration
    }
  }

  private func spawnObstacle() {
    let top = Self.levelCount - 1
    let emoji = stageEmojis[obstacleCounter % stageEmojis.count]
    let dir = rollDirection(top)
    obstacles.append(
      Obstacle(
        id: obstacleCounter,
        x: bullX,
        y: platforms[top].surfaceY - Self.obstacleSize / 2,
        velocityX: obstacleSpeed * dir,
        velocityY: 0,
        falling: false,
        level: top,
        emoji: emoji,
        rotation: 0,
        style: stageObstacleStyle,
        facing: dir
      )
    )
    obstacleCounter += 1
  }

  /// Alternating roll direction per level, producing the DK barrel zig-zag.
  private func rollDirection(_ level: Int) -> CGFloat {
    level % 2 == 0 ? 1 : -1
  }

  /// The x at which a rolling obstacle falls off its girder toward the level below.
  private func dropX(_ level: Int) -> CGFloat {
    rollDirection(level) > 0 ? screenSize.width * 0.85 : screenSize.width * 0.15
  }

  /// Move every obstacle: descend + land, or roll + fall off at the drop point.
  func updateObstacles(dt: CGFloat) {
    // Zombie attack: obstacles abandon the roll/fall state machine and home toward the
    // player at half speed (GameState+Mechanics.swift). `endMechanic` re-integrates
    // them onto the girders afterward.
    if activeMechanic == .zombie {
      updateZombieObstacles(dt: dt)
      return
    }

    let half = Self.obstacleSize / 2
    for i in obstacles.indices {
      var f = obstacles[i]

      if f.falling {
        f.velocityY += Self.gravity * dt
        let prevFeet = f.y + half
        f.y += f.velocityY * dt
        let newFeet = f.y + half
        let target = f.level - 1
        if target >= 0 {
          let top = platforms[target].surfaceY
          if prevFeet <= top + 1 && newFeet >= top {
            f.y = top - half
            f.velocityY = 0
            f.falling = false
            f.level = target
            f.velocityX = obstacleSpeed * rollDirection(target)
            f.facing = f.velocityX > 0 ? 1 : -1
          }
        }
      } else {
        f.x += f.velocityX * dt
        // Only `.spin` sets accumulate the barrel tumble; `.face`/`.upright` stay level.
        if f.style == .spin {
          f.rotation += Double(f.velocityX) * Double(dt) * 0.6
        }
        f.facing = f.velocityX > 0 ? 1 : -1
        let dx = dropX(f.level)
        let reachedDrop = f.velocityX > 0 ? f.x >= dx : f.x <= dx
        if reachedDrop {
          if f.level - 1 < 0 {
            f.despawn = true    // rolled off the bottom girder
          } else {
            f.falling = true
            f.velocityY = 0
          }
        }
      }

      obstacles[i] = f
    }

    obstacles.removeAll { $0.despawn || $0.y > screenSize.height + 120 }
  }

  /// Power-up pickups and obstacle hits.
  func resolveCollisions() {
    // Power-up pickups (this stage's drawn kind — cape / speed / serenata).
    for i in powerUps.indices where !powerUps[i].collected {
      if rectsIntersect(
        playerX, playerY, Self.playerWidth, Self.playerHeight,
        powerUps[i].x, powerUps[i].y, Self.capeSize, Self.capeSize
      ) {
        powerUps[i].collected = true
        collectPowerUp(powerUps[i].kind)
      }
    }

    // Obstacle hits.
    for i in obstacles.indices {
      let f = obstacles[i]
      guard rectsIntersect(
        playerX, playerY, Self.playerWidth, Self.playerHeight,
        f.x, f.y, Self.obstacleHitSize, Self.obstacleHitSize
      ) else { continue }

      if isCaped {
        obstacles[i].despawn = true     // caped: smash the obstacle
        Current.soundPlayer.play(.chomp, shouldDebounce: true)   // cape smash
      } else if damageCooldown <= 0 {
        health -= 1                 // otherwise: −25% health
        damageCooldown = Self.damageCooldownDuration
        obstacles[i].despawn = true
        if health <= 0 {
          Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: false)   // 0 health → soft respawn
          respawn()
          return
        }
        Current.soundPlayer.play(.soccerKick, shouldDebounce: false)   // took a hit
      }
    }

    obstacles.removeAll { $0.despawn }
  }
}
