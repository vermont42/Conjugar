//
//  GameState+Slideshow.swift
//  Conjugar
//
//  The end scene's slideshow: the live scene, Los toreros, and La familia, joined by iris
//  wipes, with a Ken Burns camera, a caption, and subject sounds on each portrait (stills
//  and crossfades under Reduce Motion). Driven by the game clock from `updateEndScene`,
//  so `CONJUGAR_GAME_TIME_SCALE` slows it for freeze-framing and tests can step it.
//  Details are in docs/game.md.
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

  static func endSceneHold(for slide: EndSceneSlide) -> Double {
    slide.isImage ? endSceneImageHold : endSceneLiveHold
  }

  /// An incoming slide hasn't started its clock, so it opens on the wide shot.
  private func endSceneClock(for slide: EndSceneSlide) -> Double {
    slide == endSceneSlide ? endSceneSlideTime : 0
  }

  func endSceneShots(for slide: EndSceneSlide) -> [EndSceneShot] {
    guard slide.isImage else { return [] }
    let time = endSceneClock(for: slide)
    if endSceneCrossfade {
      return Self.endSceneStillShots(slide, at: time)
    }
    return [EndSceneShot(framing: Self.endSceneFraming(slide, at: time), opacity: 1)]
  }

  /// Left, middle, right; 0 is regular and 1 is bold.
  func endSceneCaptionBoldness(for slide: EndSceneSlide) -> [Double] {
    Self.endSceneCaptionBoldness(slide, at: endSceneClock(for: slide), stills: endSceneCrossfade)
  }

  static var endScenePanStart: Double {
    endSceneWideHold + endScenePushInDuration + endSceneFirstDwell
  }

  static var endSceneSecondPanStart: Double {
    endScenePanStart + endScenePanLegDuration + endSceneMiddleDwell
  }

  static var endSceneStillCuts: [Double] {
    (1...3).map { endSceneImageHold * Double($0) / 4 }
  }

  /// `time` is seconds since the slide's wipe finished.
  static func endSceneFraming(_ slide: EndSceneSlide, at time: Double) -> EndSceneFraming {
    guard let subjects = slide.subjectFocusX else { return .wide }
    let pushInStart = endSceneWideHold
    if time < pushInStart + endScenePushInDuration {
      let t = smoothstep(progress(time, from: pushInStart, duration: endScenePushInDuration))
      return EndSceneFraming(zoom: t, focusX: lerp(EndSceneFraming.wide.focusX, subjects.left, t))
    }
    if time < endSceneSecondPanStart {
      let t = smoothstep(progress(time, from: endScenePanStart, duration: endScenePanLegDuration))
      return EndSceneFraming(zoom: 1, focusX: lerp(subjects.left, subjects.middle, t))
    }
    let t = smoothstep(progress(time, from: endSceneSecondPanStart, duration: endScenePanLegDuration))
    return EndSceneFraming(zoom: 1, focusX: lerp(subjects.middle, subjects.right, t))
  }

  static func endSceneStillShots(_ slide: EndSceneSlide, at time: Double) -> [EndSceneShot] {
    guard let subjects = slide.subjectFocusX else { return [] }
    let stills = [EndSceneFraming.wide] + [subjects.left, subjects.middle, subjects.right].map {
      EndSceneFraming(zoom: 1, focusX: $0)
    }
    let halfFade = endSceneCrossfadeDuration / 2
    for (index, cut) in endSceneStillCuts.enumerated() {
      if time < cut - halfFade {
        return [EndSceneShot(framing: stills[index], opacity: 1)]
      }
      if time < cut + halfFade {
        let fade = progress(time, from: cut - halfFade, duration: endSceneCrossfadeDuration)
        return [
          EndSceneShot(framing: stills[index], opacity: 1),
          EndSceneShot(framing: stills[index + 1], opacity: fade)
        ]
      }
    }
    return [EndSceneShot(framing: stills[stills.count - 1], opacity: 1)]
  }

  /// Halfway through each pan leg is where the eased focus crosses the midpoint between
  /// two subjects.
  static func endSceneCaptionHandoffs(_ slide: EndSceneSlide, stills: Bool) -> (first: Double, second: Double)? {
    guard slide.subjectFocusX != nil else { return nil }
    if stills {
      let cuts = endSceneStillCuts
      return (cuts[1], cuts[2])
    }
    let halfLeg = endScenePanLegDuration / 2
    return (endScenePanStart + halfLeg, endSceneSecondPanStart + halfLeg)
  }

  /// The left name is bold from the start, since the push-in is headed for it.
  static func endSceneCaptionBoldness(_ slide: EndSceneSlide, at time: Double, stills: Bool) -> [Double] {
    guard let handoffs = endSceneCaptionHandoffs(slide, stills: stills) else { return [] }
    func ramp(_ handoff: Double) -> Double {
      let start = handoff - endSceneCaptionFadeDuration / 2
      return min(1, max(0, (time - start) / endSceneCaptionFadeDuration))
    }
    let toMiddle = ramp(handoffs.first)
    let toRight = ramp(handoffs.second)
    return [1 - toMiddle, toMiddle - toRight, toRight]
  }

  static func endSceneCallTimes(_ slide: EndSceneSlide, stills: Bool) -> [Double] {
    guard let handoffs = endSceneCaptionHandoffs(slide, stills: stills) else { return [] }
    let first = stills ? endSceneStillCuts[0] : endSceneWideHold + endScenePushInDuration / 2
    return [first, handoffs.first, handoffs.second]
  }

  private static func progress(_ time: Double, from start: Double, duration: Double) -> CGFloat {
    CGFloat(min(1, max(0, (time - start) / duration)))
  }

  /// `endSceneCrossfade` mirrors the view's Reduce Motion setting, so it isn't reset.
  func resetEndSceneSlideshow() {
    endSceneSlide = .live
    endSceneIncomingSlide = nil
    endSceneIrisProgress = 0
    endSceneSlideTime = 0
    endSceneCallsPlayed = 0
  }

  func advanceEndSceneSlideshow(dt: Double) {
    if let incoming = endSceneIncomingSlide {
      endSceneIrisProgress = min(1, endSceneIrisProgress + dt / endSceneWipeDuration)
      if endSceneIrisProgress >= 1 {
        endSceneSlide = incoming
        endSceneIncomingSlide = nil
        endSceneIrisProgress = 0
        endSceneSlideTime = 0
        endSceneCallsPlayed = 0
      }
      return
    }

    endSceneSlideTime += dt
    playDueEndSceneCall()
    if endSceneSlideTime >= Self.endSceneHold(for: endSceneSlide) {
      endSceneIncomingSlide = endSceneSlide.next
      endSceneIrisProgress = 0
    }
  }

  /// Counting calls rather than watching for a crossing means each plays exactly once per
  /// showing, even if Reduce Motion flips mid-portrait and moves the times.
  private func playDueEndSceneCall() {
    let times = Self.endSceneCallTimes(endSceneSlide, stills: endSceneCrossfade)
    let calls = endSceneSlide.subjectCalls
    guard endSceneCallsPlayed < min(times.count, calls.count),
          endSceneSlideTime >= times[endSceneCallsPlayed] else { return }
    let call = calls[endSceneCallsPlayed]
    endSceneCallsPlayed += 1
    Current.soundPlayer.play(call.sound, shouldDebounce: false, volume: call.volume)
  }
}
