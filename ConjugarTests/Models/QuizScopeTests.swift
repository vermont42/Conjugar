//
//  QuizScopeTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  A quiz over chosen verbs: My Verbs on the Quiz tab, and Test Me's three questions on a verb's
//  page.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizScopeTests {
  private static let myVerbs = ["tener", "hablar", "ir", "arrepentir", "abolir"]

  private func makeQuiz(
    level: QuizLevel = .intermediate,
    region: Region = .spain,
    secondSingular: SecondSingularQuiz = .tu,
    shouldShuffle: Bool = false,
    gameCenter: GameCenter = GameCenterFake()
  ) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: region.rawValue,
      Settings.secondSingularQuizKey: secondSingular.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: shouldShuffle)
  }

  private static func conjugates(_ question: Quiz.Question) -> Bool {
    if case .success = TenseBridge.conjugate(infinitive: question.verb, tense: question.tense, personNumber: question.personNumber) {
      return true
    }
    return false
  }

  @Test func onlyTheFullQuizOverEveryVerbRanks() {
    #expect(QuizScope.allVerbs.isRanked)
    #expect(QuizScope.allVerbs(source: .deeplink).isRanked)
    #expect(!QuizScope.myVerbs(Self.myVerbs).isRanked)
    #expect(!QuizScope.verbPage("tener").isRanked)
    #expect(QuizScope.allVerbs.source == .tab)
    #expect(QuizScope.myVerbs(Self.myVerbs).source == .myVerbs)
    #expect(QuizScope.verbPage("tener").source == .verbPage)
    #expect(QuizScope.verbPage("tener").questionCount == 3)
    #expect(QuizScope.myVerbs(Self.myVerbs).questionCount == QuizScope.fullLength)
  }

  /// The tab's quiz is thirty questions at every level.
  @Test func theDefaultScopeAsksTheFullQuiz() {
    for level in QuizLevel.allCases {
      let quiz = makeQuiz(level: level)
      #expect(quiz.start())
      #expect(quiz.scope == .allVerbs)
      #expect(quiz.questionCount == QuizScope.fullLength)
    }
  }

  @Test func aMyVerbsQuizAsksOnlyItsVerbs() {
    for level in QuizLevel.allCases {
      for shouldShuffle in [false, true] {
        let quiz = makeQuiz(level: level, shouldShuffle: shouldShuffle)
        #expect(quiz.start(scope: .myVerbs(Self.myVerbs)))
        #expect(quiz.questionCount == QuizScope.fullLength)
        for question in quiz.questions {
          #expect(Self.myVerbs.contains(question.verb), "\(question.verb) is not in My Verbs")
          #expect(Self.conjugates(question), "\(question.verb) cannot be asked in \(question.tense) \(question.personNumber)")
        }
        // Five verbs over thirty questions: each verb takes its turn.
        #expect(Set(quiz.questions.map(\.verb)) == Set(Self.myVerbs))
      }
    }
  }

  /// The verbs take turns, so two verbs share a quiz about evenly, shuffled or not.
  @Test func myVerbsShareTheQuizEvenly() {
    for level in QuizLevel.allCases {
      for shouldShuffle in [false, true] {
        let quiz = makeQuiz(level: level, shouldShuffle: shouldShuffle)
        quiz.start(scope: .myVerbs(["tener", "ir"]))
        let tenerCount = quiz.questions.filter { $0.verb == "tener" }.count
        #expect((13...17).contains(tenerCount), "tener asked \(tenerCount) of 30 at \(level)")
      }
    }
  }

  /// A scoped quiz asks at the learner's level, so a beginner's My Verbs asks only the presente
  /// and the commands of tú, usted, and ustedes.
  @Test func aMyVerbsQuizKeepsTheLevelsTenses() {
    for shouldShuffle in [false, true] {
      let quiz = makeQuiz(level: .beginner, shouldShuffle: shouldShuffle)
      quiz.start(scope: .myVerbs(Self.myVerbs))
      #expect(Set(quiz.questions.map(\.tense)) == [.presenteDeIndicativo, .imperativoPositivo])
      #expect(!quiz.questions.contains { $0.tense == .imperativoPositivo && [.firstPlural, .secondPlural].contains($0.personNumber) })
    }
  }

  /// Three distinct cells in as many tenses as the level has, up to three: a beginner's two
  /// tenses give two.
  @Test func testMeAsksDistinctTensesOfTheVerb() {
    for level in QuizLevel.allCases {
      for shouldShuffle in [false, true] {
        let quiz = makeQuiz(level: level, shouldShuffle: shouldShuffle)
        #expect(quiz.start(scope: .verbPage("tener")))
        #expect(quiz.questionCount == 3)
        #expect(quiz.questions.allSatisfy { $0.verb == "tener" })
        #expect(Set(quiz.questions.map(\.tense)).count == min(3, level.pool.count))
        #expect(Set(quiz.questions.map { "\($0.tense.rawValue) \($0.personNumber.rawValue)" }).count == 3)
        #expect(quiz.questions.allSatisfy(Self.conjugates))
        #expect(quiz.questions.allSatisfy { level.entry(for: $0.tense)?.asks($0.personNumber) == true })
      }
    }
  }

  /// A defective verb is never asked a cell it lacks, however long the quiz.
  @Test func aDefectiveVerbIsAskedOnlyCellsItHas() {
    for level in QuizLevel.allCases {
      #expect(Conjugator.isDefective(infinitive: "abolir"))
      for scope in [QuizScope.verbPage("abolir"), .myVerbs(["abolir"])] {
        let quiz = makeQuiz(level: level, shouldShuffle: true)
        #expect(quiz.start(scope: scope))
        #expect(!quiz.questions.isEmpty)
        #expect(quiz.questions.allSatisfy(Self.conjugates))
      }
    }
  }

  @Test func theLatinAmericaRegionAsksNoVosotros() {
    for level in QuizLevel.allCases {
      for scope in [QuizScope.verbPage("hablar"), .myVerbs(Self.myVerbs)] {
        for _ in 0..<3 {
          let quiz = makeQuiz(level: level, region: .latinAmerica, shouldShuffle: true)
          quiz.start(scope: scope)
          #expect(!quiz.questions.contains { $0.personNumber == .secondPlural })
        }
      }
    }
  }

  /// Under the vos setting a scoped quiz asks vos, never tú, as the tab's quiz does.
  @Test func theVosSettingAsksVos() {
    for _ in 0..<3 {
      let quiz = makeQuiz(level: .intermediate, secondSingular: .vos, shouldShuffle: true)
      quiz.start(scope: .verbPage("tener"))
      #expect(!quiz.questions.contains { $0.personNumber == .secondSingularTú })
    }
  }

  @Test func anEmptyScopeStartsNothing() {
    let quiz = makeQuiz()
    #expect(!quiz.start(scope: .myVerbs([])))
    #expect(quiz.quizState == .notStarted)
    #expect(!quiz.start(scope: .myVerbs(["notaverb"])))
    #expect(quiz.quizState == .notStarted)
  }

  /// A scope that gives no question leaves a finished quiz's results in place.
  @Test func anEmptyScopeKeepsTheLastResults() {
    let quiz = makeQuiz()
    quiz.start(scope: .verbPage("tener"))
    answerEveryQuestion(quiz)
    #expect(quiz.quizState == .finished)
    #expect(!quiz.start(scope: .myVerbs([])))
    #expect(quiz.quizState == .finished)
    #expect(quiz.results.count == 3)
    #expect(quiz.scope == .verbPage("tener"))
  }

  /// A perfect Test Me run scores 10 a question.
  @Test func aPerfectTestMeRunScoresTheMaximum() {
    let quiz = makeQuiz(level: .intermediate)
    quiz.start(scope: .verbPage("tener"))
    answerEveryQuestion(quiz)
    #expect(quiz.score == 30)
    #expect(quiz.correctCount == 3)
  }

  /// Only the ranked quiz reports a score. The scoped quiz runs first, so if it reported, its
  /// task would land before the ranked one's.
  @Test func onlyARankedQuizReportsItsScore() async {
    let spy = GameCenterScoreSpy()
    let scoped = makeQuiz(gameCenter: spy)
    scoped.start(scope: .myVerbs(Self.myVerbs))
    answerEveryQuestion(scoped)
    let short = makeQuiz(gameCenter: spy)
    short.start(scope: .verbPage("ir"))
    answerEveryQuestion(short)
    let ranked = makeQuiz(gameCenter: spy)
    ranked.start()
    answerEveryQuestion(ranked)
    for _ in 0..<200 where spy.reportedScores.isEmpty {
      await Task.yield()
    }
    #expect(spy.reportedScores == [ranked.score])
  }

  private func answerEveryQuestion(_ quiz: Quiz) {
    while quiz.quizState == .inProgress {
      guard case let .success(answer) = TenseBridge.conjugate(
        infinitive: quiz.verb,
        tense: quiz.tense,
        personNumber: quiz.currentPersonNumber,
        pronoun: .written
      ) else {
        Issue.record("\(quiz.verb) could not be conjugated in \(quiz.tense)")
        return
      }
      _ = quiz.process(proposedAnswer: answer)
    }
  }
}

/// Records each score reported, for `onlyARankedQuizReportsItsScore`.
private final class GameCenterScoreSpy: GameCenter {
  private(set) var reportedScores: [Int] = []
  var isAuthenticated: Bool { true }
  func authenticate() {}
  func reportScore(_ score: Int) async {
    reportedScores.append(score)
  }
  func showLeaderboard() {}
}
