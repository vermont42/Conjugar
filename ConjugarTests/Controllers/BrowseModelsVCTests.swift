//
//  BrowseModelsVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

@MainActor
class BrowseModelsVCTests: XCTestCase {
  func testBrowseModelsVC() {
    var analytic = ""
    Current.analytics = AnalyticsServiceSpy(fire: { fired in analytic = fired })
    Current.settings = Settings(getterSetter: GetterSetterFake())

    let bmvc = BrowseModelsVC()

    let nc = NavigationCSpy(rootViewController: bmvc)

    XCTAssertNotNil(bmvc)
    bmvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(BrowseModelsVC.self) ")

    let modelCount = ModelInfo.all.count

    let bmv = bmvc.browseModelsView
    XCTAssertEqual(bmv.sortControl.numberOfSegments, ModelSort.allCases.count)
    XCTAssertEqual(bmv.sortControl.selectedSegmentIndex, ModelSort.allCases.firstIndex(of: .irregularity))

    ModelSort.allCases.indices.forEach { index in
      bmv.sortControl.selectedSegmentIndex = index
      XCTAssertEqual(bmvc.tableView(UITableView(), numberOfRowsInSection: 0), modelCount)
    }

    let alphabeticalIndex = ModelSort.allCases.firstIndex(of: .alphabetical) ?? 0
    bmv.sortControl.selectedSegmentIndex = alphabeticalIndex
    bmvc.valueChanged(bmv.sortControl)
    XCTAssertEqual(Current.settings.modelSort, .alphabetical)

    let irregularityIndex = ModelSort.allCases.firstIndex(of: .irregularity) ?? 0
    bmv.sortControl.selectedSegmentIndex = irregularityIndex
    bmvc.valueChanged(bmv.sortControl)
    XCTAssertEqual(Current.settings.modelSort, .irregularity)

    let classNumberIndex = ModelSort.allCases.firstIndex(of: .classNumber) ?? 0
    bmv.sortControl.selectedSegmentIndex = classNumberIndex
    bmvc.valueChanged(bmv.sortControl)
    XCTAssertEqual(Current.settings.modelSort, .classNumber)

    let table = UITableView()
    table.register(ModelCell.self, forCellReuseIdentifier: ModelCell.identifier)
    guard let firstCell = bmvc.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)) as? ModelCell else {
      XCTFail("First cell was not a ModelCell.")
      return
    }
    XCTAssertEqual(firstCell.exemplar.text, "cantar")
    XCTAssertEqual(firstCell.classNumber.text, "1")
    XCTAssertEqual(firstCell.percent.text, "0%")

    bmvc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
    XCTAssert(nc.pushedViewController is ModelVC)
  }

  func testInitialSortComesFromSettings() {
    Current.analytics = AnalyticsServiceSpy()
    Current.settings = Settings(getterSetter: GetterSetterFake())
    Current.settings.modelSort = .classNumber

    let bmvc = BrowseModelsVC()
    let expectedIndex = ModelSort.allCases.firstIndex(of: .classNumber)
    XCTAssertEqual(bmvc.browseModelsView.sortControl.selectedSegmentIndex, expectedIndex)
  }
}
