//
//  SoundPlayerDummy.swift
//  Conjugar
//
//  The test-world conformer: a no-op so the unit-test and UI-test worlds never touch
//  CoreAudio (matching the LanguageModelService…Real/Dummy convention). A Dummy —
//  passed to fill the slot, never exercised.
//

import Foundation

class SoundPlayerDummy: SoundPlayer {
  func setup() {}
  func play(_ sound: Sound, shouldDebounce: Bool, volume: Float) {}
  func warmUpSounds() {}
  func startMusic(_ music: Music) {}
  func stopMusic() {}
  func stopMusic(fadeDuration: TimeInterval) {}
}
