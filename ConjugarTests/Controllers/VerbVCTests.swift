//
//  VerbVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 9/2/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class VerbVCTests: XCTestCase {
  func testVerbVC() {
    var analytic = ""
    let vvc = VerbVC(verb: "maltear", settings: Settings(getterSetter: DictionaryGetterSetter(dictionary: [:])), analyticsService: TestAnalyticsService(fire: { fired in analytic = fired }))
    UIApplication.shared.keyWindow?.rootViewController = vvc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    XCTAssertNotNil(vvc)
    XCTAssertNotNil(vvc.verbView)
    vvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(VerbVC.self) ")
  }
}
