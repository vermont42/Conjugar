//
//  QuizVCUITests.swift
//  ConjugarUITests
//
//  Created by Joshua Adams on 12/8/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

//import XCTest
//
//class QuizVCUITests: XCTestCase {
//  let enableUiTesting = "enable-ui-testing"
//
//  override func setUp() {
//    continueAfterFailure = false
//  }
//
//  override func tearDown() {}
//
//  func testDifficultSpainQuiz() {
//    testQuiz(answers: ["sintiendo", "midiendo", "caminando", "existiendo", "bebiendo", "andas", "ocurre", "leemos", "vais", "duermen", "hago", "fuiste", "dio", "pusimos", "trabajastéis", "recibieron", "aprendí", "ibas", "veía", "caminábamos", "andabais", "sabrán", "cabré", "trabajarás", "estudiará", "escucharíamos", "visitaríais", "podrían", "vaya", "hayas", "sepa", "estudiemos", "permitáis", "comprendan", "pudiera", "viajases", "estuviere", "enseñáremos", "ve", "llevad", "no llegen", "he cubierto", "hubiste bailado", "había dicho", "habremos nadado", "habríais escrito", "hayan cocinado", "hubiera hecho", "hubieses charlado", "hubiere muerto"], region: "Spain", difficulty: "Difficult")
//  }
//
//  func testDifficultLatinAmericaQuiz() {
//    testQuiz(answers: ["sintiendo", "midiendo", "caminando", "existiendo", "bebiendo", "andas", "ocurre", "leemos", "van", "duermo", "haces", "fue", "dimos", "pusieron", "trabajé", "recibiste", "aprendió", "ibamos", "veían", "caminaba", "andabas", "sabrá", "cabremos", "trabajarán", "estudiaré", "escucharías", "visitaría", "podríamos", "vayan", "haya", "sepas", "estudie", "permitamos", "comprendan", "pudiera", "viajases", "estuviere", "enseñáremos", "ve", "lleven", "no llege", "hemos cubierto", "hubieron bailado", "había dicho", "habrás nadado", "habría escrito", "hayamos cocinado", "hubieran hecho", "hubiese charlado", "hubieres muerto"], region: "Latin America", difficulty: "Difficult")
//  }
//
//  func testModerateSpainQuiz() {
//    testQuiz(answers: ["caminas", "anda", "existimos", "bebéis", "van", "duermo", "haces", "muere", "sabremos", "cabréis", "podrán", "caminaré", "andarás", "querría", "pondríamos", "tendríais", "trabajarían", "estudiaría", "has cubierto", "ha dicho", "hemos escrito", "habéis escuchado", "han visitado", "iba", "veías", "era", "viajábamos", "enseñabais", "llevaban", "fui", "diste", "puso", "trabajamos", "ocurristeis", "leieron", "vaya", "hayas", "sepa", "llegemos", "bailéis", "sintiendo", "midiendo", "nadando", "cocinando", "ve", "he", "charlen", "platice", "no lloremos", "no esperéis"], region: "Spain", difficulty: "Moderate")
//  }
//
//  func testModerateLatinAmericaQuiz() {
//    testQuiz(answers: ["caminas", "anda", "existimos", "beben", "voy", "duermes", "hace", "morimos", "sabrán", "cabré", "podrás", "caminará", "andaremos", "querrían", "pondría", "tendrías", "trabajaría", "estudiaríamos", "han cubierto", "he dicho", "has escrito", "ha escuchado", "hemos visitado", "iban", "veía", "eras", "viajaba", "enseñábamos", "llevaban", "fui", "diste", "puso", "trabajamos", "ocurrieron", "leí", "vayas", "haya", "sepamos", "llegen", "baile", "sintiendo", "midiendo", "nadando", "cocinando", "ve", "he", "charle", "platicemos", "no lloren", "no espere"], region: "Latin America", difficulty: "Moderate")
//  }
//
//  func testEasySpainQuiz() {
//    testQuiz(answers: ["caminas", "anda", "trabajamos", "existís", "ocurren", "recibo", "bebes", "lee", "aprendemos", "vais", "duermen", "hago", "mueres", "muerde", "oímos", "podéis", "han", "siento", "sabrás", "cabrá", "podremos", "querréis", "pondrán", "tendré", "vendrás", "saldrá", "estudiaremos", "escucharéis", "visitarán", "permitiré", "partirás", "comprenderá", "correremos", "fuisteis", "dieron", "puse", "pudiste", "estuvo", "tuvimos", "anduvisteis", "supieron", "caminé", "anduviste", "trabajó", "estudiamos", "escuchastéis", "visitaron", "viajé", "enseñaste", "llevó"], region: "Spain", difficulty: "Easy")
//  }
//
//  func testEasyLatinAmericaQuiz() {
//    testQuiz(answers: ["caminas", "anda", "trabajamos", "existen", "ocurro", "recibes", "bebe", "leemos", "aprenden", "voy", "duermes", "hace", "morimos", "muerden", "oigo", "puedes", "ha", "sentimos", "sabrán", "cabré", "podrás", "querrá", "pondremos", "tendrán", "vendré", "saldrás", "estudiará", "escucharemos", "visitarán", "permitiré", "partirás", "comprenderá", "correremos", "fueron", "di", "pusiste", "pudo", "estuvimos", "tuvieron", "anduve", "supiste", "caminó", "anduvimos", "trabajaron", "estudié", "escuchaste", "visitó", "viajamos", "enseñaron", "llevé"], region: "Latin America", difficulty: "Easy")
//  }
//
//  func testQuiz(answers: [String], region: String, difficulty: String) {
//    let app = XCUIApplication()
//    app.launchArguments = [enableUiTesting, region, difficulty]
//    app.launch()
//    app.tabBars.buttons["Quiz"].tap()
//    let timeout: TimeInterval = 1.0
//    XCTAssert(app.buttons["Start"].waitForExistence(timeout: timeout))
//    app.buttons["Start"].tap()
//    let textField = app.textFields[" conjugation"]
//    answers.forEach { conjugation in
//      textField.typeText(conjugation + "\n")
//    }
//    XCTAssert(app.staticTexts["Results"].waitForExistence(timeout: timeout))
//    XCTAssert(app.staticTexts[region].exists)
//    XCTAssert(app.staticTexts[difficulty].exists)
//  }
//}
