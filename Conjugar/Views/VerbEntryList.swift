//
//  VerbEntryList.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A list of verbs that opens one on a tap: zebra-striped rows on compact width, and an adaptive
/// grid of carded cells, like the Verbs tab's, on regular width. Lazy in both, because the regular
/// -ar model alone holds thousands of verbs. A model's page and a related verb's full list use it.
struct VerbEntryList: View {
  let entries: [VerbMapEntry]
  let onSelect: (String) -> Void
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    if horizontalSizeClass == .regular {
      LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
        ForEach(entries, id: \.infinitive) { entry in
          Button {
            onSelect(entry.infinitive)
          } label: {
            VerbGridCell(entry: entry)
              .card()
          }
          .buttonStyle(.plain)
        }
      }
    } else {
      LazyVStack(spacing: 0) {
        ForEach(Array(entries.enumerated()), id: \.element.infinitive) { index, entry in
          // A `Button` wrapper gives these rows `.isButton` semantics and a press highlight.
          Button {
            onSelect(entry.infinitive)
          } label: {
            VerbRowLabel(entry: entry)
          }
          .buttonStyle(.plain)
          .background(index.isMultiple(of: 2) ? Color.clear : Color.customYellow.opacity(0.03))
          Divider().padding(.leading)
        }
      }
    }
  }
}
