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

    let regularClasses: Set<String> = ["1", "2", "3"]
    let entries = VerbMap2.shared.entries.values
    let regularVerbCount = entries.filter { regularClasses.contains($0.classNumber) }.count
    let irregularVerbCount = entries.count - regularVerbCount
    let combinedVerbCount = entries.count

    let bvv = bvvc.browseVerbsView
    [(0, irregularVerbCount), (1, regularVerbCount), (2, combinedVerbCount)].forEach {
      bvv.filterControl.selectedSegmentIndex = $0.0
      XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), $0.1)
    }

    bvv.filterControl.selectedSegmentIndex = 0
    bvvc.valueChanged(bvv.filterControl)
    XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), irregularVerbCount)

    bvvc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
    XCTAssert(nc.pushedViewController is VerbVC)
  }
}
