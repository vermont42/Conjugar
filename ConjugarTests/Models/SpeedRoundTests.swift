//
//  SpeedRoundTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The Speed Round: which items it may ask, how it draws and repeats them, which cells a key
//  conjugation asks, how a minute is timed and counted, and what it keeps and leaves unsent.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct SpeedRoundTests {
  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return calendar
  }()

  private static func daysAgo(_ days: Double) -> Date {
    Date.now.addingTimeInterval(-days * 86_400)
  }

  /// Right twelve days ago, then right again once due, which reaches the third box.
  private static func bringToMastery(_ item: PracticeItem, in record: inout PracticeRecord) {
    record.recordAnswer(item, isCorrect: true, at: daysAgo(12), calendar: calendar)
    record.recordAnswer(item, isCorrect: true, at: daysAgo(8), calendar: calendar)
  }

  private static func key(_ infinitive: String, _ key: PracticeItem.Key) -> PracticeItem {
    .keyConjugation(infinitive: infinitive, key: key)
  }

  private static func pattern(_ tense: DisplayTense, _ personNumber: DisplayPersonNumber, _ ending: RegularRoot) -> PracticeItem {
    PracticeItem.pattern(of: ConjugationCell(tense: tense, personNumber: personNumber), ending: ending)!
  }

  /// Five items Beginner asks: two key conjugations and three patterns.
  private static let fiveItems: [PracticeItem] = [
    key("tener", .yoPresente),
    key("ser", .yoPresente),
    pattern(.presenteDeIndicativo, .firstSingular, .ar),
    pattern(.presenteDeIndicativo, .thirdPlural, .er),
    pattern(.presenteDeIndicativo, .firstPlural, .ir)
  ]

  private static func record(mastering items: [PracticeItem]) -> PracticeRecord {
    var record = PracticeRecord()
    for item in items {
      bringToMastery(item, in: &record)
    }
    return record
  }

  private static func practice(mastering items: [PracticeItem], getterSetter: GetterSetterFake = GetterSetterFake()) -> PracticeStore {
    if let json = record(mastering: items).json {
      getterSetter.set(key: PracticeRecord.storageKey, value: json)
    }
    return PracticeStore(getterSetter: getterSetter, calendar: calendar)
  }

  private func makeQuiz(
    level: QuizLevel = .beginner,
    region: Region = .latinAmerica,
    practice: PracticeStore,
    gameCenter: GameCenter = GameCenterFake(),
    seed: UInt64 = 7
  ) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: region.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true, randomSource: SplitMix64(seed: seed), practice: practice)
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  /// Latin America's persons with tú, whatever the level.
  private static func allows(_ cell: ConjugationCell) -> Bool {
    Quiz.personNumbers(in: cell.tense, secondSingular: .secondSingularTú, region: .latinAmerica).contains(cell.personNumber)
  }

  /// The cells a level asks with tú in Latin America.
  private static func asks(at level: QuizLevel) -> (ConjugationCell) -> Bool {
    { cell in
      guard let entry = level.entry(for: cell.tense) else {
        return false
      }
      return entry.asks(cell.personNumber) && allows(cell)
    }
  }

  private static var generator = SplitMix64(seed: 11)

  @Test func onlyTheThirdBoxIsMastered() {
    var record = Self.record(mastering: [Self.key("tener", .yoPresente)])
    let learning = Self.key("ser", .yoPresente)
    record.recordAnswer(learning, isCorrect: true, at: Self.daysAgo(1), calendar: Self.calendar)

    #expect(SpeedRound.masteredItems(in: record, asks: Self.allows) == [Self.key("tener", .yoPresente)])
  }

  /// A mastered vosotros pattern waits for Spain, and a verb this version does not know is dropped.
  @Test func anItemTheSettingsCannotAskIsLeftOut() {
    let vosotros = Self.pattern(.presenteDeIndicativo, .secondPlural, .ar)
    let unknown = Self.key("blorfar", .yoPresente)
    let record = Self.record(mastering: [vosotros, unknown, Self.key("tener", .yoPresente)])

    #expect(SpeedRound.masteredItems(in: record, asks: Self.allows) == [Self.key("tener", .yoPresente)])
    let inSpain = { (cell: ConjugationCell) in
      Quiz.personNumbers(in: cell.tense, secondSingular: .secondSingularTú, region: .spain).contains(cell.personNumber)
    }
    #expect(SpeedRound.masteredItems(in: record, asks: inSpain).contains(vosotros))
  }

  @Test func everyQuestionAsksAMasteredItemEachInTurnAndNeverTwiceRunning() {
    var previous: PracticeItem?
    var asked: [PracticeItem] = []
    for _ in 0..<3 {
      let batch = QuizDraw.speedRoundQuestions(
        for: Self.fiveItems,
        levelAsks: Self.asks(at: .beginner),
        allows: Self.allows,
        band: .top100,
        count: SpeedRound.batchSize,
        after: previous,
        using: &Self.generator
      )
      #expect(batch.count == SpeedRound.batchSize)
      let items = batch.compactMap(PracticeItem.exercised(by:))
      #expect(items.count == batch.count)
      asked += items
      previous = items.last
    }

    #expect(Set(asked).isSubset(of: Set(Self.fiveItems)))
    for start in stride(from: 0, to: asked.count, by: Self.fiveItems.count) {
      let cycle = asked[start..<min(start + Self.fiveItems.count, asked.count)]
      #expect(Set(cycle).count == cycle.count)
    }
    for index in asked.indices.dropFirst() {
      #expect(asked[index] != asked[index - 1])
    }
  }

  @Test func oneItemIsRepeatedAndNothingGivesNothing() {
    let one = QuizDraw.speedRoundQuestions(
      for: [Self.key("tener", .yoPresente)],
      levelAsks: Self.asks(at: .beginner),
      allows: Self.allows,
      band: .top100,
      count: 4,
      using: &Self.generator
    )
    #expect(one.count == 4)
    #expect(one.allSatisfy { $0.verb == "tener" })

    let none = QuizDraw.speedRoundQuestions(
      for: [],
      levelAsks: Self.asks(at: .beginner),
      allows: Self.allows,
      band: .top100,
      count: 4,
      using: &Self.generator
    )
    #expect(none.isEmpty)
  }

  /// A pattern asks its cell of a verb of its ending regular there, drawn from the band, and a
  /// fresh one as it comes back.
  @Test func aPatternAsksRegularVerbsOfTheBand() {
    let item = Self.pattern(.imperfectoDeIndicativo, .thirdSingular, .er)
    let questions = QuizDraw.speedRoundQuestions(
      for: [item],
      levelAsks: Self.asks(at: .elementary),
      allows: Self.allows,
      band: .top100,
      count: 12,
      using: &Self.generator
    )
    let bandVerbs = Set(QuizDraw.verbs(in: .top100).map(\.infinitive))

    #expect(questions.count == 12)
    for question in questions {
      #expect(question.tense == .imperfectoDeIndicativo && question.personNumber == .thirdSingular)
      #expect(RegularRoot(infinitive: question.verb) == .er)
      #expect(bandVerbs.contains(question.verb))
      #expect(PracticeItem.exercised(by: question) == item)
    }
    #expect(Set(questions.map(\.verb)).count > 1)
  }

  /// Mastered tuve asks only tuve at Beginner, which asks no pretérito, and any irregular pretérito
  /// cell of tener at Elementary. pedir's yo pretérito (pedí) is regular, so its own cell is never
  /// asked: pidió is.
  @Test func aKeyConjugationAsksTheIrregularCellsBuiltOnItThatTheLevelAsks() {
    let beginner = QuizDraw.speedRoundCells(of: "tener", builtOn: .yoPretérito, levelAsks: Self.asks(at: .beginner), allows: Self.allows)
    #expect(beginner == [ConjugationCell(tense: .pretérito, personNumber: .firstSingular)])

    let elementary = QuizDraw.speedRoundCells(of: "tener", builtOn: .yoPretérito, levelAsks: Self.asks(at: .elementary), allows: Self.allows)
    #expect(elementary.first == ConjugationCell(tense: .pretérito, personNumber: .firstSingular))
    #expect(elementary.contains(ConjugationCell(tense: .pretérito, personNumber: .thirdPlural)))
    #expect(elementary.allSatisfy { $0.tense == .pretérito })
    #expect(!elementary.contains(ConjugationCell(tense: .pretérito, personNumber: .secondPlural)))

    let advanced = QuizDraw.speedRoundCells(of: "tener", builtOn: .yoPretérito, levelAsks: Self.asks(at: .advanced), allows: Self.allows)
    #expect(advanced.contains(ConjugationCell(tense: .imperfectoDeSubjuntivo1, personNumber: .firstSingular)))

    let pedir = QuizDraw.speedRoundCells(of: "pedir", builtOn: .yoPretérito, levelAsks: Self.asks(at: .beginner), allows: Self.allows)
    #expect(pedir.count == 1)
    #expect(pedir.first?.tense == .pretérito && pedir.first?.personNumber != .firstSingular)

    for cell in elementary + pedir {
      let verb = cell == pedir.first ? "pedir" : "tener"
      #expect(PracticeItem.exercised(by: verb, tense: cell.tense, personNumber: cell.personNumber) == Self.key(verb, .yoPretérito))
    }
  }

  @Test func theScopeNeitherRanksNorContinuesNorCounts() {
    let scope = QuizScope.speedRound()

    #expect(scope.isSpeedRound)
    #expect(scope.source == .speedRound)
    #expect(!scope.isRanked)
    #expect(!scope.mixesDueItems)
    #expect(!scope.mixesChoiceQuestions)
    #expect(!scope.continues)
    #expect(!scope.shufflesQuestions)
    #expect(!scope.sendsQuestionCounts)
    #expect(!scope.startsLiveActivity)
    #expect(LastQuizResult.Kind(scope: scope) == .speedRound)
  }

  @Test func theCountdownKeepsItsMinutes() {
    #expect(Quiz.formatMinutesSeconds(60) == "1:00")
    #expect(Quiz.formatMinutesSeconds(59) == "0:59")
    #expect(Quiz.formatMinutesSeconds(5) == "0:05")
  }

  /// A round with none right sets no best; the best survives a launch and is forgotten by Reset
  /// Practice.
  @Test func theBestIsKeptUntilAReset() {
    let getterSetter = GetterSetterFake()
    let practice = PracticeStore(getterSetter: getterSetter, calendar: Self.calendar)
    #expect(!practice.recordSpeedRound(correctCount: 0))
    #expect(practice.speedRoundBest == nil)
    #expect(practice.isEmpty)

    #expect(practice.recordSpeedRound(correctCount: 9))
    #expect(!practice.recordSpeedRound(correctCount: 9))
    #expect(!practice.recordSpeedRound(correctCount: 4))
    #expect(!practice.isEmpty)
    #expect(PracticeStore(getterSetter: getterSetter, calendar: Self.calendar).speedRoundBest == 9)

    practice.reset()
    #expect(practice.speedRoundBest == nil)
    #expect(PracticeStore(getterSetter: getterSetter, calendar: Self.calendar).speedRoundBest == nil)
  }

  @Test func nothingMasteredStartsNothingAndFiveStartARound() {
    let empty = makeQuiz(practice: PracticeStore(getterSetter: GetterSetterFake()))
    #expect(empty.speedRoundItems().isEmpty)
    #expect(!empty.start(scope: .speedRound()))
    #expect(empty.quizState == .notStarted)

    let five = makeQuiz(practice: Self.practice(mastering: Self.fiveItems))
    #expect(five.speedRoundItems().count == SpeedRound.minimumMasteredCount)
    #expect(five.start(scope: .speedRound()))
    #expect(five.quizState == .inProgress)
  }

  /// A right answer counts and advances; a miss advances at once, with no hold, its question kept
  /// for the line under the next; a slip is a miss.
  @Test func aMissMovesOnAtOnce() throws {
    let quiz = makeQuiz(practice: Self.practice(mastering: Self.fiveItems))
    quiz.start(scope: .speedRound())

    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .totalMatch)
    #expect(quiz.correctCount == 1)
    #expect(quiz.speedRoundMiss == nil)

    let missed = try #require(quiz.currentQuestion)
    #expect(quiz.process(proposedAnswer: "zzz") == .noMatch)
    #expect(!quiz.isHeld)
    #expect(quiz.correction == nil)
    #expect(quiz.currentQuestionIndex == 2)
    #expect(quiz.speedRoundMiss == missed)
    #expect(!quiz.questions.contains { $0.isReask })

    let slipped = try #require(quiz.currentQuestion)
    let slip = String(rightAnswer(quiz).dropLast()) + "x"
    #expect(quiz.process(proposedAnswer: slip) == .noMatch)
    #expect(!quiz.isAwaitingSecondAttempt)
    #expect(quiz.speedRoundMiss == slipped)

    quiz.process(proposedAnswer: rightAnswer(quiz))
    #expect(quiz.speedRoundMiss == nil)
    #expect(quiz.correctCount == 2)
    #expect(quiz.score == quiz.results.reduce(0) { $0 + $1.rawValue })
  }

  @Test func theRoundRecordsNothing() {
    let practice = Self.practice(mastering: Self.fiveItems)
    let before = practice.record
    let quiz = makeQuiz(practice: practice)
    quiz.start(scope: .speedRound())

    for index in 0..<12 {
      quiz.process(proposedAnswer: index.isMultiple(of: 3) ? "zzz" : rightAnswer(quiz))
    }

    #expect(practice.record == before)
  }

  /// Twenty-five answers in a row, past two batches, each a mastered item's and never the same
  /// item twice running.
  @Test func theRoundDrawsMoreAsItGoes() {
    let quiz = makeQuiz(level: .elementary, practice: Self.practice(mastering: Self.fiveItems + [Self.key("tener", .yoPretérito)]))
    quiz.start(scope: .speedRound())
    let mastered = Set(quiz.speedRoundItems())

    var asked: [PracticeItem] = []
    for _ in 0..<25 {
      if let question = quiz.currentQuestion, let item = PracticeItem.exercised(by: question) {
        asked.append(item)
      }
      quiz.process(proposedAnswer: rightAnswer(quiz))
    }

    #expect(quiz.quizState == .inProgress)
    #expect(asked.count == 25)
    #expect(Set(asked).isSubset(of: mastered))
    for index in asked.indices.dropFirst() {
      #expect(asked[index] != asked[index - 1])
    }
  }

  /// Sixty ticks end the round: the question on screen, unanswered, is dropped, and the right
  /// answers set the best, which a worse round does not beat. Nothing is posted to Game Center.
  @Test func sixtyTicksEndTheRoundAndKeepTheBest() throws {
    let practice = Self.practice(mastering: Self.fiveItems)
    let spy = GameCenterSpy()
    let quiz = makeQuiz(practice: practice, gameCenter: spy)
    quiz.start(scope: .speedRound())

    for _ in 0..<3 {
      quiz.process(proposedAnswer: rightAnswer(quiz))
    }
    quiz.process(proposedAnswer: "zzz")
    for _ in 0..<(SpeedRound.duration - 1) {
      quiz.clockTicked()
    }
    #expect(quiz.quizState == .inProgress)
    #expect(quiz.speedRoundSecondsLeft == 1)

    quiz.clockTicked()
    #expect(quiz.quizState == .finished)
    #expect(quiz.questions.count == 4)
    #expect(quiz.results.count == 4)
    #expect(quiz.correctCount == 3)
    #expect(quiz.speedRoundMiss == nil)
    #expect(quiz.isNewSpeedRoundBest)
    #expect(quiz.speedRoundPreviousBest == nil)
    #expect(practice.speedRoundBest == 3)
    #expect(spy.submissions.isEmpty)
    let result = try #require(practice.lastResult)
    #expect(result.kind == .speedRound)
    #expect(result.correctCount == 3)
    #expect(!quiz.canContinue)

    quiz.clockTicked()
    #expect(quiz.elapsedTime == SpeedRound.duration)

    #expect(quiz.start(scope: .speedRound()))
    #expect(quiz.speedRoundSecondsLeft == SpeedRound.duration)
    quiz.process(proposedAnswer: rightAnswer(quiz))
    for _ in 0..<SpeedRound.duration {
      quiz.clockTicked()
    }
    #expect(quiz.quizState == .finished)
    #expect(!quiz.isNewSpeedRoundBest)
    #expect(quiz.speedRoundPreviousBest == 3)
    #expect(practice.speedRoundBest == 3)
  }

  @Test func quittingSetsNoBest() {
    let practice = Self.practice(mastering: Self.fiveItems)
    let quiz = makeQuiz(practice: practice)
    quiz.start(scope: .speedRound())
    quiz.process(proposedAnswer: rightAnswer(quiz))
    quiz.quit()

    #expect(quiz.quizState == .finished)
    #expect(practice.speedRoundBest == nil)
    let elapsed = quiz.elapsedTime
    quiz.clockTicked()
    #expect(quiz.elapsedTime == elapsed)
  }
}
