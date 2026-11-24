//
//  DailyChallengeTests.swift
//  ConjugarTests
//
//  The daily challenge: its seed and day, the draw every device makes from them, the result and
//  the text it shares, the quiz widget's question, the challenge in a quiz, its store, and its
//  link.
//

import Foundation
import Testing
@testable import Conjugar

/// What a question asks, in a form two draws can be compared by.
private func signature(_ question: QuizQuestion) -> String {
  "\(question.verb) \(question.tense.rawValue) \(question.personNumber.rawValue)"
}

/// The `offset`th day after 24 November 2026.
private func key(_ offset: Int, level: QuizLevel, region: Region = .latinAmerica) -> DailyChallenge.Key {
  let start = DailyChallenge.date(fromDayString: "2026-11-24") ?? .now
  let date = DailyChallenge.calendar.date(byAdding: .day, value: offset, to: start) ?? start
  return DailyChallenge.Key(date: date, level: level, region: region)
}

private func wordCount(_ form: String) -> Int {
  form.split(separator: " ").count
}

@MainActor
struct DailyChallengeTests {
  /// Every device must make the same seed from the same day, level, and region, in every process
  /// and for all time, so the text and its FNV-1a fold are pinned. A failure here means every
  /// challenge changed for everyone.
  @Test func theSeedIsPinned() {
    let key = DailyChallenge.Key(day: "2026-11-24", level: .intermediate, region: .spain)
    #expect(key.seedText == "challenge-2026-11-24-intermediate-spain")
    #expect(key.seed == 3_446_392_299_761_896_553)
  }

  @Test func aDayRoundTrips() throws {
    let date = try #require(DailyChallenge.date(fromDayString: "2026-11-24"))
    #expect(DailyChallenge.dayString(for: date) == "2026-11-24")
    let key = DailyChallenge.Key(date: date, level: .beginner, region: .latinAmerica)
    #expect(key.day == "2026-11-24")
    #expect(key.level == .beginner)
    #expect(key.region == .latinAmerica)
  }

  @Test(arguments: ["2026-02-30", "2026-1-5", "tomorrow", "", "2026-11-24-x"])
  func aDayThatIsNotADateNamesNoChallenge(day: String) {
    #expect(DailyChallenge.Key(dayString: day, level: .beginner, region: .spain) == nil)
  }

  /// Two devices on the same date: the same draw, whatever was drawn in between, and the cached
  /// questions are the drawn ones.
  @Test(arguments: QuizLevel.allCases)
  func theSameKeyDrawsTheSameChallenge(level: QuizLevel) {
    for region in Region.allCases {
      let key = key(0, level: level, region: region)
      let first = DailyChallenge.draw(for: key).map(signature)
      _ = DailyChallenge.draw(for: DailyChallenge.Key(day: "2026-11-25", level: level, region: region))
      #expect(DailyChallenge.draw(for: key).map(signature) == first)
      #expect(DailyChallenge.questions(for: key).map(signature) == first)
    }
  }

  @Test func daysLevelsAndRegionsHaveChallengesOfTheirOwn() {
    let days = Set((0..<7).map { DailyChallenge.questions(for: key($0, level: .beginner)).map(signature) })
    #expect(days.count == 7)
    #expect(DailyChallenge.questions(for: key(0, level: .beginner)).map(signature) != DailyChallenge.questions(for: key(0, level: .advanced)).map(signature))
    #expect(DailyChallenge.questions(for: key(0, level: .intermediate, region: .spain)).map(signature)
      != DailyChallenge.questions(for: key(0, level: .intermediate, region: .latinAmerica)).map(signature))
  }

  /// The default quiz's mix in five questions: the level's cells in the region's persons, drawn in
  /// tú, from the level's band, two irregular, two core verbs, a prefixed compound, and no verb
  /// twice.
  @Test(arguments: QuizLevel.allCases)
  func aChallengeIsFiveBalancedQuestionsAtItsLevel(level: QuizLevel) {
    let band = Set(QuizDraw.verbs(for: level).map(\.infinitive))
    for region in Region.allCases {
      for offset in 0..<10 {
        let questions = DailyChallenge.questions(for: key(offset, level: level, region: region))
        let described = "\(questions.map(signature))"
        #expect(questions.count == DailyChallenge.questionCount, "\(described)")
        #expect(Set(questions.map(\.verb)).count == questions.count, "\(described)")
        for question in questions {
          let entry = level.entry(for: question.tense)
          #expect(entry?.asks(question.personNumber) == true, "\(described)")
          #expect(Quiz.personNumbers(in: question.tense, secondSingular: .secondSingularTú, region: region).contains(question.personNumber), "\(described)")
          #expect(band.contains(question.verb), "\(described)")
          #expect(question.writtenAnswer != nil, "\(described)")
        }
        let irregular = questions.filter { QuizDraw.isIrregular($0.verb, in: ConjugationCell(tense: $0.tense, personNumber: $0.personNumber)) == true }
        #expect(irregular.count >= 2, "\(described)")
        #expect(questions.filter { QuizDraw.isCore($0.verb) }.count >= QuizDraw.minimumCoreQuestions, "\(described)")
        #expect(questions.contains { QuizDraw.isCompound($0.verb) }, "\(described)")
      }
    }
  }

  @Test func latinAmericasChallengesNeverAskVosotros() {
    for offset in 0..<20 {
      let questions = DailyChallenge.questions(for: key(offset, level: .advanced, region: .latinAmerica))
      #expect(!questions.contains { $0.personNumber == .secondPlural })
    }
  }

  /// A vos learner is asked the same verbs and tenses, a tú question in vos.
  @Test func aVosLearnerIsAskedTheSameQuestionsInVos() {
    var sawTú = false
    for offset in 0..<20 {
      let key = key(offset, level: .intermediate)
      let asTú = DailyChallenge.questions(for: key)
      let asVos = DailyChallenge.questions(for: key, secondSingular: .secondSingularVos)
      #expect(asTú.map(\.verb) == asVos.map(\.verb))
      #expect(asTú.map(\.tense) == asVos.map(\.tense))
      for (tú, vos) in zip(asTú, asVos) {
        if tú.personNumber == .secondSingularTú {
          sawTú = true
          #expect(vos.personNumber == .secondSingularVos)
        } else {
          #expect(vos.personNumber == tú.personNumber)
        }
      }
      #expect(DailyChallenge.questions(for: key, secondSingular: .secondSingularTú).map(signature) == asTú.map(signature))
    }
    #expect(sawTú)
  }

  @Test func aResultCountsItsQuestionsAsFirstAsked() {
    let key = key(0, level: .intermediate)
    let questions = DailyChallenge.questions(for: key)
    let result = DailyChallengeResult(key: key, questions: questions, results: [.totalMatch, .totalMatch, .secondAttemptMatch, .noMatch, .totalMatch])

    #expect(result.outcomes == [.right, .right, .secondTry, .wrong, .right])
    #expect(result.score == 35)
    #expect(result.dots == "🟢🟢🟡🔴🟢")
    #expect(result.pointsLine == "35 / 50")
    #expect(result.spokenSummary == L.DailyChallenge.spokenResult(right: 3, secondTry: 1, count: 5, score: 35, maximum: 50))
  }

  /// The text Josh approved on 2026-11-24, in English, the language the suite runs in.
  @Test func theSharedTextIsTheAgreedText() {
    let key = DailyChallenge.Key(day: "2026-11-24", level: .elementary, region: .spain)
    let result = DailyChallengeResult(key: key, outcomes: [.right, .right, .secondTry, .wrong, .right])
    let expected = """
      Conjugar · Daily Challenge
      November 24, 2026 · \(L.QuizLevel.elementary)
      🟢🟢🟡🔴🟢  35 / 50

      Take this challenge in Conjugar:
      conjugar://quiz/challenge?date=2026-11-24&level=elementary&region=spain&source=challengeLink

      Get Conjugar on the App Store:
      https://apps.apple.com/app/conjugar/id1236500467
      """
    #expect(result.shareText(locale: Locale(identifier: "en_US")) == expected)
  }

  @Test func theSharedDateFollowsTheAppsLanguage() {
    let result = DailyChallengeResult(key: DailyChallenge.Key(day: "2026-11-24", level: .beginner, region: .spain), outcomes: [.right])
    #expect(result.shareText(locale: Locale(identifier: "es_ES")).contains("24 de noviembre de 2026"))
  }

  /// The quiz widget's question is the first of the day's challenge at the level, in the region and
  /// the tú or vos, with three wrong answers of the same shape, none of them right.
  @Test(arguments: QuizLevel.allCases)
  func theWidgetsQuestionAgreesWithTheChallenge(level: QuizLevel) throws {
    for (region, secondSingular) in [(Region.spain, DisplayPersonNumber.secondSingularTú), (.latinAmerica, .secondSingularVos)] {
      let context = WidgetSnapshotWriter.ChallengeContext(level: level, region: region, secondSingular: secondSingular)
      for offset in 0..<10 {
        let key = key(offset, level: level, region: region)
        let first = try #require(DailyChallenge.questions(for: key, secondSingular: secondSingular).first)
        let question = try #require(WidgetSnapshotWriter.challengeQuizQuestion(on: key.date, challenge: context))
        let correct = try #require(first.writtenAnswer)

        #expect(question.infinitive == ReflexivePronoun.citationForm(of: first.verb))
        #expect(question.tenseDisplay == first.tense.titleCaseName)
        #expect(question.pronoun == (first.personNumber == .none ? nil : first.personNumber.pronoun))
        #expect(question.correctAnswer == correct)
        #expect(question.questionID == WidgetSnapshotWriter.questionIDPrefix(on: key.date, challenge: context) + first.verb)
        #expect(question.wrongAnswers.count == 3)
        #expect(Set(question.wrongAnswers.map { $0.lowercased() }).count == 3)
        #expect(!question.wrongAnswers.map { $0.lowercased() }.contains(correct.lowercased()))
        #expect(question.wrongAnswers.allSatisfy { wordCount($0) == wordCount(correct) }, "\(correct): \(question.wrongAnswers)")
        // A gerundio or participio is offered other endings, never the right answer padded out.
        if first.personNumber == .none {
          #expect(!question.wrongAnswers.contains { $0.lowercased().hasPrefix(correct.lowercased()) }, "\(correct): \(question.wrongAnswers)")
        }
      }
    }
  }

  @Test func aChangeOfLevelRegionOrPersonChangesTheQuestionsID() throws {
    let date = try #require(DailyChallenge.date(fromDayString: "2026-11-24"))
    let contexts = [
      WidgetSnapshotWriter.ChallengeContext(level: .beginner, region: .spain, secondSingular: .secondSingularTú),
      WidgetSnapshotWriter.ChallengeContext(level: .elementary, region: .spain, secondSingular: .secondSingularTú),
      WidgetSnapshotWriter.ChallengeContext(level: .beginner, region: .latinAmerica, secondSingular: .secondSingularTú),
      WidgetSnapshotWriter.ChallengeContext(level: .beginner, region: .spain, secondSingular: .secondSingularVos)
    ]
    #expect(Set(contexts.map { WidgetSnapshotWriter.questionIDPrefix(on: date, challenge: $0) }).count == contexts.count)
  }

  @Test func theWidgetsSnapshotAsksTheChallengesQuestion() throws {
    let date = try #require(DailyChallenge.date(fromDayString: "2026-11-24"))
    let context = WidgetSnapshotWriter.ChallengeContext(level: .elementary, region: .latinAmerica, secondSingular: .secondSingularTú)
    let snapshot = try #require(WidgetSnapshotWriter.makeSnapshot(for: date, challenge: context))
    let first = try #require(DailyChallenge.questions(for: DailyChallenge.Key(date: date, level: .elementary, region: .latinAmerica)).first)
    #expect(snapshot.quizQuestion.infinitive == ReflexivePronoun.citationForm(of: first.verb))
    #expect(snapshot.quizQuestion.questionID.hasPrefix("2026-11-24-elementary-latinAmerica-"))
  }

  // The challenge in a quiz.

  private static func settings(level: QuizLevel = .beginner, region: Region = .latinAmerica, secondSingular: SecondSingularQuiz = .tu) -> Settings {
    Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: region.rawValue,
      Settings.secondSingularQuizKey: secondSingular.rawValue
    ]))
  }

  private func makeQuiz(
    settings: Settings = DailyChallengeTests.settings(),
    practice: PracticeStore,
    gameCenter: GameCenter = GameCenterSpy(),
    seed: UInt64 = 8
  ) -> Quiz {
    Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true, randomSource: SplitMix64(seed: seed), practice: practice)
  }

  /// Answers right throughout but for the questions at `wrong`.
  private func finish(_ quiz: Quiz, wrong: Set<Int> = []) {
    while quiz.quizState == .inProgress {
      if quiz.isHeld {
        quiz.continueAfterCorrection()
        continue
      }
      let answer = wrong.contains(quiz.currentQuestionIndex) ? "zzzzzzzz" : quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
      quiz.process(proposedAnswer: answer)
    }
  }

  /// Two devices: different random sources, levels, regions, and practice records ask the same
  /// five, at the key's level and in its region.
  @Test func aChallengeAsksItsKeysQuestionsWhateverTheDevice() throws {
    let key = DailyChallenge.Key(day: "2026-11-24", level: .intermediate, region: .spain)
    let expected = DailyChallenge.draw(for: key).map(signature)

    let first = makeQuiz(settings: Self.settings(level: .beginner, region: .latinAmerica), practice: PracticeStore(getterSetter: GetterSetterFake()), seed: 1)
    #expect(first.start(scope: .challenge(key)))
    #expect(first.questions.map(signature) == expected)
    first.quit()

    let practice = PracticeStore(getterSetter: GetterSetterFake())
    for verb in ["tener", "hacer", "poder", "decir"] {
      practice.recordLookup(verb, source: .search, at: .now.addingTimeInterval(-40 * 86_400))
    }
    let second = makeQuiz(settings: Self.settings(level: .advanced, region: .spain), practice: practice, seed: 99)
    #expect(second.start(scope: .challenge(key)))
    #expect(second.questions.map(signature) == expected)
    #expect(second.lastLevel == .intermediate)
    #expect(second.lastRegion == .spain)
    #expect(second.questions.allSatisfy { $0.choice == nil })
    second.quit()
  }

  @Test func theScopeIsNeitherRankedNorContinuedNorShuffled() {
    let scope = QuizScope.challenge(key(0, level: .beginner))
    #expect(scope.isChallenge)
    #expect(!scope.isRanked)
    #expect(!scope.continues)
    #expect(!scope.shufflesQuestions)
    #expect(!scope.startsLiveActivity)
    #expect(!scope.mixesChoiceQuestions)
    #expect(scope.sendsQuestionCounts)
    #expect(scope.source == .challenge)
    #expect(scope.level == .beginner)
    #expect(LastQuizResult.Kind(scope: scope) == .challenge)
  }

  @Test func finishingKeepsTheResultOnceAndPostsNoScore() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let gameCenter = GameCenterSpy()
    let key = DailyChallenge.Key(day: "2026-11-24", level: .elementary, region: .latinAmerica)
    let quiz = makeQuiz(practice: practice, gameCenter: gameCenter)
    #expect(quiz.start(scope: .challenge(key)))
    finish(quiz, wrong: [1])

    #expect(quiz.quizState == .finished)
    #expect(quiz.questions.count == DailyChallenge.questionCount)
    #expect(quiz.reaskCount == 0)
    #expect(!quiz.canContinue)
    #expect(quiz.challengeResult?.outcomes == [.right, .wrong, .right, .right, .right])
    #expect(practice.challengeResult(for: key) == quiz.challengeResult)
    #expect(practice.lastResult?.kind == .challenge)
    #expect(practice.lastResult?.title == L.DailyChallenge.title)
    #expect(gameCenter.submissions.isEmpty)
    #expect(practice.levelBest(at: .elementary) == nil)

    let again = makeQuiz(practice: practice, gameCenter: gameCenter)
    #expect(again.start(scope: .challenge(key)))
    finish(again)
    #expect(again.challengeResult == quiz.challengeResult)
    #expect(practice.challengeResults.count == 1)
  }

  @Test func aWrongAnswerIsHeldButNotAskedAgain() {
    let quiz = makeQuiz(practice: PracticeStore(getterSetter: GetterSetterFake()))
    #expect(quiz.start(scope: .challenge(key(0, level: .beginner))))
    #expect(quiz.process(proposedAnswer: "zzzzzzzz") == .noMatch)

    #expect(quiz.correction?.willBeReasked == false)
    #expect(quiz.questions.count == DailyChallenge.questionCount)
    quiz.quit()
  }

  @Test func aQuitChallengeKeepsNothing() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let key = key(0, level: .beginner)
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .challenge(key)))
    quiz.process(proposedAnswer: quiz.currentQuestion?.writtenAnswer?.lowercased() ?? "")
    quiz.quit()

    #expect(practice.challengeResult(for: key) == nil)
    #expect(quiz.challengeResult == nil)
  }

  @Test func theStoreKeepsTheLatestResults() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    for offset in 0..<(DailyChallengeResult.keptCount + 3) {
      practice.recordChallenge(DailyChallengeResult(key: key(offset, level: .beginner), outcomes: [.right]))
    }
    #expect(practice.challengeResults.count == DailyChallengeResult.keptCount)
    #expect(practice.challengeResult(for: key(0, level: .beginner)) == nil)
    #expect(practice.challengeResult(for: key(DailyChallengeResult.keptCount + 2, level: .beginner)) != nil)
  }

  /// A launch reads the results back, and Reset Practice keeps them, since forgetting one would
  /// let its challenge be taken again.
  @Test func theResultsSurviveALaunchAndAReset() {
    let getterSetter = GetterSetterFake()
    let result = DailyChallengeResult(key: key(0, level: .advanced, region: .spain), outcomes: [.right, .secondTry])
    let store = PracticeStore(getterSetter: getterSetter)
    store.recordChallenge(result)
    #expect(PracticeStore(getterSetter: getterSetter).challengeResult(for: result.key) == result)

    store.reset()
    #expect(store.challengeResult(for: result.key) == result)
    #expect(PracticeStore(getterSetter: getterSetter).challengeResult(for: result.key) == result)
  }

  /// Sharing says which level's challenge was shared, and never how it went.
  @Test func sharingSendsTheLevelAlone() throws {
    let spy = try #require(Current.analytics as? AnalyticsSpy)
    DailyChallengeResult(key: key(0, level: .advanced), outcomes: [.right, .wrong]).signalShare()
    let parameters = try #require(Array(zip(spy.signalNames, spy.signalParameters)).last { $0.0 == .tapShareChallenge }?.1)
    #expect(parameters == [ParameterKey.level.rawValue: "advanced"])
  }

  // The link.

  @Test func aLinkNamesItsChallengeAndOpensIt() throws {
    let key = DailyChallenge.Key(day: "2026-11-24", level: .intermediate, region: .spain)
    let link = try #require(URL.challengeDeeplink(key, source: .challengeLink))
    #expect(link.absoluteString == "conjugar://quiz/challenge?date=2026-11-24&level=intermediate&region=spain&source=challengeLink")

    let router = AppRouter()
    router.handle(url: link)
    #expect(router.selectedTab == .quiz)
    #expect(router.pendingQuizStart == nil)
    #expect(router.pendingDailySession == nil)
    let request = try #require(router.pendingChallenge)
    #expect(request.source == .challengeLink)
    #expect(request.key(now: .now, level: .beginner, region: .latinAmerica) == key)
  }

  /// A part the link leaves out or names wrongly is the learner's own: today, their level, their
  /// region.
  @Test func aLinkWithoutAKeyAsksForTodaysAtTheLearnersLevel() throws {
    let now = try #require(DailyChallenge.date(fromDayString: "2026-11-30"))
    let widget = AppRouter()
    widget.handle(url: try #require(URL(string: "conjugar://quiz/challenge?source=challengeWidget")))
    let request = try #require(widget.pendingChallenge)
    #expect(request.source == .challengeWidget)
    #expect(request.key(now: now, level: .advanced, region: .spain) == DailyChallenge.Key(day: "2026-11-30", level: .advanced, region: .spain))

    let wrong = AppRouter()
    wrong.handle(url: try #require(URL(string: "conjugar://quiz/challenge?date=2026-13-01&level=expert&region=mars")))
    let fallback = try #require(wrong.pendingChallenge)
    #expect(fallback.source == .deeplink)
    #expect(fallback.key(now: now, level: .beginner, region: .latinAmerica) == DailyChallenge.Key(day: "2026-11-30", level: .beginner, region: .latinAmerica))
  }
}
