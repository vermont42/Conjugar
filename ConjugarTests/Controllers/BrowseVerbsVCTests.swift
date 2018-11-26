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
    let bvvc = BrowseVerbsVC(settings: Settings(customDefaults: [:]), analyticsService: TestAnalyticsService(fire: { fired in analytic = fired }), reviewPrompter: nil)
    let nc = MockNavigationC(rootViewController: bvvc)
    UIApplication.shared.keyWindow?.rootViewController = nc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    XCTAssertNotNil(bvvc)
    bvvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(BrowseVerbsVC.self) ")
    XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), 84)
    bvvc.browseVerbsView.filterControl.selectedSegmentIndex = 1
    XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), 102)
    bvvc.browseVerbsView.filterControl.selectedSegmentIndex = 2
    XCTAssertEqual(bvvc.tableView(UITableView(), numberOfRowsInSection: 0), 186)
    bvvc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
    XCTAssertTrue(nc.pushedViewController is VerbVC)
  }
}
