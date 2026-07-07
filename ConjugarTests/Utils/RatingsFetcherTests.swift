//
//  RatingsFetcherTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/26/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//
//  Kept as XCTest (rather than converted to Swift Testing) on purpose: it reassigns
//  the global `Current`, and XCTest's serial execution keeps that mutation from
//  racing the other `Current`-reassigning suite (CommunViewModelTests) — which a
//  parallel Swift Testing suite would not. Adapted to RatingsFetcher's async/await +
//  Codable API (item 20); the old completion-handler `expectation` dance is gone.
//

import XCTest
@testable import Conjugar

@MainActor
class RatingsFetcherTests: XCTestCase {
  override func setUp() {
    Current = World.unitTest
  }

  func testNoReviews() async {
    await checkDescription(count: 0, expected: "No one has rated this version of Conjugar. ¡Sé la primera o el primero!")
  }

  func testOneReview() async {
    await checkDescription(count: 1, expected: "There is one rating for this version of Conjugar. Add yours!")
  }

  func testManyReviews() async {
    await checkDescription(count: 42, expected: "There are 42 ratings for this version of Conjugar. Add yours!")
  }

  private func checkDescription(count: Int, expected: String) async {
    Current.session = URLSession.stubSession(ratingsCount: count)
    let description = await RatingsFetcher.ratingsDescription()
    XCTAssertEqual(description, expected)
  }
}
