//
//  WidgetSnapshotWriter.swift
//  Conjugar
//
//  The one place the conjugation engine is invoked for widget purposes. Deterministically
//  picks a verb of the day and a daily quiz question (both keyed on the date), conjugates
//  them through the app's own engine (VerbMap + TenseBridge), and writes the result as
//  JSON into the App Group container for the widget to render. Ported from Conjuguer's
//  WidgetSnapshotWriter and adapted for Spanish.
//
//  Everything here is `nonisolated`: the engine is pure value-type computation, so the
//  snapshot can be built off the main actor.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import WidgetKit

nonisolated enum WidgetSnapshotWriter {
  /// Reference epoch for the date-based rotation. Any fixed past date works.
  private static let referenceDateString = "2026-01-01"

  /// The six persons shown in a paradigm (Spain vocabulary: tú / vosotros).
  private static let paradigmPersons: [DisplayPersonNumber] = [
    .firstSingular, .secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural
  ]

  /// The tenses shown as paradigms in the Verb of the Day widget. `[0]` (presente) is
  /// the one the small/medium sizes show; the large size shows them all.
  ///
  /// TODO: When Spanish etymology / example-sentence data exists, trim this back to
  /// `[.presenteDeIndicativo]` and surface the richer content instead (see the TODOs in
  /// WidgetSnapshot and LargeWidgetView).
  private static let paradigmTenses: [DisplayTense] = [
    .presenteDeIndicativo, .pretérito, .futuroDeIndicativo
  ]

  /// The tense families a daily quiz question can be drawn from.
  private static let quizTenses: [DisplayTense] = [
    .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo,
    .futuroDeIndicativo, .condicional, .presenteDeSubjuntivo
  ]

  // MARK: - Entry points

  /// Rebuild the snapshot for today and ask WidgetKit to reload every timeline.
  ///
  /// Date-gated (item 14): the verb/quiz content changes once a day, so when the
  /// snapshot already on disk is stamped with today's date this is a no-op — skipping
  /// the rewrite and, crucially, the `reloadAllTimelines()` that would otherwise spend
  /// WidgetKit's refresh budget on every foreground activation for unchanged content.
  static func refresh() {
    let today = dateString(for: Date(), calendar: .current)
    if currentSnapshotDateString() == today { return }
    guard writeSnapshot() else { return }
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// The `dateString` of the snapshot currently on disk, or nil if none is written yet
  /// (or it can't be read/decoded). Decodes the shared `WidgetSnapshot` the app itself
  /// wrote; the widget target's `SnapshotReader` isn't visible here.
  private static func currentSnapshotDateString() -> String? {
    guard
      let url = WidgetConstants.snapshotURL,
      let data = try? Data(contentsOf: url),
      let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    else {
      return nil
    }
    return snapshot.dateString
  }

  /// Build and persist the snapshot for the given day. Returns whether it was written.
  @discardableResult
  static func writeSnapshot(for date: Date = Date()) -> Bool {
    guard
      let url = WidgetConstants.snapshotURL,
      let snapshot = makeSnapshot(for: date),
      let data = try? JSONEncoder().encode(snapshot)
    else {
      return false
    }
    do {
      try data.write(to: url, options: .atomic)
      return true
    } catch {
      return false
    }
  }

  // MARK: - Snapshot construction

  static func makeSnapshot(for date: Date) -> WidgetSnapshot? {
    let calendar = Calendar.current
    let dayOffset = daysSinceReference(to: date, calendar: calendar)
    let dateString = Self.dateString(for: date, calendar: calendar)

    let ranked = rankedVerbs()
    guard !ranked.isEmpty else { return nil }

    // Scramble so consecutive days aren't adjacent in the frequency list.
    let verbIndex = abs(dayOffset &* 127) % ranked.count
    let entry = ranked[verbIndex]
    let infinitive = entry.infinitive

    let paradigms = paradigmTenses.compactMap { paradigm(for: infinitive, tense: $0) }
    let gerundio = markedForm(infinitive: infinitive, tense: .gerundio, personNumber: .none) ?? infinitive
    let participio = markedForm(infinitive: infinitive, tense: .participio, personNumber: .none) ?? infinitive
    let quizQuestion = makeQuizQuestion(infinitive: infinitive, dayOffset: dayOffset, dateString: dateString)

    return WidgetSnapshot(
      infinitive: infinitive,
      gloss: entry.gloss,
      frequencyRank: entry.frequencyRank,
      paradigms: paradigms,
      gerundio: gerundio,
      participio: participio,
      quizQuestion: quizQuestion,
      dateString: dateString
    )
  }

  /// Frequency-ranked verbs only (the ~1000 with a rank), most common first. Sorted
  /// inline rather than via `VerbSort` so this stays `nonisolated` (`VerbSort` is a
  /// plain MainActor-isolated enum).
  private static func rankedVerbs() -> [VerbMapEntry] {
    VerbMap.shared.entries.values
      .filter { $0.frequencyRank != nil }
      .sorted { ($0.frequencyRank ?? 0) < ($1.frequencyRank ?? 0) }
  }

  private static func paradigm(for infinitive: String, tense: DisplayTense) -> WidgetParadigm? {
    let conjugations: [WidgetConjugation] = paradigmPersons.compactMap { person in
      guard let form = markedForm(infinitive: infinitive, tense: tense, personNumber: person) else {
        return nil
      }
      return WidgetConjugation(pronoun: person.pronoun, form: form)
    }
    guard !conjugations.isEmpty else { return nil }
    return WidgetParadigm(tenseDisplay: tense.titleCaseName, conjugations: conjugations)
  }

  // MARK: - Quiz question

  private static func makeQuizQuestion(infinitive: String, dayOffset: Int, dateString: String) -> WidgetQuizQuestion {
    let tense = quizTenses[abs(dayOffset) % quizTenses.count]
    let person = paradigmPersons[abs(dayOffset / quizTenses.count) % paradigmPersons.count]

    let correct = markedForm(infinitive: infinitive, tense: tense, personNumber: person)
      ?? markedForm(infinitive: infinitive, tense: .presenteDeIndicativo, personNumber: .firstSingular)
      ?? infinitive
    let askedTense = markedForm(infinitive: infinitive, tense: tense, personNumber: person) != nil ? tense : .presenteDeIndicativo
    let askedPerson = markedForm(infinitive: infinitive, tense: tense, personNumber: person) != nil ? person : .firstSingular

    let wrongAnswers = distractors(infinitive: infinitive, tense: askedTense, correctPerson: askedPerson, correct: correct)

    return WidgetQuizQuestion(
      infinitive: infinitive,
      tenseDisplay: askedTense.titleCaseName,
      pronoun: askedPerson.pronoun,
      correctAnswer: correct,
      wrongAnswers: wrongAnswers,
      questionID: "\(dateString)-\(infinitive)"
    )
  }

  /// Up to three distractors: the same tense's other persons, then the same person in
  /// other tenses, then a last-resort mangling — all distinct from the correct answer.
  private static func distractors(infinitive: String, tense: DisplayTense, correctPerson: DisplayPersonNumber, correct: String) -> [String] {
    var seen: Set<String> = [correct]
    var result: [String] = []

    func add(_ form: String?) {
      guard result.count < 3, let form, !seen.contains(form) else { return }
      seen.insert(form)
      result.append(form)
    }

    for person in paradigmPersons where person != correctPerson {
      add(markedForm(infinitive: infinitive, tense: tense, personNumber: person))
    }
    for otherTense in quizTenses where otherTense != tense {
      add(markedForm(infinitive: infinitive, tense: otherTense, personNumber: correctPerson))
    }
    var suffix = ""
    while result.count < 3 {
      suffix += "s"
      add(correct.lowercased() + suffix)
    }
    return result
  }

  // MARK: - Engine

  /// A marked (UPPERCASE-irregular) conjugated form, or nil if the engine can't produce it.
  private static func markedForm(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> String? {
    if case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber) {
      return form
    }
    return nil
  }

  // MARK: - Dates

  private static func daysSinceReference(to date: Date, calendar: Calendar) -> Int {
    let today = calendar.startOfDay(for: date)
    guard let reference = referenceDate(calendar: calendar) else { return 0 }
    return calendar.dateComponents([.day], from: reference, to: today).day ?? 0
  }

  private static func referenceDate(calendar: Calendar) -> Date? {
    let parts = referenceDateString.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    var components = DateComponents()
    components.year = parts[0]
    components.month = parts[1]
    components.day = parts[2]
    return calendar.date(from: components)
  }

  private static func dateString(for date: Date, calendar: Calendar) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
  }
}
