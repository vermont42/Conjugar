//
//  ConjugationMapTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

// The conjugation map that ConjugationMapTool writes into the app bundle, and
// ConjugationMatch, which answers which cells of a verb a text is.
@Suite("ConjugationMap")
struct ConjugationMapTests {
  static func cell(_ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> ConjugationCell {
    ConjugationCell(tense: tense, personNumber: personNumber)
  }

  @Suite("The bundled map")
  struct Bundled {
    nonisolated static let bundledParadigms = ConjugationMap.bundled.paradigms()

    /// Every verb, in eight shards so that Swift Testing builds them in parallel.
    nonisolated static let shards: [[String]] = {
      let verbs = VerbMap.shared.entries.keys.sorted()
      return (0..<8).map { shard in verbs.enumerated().filter { $0.offset % 8 == shard }.map(\.element) }
    }()

    // The build phase regenerates the map when verbModelMap.xml or the tool's executable is
    // newer than it. This catches what that dependency analysis misses: a source the engine
    // depends on that the tool does not compile, so that the app and the map disagree.
    @Test(arguments: shards)
    func matchesAFreshBuild(of verbs: [String]) {
      var stale: [String] = []
      for infinitive in verbs {
        let fresh = ConjugationMap.oneWordCells.map { ConjugationMap.form(of: infinitive, at: $0) }
        if Self.bundledParadigms[infinitive] != fresh {
          stale.append(infinitive)
        }
      }
      #expect(!verbs.isEmpty)
      #expect(stale.isEmpty, "Stale or missing verbs, first few: \(stale.prefix(5))")
    }

    @Test func holdsEveryVerbAndForm() {
      #expect(Self.bundledParadigms.count == VerbMap.shared.count)
      // 254,328 on 2026-11-22, the count of the harness's forms_all.json. The floor allows for
      // verbs added later.
      #expect(ConjugationMap.bundled.entriesByForm.count >= 254_000)
    }

    // The measure is exact apart from case: an example's `token`, the form of its verb that the
    // example-uses pipeline found in the sentence, lowercased, must be a key whose entries name
    // that verb. No accent is folded and no pronoun is stripped. On 2026-11-22 it found 1,339
    // of 1,340 (99.9%). The one miss is especializar's token "especializarse", an infinitive
    // with an enclitic pronoun, which the reverse lookup strips.
    @Test func findsTheVerbOfNearlyEveryExampleByItsToken() {
      var exampleCount = 0
      var misses: [String] = []
      for infinitive in VerbMap.shared.entries.keys.sorted() {
        guard let example = ExampleData.example(for: infinitive) else {
          continue
        }
        exampleCount += 1
        if !ConjugationMap.bundled.entries(for: example.token).contains(where: { $0.infinitive == infinitive }) {
          misses.append("\(infinitive): \(example.token)")
        }
      }
      #expect(exampleCount >= 1_340)
      #expect(Double(exampleCount - misses.count) / Double(exampleCount) >= 0.99, "Missed \(misses.count) of \(exampleCount): \(misses.prefix(20))")
    }

    // The same, scanning every word of the sentence rather than trusting the token the
    // pipeline chose. Also 1,339 of 1,340 on 2026-11-22.
    @Test func findsTheVerbInNearlyEveryExampleSentence() {
      var exampleCount = 0
      var foundCount = 0
      for infinitive in VerbMap.shared.entries.keys {
        guard let example = ExampleData.example(for: infinitive) else {
          continue
        }
        exampleCount += 1
        let words = example.es.split { !$0.isLetter }.map(String.init)
        if words.contains(where: { word in ConjugationMap.bundled.entries(for: word).contains { $0.infinitive == infinitive } }) {
          foundCount += 1
        }
      }
      #expect(exampleCount >= 1_340)
      #expect(Double(foundCount) / Double(exampleCount) >= 0.99, "Found \(foundCount) of \(exampleCount)")
    }
  }

  @Suite("Entries")
  struct Entries {
    func cells(_ form: String, _ infinitive: String) -> [ConjugationCell] {
      ConjugationMap.bundled.entries(for: form).first { $0.infinitive == infinitive }?.cells ?? []
    }

    @Test func aFormSharedByTwoVerbsNamesBoth() {
      #expect(ConjugationMap.bundled.entries(for: "fue").map(\.infinitive) == ["ir", "ser"])
      #expect(cells("fue", "ir") == [ConjugationMapTests.cell(.pretérito, .thirdSingular)])
      #expect(cells("fue", "ser") == [ConjugationMapTests.cell(.pretérito, .thirdSingular)])
      #expect(ConjugationMap.bundled.entries(for: "siento").map(\.infinitive) == ["sentar", "sentir"])
      #expect(cells("ve", "ir") == [ConjugationMapTests.cell(.imperativoPositivo, .secondSingularTú)])
      #expect(cells("ve", "ver") == [
        ConjugationMapTests.cell(.presenteDeIndicativo, .thirdSingular),
        ConjugationMapTests.cell(.imperativoPositivo, .secondSingularTú),
        ConjugationMapTests.cell(.imperativoPositivo, .secondSingularVos)
      ])
      #expect(cells("sé", "saber") == [ConjugationMapTests.cell(.presenteDeIndicativo, .firstSingular)])
      #expect(cells("sé", "ser").contains(ConjugationMapTests.cell(.imperativoPositivo, .secondSingularTú)))
    }

    @Test func oneFormMayBeSeveralCellsOfAVerb() {
      #expect(cells("hablara", "hablar") == [
        ConjugationMapTests.cell(.imperfectoDeSubjuntivo1, .firstSingular),
        ConjugationMapTests.cell(.imperfectoDeSubjuntivo1, .thirdSingular)
      ])
    }

    @Test func accentsAndCaseAreAsWritten() {
      #expect(cells("hablo", "hablar") == [ConjugationMapTests.cell(.presenteDeIndicativo, .firstSingular)])
      #expect(cells("habló", "hablar") == [ConjugationMapTests.cell(.pretérito, .thirdSingular)])
      #expect(cells("Habló", "hablar") == [ConjugationMapTests.cell(.pretérito, .thirdSingular)])
      #expect(ConjugationMap.bundled.entries(for: "se").isEmpty)
      #expect(ConjugationMap.bundled.entries(for: "tuve").map(\.infinitive) == ["tener"])
    }

    @Test func vosFormsAreCells() {
      #expect(cells("tenés", "tener") == [ConjugationMapTests.cell(.presenteDeIndicativo, .secondSingularVos)])
      #expect(cells("sos", "ser") == [ConjugationMapTests.cell(.presenteDeIndicativo, .secondSingularVos)])
      #expect(cells("hablá", "hablar") == [ConjugationMapTests.cell(.imperativoPositivo, .secondSingularVos)])
    }

    @Test func nonFiniteFormsAreCells() {
      #expect(cells("hablar", "hablar") == [ConjugationMapTests.cell(.infinitivo, .none)])
      #expect(cells("hablando", "hablar") == [ConjugationMapTests.cell(.gerundio, .none)])
      #expect(cells("hecho", "hacer") == [ConjugationMapTests.cell(.participio, .none)])
    }

    @Test func reflexiveOnlyVerbsAreBare() {
      #expect(cells("arrepiento", "arrepentir") == [ConjugationMapTests.cell(.presenteDeIndicativo, .firstSingular)])
      #expect(ConjugationMap.bundled.entries(for: "arrepentirse").isEmpty)
    }

    @Test func compoundsAndNegativeCommandsHaveNoEntries() {
      #expect(ConjugationMap.bundled.entries(for: "he hablado").isEmpty)
      #expect(ConjugationMap.bundled.entries(for: "no hables").isEmpty)
      #expect(cells("hables", "hablar") == [
        ConjugationMapTests.cell(.presenteDeSubjuntivo, .secondSingularTú),
        ConjugationMapTests.cell(.presenteDeSubjuntivo, .secondSingularVos)
      ])
    }

    @Test func aDefectiveVerbsEmptySlotsHaveNoForm() {
      // A defective verb's formless slot is "-" in the file and nil here, never a guess.
      let defective = ConjugationMap.bundled.paradigms().filter { $0.value.contains(nil) }
      #expect(!defective.isEmpty)
      for (infinitive, forms) in defective {
        for (cell, form) in zip(ConjugationMap.oneWordCells, forms) where form == nil {
          let engineForm = try? TenseBridge.conjugate(infinitive: infinitive, tense: cell.tense, personNumber: cell.personNumber).get()
          #expect(engineForm?.isEmpty ?? true, "\(infinitive) \(cell.code)")
        }
      }
    }

    @Test func unknownTextHasNoEntries() {
      #expect(ConjugationMap.bundled.entries(for: "xyzzy").isEmpty)
      #expect(ConjugationMap.bundled.entries(for: "").isEmpty)
    }
  }

  @Suite("Format")
  struct Format {
    let map = ConjugationMap(paradigms: [
      "ir": ["ir", "yendo", "ido"] + Array(repeating: nil, count: ConjugationMap.oneWordCells.count - 3),
      "hablar": ["hablar", "hablando", nil] + Array(repeating: nil, count: ConjugationMap.oneWordCells.count - 3)
    ])

    @Test func writesOneLinePerVerbAsDeltas() {
      let dashes = Array(repeating: "-", count: ConjugationMap.oneWordCells.count - 3).joined(separator: "\t")
      #expect(map.text == "hablar\t1ndo\t-\t\(dashes)\nir\t2yendo\t1do\t\(dashes)")
    }

    @Test func readsWhatItWrites() throws {
      #expect(ConjugationMap(text: map.text) == map)
      #expect(try ConjugationMap(compressed: map.compressed()) == map)
    }

    @Test(arguments: [
      ("hablar", "hablo", "2o"),
      ("hablar", "hablar", "0"),
      ("ir", "fue", "2fue"),
      ("tener", "tuve", "4uve"),
      ("tener", "tenés", "2és"),
      ("hacer", "hecho", "4echo")
    ])
    func deltas(infinitive: String, form: String, delta: String) {
      #expect(ConjugationMap.delta(from: infinitive, to: form) == delta)
      #expect(ConjugationMap.form(from: infinitive, delta: delta) == form)
    }

    @Test func cellCodesRoundTrip() {
      for cell in ConjugationMatch.allCells {
        #expect(ConjugationCell(code: cell.code) == cell)
      }
      #expect(ConjugationCell(code: "ptts") == ConjugationMapTests.cell(.pretérito, .thirdSingular))
      #expect(ConjugationCell(code: "xx") == nil)
    }

    @Test func oneWordCellsAreTheSimpleCellsWithoutTheNegativeCommand() {
      // 3 non-finite + 9 simple tenses × 7 persons + 6 imperativo positivo persons.
      #expect(ConjugationMap.oneWordCells.count == 72)
      #expect(!ConjugationMap.oneWordCells.contains { $0.tense.isCompound || $0.tense == .imperativoNegativo })
    }
  }

  @Suite("Which cells a text is")
  struct Match {
    @Test func exactMatchingTellsAnAccentFromATense() {
      #expect(ConjugationMatch.cells(of: "hablar", equalTo: "hablo") == [ConjugationMapTests.cell(.presenteDeIndicativo, .firstSingular)])
      #expect(ConjugationMatch.cells(of: "hablar", equalTo: "habló") == [ConjugationMapTests.cell(.pretérito, .thirdSingular)])
    }

    @Test func foldingAccentsFindsBoth() {
      #expect(ConjugationMatch.cells(of: "hablar", equalTo: "hablo", accents: .folded) == [
        ConjugationMapTests.cell(.presenteDeIndicativo, .firstSingular),
        ConjugationMapTests.cell(.pretérito, .thirdSingular)
      ])
      #expect(ConjugationMatch.cells(of: "cantar", equalTo: "cante", accents: .folded).contains(ConjugationMapTests.cell(.pretérito, .firstSingular)))
    }

    @Test func foldingKeepsTheTilde() {
      #expect(ConjugationMatch.cells(of: "añadir", equalTo: "anado", accents: .folded).isEmpty)
      #expect(ConjugationMatch.cells(of: "añadir", equalTo: "añado", accents: .folded) == [ConjugationMapTests.cell(.presenteDeIndicativo, .firstSingular)])
      #expect(ConjugationMatch.foldingAccents("pingüino sintió año") == "pinguino sintio año")
    }

    @Test func compoundsAndNegativeCommandsAreCells() {
      #expect(ConjugationMatch.cells(of: "hablar", equalTo: "  Ha   hablado ") == [ConjugationMapTests.cell(.perfectoDeIndicativo, .thirdSingular)])
      #expect(ConjugationMatch.cells(of: "hablar", equalTo: "no hables") == [
        ConjugationMapTests.cell(.imperativoNegativo, .secondSingularTú),
        ConjugationMapTests.cell(.imperativoNegativo, .secondSingularVos)
      ])
    }

    @Test func theRaAndSeFormsAreDifferentCells() {
      #expect(ConjugationMatch.cells(of: "hablar", equalTo: "hablase") == [
        ConjugationMapTests.cell(.imperfectoDeSubjuntivo2, .firstSingular),
        ConjugationMapTests.cell(.imperfectoDeSubjuntivo2, .thirdSingular)
      ])
    }

    @Test func aReflexiveOnlyVerbMatchesWithOrWithoutItsPronoun() {
      let presenteYo = [ConjugationMapTests.cell(.presenteDeIndicativo, .firstSingular)]
      #expect(ConjugationMatch.cells(of: "arrepentir", equalTo: "me arrepiento") == presenteYo)
      #expect(ConjugationMatch.cells(of: "arrepentir", equalTo: "arrepiento") == presenteYo)
      #expect(ConjugationMatch.cells(of: "arrepentir", equalTo: "arrepentirse") == [ConjugationMapTests.cell(.infinitivo, .none)])
    }

    @Test func nothingMatchesNothing() {
      #expect(ConjugationMatch.cells(of: "hablar", equalTo: "   ").isEmpty)
      #expect(ConjugationMatch.cells(of: "hablar", equalTo: "comí").isEmpty)
      #expect(ConjugationMatch.cells(of: "xyzzar", equalTo: "xyzzo").isEmpty)
    }

    // The map and the matcher reach the engine separately; for a one-word form they must agree.
    @Test(arguments: ["ser", "ir", "tener", "hablar", "decir", "haber", "arrepentir"])
    func agreesWithTheMap(infinitive: String) {
      let paradigm = ConjugationMap.oneWordCells.map { ConjugationMap.form(of: infinitive, at: $0) }
      for (cell, form) in zip(ConjugationMap.oneWordCells, paradigm) {
        guard let form else {
          continue
        }
        let mapCells = ConjugationMap.bundled.entries(for: form).first { $0.infinitive == infinitive }?.cells ?? []
        let matchCells = ConjugationMatch.cells(of: infinitive, equalTo: form).filter(ConjugationMap.oneWordCells.contains)
        #expect(mapCells.contains(cell), "\(infinitive) \(cell.code) \(form)")
        #expect(mapCells == matchCells, "\(infinitive) \(form)")
      }
    }
  }
}
