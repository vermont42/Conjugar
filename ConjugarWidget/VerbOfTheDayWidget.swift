//
//  VerbOfTheDayWidget.swift
//  ConjugarWidget
//
//  The "Verb of the Day" home-screen + Lock Screen widget. A StaticConfiguration
//  whose timeline holds an entry per day of the week the app wrote, each from its local
//  midnight, so that the verb changes daily without the app being opened. All content
//  comes from the app-written snapshot; the widget never runs the engine.
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
    let now = Date.now
    completion(VerbOfTheDayEntry(date: now, snapshot: SnapshotReader.weekOrPlaceholder.day(on: now)))
  }

  /// One entry for today and one from each later day's midnight. After the last day written,
  /// WidgetKit asks again and the last day stays until the app writes a new week.
  func getTimeline(in context: Context, completion: @escaping (Timeline<VerbOfTheDayEntry>) -> Void) {
    let (moments, reload) = SnapshotReader.weekOrPlaceholder.timeline(from: .now)
    let entries = moments.map { VerbOfTheDayEntry(date: $0.date, snapshot: $0.day) }
    completion(Timeline(entries: entries, policy: .after(reload)))
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
