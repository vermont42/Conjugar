//
//  InfoVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/23/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
import UIKit
@testable import Conjugar

class InfoVCTests: XCTestCase, InfoDelegate {
  var newHeading = ""

  func infoSelectionDidChange(newHeading: String) {
    self.newHeading = newHeading
  }

  func testInfoVC() {
    var analytic = ""

    let urlString = "https://racecondition.software"
    guard let url = URL(string: urlString) else {
      XCTFail("Could not create URL.")
      return
    }

    let nonURLInfoString = "info"
    guard let nonURLInfoURL = URL(string: nonURLInfoString) else {
      XCTFail("Could not create nonURLInfoURL.")
      return
    }

    let ivc = InfoVC(analyticsService: TestAnalyticsService(fire: { fired in analytic = fired }), infoString: NSAttributedString(string: "\(nonURLInfoString)\(url)"), infoDelegate: self)
    UIApplication.shared.keyWindow?.rootViewController = ivc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)

    XCTAssertNotNil(ivc)
    XCTAssertNotNil(ivc.infoView)
    ivc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(InfoVC.self) ")

    XCTAssertEqual(newHeading, "")
    var shouldInteract = ivc.textView(UITextView(), shouldInteractWith: nonURLInfoURL, in: NSRange(location: 0, length: nonURLInfoString.count))
    XCTAssertFalse(shouldInteract)
    XCTAssertEqual(newHeading, nonURLInfoString)

    shouldInteract = ivc.textView(UITextView(), shouldInteractWith: url, in: NSRange(location: nonURLInfoString.count, length: "\(url)".count))
    XCTAssert(shouldInteract)
  }
}
