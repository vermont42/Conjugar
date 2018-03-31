//
//  Region.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

enum Region: String {
  case spain = "Spain"
  case latinAmerica = "Latin America"
  
  init() {
    self = .spain
  }
  
  var accent: String {
    switch self {
    case .spain:
      return "ES"
    case .latinAmerica:
      return "MX"
    }
  }
  
  var scoreModifier: Double {
    switch self {
    case .spain:
      return 1.0
    case .latinAmerica:
      return 0.833
    }
  }
}
