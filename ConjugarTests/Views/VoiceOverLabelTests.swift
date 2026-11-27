//
//  VoiceOverLabelTests.swift
//  ConjugarTests
//
//  What VoiceOver reads where the screen's text would read badly: the model pill without its ☛,
//  and the review card as one element, with its Spanish tagged Spanish.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct VoiceOverLabelTests {
  /// The text of each run tagged Spanish.
  private func spanishRuns(_ label: AttributedString) -> [String] {
    label.runs.compactMap { run in
      run.languageIdentifier == "es" ? String(label[run.range].characters) : nil
    }
  }

  @Test func aPillThatNamesAnExemplarReadsWithoutTheGlyph() throws {
    let entry = try #require(VerbMap.shared.entry(for: "obtener"))
    let label = try #require(VerbView.spokenTypeOrParent(verb: "obtener", entry: entry))
    let text = String(label.characters)

    #expect(!text.contains("☛"))
    #expect(!text.contains("Irreg."))
    #expect(text.hasSuffix("tener"))
    #expect(spanishRuns(label) == ["tener"])
  }

  @Test(arguments: ["tener", "hablar", "comer", "vivir"])
  func aPillWithNoExemplarReadsAsItIs(verb: String) throws {
    let entry = try #require(VerbMap.shared.entry(for: verb))
    #expect(VerbView.spokenTypeOrParent(verb: verb, entry: entry) == nil)
  }

  @Test func theHiddenCardReadsItsVerbGlossAndCaption() throws {
    let entry = try #require(VerbMap.shared.entry(for: "tener"))
    let label = ReviewCardView.accessibilityLabel(entry: entry, caption: "Looked up 3 days ago", forms: nil)

    #expect(String(label.characters) == "tener, \(entry.gloss). Looked up 3 days ago.")
    #expect(spanishRuns(label) == ["tener"])
  }

  @Test func theRevealedCardReadsItsFormsInSpanishWithoutMiddleDots() throws {
    let entry = try #require(VerbMap.shared.entry(for: "tener"))
    let forms = KeyConjugation.forms(of: "tener").map(\.form)
    let label = ReviewCardView.accessibilityLabel(entry: entry, caption: "Looked up 3 days ago", forms: forms)
    let spokenForms = forms.map(ConjugationText.plain).joined(separator: ", ")

    #expect(String(label.characters).hasSuffix(" \(spokenForms)"))
    #expect(!String(label.characters).contains("·"))
    #expect(spanishRuns(label) == ["tener", spokenForms])
    #expect(spokenForms.hasPrefix("tengo"))
  }
}
