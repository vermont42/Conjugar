//
//  SoundPlayer.swift
//  Conjugar
//
//  Created by Josh Adams on 11/18/15.
//  Copyright © 2015 Josh Adams. All rights reserved.
//

import AVFoundation
import Foundation

class SoundPlayer {
  private static let soundPlayer = SoundPlayer()
  private var sounds: [String: AVAudioPlayer]
  private static let soundExtension = "mp3"
  /// Minimum gap between two debounced plays. Mirrors Conjuguer's SoundPlayerReal.
  private static let minSoundInterval: TimeInterval = 1.0
  private var instantOfLastPlay: TimeInterval = 0.0

  private init () {
    sounds = Dictionary()
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback) // was ambient
    } catch let error as NSError {
      print("\(error.localizedDescription)")
    }
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
        } catch let error as NSError {
          print("\(error.localizedDescription)")
        }
      }
    }
    soundPlayer.sounds[sound.rawValue]?.play()
    soundPlayer.instantOfLastPlay = now
  }

  static func playRandomApplause() {
    let applauses: [Sound] = [.applause1, .applause2, .applause3]
    let applauseIndex = Int.random(in: 0 ... (applauses.count - 1))
    SoundPlayer.play(applauses[applauseIndex])
  }

  static func playRandomSadTrombone() {
    let sadTrombones: [Sound] = [.sadTrombone1, .sadTrombone2, .sadTrombone3, .sadTrombone4]
    let sadTromboneIndex = Int.random(in: 0 ... (sadTrombones.count - 1))
    SoundPlayer.play(sadTrombones[sadTromboneIndex], shouldDebounce: true)
  }
}
