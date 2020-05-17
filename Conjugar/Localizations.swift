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

  static var score: String {
    NSLocalizedString("Score", comment: "")
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
    static var purposeAndUseHeading: String {
      NSLocalizedString("Purpose & Use", comment: "")
    }

    static var purposeAndUseText: String {
      NSLocalizedString("purposeAndUseText", value:
"""
^Purpose^

In Spanish, conjugation, a concept defined in %terminology%, is important for the reasons stated there. People raised in Spanish-speaking countries learn conjugation passively, and people who engage in formal Spanish learn conjugation as part of that study.

But there exists another category of Spanish-learners: people, like the developer of ~Conjugar~, who live in non-Spanish-speaking countries, who are currently unable to engage in formal study of Spanish, but who are exposed to Spanish vocabulary by one means or another. Here is an example of the challenge that these learners face.

The developer of ~Conjugar~ knew, from exposure to Spanish in a previous job, that "ir" means "to go" and that "ir" has certain conjugations starting with "va-". But this knowledge did not allow him to communicate with Spanish-speakers he encountered. For instance, to express the thought "I'm going to the office", he might have said "ir a la oficina" or "va a la oficina". But these sentences were nonsensical to Spanish-speakers because the conjugations were incorrect. The correct (and understandable) sentence was (and is) "$voY$ a la oficina".

There are excellent resources for Spanish-verb conjugation. The website ~SpanishDict.com~ and the book ~Spanish Verbs Made Simple(r)~ are two of them. The developer of ~Conjugar~ used these resources when he wrote Spanish, but they were unavailable when he spoke Spanish extemporaneously. At some point, he realized that he needed a way to practice conjugating Spanish verbs so that correct conjugations sprang to mind when he was speaking.

This was the genesis of ~Conjugar~, the app whose majesty now envelops you. ~Conjugar~ allows you practice conjugating, via quizzes, ~all~ Spanish verb tenses so that correct conjugations are in your brain at the exact moment you need them. ~Conjugar~ gamifies this experience by scoring each practice session and potentially uploading it to Game Center, allowing you to compete against the global Spanish-verb-conjugation community. Some tenses are rare except in archaic or formal texts and are less useful for many learners. ~Conjugar~ therefore provides three difficulty levels for practice sessions. ~Easy~ tests the three most important tenses. ~Moderate~ tests all tenses that Spanish-speakers commonly use. ~Difficult~ tests ~all~ tenses, including a few that you are unlikely to encounter unless you are reading, for example, ~El ingenioso hidalgo don Quixote de la Mancha~.

^Use^

Primary navigation in ~Conjugar~ occurs via the tab bar at the bottom of the screen. Descriptions of these tabs follow.

~Conjugar~ starts on the ~Browse~ tab. This tab has three lists of Spanish verbs: a list of many irregular verbs, a list of many regular verbs, and a list that combines the other two. Swap these lists by tapping a red button above the tab bar. When you find a verb you would like to know more about, tap it. ~Conjugar~ then displays a screen with ~all~ conjugations of that verb. This screen is helpful for learning because it calls out, by highlighting in $RED$, parts of conjugations that are irregular. For example, the %presente de indicativo%, first-person singular conjugation of "dar" has an irregular "y", so ~Conjugar~ displays this conjugation as "$doY$". Tap any conjugation to hear it spoken. Tap ~Browse~ in the top-left corner to return to the ~Browse~ tab.

Tap ~Quiz~ in the tab bar to start a quiz. Tap ~Start~ on the bottom-left corner of the screen. ~Conjugar~ will then present you a set of fifty Spanish verbs to conjugate. Conjugate.

If a letter in a word like "habló" requires an accent mark and you input, for example, "hablo", you will receive partial credit for that conjugation. To input an accented letter, hold your finger on ("long press") the letter you want to accent, "o" in this example, swipe to the accented letter, "ó" in this example, and release.

When you are done with the quiz, ~Conjugar~ will report and score your results, uploading the score to Game Center if it represents a personal best. Tap ~Quiz~ in the top-left corner to return to the ~Quiz~ tab. You can then start a new quiz.

Tap ~Settings~ in the tab bar to access settings.

One class of conjugations, those of ~vosotros~, is important in Spain but largely absent in Latin America. If your goal is to communicate with Latin-American Spanish-speakers, you may want to have ~Conjugar~ omit ~vosotros~ conjugations from quizzes. If so, tap ~Latin America~ in the ~Region~ section.

In recognition of the added difficulty of learning ~vosotros~ conjugations, ~Conjugar~ assigns higher scores to quizzes that include these conjugations.

Spanish verb tenses may be roughly grouped into three classes. The first class consists of the bare minimum of tenses you will need to express yourself in Spanish. If your goal is only to express yourself in Spanish, tap ~Easy~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on these tenses. The second class consists of the tenses that native Spanish speakers regularly use in conversation and writing. If your goal is to understand spoken-and-written Spanish, tap ~Moderate~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on these tenses. The third class consists of all the Spanish verb tenses, including a few that are considered archaic or are rarely used except in formal writing. If your goal is to understand archaic-or-formal Spanish texts, tap ~Difficult~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on ~all~ Spanish verb tenses.

In recognition of the relative difficulties of learning to conjugate the ~Easy~, ~Moderate~, and ~Difficult~ classes of verbs, ~Conjugar~ assigns higher scores to ~Moderate~ quizzes than to ~Easy~ quizzes and assigns higher scores to ~Difficult~ quizzes than to ~Moderate~ quizzes.

As described elsewhere in ~Conjugar~, %voseo% is a phenomenon whereby certain Spanish speakers use the pronoun ~vos~ and its conjugations instead of ~tú~ and its conjugations.

In the ~Settings~ section "Browse Tú and/or Vos", tap "Vos" to see ~vos~ conjugations instead of ~tú~ conjugations on the ~Browse~ tab. Tap "Both" to see both.

In the ~Settings~ section "Quiz Tú or Vos", tap "Vos" to be quizzed on ~vos~, rather than ~tú~, conjugations.

Tap ~Info~ in the tab bar to access information about ~Conjugar~, %terminology%, and the tenses. Near the bottom of the screen is a $RED$ widget for filtering information about tenses by the difficulty mode in which they are quizzed. The three options are ~Easy~; ~Easy~ and ~Moderate~; and ~Easy~, ~Moderate~, and ~Difficult~.
""",
      comment: "")
    }

    static var terminologyHeading: String {
      NSLocalizedString("Terminology", comment: "")
    }

    static var questionsAndAnswersHeading: String {
      NSLocalizedString("Questions & Answers", comment: "")
    }

    static var creditsHeading: String {
      NSLocalizedString("Credits", comment: "")
    }
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

    static var time: String {
      NSLocalizedString("Time", comment: "")
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

    static var addYours: String {
      NSLocalizedString("Add yours!", comment: "")
    }

    static var noRating: String {
      NSLocalizedString("No one has rated this version of Conjugar.", comment: "")
    }
    static var oneRating: String {
      NSLocalizedString("There is one rating for this version of Conjugar.", comment: "")
    }
    static var multipleRatings: String {
      NSLocalizedString("There are %d ratings for this version of Conjugar.", comment: "")
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
