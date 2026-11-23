//
//  QuizPracticeTests.swift
//  ConjugarTests
//
//  The quiz and the practice record: every answer recorded as it is given, by every scope, and
//  the default quiz's due items, within the level and the band and at most three a round.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct QuizPracticeTests {
  private func makeQuiz(level: QuizLevel = .beginner, practice: PracticeStore, seed: UInt64 = 7) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: Region.spain.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: true, randomSource: SplitMix64(seed: seed), practice: practice)
  }

  private func daysAgo(_ days: Double) -> Date {
    Date.now.addingTimeInterval(-days * 86_400)
  }

  private func items(of quiz: Quiz) -> [PracticeItem?] {
    quiz.questions.map(PracticeItem.exercised(by:))
  }

  @Test func eachAnswerIsRecordedAsItIsGivenAndAQuitKeepsThem() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start())

    let first = try #require(quiz.currentQuestion)
    quiz.process(proposedAnswer: "zzzz")
    quiz.continueAfterCorrection()
    let second = try #require(quiz.currentQuestion)
    quiz.process(proposedAnswer: second.writtenAnswer?.lowercased() ?? "")
    quiz.quit()

    let firstItem = try #require(PracticeItem.exercised(by: first))
    let secondItem = try #require(PracticeItem.exercised(by: second))
    #expect(practice.record.entry(for: firstItem)?.lastAnswerWasRight == (firstItem == secondItem))
    #expect(practice.record.entry(for: secondItem)?.lastAnswerWasRight == true)
    #expect(practice.record.entries.count == Set([firstItem, secondItem]).count)
  }

  @Test func aSlipRecordsNothingUntilItsSecondAttempt() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .myVerbs(["cantar"])))
    let question = try #require(quiz.currentQuestion)
    let answer = try #require(question.writtenAnswer?.lowercased())
    let slip = String(answer.dropLast()) + (answer.last == "z" ? "y" : "z")

    if quiz.process(proposedAnswer: slip) == nil {
      #expect(practice.isEmpty)
      quiz.process(proposedAnswer: answer)
    }

    let item = try #require(PracticeItem.exercised(by: question))
    #expect(practice.record.entry(for: item)?.lastAnswerWasRight == true)
    quiz.quit()
  }

  @Test(arguments: [
    QuizScope.allVerbs,
    .myVerbs(["tener", "hablar"]),
    .verbPage("ir"),
    .collection(.goVerbs, title: ""),
    .custom(CustomQuiz(tenses: [.presenteDeIndicativo], verbSet: nil), myVerbs: [])
  ])
  func everyScopeWritesToTheRecord(scope: QuizScope) {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: scope))
    quiz.process(proposedAnswer: "zzzz")
    quiz.quit()

    #expect(practice.record.entries.count == 1)
  }

  /// Four verbs looked up ten days ago, each with a yo presente a Beginner is asked.
  private func practiceWithDueVerbs(_ verbs: [String] = ["tener", "ser", "ir", "hacer"]) -> PracticeStore {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    for (index, verb) in verbs.enumerated() {
      practice.recordLookup(verb, source: .search, at: daysAgo(10 + Double(index)))
    }
    return practice
  }

  /// The question a due yo presente asks of its verb.
  private func yoPresente(_ verb: String) -> QuizQuestion {
    QuizQuestion(verb, .presenteDeIndicativo, .firstSingular)
  }

  @Test func theDefaultQuizMixesInAtMostThreeDueItemsTheMostOverdueFirst() {
    let practice = practiceWithDueVerbs()
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start())

    #expect(quiz.questionCount == QuizScope.roundLength)
    // hacer, ir, and ser were looked up longest ago; tener waits, unless the draw asks it anyway.
    for verb in ["hacer", "ir", "ser"] {
      #expect(quiz.questions.contains(yoPresente(verb)), "\(verb)")
    }
    let due = practice.dueItems()
    #expect(QuizDraw.dueQuestions(for: due, band: .top100, asks: { _ in true }, using: &Self.generator).count == QuizDraw.dueItemLimit)
    quiz.quit()
  }

  @Test func dueItemsAskOnlyCellsTheLevelAsks() {
    let practice = practiceWithDueVerbs()
    let questions = QuizDraw.dueQuestions(for: practice.dueItems(), band: .top100, asks: { $0.tense == .presenteDeIndicativo }, using: &Self.generator)

    #expect(questions.count == 3)
    #expect(questions.allSatisfy { $0.tense == .presenteDeIndicativo })
    #expect(questions.allSatisfy { PracticeItem.exercised(by: $0)?.infinitive == $0.verb })
    // A Beginner is asked no pretérito, so ir's yo pretérito waits for a review.
    let pretérito = QuizDraw.dueQuestions(for: [.keyConjugation(infinitive: "ir", key: .yoPretérito)], band: .top100, asks: { $0.tense == .presenteDeIndicativo }, using: &Self.generator)
    #expect(pretérito.isEmpty)
  }

  @Test func aDueVerbBeyondTheBandWaits() {
    let practice = practiceWithDueVerbs(["contradecir"])
    #expect(!practice.dueItems().isEmpty)

    #expect(QuizDraw.dueQuestions(for: practice.dueItems(), band: .top100, asks: { _ in true }, using: &Self.generator).isEmpty)
    #expect(!QuizDraw.dueQuestions(for: practice.dueItems(), band: nil, asks: { _ in true }, using: &Self.generator).isEmpty)
  }

  @Test func aDuePatternAsksItsCellOfARegularVerbOfItsEnding() throws {
    let pattern = PracticeItem.pattern(tenseKey: "imperfecto_de_indicativo", person: "tp", ending: "er")
    for _ in 0..<5 {
      let question = try #require(QuizDraw.dueQuestions(for: [pattern], band: .top300, asks: { _ in true }, using: &Self.generator).first)
      #expect(question.tense == .imperfectoDeIndicativo)
      #expect(question.personNumber == .thirdPlural)
      #expect(question.verb.hasSuffix("er"))
      #expect(PracticeItem.exercised(by: question) == pattern)
      #expect(VerbMap.shared.entry(for: question.verb)?.isIn(.top300) == true)
    }
  }

  @Test func aScopedQuizAsksNoDueItems() {
    let practice = practiceWithDueVerbs()
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .myVerbs(["hablar"])))

    #expect(quiz.questions.allSatisfy { $0.verb == "hablar" })
    quiz.quit()
  }

  @Test func tenMoreMixesInWhatIsStillDue() {
    let verbs = ["tener", "ser", "ir", "hacer", "poner", "decir", "venir", "salir", "poder", "querer"]
    let practice = practiceWithDueVerbs(verbs)
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start())
    while quiz.quizState == .inProgress {
      quiz.process(proposedAnswer: quiz.currentQuestion?.writtenAnswer?.lowercased() ?? "")
    }
    // The first round's right answers moved what it asked, so the rest is still due.
    let stillDue = practice.dueItems().compactMap { item -> String? in
      guard case let .keyConjugation(infinitive, .yoPresente) = item else {
        return nil
      }
      return infinitive
    }
    #expect(stillDue.count >= QuizDraw.dueItemLimit)
    #expect(quiz.continueSession())

    for verb in stillDue.prefix(QuizDraw.dueItemLimit) {
      #expect(quiz.questions.dropFirst(QuizScope.roundLength).contains(yoPresente(verb)), "\(verb)")
    }
    quiz.quit()
  }

  private static var generator = SplitMix64(seed: 11)
}
