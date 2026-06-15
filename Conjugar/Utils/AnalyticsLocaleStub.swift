//
//  AnalyticsLocaleStub.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/15/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

struct AnalyticsLocaleStub: AnalyticsLocale {
  var languageCode: String
  var regionCode: String
  private static let english = "en"
  private static let america = "US"

  init(languageCode: String = AnalyticsLocaleStub.english, regionCode: String = AnalyticsLocaleStub.america) {
    self.languageCode = languageCode
    self.regionCode = regionCode
  }
}
