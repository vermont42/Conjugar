//
//  AnswerSpelling.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// How the quiz reads what a learner typed, before comparing it with the accepted answers. Search
/// folds far more loosely (`SpellingComparison.fold` drops ñ's tilde), which is right for finding a verb
/// and wrong for grading one.
nonisolated enum AnswerSpelling {
  /// Case and runs of whitespace are not part of an answer: "  He   Hablado " is he hablado.
  static func normalized(_ answer: String) -> String {
    answer.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased()
  }

  /// The subject pronouns a learner may type before an answer: yo hablo is the presente for yo,
  /// pronoun and all. Every pronoun of the person counts, whichever one the question shows, and so
  /// does tú or él typed without its accent, since the pronoun is not what is being asked. A
  /// command takes none, nor does a form with no person.
  static func leadingPronouns(tense: DisplayTense, personNumber: DisplayPersonNumber) -> [String] {
    switch tense {
    case .imperativoPositivo, .imperativoNegativo, .gerundio, .participio, .infinitivo, .translation, .raízFutura:
      return []
    default:
      break
    }
    switch personNumber {
    case .firstSingular:
      return ["yo"]
    case .secondSingularTú:
      return ["tú", "tu"]
    case .secondSingularVos:
      return ["vos"]
    case .thirdSingular:
      return ["él", "el", "ella", "usted"]
    case .firstPlural:
      return ["nosotros", "nosotras"]
    case .secondPlural:
      return ["vosotros", "vosotras"]
    case .thirdPlural:
      return ["ellos", "ellas", "ustedes"]
    case .none:
      return []
    }
  }

  /// A normalized answer, then the same answer without a leading pronoun of the asked person.
  static func candidates(for answer: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> [String] {
    let normalized = normalized(answer)
    var candidates = [normalized]
    for pronoun in leadingPronouns(tense: tense, personNumber: personNumber) where normalized.hasPrefix(pronoun + " ") {
      candidates.append(String(normalized.dropFirst(pronoun.count + 1)))
    }
    return candidates
  }
}
