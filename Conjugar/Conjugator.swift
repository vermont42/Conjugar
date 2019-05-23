//
//  Conjugator.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

class Conjugator {
  static let defective = "df"
  static let parent = "pe"
  static let trim = "tr"
  static let stem = "st"
  static let translation = "tn"
  static let shared = Conjugator()
  static let baseVerbs = ["hablar", "comer", "subir"]

  var verbs: [String: [String: String]] = [:]

  init() {
    verbs = VerbParser().parse()
  }

  func allVerbsArray() -> [String] {
    return Array(verbs.keys).sorted()
  }

  func regularVerbsArray() -> [String] {
    var regularVerbs: [String: [String: String]] = [:]
    for (key, value) in verbs where value[VerbType.key] != VerbType.irregular.rawValue {
      regularVerbs[key] = value
    }
    return Array(regularVerbs.keys).sorted()
  }

  func irregularVerbsArray() -> [String] {
    var irregularVerbs: [String: [String: String]] = [:]
    for (key, value) in verbs where value[VerbType.key] == VerbType.irregular.rawValue {
      irregularVerbs[key] = value
    }
    return Array(irregularVerbs.keys).sorted()
  }

  func parent(infinitive: String) -> String? {
    if let verb = verbs[infinitive], let parent = verb[Conjugator.parent] {
      return parent
    } else {
      return nil
    }
  }

  func verbType(infinitive: String) -> VerbType {
    guard let verb = verbs[infinitive] else {
      fatalError("Requested type of unsupported verb.")
    }
    guard let verbType = verb[VerbType.key] else {
      fatalError("Verb type not specified.")
    }
    switch verbType {
    case VerbType.irregular.rawValue:
      return .irregular
    case VerbType.regularAr.rawValue:
      return .regularAr
    case VerbType.regularEr.rawValue:
      return .regularEr
    case VerbType.regularIr.rawValue:
      return .regularIr
    default:
      fatalError("Unknown verb type detected.")
    }
  }

  func isDefective(infinitive: String) -> Bool {
    if let verb = verbs[infinitive] {
      if
        verb[PersonNumber.firstSingular.rawValue] != nil ||
        verb[PersonNumber.secondSingularTú.rawValue] != nil ||
        verb[PersonNumber.secondSingularVos.rawValue] != nil ||
        verb[PersonNumber.thirdSingular.rawValue] != nil ||
        verb[PersonNumber.firstPlural.rawValue] != nil ||
        verb[PersonNumber.secondPlural.rawValue] != nil ||
        verb[PersonNumber.thirdPlural.rawValue] != nil {
        return true
      } else {
        return false
      }
    } else {
      return false
    }
  }

  func conjugate(infinitive: String, tense: Tense, personNumber: PersonNumber) -> Result<String, ConjugatorError> {
    if infinitive.count < 2 {
      return .failure(.tooShort)
    }
    if personNumber == .firstSingular && (tense == .imperativoPositivo || tense == .imperativoNegativo) {
      return .failure(.noFirstPersonSingularImperative)
    }
    let spanishVerbEndingLength = 2
    let index = infinitive.index(infinitive.endIndex, offsetBy: -1 * spanishVerbEndingLength)
    let ending = String(infinitive[index...])
    if !["ar", "er", "ir", "ír"].contains(ending) {
      return .failure(.invalidEnding(ending))
    }
    if (tense == .gerundio || tense == .participio || tense == .raízFutura || tense == .translation) && personNumber != .none {
      return .failure(.noSuchConjugation(personNumber))
    }
    if (tense != .gerundio && tense != .participio && tense != .raízFutura && tense != .translation) && personNumber == .none {
      return .failure(.personNumberAbsent(tense))
    }

    if verbs[infinitive] == nil {
      let stem = String(infinitive[..<index])
      var verb: [String: String] = [:]
      if ending == "ar" {
        verb[Conjugator.parent] = "hablar"
        verb[Conjugator.stem] = stem
        verb[Conjugator.trim] = "habl"
      } else if ending == "er" {
        verb[Conjugator.parent] = "comer"
        verb[Conjugator.stem] = stem
        verb[Conjugator.trim] = "com"
      } else { // if ending == "ir"
        verb[Conjugator.parent] = "subir"
        verb[Conjugator.stem] = stem
        verb[Conjugator.trim] = "sub"
      }
      verb[Conjugator.translation] = "unknown"
      verbs[infinitive] = verb
    }
    return conjugateRecursively(infinitive: infinitive, tense: tense, personNumber: personNumber)
  }

  private func conjugateRecursively(infinitive: String, tense: Tense, personNumber: PersonNumber) -> Result<String, ConjugatorError> {
    guard var verb = verbs[infinitive] else {
      fatalError("verbs[\(infinitive)] was nil.")
    }
    if let defective = verb[personNumber.rawValue], defective == Conjugator.defective {
      return .success(Conjugator.defective)
    }
    let conjugationKey: String
    if tense == .gerundio || tense == .participio || tense == .raízFutura || tense == .translation {
      conjugationKey = tense.rawValue
    } else {
      conjugationKey = personNumber.rawValue + tense.rawValue
    }
    if tense == .raízFutura && verb[conjugationKey] == nil {
      guard let parent = verb[Conjugator.parent] else {
        fatalError("verb[\(Conjugator.parent) was nil.")
      }

      guard case .success(let parentStem) = conjugateRecursively(infinitive: parent, tense: .raízFutura, personNumber: .none) else {
        fatalError("parentStem was nil.")
      }
      let trim = verb[Conjugator.trim] ?? ""
      let stem = verb[Conjugator.stem] ?? ""
      var raízFutura: String
      if trim == "" {
        raízFutura = stem + parentStem
      } else {
        raízFutura = parentStem.replaceFirstOccurence(of: trim, with: stem)
      }
      verb[conjugationKey] = raízFutura
      return .success(raízFutura)
    }
    if let conjugation = verb[conjugationKey] {
      return .success(conjugation)
    } else if [.presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .presenteDeSubjuntivo, .gerundio, .participio].contains(tense) {
      guard let parent = verb[Conjugator.parent] else {
        fatalError("verb[\(Conjugator.parent) was nil.")
      }
      guard case .success(let parentConjugation) = conjugateRecursively(infinitive: parent, tense: tense, personNumber: personNumber) else {
        fatalError("parentConjugation was nil.")
      }
      let trim: String
      let stem: String
      if (tense == .futuroDeIndicativo || tense == .condicional) && verb[Tense.raízFutura.rawValue] != nil {
        trim = parent
        stem = verb[Tense.raízFutura.rawValue] ?? ""
      } else {
        trim = verb[Conjugator.trim] ?? ""
        stem = verb[Conjugator.stem] ?? ""
      }
      var conjugation: String
      if trim == "" {
        conjugation = stem + parentConjugation
      } else {
        conjugation = parentConjugation.replaceFirstOccurence(of: trim, with: stem)
      }
      verb[conjugationKey] = conjugation
      verbs[infinitive] = verb
      return .success(conjugation)
    } else if [Tense.futuroDeIndicativo, Tense.condicional].contains(tense) {
      var futureStem = verb[Tense.raízFutura.rawValue]
      if futureStem == nil {
        guard let parent = verb[Conjugator.parent] else {
          fatalError("verb[\(Conjugator.parent) was nil.")
        }
        guard case .success(let parentStem) = conjugateRecursively(infinitive: parent, tense: .raízFutura, personNumber: .none) else {
          fatalError("parentStem was nil.")
        }
        let trim = verb[Conjugator.trim] ?? ""
        let stem = verb[Conjugator.stem] ?? ""
        if trim == "" {
          futureStem = stem + parentStem
        } else {
          futureStem = parentStem.replaceFirstOccurence(of: trim, with: stem)
        }
      }
      let conjugation = (futureStem ?? "") + endingFor(tense: tense, personNumber: personNumber)
      verb[conjugationKey] = conjugation
      return .success(conjugation)
    } else if [Tense.imperfectoDeSubjuntivo1, Tense.imperfectoDeSubjuntivo2, Tense.futuroDeSubjuntivo].contains(tense) {
      let stemWithRon: String
      if let defective = verb[PersonNumber.thirdPlural.rawValue], defective == Conjugator.defective {
        guard let parent = verb[Conjugator.parent] else {
          fatalError("verb[\(Conjugator.parent) was nil.")
        }
        guard case .success(let parentStem) = conjugateRecursively(infinitive: parent, tense: .pretérito, personNumber: .thirdPlural) else {
          fatalError("parentStem was nil.")
        }
        let trim = verb[Conjugator.trim] ?? ""
        let stem = verb[Conjugator.stem] ?? ""
        if trim == "" {
          stemWithRon = stem + parentStem
        } else {
          stemWithRon = parentStem.replaceFirstOccurence(of: trim, with: stem)
        }
      } else {
        guard case .success(let nonDefectiveStemWithRon) = conjugateRecursively(infinitive: infinitive, tense: .pretérito, personNumber: .thirdPlural) else {
          fatalError("nonDefectiveStemWithRon was nil.")
        }
        stemWithRon = nonDefectiveStemWithRon
      }
      let endIndex = stemWithRon.index(stemWithRon.endIndex, offsetBy: -3)
      let stemRange = stemWithRon.startIndex ..< endIndex
      var stem = String(stemWithRon[stemRange])
      if personNumber == .firstPlural {
        let lastCharIndex = stem.index(stem.endIndex, offsetBy: -1)
        let lastChar = stem[lastCharIndex...]
        let accentedLastChar: String
        if lastChar == "a" {
          accentedLastChar = "á"
        } else {
          accentedLastChar = "é"
        }
        let stemWithoutLastChar = stem[..<lastCharIndex]
        stem = stemWithoutLastChar + accentedLastChar
      }
      return .success(stem + endingFor(tense: tense, personNumber: personNumber))
    } else if [.perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto, .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1, .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo].contains(tense) {
      let haberTenseResult = tense.haberTenseForCompoundTense()
      let haberTense: Tense
      switch haberTenseResult {
      case let .success(auxiliaryTense):
        haberTense = auxiliaryTense
      case let .failure(.noHaberForm(form)):
        return .failure(.tenseNotImplemented(form))
      }
      guard case .success(let auxiliary) = conjugateRecursively(infinitive: Tense.auxiliary, tense: haberTense, personNumber: personNumber) else {
        fatalError("auxiliary was nil.")
      }
      guard case .success(let participle) = conjugateRecursively(infinitive: infinitive, tense: .participio, personNumber: .none) else {
        fatalError("participle was nil.")
      }

      return .success(auxiliary + " " + participle)
    } else if tense == .imperativoPositivo {
      if personNumber == .firstSingular {
        return .failure(.noFirstPersonSingularImperative)
      } else if [.thirdSingular, .firstPlural, .thirdPlural].contains(personNumber) {
        guard case .success(let conjugation) = conjugateRecursively(infinitive: infinitive, tense: .presenteDeSubjuntivo, personNumber: personNumber) else {
          fatalError("conjugation was nil.")
        }

        return .success(conjugation)
      } else if personNumber == .secondSingularTú {
          if let conjugation = verbs[infinitive]?[PersonNumber.secondSingularTú.rawValue + Tense.imperativoPositivo.rawValue] {
            return .success(conjugation)
          } else {
            guard let parent = verb[Conjugator.parent] else {
              fatalError("parent was nil.")
            }
            guard case .success(let parentConjugation) = conjugateRecursively(infinitive: parent, tense: .imperativoPositivo, personNumber: .secondSingularTú) else {
              fatalError("parentConjugation was nil.")
            }

            let trim = verb[Conjugator.trim] ?? ""
            let stem = verb[Conjugator.stem] ?? ""
            var conjugation: String
            if trim == "" {
              conjugation = stem + parentConjugation
            } else {
              conjugation = parentConjugation.replaceFirstOccurence(of: trim, with: stem)
            }
            verb[conjugationKey] = conjugation
            verbs[infinitive] = verb
            return .success(conjugation)
          }
      } else if personNumber == .secondSingularVos {
        if let conjugation = verbs[infinitive]?[PersonNumber.secondSingularVos.rawValue + Tense.imperativoPositivo.rawValue] {
          return .success(conjugation)
        } else {
          guard case .success(let parentConjugation) = conjugateRecursively(infinitive: verb[Conjugator.parent] ?? "", tense: .imperativoPositivo, personNumber: .secondSingularVos) else {
            fatalError("parentConjugation was nil.")
          }
          let trim = verb[Conjugator.trim] ?? ""
          let stem = verb[Conjugator.stem] ?? ""
          var conjugation: String
          if trim == "" {
            conjugation = stem + parentConjugation
          } else {
            conjugation = parentConjugation.replaceFirstOccurence(of: trim, with: stem)
          }
          verb[conjugationKey] = conjugation
          verbs[infinitive] = verb
          return .success(conjugation)
        }
      } else /* personNumber == .secondPlural */ {
        return .success(String(infinitive[..<infinitive.index(infinitive.endIndex, offsetBy: -1)]) + "d")
      }
    } else if tense == .imperativoNegativo {
      if personNumber == .firstSingular {
        return .failure(.noFirstPersonSingularImperative)
      }
      guard case .success(let conjugation) = conjugateRecursively(infinitive: infinitive, tense: .presenteDeSubjuntivo, personNumber: personNumber) else {
        fatalError("conjugation was nil.")
      }

      return .success("no " + conjugation)
    } else {
      return .failure(.tenseNotImplemented(tense))
    }
  }

  private func endingFor(tense: Tense, personNumber: PersonNumber) -> String {
    switch personNumber {
    case .firstSingular:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ra"
      case .imperfectoDeSubjuntivo2:
        return "se"
      case .futuroDeSubjuntivo:
        return "re"
      case .futuroDeIndicativo:
        return "é"
      case .condicional:
        return "ía"
      default:
        return ""
      }
    case .secondSingularTú, .secondSingularVos:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ras"
      case .imperfectoDeSubjuntivo2:
        return "ses"
      case .futuroDeSubjuntivo:
        return "res"
      case .futuroDeIndicativo:
        return "ás"
      case .condicional:
        return "ías"
      default:
        return ""
      }
    case .thirdSingular:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ra"
      case .imperfectoDeSubjuntivo2:
        return "se"
      case .futuroDeSubjuntivo:
        return "re"
      case .futuroDeIndicativo:
        return "á"
      case .condicional:
        return "ía"
      default:
        return ""
      }
    case .firstPlural:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ramos"
      case .imperfectoDeSubjuntivo2:
        return "semos"
      case .futuroDeSubjuntivo:
        return "remos"
      case .futuroDeIndicativo:
        return "emos"
      case .condicional:
        return "íamos"
      default:
        return ""
      }
    case .secondPlural:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "rais"
      case .imperfectoDeSubjuntivo2:
        return "seis"
      case .futuroDeSubjuntivo:
        return "reis"
      case .futuroDeIndicativo:
        return "éis"
      case .condicional:
        return "íais"
      default:
        return ""
      }
    case .thirdPlural:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ran"
      case .imperfectoDeSubjuntivo2:
        return "sen"
      case .futuroDeSubjuntivo:
        return "ren"
      case .futuroDeIndicativo:
        return "án"
      case .condicional:
        return "ían"
      default:
        return ""
      }
    case .none:
      return ""
    }
  }
}
