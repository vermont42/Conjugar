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
    /// A sentence's words around its blank, which are not part of the answer. The text keeps its
    /// spacing, so that a comma or a question mark written against the blank stays there.
    case context(String)
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
      case .context(let text):
        let trimmed = text.trimmingCharacters(in: Self.spokenTrim)
        return trimmed.isEmpty ? nil : .some(trimmed)
      case .blank:
        return .some(nil)
      case .punctuation:
        return nil
      }
    }
  }

  private static let spokenTrim = CharacterSet.whitespaces.union(.punctuationCharacters)

  /// Whether the frame is a sentence, which lays out word by word.
  var isSentence: Bool {
    segments.contains { segment in
      if case .context = segment {
        return true
      }
      return false
    }
  }

  /// What a sentence frame lays out, word by word, so that a long sentence wraps between words.
  /// The blank carries the text written against it, such as the ¿ before it or the comma after
  /// it, so that a mark never starts or ends a line of its own.
  nonisolated enum SentenceToken: Equatable, Sendable {
    case addressee(String)
    case blank(leading: String, trailing: String)
    /// A word of the answer that the frame supplies, the "no" of `¡No [ ] eso!`.
    case answerWord(String)
    case word(String)
  }

  var sentenceTokens: [SentenceToken] {
    var tokens: [SentenceToken] = []
    // The last word of a text written against what follows it, with no space between, as the ¡
    // of ¡No or the ¿ of ¿[ ].
    var glued: String?
    func flush() {
      if let word = glued {
        tokens.append(.word(word))
        glued = nil
      }
    }
    for segment in segments {
      switch segment {
      case .blank:
        tokens.append(.blank(leading: glued ?? "", trailing: ""))
        glued = nil
      case .addressee(let text):
        flush()
        tokens.append(.addressee(text))
      case .word(let word):
        tokens.append(.answerWord((glued ?? "") + word))
        glued = nil
      case .context(let text), .punctuation(let text), .pronoun(let text):
        flush()
        var words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        if let first = words.first, !text.hasPrefix(" "), case .blank(let leading, let trailing) = tokens.last {
          tokens[tokens.count - 1] = .blank(leading: leading, trailing: trailing + first)
          words.removeFirst()
        }
        if !text.hasSuffix(" "), let last = words.popLast() {
          tokens += words.map(SentenceToken.word)
          glued = last
        } else {
          tokens += words.map(SentenceToken.word)
        }
      }
    }
    flush()
    return tokens
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
