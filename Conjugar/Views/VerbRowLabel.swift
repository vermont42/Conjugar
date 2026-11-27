//
//  VerbRowLabel.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A verb's row or card: the infinitive, the gloss, what a search matched, the check on a verb
/// looked up, and the blue frequency rank. The Verbs tab, My Verbs, and every `VerbEntryList` show
/// it.
struct VerbRowLabel: View {
  let entry: VerbMapEntry
  /// What a search matched, if it matched a form. See `MatchLines`.
  var matchLines: [String] = []
  /// A collection's rows check the verbs looked up.
  var isLookedUp = false

  var body: some View {
    RowLabel(title: entry.citationForm) {
      if !entry.gloss.isEmpty {
        Text(entry.gloss)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
      }
      MatchLines(lines: matchLines)
    } trailing: {
      if isLookedUp {
        LookedUpCheck()
      }

      Text(verbatim: "#\(entry.frequencyRank)")
        .font(.caption.monospacedDigit())
        .foregroundStyle(Color.customBlue)
        .accessibilityHidden(true)
    }
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
