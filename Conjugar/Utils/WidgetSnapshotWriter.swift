//
//  WidgetSnapshotWriter.swift
//  Conjugar
//
//  The one place the conjugation engine is invoked for widget purposes. Deterministically
//  picks a verb of the day (`VerbDraw`, from the frequent verbs and My Verbs) and a daily
//  quiz question (the first of the day's challenge at the learner's level) for today and the
//  six days after, conjugates them through the app's own engine (VerbMap + TenseBridge), and
//  writes the week as JSON into the App Group container for the widget to render.
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

  /// The tenses shown as paradigms in the Verb of the Day widget. Only presente de
  /// indicativo now: every size (small/medium show it in a grid, large shows it plus
  /// the example sentence + etymology below). The array shape is retained so a future
  /// size can carry more paradigms without a model change.
  private static let paradigmTenses: [DisplayTense] = [
    .presenteDeIndicativo
  ]

  /// What the quiz widget's question follows: the learner's level, region, and tú or vos, which
  /// the caller reads from the settings on the main actor.
  struct ChallengeContext: Equatable, Sendable {
    let level: QuizLevel
    let region: Region
    let secondSingular: DisplayPersonNumber

    static let initial = ChallengeContext(level: .initial, region: .latinAmerica, secondSingular: .secondSingularTú)
  }

  /// The tense families the fallback quiz question can be drawn from, should a day's challenge
  /// give none.
  private static let quizTenses: [DisplayTense] = [
    .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo,
    .futuroDeIndicativo, .condicional, .presenteDeSubjuntivo
  ]

  /// How many days a week holds: the day it is written and the six after.
  static let weekLength = 7

  /// Rebuild the week from today and ask WidgetKit to reload every timeline. `myVerbs` names the
  /// learner's My Verbs by infinitive (`LearnerVerbs.myVerbs`), which the caller reads on the main
  /// actor; they are resolved here, off it, and only when a week is written.
  ///
  /// Gated: when the week on disk is current (`isCurrent`), this does nothing, skipping the rewrite
  /// and, crucially, the `reloadAllTimelines()` that would otherwise spend WidgetKit's refresh
  /// budget on every foreground activation for unchanged content. A new day, a change to My
  /// Verbs, or a change of level, region, or tú or vos rewrites it. Today's verb survives a
  /// rewrite (`makeWeek`), so the first write of a day settles it.
  static func refresh(myVerbs: [String] = [], challenge: ChallengeContext = .initial) {
    let now = Date()
    let previous = currentWeek()
    if let previous, isCurrent(previous, on: now, myVerbs: myVerbs, challenge: challenge) {
      return
    }
    let myVerbEntries = myVerbs.compactMap { VerbMap.shared.entry(for: $0) }
    guard var week = makeWeek(for: now, myVerbs: myVerbEntries, challenge: challenge, previous: previous) else {
      return
    }
    // The names as given, so that the gate can compare them without loading the verb map, even
    // when one no longer resolves.
    week.myVerbs = myVerbs.sorted()
    guard write(week) else {
      return
    }
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Whether the week needs no rewrite on the date: it begins that day, it was planned from the
  /// same My Verbs in any order, and its first question is of the challenge at the same level,
  /// region, and tú or vos. My Verbs is compared because the week plans six days ahead: without
  /// it, a verb just opened would wait for the next day the app is opened to be planned, and a
  /// verb removed could still come up.
  static func isCurrent(_ week: WidgetWeek, on date: Date, myVerbs: [String], challenge: ChallengeContext) -> Bool {
    week.firstDay.dateString == CalendarDay.string(for: date)
      && week.myVerbs == myVerbs.sorted()
      && week.firstDay.quizQuestion.questionID.hasPrefix(questionIDPrefix(on: date, challenge: challenge))
  }

  /// The week on disk, or nil if none is written yet (or it can't be read/decoded). Decodes the
  /// shared `WidgetWeek` the app itself wrote; the widget target's `SnapshotReader` isn't visible
  /// here. A file that an earlier build wrote, of one day, reads as a week of one day.
  private static func currentWeek() -> WidgetWeek? {
    guard
      let url = WidgetConstants.snapshotURL,
      let data = try? Data(contentsOf: url)
    else {
      return nil
    }
    return try? JSONDecoder().decode(WidgetWeek.self, from: data)
  }

  /// Persist the week. Returns whether it was written.
  private static func write(_ week: WidgetWeek) -> Bool {
    guard
      let url = WidgetConstants.snapshotURL,
      let data = try? JSONEncoder().encode(week)
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

  /// The week from the date's day: that day and the six after, each with its verb of the day
  /// (`VerbDraw`) and the quiz widget's question. When `previous` already has the date's day, that
  /// day keeps its verb, so that opening the app never changes the verb the widget has shown since
  /// midnight; its question follows `challenge`. The later days are planned afresh from
  /// `myVerbs`, each My Verbs day's verb counted as having had its turn for the days after it.
  /// `previous`'s turns before the date's day count as shown, since the widget showed them.
  static func makeWeek(for date: Date, myVerbs: [VerbMapEntry], challenge: ChallengeContext = .initial, previous: WidgetWeek? = nil) -> WidgetWeek? {
    let calendar = CalendarDay.calendar
    let today = dayNumber(of: date)
    let noon = CalendarDay.noon(of: CalendarDay.string(for: date)) ?? date
    let previousTurns = previous?.myVerbsTurns ?? []

    var shown = previous?.myVerbsShown ?? [:]
    for turn in previousTurns where turn.dayNumber < today {
      shown[turn.verb] = max(shown[turn.verb] ?? Int.min, turn.dayNumber)
    }
    let inMyVerbs = Set(myVerbs.map(\.infinitive))
    shown = shown.filter { inMyVerbs.contains($0.key) }

    var planned = shown
    var turns: [WidgetWeek.Turn] = []
    var days: [WidgetSnapshot] = []
    for offset in 0..<weekLength {
      let number = today + offset
      guard let day = calendar.date(byAdding: .day, value: offset, to: noon) else {
        return nil
      }
      let entry: VerbMapEntry
      if offset == 0, let previous, let kept = keptVerb(on: date, in: previous) {
        entry = kept
        if let turn = previousTurns.first(where: { $0.dayNumber == number }) {
          planned[turn.verb] = number
          turns.append(turn)
        }
      } else {
        guard let drawn = VerbDraw.verbOfTheDay(dayNumber: number, myVerbs: myVerbs, lastShown: planned, frequentVerbs: VerbDraw.frequentVerbs) else {
          return nil
        }
        entry = drawn
        if VerbDraw.isMyVerbsDay(number), !myVerbs.isEmpty {
          planned[drawn.infinitive] = number
          turns.append(WidgetWeek.Turn(dayNumber: number, verb: drawn.infinitive))
        }
      }
      days.append(makeSnapshot(for: day, verb: entry, challenge: challenge))
    }
    guard let firstDay = days.first else {
      return nil
    }
    return WidgetWeek(
      firstDay: firstDay,
      laterDays: Array(days.dropFirst()),
      myVerbs: myVerbs.map(\.infinitive).sorted(),
      myVerbsTurns: turns,
      myVerbsShown: shown
    )
  }

  /// The verb of the date's day in `previous`, if it has that day.
  private static func keptVerb(on date: Date, in previous: WidgetWeek) -> VerbMapEntry? {
    let today = CalendarDay.string(for: date)
    guard let kept = previous.days.first(where: { $0.dateString == today }) else {
      return nil
    }
    // A day shows a reflexive-only verb with its pronoun, and the map keys it without.
    return VerbMap.shared.entry(for: kept.infinitive)
      ?? ReflexivePronoun.bareInfinitive(fromCitation: kept.infinitive).flatMap { VerbMap.shared.entry(for: $0) }
  }

  /// One day of the week, with `entry` as its verb of the day.
  static func makeSnapshot(for date: Date, verb entry: VerbMapEntry, challenge: ChallengeContext = .initial) -> WidgetSnapshot {
    let dayOffset = dayNumber(of: date)
    let dateString = CalendarDay.string(for: date)
    let infinitive = entry.infinitive

    let paradigms = paradigmTenses.compactMap { paradigm(for: infinitive, tense: $0) }
    let gerundio = markedForm(infinitive: infinitive, tense: .gerundio, personNumber: .none) ?? infinitive
    let participio = markedForm(infinitive: infinitive, tense: .participio, personNumber: .none) ?? infinitive
    let quizQuestion = challengeQuizQuestion(on: date, challenge: challenge)
      ?? makeQuizQuestion(infinitive: infinitive, dayOffset: dayOffset, dateString: dateString)

    // Richer large-widget content: a modern example sentence (with a real, human-readable
    // attribution — a book title, statistics body, or the Claude credit, never a raw
    // corpus filename) and a truncated etymology snippet. Both are `nil` when the verb
    // has no data on file, in which case the large widget simply omits that block.
    let example = ExampleData.example(for: infinitive)
    let etymology = Etymology.text(for: infinitive).map { truncateToSentenceBoundary($0, maxLength: 500) }

    return WidgetSnapshot(
      infinitive: entry.citationForm,
      gloss: entry.gloss,
      frequencyRank: entry.frequencyRank,
      paradigms: paradigms,
      gerundio: gerundio,
      participio: participio,
      exampleSpanish: example?.es,
      exampleEnglish: example?.en,
      exampleAttribution: example?.provenance.attribution,
      etymologySnippet: etymology,
      quizQuestion: quizQuestion,
      dateString: dateString
    )
  }

  /// Trim an etymology body to at most `maxLength` characters, preferring to cut at the
  /// last sentence boundary; otherwise hard-cut and append an ellipsis. Always rebalances
  /// the `~bold~` markers so a cut can't leave a dangling opener that would render the
  /// whole tail bold in the widget's parser.
  static func truncateToSentenceBoundary(_ text: String, maxLength: Int) -> String {
    guard text.count > maxLength else {
      return rebalanceTildes(text)
    }
    let prefix = String(text.prefix(maxLength))
    if let lastPeriod = prefix.lastIndex(of: ".") {
      return rebalanceTildes(String(prefix[...lastPeriod]))
    }
    return rebalanceTildes(prefix) + "…"
  }

  /// Etymology snippets use `~…~` bold markup. A mid-string cut can leave an unclosed
  /// `~` opener, which the widget's parser (splitting on `~`) would render as bold
  /// running to the end of the snippet. Drop the dangling opener so the tail stays plain.
  static func rebalanceTildes(_ text: String) -> String {
    guard !text.filter({ $0 == "~" }).count.isMultiple(of: 2) else {
      return text
    }
    guard let lastTilde = text.lastIndex(of: "~") else {
      return text
    }
    return String(text[..<lastTilde]) + String(text[text.index(after: lastTilde)...])
  }

  /// The verb the widget shows on the date's day: from My Verbs every third day once it has
  /// entries, otherwise drawn from the 1,000 most frequent verbs (`VerbDraw`). Without the band
  /// the verb of the day would eventually be `churruscar` and the widget quiz would ask for its
  /// pretérito. A My Verbs day may name a rare verb, since the learner chose it. `lastShown` is
  /// `VerbDraw.verbOfTheDay`'s.
  static func verbOfTheDay(on date: Date, myVerbs: [VerbMapEntry], lastShown: [String: Int] = [:]) -> VerbMapEntry? {
    VerbDraw.verbOfTheDay(dayNumber: dayNumber(of: date), myVerbs: myVerbs, lastShown: lastShown, frequentVerbs: VerbDraw.frequentVerbs)
  }

  /// The date's day as a count of days since the reference date, in `CalendarDay`'s Gregorian
  /// calendar, so that a Buddhist or Japanese calendar setting cannot shift it.
  static func dayNumber(of date: Date) -> Int {
    let calendar = CalendarDay.calendar
    guard let reference = CalendarDay.start(of: referenceDateString) else {
      return 0
    }
    return calendar.dateComponents([.day], from: reference, to: calendar.startOfDay(for: date)).day ?? 0
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

  /// What every question ID of a day's challenge begins with, so that a change of level, region,
  /// or tú or vos shows as a stale snapshot.
  static func questionIDPrefix(on date: Date, challenge: ChallengeContext) -> String {
    let key = DailyChallenge.Key(date: date, level: challenge.level, region: challenge.region)
    return "\(key.day)-\(key.levelKey)-\(key.regionKey)-\(challenge.secondSingular.rawValue)-"
  }

  /// The quiz widget's question for a day: the first question of that day's challenge at the
  /// learner's level and region, in their tú or vos, so that the widget and the challenge agree.
  /// Nil when the challenge gives no question.
  static func challengeQuizQuestion(on date: Date, challenge: ChallengeContext) -> WidgetQuizQuestion? {
    let key = DailyChallenge.Key(date: date, level: challenge.level, region: challenge.region)
    guard
      let question = DailyChallenge.questions(for: key, secondSingular: challenge.secondSingular).first,
      let correct = markedForm(infinitive: question.verb, tense: question.tense, personNumber: question.personNumber)
    else {
      return nil
    }
    let questionID = questionIDPrefix(on: date, challenge: challenge) + question.verb
    var generator = SplitMix64(seed: DailyChallenge.stableSeed(for: questionID))
    return WidgetQuizQuestion(
      infinitive: ReflexivePronoun.citationForm(of: question.verb),
      tenseDisplay: question.tense.titleCaseName,
      pronoun: question.personNumber == .none ? nil : question.personNumber.pronoun,
      correctAnswer: correct,
      wrongAnswers: wrongAnswers(for: question, correct: correct, challenge: challenge, using: &generator),
      questionID: questionID
    )
  }

  /// How a form looks apart from its letters: a compound tense's has haber before it, a negative
  /// command's has no, and a gerundio or participio has no person. A wrong answer of another
  /// shape would stand out as plainly wrong.
  private enum Shape {
    case simple
    case compound
    case negativeCommand
    case personless
  }

  private static func shape(of tense: DisplayTense) -> Shape {
    if tense == .gerundio || tense == .participio {
      return .personless
    }
    if tense == .imperativoNegativo {
      return .negativeCommand
    }
    return tense.isCompound ? .compound : .simple
  }

  /// Three wrong answers of the same verb and shape: one of the same tense in another person
  /// the level asks, one of the same person in another of the level's tenses, then the cell as a
  /// regular verb would have it, and more of the first two. A reflexive-only verb's pronoun
  /// names its person, so its wrong answers keep the person and change the tense. A gerundio or
  /// participio, which has no person, is offered the other endings, then the other of the two and
  /// the infinitive, which ir's yendo needs.
  private static func wrongAnswers(for question: QuizQuestion, correct: String, challenge: ChallengeContext, using generator: inout SplitMix64) -> [String] {
    let verb = question.verb
    let tense = question.tense
    let personNumber = question.personNumber
    let questionShape = shape(of: tense)
    let isReflexiveOnly = ReflexivePronoun.isReflexiveOnly(verb)
    let pool = challenge.level.pool

    var sameTense: [String] = []
    if questionShape != .personless, !isReflexiveOnly {
      let personNumbers = Quiz.personNumbers(in: tense, secondSingular: challenge.secondSingular, region: challenge.region)
        .filter { $0 != personNumber && (challenge.level.entry(for: tense)?.asks($0) ?? true) }
      sameTense = personNumbers.compactMap { markedForm(infinitive: verb, tense: tense, personNumber: $0) }.shuffled(using: &generator)
    }
    var samePerson: [String] = []
    if questionShape != .personless {
      samePerson = pool.map(\.tense)
        .filter { $0 != tense && shape(of: $0) == questionShape }
        .compactMap { markedForm(infinitive: verb, tense: $0, personNumber: personNumber) }
        .shuffled(using: &generator)
    }
    var regular: [String] = []
    if let form = TenseBridge.regularForm(infinitive: verb, tense: tense, personNumber: personNumber) {
      regular.append(isReflexiveOnly ? ReflexivePronoun.attach(to: form, tense: tense, personNumber: personNumber) : form)
    }
    if questionShape == .personless, !isReflexiveOnly {
      regular += otherEndings(of: verb, tense: tense)
      let otherNonFinite: DisplayTense = tense == .gerundio ? .participio : .gerundio
      regular += [markedForm(infinitive: verb, tense: otherNonFinite, personNumber: .none), verb].compactMap { $0 }
    }

    var seen: Set<String> = [correct.lowercased()]
    var answers: [String] = []
    func take(_ candidates: [String], upTo count: Int) {
      for candidate in candidates where answers.count < count && !seen.contains(candidate.lowercased()) {
        seen.insert(candidate.lowercased())
        answers.append(candidate)
      }
    }
    take(sameTense, upTo: 1)
    take(samePerson, upTo: answers.count + 1)
    take(regular, upTo: wrongAnswerCount)
    take(sameTense + samePerson, upTo: wrongAnswerCount)
    var suffix = ""
    while answers.count < wrongAnswerCount {
      suffix += "s"
      take([correct.lowercased() + suffix], upTo: wrongAnswerCount)
    }
    return answers
  }

  private static let wrongAnswerCount = 3

  /// A gerundio's or participio's form with each regular ending but the verb's own, and the
  /// endings that leyendo and leído add: hablando offers habliendo, hablendo, and hablyendo.
  private static func otherEndings(of verb: String, tense: DisplayTense) -> [String] {
    guard verb.count > 2 else {
      return []
    }
    let stem = String(verb.dropLast(2))
    let endings = tense == .gerundio ? ["ando", "iendo", "endo", "yendo"] : ["ado", "ido", "ído"]
    return endings.map { stem + $0 }
  }

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
      infinitive: ReflexivePronoun.citationForm(of: infinitive),
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

  /// A marked (UPPERCASE-irregular) conjugated form, with a reflexive-only verb's pronoun, or
  /// nil if the engine can't produce it.
  private static func markedForm(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> String? {
    if case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber, pronoun: .written) {
      return form
    }
    return nil
  }
}
