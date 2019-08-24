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
    let settings = Settings(getterSetter: DictionaryGetterSetter())
    Current.analytics = TestAnalyticsService(fire: { fired in analytic = fired })
    Current.settings = settings

    let bivc = BrowseInfoVC()
    let nc = MockNavigationC(rootViewController: bivc)
    UIApplication.shared.keyWindow?.rootViewController = nc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)

    XCTAssertNotNil(bivc)
    bivc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(BrowseInfoVC.self) ")
    XCTAssertEqual(bivc.tableView(UITableView(), numberOfRowsInSection: 0), 28)

    let biv = bivc.browseInfoView

    let easyCount = 9
    let easyModerateCount = 17
    let allCount = 28

    [(0, easyCount), (1, easyModerateCount), (2, allCount)].forEach {
      biv.difficultyControl.selectedSegmentIndex = $0.0
      XCTAssertEqual(bivc.tableView(UITableView(), numberOfRowsInSection: 0), $0.1)
    }

    bivc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
    XCTAssert(nc.pushedViewController is InfoVC)
    nc.popViewController(animated: false)

    [(0, Difficulty.easy), (1, .moderate), (2, .difficult)].forEach {
      biv.difficultyControl.selectedSegmentIndex = $0.0
      bivc.difficultyChanged(biv.difficultyControl)
      XCTAssertEqual(settings.infoDifficulty, $0.1)
    }

    bivc.infoSelectionDidChange(newHeading: "Terminology")
    XCTAssert(nc.pushedViewController is InfoVC)
  }
}
