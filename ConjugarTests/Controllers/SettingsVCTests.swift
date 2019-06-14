//
//  SettingsVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/1/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
import UIKit
@testable import Conjugar

class SettingsVCTests: XCTestCase {
  func testSettings() {
    var analytic = ""
    GlobalContainer.registerUnitTestingDependencies()
    GlobalContainer.registerAnalytics(TestAnalyticsService(fire: { fired in analytic = fired }))

    let svc = SettingsVC()
    let nc = MockNavigationC(rootViewController: svc)
    UIApplication.shared.keyWindow?.rootViewController = nc

    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    XCTAssertNotNil(svc)
    svc.viewWillAppear(true)
    XCTAssert(nc.pushedViewController is SettingsVC)
    XCTAssertEqual(analytic, "visited viewController: \(SettingsVC.self) ")

    XCTAssertEqual(GlobalContainer.settings.region, .latinAmerica)
    let regionControl = svc.settingsView.regionControl
    regionControl.selectedSegmentIndex = 0
    svc.regionChanged(regionControl)
    XCTAssertEqual(GlobalContainer.settings.region, .spain)

    XCTAssertEqual(GlobalContainer.settings.difficulty, .easy)
    let difficultyControl = svc.settingsView.difficultyControl
    difficultyControl.selectedSegmentIndex = 2
    svc.difficultyChanged(difficultyControl)
    XCTAssertEqual(GlobalContainer.settings.difficulty, .difficult)
    difficultyControl.selectedSegmentIndex = 1
    svc.difficultyChanged(difficultyControl)
    XCTAssertEqual(GlobalContainer.settings.difficulty, .moderate)

    XCTAssertEqual(GlobalContainer.settings.secondSingularBrowse, .tu)
    let browseVosControl = svc.settingsView.browseVosControl
    browseVosControl.selectedSegmentIndex = 2
    svc.browseVosChanged(browseVosControl)
    XCTAssertEqual(GlobalContainer.settings.secondSingularBrowse, .both)
    browseVosControl.selectedSegmentIndex = 1
    svc.browseVosChanged(browseVosControl)
    XCTAssertEqual(GlobalContainer.settings.secondSingularBrowse, .vos)

    XCTAssertEqual(GlobalContainer.settings.secondSingularQuiz, .tu)
    let quizVosControl = svc.settingsView.quizVosControl
    quizVosControl.selectedSegmentIndex = 1
    svc.quizVosChanged(quizVosControl)
    XCTAssertEqual(GlobalContainer.settings.secondSingularQuiz, .vos)

    XCTAssertFalse(GlobalContainer.gameCenter.isAuthenticated)
    svc.authenticate()
    XCTAssert(GlobalContainer.gameCenter.isAuthenticated)

    let expectatiön = expectation(description: "testRateReview")
    svc.rateReview(completion: { didSucceed in
      XCTAssert(didSucceed)
      expectatiön.fulfill()
    })
    let timeout: TimeInterval = 0.5
    wait(for: [expectatiön], timeout: timeout)
  }
}
