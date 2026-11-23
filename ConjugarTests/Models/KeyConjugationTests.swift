//
//  KeyConjugationTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

/// The four key conjugations, the verb page's share text, and what a long press copies. MainActor
/// only because the share text reads `L`.
@MainActor
struct KeyConjugationTests {
  @Test(arguments: [
    ("hablar", "hablo · hablé · hablaré · hablado"),
    ("pensar", "pienso · pensé · pensaré · pensado"),
    ("dormir", "duermo · dormí · dormiré · dormido"),
    ("tener", "tengo · tuve · tendré · tenido"),
    ("ir", "voy · fui · iré · ido"),
    ("decir", "digo · dije · diré · dicho"),
    ("arrepentir", "me arrepiento · me arrepentí · me arrepentiré · arrepentido")
  ])
  func line(infinitive: String, expected: String) {
    #expect(KeyConjugation.line(for: infinitive) == expected)
  }

  @Test func formsComeBackMixedCaseForTheRedLetters() {
    let tener = KeyConjugation.forms(of: "tener")
    #expect(tener.map(\.key) == KeyConjugation.allCases)
    #expect(tener.map(\.form) == ["tenGo", "tUVE", "tenDré", "tenido"])
    // A regular verb has no red letters.
    #expect(KeyConjugation.forms(of: "hablar").allSatisfy { !$0.form.contains(where: \.isUppercase) })
    // A stem change is red.
    #expect(KeyConjugation.forms(of: "pensar").first?.form.contains(where: \.isUppercase) == true)
  }

  @Test func aDefectiveVerbLeavesOutWhatItLacks() {
    let abolir = KeyConjugation.forms(of: "abolir")
    #expect(abolir.map(\.key) == [.yoPretérito, .yoFuturo, .participio])
    #expect(KeyConjugation.line(for: "abolir") == "abolí · aboliré · abolido")
  }

  @Test func eachKeyIsACellOfThePage() {
    #expect(KeyConjugation.allCases.map(\.tense) == [.presenteDeIndicativo, .pretérito, .futuroDeIndicativo, .participio])
    #expect(KeyConjugation.allCases.map(\.personNumber) == [.firstSingular, .firstSingular, .firstSingular, .none])
  }

  @Test func shareTextNamesTheVerbItsGlossItsKeyConjugationsAndTheAppStore() throws {
    let text = KeyConjugation.shareText(for: "tener")
    let gloss = try #require(VerbMap.shared.entry(for: "tener")?.gloss)
    #expect(text.hasPrefix("tener, "))
    #expect(text.contains(gloss))
    #expect(text.contains("tengo · tuve · tendré · tenido"))
    #expect(text.hasSuffix("https://apps.apple.com/app/conjugar/id1236500467"))
  }

  @Test func shareTextCitesAReflexiveOnlyVerbWithItsPronoun() {
    let text = KeyConjugation.shareText(for: "arrepentir")
    #expect(text.hasPrefix("arrepentirse, "))
    #expect(text.contains("me arrepiento · me arrepentí"))
  }

  @Test func appStoreLinkNamesNoStorefront() {
    #expect(URL.appStore.absoluteString == "https://apps.apple.com/app/conjugar/id1236500467")
  }

  @Test func copyTextIsTheFormAloneInLowercase() {
    let imperative = ConjugationDisplayRow(index: 0, pronoun: nil, form: "TEN", isImperative: true, isMarked: false)
    #expect(imperative.displayForm == "¡TEN!")
    #expect(imperative.copyText == "ten")
    let finite = ConjugationDisplayRow(index: 0, pronoun: "yo", form: "tenGo", isImperative: false, isMarked: false)
    #expect(finite.copyText == "tengo")
    #expect(ConjugationDisplayRow.copyText(of: "me arrepIEnto") == "me arrepiento")
  }

  @Test func anEmptyCellCopiesNothing() {
    let empty = ConjugationDisplayRow(index: 0, pronoun: "yo", form: "", isImperative: false, isMarked: false)
    #expect(empty.copyText == nil)
  }
}
