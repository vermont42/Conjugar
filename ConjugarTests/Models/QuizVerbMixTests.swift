//
//  QuizVerbMixTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Which verbs the default quiz asks: its level's frequency band, half its questions in an
//  irregular cell, the core verbs, and the prefixed compounds.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizVerbMixTests {
  private static let seeds: [UInt64] = Array(1...40)
  /// Three rounds' worth, so that the proportions show at a length a round cannot.
  private static let longQuiz = 30

  // Each level's quizzes are drawn once for the suite.
  private static let quizzes: [QuizLevel: [UInt64: [QuizQuestion]]] = Dictionary(uniqueKeysWithValues: QuizLevel.allCases.map { level in
    (level, Dictionary(uniqueKeysWithValues: seeds.map { ($0, draw(level, seed: $0, count: Self.longQuiz)) }))
  })

  private static func draw(_ level: QuizLevel, seed: UInt64, count: Int, region: Region = .spain) -> [QuizQuestion] {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: region.rawValue
    ]))
    let quiz = Quiz(settings: settings, gameCenter: GameCenterFake(), randomSource: SplitMix64(seed: seed))
    quiz.start(scope: QuizScope(verbs: nil, questionCount: count, source: .tab))
    let questions = quiz.questions
    quiz.quit()
    return questions
  }

  private func defaultQuiz(_ level: QuizLevel, seed: UInt64) -> [QuizQuestion] {
    Self.quizzes[level]?[seed] ?? []
  }

  private func isIrregular(_ question: QuizQuestion) -> Bool {
    QuizDraw.isIrregular(question.verb, in: ConjugationCell(tense: question.tense, personNumber: question.personNumber)) == true
  }

  private func entry(_ question: QuizQuestion) -> VerbMapEntry? {
    VerbMap.shared.entry(for: question.verb)
  }

  @Test(arguments: zip(QuizLevel.allCases, [100, 300, 1_000, VerbMap.shared.count]))
  func eachLevelDrawsFromItsBand(level: QuizLevel, bandSize: Int) {
    #expect(QuizDraw.verbs(for: level).count == bandSize)
    for seed in Self.seeds {
      let ranks = defaultQuiz(level, seed: seed).map { entry($0)?.frequencyRank ?? Int.max }
      #expect(ranks.allSatisfy { $0 <= bandSize }, "seed \(seed): \(ranks.max() ?? 0)")
    }
  }

  @Test(arguments: QuizLevel.allCases)
  func aDefaultQuizAsksEveryQuestion(level: QuizLevel) {
    for seed in Self.seeds {
      let questions = defaultQuiz(level, seed: seed)
      #expect(questions.count == Self.longQuiz, "seed \(seed)")
      #expect(questions.allSatisfy { $0.writtenAnswer != nil }, "seed \(seed)")
    }
  }

  @Test(arguments: QuizLevel.allCases)
  func halfTheQuestionsAskAnIrregularCell(level: QuizLevel) {
    for seed in Self.seeds {
      let irregular = defaultQuiz(level, seed: seed).filter(isIrregular)
      #expect(irregular.count == Self.longQuiz / 2, "seed \(seed)")
    }
  }

  /// tener is irregular in the presente and regular in the imperfecto, so the half is counted by
  /// cell, and a verb can be asked on either side of it.
  @Test func irregularityIsJudgedByCell() {
    let presente = ConjugationCell(tense: .presenteDeIndicativo, personNumber: .firstSingular)
    let imperfecto = ConjugationCell(tense: .imperfectoDeIndicativo, personNumber: .firstSingular)
    #expect(QuizDraw.isIrregular("tener", in: presente) == true)
    #expect(QuizDraw.isIrregular("tener", in: imperfecto) == false)
    #expect(QuizDraw.isIrregular("hablar", in: presente) == false)
    // A spelling change counts, as the verb page shows it in red.
    #expect(QuizDraw.isIrregular("llegar", in: ConjugationCell(tense: .pretérito, personNumber: .firstSingular)) == true)
    // A compound is judged by its participle, not by its haber.
    #expect(QuizDraw.isIrregular("hablar", in: ConjugationCell(tense: .perfectoDeIndicativo, personNumber: .firstSingular)) == false)
    #expect(QuizDraw.isIrregular("hacer", in: ConjugationCell(tense: .perfectoDeIndicativo, personNumber: .firstPlural)) == true)
    // abolir has no yo presente.
    #expect(QuizDraw.isIrregular("abolir", in: presente) == nil)
  }

  /// Only ser, ir, and ver are irregular there, so a quiz asks at most one irregular imperfecto.
  @Test(arguments: QuizLevel.allCases.filter { $0.entry(for: .imperfectoDeIndicativo) != nil })
  func theImperfectoAsksAtMostOneIrregularVerb(level: QuizLevel) {
    var irregularImperfectos = 0
    for seed in Self.seeds {
      let imperfectos = defaultQuiz(level, seed: seed).filter { $0.tense == .imperfectoDeIndicativo }
      let irregular = imperfectos.filter(isIrregular)
      #expect(irregular.count <= QuizDraw.maximumIrregularWhereFew, "seed \(seed): \(irregular.map(\.verb))")
      irregularImperfectos += irregular.count
    }
    #expect(irregularImperfectos > 0)
  }

  @Test(arguments: QuizLevel.allCases)
  func atLeastTwoQuestionsAskACoreVerb(level: QuizLevel) {
    for seed in Self.seeds {
      let core = defaultQuiz(level, seed: seed).filter { QuizDraw.isCore($0.verb) }
      #expect(core.count >= QuizDraw.minimumCoreQuestions, "seed \(seed)")
    }
  }

  @Test(arguments: QuizLevel.allCases)
  func everyQuizAsksACompound(level: QuizLevel) {
    for seed in Self.seeds {
      #expect(defaultQuiz(level, seed: seed).contains { VerbRelations.isCompound($0.verb) }, "seed \(seed)")
    }
  }

  @Test(arguments: [QuizLevel.intermediate, .advanced])
  func oneToThreeQuestionsAskARareCompound(level: QuizLevel) {
    var counts: Set<Int> = []
    for seed in Self.seeds {
      let rare = defaultQuiz(level, seed: seed).filter { entry($0).map(QuizDraw.isRareCompound) ?? false }
      #expect(QuizDraw.rareCompoundRange.contains(rare.count), "seed \(seed)")
      counts.insert(rare.count)
    }
    #expect(counts == Set(QuizDraw.rareCompoundRange))
  }

  @Test(arguments: [QuizLevel.beginner, .elementary])
  func aNarrowBandHasNoRareCompound(level: QuizLevel) {
    #expect(!QuizDraw.verbs(for: level).contains(where: QuizDraw.isRareCompound))
  }

  /// A frequent compound is not held to the rare ones' one to three.
  @Test func frequentCompoundsDrawFreely() {
    let compoundCounts = Self.seeds.map { seed in
      defaultQuiz(.elementary, seed: seed).filter { VerbRelations.isCompound($0.verb) }.count
    }
    #expect((compoundCounts.max() ?? 0) > QuizDraw.rareCompoundRange.upperBound)
  }

  /// The regular questions take the three endings in turn, so -er and -ir verbs are not drowned
  /// by the many -ar verbs of a band.
  @Test(arguments: QuizLevel.allCases)
  func regularQuestionsSpreadAcrossTheEndings(level: QuizLevel) {
    var counts: [RegularRoot: Int] = [:]
    for seed in Self.seeds {
      for question in defaultQuiz(level, seed: seed) where !isIrregular(question) {
        if let ending = RegularRoot(infinitive: question.verb) {
          counts[ending, default: 0] += 1
        }
      }
    }
    let total = counts.values.reduce(0, +)
    for ending in [RegularRoot.ar, .er, .ir] {
      #expect(Double(counts[ending] ?? 0) > Double(total) * 0.25, "\(level) \(ending): \(counts)")
    }
  }

  @Test(arguments: QuizLevel.allCases)
  func theMixKeepsTheLevelsCells(level: QuizLevel) {
    for seed in Self.seeds {
      for question in defaultQuiz(level, seed: seed) {
        #expect(level.entry(for: question.tense)?.asks(question.personNumber) == true, "\(question)")
      }
    }
  }

  /// A quiz of ten keeps the rules, which are per draw.
  @Test func aTenQuestionQuizMixesToo() {
    for level in QuizLevel.allCases {
      for seed in Self.seeds.prefix(20) {
        let questions = Self.draw(level, seed: seed, count: 10)
        #expect(questions.count == 10)
        // From the second level up, a choice between two sentences takes one of the ten, so the
        // draw's rules govern the other nine, of which half, rounded either way, are irregular.
        let typed = questions.filter { $0.choice == nil }
        #expect(typed.count == (level == .beginner ? 10 : 9))
        #expect((typed.count / 2...(typed.count + 1) / 2).contains(typed.filter(isIrregular).count), "\(level) seed \(seed)")
        #expect(typed.filter { QuizDraw.isCore($0.verb) }.count >= QuizDraw.minimumCoreQuestions, "\(level) seed \(seed)")
        #expect(typed.contains { VerbRelations.isCompound($0.verb) }, "\(level) seed \(seed)")
      }
    }
  }

  @Test func theMixHoldsInLatinAmerica() {
    for seed in Self.seeds.prefix(10) {
      let questions = Self.draw(.advanced, seed: seed, count: Self.longQuiz, region: .latinAmerica)
      #expect(questions.allSatisfy { $0.personNumber != .secondPlural })
      #expect(questions.filter(isIrregular).count == Self.longQuiz / 2, "seed \(seed)")
    }
  }

  @Test func noProvisionalCountReachesABand() {
    #expect(VerbMap.shared.entries(in: .top1000).allSatisfy { !$0.hitsAreProvisional })
  }

  /// A scope's verbs are its own: the band and the mix are the default quiz's.
  @Test func aScopedQuizAsksOnlyItsVerbs() {
    let verbs = ["hablar", "comer", "vivir"]
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [Settings.quizLevelKey: QuizLevel.advanced.rawValue]))
    let quiz = Quiz(settings: settings, gameCenter: GameCenterFake(), randomSource: SplitMix64(seed: 3))
    #expect(quiz.start(scope: .myVerbs(verbs)))
    #expect(quiz.questions.allSatisfy { verbs.contains($0.verb) })
    #expect(quiz.questions.allSatisfy { !isIrregular($0) })
    quiz.quit()
  }
}
