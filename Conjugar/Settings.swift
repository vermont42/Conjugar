//
//  Settings.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/17/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import Foundation

class Settings {
  static let shared = Settings()

  private var userDefaults: UserDefaults?

  var region: Region {
    didSet {
      if let userDefaults = userDefaults, region != oldValue {
        userDefaults.set("\(region.rawValue)", forKey: Settings.regionKey)
      }
    }
  }
  static let regionKey = "region"
  private static let regionDefault: Region = .latinAmerica

  var difficulty: Difficulty {
    didSet {
      if let userDefaults = userDefaults, difficulty != oldValue {
        userDefaults.set("\(difficulty.rawValue)", forKey: Settings.difficultyKey)
      }
    }
  }
  static let difficultyKey = "difficulty"
  private static let difficultyDefault: Difficulty = .easy

  var infoDifficulty: Difficulty {
    didSet {
      if let userDefaults = userDefaults, infoDifficulty != oldValue {
        userDefaults.set("\(infoDifficulty.rawValue)", forKey: Settings.infoDifficultyKey)
      }
    }
  }
  static let infoDifficultyKey = "infoDifficulty"
  private static let infoDifficultyDefault: Difficulty = .difficult

  var secondSingularBrowse: SecondSingularBrowse {
    didSet {
      if let userDefaults = userDefaults, secondSingularBrowse != oldValue {
        userDefaults.set("\(secondSingularBrowse.rawValue)", forKey: Settings.secondSingularBrowseKey)
      }
    }
  }
  static let secondSingularBrowseKey = "secondSingularBrowse"
  private static let secondSingularBrowseDefault: SecondSingularBrowse = .tu

  var secondSingularQuiz: SecondSingularQuiz {
    didSet {
      if let userDefaults = userDefaults, secondSingularQuiz != oldValue {
        userDefaults.set("\(secondSingularQuiz.rawValue)", forKey: Settings.secondSingularQuizKey)
      }
    }
  }
  static let secondSingularQuizKey = "secondSingularQuiz"
  private static let secondSingularQuizDefault: SecondSingularQuiz = .tu

  var promptActionCount: Int {
    didSet {
      if let userDefaults = userDefaults, promptActionCount != oldValue {
        userDefaults.set("\(promptActionCount)", forKey: Settings.promptActionCountKey)
      }
    }
  }
  static let promptActionCountKey = "promptActionCount"
  private static let promptActionCountDefault = 0

  var lastReviewPromptDate: Date {
    didSet {
      if let userDefaults = userDefaults, lastReviewPromptDate != oldValue {
        userDefaults.set(formatter.string(from: lastReviewPromptDate), forKey: Settings.lastReviewPromptDateKey)
      }
    }
  }
  static let lastReviewPromptDateKey = "lastReviewPromptDate"
  private static let lastReviewPromptDateDefault = Date(timeIntervalSince1970: 0.0)
  private let formatter = DateFormatter()
  private static let format = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"

  var userRejectedGameCenter: Bool {
    didSet {
      if let userDefaults = userDefaults, userRejectedGameCenter != oldValue {
        userDefaults.set("\(userRejectedGameCenter)", forKey: Settings.userRejectedGameCenterKey)
      }
    }
  }
  static let userRejectedGameCenterKey = "userRejectedGameCenter"
  static let userRejectedGameCenterDefault = false

  var didShowGameCenterDialog: Bool {
    didSet {
      if let userDefaults = userDefaults, didShowGameCenterDialog != oldValue {
        userDefaults.set("\(didShowGameCenterDialog)", forKey: Settings.didShowGameCenterDialogKey)
      }
    }
  }
  static let didShowGameCenterDialogKey = "didShowGameCenterDialog"
  static let didShowGameCenterDialogDefault = false

  private init() {
    userDefaults = UserDefaults.standard

    guard let userDefaults = userDefaults else {
      fatalError("userDefaults was nil.")
    }

    if let regionString = userDefaults.string(forKey: Settings.regionKey) {
      region = Region(rawValue: regionString) ?? Settings.regionDefault
    } else {
      region = Settings.regionDefault
      userDefaults.set(region.rawValue, forKey: Settings.regionKey)
    }

    if let difficultyString = userDefaults.string(forKey: Settings.difficultyKey) {
      difficulty = Difficulty(rawValue: difficultyString) ?? Settings.difficultyDefault
    } else {
      difficulty = Settings.difficultyDefault
      userDefaults.set(difficulty.rawValue, forKey: Settings.difficultyKey)
    }

    if let infoDifficultyString = userDefaults.string(forKey: Settings.infoDifficultyKey) {
      infoDifficulty = Difficulty(rawValue: infoDifficultyString) ?? Settings.infoDifficultyDefault
    } else {
      infoDifficulty = Settings.infoDifficultyDefault
      userDefaults.set(infoDifficulty.rawValue, forKey: Settings.infoDifficultyKey)
    }

    if let secondSingularBrowseString = userDefaults.string(forKey: Settings.secondSingularBrowseKey) {
      secondSingularBrowse = SecondSingularBrowse(rawValue: secondSingularBrowseString) ?? Settings.secondSingularBrowseDefault
    } else {
      secondSingularBrowse = Settings.secondSingularBrowseDefault
      userDefaults.set(secondSingularBrowse.rawValue, forKey: Settings.secondSingularBrowseKey)
    }

    if let secondSingularQuizString = userDefaults.string(forKey: Settings.secondSingularQuizKey) {
      secondSingularQuiz = SecondSingularQuiz(rawValue: secondSingularQuizString) ?? Settings.secondSingularQuizDefault
    } else {
      secondSingularQuiz = Settings.secondSingularQuizDefault
      userDefaults.set(secondSingularQuiz.rawValue, forKey: Settings.secondSingularQuizKey)
    }

    if let promptActionCountString = userDefaults.string(forKey: Settings.promptActionCountKey) {
      promptActionCount = Int((promptActionCountString as NSString).intValue)
    } else {
      promptActionCount = Settings.promptActionCountDefault
      userDefaults.set("\(promptActionCount)", forKey: Settings.promptActionCountKey)
    }

    formatter.dateFormat = Settings.format

    if let lastReviewPromptDateString = userDefaults.string(forKey: Settings.lastReviewPromptDateKey) {
      lastReviewPromptDate = formatter.date(from: lastReviewPromptDateString) ?? Date()
    } else {
      lastReviewPromptDate = Settings.lastReviewPromptDateDefault
      userDefaults.set(formatter.string(from: lastReviewPromptDate), forKey: Settings.lastReviewPromptDateKey)
    }

    if let userRejectedGameCenterString = userDefaults.string(forKey: Settings.userRejectedGameCenterKey) {
      userRejectedGameCenter = Bool((userRejectedGameCenterString as NSString).boolValue)
    } else {
      userRejectedGameCenter = Settings.userRejectedGameCenterDefault
      userDefaults.set("\(userRejectedGameCenter)", forKey: Settings.userRejectedGameCenterKey)
    }

    if let didShowGameCenterDialogString = userDefaults.string(forKey: Settings.didShowGameCenterDialogKey) {
      didShowGameCenterDialog = Bool((didShowGameCenterDialogString as NSString).boolValue)
    } else {
      didShowGameCenterDialog = Settings.didShowGameCenterDialogDefault
      userDefaults.set("\(didShowGameCenterDialog)", forKey: Settings.didShowGameCenterDialogKey)
    }
  }

  init(customDefaults: [String: Any]) {
    if let region = Region(rawValue: (customDefaults[Settings.regionKey] as? String) ?? "") {
      self.region = region
    } else {
      region = Settings.regionDefault
    }

    if let difficulty = Difficulty(rawValue: (customDefaults[Settings.difficultyKey] as? String) ?? "") {
      self.difficulty = difficulty
    } else {
      difficulty = Settings.difficultyDefault
    }

    if let infoDifficulty = Difficulty(rawValue: (customDefaults[Settings.infoDifficultyKey] as? String) ?? "") {
      self.infoDifficulty = infoDifficulty
    } else {
      infoDifficulty = Settings.infoDifficultyDefault
    }

    if let secondSingularBrowse = SecondSingularBrowse(rawValue: (customDefaults[Settings.secondSingularBrowseKey] as? String) ?? "") {
      self.secondSingularBrowse = secondSingularBrowse
    } else {
      secondSingularBrowse = Settings.secondSingularBrowseDefault
    }

    if let secondSingularQuiz = SecondSingularQuiz(rawValue: (customDefaults[Settings.secondSingularQuizKey] as? String) ?? "") {
      self.secondSingularQuiz = secondSingularQuiz
    } else {
      secondSingularQuiz = Settings.secondSingularQuizDefault
    }

    if let promptActionCount = customDefaults[Settings.promptActionCountKey] as? Int {
      self.promptActionCount = promptActionCount
    } else {
      promptActionCount = Settings.promptActionCountDefault
    }

    formatter.dateFormat = Settings.format

    if let lastReviewPromptDate = formatter.date(from: (customDefaults[Settings.lastReviewPromptDateKey] as? String ?? "")) {
      self.lastReviewPromptDate = lastReviewPromptDate
    } else {
      lastReviewPromptDate = Settings.lastReviewPromptDateDefault
    }

    if let userRejectedGameCenter = customDefaults[Settings.userRejectedGameCenterKey] as? Bool {
      self.userRejectedGameCenter = userRejectedGameCenter
    } else {
      userRejectedGameCenter = Settings.userRejectedGameCenterDefault
    }

    if let didShowGameCenterDialog = customDefaults[Settings.didShowGameCenterDialogKey] as? Bool {
      self.didShowGameCenterDialog = didShowGameCenterDialog
    } else {
      didShowGameCenterDialog = Settings.didShowGameCenterDialogDefault
    }
  }
}
