//
//  ReviewCardView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// An irregular verb looked up some days ago, offered above the verb list with its key
/// conjugations hidden. A tap anywhere on the card reveals them; after that, a tap opens the verb's
/// page. The ✕ dismisses the card. Which verb, and what each tap does to its schedule, is the
/// caller's.
struct ReviewCardView: View {
  let entry: VerbMapEntry
  /// Whole days since the verb was last opened, or nil when the record does not know.
  let daysSinceLookup: Int?
  let isRevealed: Bool
  let reveal: () -> Void
  let open: () -> Void
  let dismiss: () -> Void

  private var forms: [String] {
    KeyConjugation.forms(of: entry.infinitive).map(\.form)
  }

  private func tap() {
    if isRevealed {
      open()
    } else {
      reveal()
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(L.ReviewCard.lookedUp(daysAgo: daysSinceLookup))
        .font(.caption.smallCaps())
        .foregroundStyle(.secondary)
        .padding(.trailing, 44)

      Text(Self.spanish(entry.citationForm))
        .font(.title3)
        .fontDesign(.serif)
        .foregroundStyle(Color.customYellow)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { tap() }

      if !entry.gloss.isEmpty {
        Text(entry.gloss)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
          .accessibilityAddTraits(.isButton)
          .accessibilityAction { tap() }
      }

      if isRevealed {
        revealedConjugations
      } else {
        hiddenConjugations
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .overlay(alignment: .topTrailing) {
      // The button's 44-point frame reaches into the card's padding rather than pushing the
      // infinitive down.
      Button(action: dismiss) {
        Image(systemName: "xmark")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .offset(x: 14, y: -14)
      .accessibilityLabel(Text(L.ReviewCard.dismiss))
      .accessibilityIdentifier("review_card_dismiss")
    }
    .cardWithAccentBar()
    .contentShape(Rectangle())
    .onTapGesture { tap() }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("review_card")
  }

  private var hiddenConjugations: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: forms.map { $0.lowercased() }.joined(separator: " · "))
        .font(.body)
        .fontDesign(.serif)
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)

      Text(L.ReviewCard.prompt)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { tap() }
        .accessibilityIdentifier("review_card_reveal")
    }
    .padding(.top, Layout.defaultSpacing)
  }

  private var revealedConjugations: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(Self.conjugationLine(forms))
        .font(.body)
        .fontDesign(.serif)
        // VoiceOver would read the middle dots aloud, so the label pauses at commas instead.
        .accessibilityLabel(Text(Self.spanish(forms.map(ConjugationText.plain).joined(separator: ", "))))
        .accessibilityHint(Text(L.ReviewCard.openHint))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { tap() }
        .accessibilityIdentifier("review_card_conjugations")

      Spacer(minLength: 0)

      Image(systemName: "chevron.right")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
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

  /// Text that VoiceOver reads with a Spanish voice.
  private static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
  }
}
