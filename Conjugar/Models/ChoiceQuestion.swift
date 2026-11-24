//
//  ChoiceQuestion.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The same sentence in two tenses, of which the learner picks the one a speaker would use: "De
/// niña, Ana jugaba al tenis todos los sábados." over "…jugó…", since a habit in the past takes the
/// imperfecto. The items live in `ChoiceQuestions.json`. Claude drafts them, `ChoiceQuestionTests`
/// confirms both sentences against the engine, and each is reviewed before it ships, which
/// `reviewed` records.
///
/// Each sentence is read as a Complete the Sentence sentence is (`GapSentence`), so the braces,
/// the tú or vos rule, and the machine check serve both. The sentences differ only inside their
/// braces.
nonisolated struct ChoiceQuestion: Decodable, Identifiable, Equatable, Sendable {
  struct Option: Decodable, Equatable, Sendable {
    /// A `DisplayTense` case name.
    let tense: String
    /// The sentence, with the words of the form in braces.
    let es: String
  }

  let id: String
  /// The bare infinitive, a key of the verb map.
  let verb: String
  /// A `DisplayPersonNumber` raw value, which both sentences share. `ss` is asked in tú or vos.
  let person: String
  /// The `QuizLevel` from which the item is asked.
  let level: String
  /// A `ChoiceRegion` raw value for an item whose answer is the usage of one region, which only
  /// that region's learners are asked. Absent for an item true in both.
  let region: String?
  /// A `ChoiceReason` raw value.
  let reason: String
  let right: Option
  let other: Option
  let en: String
  let reviewed: Bool

  var quizLevel: QuizLevel? {
    QuizLevel(rawValue: level)
  }

  var choiceRegion: ChoiceRegion? {
    region.flatMap(ChoiceRegion.init(rawValue:))
  }

  var choiceReason: ChoiceReason? {
    ChoiceReason(rawValue: reason)
  }

  var rightSentence: GapSentence {
    sentence(right, suffix: "right")
  }

  var otherSentence: GapSentence {
    sentence(other, suffix: "other")
  }

  private func sentence(_ option: Option, suffix: String) -> GapSentence {
    GapSentence(id: "\(id).\(suffix)", verb: verb, tense: option.tense, person: person, es: option.es, en: en, reviewed: reviewed)
  }

  /// Whether a quiz at `level` in `region` asks this item: from the item's own level up, in its
  /// region if it names one, and only where the level asks the right sentence's verb in its cell.
  /// The other sentence's cell may be one no level asks, as the condicional after si is, since the
  /// learner reads it and is never asked to write it.
  func isAskable(at level: QuizLevel, in region: ChoiceRegion) -> Bool {
    guard
      let quizLevel,
      let from = QuizLevel.allCases.firstIndex(of: quizLevel),
      let at = QuizLevel.allCases.firstIndex(of: level),
      at >= from
    else {
      return false
    }
    if self.region != nil, choiceRegion != region {
      return false
    }
    return rightSentence.isAskable(at: level)
  }

  /// The line the card shows once the learner has chosen, naming the tenses as the card does.
  @MainActor var reasonLine: String {
    let rightName = rightSentence.displayTense?.sentenceDisplayName ?? ""
    let otherName = otherSentence.displayTense?.sentenceDisplayName ?? ""
    return choiceReason?.line(right: rightName, other: otherName) ?? ""
  }
}

/// The region of an item whose answer differs between Spain and Latin America.
nonisolated enum ChoiceRegion: String, CaseIterable, Sendable {
  case spain
  case latinAmerica
}

/// Why a speaker uses the right sentence's tense. Few reasons serve many items, so each is
/// written and translated once, in `Localizable.xcstrings`, with the tenses' names filled in.
nonisolated enum ChoiceReason: String, CaseIterable, Sendable {
  case actionUnderWay = "action_under_way"
  case belief
  case comoSi = "como_si"
  case descriptionInThePast = "description_in_the_past"
  case doubtOrDenial = "doubt_or_denial"
  case earlierPast = "earlier_past"
  case emotion
  case finishedEvent = "finished_event"
  case futureAfterCuando = "future_after_cuando"
  case futureInThePast = "future_in_the_past"
  case guessAboutThePresent = "guess_about_the_present"
  case habitAfterCuando = "habit_after_cuando"
  case habitInThePast = "habit_in_the_past"
  case hopeWithOjalá = "hope_with_ojala"
  case influence
  case interruptingEvent = "interrupting_event"
  case judgment
  case likelySi = "likely_si"
  case negativeCommand = "negative_command"
  case pastTrigger = "past_trigger"
  case periodNowOver = "period_now_over"
  case resultOfCondition = "result_of_condition"
  case timeAndAgeInThePast = "time_and_age_in_the_past"
  case todayInLatinAmerica = "today_in_latin_america"
  case todayInSpain = "today_in_spain"
  case unlikelySi = "unlikely_si"
  case wishContraryToFact = "wish_contrary_to_fact"

  /// Whether the line names the other sentence's tense too, as "never the condicional" does.
  var namesBothTenses: Bool {
    switch self {
    case .comoSi, .likelySi, .negativeCommand, .unlikelySi:
      return true
    default:
      return false
    }
  }

  @MainActor func line(right: String, other: String) -> String {
    switch self {
    case .actionUnderWay:
      return L.Choice.reasonActionUnderWay(right)
    case .belief:
      return L.Choice.reasonBelief(right)
    case .comoSi:
      return L.Choice.reasonComoSi(right: right, other: other)
    case .descriptionInThePast:
      return L.Choice.reasonDescriptionInThePast(right)
    case .doubtOrDenial:
      return L.Choice.reasonDoubtOrDenial(right)
    case .earlierPast:
      return L.Choice.reasonEarlierPast(right)
    case .emotion:
      return L.Choice.reasonEmotion(right)
    case .finishedEvent:
      return L.Choice.reasonFinishedEvent(right)
    case .futureAfterCuando:
      return L.Choice.reasonFutureAfterCuando(right)
    case .futureInThePast:
      return L.Choice.reasonFutureInThePast(right)
    case .guessAboutThePresent:
      return L.Choice.reasonGuessAboutThePresent(right)
    case .habitAfterCuando:
      return L.Choice.reasonHabitAfterCuando(right)
    case .habitInThePast:
      return L.Choice.reasonHabitInThePast(right)
    case .hopeWithOjalá:
      return L.Choice.reasonHopeWithOjalá(right)
    case .influence:
      return L.Choice.reasonInfluence(right)
    case .interruptingEvent:
      return L.Choice.reasonInterruptingEvent(right)
    case .judgment:
      return L.Choice.reasonJudgment(right)
    case .likelySi:
      return L.Choice.reasonLikelySi(right: right, other: other)
    case .negativeCommand:
      return L.Choice.reasonNegativeCommand(right: right, other: other)
    case .pastTrigger:
      return L.Choice.reasonPastTrigger(right)
    case .periodNowOver:
      return L.Choice.reasonPeriodNowOver(right)
    case .resultOfCondition:
      return L.Choice.reasonResultOfCondition(right)
    case .timeAndAgeInThePast:
      return L.Choice.reasonTimeAndAgeInThePast(right)
    case .todayInLatinAmerica:
      return L.Choice.reasonTodayInLatinAmerica(right)
    case .todayInSpain:
      return L.Choice.reasonTodayInSpain(right)
    case .unlikelySi:
      return L.Choice.reasonUnlikelySi(right: right, other: other)
    case .wishContraryToFact:
      return L.Choice.reasonWishContraryToFact(right)
    }
  }
}

/// A choice as asked: the item, which of the two places shows the right sentence, so that the
/// right one is not always first, and the learner's tú or vos, in which a second-person item's
/// sentences are shown.
nonisolated struct ChoicePrompt: Equatable, Sendable {
  /// One sentence as the card shows it: its words around the form, the form in the person asked,
  /// and its tense's name.
  struct Option: Equatable, Sendable {
    let before: String
    let form: String
    let after: String
    let tense: DisplayTense
    let isRight: Bool

    var sentence: String {
      before + form + after
    }
  }

  let question: ChoiceQuestion
  let rightIndex: Int
  let secondSingular: DisplayPersonNumber

  var options: [Option] {
    let right = option(question.rightSentence, isRight: true)
    let other = option(question.otherSentence, isRight: false)
    return (rightIndex == 0 ? [right, other] : [other, right]).compactMap { $0 }
  }

  /// The question a choice asks, of the verb in the right sentence's cell, in the learner's tú or
  /// vos.
  var quizQuestion: QuizQuestion? {
    QuizQuestion.sentence(question.rightSentence, secondSingular: secondSingular)?.choosing(self)
  }

  /// The form of the option at `index`, as the results show it.
  func form(at index: Int) -> String? {
    let options = options
    return options.indices.contains(index) ? options[index].form : nil
  }

  private func option(_ sentence: GapSentence, isRight: Bool) -> Option? {
    guard
      let tense = sentence.displayTense,
      let parts = QuizQuestion.sentence(sentence, secondSingular: secondSingular)?.completedSentenceParts
    else {
      return nil
    }
    return Option(before: parts.before, form: parts.blank, after: parts.after, tense: tense, isRight: isRight)
  }
}

nonisolated enum ChoiceQuestions {
  /// Every item in the bundle, drafts included.
  static let all: [ChoiceQuestion] = {
    let bundle = Bundle.main.url(forResource: "ChoiceQuestions", withExtension: "json") != nil ? Bundle.main : Bundle(for: BundleToken.self)
    return bundle.url(forResource: "ChoiceQuestions", withExtension: "json")
      .flatMap { try? Data(contentsOf: $0) }
      .map(decode) ?? []
  }()

  private final class BundleToken {}

  static func decode(_ data: Data) -> [ChoiceQuestion] {
    (try? JSONDecoder().decode([ChoiceQuestion].self, from: data)) ?? []
  }

  /// The items a quiz at a level asks in a region. A debug build asks drafts too, marked as drafts
  /// on the card, as Complete the Sentence does.
  static func askable(
    at level: QuizLevel,
    in region: ChoiceRegion,
    from items: [ChoiceQuestion] = all,
    includesDrafts: Bool = GapSentences.includesDrafts
  ) -> [ChoiceQuestion] {
    items.filter { ($0.reviewed || includesDrafts) && $0.isAskable(at: level, in: region) }
  }
}

extension QuizDraw {
  /// One choice for a round, from those the session has not asked, or from all once every one
  /// has been. Nil when the level has none, as Beginner has none.
  nonisolated static func choice(
    from candidates: [ChoiceQuestion],
    excluded: Set<String>,
    secondSingular: DisplayPersonNumber,
    using generator: inout some RandomNumberGenerator
  ) -> ChoicePrompt? {
    let sorted = candidates.sorted { $0.id < $1.id }
    let unasked = sorted.filter { !excluded.contains($0.id) }
    guard let question = (unasked.isEmpty ? sorted : unasked).randomElement(using: &generator) else {
      return nil
    }
    return ChoicePrompt(question: question, rightIndex: Int.random(in: 0...1, using: &generator), secondSingular: secondSingular)
  }

  /// Where a round's choice goes: anywhere but first, so that a round opens on a typed question
  /// with the keyboard up.
  nonisolated static func choicePosition(in count: Int, using generator: inout some RandomNumberGenerator) -> Int {
    count < 1 ? count : Int.random(in: 1...count, using: &generator)
  }
}
