//
//  ModelSearchTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

/// The Models tab's search: what a query finds, what a space alone does, and when the sad trombone
/// plays.
@MainActor
struct ModelSearchTests {
  private func info(_ classNumber: String, _ exemplar: String) -> ModelInfo {
    ModelInfo(classNumber: classNumber, exemplar: exemplar, verbs: [], irregularityPercent: 0)
  }

  private var models: [ModelInfo] {
    [info("1", "cantar"), info("4B", "mostrar"), info("29", "hacer"), info("47", "tañer"), info("4B-1", "jugar")]
  }

  private func exemplars(matching query: String) -> [String] {
    ModelSearch.models(in: models, matching: query).map(\.exemplar)
  }

  @Test func anEmptyQueryFindsEveryModelInOrder() {
    #expect(exemplars(matching: "") == models.map(\.exemplar))
  }

  @Test func aQueryOfSpacesFindsEveryModel() {
    #expect(exemplars(matching: "   ") == models.map(\.exemplar))
  }

  @Test func aQueryFindsByExemplarOrClassNumber() {
    #expect(exemplars(matching: "hacer") == ["hacer"])
    #expect(exemplars(matching: "4b") == ["mostrar", "jugar"])
    #expect(exemplars(matching: " 29 ") == ["hacer"])
  }

  @Test func aQueryIgnoresCaseAndEveryDiacritic() {
    #expect(exemplars(matching: "HACER") == ["hacer"])
    #expect(exemplars(matching: "tañer") == ["tañer"])
    #expect(exemplars(matching: "taner") == ["tañer"])
  }

  @Test func aQueryThatMatchesNothingFindsNothing() {
    #expect(exemplars(matching: "xyzzyq").isEmpty)
  }

  /// A space alone is not a search, so the collections stay and the list is whole.
  @Test func aSpaceAloneIsNotASearch() {
    var search = ModelSearch(sort: .irregularity)
    let playsTrombone = search.update(text: " ", sort: .irregularity)
    #expect(!search.isSearching)
    #expect(!playsTrombone)
    #expect(search.models.count == ModelInfo.all.count)
  }

  @Test func theTrombonePlaysWhenTheTextChangesToAFailedQuery() {
    var search = ModelSearch(sort: .irregularity)
    let onAMatch = search.update(text: "hac", sort: .irregularity)
    let onAFailure = search.update(text: "xyzzyq", sort: .irregularity)
    let onAnotherFailure = search.update(text: "xyzzyqq", sort: .irregularity)
    #expect(!onAMatch)
    #expect(onAFailure)
    #expect(onAnotherFailure)
    #expect(search.models.isEmpty)
  }

  /// A new order shows the same failed query again, and that is no new failure.
  @Test func theTromboneDoesNotPlayAgainOnASortChange() {
    var search = ModelSearch(sort: .irregularity)
    let onTheFailure = search.update(text: "xyzzyq", sort: .irregularity)
    let onASort = search.update(text: "xyzzyq", sort: .alphabetical)
    let onAnotherSort = search.update(text: "xyzzyq", sort: .classNumber)
    #expect(onTheFailure)
    #expect(!onASort)
    #expect(!onAnotherSort)
    #expect(search.sort == .classNumber)
  }

  @Test func aSortChangeReordersTheResults() {
    var search = ModelSearch(sort: .alphabetical)
    _ = search.update(text: "4b", sort: .alphabetical)
    let alphabetical = search.models.map(\.classNumber)
    _ = search.update(text: "4b", sort: .classNumber)
    #expect(Set(search.models.map(\.classNumber)) == Set(alphabetical))
    #expect(search.models.map(\.classNumber) == ModelSort.classNumber.sorted(search.models).map(\.classNumber))
  }
}
