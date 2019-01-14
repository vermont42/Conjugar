//
//  Settings.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

class Settings {
  private let getterSetter: GetterSetter

  var region: Region {
    didSet {
      if region != oldValue {
        getterSetter.set(key: Settings.regionKey, value: region.rawValue)
      }
    }
  }
  static let regionKey = "region"
  private static let regionDefault: Region = .latinAmerica

  var difficulty: Difficulty {
    didSet {
      if difficulty != oldValue {
        getterSetter.set(key: Settings.difficultyKey, value: difficulty.rawValue)
      }
    }
  }
  static let difficultyKey = "difficulty"
  private static let difficultyDefault: Difficulty = .easy

  var infoDifficulty: Difficulty {
    didSet {
      if infoDifficulty != oldValue {
        getterSetter.set(key: Settings.infoDifficultyKey, value: infoDifficulty.rawValue)
      }
    }
  }
  static let infoDifficultyKey = "infoDifficulty"
  private static let infoDifficultyDefault: Difficulty = .difficult

  var secondSingularBrowse: SecondSingularBrowse {
    didSet {
      if secondSingularBrowse != oldValue {
        getterSetter.set(key: Settings.secondSingularBrowseKey, value: secondSingularBrowse.rawValue)
      }
    }
  }
  static let secondSingularBrowseKey = "secondSingularBrowse"
  private static let secondSingularBrowseDefault: SecondSingularBrowse = .tu

  var secondSingularQuiz: SecondSingularQuiz {
    didSet {
      if secondSingularQuiz != oldValue {
        getterSetter.set(key: Settings.secondSingularQuizKey, value: secondSingularQuiz.rawValue)
      }
    }
  }
  static let secondSingularQuizKey = "secondSingularQuiz"
  private static let secondSingularQuizDefault: SecondSingularQuiz = .tu

  var promptActionCount: Int {
    didSet {
      if promptActionCount != oldValue {
        getterSetter.set(key: Settings.promptActionCountKey, value: "\(promptActionCount)")
      }
    }
  }
  static let promptActionCountKey = "promptActionCount"
  private static let promptActionCountDefault = 0

  var lastReviewPromptDate: Date {
    didSet {
      if lastReviewPromptDate != oldValue {
        getterSetter.set(key: Settings.lastReviewPromptDateKey, value: formatter.string(from: lastReviewPromptDate))
      }
    }
  }
  static let lastReviewPromptDateKey = "lastReviewPromptDate"
  private static let lastReviewPromptDateDefault = Date(timeIntervalSince1970: 0.0)
  private let formatter = DateFormatter()
  private static let format = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"

  var userRejectedGameCenter: Bool {
    didSet {
      if userRejectedGameCenter != oldValue {
        getterSetter.set(key: Settings.userRejectedGameCenterKey, value: "\(userRejectedGameCenter)")
      }
    }
  }
  static let userRejectedGameCenterKey = "userRejectedGameCenter"
  static let userRejectedGameCenterDefault = false

  var didShowGameCenterDialog: Bool {
    didSet {
      if didShowGameCenterDialog != oldValue {
        getterSetter.set(key: Settings.didShowGameCenterDialogKey, value: "\(didShowGameCenterDialog)")
      }
    }
  }
  static let didShowGameCenterDialogKey = "didShowGameCenterDialog"
  static let didShowGameCenterDialogDefault = false

  init(getterSetter: GetterSetter) {
    self.getterSetter = getterSetter

    if let regionString = getterSetter.get(key: Settings.regionKey) {
      region = Region(rawValue: regionString) ?? Settings.regionDefault
    } else {
      region = Settings.regionDefault
      getterSetter.set(key: Settings.regionKey, value: region.rawValue)
    }

    if let difficultyString = getterSetter.get(key: Settings.difficultyKey) {
      difficulty = Difficulty(rawValue: difficultyString) ?? Settings.difficultyDefault
    } else {
      difficulty = Settings.difficultyDefault
      getterSetter.set(key: Settings.difficultyKey, value: difficulty.rawValue)
    }

    if let infoDifficultyString = getterSetter.get(key: Settings.infoDifficultyKey) {
      infoDifficulty = Difficulty(rawValue: infoDifficultyString) ?? Settings.infoDifficultyDefault
    } else {
      infoDifficulty = Settings.infoDifficultyDefault
      getterSetter.set(key: Settings.infoDifficultyKey, value: infoDifficulty.rawValue)
    }

    if let secondSingularBrowseString = getterSetter.get(key: Settings.secondSingularBrowseKey) {
      secondSingularBrowse = SecondSingularBrowse(rawValue: secondSingularBrowseString) ?? Settings.secondSingularBrowseDefault
    } else {
      secondSingularBrowse = Settings.secondSingularBrowseDefault
      getterSetter.set(key: Settings.secondSingularBrowseKey, value: secondSingularBrowse.rawValue)
    }

    if let secondSingularQuizString = getterSetter.get(key: Settings.secondSingularQuizKey) {
      secondSingularQuiz = SecondSingularQuiz(rawValue: secondSingularQuizString) ?? Settings.secondSingularQuizDefault
    } else {
      secondSingularQuiz = Settings.secondSingularQuizDefault
      getterSetter.set(key: Settings.secondSingularQuizKey, value: secondSingularQuiz.rawValue)
    }

    if let promptActionCountString = getterSetter.get(key: Settings.promptActionCountKey) {
      promptActionCount = Int((promptActionCountString as NSString).intValue)
    } else {
      promptActionCount = Settings.promptActionCountDefault
      getterSetter.set(key: Settings.promptActionCountKey, value: "\(promptActionCount)")
    }

    formatter.dateFormat = Settings.format

    if let lastReviewPromptDateString = getterSetter.get(key: Settings.lastReviewPromptDateKey) {
      lastReviewPromptDate = formatter.date(from: lastReviewPromptDateString) ?? Settings.lastReviewPromptDateDefault
    } else {
      lastReviewPromptDate = Settings.lastReviewPromptDateDefault
      getterSetter.set(key: Settings.lastReviewPromptDateKey, value: formatter.string(from: lastReviewPromptDate))
    }

    if let userRejectedGameCenterString = getterSetter.get(key: Settings.userRejectedGameCenterKey) {
      userRejectedGameCenter = Bool((userRejectedGameCenterString as NSString).boolValue)
    } else {
      userRejectedGameCenter = Settings.userRejectedGameCenterDefault
      getterSetter.set(key: Settings.userRejectedGameCenterKey, value: "\(userRejectedGameCenter)")
    }

    if let didShowGameCenterDialogString = getterSetter.get(key: Settings.didShowGameCenterDialogKey) {
      didShowGameCenterDialog = Bool((didShowGameCenterDialogString as NSString).boolValue)
    } else {
      didShowGameCenterDialog = Settings.didShowGameCenterDialogDefault
      getterSetter.set(key: Settings.didShowGameCenterDialogKey, value: "\(didShowGameCenterDialog)")
    }
  }
}
