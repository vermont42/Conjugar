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
  /// Passed in explicitly (cover content does not inherit a custom `.environment`
  /// router — the OnboardingView lesson) so the `conjugar://game/boss` deeplink's
  /// `pendingBossEntry` can be consumed after configure. The Settings-tab Play
  /// button presents `GameView()` with no router; that path never starts at the boss.
  var router: AppRouter?

  @Environment(\.dismiss) private var dismiss
  @State private var gameState = GameState()
  @State private var jumpHeld = false
  /// Touch-down re-arm for the boss dance buttons (the jump idiom, per-move so a
  /// held paso can't fire twice).
  @State private var heldDanceMoves: Set<DanceMove> = []

  private static let dirButtonSize: CGFloat = 40
  private static let jumpButtonSize: CGFloat = 51   // 64 shrunk by 20%
  /// The boss dance pad is one horizontal row of equal circular buttons sitting just
  /// below the tablao floor (design note 2).
  private static let bossMoveButtonSize: CGFloat = 52
  private static let bossRowFloorGap: CGFloat = 52
  /// Top of the phrase-success confetti band (field coordinates) — below the Duende
  /// meter and close button.
  private static let bossSuccessConfettiTop: CGFloat = 72

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
  /// All are rendered; the numbered-box fallback stays only as a safety net. The
  /// boss dance actions ole/stomp now have their own hand-keyed sprites (boss plan
  /// Phase 4, `gen_dancer_action.py`) — no longer reusing cape/jump.
  private static let spriteActions: Set<PlayerAction> = [.idle, .walk, .climb, .jump, .cape, .capeWalk, .ole, .stomp]

  /// The asset-name stem for each action: `dancer_<name>_<frame>`.
  private static func actionName(_ action: PlayerAction) -> String {
    switch action {
    case .idle: return "idle"
    case .walk: return "walk"
    case .climb: return "climb"
    case .jump: return "jump"
    case .cape: return "cape"
    case .capeWalk: return "capeWalk"
    case .ole: return "ole"        // boss desplante (arms-up V + back arch)
    case .stomp: return "stomp"    // boss zapateado (weight drop + braceo)
    }
  }

  /// Displayed width for an action, from its rendered union-crop aspect ratio
  /// (cel + outline pixel dims, all ~226 tall — the full flamenco gown) at the
  /// constant `dancerVisualHeight`. Climb is wider (172) for the arms-raised reach.
  /// Keeping height fixed and width per-action means `.scaledToFit()` never
  /// letterboxes and the feet stay glued to the frame's bottom edge across actions.
  private static func dancerWidth(_ action: PlayerAction) -> CGFloat {
    let aspect: CGFloat
    switch action {
    case .idle: aspect = 104.0 / 225.0
    case .walk: aspect = 122.0 / 226.0
    case .climb: aspect = 172.0 / 228.0
    case .jump: aspect = 116.0 / 226.0     // apex raises the arms (wider than the old rise-dup crop)
    case .cape: aspect = 152.0 / 225.0        // wider: muleta held out in front
    case .capeWalk: aspect = 155.0 / 227.0
    case .ole: aspect = 116.0 / 229.0         // arms-up V (Phase 4 crop)
    case .stomp: aspect = 108.0 / 229.0       // weight drop + braceo (Phase 4 crop)
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

  /// A subtle per-frame vertical "gait bob" for the walk cycles. With no vertical
  /// motion the gliding dancer reads as a ghost. A biped's body really traces a
  /// shallow arc while walking, but the platform gap is too short for a true
  /// parabola (and the feet are glued to the platform), so instead selected frames
  /// of the 6-frame walk are nudged up by `dancerWalkBobHeight`. The lift profile is
  /// indexed by 1-based frame; the current profile is "0 0 0 1 1 1" — frames 1–3 flat,
  /// frames 4–6 raised one unit. (An alternate to try: [0, 1, 0, 1, 0, 1].) Returns a
  /// y offset in points, negative = up. Applies to both the plain and caped walks,
  /// which share the 6-frame leg cadence.
  private static let dancerWalkBobHeight: CGFloat = 1
  private static let dancerWalkBobProfile: [CGFloat] = [0, 0, 0, 1, 1, 1]
  private static func dancerWalkBob(_ action: PlayerAction, frame: Int) -> CGFloat {
    guard action == .walk || action == .capeWalk else { return 0 }
    guard (1...dancerWalkBobProfile.count).contains(frame) else { return 0 }
    return -dancerWalkBobProfile[frame - 1] * dancerWalkBobHeight   // negative = up
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
    case .stomp: return (452, 306)  // hand-keyed (Phase 3): up → head-slam → settle
    case .rear:  return (452, 294)  // hand-keyed (Phase 3): gather → pawing rear → hold
    case .bow:   return (452, 232)  // hand-keyed (Phase 3): dip → kneeling bow → held
    }
  }

  /// Bull actions backed by real rendered sprites. The numbered-box fallback in
  /// `bullSprite` stays only as a defensive safety net (every action is covered).
  /// All six are now hand-keyed/rendered: idle/walk/throw from the base bull plan,
  /// and stomp/rear/bow from boss plan Phase 3 (`gen_bull_action.py`).
  private static let bullSpriteActions: Set<BullAction> = [.idle, .walk, .throw, .stomp, .rear, .bow]

  /// The asset-name stem for each bull action: `bull_<name>_<frame>`.
  private static func bullActionName(_ action: BullAction) -> String {
    switch action {
    case .idle: return "idle"
    case .walk: return "walk"
    case .throw: return "throw"
    case .stomp: return "stomp"
    case .rear: return "rear"
    case .bow: return "bow"
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

  // The matador — the kidnapped bullfighter, a STATIC one-frame goal figure standing
  // beside the bull on the top platform (`Image("matador")`). Same visual/collision
  // split as the dancer and bull: the rendered sprite is taller than the 40pt
  // `bullfighterSize` collision box, so it overhangs upward with its feet (the crop's
  // lowest pixel) aligned to the box bottom — which `GameState` sits on the platform
  // surface. Rendered front-on (`--view back` = the face), hands on hips, so — unlike
  // the dancer/bull side renders — he is NEVER mirrored.
  //
  // Union-crop pixel dims (W, H) from `pack_or_rename.sh` (512-render, --matador cel +
  // outline-width 2). Displayed at a constant visual height, width from the aspect —
  // the same crop-px→pt discipline as the bull; don't guess, re-capture if re-rendered.
  private static let matadorCrop: (w: CGFloat, h: CGFloat) = (188, 452)
  /// A standing man reads a touch taller than the bull's back (bull idle ≈ 72pt tall on
  /// screen), planted beside it. Tuned by eye against the bull in `conjugar://game`.
  private static let matadorVisualHeight: CGFloat = 74
  private static var matadorWidth: CGFloat { matadorVisualHeight * (matadorCrop.w / matadorCrop.h) }
  /// Align the tall sprite's bottom (his shoes) with the collision box bottom (the
  /// platform surface), mirroring `bullFeetOffset` / `dancerFeetOffset`.
  private static let matadorFeetOffset: CGFloat = -(matadorVisualHeight - GameState.bullfighterSize) / 2

  var body: some View {
    GeometryReader { geo in
      TimelineView(.animation) { timeline in
        gameField(size: geo.size)
          .onChange(of: timeline.date) { _, now in
            gameState.update(currentTime: now)
          }
      }
      .onAppear {
        gameState.configure(screenSize: geo.size)
        // The conjugar://game/boss deeplink: consume the one-shot flag after
        // configure and jump straight to the boss intro. `conjugar://game/end`
        // jumps all the way to the end scene.
        if router?.pendingBossEntry == true {
          router?.pendingBossEntry = false
          gameState.enterBossIntro()
        } else if router?.pendingEndScene == true {
          router?.pendingEndScene = false
          gameState.debugJumpToEndScene()
        }
      }
      .onDisappear { gameState.stopAudio() }
    }
    .background(Color.customBackground.ignoresSafeArea())
    // The game is always a night scene (spotlights, flamenco stage): pin its whole
    // subtree to dark so the adaptive `Color.custom*` assets never resolve to their
    // light variants, even when the rest of the app is in light mode. Applied last so
    // the background above resolves dark too.
    .environment(\.colorScheme, .dark)
  }

  private func gameField(size: CGSize) -> some View {
    ZStack {
      Color.customBackground.ignoresSafeArea()

      // The playfield proper — everything that should judder on a llamada screen
      // shake. HUD/controls/cards sit outside the shaken group.
      ZStack {
        ForEach(gameState.platforms) { platform in
          Group {
            RoundedRectangle(cornerRadius: 3)
              .fill(Color.customRed)
              .frame(width: platform.rect.width, height: platform.rect.height)
              .position(x: platform.rect.midX, y: platform.rect.midY)
            // A thin dotted yellow "mortar" line along the platform's TOP edge, so the
            // red girder reads as a course of brick. An explicitly-framed shape + a
            // .position places it reliably (an .overlay(alignment:) on the flexible
            // rectangle ignored .top, and a bare Path in the ZStack didn't render).
            HLine()
              .stroke(Color.customYellow,
                      style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 4]))
              .frame(width: platform.rect.width - 6, height: 2)
              .position(x: platform.rect.midX, y: platform.rect.minY + 1)
          }
          // The bottom girder is the boss's tablao floor; everything above fades out.
          .opacity(platform.level == 0 ? 1 : 1 - gameState.bossTransition)
        }

        ForEach(gameState.ladders) { ladder in
          ladderView(ladder)
            .opacity(1 - gameState.bossTransition)
        }

        ForEach(gameState.powerUps) { powerUp in
          if !powerUp.collected {
            powerUpView(powerUp)
              .opacity(1 - gameState.bossTransition)
          }
        }

        ForEach(gameState.obstacles) { obstacle in
          // Per-set rendering: `.spin` sets tumble like barrels; `.face` sets stay
          // upright and mirror to face their travel (glyphs render facing LEFT, so a
          // rightward mover flips to −1 — the dancer/bull convention); `.upright`
          // sets neither spin nor mirror.
          Text(obstacle.emoji)
            .font(.system(size: 28))
            .rotationEffect(obstacle.style == .spin ? .degrees(obstacle.rotation) : .zero)
            .scaleEffect(x: obstacle.style == .face && obstacle.facing > 0 ? -1 : 1, y: 1)
            .position(x: obstacle.x, y: obstacle.y)
            .opacity(1 - gameState.bossTransition)
        }

        // El Encierro: 🐂 chargers running across the girders. The glyph faces LEFT, so
        // mirror it (−1) when it charges right — the obstacle/dancer/bull convention.
        ForEach(gameState.chargers) { charger in
          Text(verbatim: "🐂")
            .font(.system(size: 28))
            .scaleEffect(x: charger.direction > 0 ? -1 : 1, y: 1)
            .position(x: charger.x, y: charger.y)
            .opacity(1 - gameState.bossTransition)
        }

        stageDressing

        matadorSprite

        bullSprite
        playerSprite
        speedBadge

        // El Apagón: the lights-out overlay. Placed after the sprites (so they darken)
        // but before the cue chips + jaleo pops (so an announcement floats above the
        // darkness); the HUD/controls live outside this shaken group and stay lit.
        apagonOverlay

        cueChips
        jaleoPopViews
      }
      .offset(shakeOffset)

      if gameState.phase == .victory || gameState.phase == .endScene {
        confetti(count: 40, colors: [.customRed, .customYellow, .customBlue])
      } else if gameState.isPhraseSuccess {
        // A blue (the matador's color) half-density burst when a phrase lands, filling
        // the mid-field between the bull and the top HUD.
        confetti(count: 20, colors: [.customBlue], yRange: successConfettiRange)
      }

      bossTapLayer

      quitButton
      if gameState.phase == .climb || gameState.phase == .escape {
        // Hearts stay up through the escape beat so the pips don't blink out mid-flee.
        healthPips
      } else if !gameState.hasWon {
        // The Duende meter shows through the intro + duel, then is retired the moment
        // the player wins (victory + end scene) for a cleaner curtain call.
        bossHUD
      }
      bossCards
      controls
      bossControlRow
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
          .offset(y: Self.dancerFeetOffset + Self.dancerWalkBob(action, frame: gameState.playerFrame))
          // The muleta is part of the caped sprite now, so the about-to-expire
          // warning is a flash of the whole caped pose (was a separate 🧣 emoji):
          // during the expiry blink `isCaped` stays true but `isCapeVisible` toggles.
          .opacity(gameState.isCaped && !gameState.isCapeVisible ? 0.4 : 1)
      } else {
        // Numbered-box fallback (safety net; unused for the player today).
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.customRed)
        Text(verbatim: "\(gameState.playerFrame)")
          .font(.system(size: 18, weight: .bold, design: .monospaced))
          .foregroundStyle(.white)
        facingChevron(gameState.playerFacing, tint: .white)
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

  /// The captive matador — a single static frame beside the bull on the top platform.
  /// During an escape beat (summits 1–4) he rides upward with the bull off the top of
  /// the screen (`GameState.updateEscape`); the boss end scene later frees him.
  /// Displayed at a constant height with width from the render aspect (like the dancer),
  /// feet planted on the girder; front-facing, so no mirroring. `.interpolation(.high)`
  /// smooths the 512→display downscale (nearest-neighbor frays the cel outline — the
  /// bull lesson).
  private var matadorSprite: some View {
    Image("matador")
      .resizable()
      .interpolation(.high)
      .scaledToFit()
      .frame(width: Self.matadorWidth, height: Self.matadorVisualHeight)
      .offset(y: Self.matadorFeetOffset)
      .position(x: gameState.bullfighterX, y: gameState.bullfighterY)
  }

  /// A stage's power-up pickup, rendered by kind: the cape keeps its rendered muleta
  /// sprite (was a 🧣 emoji), while speed ⚡ and La Serenata 🎸 are `Text` glyphs at
  /// capeSize scale. The collision box stays the full `capeSize` centered on `y`.
  @ViewBuilder
  private func powerUpView(_ powerUp: PowerUp) -> some View {
    switch powerUp.kind {
    case .cape:
      // Drawn at 60% of capeSize so it matches the carried cape's apparent size, hem
      // sitting on the platform surface.
      let pickupHeight = GameState.capeSize * 0.6
      Image("cape_pickup")
        .resizable()
        .scaledToFit()
        .frame(width: pickupHeight * (188.0 / 229.0), height: pickupHeight)
        .position(x: powerUp.x, y: powerUp.y + GameState.capeSize * 0.2)
    case .speed:
      Text(verbatim: "⚡")
        .font(.system(size: GameState.capeSize))
        .position(x: powerUp.x, y: powerUp.y)
    case .serenata:
      Text(verbatim: "🎸")
        .font(.system(size: GameState.capeSize))
        .position(x: powerUp.x, y: powerUp.y)
    }
  }

  /// A ⚡ badge floating just above the dancer while the speed power-up is active,
  /// sharing the cape's last-2 s expiry blink (`isSpeedBadgeVisible`).
  private var speedBadge: some View {
    Group {
      if gameState.speedRemaining > 0 {
        Text(verbatim: "⚡")
          .font(.system(size: 20))
          .opacity(gameState.isSpeedBadgeVisible ? 1 : 0.25)
          .position(x: gameState.playerX, y: gameState.playerY - GameState.playerHeight)
      }
    }
  }

  /// El Apagón's lights-out overlay: a near-black wash with a soft radial spotlight
  /// punched around the dancer, its darkness scaled by `apagonDim` so it fades in and
  /// out with the mechanic's envelope. The `compositingGroup` + `.destinationOut`
  /// blend is required — a plain overlay can't cut a *soft* hole (the mask idiom). Sits
  /// inside the shaken playfield so it moves with the field; `allowsHitTesting(false)`
  /// keeps the controls beneath it responsive.
  @ViewBuilder
  private var apagonOverlay: some View {
    if gameState.apagonDim > 0 {
      Color.black.opacity(GameState.apagonDimOpacity * Double(gameState.apagonDim))
        .mask {
          ZStack {
            Rectangle()
            RadialGradient(
              colors: [.black, .clear], center: .center,
              startRadius: GameState.apagonSpotlightRadius * 0.55,
              endRadius: GameState.apagonSpotlightRadius
            )
            .frame(
              width: GameState.apagonSpotlightRadius * 2,
              height: GameState.apagonSpotlightRadius * 2
            )
            .position(x: gameState.playerX, y: gameState.playerY)
            .blendMode(.destinationOut)
          }
          .compositingGroup()
        }
        .allowsHitTesting(false)
    }
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

  // MARK: Boss fight — La Llamada. User-facing strings are in `L.Game` /
  // Localizable.xcstrings: the jaleo shouts + title cards stay Spanish in both
  // localizations (decision 16), the narrative line + a11y labels localize en/es.

  /// A brief deterministic sin-decay judder on llamadas (the Conjuguer idiom —
  /// driven by the game clock, so no per-frame randomness in the view).
  private var shakeOffset: CGSize {
    let shake = gameState.screenShake
    guard shake > 0 else { return .zero }
    let intensity = CGFloat(shake / GameState.screenShakeDuration)
    let magnitude = GameState.screenShakeMagnitude * intensity
    return CGSize(
      width: CGFloat(sin(gameState.sineTime * 47)) * magnitude,
      height: CGFloat(cos(gameState.sineTime * 53)) * magnitude
    )
  }

  /// The tablao set: the matador's pedestal. Fades in with `bossTransition` as the
  /// climb scenery fades out. (An emoji crowd row once sat just below the floor, but
  /// its glyph style clashed with the rendered bull/dancer/matador sprites, so it
  /// was removed — the jaleo pops carry the crowd's voice instead.)
  private var stageDressing: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(Color.customRed)
      .frame(width: GameState.bossPedestalSize.width, height: GameState.bossPedestalSize.height)
      .overlay(
        HLine()
          .stroke(Color.customYellow, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 4]))
          .frame(height: 2), alignment: .top
      )
      .position(x: gameState.pedestalCenterX, y: gameState.pedestalTopY + GameState.bossPedestalSize.height / 2)
      .opacity(gameState.bossTransition)
  }

  /// The bull-demo step, when the duel is in its call half (drives the cue chips).
  private var demoStep: Int? {
    guard gameState.phase == .duel, case .bullDemo(let step) = gameState.duelState else { return nil }
    return step
  }

  /// SC5-style cue chips accumulating left→right above the bull as he demos the
  /// phrase. The full sequence lingers a recall beat (`demoRecallHold`) after the
  /// last move, then vanishes at ¡Tu turno! — echoing is from memory.
  private var cueChips: some View {
    Group {
      if let step = demoStep, !gameState.phraseSequence.isEmpty {
        HStack(spacing: 4) {
          ForEach(0...min(step, gameState.phraseSequence.count - 1), id: \.self) { index in
            moveChip(gameState.phraseSequence[index])
          }
        }
        .position(x: gameState.bullX, y: gameState.bullY - 74)
      }
    }
  }

  private func moveChip(_ move: DanceMove) -> some View {
    ZStack {
      switch move {
      case .pasoLeft:
        Image(systemName: "arrowtriangle.left.fill")
      case .pasoRight:
        Image(systemName: "arrowtriangle.right.fill")
      case .ole:
        Image(systemName: "figure.arms.open")
      case .stomp:
        Image(systemName: "shoeprints.fill")
      case .cape:
        Image("cape_pickup")
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
      case .freeze:
        Text(verbatim: "🔥")
          .font(.system(size: 14))
      }
    }
    .font(.system(size: 13, weight: .bold))
    .foregroundStyle(Color.customYellow)
    .frame(width: 26, height: 26)
    .background(Color.customRed.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.customYellow.opacity(0.5), lineWidth: 1))
  }

  /// Floating, fading jaleo shouts (¡Olé! ¡Uy! ¡Eso!…) — the sibling score-pop idiom.
  /// Also carries the mechanic bull-speech announcements, which can be long (the
  /// two-line "Your obstacles are now zombies!"). Those are `.position`-centered at the
  /// bull, so a wide line would overflow whichever edge the bull is nearer. Bounding
  /// each pop's wrap width to twice the distance from its center to the NEARER edge (less
  /// a margin) keeps the center-aligned box fully on-screen wherever the bull speaks from;
  /// short shouts sit well inside that bound, so their single-line layout is unchanged.
  private var jaleoPopViews: some View {
    ForEach(gameState.jaleoPops) { pop in
      let age = pop.initialTTL - pop.ttl
      let margin = Layout.defaultHorizontalMargin
      let halfRoom = max(0, min(pop.x, gameState.screenSize.width - pop.x) - margin)
      Text(verbatim: pop.text)
        .font(.system(size: pop.size, weight: .heavy, design: .rounded))
        .foregroundStyle(Color.customYellow)
        .multilineTextAlignment(.center)
        .frame(maxWidth: max(1, halfRoom * 2))
        .fixedSize(horizontal: false, vertical: true)
        .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
        .opacity(pop.ttl / pop.initialTTL)
        .position(x: pop.x, y: pop.y - CGFloat(age) * pop.riseRate)
    }
  }

  /// Duende meter (the tug-of-war progress bar) + the compás bar while echoing.
  /// Replaces the hearts whenever `phase != .climb`.
  private var bossHUD: some View {
    VStack(spacing: 6) {
      HStack(spacing: 5) {
        Image("dancer")
          .font(.system(size: 16))
          .foregroundStyle(Color.customYellow)
        ForEach(0..<GameState.meterNotches, id: \.self) { index in
          RoundedRectangle(cornerRadius: 3)
            .fill(index < gameState.banked ? Color.customYellow : Color.customYellow.opacity(0.15))
            .frame(width: 20, height: 10)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color.customYellow.opacity(0.4), lineWidth: 1))
        }
        Image("bull")
          .font(.system(size: 18))
          .foregroundStyle(Color.customYellow)
      }
      .accessibilityLabel(Text(verbatim: L.Game.duendeMeter))

      if gameState.isEchoActive {
        let fraction = max(0, min(1, gameState.echoRemaining / gameState.echoTotal))
        ZStack(alignment: .leading) {
          Capsule().fill(Color.customYellow.opacity(0.15))
          Capsule().fill(Color.customRed).frame(width: 160 * CGFloat(fraction))
        }
        .frame(width: 160, height: 7)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(.top, Layout.doubleDefaultSpacing)
    .opacity(gameState.bossTransition)
  }

  /// The intro / victory / end-scene title cards. Hit-testing off — the full-screen
  /// tap layer underneath handles skip/advance.
  private var bossCards: some View {
    Group {
      switch gameState.phase {
      case .bossIntro:
        bossTitle(L.Game.duelTitle)
      case .victory:
        victoryTitle
      case .endScene:
        VStack(spacing: Layout.doubleDefaultSpacing) {
          victoryTitle
          Text(verbatim: L.Game.bullImpressed)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.customYellow)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            .padding(.horizontal, Layout.tripleDefaultSpacing)
        }
      case .climb, .escape, .duel:
        EmptyView()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(.top, 100)
    .allowsHitTesting(false)
  }

  /// The intro card ("¡El duelo!"): a bold rounded plate in the game's playful voice.
  private func bossTitle(_ text: String) -> some View {
    Text(verbatim: text)
      .font(.system(size: 44, weight: .black, design: .rounded))
      .foregroundStyle(Color.customYellow)
      .padding(.horizontal, Layout.doubleDefaultSpacing)
      .padding(.vertical, Layout.defaultSpacing)
      .background(Color.customRed.opacity(0.75), in: RoundedRectangle(cornerRadius: Layout.cornerRadius))
      .shadow(radius: 4)
  }

  /// The win payoff title ("¡Victoria!"): a grander, condensed gold display treatment
  /// distinct from the intro plate — a taller, tighter cut that reads as a curtain
  /// call. Gold on the red plate, with a soft glow.
  private var victoryTitle: some View {
    Text(verbatim: L.Game.victoria)
      .font(.system(size: 54, weight: .black, design: .rounded))
      .fontWidth(.condensed)
      .foregroundStyle(Color.customYellow)
      .shadow(color: Color.customYellow.opacity(0.5), radius: 8)
      .padding(.horizontal, Layout.tripleDefaultSpacing)
      .padding(.vertical, Layout.defaultSpacing)
      .background(Color.customRed.opacity(0.8), in: RoundedRectangle(cornerRadius: Layout.cornerRadius))
      .shadow(radius: 5)
  }

  /// Confetti — Konjugieren's golden-angle ellipse Canvas (the seed spreads the dots
  /// into the diagonal rows the design calls out), in Conjugar's palette. `colors`
  /// cycles by index down those rows: the end scene alternates red/yellow/blue
  /// (design note 6); the per-phrase success burst is blue-only at half the count
  /// (design note 4). `yRange` (in the field's coordinate space) bounds the dots to a
  /// vertical band — the success burst fills only the mid-field between the bull and
  /// the top HUD; nil means the full-screen celebration.
  private func confetti(count: Int, colors: [Color], yRange: ClosedRange<CGFloat>? = nil) -> some View {
    let field = TimelineView(.animation) { timeline in
      let time = timeline.date.timeIntervalSince1970
      Canvas { context, size in
        let minY = yRange?.lowerBound ?? 0
        let spanY = max(1, (yRange?.upperBound ?? size.height) - minY)
        for i in 0..<count {
          let seed = Double(i) * 137.508
          let baseX = (seed.truncatingRemainder(dividingBy: 1.0) + Double(i) * 0.025).truncatingRemainder(dividingBy: 1.0) * size.width
          let baseY = minY + (seed * 0.618).truncatingRemainder(dividingBy: 1.0) * spanY
          let floatOffset = sin(time * 1.5 + seed) * 20
          let radius = 3.0 + (seed * 0.3).truncatingRemainder(dividingBy: 5.0)
          let rect = CGRect(x: baseX - radius, y: baseY + floatOffset - radius, width: radius * 2, height: radius * 2)
          context.fill(Path(ellipseIn: rect), with: .color(colors[i % colors.count]))
        }
      }
    }
    .allowsHitTesting(false)

    // The full-screen celebration ignores the safe area; the banded success burst stays
    // in the field's coordinate space so its bounds line up with the bull and the HUD.
    return Group {
      if yRange == nil {
        field.ignoresSafeArea()
      } else {
        field
      }
    }
  }

  /// The vertical band the phrase-success burst fills: from just below the top HUD
  /// (Duende meter + close button) down to just above the bull's head — the empty
  /// mid-field, rather than the whole screen (design follow-up).
  private var successConfettiRange: ClosedRange<CGFloat> {
    let top = Self.bossSuccessConfettiTop
    let bottom = max(top + 1, gameState.stageFloorY - Self.bullHeight(.idle) - 8)
    return top...bottom
  }

  /// Full-screen tap catcher for the boss's skippable beats: intro → duel,
  /// victory → end scene, end scene → dismiss. Sits under the quit button and
  /// controls so those stay tappable.
  private var bossTapLayer: some View {
    Group {
      if gameState.phase == .bossIntro || gameState.phase == .victory || gameState.phase == .endScene {
        Color.clear
          .contentShape(Rectangle())
          .ignoresSafeArea()
          .onTapGesture {
            if gameState.phase == .endScene {
              dismiss()
            } else {
              gameState.handleBossTap()
            }
          }
      }
    }
  }

  // MARK: Boss controls (taps, not held intents — the jump touch-down/re-arm idiom)

  /// The boss dance pad: all five moves in one horizontal row of equal circular
  /// buttons, positioned just below the tablao floor (design note 2). The pasos sit at
  /// the ends (spatially left/right); olé, stomp, and cape fill the middle. Placed by
  /// the stage floor so it tucks right under the platform the dancers stand on.
  private var bossControlRow: some View {
    Group {
      if gameState.phase == .duel {
        HStack(spacing: Layout.defaultSpacing) {
          danceButton(.pasoLeft, label: L.Game.pasoLeftMove, size: Self.bossMoveButtonSize, isCircle: true) {
            Image(systemName: "arrowtriangle.left.fill")
          }
          danceButton(.ole, label: L.Game.oleMove, size: Self.bossMoveButtonSize, isCircle: true) {
            // An arms-raised figure for the olé desplante (not a jump — design note 3).
            Image(systemName: "figure.mind.and.body")
          }
          danceButton(.stomp, label: L.Game.stompMove, size: Self.bossMoveButtonSize, isCircle: true) {
            Image(systemName: "shoeprints.fill")
              .font(.system(size: 24, weight: .bold))
          }
          danceButton(.cape, label: L.Game.capeMove, size: Self.bossMoveButtonSize, isCircle: true) {
            Image("cape_pickup")
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
          }
          danceButton(.pasoRight, label: L.Game.pasoRightMove, size: Self.bossMoveButtonSize, isCircle: true) {
            Image(systemName: "arrowtriangle.right.fill")
          }
        }
        .position(x: gameState.screenSize.width / 2,
                  y: gameState.stageFloorY + Self.bossRowFloorGap)
      }
    }
  }

  /// A boss dance button: fires once on touch-down, re-arms on lift (a held paso
  /// must not fire twice). Dimmed while input is locked (demo/result/showboat);
  /// `danceInput` also guards, so a dimmed tap is harmless.
  private func danceButton<Icon: View>(
    _ move: DanceMove,
    label: String,
    size: CGFloat = GameView.dirButtonSize,
    isCircle: Bool = false,
    @ViewBuilder icon: () -> Icon
  ) -> some View {
    icon()
      .font(.system(size: 22, weight: .bold))
      .foregroundStyle(Color.customYellow)
      .frame(width: size, height: size)
      .background {
        if isCircle {
          Circle().fill(Color.customRed.opacity(0.18))
        } else {
          RoundedRectangle(cornerRadius: 10).fill(Color.customYellow.opacity(0.18))
        }
      }
      .overlay {
        if isCircle {
          Circle().strokeBorder(Color.customYellow, lineWidth: 2)
        } else {
          RoundedRectangle(cornerRadius: 10).strokeBorder(Color.customYellow.opacity(0.35), lineWidth: 1)
        }
      }
      .contentShape(Rectangle())
      .opacity(gameState.isEchoActive ? 1 : 0.35)
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            if !heldDanceMoves.contains(move) {
              heldDanceMoves.insert(move)
              gameState.danceInput(move)
            }
          }
          .onEnded { _ in heldDanceMoves.remove(move) }
      )
      .accessibilityLabel(Text(verbatim: label))
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
    // (small bottom padding) so the cross clears the field of play. The duel's dance
    // pad is `bossControlRow`, placed by the stage floor rather than pinned to the
    // bottom edge; the boss's other phases (intro, victory, end scene) have no controls
    // at all — taps go to the tap layer.
    HStack(alignment: .center) {
      switch gameState.phase {
      case .climb:
        dPad
        Spacer()
        jumpButton
      case .escape, .duel, .bossIntro, .victory, .endScene:
        // No player controls during the escape beat (the bull flees on its own).
        Spacer()
      }
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

/// A horizontal line across its frame's width (used as the dotted "mortar" line on
/// each brick platform). A plain `Shape` draws reliably inside its own frame, unlike a
/// `Path` with absolute coordinates dropped into a `ZStack`.
private struct HLine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return path
  }
}
