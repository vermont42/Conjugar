//
//  GameState+PowerUps.swift
//  Conjugar
//

import CoreGraphics

extension GameState {
  // MARK: Shared blink envelope

  /// Whether a power-up whose timer is `remaining` should render this frame: solid
  /// until its final `capeBlinkDuration` seconds, then flashing ~5×/s to warn of
  /// imminent expiry, then gone. Shared by the cape overlay (`isCapeVisible`) and the
  /// speed badge (`isSpeedBadgeVisible`) so the two blink identically.
  func powerUpVisible(remaining: Double) -> Bool {
    guard remaining > 0 else { return false }
    guard remaining <= Self.capeBlinkDuration else { return true }
    return Int(remaining * 10) % 2 == 0
  }

  /// Whether the ⚡ badge above the dancer should be drawn this frame (same blink
  /// envelope as the cape).
  var isSpeedBadgeVisible: Bool { powerUpVisible(remaining: speedRemaining) }

  /// Whether the 🎸 badge beside the dancer should be drawn this frame (same blink
  /// envelope as the cape and speed badges).
  var isSerenataBadgeVisible: Bool { powerUpVisible(remaining: serenataRemaining) }

  /// The walk/climb speed multiplier in effect right now — ×`speedFactor` while the
  /// speed power-up is active, otherwise ×1. Multiplied into `updatePlayer`'s walk
  /// line and `updateClimb`'s climb line.
  var speedFactorNow: CGFloat { speedRemaining > 0 ? Self.speedFactor : 1 }

  /// The BULL's pacing multiplier — ⚡ doubles how fast he crosses the top girder too
  /// (per Josh), so the whole scene quickens while the power-up runs. Multiplied into
  /// `updateBull`'s pace line only: his flipbook still runs at the fixed `fps`, so the
  /// walk animation itself is unaffected.
  var bullSpeedFactorNow: CGFloat { speedRemaining > 0 ? Self.speedFactor : 1 }

  // MARK: The carried cape

  /// Whether to draw the cape as a separate glyph beside the dancer this frame. The
  /// muleta is baked into the `.cape`/`.capeWalk` sprites, so the carried overlay fills
  /// in exactly when those aren't showing — mid-jump and on a ladder, where the dancer
  /// renders capeless — and the two are never on screen together. It shares the cape's
  /// expiry blink through `isCapeVisible` at the render site.
  var isCarriedCapeVisible: Bool {
    isCaped && playerAction != .cape && playerAction != .capeWalk
  }

  /// Turn the carried cape toward this jump's quarter-turn target and back to standard
  /// on landing, at `capeRotationRate` deg/s. `capeRotationDirection` is set by `jump()`
  /// from the facing (+1 clockwise / −1 counter-clockwise) and cleared once the cape has
  /// fully unwound, so a re-pickup mid-air can reset it to standard (`collectPowerUp`).
  func updateCapeRotation(dt: CGFloat) {
    let target = playerGrounded ? 0 : capeRotationDirection * Self.capeJumpRotation
    if capeRotation != target {
      let step = Self.capeRotationRate * Double(dt)
      capeRotation = capeRotation < target
        ? min(target, capeRotation + step)
        : max(target, capeRotation - step)
    }
    if playerGrounded && capeRotation == 0 { capeRotationDirection = 0 }
  }

  // MARK: Per-stage assignment (shuffle bag)

  /// Draw the next stage's power-up kind: honor the `CONJUGAR_GAME_POWERUP` override
  /// if set, otherwise pull from the shuffle bag (refill + reshuffle through
  /// `bossRNG` when empty).
  func drawStagePowerUpKind() -> PowerUpKind {
    if let forced = Self.debugForcedPowerUp { return forced }
    if powerUpBag.isEmpty {
      powerUpBag = PowerUpKind.allCases.shuffled(using: &bossRNG)
    }
    return powerUpBag.removeLast()
  }

  /// Draw and store this stage's power-up kind, then (re)place the pickups. Called
  /// from `reset()` (stage 1) and `advanceToNextStage()` (every later stage).
  func assignStagePowerUp() {
    stagePowerUpKind = drawStagePowerUpKind()
    rebuildPowerUps(kind: stagePowerUpKind)
  }

  /// Rebuild the stage's two pickups at their platform spawn points (the same two
  /// mid-platforms the cape always used), all of the drawn `kind` and uncollected.
  func rebuildPowerUps(kind: PowerUpKind) {
    let w = screenSize.width
    powerUps = [
      PowerUp(id: 0, x: w * 0.4, y: platforms[1].surfaceY - Self.capeSize / 2, kind: kind, collected: false),
      PowerUp(id: 1, x: w * 0.6, y: platforms[3].surfaceY - Self.capeSize / 2, kind: kind, collected: false)
    ]
  }

  // MARK: Collection

  /// Apply the effect of collecting a pickup of `kind` (called from
  /// `resolveCollisions`). Each starts its own timer and plays its cue.
  func collectPowerUp(_ kind: PowerUpKind) {
    switch kind {
    case .cape:
      capedRemaining = Self.capeDuration
      // A fresh cape always arrives in its standard orientation: picking one up while
      // already caped snaps any in-progress jump turn back to 0 (the next jump turns
      // again as normal).
      capeRotation = 0
      capeRotationDirection = 0
      Current.soundPlayer.play(.shieldActivate, shouldDebounce: false)   // cape power-up
    case .speed:
      speedRemaining = Self.speedDuration
      Current.soundPlayer.play(.speedWhoosh, shouldDebounce: false)      // speed power-up
    case .serenata:
      serenataRemaining = Self.serenataDuration
      serenataDanceTimer = 0                                             // start dancing at once
      Current.soundPlayer.play(.guitarStrum, shouldDebounce: false)      // La Serenata
    case .flechazo:
      flechazoRemaining = Self.flechazoDuration
      flechazoCooldown = 0
      Current.soundPlayer.play(.brainLockOn, shouldDebounce: false)      // El Flechazo armed
    case .cortejo:
      // Grant three charges (banks onto any remainder from an earlier mushroom) and fire one
      // now if idle; the rest wait for later jumps. `maybeTriggerCortejo` plays the possession
      // cue when it fires; if it banks (a chase is mid-flight) play a distinct "bank" click so
      // the pickup still registers audibly.
      cortejoCharges += 3
      if !maybeTriggerCortejo() {
        Current.soundPlayer.play(.castanetHigh, shouldDebounce: false)   // banked — charges stored
      }
    }
  }

  /// Whether a cortejo possession is in flight — an obstacle shivering, chasing, or fading
  /// out from a catch. The pickup's immediate fire and every jump-retrigger both wait for
  /// this to clear, so the chase/obliteration time is a natural cooldown between possessions.
  var isCortejoActive: Bool {
    obstacles.contains { $0.isChaser || $0.vibrateRemaining > 0 }
  }

  /// Spend one banked cortejo charge to start a possession — but only when idle (no chase in
  /// flight) and charged. Shared by the pickup (immediate fire) and each qualifying jump, so
  /// the two next jumps after a chase completes each re-possess until the charges run out.
  /// Returns whether it actually fired (false = banked/none), so the pickup can play a
  /// distinct bank cue instead of the possession chime.
  @discardableResult
  func maybeTriggerCortejo() -> Bool {
    guard cortejoCharges > 0, !isCortejoActive else { return false }
    cortejoCharges -= 1
    startCortejo()
    Current.soundPlayer.play(.chime, shouldDebounce: false)   // the possession cue
    return true
  }

  // MARK: Serenata dance

  /// While La Serenata plays the bull stands still and dances random bursts from the
  /// end-scene repertoire (foreshadowing the boss dance-off + the dancing-bull end
  /// scene). Called by `updateBull` in place of pacing/throwing; `bullMoveTimer` is
  /// decremented here because the climb pipeline otherwise never ticks it (only the
  /// boss path does). `derivedBullAction` then shows the commanded move while the
  /// burst runs, `.idle` between bursts.
  func updateSerenataDance(dt: CGFloat) {
    if bullMoveTimer > 0 { bullMoveTimer -= Double(dt) }
    serenataDanceTimer -= Double(dt)
    if serenataDanceTimer <= 0 {
      serenataDanceTimer = Self.serenataDanceInterval
      let move = Self.endSceneDanceMoves.randomElement(using: &bossRNG) ?? .stomp
      commandBullMove(move, duration: Self.danceBurstDuration)
    }
  }

  /// A jump during La Serenata is a strummed chord: it rings the quiz's correct-answer
  /// chime and sends a 🎵 to the serenaded bull. Called from `jump()`; a no-op unless the
  /// power-up is running.
  func strumSerenataIfActive() {
    guard serenataRemaining > 0 else { return }
    Current.soundPlayer.play(.chime, shouldDebounce: false)   // the quiz's "correct!" cue
    serenataNotes.append(
      SerenataNote(
        id: serenataNoteCounter,
        x: bullX, y: bullY - Self.serenataNoteLift,
        remaining: Self.serenataNoteLife
      )
    )
    serenataNoteCounter += 1
  }

  /// Ride each note on the bull, half a glyph above his center — its position is re-read
  /// from him every frame, so it tracks him through the dance — and burst it into
  /// yellow-and-blue particles once its second is up.
  func updateSerenataNotes(dt: CGFloat) {
    guard !serenataNotes.isEmpty else { return }
    for i in serenataNotes.indices {
      serenataNotes[i].x = bullX
      serenataNotes[i].y = bullY - Self.serenataNoteLift
      serenataNotes[i].remaining -= Double(dt)
      if serenataNotes[i].remaining <= 0 {
        spawnFanfareParticles(x: serenataNotes[i].x, y: serenataNotes[i].y)
      }
    }
    serenataNotes.removeAll { $0.remaining <= 0 }
  }

  // MARK: El Flechazo (heart missiles on jump)

  /// Whether the ❤️ badge above the dancer should be drawn this frame (same blink envelope
  /// as the cape/speed badges).
  var isFlechazoBadgeVisible: Bool { powerUpVisible(remaining: flechazoRemaining) }

  /// Fire a homing ❤️ missile at the nearest obstacle to the player, if the power-up is
  /// armed and off cooldown and a target exists. Called from `jump()`. No target → no
  /// missile and NO cooldown consumed (per the plan).
  func fireHeartMissileIfArmed() {
    guard isFlechazoActive, flechazoCooldown <= 0, let target = randomTargetableObstacle() else { return }
    let dx = target.x - playerX
    let dy = target.y - playerY
    let dist = max(1, (dx * dx + dy * dy).squareRoot())
    heartMissiles.append(
      HeartMissile(
        id: heartMissileCounter,
        x: playerX, y: playerY,
        velocityX: dx / dist * Self.heartMissileSpeed,
        velocityY: dy / dist * Self.heartMissileSpeed,
        targetID: target.id,
        lifeRemaining: Self.heartMissileLife
      )
    )
    // Every fired missile blooms a ❤️ beside the captive matador — the arrow is aimed at
    // an obstacle, but the *flechazo* is for him. It pops when this missile connects.
    matadorHearts.append(MatadorHeart(id: matadorHeartCounter, missileID: heartMissileCounter))
    matadorHeartCounter += 1
    heartMissileCounter += 1
    flechazoCooldown = Self.flechazoCooldownDuration
    Current.soundPlayer.play(.brainLockOn, shouldDebounce: false, volume: 0.6)   // lock-on
  }

  // MARK: El Flechazo — the matador's hearts

  /// Where the heart in `slot` (its index in `matadorHearts`) sits: off the matador's
  /// right side at his sprite's vertical center, later hearts stacking further right.
  /// Derived from his live position, so the pile rides him through an escape beat.
  func matadorHeartPosition(slot: Int) -> CGPoint {
    CGPoint(
      x: bullfighterX + Self.matadorHeartOffset.width + CGFloat(slot) * Self.matadorHeartSpacing,
      y: bullfighterY + Self.matadorHeartOffset.height
    )
  }

  /// Burst the heart bound to `missileID` into yellow-and-blue particles — the payoff for
  /// a missile that struck. A no-op if that heart is already gone.
  func popMatadorHeart(missileID: Int) {
    guard let slot = matadorHearts.firstIndex(where: { $0.missileID == missileID }) else { return }
    let position = matadorHeartPosition(slot: slot)
    matadorHearts.remove(at: slot)
    spawnFanfareParticles(x: position.x, y: position.y)
  }

  /// Age the pile: grow each new heart in, and quietly retire any whose missile is gone
  /// without having struck (it expired mid-flight, or a summit cleared the field) — an
  /// un-popped heart fades rather than lingering forever.
  func updateMatadorHearts(dt: CGFloat) {
    guard !matadorHearts.isEmpty else { return }
    for i in matadorHearts.indices {
      matadorHearts[i].age += Double(dt)
      if let fade = matadorHearts[i].fadeRemaining {
        matadorHearts[i].fadeRemaining = fade - Double(dt)
      } else if !heartMissiles.contains(where: { $0.id == matadorHearts[i].missileID }) {
        matadorHearts[i].fadeRemaining = Self.matadorHeartFade
      }
    }
    matadorHearts.removeAll { ($0.fadeRemaining ?? 1) <= 0 }
  }

  /// 0…1 opacity of the heart in `slot`: it grows in over `matadorHeartGrow`, holds at
  /// full while its missile flies, then fades over `matadorHeartFade` if it never popped.
  func matadorHeartOpacity(_ heart: MatadorHeart) -> Double {
    let grow = min(1, heart.age / Self.matadorHeartGrow)
    guard let fade = heart.fadeRemaining else { return grow }
    return min(grow, max(0, fade / Self.matadorHeartFade))
  }

  /// The obstacle nearest the player (ignoring ones already fading out), or nil if the field
  /// is empty. Targets may include `camada` babies — harmless. Used as the mid-flight
  /// re-target fallback when a missile's original quarry vanishes.
  func nearestObstacleToPlayer() -> Obstacle? {
    obstacles
      .filter { $0.fadeRemaining <= 0 }
      .min { distSq(playerX, playerY, $0.x, $0.y) < distSq(playerX, playerY, $1.x, $1.y) }
  }

  /// A RANDOM on-screen obstacle (ignoring ones already fading out), or nil if the field is
  /// empty — the missile's launch target (per Josh: a jump fires at a random obstacle, not
  /// the closest). Drawn through `bossRNG` so it stays deterministic under test.
  func randomTargetableObstacle() -> Obstacle? {
    obstacles.filter { $0.fadeRemaining <= 0 }.randomElement(using: &bossRNG)
  }

  /// Steer every in-flight missile toward its target's current position (pursuit → a roughly
  /// parabolic path, since the target moves), destroying the obstacle on contact. A missile
  /// whose target vanished retargets to the new nearest obstacle, or fades out when its life
  /// expires with none left.
  func updateHeartMissiles(dt: CGFloat) {
    guard !heartMissiles.isEmpty else { return }
    let snapshot = obstacles
    for i in heartMissiles.indices {
      var missile = heartMissiles[i]
      missile.lifeRemaining -= Double(dt)

      var target = snapshot.first { $0.id == missile.targetID && $0.fadeRemaining <= 0 }
      if target == nil {
        target = snapshot
          .filter { $0.fadeRemaining <= 0 }
          .min { distSq(missile.x, missile.y, $0.x, $0.y) < distSq(missile.x, missile.y, $1.x, $1.y) }
        if let retarget = target { missile.targetID = retarget.id }
      }
      if let target {
        let dx = target.x - missile.x
        let dy = target.y - missile.y
        let dist = max(1, (dx * dx + dy * dy).squareRoot())
        missile.velocityX = dx / dist * Self.heartMissileSpeed
        missile.velocityY = dy / dist * Self.heartMissileSpeed
      }
      missile.x += missile.velocityX * dt
      missile.y += missile.velocityY * dt

      if let target, distSq(missile.x, missile.y, target.x, target.y) <= Self.heartMissileHitDistance * Self.heartMissileHitDistance {
        // Fade the struck obstacle out over 1 s (non-colliding while it fades) and throw a
        // yellow particle burst — same feedback as an obstacle striking the player, not an
        // instant despawn.
        if let ti = obstacles.firstIndex(where: { $0.id == target.id }) {
          obstacles[ti].fadeRemaining = Self.obstacleFadeDuration
          obstacles[ti].velocityX = 0
          obstacles[ti].velocityY = 0
        }
        spawnHitParticles(x: target.x, y: target.y)
        // The strike lands back at the matador too: his heart bursts yellow-and-blue.
        popMatadorHeart(missileID: missile.id)
        Current.soundPlayer.play(.chomp, shouldDebounce: true)   // smash
        missile.lifeRemaining = -1
      }
      heartMissiles[i] = missile
    }
    obstacles.removeAll { $0.despawn }
    heartMissiles.removeAll { $0.lifeRemaining <= 0 }
  }

  // MARK: El Cortejo (mushroom chaser)

  /// Possess a random on-screen obstacle: it shivers in place for `cortejoVibrateDuration`,
  /// then pursues another random obstacle. With fewer than 2 obstacles it simply fizzles —
  /// the possessed one shivers, finds no quarry, and despawns.
  func startCortejo() {
    let candidates = obstacles.filter { $0.parentID == nil && !$0.isChaser && $0.fadeRemaining <= 0 && $0.vibrateRemaining <= 0 }
    guard let chaser = candidates.randomElement(using: &bossRNG),
          let ci = obstacles.firstIndex(where: { $0.id == chaser.id }) else { return }
    obstacles[ci].vibrateRemaining = Self.cortejoVibrateDuration
    obstacles[ci].velocityX = 0
    obstacles[ci].velocityY = 0
    let quarry = candidates.filter { $0.id != chaser.id }.randomElement(using: &bossRNG)
    obstacles[ci].chaseTargetID = quarry?.id
    // Show where the possession came from: a 🍄 flies from the dancer to the obstacle
    // she just claimed, the way her hearts fly under El Flechazo. Purely cosmetic — the
    // shiver has already started, and the mushroom arrives during it.
    spawnCortejoMushroom(targetID: chaser.id)
  }

  /// Launch the cosmetic 🍄 from the dancer toward `targetID`.
  private func spawnCortejoMushroom(targetID: Int) {
    cortejoMushrooms.append(
      CortejoMushroom(
        id: cortejoMushroomCounter,
        x: playerX, y: playerY,
        targetID: targetID,
        lifeRemaining: Self.cortejoMushroomLife
      )
    )
    cortejoMushroomCounter += 1
  }

  /// Steer each flying mushroom at its target's current position and retire it on
  /// arrival (or when its life runs out, or its target vanishes). No collision, no
  /// damage: the possession it illustrates is already under way.
  func updateCortejoMushrooms(dt: CGFloat) {
    guard !cortejoMushrooms.isEmpty else { return }
    let snapshot = obstacles
    for i in cortejoMushrooms.indices {
      cortejoMushrooms[i].lifeRemaining -= Double(dt)
      guard let target = snapshot.first(where: { $0.id == cortejoMushrooms[i].targetID }) else {
        cortejoMushrooms[i].lifeRemaining = -1   // quarry gone — nothing left to illustrate
        continue
      }
      let dx = target.x - cortejoMushrooms[i].x
      let dy = target.y - cortejoMushrooms[i].y
      let dist = max(1, (dx * dx + dy * dy).squareRoot())
      if dist <= Self.cortejoMushroomHitDistance {
        cortejoMushrooms[i].lifeRemaining = -1   // arrived
        continue
      }
      cortejoMushrooms[i].x += dx / dist * Self.cortejoMushroomSpeed * dt
      cortejoMushrooms[i].y += dy / dist * Self.cortejoMushroomSpeed * dt
    }
    cortejoMushrooms.removeAll { $0.lifeRemaining <= 0 }
  }

  /// Tick the possessed obstacle from shiver → chase → catch. On catch, both it and its quarry
  /// fade out over `obstacleFadeDuration` (non-colliding while fading), red confetti blooms at
  /// the meeting point, and a bright catch cue plays.
  func updateCortejo(dt: CGFloat) {
    guard obstacles.contains(where: { $0.isChaser || $0.vibrateRemaining > 0 }) else { return }

    // Shiver → become a chaser once the vibrate window elapses.
    for i in obstacles.indices where obstacles[i].vibrateRemaining > 0 && obstacles[i].fadeRemaining <= 0 {
      obstacles[i].vibrateRemaining = max(0, obstacles[i].vibrateRemaining - Double(dt))
      if obstacles[i].vibrateRemaining == 0 { obstacles[i].isChaser = true }
    }

    // Steer the chasers (targets read from a snapshot to avoid overlapping access).
    let snapshot = obstacles
    let speed = obstacleSpeed * Self.cortejoChaseFactor
    for i in obstacles.indices where obstacles[i].isChaser && obstacles[i].fadeRemaining <= 0 {
      var chaser = obstacles[i]
      let target = snapshot.first { $0.id == chaser.chaseTargetID && !$0.isChaser && $0.fadeRemaining <= 0 }
        ?? snapshot
          .filter { !$0.isChaser && $0.fadeRemaining <= 0 && $0.vibrateRemaining <= 0 && $0.parentID == nil }
          .min { distSq(chaser.x, chaser.y, $0.x, $0.y) < distSq(chaser.x, chaser.y, $1.x, $1.y) }
      guard let target else {
        chaser.despawn = true               // no quarry remains — fizzle
        obstacles[i] = chaser
        continue
      }
      chaser.chaseTargetID = target.id
      let dx = target.x - chaser.x
      let dy = target.y - chaser.y
      let dist = max(1, (dx * dx + dy * dy).squareRoot())
      chaser.x += dx / dist * speed * dt     // up allowed — velocityY may be negative
      chaser.y += dy / dist * speed * dt
      chaser.facing = dx > 0 ? 1 : -1
      if chaser.style == .spin { chaser.rotation += Double(speed) * Double(dt) * 0.6 }

      if distSq(chaser.x, chaser.y, target.x, target.y) <= Self.cortejoCatchDistance * Self.cortejoCatchDistance {
        chaser.fadeRemaining = Self.obstacleFadeDuration
        chaser.velocityX = 0
        chaser.velocityY = 0
        if let ti = obstacles.firstIndex(where: { $0.id == target.id }) {
          obstacles[ti].fadeRemaining = Self.obstacleFadeDuration
          obstacles[ti].velocityX = 0
          obstacles[ti].velocityY = 0
        }
        spawnCortejoConfetti(x: (chaser.x + target.x) / 2, y: (chaser.y + target.y) / 2)
        Current.soundPlayer.play(.coin, shouldDebounce: false)   // the celebratory catch
      }
      obstacles[i] = chaser
    }
    obstacles.removeAll { $0.despawn }
  }

  /// A small fan of red love-glyphs blooming over a cortejo catch — reusing the boss end
  /// scene's particle idiom (`spawnJaleo` emoji pops; emoji keep their own red color
  /// regardless of the jaleo tint), so no new particle type is needed.
  func spawnCortejoConfetti(x: CGFloat, y: CGFloat) {
    let glyphs = ["🌹", "❤️", "🌹", "❤️", "🌹"]
    for (index, glyph) in glyphs.enumerated() {
      let column = CGFloat(index - glyphs.count / 2)
      spawnJaleo(glyph, x: x + column * 16, y: y - 8, size: index == 0 ? 30 : 24, riseRate: Self.jaleoDriftRise, ttl: 1.1)
    }
  }
}
