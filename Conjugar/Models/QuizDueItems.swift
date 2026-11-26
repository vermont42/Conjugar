//
//  QuizDueItems.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// How the default quiz mixes in items the practice record says are due, so that a learner who
/// never opens a review still relearns.
nonisolated extension QuizDraw {
  /// At most this many of a round's questions come from the record.
  static let dueItemLimit = 3

  /// A question for each due item that the level asks and the band holds, in the record's order,
  /// most overdue first, and at most `limit`. A key conjugation asks the first cell of its verb
  /// that is irregular, built on it, and asked by the level (`PracticeItem.irregularCells`), so
  /// that the answer moves the item back. A pattern asks its cell of a regular verb of its ending
  /// from the band. An item the level does not ask, such as a yo pretérito looked up by a
  /// Beginner, or a looked-up verb beyond the band, waits for a review session, so that the
  /// default quiz stays within its level.
  static func dueQuestions(
    for items: [PracticeItem],
    band frequencyBand: FrequencyBand?,
    asks: (ConjugationCell) -> Bool,
    limit: Int = dueItemLimit,
    using generator: inout some RandomNumberGenerator
  ) -> [QuizQuestion] {
    recordQuestions(for: items, keyConjugationBand: frequencyBand, patternBand: frequencyBand, asks: asks, limit: limit, using: &generator)
      .map(\.question)
  }

  /// A question for each of the first `limit` items that can be asked, with the item it asks. A
  /// key conjugation's verb must be in `keyConjugationBand`, nil for every verb; a pattern's verb
  /// is drawn from `patternBand`.
  static func recordQuestions(
    for items: [PracticeItem],
    keyConjugationBand: FrequencyBand?,
    patternBand: FrequencyBand?,
    asks: (ConjugationCell) -> Bool,
    limit: Int,
    using generator: inout some RandomNumberGenerator
  ) -> [(item: PracticeItem, question: QuizQuestion)] {
    var drawn: [(item: PracticeItem, question: QuizQuestion)] = []
    var regularVerbsByEnding: [String: [String]] = [:]

    for item in items where drawn.count < limit {
      switch item {
      case let .keyConjugation(infinitive, key):
        guard let entry = VerbMap.shared.entry(for: infinitive),
              keyConjugationBand.map(entry.isIn) ?? true,
              let cell = PracticeItem.irregularCells(of: infinitive, builtOn: key).first(where: asks) else {
          continue
        }
        drawn.append((item, QuizQuestion(infinitive, cell.tense, cell.personNumber)))
      case .pattern:
        guard let cell = item.cell, let ending = item.ending, asks(cell) else {
          continue
        }
        let candidates = regularVerbsByEnding[ending.practiceKey] ?? verbs(in: patternBand)
          .filter { !$0.isIrregular && RegularRoot(infinitive: $0.infinitive) == ending }
          .map(\.infinitive)
        regularVerbsByEnding[ending.practiceKey] = candidates
        let used = Set(drawn.map(\.question.verb))
        let fitting = candidates.filter { !used.contains($0) }
        for _ in 0..<attemptsPerPattern {
          guard let verb = fitting.randomElement(using: &generator) else {
            break
          }
          if isIrregular(verb, in: cell) == false {
            drawn.append((item, QuizQuestion(verb, cell.tense, cell.personNumber)))
            break
          }
        }
      }
    }
    return drawn
  }

  /// The drawn questions with the due ones placed among them at random.
  static func mixing(_ due: [QuizQuestion], into drawn: [QuizQuestion], using generator: inout some RandomNumberGenerator) -> [QuizQuestion] {
    var questions = drawn
    for question in due {
      questions.insert(question, at: Int.random(in: 0...questions.count, using: &generator))
    }
    return questions
  }

  private static let attemptsPerPattern = 8
}
