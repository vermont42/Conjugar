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
    // A store of its own, so that answers here never reach `Current.practice`, from which a
    // later suite's ranked quiz would draw due items.
    return Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: shouldShuffle, practice: PracticeStore(getterSetter: GetterSetterFake()))
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
    #expect(QuizScope.myVerbs(Self.myVerbs).questionCount == QuizScope.roundLength)
  }

  /// Every scope the app can start, with whether it ranks, runs in a sheet, and starts the Live
  /// Activity. A new kind fails to compile `name(of:)` until it is named there, and fails this
  /// test until it has a row.
  @Test func everyScopeTheAppStartsPinsWhetherItRanks() {
    let challenge = DailyChallenge.Key(day: "2026-11-27", level: .beginner, region: .spain)
    let custom = CustomQuiz(verbSet: .collection(.irregularFuture))
    let practiceSet = PracticeSet(custom: CustomQuiz(tenses: [.pretérito]), level: .advanced)
    let rows: [(scope: QuizScope, isRanked: Bool, runsInSheet: Bool, startsLiveActivity: Bool)] = [
      (.allVerbs, true, false, true),
      (.allVerbs(source: .deeplink), true, false, true),
      (.myVerbs(Self.myVerbs), false, false, true),
      (.verbPage("tener"), false, true, false),
      (.collection(.goVerbs, title: "-go Verbs"), false, true, false),
      (.custom(custom, myVerbs: Self.myVerbs), false, false, true),
      (practiceSet.scope(source: .sharedLink), false, true, false),
      (.recordSession(.review), false, false, true),
      (.recordSession(.mistakes), false, false, true),
      (.verbEssentials(), false, false, true),
      (.verbEssentials(["tener", "ir"]), false, false, true),
      (.modelPractice(ModelPracticeSession(classNumber: "4A", mode: .alone)), false, true, false),
      (.modelPractice(ModelPracticeSession(classNumber: "4A", mode: .mixed)), false, true, false),
      (.recognition(), false, false, true),
      (.sentences(), false, false, true),
      (.speedRound(), false, false, false),
      (.daily(), false, false, true),
      (.challenge(challenge), false, false, false)
    ]
    for row in rows {
      let name = Self.name(of: row.scope.kind)
      #expect(row.scope.isRanked == row.isRanked, "\(name)")
      #expect(row.scope.mixesDueItems == row.isRanked, "\(name)")
      #expect(row.scope.mixesChoiceQuestions == row.isRanked, "\(name)")
      #expect(row.scope.kind.runsInSheet == row.runsInSheet, "\(name)")
      #expect(row.scope.startsLiveActivity == row.startsLiveActivity, "\(name)")
    }
    #expect(Set(rows.map { Self.name(of: $0.scope.kind) }) == Set(Self.kindNames))
  }

  private static let kindNames = [
    "allVerbs", "myVerbs", "verbPage", "collection", "custom", "practiceSet", "recordSession", "verbEssentials",
    "modelPractice", "recognition", "sentences", "speedRound", "daily", "challenge"
  ]

  private static func name(of kind: QuizScope.Kind) -> String {
    switch kind {
    case .allVerbs: "allVerbs"
    case .myVerbs: "myVerbs"
    case .verbPage: "verbPage"
    case .collection: "collection"
    case .custom: "custom"
    case .practiceSet: "practiceSet"
    case .recordSession: "recordSession"
    case .verbEssentials: "verbEssentials"
    case .modelPractice: "modelPractice"
    case .recognition: "recognition"
    case .sentences: "sentences"
    case .speedRound: "speedRound"
    case .daily: "daily"
    case .challenge: "challenge"
    }
  }

  /// Test Me's correction links nowhere, since its verb's page is under the sheet.
  @Test func onlyTestMeHidesTheVerbLink() {
    #expect(!QuizScope.verbPage("tener").showsVerbLink)
    #expect(QuizScope.collection(.goVerbs, title: "-go Verbs").showsVerbLink)
    #expect(QuizScope.allVerbs.showsVerbLink)
  }

  /// The tab's quiz is a round of ten at every level.
  @Test func theDefaultScopeAsksTheFullQuiz() {
    for level in QuizLevel.allCases {
      let quiz = makeQuiz(level: level)
      #expect(quiz.start())
      #expect(quiz.scope == .allVerbs)
      #expect(quiz.questionCount == QuizScope.roundLength)
    }
  }

  @Test func aMyVerbsQuizAsksOnlyItsVerbs() {
    for level in QuizLevel.allCases {
      for shouldShuffle in [false, true] {
        let quiz = makeQuiz(level: level, shouldShuffle: shouldShuffle)
        #expect(quiz.start(scope: .myVerbs(Self.myVerbs)))
        #expect(quiz.questionCount == QuizScope.roundLength)
        for _ in 0..<2 {
          answerEveryQuestion(quiz)
          #expect(quiz.continueSession())
        }
        answerEveryQuestion(quiz)
        #expect(quiz.questionCount == 3 * QuizScope.roundLength)
        for question in quiz.questions {
          #expect(Self.myVerbs.contains(question.verb), "\(question.verb) is not in My Verbs")
          #expect(Self.conjugates(question), "\(question.verb) cannot be asked in \(question.tense) \(question.personNumber)")
        }
        // Five verbs over three rounds: each verb takes its turn, even abolir, which a beginner
        // can be asked in only two cells.
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
        #expect((4...6).contains(tenerCount), "tener asked \(tenerCount) of 10 at \(level)")
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

  /// Only the ranked quiz reports a score.
  @Test func onlyARankedQuizReportsItsScore() {
    let spy = GameCenterSpy()
    let scoped = makeQuiz(gameCenter: spy)
    scoped.start(scope: .myVerbs(Self.myVerbs))
    answerEveryQuestion(scoped)
    let short = makeQuiz(gameCenter: spy)
    short.start(scope: .verbPage("ir"))
    answerEveryQuestion(short)
    let ranked = makeQuiz(gameCenter: spy)
    ranked.start()
    answerEveryQuestion(ranked)
    #expect(spy.submissions.map(\.score) == [ranked.score])
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
