//
//  Utterer.swift
//  Conjugar
//
//  Created by Josh Adams on 11/18/15.
//  Copyright © 2015 Josh Adams. All rights reserved.
//

import AVFoundation
import os

nonisolated private let uttererLogger = Logger(subsystem: "com.racecondition.Conjugar", category: "Utterer")

class Utterer {
  private static let synth = AVSpeechSynthesizer()
  private static let rate: Float = 0.5
  private static let pitchMultiplier: Float = 0.8
  // The region-accent source. Injected once at launch via `setup`; defaults to the
  // live settings so `utter` never needs an optional guard.
  private static var settings: Settings = Current.settings

  // The single owner of the shared `AVAudioSession`, configured once at launch.
  // `.ambient` is the deliberate contract for a study app's feedback chirps and
  // spoken forms: mix with the user's music/podcast and respect the silent switch.
  // `SoundPlayer` no longer touches the session, so there is no more
  // last-writer-wins race that silenced other audio.
  static func setup(settings: Settings) {
    Utterer.settings = settings
    configureSession()
    utter("")
  }

  // Extracted from `setup` because the session outlives its configuration: a media-services reset
  // reverts the category to the system-default `.soloAmbient`, and an interruption deactivates the
  // session, with nothing re-establishing either on its own. `.soloAmbient` would also break the
  // contract above by silencing the user's music rather than mixing with it. `SoundPlayerReal`
  // calls this from its recovery path instead of touching the session itself, so this type remains
  // the single owner.
  static func configureSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.ambient)
      try session.setActive(true)
    } catch {
      uttererLogger.error("Could not set audio-session category: \(error.localizedDescription)")
    }
  }

  static func utter(_ thingToUtter: String, locale: String? = nil) {
    let utterance = AVSpeechUtterance(string: thingToUtter)
    utterance.rate = Utterer.rate
    if let locale = locale {
      utterance.voice = AVSpeechSynthesisVoice(language: locale)
    } else {
      utterance.voice = AVSpeechSynthesisVoice(language: "es-" + settings.region.accent)
    }
    utterance.pitchMultiplier = Utterer.pitchMultiplier
    synth.speak(utterance)
    Current.soundPlayer.play(.silence, shouldDebounce: false) // https://forums.developer.apple.com/thread/23160
  }
}
