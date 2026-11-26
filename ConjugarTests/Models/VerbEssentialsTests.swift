//
//  VerbEssentialsTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Verb Essentials: a verb's key conjugations asked as one step, each blank graded and recorded
//  alone, the verbs a round draws, the rows on screen, re-asks, and Five More Verbs.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct VerbEssentialsTests {
  private func makeQuiz(level: QuizLevel = .beginner, practice: PracticeStore = PracticeStore(getterSetter: GetterSetterFake()), seed: UInt64 = 3) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: Region.spain.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: true, randomSource: SplitMix64(seed: seed), practice: practice)
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  private func answerRight(_ quiz: Quiz) {
    quiz.process(proposedAnswer: rightAnswer(quiz))
  }

  /// A wrong answer that nothing diagnoses and no slip comes near, held and continued.
  private func answerWrong(_ quiz: Quiz) {
    quiz.process(proposedAnswer: "zzzz")
    quiz.continueAfterCorrection()
  }

  private static var generator = SplitMix64(seed: 11)

  // The step

  @Test func aVerbsStepAsksItsKeyConjugationsInThePagesOrder() {
    #expect(VerbEssentials.questions(for: "tener") == [
      QuizQuestion("tener", .presenteDeIndicativo, .firstSingular),
      QuizQuestion("tener", .pretérito, .firstSingular),
      QuizQuestion("tener", .futuroDeIndicativo, .firstSingular),
      QuizQuestion("tener", .participio, .none)
    ])
  }

  @Test func aKeyConjugationTheEngineDoesNotGiveIsNotAsked() {
    #expect(VerbEssentials.questions(for: "abolir").map(\.tense) == [.pretérito, .futuroDeIndicativo, .participio])
  }

  @Test func eachVerbIsAStepOfItsOwnNumberedAfterThoseBefore() {
    let first = VerbEssentials.steps(for: ["tener", "abolir"])
    #expect(first.map(\.step) == [0, 0, 0, 0, 1, 1, 1])
    let more = VerbEssentials.steps(for: ["ir"], after: first)
    #expect(more.map(\.step) == [2, 2, 2, 2])
  }

  // Each blank's answers, for each kind of irregular verb

  /// A -go presente and an irregular futuro (salir), a strong pretérito (poder), an irregular
  /// participio (escribir), and a prefixed compound (detener), each blank typed as a learner would.
  @Test(arguments: [
    ("salir", ["salgo", "salí", "saldré", "salido"]),
    ("poder", ["puedo", "pude", "podré", "podido"]),
    ("tener", ["tengo", "tuve", "tendré", "tenido"]),
    ("escribir", ["escribo", "escribí", "escribiré", "escrito"]),
    ("hacer", ["hago", "hice", "haré", "hecho"]),
    ("detener", ["detengo", "detuve", "detendré", "detenido"]),
    ("componer", ["compongo", "compuse", "compondré", "compuesto"])
  ])
  func eachBlankTakesItsKeyConjugation(verb: String, answers: [String]) {
    let questions = VerbEssentials.questions(for: verb)
    #expect(questions.count == answers.count)
    for (question, answer) in zip(questions, answers) {
      #expect(question.grade(question.answer(filling: answer)) == .totalMatch, "\(verb): \(answer)")
    }
  }

  @Test func aReflexiveOnlyVerbsBlankTakesTheFormWithOrWithoutItsPronoun() throws {
    let question = try #require(VerbEssentials.questions(for: "arrepentir").first)
    #expect(question.frame == AnswerFrame(segments: [.pronoun("yo"), .word("me"), .blank]))
    #expect(question.grade(question.answer(filling: "arrepiento")) == .totalMatch)
    #expect(question.grade(question.answer(filling: "me arrepiento")) == .totalMatch)
  }

  @Test func theRegularFormOfAnIrregularKeyConjugationIsDiagnosed() throws {
    let preterite = try #require(VerbEssentials.questions(for: "poder").dropFirst().first)
    #expect(preterite.diagnosis(of: "podí") != nil)
    let participle = try #require(VerbEssentials.questions(for: "escribir").last)
    #expect(participle.diagnosis(of: "escribido") != nil)
  }

  // The draw

  @Test func aRoundDrawsDistinctVerbsWithAnIrregularKeyConjugationFromTheBand() {
    let pool = VerbEssentials.pool(band: .top100)
    let verbs = VerbEssentials.verbs(from: pool, count: 5, limitsCompounds: true, using: &Self.generator)

    #expect(verbs.count == 5)
    #expect(Set(verbs).count == 5)
    for verb in verbs {
      #expect(VerbMap.shared.entry(for: verb)?.isIn(.top100) == true)
      #expect(VerbEssentials.hasIrregularKeyConjugation(verb))
    }
  }

  @Test func thePoolHoldsIrregularVerbsOnly() {
    let pool = VerbEssentials.pool(band: .top100)
    #expect(pool.contains("tener"))
    #expect(!pool.contains("hablar"))
    #expect(!pool.contains("comer"))
  }

  @Test func aVerbWithoutAnIrregularKeyConjugationIsNeverDrawn() {
    #expect(!VerbEssentials.hasIrregularKeyConjugation("bullir"))
    #expect(!VerbEssentials.hasIrregularKeyConjugation("hablar"))
    #expect(VerbEssentials.hasIrregularKeyConjugation("pensar"))
    #expect(VerbEssentials.verbs(from: ["bullir", "hablar", "pensar"], count: 5, limitsCompounds: false, using: &Self.generator) == ["pensar"])
  }

  @Test func aBandsRoundHoldsAtMostOneCompoundWhileBaseVerbsRemain() {
    let pool = ["detener", "contener", "mantener", "obtener", "componer", "tener", "poner", "hacer", "decir", "venir"]
    for seed in 0..<20 {
      var generator = SplitMix64(seed: UInt64(seed))
      let verbs = VerbEssentials.verbs(from: pool, count: 5, limitsCompounds: true, using: &generator)
      #expect(verbs.count == 5)
      #expect(verbs.filter(VerbRelations.isCompound).count <= VerbEssentials.compoundLimit)
    }
  }

  @Test func aPoolOfCompoundsStillFillsItsRound() {
    let pool = ["detener", "contener", "mantener", "obtener", "retener", "tener"]
    let verbs = VerbEssentials.verbs(from: pool, count: 5, limitsCompounds: true, using: &Self.generator)
    #expect(verbs.count == 5)
    #expect(Set(verbs).count == 5)
  }

  @Test func verbsAlreadyAskedComeLast() {
    let pool = ["tener", "poner", "hacer", "decir", "venir", "salir", "poder"]
    let verbs = VerbEssentials.verbs(from: pool, count: 5, asked: ["tener", "poner", "hacer"], limitsCompounds: false, using: &Self.generator)
    #expect(Set(verbs.prefix(4)) == ["decir", "venir", "salir", "poder"])
    #expect(["tener", "poner", "hacer"].contains(verbs[4]))
  }

  // The scope

  @Test func theScopeIsUnrankedUnshuffledAndContinues() {
    let scope = QuizScope.verbEssentials()
    #expect(scope.isVerbEssentials)
    #expect(scope.source == .verbEssentials)
    #expect(scope.verbs == nil)
    #expect(scope.questionCount == 20)
    #expect(!scope.isRanked)
    #expect(!scope.mixesDueItems)
    #expect(!scope.shufflesQuestions)
    #expect(scope.continues)
    #expect(scope.sendsQuestionCounts)
    #expect(scope.startsLiveActivity)
  }

  // A round

  @Test func aRoundAsksFiveVerbsOfTheLevelsBandEachAsOneStep() {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .verbEssentials()))

    let verbs = quiz.questions.map(\.verb).reduce(into: [String]()) { if $0.last != $1 { $0.append($1) } }
    #expect(verbs.count == 5)
    #expect(Set(verbs).count == 5)
    #expect(quiz.questions.count == verbs.map { VerbEssentials.questions(for: $0).count }.reduce(0, +))
    for verb in verbs {
      #expect(VerbMap.shared.entry(for: verb)?.isIn(.top100) == true)
    }
    #expect(Set(quiz.questions.compactMap(\.step)).count == 5)
    #expect(quiz.questions.allSatisfy { $0.step != nil })
  }

  @Test func eachBlankIsRecordedAlone() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .verbEssentials(["tener"])))

    answerRight(quiz)
    answerWrong(quiz)
    answerRight(quiz)
    answerRight(quiz)
    quiz.quit()

    #expect(practice.record.entry(for: .keyConjugation(infinitive: "tener", key: .yoPresente))?.lastAnswerWasRight == true)
    #expect(practice.record.entry(for: .keyConjugation(infinitive: "tener", key: .yoPretérito))?.lastAnswerWasRight == false)
    #expect(practice.record.entry(for: .keyConjugation(infinitive: "tener", key: .yoFuturo))?.lastAnswerWasRight == true)
    // tenido is regular, so its answer moves the -er participio's pattern.
    let participle = PracticeItem.exercised(by: QuizQuestion("tener", .participio, .none))
    #expect(participle != nil)
    #expect(participle.flatMap { practice.record.entry(for: $0) }?.lastAnswerWasRight == true)
    #expect(practice.record.entries.count == 4)
  }

  @Test func theRowsShowWhatIsAnsweredWhatIsAskedAndWhatIsToCome() throws {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .verbEssentials(["tener"])))
    #expect(quiz.essentialsRows?.map(\.content) == [.current, .pending, .pending, .pending])
    #expect(!quiz.isMidStep)

    answerRight(quiz)
    #expect(quiz.isMidStep)
    #expect(quiz.essentialsRows?.map(\.content) == [.answered(form: "tenGo", result: .totalMatch), .current, .pending, .pending])
    #expect(quiz.essentialsRows?.map(\.key) == KeyConjugation.allCases)
  }

  @Test func anotherQuizHasNoRows() {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .myVerbs(["tener"])))
    #expect(quiz.essentialsRows == nil)
    #expect(!quiz.isMidStep)
  }

  @Test func aMissedBlankReturnsAfterTheNextVerbWithItsOtherRowsGiven() throws {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .verbEssentials(["tener", "poner", "hacer"])))
    let firstVerb = quiz.verb
    let firstStepLength = quiz.currentStepRange.count

    answerRight(quiz)
    answerWrong(quiz)
    #expect(quiz.questions.count == 13)

    // The re-ask sits after the second verb's step, as a step of its own.
    let secondStepEnd = firstStepLength + 4 + 1
    let reask = quiz.questions[secondStepEnd - 1]
    #expect(reask.isReask)
    #expect(reask.verb == firstVerb)
    #expect(reask.tense == .pretérito)
    #expect(reask.step != quiz.questions[0].step)
    #expect(reask.step != quiz.questions[secondStepEnd - 2].step)

    while quiz.currentQuestionIndex < secondStepEnd - 1 {
      answerRight(quiz)
    }
    let rows = try #require(quiz.essentialsRows)
    #expect(rows.map(\.content) == [
      .given(form: try #require(KeyConjugation.forms(of: firstVerb).first?.form)),
      .current,
      .given(form: try #require(KeyConjugation.forms(of: firstVerb).dropFirst(2).first?.form)),
      .given(form: try #require(KeyConjugation.forms(of: firstVerb).last?.form))
    ])
  }

  @Test func aSecondMissInTheSameVerbJoinsTheFirstsReask() {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .verbEssentials(["tener", "poner"])))

    answerWrong(quiz)
    answerRight(quiz)
    answerWrong(quiz)
    #expect(quiz.questions.count == 10)

    let reasks = quiz.questions.filter(\.isReask)
    #expect(reasks.map(\.tense) == [.presenteDeIndicativo, .futuroDeIndicativo])
    #expect(Set(reasks.map(\.step)).count == 1)
    #expect(Array(quiz.questions.suffix(2)) == reasks)
  }

  @Test func aReaskOfTheLastVerbComesAtTheEnd() {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .verbEssentials(["tener"])))
    answerRight(quiz)
    answerRight(quiz)
    answerRight(quiz)
    answerWrong(quiz)
    #expect(quiz.questions.count == 5)
    #expect(quiz.questions.last?.isReask == true)
    #expect(quiz.questions.last?.step != quiz.questions.first?.step)
  }

  @Test func aDiagnosedBlankEarnsHalfPointsOnItsSecondAttempt() {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .verbEssentials(["poder"])))
    answerRight(quiz)

    #expect(quiz.process(proposedAnswer: "podí") == nil)
    #expect(quiz.process(proposedAnswer: "pude") == .secondAttemptMatch)
    #expect(quiz.essentialsRows?[1].content == .answered(form: "pUDE", result: .secondAttemptMatch))
  }

  @Test func fiveMoreVerbsAreNewAndContinueTheSteps() {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .verbEssentials()))
    while quiz.quizState == .inProgress {
      answerRight(quiz)
    }
    let firstVerbs = Set(quiz.questions.map(\.verb))
    let firstCount = quiz.questions.count
    #expect(quiz.canContinue)

    #expect(quiz.continueSession())
    let more = quiz.questions.dropFirst(firstCount)
    #expect(Set(more.map(\.verb)).count == 5)
    #expect(Set(more.map(\.verb)).isDisjoint(with: firstVerbs))
    #expect(more.compactMap(\.step).min() == 5)
    #expect(quiz.currentQuestionIndex == firstCount)
  }

  @Test func aFinishedRoundIsKeptAsTheLastResultAtItsLevelAndPostsNoScore() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let gameCenter = GameCenterFake()
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [Settings.quizLevelKey: QuizLevel.elementary.rawValue]))
    let quiz = Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true, randomSource: SplitMix64(seed: 3), practice: practice)
    #expect(quiz.start(scope: .verbEssentials()))
    while quiz.quizState == .inProgress {
      answerRight(quiz)
    }

    #expect(!quiz.isRankedRound)
    #expect(practice.lastResult?.kind == .verbEssentials)
    #expect(practice.lastResult?.level == .elementary)
    #expect(practice.lastResult?.title == L.VerbEssentials.title)
    #expect(practice.lastResult?.questionCount == quiz.questionCount)
  }
}
