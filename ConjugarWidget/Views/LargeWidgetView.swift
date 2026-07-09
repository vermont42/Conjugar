//
//  LargeWidgetView.swift
//  ConjugarWidget
//
//  systemLarge Verb of the Day: the verb header, every paradigm the snapshot carries
//  (presente + pretérito + futuro), and the gerundio / participio.
//
//  TODO: the large widget could show an etymology snippet and an example sentence
//  under the presente paradigm. When Spanish etymology/example data exists (see
//  WidgetSnapshot's TODO), replace the extra paradigms here with that richer content.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
  let snapshot: WidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      WidgetVerbHeader(snapshot: snapshot)

      ForEach(Array(snapshot.paradigms.enumerated()), id: \.offset) { _, paradigm in
        VStack(alignment: .leading, spacing: 2) {
          Text(paradigm.tenseDisplay)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
          ParadigmGrid(conjugations: paradigm.conjugations, formSize: 12)
        }
      }

      HStack(spacing: 12) {
        nonFinite(label: "gerundio", form: snapshot.gerundio)
        nonFinite(label: "participio", form: snapshot.participio)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(WidgetDeeplink.verb(snapshot.infinitive))
  }

  private func nonFinite(label: String, form: String) -> some View {
    HStack(spacing: 4) {
      Text(label)
        .font(.system(size: 9))
        .foregroundStyle(.secondary)
      Text(mixedCase: form)
        .font(.system(size: 12, weight: .medium, design: .serif))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
  }
}
