//
//  WidgetSnapshot.swift
//  Conjugar
//
//  The Codable payload the app precomputes (via the conjugation engine) and hands
//  to the widget as JSON in the App Group container: a week of days (`WidgetWeek`), each a
//  `WidgetSnapshot`. The widget is a pure renderer: it never runs the engine or loads
//  verbModelMap.xml. It only decodes this.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// One day of what the widgets show: the verb of the day and the quiz widget's question.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
  /// The verb of the day as the app shows it, e.g. "tener", or "arrepentirse" for a
  /// reflexive-only verb. The app's `conjugar://verb/` route accepts that form.
  let infinitive: String
  /// Terse English gloss from the verb map, e.g. "to have".
  let gloss: String
  /// The verb's 1-based frequency rank (1 = most common) among all 4,811 verbs. Optional
  /// only so snapshots written before every verb had a rank still decode; the writer always
  /// supplies one. It is inside the 1,000 most frequent verbs except on a My Verbs day
  /// (`VerbDraw`), when the learner's own verb may be rarer.
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
  /// A tap-to-answer quiz question: the first of the day's daily challenge at the learner's level,
  /// or, should the challenge give none, one over the verb of the day.
  let quizQuestion: WidgetQuizQuestion
  /// The day this snapshot is for, `yyyy-MM-dd` as `CalendarDay` names it.
  let dateString: String
}

/// What the app writes into the App Group: the days from the one it was written on to six days
/// after, so that the widgets change at midnight without the app being opened. On the eighth day
/// and after, the widgets keep the last day written.
///
/// The file keeps the shape a single day had. The first day's keys sit at the top level, and the
/// rest go under `laterDays`, so a widget that knows only one day reads the first from a week, and
/// a widget that knows the week reads a file of one day as a week of one. The app's bookkeeping is
/// optional for the same reason, and the widget ignores it.
nonisolated struct WidgetWeek: Codable, Equatable, Sendable {
  /// A My Verbs day's verb, by the map's infinitive (arrepentir, not arrepentirse).
  struct Turn: Codable, Equatable, Sendable {
    let dayNumber: Int
    let verb: String
  }

  /// A moment of a widget's timeline and the day it shows from then.
  struct Moment: Equatable, Sendable {
    let date: Date
    let day: WidgetSnapshot
  }

  let firstDay: WidgetSnapshot
  /// The days after the first, in order.
  let laterDays: [WidgetSnapshot]
  /// For the app: My Verbs as the week was planned from them, sorted, so that a change shows.
  var myVerbs: [String]?
  /// For the app: the My Verbs days among `days` and their verbs.
  let myVerbsTurns: [Turn]?
  /// For the app: the day number on which each verb of My Verbs last had its turn, through the day
  /// the week was written. Later days are only planned, and `myVerbsTurns` holds them.
  let myVerbsShown: [String: Int]?

  init(firstDay: WidgetSnapshot, laterDays: [WidgetSnapshot] = [], myVerbs: [String]? = nil, myVerbsTurns: [Turn]? = nil, myVerbsShown: [String: Int]? = nil) {
    self.firstDay = firstDay
    self.laterDays = laterDays
    self.myVerbs = myVerbs
    self.myVerbsTurns = myVerbsTurns
    self.myVerbsShown = myVerbsShown
  }

  var days: [WidgetSnapshot] {
    [firstDay] + laterDays
  }

  private enum CodingKeys: String, CodingKey {
    case laterDays
    case myVerbs
    case myVerbsTurns
    case myVerbsShown
  }

  init(from decoder: any Decoder) throws {
    firstDay = try WidgetSnapshot(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    laterDays = try container.decodeIfPresent([WidgetSnapshot].self, forKey: .laterDays) ?? []
    myVerbs = try container.decodeIfPresent([String].self, forKey: .myVerbs)
    myVerbsTurns = try container.decodeIfPresent([Turn].self, forKey: .myVerbsTurns)
    myVerbsShown = try container.decodeIfPresent([String: Int].self, forKey: .myVerbsShown)
  }

  func encode(to encoder: any Encoder) throws {
    try firstDay.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(laterDays, forKey: .laterDays)
    try container.encodeIfPresent(myVerbs, forKey: .myVerbs)
    try container.encodeIfPresent(myVerbsTurns, forKey: .myVerbsTurns)
    try container.encodeIfPresent(myVerbsShown, forKey: .myVerbsShown)
  }

  /// The day the widgets show on the date: the last day written for it or before it, or the first
  /// when every day is later, as after the clock is turned back.
  func day(on date: Date) -> WidgetSnapshot {
    let today = CalendarDay.string(for: date)
    return days.last { $0.dateString <= today } ?? firstDay
  }

  /// The day whose quiz question has the ID, which the quiz widget's answer names.
  func day(askingQuestion questionID: String) -> WidgetSnapshot? {
    days.first { $0.quizQuestion.questionID == questionID }
  }

  /// A widget's timeline from `now`: the day shown now, then each later day from its midnight, and
  /// the midnight after the last, when WidgetKit should ask again.
  func timeline(from now: Date) -> (moments: [Moment], reload: Date) {
    let today = CalendarDay.string(for: now)
    var moments = [Moment(date: now, day: day(on: now))]
    for later in days where later.dateString > today {
      guard let start = CalendarDay.start(of: later.dateString), start > now else {
        continue
      }
      moments.append(Moment(date: start, day: later))
    }
    return (moments, CalendarDay.nextMidnight(after: moments.last?.date ?? now))
  }
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
  /// The verb as the app shows it, "arrepentirse" for a reflexive-only verb.
  let infinitive: String
  /// Title-cased tense name shown as the prompt, e.g. "Pretérito".
  let tenseDisplay: String
  /// The pronoun for the asked person, or nil for personless tenses (gerundio).
  let pronoun: String?
  /// The correct form, UPPERCASE-marked, with a reflexive-only verb's pronoun.
  let correctAnswer: String
  /// Up to three distractors, UPPERCASE-marked.
  let wrongAnswers: [String]
  /// Stable id ("yyyy-MM-dd-level-region-person-infinitive" for a challenge's question) — keys the
  /// shuffle and the answer state.
  let questionID: String
}
