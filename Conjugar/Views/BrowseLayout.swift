//
//  BrowseLayout.swift
//  Conjugar
//
//  Shared grid-column definitions for the iPad (regular-width) layouts, mirroring
//  the sibling apps Conjuguer/Konjugieren. Each list/detail screen reads
//  `@Environment(\.horizontalSizeClass)` and switches between its single-column
//  compact body and a `LazyVGrid` fed from one of these column sets. Adaptive
//  minimums make portrait vs. landscape (and Split View) "just work" — the OS
//  fits more columns as width grows.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

enum BrowseLayout {
  /// Adaptive columns for the verb / model browse grids (regular width). Conjugar's
  /// rows carry a serif infinitive plus a gloss line, so the minimum is a touch
  /// wider than the siblings' bare 250.
  static let listColumns = [
    GridItem(.adaptive(minimum: 260), spacing: Layout.doubleDefaultSpacing)
  ]

  /// Adaptive columns for the Info section-card grid (wider cells for longer titles).
  static let infoColumns = [
    GridItem(.adaptive(minimum: 320), spacing: Layout.doubleDefaultSpacing)
  ]

  /// Fixed two-up for the verb / model detail conjugation-card masonry.
  static let detailColumns = [GridItem(.flexible()), GridItem(.flexible())]
}
