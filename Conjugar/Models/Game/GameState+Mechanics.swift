//
//  GameState+Mechanics.swift
//  Conjugar
//
//  La Subida — the challenge-mechanic framework (see prompts/game_la_subida.md,
//  Phase 3) and the first mechanic, the **zombie attack**. Each stage is assigned one
//  mechanic, drawn from a shuffle bag so no kind repeats until all three have appeared
//  (the same idiom as the power-up bag). A scheduler fires the mechanic once after a
//  random first delay, then re-fires periodically through the rest of the stage:
//
//    • zombie   — for `zombieDuration` seconds every on-screen obstacle slows to
//                 `zombieSpeedFactor`× and homes toward the player (keeping its own
//                 emoji — no 🧟 swap, per Josh); when the window ends the obstacles are
//                 re-integrated onto the nearest girder below them via `relevel`.
//    • encierro — announces only for now; Phase 4 spawns the 🐂 charger stampede.
//    • apagon   — announces only for now; Phase 5 drives the lights-out spotlight.
//
//  The scheduler ticks only in `.climb` (from `update`); escape, boss entry, and
//  respawn all cancel an active window (`cancelActiveMechanic`).
//

import CoreGraphics

extension GameState {
  // MARK: Per-stage assignment (shuffle bag)

  /// Draw the next stage's mechanic: honor the `CONJUGAR_GAME_MECHANIC` override if
  /// set, otherwise pull from the shuffle bag (refill + reshuffle through `bossRNG`
  /// when empty), so a mechanic never repeats until all three have appeared.
  func drawStageMechanic() -> ChallengeMechanic {
    if let forced = Self.debugForcedMechanic { return forced }
    if mechanicBag.isEmpty {
      mechanicBag = ChallengeMechanic.allCases.shuffled(using: &bossRNG)
    }
    return mechanicBag.removeLast()
  }

  /// Draw and store this stage's mechanic, then arm its first-appearance countdown.
  /// Called from `reset()` (stage 1) and `advanceToNextStage()` (every later stage).
  func assignStageMechanic() {
    assignedMechanic = drawStageMechanic()
    armMechanicCountdown(firstDelay: true)
  }

  /// Set `mechanicCountdown` for the next firing: a random point in `mechanicFirstDelay`
  /// for a stage's first appearance, otherwise the fixed `mechanicRepeatDelay`. When a
  /// mechanic is forced for verification (`CONJUGAR_GAME_MECHANIC`) both are shortened
  /// to ~2 s so it fires almost at once and loops quickly.
  func armMechanicCountdown(firstDelay: Bool) {
    if Self.debugForcedMechanic != nil {
      mechanicCountdown = 2.0
    } else if firstDelay {
      mechanicCountdown = Double.random(in: Self.mechanicFirstDelay, using: &bossRNG)
    } else {
      mechanicCountdown = Self.mechanicRepeatDelay
    }
  }

  // MARK: Scheduler

  /// One frame of the mechanic scheduler (ticks only in `.climb`). While a mechanic is
  /// active its window winds down (`mechanicRemaining`); otherwise the countdown to the
  /// next firing does (`mechanicCountdown`).
  func updateMechanicScheduler(dt: CGFloat) {
    if activeMechanic != nil {
      mechanicRemaining -= Double(dt)
      if mechanicRemaining <= 0 {
        endMechanic()
      }
    } else {
      mechanicCountdown -= Double(dt)
      if mechanicCountdown <= 0 {
        startMechanic()
      }
    }
  }

  /// Fire this stage's mechanic: open its window and play its announcement (a bull
  /// "speech" jaleo + the mechanic's SFX). Encierro/apagón announce only until their
  /// phases (4/5) wire the behavior; the zombie window is live here.
  func startMechanic() {
    activeMechanic = assignedMechanic
    mechanicRemaining = mechanicDuration(assignedMechanic)
    switch assignedMechanic {
    case .zombie:
      spawnBullSpeech(L.Game.zombieAnnouncement)
      Current.soundPlayer.play(.zombieGroan, shouldDebounce: false)
    case .encierro:
      // Announce only for now — Phase 4 spawns the 🐂 charger stampede in this window.
      spawnBullSpeech(L.Game.encierroAnnouncement)
      Current.soundPlayer.play(.stampede, shouldDebounce: false)
    case .apagon:
      // Announce only for now — Phase 5 drives the lights-out spotlight in this window.
      spawnBullSpeech(L.Game.apagonAnnouncement)
      Current.soundPlayer.play(.lightsOut, shouldDebounce: false)
    }
  }

  /// Close the active window cleanly (re-integrate zombie obstacles onto the girders)
  /// and re-arm the countdown so the mechanic re-fires later in the stage.
  func endMechanic() {
    finishActiveMechanic()
    armMechanicCountdown(firstDelay: false)
  }

  /// Cancel the active window WITHOUT re-arming — used by escape, boss entry, and
  /// respawn (each rebuilds or re-arms the scheduler on its own).
  func cancelActiveMechanic() {
    finishActiveMechanic()
  }

  /// Shared teardown: undo a mechanic's live effects and clear the active state. The
  /// zombie's homing obstacles are re-integrated onto the nearest girder below them
  /// (callers that also clear `obstacles` make this a cheap no-op).
  private func finishActiveMechanic() {
    if activeMechanic == .zombie {
      reintegrateZombieObstacles()
    }
    activeMechanic = nil
    mechanicRemaining = 0
  }

  /// The window length for each mechanic.
  func mechanicDuration(_ mechanic: ChallengeMechanic) -> Double {
    switch mechanic {
    case .zombie: return Self.zombieDuration
    case .encierro: return Self.encierroDuration
    case .apagon: return Self.apagonDuration
    }
  }

  // MARK: Announcements

  /// The bull "speaks" a mechanic announcement — a big jaleo popping just below the
  /// bull and rising gently (decision 9: "Note how speech is animated in the boss
  /// fight"). Localization follows the title-card policy: the zombie line is narrative
  /// and localizes en/es, while "¡El encierro!"/"¡Apagón!" stay Spanish in both.
  func spawnBullSpeech(_ text: String) {
    spawnJaleo(text, x: bullX, y: bullY + Self.bullSize, size: 30, riseRate: Self.jaleoDriftRise, ttl: 2.0)
  }

  // MARK: Zombie attack

  /// While the zombie window is open, each obstacle abandons the roll/fall state
  /// machine and drifts straight toward the player at half speed. `.spin` sets keep
  /// their cosmetic tumble; `.face` sets turn to face the drift.
  func updateZombieObstacles(dt: CGFloat) {
    let speed = obstacleSpeed * Self.zombieSpeedFactor
    for i in obstacles.indices {
      var f = obstacles[i]
      let dx = playerX - f.x
      let dy = playerY - f.y
      let dist = max(1, (dx * dx + dy * dy).squareRoot())
      let velocityX = dx / dist * speed
      let velocityY = dy / dist * speed
      f.x += velocityX * dt
      f.y += velocityY * dt
      f.velocityX = velocityX
      f.velocityY = velocityY
      if f.style == .spin {
        f.rotation += Double(velocityX) * Double(dt) * 0.6
      }
      if abs(velocityX) > 0.001 {
        f.facing = velocityX > 0 ? 1 : -1
      }
      obstacles[i] = f
    }
  }

  /// When the zombie window ends, drop every homing obstacle back onto the girders:
  /// `relevel` sends it falling toward the nearest girder below its feet (or despawns
  /// it if it drifted below the bottom girder), so the ordinary roll/fall pipeline
  /// takes over again.
  func reintegrateZombieObstacles() {
    for i in obstacles.indices {
      relevel(&obstacles[i])
    }
    obstacles.removeAll { $0.despawn }
  }

  /// Re-seat one obstacle onto the nearest girder at/below its feet: set `level` one
  /// above that girder and `falling = true` (velocityY zeroed) so the landing code in
  /// `updateObstacles` snaps it down and re-rolls its horizontal speed/facing. An
  /// obstacle that drifted below the bottom girder is marked to despawn.
  func relevel(_ obstacle: inout Obstacle) {
    let feet = obstacle.y + Self.obstacleSize / 2
    guard let target = platforms
      .filter({ $0.surfaceY >= feet })
      .min(by: { $0.surfaceY < $1.surfaceY }) else {
      obstacle.despawn = true
      return
    }
    obstacle.level = target.level + 1
    obstacle.falling = true
    obstacle.velocityY = 0
  }
}
