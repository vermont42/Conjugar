//
//  GetterSetter.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

protocol GetterSetter {
  func get(key: String) -> String?
  func set(key: String, value: String)
}
