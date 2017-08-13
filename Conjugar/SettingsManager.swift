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
}
