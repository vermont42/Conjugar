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
    return Quiz(settings: settings, gameCenter: GameCenterFake(), randomSource: SplitMix64(seed: seed))
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
            #expect(quiz.questionCount == QuizScope.fullLength)
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

  /// Under a fixed seed, each tense is asked in proportion to its weight: a compound about one
  /// question in 34 at Advanced, the presente three times as often.
  @Test func tensesAppearAtTheirWeight() {
    for level in [QuizLevel.elementary, .advanced] {
      let quiz = makeQuiz(level: level, seed: 7)
      var counts: [DisplayTense: Int] = [:]
      let quizzes = 200
      for _ in 0..<quizzes {
        quiz.start()
        for question in quiz.questions {
          counts[question.tense, default: 0] += 1
        }
        quiz.quit()
      }
      let total = Double(quizzes * QuizScope.fullLength)
      let totalWeight = Double(level.pool.reduce(0) { $0 + $1.weight })
      for entry in level.pool {
        let expected = total * Double(entry.weight) / totalWeight
        let actual = Double(counts[entry.tense] ?? 0)
        #expect(abs(actual - expected) < expected * 0.25, "\(level) \(entry.tense): \(actual), expected about \(expected)")
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

  /// Regular and irregular verbs take turns, so half a quiz asks a verb from an irregular list.
  @Test func regularAndIrregularVerbsTakeTurns() {
    let regular = Set(VerbFamilies.allRegularVerbs)
    for level in QuizLevel.allCases {
      let settings = Settings(getterSetter: GetterSetterFake(dictionary: [Settings.quizLevelKey: level.rawValue]))
      let quiz = Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: false)
      quiz.start()
      for (index, question) in quiz.questions.enumerated() where index.isMultiple(of: 2) {
        #expect(regular.contains(question.verb), "\(level): \(question.verb) at \(index)")
      }
      let irregularCount = quiz.questions.filter { !regular.contains($0.verb) }.count
      #expect(irregularCount >= QuizScope.fullLength / 2 - 3, "\(level): \(irregularCount) irregular")
      quiz.quit()
    }
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
