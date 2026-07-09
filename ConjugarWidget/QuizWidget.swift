//
//  QuizWidget.swift
//  ConjugarWidget
//
//  The interactive daily-quiz widget. Shows the snapshot's quiz question with
//  tap-to-answer buttons (AnswerQuizIntent); once answered (state stored in the shared
//  defaults suite, keyed to the question id) it flips to a correct/incorrect result.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import WidgetKit

struct QuizEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
  let isAnswered: Bool
  let wasCorrect: Bool
}

struct QuizProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuizEntry {
    QuizEntry(date: .now, snapshot: SnapshotReader.placeholder, isAnswered: false, wasCorrect: false)
  }

  func getSnapshot(in context: Context, completion: @escaping (QuizEntry) -> Void) {
    completion(makeEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuizEntry>) -> Void) {
    // Add one calendar day (not a flat 86,400 s) so the rollover lands on local
    // midnight even on DST-change days.
    let startOfToday = Calendar.current.startOfDay(for: .now)
    let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86_400)
    completion(Timeline(entries: [makeEntry()], policy: .after(nextMidnight)))
  }

  private func makeEntry() -> QuizEntry {
    let snapshot = SnapshotReader.read() ?? SnapshotReader.placeholder
    let (isAnswered, wasCorrect) = readQuizState(snapshot: snapshot)
    return QuizEntry(date: .now, snapshot: snapshot, isAnswered: isAnswered, wasCorrect: wasCorrect)
  }

  // Answer state counts only if it was recorded for the question currently displayed.
  private func readQuizState(snapshot: WidgetSnapshot) -> (isAnswered: Bool, wasCorrect: Bool) {
    guard let defaults = WidgetConstants.sharedDefaults else { return (false, false) }
    let storedID = defaults.string(forKey: WidgetConstants.quizQuestionIDKey) ?? ""
    guard storedID == snapshot.quizQuestion.questionID else { return (false, false) }
    return (defaults.bool(forKey: WidgetConstants.quizAnsweredKey),
            defaults.bool(forKey: WidgetConstants.quizCorrectKey))
  }
}

struct QuizWidget: Widget {
  let kind = "QuizWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuizProvider()) { entry in
      QuizWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName(WidgetL.QuizWidget.name)
    .description(WidgetL.QuizWidget.description)
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
