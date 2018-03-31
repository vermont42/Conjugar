//
//  Utterer.swift
//  Conjugar
//
//  Created by Josh Adams on 11/18/15.
//  Copyright © 2015 Josh Adams. All rights reserved.
//

import AVFoundation

class Utterer {
  private static let synth = AVSpeechSynthesizer()
  private static let rate: Float = 0.5
  private static let pitchMultiplier: Float = 0.8
  
  static func setup() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
    }
    catch let error as NSError {
      print("\(error.localizedDescription)")
    }
    utter("")
  }
  
  static func utter(_ thingToUtter: String, locale: String? = nil) {
    let utterance = AVSpeechUtterance(string: thingToUtter)
    utterance.rate = Utterer.rate
    if let locale = locale {
      utterance.voice = AVSpeechSynthesisVoice(language: locale)
    }
    else {
      utterance.voice = AVSpeechSynthesisVoice(language: "es-" + SettingsManager.getRegion().accent)
    }
    utterance.pitchMultiplier = Utterer.pitchMultiplier
    synth.speak(utterance)
    SoundManager.play(.silence) // https://forums.developer.apple.com/thread/23160
  }
}
