//
//  WidgetConjugationText.swift
//  ConjugarWidget
//
//  The widget's copy of the app's ConjugationText convention: UPPERCASE letters in a
//  marked form flag the irregular span. Regular letters render in the foreground
//  color, irregular letters in red, and everything is lowercased for display. The
//  colors are hardcoded dynamic (light/dark) copies of the app's `customForeground`
//  / `customRed` assets so the extension needs no shared asset catalog — matching
//  Conjuguer's approach.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import UIKit

private func dynamicColor(light: (r: Double, g: Double, b: Double),
                          dark: (r: Double, g: Double, b: Double)) -> Color {
  Color(uiColor: UIColor { traits in
    let c = traits.userInterfaceStyle == .dark ? dark : light
    return UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1)
  })
}

// customForeground: black in light, white in dark.
private let widgetRegularColor = dynamicColor(
  light: (0x00 / 255, 0x00 / 255, 0x00 / 255),
  dark: (0xFF / 255, 0xFF / 255, 0xFF / 255))

// customRed: #C1001D in both light and dark.
private let widgetIrregularColor = dynamicColor(
  light: (0xC1 / 255, 0x00 / 255, 0x1D / 255),
  dark: (0xC1 / 255, 0x00 / 255, 0x1D / 255))

extension Text {
  /// Build a `Text` from an engine-marked form, coloring the irregular (UPPERCASE)
  /// span red and lowercasing everything for display.
  init(mixedCase markedForm: String) {
    var result = AttributedString()
    var runIsIrregular = false
    var runChars = ""

    func flush() {
      guard !runChars.isEmpty else { return }
      var segment = AttributedString(runChars)
      segment.foregroundColor = runIsIrregular ? widgetIrregularColor : widgetRegularColor
      result.append(segment)
      runChars = ""
    }

    for character in markedForm {
      let isIrregular = character.isLetter && character.isUppercase
      if isIrregular != runIsIrregular {
        flush()
        runIsIrregular = isIrregular
      }
      runChars.append(Character(character.lowercased()))
    }
    flush()

    self.init(result)
  }
}
