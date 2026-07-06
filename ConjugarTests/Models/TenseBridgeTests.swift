//
//  TenseBridgeTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

// The legacy-vocabulary → Conjugator bridge the migrated UI conjugates through:
// simple tenses map onto `EngineTense`; the compound (perfect) tenses, imperativo
// negativo, and futuro de subjuntivo are composed/derived here because `EngineTense`
// deliberately does not model them. Expected forms were verified against the
// legacy engine's output for verbs both engines know.
//
// UPPERCASE spans in the expectations are the irregularity-highlight encoding
// (`IrregularityMarker`): the letters that differ from the verb's regular
// composition, which `conjugatedString` renders red — the same convention the
// legacy verbs.xml hand-encoded.
@Suite("TenseBridge (legacy DisplayTense/DisplayPersonNumber → Conjugator)")
struct TenseBridgeTests {
  /// Bridge-conjugate, returning the form or nil on failure (a failure surfaces
  /// as a clear mismatch).
  static func form(_ infinitive: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> String? {
    if case .success(let conjugated) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber) {
      return conjugated
    }
    return nil
  }

  // MARK: - Simple tenses ride the case-for-case mapping

  @Test("simple tenses map case-for-case onto EngineTense", arguments: [
    ("hablar", DisplayTense.presenteDeIndicativo, DisplayPersonNumber.firstSingular, "hablo"),
    ("pensar", .presenteDeIndicativo, .firstSingular, "pIenso"),
    ("pensar", .presenteDeIndicativo, .secondSingularVos, "pensás"),
    ("pagar", .pretérito, .firstSingular, "pagUé"),
    ("comer", .imperfectoDeIndicativo, .thirdPlural, "comían"),
    ("tener", .futuroDeIndicativo, .firstSingular, "tenDré"),
    ("tener", .condicional, .thirdSingular, "tenDría"),
    ("ir", .presenteDeSubjuntivo, .firstPlural, "VAYamos"),
    ("tener", .imperfectoDeSubjuntivo1, .firstSingular, "tUViera"),
    ("tener", .imperfectoDeSubjuntivo2, .firstSingular, "tUViese"),
    ("tener", .imperativoPositivo, .secondSingularTú, "teN"),
    ("hablar", .imperativoPositivo, .secondSingularVos, "hablá"),
    ("hablar", .imperativoPositivo, .thirdSingular, "hable"),
    ("subir", .gerundio, .none, "subiendo"),
    ("volver", .participio, .none, "vUELTo")
  ])
  func simpleTenses(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber, expected: String) {
    #expect(Self.form(infinitive, tense, personNumber) == expected, "\(infinitive) \(tense.displayName) \(personNumber.pronoun)")
  }

  // MARK: - Compound tenses: haber in the matching simple tense + participle

  @Test("compound tenses compose haber + participle", arguments: [
    ("hablar", DisplayTense.perfectoDeIndicativo, DisplayPersonNumber.firstSingular, "hE hablado"),
    ("comer", .pretéritoAnterior, .secondSingularTú, "hUbiste comido"),
    ("tener", .pluscuamperfectoDeIndicativo, .thirdPlural, "habían tenido"),
    ("imprimir", .futuroPerfecto, .firstSingular, "habRé imprESo"),
    ("subir", .condicionalCompuesto, .firstPlural, "habRíamos subido"),
    ("vivir", .perfectoDeSubjuntivo, .thirdSingular, "haYa vivido"),
    ("hablar", .pluscuamperfectoDeSubjuntivo1, .firstSingular, "hUbiera hablado"),
    ("hablar", .pluscuamperfectoDeSubjuntivo2, .secondPlural, "hUbieseis hablado"),
    ("volver", .futuroPerfectoDeSubjuntivo, .thirdSingular, "hUbiere vUELTo"),
    ("hacer", .perfectoDeIndicativo, .secondSingularVos, "haS hECHo")
  ])
  func compoundTenses(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber, expected: String) {
    #expect(Self.form(infinitive, tense, personNumber) == expected, "\(infinitive) \(tense.displayName) \(personNumber.pronoun)")
  }

  // MARK: - Futuro de subjuntivo: derived from the -ra imperfect subjunctive

  @Test("futuro de subjuntivo derives from the -ra form", arguments: [
    ("hablar", DisplayPersonNumber.firstSingular, "hablare"),
    ("hablar", .secondSingularTú, "hablares"),
    ("hablar", .secondSingularVos, "hablares"),
    ("hablar", .thirdSingular, "hablare"),
    ("hablar", .firstPlural, "habláremos"),
    ("hablar", .secondPlural, "hablareis"),
    ("hablar", .thirdPlural, "hablaren"),
    ("tener", .thirdPlural, "tUVieren"),
    ("ir", .firstSingular, "FUere"),
    ("comer", .firstPlural, "comiéremos")
  ])
  func futuroDeSubjuntivo(infinitive: String, personNumber: DisplayPersonNumber, expected: String) {
    #expect(Self.form(infinitive, .futuroDeSubjuntivo, personNumber) == expected, "\(infinitive) \(personNumber.pronoun)")
  }

  // MARK: - Imperativo negativo: "no" + presente de subjuntivo

  @Test("imperativo negativo is no + presente de subjuntivo", arguments: [
    ("hablar", DisplayPersonNumber.secondSingularTú, "no hables"),
    ("hablar", .secondSingularVos, "no hables"),
    ("hablar", .thirdSingular, "no hable"),
    ("hablar", .firstPlural, "no hablemos"),
    ("tener", .secondSingularTú, "no tenGas"),
    ("ir", .secondPlural, "no VAYáis")
  ])
  func imperativoNegativo(infinitive: String, personNumber: DisplayPersonNumber, expected: String) {
    #expect(Self.form(infinitive, .imperativoNegativo, personNumber) == expected, "\(infinitive) \(personNumber.pronoun)")
  }

  @Test("first-person-singular imperatives fail, as in the legacy engine")
  func noFirstPersonSingularImperative() {
    #expect(Self.form("hablar", .imperativoPositivo, .firstSingular) == nil)
    #expect(Self.form("hablar", .imperativoNegativo, .firstSingular) == nil)
  }

  // MARK: - Defective slots surface as .noForm; existing slots still conjugate

  @Test("defective slots surface as .noForm")
  func defectiveSlots() {
    #expect(TenseBridge.conjugate(infinitive: "abolir", tense: .presenteDeIndicativo, personNumber: .firstSingular) == .failure(.noForm(.presenteDeIndicativo(.firstSingular))))
    #expect(Self.form("abolir", .imperativoNegativo, .secondSingularTú) == nil)
    #expect(Self.form("abolir", .presenteDeIndicativo, .firstPlural) == "abolimos")
    #expect(Self.form("abolir", .perfectoDeIndicativo, .firstSingular) == "hE abolido")
    #expect(Self.form("abolir", .futuroDeSubjuntivo, .firstSingular) == "aboliere")
  }

  // MARK: - Pseudo-tense affordances the Verb screen uses

  @Test("gerundio, participio, and raíz futura bridge with irregularity marks")
  func pseudoTenses() {
    #expect(Self.form("ir", .gerundio, .none) == "Yendo")
    #expect(Self.form("abrir", .participio, .none) == "abIERTo")
    #expect(Self.form("tener", .raízFutura, .none) == "tenDr")
    #expect(Self.form("hablar", .raízFutura, .none) == "hablar")
  }
}
