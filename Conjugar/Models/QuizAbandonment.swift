//
//  QuizAbandonment.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The quizzes in progress, kept so that the next launch can report one that the app was left
/// during. A quiz writes its entry as it starts and at each question, and removes it when it is
/// quit or reaches its results, so an entry still present at launch belongs to a quiz that ended
/// with the app. Entries are keyed by quiz, since a quiz in a sheet can run beside the Quiz tab's.
enum QuizAbandonment {
  struct Entry: Codable, Equatable {
    let level: String
    let source: String
    /// The question reached, re-asks not counted (`Quiz.questionReached`). Nil for a session that
    /// sends no counts (`QuizScope.sendsQuestionCounts`).
    let questionNumber: Int?
  }

  static let key = "quizzesInProgress"

  static func record(_ entry: Entry, id: String, getterSetter: GetterSetter) {
    var entries = entries(getterSetter: getterSetter)
    guard entries[id] != entry else {
      return
    }
    entries[id] = entry
    store(entries, getterSetter: getterSetter)
  }

  static func clear(id: String, getterSetter: GetterSetter) {
    var entries = entries(getterSetter: getterSetter)
    guard entries.removeValue(forKey: id) != nil else {
      return
    }
    store(entries, getterSetter: getterSetter)
  }

  /// Sends `abandonQuiz` for each quiz the last run left in progress, and forgets them.
  static func reportAndClear(getterSetter: GetterSetter, analytics: Analytics) {
    let entries = entries(getterSetter: getterSetter)
    guard !entries.isEmpty else {
      return
    }
    for entry in entries.values {
      var parameters = [
        ParameterKey.level.rawValue: entry.level,
        ParameterKey.source.rawValue: entry.source
      ]
      if let questionNumber = entry.questionNumber {
        parameters[ParameterKey.questionNumber.rawValue] = "\(questionNumber)"
      }
      analytics.signal(name: .abandonQuiz, parameters: parameters)
    }
    store([:], getterSetter: getterSetter)
  }

  static func entries(getterSetter: GetterSetter) -> [String: Entry] {
    guard
      let data = getterSetter.get(key: key)?.data(using: .utf8),
      let entries = try? JSONDecoder().decode([String: Entry].self, from: data)
    else {
      return [:]
    }
    return entries
  }

  /// `GetterSetter` has no removal, so no entries are stored as an empty string.
  private static func store(_ entries: [String: Entry], getterSetter: GetterSetter) {
    guard !entries.isEmpty else {
      getterSetter.set(key: key, value: "")
      return
    }
    guard
      let data = try? JSONEncoder().encode(entries),
      let string = String(data: data, encoding: .utf8)
    else {
      return
    }
    getterSetter.set(key: key, value: string)
  }
}
