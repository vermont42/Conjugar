//
//  UIViewControllerExtensionTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
import UIKit
@testable import Conjugar

class UIViewControllerExtensionTests: XCTestCase {
  func testFatalCastMessage() {
    let vc = VerbVC()
    let view = VerbView()
    let message = vc.fatalCastMessage(view: view.self)
    XCTAssert(message.contains("Could not cast <Conjugar.VerbVC:"))
    XCTAssert(message.contains("to <Conjugar.VerbView:"))
  }
}
