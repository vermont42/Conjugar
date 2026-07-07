//
//  ConjugarTips.swift
//  Conjugar
//
//  TipKit onboarding tips, ported from the sibling app Conjuguer (French) and
//  adapted for Spanish (July 2026). Four tips nudge new users toward the quiz,
//  the verb models, higher quiz difficulty (rule-gated on a completed quiz), and
//  Game Center. See `TipDisplay.tipsEnabled` for the screenshot kill switch.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

enum TipDisplay {
  /// Master switch for all TipKit tips. Ordinarily `true`. Set to `false` before
  /// generating screenshots (then restore to `true`) so no tip ever appears.
  ///
  /// When `false`, `ConjugarApp` skips `Tips.configure()`. TipKit displays nothing
  /// until it is configured, so every `TipView` and `.popoverTip(_:)` in the app stays
  /// hidden — no per-call-site changes needed.
  static let tipsEnabled = true
}

struct TryQuizTip: Tip {
  var title: Text {
    Text(L.Tips.tryQuizTitle)
  }

  var message: Text? {
    Text(L.Tips.tryQuizMessage)
  }

  var image: Image? {
    Image(systemName: "pencil.circle.fill")
  }

  var options: [TipOption] {
    MaxDisplayCount(1)
  }
}

struct ExploreModelsTip: Tip {
  var title: Text {
    Text(L.Tips.exploreModelsTitle)
  }

  var message: Text? {
    Text(L.Tips.exploreModelsMessage)
  }

  var image: Image? {
    Image(systemName: "square.stack.3d.up.fill")
  }

  var options: [TipOption] {
    MaxDisplayCount(1)
  }
}

struct ChangeDifficultyTip: Tip {
  static let quizCompleted = Event(id: "quizCompleted")

  var title: Text {
    Text(L.Tips.changeDifficultyTitle)
  }

  var message: Text? {
    Text(L.Tips.changeDifficultyMessage)
  }

  var image: Image? {
    Image(systemName: "slider.horizontal.3")
  }

  var rules: [Rule] {
    #Rule(Self.quizCompleted) {
      $0.donations.count >= 1
    }
  }

  var options: [TipOption] {
    MaxDisplayCount(1)
  }
}

struct EnableGameCenterTip: Tip {
  var title: Text {
    Text(L.Tips.enableGameCenterTitle)
  }

  var message: Text? {
    Text(L.Tips.enableGameCenterMessage)
  }

  var image: Image? {
    Image(systemName: "trophy.fill")
  }

  var options: [TipOption] {
    MaxDisplayCount(1)
  }
}
