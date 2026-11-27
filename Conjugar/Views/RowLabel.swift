//
//  RowLabel.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// Whether a `RowLabel` is drawn as a list's row or as a grid's card. `AdaptiveRows` sets it.
enum RowLabelStyle {
  case row
  case card
}

extension EnvironmentValues {
  @Entry var rowLabelStyle = RowLabelStyle.row
}

/// The label of a verb's, a model's, or a collection's row or card: a serif gold title, the lines
/// beneath it, and something at the trailing edge, such as a rank, a pill, or a count. A collection
/// has a symbol as well. `VerbRowLabel`, `ModelRowLabel`, and `VerbCollectionRowLabel` fill it in.
///
/// As a row, the trailing part sits at the end, level with the title, and the row pads itself and
/// is its whole width a tap target. As a card, the trailing part shares the first line with the
/// title, or with the symbol if there is one, and `.card()` supplies the padding. A card fills its
/// grid row's height, so that the cards beside it are as tall.
struct RowLabel<Lines: View, Trailing: View>: View {
  let title: String
  /// A verb's infinitive and a model's exemplar are Spanish; a collection's title is in the app's
  /// language.
  let titleIsSpanish: Bool
  var symbol: String?
  let lines: Lines
  let trailing: Trailing
  @Environment(\.rowLabelStyle) private var style

  init(
    title: String,
    titleIsSpanish: Bool = true,
    symbol: String? = nil,
    @ViewBuilder lines: () -> Lines,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.title = title
    self.titleIsSpanish = titleIsSpanish
    self.symbol = symbol
    self.lines = lines()
    self.trailing = trailing()
  }

  var body: some View {
    switch style {
    case .row:
      row
    case .card:
      card
    }
  }

  /// The title, which VoiceOver reads in a Spanish voice when it is Spanish.
  static func title(_ title: String, isSpanish: Bool) -> AttributedString {
    isSpanish ? AttributedString(spanish: title) : AttributedString(title)
  }

  private var titleText: some View {
    Text(Self.title(title, isSpanish: titleIsSpanish))
      .serifTitle()
  }

  private var row: some View {
    HStack(alignment: .firstTextBaseline, spacing: symbol == nil ? nil : 12) {
      if let symbol {
        symbolImage(symbol)
          .font(.title3)
          .frame(width: 28)
      }

      VStack(alignment: .leading, spacing: 2) {
        titleText
        lines
      }

      Spacer()

      trailing
    }
    .padding(.horizontal)
    // The collections' rows are a little tighter, so that all five leave the models in view.
    .padding(.vertical, symbol == nil ? 12 : 10)
    // The whole row is the tap target. Without a content shape, SwiftUI hit-tests only the drawn
    // text, and a tap in the gap or the padding opens nothing.
    .contentShape(Rectangle())
  }

  private var card: some View {
    // A collection's card has more lines than a verb's or a model's, so they stand further apart.
    VStack(alignment: .leading, spacing: symbol == nil ? 2 : Layout.defaultSpacing) {
      if let symbol {
        HStack {
          symbolImage(symbol)
            .font(.title2)
          Spacer()
          trailing
        }
        titleText
      } else {
        HStack(alignment: .firstTextBaseline) {
          titleText
          Spacer(minLength: Layout.defaultSpacing)
          trailing
        }
      }

      lines
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .contentShape(Rectangle())
  }

  private func symbolImage(_ name: String) -> some View {
    Image(systemName: name)
      .foregroundStyle(Color.customYellow)
      .accessibilityHidden(true)
  }
}
