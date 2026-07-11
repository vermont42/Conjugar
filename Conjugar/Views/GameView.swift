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

  // Real rendered dancer walk sprite (tools/blender → Assets.xcassets/Game).
  // Frames are 109×169 px; the visual overhangs the 44×30 collision box, with
  // the feet aligned to the box's bottom edge via dancerFeetOffset.
  private static let dancerVisualHeight: CGFloat = 56
  private static let dancerVisualWidth: CGFloat = 56 * 109 / 169   // preserve aspect
  private static let dancerFeetOffset: CGFloat = -(56 - GameState.playerHeight) / 2

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
      if gameState.playerAction == .walk {
        // Real rendered walk cycle (dancer_walk_1…6). The sprite is rendered
        // facing left, so mirror it when the player faces right.
        Image("dancer_walk_\(gameState.playerFrame)")
          .resizable()
          .scaledToFit()
          .frame(width: Self.dancerVisualWidth, height: Self.dancerVisualHeight)
          .scaleEffect(x: gameState.playerFacing >= 0 ? -1 : 1, y: 1)
          .offset(y: Self.dancerFeetOffset)
      } else {
        // Placeholder numbered flipbook for the not-yet-rendered actions.
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
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.customYellow)
      Text(verbatim: "\(gameState.bullFrame)")
        .font(.system(size: 32, weight: .bold, design: .monospaced))
        .foregroundStyle(Color.customBackground)
      facingChevron(gameState.bullFacing, tint: Color.customBackground)
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
