//
//  VerbFamiliesTests.swift
//  ConjugarTests
//
//  A guard-rail for the hand-curated quiz verb lists in `VerbFamilies`. `Quiz`
//  builds questions from these lists and the engine conjugates whatever it is given,
//  so a bad entry silently teaches wrong Spanish. `QuizTests` can't catch it — it
//  compares the quiz's answer to the same engine's output, verifying self-consistency,
//  not linguistic truth. These tests instead pin the lists to `VerbMap.shared`:
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

  // MARK: - (a) Every listed verb resolves in the map

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

  // MARK: - (b) Regular lists really are that regular class

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

  // MARK: - (c) No list repeats an entry

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
}
