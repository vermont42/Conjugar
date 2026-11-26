//
//  VerbPageFormsTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

/// The verb page's forms, and what its two tips need to know. MainActor because the page's forms
/// take the learner's choice of tú or vos.
@MainActor
struct VerbPageFormsTests {
  private func forms(_ verb: String, marks: Set<ConjugationCell> = [], secondSingular: SecondSingularBrowse = .tu) -> VerbPageForms {
    VerbPageForms(verb: verb, marks: marks, secondSingular: secondSingular)
  }

  /// A regular verb's page shows red letters only in its compound tenses' auxiliary (hE hablado),
  /// which every page has. The red-letter tip is about the verb's own.
  @Test(arguments: ["hablar", "abaratar", "comer", "vivir"])
  func aRegularVerbHasNoRedLettersOfItsOwn(verb: String) {
    let page = forms(verb)
    #expect(!page.hasRedLetters)
    let compoundForms = page.sections.filter(\.table.isCompound).flatMap { $0.rows.map(\.form) }
    let auxiliaryIsMarked = compoundForms.contains { $0.contains(where: \.isUppercase) }
    #expect(auxiliaryIsMarked)
  }

  @Test(arguments: ["tener", "ser", "pedir", "dormir"])
  func anIrregularVerbHasRedLetters(verb: String) {
    #expect(forms(verb).hasRedLetters)
  }

  /// The engine marks a spelling change as it marks any irregularity (busQUé), so buscar's page
  /// has red letters and shows the tip.
  @Test func aSpellingChangeCountsAsARedLetter() {
    #expect(forms("buscar").hasRedLetters)
  }

  /// The header's forms count: a verb whose only red letter were its participle would show the tip.
  @Test func theHeaderFormsAreRead() {
    let escribir = forms("escribir")
    let participleIsMarked = escribir.participio.contains(where: \.isUppercase)
    #expect(participleIsMarked)
    #expect(escribir.hasRedLetters)
  }

  @Test func theSectionsFollowThePageAndTheChosenPerson() {
    let tu = forms("hablar")
    #expect(tu.sections.map(\.tense) == ConjugationTable.all.map(\.tense))
    #expect(tu.sections[0].rows.map(\.form) == ["hablo", "hablas", "habla", "hablamos", "habláis", "hablan"])
    #expect(forms("hablar", secondSingular: .vos).sections[0].rows.map(\.form)[1] == "hablás")
    // A marked vos form shows vos beside tú for a learner who chose tú.
    let marked = forms("hablar", marks: [ConjugationCell(tense: .presenteDeIndicativo, personNumber: .secondSingularVos)])
    #expect(marked.sections[0].rows.map(\.form) == ["hablo", "hablas", "hablás", "habla", "hablamos", "habláis", "hablan"])
    #expect(marked.markedSectionID == DisplayTense.presenteDeIndicativo.rawValue)
    #expect(tu.markedSectionID == nil)
  }

  /// The scroll tip points to the etymology and the examples, so a page without them has nothing
  /// for it to point to.
  @Test func theScrollTipNeedsSomethingBelowTheConjugations() {
    #expect(!ScrollToBottomTip.hasTarget(onPageOf: "abaratar"))
    #expect(ScrollToBottomTip.hasTarget(onPageOf: "tener"))
  }
}
