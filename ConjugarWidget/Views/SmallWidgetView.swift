//
//  SmallWidgetView.swift
//  ConjugarWidget
//
//  systemSmall Verb of the Day: the verb, its gloss, and the first three present-
//  tense forms.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct SmallWidgetView: View {
  let snapshot: WidgetSnapshot

  private var presente: WidgetParadigm? { snapshot.paradigms.first }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      WidgetVerbHeader(snapshot: snapshot)

      if let presente {
        VStack(alignment: .leading, spacing: 1) {
          ForEach(presente.conjugations.prefix(3), id: \.pronoun) { conjugation in
            HStack(spacing: 4) {
              Text(conjugation.pronoun)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
              Text(mixedCase: conjugation.form)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
          }
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(WidgetDeeplink.verb(snapshot.infinitive))
  }
}

/// The verb + gloss + frequency-rank line shared by the home-screen sizes.
struct WidgetVerbHeader: View {
  let snapshot: WidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(snapshot.infinitive)
          .font(.headline)
          .fontDesign(.serif)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        if let rank = snapshot.frequencyRank {
          Text(verbatim: "#\(rank)")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
        }
      }
      Text(snapshot.gloss)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
  }
}
