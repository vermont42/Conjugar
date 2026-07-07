//
//  VerbOfTheDayWidget.swift
//  ConjugarWidget
//
//  The "Verb of the Day" home-screen + Lock Screen widget. A StaticConfiguration
//  whose timeline holds one entry, refreshing at the next local midnight. All content
//  comes from the app-written snapshot; the widget never runs the engine.
//  Ported from Conjuguer's VerbDuJourWidget.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import WidgetKit

struct VerbOfTheDayEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct VerbOfTheDayProvider: TimelineProvider {
  func placeholder(in context: Context) -> VerbOfTheDayEntry {
    VerbOfTheDayEntry(date: .now, snapshot: SnapshotReader.placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (VerbOfTheDayEntry) -> Void) {
    let snapshot = SnapshotReader.read() ?? SnapshotReader.placeholder
    completion(VerbOfTheDayEntry(date: .now, snapshot: snapshot))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<VerbOfTheDayEntry>) -> Void) {
    let snapshot = SnapshotReader.read() ?? SnapshotReader.placeholder
    let entry = VerbOfTheDayEntry(date: .now, snapshot: snapshot)
    // Add one calendar day (not a flat 86,400 s) so the rollover lands on local
    // midnight even on DST-change days.
    let startOfToday = Calendar.current.startOfDay(for: .now)
    let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86_400)
    completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
  }
}

struct VerbOfTheDayWidget: Widget {
  let kind = "VerbOfTheDayWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: VerbOfTheDayProvider()) { entry in
      VerbOfTheDayEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName(WidgetL.VerbWidget.name)
    .description(WidgetL.VerbWidget.description)
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
  }
}

struct VerbOfTheDayEntryView: View {
  var entry: VerbOfTheDayEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .systemSmall:
      SmallWidgetView(snapshot: entry.snapshot)
    case .systemMedium:
      MediumWidgetView(snapshot: entry.snapshot)
    case .systemLarge:
      LargeWidgetView(snapshot: entry.snapshot)
    case .accessoryRectangular:
      AccessoryRectangularView(snapshot: entry.snapshot)
    case .accessoryInline:
      AccessoryInlineView(snapshot: entry.snapshot)
    default:
      SmallWidgetView(snapshot: entry.snapshot)
    }
  }
}
