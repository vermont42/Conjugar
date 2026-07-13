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
  /// The flamenco loop under the built-in game.
  case gameLoop = "flamencoLoop"
}
