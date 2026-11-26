//
//  BrowseLayout.swift
//  Conjugar
//
//  Shared grid-column definitions for the iPad (regular-width) layouts. Each
//  list/detail screen reads `@Environment(\.horizontalSizeClass)` and switches between
//  its single-column compact body and a `LazyVGrid` fed from one of these column sets.
//  Adaptive minimums make portrait vs. landscape (and Split View) "just work" — the OS
//  fits more columns as width grows. Also where the two browse tabs put their search fields.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

enum BrowseLayout {
  /// Adaptive columns for the verb / model browse grids (regular width). Conjugar's
  /// rows carry a serif infinitive plus a gloss line, so the minimum is a touch
  /// wider than a bare list's 250.
  static let listColumns = [
    GridItem(.adaptive(minimum: 260), spacing: Layout.doubleDefaultSpacing)
  ]

  /// Where the Verbs and Models tabs put their search fields. iPadOS 26 shrinks `.automatic` into a
  /// toolbar button, which hides the field and ignores a programmatic `.searchFocused`, so the
  /// Verbs tab's letter keys could not reopen it. On iPad, and on a Mac running the app, a drawer
  /// that always shows does neither. The iPhone keeps `.automatic`.
  static let searchPlacement: SearchFieldPlacement = UIDevice.current.userInterfaceIdiom == .pad
    ? .navigationBarDrawer(displayMode: .always)
    : .automatic

  /// Adaptive columns for the Info section-card grid (wider cells for longer titles).
  static let infoColumns = [
    GridItem(.adaptive(minimum: 320), spacing: Layout.doubleDefaultSpacing)
  ]

  /// Fixed two-up for the verb / model detail conjugation-card masonry.
  /// Aligned to the top, so that a short card (an imperative has no yo row) starts level with the
  /// card beside it rather than floating in the middle of the row.
  static let detailColumns = [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)]
}
