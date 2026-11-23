//
//  PracticeItemMapping.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated extension PracticeItem {
  /// The item a question exercises. A cell in which the verb is irregular, as the verb page marks
  /// it in red (`QuizDraw.isIrregular(_:in:)`, so a spelling change such as busqué too), exercises
  /// the key conjugation whose stem the cell is built on (`Key(tense:)`). A regular cell exercises
  /// its pattern, shared by every verb of its ending regular there, so tener's imperfecto (tenía)
  /// moves the -er imperfecto as comer's does. Nil for a cell the engine does not give.
  static func exercised(by verb: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> PracticeItem? {
    let cell = ConjugationCell(tense: tense, personNumber: personNumber)
    guard let isIrregular = QuizDraw.isIrregular(verb, in: cell) else {
      return nil
    }
    if isIrregular, let key = Key(tense: tense) {
      return .keyConjugation(infinitive: verb, key: key)
    }
    return pattern(of: cell, ending: RegularRoot(infinitive: verb))
  }

  static func exercised(by question: QuizQuestion) -> PracticeItem? {
    exercised(by: question.verb, tense: question.tense, personNumber: question.personNumber)
  }

  static func pattern(of cell: ConjugationCell, ending root: RegularRoot?) -> PracticeItem? {
    guard let root, let tenseKey = tenseKey(for: cell.tense) else {
      return nil
    }
    let person = cell.personNumber == .none ? nil : cell.personNumber.rawValue
    return .pattern(tenseKey: tenseKey, person: person, ending: root.practiceKey)
  }

  /// The items a lookup of the verb schedules, which the review card offers: each key conjugation
  /// of an irregular verb that some irregular cell is built on, since only such a cell's answer
  /// moves it. tener has three, its participle (tenido) being regular; pensar has only the yo
  /// presente. A regular verb has none, since its conjugations are the patterns of its ending.
  static func keyConjugations(of infinitive: String) -> [PracticeItem] {
    guard isReviewable(infinitive) else {
      return []
    }
    return Key.allCases
      .filter { key in irregularCells(of: infinitive, builtOn: key).contains { _ in true } }
      .map { .keyConjugation(infinitive: infinitive, key: $0) }
  }

  /// The cells of the verb that are irregular and built on the key conjugation, which a review of
  /// it can ask, the key's own cell first (tengo, then tienes, …, tenga, …). Asking any of them
  /// moves the key conjugation, and only them: pedir's yo pretérito (pedí) is regular, so its
  /// review asks pidió. Lazy, since a caller usually wants the first that fits.
  static func irregularCells(of infinitive: String, builtOn key: Key) -> some Sequence<ConjugationCell> {
    key.cells.lazy.filter { QuizDraw.isIrregular(infinitive, in: $0) == true }
  }

  /// Whether the review card offers the verb: only an irregular verb, counted as the verb page's
  /// pill counts it, so the orthographic classes (buscar, busqué) too.
  static func isReviewable(_ infinitive: String) -> Bool {
    VerbMap.shared.entry(for: infinitive).map(VerbDraw.isIrregular) ?? false
  }

  /// The item's own cell: a key conjugation's (yo tengo, the participio), or the pattern's. Nil
  /// for a key this version cannot read.
  var cell: ConjugationCell? {
    switch self {
    case let .keyConjugation(_, key):
      let conjugation = key.keyConjugation
      return ConjugationCell(tense: conjugation.tense, personNumber: conjugation.personNumber)
    case let .pattern(tenseKey, person, _):
      guard let tense = Self.tense(forKey: tenseKey) else {
        return nil
      }
      guard let person else {
        return tense == .gerundio || tense == .participio ? ConjugationCell(tense: tense, personNumber: .none) : nil
      }
      guard let personNumber = DisplayPersonNumber(rawValue: person), personNumber != .none else {
        return nil
      }
      return ConjugationCell(tense: tense, personNumber: personNumber)
    }
  }

  /// A pattern's ending. Nil for a key conjugation.
  var ending: RegularRoot? {
    guard case let .pattern(_, _, ending) = self else {
      return nil
    }
    return [RegularRoot.ar, .er, .ir].first { $0.practiceKey == ending }
  }

  /// A tense's permanent key in the record: the custom quiz's, or `participio`.
  static func tenseKey(for tense: DisplayTense) -> String? {
    if tense == .participio {
      return participioKey
    }
    return CustomQuiz.choosableTenses.contains(tense) ? CustomQuiz.key(for: tense) : nil
  }

  static func tense(forKey key: String) -> DisplayTense? {
    key == participioKey ? .participio : CustomQuiz.tense(forKey: key)
  }

  private static let participioKey = "participio"
}

nonisolated extension PracticeItem.Key {
  /// The key conjugation whose stem an irregular cell of the tense is built on. Most follow from
  /// the stems: the presente de subjuntivo and the commands of usted, nosotros, and ustedes from
  /// tengo; both imperfectos de subjuntivo and the futuro de subjuntivo from tuve; the condicional
  /// from tendré; every compound tense from tenido. The rest go to the nearest key, accepting that
  /// a slip in tienes counts against tengo: the presente's other persons (tienes, duerme), the tú
  /// and vos commands (ten, pon, di), and the three irregular imperfectos (era, iba, veía) to the yo
  /// presente; the gerundio (durmiendo, pidiendo), whose stem is the third-person pretérito's
  /// (durmió), to the yo pretérito. Nil for a tense a quiz never asks.
  init?(tense: DisplayTense) {
    switch tense {
    case .presenteDeIndicativo, .presenteDeSubjuntivo, .imperativoPositivo, .imperativoNegativo, .imperfectoDeIndicativo:
      self = .yoPresente
    case .pretérito, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .futuroDeSubjuntivo, .gerundio:
      self = .yoPretérito
    case .futuroDeIndicativo, .condicional:
      self = .yoFuturo
    case .participio, .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
      .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1, .pluscuamperfectoDeSubjuntivo2,
      .futuroPerfectoDeSubjuntivo:
      self = .participio
    case .infinitivo, .translation, .raízFutura:
      return nil
    }
  }

  /// Every cell a quiz can ask that is built on the key conjugation, its own cell first, then the
  /// finite tenses, the gerundio, and the participio, each tense's persons in the table's order.
  var cells: [ConjugationCell] {
    let own = ConjugationCell(tense: keyConjugation.tense, personNumber: keyConjugation.personNumber)
    let tenses = (DisplayTense.conjugatedTenses + [.gerundio, .participio]).filter { Self(tense: $0) == self }
    let others = tenses.flatMap { tense -> [ConjugationCell] in
      Self.personNumbers(of: tense).map { ConjugationCell(tense: tense, personNumber: $0) }
    }
    return [own] + others.filter { $0 != own }
  }

  private static func personNumbers(of tense: DisplayTense) -> [DisplayPersonNumber] {
    switch tense {
    case .gerundio, .participio:
      return [.none]
    case .imperativoPositivo, .imperativoNegativo:
      return [.secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    default:
      return [.firstSingular, .secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    }
  }

  var keyConjugation: KeyConjugation {
    switch self {
    case .yoPresente:
      return .yoPresente
    case .yoPretérito:
      return .yoPretérito
    case .yoFuturo:
      return .yoFuturo
    case .participio:
      return .participio
    }
  }
}

nonisolated extension RegularRoot {
  /// The ending's name in the record's pattern keys.
  var practiceKey: String {
    switch self {
    case .ar:
      return "ar"
    case .er:
      return "er"
    case .ir:
      return "ir"
    }
  }
}
