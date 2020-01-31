//
//  UsesAutoLayoutTests.swift
//  ConjugarTests
//
//  Created by Josh Adams on 1/28/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class UsesAutoLayoutTests: XCTestCase {
  @UsesAutoLayout
  var wrappedView: UIView = {
    return UIView()
  }()

  func testUsesAutoLayout() {
    let vanillaView = UIView()
    XCTAssert(vanillaView.translatesAutoresizingMaskIntoConstraints)
    XCTAssertFalse(wrappedView.translatesAutoresizingMaskIntoConstraints)
  }
}
