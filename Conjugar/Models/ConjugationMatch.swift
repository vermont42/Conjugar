//
//  ConjugationMatch.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Which cells of a verb a text is: "fue" is ir's pretérito (él), "ha hablado" is hablar's perfecto
/// de indicativo (él). The quiz needs this to tell a slip from a real error: hablo is one accent
/// away from habló, and is the presente (yo) of the same verb, not a misspelling of the pretérito.
///
/// It conjugates the verb's every displayed cell, compound tenses and the imperativo negativo
/// included, rather than reading `ConjugationMap`, which holds one-word forms only. That is about
/// 150 engine calls, so call it when a text needs judging, not per keystroke.
nonisolated enum ConjugationMatch {
  /// How accents count when comparing.
  enum Accents: Sendable {
    /// Accents must match: "hablo" is not habló.
    case exact
    /// Acute accents and the diaeresis are ignored, so "hablo" also matches habló. The tilde of
    /// ñ is kept, because ñ is a letter of its own, not n with an accent.
    case folded
    /// As `folded`, and ñ's tilde is ignored too, for judging a typing slip, where a learner
    /// without a Spanish keyboard types enseno for enseño.
    case bare
  }

  /// Every cell this verb has: the infinitive, the gerund, the participle, and each conjugated
  /// tense in each person it has, vos included. In the verb page's tense order, which
  /// `ConjugationTable` owns, so that a search result names its cells in the order the page shows
  /// them.
  static let allCells: [ConjugationCell] = {
    var cells = [DisplayTense.infinitivo, .gerundio, .participio].map { ConjugationCell(tense: $0, personNumber: .none) }
    for tense in ConjugationTable.all.map(\.tense) {
      let isImperative = tense == .imperativoPositivo || tense == .imperativoNegativo
      for personNumber in ConjugationCell.finitePersons where !isImperative || personNumber != .firstSingular {
        cells.append(ConjugationCell(tense: tense, personNumber: personNumber))
      }
    }
    return cells
  }()

  /// `cells` in `allCells` order, the page's.
  static func inPageOrder(_ cells: some Sequence<ConjugationCell>) -> [ConjugationCell] {
    cells.sorted { pageIndex(of: $0) < pageIndex(of: $1) }
  }

  /// Where `cell` falls in `allCells`.
  static func pageIndex(of cell: ConjugationCell) -> Int {
    pageIndexes[cell] ?? Int.max
  }

  private static let pageIndexes: [ConjugationCell: Int] = Dictionary(
    uniqueKeysWithValues: allCells.enumerated().map { ($1, $0) }
  )

  /// The cells of `infinitive` whose form equals `text`, in `allCells` order. Case and runs of
  /// spaces never count. A reflexive-only verb's form matches with its pronoun or without it
  /// (me arrepiento, arrepiento), as the quiz grades it. Empty for a verb not in `VerbMap`.
  static func cells(of infinitive: String, equalTo text: String, accents: Accents = .exact) -> [ConjugationCell] {
    let target = normalized(text, accents: accents)
    // The engine conjugates any infinitive-shaped text as a regular verb, so an unknown verb has
    // to be refused here.
    guard !target.isEmpty, VerbMap.shared.entry(for: infinitive) != nil else {
      return []
    }
    let pronouns: [ReflexivePronoun] = ReflexivePronoun.isReflexiveOnly(infinitive) ? [.omitted, .written] : [.omitted]
    return allCells.filter { cell in
      forms(of: infinitive, at: cell, pronouns: pronouns).contains { normalized($0, accents: accents) == target }
    }
  }

  /// The forms a cell may be written as: the bare form, and for a reflexive-only verb also the
  /// form with its pronoun.
  private static func forms(of infinitive: String, at cell: ConjugationCell, pronouns: [ReflexivePronoun]) -> [String] {
    if cell.tense == .infinitivo {
      return [infinitive, ReflexivePronoun.citationForm(of: infinitive)]
    }
    return pronouns.compactMap { pronoun in
      guard case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: cell.tense, personNumber: cell.personNumber, pronoun: pronoun) else {
        return nil
      }
      return form
    }
  }

  /// Lowercased, with runs of whitespace collapsed to one space, and accents folded if asked.
  static func normalized(_ text: String, accents: Accents) -> String {
    let collapsed = text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    switch accents {
    case .exact:
      return collapsed
    case .folded:
      return foldingAccents(collapsed)
    case .bare:
      return bareSpelling(collapsed)
    }
  }

  private static let foldedMarks: Set<Unicode.Scalar> = ["\u{0301}", "\u{0308}"]
  private static let bareMarks: Set<Unicode.Scalar> = ["\u{0301}", "\u{0308}", "\u{0303}"]

  /// "habló" → "hablo", "pingüino" → "pinguino", "año" unchanged.
  static func foldingAccents(_ text: String) -> String {
    removing(foldedMarks, from: text)
  }

  /// "enseñó" → "enseno": `foldingAccents`, and ñ's tilde dropped as well.
  static func bareSpelling(_ text: String) -> String {
    removing(bareMarks, from: text)
  }

  private static func removing(_ marks: Set<Unicode.Scalar>, from text: String) -> String {
    let scalars = text.decomposedStringWithCanonicalMapping.unicodeScalars.filter { !marks.contains($0) }
    return String(String.UnicodeScalarView(scalars)).precomposedStringWithCanonicalMapping
  }
}
