//
//  Music.swift
//  Conjugar
//

// The looping background-music tracks, mirroring `Sound` (the one-shot SFX vocabulary).
// Each raw value is the base name of a bundled mp3; `SoundPlayerReal.startMusic(_:)`
// loads `<rawValue>.mp3`, loops it forever, and cross-fades it in. Source tracks are
// downsampled from their purchased wav to mp3 before bundling so the app stays small
// (a 2-3 min wav is ~25 MB; the same track at 192 kbps mp3 is ~3 MB) — see the "Game
// sound & music" note in docs/blog_notes.md.
enum Music: String {
  /// Flamenco Adventure (Pond5) — the gameplay loop. File name is legacy: the bundled
  /// `flamencoLoop.mp3` holds Flamenco Adventure (a prior placeholder track was
  /// overwritten in place, so the raw value and call sites did not have to change).
  case gameLoop = "flamencoLoop"

  /// Spanish Tension (Pond5) — bed for the future onboarding flow and game-end scene.
  /// NOT wired yet (those scenes don't exist). See the onboarding-music note in CLAUDE.md.
  case onboarding = "spanishTension"

  /// Spanish Guitar Standoff (Pond5) — the future boss-fight loop. NOT wired yet.
  case bossFight = "spanishGuitarStandoff"
}
