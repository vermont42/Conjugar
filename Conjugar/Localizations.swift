//
//  Localizations.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/1/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

// genstrings -o es.lproj *.swift

enum Localizations {
  static var both: String {
    NSLocalizedString("Both", comment: "")
  }

  static var spain: String {
    NSLocalizedString("Spain", comment: "")
  }

  static var latinAmerica: String {
    NSLocalizedString("Latin America", comment: "")
  }

  static var easy: String {
    NSLocalizedString("Easy", comment: "")
  }

  static var moderate: String {
    NSLocalizedString("Moderate", comment: "")
  }

  static var difficult: String {
    NSLocalizedString("Difficult", comment: "")
  }

  enum BrowseInfo {
    static var localizedTitle: String {
      NSLocalizedString("Info", comment: "")
    }

    static var easy: String {
      NSLocalizedString("E", comment: "")
    }

    static var easyAndModerate: String {
      NSLocalizedString("E & M", comment: "")
    }

    static var easyModerateAndDifficult: String {
      NSLocalizedString("E, M, & D", comment: "")
    }

    static var filter: String {
      NSLocalizedString("Filter Tenses by Difficulty", comment: "")
    }
  }

  enum BrowseVerbs {
    static var localizedTitle: String {
      NSLocalizedString("Browse", comment: "")
    }
  }

  enum Info {
  }

  enum Quiz {
    static var localizedTitle: String {
      NSLocalizedString("Quiz", comment: "")
    }

    static var start: String {
      NSLocalizedString("Start", comment: "")
    }

    static var restart: String {
      NSLocalizedString("Restart", comment: "")
    }

    static var gameCenter: String {
      NSLocalizedString("Game Center", comment: "")
    }

    static var gameCenterMessage: String {
      NSLocalizedString("Would you like Conjugar to upload your future scores to Game Center after your quiz? See how you stack up against the global community of conjugators.", comment: "")
    }

    static var no: String {
      NSLocalizedString("No", comment: "")
    }

    static var yes: String {
      NSLocalizedString("Yes", comment: "")
    }

    static var conjugation: String {
      NSLocalizedString("conjugation", comment: "")
    }

    static var verb: String {
      NSLocalizedString("Verb", comment: "")
    }

    static var pronoun: String {
      NSLocalizedString("Pronoun", comment: "")
    }

    static var lastAnswer: String {
      NSLocalizedString("Last Answer", comment: "")
    }

    static var correctAnswer: String {
      NSLocalizedString("Correct Answer", comment: "")
    }

    static var score: String {
      NSLocalizedString("Score", comment: "")
    }

    static var progress: String {
      NSLocalizedString("Progress", comment: "")
    }

    static var elapsed: String {
      NSLocalizedString("Elapsed", comment: "")
    }
  }

  enum Results {
    static var title: String {
      NSLocalizedString("Results", comment: "")
    }
  }

  enum Settings {
    static var localizedTitle: String {
      NSLocalizedString("Settings", comment: "")
    }

    static var region: String {
      NSLocalizedString("Region", comment: "")
    }

    static var regionDescription: String {
      NSLocalizedString("In Latin American mode, quizzes do not include vosotros conjugations. This setting also determines how Conjugar pronounces conjugations.", comment: "")
    }

    static var difficulty: String {
      NSLocalizedString("Difficulty", comment: "")
    }

    static var difficultyDescription: String {
      NSLocalizedString("Moderate-mode quizzes test more tenses than easy-mode quizzes. Difficult-mode quizzes test more tenses than moderate-mode quizzes.", comment: "")
    }

    static var browse: String {
      NSLocalizedString("Browse Tú and/or Vos", comment: "")
    }

    static var browseDescription: String {
      NSLocalizedString("This setting determines whether you see tú conjugations, vos conjugations, or both when you browse verb conjugations.", comment: "")
    }

    static var quiz: String {
      NSLocalizedString("Quiz Tú or Vos", comment: "")
    }

    static var quizDescription: String {
      NSLocalizedString("This setting determines whether Conjugar's quiz mode quizzes you on tú forms or vos forms of verbs.", comment: "")
    }

    static var enable: String {
      NSLocalizedString("Enable", comment: "")
    }

    static var enableDescription: String {
      NSLocalizedString("Conjugar can send future quiz scores to Game Center so that you can see them in the global leaderboard. Tap Enable to enable this.", comment: "")
    }

    static var ratingsAndReviews: String {
      NSLocalizedString("Ratings and Reviews", comment: "")
    }

    static var rateOrReview: String {
      NSLocalizedString("Rate or Review", comment: "")
    }
  }

  enum Verb {
    static var irregular: String {
      NSLocalizedString("Irregular", comment: "")
    }

    static var regular: String {
      NSLocalizedString("Regular", comment: "")
    }

    static var defective: String {
      NSLocalizedString("Defective", comment: "")
    }

    static var notDefective: String {
      NSLocalizedString("Not Defective", comment: "")
    }

    static var irregularWithParent: String {
      NSLocalizedString("Irreg. ☛ %@", comment: "")
    }
  }
}
