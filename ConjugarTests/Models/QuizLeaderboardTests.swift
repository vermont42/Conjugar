//
//  QuizLeaderboardTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  One Game Center leaderboard a level: which sessions post, what they post, and to which board.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizLeaderboardTests {
  private func makeQuiz(level: QuizLevel, gameCenter: GameCenter) -> (Quiz, Settings) {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: Region.spain.rawValue
    ]))
    return (Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false, practice: PracticeStore(getterSetter: GetterSetterFake())), settings)
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  private func finishRight(_ quiz: Quiz) {
    while quiz.quizState == .inProgress {
      #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .totalMatch)
    }
  }

  /// App Store Connect never lets an ID change, so each is pinned as created there.
  @Test func eachLevelHasItsOwnLeaderboard() {
    #expect(QuizLevel.beginner.leaderboardID == "conjugar.level.beginner")
    #expect(QuizLevel.elementary.leaderboardID == "conjugar.level.elementary")
    #expect(QuizLevel.intermediate.leaderboardID == "conjugar.level.intermediate")
    #expect(QuizLevel.advanced.leaderboardID == "conjugar.level.advanced")
    #expect(Set(QuizLevel.allCases.map(\.leaderboardID)).count == QuizLevel.allCases.count)
  }

  @Test func aRankedSessionPostsAPerfectHundredToItsLevel() {
    for level in QuizLevel.allCases {
      let spy = GameCenterSpy()
      let (quiz, _) = makeQuiz(level: level, gameCenter: spy)
      #expect(quiz.start())
      finishRight(quiz)
      #expect(spy.submissions == [GameCenterSpy.Submission(score: 100, level: level)])
    }
  }

  /// A level changed in Settings mid-quiz changes the next quiz, not the board this one posts to.
  @Test func theLevelIsTheOneTheQuizBeganAt() {
    let spy = GameCenterSpy()
    let (quiz, settings) = makeQuiz(level: .beginner, gameCenter: spy)
    quiz.start()
    settings.quizLevel = .advanced
    finishRight(quiz)
    #expect(spy.submissions.map(\.level) == [.beginner])
  }

  /// A right second attempt's 5 counts. The re-ask after a miss earns 5 too, but beyond the ten.
  @Test func aSecondAttemptCountsAndAReaskDoesNot() {
    let spy = GameCenterSpy()
    let (quiz, _) = makeQuiz(level: .elementary, gameCenter: spy)
    quiz.start()
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz) + "x") == nil)
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .secondAttemptMatch)
    #expect(quiz.process(proposedAnswer: "zzzz") == .noMatch)
    quiz.continueAfterCorrection()
    finishRight(quiz)
    #expect(quiz.reaskCount == 1)
    #expect(quiz.score == 90)
    #expect(spy.submissions.map(\.score) == [85])
  }

  @Test func tenMorePostsNothingMore() {
    let spy = GameCenterSpy()
    let (quiz, _) = makeQuiz(level: .intermediate, gameCenter: spy)
    quiz.start()
    finishRight(quiz)
    #expect(quiz.continueSession())
    finishRight(quiz)
    #expect(spy.submissions.count == 1)
  }

  @Test func aScopedQuizPostsNothing() {
    let spy = GameCenterSpy()
    for scope in [QuizScope.myVerbs(["tener", "hablar", "ir"]), .collection(.goVerbs, title: ""), .verbPage("tener")] {
      let (quiz, _) = makeQuiz(level: .advanced, gameCenter: spy)
      #expect(quiz.start(scope: scope))
      finishRight(quiz)
    }
    #expect(spy.submissions.isEmpty)
  }
}
