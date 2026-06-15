//
//  AnalyticsLocaleReal.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/15/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

struct AnalyticsLocaleReal: AnalyticsLocale {
  private let none = "none"
  private let NONE = "NONE"

  var languageCode: String {
    Locale.current.language.languageCode?.identifier ?? none
  }

  var regionCode: String {
    Locale.current.region?.identifier ?? NONE
  }
}
