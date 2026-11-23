//
//  AnalyticsSpy.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/25/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

nonisolated class AnalyticsSpy: Analytics {
  private(set) var signalNames: [AnalyticsName] = []
  private(set) var signalParameters: [[String: String]] = []

  func initialize(appID: String) {}

  func signal(name: AnalyticsName, parameters: [String: String]) {
    signalNames.append(name)
    signalParameters.append(parameters)
  }
}
