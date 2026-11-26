//
//  QuizWidget.swift
//  ConjugarWidget
//
//  The interactive daily-quiz widget. Shows the day's quiz question with
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
    let now = Date.now
    completion(makeEntry(date: now, snapshot: SnapshotReader.weekOrPlaceholder.day(on: now)))
  }

  /// One entry for today's question and one from each later day's midnight, each answered only
  /// if its own question was. After the last day written, the last question stays.
  func getTimeline(in context: Context, completion: @escaping (Timeline<QuizEntry>) -> Void) {
    let (moments, reload) = SnapshotReader.weekOrPlaceholder.timeline(from: .now)
    let entries = moments.map { makeEntry(date: $0.date, snapshot: $0.day) }
    completion(Timeline(entries: entries, policy: .after(reload)))
  }

  private func makeEntry(date: Date, snapshot: WidgetSnapshot) -> QuizEntry {
    let (isAnswered, wasCorrect) = readQuizState(snapshot: snapshot)
    return QuizEntry(date: date, snapshot: snapshot, isAnswered: isAnswered, wasCorrect: wasCorrect)
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
