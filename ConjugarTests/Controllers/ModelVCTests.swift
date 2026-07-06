//
//  ModelVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class ModelVCTests: XCTestCase {
  private func modelInfo(forClass classNumber: String) -> ModelInfo? {
    ModelInfo.all.first { $0.classNumber == classNumber }
  }

  func testModelVCForSmallClass() {
    var analytic = ""
    Current.analytics = AnalyticsServiceSpy(fire: { fired in analytic = fired })
    Current.settings = Settings(getterSetter: GetterSetterFake())

    guard let tener = modelInfo(forClass: "31") else {
      XCTFail("No ModelInfo for class 31.")
      return
    }
    let mvc = ModelVC(modelInfo: tener)
    let nc = NavigationCSpy(rootViewController: mvc)

    XCTAssertNotNil(mvc.modelView)
    mvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(ModelVC.self) ")

    XCTAssertEqual(mvc.tableView(UITableView(), numberOfRowsInSection: 0), tener.verbs.count)
    XCTAssert(tener.verbs.contains("obtener"))
    XCTAssertEqual(mvc.modelView.details.text?.contains("31"), true)

    let table = UITableView()
    table.register(VerbCell.self, forCellReuseIdentifier: VerbCell.identifier)
    guard let firstCell = mvc.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)) as? VerbCell else {
      XCTFail("First cell was not a VerbCell.")
      return
    }
    XCTAssertEqual(firstCell.verb.text, tener.verbs[0])

    mvc.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
    XCTAssert(nc.pushedViewController is VerbVC)
  }

  func testModelVCForHugeClass() {
    Current.analytics = AnalyticsServiceSpy()
    Current.settings = Settings(getterSetter: GetterSetterFake())

    guard let cantar = modelInfo(forClass: "1") else {
      XCTFail("No ModelInfo for class 1.")
      return
    }
    let mvc = ModelVC(modelInfo: cantar)
    XCTAssertNotNil(mvc.modelView)
    XCTAssert(cantar.verbs.count > 1000)
    XCTAssertEqual(mvc.tableView(UITableView(), numberOfRowsInSection: 0), cantar.verbs.count)
  }
}
