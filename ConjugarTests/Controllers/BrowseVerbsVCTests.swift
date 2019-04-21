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
    let bvvc = BrowseVerbsVC(settings: Settings(getterSetter: DictionaryGetterSetter(dictionary: [:])), analyticsService: TestAnalyticsService(fire: { fired in analytic = fired }), reviewPrompter: TestReviewPrompter())
    let nc = MockNavigationC(rootViewController: bvvc)
    UIApplication.shared.keyWindow?.rootViewController = nc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    XCTAssertNotNil(bvvc)
    bvvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(BrowseVerbsVC.self) ")
    XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), 92)
    bvvc.browseVerbsView.filterControl.selectedSegmentIndex = 1
    XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), 105)
    bvvc.browseVerbsView.filterControl.selectedSegmentIndex = 2
    XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), 197)
    bvvc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
    XCTAssertTrue(nc.pushedViewController is VerbVC)
  }
}
