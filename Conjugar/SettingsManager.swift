//
//  SettingsManager.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/26/15.
//  Copyright (c) 2015 Josh Adams. All rights reserved.
//
import Foundation
class SettingsManager {
  fileprivate static let settingsManager = SettingsManager()
  fileprivate var userDefaults: UserDefaults

  fileprivate var region: Region
  fileprivate static let regionKey = "region"

  fileprivate var difficulty: Difficulty
  fileprivate static let difficultyKey = "difficulty"
  fileprivate var infoDifficulty: Difficulty
  fileprivate static let infoDifficultyKey = "infoDifficulty"
  fileprivate var userRejectedGameCenter: Bool
  fileprivate static let userRejectedGameCenterKey = "userRejectedGameCenter"
  fileprivate static let userRejectedGameCenterDefault = false
  fileprivate var didShowGameCenterDialog: Bool
  fileprivate static let didShowGameCenterDialogKey = "didShowGameCenterDialog"
  fileprivate static let didShowGameCenterDialogDefault = false

  fileprivate var lastReviewPromptDate: Date
  fileprivate static let lastReviewPromptDateKey = "lastReviewPromptDate"
  fileprivate static let lastReviewPromptDateDefault = Date(timeIntervalSince1970: 0.0)
  fileprivate var promptActionCount: Int
  fileprivate static let promptActionCountKey = "promptActionCount"
  fileprivate static let promptActionCountDefault = 0
  fileprivate init() {
    userDefaults = UserDefaults.standard

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
      lastReviewPromptDate = Date(timeIntervalSince1970: (lastReviewPromptDateString as NSString).doubleValue)
    }
    else {
      lastReviewPromptDate = SettingsManager.lastReviewPromptDateDefault
      userDefaults.set("\(lastReviewPromptDate)", forKey: SettingsManager.lastReviewPromptDateKey)
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
      settingsManager.userDefaults.set("\(lastReviewPromptDate)", forKey: SettingsManager.lastReviewPromptDateKey)
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
}

