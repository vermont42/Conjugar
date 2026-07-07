//
//  GradientDivider.swift
//  Conjugar
//
//  A hairline separator that fades in from and out to transparent — the design
//  system's alternative to a plain `Divider()` for splitting sections inside a
//  single `card()`. Ported from Konjugieren. Reads the adaptive color assets, so
//  it is light/dark correct. _(ios-design-agent-skill §5: decorative separators
//  with personality.)_
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct GradientDivider: View {
  var color: Color = .customYellow

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          colors: [.clear, color.opacity(0.3), .clear],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .frame(height: 1)
      .accessibilityHidden(true)
  }
}
