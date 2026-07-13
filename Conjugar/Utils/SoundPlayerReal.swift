//
//  SoundPlayerReal.swift
//  Conjugar
//
//  Ported from Conjuguer (commit 9bb4f3e — the performance commit — plus 270052a's
//  per-sound debounce). The whole point of this file is to never freeze: the first
//  AVAudioPlayer cold-starts the process-wide audio stack (~1.5s) on the main thread,
//  the blocking play() round-trips the audio server (~20-80ms), and mp3 decode is not
//  free — so all three are pushed off the main thread. See the blog debugging story
//  "AI Doomers Are Wrong" for the measurements this design is built around.
//
//  Conjugar difference from Conjuguer: `Utterer` is the single owner of the shared
//  AVAudioSession (configured once as `.ambient`), so setup() here does NOT configure
//  a session — it only warms the stack off-main. `Utterer.setup` must run first.
//

import AVFoundation
import Foundation

class SoundPlayerReal: SoundPlayer {
  private var sounds: [String: AVAudioPlayer] = [:]
  private let soundExtension = "mp3"
  // Last-play instant keyed per sound so each sound's debounce window is independent.
  // A single shared clock was bumped by every (even non-debounced) play, so during
  // active play the frequent non-debounced SFX kept it fresh and any debounced sound
  // was almost always dropped.
  private var instantOfLastPlayBySound: [Sound: TimeInterval] = [:]
  private var musicPlayer: AVAudioPlayer?
  private var savedMusicTime: TimeInterval?
  // The track currently loaded into `musicPlayer`, so `startMusic(_:)` knows whether a
  // request is a resume of the same track (reuse the player, honor the saved playhead)
  // or a switch to a different one (rebuild, drop the stale playhead).
  private var currentMusic: Music?
  private static let musicVolume: Float = 0.4
  private static let musicFadeDuration: TimeInterval = 2.0

  // SFX playback is dispatched here: AVAudioPlayer.play() blocks its caller
  // ~20-80ms (an audio-server round trip), which stuttered the main game loop
  // when sound effects fired. The queue is concurrent so rapid SFX don't serialize
  // behind one blocking play().
  private static let playbackQueue = DispatchQueue(
    label: "com.racecondition.Conjugar.soundPlayback",
    qos: .userInitiated,
    attributes: .concurrent
  )

  // AVAudioPlayer isn't Sendable, but play() is documented safe to call off the
  // main thread, and the player is only configured (volume) on the main actor
  // before dispatch, so handing it to the playback queue is safe. `nonisolated`
  // keeps the box (and its member) out of the module's default main-actor
  // isolation so it can be built/read inside the background Sendable closure.
  private nonisolated struct PlayerBox: @unchecked Sendable {
    let player: AVAudioPlayer
  }

  // Carries pre-decoded players from the background warm-up back to the main actor.
  // AVAudioPlayer isn't Sendable; the players are built off-main and only inserted
  // into `sounds` on the main actor, so the hand-off is safe. `nonisolated` as above.
  private nonisolated struct PreparedSoundsBox: @unchecked Sendable {
    let players: [String: AVAudioPlayer]
  }

  func setup() {
    // No AudioSession.configure() here: `Utterer.setup` owns the shared session and
    // configures it once as `.ambient` (respect the silent switch, mix with the
    // user's music). It must run before this. Instantiating the first AVAudioPlayer
    // cold-starts the process-wide audio stack — measured at ~1.5s on first launch —
    // so doing it synchronously from launch would freeze the app. Warm the stack off
    // the main thread instead; the per-sound lazy load in play(_:) is fast once warm.
    Task.detached(priority: .userInitiated) {
      Self.warmUpAudioStack()
    }
  }

  // Process-wide audio warm-up. Touches only AVFoundation + Bundle (no shared
  // app state), so it is nonisolated and safe to run off the main actor. The
  // throwaway player's init + prepareToPlay does the expensive cold-start.
  nonisolated private static func warmUpAudioStack() {
    guard let url = Bundle.main.url(forResource: Sound.silence.rawValue, withExtension: "mp3") else {
      return
    }
    let warmUpPlayer = try? AVAudioPlayer(contentsOf: url)
    warmUpPlayer?.volume = 0
    warmUpPlayer?.prepareToPlay()
    warmUpPlayer?.play()
  }

  func startMusic(_ music: Music) {
    // (Re)build the player on first start or when switching to a different track. A
    // switch discards any saved playhead — resuming a position only makes sense for the
    // same track (the game pausing and being re-entered), not when moving between, say,
    // an onboarding bed and the gameplay loop.
    if musicPlayer == nil || currentMusic != music {
      musicPlayer?.stop()
      savedMusicTime = nil
      if let url = Bundle.main.url(forResource: music.rawValue, withExtension: soundExtension) {
        musicPlayer = try? AVAudioPlayer(contentsOf: url)
        musicPlayer?.numberOfLoops = -1
      }
      currentMusic = music
    }
    guard let player = musicPlayer else {
      return
    }
    if let saved = savedMusicTime {
      player.currentTime = saved
      savedMusicTime = nil
    } else {
      player.currentTime = player.duration > 0 ? TimeInterval.random(in: 0 ..< player.duration) : 0
    }
    player.volume = 0
    player.play()
    player.setVolume(Self.musicVolume, fadeDuration: Self.musicFadeDuration)
  }

  func stopMusic() {
    if let player = musicPlayer, player.isPlaying {
      savedMusicTime = player.currentTime
    }
    musicPlayer?.stop()
  }

  func warmUpSounds() {
    // Pre-decode + prepare every effect's AVAudioPlayer off the main thread, then
    // hand them back to the main actor, so the first play of each sound never
    // decodes its mp3 on the game loop. Already-loaded sounds are skipped.
    let names = Sound.allCases.map(\.rawValue).filter { sounds[$0] == nil }
    guard !names.isEmpty else {
      return
    }
    let ext = soundExtension
    Self.playbackQueue.async { [weak self] in
      var prepared: [String: AVAudioPlayer] = [:]
      for name in names {
        guard
          let url = Bundle.main.url(forResource: name, withExtension: ext),
          let player = try? AVAudioPlayer(contentsOf: url)
        else {
          continue
        }
        player.prepareToPlay()
        prepared[name] = player
      }
      let box = PreparedSoundsBox(players: prepared)
      Task { @MainActor in
        self?.mergePreparedSounds(box)
      }
    }
  }

  private func mergePreparedSounds(_ box: PreparedSoundsBox) {
    // Don't replace a player that was lazily created (and may be playing) meanwhile.
    for (name, player) in box.players where sounds[name] == nil {
      sounds[name] = player
    }
  }

  func play(_ sound: Sound, shouldDebounce: Bool, volume: Float) {
    // Normally the player is already prepared by warmUpSounds(); this is the lazy
    // fallback for a sound played before the warm-up reached it (decodes its mp3
    // on the calling thread).
    if sounds[sound.rawValue] == nil {
      if let audioURL = Bundle.main.url(forResource: sound.rawValue, withExtension: soundExtension) {
        sounds[sound.rawValue] = try? AVAudioPlayer(contentsOf: audioURL)
        sounds[sound.rawValue]?.prepareToPlay()
      }
    }

    let instantOfCurrentPlay = Date().timeIntervalSince1970
    let minSoundInterval: TimeInterval = 1.0
    let instantOfLastPlay = instantOfLastPlayBySound[sound] ?? 0.0
    if !shouldDebounce || (instantOfCurrentPlay - instantOfLastPlay > minSoundInterval) {
      guard let player = sounds[sound.rawValue] else {
        return
      }
      player.volume = volume
      // Dispatch the blocking play() off the main thread so it doesn't stutter the
      // game loop (see playbackQueue). The player is configured above on the main
      // actor; only the play() round trip runs in the background.
      let box = PlayerBox(player: player)
      Self.playbackQueue.async {
        box.player.play()
      }
      instantOfLastPlayBySound[sound] = instantOfCurrentPlay
    }
  }
}
