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

  private var userRejectedGameCenter: Bool
  private static let userRejectedGameCenterKey = "userRejectedGameCenter"
  private static let userRejectedGameCenterDefault = false

  private var didShowGameCenterDialog: Bool
  private static let didShowGameCenterDialogKey = "didShowGameCenterDialog"
  private static let didShowGameCenterDialogDefault = false

  private var secondSingularBrowse: SecondSingularBrowse
  private static let secondSingularBrowseKey = "secondSingularBrowse"

  private var secondSingularQuiz: SecondSingularQuiz
  private static let secondSingularQuizKey = "secondSingularQuiz"

  private init() {
    userDefaults = UserDefaults.standard

    if let storedUserRejectedGameCenterString = userDefaults.string(forKey: SettingsManager.userRejectedGameCenterKey) {
      userRejectedGameCenter = (storedUserRejectedGameCenterString as NSString).boolValue
    } else {
      userRejectedGameCenter = SettingsManager.userRejectedGameCenterDefault
      userDefaults.set("\(userRejectedGameCenter)", forKey: SettingsManager.userRejectedGameCenterKey)
      userDefaults.synchronize()
    }

    if let storedDidShowGameCenterDialogString = userDefaults.string(forKey: SettingsManager.didShowGameCenterDialogKey) {
      didShowGameCenterDialog = (storedDidShowGameCenterDialogString as NSString).boolValue
    } else {
      didShowGameCenterDialog = SettingsManager.didShowGameCenterDialogDefault
      userDefaults.set("\(didShowGameCenterDialog)", forKey: SettingsManager.didShowGameCenterDialogKey)
      userDefaults.synchronize()
    }

    if let storedSecondSingularBrowseString = userDefaults.string(forKey: SettingsManager.secondSingularBrowseKey) {
      secondSingularBrowse = SecondSingularBrowse(rawValue: storedSecondSingularBrowseString) ?? .tu
    } else {
      secondSingularBrowse = SecondSingularBrowse()
      userDefaults.set(secondSingularBrowse.rawValue, forKey: SettingsManager.secondSingularBrowseKey)
      userDefaults.synchronize()
    }

    if let storedSecondSingularQuizString = userDefaults.string(forKey: SettingsManager.secondSingularQuizKey) {
      secondSingularQuiz = SecondSingularQuiz(rawValue: storedSecondSingularQuizString) ?? .tu
    } else {
      secondSingularQuiz = SecondSingularQuiz()
      userDefaults.set(secondSingularQuiz.rawValue, forKey: SettingsManager.secondSingularQuizKey)
      userDefaults.synchronize()
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
