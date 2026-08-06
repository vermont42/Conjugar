//
//  RatingsFetcherTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/26/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//
//  Kept as XCTest (rather than converted to Swift Testing) on purpose: it mutates the
//  global `Current`, and XCTest's serial execution keeps that write from racing the many
//  suites that *read* `Current`. A Swift Testing suite runs in parallel with the others by
//  default, so the same code there would be a data race on a global. (`.serialized`
//  wouldn't save it — that trait orders tests within a suite, not across suites.)
//

import XCTest
@testable import Conjugar

@MainActor
class RatingsFetcherTests: XCTestCase {
  // The *async* setUp, deliberately: a non-async `override func setUp()` inherits
  // XCTestCase's nonisolated isolation (an override has nowhere to hop, so it cannot
  // add `@MainActor`), which makes assigning the MainActor-isolated `Current` a Swift 6
  // concurrency warning. An async override can be isolated to the class's actor,
  // because the caller awaits it.
  override func setUp() async throws {
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
