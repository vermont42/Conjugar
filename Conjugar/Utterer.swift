//
//  Utterer.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/15/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import AVFoundation

class Utterer {
  fileprivate static let synth = AVSpeechSynthesizer()
  fileprivate static let rate: Float = 0.5
  fileprivate static let pitchMultiplier: Float = 0.8
  
  static func utter(_ thingToUtter: String) {
    let utterance = AVSpeechUtterance(string: thingToUtter)
    utterance.rate = Utterer.rate
    utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
    utterance.pitchMultiplier = Utterer.pitchMultiplier
    synth.speak(utterance)
    SoundManager.play(.silence) // https://forums.developer.apple.com/thread/23160
  }
}
