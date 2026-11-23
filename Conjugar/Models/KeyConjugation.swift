//
//  KeyConjugation.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The four conjugations from which a learner can rebuild most of a verb: "tener: tengo · tuve ·
/// tendré · tenido". Each is the stem a family of tenses is built on, which is why these four and
/// not others. They appear with no heading, in the interface or in code names, because the
/// textbook term for them means little to most learners. The verb page's share text, the review
/// card, and Spotlight build on them, so do not change the set lightly.
nonisolated enum KeyConjugation: CaseIterable, Sendable {
  /// tengo. The presente de subjuntivo (tenga) and the usted, nosotros, ustedes, and negative
  /// imperatives follow it.
  case yoPresente
  /// tuve. The two imperfectos de subjuntivo (tuviera, tuviese) and the futuro de subjuntivo
  /// (tuviere) follow it.
  case yoPretérito
  /// tendré. The condicional (tendría) shares its stem.
  case yoFuturo
  /// tenido. Every compound tense is built on it (he tenido, había tenido, …).
  case participio

  /// The tense of the page's cell this key conjugation is.
  var tense: DisplayTense {
    switch self {
    case .yoPresente:
      return .presenteDeIndicativo
    case .yoPretérito:
      return .pretérito
    case .yoFuturo:
      return .futuroDeIndicativo
    case .participio:
      return .participio
    }
  }

  /// The person of the page's cell this key conjugation is: yo, or `.none` for the participio.
  var personNumber: DisplayPersonNumber {
    self == .participio ? .none : .firstSingular
  }

  /// One key conjugation of one verb.
  struct Form: Equatable, Sendable {
    let key: KeyConjugation
    /// Mixed case, as the engine writes it, so that a caller can show the red letters (tenGo,
    /// TUVe). A reflexive-only verb's forms carry their pronoun (me arrepiento), as the verb page
    /// writes them.
    let form: String
  }

  /// `infinitive`'s key conjugations, in this enum's order. A form the engine cannot produce,
  /// such as abolir's yo presente, is left out rather than returned as a dash.
  static func forms(of infinitive: String) -> [Form] {
    allCases.compactMap { key in
      guard case .success(let form) = TenseBridge.conjugate(
        infinitive: infinitive,
        tense: key.tense,
        personNumber: key.personNumber,
        pronoun: .written
      ), !form.isEmpty else {
        return nil
      }
      return Form(key: key, form: form)
    }
  }

  /// The key conjugations as plain text, lowercased and joined by middle dots: "tengo · tuve ·
  /// tendré · tenido".
  static func line(for infinitive: String) -> String {
    forms(of: infinitive).map { $0.form.lowercased() }.joined(separator: " · ")
  }
}

extension KeyConjugation {
  /// What the verb page's share button sends, in the learner's language: the verb as a
  /// dictionary cites it, its gloss in quotation marks of that language, its key conjugations,
  /// and the App Store link. MainActor because `L` is.
  @MainActor
  static func shareText(for infinitive: String) -> String {
    let citation = ReflexivePronoun.citationForm(of: infinitive)
    return L.Verb.shareText(
      infinitive: citation,
      gloss: VerbMap.shared.entry(for: infinitive)?.gloss ?? "",
      keyConjugations: line(for: infinitive),
      link: URL.appStore.absoluteString
    )
  }
}
