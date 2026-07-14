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
    gameState.flags.append(
      Flag(id: 1, x: 0, y: 0, velocityX: 0, velocityY: 0, falling: false, level: 0, emoji: "🏳️", rotation: 0)
    )
    gameState.playerX = gameState.bullX
    gameState.playerY = gameState.bullY
    gameState.checkReachedBull()
    #expect(gameState.summitCount == 1)
    #expect(gameState.phase == .bossIntro)
    #expect(gameState.flags.isEmpty)          // field cleared for the stage
    #expect(gameState.capedRemaining == 0)
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

  @Test func endSceneHintIsWithheldThenShown() {
    let gameState = duelReady()
    gameState.banked = 5
    gameState.startPhrase()
    advanceToEcho(gameState)
    completeEcho(gameState)
    gameState.updateBoss(dt: CGFloat(GameState.phraseResultHold) + 0.05)
    gameState.updateBoss(dt: CGFloat(GameState.victoryHold) + 0.05)
    #expect(gameState.phase == .endScene)
    #expect(!gameState.showEndSceneHint)                    // withheld at first
    // The matador holds his beat, walks over — the slide finishes before the hint
    // is due, so it is still hidden mid-walk (the delay is intentionally short).
    gameState.updateBoss(dt: GameState.endSceneHintDelay + 0.05)
    #expect(gameState.showEndSceneHint)                     // shown once it can read
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
    for _ in 0..<60 {
      gameState.updateBoss(dt: 0.1)
      #expect(gameState.bullFrame <= bowFrames)
    }
    #expect(gameState.bullFrame == bowFrames)               // held, not wrapping
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
