//
//  ConjugarTips.swift
//  Conjugar
//
//  TipKit onboarding tips. Four tips nudge new users toward the quiz, the verb
//  models, higher quiz difficulty (rule-gated on a completed quiz), and Game
//  Center. See `TipDisplay.tipsEnabled`, in `Utils/KillSwitches.swift`, for the
//  screenshot kill switch.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

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
