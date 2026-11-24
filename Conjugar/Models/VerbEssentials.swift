//
//  VerbEssentials.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Verb Essentials: given an irregular verb, the learner types its key conjugations, tengo · tuve ·
/// tendré · tenido. Each is its own question, graded alone and recorded as its own item, but a
/// verb's are shown together as one step, so that the learner sees the verb assemble.
nonisolated extension QuizScope {
  /// Five verbs, twenty blanks.
  static let verbEssentialsVerbCount = 5

  /// Nil asks the irregular verbs of the learner's band. A list asks those of its verbs that have
  /// an irregular key conjugation.
  static func verbEssentials(_ verbs: [String]? = nil) -> QuizScope {
    QuizScope(
      verbs: verbs,
      questionCount: verbEssentialsVerbCount * KeyConjugation.allCases.count,
      source: .verbEssentials,
      isVerbEssentials: true
    )
  }
}

nonisolated enum VerbEssentials {
  /// The prefixed compounds (detener, rehacer) a round drawn from a band may hold, while base verbs
  /// remain, since a compound's key conjugations are its root's behind a prefix.
  static let compoundLimit = 1

  /// One verb's questions: its key conjugations in the verb page's order. One the engine does not
  /// give, such as abolir's yo presente, is not asked.
  static func questions(for verb: String) -> [QuizQuestion] {
    KeyConjugation.forms(of: verb).map { QuizQuestion(verb, $0.key.tense, $0.key.personNumber) }
  }

  /// The verbs' questions, each verb a step of its own, numbered after the steps of `prior`.
  static func steps(for verbs: [String], after prior: [QuizQuestion] = []) -> [QuizQuestion] {
    let first = (prior.compactMap(\.step).max() ?? -1) + 1
    return verbs.enumerated().flatMap { offset, verb in
      questions(for: verb).map { $0.inStep(first + offset) }
    }
  }

  /// Whether one of the verb's key conjugations is irregular. Every irregular verb has one but a
  /// few defective verbs and those whose only change is an ending's i lost after ll or ñ (bullir,
  /// tañer).
  static func hasIrregularKeyConjugation(_ verb: String) -> Bool {
    KeyConjugation.forms(of: verb).contains { $0.form != $0.form.lowercased() }
  }

  /// The irregular verbs of a band, or of every verb, the most frequent first.
  static func pool(band: FrequencyBand?) -> [String] {
    let entries = band.map { VerbMap.shared.entries(in: $0) }
      ?? VerbMap.shared.entries.values.sorted { $0.frequencyRank < $1.frequencyRank }
    return entries.filter(VerbDraw.isIrregular).map(\.infinitive)
  }

  /// A round's verbs: `count` distinct verbs of `pool` with an irregular key conjugation, at
  /// random. Verbs the session has asked come only once every other verb has been, so that five
  /// more verbs are new for as long as the pool lasts. With `limitsCompounds`, a round holds at
  /// most `compoundLimit` prefixed compounds unless the pool runs out of base verbs.
  static func verbs(
    from pool: [String],
    count: Int,
    asked: Set<String> = [],
    limitsCompounds: Bool,
    using generator: inout some RandomNumberGenerator
  ) -> [String] {
    let fresh = pool.filter { !asked.contains($0) }.shuffled(using: &generator)
    let repeated = pool.filter { asked.contains($0) }.shuffled(using: &generator)
    var chosen: [String] = []
    var deferred: [String] = []
    var compoundCount = 0
    for verb in fresh + repeated where chosen.count < count && !chosen.contains(verb) {
      guard hasIrregularKeyConjugation(verb) else {
        continue
      }
      if limitsCompounds, isCompound(verb) {
        guard compoundCount < compoundLimit else {
          deferred.append(verb)
          continue
        }
        compoundCount += 1
      }
      chosen.append(verb)
    }
    chosen += deferred.prefix(max(count - chosen.count, 0))
    return chosen
  }

  /// A prefixed compound of another verb of the map, by the Related Verbs card's relation.
  static func isCompound(_ verb: String) -> Bool {
    VerbRelations.shared.baseByVerb[verb] != nil
  }
}

/// One of the rows Verb Essentials shows for a verb.
nonisolated struct VerbEssentialsRow: Identifiable, Equatable, Sendable {
  enum Content: Equatable, Sendable {
    /// Asked earlier in the step, with the engine's form and how the answer went.
    case answered(form: String, result: ConjugationResult)
    /// The question the answer field asks.
    case current
    /// A re-ask asks only the key conjugations that were missed, and gives the others.
    case given(form: String)
    /// Asked later in the step.
    case pending
  }

  let key: KeyConjugation
  let content: Content

  var id: KeyConjugation {
    key
  }
}

extension Quiz {
  /// The questions of the current step, which a Verb Essentials verb's share. Any other question
  /// is a step of its own.
  var currentStepRange: Range<Int> {
    let index = currentQuestionIndex
    guard questions.indices.contains(index), let step = questions[index].step else {
      return index..<(index + 1)
    }
    var lower = index
    while lower > 0, questions[lower - 1].step == step {
      lower -= 1
    }
    var upper = index + 1
    while upper < questions.count, questions[upper].step == step {
      upper += 1
    }
    return lower..<upper
  }

  /// Whether the question on screen follows another of its step, whose row already shows how it
  /// went.
  var isMidStep: Bool {
    currentStepRange.lowerBound < currentQuestionIndex
  }

  /// The current verb's rows, in the verb page's order. Nil unless the question belongs to a step
  /// of Verb Essentials.
  var essentialsRows: [VerbEssentialsRow]? {
    guard scope.isVerbEssentials, let question = currentQuestion, question.step != nil else {
      return nil
    }
    let step = currentStepRange
    return KeyConjugation.forms(of: question.verb).map { form in
      guard let index = step.first(where: { questions[$0].tense == form.key.tense }) else {
        return VerbEssentialsRow(key: form.key, content: .given(form: form.form))
      }
      let content: VerbEssentialsRow.Content
      if index < currentQuestionIndex, results.indices.contains(index) {
        content = .answered(form: correctAnswers[index], result: results[index])
      } else if index == currentQuestionIndex {
        content = .current
      } else {
        content = .pending
      }
      return VerbEssentialsRow(key: form.key, content: content)
    }
  }

  /// Where a missed question returns, and the step it joins.
  ///
  /// A question shown alone returns after `reaskGap` others. A Verb Essentials blank returns after
  /// the next verb, as a step of its own whose other rows are given, so that a re-ask never lands
  /// among another verb's blanks. A second miss in the same verb joins the first's re-ask, after
  /// it, which keeps the verb page's order.
  static func reaskPlacement(of index: Int, in questions: [QuizQuestion]) -> (position: Int, step: Int?) {
    let question = questions[index]
    guard let step = question.step else {
      return (min(index + 1 + reaskGap, questions.count), nil)
    }
    let later = questions.indices.dropFirst(index + 1)
    if let joined = later.first(where: { questions[$0].isReask && questions[$0].verb == question.verb && questions[$0].step != nil }),
       let joinedStep = questions[joined].step {
      return (stepEnd(from: joined, in: questions), joinedStep)
    }
    let newStep = (questions.compactMap(\.step).max() ?? step) + 1
    let nextStart = stepEnd(from: index, in: questions)
    guard nextStart < questions.count else {
      return (questions.count, newStep)
    }
    return (stepEnd(from: nextStart, in: questions), newStep)
  }

  /// The index after the last question of the step that holds `index`.
  private static func stepEnd(from index: Int, in questions: [QuizQuestion]) -> Int {
    guard let step = questions[index].step else {
      return index + 1
    }
    return questions.indices.dropFirst(index + 1).first { questions[$0].step != step } ?? questions.count
  }
}
