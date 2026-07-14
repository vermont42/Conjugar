//
//  Sound.swift
//  Conjugar
//
//  Created by Josh Adams on 4/9/16.
//  Copyright © 2016 Josh Adams. All rights reserved.
//

// `CaseIterable` so `SoundPlayerReal.warmUpSounds()` can pre-decode every effect
// off-main at game start (a case with no bundled mp3 is simply skipped). The game
// cases (`chomp`, `cow`, `pop`, `shieldActivate`, `soccerKick`) were reused from the
// sibling apps Konjugieren/Conjuguer for the flamenco/bull game; the boss-fight pack
// (`castanetHigh`…`capeWhoosh`) is the La Llamada dance-off duel's SFX, sourced from
// Pixabay (see `asset-licenses/pixabay-game-sfx.txt`); the rest are the app's
// original quiz/feedback cues.
enum Sound: String, CaseIterable {
  case applause1
  case applause2
  case applause3
  case buzz
  case chime
  case chirp
  case chomp
  case cow
  case gun
  case pop
  case sadTrombone1
  case sadTrombone2
  case sadTrombone3
  case sadTrombone4
  case shieldActivate
  case silence
  case soccerKick

  // Boss fight — La Llamada dance-off SFX (Pixabay, `Conjugar/Audio/`). The two
  // pasos are one castanet click pitched low/high so left vs right read distinctly.
  case castanetLow
  case castanetHigh
  case palmas
  case crowdOle
  case snort
  case stompThud
  case capeWhoosh
  case tensionSting

  static var randomApplause: Sound {
    [.applause1, .applause2, .applause3].randomElement() ?? .applause1
  }

  static var randomSadTrombone: Sound {
    [.sadTrombone1, .sadTrombone2, .sadTrombone3, .sadTrombone4].randomElement() ?? .sadTrombone1
  }
}
