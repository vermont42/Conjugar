//
//  QuizLevelTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The four levels: the tenses each asks, the weights it draws them by, and the setting that
//  chooses one.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizLevelTests {
  /// Three rounds' worth, so that a rare tense's share shows.
  private static let longQuiz = 30

  private func makeQuiz(
    level: QuizLevel,
    region: Region = .spain,
    secondSingular: SecondSingularQuiz = .tu,
    seed: UInt64 = 1
  ) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: region.rawValue,
      Settings.secondSingularQuizKey: secondSingular.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: GameCenterFake(), randomSource: SplitMix64(seed: seed), practice: PracticeStore(getterSetter: GetterSetterFake()))
  }

  @Test func eachLevelAsksTheTensesOfTheLadder() {
    #expect(QuizLevel.beginner.pool.map(\.tense) == [.presenteDeIndicativo, .imperativoPositivo])
    #expect(QuizLevel.elementary.pool.map(\.tense) == [
      .presenteDeIndicativo, .imperativoPositivo, .pretérito, .imperfectoDeIndicativo, .perfectoDeIndicativo,
      .futuroDeIndicativo, .gerundio
    ])
    #expect(Set(QuizLevel.intermediate.pool.map(\.tense)) == Set(QuizLevel.elementary.pool.map(\.tense)).union([
      .presenteDeSubjuntivo, .imperativoNegativo, .condicional, .pluscuamperfectoDeIndicativo, .futuroPerfecto
    ]))
    #expect(Set(QuizLevel.advanced.pool.map(\.tense)) == Set(QuizLevel.intermediate.pool.map(\.tense)).union([
      .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
      .pluscuamperfectoDeSubjuntivo2, .condicionalCompuesto, .futuroDeSubjuntivo, .futuroPerfectoDeSubjuntivo,
      .pretéritoAnterior
    ]))
    // Every tense the quiz can conjugate, at the top level.
    #expect(QuizLevel.advanced.pool.count == 21)
    #expect(Set(QuizLevel.advanced.pool.map(\.tense)).count == 21)
  }

  /// Until Intermediate, commands are asked only of tú or vos, usted, and ustedes.
  @Test func nosotrosAndVosotrosCommandsWaitForIntermediate() {
    for level in [QuizLevel.beginner, .elementary] {
      let entry = level.entry(for: .imperativoPositivo)
      #expect(entry?.asks(.firstPlural) == false)
      #expect(entry?.asks(.secondPlural) == false)
      #expect(entry?.asks(.thirdSingular) == true)
    }
    #expect(QuizLevel.intermediate.entry(for: .imperativoPositivo)?.excludedPersons.isEmpty == true)
    #expect(QuizLevel.advanced.entry(for: .imperativoPositivo)?.excludedPersons.isEmpty == true)
  }

  @Test func theWeightsFollowUseAndThinTheCompounds() {
    let weights = Dictionary(uniqueKeysWithValues: QuizLevel.advanced.pool.map { ($0.tense, $0.weight) })
    #expect(weights[.presenteDeIndicativo] == 3)
    #expect(weights[.pretérito] == 3)
    #expect(weights[.imperfectoDeIndicativo] == 3)
    for tense in [DisplayTense.futuroDeIndicativo, .condicional, .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1,
      .imperfectoDeSubjuntivo2, .imperativoPositivo, .imperativoNegativo] {
      #expect(weights[tense] == 2, "\(tense)")
    }
    let compoundTenses: [DisplayTense] = [
      .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto, .condicionalCompuesto,
      .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1, .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo
    ]
    for tense in [DisplayTense.gerundio, .futuroDeSubjuntivo] + compoundTenses {
      #expect(weights[tense] == 1, "\(tense)")
    }
    #expect(QuizLevel.advanced.pool.reduce(0) { $0 + $1.weight } == 34)
  }

  /// Whatever the region and the second person, a level's quiz asks only its own cells.
  @Test func eachLevelDrawsOnlyItsOwnCells() {
    for level in QuizLevel.allCases {
      for region in Region.allCases {
        for secondSingular in SecondSingularQuiz.allCases {
          let quiz = makeQuiz(level: level, region: region, secondSingular: secondSingular)
          for _ in 0..<10 {
            #expect(quiz.start())
            #expect(quiz.questionCount == QuizScope.roundLength)
            for question in quiz.questions {
              let entry = level.entry(for: question.tense)
              #expect(entry != nil, "\(level) asked \(question.tense)")
              #expect(entry?.asks(question.personNumber) == true, "\(level) asked \(question.tense) of \(question.personNumber)")
              #expect(region == .spain || question.personNumber != .secondPlural)
              #expect(question.personNumber != (secondSingular == .tu ? .secondSingularVos : .secondSingularTú))
              #expect(question.writtenAnswer != nil, "\(question.verb) \(question.tense) \(question.personNumber)")
            }
            quiz.quit()
          }
        }
      }
    }
  }

  /// Under a fixed seed, each tense is drawn in proportion to its weight: a compound about one
  /// draw in 34 at Advanced, the presente three times as often. The draws are the quiz's own,
  /// made directly. Through `Quiz.start`, the same 6,000 per level took 4.1 seconds
  /// (2026-11-27); `aQuizAsksEachWeightAtItsShare` checks that a quiz draws this way.
  @Test func tensesAppearAtTheirWeight() {
    for level in [QuizLevel.elementary, .advanced] {
      var generator = SplitMix64(seed: 7)
      var counts: [DisplayTense: Int] = [:]
      let draws = 200 * Self.longQuiz
      for _ in 0..<draws {
        if let entry = level.pool.weightedRandomElement(using: &generator) {
          counts[entry.tense, default: 0] += 1
        }
      }
      let totalWeight = Double(level.pool.reduce(0) { $0 + $1.weight })
      for entry in level.pool {
        let expected = Double(draws) * Double(entry.weight) / totalWeight
        let actual = Double(counts[entry.tense] ?? 0)
        #expect(abs(actual - expected) < expected * 0.25, "\(level) \(entry.tense): \(actual), expected about \(expected)")
      }
    }
  }

  /// A quiz asks its tenses by weight: under a fixed seed, the tenses of each weight together
  /// take their share of its questions. Shares of whole weights rather than of single tenses,
  /// because each holds enough questions to judge in 30 quizzes, not 200.
  @Test func aQuizAsksEachWeightAtItsShare() {
    for level in [QuizLevel.elementary, .advanced] {
      let quiz = makeQuiz(level: level, seed: 7)
      let weights = Dictionary(uniqueKeysWithValues: level.pool.map { ($0.tense, $0.weight) })
      var counts: [Int: Int] = [:]
      let quizzes = 30
      for _ in 0..<quizzes {
        quiz.start(scope: QuizScope(kind: .allVerbs, verbs: nil, questionCount: Self.longQuiz, source: .tab))
        for question in quiz.questions {
          counts[weights[question.tense] ?? 0, default: 0] += 1
        }
        quiz.quit()
      }
      #expect(counts[0] == nil, "\(level) asked a tense outside its pool")
      let total = Double(quizzes * Self.longQuiz)
      let totalWeight = Double(weights.values.reduce(0, +))
      for weight in Set(weights.values) {
        let expected = total * Double(weights.values.filter { $0 == weight }.reduce(0, +)) / totalWeight
        let actual = Double(counts[weight] ?? 0)
        #expect(abs(actual - expected) < expected * 0.25, "\(level) weight \(weight): \(actual), expected about \(expected)")
      }
    }
  }

  @Test func aSeedDrawsTheSameQuiz() {
    let first = makeQuiz(level: .advanced, seed: 42)
    let second = makeQuiz(level: .advanced, seed: 42)
    first.start()
    second.start()
    #expect(first.questions == second.questions)
    let third = makeQuiz(level: .advanced, seed: 43)
    third.start()
    #expect(first.questions != third.questions)
  }

  @Test func theLiveActivityCarriesTheLevel() {
    let spy = Current.liveActivities as! LiveActivitiesSpy // swiftlint:disable:this force_cast
    let quiz = makeQuiz(level: .elementary)
    quiz.start()
    #expect(spy.lastLevel == "elementary")
    quiz.quit()
  }

  @Test func theLevelsWireNamesAreStable() {
    #expect(QuizLevel.allCases.map(\.rawValue) == ["beginner", "elementary", "intermediate", "advanced"])
    #expect(Settings.quizLevelKey == "quizLevel")
  }
}

@MainActor
@Suite struct QuizLevelSettingTests {
  @Test func aNewInstallStartsAtBeginner() {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    #expect(settings.quizLevel == .beginner)
    #expect(getterSetter.get(key: Settings.quizLevelKey) == "beginner")
  }

  @Test func aStoredDifficultyBecomesALevel() {
    let migrations: [(String, QuizLevel)] = [("Easy", .elementary), ("Moderate", .intermediate), ("Difficult", .advanced)]
    for (difficulty, level) in migrations {
      let getterSetter = GetterSetterFake(dictionary: [Settings.legacyDifficultyKey: difficulty])
      #expect(Settings(getterSetter: getterSetter).quizLevel == level)
      #expect(getterSetter.get(key: Settings.quizLevelKey) == level.rawValue)
    }
  }

  /// The old setting is read only while there is no level, so a level chosen later stands.
  @Test func aChosenLevelOutlivesTheOldSetting() {
    let getterSetter = GetterSetterFake(dictionary: [Settings.legacyDifficultyKey: "Difficult"])
    let settings = Settings(getterSetter: getterSetter)
    settings.quizLevel = .beginner
    #expect(Settings(getterSetter: getterSetter).quizLevel == .beginner)
  }

  @Test func anUnknownDifficultyStartsAtBeginner() {
    let getterSetter = GetterSetterFake(dictionary: [Settings.legacyDifficultyKey: "Ridiculous"])
    #expect(Settings(getterSetter: getterSetter).quizLevel == .beginner)
  }

  /// The Info tab keeps its own three difficulties, apart from the quiz's level.
  @Test func theInfoFilterIsItsOwnSetting() {
    let getterSetter = GetterSetterFake(dictionary: [Settings.legacyDifficultyKey: "Easy"])
    let settings = Settings(getterSetter: getterSetter)
    #expect(settings.infoDifficulty == .difficult)
    settings.infoDifficulty = .easy
    #expect(settings.quizLevel == .elementary)
    #expect(getterSetter.get(key: Settings.infoDifficultyKey) == "Easy")
  }
}
