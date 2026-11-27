//
//  ReviewCardView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// An irregular verb looked up or practiced some days ago, offered above the verb list with its
/// key conjugations hidden. A tap anywhere on the card reveals them; after that, a tap opens the
/// verb's page. The ✕ dismisses the card. Which verb, and what each tap does to its schedule, is
/// the caller's.
///
/// The card is one `Button`, so that Full Keyboard Access and Switch Control reach it and VoiceOver
/// finds one element with one action, and the ✕ is a second button beside it rather than inside it.
struct ReviewCardView: View {
  let entry: VerbMapEntry
  /// Whole days since a key conjugation of the verb was last looked up or answered, or nil when
  /// the record does not know.
  let daysSinceActivity: Int?
  /// Whether that was a lookup rather than a quiz answer, which the caption says.
  let wasLookedUp: Bool
  let isRevealed: Bool
  let reveal: () -> Void
  let open: () -> Void
  let dismiss: () -> Void

  private var forms: [String] {
    KeyConjugation.forms(of: entry.infinitive).map(\.form)
  }

  private var caption: String {
    wasLookedUp ? L.ReviewCard.lookedUp(daysAgo: daysSinceActivity) : L.ReviewCard.practiced(daysAgo: daysSinceActivity)
  }

  private func tap() {
    if isRevealed {
      open()
    } else {
      reveal()
    }
  }

  /// The ✕'s 44-point frame reaches into the card's padding, two points from the card's corner, as
  /// it did when it sat on the content and was offset 14 points into the 16-point padding.
  private static let dismissInset: CGFloat = 2

  var body: some View {
    Button(action: tap) {
      VStack(alignment: .leading, spacing: 4) {
        Text(caption)
          .font(.caption.smallCaps())
          .foregroundStyle(.secondary)
          .padding(.trailing, 44)

        Text(spanish: entry.citationForm)
          .serifTitle()

        if !entry.gloss.isEmpty {
          Text(entry.gloss)
            .font(.subheadline)
            .foregroundStyle(Color.customForeground)
        }

        if isRevealed {
          revealedConjugations
        } else {
          hiddenConjugations
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .cardWithAccentBar()
      .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(Self.accessibilityLabel(entry: entry, caption: caption, forms: isRevealed ? forms : nil)))
    .accessibilityHint(Text(isRevealed ? L.ReviewCard.openHint : L.ReviewCard.prompt))
    .accessibilityIdentifier("review_card")
    // The overlay would otherwise come first, so VoiceOver would reach the ✕ before the card.
    .accessibilitySortPriority(1)
    .overlay(alignment: .topTrailing) {
      Button(action: dismiss) {
        Image(systemName: "xmark")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .padding([.top, .trailing], Self.dismissInset)
      .accessibilityLabel(Text(L.ReviewCard.dismiss))
      .accessibilityIdentifier("review_card_dismiss")
    }
    .accessibilityElement(children: .contain)
  }

  /// What VoiceOver reads for the card: the verb and its gloss, the caption, and once revealed the
  /// forms, separated by commas rather than the middle dots it would read aloud. The verb and the
  /// forms are tagged Spanish; the hint says what a tap does.
  static func accessibilityLabel(entry: VerbMapEntry, caption: String, forms: [String]?) -> AttributedString {
    var label = AttributedString(spanish: entry.citationForm)
    if !entry.gloss.isEmpty {
      label.append(AttributedString(", \(entry.gloss)"))
    }
    label.append(AttributedString(". \(caption)."))
    if let forms {
      label.append(AttributedString(" "))
      label.append(AttributedString(spanish: forms.map(ConjugationText.plain).joined(separator: ", ")))
    }
    return label
  }

  private var hiddenConjugations: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: forms.map { $0.lowercased() }.joined(separator: " · "))
        .font(.body)
        .fontDesign(.serif)
        .redacted(reason: .placeholder)

      Text(L.ReviewCard.prompt)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .padding(.top, Layout.defaultSpacing)
  }

  private var revealedConjugations: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(Self.conjugationLine(forms))
        .font(.body)
        .fontDesign(.serif)

      Spacer(minLength: 0)

      Image(systemName: "chevron.right")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
    }
    .padding(.top, Layout.defaultSpacing)
    .transition(.opacity)
  }

  /// The forms with their irregular letters red, joined by middle dots: "tenGo · TUVe · tenDRé ·
  /// tenido" shown as "tengo · tuve · tendré · tenido".
  private static func conjugationLine(_ forms: [String]) -> AttributedString {
    var line = AttributedString()
    for (index, form) in forms.enumerated() {
      if index > 0 {
        var separator = AttributedString(" · ")
        separator.foregroundColor = Color.secondary
        line.append(separator)
      }
      line.append(ConjugationText.attributedString(for: form))
    }
    line.languageIdentifier = "es"
    return line
  }
}
