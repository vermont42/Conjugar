//
//  VerbBrowseKeyboardTests.swift
//  ConjugarTests
//
//  How the arrow keys move the Verbs tab's highlighted result on iPad and Mac keyboards.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

@Suite struct VerbBrowseKeyboardTests {
  @Test func theFirstDownLandsOnTheFirstResult() {
    #expect(VerbBrowseView.keyboardSelection(after: nil, moving: 1, count: 5) == 0)
  }

  @Test func theFirstUpSelectsNothing() {
    #expect(VerbBrowseView.keyboardSelection(after: nil, moving: -1, count: 5) == nil)
  }

  @Test func theSelectionStopsAtEitherEnd() {
    #expect(VerbBrowseView.keyboardSelection(after: 4, moving: 1, count: 5) == 4)
    #expect(VerbBrowseView.keyboardSelection(after: 0, moving: -1, count: 5) == 0)
    #expect(VerbBrowseView.keyboardSelection(after: 2, moving: 1, count: 5) == 3)
  }

  @Test func noResultsMeansNoSelection() {
    #expect(VerbBrowseView.keyboardSelection(after: nil, moving: 1, count: 0) == nil)
    #expect(VerbBrowseView.keyboardSelection(after: 3, moving: 1, count: 0) == nil)
  }
}
