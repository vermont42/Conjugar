//
//  SoundPlayer.swift
//  Conjugar
//
//  Created by Josh Adams on 11/18/15.
//  Copyright © 2015 Josh Adams. All rights reserved.
//

import AVFoundation

class SoundPlayer {
  private static let soundPlayer = SoundPlayer()
  private var sounds: [String: AVAudioPlayer]
  private static let soundExtension = "mp3"

  private init () {
    sounds = Dictionary()
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback) // was ambient
    } catch let error as NSError {
      print("\(error.localizedDescription)")
    }
  }

  static func play(_ sound: Sound) {
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
  }

  static func playRandomApplause() {
    let applauses: [Sound] = [.applause1, .applause2, .applause3]
    let applauseIndex = Int.random(in: 0 ... (applauses.count - 1))
    SoundPlayer.play(applauses[applauseIndex])
  }
}
