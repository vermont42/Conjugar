//
//  BrowseInfoVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 9/2/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class BrowseInfoVCTests: XCTestCase {
  func testBrowseInfoVC() {
    var analytic = ""
    let bivc = BrowseInfoVC(settings: Settings(customDefaults: [:]), analyticsService: TestAnalyticsService(fire: { fired in analytic = fired }))
    let nc = MockNavigationC(rootViewController: bivc)
    UIApplication.shared.keyWindow?.rootViewController = nc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    XCTAssertNotNil(bivc)
    bivc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(BrowseInfoVC.self) ")
    XCTAssertEqual(bivc.tableView(UITableView(), numberOfRowsInSection: 0), 28)
    bivc.browseInfoView.difficultyControl.selectedSegmentIndex = 0
    XCTAssertEqual(bivc.tableView(UITableView(), numberOfRowsInSection: 0), 9)
    bivc.browseInfoView.difficultyControl.selectedSegmentIndex = 1
    XCTAssertEqual(bivc.tableView(UITableView(), numberOfRowsInSection: 0), 17)
    bivc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
    XCTAssertTrue(nc.pushedViewController is InfoVC)
  }
}
