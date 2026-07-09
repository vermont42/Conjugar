//
//  SoundPlayer.swift
//  Conjugar
//
//  Created by Josh Adams on 11/18/15.
//  Copyright © 2015 Josh Adams. All rights reserved.
//

import AVFoundation
import Foundation
import os

nonisolated private let soundLogger = Logger(subsystem: "com.racecondition.Conjugar", category: "SoundPlayer")

class SoundPlayer {
  private static let soundPlayer = SoundPlayer()
  private var sounds: [String: AVAudioPlayer]
  private static let soundExtension = "mp3"
  /// Minimum gap between two debounced plays.
  private static let minSoundInterval: TimeInterval = 1.0
  private var instantOfLastPlay: TimeInterval = 0.0

  // The shared `AVAudioSession` is owned and configured once at launch by
  // `Utterer.setup` (a single owner, `.ambient` — respect the silent switch and mix
  // with other audio). `SoundPlayer` no longer sets a category, so
  // the last-writer-wins conflict that stopped the user's music is gone.
  private init () {
    sounds = Dictionary()
  }

  /// Play a sound. Pass `shouldDebounce: true` for sounds that can be triggered in
  /// rapid succession (e.g. the sad trombone fired from the browse-search filter,
  /// which SwiftUI re-evaluates several times per keystroke) so only one plays per
  /// `minSoundInterval`; the default `false` preserves the prior immediate behavior.
  static func play(_ sound: Sound, shouldDebounce: Bool = false) {
    let now = Date().timeIntervalSince1970
    if shouldDebounce && now - soundPlayer.instantOfLastPlay <= minSoundInterval {
      return
    }
    if soundPlayer.sounds[sound.rawValue] == nil {
      if let audioUrl = Bundle.main.url(forResource: sound.rawValue, withExtension: soundExtension) {
        do {
          try soundPlayer.sounds[sound.rawValue] = AVAudioPlayer.init(contentsOf: audioUrl)
        } catch {
          soundLogger.error("Could not load sound \(sound.rawValue): \(error.localizedDescription)")
        }
      }
    }
    soundPlayer.sounds[sound.rawValue]?.play()
    soundPlayer.instantOfLastPlay = now
  }

  static func playRandomApplause() {
    if let applause = [Sound.applause1, .applause2, .applause3].randomElement() {
      SoundPlayer.play(applause)
    }
  }

  static func playRandomSadTrombone() {
    if let sadTrombone = [Sound.sadTrombone1, .sadTrombone2, .sadTrombone3, .sadTrombone4].randomElement() {
      SoundPlayer.play(sadTrombone, shouldDebounce: true)
    }
  }
}
