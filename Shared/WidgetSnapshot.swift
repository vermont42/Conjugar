//
//  WidgetSnapshot.swift
//  Conjugar
//
//  The Codable payload the app precomputes (via the conjugation engine) and hands
//  to the widget as JSON in the App Group container. The widget is a pure renderer:
//  it never runs the engine or loads verbModelMap.xml — it only decodes this.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
  /// The verb of the day, e.g. "tener".
  let infinitive: String
  /// Terse English gloss from the verb map, e.g. "to have".
  let gloss: String
  /// 1-based frequency rank (1 = most common), or nil if outside the top ~1000.
  let frequencyRank: Int?
  /// One entry per displayed tense. `[0]` is always presente de indicativo; the
  /// large widget shows the rest. Forms carry the engine's UPPERCASE irregularity
  /// marking so `Text(mixedCase:)` can color them.
  ///
  /// TODO: the large widget could show an etymology
  /// snippet and an example sentence instead of extra tenses. Spanish verbs don't
  /// carry that data yet. When they do, add `etymologySnippet` / `exampleSpanish` /
  /// `exampleEnglish` fields here, trim `paradigms` back to just the presente, and
  /// update `LargeWidgetView` / `WidgetSnapshotWriter` to match the French layout.
  let paradigms: [WidgetParadigm]
  /// The gerundio (present participle), UPPERCASE-marked.
  let gerundio: String
  /// The participio (past participle), UPPERCASE-marked.
  let participio: String
  /// A tap-to-answer quiz question over the same verb.
  let quizQuestion: WidgetQuizQuestion
  /// The yyyy-MM-dd this snapshot was generated for.
  let dateString: String
}

nonisolated struct WidgetParadigm: Codable, Equatable, Sendable {
  /// Title-cased tense name, e.g. "Presente de Indicativo".
  let tenseDisplay: String
  /// The six persons, in canonical order.
  let conjugations: [WidgetConjugation]
}

nonisolated struct WidgetConjugation: Codable, Equatable, Sendable {
  let pronoun: String
  /// The conjugated form, UPPERCASE letters marking the irregular span.
  let form: String
}

nonisolated struct WidgetQuizQuestion: Codable, Equatable, Sendable {
  let infinitive: String
  /// Title-cased tense name shown as the prompt, e.g. "Pretérito".
  let tenseDisplay: String
  /// The pronoun for the asked person, or nil for personless tenses (gerundio).
  let pronoun: String?
  /// The correct form, UPPERCASE-marked.
  let correctAnswer: String
  /// Up to three distractors, UPPERCASE-marked.
  let wrongAnswers: [String]
  /// Stable id ("yyyy-MM-dd-infinitive") — keys the shuffle and the answer state.
  let questionID: String
}
