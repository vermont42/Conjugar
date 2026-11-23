//
//  QuizLiveActivityTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Which quizzes start, update, and end the quiz Live Activity, the app's only one, checked
//  against `LiveActivitiesSpy`. `Current` is shared with suites running in parallel, so each
//  test compares the spy's counts before and after its own steps. The steps are synchronous
//  on the main actor, so no other test's quiz can start or end between them.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizLiveActivityTests {
  private var spy: LiveActivitiesSpy {
    Current.liveActivities as! LiveActivitiesSpy // swiftlint:disable:this force_cast
  }

  private func startedQuiz(scope: QuizScope = .allVerbs) -> Quiz {
    let quiz = Quiz(settings: Settings(getterSetter: GetterSetterFake()), gameCenter: GameCenterFake(), shouldShuffle: false)
    #expect(quiz.start(scope: scope))
    return quiz
  }

  private func answerCorrectly(_ quiz: Quiz) {
    guard case .success(let correct) = TenseBridge.conjugate(infinitive: quiz.verb, tense: quiz.tense, personNumber: quiz.currentPersonNumber) else {
      Issue.record("Could not conjugate \(quiz.verb).")
      return
    }
    _ = quiz.process(proposedAnswer: correct)
  }

  @Test func theTabsQuizStartsUpdatesAndEndsTheLiveActivity() {
    let startsBefore = spy.startCount
    let quiz = startedQuiz()
    #expect(spy.startCount == startsBefore + 1)

    let updatesBefore = spy.updateCount
    answerCorrectly(quiz)
    #expect(spy.updateCount == updatesBefore + 1)

    let endsBefore = spy.endCount
    quiz.quit()
    #expect(spy.endCount == endsBefore + 1)
  }

  @Test func finishingTheTabsQuizEndsTheLiveActivityOnce() {
    let quiz = startedQuiz(scope: .myVerbs(["tener", "hablar"]))
    let endsBefore = spy.endCount
    while quiz.quizState == .inProgress {
      answerCorrectly(quiz)
    }
    #expect(spy.endCount == endsBefore + 1)
    quiz.quit()
    #expect(spy.endCount == endsBefore + 1)
  }

  @Test func aCollectionsQuizOverTheTabsQuizLeavesTheTabsLiveActivityAlone() {
    let tab = startedQuiz()
    let startsBefore = spy.startCount
    let updatesBefore = spy.updateCount
    let endsBefore = spy.endCount

    let sheet = startedQuiz(scope: .collection(.goVerbs, title: ""))
    answerCorrectly(sheet)
    sheet.quit()
    #expect(spy.startCount == startsBefore)
    #expect(spy.updateCount == updatesBefore)
    #expect(spy.endCount == endsBefore)

    tab.quit()
    #expect(spy.endCount == endsBefore + 1)
  }

  @Test func aVerbPageQuizTakesNoLiveActivity() {
    let startsBefore = spy.startCount
    let updatesBefore = spy.updateCount
    let endsBefore = spy.endCount
    let quiz = startedQuiz(scope: .verbPage("tener"))
    answerCorrectly(quiz)
    quiz.quit()
    #expect(spy.startCount == startsBefore)
    #expect(spy.updateCount == updatesBefore)
    #expect(spy.endCount == endsBefore)
  }
}
