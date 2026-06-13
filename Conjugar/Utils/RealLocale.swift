//
//  RealLocale.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/15/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

struct RealLocale: Locale {
  private let none = "none"
  private let NONE = "NONE"

  var languageCode: String {
    NSLocale.current.language.languageCode?.identifier ?? none
  }

  var regionCode: String {
    NSLocale.current.region?.identifier ?? NONE
  }
}
