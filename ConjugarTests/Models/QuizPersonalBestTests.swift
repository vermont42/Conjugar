//
//  QuizPersonalBestTests.swift
//  ConjugarTests
//
//  The best ranked score at each level, kept on the device, and the achievements' progress a quiz
//  reports to Game Center as it finishes or is quit.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct QuizPersonalBestTests {
  private func makeQuiz(
    level: QuizLevel = .beginner,
    practice: PracticeStore,
    gameCenter: GameCenter = GameCenterSpy()
  ) -> (Quiz, Settings) {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: Region.latinAmerica.rawValue
    ]))
    return (Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false, practice: practice), settings)
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  /// Misses the first `misses` questions that are not re-asks and answers the rest right.
  private func finish(_ quiz: Quiz, missing misses: Int = 0) {
    var missed = 0
    while quiz.quizState == .inProgress {
      if missed < misses, quiz.currentQuestion?.isReask == false {
        #expect(quiz.process(proposedAnswer: "zzzz") == .noMatch)
        quiz.continueAfterCorrection()
        missed += 1
      } else {
        #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .totalMatch)
      }
    }
  }

  @Test func theFirstRankedRoundSetsTheBest() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let (quiz, _) = makeQuiz(practice: practice)
    #expect(practice.levelBest(at: .beginner) == nil)

    #expect(quiz.start())
    finish(quiz)
    #expect(quiz.isNewLevelBest)
    #expect(quiz.levelPreviousBest == nil)
    #expect(practice.levelBest(at: .beginner) == 100)
  }

  @Test func aLowerScoreDoesNotBeatItAndAHigherOneReplacesIt() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let (quiz, _) = makeQuiz(practice: practice)

    quiz.start()
    finish(quiz, missing: 2)
    #expect(quiz.firstRoundScore == 80)
    #expect(quiz.isNewLevelBest)
    #expect(practice.levelBest(at: .beginner) == 80)

    quiz.start()
    finish(quiz, missing: 3)
    #expect(!quiz.isNewLevelBest)
    #expect(quiz.levelPreviousBest == 80)
    #expect(practice.levelBest(at: .beginner) == 80)

    quiz.start()
    finish(quiz, missing: 1)
    #expect(quiz.isNewLevelBest)
    #expect(quiz.levelPreviousBest == 80)
    #expect(practice.levelBest(at: .beginner) == 90)
  }

  @Test func eachLevelHasItsOwnBest() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let (quiz, settings) = makeQuiz(level: .beginner, practice: practice)
    quiz.start()
    finish(quiz, missing: 1)
    settings.quizLevel = .advanced
    quiz.start()
    finish(quiz)
    #expect(quiz.isNewLevelBest)
    #expect(practice.levelBest(at: .beginner) == 90)
    #expect(practice.levelBest(at: .advanced) == 100)
    #expect(practice.levelBest(at: .elementary) == nil)
  }

  @Test func tenMoreAndAScoreOfZeroSetNone() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let (quiz, _) = makeQuiz(practice: practice)
    quiz.start()
    finish(quiz, missing: 10)
    #expect(quiz.firstRoundScore == 0)
    #expect(!quiz.isNewLevelBest)
    #expect(practice.levelBest(at: .beginner) == nil)

    quiz.start()
    finish(quiz)
    #expect(quiz.continueSession())
    #expect(!quiz.isNewLevelBest)
    #expect(quiz.levelPreviousBest == nil)
    finish(quiz)
    #expect(!quiz.isNewLevelBest)
    #expect(quiz.levelPreviousBest == nil)
    #expect(practice.levelBest(at: .beginner) == 100)
  }

  @Test func anUnrankedSessionSetsNone() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let (quiz, _) = makeQuiz(practice: practice)
    for scope in [QuizScope.daily(), .myVerbs(["tener", "hablar", "ir"]), .verbPage("tener")] {
      #expect(quiz.start(scope: scope))
      finish(quiz)
      #expect(!quiz.isNewLevelBest)
    }
    #expect(practice.levelBest(at: .beginner) == nil)
  }

  @Test func theBestsSurviveALaunchAndAResetForgetsThem() {
    let getterSetter = GetterSetterFake()
    let practice = PracticeStore(getterSetter: getterSetter)
    #expect(practice.recordRankedScore(70, level: .elementary))
    #expect(practice.recordRankedScore(95, level: .intermediate))
    #expect(!practice.isEmpty)

    let relaunched = PracticeStore(getterSetter: getterSetter)
    #expect(relaunched.levelBest(at: .elementary) == 70)
    #expect(relaunched.levelBest(at: .intermediate) == 95)

    relaunched.reset()
    #expect(relaunched.levelBest(at: .elementary) == nil)
    #expect(relaunched.isEmpty)
    #expect(PracticeStore(getterSetter: getterSetter).levelBest(at: .intermediate) == nil)
  }

  /// A record whose every Beginner pattern is mastered reports 100 as the quiz finishes.
  @Test func aFinishReportsTheRecordsProgress() {
    let getterSetter = GetterSetterFake()
    var record = PracticeRecord()
    let mastery = Mastery(level: .beginner, record: record, secondSingular: .secondSingularTú, region: .latinAmerica)
    for table in mastery.patterns {
      for personNumber in table.personNumbers {
        for ending in Mastery.endings {
          let item = PracticeItem.pattern(of: ConjugationCell(tense: table.tense, personNumber: personNumber), ending: ending)!
          record.recordAnswer(item, isCorrect: true, at: Date.now.addingTimeInterval(-12 * 86_400))
          record.recordAnswer(item, isCorrect: true, at: Date.now.addingTimeInterval(-8 * 86_400))
        }
      }
    }
    if let json = record.json {
      getterSetter.set(key: PracticeRecord.storageKey, value: json)
    }
    let spy = GameCenterSpy()
    let (quiz, _) = makeQuiz(practice: PracticeStore(getterSetter: getterSetter), gameCenter: spy)

    quiz.start()
    #expect(spy.achievementReports.isEmpty)
    finish(quiz)
    #expect(spy.achievementReports.count == 1)
    #expect(spy.achievementReports.last?[.patternsBeginner] == 100)
    #expect((spy.achievementReports.last?[.patternsElementary] ?? 100) < 100)
  }

  @Test func aQuitReportsAndSignedOutNothingIs() {
    let spy = GameCenterSpy()
    let (quiz, _) = makeQuiz(practice: PracticeStore(getterSetter: GetterSetterFake()), gameCenter: spy)
    quiz.start()
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .totalMatch)
    quiz.quit()
    #expect(spy.achievementReports.count == 1)

    let signedOut = GameCenterSpy(isAuthenticated: false)
    let (other, _) = makeQuiz(practice: PracticeStore(getterSetter: GetterSetterFake()), gameCenter: signedOut)
    other.start()
    finish(other)
    other.start()
    other.quit()
    #expect(signedOut.achievementReports.isEmpty)
  }
}
