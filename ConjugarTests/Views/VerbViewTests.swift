//
//  VerbViewTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 9/4/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class VerbViewTests: XCTestCase {
  func testVerbVC() {
    let vvc = VerbVC(settings: Settings(getterSetter: DictionaryGetterSetter(dictionary: [:])), analyticsService: TestAnalyticsService(fire: {_ in}))
    vvc.verb = "maltear"
    UIApplication.shared.keyWindow?.rootViewController = vvc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    let verbView = vvc.verbView
    XCTAssertNotNil(verbView)
    XCTAssertEqual(verbView.subviews.count, 8)
  }
}
