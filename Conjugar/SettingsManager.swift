//
//  SettingsManager.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/26/15.
//  Copyright (c) 2015 Josh Adams. All rights reserved.
//

import Foundation

class SettingsManager {
  private static let settingsManager = SettingsManager()
  private var userDefaults: UserDefaults

  private var region: Region
  private static let regionKey = "region"

  private var difficulty: Difficulty
  private static let difficultyKey = "difficulty"

  private var infoDifficulty: Difficulty
  private static let infoDifficultyKey = "infoDifficulty"

  private var userRejectedGameCenter: Bool
  private static let userRejectedGameCenterKey = "userRejectedGameCenter"
  private static let userRejectedGameCenterDefault = false

  private var didShowGameCenterDialog: Bool
  private static let didShowGameCenterDialogKey = "didShowGameCenterDialog"
  private static let didShowGameCenterDialogDefault = false

  private var lastReviewPromptDate: Date
  private static let lastReviewPromptDateKey = "lastReviewPromptDate"
  private static let lastReviewPromptDateDefault = Date(timeIntervalSince1970: 0.0)
  private static let formatter = DateFormatter()

  private var promptActionCount: Int
  private static let promptActionCountKey = "promptActionCount"
  private static let promptActionCountDefault = 0

  private var secondSingularBrowse: SecondSingularBrowse
  private static let secondSingularBrowseKey = "secondSingularBrowse"

  private var secondSingularQuiz: SecondSingularQuiz
  private static let secondSingularQuizKey = "secondSingularQuiz"

  private init() {
    userDefaults = UserDefaults.standard
    SettingsManager.formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"

    if let storedRegionString = userDefaults.string(forKey: SettingsManager.regionKey) {
      region = Region(rawValue: storedRegionString)!
    }
    else {
      region = Region()
      userDefaults.set(region.rawValue, forKey: SettingsManager.regionKey)
      userDefaults.synchronize()
    }

    if let storedDifficultyString = userDefaults.string(forKey: SettingsManager.difficultyKey) {
      difficulty = Difficulty(rawValue: storedDifficultyString)!
    }
    else {
      difficulty = Difficulty()
      userDefaults.set(difficulty.rawValue, forKey: SettingsManager.difficultyKey)
      userDefaults.synchronize()
    }

    if let storedInfoDifficultyString = userDefaults.string(forKey: SettingsManager.infoDifficultyKey) {
      infoDifficulty = Difficulty(rawValue: storedInfoDifficultyString)!
    }
    else {
      infoDifficulty = Difficulty.difficult
      userDefaults.set(infoDifficulty.rawValue, forKey: SettingsManager.infoDifficultyKey)
      userDefaults.synchronize()
    }

    if let storedUserRejectedGameCenterString = userDefaults.string(forKey: SettingsManager.userRejectedGameCenterKey) {
      userRejectedGameCenter = (storedUserRejectedGameCenterString as NSString).boolValue
    }
    else {
      userRejectedGameCenter = SettingsManager.userRejectedGameCenterDefault
      userDefaults.set("\(userRejectedGameCenter)", forKey: SettingsManager.userRejectedGameCenterKey)
      userDefaults.synchronize()
    }

    if let storedDidShowGameCenterDialogString = userDefaults.string(forKey: SettingsManager.didShowGameCenterDialogKey) {
      didShowGameCenterDialog = (storedDidShowGameCenterDialogString as NSString).boolValue
    }
    else {
      didShowGameCenterDialog = SettingsManager.didShowGameCenterDialogDefault
      userDefaults.set("\(didShowGameCenterDialog)", forKey: SettingsManager.didShowGameCenterDialogKey)
      userDefaults.synchronize()
    }

    if let lastReviewPromptDateString = userDefaults.string(forKey: SettingsManager.lastReviewPromptDateKey) {
      lastReviewPromptDate = SettingsManager.formatter.date(from: lastReviewPromptDateString) ?? Date()
    }
    else {
      lastReviewPromptDate = SettingsManager.lastReviewPromptDateDefault
      userDefaults.set(SettingsManager.formatter.string(from: lastReviewPromptDate), forKey: SettingsManager.lastReviewPromptDateKey)
      userDefaults.synchronize()
    }

    if let promptActionCountString = userDefaults.string(forKey: SettingsManager.promptActionCountKey) {
      promptActionCount = Int((promptActionCountString as NSString).intValue)
    }
    else {
      promptActionCount = SettingsManager.promptActionCountDefault
      userDefaults.set("\(promptActionCount)", forKey: SettingsManager.promptActionCountKey)
      userDefaults.synchronize()
    }

    if let storedSecondSingularBrowseString = userDefaults.string(forKey: SettingsManager.secondSingularBrowseKey) {
      secondSingularBrowse = SecondSingularBrowse(rawValue: storedSecondSingularBrowseString)!
    }
    else {
      secondSingularBrowse = SecondSingularBrowse()
      userDefaults.set(secondSingularBrowse.rawValue, forKey: SettingsManager.secondSingularBrowseKey)
      userDefaults.synchronize()
    }

    if let storedSecondSingularQuizString = userDefaults.string(forKey: SettingsManager.secondSingularQuizKey) {
      secondSingularQuiz = SecondSingularQuiz(rawValue: storedSecondSingularQuizString)!
    }
    else {
      secondSingularQuiz = SecondSingularQuiz()
      userDefaults.set(secondSingularQuiz.rawValue, forKey: SettingsManager.secondSingularQuizKey)
      userDefaults.synchronize()
    }
  }

  class func getRegion() -> Region {
    return settingsManager.region
  }
  class func setRegion(_ region: Region) {
    if region != settingsManager.region {
      settingsManager.region = region
      settingsManager.userDefaults.set(region.rawValue, forKey: SettingsManager.regionKey)
      settingsManager.userDefaults.synchronize()
    }
  }

  class func getDifficulty() -> Difficulty {
    return settingsManager.difficulty
  }

  class func setDifficulty(_ difficulty: Difficulty) {
    if difficulty != settingsManager.difficulty {
      settingsManager.difficulty = difficulty
      settingsManager.userDefaults.set(difficulty.rawValue, forKey: SettingsManager.difficultyKey)
      settingsManager.userDefaults.synchronize()
    }
  }

  class func getInfoDifficulty() -> Difficulty {
    return settingsManager.infoDifficulty
  }

  class func setInfoDifficulty(_ infoDifficulty: Difficulty) {
    if infoDifficulty != settingsManager.infoDifficulty {
      settingsManager.infoDifficulty = infoDifficulty
      settingsManager.userDefaults.set(infoDifficulty.rawValue, forKey: SettingsManager.infoDifficultyKey)
      settingsManager.userDefaults.synchronize()
    }
  }

  class func getUserRejectedGameCenter() -> Bool {
    return settingsManager.userRejectedGameCenter
  }

  class func setUserRejectedGameCenter(_ userRejectedGameCenter: Bool) {
    if userRejectedGameCenter != settingsManager.userRejectedGameCenter {
      settingsManager.userRejectedGameCenter = userRejectedGameCenter
      settingsManager.userDefaults.set("\(userRejectedGameCenter)", forKey: SettingsManager.userRejectedGameCenterKey)
      settingsManager.userDefaults.synchronize()
    }
  }
  class func getDidShowGameCenterDialog() -> Bool {
    return settingsManager.didShowGameCenterDialog
  }

  class func setDidShowGameCenterDialog(_ didShowGameCenterDialog: Bool) {
    if didShowGameCenterDialog != settingsManager.didShowGameCenterDialog {
      settingsManager.didShowGameCenterDialog = didShowGameCenterDialog
      settingsManager.userDefaults.set("\(didShowGameCenterDialog)", forKey: SettingsManager.didShowGameCenterDialogKey)
      settingsManager.userDefaults.synchronize()
    }
  }

  class func getLastReviewPromptDate() -> Date {
    return settingsManager.lastReviewPromptDate
  }

  class func setLastReviewPromptDate(_ lastReviewPromptDate: Date) {
    if lastReviewPromptDate != settingsManager.lastReviewPromptDate {
      settingsManager.lastReviewPromptDate = lastReviewPromptDate
      settingsManager.userDefaults.set(SettingsManager.formatter.string(from: lastReviewPromptDate), forKey: SettingsManager.lastReviewPromptDateKey)
      settingsManager.userDefaults.synchronize()
    }
  }

  class func getPromptActionCount() -> Int {
    return settingsManager.promptActionCount
  }

  class func setPromptActionCount(_ promptActionCount: Int) {
    if promptActionCount != settingsManager.promptActionCount {
      settingsManager.promptActionCount = promptActionCount
      settingsManager.userDefaults.set("\(promptActionCount)", forKey: SettingsManager.promptActionCountKey)
      settingsManager.userDefaults.synchronize()
    }
  }

  class func getSecondSingularBrowse() -> SecondSingularBrowse {
    return settingsManager.secondSingularBrowse
  }

  class func setSecondSingularBrowse(_ secondSingularBrowse: SecondSingularBrowse) {
    if secondSingularBrowse != settingsManager.secondSingularBrowse {
      settingsManager.secondSingularBrowse = secondSingularBrowse
      settingsManager.userDefaults.set(secondSingularBrowse.rawValue, forKey: SettingsManager.secondSingularBrowseKey)
      settingsManager.userDefaults.synchronize()
    }
  }

  class func getSecondSingularQuiz() -> SecondSingularQuiz {
    return settingsManager.secondSingularQuiz
  }

  class func setSecondSingularQuiz(_ secondSingularQuiz: SecondSingularQuiz) {
    if secondSingularQuiz != settingsManager.secondSingularQuiz {
      settingsManager.secondSingularQuiz = secondSingularQuiz
      settingsManager.userDefaults.set(secondSingularQuiz.rawValue, forKey: SettingsManager.secondSingularQuizKey)
      settingsManager.userDefaults.synchronize()
    }
  }
}

