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
//    • encierro — a stampede of 🐂 chargers runs across the girders (see
//                 `updateChargers` / `resolveChargerCollisions`).
//    • apagon   — the lights cut to a near-black overlay with a soft spotlight
//                 tracking the dancer; `updateApagon` drives the `apagonDim` envelope
//                 and `GameView` renders the mask.
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
    // Refresh the apagón spotlight from the (just-updated) window state, so the darkness
    // tracks `mechanicRemaining` and a natural/cancelled end leaves it at 0.
    updateApagon()
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
      // El Encierro: a stampede of 🐂 chargers runs across the girders (updateChargers
      // spawns them while this window is open, then lets stragglers finish crossing).
      spawnBullSpeech(L.Game.encierroAnnouncement)
      Current.soundPlayer.play(.stampede, shouldDebounce: false)
      chargerSpawnTimer = 0                // the first charger enters on the next frame
      encierroCoveredPlayerLevel = false   // guarantee one down the player's girder
    case .apagon:
      // El Apagón: the lights cut. `updateApagon` ramps `apagonDim` up from 0 over
      // this window (GameView renders the spotlight mask); `endMechanic` pops the
      // lights back on.
      spawnBullSpeech(L.Game.apagonAnnouncement)
      Current.soundPlayer.play(.lightsOut, shouldDebounce: false)
    }
  }

  /// Close the active window cleanly (re-integrate zombie obstacles onto the girders)
  /// and re-arm the countdown so the mechanic re-fires later in the stage. A natural
  /// apagón end pops the lights back on (`Sound.pop`); a *cancel* (escape/boss/respawn)
  /// does not, so a between-stage or death transition isn't punctuated by the pop.
  func endMechanic() {
    let ending = activeMechanic
    finishActiveMechanic()
    if ending == .apagon {
      Current.soundPlayer.play(.pop, shouldDebounce: false)
    }
    armMechanicCountdown(firstDelay: false)
  }

  /// Cancel the active window WITHOUT re-arming — used by escape, boss entry, and
  /// respawn (each rebuilds or re-arms the scheduler on its own). Unlike a natural
  /// window end (`endMechanic`), a cancel also clears any 🐂 chargers still crossing:
  /// they belong to the interrupted climb, not the next stage / respawn.
  func cancelActiveMechanic() {
    finishActiveMechanic()
    chargers.removeAll()
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
    apagonDim = 0   // the lights come back on (updateApagon's guard then leaves it 0)
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

  // MARK: El Encierro (the 🐂 charger stampede)

  /// One frame of the charger stampede: spawn a fresh charger on its interval while the
  /// encierro window is open (stragglers from a just-closed window keep crossing —
  /// spawning stops but movement doesn't), then run every charger straight across its
  /// girder at 2× the stage's obstacle speed, despawning any that clear a screen edge.
  func updateChargers(dt: CGFloat) {
    if activeMechanic == .encierro {
      chargerSpawnTimer -= Double(dt)
      if chargerSpawnTimer <= 0 {
        spawnCharger()
        chargerSpawnTimer = Self.chargerSpawnInterval
      }
    }

    guard !chargers.isEmpty else { return }
    let speed = obstacleSpeed * Self.chargerSpeedFactor
    for i in chargers.indices {
      chargers[i].x += chargers[i].direction * speed * dt
    }
    let margin = Self.chargerSize
    chargers.removeAll { $0.x < -margin || $0.x > screenSize.width + margin }
  }

  /// Spawn one charger for the open encierro window. It targets the player's girder the
  /// first time (so the stampede always threatens the player at least once), then random
  /// girders (levels 0…top−1, never the bull's), entering from the screen edge opposite
  /// its travel and snorting as it charges.
  private func spawnCharger() {
    let top = Self.levelCount - 1
    let level: Int
    if !encierroCoveredPlayerLevel && (0..<top).contains(playerLevel) {
      level = playerLevel
      encierroCoveredPlayerLevel = true
    } else {
      level = Int.random(in: 0..<top, using: &bossRNG)
    }
    let direction: CGFloat = Bool.random(using: &bossRNG) ? 1 : -1
    let y = platforms[level].surfaceY - Self.chargerSize / 2
    // Enter from the edge opposite the travel direction (rightward → from the left).
    let startX = direction > 0 ? -Self.chargerSize / 2 : screenSize.width + Self.chargerSize / 2
    chargers.append(Charger(id: chargerCounter, x: startX, y: y, level: level, direction: direction))
    chargerCounter += 1
    Current.soundPlayer.play(.snort, shouldDebounce: true, volume: 0.3)
  }

  /// Charger↔player collisions (called from `resolveCollisions`): the obstacle rules
  /// with a tight `chargerHitSize` box — a cape smashes the 🐂 (chomp), otherwise it
  /// costs a pip (soccer-kick) unless the damage cooldown is still up, and a lethal hit
  /// soft-respawns. Returns `true` iff it respawned (so the caller can bail early).
  func resolveChargerCollisions() -> Bool {
    for i in chargers.indices {
      let c = chargers[i]
      guard rectsIntersect(
        playerX, playerY, Self.playerWidth, Self.playerHeight,
        c.x, c.y, Self.chargerHitSize, Self.chargerHitSize
      ) else { continue }

      if isCaped {
        chargers[i].despawn = true                             // caped: smash the charger
        Current.soundPlayer.play(.chomp, shouldDebounce: true)
      } else if damageCooldown <= 0 {
        health -= 1
        damageCooldown = Self.damageCooldownDuration
        chargers[i].despawn = true
        if health <= 0 {
          Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: false)
          respawn()
          return true
        }
        Current.soundPlayer.play(.soccerKick, shouldDebounce: false)
      }
    }
    chargers.removeAll { $0.despawn }
    return false
  }

  // MARK: El Apagón (the lights-out spotlight)

  /// Drive the blackout envelope from the active window's remaining time: the darkness
  /// (`apagonDim`, 0…1) fades in over `apagonFadeIn`, holds at full for the middle of
  /// the window, then fades back out over the last `apagonFadeOut`. It's purely a
  /// function of `mechanicRemaining` — no per-frame randomness, no `dt` accumulation —
  /// so it's deterministic and self-correcting. When no apagón is active the guard
  /// leaves `apagonDim` alone (kept at 0 by `finishActiveMechanic`). Called from
  /// `updateMechanicScheduler` after the window state has been ticked.
  func updateApagon() {
    guard activeMechanic == .apagon else { return }
    let elapsed = Self.apagonDuration - mechanicRemaining
    if elapsed < Self.apagonFadeIn {
      apagonDim = CGFloat(max(0, elapsed) / Self.apagonFadeIn)
    } else if mechanicRemaining < Self.apagonFadeOut {
      apagonDim = CGFloat(max(0, mechanicRemaining) / Self.apagonFadeOut)
    } else {
      apagonDim = 1
    }
  }
}
