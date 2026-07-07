//
//  WidgetL.swift
//  Conjugar
//
//  Scoped localization accessors for the widget, mirroring the app's `L`. Each is a
//  `LocalizedStringResource` keyed into `ConjugarWidget/Localizable.xcstrings`, with
//  an English `defaultValue` so keys still resolve when this file is compiled into
//  the app bundle (which lacks the widget catalog).
//
//  NOTE: AppIntent `title` / `@Parameter(title:)` metadata is extracted at compile
//  time and CANNOT reference these accessors — those intents use inline string
//  literals instead (see OpenQuizIntent, AnswerQuizIntent).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum WidgetL {
  enum VerbWidget {
    static var name: LocalizedStringResource {
      LocalizedStringResource("Widget.verbOfTheDayName", defaultValue: "Verb of the Day")
    }
    static var description: LocalizedStringResource {
      LocalizedStringResource("Widget.verbOfTheDayDescription", defaultValue: "A daily Spanish verb with its conjugations.")
    }
  }

  enum QuizWidget {
    static var name: LocalizedStringResource {
      LocalizedStringResource("Widget.quizName", defaultValue: "Daily Quiz")
    }
    static var description: LocalizedStringResource {
      LocalizedStringResource("Widget.quizDescription", defaultValue: "Answer a daily conjugation question.")
    }
    static var correct: LocalizedStringResource {
      LocalizedStringResource("Widget.quizCorrect", defaultValue: "Correct!")
    }
    static var incorrect: LocalizedStringResource {
      LocalizedStringResource("Widget.quizIncorrect", defaultValue: "Incorrect")
    }
  }

  enum QuickQuizControl {
    static var name: LocalizedStringResource {
      LocalizedStringResource("Widget.quickQuizName", defaultValue: "Quick Quiz")
    }
    static var description: LocalizedStringResource {
      LocalizedStringResource("Widget.quickQuizDescription", defaultValue: "Start a Conjugar quiz.")
    }
  }

  enum RandomVerbControl {
    static var name: LocalizedStringResource {
      LocalizedStringResource("Widget.randomVerbName", defaultValue: "Random Verb")
    }
    static var description: LocalizedStringResource {
      LocalizedStringResource("Widget.randomVerbDescription", defaultValue: "Open a random Spanish verb.")
    }
  }

  enum LiveActivity {
    static var title: LocalizedStringResource {
      LocalizedStringResource("Widget.liveActivityTitle", defaultValue: "Quiz")
    }
  }
}
