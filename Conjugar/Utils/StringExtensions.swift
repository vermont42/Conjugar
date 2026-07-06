//
//  StringExtensions.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/2/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

extension String {
  func replaceFirstOccurence(of oldSubstring: String, with newSubstring: String) -> String {
    if let range = self.range(of: oldSubstring) {
      return self.replacingCharacters(in: range, with: newSubstring)
    }
    return self
  }

  var conjugatedString: NSAttributedString {
    let words = self.components(separatedBy: " ")
    var attStrings: [NSAttributedString] = []
    for word in words {
      var startIndex: Int?
      var endIndex: Int?
      for (i, char) in word.enumerated() {
        if char.isUppercase {
          if startIndex == nil {
            startIndex = i
          }
          endIndex = i
        }
      }
      if let start = startIndex, let end = endIndex {
        let attString = NSMutableAttributedString(string: word.lowercased())
        attString.addAttribute(.foregroundColor, value: Colors.red, range: NSRange(location: start, length: end - start + 1))
        attStrings.append(attString)
      } else {
        attStrings.append(NSAttributedString(string: word))
      }
    }
    var attString: NSAttributedString = attStrings[0]
    for i in 1 ..< attStrings.count {
      attString += (NSAttributedString(string: " ") + attStrings[i])
    }
    return attString
  }

  func coloredString(color: UIColor) -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: self)
    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0, length: count))
    return attributedString
  }
}
