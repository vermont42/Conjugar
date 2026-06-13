//
//  IntExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/25/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

extension Int {
  var timeString: String {
    var remainingSeconds = self
    let hours = remainingSeconds / 3600
    remainingSeconds -= hours * 3600
    let minutes = remainingSeconds / 60
    remainingSeconds -= minutes * 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
    } else if minutes > 0 {
      return String(format: "%d:%02d", minutes, remainingSeconds)
    } else {
      return String(format: "%d", remainingSeconds)
    }
  }
}
