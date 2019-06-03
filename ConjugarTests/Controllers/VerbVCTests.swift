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
    let vvc = VerbVC(verb: "maltear", settings: Settings(getterSetter: DictionaryGetterSetter()), analyticsService: TestAnalyticsService(fire: { fired in analytic = fired }))
    UIApplication.shared.keyWindow?.rootViewController = vvc

    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    XCTAssertNotNil(vvc)
    XCTAssertNotNil(vvc.verbView)
    vvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(VerbVC.self) ")
  }

  func testVerbTypes() {
    let arText = "Regular AR"
    let erText = "Regular ER"
    let irText = "Regular IR"
    let defectiveText = "Defective"
    let notDefectiveText = "Not Defective"
    let parentText = "Irreg. ☛ conocer"
    let irregularText = "Irregular"

    [
      ("maltear", arText, notDefectiveText),
      ("comer", erText, notDefectiveText),
      ("subir", irText, notDefectiveText),
      ("gustar", arText, defectiveText),
      ("reconocer", parentText, notDefectiveText),
      ("ser", irregularText, notDefectiveText)
    ].forEach {
      let vvc = VerbVC(verb: $0.0, settings: Settings(getterSetter: DictionaryGetterSetter()), analyticsService: TestAnalyticsService())
      UIApplication.shared.keyWindow?.rootViewController = vvc
      vvc.viewWillAppear(true)
      let vv = vvc.verbView
      XCTAssertEqual(vv.parentOrType.text, $0.1)
      XCTAssertEqual(vv.defectivo.text, $0.2)
    }
  }
}
