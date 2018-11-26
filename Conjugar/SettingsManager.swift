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
}
