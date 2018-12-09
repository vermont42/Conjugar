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
    app.buttons["Start"].tap()
    // TODO: Output all correct answers for a default quiz, no shuffle.
    // Inject a generic Settings object when enable-ui-testing is true.
    // Use the answers for testing. Ensure that ResultsVC ends up on screen.
  }
}
