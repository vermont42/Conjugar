//
//  InfoCellTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/22/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class InfoCellTests: XCTestCase {
  func testInfoCell() {
    let cell = InfoCell(style: .default, reuseIdentifier: "cell")
    cell.configure(heading: "Here is an info heading.")
    XCTAssertEqual(cell.heading.text, "Here is an info heading.")
  }
}
