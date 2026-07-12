//
//  GameView.swift
//  Conjugar
//
//  The Donkey-Kong-inspired flamenco/bull game prototype, launched full-screen
//  from the Settings tab. Pure SwiftUI, matching the sibling apps' loop pattern:
//  `GeometryReader → TimelineView(.animation) → ZStack`, with the tick driven by
//  `.onChange(of: timeline.date)`. Platforms/ladders are drawn with SwiftUI
//  primitives in Conjugar's palette; the player and bull are placeholder numbered
//  frames (their current flipbook index) so the animation machinery is visible
//  before any real sprite art exists.
//

import SwiftUI

struct GameView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var gameState = GameState()
  @State private var jumpHeld = false

  private static let dirButtonSize: CGFloat = 40
  private static let jumpButtonSize: CGFloat = 51   // 64 shrunk by 20%

  // Real rendered dancer sprites (tools/blender → Assets.xcassets/Game). Every
  // player action is a rendered flipbook now (idle/walk/climb/jump/cape); the
  // visual overhangs the collision box, feet aligned to its bottom edge via
  // dancerFeetOffset. All actions are held to one visual HEIGHT and given their
  // own rendered aspect ratio (widths differ with limb spread), so the character
  // stays one size with feet aligned as the action changes.
  // Bumped 56 → 57.3 with the cel outline: the Freestyle edge added ~4px to every
  // crop's HEIGHT (169→173) without changing the body's rendered px (the outline is
  // a post-process line outside the mesh bounds), so scaling the taller crop by that
  // same ratio (56 × 173/169) holds the character BODY at its prior on-screen size —
  // consistent with the bull, whose unchanged bullScale likewise keeps its body one
  // size while the outline just adds a thin margin around it.
  private static let dancerVisualHeight: CGFloat = 57.3
  private static let dancerFeetOffset: CGFloat = -(dancerVisualHeight - GameState.playerHeight) / 2

  /// Player actions backed by real rendered sprites (`dancer_<action>_<frame>`).
  /// All five are rendered; the numbered-box fallback stays only as a safety net.
  private static let spriteActions: Set<PlayerAction> = [.idle, .walk, .climb, .jump, .cape]

  /// The asset-name stem for each action: `dancer_<name>_<frame>`.
  private static func actionName(_ action: PlayerAction) -> String {
    switch action {
    case .idle: return "idle"
    case .walk: return "walk"
    case .climb: return "climb"
    case .jump: return "jump"
    case .cape: return "cape"
    }
  }

  /// Displayed width for an action, from its rendered union-crop aspect ratio
  /// (cel + outline pixel dims, all ~173 tall) at the constant `dancerVisualHeight`.
  /// Keeping height fixed and width per-action means `.scaledToFit()` never
  /// letterboxes and the feet stay glued to the frame's bottom edge across actions.
  private static func dancerWidth(_ action: PlayerAction) -> CGFloat {
    let aspect: CGFloat
    switch action {
    case .idle: aspect = 38.0 / 174.0
    case .walk: aspect = 122.0 / 226.0
    case .climb: aspect = 74.0 / 173.0
    case .jump: aspect = 123.0 / 173.0
    case .cape: aspect = 113.0 / 173.0
    }
    return dancerVisualHeight * aspect
  }

  /// Horizontal scale for facing. The renders face LEFT, so mirror (−1) when the
  /// player faces right. Climb is a back-view ladder pose (camera behind the
  /// figure) — left–right symmetric, so never mirror it, or the lean flips.
  private static func dancerMirror(_ action: PlayerAction, facing: CGFloat) -> CGFloat {
    if action == .climb { return 1 }
    return facing >= 0 ? -1 : 1
  }

  // Real rendered bull sprites (`bull_<action>_<frame>`), same visual/collision
  // split as the dancer: the bull is wider than tall (a quadruped), so its visual
  // overhangs the square `bullSize` collision box, feet aligned to the box bottom.
  //
  // Unlike the dancer (all crops the same pixel height → constant on-screen
  // height), the bull's THROW rears the head up, so its union crop is much taller
  // (118 px) than the walk's (97 px). But `render_sprites.py` auto-fits ortho by
  // the bull's constant body LENGTH (every action crops to ~174 px wide), so one
  // render pixel is the SAME world size in every action. We therefore map crop
  // pixels to screen at one constant `bullScale` — width, height, and the feet
  // offset all derived per action from its crop dims. That keeps the body a
  // constant size while the reared head genuinely extends upward on a throw
  // (a fixed on-screen height would instead shrink the body ~18% mid-throw).
  // The cel outline adds a fixed pixel margin to every crop dim; bullScale absorbs
  // it so the body stays one size and the outline is just a thin edge.
  // 2026-07-12: two coupled changes. (1) Bumped the on-screen bull +25% (headroom in
  // the top gap; a bigger bull lets the small-geometry ivory horn + eye read). (2)
  // Re-rendered the bull sprites at --size 512 (was 192): at 192 the ~168 px-wide crop
  // was upscaled ~2.4× to the on-screen ~410 px and the small horn turned to blocky
  // mush. 512 makes the source ≈ the @3x display size, so the horns render crisp — but
  // it needs SMOOTH interpolation (see bullSprite; nearest-neighbor frays the outline
  // into spikes when downscaling) and the DEFAULT --outline-width 2 (at 512, a wider
  // outline makes Freestyle draw hair-like contour spikes). bullScale drops to hold the
  // same on-screen size (137 pt idle width): 512-crop 436 px × 0.314 ≈ 137 pt, the same
  // as the old 168 px × 0.816. VISUAL only — collision is `GameState.bullSize`, and the
  // per-action feet offset re-derives from `bullHeight`, so feet stay planted.
  private static let bullScale: CGFloat = 0.314   // screen pt per render crop px (512-render, +25%)

  /// Union-crop pixel dims (W, H) per action, from `pack_or_rename.sh` (512-render,
  /// cel + ivory-horn accents + outline-width 2).
  private static func bullCrop(_ action: BullAction) -> (w: CGFloat, h: CGFloat) {
    switch action {
    case .idle:  return (436, 230)
    case .walk:  return (452, 248)
    case .throw: return (452, 306)
    }
  }

  /// Bull actions backed by real rendered sprites. The numbered-box fallback in
  /// `bullSprite` stays only as a defensive safety net (all three are covered).
  private static let bullSpriteActions: Set<BullAction> = [.idle, .walk, .throw]

  /// The asset-name stem for each bull action: `bull_<name>_<frame>`.
  private static func bullActionName(_ action: BullAction) -> String {
    switch action {
    case .idle: return "idle"
    case .walk: return "walk"
    case .throw: return "throw"
    }
  }

  private static func bullWidth(_ action: BullAction) -> CGFloat { bullCrop(action).w * bullScale }
  private static func bullHeight(_ action: BullAction) -> CGFloat { bullCrop(action).h * bullScale }

  /// Shift the visual so its bottom edge (the bull's feet — the union crop's lowest
  /// foot sits at the crop bottom) aligns with the collision box bottom, i.e. the
  /// platform. The reared-head throw is taller than the box, so its offset is
  /// negative (nudged up); the shorter walk/idle sit slightly down.
  private static func bullFeetOffset(_ action: BullAction) -> CGFloat {
    -(bullHeight(action) - GameState.bullSize) / 2
  }

  /// Horizontal scale for the bull's facing. Like the player's non-climb actions,
  /// the renders face LEFT, so mirror (−1) when the bull faces right.
  private static func bullMirror(_ facing: CGFloat) -> CGFloat {
    facing >= 0 ? -1 : 1
  }

  var body: some View {
    GeometryReader { geo in
      TimelineView(.animation) { timeline in
        gameField(size: geo.size)
          .onChange(of: timeline.date) { _, now in
            gameState.update(currentTime: now)
          }
      }
      .onAppear { gameState.configure(screenSize: geo.size) }
      .onDisappear { gameState.stopAudio() }
    }
    .background(Color.customBackground.ignoresSafeArea())
  }

  private func gameField(size: CGSize) -> some View {
    ZStack {
      Color.customBackground.ignoresSafeArea()

      ForEach(gameState.platforms) { platform in
        RoundedRectangle(cornerRadius: 3)
          .fill(Color.customRed)
          .frame(width: platform.rect.width, height: platform.rect.height)
          .position(x: platform.rect.midX, y: platform.rect.midY)
      }

      ForEach(gameState.ladders) { ladder in
        ladderView(ladder)
      }

      ForEach(gameState.capes) { cape in
        if !cape.collected {
          Text(GameState.capeEmoji)
            .font(.system(size: 28))
            .position(x: cape.x, y: cape.y)
        }
      }

      ForEach(gameState.flags) { flag in
        Text(flag.emoji)
          .font(.system(size: 28))
          .rotationEffect(.degrees(flag.rotation))
          .position(x: flag.x, y: flag.y)
      }

      Text(GameState.bullfighterEmoji)
        .font(.system(size: 34))
        .position(x: gameState.bullfighterX, y: gameState.bullfighterY)

      bullSprite
      playerSprite

      quitButton
      healthPips
      controls
    }
    .accessibilityIdentifier("game_root")
  }

  // MARK: Sprites

  private var playerSprite: some View {
    ZStack {
      if Self.spriteActions.contains(gameState.playerAction) {
        // Real rendered flipbook for this action (dancer_<action>_<frame>).
        let action = gameState.playerAction
        Image("dancer_\(Self.actionName(action))_\(gameState.playerFrame)")
          .resizable()
          .scaledToFit()
          .frame(width: Self.dancerWidth(action), height: Self.dancerVisualHeight)
          .scaleEffect(x: Self.dancerMirror(action, facing: gameState.playerFacing), y: 1)
          .offset(y: Self.dancerFeetOffset)
      } else {
        // Numbered-box fallback (safety net; unused for the player today).
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.customRed)
        Text(verbatim: "\(gameState.playerFrame)")
          .font(.system(size: 18, weight: .bold, design: .monospaced))
          .foregroundStyle(.white)
        facingChevron(gameState.playerFacing, tint: .white)
      }
      if gameState.isCapeVisible {
        Text(GameState.capeEmoji)
          .font(.system(size: 22))
          .offset(y: -GameState.playerHeight / 2 - 4)
      }
    }
    .frame(width: GameState.playerWidth, height: GameState.playerHeight)
    .position(x: gameState.playerX, y: gameState.playerY)
  }

  private var bullSprite: some View {
    ZStack {
      if Self.bullSpriteActions.contains(gameState.bullAction) {
        // Real rendered flipbook for this action (bull_<action>_<frame>).
        let action = gameState.bullAction
        Image("bull_\(Self.bullActionName(action))_\(gameState.bullFrame)")
          .resizable()
          // Smooth interpolation (like the dancer): the bull is displayed large, so
          // its 512-render sprite must SCALE to the ~410 px @3x display. `.none`
          // (nearest-neighbor) frayed the outline into spikes on that downscale;
          // smooth resampling keeps the cel edges + ivory horn clean.
          .interpolation(.high)
          .scaledToFit()
          .frame(width: Self.bullWidth(action), height: Self.bullHeight(action))
          .scaleEffect(x: Self.bullMirror(gameState.bullFacing), y: 1)
          .offset(y: Self.bullFeetOffset(action))
      } else {
        // Numbered-box fallback (safety net; all three bull actions are covered).
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.customYellow)
        Text(verbatim: "\(gameState.bullFrame)")
          .font(.system(size: 32, weight: .bold, design: .monospaced))
          .foregroundStyle(Color.customBackground)
        facingChevron(gameState.bullFacing, tint: Color.customBackground)
      }
    }
    .frame(width: GameState.bullSize, height: GameState.bullSize)
    .position(x: gameState.bullX, y: gameState.bullY)
  }

  /// A small facing indicator at the top edge — we don't mirror the number (a
  /// mirrored digit looks wrong), so facing is shown with a chevron.
  private func facingChevron(_ facing: CGFloat, tint: Color) -> some View {
    Image(systemName: facing >= 0 ? "arrowtriangle.right.fill" : "arrowtriangle.left.fill")
      .font(.system(size: 10, weight: .bold))
      .foregroundStyle(tint)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: facing >= 0 ? .topTrailing : .topLeading)
      .padding(3)
  }

  private func ladderView(_ ladder: Ladder) -> some View {
    let height = ladder.bottomY - ladder.topY
    let midY = (ladder.topY + ladder.bottomY) / 2
    let width = GameState.ladderWidth
    let rungCount = max(2, Int(height / 18))
    return ZStack {
      HStack {
        Capsule().fill(Color.customBlue).frame(width: 4)
        Spacer()
        Capsule().fill(Color.customBlue).frame(width: 4)
      }
      VStack(spacing: 0) {
        ForEach(0..<rungCount, id: \.self) { _ in
          Rectangle().fill(Color.customBlue).frame(height: 3)
          Spacer(minLength: 0)
        }
      }
    }
    .frame(width: width, height: height)
    .position(x: ladder.x, y: midY)
  }

  // MARK: HUD & controls

  private var quitButton: some View {
    Button { dismiss() } label: {
      Image(systemName: "xmark.circle.fill")
        .font(.system(size: 32))
        .foregroundStyle(Color.customYellow)
        .shadow(radius: 2)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(.leading, Layout.defaultHorizontalMargin)
    .padding(.top, Layout.doubleDefaultSpacing)
    .accessibilityLabel(L.Game.quit)
  }

  private var healthPips: some View {
    HStack(spacing: 6) {
      ForEach(0..<GameState.maxHealth, id: \.self) { index in
        Image(systemName: index < gameState.health ? "heart.fill" : "heart")
          .font(.system(size: 20))
          .foregroundStyle(Color.customRed)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    .padding(.trailing, Layout.defaultHorizontalMargin)
    .padding(.top, Layout.doubleDefaultSpacing)
    .accessibilityLabel(L.Game.health)
  }

  private var controls: some View {
    // D-pad at bottom-leading, jump at the inverse (bottom-trailing) position, with
    // the jump button's center vertically aligned to the D-pad's center. Pushed low
    // (small bottom padding) so the cross clears the field of play.
    HStack(alignment: .center) {
      dPad
      Spacer()
      jumpButton
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .padding(.horizontal, Layout.tripleDefaultSpacing)
    .padding(.bottom, Layout.defaultSpacing)
  }

  private var dPad: some View {
    // Up shows only when the player can start climbing up a ladder; down only when
    // standing directly above one. Absent buttons collapse to an empty slot so the
    // cross layout stays put.
    VStack(spacing: Layout.defaultSpacing / 2) {
      if gameState.canClimbUp {
        directionButton("arrowtriangle.up.fill", label: L.Game.moveUp) { gameState.movingUp = $0 }
      } else {
        dPadSlot
      }
      HStack(spacing: Layout.defaultSpacing / 2) {
        directionButton("arrowtriangle.left.fill", label: L.Game.moveLeft) { gameState.movingLeft = $0 }
        dPadSlot
        directionButton("arrowtriangle.right.fill", label: L.Game.moveRight) { gameState.movingRight = $0 }
      }
      if gameState.canClimbDown {
        directionButton("arrowtriangle.down.fill", label: L.Game.moveDown) { gameState.movingDown = $0 }
      } else {
        dPadSlot
      }
    }
  }

  /// An empty, non-interactive placeholder that keeps the D-pad cross from shifting
  /// when the up/down buttons hide themselves.
  private var dPadSlot: some View {
    Color.clear.frame(width: Self.dirButtonSize, height: Self.dirButtonSize)
  }

  /// Press-and-hold directional button (the Conjuguer idiom): a `DragGesture`
  /// with `minimumDistance: 0` sets the intent boolean on touch-down and clears it
  /// on lift; the game loop reads the boolean each frame.
  private func directionButton(
    _ symbol: String,
    label: String,
    setPressed: @escaping (Bool) -> Void
  ) -> some View {
    Image(systemName: symbol)
      .font(.system(size: 22, weight: .bold))
      .foregroundStyle(Color.customYellow)
      .frame(width: Self.dirButtonSize, height: Self.dirButtonSize)
      .background(Color.customYellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
      .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.customYellow.opacity(0.35), lineWidth: 1))
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in setPressed(true) }
          .onEnded { _ in setPressed(false) }
      )
      .accessibilityLabel(label)
  }

  /// Jump is an impulse, not a held intent: fire once on touch-down, re-arm on lift.
  private var jumpButton: some View {
    Image(systemName: "figure.jump")
      .font(.system(size: 26, weight: .bold))
      .foregroundStyle(Color.customYellow)
      .frame(width: Self.jumpButtonSize, height: Self.jumpButtonSize)
      .background(Color.customRed.opacity(0.18), in: Circle())
      .overlay(Circle().strokeBorder(Color.customYellow, lineWidth: 2))
      .contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            if !jumpHeld {
              jumpHeld = true
              gameState.jump()
            }
          }
          .onEnded { _ in jumpHeld = false }
      )
      .accessibilityLabel(L.Game.jump)
  }
}
