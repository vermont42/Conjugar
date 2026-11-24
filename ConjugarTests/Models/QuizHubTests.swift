//
//  QuizHubTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The last quiz's results, which the Quiz tab shows: their stored form, what each scope keeps,
//  and when a quiz writes or forgets them.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct QuizHubTests {
  private func makeQuiz(level: QuizLevel = .elementary, practice: PracticeStore) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: Region.spain.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: true, randomSource: SplitMix64(seed: 3), practice: practice)
  }

  private func answerAll(_ quiz: Quiz, rightly: Bool = true) {
    while quiz.quizState == .inProgress {
      if quiz.isHeld {
        quiz.continueAfterCorrection()
        continue
      }
      let answer = quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
      quiz.process(proposedAnswer: rightly ? answer : "zzzzzzzz")
    }
  }

  private func daysAgo(_ days: Double) -> Date {
    Date.now.addingTimeInterval(-days * 86_400)
  }

  @Test func theStoredFormIsPinned() throws {
    let json = #"{"kind":"collection","subject":"goVerbs","levelKey":"elementary","score":75,"correctCount":7,"secondAttemptCount":1,"questionCount":10,"date":0}"#
    let result = try #require(LastQuizResult(json: json))

    #expect(result == LastQuizResult(
      kind: .collection,
      subject: "goVerbs",
      level: .elementary,
      score: 75,
      correctCount: 7,
      secondAttemptCount: 1,
      questionCount: 10,
      date: Date(timeIntervalSinceReferenceDate: 0)
    ))
  }

  @Test func aResultRoundTrips() throws {
    let result = LastQuizResult(kind: .verbPage, subject: "tener", level: .advanced, score: 25, correctCount: 2, secondAttemptCount: 1, questionCount: 3, date: Date(timeIntervalSinceReferenceDate: 1_000))
    let json = try #require(result.json)

    #expect(LastQuizResult(json: json) == result)
  }

  @Test func aResultWithNoLevelReadsBack() throws {
    let json = #"{"kind":"review","score":10,"correctCount":1,"secondAttemptCount":0,"questionCount":1,"date":0}"#
    let result = try #require(LastQuizResult(json: json))

    #expect(result.level == nil)
    #expect(result.subject == nil)
    #expect(LastQuizResult(json: "") == nil)
    #expect(LastQuizResult(json: #"{"kind":"speedRound"}"#) == nil)
  }

  @Test func eachScopeHasItsKind() {
    let custom = CustomQuiz(tenses: [.pretérito])
    #expect(LastQuizResult.Kind(scope: .allVerbs) == .allVerbs)
    #expect(LastQuizResult.Kind(scope: .allVerbs(source: .deeplink)) == .allVerbs)
    #expect(LastQuizResult.Kind(scope: .myVerbs(["tener"])) == .myVerbs)
    #expect(LastQuizResult.Kind(scope: .verbPage("tener")) == .verbPage)
    #expect(LastQuizResult.Kind(scope: .collection(.goVerbs, title: "")) == .collection)
    #expect(LastQuizResult.Kind(scope: .custom(custom, myVerbs: [])) == .custom)
    #expect(LastQuizResult.Kind(scope: .custom(CustomQuiz(verbSet: .collection(.goVerbs)), myVerbs: [])) == .custom)
    #expect(LastQuizResult.Kind(scope: PracticeSet(custom: custom, level: nil).scope(source: .sharedLink)) == .practiceSet)
    #expect(LastQuizResult.Kind(scope: .recordSession(.review)) == .review)
    #expect(LastQuizResult.Kind(scope: .recordSession(.mistakes)) == .mistakes)
  }

  @Test func eachKindHasATitle() {
    func title(_ kind: LastQuizResult.Kind, _ subject: String? = nil) -> String {
      LastQuizResult(kind: kind, subject: subject, level: nil, score: 0, correctCount: 0, secondAttemptCount: 0, questionCount: 0, date: .now).title
    }

    #expect(title(.allVerbs) == L.Quiz.allVerbs)
    #expect(title(.collection, "goVerbs") == VerbCollection.goVerbs.title)
    #expect(title(.collection, "model-31") == VerbCollection.model("31").title)
    #expect(title(.custom) == L.CustomQuiz.title)
    #expect(title(.mistakes) == L.PracticeSession.mistakes)
    #expect(title(.myVerbs) == L.MyVerbs.title)
    #expect(title(.practiceSet) == L.PracticeSet.title)
    #expect(title(.review) == L.PracticeSession.review)
    #expect(title(.verbPage, "arrepentir") == "arrepentirse")
  }

  @Test func theStoreKeepsTheResultAcrossALaunch() {
    let getterSetter = GetterSetterFake()
    let store = PracticeStore(getterSetter: getterSetter)
    #expect(store.lastResult == nil)
    #expect(store.isEmpty)
    let result = LastQuizResult(kind: .allVerbs, level: .beginner, score: 90, correctCount: 9, secondAttemptCount: 0, questionCount: 10, date: Date(timeIntervalSinceReferenceDate: 0))

    store.recordResult(result)

    #expect(!store.isEmpty)
    #expect(PracticeStore(getterSetter: getterSetter).lastResult == result)
  }

  @Test func resetForgetsTheResult() {
    let getterSetter = GetterSetterFake()
    let store = PracticeStore(getterSetter: getterSetter)
    store.recordResult(LastQuizResult(kind: .allVerbs, level: .beginner, score: 90, correctCount: 9, secondAttemptCount: 0, questionCount: 10, date: .now))

    store.reset()

    #expect(store.lastResult == nil)
    #expect(store.isEmpty)
    #expect(PracticeStore(getterSetter: getterSetter).lastResult == nil)
  }

  @Test func aFinishedQuizKeepsItsResult() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start())

    answerAll(quiz)

    let result = try #require(practice.lastResult)
    #expect(result.kind == .allVerbs)
    #expect(result.level == .elementary)
    #expect(result.score == quiz.score)
    #expect(result.correctCount == 10)
    #expect(result.questionCount == 10)
    #expect(result.secondAttemptCount == 0)
    #expect(PracticeRecord.daysBetween(result.date, and: .now) == 0)
  }

  @Test func tenMoreReplacesTheResultWithTheSessionSoFar() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start())
    answerAll(quiz)
    #expect(quiz.continueSession())
    #expect(practice.lastResult?.questionCount == 10)

    answerAll(quiz, rightly: false)

    let result = try #require(practice.lastResult)
    #expect(result.questionCount == 20)
    #expect(result.correctCount == 10)
    #expect(result.score == quiz.score)
  }

  @Test func aQuitQuizKeepsNothing() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start())
    if let answer = quiz.currentQuestion?.writtenAnswer?.lowercased() {
      quiz.process(proposedAnswer: answer)
    }

    quiz.quit()

    #expect(practice.lastResult == nil)
  }

  @Test func aQuitKeepsTheEarlierResult() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .verbPage("tener")))
    answerAll(quiz)
    let finished = try #require(practice.lastResult)

    #expect(quiz.start())
    quiz.quit()

    #expect(practice.lastResult == finished)
  }

  @Test func aReviewKeepsNoLevel() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    practice.recordLookup("tener", source: .search, at: daysAgo(40))
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .recordSession(.review)))

    answerAll(quiz)

    let result = try #require(practice.lastResult)
    #expect(result.kind == .review)
    #expect(result.level == nil)
    #expect(result.questionCount == quiz.questionCount)
  }

  @Test func aVerbPagesQuizNamesItsVerb() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(level: .advanced, practice: practice)
    #expect(quiz.start(scope: .verbPage("tener")))

    answerAll(quiz)

    let result = try #require(practice.lastResult)
    #expect(result.kind == .verbPage)
    #expect(result.subject == "tener")
    #expect(result.title == "tener")
    #expect(result.level == .advanced)
    #expect(result.questionCount == 3)
  }

  @Test func aCollectionsQuizNamesItsCollection() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .collection(.goVerbs, title: VerbCollection.goVerbs.title)))

    answerAll(quiz)

    let result = try #require(practice.lastResult)
    #expect(result.kind == .collection)
    #expect(result.subject == "goVerbs")
  }
}
