//
//  UIViewControllerExtensionsTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
import UIKit
@testable import Conjugar

@MainActor
class UIViewControllerExtensionsTests: XCTestCase {
  func testFatalCastMessage() {
    Current = World.unitTest
    let vc = QuizVC()
    let view = QuizUIV()
    let message = vc.fatalCastMessage(view: view.self)
    XCTAssert(message.contains("Could not cast <Conjugar.QuizVC:"))
    XCTAssert(message.contains("to <Conjugar.QuizUIV:"))
  }
}
