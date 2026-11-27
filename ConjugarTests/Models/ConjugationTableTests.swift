//
//  ConjugationTableTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

@testable import Conjugar
import Testing

/// The verb page's order, second names, and articles. The order comes from docs/tense_frequency.md;
/// change it there first.
@Suite("ConjugationTable")
struct ConjugationTableTests {
  @Test func thePageOrderIsTheCountedOrder() {
    #expect(ConjugationTable.all.map(\.tense) == [
      .presenteDeIndicativo,
      .imperfectoDeIndicativo,
      .pretérito,
      .presenteDeSubjuntivo,
      .futuroDeIndicativo,
      .condicional,
      .imperfectoDeSubjuntivo1,
      .imperfectoDeSubjuntivo2,
      .futuroDeSubjuntivo,
      .imperativoPositivo,
      .imperativoNegativo,
      .perfectoDeIndicativo,
      .pluscuamperfectoDeIndicativo,
      .perfectoDeSubjuntivo,
      .pluscuamperfectoDeSubjuntivo1,
      .condicionalCompuesto,
      .pluscuamperfectoDeSubjuntivo2,
      .futuroPerfecto,
      .pretéritoAnterior,
      .futuroPerfectoDeSubjuntivo
    ])
  }

  @Test func everyConjugatedTenseHasOneCard() {
    let tenses = ConjugationTable.all.map(\.tense)
    #expect(tenses.count == DisplayTense.conjugatedTenses.count)
    #expect(Set(tenses) == Set(DisplayTense.conjugatedTenses))
  }

  @Test func theSimpleTensesComeFirst() {
    let compound = ConjugationTable.all.map(\.isCompound)
    #expect(compound == compound.sorted { !$0 && $1 })
    #expect(ConjugationTable.firstSimple == .presenteDeIndicativo)
    #expect(ConjugationTable.firstCompound == .perfectoDeIndicativo)
  }

  /// Only the verb page changes order. The map's file format depends on this one.
  @Test func theOtherScreensKeepTheirOrder() {
    #expect(DisplayTense.conjugatedTenses.prefix(3) == [.presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo])
  }

  @Test func theLandingMarksFollowThePage() {
    let marked = ConjugationTable.all.map(\.tense).compactMap(VerbView.section(markedBy:))
    #expect(marked == [.simple, .compound])
  }

  /// A search result names its cells in the order the page shows them. The page draws its rows
  /// from `VerbPageForms`, so walk those, with tú and vos both shown, and ask that each row is the
  /// next cell of `allCells`: the same tense, and the same pronoun and form. hablar's forms tell
  /// its imperatives' persons apart, which have no pronoun.
  @MainActor
  @Test func searchNamesFollowThePage() {
    let page = VerbPageForms(verb: "hablar", marks: [], secondSingular: .both)
    let drawn = page.sections.flatMap { section in
      section.rows.map { "\(section.tense) \($0.pronoun ?? "-") \($0.form)" }
    }
    let named = ConjugationMatch.allCells.filter { $0.personNumber != .none }.map { cell in
      let pronoun = cell.tense.isCommand ? "-" : cell.personNumber.pronoun
      let form = (try? TenseBridge.conjugate(infinitive: "hablar", tense: cell.tense, personNumber: cell.personNumber, pronoun: .written).get()) ?? ""
      return "\(cell.tense) \(pronoun) \(form)"
    }
    #expect(named == drawn)
  }

  @MainActor
  @Test func everyCardOpensItsOwnArticle() {
    for table in ConjugationTable.all {
      let article = table.article
      #expect(article != nil, "No article for \(table.tense)")
      #expect(article?.heading == table.tense.titleCaseName)
    }
  }

  @Test func everyCardHasAnEnglishSecondName() {
    for table in ConjugationTable.all {
      let names = table.secondNames(spanishInterface: false)
      #expect(names.first?.isSpanish == false, "\(table.tense)")
      #expect(names.allSatisfy { !$0.text.isEmpty })
    }
  }

  @Test func theEnglishInterfaceAddsTheRAENameWhereItDiffers() {
    #expect(ConjugationTable(tense: .pretérito).secondNames(spanishInterface: false) == [
      .init(text: "preterite", isSpanish: false),
      .init(text: "pretérito perfecto simple", isSpanish: true)
    ])
    #expect(ConjugationTable(tense: .presenteDeIndicativo).secondNames(spanishInterface: false) == [
      .init(text: "present", isSpanish: false)
    ])
  }

  @Test func theSpanishInterfaceGivesTheRAEAndBelloNames() {
    #expect(ConjugationTable(tense: .imperfectoDeIndicativo).secondNames(spanishInterface: true).map(\.text) == [
      "pretérito imperfecto", "copretérito"
    ])
    #expect(ConjugationTable(tense: .condicionalCompuesto).secondNames(spanishInterface: true).map(\.text) == ["antepospretérito"])
    let empty = ConjugationTable.all.filter { $0.secondNames(spanishInterface: true).isEmpty }.map(\.tense)
    #expect(empty == [.presenteDeIndicativo, .presenteDeSubjuntivo])
    #expect(ConjugationTable.all.allSatisfy { $0.secondNames(spanishInterface: true).allSatisfy(\.isSpanish) })
  }

  /// No second name repeats the heading it sits under.
  @Test func noSecondNameRepeatsItsHeading() {
    for table in ConjugationTable.all {
      for spanish in [false, true] {
        for name in table.secondNames(spanishInterface: spanish) {
          #expect(name.text.lowercased() != table.tense.displayName, "\(table.tense)")
        }
      }
    }
  }

  @Test func theArticleSignalKeepsItsWireName() {
    #expect(AnalyticsName.tapTenseArticle.rawValue == "tapTenseArticle")
  }
}
