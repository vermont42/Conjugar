//
//  AdaptiveRows.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// Items that open on a tap: on compact width, a stack of rows, each above a divider, every other
/// one faintly gold; on regular width, an adaptive grid of carded cells. Lazy in both, because the
/// Verbs tab and the regular -ar model hold thousands of verbs. The caller draws each item's label,
/// which learns from `rowLabelStyle` whether it is a row or a card. The Verbs tab's list, the
/// Models tab's models and collections, and `VerbEntryList` use it.
struct AdaptiveRows<Item, ID: Hashable, Label: View>: View {
  let items: [Item]
  /// Each item's identity, which is also what a `ScrollViewProxy` scrolls to.
  let id: KeyPath<Item, ID>
  /// The Models tab's collections, five rows, go without the stripe.
  var isStriped = true
  /// The item the arrow keys have highlighted: a tinted row, or an outlined card.
  var highlighted: ID?
  /// Space around the grid. The rows reach the edges of the screen and pad their own content, so
  /// the stack gets none.
  var gridPadding = EdgeInsets()
  /// An identifier for each item's button, a prefix and the item's key, which the screenshot driver
  /// and the tests tap.
  var accessibilityIdentifier: (prefix: String, key: KeyPath<Item, String>)?
  let open: (Item) -> Void
  let label: (Item) -> Label
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  init(
    _ items: [Item],
    id: KeyPath<Item, ID>,
    isStriped: Bool = true,
    highlighted: ID? = nil,
    gridPadding: EdgeInsets = EdgeInsets(),
    accessibilityIdentifier: (prefix: String, key: KeyPath<Item, String>)? = nil,
    open: @escaping (Item) -> Void,
    @ViewBuilder label: @escaping (Item) -> Label
  ) {
    self.items = items
    self.id = id
    self.isStriped = isStriped
    self.highlighted = highlighted
    self.gridPadding = gridPadding
    self.accessibilityIdentifier = accessibilityIdentifier
    self.open = open
    self.label = label
  }

  var body: some View {
    if horizontalSizeClass == .regular {
      LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
        ForEach(items, id: id) { item in
          button(item) {
            label(item)
              .environment(\.rowLabelStyle, .card)
              .card()
              .overlay {
                if item[keyPath: id] == highlighted {
                  RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Color.customRed, lineWidth: 2)
                }
              }
          }
        }
      }
      .padding(gridPadding)
    } else {
      LazyVStack(spacing: 0) {
        ForEach(numbered) { row in
          // A `Button` gives the row the button trait and a press highlight.
          button(row.item) {
            label(row.item)
              .environment(\.rowLabelStyle, .row)
          }
          .background(Color.listRow(row.index, isStriped: isStriped, isHighlighted: row.id == highlighted))
          Divider().padding(.leading)
        }
      }
    }
  }

  private func button(_ item: Item, @ViewBuilder label: () -> some View) -> some View {
    Button {
      open(item)
    } label: {
      label()
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(identifier(of: item) ?? "", isEnabled: accessibilityIdentifier != nil)
  }

  private func identifier(of item: Item) -> String? {
    accessibilityIdentifier.map { $0.prefix + item[keyPath: $0.key] }
  }

  /// The items with their places, which the stripe counts.
  private var numbered: [Numbered] {
    items.enumerated().map { index, item in
      Numbered(index: index, item: item, id: item[keyPath: id])
    }
  }

  private struct Numbered: Identifiable {
    let index: Int
    let item: Item
    let id: ID
  }
}
