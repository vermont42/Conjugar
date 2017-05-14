//
//  StringExtensions.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/2/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

extension String {
  func replaceFirstOccurence(of oldSubstring: String, with newSubstring: String) -> String {
    if let range = self.range(of: oldSubstring) {
      return self.replacingCharacters(in: range, with: newSubstring)
    }
    return self
  }
  
  var attributedString: NSAttributedString {
    let nsString = NSString(string: self)
    let length = nsString.length
    var startIndex = -1
    var endIndex = startIndex
    let uppercaseLetters = NSCharacterSet.uppercaseLetters
    for i in 0 ..< length {
      if uppercaseLetters.contains(UnicodeScalar(nsString.character(at: i))!) {
        startIndex = i
        break
      }
    }
    if startIndex != -1 {
      for i in (0 ..< length).reversed() {
        if uppercaseLetters.contains(UnicodeScalar(nsString.character(at: i))!) {
          endIndex = i
          break
        }
      }
      let attString = NSMutableAttributedString(string: nsString.lowercased)
      attString.addAttribute(NSForegroundColorAttributeName, value: Colors.red, range:  NSRange(location: startIndex, length: endIndex - startIndex + 1))
      return attString
    }
    else {
      return NSAttributedString(string: self)
    }
  }
}
