//
//  AnalyticsServiceSpy.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/25/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import Foundation

class AnalyticsServiceSpy: AnalyticsService {
  private var fire: (String) -> ()

  init(fire: @escaping (String) -> () = { analytic in print(analytic) }) {
    self.fire = fire
  }

  func recordEvent(_ eventName: String, parameters: [String: String]?, metrics: [String: Double]?) {
    var analytic = eventName
    if let parameters = parameters {
      analytic += " "
      for (key, value) in parameters {
        analytic += key + ": " + value + " "
      }
    }
    fire(analytic)
  }
}
