//
//  QuizRoundTests.swift
//  ConjugarTests
//
//  A session of rounds: ten questions, a missed question asked once more a few questions on, Ten
//  More, which round's score ranks, what the quiz signals may say, the record of a quiz left in
//  progress, and the quiz clock.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizRoundTests {
  private func makeQuiz(
    level: QuizLevel = .intermediate,
    clock: QuizClock = .hide,
    gameCenter: GameCenter = GameCenterFake()
  ) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: Region.spain.rawValue,
      Settings.quizClockKey: clock.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false)
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  private func answerRight(_ quiz: Quiz) {
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .totalMatch)
  }

  private func answerWrong(_ quiz: Quiz) {
    #expect(quiz.process(proposedAnswer: "zzzz") == .noMatch)
    quiz.continueAfterCorrection()
  }

  private func finishRight(_ quiz: Quiz) {
    while quiz.quizState == .inProgress {
      answerRight(quiz)
    }
  }

  private var liveActivities: LiveActivitiesSpy {
    Current.liveActivities as! LiveActivitiesSpy // swiftlint:disable:this force_cast
  }

  @Test func aQuizOverEveryVerbOrMyVerbsOrACollectionAsksTen() {
    for scope in [QuizScope.allVerbs, .myVerbs(["tener", "hablar", "ir"]), .collection(.goVerbs, title: "")] {
      let quiz = makeQuiz()
      #expect(quiz.start(scope: scope))
      #expect(quiz.questionCount == 10)
      #expect(quiz.questions.count == 10)
      quiz.quit()
    }
  }

  @Test func aMissedQuestionReturnsThreeQuestionsOn() {
    let quiz = makeQuiz()
    quiz.start()
    let missed = quiz.currentQuestion
    answerWrong(quiz)
    #expect(quiz.questions.count == 11)
    #expect(quiz.questionCount == 10)
    #expect(quiz.questions[4].isReask)
    #expect(quiz.questions[4] == missed?.reasked())
    #expect(quiz.questions.filter(\.isReask).count == 1)
    quiz.quit()
  }

  @Test func aQuestionMissedNearTheEndReturnsBeforeTheResults() {
    let quiz = makeQuiz()
    quiz.start()
    for _ in 0..<8 {
      answerRight(quiz)
    }
    let missed = quiz.currentQuestion
    answerWrong(quiz)
    #expect(quiz.questions.last == missed?.reasked())
    answerRight(quiz)
    #expect(quiz.currentQuestion?.isReask == true)
    answerRight(quiz)
    #expect(quiz.quizState == .finished)
    #expect(quiz.results.count == 11)
  }

  @Test func aReaskIsAskedOnceWhateverItsAnswer() {
    let quiz = makeQuiz()
    quiz.start()
    answerWrong(quiz)
    while quiz.currentQuestion?.isReask == false {
      answerRight(quiz)
    }
    #expect(quiz.process(proposedAnswer: "zzzz") == .noMatch)
    #expect(quiz.correction?.willBeReasked == false)
    quiz.continueAfterCorrection()
    finishRight(quiz)
    #expect(quiz.questions.filter(\.isReask).count == 1)
    #expect(quiz.questions.count == 11)
  }

  /// Nine right answers, a miss, and its re-ask right: 90 + 0 + 5.
  @Test func aRightReaskEarnsHalfAndCountsApart() {
    let quiz = makeQuiz()
    quiz.start()
    answerWrong(quiz)
    finishRight(quiz)
    #expect(quiz.score == 95)
    #expect(quiz.maximumScore == 105)
    #expect(quiz.firstRoundScore == 90)
    #expect(quiz.correctCount == 9)
    #expect(quiz.secondAttemptCount == 0)
    #expect(quiz.reaskCount == 1)
    #expect(quiz.reaskCorrectCount == 1)
  }

  /// A slip on a re-ask still earns its second attempt, which earns the re-ask's 5.
  @Test func aReaskRightOnItsSecondAttemptEarnsHalf() {
    let quiz = makeQuiz()
    quiz.start(scope: .verbPage("hablar"))
    answerWrong(quiz)
    answerRight(quiz)
    answerRight(quiz)
    #expect(quiz.currentQuestion?.isReask == true)
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz) + "x") == nil)
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .secondAttemptMatch)
    #expect(quiz.quizState == .finished)
    #expect(quiz.score == 25)
    #expect(quiz.secondAttemptCount == 0)
    #expect(quiz.reaskCorrectCount == 1)
  }

  /// A position that counted re-asks would tell how many answers were wrong.
  @Test func theQuestionReachedCountsNoReask() {
    let quiz = makeQuiz()
    quiz.start()
    answerWrong(quiz)
    answerWrong(quiz)
    answerWrong(quiz)
    answerRight(quiz)
    #expect(quiz.currentQuestion?.isReask == true)
    #expect(quiz.currentQuestionIndex == 4)
    #expect(quiz.questionReached == 4)
    quiz.quit()
  }

  @Test func tenMoreContinuesTheSession() {
    let quiz = makeQuiz()
    quiz.start()
    answerWrong(quiz)
    finishRight(quiz)
    #expect(quiz.canContinue)
    let firstRound = quiz.questions
    let score = quiz.score
    let elapsed = quiz.elapsedTime

    #expect(quiz.continueSession())
    #expect(quiz.quizState == .inProgress)
    #expect(quiz.roundCount == 2)
    #expect(quiz.currentQuestionIndex == firstRound.count)
    #expect(Array(quiz.questions.prefix(firstRound.count)) == firstRound)
    #expect(quiz.questions.count == firstRound.count + 10)
    #expect(quiz.questionCount == 20)
    #expect(quiz.score == score)
    #expect(quiz.elapsedTime == elapsed)
    #expect(quiz.isClockRunning)
    #expect(!quiz.canContinue)

    finishRight(quiz)
    #expect(quiz.score == score + 100)
    #expect(quiz.questionCount == 20)
    #expect(quiz.canContinue)
  }

  @Test func aQuitOrAVerbPageOffersNoTenMore() {
    let quit = makeQuiz()
    quit.start()
    answerRight(quit)
    quit.quit()
    #expect(!quit.canContinue)
    #expect(!quit.continueSession())
    #expect(quit.quizState == .finished)

    let verbPage = makeQuiz()
    verbPage.start(scope: .verbPage("tener"))
    finishRight(verbPage)
    #expect(!verbPage.canContinue)
    #expect(!verbPage.continueSession())
  }

  /// A later round over My Verbs asks only those verbs, and a cell the first round asked goes to
  /// another verb while one fits.
  @Test func tenMoreOverMyVerbsKeepsToThem() {
    let verbs = ["tener", "hablar", "ir", "comer", "vivir"]
    let quiz = makeQuiz(level: .advanced)
    quiz.start(scope: .myVerbs(verbs))
    finishRight(quiz)
    #expect(quiz.continueSession())
    finishRight(quiz)
    #expect(quiz.questions.count == 20)
    #expect(quiz.questions.allSatisfy { verbs.contains($0.verb) })
    #expect(Set(quiz.questions.map { "\($0.verb) \($0.tense.rawValue) \($0.personNumber.rawValue)" }).count == 20)
  }

  @Test func eachRoundStartsTheLiveActivity() {
    let quiz = makeQuiz()
    let startsBefore = liveActivities.startCount
    quiz.start()
    finishRight(quiz)
    quiz.continueSession()
    #expect(liveActivities.startCount == startsBefore + 2)
    #expect(liveActivities.lastState?.currentQuestion == 11)
    #expect(liveActivities.lastState?.totalQuestions == 20)
    quiz.quit()
  }

  /// Only the first round posts, and only its own questions' points: the re-ask's 5 and Ten
  /// More's 100 never count.
  @Test func aRankedSessionPostsItsFirstRoundOnly() async {
    let spy = GameCenterRoundSpy()
    let quiz = makeQuiz(gameCenter: spy)
    quiz.start()
    answerWrong(quiz)
    finishRight(quiz)
    #expect(quiz.isRankedRound)
    quiz.continueSession()
    #expect(!quiz.isRankedRound)
    finishRight(quiz)
    for _ in 0..<200 where spy.reportedScores.isEmpty {
      await Task.yield()
    }
    for _ in 0..<20 {
      await Task.yield()
    }
    #expect(spy.reportedScores == [90])
  }

  @Test func onlyAQuizOverEveryVerbRanks() {
    let quiz = makeQuiz()
    quiz.start(scope: .myVerbs(["tener", "hablar"]))
    #expect(!quiz.isRankedRound)
    quiz.quit()
    quiz.start(scope: .allVerbs(source: .deeplink))
    #expect(quiz.isRankedRound)
    quiz.quit()
  }

  @Test func aQuizInProgressIsRecordedUntilItEnds() {
    let quiz = makeQuiz(level: .elementary)
    quiz.start(scope: .myVerbs(["tener", "hablar"]))
    var entry = QuizAbandonment.entries(getterSetter: Current.getterSetter)[quiz.abandonmentID]
    #expect(entry == QuizAbandonment.Entry(level: "elementary", source: "myVerbs", questionNumber: 1))
    answerWrong(quiz)
    answerRight(quiz)
    entry = QuizAbandonment.entries(getterSetter: Current.getterSetter)[quiz.abandonmentID]
    #expect(entry?.questionNumber == 3)
    finishRight(quiz)
    #expect(QuizAbandonment.entries(getterSetter: Current.getterSetter)[quiz.abandonmentID] == nil)

    quiz.continueSession()
    #expect(QuizAbandonment.entries(getterSetter: Current.getterSetter)[quiz.abandonmentID]?.questionNumber == 11)
    quiz.quit()
    #expect(QuizAbandonment.entries(getterSetter: Current.getterSetter)[quiz.abandonmentID] == nil)
  }

  @Test func theNextLaunchReportsEachQuizLeftInProgress() {
    let getterSetter = GetterSetterFake()
    let analytics = AnalyticsSpy()
    QuizAbandonment.record(.init(level: "beginner", source: "tab", questionNumber: 4), id: "a", getterSetter: getterSetter)
    QuizAbandonment.record(.init(level: "advanced", source: "verbPage", questionNumber: 2), id: "b", getterSetter: getterSetter)
    QuizAbandonment.record(.init(level: "advanced", source: "list", questionNumber: 1), id: "c", getterSetter: getterSetter)
    QuizAbandonment.clear(id: "c", getterSetter: getterSetter)

    QuizAbandonment.reportAndClear(getterSetter: getterSetter, analytics: analytics)
    #expect(analytics.signalNames == [.abandonQuiz, .abandonQuiz])
    let reported = Set(analytics.signalParameters.map { "\($0["level"] ?? "") \($0["source"] ?? "") \($0["questionNumber"] ?? "")" })
    #expect(reported == ["beginner tab 4", "advanced verbPage 2"])
    #expect(QuizAbandonment.entries(getterSetter: getterSetter).isEmpty)

    QuizAbandonment.reportAndClear(getterSetter: getterSetter, analytics: analytics)
    #expect(analytics.signalNames.count == 2)
  }

  @Test func theClockIsHiddenByDefaultAndPersists() {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    #expect(settings.quizClock == .hide)
    settings.quizClock = .show
    #expect(Settings(getterSetter: getterSetter).quizClock == .show)
  }

  /// The clock counts while hidden, but the Live Activity shows no time.
  @Test func aHiddenClockKeepsTheTimeOffTheLiveActivity() {
    for clock in QuizClock.allCases {
      let quiz = makeQuiz(clock: clock)
      quiz.start()
      #expect(quiz.isClockRunning)
      #expect((liveActivities.lastState?.elapsedTime == nil) == (clock == .hide))
      quiz.quit()
    }
  }
}

private final class GameCenterRoundSpy: GameCenter {
  private(set) var reportedScores: [Int] = []
  var isAuthenticated: Bool { true }
  func authenticate() {}
  func reportScore(_ score: Int) async {
    reportedScores.append(score)
  }
  func showLeaderboard() {}
}
