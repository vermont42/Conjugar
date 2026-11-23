//
//  AnswerFrame.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The shape of an expected answer: one blank the learner fills, and the words around it that the
/// learner does not type. `yo [ ]` settles that the subject pronoun is not part of the answer,
/// `(tú) ¡no [ ]!` that the "no" of a negative command is supplied, and `yo me [ ]` where a
/// reflexive pronoun goes.
nonisolated struct AnswerFrame: Equatable, Sendable {
  nonisolated enum Segment: Equatable, Sendable {
    /// Who a command addresses, shown as (tú) or (usted). A command takes no subject pronoun, but
    /// the learner must still know whom it addresses.
    case addressee(String)
    /// A subject pronoun in front of the answer, which is not part of it.
    case pronoun(String)
    /// A word of the answer that the frame supplies: the "no" of a negative command, or a
    /// reflexive pronoun placed before the verb.
    case word(String)
    case punctuation(String)
    case blank
  }

  let segments: [Segment]

  /// The segments before the blank.
  var leading: [Segment] {
    Array(segments.prefix { $0 != .blank })
  }

  /// The segments after the blank.
  var trailing: [Segment] {
    guard let blankIndex = segments.firstIndex(of: .blank) else {
      return []
    }
    return Array(segments[segments.index(after: blankIndex)...])
  }

  /// The answer that the filled blank gives: the frame's own words of the answer, then what the
  /// learner typed. A learner who also types some of those words ("no hables" after the frame's
  /// "no") is not made to repeat them, and the frame's punctuation typed into the blank (¡habla!)
  /// is dropped.
  func answer(filling blank: String) -> String {
    let typed = Self.words(of: blank.trimmingCharacters(in: Self.framePunctuation))
    let supplied = leading.compactMap { segment -> String? in
      if case .word(let word) = segment {
        return word.lowercased()
      }
      return nil
    }
    // The longest run of supplied words that ends the frame and starts what was typed.
    let typedLowercased = typed.map { $0.lowercased() }
    let overlap = (0...supplied.count).last { count in
      typedLowercased.starts(with: supplied.suffix(count))
    } ?? 0
    return (supplied.dropLast(overlap) + typed).joined(separator: " ")
  }

  /// What VoiceOver reads for the frame's words, in order, with the blank as nil: ["tú", "no",
  /// nil] for `(tú) ¡no [ ]!`. Punctuation is not read.
  var spokenParts: [String?] {
    segments.compactMap { segment -> String?? in
      switch segment {
      case .addressee(let text), .pronoun(let text), .word(let text):
        return .some(text)
      case .blank:
        return .some(nil)
      case .punctuation:
        return nil
      }
    }
  }

  private static let framePunctuation = CharacterSet(charactersIn: "¡!¿?").union(.whitespacesAndNewlines)

  private static func words(of text: String) -> [String] {
    text.split(whereSeparator: \.isWhitespace).map(String.init)
  }

  /// The frame for one quiz question.
  ///
  /// A finite form, simple or compound, takes its subject pronoun (`yo [ ]` takes hablo or he
  /// hablado). A command names whom it addresses, usted and ustedes included, and is set in
  /// exclamation marks; a negative command supplies its "no". The gerundio and participio take
  /// nothing. A reflexive-only verb's pronoun stands before the blank wherever Spanish puts it
  /// before the verb (`yo me [ ]`, `¡no te [ ]!`), and is the blank's to type where it follows
  /// as an enclitic (arrepiéntete).
  static func quizFrame(tense: DisplayTense, personNumber: DisplayPersonNumber, isReflexiveOnly: Bool) -> AnswerFrame {
    let reflexive: [Segment] = isReflexiveOnly ? ReflexivePronoun.pronoun(for: personNumber).map { [.word($0)] } ?? [] : []
    switch tense {
    case .imperativoPositivo:
      return AnswerFrame(segments: addressee(personNumber) + [.punctuation("¡"), .blank, .punctuation("!")])
    case .imperativoNegativo:
      return AnswerFrame(segments: addressee(personNumber) + [.punctuation("¡"), .word("no")] + reflexive + [.blank, .punctuation("!")])
    case .gerundio, .participio, .infinitivo, .translation, .raízFutura:
      return AnswerFrame(segments: [.blank])
    case .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .futuroDeSubjuntivo,
         .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      guard personNumber != .none else {
        return AnswerFrame(segments: [.blank])
      }
      return AnswerFrame(segments: [.pronoun(personNumber.pronoun)] + reflexive + [.blank])
    }
  }

  private static func addressee(_ personNumber: DisplayPersonNumber) -> [Segment] {
    personNumber.commandAddressee.map { [.addressee($0)] } ?? []
  }
}

nonisolated extension DisplayPersonNumber {
  /// Whom a command in this person addresses. The third persons' commands are usted's and
  /// ustedes', which the subject pronouns él and ellas would misname. Nil for yo and `.none`.
  var commandAddressee: String? {
    switch self {
    case .secondSingularTú:
      return "tú"
    case .secondSingularVos:
      return "vos"
    case .thirdSingular:
      return "usted"
    case .firstPlural:
      return "nosotros"
    case .secondPlural:
      return "vosotros"
    case .thirdPlural:
      return "ustedes"
    case .firstSingular, .none:
      return nil
    }
  }
}
