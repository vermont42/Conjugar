//
//  GetterSetterReal.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

class GetterSetterReal: GetterSetter {
  private let userDefaults: UserDefaults

  /// The App Group's defaults, given here, hold the learner's record (`LearnerVerbs`) and the
  /// practice record (`PracticeRecord`). The widget extension reads neither; it reads the snapshot
  /// that `WidgetSnapshotWriter` writes. Settings stay in the standard defaults.
  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  func get(key: String) -> String? {
    return userDefaults.string(forKey: key)
  }

  func set(key: String, value: String) {
    userDefaults.set(value, forKey: key)
  }
}
