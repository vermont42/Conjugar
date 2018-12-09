//
//  QuizVCUITests.swift
//  ConjugarUITests
//
//  Created by Joshua Adams on 12/8/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import XCTest

class QuizVCUITests: XCTestCase {

  override func setUp() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["enable-ui-testing"]
    app.launch()
  }

  override func tearDown() {}

  func testQuiz() {
    let app = XCUIApplication()
    app.tabBars.buttons["Quiz"].tap()
    XCTAssert(app.buttons["Start"].waitForExistence(timeout: 1))
    app.buttons["Start"].tap()
    let textField = app.textFields[" conjugation"]
    ["sintiendo", "midiendo", "caminando", "existiendo", "bebiendo", "andas", "ocurre", "leemos", "vais", "duermen", "hago", "fuiste", "dio", "pusimos", "trabajastéis", "recibieron", "aprendí", "ibas", "veía", "caminábamos", "andabais", "sabrán", "cabré", "trabajarás", "estudiará", "escucharíamos", "visitaríais", "podrían", "vaya", "hayas", "sepa", "estudiemos", "permitáis", "comprendan", "pudiera", "viajases", "estuviere", "enseñáremos", "ve", "llevad", "no llegen", "he cubierto", "hubiste bailado", "había dicho", "habremos nadado", "habríais escrito", "hayan cocinado", "hubiera hecho", "hubieses charlado", "hubiere muerto"].forEach { conjugation in
      textField.typeText(conjugation + "\n")
    }

    // TODO: Check stuff on results screen. Also test Latin America, moderate, and easy scenarios.

    // TODO: Pass in shuffle=false value and restore that to true in app delegate for non-UI-test scenario.

    // TODO: Output all correct answers for a default quiz, no shuffle.
    // Inject a generic Settings object when enable-ui-testing is true.
    // Use the answers for testing. Ensure that ResultsVC ends up on screen.
  }
}
