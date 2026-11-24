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
  /// Whether the quiz asks this question again after a wrong answer to it (`reasked(inStep:)`). A
  /// re-ask is never asked again, and a right answer to it earns half points.
  private(set) var isReask = false
  /// The questions shown together on one screen share a step, as a verb's key conjugations do in
  /// Verb Essentials. Nil for a question shown alone.
  private(set) var step: Int?
  /// For Name the Form, the form shown and the cells that write it. The verb and cell are then the
  /// asked one, which the prompt was conjugated from, and the learner names them.
  private(set) var recognition: RecognitionQuestion?
  /// For Complete the Sentence, the sentence the answer fills.
  private(set) var sentence: GapSentence?
  /// For a choice question, the two sentences the learner chooses between. The verb and cell are
  /// the right sentence's, and `sentence` is that sentence.
  private(set) var choice: ChoicePrompt?

  init(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) {
    self.verb = verb
    self.tense = tense
    self.personNumber = personNumber
  }

  /// The same question, to be asked again, in `step`.
  func reasked(inStep step: Int? = nil) -> QuizQuestion {
    var question = self
    question.isReask = true
    question.step = step
    return question
  }

  /// The same question, shown with the others of `step`.
  func inStep(_ step: Int) -> QuizQuestion {
    var question = self
    question.step = step
    return question
  }

  /// The same question, asked as Name the Form.
  func recognizing(_ recognition: RecognitionQuestion) -> QuizQuestion {
    var question = self
    question.recognition = recognition
    return question
  }

  /// The same question, asked in a sentence.
  func inSentence(_ sentence: GapSentence) -> QuizQuestion {
    var question = self
    question.sentence = sentence
    return question
  }

  /// The same question, asked as a choice between two sentences.
  func choosing(_ choice: ChoicePrompt) -> QuizQuestion {
    var question = self
    question.choice = choice
    return question
  }

  /// The question a sentence asks in the learner's tú or vos, or nil when the sentence names no
  /// cell.
  static func sentence(_ sentence: GapSentence, secondSingular: DisplayPersonNumber) -> QuizQuestion? {
    guard let tense = sentence.displayTense, let personNumber = sentence.personNumber(secondSingular: secondSingular) else {
      return nil
    }
    return QuizQuestion(sentence.verb, tense, personNumber).inSentence(sentence)
  }

  /// The answer the quiz shows, irregularity-marked, with a reflexive-only verb's pronoun. Nil
  /// when the engine gives no form for the cell.
  var writtenAnswer: String? {
    if case let .success(answer) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber, pronoun: .written) {
      return answer
    }
    return nil
  }

  /// Every spelling the quiz takes as right, irregularity-marked where the engine marks it, as
  /// the quiz would show it: the written answer first; a reflexive-only verb's form without its
  /// pronoun (arrepiento beside me arrepiento); and each standard variant of the cell
  /// (`StandardVariants`), such as frito beside freído or the rió that the 2010 *Ortografía*
  /// retired beside rio, with and without that pronoun.
  var shownSpellings: [String] {
    var spellings: [String] = []
    func add(_ spelling: String) {
      if !spellings.contains(where: { $0.lowercased() == spelling.lowercased() }) {
        spellings.append(spelling)
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
    // A sentence is the prompt, and in it either imperfect subjunctive is right.
    if sentence != nil, let other = tense.otherImperfectSubjunctive {
      for spelling in QuizQuestion(verb, other, personNumber).shownSpellings {
        add(spelling)
      }
    }
    return spellings
  }

  /// `shownSpellings`, lowercased: every answer the quiz takes as right.
  var acceptedAnswers: [String] {
    shownSpellings.map { $0.lowercased() }
  }

  /// The shape of the answer, with the words the learner does not type around the blank.
  var frame: AnswerFrame {
    // Name the Form's one blank takes the infinitive.
    if recognition != nil {
      return AnswerFrame(segments: [.blank])
    }
    if let sentenceFrame = sentence?.frame(personNumber: personNumber) {
      return sentenceFrame
    }
    return AnswerFrame.quizFrame(tense: tense, personNumber: personNumber, isReflexiveOnly: ReflexivePronoun.isReflexiveOnly(verb))
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

  /// The grade of one attempt as typed, `.totalMatch` or `.noMatch`. Case and spacing never
  /// count, nor does a leading subject pronoun of the asked person ("yo hablo"). Accents do: an
  /// answer right but for them is a slip (`isSlip(_:)`), which earns one more attempt.
  func grade(_ answer: String) -> ConjugationResult {
    let candidates = AnswerSpelling.candidates(for: answer, tense: tense, personNumber: personNumber)
    let accepted = acceptedAnswers
    return candidates.contains(where: accepted.contains) ? .totalMatch : .noMatch
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
