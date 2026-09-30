//
//  GameBossTests.swift
//  ConjugarTests
//
//  Unit tests for the boss fight — La Llamada, the call-and-response dance-off
//  (GameState+BossFight.swift): the summit gate, intro transition, the duel's
//  demo/echo/judge loop (incl. the round-3 freeze fake-out and compás expiry),
//  the Duende meter's tug-of-war round derivation, scoring accumulation, victory
//  and end scene, and reset()'s full restoration of the climb. Swift Testing
//  (never XCTest) per the repo's isolated-deinit landmine; `@MainActor` because
//  `GameState` is MainActor. Phrases are scripted with a seeded `SplitMix64`
//  injected into `bossRNG`.
//

import CoreGraphics
import Foundation
import Testing
@testable import Conjugar

@Suite("GameBoss")
@MainActor
struct GameBossTests {
  private static let size = CGSize(width: 400, height: 800)

  private func configured() -> GameState {
    let gameState = GameState()
    gameState.configure(screenSize: Self.size)
    return gameState
  }

  /// A GameState dropped straight into the duel (intro tap-skipped), with a
  /// seeded RNG so the phrase is deterministic.
  private func duelReady(seed: UInt64 = 42) -> GameState {
    let gameState = configured()
    gameState.bossRNG = SplitMix64(seed: seed)
    gameState.enterBossIntro()
    gameState.handleBossTap()   // any tap skips the intro
    return gameState
  }

  /// Run the bull's demo out so input unlocks.
  private func advanceToEcho(_ gameState: GameState) {
    var safety = 0
    while !gameState.isEchoActive && safety < 500 {
      safety += 1
      gameState.updateBoss(dt: 0.2)
    }
  }

  /// Echo the whole phrase correctly (waiting out any freeze slot).
  private func completeEcho(_ gameState: GameState) {
    var safety = 0
    while case .playerEcho(let step) = gameState.duelState, safety < 20 {
      safety += 1
      let expected = gameState.phraseSequence[step]
      if expected == .freeze {
        gameState.updateBoss(dt: CGFloat(GameState.freezeHold) + 0.05)
      } else {
        gameState.danceInput(expected)
      }
    }
  }

  /// Step the real frame tick with scripted dates (the GameStateTests pattern).
  private func tick(_ gameState: GameState, seconds: Double) {
    var date = Date(timeIntervalSinceReferenceDate: 1_000)
    gameState.update(currentTime: date)   // primes lastUpdateTime (dt == 0 frame)
    let step = 1.0 / 60.0
    for _ in 0..<Int(seconds / step) {
      date = date.addingTimeInterval(step)
      gameState.update(currentTime: date)
    }
  }

  // MARK: Entry

  @Test func summitTriggersBossIntro() {
    let gameState = configured()
    gameState.summitCount = 4                  // the 5th summit is the boss (summitsToBoss)
    gameState.obstacles.append(
      Obstacle(id: 1, x: 0, y: 0, velocityX: 0, velocityY: 0, falling: false, level: 0, emoji: "🏳️", rotation: 0)
    )
    // Power-ups active at the summit must not leak into the duel (their timers tick only
    // in the `.climb` branch, so a survivor would freeze on — e.g. a permanent ⚡ badge).
    gameState.capedRemaining = 3
    gameState.speedRemaining = 3
    gameState.serenataRemaining = 3
    gameState.serenataDanceTimer = 1
    gameState.playerX = gameState.bullX
    gameState.playerY = gameState.bullY
    gameState.checkReachedBull()
    #expect(gameState.summitCount == 5)
    #expect(gameState.phase == .bossIntro)
    #expect(gameState.obstacles.isEmpty)       // field cleared for the stage
    #expect(gameState.capedRemaining == 0)
    #expect(gameState.speedRemaining == 0)
    #expect(gameState.serenataRemaining == 0)
    #expect(gameState.serenataDanceTimer == 0)
  }

  @Test func introTransitionCompletesIntoDuel() {
    let gameState = configured()
    gameState.bossRNG = SplitMix64(seed: 7)
    gameState.enterBossIntro()
    tick(gameState, seconds: GameState.introDuration + 0.2)
    #expect(gameState.phase == .duel)
    #expect(gameState.bossTransition == 1)
    #expect(abs(gameState.bullX - gameState.bullStageX) < 0.5)
    #expect(abs(gameState.playerX - gameState.dancerStageX) < 0.5)
    #expect(abs(gameState.bullfighterX - gameState.matadorStageX) < 0.5)
    #expect(gameState.duelState == .bullDemo(step: 0))
    #expect(gameState.phraseSequence.count == GameState.phraseLengths[0])
  }

  @Test func tapSkipsIntroStraightToDuel() {
    let gameState = duelReady()
    #expect(gameState.phase == .duel)
    #expect(gameState.bossTransition == 1)
    #expect(gameState.duelState == .bullDemo(step: 0))
  }

  // MARK: Demo → echo

  @Test func demoStepsThroughPhraseThenUnlocksEcho() {
    let gameState = duelReady()
    let length = gameState.phraseSequence.count
    #expect(length == 3)                                   // round 1
    for expectedStep in 0..<length {
      #expect(gameState.duelState == .bullDemo(step: expectedStep))
      // Per-step timer, so the final step's recall hold is waited out too.
      gameState.updateBoss(dt: CGFloat(gameState.demoStepTimer(forStep: expectedStep)) + 0.05)
    }
    #expect(gameState.isEchoActive)
    #expect(gameState.duelState == .playerEcho(step: 0))
    // Compás budget: moves × 1.5 s + 2 s grace.
    let expectedBudget = Double(length) * GameState.echoTimePerMove + GameState.echoGrace
    #expect(abs(gameState.echoTotal - expectedBudget) < 0.001)
  }

  @Test func demoHoldsFinalSequenceOneBeatBeforeEcho() {
    let gameState = duelReady()
    let length = gameState.phraseSequence.count
    // Step through every move but the last at the normal per-move cadence.
    for step in 0..<(length - 1) {
      #expect(gameState.duelState == .bullDemo(step: step))
      gameState.updateBoss(dt: CGFloat(gameState.demoStepDuration) + 0.05)
    }
    #expect(gameState.duelState == .bullDemo(step: length - 1))
    // The final move's own step time elapses — but the recall hold keeps the whole
    // sequence of cue chips on screen, so we're still demoing, not yet echoing.
    gameState.updateBoss(dt: CGFloat(gameState.demoStepDuration) + 0.05)
    #expect(gameState.duelState == .bullDemo(step: length - 1))
    #expect(!gameState.isEchoActive)
    // Only after the recall hold do the chips clear and the echo unlock.
    gameState.updateBoss(dt: CGFloat(GameState.demoRecallHold))
    #expect(gameState.isEchoActive)
    #expect(gameState.duelState == .playerEcho(step: 0))
  }

  // MARK: Judging

  @Test func correctEchoBanksPhraseAndScores() {
    let gameState = duelReady()
    advanceToEcho(gameState)
    let length = gameState.phraseSequence.count
    completeEcho(gameState)
    #expect(gameState.duelState == .phraseResult(success: true))
    #expect(gameState.banked == 1)
    // Round-1 phrase: +50 per move, +200 × round (1-based).
    #expect(gameState.score == length * GameState.movePoints + GameState.phraseBonus)
  }

  @Test func wrongInputFailsSlidesMeterAndRerollsSameLength() {
    let gameState = duelReady(seed: 99)
    gameState.banked = 1
    gameState.startPhrase()
    advanceToEcho(gameState)
    let failed = gameState.phraseSequence
    let expected = failed[0]
    let wrong = DanceMove.phraseMoves.first { $0 != expected } ?? .cape
    gameState.danceInput(wrong)
    #expect(gameState.duelState == .phraseResult(success: false))
    #expect(gameState.banked == 0)                          // slid back a notch
    // Result hold → showboat-lite → a FRESH phrase of the same length.
    gameState.updateBoss(dt: CGFloat(GameState.phraseResultHold) + 0.05)
    #expect(gameState.duelState == .showboat)
    gameState.updateBoss(dt: CGFloat(GameState.showboatLiteDuration) + 0.05)
    #expect(gameState.duelState == .bullDemo(step: 0))
    #expect(gameState.phraseSequence.count == failed.count)
    #expect(gameState.phraseSequence != failed)             // no rote-repeating
  }

  @Test func meterFloorsAtZero() {
    let gameState = duelReady()
    advanceToEcho(gameState)
    let expected = gameState.phraseSequence[0]
    let wrong = DanceMove.phraseMoves.first { $0 != expected } ?? .cape
    gameState.danceInput(wrong)
    #expect(gameState.banked == 0)                          // was 0; floored, not −1
  }

  @Test func compasExpiryFailsThePhrase() {
    let gameState = duelReady()
    advanceToEcho(gameState)
    gameState.updateBoss(dt: CGFloat(gameState.echoTotal) + 0.1)
    #expect(gameState.duelState == .phraseResult(success: false))
  }

  // MARK: The freeze fake-out (round 3)

  @Test func roundThreePhraseInjectsOneFreezeAtNonFirstSlot() {
    let gameState = duelReady()
    gameState.banked = 4                                    // round 3
    gameState.startPhrase()
    #expect(gameState.phraseSequence.count == 5)
    #expect(gameState.phraseSequence.filter { $0 == .freeze }.count == 1)
    #expect(gameState.phraseSequence[0] != .freeze)
  }

  @Test func inputDuringFreezeFails() {
    let gameState = duelReady()
    gameState.banked = 4
    gameState.startPhrase()
    advanceToEcho(gameState)
    // Play correctly until the freeze slot is current, then commit the sin.
    var safety = 0
    while case .playerEcho(let step) = gameState.duelState, safety < 10 {
      safety += 1
      let expected = gameState.phraseSequence[step]
      if expected == .freeze {
        gameState.danceInput(.stomp)
        break
      }
      gameState.danceInput(expected)
    }
    #expect(gameState.duelState == .phraseResult(success: false))
    #expect(gameState.banked == 3)
  }

  /// Echo correct moves until the freeze slot is the current one (the moment the
  /// hint would pop), without consuming the freeze itself.
  private func playUntilFreezeCurrent(_ gameState: GameState) {
    var safety = 0
    while case .playerEcho(let step) = gameState.duelState, safety < 10 {
      safety += 1
      if gameState.phraseSequence[step] == .freeze { return }
      gameState.danceInput(gameState.phraseSequence[step])
    }
  }

  @Test func firstFreezeSlotPopsTheQuietaHintOnce() {
    let gameState = duelReady()
    gameState.banked = 4
    gameState.startPhrase()
    advanceToEcho(gameState)
    playUntilFreezeCurrent(gameState)
    #expect(gameState.jaleoPops.contains { $0.text.contains("¡quieta!") })
    #expect(gameState.didShowFreezeHint)

    // A later freeze phrase relies on memory — no second hint.
    completeEcho(gameState)                                 // finish this phrase
    gameState.jaleoPops.removeAll()
    gameState.banked = 4
    gameState.startPhrase()
    advanceToEcho(gameState)
    playUntilFreezeCurrent(gameState)
    #expect(!gameState.jaleoPops.contains { $0.text.contains("¡quieta!") })
  }

  @Test func waitingOutFreezePassesAndBanks() {
    let gameState = duelReady()
    gameState.banked = 4
    gameState.startPhrase()
    advanceToEcho(gameState)
    completeEcho(gameState)                                 // waits the freeze out
    #expect(gameState.duelState == .phraseResult(success: true))
    #expect(gameState.banked == 5)
  }

  // MARK: Meter-derived rounds & showboats

  @Test func bankedTwoTriggersShowboatAndRoundTwoLength() {
    let gameState = duelReady()
    gameState.banked = 1
    gameState.startPhrase()
    #expect(gameState.phraseSequence.count == 3)            // still round 1
    advanceToEcho(gameState)
    completeEcho(gameState)
    #expect(gameState.banked == 2)
    gameState.updateBoss(dt: CGFloat(GameState.phraseResultHold) + 0.05)
    #expect(gameState.duelState == .showboat)               // between-round strut
    gameState.updateBoss(dt: CGFloat(GameState.showboatDuration) + 0.05)
    #expect(gameState.duelState == .bullDemo(step: 0))
    #expect(gameState.phraseSequence.count == 4)            // round 2 length
    #expect(gameState.demoStepDuration == GameState.demoStepDurations[1])
  }

  @Test func bankedFourTriggersShowboatIntoRoundThree() {
    let gameState = duelReady()
    gameState.banked = 3
    gameState.startPhrase()
    advanceToEcho(gameState)
    completeEcho(gameState)
    #expect(gameState.banked == 4)
    gameState.updateBoss(dt: CGFloat(GameState.phraseResultHold) + 0.05)
    #expect(gameState.duelState == .showboat)
    gameState.updateBoss(dt: CGFloat(GameState.showboatDuration) + 0.05)
    #expect(gameState.phraseSequence.count == 5)            // round 3 length
  }

  // MARK: Victory & end scene

  @Test func bankedSixWinsThenEndSceneSlidesTheMatador() {
    let gameState = duelReady()
    gameState.banked = 5
    gameState.score = 0
    gameState.startPhrase()
    advanceToEcho(gameState)
    let moveCount = gameState.phraseSequence.count
    completeEcho(gameState)
    #expect(gameState.banked == 6)
    gameState.updateBoss(dt: CGFloat(GameState.phraseResultHold) + 0.05)
    #expect(gameState.phase == .victory)
    #expect(gameState.bullAction == .bow)
    // +50 × moves (incl. the survived freeze), +200 × round 3, +2,000 clear.
    let expected = moveCount * GameState.movePoints + GameState.phraseBonus * 3 + GameState.bossClearBonus
    #expect(gameState.score == expected)

    gameState.updateBoss(dt: CGFloat(GameState.victoryHold) + 0.05)
    #expect(gameState.phase == .endScene)
    #expect(gameState.bullAction == .bow)                   // bow held through the scene

    // The matador holds a beat, then slides from his pedestal to the dancer's side.
    let slideEnd = GameState.matadorSlideDelay + GameState.matadorSlideDuration
    var safety = 0
    while gameState.endSceneTime < slideEnd + 0.2 && safety < 100 {
      safety += 1
      gameState.updateBoss(dt: 0.1)
    }
    #expect(abs(gameState.bullfighterX - (gameState.dancerStageX + 36)) < 0.5)
    #expect(gameState.endSceneBurstDone)
    // The reunion burst spawns a fan of hearts and roses over the pair.
    #expect(gameState.jaleoPops.filter { $0.text == "❤️" || $0.text == "🌹" }.count >= 3)
  }

  @Test func victoryTapSkipsToEndScene() {
    let gameState = duelReady()
    gameState.banked = 5
    gameState.startPhrase()
    advanceToEcho(gameState)
    completeEcho(gameState)
    gameState.updateBoss(dt: CGFloat(GameState.phraseResultHold) + 0.05)
    #expect(gameState.phase == .victory)
    gameState.handleBossTap()
    #expect(gameState.phase == .endScene)
  }

  @Test func bowHoldsItsFinalFrame() {
    let gameState = duelReady()
    gameState.banked = 5
    gameState.startPhrase()
    advanceToEcho(gameState)
    completeEcho(gameState)
    gameState.updateBoss(dt: CGFloat(GameState.phraseResultHold) + 0.05)
    let bowFrames = GameState.bullFrameCounts[.bow] ?? 1
    // Through victory and the pre-reunion end scene the bow holds its final frame
    // (30 × 0.1 s stays under the matador's arrival, after which the freed bull breaks
    // into its celebratory dance loop — no longer a held bow).
    for _ in 0..<30 {
      gameState.updateBoss(dt: 0.1)
      #expect(gameState.bullFrame <= bowFrames)
    }
    #expect(gameState.bullFrame == bowFrames)               // held, not wrapping
  }

  // MARK: End-scene slideshow

  /// A GameState in the end scene, ticked until the reunion burst has just fired (the
  /// frame that arms the slideshow).
  private func reunited() -> GameState {
    let gameState = configured()
    gameState.bossRNG = SplitMix64(seed: 7)
    gameState.debugJumpToEndScene()
    var safety = 0
    while !gameState.endSceneBurstDone && safety < 1_000 {
      safety += 1
      gameState.updateBoss(dt: 0.05)
    }
    return gameState
  }

  /// Tick the boss loop for `seconds` in small steps.
  private func run(_ gameState: GameState, seconds: Double, step: Double = 0.05) {
    for _ in 0..<Int((seconds / step).rounded()) {
      gameState.updateBoss(dt: CGFloat(step))
    }
  }

  /// Run the current slide's hold out and its wipe to completion.
  private func advanceOneSlide(_ gameState: GameState) {
    run(gameState, seconds: GameState.endSceneHold(for: gameState.endSceneSlide) + 0.05)
    run(gameState, seconds: GameState.endSceneIrisDuration + 0.05)
  }

  /// When each camera move starts and ends, seconds after a portrait's wipe finished.
  private static let pushInEnd = GameState.endSceneWideHold + GameState.endScenePushInDuration
  private static let panStart = pushInEnd + GameState.endSceneFirstDwell
  private static let middleArrival = panStart + GameState.endScenePanLegDuration
  private static let secondPanStart = middleArrival + GameState.endSceneMiddleDwell
  private static let panEnd = secondPanStart + GameState.endScenePanLegDuration

  @Test func slideshowWaitsForTheReunionBurst() {
    let gameState = configured()
    gameState.debugJumpToEndScene()
    // Just short of the matador's arrival: the burst hasn't fired, so no cycle yet.
    run(gameState, seconds: GameState.matadorSlideDelay + GameState.matadorSlideDuration - 0.2)
    #expect(!gameState.endSceneBurstDone)
    #expect(gameState.endSceneSlide == .live)
    #expect(gameState.endSceneIncomingSlide == nil)
    #expect(gameState.endSceneSlideTime == 0)
  }

  @Test func burstPlusHoldStartsTheWipeToLosToreros() {
    let gameState = reunited()
    #expect(gameState.endSceneSlideTime == 0)
    run(gameState, seconds: GameState.endSceneLiveHold - 0.2)
    #expect(gameState.endSceneIncomingSlide == nil)
    run(gameState, seconds: 0.3)
    #expect(gameState.endSceneSlide == .live)
    #expect(gameState.endSceneIncomingSlide == .toreros)
    #expect(gameState.isEndSceneImageUp)
  }

  @Test func wipeCompletesAfterTheIrisDuration() {
    let gameState = reunited()
    run(gameState, seconds: GameState.endSceneLiveHold + 0.05)
    #expect(gameState.endSceneIncomingSlide == .toreros)
    run(gameState, seconds: GameState.endSceneIrisDuration / 2)
    #expect(gameState.endSceneIrisProgress > 0.3 && gameState.endSceneIrisProgress < 0.7)
    #expect(gameState.endSceneOverlayOpacity > 0 && gameState.endSceneOverlayOpacity < 1)
    run(gameState, seconds: GameState.endSceneIrisDuration / 2 + 0.05)
    #expect(gameState.endSceneSlide == .toreros)
    #expect(gameState.endSceneIncomingSlide == nil)
    #expect(gameState.endSceneIrisProgress == 0)
    #expect(gameState.endSceneOverlayOpacity == 0)
    #expect(gameState.endSceneSlideTime < 0.2)
  }

  @Test func crossfadeUsesTheShorterDuration() {
    let gameState = reunited()
    gameState.endSceneCrossfade = true
    run(gameState, seconds: GameState.endSceneLiveHold + 0.05)
    run(gameState, seconds: GameState.endSceneCrossfadeDuration + 0.05)
    #expect(gameState.endSceneSlide == .toreros)
    #expect(gameState.endSceneIncomingSlide == nil)
  }

  @Test func slidesCycleLiveTorerosFamiliaLive() {
    let gameState = reunited()
    var seen: [EndSceneSlide] = [gameState.endSceneSlide]
    for _ in 0..<4 {
      advanceOneSlide(gameState)
      seen.append(gameState.endSceneSlide)
    }
    #expect(seen == [.live, .toreros, .familia, .live, .toreros])
    #expect(EndSceneSlide.allCases.map(\.next) == [.toreros, .familia, .live])
  }

  @Test func portraitsHoldForTheirWholeCameraMove() {
    #expect(GameState.endSceneImageHold == Self.panEnd + GameState.endSceneLastDwell)
    let gameState = reunited()
    advanceOneSlide(gameState)                              // on Los toreros
    run(gameState, seconds: GameState.endSceneImageHold - 0.2)
    #expect(gameState.endSceneIncomingSlide == nil)         // longer than the live 5 s
    run(gameState, seconds: 0.3)
    #expect(gameState.endSceneIncomingSlide == .familia)
  }

  @Test(arguments: [EndSceneSlide.toreros, .familia])
  func kenBurnsCameraFollowsTheTimeline(slide: EndSceneSlide) throws {
    let subjects = try #require(slide.subjectFocusX)
    let framing = { GameState.endSceneFraming(slide, at: $0) }
    #expect(subjects.left < subjects.middle && subjects.middle < subjects.right)
    #expect(framing(0) == .wide)
    #expect(framing(GameState.endSceneWideHold - 0.01) == .wide)

    let midPushIn = framing(GameState.endSceneWideHold + GameState.endScenePushInDuration / 2)
    #expect(midPushIn.zoom > 0.3 && midPushIn.zoom < 0.7)   // zooming and panning together
    #expect(midPushIn.focusX < 0.5 && midPushIn.focusX > subjects.left)

    let onFirst = EndSceneFraming(zoom: 1, focusX: subjects.left)
    #expect(framing(Self.pushInEnd) == onFirst)
    #expect(framing(Self.panStart) == onFirst)              // the dwell

    let midFirstLeg = framing(Self.panStart + GameState.endScenePanLegDuration / 2)
    #expect(midFirstLeg.zoom == 1)
    #expect(midFirstLeg.focusX > subjects.left && midFirstLeg.focusX < subjects.middle)

    // The camera rests on the animal for a full second.
    let onMiddle = EndSceneFraming(zoom: 1, focusX: subjects.middle)
    #expect(framing(Self.middleArrival) == onMiddle)
    #expect(framing(Self.middleArrival + GameState.endSceneMiddleDwell / 2) == onMiddle)
    #expect(framing(Self.secondPanStart) == onMiddle)
    #expect(GameState.endSceneMiddleDwell == 1)

    let midSecondLeg = framing(Self.secondPanStart + GameState.endScenePanLegDuration / 2)
    #expect(midSecondLeg.focusX > subjects.middle && midSecondLeg.focusX < subjects.right)

    let onSecond = EndSceneFraming(zoom: 1, focusX: subjects.right)
    #expect(framing(Self.panEnd) == onSecond)
    #expect(framing(GameState.endSceneImageHold + 1) == onSecond)   // held through the wipe
  }

  @Test func theLiveSceneHasNoCamera() {
    #expect(EndSceneSlide.live.subjectFocusX == nil)
    #expect(GameState.endSceneFraming(.live, at: 3) == .wide)
    #expect(GameState.endSceneStillShots(.live, at: 3).isEmpty)
    #expect(reunited().endSceneShots(for: .live).isEmpty)
    #expect(reunited().endSceneCaptionBoldness(for: .live).isEmpty)
  }

  @Test(arguments: [EndSceneSlide.toreros, .familia])
  func reduceMotionShowsTheWideShotAndEachSubjectAsStills(slide: EndSceneSlide) throws {
    let subjects = try #require(slide.subjectFocusX)
    let shots = { GameState.endSceneStillShots(slide, at: $0) }
    let stills = [EndSceneFraming.wide] + [subjects.left, subjects.middle, subjects.right].map {
      EndSceneFraming(zoom: 1, focusX: $0)
    }
    let cuts = GameState.endSceneStillCuts
    #expect(cuts == [2.25, 4.5, 6.75])                      // four stills share the 9 s

    #expect(shots(0) == [EndSceneShot(framing: stills[0], opacity: 1)])
    for (index, cut) in cuts.enumerated() {
      #expect(shots(cut - 0.3) == [EndSceneShot(framing: stills[index], opacity: 1)])
      // Halfway through each crossfade, the next still is half up over the last one.
      let mid = shots(cut)
      #expect(mid.map(\.framing) == [stills[index], stills[index + 1]])
      #expect(abs(mid[1].opacity - 0.5) < 0.001)
      #expect(shots(cut + 0.3) == [EndSceneShot(framing: stills[index + 1], opacity: 1)])
    }
    #expect(shots(GameState.endSceneImageHold) == [EndSceneShot(framing: stills[3], opacity: 1)])
  }

  @Test(arguments: [EndSceneSlide.toreros, .familia], [false, true])
  func captionBoldnessHandsOffAcrossTheSubjects(slide: EndSceneSlide, stills: Bool) throws {
    let handoffs = try #require(GameState.endSceneCaptionHandoffs(slide, stills: stills))
    let boldness = { GameState.endSceneCaptionBoldness(slide, at: $0, stills: stills) }
    let fade = GameState.endSceneCaptionFadeDuration
    // Far enough apart that the middle name reaches full bold between them.
    #expect(handoffs.second - handoffs.first >= fade)

    #expect(boldness(0) == [1, 0, 0])                       // the left name, from the wide shot
    #expect(boldness(handoffs.first - fade / 2) == [1, 0, 0])
    let firstHalf = boldness(handoffs.first)
    #expect(abs(firstHalf[0] - 0.5) < 0.001 && abs(firstHalf[1] - 0.5) < 0.001 && firstHalf[2] == 0)
    let quarter = boldness(handoffs.first - fade / 4)
    #expect(abs(quarter[0] - 0.75) < 0.001)                 // a linear trade over one second
    let secondHalf = boldness(handoffs.second)
    #expect(secondHalf[0] == 0 && abs(secondHalf[1] - 0.5) < 0.001 && abs(secondHalf[2] - 0.5) < 0.001)
    #expect(boldness(handoffs.second + fade / 2) == [0, 0, 1])
    #expect(boldness(GameState.endSceneImageHold) == [0, 0, 1])
    for step in 0...80 {
      #expect(abs(boldness(Double(step) * 0.1).reduce(0, +) - 1) < 0.001)
    }
  }

  @Test(arguments: [EndSceneSlide.toreros, .familia])
  func kenBurnsHandoffsLandHalfwayBetweenSubjects(slide: EndSceneSlide) throws {
    let subjects = try #require(slide.subjectFocusX)
    let handoffs = try #require(GameState.endSceneCaptionHandoffs(slide, stills: false))
    let focus = { GameState.endSceneFraming(slide, at: $0).focusX }
    #expect(handoffs.first > Self.panStart && handoffs.first < Self.middleArrival)
    #expect(handoffs.second > Self.secondPanStart && handoffs.second < Self.panEnd)
    #expect(abs(focus(handoffs.first) - (subjects.left + subjects.middle) / 2) < 0.001)
    #expect(abs(focus(handoffs.second) - (subjects.middle + subjects.right) / 2) < 0.001)
    // With the stills, the bold changes on the cuts onto the middle and right subjects.
    let stillHandoffs = try #require(GameState.endSceneCaptionHandoffs(slide, stills: true))
    #expect(stillHandoffs.first == GameState.endSceneStillCuts[1])
    #expect(stillHandoffs.second == GameState.endSceneStillCuts[2])
  }

  @Test func eachSubjectHasItsOwnSound() {
    #expect(EndSceneSlide.live.subjectCalls.isEmpty)
    #expect(EndSceneSlide.toreros.subjectCalls.map(\.sound) == [.castanetPortrait, .moo, .ole])
    #expect(EndSceneSlide.familia.subjectCalls.map(\.sound) == [.castanetPortrait, .neigh, .ole])
  }

  @Test(arguments: [EndSceneSlide.toreros, .familia], [false, true])
  func callTimesFollowTheCamera(slide: EndSceneSlide, stills: Bool) throws {
    let handoffs = try #require(GameState.endSceneCaptionHandoffs(slide, stills: stills))
    let times = GameState.endSceneCallTimes(slide, stills: stills)
    let first = stills ? GameState.endSceneStillCuts[0]
      : GameState.endSceneWideHold + GameState.endScenePushInDuration / 2
    #expect(times == [first, handoffs.first, handoffs.second])
    #expect(GameState.endSceneCallTimes(.live, stills: stills).isEmpty)
  }

  @Test func subjectSoundsPlayOncePerShowing() throws {
    let gameState = reunited()
    advanceOneSlide(gameState)                              // on Los toreros
    #expect(gameState.endSceneCallsPlayed == 0)             // the wide shot is quiet
    let times = GameState.endSceneCallTimes(.toreros, stills: false)
    for (index, time) in times.enumerated() {
      run(gameState, seconds: time - gameState.endSceneSlideTime - 0.1)
      #expect(gameState.endSceneCallsPlayed == index)
      run(gameState, seconds: 0.2)
      #expect(gameState.endSceneCallsPlayed == index + 1)
    }
    run(gameState, seconds: GameState.endSceneImageHold - gameState.endSceneSlideTime + 0.05)
    #expect(gameState.endSceneCallsPlayed == 3)             // no repeats before the wipe
    run(gameState, seconds: GameState.endSceneIrisDuration + 0.05)
    #expect(gameState.endSceneSlide == .familia)
    #expect(gameState.endSceneCallsPlayed == 0)             // a fresh set for La familia
  }

  @Test func shotsFollowTheSlideClockAndTheReduceMotionSetting() {
    let gameState = reunited()
    run(gameState, seconds: GameState.endSceneLiveHold + 0.05)
    // Mid-wipe, the incoming portrait opens on the wide shot, its first name bold.
    #expect(gameState.endSceneShots(for: .toreros) == [EndSceneShot(framing: .wide, opacity: 1)])
    #expect(gameState.endSceneCaptionBoldness(for: .toreros) == [1, 0, 0])
    run(gameState, seconds: GameState.endSceneIrisDuration + 0.05)
    run(gameState, seconds: Self.panStart + GameState.endScenePanLegDuration / 2)
    let moving = gameState.endSceneShots(for: .toreros)
    #expect(moving.count == 1)
    #expect(moving[0].framing == GameState.endSceneFraming(.toreros, at: gameState.endSceneSlideTime))
    gameState.endSceneCrossfade = true
    #expect(gameState.endSceneShots(for: .toreros) ==
      GameState.endSceneStillShots(.toreros, at: gameState.endSceneSlideTime))
  }

  @Test func debugJumpAndResetClearTheSlideshow() {
    let gameState = reunited()
    advanceOneSlide(gameState)
    run(gameState, seconds: 2)
    gameState.endSceneIncomingSlide = .familia
    gameState.endSceneIrisProgress = 0.5
    gameState.reset()
    expectSlideshowCleared(gameState)

    // Dirty it again from the climb, then take the debug jump.
    gameState.endSceneSlide = .familia
    gameState.endSceneIncomingSlide = .live
    gameState.endSceneIrisProgress = 0.4
    gameState.endSceneSlideTime = 2
    gameState.endSceneCallsPlayed = 2
    gameState.debugJumpToEndScene()
    #expect(gameState.phase == .endScene)
    expectSlideshowCleared(gameState)
  }

  private func expectSlideshowCleared(_ gameState: GameState) {
    #expect(gameState.endSceneSlide == .live)
    #expect(gameState.endSceneIncomingSlide == nil)
    #expect(gameState.endSceneIrisProgress == 0)
    #expect(gameState.endSceneSlideTime == 0)
    #expect(gameState.endSceneCallsPlayed == 0)
  }

  // MARK: Input gating & reset

  @Test func danceInputIgnoredOutsideEcho() {
    let gameState = duelReady()
    #expect(gameState.duelState == .bullDemo(step: 0))      // demo: input locked
    let scoreBefore = gameState.score
    gameState.danceInput(.stomp)
    #expect(gameState.duelState == .bullDemo(step: 0))
    #expect(gameState.score == scoreBefore)
    #expect(gameState.banked == 0)
  }

  @Test func resetRestoresTheClimb() {
    let gameState = duelReady()
    gameState.banked = 3
    gameState.health = 1
    gameState.spawnJaleo("¡Olé!", x: 0, y: 0)
    gameState.reset()
    #expect(gameState.phase == .climb)                      // hearts re-shown off this
    #expect(gameState.health == GameState.maxHealth)
    #expect(gameState.banked == 0)
    #expect(gameState.bossTransition == 0)
    #expect(gameState.jaleoPops.isEmpty)
    #expect(gameState.playerLevel == 0)
    #expect(gameState.bullfighterX == gameState.bullfighterHomeX)
    #expect(gameState.bullfighterY == gameState.bullfighterHomeY)
  }

  @Test func climbTickIsUntouchedByBossMachinery() {
    let gameState = configured()
    #expect(gameState.phase == .climb)
    tick(gameState, seconds: 0.5)
    #expect(gameState.phase == .climb)
    #expect(gameState.bossTransition == 0)
    #expect(gameState.playerGrounded)                       // physics ran normally
  }
}
