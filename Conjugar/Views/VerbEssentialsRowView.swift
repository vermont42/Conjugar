//
//  VerbEssentialsRowView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A row of Verb Essentials other than the one the answer field asks: a key conjugation already
/// answered, with how it went, one given in a re-ask, or one still to come. The answer field's own
/// row is drawn by `QuizView`, which keeps the field in one place in its hierarchy, so that the
/// keyboard stays up as the field moves down the rows.
struct VerbEssentialsRowView: View {
  let row: VerbEssentialsRow

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      VerbEssentialsRowLabel(key: row.key)

      HStack(spacing: Layout.defaultSpacing) {
        if let pronoun = row.key.pronoun {
          Text(spanish: pronoun)
            .fontWeight(.semibold)
            .foregroundStyle(Color.customForeground)
        }
        content
      }
      .font(.title3)
      .fontDesign(.serif)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spokenRow)
  }

  @ViewBuilder
  private var content: some View {
    switch row.content {
    case .answered(let form, let result):
      ConjugationText(form: form)
      Spacer(minLength: 0)
      Self.icon(for: result)
    case .given(let form):
      ConjugationText(form: form, regularColor: .secondary)
      Spacer(minLength: 0)
    case .pending:
      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        .frame(height: 36)
    case .current:
      EmptyView()
    }
  }

  @ViewBuilder
  private static func icon(for result: ConjugationResult) -> some View {
    switch result {
    case .totalMatch:
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(Color.customGreen)
    case .secondAttemptMatch:
      Image(systemName: "circle.lefthalf.filled")
        .foregroundStyle(Color.customYellow)
    case .noMatch:
      Image(systemName: "xmark.circle.fill")
        .foregroundStyle(Color.customRed)
    }
  }

  /// "pretérito, yo tuve, right", or for a row to come, "participio, not yet asked", the Spanish
  /// read in Spanish.
  private var spokenRow: Text {
    let name = Text(spanish: row.key.tense.displayName)
    let lead = row.key.pronoun.map { $0 + " " } ?? ""
    switch row.content {
    case .answered(let form, let result):
      return name + Text(verbatim: ", ") + Text(spanish: lead + form.lowercased()) + Text(verbatim: ", ") + Text(Self.spokenResult(result))
    case .given(let form):
      return name + Text(verbatim: ", ") + Text(spanish: lead + form.lowercased())
    case .pending:
      return name + Text(verbatim: ", ") + Text(L.VerbEssentials.spokenPending)
    case .current:
      return name
    }
  }

  private static func spokenResult(_ result: ConjugationResult) -> String {
    switch result {
    case .totalMatch:
      return L.VerbEssentials.spokenRight
    case .secondAttemptMatch:
      return L.Results.secondTry
    case .noMatch:
      return L.VerbEssentials.spokenWrong
    }
  }
}

/// The tense a row asks, above its conjugation.
struct VerbEssentialsRowLabel: View {
  let key: KeyConjugation

  var body: some View {
    Text(spanish: key.tense.displayName)
      .font(.subheadline.weight(.semibold))
      .fontDesign(.serif)
      .foregroundStyle(Color.customYellow)
  }
}

extension KeyConjugation {
  /// The subject pronoun a row shows before its conjugation, yo, or nil for the participio.
  var pronoun: String? {
    personNumber == .none ? nil : personNumber.pronoun
  }
}
