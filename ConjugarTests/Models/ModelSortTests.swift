//
//  ModelSortTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

struct ModelSortTests {
  private func info(_ classNumber: String, exemplar: String = "cantar", percent: Int = 0) -> ModelInfo {
    ModelInfo(classNumber: classNumber, exemplar: exemplar, verbs: [], irregularityPercent: percent)
  }

  @Test func classNumberSortUsesBookOrderNotStringOrder() {
    let bookOrder = ["1", "1-2", "1-10", "2", "4A", "4A-2", "4B", "4B-1", "6B-4", "6C", "9-2", "10", "29"]
    for (index, classNumber) in bookOrder.enumerated().dropLast() {
      let next = bookOrder[index + 1]
      #expect(ModelSort.classNumberPrecedes(classNumber, next))
      #expect(!ModelSort.classNumberPrecedes(next, classNumber))
    }

    let shuffled = ["10", "4B-1", "1-10", "6C", "1", "9-2", "4A", "29", "2", "6B-4", "4A-2", "1-2", "4B"]
    let sorted = ModelSort.classNumber.sorted(shuffled.map { info($0) }).map(\.classNumber)
    #expect(sorted == bookOrder)
  }

  @Test func irregularitySortDescendsByPercentBreakingTiesAlphabetically() {
    let infos = [
      info("1", exemplar: "cantar", percent: 0),
      info("19", exemplar: "ser", percent: 71),
      info("4B", exemplar: "mostrar", percent: 14),
      info("4A", exemplar: "pensar", percent: 14)
    ]
    let sorted = ModelSort.irregularity.sorted(infos).map(\.exemplar)
    #expect(sorted == ["ser", "mostrar", "pensar", "cantar"])
  }

  @Test func alphabeticalSortUsesSpanishCollation() {
    // ñ collates between n and o in Spanish; code-point order would misplace it.
    let infos = [info("1", exemplar: "obrar"), info("2", exemplar: "ñoñear"), info("3", exemplar: "nadar")]
    let sorted = ModelSort.alphabetical.sorted(infos).map(\.exemplar)
    #expect(sorted == ["nadar", "ñoñear", "obrar"])
  }

  @Test func classNumberSortOfCatalogRunsFrom1To35() {
    let sorted = ModelSort.classNumber.sorted(ModelInfo.all)
    #expect(sorted.first?.classNumber == "1")
    #expect(sorted.last?.classNumber == "35")
  }
}
