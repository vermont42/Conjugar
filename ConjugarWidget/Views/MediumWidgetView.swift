//
//  MediumWidgetView.swift
//  ConjugarWidget
//
//  systemMedium Verb of the Day: the verb header plus the full presente de
//  indicativo paradigm in two columns.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct MediumWidgetView: View {
  let snapshot: WidgetSnapshot

  private var presente: WidgetParadigm? { snapshot.paradigms.first }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      WidgetVerbHeader(snapshot: snapshot)

      if let presente {
        Text(presente.tenseDisplay)
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(.secondary)
          .lineLimit(1)
        ParadigmGrid(conjugations: presente.conjugations, formSize: 13)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(WidgetDeeplink.verb(snapshot.infinitive))
  }
}

/// A six-form paradigm laid out as a two-column grid.
struct ParadigmGrid: View {
  let conjugations: [WidgetConjugation]
  var formSize: CGFloat = 13

  private let columns = [
    GridItem(.flexible(), spacing: 8, alignment: .leading),
    GridItem(.flexible(), spacing: 8, alignment: .leading)
  ]

  var body: some View {
    LazyVGrid(columns: columns, alignment: .leading, spacing: 2) {
      ForEach(conjugations, id: \.pronoun) { conjugation in
        HStack(spacing: 4) {
          Text(conjugation.pronoun)
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Text(mixedCase: conjugation.form)
            .font(.system(size: formSize, weight: .medium, design: .serif))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
      }
    }
  }
}
