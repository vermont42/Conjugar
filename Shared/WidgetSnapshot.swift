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
  /// One entry per displayed tense. `[0]` is always presente de indicativo. The
  /// small/medium sizes show only `[0]`; the large size now shows just the presente
  /// too (freeing room for the example + etymology below), so in practice this holds
  /// a single paradigm — it stays an array so a future size can carry more. Forms
  /// carry the engine's UPPERCASE irregularity marking so `Text(mixedCase:)` can
  /// color them.
  let paradigms: [WidgetParadigm]
  /// The gerundio (present participle), UPPERCASE-marked.
  let gerundio: String
  /// The participio (past participle), UPPERCASE-marked.
  let participio: String
  /// A modern example sentence for the verb (Spanish), or nil if none is on file.
  /// Shown by the large widget. Optional so pre-example snapshots still decode.
  let exampleSpanish: String?
  /// The example's English translation.
  let exampleEnglish: String?
  /// A human-readable attribution for the example — "— Author, Title (year)" for
  /// literature, "Fuente:/Source: …" for statistics, the Claude credit otherwise
  /// (never a raw corpus filename). Baked by the app via `ExampleSource.attribution`.
  let exampleAttribution: String?
  /// A short etymology snippet in `~bold~` markup, truncated to a sentence boundary,
  /// or nil if none is on file. Shown by the large widget.
  let etymologySnippet: String?
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
