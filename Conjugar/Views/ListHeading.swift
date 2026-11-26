//
//  ListHeading.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// The small-caps line that names or counts a list: "4,811 verbs", "Recent", "Collections". The
/// caller pads it to suit the list.
struct ListHeading: View {
  let text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    Text(text)
      .font(.caption.smallCaps())
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.isHeader)
  }
}
