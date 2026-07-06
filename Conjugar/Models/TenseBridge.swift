//
//  TenseBridge.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The seam between the legacy `DisplayTense`/`DisplayPersonNumber` vocabulary the UI is
// structured around and the new engine (`Conjugator2`/`EngineTense`/`EnginePersonNumber`).
// The simple tenses map case-for-case onto `EngineTense`; the tenses `EngineTense`
// deliberately does not model are composed here:
//
//   - the nine compound (perfect) tenses — `CompoundTense` (haber + participle),
//   - imperativo negativo — "no " + presente de subjuntivo,
//   - futuro de subjuntivo — derived from the -ra imperfect subjunctive by
//     swapping the ending's -a- for -e- (hablara → hablare, tuviéramos →
//     tuviéremos), the same relation the legacy engine exploited via the
//     preterite 3p stem.
//
// Every successful form comes back with its irregular span UPPERCASE
// (`IrregularityMarker`, diffing against the verb's regular composition), the
// encoding `String.conjugatedString` renders as the red irregularity highlight —
// exactly the convention the legacy verbs.xml data hand-encoded.
//
// A defective verb's formless slot surfaces as `.noForm`, which the UI renders
// as a blank row (the legacy engine's "df" sentinel played this role).
enum TenseBridge {
  /// Conjugate a legacy `(DisplayTense, DisplayPersonNumber)` slot through `Conjugator2`,
  /// irregularity-marked for display.
  static func conjugate(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> Result<String, Conjugator2Error> {
    let result = unmarkedConjugate(infinitive: infinitive, tense: tense, personNumber: personNumber)
    guard
      case let .success(form) = result,
      let regular = regularForm(infinitive: infinitive, tense: tense, personNumber: personNumber) else {
      return result
    }
    return .success(IrregularityMarker.marked(form: form, regular: regular))
  }

  /// The legacy person's `EnginePersonNumber` counterpart, or nil for `.none`.
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

  /// The `EngineTense` case for a legacy simple tense, or nil for the tenses `EngineTense`
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

  // MARK: - The unmarked conjugation

  private static func unmarkedConjugate(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> Result<String, Conjugator2Error> {
    switch tense {
    case .infinitivo, .translation:
      fatalError("\(tense.displayName) is not a conjugation; look it up directly.")
    case .gerundio:
      return Conjugator2.conjugate(infinitive: infinitive, tense: .gerundio)
    case .participio:
      return Conjugator2.conjugate(infinitive: infinitive, tense: .participioPasado)
    case .raízFutura:
      return Conjugator2.futureRoot(infinitive: infinitive)
    case .imperativoPositivo, .imperativoNegativo:
      guard personNumber != .firstSingular, let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        return .failure(.imperativeNotAvailable(.firstSingular))
      }
      if tense == .imperativoPositivo {
        return Conjugator2.conjugate(infinitive: infinitive, tense: .imperativoAfirmativo(enginePersonNumber))
      } else {
        return Conjugator2.conjugate(infinitive: infinitive, tense: .presenteDeSubjuntivo(enginePersonNumber)).map { "no " + $0 }
      }
    case .futuroDeSubjuntivo:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        fatalError("\(tense.displayName) requires a person.")
      }
      return Conjugator2.conjugate(infinitive: infinitive, tense: .imperfectoDeSubjuntivoRa(enginePersonNumber)).map {
        futureSubjunctive(fromRaForm: $0, personNumber: enginePersonNumber)
      }
    case .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber), let engineTense = simpleEngineTense(for: tense, personNumber: enginePersonNumber) else {
        fatalError("\(tense.displayName) requires a person.")
      }
      return Conjugator2.conjugate(infinitive: infinitive, tense: engineTense)
    case .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      return CompoundTense.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber)
    }
  }

  // MARK: - The regular baseline (what irregularity marking diffs against)

  /// The same slot conjugated with a **feature-less** regular model — the
  /// baseline whose differing span is the verb's irregularity.
  private static func regularForm(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> String? {
    guard let base = RegularRoot2(infinitive: infinitive) else {
      return nil
    }
    let regularModel = VerbModel2(base: base)
    func regular(_ engineTense: EngineTense) -> String? {
      if case let .success(form) = Conjugator2.conjugate(infinitive: infinitive, tense: engineTense, model: regularModel) {
        return form
      }
      return nil
    }
    switch tense {
    case .infinitivo, .translation:
      return nil
    case .gerundio:
      return regular(.gerundio)
    case .participio:
      return regular(.participioPasado)
    case .raízFutura:
      return regular(.futuro(.firstSingular)).map { String($0.dropLast()) }
    case .imperativoPositivo:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        return nil
      }
      return regular(.imperativoAfirmativo(enginePersonNumber))
    case .imperativoNegativo:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        return nil
      }
      return regular(.presenteDeSubjuntivo(enginePersonNumber)).map { "no " + $0 }
    case .futuroDeSubjuntivo:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber) else {
        return nil
      }
      return regular(.imperfectoDeSubjuntivoRa(enginePersonNumber)).map {
        futureSubjunctive(fromRaForm: $0, personNumber: enginePersonNumber)
      }
    case .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2:
      guard let enginePersonNumber = enginePersonNumber(for: personNumber), let engineTense = simpleEngineTense(for: tense, personNumber: enginePersonNumber) else {
        return nil
      }
      return regular(engineTense)
    case .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      guard
        case let .success(haberTense) = tense.haberTenseForCompoundTense(),
        let auxiliary = regularForm(infinitive: DisplayTense.auxiliary, tense: haberTense, personNumber: personNumber),
        let participle = regularForm(infinitive: infinitive, tense: .participio, personNumber: .none) else {
        return nil
      }
      return auxiliary + " " + participle
    }
  }

  // MARK: - Futuro de subjuntivo

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
