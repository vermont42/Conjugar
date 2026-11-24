//
//  QuizRecordSessionTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Review and Practice My Mistakes: which items each session asks, in what order, how its rounds
//  run, and what it leaves unsent.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct QuizRecordSessionTests {
  private func makeQuiz(
    level: QuizLevel = .beginner,
    region: Region = .spain,
    practice: PracticeStore,
    gameCenter: GameCenter = GameCenterFake()
  ) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: region.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true, randomSource: SplitMix64(seed: 5), practice: practice)
  }

  private func daysAgo(_ days: Double) -> Date {
    Date.now.addingTimeInterval(-days * 86_400)
  }

  private func key(_ infinitive: String, _ key: PracticeItem.Key) -> PracticeItem {
    .keyConjugation(infinitive: infinitive, key: key)
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  private func finishRight(_ quiz: Quiz) {
    while quiz.quizState == .inProgress {
      quiz.process(proposedAnswer: rightAnswer(quiz))
    }
  }

  /// Each verb looked up on a day of its own, the first longest ago, so each verb's key
  /// conjugations are due in the given order.
  private func practiceWithDueVerbs(_ verbs: [String]) -> PracticeStore {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    for (index, verb) in verbs.enumerated() {
      practice.recordLookup(verb, source: .search, at: daysAgo(Double(40 - index)))
    }
    return practice
  }

  /// Every askable cell, as a quiz with the tú setting and Spain's persons asks them.
  private static func asksAll(_ cell: ConjugationCell) -> Bool {
    cell.personNumber != .secondSingularVos
  }

  @Test func theNextDueItemIsCountedInDays() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    #expect(practice.daysUntilNextDue() == nil)
    practice.recordLookup("tener", source: .search)
    #expect(practice.daysUntilNextDue() == 1)
    #expect(practice.dueItems().isEmpty)
  }

  /// Neither the level's tenses nor its band hold a session back: a Beginner, whose quiz asks no
  /// pretérito and only the top 100, is asked ir's fui and contradecir's contradigo.
  @Test func aSessionAsksBeyondTheLevelsTensesAndBand() {
    let items = [key("ir", .yoPretérito), key("contradecir", .yoPresente)]
    let questions = QuizDraw.sessionQuestions(for: items, band: .top100, asks: Self.asksAll, using: &Self.generator)

    #expect(questions == [
      QuizQuestion("ir", .pretérito, .firstSingular),
      QuizQuestion("contradecir", .presenteDeIndicativo, .firstSingular)
    ])
  }

  /// A key conjugation whose own cell is regular for its verb is asked by an irregular cell built
  /// on it, so that the answer moves it: pedí is regular, so pedir's yo pretérito asks pidió.
  @Test func aKeyConjugationAsksAnIrregularCellBuiltOnIt() throws {
    let question = try #require(QuizDraw.sessionQuestions(for: [key("pedir", .yoPretérito)], band: nil, asks: Self.asksAll, using: &Self.generator).first)

    #expect(question.tense == .pretérito)
    #expect(question.personNumber != .firstSingular)
    #expect(PracticeItem.exercised(by: question) == key("pedir", .yoPretérito))
    // The participio, which no level asks, is asked as itself.
    let participio = QuizDraw.sessionQuestions(for: [key("escribir", .participio)], band: .top100, asks: Self.asksAll, using: &Self.generator)
    #expect(participio == [QuizQuestion("escribir", .participio, .none)])
  }

  @Test func aPatternAsksARegularVerbOfItsEndingFromTheBand() throws {
    let pattern = PracticeItem.pattern(tenseKey: "imperfecto_de_indicativo", person: "fp", ending: "ir")
    for _ in 0..<5 {
      let question = try #require(QuizDraw.sessionQuestions(for: [pattern], band: .top100, asks: Self.asksAll, using: &Self.generator).first)
      #expect(PracticeItem.exercised(by: question) == pattern)
      #expect(VerbMap.shared.entry(for: question.verb)?.isIn(.top100) == true)
    }
  }

  /// tener's key conjugations, due apart, sit together in the verb page's order at the place of
  /// the first drawn.
  @Test func aVerbsKeyConjugationsSitTogether() {
    let pattern = PracticeItem.pattern(tenseKey: "presente_de_indicativo", person: "fs", ending: "ar")
    let items = [key("tener", .yoFuturo), pattern, key("ser", .yoPresente), key("tener", .yoPresente), key("tener", .yoPretérito)]
    let questions = QuizDraw.sessionQuestions(for: items, band: .top100, asks: Self.asksAll, using: &Self.generator)

    #expect(questions.map(PracticeItem.exercised(by:)) == [
      key("tener", .yoPresente), key("tener", .yoPretérito), key("tener", .yoFuturo), pattern, key("ser", .yoPresente)
    ])
  }

  @Test func excludedAndUnaskableItemsAreSkippedWithinTheLimit() {
    let items = [
      key("tener", .yoPresente),
      key("notAVerb", .yoPresente),
      .pattern(tenseKey: "presente_de_indicativo", person: "sp", ending: "ar"),
      key("ser", .yoPresente),
      key("ir", .yoPresente),
      key("hacer", .yoPresente)
    ]
    let noVosotros: (ConjugationCell) -> Bool = { $0.personNumber != .secondPlural && Self.asksAll($0) }
    let questions = QuizDraw.sessionQuestions(
      for: items,
      band: .top100,
      asks: noVosotros,
      excluded: [key("tener", .yoPresente).key],
      limit: 2,
      using: &Self.generator
    )

    #expect(questions.map(\.verb) == ["ser", "ir"])
    #expect(!QuizDraw.canAsk(items[1], asks: Self.asksAll))
    #expect(!QuizDraw.canAsk(items[2], asks: noVosotros))
    #expect(QuizDraw.canAsk(items[2], asks: Self.asksAll))
  }

  @Test func aRecordSessionNeverRanksOrSendsCounts() {
    for session in QuizRecordSession.allCases {
      let scope = QuizScope.recordSession(session)
      #expect(!scope.isRanked)
      #expect(!scope.mixesDueItems)
      #expect(!scope.sendsQuestionCounts)
      #expect(!scope.shufflesQuestions)
      #expect(scope.continues)
      #expect(scope.questionCount == QuizScope.roundLength)
    }
    #expect(QuizScope.recordSession(.review).source == .review)
    #expect(QuizScope.recordSession(.mistakes).source == .mistakes)
    #expect(QuizScope.allVerbs.sendsQuestionCounts)
  }

  /// Twelve verbs due: ten in the first round, the most overdue first, two in Ten More, and no
  /// more after.
  @Test func twelveDueItemsAreAskedAsTenThenTwo() {
    let verbs = ["tener", "ser", "ir", "hacer", "poner", "decir", "venir", "salir", "poder", "querer", "saber", "traer"]
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    for (index, verb) in verbs.enumerated() {
      // One key conjugation each, so each verb is one item.
      practice.recordAnswer(to: QuizQuestion(verb, .presenteDeIndicativo, .firstSingular), isCorrect: false, at: daysAgo(Double(40 - index)))
    }
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.askableCount(for: .review) == 12)
    #expect(quiz.start(scope: .recordSession(.review)))
    #expect(quiz.questions.map(\.verb) == Array(verbs.prefix(10)))
    finishRight(quiz)
    #expect(quiz.canContinue)

    #expect(quiz.continueSession())
    #expect(quiz.questions.dropFirst(10).map(\.verb) == Array(verbs.suffix(2)))
    finishRight(quiz)
    #expect(quiz.questionCount == 12)
    #expect(!quiz.canContinue)
    #expect(!quiz.continueSession())
    #expect(quiz.askableCount(for: .review) == 0)
  }

  @Test func aShortReviewDoesNotContinue() {
    let practice = practiceWithDueVerbs(["pensar"])
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.askableCount(for: .review) == 1)
    #expect(quiz.start(scope: .recordSession(.review)))
    #expect(quiz.questions == [QuizQuestion("pensar", .presenteDeIndicativo, .firstSingular)])
    finishRight(quiz)
    #expect(quiz.quizState == .finished)
    #expect(!quiz.canContinue)
  }

  @Test func anEmptyRecordStartsNothing() {
    let quiz = makeQuiz(practice: PracticeStore(getterSetter: GetterSetterFake()))
    for session in QuizRecordSession.allCases {
      #expect(quiz.askableCount(for: session) == 0)
      #expect(!quiz.start(scope: .recordSession(session)))
      #expect(quiz.quizState == .notStarted)
    }
  }

  @Test func aMistakeLeavesOnceAnsweredRight() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    practice.recordAnswer(to: QuizQuestion("tener", .presenteDeIndicativo, .firstSingular), isCorrect: false, at: daysAgo(1))
    practice.recordAnswer(to: QuizQuestion("ir", .pretérito, .thirdSingular), isCorrect: false)
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.askableCount(for: .mistakes) == 2)

    #expect(quiz.start(scope: .recordSession(.mistakes)))
    // The most recently missed first.
    #expect(quiz.questions.map(\.verb) == ["ir", "tener"])
    finishRight(quiz)
    #expect(practice.missedItems().isEmpty)
    #expect(quiz.askableCount(for: .mistakes) == 0)
  }

  /// A mistake missed again stays a mistake, but Ten More asks the ones the session has not.
  @Test func aMistakeMissedAgainDoesNotReturnInTenMore() {
    let verbs = ["tener", "ser", "ir", "hacer", "poner", "decir", "venir", "salir", "poder", "querer", "saber"]
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    for (index, verb) in verbs.enumerated() {
      practice.recordAnswer(to: QuizQuestion(verb, .presenteDeIndicativo, .firstSingular), isCorrect: false, at: daysAgo(Double(index)))
    }
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .recordSession(.mistakes)))
    let firstRound = Set(quiz.questions.map(\.verb))
    #expect(firstRound.count == 10)
    while quiz.quizState == .inProgress {
      quiz.process(proposedAnswer: "zzzz")
      quiz.continueAfterCorrection()
    }
    #expect(practice.missedItems().count == 11)
    #expect(quiz.canContinue)

    #expect(quiz.continueSession())
    let tenMore = quiz.questions.suffix(from: quiz.currentQuestionIndex).map(\.verb)
    #expect(tenMore == ["saber"])
    quiz.quit()
  }

  @Test func aRecordSessionPostsNoScoreAndRecordsNoQuestionNumber() {
    let spy = GameCenterSpy()
    let quiz = makeQuiz(practice: practiceWithDueVerbs(["tener"]), gameCenter: spy)
    #expect(quiz.start(scope: .recordSession(.review)))
    #expect(!quiz.isRankedRound)
    let entry = QuizAbandonment.entries(getterSetter: Current.getterSetter)[quiz.abandonmentID]
    #expect(entry == QuizAbandonment.Entry(level: "beginner", source: "review", questionNumber: nil))
    finishRight(quiz)
    #expect(spy.submissions.isEmpty)
  }

  @Test func anAbandonedRecordSessionReportsNoQuestionNumber() {
    let getterSetter = GetterSetterFake()
    let analytics = AnalyticsSpy()
    QuizAbandonment.record(.init(level: "beginner", source: "mistakes", questionNumber: nil), id: "a", getterSetter: getterSetter)

    QuizAbandonment.reportAndClear(getterSetter: getterSetter, analytics: analytics)
    #expect(analytics.signalParameters == [["level": "beginner", "source": "mistakes"]])
  }

  /// A vosotros pattern missed in Spain cannot be asked once the region is Latin America.
  @Test func theRegionDecidesWhatCanBeAsked() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    practice.recordAnswer(to: QuizQuestion("hablar", .presenteDeIndicativo, .secondPlural), isCorrect: false)
    #expect(makeQuiz(region: .spain, practice: practice).askableCount(for: .mistakes) == 1)

    let quiz = makeQuiz(region: .latinAmerica, practice: practice)
    #expect(quiz.askableCount(for: .mistakes) == 0)
    #expect(!quiz.start(scope: .recordSession(.mistakes)))
  }

  private static var generator = SplitMix64(seed: 3)
}
