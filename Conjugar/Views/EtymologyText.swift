//
//  EtymologyText.swift
//  Conjugar
//
//  Renders an etymology body (from `Etymology.text(for:)`) as SwiftUI Text. The
//  markup is intentionally minimal and has its **own** parser — independent of the
//  Info `richTextBlocks` markup — so etymology prose can freely contain `%`, `$`,
//  `^`, etc. without a stray character being misread as Info markup:
//
//    ~…~   bold — every cited word-form, ancestral form, cognate, affix, or root
//    \n\n  paragraph break
//    *     a literal asterisk before a bold run marks a reconstructed form
//          (`*~steh₂-~`); it passes through untouched.
//
//  Set in the reading face (not the serif linguistic face) since it is running
//  prose, with the bolded forms carrying the "language" emphasis.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct EtymologyText: View {
  /// The marked-up etymology body: `~…~` bold, `\n\n` paragraph breaks.
  let text: String

  var body: some View {
    Text(Self.attributedString(for: text))
      .foregroundStyle(Color.customForeground)
      .lineSpacing(4)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Split on the bold marker `~`, toggling emphasis on each boundary. Bold runs get
  /// `.stronglyEmphasized` (composes with the ambient font weight) rather than a fixed
  /// font, so the text still honors Dynamic Type. Everything outside `~…~` — including
  /// the reconstruction `*` — passes through verbatim.
  static func attributedString(for text: String) -> AttributedString {
    var result = AttributedString()
    var isBold = false
    for segment in text.components(separatedBy: String(String.boldMarker)) {
      var piece = AttributedString(segment)
      if isBold {
        piece.inlinePresentationIntent = .stronglyEmphasized
      }
      result.append(piece)
      isBold.toggle()
    }
    return result
  }

  /// The plain text with `~` markup stripped — for accessibility labels and tests.
  static func plain(_ text: String) -> String {
    text.replacingOccurrences(of: String(String.boldMarker), with: "")
  }
}
