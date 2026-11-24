//
//  AnswerDiagnosis.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Why a wrong quiz answer is wrong, in the cases where the engine can say so for certain. Every
/// case is an exact construction from the verb's own model, compared with the answer as typed,
/// never a guess at what the learner meant, because a wrong diagnosis is worse than none. An
/// answer that fits no case gets none.
nonisolated enum AnswerDiagnosis: Equatable, Sendable {
  /// no habla or no hablas for no hables: a negative command written as the affirmative command or
  /// the indicative.
  case negativeCommand
  /// buscé for busqué, escogo for escojo: a stem-final consonant left unchanged before an ending
  /// that needs another spelling of it.
  case consonantSpelling(infinitive: String, from: String, to: String, beforeE: Bool)
  /// leió for leyó: the ending's i left unchanged between vowels.
  case endingIBecomesY(infinitive: String)
  /// bullió for bulló: the ending's i kept after a palatal.
  case endingLosesI(infinitive: String, after: String)
  /// envio for envío: the stem's i or u without its written accent.
  case stemAccent(infinitive: String, vowel: String)
  /// penso for pienso, sentió for sintió.
  case stemChangeMissing(infinitive: String, from: String, to: String)
  /// piensamos for pensamos: a stem change where the verb makes none.
  case stemChangeMisplaced(infinitive: String)
  /// tení for tuve, hacido for hecho: the form a regular verb would have. `tense` is where the
  /// irregularity lies, which in a compound tense is the participle.
  case regularForm(infinitive: String, tense: DisplayTense)
  /// hablara for hablase, or the reverse, which the quiz keeps apart.
  case otherImperfectSubjunctive(givenIsRa: Bool)
  /// hablas for hablo, ha hablado for he hablado: another person of the asked tense.
  case otherPerson(tense: DisplayTense, persons: [DisplayPersonNumber])
  /// hablo for habló: another tense. Its persons are named only when the asked person is not
  /// among them.
  case otherTense(DisplayTense, persons: [DisplayPersonNumber])
}

extension AnswerDiagnosis {
  /// The one line the quiz shows, in the app's language, both in the prompt for a second attempt
  /// and in the correction.
  var line: String {
    switch self {
    case .negativeCommand:
      return L.Diagnosis.negativeCommand
    case let .consonantSpelling(infinitive, from, to, beforeE):
      return beforeE ? L.Diagnosis.consonantBeforeE(infinitive, from, to) : L.Diagnosis.consonantBeforeAO(infinitive, from, to)
    case let .endingIBecomesY(infinitive):
      return L.Diagnosis.endingIBecomesY(infinitive)
    case let .endingLosesI(infinitive, after):
      return L.Diagnosis.endingLosesI(infinitive, after)
    case let .stemAccent(infinitive, vowel):
      return L.Diagnosis.stemAccent(infinitive, vowel)
    case let .stemChangeMissing(infinitive, from, to):
      return L.Diagnosis.stemChangeMissing(infinitive, from, to)
    case let .stemChangeMisplaced(infinitive):
      return L.Diagnosis.stemChangeMisplaced(infinitive)
    case let .regularForm(infinitive, tense):
      return L.Diagnosis.regularForm(infinitive, tense.titleCaseName)
    case let .otherImperfectSubjunctive(givenIsRa):
      return givenIsRa ? L.Diagnosis.raForSe : L.Diagnosis.seForRa
    case let .otherPerson(tense, persons):
      return L.Diagnosis.otherPerson(ListFormatter.localizedString(byJoining: Self.names(of: persons, in: tense)))
    case let .otherTense(tense, persons):
      guard tense.hasPersons else {
        return L.Diagnosis.nonFinite(tense.titleCaseName)
      }
      let names = Self.names(of: persons, in: tense)
      let name = names.isEmpty ? tense.titleCaseName : "\(tense.titleCaseName) (\(names.joined(separator: ", ")))"
      return L.Diagnosis.otherTense(name)
    }
  }

  /// The persons as the verb page names them, with a command's usted and ustedes.
  private static func names(of persons: [DisplayPersonNumber], in tense: DisplayTense) -> [String] {
    persons.compactMap { MatchedForm.personName(of: ConjugationCell(tense: tense, personNumber: $0)) }
  }
}

nonisolated private extension DisplayTense {
  var hasPersons: Bool {
    switch self {
    case .infinitivo, .gerundio, .participio, .translation, .raízFutura:
      return false
    default:
      return true
    }
  }
}

nonisolated extension QuizQuestion {
  /// The diagnosis of a wrong answer, or nil when it is right or nothing certain can be said.
  /// The checks run from the most specific explanation to the least and stop at the first that
  /// fits, since one answer can fit several: dice for decir's di is both the form a regular verb
  /// would have and the presente (él), and the first says more about the learner's error.
  func diagnosis(of answer: String) -> AnswerDiagnosis? {
    guard grade(answer) != .totalMatch, writtenAnswer != nil, let model = Conjugator.model(for: verb) else {
      return nil
    }
    let typed = AnswerSpelling.candidates(for: answer, tense: tense, personNumber: personNumber).filter { !$0.isEmpty }
    guard !typed.isEmpty else {
      return nil
    }
    // The engine writes a construction such as leió as the 2010 Ortografía would, leio.
    let candidates = Set(typed + typed.map(Orthography.currentSpelling(of:)))
    let diagnoser = AnswerDiagnoser(question: self, candidates: candidates, model: model)
    return diagnoser.negativeCommand()
      ?? diagnoser.spelling()
      ?? diagnoser.stemChange()
      ?? diagnoser.regularForm()
      ?? diagnoser.otherCell()
  }
}

/// The checks behind `QuizQuestion.diagnosis(of:)`. Each builds the asked cell some wrong way and
/// asks whether the answer is that construction.
nonisolated private struct AnswerDiagnoser {
  let question: QuizQuestion
  let candidates: Set<String>
  let model: VerbModel

  private var verb: String {
    question.verb
  }

  private var citationForm: String {
    ReflexivePronoun.citationForm(of: verb)
  }

  /// The asked cell as the engine writes it, bare and lowercased.
  private var rightForm: String? {
    guard case let .success(form) = TenseBridge.conjugate(infinitive: verb, tense: question.tense, personNumber: question.personNumber) else {
      return nil
    }
    return form.lowercased()
  }

  /// The asked cell as `model` would write it, bare and, for a reflexive-only verb, with its
  /// pronoun too.
  private func forms(of model: VerbModel) -> Set<String> {
    guard case let .success(form) = TenseBridge.conjugate(infinitive: verb, tense: question.tense, personNumber: question.personNumber, model: model) else {
      return []
    }
    return withPronoun(form.lowercased(), tense: question.tense)
  }

  private func withPronoun(_ form: String, tense: DisplayTense) -> Set<String> {
    guard ReflexivePronoun.isReflexiveOnly(verb) else {
      return [form]
    }
    return [form, ReflexivePronoun.attach(to: form, tense: tense, personNumber: question.personNumber).lowercased()]
  }

  private func isAnswer(_ model: VerbModel) -> Bool {
    !forms(of: model).isDisjoint(with: candidates)
  }

  private func model(without index: Int) -> VerbModel {
    var features = model.features
    features.remove(at: index)
    return VerbModel(base: model.base, features: features)
  }

  private func model(replacing index: Int, with feature: any ConjugationFeature) -> VerbModel {
    var features = model.features
    features[index] = feature
    return VerbModel(base: model.base, features: features)
  }

  /// A negative command is no plus the presente de subjuntivo, so the affirmative command and the
  /// indicative of the same person are both the same error. usted's affirmative command is
  /// already the subjunctive, and so is a right answer.
  func negativeCommand() -> AnswerDiagnosis? {
    guard question.tense == .imperativoNegativo else {
      return nil
    }
    var wrongForms = Set<String>()
    for tense in [DisplayTense.imperativoPositivo, .presenteDeIndicativo] {
      guard case let .success(form) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: question.personNumber) else {
        continue
      }
      for written in withPronoun(form.lowercased(), tense: tense) {
        wrongForms.insert("no " + written)
      }
    }
    return wrongForms.isDisjoint(with: candidates) ? nil : .negativeCommand
  }

  /// A spelling feature left out: a stem-final consonant, the ending's i between vowels or after
  /// a palatal, or a written accent on the stem.
  func spelling() -> AnswerDiagnosis? {
    for (index, feature) in model.features.enumerated() {
      let without = model(without: index)
      switch feature {
      case let consonant as StemFinalConsonant:
        if isAnswer(without) {
          return .consonantSpelling(infinitive: citationForm, from: consonant.from, to: consonant.to, beforeE: consonant.trigger == .beforeFrontE)
        }
      case is IYHiatus:
        // The feature also writes the accent of leíste, which is not a y.
        if let rightForm, let construction = forms(of: without).first, isAnswer(without), Self.yCount(rightForm) > Self.yCount(construction) {
          return .endingIBecomesY(infinitive: citationForm)
        }
      case is AbsorbIAfterPalatal:
        if isAnswer(without), let palatal = Self.palatal(endingStemOf: verb) {
          return .endingLosesI(infinitive: citationForm, after: palatal)
        }
      case let accent as AccentStem:
        if isAnswer(without) {
          return .stemAccent(infinitive: citationForm, vowel: String(accent.vowel.plain))
        }
      default:
        continue
      }
    }
    return nil
  }

  private static func yCount(_ form: String) -> Int {
    form.filter { $0 == "y" }.count
  }

  private static func palatal(endingStemOf infinitive: String) -> String? {
    let stem = infinitive.dropLast(2)
    return ["ll", "ñ", "ch"].first { stem.hasSuffix($0) }
  }

  /// A stem change left out, or made where the verb makes none. The second is said only of a
  /// cell whose right form has no stem change at all, since sintamos changes its stem, though not
  /// as sienta does.
  func stemChange() -> AnswerDiagnosis? {
    let stemVowels = model.features.enumerated().compactMap { index, feature in
      (feature as? StemVowel).map { (index, $0) }
    }
    guard !stemVowels.isEmpty else {
      return nil
    }
    for (index, stemVowel) in stemVowels where isAnswer(model(without: index)) {
      return .stemChangeMissing(infinitive: citationForm, from: String(stemVowel.from), to: stemVowel.to)
    }
    let withoutStemVowels = VerbModel(base: model.base, features: model.features.filter { !($0 is StemVowel) })
    guard let rightForm, forms(of: withoutStemVowels).contains(rightForm) else {
      return nil
    }
    for (index, stemVowel) in stemVowels where isAnswer(model(replacing: index, with: EverywhereStemVowel(stemVowel: stemVowel))) {
      return .stemChangeMisplaced(infinitive: citationForm)
    }
    return nil
  }

  /// The cell as a regular verb would have it. Said only where the verb is irregular in more than
  /// its spelling and stem vowel, which the checks before this one name, so that leer's leiste is
  /// not called the form of a regular verb.
  func regularForm() -> AnswerDiagnosis? {
    guard isAnswer(VerbModel(base: model.base)), let rightForm else {
      return nil
    }
    let regularButForSpelling = VerbModel(base: model.base, features: model.features.filter(Self.isSpellingOrStemVowel))
    guard !forms(of: regularButForSpelling).contains(rightForm) else {
      return nil
    }
    let tense = question.tense.isCompound ? DisplayTense.participio : question.tense
    return .regularForm(infinitive: citationForm, tense: tense)
  }

  private static func isSpellingOrStemVowel(_ feature: any ConjugationFeature) -> Bool {
    feature is StemVowel || feature is StemFinalConsonant || feature is IYHiatus || feature is AbsorbIAfterPalatal
      || feature is AccentStem || feature is DiaeresisDropBeforeY || feature is DefectiveFeature
  }

  /// Another cell of the verb, in the page's order: the other imperfect subjunctive first, then
  /// another person of the asked tense, then another tense.
  func otherCell() -> AnswerDiagnosis? {
    let asked = ConjugationCell(tense: question.tense, personNumber: question.personNumber)
    let matched = Set(candidates.flatMap { ConjugationMatch.cells(of: verb, equalTo: $0) })
    let cells = ConjugationMatch.allCells.filter { matched.contains($0) && $0 != asked }
    guard let first = cells.first else {
      return nil
    }
    if let counterpart = Self.otherImperfectSubjunctive[question.tense],
       cells.contains(ConjugationCell(tense: counterpart, personNumber: question.personNumber)) {
      return .otherImperfectSubjunctive(givenIsRa: counterpart == .imperfectoDeSubjuntivo1 || counterpart == .pluscuamperfectoDeSubjuntivo1)
    }
    let sameTense = cells.filter { $0.tense == question.tense }
    if !sameTense.isEmpty {
      return .otherPerson(tense: question.tense, persons: sameTense.map(\.personNumber))
    }
    var persons = cells.filter { $0.tense == first.tense && $0.personNumber != .none }.map(\.personNumber)
    if persons.contains(question.personNumber) {
      persons = []
    }
    return .otherTense(first.tense, persons: persons)
  }

  private static let otherImperfectSubjunctive: [DisplayTense: DisplayTense] = [
    .imperfectoDeSubjuntivo1: .imperfectoDeSubjuntivo2,
    .imperfectoDeSubjuntivo2: .imperfectoDeSubjuntivo1,
    .pluscuamperfectoDeSubjuntivo1: .pluscuamperfectoDeSubjuntivo2,
    .pluscuamperfectoDeSubjuntivo2: .pluscuamperfectoDeSubjuntivo1
  ]
}

/// A stem-vowel change made in every slot, for building piensamos.
nonisolated private struct EverywhereStemVowel: ConjugationFeature {
  let stemVowel: StemVowel

  func applies(to tense: EngineTense) -> Bool {
    true
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    stemVowel.apply(stem: stem, ending: ending, tense: tense, regularStem: regularStem)
  }
}
