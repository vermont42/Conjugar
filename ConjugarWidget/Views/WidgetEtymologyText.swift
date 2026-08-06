//
//  WidgetEtymologyText.swift
//  ConjugarWidget
//
//  The widget's copy of the app's etymology markup: `~…~` marks a bold span (a cited
//  form, root, cognate, or affix), `\n\n` is a paragraph break. This mirrors the app's
//  `EtymologyText` parser but stands alone so the extension needs nothing from the app
//  target. A reconstruction `*` (as in `*~parēscere~`) passes through untouched.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

extension Text {
  /// Build a `Text` from an etymology body, bolding each `~…~` span.
  init(widgetEtymology etymologyString: String) {
    var attributedString = AttributedString()
    let segments = etymologyString.components(separatedBy: "~")
    for (index, segment) in segments.enumerated() {
      var part = AttributedString(segment)
      if index % 2 == 1 {
        part.inlinePresentationIntent = .stronglyEmphasized
      }
      attributedString.append(part)
    }
    self.init(attributedString)
  }
}
