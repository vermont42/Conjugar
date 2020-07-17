//
//  ConjugarWidget.swift
//  ConjugarWidget
//
//  Created by Joshua Adams on 7/14/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import WidgetKit
import SwiftUI
import UIKit
import Intents

struct Provider: IntentTimelineProvider {
  public func snapshot(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let entry = SimpleEntry(date: Date(), configuration: configuration)
    completion(entry)
  }

  public func timeline(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SimpleEntry] = []

    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, configuration: configuration)
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  public let date: Date
  public let configuration: ConfigurationIntent
}

struct PlaceholderView: View {
  var body: some View {
    ZStack {
      Color.black
      Text("Conjugar").foregroundColor(Color(Colors.yellow))
        .modifier(WidgetLabel())
    }
  }
}

struct ConjugarWidgetEntryView: View {
  var entry: Provider.Entry
  var body: some View {
    ZStack {
      Color.black
      VStack {
        Text("Ser ~ Presente").foregroundColor(Color(Colors.yellow))
          .modifier(WidgetLabel())
        Text("~~~~~~~~~~").foregroundColor(Color(Colors.yellow))
          .modifier(WidgetLabel())
        (Text("Yo so").foregroundColor(Color(Colors.yellow)) +
          Text("y").foregroundColor(Color(Colors.red)) +
          Text(".").foregroundColor(Color(Colors.yellow)))
          .modifier(WidgetLabel())
        (Text("Tú ").foregroundColor(Color(Colors.yellow)) +
          Text("eres").foregroundColor(Color(Colors.red)) +
          Text(".").foregroundColor(Color(Colors.yellow)))
          .modifier(WidgetLabel())
        (Text("Vos s").foregroundColor(Color(Colors.yellow)) +
          Text("o").foregroundColor(Color(Colors.red)) +
          Text("s.").foregroundColor(Color(Colors.yellow)))
          .modifier(WidgetLabel())
        (Text("Ella ").foregroundColor(Color(Colors.yellow)) +
          Text("es").foregroundColor(Color(Colors.red)) +
          Text(".").foregroundColor(Color(Colors.yellow)))
          .modifier(WidgetLabel())
        (Text("Nosotros s").foregroundColor(Color(Colors.yellow)) +
          Text("o").foregroundColor(Color(Colors.red)) +
          Text("mos.").foregroundColor(Color(Colors.yellow)))
          .modifier(WidgetLabel())
        (Text("Vosotros s").foregroundColor(Color(Colors.yellow)) +
          Text("o").foregroundColor(Color(Colors.red)) +
          Text("is.").foregroundColor(Color(Colors.yellow)))
          .modifier(WidgetLabel())
        (Text("Ellos s").foregroundColor(Color(Colors.yellow)) +
          Text("o").foregroundColor(Color(Colors.red)) +
          Text("n.").foregroundColor(Color(Colors.yellow)))
          .modifier(WidgetLabel())
      }
    }
  }
}

@main
struct ConjugarWidget: Widget {
  private let kind: String = "ConjugarWidget"

  public var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider(), placeholder: PlaceholderView()) { entry in
      ConjugarWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Conjugar")
    .description("Conjugar")
    .supportedFamilies([.systemLarge])
  }
}

// swiftlint:disable type_name
struct ConjugarWidget_Previews: PreviewProvider {
  static var previews: some View {
    ConjugarWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
      .previewContext(WidgetPreviewContext(family: .systemLarge))
  }
}
