//
//  VerbPageForms.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// The forms a verb's page shows: the three header forms and a card of rows for each tense, in the
/// page's order. `VerbView` builds one when it is pushed.
struct VerbPageForms {
  let participio: String
  let gerundio: String
  /// The future stem with its hyphen, "tendr-".
  let raizFutura: String
  let sections: [ConjugationSection]
  /// Whether the verb itself has a red letter, which the engine marks by writing it in uppercase:
  /// in a simple tense or a header form. A compound tense does not count, because its auxiliary is
  /// marked on every verb's page (hE hablado). `RedLettersTip` appears only where this is true.
  let hasRedLetters: Bool

  /// The sections for `secondSingular`, the learner's choice of tú, vos, or both. A page opened
  /// from a search for a vos form (hablás) shows vos as well as tú, whatever the choice, so that
  /// the mark has a row to sit on; likewise tú for a learner who chose vos.
  init(verb: String, marks: Set<ConjugationCell>, secondSingular: SecondSingularBrowse) {
    participio = Self.form(verb, .participio, .none)
    gerundio = Self.form(verb, .gerundio, .none)
    raizFutura = Self.form(verb, .raízFutura, .none) + "-"
    let sections = Self.sections(verb: verb, marks: marks, secondSingular: secondSingular)
    self.sections = sections
    let simpleForms = sections.filter { !$0.table.isCompound }.flatMap { $0.rows.map(\.form) }
    hasRedLetters = (simpleForms + [participio, gerundio, raizFutura]).contains { $0.contains(where: \.isUppercase) }
  }

  /// The first card with a marked row, in the page's own order, which the page scrolls to when it
  /// opens. Nil when nothing is marked or only the header is.
  var markedSectionID: String? {
    sections.first { $0.rows.contains(where: \.isMarked) }?.id
  }

  /// One section per tense, each a pronoun-ordered list of rows: yo where the tense has one, the
  /// second singular as chosen, then the plural persons, with a defective verb's formless slot
  /// blank.
  private static func sections(verb: String, marks: Set<ConjugationCell>, secondSingular: SecondSingularBrowse) -> [ConjugationSection] {
    var secondSingular = secondSingular
    let hidden: [SecondSingularBrowse: DisplayPersonNumber] = [.tu: .secondSingularVos, .vos: .secondSingularTú]
    if let hiddenPerson = hidden[secondSingular], marks.contains(where: { $0.personNumber == hiddenPerson }) {
      secondSingular = .both
    }
    return ConjugationTable.all.map { table in
      let tense = table.tense
      let isImperative = tense == .imperativoPositivo || tense == .imperativoNegativo
      var persons: [DisplayPersonNumber] = []
      if tense.hasYoForm {
        persons.append(.firstSingular)
      }
      switch secondSingular {
      case .tu:
        persons.append(.secondSingularTú)
      case .vos:
        persons.append(.secondSingularVos)
      case .both:
        persons.append(contentsOf: [.secondSingularTú, .secondSingularVos])
      }
      persons.append(contentsOf: [.thirdSingular, .firstPlural, .secondPlural, .thirdPlural])

      let rows = persons.enumerated().map { index, personNumber in
        ConjugationDisplayRow(
          index: index,
          pronoun: isImperative ? nil : personNumber.pronoun,
          form: form(verb, tense, personNumber),
          isImperative: isImperative,
          isMarked: marks.contains(ConjugationCell(tense: tense, personNumber: personNumber))
        )
      }
      return ConjugationSection(table: table, rows: rows)
    }
  }

  /// One slot's form, or blank: a defective verb's formless slot, or any other failure rather than
  /// a crash.
  private static func form(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> String {
    if case .success(let value) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber, pronoun: .written) {
      return value
    }
    return ""
  }
}

/// One card of the verb page: a tense and its rows.
struct ConjugationSection: Identifiable {
  let table: ConjugationTable
  let rows: [ConjugationDisplayRow]
  var tense: DisplayTense { table.tense }
  var id: String { table.id }
}

struct ConjugationDisplayRow: Identifiable {
  let index: Int
  let pronoun: String?
  let form: String
  let isImperative: Bool
  /// True for a cell that the search which opened the page matched.
  let isMarked: Bool
  var id: Int { index }

  /// The form as displayed: imperatives are wrapped in ¡…!.
  var displayForm: String {
    isImperative ? "¡\(form)!" : form
  }

  /// What a long press copies: the form alone, without its subject pronoun or the ¡…! that wraps
  /// an imperative, lowercased, since the capitals only mark the red letters. A reflexive-only
  /// verb's form keeps its reflexive pronoun (me arrepiento), which is part of the form. Nil for a
  /// cell the engine could not fill.
  var copyText: String? {
    Self.copyText(of: form)
  }

  static func copyText(of form: String) -> String? {
    form.isEmpty ? nil : form.lowercased()
  }

  /// What to speak on tap: pronoun + form for finite tenses, the bare form for
  /// imperatives, all lowercased.
  var spokenText: String {
    if let pronoun {
      return "\(pronoun) \(form)".lowercased()
    }
    return form.lowercased()
  }
}
