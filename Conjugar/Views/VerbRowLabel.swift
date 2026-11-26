//
//  VerbRowLabel.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// The visual content of a verb row: the serif gold infinitive and the gloss, with a blue
/// frequency-rank badge. The Verbs tab, My Verbs, and every `VerbEntryList` show it.
struct VerbRowLabel: View {
  let entry: VerbMapEntry
  /// What a search matched, if it matched a form. See `MatchLines`.
  var matchLines: [String] = []
  /// A collection's rows check the verbs looked up.
  var isLookedUp = false

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.citationForm)
          .serifTitle()
        if !entry.gloss.isEmpty {
          Text(entry.gloss)
            .font(.subheadline)
            .foregroundStyle(Color.customForeground)
        }
        MatchLines(lines: matchLines)
      }

      Spacer()

      if isLookedUp {
        LookedUpCheck()
      }

      Text(verbatim: "#\(entry.frequencyRank)")
        .font(.caption.monospacedDigit())
        .foregroundStyle(Color.customBlue)
        .accessibilityHidden(true)
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    // The whole row is the tap target. Without a content shape, SwiftUI hit-tests only the drawn
    // text, and a tap in the gap or the padding opens nothing.
    .contentShape(Rectangle())
  }
}

/// The carded variant of a verb row for the regular-width grid: the same infinitive, gloss, and rank
/// as `VerbRowLabel`, laid out to fill a `.card()` cell, with the rank beside the infinitive and no
/// row padding, which the card supplies.
struct VerbGridCell: View {
  let entry: VerbMapEntry
  var matchLines: [String] = []
  var isLookedUp = false

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .firstTextBaseline) {
        Text(entry.citationForm)
          .serifTitle()

        Spacer(minLength: Layout.defaultSpacing)

        if isLookedUp {
          LookedUpCheck()
        }

        Text(verbatim: "#\(entry.frequencyRank)")
          .font(.caption.monospacedDigit())
          .foregroundStyle(Color.customBlue)
          .accessibilityHidden(true)
      }

      if !entry.gloss.isEmpty {
        Text(entry.gloss)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
      }

      MatchLines(lines: matchLines)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

/// The check on a collection's row for a verb looked up, which VoiceOver reads as "Looked up".
struct LookedUpCheck: View {
  var body: some View {
    Image(systemName: "checkmark.circle.fill")
      .font(.subheadline)
      .foregroundStyle(Color.customGreen)
      .accessibilityLabel(L.VerbCollection.lookedUp)
  }
}

/// The forms a search matched, under a row's gloss: "fue: Pretérito (él)". Every word of a line
/// is Spanish, the tense names included, so VoiceOver reads each line in a Spanish voice.
struct MatchLines: View {
  let lines: [String]

  var body: some View {
    ForEach(lines, id: \.self) { line in
      Text(spanish: line)
        .font(.caption)
        .foregroundStyle(Color.customBlue)
        .padding(.top, 2)
    }
  }
}
