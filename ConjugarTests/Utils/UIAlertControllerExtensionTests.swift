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
    Current = World.unitTest
    let ivc = InfoVC(infoString: NSAttributedString(string: "🍕"), infoDelegate: self)

    guard let window = UIApplication.shared.connectedScenes
    .filter({$0.activationState == .foregroundActive})
    .map({$0 as? UIWindowScene})
    .compactMap({$0})
    .first?.windows
    .filter({$0.isKeyWindow}).first else {
      XCTFail("Could not create window.")
      return
    }

    window.rootViewController = ivc

    ivc.viewWillAppear(true)
    UIAlertController.showMessage("", title: "", okTitle: "", onViewController: ivc)
    XCTAssert(ivc.presentedViewController is UIAlertController)
  }

  func infoSelectionDidChange(newHeading: String) { }
}
