//
//  VerbFamiliesTests.swift
//  ConjugarTests
//
//  The hand-curated verb lists in `VerbFamilies` are an oracle for the quiz's draw, which
//  judges irregularity per cell from the engine (`QuizDraw.isIrregular(_:in:)`): every verb a
//  list names as irregular in a tense, the engine marks irregular there, and every listed
//  regular verb of a plain regular class it marks regular everywhere. The lists are also
//  pinned to `VerbMap.shared`:
//
//   • every listed verb must resolve in the map (an unmapped verb falls back to a
//     regular model and drills a nonexistent form — this is how "manecer" survived);
//   • a `regular…` list's verbs must actually be that regular conjugation class
//     (-ar → 1, -er → 2, -ir → 3), so an irregular verb like "helar" (4A) or "andar"
//     (35) can't masquerade as a regular drill;
//   • no list repeats an entry (a duplicate skews the round-robin cycle).
//
//  The engine and map are `nonisolated`, so this suite is too (it touches no MainActor
//  state) and stays parallel.
//

import Testing
@testable import Conjugar

@Suite("VerbFamilies ↔ VerbMap guard-rail")
struct VerbFamiliesTests {
  static let map = VerbMap.shared

  /// The leading conjugation-class family: the integer prefix of a class number, so
  /// "1", "1-1" (orthographic -ar) and "1-4" (z→c -ar) all read as 1; "4A" reads as 4.
  static func leadingClass(_ classNumber: String) -> Int? {
    Int(classNumber.prefix { $0.isNumber })
  }

  /// Every quiz list, labeled for diagnostics.
  static let allLists: [(name: String, verbs: [String])] = [
    ("regularArVerbs", VerbFamilies.regularArVerbs),
    ("regularErVerbs", VerbFamilies.regularErVerbs),
    ("regularIrVerbs", VerbFamilies.regularIrVerbs),
    ("irregularPresenteDeIndicativoVerbs", VerbFamilies.irregularPresenteDeIndicativoVerbs),
    ("irregularImperfectivoVerbs", VerbFamilies.irregularImperfectivoVerbs),
    ("irregularPreteritoVerbs", VerbFamilies.irregularPreteritoVerbs),
    ("irregularRaizFuturaVerbs", VerbFamilies.irregularRaizFuturaVerbs),
    ("irregularPresenteDeSubjuntivoVerbs", VerbFamilies.irregularPresenteDeSubjuntivoVerbs),
    ("irregularTuImperativoVerbs", VerbFamilies.irregularTuImperativoVerbs),
    ("irregularVosImperativoVerbs", VerbFamilies.irregularVosImperativoVerbs),
    ("irregularParticipioVerbs", VerbFamilies.irregularParticipioVerbs),
    ("irregularGerundioVerbs", VerbFamilies.irregularGerundioVerbs)
  ]

  // An unmapped verb conjugates on the regular fallback model, so a quiz can demand
  // a form of a verb that does not exist ("manecer" → "maneza").
  @Test("every quiz-list verb resolves in VerbMap")
  func everyVerbResolves() {
    var unmapped: [String] = []
    for list in Self.allLists {
      for verb in list.verbs where Self.map.entry(for: verb) == nil {
        unmapped.append("\(list.name): \(verb)")
      }
    }
    #expect(unmapped.isEmpty, "unmapped verbs: \(unmapped)")
  }

  static let regularLists: [(name: String, verbs: [String], expectedClass: Int)] = [
    ("regularArVerbs", VerbFamilies.regularArVerbs, 1),
    ("regularErVerbs", VerbFamilies.regularErVerbs, 2),
    ("regularIrVerbs", VerbFamilies.regularIrVerbs, 3)
  ]

  // A verb here is quizzed as a *regular* drill (including via allRegularVerbs, which
  // feeds pretérito/imperfecto/… questions), so an irregular verb misfiled here asks a
  // learner for an irregular form they were promised would be regular ("helar" → hiela,
  // "andar" → anduve).
  @Test("regular lists contain only their own regular conjugation class")
  func regularListsAreRegular() {
    var misfiled: [String] = []
    for list in Self.regularLists {
      for verb in list.verbs {
        guard let entry = Self.map.entry(for: verb) else { continue }  // covered by everyVerbResolves
        if Self.leadingClass(entry.classNumber) != list.expectedClass {
          misfiled.append("\(list.name): \(verb) is class \(entry.classNumber)")
        }
      }
    }
    #expect(misfiled.isEmpty, "misfiled regular verbs: \(misfiled)")
  }

  // A duplicate ("esconder" twice) over-weights that verb in the round-robin cycle.
  @Test("no quiz list repeats an entry")
  func noDuplicates() {
    var duplicated: [String] = []
    for list in Self.allLists {
      let seen = Set(list.verbs)
      if seen.count != list.verbs.count {
        let dupes = list.verbs.filter { verb in list.verbs.filter { $0 == verb }.count > 1 }
        duplicated.append("\(list.name): \(Set(dupes).sorted())")
      }
    }
    #expect(duplicated.isEmpty, "lists with duplicate entries: \(duplicated)")
  }

  /// Each irregular list, with the cells its tense asks.
  static let irregularLists: [(name: String, verbs: [String], cells: [ConjugationCell])] = {
    let persons: [DisplayPersonNumber] = [.firstSingular, .secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    func cells(_ tense: DisplayTense) -> [ConjugationCell] {
      persons.map { ConjugationCell(tense: tense, personNumber: $0) }
    }
    return [
      ("irregularPresenteDeIndicativoVerbs", VerbFamilies.irregularPresenteDeIndicativoVerbs, cells(.presenteDeIndicativo)),
      ("irregularImperfectivoVerbs", VerbFamilies.irregularImperfectivoVerbs, cells(.imperfectoDeIndicativo)),
      ("irregularPreteritoVerbs", VerbFamilies.irregularPreteritoVerbs, cells(.pretérito)),
      ("irregularRaizFuturaVerbs", VerbFamilies.irregularRaizFuturaVerbs, cells(.futuroDeIndicativo)),
      ("irregularPresenteDeSubjuntivoVerbs", VerbFamilies.irregularPresenteDeSubjuntivoVerbs, cells(.presenteDeSubjuntivo)),
      ("irregularTuImperativoVerbs", VerbFamilies.irregularTuImperativoVerbs, [ConjugationCell(tense: .imperativoPositivo, personNumber: .secondSingularTú)]),
      ("irregularVosImperativoVerbs", VerbFamilies.irregularVosImperativoVerbs, [ConjugationCell(tense: .imperativoPositivo, personNumber: .secondSingularVos)]),
      ("irregularParticipioVerbs", VerbFamilies.irregularParticipioVerbs, [ConjugationCell(tense: .participio, personNumber: .none)]),
      ("irregularGerundioVerbs", VerbFamilies.irregularGerundioVerbs, [ConjugationCell(tense: .gerundio, personNumber: .none)])
    ]
  }()

  // ser's vos command, sé, is its stem s- with the regular vos ending -é, so the engine rightly
  // marks nothing in it.
  static let regularLookingIrregulars: Set<String> = ["irregularVosImperativoVerbs: ser"]

  @Test("the quiz's draw judges every listed irregular verb irregular in its tense")
  func theDrawFindsTheIrregularVerbs() {
    var missed: [String] = []
    for list in Self.irregularLists {
      for verb in list.verbs where !list.cells.contains(where: { QuizDraw.isIrregular(verb, in: $0) == true }) {
        missed.append("\(list.name): \(verb)")
      }
    }
    #expect(Set(missed) == Self.regularLookingIrregulars, "judged regular: \(missed)")
  }

  // A listed regular verb of an orthographic class (buscar, 1-1) is irregular where its spelling
  // changes (busqué), as the quiz counts it, so only the plain classes are held to every cell.
  @Test("the quiz's draw judges every plainly regular listed verb regular everywhere")
  func theDrawFindsTheRegularVerbs() {
    let plainClasses: Set<String> = ["1", "2", "3"]
    var marked: [String] = []
    for verb in VerbFamilies.allRegularVerbs where plainClasses.contains(Self.map.entry(for: verb)?.classNumber ?? "") {
      for entry in QuizLevel.advanced.pool {
        let persons: [DisplayPersonNumber] = entry.tense == .gerundio ? [.none] : [.firstSingular, .secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
        for person in persons where QuizDraw.isIrregular(verb, in: ConjugationCell(tense: entry.tense, personNumber: person)) == true {
          marked.append("\(verb) \(entry.tense) \(person)")
        }
      }
    }
    #expect(marked.isEmpty, "judged irregular: \(marked.prefix(20))")
  }
}
