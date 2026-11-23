//
//  QuizQuestion.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// One quiz question, a verb's cell, and every answer the quiz takes for it.
///
/// The accepted answers are expanded rather than the learner's answer folded, because a fold
/// applied to both sides would also accept a misspelling.
nonisolated struct QuizQuestion: Equatable, Sendable {
  let verb: String
  let tense: DisplayTense
  /// `.none` for the gerundio and the participio.
  let personNumber: DisplayPersonNumber

  init(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) {
    self.verb = verb
    self.tense = tense
    self.personNumber = personNumber
  }

  /// The answer the quiz shows, irregularity-marked, with a reflexive-only verb's pronoun. Nil
  /// when the engine gives no form for the cell.
  var writtenAnswer: String? {
    if case let .success(answer) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber, pronoun: .written) {
      return answer
    }
    return nil
  }

  /// Every lowercased spelling the quiz takes as right: the written answer; a reflexive-only
  /// verb's form without its pronoun (arrepiento beside me arrepiento); and each standard variant
  /// of the cell (`StandardVariants`), such as frito beside freído or the rió that the 2010
  /// *Ortografía* retired beside rio, with and without that pronoun.
  var acceptedAnswers: [String] {
    var answers: [String] = []
    func add(_ answer: String) {
      let lowercased = answer.lowercased()
      if !answers.contains(lowercased) {
        answers.append(lowercased)
      }
    }
    if let writtenAnswer {
      add(writtenAnswer)
    }
    if case let .success(bare) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber) {
      add(bare)
    }
    let isReflexiveOnly = ReflexivePronoun.isReflexiveOnly(verb)
    for variant in StandardVariants.forms(infinitive: verb, tense: tense, personNumber: personNumber) {
      if isReflexiveOnly {
        add(ReflexivePronoun.attach(to: variant, tense: tense, personNumber: personNumber))
      }
      add(variant)
    }
    return answers
  }

  /// The shape of the answer, with the words the learner does not type around the blank.
  var frame: AnswerFrame {
    AnswerFrame.quizFrame(tense: tense, personNumber: personNumber, isReflexiveOnly: ReflexivePronoun.isReflexiveOnly(verb))
  }

  /// The answer that a filled blank gives, ready for `grade(_:)`: the frame's own words of the
  /// answer, such as a negative command's "no", then the blank. A subject pronoun of the asked
  /// person typed into the blank is dropped first, so that "yo me arrepiento" in `yo me [ ]` does
  /// not become "me yo me arrepiento".
  func answer(filling blank: String) -> String {
    var typed = AnswerSpelling.normalized(blank)
    for pronoun in AnswerSpelling.leadingPronouns(tense: tense, personNumber: personNumber) where typed.hasPrefix(pronoun + " ") {
      typed = String(typed.dropFirst(pronoun.count + 1))
      break
    }
    return frame.answer(filling: typed)
  }

  /// The grade of an answer as typed. Case and spacing never count, nor does a leading subject
  /// pronoun of the asked person ("yo hablo"). An answer that matches an accepted one but for its
  /// accents earns `.partialMatch`.
  func grade(_ answer: String) -> ConjugationResult {
    let candidates = AnswerSpelling.candidates(for: answer, tense: tense, personNumber: personNumber)
    let accepted = acceptedAnswers
    if candidates.contains(where: accepted.contains) {
      return .totalMatch
    }
    let isPartial = candidates.contains { candidate in
      accepted.contains { ConjugationResult.compare(lhs: candidate, rhs: $0) == .partialMatch }
    }
    return isPartial ? .partialMatch : .noMatch
  }

  /// The spelling the engine writes, irregularity-marked, of a right answer typed in a spelling
  /// the 2010 *Ortografía* retired (rió for rio), for the quiz to show quietly beside the check.
  /// Nil for any other answer.
  func currentSpelling(of answer: String) -> String? {
    let accepted = acceptedAnswers
    for candidate in AnswerSpelling.candidates(for: answer, tense: tense, personNumber: personNumber) where accepted.contains(candidate) {
      let respelled = Orthography.currentSpelling(of: candidate)
      guard respelled != candidate, accepted.contains(respelled) else {
        continue
      }
      if let writtenAnswer, respelled == writtenAnswer.lowercased() {
        return writtenAnswer
      }
      return respelled
    }
    return nil
  }
}
