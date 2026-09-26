//
//  GameState+Slideshow.swift
//  Conjugar
//
//  The end scene's slideshow. Five seconds after the reunion burst, an iris wipe opens
//  on a still portrait of the dancer, the bull, and the matador (Los toreros), then one
//  of the developer's family (La familia), then the live scene again, cycling until the
//  player quits. Time-driven from `updateEndScene` like the rest of the end scene, so
//  `CONJUGAR_GAME_TIME_SCALE` slows the iris for freeze-framing and tests can drive it.
//  The live simulation keeps running underneath every image. GameView draws the images,
//  the iris, the drag, the toast, and the caption (prompts/end_scene_plan.md).
//

import CoreGraphics
import Foundation

extension GameState {
  /// How long the current wipe takes: an iris, or a shorter crossfade under Reduce Motion.
  var endSceneWipeDuration: Double {
    endSceneCrossfade ? Self.endSceneCrossfadeDuration : Self.endSceneIrisDuration
  }

  /// The wipe's eased progress (smoothstep), which the view uses for the iris diameter
  /// and the crossfade.
  var endSceneIrisEased: CGFloat {
    Self.smoothstep(CGFloat(endSceneIrisProgress))
  }

  /// True while a still image is on screen or opening. The bull's vocalizations and the
  /// reunion chimes come from things the player can't see then, so they are suppressed.
  var isEndSceneImageUp: Bool {
    endSceneSlide.isImage || (endSceneIncomingSlide?.isImage ?? false)
  }

  /// How visible the live scene's overlays (the ¡Victoria! title, the "bull is impressed"
  /// line, the confetti) are: fully on the live slide, gone under an image, and fading
  /// with the wipe between the two.
  var endSceneOverlayOpacity: Double {
    let t = Double(endSceneIrisEased)
    switch (endSceneSlide.isImage, endSceneIncomingSlide?.isImage) {
    case (false, nil): return 1
    case (false, true?): return 1 - t
    case (true, false?): return t
    default: return 0
    }
  }

  /// Clear the whole slideshow back to the live scene, used by `reset()` and
  /// `enterEndScene()`. The cycle itself arms when the reunion burst fires.
  /// `endSceneCrossfade` is the view's Reduce Motion setting, so it survives.
  func resetEndSceneSlideshow() {
    endSceneSlide = .live
    endSceneIncomingSlide = nil
    endSceneIrisProgress = 0
    endSceneSlideHold = 0
    endSceneDragActive = false
    endSceneHasDragged = false
    endSceneToastTime = 0
  }

  /// Start the cycle: the live scene holds for its full beat, then the first wipe.
  /// Called once, on the frame the reunion burst fires.
  func armEndSceneSlideshow() {
    endSceneSlideHold = Self.endSceneSlideHold
  }

  /// One tick of the slideshow, after the cycle has armed: advance a wipe in progress,
  /// or count down the current slide's hold (paused while the player drags) and start
  /// the next wipe at zero.
  func advanceEndSceneSlideshow(dt: Double) {
    if endSceneToastTime > 0 {
      endSceneToastTime = max(0, endSceneToastTime - dt)
    }

    if let incoming = endSceneIncomingSlide {
      endSceneIrisProgress = min(1, endSceneIrisProgress + dt / endSceneWipeDuration)
      if endSceneIrisProgress >= 1 {
        endSceneSlide = incoming
        endSceneIncomingSlide = nil
        endSceneIrisProgress = 0
        endSceneSlideHold = Self.endSceneSlideHold
        if incoming.isImage && !endSceneHasDragged {
          endSceneToastTime = Self.endSceneToastDuration
        }
      }
      return
    }

    guard !endSceneDragActive else { return }
    endSceneSlideHold -= dt
    if endSceneSlideHold <= 0 {
      endSceneIncomingSlide = endSceneSlide.next
      endSceneIrisProgress = 0
    }
  }

  /// A finger went down on an image: pause the hold and retire the toast for the rest of
  /// the session.
  func beginEndSceneDrag() {
    endSceneDragActive = true
    endSceneHasDragged = true
    endSceneToastTime = 0
  }

  /// The finger lifted: the slide gets a fresh full hold from here.
  func endEndSceneDrag() {
    endSceneDragActive = false
    restartEndSceneHold()
  }

  /// Give the slide on screen a fresh full hold (after a drag, or a VoiceOver pan), so
  /// someone studying the picture doesn't have it wiped away. A no-op mid-wipe.
  func restartEndSceneHold() {
    guard endSceneIncomingSlide == nil else { return }
    endSceneSlideHold = Self.endSceneSlideHold
  }
}
