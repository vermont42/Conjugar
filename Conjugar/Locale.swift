//
//  Locale.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/15/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

protocol Locale {
  var locale: String { get }
  var languageCode: String { get }
  var defaultLanguageCode: String { get }
  var regionCode: String { get }
}

extension Locale {
  var locale: String {
    return languageCode + regionCode
  }

  var defaultLanguageCode: String {
    let 🏴󠁧󠁢󠁥󠁮󠁧󠁿👅 = "en"
    return 🏴󠁧󠁢󠁥󠁮󠁧󠁿👅
  }
}
