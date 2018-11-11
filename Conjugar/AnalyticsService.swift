//
//  AnalyticsService.swift
//  Conjugar
//
//  Created by Joshua Adams on 10/8/18.
//  Copyright © 2018 Joshua Adams. All rights reserved.
//

import Foundation

@objc protocol AnalyticsService {
  func recordEvent(_ eventName: String, parameters: [String:String]?, metrics: [String:Double]?) -> Void
}
