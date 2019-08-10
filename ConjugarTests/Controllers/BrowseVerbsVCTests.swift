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
    let bvvc = BrowseVerbsVC(settings: Settings(getterSetter: DictionaryGetterSetter()), analyticsService: TestAnalyticsService(fire: { fired in analytic = fired }), reviewPrompter: TestReviewPrompter())
    let nc = MockNavigationC(rootViewController: bvvc)
    UIApplication.shared.keyWindow?.rootViewController = nc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)

    XCTAssertNotNil(bvvc)
    bvvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(BrowseVerbsVC.self) ")

    let irregularVerbCount = Conjugator.shared.irregularVerbs.count
    let regularVerbCount = Conjugator.shared.regularVerbs.count
    let combinedVerbCount = irregularVerbCount + regularVerbCount

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
