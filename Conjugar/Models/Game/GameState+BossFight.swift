//
//  GameState+BossFight.swift
//  Conjugar
//
//  Boss fight — **La Llamada**, the call-and-response dance-off duel
//  (see prompts/game_boss_llamada.md). After summiting, the bull dances a phrase
//  move by move (cue chips accumulate), the player echoes it from memory on the
//  morphed control pad while a compás bar sweeps, and a 6-notch Duende meter
//  (banked phrases) is both the tug-of-war and the fight's progression: banked 0–1
//  round 1 (length 3), 2–3 round 2 (length 4), 4–5 round 3 (length 5, with a 🔥
//  freeze fake-out), 6 victory. Failure slides the meter back a notch and rerolls a
//  fresh phrase — the bull never harms the dancer; there is no lose state.
//
//  `update(currentTime:)` routes every non-`.climb` phase here, so the climb
//  pipeline's derived actions never stomp the commanded dance bursts. Phase-1 note:
//  the dance actions reuse existing rendered flipbooks (ole ≈ cape, stomp ≈ jump;
//  bull stomp/rear ≈ throw, bow ≈ idle), and the boss SFX are placeholder reuses of
//  existing `Sound` cases — boss plan Phases 2–4 swap in the real pack and sprites.
//

import CoreGraphics
import Foundation

extension GameState {
  // MARK: Derived state

  /// The current round, 0-based, derived from the meter: banked 0–1 → 0, 2–3 → 1,
  /// 4–5 → 2. A failure's slide-back can demote the round — the tug-of-war working
  /// as intended.
  var bossRound: Int {
    min(banked / 2, Self.phraseLengths.count - 1)
  }

  /// Bull-demo seconds per move this round — playback speeds up round over round.
  var demoStepDuration: Double {
    Self.demoStepDurations[bossRound]
  }

  /// Whether the boss control cluster should accept (and brightly render) input.
  var isEchoActive: Bool {
    guard phase == .duel, case .playerEcho = duelState else { return false }
    return true
  }

  // MARK: Stage geometry (portrait tablao on the bottom girder)

  var stageFloorY: CGFloat { platforms.isEmpty ? 0 : platforms[0].surfaceY }
  var bullStageX: CGFloat { screenSize.width * 0.28 }
  var bullStageY: CGFloat { stageFloorY - Self.bullSize / 2 }
  var dancerStageX: CGFloat { screenSize.width * 0.68 }
  var dancerStageY: CGFloat { stageFloorY - Self.playerHeight / 2 }
  var pedestalCenterX: CGFloat { screenSize.width * 0.9 }
  var pedestalTopY: CGFloat { stageFloorY - Self.bossPedestalSize.height }
  var matadorStageX: CGFloat { pedestalCenterX }
  var matadorStageY: CGFloat { pedestalTopY - Self.bullfighterSize / 2 }

  // MARK: Entry & intro

  /// The boss's front door, called from `checkReachedBull()` on the triggering
  /// summit (and by the two debug entries). Freezes climb inputs, clears the field,
  /// starts the scenery crossfade, and fades the gameplay music out — the boss track
  /// fades in when the transition completes (the llamada beat).
  func enterBossIntro() {
    guard phase == .climb else { return }
    phase = .bossIntro
    introTimer = Self.introDuration
    bossTransition = 0
    didLlamada = false
    bossMusicStarted = false

    movingLeft = false
    movingRight = false
    movingUp = false
    movingDown = false
    playerClimbing = false
    climbingLadder = nil
    playerVelocityY = 0
    playerGrounded = true
    capedRemaining = 0
    damageCooldown = 0
    flags.removeAll()
    bullThrowTimer = 0

    introFromPlayerX = playerX
    introFromPlayerY = playerY
    introFromBullX = bullX
    introFromBullY = bullY
    introFromMatadorX = bullfighterX
    introFromMatadorY = bullfighterY

    playerAction = .walk
    playerPhase = 0
    playerMoveTimer = 0
    bullAction = .walk
    bullPhase = 0
    bullMoveTimer = 0

    Current.soundPlayer.stopMusic(fadeDuration: Self.bossTransitionDuration)
  }

  /// Any tap during the intro jumps straight to the duel.
  func skipBossIntro() {
    guard phase == .bossIntro else { return }
    bossTransition = 1
    snapActorsToStage()
    performLlamada()
    startDuel()
  }

  private func snapActorsToStage() {
    playerX = dancerStageX
    playerY = dancerStageY
    bullX = bullStageX
    bullY = bullStageY
    bullfighterX = matadorStageX
    bullfighterY = matadorStageY
    playerFacing = -1
    bullFacing = 1
  }

  /// The bull's opening llamada: stomp burst + shake + the boss track fading in.
  /// Idempotent — the tap-skip path may race the timed path.
  private func performLlamada() {
    guard !didLlamada else { return }
    didLlamada = true
    playerAction = .idle
    commandBullMove(.stomp, duration: Self.danceBurstDuration)
    triggerScreenShake()
    // Placeholder stomp thud (Phase 2: the Pixabay stompThud).
    Current.soundPlayer.play(.soccerKick, shouldDebounce: false, volume: 0.5)
    if !bossMusicStarted {
      bossMusicStarted = true
      Current.soundPlayer.startMusic(.bossFight)
    }
  }

  private func updateIntro(dt: Double) {
    if bossTransition < 1 {
      bossTransition = min(1, bossTransition + dt / Self.bossTransitionDuration)
      let t = Self.smoothstep(CGFloat(bossTransition))
      playerX = Self.lerp(introFromPlayerX, dancerStageX, t)
      playerY = Self.lerp(introFromPlayerY, dancerStageY, t)
      bullX = Self.lerp(introFromBullX, bullStageX, t)
      bullY = Self.lerp(introFromBullY, bullStageY, t)
      bullfighterX = Self.lerp(introFromMatadorX, matadorStageX, t)
      bullfighterY = Self.lerp(introFromMatadorY, matadorStageY, t)
      playerFacing = -1
      bullFacing = 1
      if bossTransition >= 1 {
        performLlamada()
      }
    }
    introTimer -= dt
    if introTimer <= 0 {
      startDuel()
    }
  }

  // MARK: The duel loop

  private func startDuel() {
    guard phase != .duel else { return }
    phase = .duel
    startPhrase()
  }

  /// Roll a fresh phrase for the current round and begin the bull's demo.
  func startPhrase() {
    rollPhrase()
    duelState = .bullDemo(step: 0)
    duelTimer = demoStepDuration
    performBullDemo(move: phraseSequence[0])
  }

  /// A fresh uniform-random phrase at the current round's length. Round 3 injects
  /// exactly one freeze at a random non-first slot. Rerolled fresh on failure — the
  /// player never rote-repeats a failed phrase.
  func rollPhrase() {
    let length = Self.phraseLengths[bossRound]
    var moves = (0..<length).map { _ in DanceMove.phraseMoves.randomElement(using: &bossRNG) ?? .stomp }
    if bossRound == Self.phraseLengths.count - 1 {
      let slot = Int.random(in: 1..<length, using: &bossRNG)
      moves[slot] = .freeze
    }
    phraseSequence = moves
  }

  private func performBullDemo(move: DanceMove) {
    commandBullMove(Self.bullDanceAction(move), duration: demoStepDuration)
    switch move {
    case .pasoLeft: bullFacing = -1
    case .pasoRight: bullFacing = 1
    default: bullFacing = 1
    }
    // Placeholder cue note (Phase 2: per-move castanets/palmas/whoosh).
    Current.soundPlayer.play(.chirp, shouldDebounce: false, volume: 0.3)
  }

  private func beginEcho() {
    duelState = .playerEcho(step: 0)
    echoTotal = Double(phraseSequence.count) * Self.echoTimePerMove + Self.echoGrace
    echoRemaining = echoTotal
    bullAction = .idle
    bullFacing = 1
    prepareEchoSlot(0)
    spawnJaleo("¡Tu turno!", x: playerX, y: playerY - 54)
  }

  private func prepareEchoSlot(_ step: Int) {
    if phraseSequence[step] == .freeze {
      freezeTimer = Self.freezeHold
    }
  }

  /// Judge one player input against the expected slot. Boss buttons call this on
  /// touch-down (never held intents).
  func danceInput(_ move: DanceMove) {
    guard phase == .duel, case .playerEcho(let step) = duelState else { return }
    let expected = phraseSequence[step]
    guard expected != .freeze else {
      // The 🔥 fake-out: any input during the freeze window fails the phrase.
      failPhrase()
      return
    }
    if move == expected {
      score += Self.movePoints
      commandPlayerMove(move)
      Current.soundPlayer.play(.pop, shouldDebounce: false, volume: 0.5)
      spawnJaleo(["¡Eso!", "¡Bien!", "¡Vamos!"].randomElement() ?? "¡Eso!", x: playerX, y: playerY - 54)
      advanceEcho(from: step)
    } else {
      failPhrase()
    }
  }

  private func advanceEcho(from step: Int) {
    let next = step + 1
    if next >= phraseSequence.count {
      succeedPhrase()
    } else {
      duelState = .playerEcho(step: next)
      prepareEchoSlot(next)
    }
  }

  private func succeedPhrase() {
    score += Self.phraseBonus * (bossRound + 1)
    banked += 1
    spawnJaleo("¡Olé!", x: playerX, y: playerY - 70)
    // Placeholder phrase-success cue (Phase 2: palmas + crowd olé).
    Current.soundPlayer.play(.chime, shouldDebounce: false)
    duelState = .phraseResult(success: true)
    duelTimer = Self.phraseResultHold
  }

  private func failPhrase() {
    banked = max(0, banked - 1)
    Current.soundPlayer.play(.buzz, shouldDebounce: false)
    spawnJaleo("¡Uy!", x: playerX, y: playerY - 54)
    // The bull snorts and stomps smugly (Phase 2: the real snort).
    Current.soundPlayer.play(.cow, shouldDebounce: true, volume: 0.2)
    commandBullMove(.stomp, duration: Self.danceBurstDuration)
    duelState = .phraseResult(success: false)
    duelTimer = Self.phraseResultHold
  }

  private func resolvePhraseResult(success: Bool) {
    if success && banked >= Self.meterNotches {
      enterVictory()
    } else if success && (banked == 2 || banked == 4) {
      enterShowboat(duration: Self.showboatDuration)
    } else if !success {
      enterShowboat(duration: Self.showboatLiteDuration)
    } else {
      startPhrase()
    }
  }

  private func enterShowboat(duration: Double) {
    duelState = .showboat
    duelTimer = duration
    showboatDidRear = false
    commandBullMove(.walk, duration: duration)
    // Crowd murmur placeholder (Phase 2: real crowd bed).
    Current.soundPlayer.play(.cow, shouldDebounce: true, volume: 0.15)
  }

  private func updateDuel(dt: Double) {
    switch duelState {
    case .bullDemo(let step):
      duelTimer -= dt
      if duelTimer <= 0 {
        let next = step + 1
        if next < phraseSequence.count {
          duelState = .bullDemo(step: next)
          duelTimer = demoStepDuration
          performBullDemo(move: phraseSequence[next])
        } else {
          beginEcho()
        }
      }

    case .playerEcho(let step):
      echoRemaining -= dt
      if phraseSequence[step] == .freeze {
        freezeTimer -= dt
        if freezeTimer <= 0 {
          // Survived the fake-out: sparkle and auto-advance.
          score += Self.movePoints
          spawnJaleo("✨", x: playerX, y: playerY - 54)
          Current.soundPlayer.play(.chirp, shouldDebounce: false, volume: 0.4)
          advanceEcho(from: step)
          return
        }
      }
      if echoRemaining <= 0 {
        failPhrase()
      }

    case .phraseResult(let success):
      duelTimer -= dt
      if duelTimer <= 0 {
        resolvePhraseResult(success: success)
      }

    case .showboat:
      duelTimer -= dt
      // One rear-up flourish in the strut's final second.
      if !showboatDidRear && duelTimer <= Self.showboatLiteDuration {
        showboatDidRear = true
        commandBullMove(.rear, duration: Self.danceBurstDuration)
      }
      if duelTimer <= 0 {
        startPhrase()
      }
    }
  }

  // MARK: Victory & end scene

  private func enterVictory() {
    phase = .victory
    victoryTimer = Self.victoryHold
    score += Self.bossClearBonus
    // The bull — impressed — bows and holds the final frame (capped each tick).
    bullAction = .bow
    bullPhase = 0
    bullMoveTimer = 0
    playerAction = .idle
    playerMoveTimer = 0
    Current.soundPlayer.play(Sound.randomApplause, shouldDebounce: false)
    triggerScreenShake()
  }

  private func updateVictory(dt: Double) {
    capBullBowHold()
    victoryTimer -= dt
    if victoryTimer <= 0 {
      enterEndScene()
    }
  }

  /// Freeze the bow's flipbook on its final frame after one pass (the frame index
  /// wraps modulo the count, so an uncapped phase would loop the bow forever).
  private func capBullBowHold() {
    guard bullAction == .bow, let count = Self.bullFrameCounts[.bow] else { return }
    let lastFramePhase = (Double(count) - 0.01) / Double(Self.fps)
    bullPhase = min(bullPhase, lastFramePhase)
  }

  /// The minimal end scene (boss plan Phase 5 polishes it): the boss track fades
  /// out, `Music.onboarding` fades in — its long-intended use — and the freed
  /// matador slides from his pedestal to the dancer. Any tap dismisses the game.
  func enterEndScene() {
    guard phase == .victory else { return }
    phase = .endScene
    endSceneTime = 0
    endSceneMusicStarted = false
    endSceneBurstDone = false
    Current.soundPlayer.stopMusic(fadeDuration: Self.endSceneMusicFade)
  }

  private func updateEndScene(dt: Double) {
    capBullBowHold()
    endSceneTime += dt

    if !endSceneMusicStarted && endSceneTime >= Self.endSceneMusicFade {
      endSceneMusicStarted = true
      Current.soundPlayer.startMusic(.onboarding)
    }

    // The matador slides from his pedestal to the dancer's side.
    let slide = min(1.0, endSceneTime / Self.matadorSlideDuration)
    let t = Self.smoothstep(CGFloat(slide))
    let targetX = dancerStageX + 36
    let targetY = stageFloorY - Self.bullfighterSize / 2
    bullfighterX = Self.lerp(matadorStageX, targetX, t)
    bullfighterY = Self.lerp(matadorStageY, targetY, t)

    if slide >= 1 && !endSceneBurstDone {
      endSceneBurstDone = true
      let midX = (playerX + targetX) / 2
      spawnJaleo("❤️", x: midX - 14, y: playerY - 64)
      spawnJaleo("🌹", x: midX + 14, y: playerY - 76)
      Current.soundPlayer.play(.chime, shouldDebounce: false, volume: 0.5)
    }
  }

  // MARK: Boss frame tick

  /// The boss counterpart of the climb pipeline, routed from `update(currentTime:)`
  /// for every phase except `.climb`.
  func updateBoss(dt: CGFloat) {
    let dtSeconds = Double(dt)
    advanceBossCosmetics(dt: dtSeconds)

    switch phase {
    case .climb:
      return
    case .bossIntro:
      updateIntro(dt: dtSeconds)
    case .duel:
      updateDuel(dt: dtSeconds)
    case .victory:
      updateVictory(dt: dtSeconds)
    case .endScene:
      updateEndScene(dt: dtSeconds)
    }
  }

  /// Flipbook phases, one-shot burst expiry, shake decay, and jaleo aging — shared
  /// by every boss phase.
  private func advanceBossCosmetics(dt: Double) {
    playerPhase += dt
    bullPhase += dt

    if screenShake > 0 {
      screenShake = max(0, screenShake - dt)
    }

    if playerMoveTimer > 0 {
      playerMoveTimer -= dt
      if playerMoveTimer <= 0 {
        playerAction = .idle
        playerFacing = -1
      }
    }
    if bullMoveTimer > 0 {
      bullMoveTimer -= dt
      if bullMoveTimer <= 0 {
        // Never let a stale burst-expiry overwrite the held victory bow.
        if bullAction != .bow {
          bullAction = phase == .duel && isShowboating ? .walk : .idle
        }
        bullFacing = 1
      }
    }

    for i in jaleoPops.indices {
      jaleoPops[i].ttl -= dt
    }
    jaleoPops.removeAll { $0.ttl <= 0 }
  }

  private var isShowboating: Bool {
    duelState == .showboat
  }

  // MARK: One-shot dance bursts (the `bullThrowTimer` pattern)

  private func commandPlayerMove(_ move: DanceMove) {
    playerAction = Self.playerDanceAction(move)
    playerPhase = 0
    playerMoveTimer = Self.danceBurstDuration
    switch move {
    case .pasoLeft: playerFacing = -1
    case .pasoRight: playerFacing = 1
    default: playerFacing = -1
    }
  }

  private func commandBullMove(_ action: BullAction, duration: Double) {
    bullAction = action
    bullPhase = 0
    bullMoveTimer = duration
  }

  /// The dancer's animation for each move (Phase-1 reuse: ole ≈ its own case backed
  /// by cape frames, stomp by jump frames — see GameView's asset mapping).
  static func playerDanceAction(_ move: DanceMove) -> PlayerAction {
    switch move {
    case .pasoLeft, .pasoRight: return .walk
    case .ole: return .ole
    case .stomp: return .stomp
    case .cape: return .cape
    case .freeze: return .idle
    }
  }

  /// The bull's demo animation for each move.
  static func bullDanceAction(_ move: DanceMove) -> BullAction {
    switch move {
    case .pasoLeft, .pasoRight: return .walk
    case .ole: return .rear
    case .stomp: return .stomp
    case .cape: return .throw
    case .freeze: return .idle
    }
  }

  // MARK: Juice

  func triggerScreenShake() {
    screenShake = Self.screenShakeDuration
  }

  func spawnJaleo(_ text: String, x: CGFloat, y: CGFloat) {
    jaleoCounter += 1
    jaleoPops.append(
      JaleoPop(id: jaleoCounter, text: text, x: x, y: y, ttl: Self.jaleoPopDuration, initialTTL: Self.jaleoPopDuration)
    )
  }

  /// Tap routing for the boss's full-screen tap layer: skip the intro, or skip the
  /// victory hold into the end scene. (An end-scene tap dismisses in the view.)
  func handleBossTap() {
    switch phase {
    case .bossIntro:
      skipBossIntro()
    case .victory:
      enterEndScene()
    default:
      break
    }
  }

  // MARK: Math helpers

  static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
  }

  static func smoothstep(_ t: CGFloat) -> CGFloat {
    let clamped = min(max(t, 0), 1)
    return clamped * clamped * (3 - 2 * clamped)
  }
}
