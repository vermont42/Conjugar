//
//  SoundPlayer.swift
//  Conjugar
//
//  Created by Josh Adams on 11/18/15.
//  Copyright © 2015 Josh Adams. All rights reserved.
//

// The audio seam. Ported from the sibling app Conjuguer's protocol-injected,
// performance-safe design (commit 9bb4f3e: off-main audio-stack warm-up, off-main
// SFX pre-decode, and a background playback queue that absorbs the blocking
// `play()`; commit 270052a: per-sound debounce clocks). Wired into `World` as
// `Current.soundPlayer` — `SoundPlayerReal` on device/simulator, `SoundPlayerDummy`
// in the test worlds so unit/UI tests never touch CoreAudio.
@MainActor
protocol SoundPlayer {
  func setup()
  func play(_ sound: Sound, shouldDebounce: Bool, volume: Float)
  func warmUpSounds()
  func startMusic(_ music: Music)
  func stopMusic()
}

extension SoundPlayer {
  func play(_ sound: Sound) {
    play(sound, shouldDebounce: true, volume: 1.0)
  }

  func play(_ sound: Sound, shouldDebounce: Bool) {
    play(sound, shouldDebounce: shouldDebounce, volume: 1.0)
  }
}
