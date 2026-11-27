//
//  ModelInfoTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct ModelInfoTests {
  private func info(_ classNumber: String) -> ModelInfo? {
    ModelInfo.all.first { $0.classNumber == classNumber }
  }

  /// The model page's grid shows the second singular as the learner chose, tú, vos, or both.
  @Test(arguments: zip(
    [SecondSingularBrowse.tu, .vos, .both],
    [
      [DisplayPersonNumber.firstSingular, .secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural],
      [.firstSingular, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural],
      [.firstSingular, .secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    ]
  ))
  func theGridsPersonsFollowTheSecondSingularChoice(secondSingular: SecondSingularBrowse, persons: [DisplayPersonNumber]) {
    #expect(ModelView.gridPersons(for: secondSingular) == persons)
  }

  /// The grid's columns are the verb page's rows, in the same order, for each choice.
  @Test(arguments: [SecondSingularBrowse.tu, .vos, .both])
  func theGridsPersonsAreTheVerbPagesRows(secondSingular: SecondSingularBrowse) throws {
    let page = VerbPageForms(verb: "hablar", marks: [], secondSingular: secondSingular)
    let presente = try #require(page.sections.first { $0.tense == .presenteDeIndicativo })
    #expect(presente.rows.map(\.pronoun) == ModelView.gridPersons(for: secondSingular).map(\.pronoun))
  }

  @Test func catalogYields102RowsWithNoAliasRows() {
    // 106 class numbers − the 4 prefix-accent aliases folded into their parents.
    #expect(ModelInfo.all.count == 102)
    for alias in ModelInfo.parentByAlias.keys {
      #expect(info(alias) == nil)
    }
  }

  @Test func aliasClassesFoldIntoParentRows() {
    // 29-2 satisfacer rides hacer's model, so satisfacer lists under row 29.
    let hacer = info("29")
    #expect(hacer?.exemplar == "hacer")
    #expect(hacer?.verbs.contains { $0.infinitive == "satisfacer" } == true)
    #expect(info("30")?.verbs.contains { $0.infinitive == "suponer" } == true)
    #expect(info("31")?.verbs.contains { $0.infinitive == "obtener" } == true)
    #expect(info("32")?.verbs.contains { $0.infinitive == "convenir" } == true)
  }

  @Test func verbListsCoverEveryVerbSense() {
    // Every (verb, sense) pair lands in exactly one row's list, so the row
    // counts sum to the total sense count (homonyms carry two class numbers).
    let senseCount = VerbMap.shared.entries.values.reduce(0) { $0 + $1.classNumbers.count }
    let rowCount = ModelInfo.all.reduce(0) { $0 + $1.verbs.count }
    #expect(rowCount == senseCount)
  }

  @Test func verbListsAreByFrequency() {
    let verbs = info("1")?.verbs ?? []
    #expect(verbs.map(\.frequencyRank) == verbs.map(\.frequencyRank).sorted())
    #expect(verbs.contains { $0.infinitive == "cantar" })
  }

  /// A row's verbs are every verb with a sense in its class, or in an alias class that rides it,
  /// each once: the one definition that a model's page, its collection, its practice, and the
  /// Related Verbs card read.
  @Test func aRowsVerbsAreEveryVerbWithASenseInIt() {
    for model in ModelInfo.all {
      let expected = VerbMap.shared.entriesByFrequency.filter { entry in
        entry.classNumbers.contains { (ModelInfo.parentByAlias[$0] ?? $0) == model.classNumber }
      }
      #expect(model.verbs.map(\.infinitive) == expected.map(\.infinitive), "\(model.classNumber)")
    }
  }

  @Test func regularClassesScoreZeroIrregularity() {
    #expect(info("1")?.irregularityPercent == 0)
    #expect(info("2")?.irregularityPercent == 0)
    #expect(info("3")?.irregularityPercent == 0)
  }

  @Test func irregularClassesScorePositiveIrregularity() {
    let pensar = info("4A")?.irregularityPercent ?? 0
    #expect(pensar > 0)
    #expect(pensar < 50)

    let ser = info("19")?.irregularityPercent ?? 0
    #expect(ser >= 50)

    let ir = info("24")?.irregularityPercent ?? 0
    #expect(ir >= 50)
  }
}
