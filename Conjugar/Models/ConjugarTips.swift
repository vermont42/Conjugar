//
//  ConjugarTips.swift
//  Conjugar
//
//  TipKit onboarding tips. Four tips nudge new users toward the quiz, the verb
//  models, a higher quiz level (rule-gated on a completed quiz), and Game
//  Center, and two on the verb page explain its red letters and point to the
//  etymology and examples at its bottom. See `TipDisplay.tipsEnabled`, in
//  `Utils/KillSwitches.swift`, for the screenshot kill switch.
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

struct ChangeLevelTip: Tip {
  static let quizCompleted = Event(id: "quizCompleted")

  var title: Text {
    Text(L.Tips.changeLevelTitle)
  }

  var message: Text? {
    Text(L.Tips.changeLevelMessage)
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

/// Explains the verb page's red letters. `VerbView` shows it only on a page that has one. Once
/// closed, it never returns.
struct RedLettersTip: Tip {
  var title: Text {
    Text(L.Tips.redLettersTitle)
  }

  var message: Text? {
    Text(L.Tips.redLettersMessage)
  }

  var image: Image? {
    Image(systemName: "character.cursor.ibeam")
  }
}

/// Points to the etymology and the examples at the bottom of the verb page. It waits until a page
/// visit after `RedLettersTip` was closed, so the two never appear one straight after the other,
/// and the page retires it once the learner scrolls that far unprompted.
struct ScrollToBottomTip: Tip {
  @Parameter
  static var isUnlocked: Bool = false

  var title: Text {
    Text(L.Tips.scrollToBottomTitle)
  }

  var message: Text? {
    Text(L.Tips.scrollToBottomMessage)
  }

  var image: Image? {
    Image(systemName: "arrow.down.to.line")
  }

  var rules: [Rule] {
    #Rule(Self.$isUnlocked) {
      $0 == true
    }
  }
}
