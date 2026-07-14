//
//  LargeWidgetView.swift
//  ConjugarWidget
//
//  systemLarge Verb of the Day: the verb header, its non-finite forms, the presente de
//  indicativo paradigm, then a modern example sentence (with a real book/source
//  attribution) and a truncated etymology snippet that fills the remaining space.
//  The extra paradigms (pretérito / futuro) the large widget used to show were dropped
//  to make room for this richer content — mirroring the sibling apps Conjuguer and
//  Konjugieren.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
  let snapshot: WidgetSnapshot

  private var presente: WidgetParadigm? { snapshot.paradigms.first }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      header

      nonFiniteRow

      // The presente paradigm is written with all six persons in canonical order, so
      // column two is column one shifted by three. Guard the fixed indexing so a
      // short/defective paradigm can't crash the widget process.
      if let presente, presente.conjugations.count >= 6 {
        Divider()
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 2) {
          ForEach(0 ..< 3, id: \.self) { row in
            GridRow {
              conjugationCell(presente.conjugations[row])
              conjugationCell(presente.conjugations[row + 3])
            }
          }
        }
      }

      exampleBlock

      etymologyBlock

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(WidgetDeeplink.verb(snapshot.infinitive))
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text(snapshot.infinitive)
        .font(.title3)
        .fontWeight(.bold)
        .fontDesign(.serif)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      Text(verbatim: "— \(snapshot.gloss)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Spacer(minLength: 0)
      if let rank = snapshot.frequencyRank {
        Text(verbatim: "#\(rank)")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(.secondary)
      }
    }
  }

  /// The gerundio / participio, the way Konjugieren shows "pp:" under its header.
  private var nonFiniteRow: some View {
    HStack(spacing: 4) {
      Text(verbatim: "ger")
        .foregroundStyle(.secondary)
      Text(mixedCase: snapshot.gerundio)
        .fontWeight(.medium)
      Text(verbatim: "·")
        .foregroundStyle(.secondary)
      Text(verbatim: "part")
        .foregroundStyle(.secondary)
      Text(mixedCase: snapshot.participio)
        .fontWeight(.medium)
    }
    .font(.caption2)
    .lineLimit(1)
    .minimumScaleFactor(0.6)
  }

  @ViewBuilder private var exampleBlock: some View {
    if let spanish = snapshot.exampleSpanish {
      Divider()
      VStack(alignment: .leading, spacing: 1) {
        Text(spanish)
          .font(.caption)
          .fontDesign(.serif)
          .italic()
          .lineLimit(3)
        if let english = snapshot.exampleEnglish {
          Text(english)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        if let attribution = snapshot.exampleAttribution {
          Text(attribution)
            .font(.system(size: 9))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
      }
    }
  }

  /// No `lineLimit`: the etymology fills whatever vertical space remains and clips at
  /// the widget edge, matching Konjugieren. The snapshot writer already truncated it to
  /// a sentence boundary.
  @ViewBuilder private var etymologyBlock: some View {
    if let etymology = snapshot.etymologySnippet {
      Divider()
      Text(widgetEtymology: etymology)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  private func conjugationCell(_ conjugation: WidgetConjugation) -> some View {
    HStack(spacing: 4) {
      Text(conjugation.pronoun)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(width: 28, alignment: .trailing)
      Text(mixedCase: conjugation.form)
        .font(.caption)
        .fontWeight(.medium)
        .fontDesign(.serif)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
  }
}
