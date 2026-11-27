//
//  RowLabelTests.swift
//  ConjugarTests
//
//  The pieces of the browse lists' rows and cards that are not layout: the title's language, a
//  row's background, and a collection's progress.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
@testable import Conjugar

@MainActor
struct RowLabelTests {
  private typealias Label = RowLabel<EmptyView, EmptyView>

  @Test func aSpanishTitleIsReadInASpanishVoice() {
    let title = Label.title("tener", isSpanish: true)

    #expect(String(title.characters) == "tener")
    #expect(title.runs.allSatisfy { $0.languageIdentifier == "es" })
  }

  @Test func aCollectionsTitleIsReadInTheAppsLanguage() {
    let title = Label.title("-go Verbs", isSpanish: false)

    #expect(String(title.characters) == "-go Verbs")
    #expect(title.runs.allSatisfy { $0.languageIdentifier == nil })
  }

  @Test func aStripedListTintsEveryOtherRow() {
    #expect(Color.listRow(0, isStriped: true, isHighlighted: false) == .zebraStripe(0))
    #expect(Color.listRow(1, isStriped: true, isHighlighted: false) == .zebraStripe(1))
    #expect(Color.zebraStripe(0) != Color.zebraStripe(1))
  }

  @Test func anUnstripedListTintsNoRow() {
    #expect(Color.listRow(0, isStriped: false, isHighlighted: false) == .clear)
    #expect(Color.listRow(1, isStriped: false, isHighlighted: false) == .clear)
  }

  @Test(arguments: [0, 1])
  func theHighlightCoversTheStripe(index: Int) {
    #expect(Color.listRow(index, isStriped: true, isHighlighted: true) == .keyboardSelection)
    #expect(Color.listRow(index, isStriped: false, isHighlighted: true) == .keyboardSelection)
  }

  @Test func aCollectionsProgressReadsAsAFractionAndAsASentence() {
    let progress = CollectionProgress(opened: 2, total: 11)

    #expect(progress.fraction == "2/11")
    #expect(progress.description == L.VerbCollection.progress(opened: 2, total: 11))
    #expect(progress.barValue == 2)
    #expect(progress.barTotal == 11)
  }

  @Test func anEmptyCollectionsBarIsEmptyNotUndefined() {
    let progress = CollectionProgress(opened: 0, total: 0)

    #expect(progress.fraction == "0/0")
    #expect(progress.barValue == 0)
    #expect(progress.barTotal == 1)
  }
}
