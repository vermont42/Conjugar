//
//  GameState.swift
//  Conjugar
//
//  The @Observable core of the Donkey-Kong-inspired flamenco/bull game prototype.
//  Follows the sibling apps' house pattern (Conjuguer/Konjugieren): a single
//  `@MainActor @Observable final class` holding all state and tuning constants,
//  driven by `TimelineView(.animation)` via `update(currentTime:)`. Entities are
//  value-type structs (see GameModels.swift). Mechanic logic is split across
//  `GameState+Physics`, `GameState+Flags`, and `GameState+Animation`, so any state
//  those extensions touch is declared internal (not private).
//
//  This is a placeholder-art prototype: the player and bull "sprites" are their
//  current animation frame *number*, rendered as text (see GameView). Swapping in
//  real sprite art later is a one-line change — `Text("\(frame)")` → `Image(...)`.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class GameState {
  // MARK: Tuning constants (placeholders — tweak to taste)

  static let levelCount = 6
  static let sideMargin: CGFloat = 8
  static let platformThickness: CGFloat = 14
  static let ladderWidth: CGFloat = 34

  static let playerWidth: CGFloat = 44
  static let playerHeight: CGFloat = 30
  static let bullSize: CGFloat = 70
  static let bullfighterSize: CGFloat = 40
  static let flagSize: CGFloat = 30
  /// Collision size for a flag — deliberately smaller than its drawn box. Flag emoji
  /// sit inside transparent glyph padding, so the full 30 pt box registers "phantom"
  /// hits when a jump has visually cleared the flag. This tighter box makes the rule
  /// honest: if the player's arc doesn't touch the flag, it doesn't cost health.
  static let flagHitSize: CGFloat = 20
  static let capeSize: CGFloat = 34

  static let gravity: CGFloat = 1400
  static let playerSpeed: CGFloat = 150
  static let climbSpeed: CGFloat = 110
  // Jumping is for dodging enemies only — deliberately too weak to reach the
  // next platform up (max hop ≈ jumpImpulse² / 2·gravity, kept below the gap).
  static let jumpImpulse: CGFloat = 360
  static let climbTolerance: CGFloat = 34

  static let flagRollSpeed: CGFloat = 95
  static let flagSpawnInterval: Double = 2.0
  static let bullThrowDuration: Double = 0.5
  static let bullPaceSpeed: CGFloat = 42

  // 5 s solid, then a 2 s expiry blink that ends the power-up (see `isCapeVisible`).
  static let capeDuration: Double = 7
  static let capeBlinkDuration: Double = 2
  static let maxHealth = 4
  static let damageCooldownDuration: Double = 1.0

  /// Placeholder flipbook speed (RaceRunner's rate).
  static let fps = 10

  /// Global time multiplier for the game loop — 1 in normal play. Setting the
  /// `CONJUGAR_GAME_TIME_SCALE` launch environment variable (e.g. `0.1`) slows
  /// the whole simulation down uniformly, so individual animation frames (a
  /// jump's apex, a climb/cape pose) can be caught in a screenshot.
  static let debugTimeScale: CGFloat = {
    if let raw = ProcessInfo.processInfo.environment["CONJUGAR_GAME_TIME_SCALE"],
       let value = Double(raw), value > 0 {
      return CGFloat(value)
    }
    return 1
  }()

  /// When the `CONJUGAR_GAME_DISABLE_FLAGS` launch environment variable is set,
  /// the bull throws no flags — a calmer field for capturing player animations.
  static let debugFlagsDisabled = ProcessInfo.processInfo.environment["CONJUGAR_GAME_DISABLE_FLAGS"] != nil

  static let flagEmojis = [
    "🇪🇸", "🇲🇽", "🇦🇷", "🇨🇴", "🇵🇪", "🇨🇱", "🇻🇪", "🇪🇨", "🇬🇹", "🇨🇺",
    "🇧🇴", "🇩🇴", "🇭🇳", "🇵🇾", "🇸🇻", "🇳🇮", "🇨🇷", "🇺🇾", "🇵🇦"
  ]

  // MARK: World

  var screenSize: CGSize = .zero
  var didConfigure = false
  var platforms: [Platform] = []
  var ladders: [Ladder] = []
  var flags: [Flag] = []
  var capes: [CapePickup] = []
  var flagCounter = 0

  // MARK: Player state

  var playerX: CGFloat = 0
  var playerY: CGFloat = 0
  var playerVelocityY: CGFloat = 0
  var playerGrounded = true
  var playerClimbing = false
  var climbingLadder: Int?
  var playerLevel = 0
  var playerFacing: CGFloat = 1
  var playerPhase: Double = 0
  var playerAction: PlayerAction = .idle

  // Intent booleans set by the on-screen controls, consumed each frame.
  var movingLeft = false
  var movingRight = false
  var movingUp = false
  var movingDown = false

  var capedRemaining: Double = 0
  var health = GameState.maxHealth
  var damageCooldown: Double = 0

  var isCaped: Bool { capedRemaining > 0 }

  /// Whether the cape overlay should be drawn this frame. Gameplay (`isCaped`) stays
  /// true for the whole `capeDuration`; only the *visual* blinks. During the power-up's
  /// final `capeBlinkDuration` seconds it flashes ~5×/s to warn the player it's about
  /// to expire, then "blinks out of existence" when the cape ends.
  var isCapeVisible: Bool {
    guard isCaped else { return false }
    guard capedRemaining <= Self.capeBlinkDuration else { return true }
    return Int(capedRemaining * 10) % 2 == 0
  }

  /// Whether the up control should be shown: the player is standing in front of a
  /// ladder whose base is on this level (so pressing up would start a climb), or is
  /// already climbing. Drives the up button's appearance (per the game2 tweaks).
  var canClimbUp: Bool {
    if playerClimbing { return true }
    guard playerGrounded else { return false }
    return ladders.contains { abs(playerX - $0.x) < Self.climbTolerance && $0.lowerLevel == playerLevel }
  }

  /// Whether the down control should be shown: the player is standing directly above
  /// a ladder whose top is on this level, or is already climbing.
  var canClimbDown: Bool {
    if playerClimbing { return true }
    guard playerGrounded else { return false }
    return ladders.contains { abs(playerX - $0.x) < Self.climbTolerance && $0.upperLevel == playerLevel }
  }

  // MARK: Bull state

  var bullX: CGFloat = 0
  var bullY: CGFloat = 0
  var bullDirection: CGFloat = 1
  var bullFacing: CGFloat = 1
  var bullPhase: Double = 0
  var bullAction: BullAction = .idle
  var bullThrowTimer: Double = 0
  var flagSpawnTimer: Double = GameState.flagSpawnInterval

  var bullfighterX: CGFloat = 0
  var bullfighterY: CGFloat = 0

  // MARK: Loop bookkeeping

  private var lastUpdateTime: Date?

  // MARK: Lifecycle

  /// Build the level geometry from the on-screen size (once) and place entities.
  func configure(screenSize: CGSize) {
    guard !didConfigure, screenSize.width > 0, screenSize.height > 0 else { return }
    self.screenSize = screenSize
    buildLevel()
    reset()
    didConfigure = true
    startAudio()
  }

  // MARK: Audio

  /// Kick off the game's audio at entry: warm every SFX player and the flag/cape
  /// emoji glyphs off the main thread (so the first flag thrown never stalls the
  /// render or audio path — see SoundPlayerReal / GlyphWarmer), then start the
  /// looping flamenco music. Called once from `configure`. The audio-stack itself
  /// was already warmed at app launch by `SoundPlayerReal.setup()`.
  private func startAudio() {
    // Pre-decode every SFX off-main (skips ones already prepared).
    Current.soundPlayer.warmUpSounds()

    // Pre-rasterize the emoji this game rains (flags are the worst first-draw
    // offender) into the process-wide glyph cache, off the main actor. The cape and
    // bullfighter are rendered sprites now, so only the flags remain as emoji.
    let glyphs: [(String, CGFloat)] = Self.flagEmojis.map { ($0, 28) }
    Task.detached(priority: .userInitiated) {
      GlyphWarmer.warm(glyphs)
    }

    Current.soundPlayer.startMusic(.gameLoop)
  }

  /// Stop the looping music. Called from `GameView.onDisappear` when the player
  /// leaves the game (the playhead is saved so a later entry resumes it).
  func stopAudio() {
    Current.soundPlayer.stopMusic()
  }

  private func buildLevel() {
    let w = screenSize.width
    let h = screenSize.height

    // Platforms: level 0 (bottom, player) at ~78% height, level 5 (top, bull) at
    // ~14%, evenly spaced. Beams span the width minus a small side margin.
    let topY = h * 0.16
    let bottomY = h * 0.78
    let spacing = (bottomY - topY) / CGFloat(Self.levelCount - 1)
    let platformWidth = w - 2 * Self.sideMargin
    platforms = (0..<Self.levelCount).map { level in
      let centerY = bottomY - CGFloat(level) * spacing
      let rect = CGRect(
        x: Self.sideMargin,
        y: centerY - Self.platformThickness / 2,
        width: platformWidth,
        height: Self.platformThickness
      )
      return Platform(id: level, level: level, rect: rect)
    }

    // Ladders: one per gap, staggered left/right so the player must traverse each
    // level to reach the next ladder (the Donkey-Kong zig-zag).
    ladders = (0..<(Self.levelCount - 1)).map { gap in
      let x = w * (gap % 2 == 0 ? 0.75 : 0.25)
      return Ladder(
        id: gap,
        lowerLevel: gap,
        upperLevel: gap + 1,
        x: x,
        topY: platforms[gap + 1].surfaceY,
        bottomY: platforms[gap].surfaceY
      )
    }

    // Cape pickups on two mid platforms, away from the ladders.
    capes = [
      CapePickup(id: 0, x: w * 0.4, y: platforms[1].surfaceY - Self.capeSize / 2, collected: false),
      CapePickup(id: 1, x: w * 0.6, y: platforms[3].surfaceY - Self.capeSize / 2, collected: false)
    ]

    // Bullfighter: one static frame beside the bull on the top platform.
    bullfighterX = w * 0.72
    bullfighterY = platforms[Self.levelCount - 1].surfaceY - Self.bullfighterSize / 2
  }

  /// Return the player and bull to their starting state, clear flags, restore all
  /// health, and re-arm the cape pickups. Keeps platforms/ladders geometry.
  func reset() {
    let w = screenSize.width
    let top = Self.levelCount - 1

    playerX = w * 0.15
    playerY = platforms[0].surfaceY - Self.playerHeight / 2
    playerVelocityY = 0
    playerGrounded = true
    playerClimbing = false
    climbingLadder = nil
    playerLevel = 0
    playerFacing = 1
    playerPhase = 0
    playerAction = .idle

    movingLeft = false
    movingRight = false
    movingUp = false
    movingDown = false

    capedRemaining = 0
    health = Self.maxHealth
    damageCooldown = 0

    flags.removeAll()
    flagCounter = 0
    flagSpawnTimer = Self.flagSpawnInterval
    for i in capes.indices { capes[i].collected = false }

    bullX = w * 0.4
    bullY = platforms[top].surfaceY - Self.bullSize / 2
    bullDirection = 1
    bullFacing = 1
    bullPhase = 0
    bullAction = .idle
    bullThrowTimer = 0

    lastUpdateTime = nil
  }

  // MARK: Frame tick

  func update(currentTime: Date) {
    let rawDt: CGFloat
    if let last = lastUpdateTime {
      rawDt = CGFloat(currentTime.timeIntervalSince(last))
    } else {
      rawDt = 0
    }
    lastUpdateTime = currentTime

    // Skip the first frame and any big hitch (returning from background).
    guard didConfigure, rawDt > 0, rawDt < 1 else { return }

    // Clamp so a sub-second hitch isn't applied in one giant step (prevents
    // tunneling through platform/flag collision tests).
    let dt = min(rawDt, 1.0 / 30.0) * Self.debugTimeScale

    if damageCooldown > 0 { damageCooldown = max(0, damageCooldown - Double(dt)) }
    if capedRemaining > 0 { capedRemaining = max(0, capedRemaining - Double(dt)) }

    // The up/down buttons vanish when not at a ladder; if one is removed mid-press
    // its gesture may never fire `.onEnded`, so clear a stranded climb intent here.
    if !canClimbUp { movingUp = false }
    if !canClimbDown { movingDown = false }

    updatePlayer(dt: dt)
    updateBull(dt: dt)
    updateFlags(dt: dt)
    advanceAnimations(dt: dt)
    resolveCollisions()
    checkReachedBull()
  }

  // MARK: Collision helper

  /// Centered-rectangle AABB overlap test.
  func rectsIntersect(
    _ ax: CGFloat, _ ay: CGFloat, _ aw: CGFloat, _ ah: CGFloat,
    _ bx: CGFloat, _ by: CGFloat, _ bw: CGFloat, _ bh: CGFloat
  ) -> Bool {
    abs(ax - bx) < (aw + bw) / 2 && abs(ay - by) < (ah + bh) / 2
  }
}
