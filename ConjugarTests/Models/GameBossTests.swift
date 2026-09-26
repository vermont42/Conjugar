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
    run(gameState, seconds: GameState.endSceneSlideHold + 0.05)
    run(gameState, seconds: GameState.endSceneIrisDuration + 0.05)
  }

  @Test func slideshowWaitsForTheReunionBurst() {
    let gameState = configured()
    gameState.debugJumpToEndScene()
    // Just short of the matador's arrival: the burst hasn't fired, so no cycle yet.
    run(gameState, seconds: GameState.matadorSlideDelay + GameState.matadorSlideDuration - 0.2)
    #expect(!gameState.endSceneBurstDone)
    #expect(gameState.endSceneSlide == .live)
    #expect(gameState.endSceneIncomingSlide == nil)
    #expect(gameState.endSceneSlideHold == 0)
  }

  @Test func burstPlusHoldStartsTheWipeToLosToreros() {
    let gameState = reunited()
    #expect(gameState.endSceneSlideHold == GameState.endSceneSlideHold)
    run(gameState, seconds: GameState.endSceneSlideHold - 0.2)
    #expect(gameState.endSceneIncomingSlide == nil)
    run(gameState, seconds: 0.3)
    #expect(gameState.endSceneSlide == .live)
    #expect(gameState.endSceneIncomingSlide == .toreros)
    #expect(gameState.isEndSceneImageUp)
  }

  @Test func wipeCompletesAfterTheIrisDuration() {
    let gameState = reunited()
    run(gameState, seconds: GameState.endSceneSlideHold + 0.05)
    #expect(gameState.endSceneIncomingSlide == .toreros)
    run(gameState, seconds: GameState.endSceneIrisDuration / 2)
    #expect(gameState.endSceneIrisProgress > 0.3 && gameState.endSceneIrisProgress < 0.7)
    #expect(gameState.endSceneOverlayOpacity > 0 && gameState.endSceneOverlayOpacity < 1)
    run(gameState, seconds: GameState.endSceneIrisDuration / 2 + 0.05)
    #expect(gameState.endSceneSlide == .toreros)
    #expect(gameState.endSceneIncomingSlide == nil)
    #expect(gameState.endSceneIrisProgress == 0)
    #expect(gameState.endSceneOverlayOpacity == 0)
    #expect(gameState.endSceneSlideHold > GameState.endSceneSlideHold - 0.2)
  }

  @Test func crossfadeUsesTheShorterDuration() {
    let gameState = reunited()
    gameState.endSceneCrossfade = true
    run(gameState, seconds: GameState.endSceneSlideHold + 0.05)
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

  @Test func dragPausesTheHoldAndItsEndRestartsIt() {
    let gameState = reunited()
    advanceOneSlide(gameState)                              // on Los toreros
    run(gameState, seconds: 3)
    let held = gameState.endSceneSlideHold
    gameState.beginEndSceneDrag()
    run(gameState, seconds: GameState.endSceneSlideHold * 2)
    #expect(gameState.endSceneSlideHold == held)            // paused, however long
    #expect(gameState.endSceneIncomingSlide == nil)
    gameState.endEndSceneDrag()
    #expect(!gameState.endSceneDragActive)
    #expect(gameState.endSceneSlideHold == GameState.endSceneSlideHold)
    run(gameState, seconds: GameState.endSceneSlideHold - 0.2)
    #expect(gameState.endSceneIncomingSlide == nil)         // the full 5 s again
    run(gameState, seconds: 0.3)
    #expect(gameState.endSceneIncomingSlide == .familia)
  }

  @Test func toastShowsOnImagesUntilTheFirstDrag() {
    let gameState = reunited()
    #expect(gameState.endSceneToastTime == 0)               // not on the live scene
    advanceOneSlide(gameState)                              // Los toreros opens
    #expect(gameState.endSceneToastTime > GameState.endSceneToastDuration - 0.2)
    run(gameState, seconds: GameState.endSceneToastDuration + 0.05)
    #expect(gameState.endSceneToastTime == 0)               // faded on its own
    gameState.beginEndSceneDrag()
    gameState.endEndSceneDrag()
    #expect(gameState.endSceneHasDragged)
    advanceOneSlide(gameState)                              // La familia opens
    #expect(gameState.endSceneSlide == .familia)
    #expect(gameState.endSceneToastTime == 0)               // retired for the session
  }

  @Test func dragRetiresAShowingToast() {
    let gameState = reunited()
    advanceOneSlide(gameState)
    #expect(gameState.endSceneToastTime > 0)
    gameState.beginEndSceneDrag()
    #expect(gameState.endSceneToastTime == 0)
  }

  @Test func debugJumpAndResetClearTheSlideshow() {
    let gameState = reunited()
    advanceOneSlide(gameState)
    gameState.beginEndSceneDrag()
    run(gameState, seconds: 0.5)
    gameState.endSceneIncomingSlide = .familia
    gameState.endSceneIrisProgress = 0.5
    gameState.endSceneToastTime = 1
    gameState.reset()
    expectSlideshowCleared(gameState)

    // Dirty it again from the climb, then take the debug jump.
    gameState.endSceneSlide = .familia
    gameState.endSceneIncomingSlide = .live
    gameState.endSceneIrisProgress = 0.4
    gameState.endSceneSlideHold = 2
    gameState.endSceneDragActive = true
    gameState.endSceneHasDragged = true
    gameState.endSceneToastTime = 1
    gameState.debugJumpToEndScene()
    #expect(gameState.phase == .endScene)
    expectSlideshowCleared(gameState)
  }

  private func expectSlideshowCleared(_ gameState: GameState) {
    #expect(gameState.endSceneSlide == .live)
    #expect(gameState.endSceneIncomingSlide == nil)
    #expect(gameState.endSceneIrisProgress == 0)
    #expect(gameState.endSceneSlideHold == 0)
    #expect(!gameState.endSceneDragActive)
    #expect(!gameState.endSceneHasDragged)
    #expect(gameState.endSceneToastTime == 0)
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
