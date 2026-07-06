//
//  ConjugationText.swift
//  Conjugar
//
//  Renders a conjugated form as SwiftUI Text with its irregular span in
//  `customRed` — the SwiftUI equivalent of the legacy `String.conjugatedString`
//  (uppercase letters = irregular). Shared by the Verb, Model, Quiz, and Results
//  screens. Set in a serif face to mark it as linguistic content (audit K9).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct ConjugationText: View {
  /// The engine-marked form (uppercase letters flag the irregular span).
  let form: String
  var regularColor: Color = .customForeground

  var body: some View {
    Text(Self.attributedString(for: form, regularColor: regularColor))
      .fontDesign(.serif)
  }

  /// Build the attributed form: irregular runs red, the rest `regularColor`,
  /// everything lowercased for display.
  static func attributedString(for form: String, regularColor: Color = .customForeground) -> AttributedString {
    guard case .conjugation(let parts) = form.parseConjugationToSegment() else {
      return AttributedString(form.lowercased())
    }
    var result = AttributedString()
    for part in parts {
      switch part {
      case .regular(let text):
        var attr = AttributedString(text)
        attr.foregroundColor = regularColor
        result.append(attr)
      case .irregular(let text):
        var attr = AttributedString(text)
        attr.foregroundColor = Color.customRed
        result.append(attr)
      }
    }
    return result
  }

  /// The plain lowercased form (markup stripped) for speech / accessibility.
  static func plain(_ form: String) -> String {
    form.lowercased()
  }
}
