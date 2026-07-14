//
//  SoundPlayerTests.swift
//  ConjugarTests
//
//  Verifies the audio DI seam: the unit-test world must inject the no-op
//  `SoundPlayerDummy` so tests never touch CoreAudio (matching the
//  LanguageModelService…Real/Dummy convention), and the Dummy must absorb every
//  protocol call without effect. Swift Testing (never XCTest) per the repo's
//  isolated-deinit landmine; `@MainActor` because `SoundPlayer` is MainActor.
//

import Testing
@testable import Conjugar

@Suite("SoundPlayer")
@MainActor
struct SoundPlayerTests {
  @Test func testWorldInjectsDummy() {
    // World.chooseWorld() selects World.unitTest under the XCTest runtime, so the
    // live Current must carry the silent Dummy — no CoreAudio in the test process.
    #expect(Current.soundPlayer is SoundPlayerDummy)
  }

  @Test func dummyAbsorbsEveryCall() {
    let dummy = SoundPlayerDummy()
    dummy.setup()
    dummy.warmUpSounds()
    dummy.startMusic(.gameLoop)
    dummy.play(.pop, shouldDebounce: false, volume: 1.0)
    dummy.play(.chirp)                       // protocol-extension convenience
    dummy.play(Sound.randomApplause, shouldDebounce: true)
    dummy.stopMusic()
    // Reaching here without a crash (and without audio) is the assertion.
  }

  @Test func soundCoversGameCasesAndRandomHelpers() {
    // The reused game SFX must be present so warmUpSounds()/play(...) can find them.
    let names = Set(Sound.allCases.map(\.rawValue))
    #expect(names.isSuperset(of: ["pop", "chomp", "moo", "shieldActivate", "soccerKick"]))

    #expect([.applause1, .applause2, .applause3].contains(Sound.randomApplause))
    #expect([.sadTrombone1, .sadTrombone2, .sadTrombone3, .sadTrombone4].contains(Sound.randomSadTrombone))
  }
}
