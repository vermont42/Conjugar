//
//  UIAlertControllerExtensionTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
import UIKit
@testable import Conjugar

class UIAlertControllerExtensionTests: XCTestCase, InfoDelegate {
  func testShowMessage() {
    let ivc = InfoVC(analyticsService: TestAnalyticsService(), infoString: NSAttributedString(string: "🍕"), infoDelegate: self)
    UIApplication.shared.keyWindow?.rootViewController = ivc
    ivc.viewWillAppear(true)
    UIAlertController.showMessage("", title: "")
    XCTAssert(ivc.presentedViewController is UIAlertController)
  }

  func infoSelectionDidChange(newHeading: String) { }
}