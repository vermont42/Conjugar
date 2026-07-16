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
//  pipeline's derived actions never stomp the commanded dance bursts. The dance
//  actions (dancer ole/stomp; bull stomp/rear/bow) render their own hand-keyed
//  sprite flipbooks, and the duel is scored by its own SFX/music pack.
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

  /// How long to hold `.bullDemo` on a given step before advancing. The LAST step
  /// gets an extra `demoRecallHold` so the whole sequence of cue chips stays on
  /// screen a beat longer before `beginEcho()` clears them (the final move was
  /// vanishing too fast to memorize, especially in the 5-step round-3 phrases).
  func demoStepTimer(forStep step: Int) -> Double {
    let isLast = step == phraseSequence.count - 1
    return demoStepDuration + (isLast ? Self.demoRecallHold : 0)
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
    // Warm the Taptic Engine so the llamada's first pulse fires without latency.
    Current.hapticPlayer.prepare()

    movingLeft = false
    movingRight = false
    movingUp = false
    movingDown = false
    playerClimbing = false
    climbingLadder = nil
    playerVelocityY = 0
    playerGrounded = true
    // Climb power-ups' timers only tick in the `.climb` branch, so any left active at the
    // summit would freeze on (e.g. a permanent ⚡ badge) — clear them all here.
    capedRemaining = 0
    speedRemaining = 0
    serenataRemaining = 0
    serenataDanceTimer = 0
    damageCooldown = 0
    obstacles.removeAll()
    bullThrowTimer = 0
    // The boss interrupts any active climb mechanic (zombie/encierro/apagón).
    cancelActiveMechanic()

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
    // The stomp thud that opens the duel.
    Current.soundPlayer.play(.stompThud, shouldDebounce: false, volume: 0.5)
    Current.hapticPlayer.play(.impactHeavy)
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
    duelTimer = demoStepTimer(forStep: 0)
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
    // Each move speaks in its own voice — castanets (paso l/r), palmas (olé),
    // thud (stomp), whoosh (cape). Non-debounced: the cues are deliberately spaced
    // and a phrase may repeat a move within the 1 s debounce window.
    if let cue = move.cueSound {
      Current.soundPlayer.play(cue, shouldDebounce: false, volume: 0.3)
    }
  }

  private func beginEcho() {
    duelState = .playerEcho(step: 0)
    echoTotal = Double(phraseSequence.count) * Self.echoTimePerMove + Self.echoGrace
    echoRemaining = echoTotal
    bullAction = .idle
    bullFacing = 1
    prepareEchoSlot(0)
    spawnJaleo(L.Game.tuTurno, x: playerX, y: playerY - 84, size: 36)
  }

  private func prepareEchoSlot(_ step: Int) {
    if phraseSequence[step] == .freeze {
      freezeTimer = Self.freezeHold
      // A warning buzz marks the "hold!" moment — the physical counterpart to the
      // demo's ominous tension sting.
      Current.hapticPlayer.play(.warning)
      // Teach the fake-out at the moment it's actionable: the first freeze slot a
      // player ever faces (per boss run) says what to do — nothing.
      if !didShowFreezeHint {
        didShowFreezeHint = true
        spawnJaleo(L.Game.freezeHint, x: playerX, y: playerY - 84, size: 30)
      }
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
      // The dancer echoes the move in the same voice the bull demoed it in.
      if let cue = move.cueSound {
        Current.soundPlayer.play(cue, shouldDebounce: false, volume: 0.4)
      }
      Current.hapticPlayer.play(.impactLight)
      // A per-move shout — but not on the final move, whose succeedPhrase ¡Olé!
      // spawns at this same spot an instant later and would overlap it.
      if step + 1 < phraseSequence.count {
        spawnPlayerSpeech([L.Game.jaleoEso, L.Game.jaleoBien, L.Game.jaleoVamos].randomElement(using: &bossRNG) ?? L.Game.jaleoEso)
      }
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
    spawnPlayerSpeech(L.Game.jaleoOle, size: 44)
    // A banked phrase earns palmas and a crowd olé.
    Current.soundPlayer.play(.palmas, shouldDebounce: false, volume: 0.45)
    Current.soundPlayer.play(.crowdOle, shouldDebounce: false, volume: 0.4)
    Current.hapticPlayer.play(.success)
    duelState = .phraseResult(success: true)
    duelTimer = Self.phraseResultHold
  }

  private func failPhrase() {
    banked = max(0, banked - 1)
    Current.soundPlayer.play(.buzz, shouldDebounce: false)
    spawnJaleo(L.Game.jaleoUy, x: playerX, y: playerY - 74, size: 32)
    // The bull snorts and stomps smugly.
    Current.soundPlayer.play(.snort, shouldDebounce: true, volume: 0.4)
    Current.hapticPlayer.play(.error)
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
    // A low crowd murmur under the strut (debounced so back-to-back showboats
    // don't stack it).
    Current.soundPlayer.play(.crowdOle, shouldDebounce: true, volume: 0.15)
  }

  private func updateDuel(dt: Double) {
    switch duelState {
    case .bullDemo(let step):
      duelTimer -= dt
      if duelTimer <= 0 {
        let next = step + 1
        if next < phraseSequence.count {
          duelState = .bullDemo(step: next)
          duelTimer = demoStepTimer(forStep: next)
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
          spawnJaleo("✨", x: playerX, y: playerY - 64, size: 30)
          Current.soundPlayer.play(.chirp, shouldDebounce: false, volume: 0.4)
          Current.hapticPlayer.play(.impactMedium)
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
    // Hide the Duende meter for the rest of the boss sequence — a cleaner curtain call.
    hasWon = true
    // The bull — impressed — bows and holds the final frame (capped each tick).
    bullAction = .bow
    bullPhase = 0
    bullMoveTimer = 0
    playerAction = .idle
    playerMoveTimer = 0
    // Face the bowing bull for now; the dancer turns to the arriving matador two
    // seconds into the end scene (`endSceneDancerTurnDelay`).
    playerFacing = -1
    Current.soundPlayer.play(Sound.randomApplause, shouldDebounce: false)
    Current.hapticPlayer.play(.success)
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
    endSceneDanceTimer = Self.endSceneDanceInterval
    endSceneMooTimer = Double.random(in: Self.endSceneMooIntervalRange, using: &bossRNG)
    endSceneBurstTimer = Double.random(in: Self.endSceneBurstIntervalRange, using: &bossRNG)
    Current.soundPlayer.stopMusic(fadeDuration: Self.endSceneMusicFade)
  }

  private func updateEndScene(dt: Double) {
    capBullBowHold()
    endSceneTime += dt

    // Two seconds in, the dancer turns to face the matador sliding in from her right.
    if endSceneTime >= Self.endSceneDancerTurnDelay {
      playerFacing = 1
    }

    // The boss track finished fading on `enterEndScene`; the onboarding bed rises as
    // it clears, so the two never talk over each other (its own fade-in is gentle).
    if !endSceneMusicStarted && endSceneTime >= Self.endSceneMusicFade {
      endSceneMusicStarted = true
      Current.soundPlayer.startMusic(.onboarding)
    }

    // The freed matador holds a beat (applause + confetti land), then walks from his
    // pedestal to the dancer's side, decelerating into place (smoothstep easing).
    let slide = min(1.0, max(0.0, (endSceneTime - Self.matadorSlideDelay) / Self.matadorSlideDuration))
    let t = Self.smoothstep(CGFloat(slide))
    let targetX = dancerStageX + 36
    let targetY = stageFloorY - Self.bullfighterSize / 2
    bullfighterX = Self.lerp(matadorStageX, targetX, t)
    bullfighterY = Self.lerp(matadorStageY, targetY, t)

    guard slide >= 1 else { return }

    // The couple has reunited — the scene now *lives* rather than freezing on a still.
    if !endSceneBurstDone {
      endSceneBurstDone = true
      spawnReunionBurst(midX: coupleMidX)
      Current.soundPlayer.play(.chime, shouldDebounce: false, volume: 0.5)
      Current.hapticPlayer.play(.success)
    }

    // The freed bull celebrates with a loop of dance: every `endSceneDanceInterval` it
    // performs one randomly-chosen animated move (walk is danced in place — its
    // position never changes), held its burst duration then returning to idle via
    // `advanceBossCosmetics` (a bow instead freezes at the bottom until the next move).
    endSceneDanceTimer -= dt
    if endSceneDanceTimer <= 0 {
      endSceneDanceTimer = Self.endSceneDanceInterval
      let move = Self.endSceneDanceMoves.randomElement(using: &bossRNG) ?? .walk
      commandBullMove(move, duration: Self.endSceneDanceMoveDuration)
    }

    // …and vocalizes every few seconds while it dances — an equal-odds choice of a
    // snort, a moo, a stomp, or (nil) staying quiet.
    endSceneMooTimer -= dt
    if endSceneMooTimer <= 0 {
      endSceneMooTimer = Double.random(in: Self.endSceneMooIntervalRange, using: &bossRNG)
      let vocalizations: [Sound?] = [.snort, .moo, .stompThud, nil]
      if let sound = vocalizations.randomElement(using: &bossRNG) ?? nil {
        Current.soundPlayer.play(sound, shouldDebounce: false, volume: 0.5)
      }
    }

    // Hearts and roses keep flying up from the couple on their own random cadence.
    endSceneBurstTimer -= dt
    if endSceneBurstTimer <= 0 {
      endSceneBurstTimer = Double.random(in: Self.endSceneBurstIntervalRange, using: &bossRNG)
      spawnReunionBurst(midX: coupleMidX)
      Current.soundPlayer.play(.chime, shouldDebounce: false, volume: 0.35)
    }
  }

  /// The x-midpoint of the reunited pair (dancer + freed matador) — the origin the
  /// hearts and roses fly up from.
  private var coupleMidX: CGFloat {
    (playerX + bullfighterX) / 2
  }

  /// The reunion payoff: a small fan of hearts and roses blooming over the pair as
  /// the matador arrives. Deterministic spread (indexed, not RNG) so it reads the
  /// same every win and the tests stay stable.
  private func spawnReunionBurst(midX: CGFloat) {
    let glyphs = ["❤️", "🌹", "❤️", "🌹", "❤️"]
    for (index, glyph) in glyphs.enumerated() {
      // Fan out from the center: −2…+2 columns, alternating heights.
      let column = CGFloat(index - glyphs.count / 2)
      let dx = column * 22
      let dy = CGFloat(index.isMultiple(of: 2) ? -78 : -94)
      spawnJaleo(glyph, x: midX + dx, y: playerY + dy, size: index == 0 ? 34 : 28)
    }
  }

  // MARK: Boss frame tick

  /// The boss counterpart of the climb pipeline, routed from `update(currentTime:)`
  /// for every phase except `.climb`.
  func updateBoss(dt: CGFloat) {
    let dtSeconds = Double(dt)
    advanceBossCosmetics(dt: dtSeconds)

    switch phase {
    case .climb, .escape:
      // `.escape` is driven by `updateEscape` (GameState+Stages.swift), never routed
      // here; the case is defensive so the switch stays exhaustive.
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

    advanceJaleoPops(dt: dt)
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

  /// Command a one-shot bull dance burst: play `action` for `duration`, then fall back
  /// to idle (via `advanceBossCosmetics` in the boss path, or `updateSerenataDance`'s
  /// `derivedBullAction` in the climb path). Internal so the serenata dance can reuse it.
  func commandBullMove(_ action: BullAction, duration: Double) {
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

  func spawnJaleo(
    _ text: String,
    x: CGFloat,
    y: CGFloat,
    size: CGFloat = 24,
    riseRate: CGFloat = GameState.jaleoDriftRise,
    ttl: Double = GameState.jaleoPopDuration
  ) {
    jaleoCounter += 1
    jaleoPops.append(
      JaleoPop(id: jaleoCounter, text: text, x: x, y: y, ttl: ttl, initialTTL: ttl, size: size, riseRate: riseRate)
    )
  }

  /// The dancer *speaking* (¡Eso!/¡Bien!/¡Olé!…): the shout rises from just above her
  /// head all the way to the sight-line high in the empty upper field, fading slowly as
  /// it climbs so the words fill the otherwise-dead space above the tablao (design note
  /// 1). The rise rate is solved so the pop reaches the sight-line exactly as it fades.
  func spawnPlayerSpeech(_ text: String, size: CGFloat = 30) {
    let spawnY = playerY - Self.playerHeight
    let targetY = screenSize.height * Self.jaleoRiseTargetFraction
    let travel = max(80, spawnY - targetY)
    spawnJaleo(text, x: playerX, y: spawnY, size: size, riseRate: travel / Self.jaleoSpeechDuration, ttl: Self.jaleoSpeechDuration)
  }

  /// True during the brief hold after a phrase is echoed correctly — drives the blue
  /// success particle burst (design note 4).
  var isPhraseSuccess: Bool {
    phase == .duel && duelState == .phraseResult(success: true)
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

  // MARK: Debug

  /// Jump straight from the climb to the boss's end scene (couple reunited, bull
  /// bowing, onboarding music) — the `CONJUGAR_GAME_START_END` env var and the
  /// `conjugar://game/end` deeplink both land here. Reuses the real entry points so
  /// the debug path exercises the same setup the played-through path does.
  func debugJumpToEndScene() {
    guard phase == .climb else { return }
    enterBossIntro()          // freeze the climb, clear the field, set intro anchors
    bossTransition = 1
    snapActorsToStage()       // bull/dancer at their marks, matador on his pedestal
    banked = Self.meterNotches
    enterVictory()            // → .victory (bull bows, status bar latches)
    enterEndScene()           // → .endScene (the living reunion loop)
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
