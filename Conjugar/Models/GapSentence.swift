//
//  GapSentence.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated extension QuizScope {
  /// Complete the Sentence: ten authored sentences at the learner's level, each with its verb
  /// blanked.
  static func sentences() -> QuizScope {
    QuizScope(verbs: nil, questionCount: roundLength, source: .sentences, isSentences: true)
  }
}

/// A short authored sentence with its verb blanked, "Ayer {fuimos} al cine.", which ties a form to
/// a meaning. The sentences live in `GapSentences.json`. Claude drafts them, `GapSentenceTests`
/// confirms every blank against the engine, and each is reviewed before it ships, which `reviewed`
/// records.
///
/// A second-person singular sentence is written with the tú form in its braces and is asked in
/// tú or vos as the setting chooses, so its words never name tú (no tú, ti, or contigo); te and tu
/// serve both. The frame names the person instead, as `(tú)` or `(vos)`. Nothing is written in
/// vosotros, so every sentence reads in both regions.
nonisolated struct GapSentence: Decodable, Identifiable, Equatable, Sendable {
  let id: String
  /// The bare infinitive, a key of the verb map.
  let verb: String
  /// A `DisplayTense` case name, such as `presenteDeIndicativo`.
  let tense: String
  /// A `DisplayPersonNumber` raw value, absent for the gerundio. `ss` is the second person
  /// singular, asked in tú or vos.
  let person: String?
  /// The sentence, with the words of the answer in braces. A word of the answer that the quiz's
  /// frame supplies, a negative command's "no" or a reflexive-only verb's pronoun before the verb,
  /// stands just before the braces, outside them.
  let es: String
  let en: String
  let reviewed: Bool

  var displayTense: DisplayTense? {
    DisplayTense.allCases.first { String(describing: $0) == tense }
  }

  /// The person the sentence is written in, with the second person singular in tú.
  var writtenPersonNumber: DisplayPersonNumber? {
    guard let person else {
      return DisplayPersonNumber.none
    }
    return DisplayPersonNumber(rawValue: person)
  }

  /// The person a quiz asks, with the second person singular in the learner's tú or vos.
  func personNumber(secondSingular: DisplayPersonNumber) -> DisplayPersonNumber? {
    writtenPersonNumber == .secondSingularTú ? secondSingular : writtenPersonNumber
  }

  /// The text in braces, as the sentence writes it.
  var blankText: String? {
    guard case .some(.blank(let text)) = pieces.first(where: \.isBlank) else {
      return nil
    }
    return text
  }

  /// The sentence's words before the braces and after them.
  private var surroundings: (before: String, after: String)? {
    guard pieces.filter(\.isBlank).count == 1 else {
      return nil
    }
    var before = ""
    var after = ""
    var isAfter = false
    for piece in pieces {
      switch piece {
      case .blank:
        isAfter = true
      case .text(let text):
        if isAfter {
          after += text
        } else {
          before += text
        }
      }
    }
    return (before, after)
  }

  /// The sentence as a quiz asks it in `personNumber`: whom it addresses, for a command or the
  /// second person singular, then its words, with the frame's supplied words of the answer split
  /// out of the text before the blank so that grading puts them in front of what was typed. Nil
  /// when the sentence lacks a word the frame supplies, which `GapSentenceTests` rules out.
  func frame(personNumber: DisplayPersonNumber) -> AnswerFrame? {
    guard let displayTense, let (before, after) = surroundings else {
      return nil
    }
    let quizFrame = AnswerFrame.quizFrame(tense: displayTense, personNumber: personNumber, isReflexiveOnly: ReflexivePronoun.isReflexiveOnly(verb))
    var segments: [AnswerFrame.Segment] = []
    if displayTense.isCommand || personNumber == .secondSingularTú || personNumber == .secondSingularVos {
      if let addressee = personNumber.commandAddressee {
        segments.append(.addressee(addressee))
      }
    }
    let supplied = quizFrame.leading.compactMap { segment -> String? in
      if case .word(let word) = segment {
        return word
      }
      return nil
    }
    var context = Substring(before)
    var suppliedSegments: [AnswerFrame.Segment] = []
    for word in supplied.reversed() {
      var trimmed = context
      while trimmed.last?.isWhitespace == true {
        trimmed = trimmed.dropLast()
      }
      guard trimmed.lowercased().hasSuffix(word.lowercased()) else {
        return nil
      }
      let start = trimmed.index(trimmed.endIndex, offsetBy: -word.count)
      // The word stands alone, not as the end of a longer one ("¡No", not "Bueno").
      if start > trimmed.startIndex, trimmed[trimmed.index(before: start)].isLetter {
        return nil
      }
      suppliedSegments.insert(.word(String(trimmed[start...])), at: 0)
      context = trimmed[..<start]
    }
    if !context.isEmpty {
      segments.append(.context(String(context)))
    }
    segments += suppliedSegments
    segments.append(.blank)
    if !after.isEmpty {
      segments.append(.context(after))
    }
    return AnswerFrame(segments: segments)
  }

  /// The answer the braces give with the frame's supplied words, as the quiz grades it in the
  /// person the sentence is written in: "no hagas" for "¡No {hagas} eso!".
  var writtenAnswer: String? {
    guard let personNumber = writtenPersonNumber, let blankText else {
      return nil
    }
    return frame(personNumber: personNumber)?.answer(filling: blankText)
  }

  /// The sentence as it reads with `blank` written in, capitalized where the blank begins it.
  func completed(with blank: String) -> String {
    guard let parts = completedParts(with: blank) else {
      return es
    }
    return parts.before + parts.blank + parts.after
  }

  /// `completed(with:)` in its three parts, the blank's apart, for a view that sets it off.
  func completedParts(with blank: String) -> (before: String, blank: String, after: String)? {
    guard let (before, after) = surroundings else {
      return nil
    }
    let opensSentence = !before.contains { $0.isLetter }
    let filled = opensSentence ? blank.prefix(1).uppercased() + blank.dropFirst() : blank
    return (before, filled, after)
  }

  /// Whether a level asks this sentence: its verb is in the level's band, and its tense and person
  /// are ones the level asks.
  func isAskable(at level: QuizLevel) -> Bool {
    guard let entry = VerbMap.shared.entry(for: verb), let displayTense, let personNumber = writtenPersonNumber else {
      return false
    }
    if let band = level.band, !entry.isIn(band) {
      return false
    }
    return level.entry(for: displayTense)?.asks(personNumber) ?? false
  }

  private enum Piece: Equatable {
    case blank(String)
    case text(String)

    var isBlank: Bool {
      if case .blank = self {
        return true
      }
      return false
    }
  }

  private var pieces: [Piece] {
    var result: [Piece] = []
    var text = ""
    var blank: String?
    for character in es {
      switch character {
      case "{":
        if !text.isEmpty {
          result.append(.text(text))
        }
        text = ""
        blank = ""
      case "}":
        result.append(.blank(blank ?? ""))
        blank = nil
      default:
        if blank != nil {
          blank?.append(character)
        } else {
          text.append(character)
        }
      }
    }
    if !text.isEmpty {
      result.append(.text(text))
    }
    return result
  }
}

nonisolated enum GapSentences {
  /// Every sentence in the bundle, drafts included.
  static let all: [GapSentence] = {
    let bundle = Bundle.main.url(forResource: "GapSentences", withExtension: "json") != nil ? Bundle.main : Bundle(for: BundleToken.self)
    return bundle.url(forResource: "GapSentences", withExtension: "json")
      .flatMap { try? Data(contentsOf: $0) }
      .map(decode) ?? []
  }()

  private final class BundleToken {}

  static func decode(_ data: Data) -> [GapSentence] {
    (try? JSONDecoder().decode([GapSentence].self, from: data)) ?? []
  }

  // A debug build asks drafts too, marked as drafts on the card, so that a sentence can be tried
  // in the app before it is approved. A release build asks only approved sentences.
  #if DEBUG
  static let includesDrafts = true
  #else
  static let includesDrafts = false
  #endif

  /// The sentences a level asks.
  static func askable(at level: QuizLevel, from sentences: [GapSentence] = all, includesDrafts: Bool = includesDrafts) -> [GapSentence] {
    sentences.filter { ($0.reviewed || includesDrafts) && $0.isAskable(at: level) }
  }
}

nonisolated extension DisplayTense {
  /// The other imperfect subjunctive, simple or compound, which a sentence takes as right beside
  /// the one asked: in a sentence, tuviese is as good as tuviera.
  var otherImperfectSubjunctive: DisplayTense? {
    switch self {
    case .imperfectoDeSubjuntivo1:
      return .imperfectoDeSubjuntivo2
    case .imperfectoDeSubjuntivo2:
      return .imperfectoDeSubjuntivo1
    case .pluscuamperfectoDeSubjuntivo1:
      return .pluscuamperfectoDeSubjuntivo2
    case .pluscuamperfectoDeSubjuntivo2:
      return .pluscuamperfectoDeSubjuntivo1
    default:
      return nil
    }
  }

  /// The tense's name on a sentence's card. A sentence takes either imperfect subjunctive, so it
  /// names neither's number.
  var sentenceDisplayName: String {
    otherImperfectSubjunctive == nil ? displayName : displayName.replacingOccurrences(of: " 1", with: "").replacingOccurrences(of: " 2", with: "")
  }
}

extension QuizDraw {
  /// A round of sentences: the session's unasked ones first, and one sentence a verb where the
  /// sentences allow, so that a round of ten is not four of ser's. A pool smaller than the round
  /// makes a shorter round, and once every sentence has been asked, Ten More asks them again.
  nonisolated static func sentences(
    from candidates: [GapSentence],
    count: Int,
    excluded: Set<String>,
    using generator: inout some RandomNumberGenerator
  ) -> [GapSentence] {
    let shuffled = candidates.sorted { $0.id < $1.id }.shuffled(using: &generator)
    var round: [GapSentence] = []
    var verbs: Set<String> = []
    for group in [shuffled.filter { !excluded.contains($0.id) }, shuffled.filter { excluded.contains($0.id) }] {
      for sentence in group where round.count < count && !verbs.contains(sentence.verb) {
        round.append(sentence)
        verbs.insert(sentence.verb)
      }
      for sentence in group where round.count < count && !round.contains(sentence) {
        round.append(sentence)
      }
    }
    return round
  }
}

nonisolated extension QuizQuestion {
  /// The question's sentence completed with the engine's form, in the person asked, which the
  /// correction shows: "¡No vayas solo de noche!". Nil for a question asked without a sentence.
  var completedSentence: String? {
    completedSentenceParts.map { $0.before + $0.blank + $0.after }
  }

  /// `completedSentence` in its three parts, the engine's form apart.
  var completedSentenceParts: (before: String, blank: String, after: String)? {
    guard let sentence, let answer = writtenAnswer?.lowercased() else {
      return nil
    }
    let suppliedCount = frame.leading.filter { segment in
      if case .word = segment {
        return true
      }
      return false
    }.count
    return sentence.completedParts(with: answer.split(separator: " ").dropFirst(suppliedCount).joined(separator: " "))
  }
}
