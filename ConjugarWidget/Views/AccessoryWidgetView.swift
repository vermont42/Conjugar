//
//  AccessoryWidgetView.swift
//  ConjugarWidget
//
//  Lock Screen accessory presentations of the Verb of the Day.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import WidgetKit

struct AccessoryRectangularView: View {
  let snapshot: WidgetSnapshot

  private var firstForm: WidgetConjugation? { snapshot.paradigms.first?.conjugations.first }

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(snapshot.infinitive)
        .font(.headline)
        .lineLimit(1)
      Text(snapshot.gloss)
        .font(.caption2)
        .lineLimit(1)
      if let firstForm {
        // Accessory widgets are monochrome-tinted, so drop the color and just show
        // the lowercased form.
        Text(verbatim: "\(firstForm.pronoun) \(firstForm.form.lowercased())")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(WidgetDeeplink.verb(snapshot.infinitive))
  }
}

struct AccessoryInlineView: View {
  let snapshot: WidgetSnapshot

  var body: some View {
    Text(verbatim: "\(snapshot.infinitive) — \(snapshot.gloss)")
      .widgetURL(WidgetDeeplink.verb(snapshot.infinitive))
  }
}
