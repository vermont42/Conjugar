//
//  GameState+Flags.swift
//  Conjugar
//
//  The bull's behavior (pacing the top girder + throwing flag "barrels"), flag
//  descent/rolling down the platforms, and the flag↔player / cape-pickup collisions.
//

import CoreGraphics

extension GameState {
  /// One frame of bull AI: pace the top girder, and throw a flag on a timer.
  func updateBull(dt: CGFloat) {
    if bullThrowTimer > 0 { bullThrowTimer -= Double(dt) }

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

    flagSpawnTimer -= Double(dt)
    if flagSpawnTimer <= 0 {
      spawnFlag()
      Current.soundPlayer.play(.cow, shouldDebounce: false, volume: 0.15)   // the bull bellows as it throws (kept low)
      flagSpawnTimer = Self.flagSpawnInterval
      bullThrowTimer = Self.bullThrowDuration
    }
  }

  private func spawnFlag() {
    let top = Self.levelCount - 1
    let emoji = Self.flagEmojis[flagCounter % Self.flagEmojis.count]
    flags.append(
      Flag(
        id: flagCounter,
        x: bullX,
        y: platforms[top].surfaceY - Self.flagSize / 2,
        velocityX: Self.flagRollSpeed * rollDirection(top),
        velocityY: 0,
        falling: false,
        level: top,
        emoji: emoji,
        rotation: 0
      )
    )
    flagCounter += 1
  }

  /// Alternating roll direction per level, producing the DK barrel zig-zag.
  private func rollDirection(_ level: Int) -> CGFloat {
    level % 2 == 0 ? 1 : -1
  }

  /// The x at which a rolling flag falls off its girder toward the level below.
  private func dropX(_ level: Int) -> CGFloat {
    rollDirection(level) > 0 ? screenSize.width * 0.85 : screenSize.width * 0.15
  }

  /// Move every flag: descend + land, or roll + fall off at the drop point.
  func updateFlags(dt: CGFloat) {
    let half = Self.flagSize / 2
    for i in flags.indices {
      var f = flags[i]

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
            f.velocityX = Self.flagRollSpeed * rollDirection(target)
          }
        }
      } else {
        f.x += f.velocityX * dt
        f.rotation += Double(f.velocityX) * Double(dt) * 0.6
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

      flags[i] = f
    }

    flags.removeAll { $0.despawn || $0.y > screenSize.height + 120 }
  }

  /// Cape pickups and flag hits.
  func resolveCollisions() {
    // Cape pickups.
    for i in capes.indices where !capes[i].collected {
      if rectsIntersect(
        playerX, playerY, Self.playerWidth, Self.playerHeight,
        capes[i].x, capes[i].y, Self.capeSize, Self.capeSize
      ) {
        capes[i].collected = true
        capedRemaining = Self.capeDuration
        Current.soundPlayer.play(.shieldActivate, shouldDebounce: false)   // cape power-up
      }
    }

    // Flag hits.
    for i in flags.indices {
      let f = flags[i]
      guard rectsIntersect(
        playerX, playerY, Self.playerWidth, Self.playerHeight,
        f.x, f.y, Self.flagHitSize, Self.flagHitSize
      ) else { continue }

      if isCaped {
        flags[i].despawn = true     // caped: smash the flag
        Current.soundPlayer.play(.chomp, shouldDebounce: true)   // cape smash
      } else if damageCooldown <= 0 {
        health -= 1                 // otherwise: −25% health
        damageCooldown = Self.damageCooldownDuration
        flags[i].despawn = true
        if health <= 0 {
          Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: false)   // game over → reset
          reset()
          return
        }
        Current.soundPlayer.play(.soccerKick, shouldDebounce: false)   // took a hit
      }
    }

    flags.removeAll { $0.despawn }
  }
}
