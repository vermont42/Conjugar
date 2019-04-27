//
//  RatingsFetcherTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/26/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class RatingsFetcherTests: XCTestCase {
  func testNoReviews() {
    testDescription(count: 0, expectedDescription: "No one has rated this version of Conjugar. Be the first!")
  }

  func testOneReview() {
    testDescription(count: 1, expectedDescription: "There is one rating for this version of Conjugar. Add yours!")
  }

  func testManyReviews() {
    testDescription(count: 42, expectedDescription: "There are 42 ratings for this version of Conjugar. Add yours!")
  }

  private func stubSession(ratingsCount: Int) -> URLSession {
    URLProtocolStub.testURLs = [RatingsFetcher.iTunesURL: RatingsFetcher.stubData(ratingsCount: ratingsCount)]
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: config)
  }

  private func testDescription(count: Int, expectedDescription: String) {
    let expection = expectation(description: "testDescription")
    RatingsFetcher.fetchRatingsDescription(session: stubSession(ratingsCount: count), completion: { actualDescription in
      XCTAssertEqual(actualDescription, expectedDescription)
      expection.fulfill()
    })
    let timeout: TimeInterval = 0.5
    wait(for: [expection], timeout: timeout)
  }
}
