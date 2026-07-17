//
//  GameState+Physics.swift
//  Conjugar
//
//  Player physics: horizontal move from intent booleans, gravity + platform snap,
//  ladder climbing, jump impulse, and the "reached the bull" check.
//

import CoreGraphics

extension GameState {
  /// One frame of player motion.
  func updatePlayer(dt: CGFloat) {
    // Facing follows the last horizontal intent.
    if movingRight && !movingLeft {
      playerFacing = 1
    } else if movingLeft && !movingRight {
      playerFacing = -1
    }

    if playerClimbing {
      updateClimb(dt: dt)
      return
    }

    // Grab a ladder if standing at one and pressing up/down.
    if (movingUp || movingDown) && tryEnterLadder() {
      return
    }

    // Horizontal move from intent (both pressed cancels), clamped to the beam. The
    // speed power-up (⚡) doubles the walk rate via `speedFactorNow`.
    let dir: CGFloat = (movingRight ? 1 : 0) - (movingLeft ? 1 : 0)
    playerX += dir * Self.playerSpeed * speedFactorNow * dt
    let halfW = Self.playerWidth / 2
    playerX = min(max(playerX, Self.sideMargin + halfW), screenSize.width - Self.sideMargin - halfW)

    // Gravity + integrate vertical position.
    let prevFeet = playerY + Self.playerHeight / 2
    playerVelocityY += Self.gravity * dt
    playerY += playerVelocityY * dt
    let newFeet = playerY + Self.playerHeight / 2

    // Platform snap: when falling and the feet cross a beam's top face while
    // horizontally over it, land on that beam. During El Terremoto a FINISHED gap
    // (fully faded) at the landing x is a true hole — skip the landing so she falls
    // through to the level below (a still-fading gap is solid and lands normally).
    playerGrounded = false
    if playerVelocityY >= 0 {
      for platform in platforms {
        let top = platform.surfaceY
        let overlapsX = playerX >= platform.rect.minX - halfW && playerX <= platform.rect.maxX + halfW
        if overlapsX && prevFeet <= top + 1 && newFeet >= top {
          if hasFinishedGap(level: platform.level, x: playerX) { continue }   // fall through the hole
          playerY = top - Self.playerHeight / 2
          playerVelocityY = 0
          playerGrounded = true
          playerLevel = platform.level
          break
        }
      }
    }

    // Fell through a hole in the bottom girder: dock a heart + reposition (terremoto only —
    // the player is never below the bottom platform otherwise).
    if !platformGaps.isEmpty && !playerGrounded && newFeet > platforms[0].surfaceY + 4 {
      fellThroughFloor()
    }
  }

  /// Jump impulse — the one control that's a press, not a held intent.
  func jump() {
    guard playerGrounded, !playerClimbing else { return }
    playerVelocityY = -Self.jumpImpulse
    playerGrounded = false
    Current.soundPlayer.play(.pop, shouldDebounce: false)
    // El Flechazo: a qualifying jump fires a homing ❤️ missile (no-op unless armed).
    fireHeartMissileIfArmed()
    // El Cortejo: a jump spends a banked charge to re-possess, once the prior chase has
    // finished (no-op while a chase is in flight or with no charges).
    maybeTriggerCortejo()
  }

  /// If the player is standing at a ladder and pressing toward it, enter climbing.
  private func tryEnterLadder() -> Bool {
    guard playerGrounded else { return false }
    for ladder in ladders where abs(playerX - ladder.x) < Self.climbTolerance {
      let goingUp = movingUp && ladder.lowerLevel == playerLevel
      let goingDown = movingDown && ladder.upperLevel == playerLevel
      if goingUp || goingDown {
        playerClimbing = true
        climbingLadder = ladder.id
        playerX = ladder.x
        playerVelocityY = 0
        playerGrounded = false
        return true
      }
    }
    return false
  }

  /// One frame of ladder climbing. Exits (and lands) at either end.
  private func updateClimb(dt: CGFloat) {
    guard let lid = climbingLadder, let ladder = ladders.first(where: { $0.id == lid }) else {
      playerClimbing = false
      return
    }

    let dir: CGFloat = (movingDown ? 1 : 0) - (movingUp ? 1 : 0)   // +y is down
    playerY += dir * Self.climbSpeed * speedFactorNow * dt         // ⚡ doubles the climb too

    // A quiet, retriggered rung-tick while actually climbing. Debounced (~1/sec) and
    // low-volume so the per-frame call can't machine-gun the effect.
    if dir != 0 {
      Current.soundPlayer.play(.chirp, shouldDebounce: true, volume: 0.4)
    }

    let topCenter = ladder.topY - Self.playerHeight / 2       // player center at upper platform
    let bottomCenter = ladder.bottomY - Self.playerHeight / 2 // player center at lower platform

    if playerY <= topCenter {
      land(on: ladder.upperLevel, centerY: topCenter)
    } else if playerY >= bottomCenter {
      land(on: ladder.lowerLevel, centerY: bottomCenter)
    }
  }

  private func land(on level: Int, centerY: CGFloat) {
    playerY = centerY
    playerClimbing = false
    climbingLadder = nil
    playerGrounded = true
    playerLevel = level
    playerVelocityY = 0
  }

  /// Reaching the bull counts a summit. The 5th summit (`summitsToBoss`) begins the
  /// boss fight (La Llamada — GameState+BossFight.swift); summits 1–4 trigger the
  /// escape beat (`enterEscape` — GameState+Stages.swift), the bull fleeing upward
  /// with the matador before the next stage rebuilds.
  func checkReachedBull() {
    if rectsIntersect(
      playerX, playerY, Self.playerWidth, Self.playerHeight,
      bullX, bullY, Self.bullSize, Self.bullSize
    ) {
      summitCount += 1
      if summitCount >= Self.summitsToBoss {
        enterBossIntro()
      } else {
        enterEscape()
      }
    }
  }
}
