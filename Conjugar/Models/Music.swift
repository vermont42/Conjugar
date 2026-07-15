//
//  Music.swift
//  Conjugar
//

// The looping background-music tracks, mirroring `Sound` (the one-shot SFX vocabulary).
// Each raw value is the base name of a bundled mp3; `SoundPlayerReal.startMusic(_:)`
// loads `<rawValue>.mp3`, loops it forever, and cross-fades it in. Source tracks are
// downsampled from their purchased wav to mp3 before bundling so the app stays small
// (a 2-3 min wav is ~25 MB; the same track at 192 kbps mp3 is ~3 MB).
enum Music: String {
  /// Flamenco Adventure (Pond5) — the gameplay loop.
  case gameLoop = "flamencoLoop"

  /// Spanish Tension (Pond5) — used for onboarding and the boss fight's end scene.
  /// See the onboarding-music note in CLAUDE.md.
  case onboarding = "spanishTension"

  /// Spanish Guitar Standoff (Pond5) — the boss-fight loop.
  case bossFight = "spanishGuitarStandoff"

  /// Whether `startMusic` should seek a fresh player to a random playhead. True for the
  /// gameplay loop (a fresh entry point each session keeps the bed from feeling repetitive);
  /// false for the through-composed beds, which must start at 0 rather than mid-phrase.
  var startsAtRandomPosition: Bool {
    switch self {
    case .gameLoop:
      return true
    case .onboarding, .bossFight:
      return false
    }
  }
}
