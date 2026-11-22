//
//  URLExtensionTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct URLExtensionTests {
  @Test func mailtoEncodesEverythingOutsideTheUnreservedSet() {
    let url = URL.mailto("someone@example.com", subject: "x & y", body: "año=#1")
    #expect(url?.absoluteString == "mailto:someone@example.com?subject=x%20%26%20y&body=a%C3%B1o%3D%231")
  }

  @Test func mailtoRoundTripsTheQuery() throws {
    let url = try #require(URL.mailto("someone@example.com", subject: "«hablr»", body: "b"))
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    #expect(components.scheme == "mailto")
    #expect(components.path == "someone@example.com")
    #expect(components.queryItems?.first { $0.name == "subject" }?.value == "«hablr»")
  }
}
