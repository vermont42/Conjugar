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
    let nsStringCombined = NSString(string: self)
    guard let nsStrings = NSArray(array: nsStringCombined.components(separatedBy: " ")) as? [NSString] else {
      fatalError("nsStrings was nil.")
    }
    var attStrings: [NSAttributedString] = []
    for nsString in nsStrings {
      let length = nsString.length
      var startIndex = -1
      var endIndex = startIndex
      let uppercaseLetters = NSCharacterSet.uppercaseLetters
      for i in 0 ..< length {
        guard let unicodeScalar = UnicodeScalar(nsString.character(at: i)) else {
          fatalError("unicodeScalar was nil.")
        }
        if uppercaseLetters.contains(unicodeScalar) {
          startIndex = i
          break
        }
      }
      if startIndex != -1 {
        for i in (0 ..< length).reversed() {
          guard let unicodeScalar = UnicodeScalar(nsString.character(at: i)) else {
            fatalError("unicodeScalar was nil.")
          }
          if uppercaseLetters.contains(unicodeScalar) {
            endIndex = i
            break
          }
        }
        let attString = NSMutableAttributedString(string: nsString.lowercased)
        attString.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.red, range: NSRange(location: startIndex, length: endIndex - startIndex + 1))
        attStrings.append(attString)
      } else {
        attStrings.append(NSAttributedString(string: nsString as String))
      }
    }
    var attString: NSAttributedString = attStrings[0]
    for i in 1 ..< attStrings.count {
      attString += (NSAttributedString(string: " " ) + attStrings[i])
    }
    return attString
  }

  func coloredString(color: UIColor) -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: self)
    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0, length: count))
    return attributedString
  }

  var infoString: NSAttributedString {
    let infoString = NSMutableAttributedString(string: self)
    infoString.addAttributes([NSAttributedString.Key.foregroundColor: Colors.yellow, NSAttributedString.Key.font: Fonts.body], range: NSRange(location: 0, length: infoString.length))
    var attributesAndRanges: [(NSAttributedString.Key, Any, NSRange)] = []
    var conjugationRanges: [NSRange] = []
    let centeredStyle = NSMutableParagraphStyle()
    centeredStyle.alignment = .center
    var inHeading = false
    var inSubheading = false
    var inBold = false
    var inConjugation = false
    var inLink = false
    var currentIndex = 0
    var startIndex = 0

    for char in self {
      if char == "*" {
        if inHeading {
          attributesAndRanges.append((NSAttributedString.Key.paragraphStyle, centeredStyle, NSRange(location: startIndex, length: currentIndex - startIndex)))
          attributesAndRanges.append((NSAttributedString.Key.font, Fonts.heading, NSRange(location: startIndex, length: currentIndex - startIndex)))
          inHeading = false
        } else {
          inHeading = true
          startIndex = currentIndex
        }
      }

      if char == "^" {
        if inSubheading {
          attributesAndRanges.append((NSAttributedString.Key.paragraphStyle, centeredStyle, NSRange(location: startIndex, length: currentIndex - startIndex)))
          attributesAndRanges.append((NSAttributedString.Key.font, Fonts.subheading, NSRange(location: startIndex, length: currentIndex - startIndex)))
          inSubheading = false
        } else {
          inSubheading = true
          startIndex = currentIndex
        }
      }

      if char == "~" {
        if inBold {
          attributesAndRanges.append((NSAttributedString.Key.font, Fonts.boldBody, NSRange(location: startIndex, length: currentIndex - startIndex)))
          inBold = false
        } else {
          inBold = true
          startIndex = currentIndex
        }
      }

      if char == "%" {
        if inLink {
          let nsRange = NSRange(location: startIndex + 1, length: (currentIndex - startIndex) - 1)
          guard let range = Range(nsRange, in: self) else {
            fatalError("Could not make Range.")
          }
          var subString = String(self[range])
          let http = "http"
          if subString.prefix(http.count) != http {
            guard let encodedString = subString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
              fatalError("Could not URL encode substring.")
            }
            subString = encodedString
          }
          attributesAndRanges.append((NSAttributedString.Key.link, subString, nsRange))
          inLink = false
        } else {
          inLink = true
          startIndex = currentIndex
        }
      }

      if char == "$" {
        if inConjugation {
          let nsRange = NSRange(location: startIndex + 1, length: (currentIndex - startIndex) - 1)
          conjugationRanges.append(nsRange)
          inConjugation = false
        } else {
          inConjugation = true
          startIndex = currentIndex
        }
      }

      currentIndex += 1
    }

    for triple in attributesAndRanges {
      infoString.addAttribute(triple.0, value: triple.1, range: triple.2)
    }

    for conjugationRange in conjugationRanges {
      let conjugation = infoString.mutableString.substring(with: conjugationRange)
      let attributedString = (conjugation as String).conjugatedString
      infoString.replaceCharacters(in: conjugationRange, with: (self as NSString).substring(with: conjugationRange).lowercased())
      attributedString.enumerateAttribute(NSAttributedString.Key.foregroundColor, in: NSRange(location: 0, length: attributedString.length), options: []) { (value, range, _) -> Void in
        if value != nil {
          let infoRange = NSRange(location: conjugationRange.location + range.location, length: range.length)
          infoString.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.red, range: infoRange)
        }
      }
    }

    ["*", "^", "$", "~", "%"].forEach {
      infoString.mutableString.replaceOccurrences(of: $0, with: "", options: NSString.CompareOptions.caseInsensitive, range: NSRange(location: 0, length: infoString.length))
    }

    return infoString
  }
}
