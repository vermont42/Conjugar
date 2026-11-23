//
//  ReverseLookupTests.swift
//  ConjugarTests
//
//  Pins the reverse lookup: a form typed into the verb search finds its verb, and each result
//  names the cells it matched.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct ReverseLookupTests {
  nonisolated private static let entries = Array(VerbMap.shared.entries.values)

  private func matches(_ query: String) -> [VerbSearch.Match] {
    VerbSearch.matches(for: query, in: Self.entries)
  }

  private func infinitives(_ query: String) -> [String] {
    matches(query).map(\.entry.infinitive)
  }

  private func match(_ query: String, _ infinitive: String) -> VerbSearch.Match? {
    matches(query).first { $0.entry.infinitive == infinitive }
  }

  private func lines(_ query: String, _ infinitive: String, hiding hidden: Set<DisplayPersonNumber> = [.secondSingularVos]) -> [String] {
    MatchedForm.shown(match(query, infinitive)?.forms ?? [], hiding: hidden).map { $0.line(hiding: hidden) }
  }

  private static func cell(_ tense: DisplayTense, _ personNumber: DisplayPersonNumber = .none) -> ConjugationCell {
    ConjugationCell(tense: tense, personNumber: personNumber)
  }

  /// Each query, and the verbs that must come first, in order.
  @Test(arguments: [
    ("fue", ["ser", "ir"]),
    ("fui", ["ser", "ir"]),
    ("ve", ["ir", "ver"]),
    ("siento", ["sentir", "sentar"]),
    ("hablo", ["hablar"]),
    ("dímelo", ["decir"]),
    ("dimelo", ["decir"]),
    ("dámelo", ["dar"]),
    ("levántate", ["levantar"]),
    ("diciéndole", ["decir"]),
    ("me levanto", ["levantar"]),
    ("se lo dije", ["decir"]),
    ("no hables", ["hablar"]),
    ("he hablado", ["hablar"]),
    ("habría dicho", ["decir"]),
    ("habria dicho", ["decir"]),
    ("yo hablo", ["hablar"]),
    ("hablás", ["hablar"]),
    ("tenés", ["tener"]),
    ("sos", ["ser"]),
    ("hecha", ["hacer"]),
    ("dichas", ["decir"]),
    ("vámonos", ["ir"]),
    ("levantaos", ["levantar"]),
    ("idos", ["ir"]),
    ("démoselo", ["dar"]),
    ("especializarse", ["especializar"]),
    ("estoy hablando", ["hablar"]),
    ("voy a comer", ["comer"]),
    ("esta", ["estar"]),
    ("rio", ["reír"])
  ])
  func aFormFindsItsVerbFirst(query: String, expected: [String]) {
    #expect(Array(infinitives(query).prefix(expected.count)) == expected)
  }

  @Test func rotosFindsRomperAsAParticiple() {
    #expect(lines("rotos", "romper") == ["rotos: Participio"])
    // rotar has no form "rotos", nor a participle that strips to it.
    #expect(match("rotos", "rotar") == nil)
    // "rota" is rotar's form and, with its ending, romper's participle; both are found.
    #expect(lines("rota", "romper") == ["rota: Participio"])
    #expect(lines("rota", "rotar").first == "rota: Presente de Indicativo (él) · Imperativo Positivo (tú)")
  }

  @Test func aSharedFormNamesBothVerbs() {
    #expect(lines("fue", "ir") == ["fue: Pretérito (él)"])
    #expect(lines("fue", "ser") == ["fue: Pretérito (él)"])
    #expect(lines("ve", "ir") == ["ve: Imperativo Positivo (tú)"])
  }

  @Test func anAccentlessFormNamesTheLiteralCellThenTheFoldedOne() throws {
    let hablar = try #require(match("hablo", "hablar"))
    #expect(hablar.kind == .conjugation)
    #expect(hablar.forms.map { $0.line() } == ["hablo: Presente de Indicativo (yo)", "habló: Pretérito (él)"])
    #expect(hablar.forms.map(\.isFolded) == [false, true])
  }

  @Test func aFormOnlyFoldingFindsIsAFoldedConjugation() throws {
    let estar = try #require(match("esta", "estar"))
    #expect(estar.kind == .foldedConjugation)
    #expect(estar.forms.first?.text == "está")
  }

  @Test func accentlessSeAndDeFindTheirVerbsFirst() {
    #expect(Set(infinitives("se").prefix(2)) == ["saber", "ser"])
    #expect(infinitives("de").first == "dar")
    #expect(lines("de", "dar") == ["dé: Presente de Subjuntivo (yo, él) · Imperativo Positivo (usted)"])
  }

  @Test func comeFindsComerAfterTheExactGlossSenses() throws {
    let found = infinitives("come")
    #expect(Array(found.prefix(4)) == ["llegar", "venir", "acudir", "comer"])
    let comer = try #require(match("come", "comer"))
    #expect(comer.forms.first?.line() == "come: Presente de Indicativo (él) · Imperativo Positivo (tú)")
  }

  @Test func aCommandsThirdPersonsAreUstedAndUstedes() {
    #expect(lines("hablen", "hablar") == ["hablen: Presente de Subjuntivo (ellas) · Imperativo Positivo (ustedes)"])
  }

  @Test func encliticsNameTheCommandWithItsPronouns() {
    #expect(lines("dímelo", "decir") == ["dímelo: Imperativo Positivo (tú)"])
    #expect(lines("levántate", "levantar") == ["levántate: Imperativo Positivo (tú)"])
    #expect(lines("diciéndole", "decir") == ["diciéndole: Gerundio"])
    #expect(lines("decírselo", "decir") == ["decírselo: Infinitivo"])
  }

  @Test func anEncliticTypedWithoutItsAccentIsFolded() throws {
    let decir = try #require(match("dimelo", "decir"))
    #expect(decir.kind == .foldedConjugation)
    #expect(decir.forms.first?.text == "dímelo")
  }

  @Test func dimeIsDecirsCommandNotDarsPreterite() {
    // di is decir's tú command and dar's yo pretérito, but only a command takes an enclitic.
    #expect(match("dime", "dar") == nil)
    #expect(lines("dime", "decir") == ["dime: Imperativo Positivo (tú)"])
  }

  @Test func aNegativeCommandIsNamedAsOne() {
    #expect(lines("no hables", "hablar") == ["no hables: Imperativo Negativo (tú)"])
    // "no" before a form that is no negative command is dropped.
    #expect(lines("no hablo", "hablar").first == "hablo: Presente de Indicativo (yo)")
  }

  @Test func compoundsAreConfirmedByTheVerbsOwnCells() {
    #expect(lines("he hablado", "hablar") == ["he hablado: Perfecto de Indicativo (yo)"])
    #expect(lines("habria dicho", "decir") == ["habría dicho: Condicional Compuesto (yo, él)"])
    #expect(lines("yo habría dicho", "decir") == ["habría dicho: Condicional Compuesto (yo)"])
    #expect(lines("se lo he dicho", "decir") == ["he dicho: Perfecto de Indicativo (yo)"])
  }

  @Test func aSubjectPronounNarrowsThePersons() {
    #expect(lines("ella hable", "hablar") == ["hable: Presente de Subjuntivo (él) · Imperativo Positivo (usted)"])
    // A pronoun that fits no cell narrows nothing.
    #expect(lines("yo hablamos", "hablar").first == "hablamos: Presente de Indicativo (nosotros) · Pretérito (nosotros)")
  }

  @Test func aReflexiveOnlyVerbMatchesWithItsPronoun() {
    #expect(lines("me arrepiento", "arrepentir") == ["me arrepiento: Presente de Indicativo (yo)"])
    #expect(lines("arrepiéntete", "arrepentir") == ["arrepiéntete: Imperativo Positivo (tú)"])
  }

  @Test func vosFormsAreNamedAsVos() {
    // The tú form one accent away follows, as habló follows hablo.
    #expect(lines("hablás", "hablar") == ["hablás: Presente de Indicativo (vos)", "hablas: Presente de Indicativo (tú)"])
    #expect(lines("sos", "ser") == ["sos: Presente de Indicativo (vos)"])
  }

  @Test func vosIsLeftOutWhereTúSharesTheFormUnlessThePageShowsIt() {
    #expect(lines("hablaste", "hablar") == ["hablaste: Pretérito (tú)"])
    #expect(lines("hablaste", "hablar", hiding: []) == ["hablaste: Pretérito (tú, vos)"])
    #expect(lines("hablaste", "hablar", hiding: [.secondSingularTú]) == ["hablaste: Pretérito (vos)"])
  }

  @Test func participlesWithEndingsAreReadAsTheParticiple() {
    #expect(lines("hecha", "hacer") == ["hecha: Participio"])
    #expect(lines("dichas", "decir") == ["dichas: Participio"])
    // toma less its -a plus -o is tomo, which is no participle.
    #expect(match("toma", "tomar")?.forms.allSatisfy { $0.cells.allSatisfy { $0.tense != .participio } } == true)
  }

  @Test func aPeriphrasisFindsTheVerbOfItsNonFiniteWord() {
    #expect(lines("estoy hablando", "hablar") == ["hablando: Gerundio"])
    #expect(lines("voy a comer", "comer") == ["comer: Infinitivo"])
  }

  @Test func anInfinitiveIsStillAnInfinitiveMatch() {
    #expect(match("hablar", "hablar")?.kind == .exactInfinitive)
    #expect(match("hablar", "hablar")?.forms.isEmpty == true)
  }

  @Test func theJudgedQueriesHold() {
    #expect(Array(infinitives("go").prefix(1)) == ["ir"])
    #expect(Array(infinitives("be").prefix(2)) == ["ser", "estar"])
    #expect(infinitives("listen").first == "escuchar")
    #expect(Array(infinitives("sonar").prefix(2)) == ["sonar", "soñar"])
  }

  @Test(arguments: ["xyzzyq", "no", "lo", "lo la", "levantar(se)"])
  func nonsenseAndPronounsAloneFindNoForm(query: String) {
    #expect(FormLookup.forms(for: query).isEmpty)
  }

  @Test func aVerbOutsideTheEntriesIsNotFound() {
    let others = Self.entries.filter { $0.infinitive != "ser" }
    #expect(!VerbSearch.matches(for: "fue", in: others).contains { $0.entry.infinitive == "ser" })
  }

  @Test func formsComeInLiteralThenPageOrder() {
    let found = FormLookup.forms(for: "hable")["hablar"] ?? []
    #expect(found.map(\.text) == ["hable", "hablé"])
  }

  @Test(arguments: [
    (["me", "lo"], "di", DisplayTense.imperativoPositivo, DisplayPersonNumber.secondSingularTú, "dímelo"),
    (["nos"], "vamos", .imperativoPositivo, .firstPlural, "vámonos"),
    (["se", "lo"], "demos", .imperativoPositivo, .firstPlural, "démoselo"),
    (["lo"], "hagamos", .imperativoPositivo, .firstPlural, "hagámoslo"),
    (["os"], "levantad", .imperativoPositivo, .secondPlural, "levantaos"),
    (["os"], "id", .imperativoPositivo, .secondPlural, "idos"),
    (["lo"], "haced", .imperativoPositivo, .secondPlural, "hacedlo"),
    (["le"], "diciendo", .gerundio, .none, "diciéndole"),
    (["se", "lo"], "decir", .infinitivo, .none, "decírselo")
  ])
  func attachJoinsPronounsAsSpanishDoes(clitics: [String], form: String, tense: DisplayTense, person: DisplayPersonNumber, expected: String) {
    #expect(FormLookup.attach(clitics, to: form, at: Self.cell(tense, person)) == expected)
  }

  @Test func aFoldedFormOfAHiddenPersonIsNotNamed() {
    #expect(lines("ve", "ver") == ["ve: Presente de Indicativo (él) · Imperativo Positivo (tú)"])
    #expect(lines("ve", "ver", hiding: []) == ["ve: Presente de Indicativo (él) · Imperativo Positivo (tú, vos)"])
    // A vos form typed without its accent is the only form, and stays.
    #expect(lines("tenes", "tener") == ["tenés: Presente de Indicativo (vos)"])
  }

  @Test func theMarksAreTheShownCells() throws {
    let form = try #require(match("hablaste", "hablar")?.forms.first)
    #expect(Set(form.shownCells(hiding: [.secondSingularVos])) == [Self.cell(.pretérito, .secondSingularTú)])
  }

  @Test func aMisspelledFormGuessesItsVerb() throws {
    #expect(matches("tenjo").isEmpty)
    let guess = try #require(VerbSearch.guess(for: "tenjo", in: Self.entries))
    #expect(guess.entry.infinitive == "tener")
    #expect(guess.form?.text == "tengo")
  }

  @Test(arguments: [("hablr", "hablar"), ("tenr", "tener"), ("hbalar", "hablar")])
  func anInfinitiveWinsAGuessItTies(query: String, expected: String) {
    let guess = VerbSearch.guess(for: query, in: Self.entries)
    #expect(guess?.entry.infinitive == expected)
    #expect(guess?.form == nil)
  }

  @Test(arguments: ["xyzzyq", "qqqq"])
  func nonsenseGuessesNothing(query: String) {
    #expect(VerbSearch.guess(for: query, in: Self.entries) == nil)
  }

  // Every example's token, typed into the search as it stands, finds the example's verb among
  // the results. A lookup in the map alone misses especializarse, an infinitive with an
  // enclitic; the search finds it.
  @Test func theSearchFindsTheVerbOfEveryExampleByItsToken() {
    var exampleCount = 0
    var misses: [String] = []
    for infinitive in VerbMap.shared.entries.keys.sorted() {
      guard let example = ExampleData.example(for: infinitive) else {
        continue
      }
      exampleCount += 1
      // FormLookup is the part of the search that finds forms, and costs a fraction of a full
      // search, which the misses alone go through.
      let foundAsForm = FormLookup.forms(for: example.token)[infinitive] != nil
      if !foundAsForm, !matches(example.token).contains(where: { $0.entry.infinitive == infinitive }) {
        misses.append("\(infinitive): \(example.token)")
      }
    }
    #expect(exampleCount >= 1_340)
    #expect(misses.isEmpty, "Missed \(misses.count) of \(exampleCount): \(misses.prefix(20))")
  }
}
