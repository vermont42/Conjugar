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
    let nsStrings = NSArray(array: nsStringCombined.components(separatedBy: " ")) as! [NSString]
    var attStrings: [NSAttributedString] = []
    for nsString in nsStrings {
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
        attString.addAttribute(NSAttributedStringKey.foregroundColor, value: Colors.red, range:  NSRange(location: startIndex, length: endIndex - startIndex + 1))
        attStrings.append(attString)
      }
      else {
        attStrings.append(NSAttributedString(string: nsString as String))
      }
    }
    var attString: NSAttributedString = attStrings[0]
    for i in 1 ..< attStrings.count {
      attString = attString + NSAttributedString(string: " " ) + attStrings[i]
    }
    return attString
  }
  
  func coloredString(color: UIColor) -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: self)
    attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: color, range: NSMakeRange(0, count))
    return attributedString
  }
  
  var infoString: NSAttributedString {
    let infoString = NSMutableAttributedString(string: self)
    infoString.addAttributes([NSAttributedStringKey.foregroundColor: Colors.yellow, NSAttributedStringKey.font: Fonts.body], range: NSMakeRange(0, infoString.length))
    var attributesAndRanges: [(NSAttributedStringKey, Any, NSRange)] = []
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
          attributesAndRanges.append((NSAttributedStringKey.paragraphStyle, centeredStyle, NSMakeRange(startIndex, currentIndex - startIndex)))
          attributesAndRanges.append((NSAttributedStringKey.font, Fonts.heading, NSMakeRange(startIndex, currentIndex - startIndex)))
          inHeading = false
        }
        else {
          inHeading = true
          startIndex = currentIndex
        }
      }
      
      if char == "^" {
        if inSubheading {
          attributesAndRanges.append((NSAttributedStringKey.paragraphStyle, centeredStyle, NSMakeRange(startIndex, currentIndex - startIndex)))
          attributesAndRanges.append((NSAttributedStringKey.font, Fonts.subheading, NSMakeRange(startIndex, currentIndex - startIndex)))
          inSubheading = false
        }
        else {
          inSubheading = true
          startIndex = currentIndex
        }
      }
      
      if char == "~" {
        if inBold {
          attributesAndRanges.append((NSAttributedStringKey.font, Fonts.boldBody, NSMakeRange(startIndex, currentIndex - startIndex)))
          inBold = false
        }
        else {
          inBold = true
          startIndex = currentIndex
        }
      }
      
      if char == "%" {
        if inLink {
          let nsRange = NSMakeRange(startIndex + 1, (currentIndex - startIndex) - 1)
          guard let range = Range(nsRange, in: self) else { fatalError("Could not make Range.") }
          var subString = String(self[range])          
          let http = "http"
          if subString.prefix(http.count) != http {
            guard let encodedString = subString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { fatalError("Could not URL encode substring.") }
            subString = encodedString
          }
          attributesAndRanges.append((NSAttributedStringKey.link, subString, nsRange))
          inLink = false
        }
        else {
          inLink = true
          startIndex = currentIndex
        }
      }
      
      if char == "$" {
        if inConjugation {
          let nsRange = NSMakeRange(startIndex + 1, (currentIndex - startIndex) - 1)
          conjugationRanges.append(nsRange)
          inConjugation = false
        }
        else {
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
      attributedString.enumerateAttribute(NSAttributedStringKey.foregroundColor, in: NSMakeRange(0, attributedString.length), options: []) { (value, range, stop) -> Void in
        if value != nil {
          let infoRange = NSRange(location: conjugationRange.location + range.location, length: range.length)
          infoString.addAttribute(NSAttributedStringKey.foregroundColor, value: Colors.red, range: infoRange)
        }
      }
    }
    
    ["*", "^", "$", "~", "%"].forEach {
    infoString.mutableString.replaceOccurrences(of: $0, with: "", options: NSString.CompareOptions.caseInsensitive, range: NSRange(location: 0, length: infoString.length))
    }
    
    return infoString
  }
}
