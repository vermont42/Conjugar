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

  var promptActionCount: Int {
    didSet {
      if let userDefaults = userDefaults, promptActionCount != oldValue {
        userDefaults.set("\(promptActionCount)", forKey: Settings.promptActionCountKey)
      }
    }
  }
  static let promptActionCountKey = "promptActionCount"
  private static let promptActionCountDefault = 0

  private init() {
    userDefaults = UserDefaults.standard
    guard let userDefaults = userDefaults else {
      fatalError("userDefaults was nil.")
    }

    if let promptActionCountString = userDefaults.string(forKey: Settings.promptActionCountKey) {
      promptActionCount = Int((promptActionCountString as NSString).intValue)
    }
    else {
      promptActionCount = Settings.promptActionCountDefault
      userDefaults.set("\(promptActionCount)", forKey: Settings.promptActionCountKey)
    }
  }

  init(customDefaults: [String: Any]) {
    if let promptActionCount = customDefaults[Settings.promptActionCountKey] as? Int {
      self.promptActionCount = promptActionCount
    } else {
      promptActionCount = Settings.promptActionCountDefault
    }
  }
}
