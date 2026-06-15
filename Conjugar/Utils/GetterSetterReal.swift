//
//  GetterSetterReal.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

class GetterSetterReal: GetterSetter {
  private let userDefaults = UserDefaults.standard

  func get(key: String) -> String? {
    return userDefaults.string(forKey: key)
  }

  func set(key: String, value: String) {
    userDefaults.set(value, forKey: key)
  }
}
