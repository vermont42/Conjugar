//
//  VerbLookupTests.swift
//  ConjugarTests
//
//  Pins the Look Up a Verb shortcut's answers and destinations (browse plan, Phase 11). The
//  answers' English wording assumes the test run's language is English.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct VerbLookupTests {
  nonisolated private static let entries = Array(VerbMap.shared.entries.values)
  nonisolated private static let hidingVos: Set<DisplayPersonNumber> = [.secondSingularVos]

  private func lookUp(_ word: String, hiding hidden: Set<DisplayPersonNumber> = hidingVos) -> VerbLookup {
    VerbLookup(word: word, entries: Self.entries, hiding: hidden)
  }

  private func entry(_ infinitive: String) throws -> VerbMapEntry {
    try #require(VerbMap.shared.entry(for: infinitive))
  }

  /// The verbs each finding names, in order.
  private func infinitives(_ lookup: VerbLookup) -> [String] {
    lookup.findings.compactMap { finding in
      switch finding {
      case .verb(let entry), .form(_, let entry), .otherMatches(let entry, _), .guess(let entry, _):
        return entry.infinitive
      case .nothing:
        return nil
      }
    }
  }

  private func searchLink(_ text: String) -> URL? {
    URL.searchDeeplink(text: text, source: .lookup)
  }

  // MARK: - One verb answers: its page

  @Test func anInfinitiveOpensItsPageUnmarked() throws {
    let lookup = lookUp("tener")
    #expect(lookup.findings == [.verb(try entry("tener"))])
    #expect(lookup.destination == URL.verbDeeplink("tener", source: .lookup))
  }

  @Test func anInfinitiveIsAnsweredWithItsGlossAndKeyConjugations() {
    #expect(lookUp("tener").answer() == "tener, “have”: tengo · tuve · tendré · tenido")
  }

  @Test func aReflexiveOnlyVerbIsNamedWithItsPronoun() throws {
    let lookup = lookUp("arrepentirse")
    #expect(lookup.findings == [.verb(try entry("arrepentir"))])
    #expect(lookup.answer().hasPrefix("arrepentirse, “"))
    #expect(lookup.answer().hasSuffix(": me arrepiento · me arrepentí · me arrepentiré · arrepentido"))
    #expect(lookup.destination == URL.verbDeeplink("arrepentir", source: .lookup))
  }

  @Test func anInfinitiveWithoutItsTildeStillAnswers() throws {
    #expect(lookUp("anadir").findings == [.verb(try entry("añadir"))])
  }

  @Test func aFormOfOneVerbOpensItsPageMarked() {
    let lookup = lookUp("tuve")
    #expect(infinitives(lookup) == ["tener"])
    #expect(lookup.answer() == "tuve: Pretérito (yo) of tener")
    #expect(lookup.destination == URL.verbDeeplink("tener", source: .lookup, match: "tuve"))
  }

  @MainActor
  @Test func theLinksMatchMarksTheFormsCells() throws {
    let router = AppRouter()
    router.handle(url: try #require(lookUp("tuve").destination))
    #expect(router.pendingVerb?.infinitive == "tener")
    #expect(router.pendingVerb?.source == .lookup)
    #expect(router.pendingVerb?.marks == [ConjugationCell(tense: .pretérito, personNumber: .firstSingular)])
  }

  // "hablo" is also one accent from habló, which the verb list names on a second line. The
  // lookup names only what was typed, but still opens the one verb.
  @Test func aLiteralFormLeavesOutItsFoldedNeighbor() {
    let lookup = lookUp("hablo")
    #expect(lookup.answer() == "hablo: Presente de Indicativo (yo) of hablar")
    #expect(lookup.destination == URL.verbDeeplink("hablar", source: .lookup, match: "hablo"))
  }

  @Test func theHiddenSecondSingularIsLeftOutOfTheCells() {
    #expect(lookUp("hablaste").answer() == "hablaste: Pretérito (tú) of hablar")
    #expect(lookUp("hablaste", hiding: []).answer() == "hablaste: Pretérito (tú, vos) of hablar")
  }

  // Pronouns the lookup strips leave a form of one verb, so they do not cost the page. The link
  // carries the bare form of the cell, which the page can mark.
  @Test(arguments: [
    ("dímelo", "decir", "di"),
    ("levántate", "levantar", "levanta"),
    ("se lo dije", "decir", "dije"),
    ("hecha", "hacer", "hecho")
  ])
  func strippedPronounsAndEndingsStillOpenOnePage(word: String, infinitive: String, match: String) {
    let lookup = lookUp(word)
    #expect(infinitives(lookup) == [infinitive])
    #expect(lookup.destination == URL.verbDeeplink(infinitive, source: .lookup, match: match))
  }

  @Test func aFoldedFormAnswersWhenNothingLiteralDoes() {
    let lookup = lookUp("dimelo")
    #expect(lookup.answer() == "dímelo: Imperativo Positivo (tú) of decir")
    #expect(lookup.destination == URL.verbDeeplink("decir", source: .lookup, match: "di"))
  }

  @Test func aCompoundTenseOpensItsPage() {
    let lookup = lookUp("he hablado")
    #expect(lookup.answer() == "he hablado: Perfecto de Indicativo (yo) of hablar")
    #expect(lookup.destination == URL.verbDeeplink("hablar", source: .lookup, match: "he hablado"))
  }

  @Test func anEnglishSenseOfOneVerbOpensItsPage() {
    let lookup = lookUp("refuel")
    #expect(infinitives(lookup) == ["repostar"])
    #expect(lookup.answer().hasPrefix("repostar, “refuel”: "))
    #expect(lookup.destination == URL.verbDeeplink("repostar", source: .lookup))
  }

  // "eat" is comer's, and also papear's and manducar's.
  @Test func anEnglishSenseOfSeveralVerbsOpensTheSearch() {
    let lookup = lookUp("eat")
    #expect(infinitives(lookup).first == "comer")
    #expect(infinitives(lookup).count > 1)
    #expect(lookup.answer().hasPrefix("comer, “eat”: como · comí · comeré · comido\n"))
    #expect(lookup.destination == searchLink("eat"))
  }

  // MARK: - Several verbs answer: the search

  @Test func aFormOfTwoVerbsNamesBothAndOpensTheSearch() {
    let lookup = lookUp("fue")
    #expect(infinitives(lookup) == ["ser", "ir"])
    #expect(lookup.answer() == "fue: Pretérito (él) of ser\nfue: Pretérito (él) of ir")
    #expect(lookup.destination == searchLink("fue"))
  }

  // Josh's ranking puts an exact English sense above a form, so the lookup does too: "come" is
  // not only comer's.
  @Test func anEnglishSenseCountsAgainstAForm() {
    let lookup = lookUp("come")
    let named = infinitives(lookup)
    #expect(named.count == VerbLookup.maxNamedVerbs || named.contains("comer"))
    #expect(named.first == "llegar")
    #expect(lookup.destination == searchLink("come"))
  }

  @Test func accentlessSeNamesSaberAndSer() {
    let lookup = lookUp("se")
    #expect(Set(infinitives(lookup)) == ["saber", "ser"])
    #expect(lookup.answer().contains("sé: Presente de Indicativo (yo) of saber"))
    #expect(lookup.destination == searchLink("se"))
  }

  @Test func noMoreThanFourVerbsAreNamed() {
    #expect(infinitives(lookUp("have")).count <= VerbLookup.maxNamedVerbs)
  }

  // MARK: - No verb answers

  @Test func aPrefixOfOneVerbNamesItAndOpensTheSearch() throws {
    let lookup = lookUp("habl")
    #expect(lookup.findings == [.otherMatches(first: try entry("hablar"), count: 1)])
    #expect(lookup.answer() == "Conjugar has no verb or conjugation spelled “habl”, but one verb matches: hablar, “speak”.")
    #expect(lookup.destination == searchLink("habl"))
  }

  @Test func aPrefixOfSeveralVerbsCountsThemAndNamesTheFirst() throws {
    let lookup = lookUp("cant")
    guard case let .otherMatches(first, count) = try #require(lookup.findings.first) else {
      Issue.record("Expected other matches, got \(lookup.findings)")
      return
    }
    #expect(first.infinitive == "cantar")
    #expect(count > 1)
    #expect(lookup.answer().hasPrefix("Conjugar has no verb or conjugation spelled “cant”, but \(count) verbs match. The first is cantar, “"))
    #expect(lookup.destination == searchLink("cant"))
  }

  @Test func aMisspellingIsAnsweredWithTheGuess() throws {
    let lookup = lookUp("hablr")
    #expect(lookup.findings == [.guess(try entry("hablar"), form: nil)])
    #expect(lookup.answer() == "Conjugar has no verb or conjugation spelled “hablr”. Perhaps you meant hablar.")
    #expect(lookup.destination == searchLink("hablr"))
  }

  @Test func aMisspelledFormIsAnsweredWithItsForm() {
    #expect(lookUp("tenjo").answer() == "Conjugar has no verb or conjugation spelled “tenjo”. Perhaps you meant tengo, of tener.")
  }

  @Test func nonsenseFindsNothing() {
    let lookup = lookUp("xyzzyq")
    #expect(lookup.findings == [.nothing])
    #expect(lookup.answer() == "Conjugar has no verb or conjugation spelled “xyzzyq”.")
    #expect(lookup.destination == searchLink("xyzzyq"))
  }

  @Test func theWordIsTrimmed() {
    let lookup = lookUp("  tuve \n")
    #expect(lookup.word == "tuve")
    #expect(lookup.destination == URL.verbDeeplink("tener", source: .lookup, match: "tuve"))
  }

  // MARK: - The intents

  @MainActor
  @Test func theLookupResultIntentIsHiddenAndOpensTheApp() {
    #expect(!OpenLookupResultIntent.isDiscoverable)
    #expect(OpenLookupResultIntent.openAppWhenRun)
  }
}
