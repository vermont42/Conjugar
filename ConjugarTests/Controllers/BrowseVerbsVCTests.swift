//
//  BrowseVerbsVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 8/27/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class BrowseVerbsVCTests: XCTestCase {
  func testBrowseVerbsVC() {
    var analytic = ""
    Current.analytics = AnalyticsServiceSpy(fire: { fired in analytic = fired })
    Current.settings = Settings(getterSetter: GetterSetterFake())

    let bvvc = BrowseVerbsVC()

    let nc = NavigationCSpy(rootViewController: bvvc)

    XCTAssertNotNil(bvvc)
    bvvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(BrowseVerbsVC.self) ")

    let verbCount = VerbMap.shared.entries.count

    let bvv = bvvc.browseVerbsView
    XCTAssertEqual(bvv.sortControl.numberOfSegments, VerbSort.allCases.count)
    XCTAssertEqual(bvv.sortControl.selectedSegmentIndex, VerbSort.allCases.firstIndex(of: .frequency))

    VerbSort.allCases.indices.forEach { index in
      bvv.sortControl.selectedSegmentIndex = index
      XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), verbCount)
    }

    let alphabeticalIndex = VerbSort.allCases.firstIndex(of: .alphabetical) ?? 0
    bvv.sortControl.selectedSegmentIndex = alphabeticalIndex
    bvvc.valueChanged(bvv.sortControl)
    XCTAssertEqual(Current.settings.verbSort, .alphabetical)

    let frequencyIndex = VerbSort.allCases.firstIndex(of: .frequency) ?? 0
    bvv.sortControl.selectedSegmentIndex = frequencyIndex
    bvvc.valueChanged(bvv.sortControl)
    XCTAssertEqual(Current.settings.verbSort, .frequency)

    let table = UITableView()
    table.register(VerbCell.self, forCellReuseIdentifier: VerbCell.identifier)
    guard let firstCell = bvvc.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)) as? VerbCell else {
      XCTFail("First cell was not a VerbCell.")
      return
    }
    XCTAssertEqual(firstCell.verb.text, "ser")
    XCTAssertEqual(firstCell.rank.text, "#1")

    bvvc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
    XCTAssert(nc.pushedViewController is VerbVC)
  }

  func testInitialSortComesFromSettings() {
    Current.analytics = AnalyticsServiceSpy()
    Current.settings = Settings(getterSetter: GetterSetterFake())
    Current.settings.verbSort = .alphabetical

    let bvvc = BrowseVerbsVC()
    let expectedIndex = VerbSort.allCases.firstIndex(of: .alphabetical)
    XCTAssertEqual(bvvc.browseVerbsView.sortControl.selectedSegmentIndex, expectedIndex)
  }
}
