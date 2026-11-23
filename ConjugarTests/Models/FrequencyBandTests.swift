//
//  FrequencyBandTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

struct FrequencyBandTests {
  @Test func eachBandHoldsExactlyItsCount() {
    for band in FrequencyBand.allCases {
      let entries = VerbMap.shared.entries(in: band)
      #expect(entries.count == band.verbCount)
      #expect(entries.map(\.frequencyRank) == Array(1...band.verbCount))
    }
  }

  @Test func theBandsNest() {
    let top100 = Set(VerbMap.shared.entries(in: .top100).map(\.infinitive))
    let top300 = Set(VerbMap.shared.entries(in: .top300).map(\.infinitive))
    let top1000 = Set(VerbMap.shared.entries(in: .top1000).map(\.infinitive))
    #expect(top100.isSubset(of: top300))
    #expect(top300.isSubset(of: top1000))
    #expect(FrequencyBand.allCases.map(\.verbCount) == [100, 300, 1000])
  }

  @Test func aBandEndsAtItsCount() throws {
    let hundredth = try #require(VerbMap.shared.entries.values.first { $0.frequencyRank == 100 })
    let hundredAndFirst = try #require(VerbMap.shared.entries.values.first { $0.frequencyRank == 101 })
    #expect(hundredth.isIn(.top100))
    #expect(!hundredAndFirst.isIn(.top100))
    #expect(hundredAndFirst.isIn(.top300))
  }
}
