//
//  TenseBridge.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The seam between the `DisplayTense`/`DisplayPersonNumber` vocabulary the UI is
// structured around and the engine (`Conjugator`/`EngineTense`/`EnginePersonNumber`).
// The simple tenses map case-for-case onto `EngineTense`; the tenses `EngineTense`
// deliberately does not model are composed here:
//
//   - the nine compound (perfect) tenses — `CompoundTense` (haber + participle),
//   - imperativo negativo — "no " + presente de subjuntivo,
//   - futuro de subjuntivo — derived from the -ra imperfect subjunctive by
//     swapping the ending's -a- for -e- (hablara → hablare, tuviéramos →
//     tuviéremos), the same relation as building it from the preterite 3p stem.
//
// Every successful form comes back with its irregular span UPPERCASE
// (`IrregularityMarker`, diffing against the verb's regular composition), the
// encoding `ConjugationText` renders as the red irregularity highlight.
//
// A defective verb's formless slot surfaces as `.noForm`, which the UI renders
// as a blank row.
nonisolated enum TenseBridge {
  /// Conjugate a `(DisplayTense, DisplayPersonNumber)` slot through `Conjugator`,
  /// irregularity-marked for display.
  ///
  /// `pronoun` defaults to `.omitted`, the bare form the engine has always returned, which the
  /// oracle tests, the corpus dumps, and the compound tenses' auxiliary rely on. Every surface
  /// that shows a form to a learner passes `.written`, so that a reflexive-only verb reads as
  /// Spanish writes it (me arrepiento, arrepiéntete). See `ReflexivePronoun`.
  static func conjugate(
    infinitive: String,
    tense: DisplayTense,
    personNumber: DisplayPersonNumber,
    pronoun: ReflexivePronoun = .omitted
  ) -> Result<String, ConjugatorError> {
    let marked = markedConjugate(infinitive: infinitive, tense: tense, personNumber: personNumber)
    guard pronoun == .written, ReflexivePronoun.isReflexiveOnly(infinitive) else {
      return marked
    }
    return marked.map { ReflexivePronoun.attach(to: $0, tense: tense, personNumber: personNumber) }
  }

  private static func markedConjugate(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> Result<String, ConjugatorError> {
    let result = unmarkedConjugate(infinitive: infinitive, tense: tense, personNumber: personNumber)
    guard case let .success(form) = result else {
      return result
    }
    // The regular composition may be written two ways, since the 2010 Ortografía takes the
    // accent off a monosyllable: ir's bare ending áis is ais. The spelling that explains more of
    // the form is the baseline, so vayáis marks VAYáis.
    let markings = regularForms(infinitive: infinitive, tense: tense, personNumber: personNumber)
      .map { IrregularityMarker.marked(form: form, regular: $0) }
    guard let marking = markings.min(by: { $0.filter(\.isUppercase).count < $1.filter(\.isUppercase).count }) else {
      return result
    }
    return .success(marking)
  }

  /// The display person's `EnginePersonNumber` counterpart, or nil for `.none`.
  static func enginePersonNumber(for personNumber: DisplayPersonNumber) -> EnginePersonNumber? {
    switch personNumber {
    case .firstSingular:
      return .firstSingular
    case .secondSingularTú:
      return .secondSingular
    case .secondSingularVos:
      return .secondSingularVos
    case .thirdSingular:
      return .thirdSingular
    case .firstPlural:
      return .firstPlural
    case .secondPlural:
      return .secondPlural
    case .thirdPlural:
      return .thirdPlural
    case .none:
      return nil
    }
  }

  /// The `EngineTense` case for a simple display tense, or nil for the tenses `EngineTense`
  /// does not model (compounds, futuro de subjuntivo, imperativo negativo, and
  /// the pseudo-tenses).
  static func simpleEngineTense(for tense: DisplayTense, personNumber: EnginePersonNumber) -> EngineTense? {
    switch tense {
    case .presenteDeIndicativo:
      return .presenteDeIndicativo(personNumber)
    case .pretérito:
      return .pretérito(personNumber)
    case .imperfectoDeIndicativo:
      return .imperfectoDeIndicativo(personNumber)
    case .futuroDeIndicativo:
      return .futuro(personNumber)
    case .condicional:
      return .condicional(personNumber)
    case .presenteDeSubjuntivo:
      return .presenteDeSubjuntivo(personNumber)
    case .imperfectoDeSubjuntivo1:
      return .imperfectoDeSubjuntivoRa(personNumber)
    case .imperfectoDeSubjuntivo2:
      return .imperfectoDeSubjuntivoSe(personNumber)
    case .imperativoPositivo:
      return .imperativoAfirmativo(personNumber)
    default:
      return nil
    }
  }

  private static func unmarkedConjugate(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> Result<String, ConjugatorError> {
    switch tense {
    case .infinitivo, .translation:
      fatalError("\(tense.displayName) is not a conjugation; look it up directly.")
    case .gerundio:
      return Conjugator.conjugate(infinitive: infinitive, tense: .gerundio)
    case .participio:
      return Conjugator.conjugate(infinitive: infinitive, tense: .participioPasado)
    case .raízFutura:
      return Conjugator.futureRoot(infinitive: infinitive)
    case .imperativoPositivo, .imperativoNegativo:
      guard personNumber != .firstSingular, let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        return .failure(.imperativeNotAvailable(.firstSingular))
      }
      if tense == .imperativoPositivo {
        return Conjugator.conjugate(infinitive: infinitive, tense: .imperativoAfirmativo(enginePersonNumber))
      } else {
        return Conjugator.conjugate(infinitive: infinitive, tense: .presenteDeSubjuntivo(enginePersonNumber)).map { "no " + $0 }
      }
    case .futuroDeSubjuntivo:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        fatalError("\(tense.displayName) requires a person.")
      }
      return Conjugator.conjugate(infinitive: infinitive, tense: .imperfectoDeSubjuntivoRa(enginePersonNumber)).map {
        futureSubjunctive(fromRaForm: $0, personNumber: enginePersonNumber)
      }
    case .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber), let engineTense = simpleEngineTense(for: tense, personNumber: enginePersonNumber) else {
        fatalError("\(tense.displayName) requires a person.")
      }
      return Conjugator.conjugate(infinitive: infinitive, tense: engineTense)
    case .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      return CompoundTense.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber)
    }
  }

  /// The same slot conjugated with a **feature-less** regular model — the
  /// baseline whose differing span is the verb's irregularity — in each spelling the engine
  /// accepts for it (`Conjugator.conjugateAll`).
  private static func regularForms(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> [String] {
    guard let base = RegularRoot(infinitive: infinitive) else {
      return []
    }
    let regularModel = VerbModel(base: base)
    func regular(_ engineTense: EngineTense) -> [String] {
      (try? Conjugator.conjugateAll(infinitive: infinitive, tense: engineTense, model: regularModel).get()) ?? []
    }
    switch tense {
    case .infinitivo, .translation:
      return []
    case .gerundio:
      return regular(.gerundio)
    case .participio:
      return regular(.participioPasado)
    case .raízFutura:
      return regular(.futuro(.firstSingular)).map { String($0.dropLast()) }
    case .imperativoPositivo:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        return []
      }
      return regular(.imperativoAfirmativo(enginePersonNumber))
    case .imperativoNegativo:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        return []
      }
      return regular(.presenteDeSubjuntivo(enginePersonNumber)).map { "no " + $0 }
    case .futuroDeSubjuntivo:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        return []
      }
      return regular(.imperfectoDeSubjuntivoRa(enginePersonNumber)).map {
        futureSubjunctive(fromRaForm: $0, personNumber: enginePersonNumber)
      }
    case .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber), let engineTense = simpleEngineTense(for: tense, personNumber: enginePersonNumber) else {
        return []
      }
      return regular(engineTense)
    case .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      guard case let .success(haberTense) = tense.haberTenseForCompoundTense() else {
        return []
      }
      let participles = regularForms(infinitive: infinitive, tense: .participio, personNumber: .none)
      return regularForms(infinitive: DisplayTense.auxiliary, tense: haberTense, personNumber: personNumber).flatMap { auxiliary in
        participles.map { auxiliary + " " + $0 }
      }
    }
  }

  /// Futuro de subjuntivo = the -ra imperfect subjunctive with the ending's -a-
  /// swapped for -e- (hablara → hablare, tuvieran → tuvieren, habláramos →
  /// habláremos). Deriving from the computed -ra form means every strong
  /// preterite stem rides through for free, exactly as it does for the -ra/-se
  /// pair.
  private static func futureSubjunctive(fromRaForm raForm: String, personNumber: EnginePersonNumber) -> String {
    switch personNumber {
    case .firstSingular, .thirdSingular:
      return raForm.dropLast(1) + "e"      // -ra → -re
    case .secondSingular, .secondSingularVos:
      return raForm.dropLast(2) + "es"     // -ras → -res
    case .thirdPlural:
      return raForm.dropLast(2) + "en"     // -ran → -ren
    case .firstPlural:
      return raForm.dropLast(4) + "emos"   // -ramos → -remos
    case .secondPlural:
      return raForm.dropLast(3) + "eis"    // -rais → -reis
    }
  }
}
