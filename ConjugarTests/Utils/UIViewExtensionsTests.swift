//
//  UIViewExtensionsTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/28/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class UIViewExtensionsTests: XCTestCase {
  func testPulsate() {
    let view = UIView()
    view.pulsate()
    let expectatiön = expectation(description: "testPulsate")
    let duration: TimeInterval = 0.3
    let cushion: TimeInterval = 1.0
    let timeoutFactor: TimeInterval = 2.0
    DispatchQueue.main.asyncAfter(deadline: .now() + duration + cushion, execute: {
      XCTAssert(view.transform.isIdentity)
      expectatiön.fulfill()
    })
    wait(for: [expectatiön], timeout: duration + cushion * timeoutFactor)
  }

  func testEnableAutoLayout() {
    let view = UIView()
    XCTAssert(view.translatesAutoresizingMaskIntoConstraints)
    view.enableAutoLayout()
    XCTAssertFalse(view.translatesAutoresizingMaskIntoConstraints)
  }
}
