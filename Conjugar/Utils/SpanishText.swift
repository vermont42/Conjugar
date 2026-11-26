//
//  SpanishText.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

extension AttributedString {
  /// Text that VoiceOver reads in a Spanish voice, whatever the app's language.
  init(spanish text: String) {
    self.init(text)
    self.languageIdentifier = "es"
  }
}

extension Text {
  /// Text that VoiceOver reads in a Spanish voice, whatever the app's language.
  init(spanish text: String) {
    self.init(AttributedString(spanish: text))
  }
}
