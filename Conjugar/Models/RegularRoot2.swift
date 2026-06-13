//
//  RegularRoot2.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The three regular roots the engine composes onto: cantar (-ar), comer (-er),
// subir (-ir). These ending tables are the ground truth, transcribed from the
// verified oracle (spanish_models.md §3 / classes 1, 2, 3) plus the voseo
// supplement. Features (Phase 2+) override individual slots on top of these.
//
// -er and -ir differ only in PI 1p/2p, IMP 2p, and the future/conditional theme
// vowel; they are kept as separate roots for tradition and clarity.
enum RegularRoot2 {
  case ar
  case er
  case ir

  /// Selects the root from an infinitive's ending, or nil if it is not -ar/-er/-ir.
  init?(infinitive: String) {
    switch infinitive.suffix(2).lowercased() {
    case "ar":
      self = .ar
    case "er":
      self = .er
    case "ir", "ír":
      self = .ir
    default:
      return nil
    }
  }

  /// The regular ending for a slot, or nil when the regular paradigm has no such
  /// form (e.g. an affirmative imperative for usted/nosotros/ustedes, which are
  /// derived from the subjunctive in a later phase).
  func ending(for tense: Tense2) -> String? {
    switch tense {
    case .participioPasado:
      return self == .ar ? "ado" : "ido"
    case .gerundio:
      return self == .ar ? "ando" : "iendo"

    // vos present indicative has its own ending (cantás), so no tú fallback.
    case let .presenteDeIndicativo(pn):
      return ending(presenteDeIndicativo, pn, vosFallsBackToTú: false)
    // vos affirmative imperative has its own ending (cantá), so no tú fallback.
    case let .imperativoAfirmativo(pn):
      return ending(imperativoAfirmativo, pn, vosFallsBackToTú: false)

    // Every other tense: vos uses the tú form.
    case let .pretérito(pn):
      return ending(pretérito, pn)
    case let .imperfectoDeIndicativo(pn):
      return ending(imperfectoDeIndicativo, pn)
    case let .futuro(pn):
      return ending(futuro, pn)
    case let .condicional(pn):
      return ending(condicional, pn)
    case let .presenteDeSubjuntivo(pn):
      return ending(presenteDeSubjuntivo, pn)
    case let .imperfectoDeSubjuntivoRa(pn):
      return ending(imperfectoDeSubjuntivoRa, pn)
    case let .imperfectoDeSubjuntivoSe(pn):
      return ending(imperfectoDeSubjuntivoSe, pn)
    }
  }

  // MARK: - Lookup

  private func ending(_ endings: [PersonNumber2: String], _ pn: PersonNumber2, vosFallsBackToTú: Bool = true) -> String? {
    if let ending = endings[pn] {
      return ending
    }
    if vosFallsBackToTú && pn == .secondSingularVos {
      return endings[.secondSingular]
    }
    return nil
  }

  // MARK: - Ending tables (oracle §3 + voseo)

  private var presenteDeIndicativo: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.firstSingular: "o", .secondSingular: "as", .secondSingularVos: "ás", .thirdSingular: "a", .firstPlural: "amos", .secondPlural: "áis", .thirdPlural: "an"]
    case .er:
      return [.firstSingular: "o", .secondSingular: "es", .secondSingularVos: "és", .thirdSingular: "e", .firstPlural: "emos", .secondPlural: "éis", .thirdPlural: "en"]
    case .ir:
      return [.firstSingular: "o", .secondSingular: "es", .secondSingularVos: "ís", .thirdSingular: "e", .firstPlural: "imos", .secondPlural: "ís", .thirdPlural: "en"]
    }
  }

  private var pretérito: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.firstSingular: "é", .secondSingular: "aste", .thirdSingular: "ó", .firstPlural: "amos", .secondPlural: "asteis", .thirdPlural: "aron"]
    case .er, .ir:
      return [.firstSingular: "í", .secondSingular: "iste", .thirdSingular: "ió", .firstPlural: "imos", .secondPlural: "isteis", .thirdPlural: "ieron"]
    }
  }

  private var imperfectoDeIndicativo: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.firstSingular: "aba", .secondSingular: "abas", .thirdSingular: "aba", .firstPlural: "ábamos", .secondPlural: "abais", .thirdPlural: "aban"]
    case .er, .ir:
      return [.firstSingular: "ía", .secondSingular: "ías", .thirdSingular: "ía", .firstPlural: "íamos", .secondPlural: "íais", .thirdPlural: "ían"]
    }
  }

  private var futuro: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.firstSingular: "aré", .secondSingular: "arás", .thirdSingular: "ará", .firstPlural: "aremos", .secondPlural: "aréis", .thirdPlural: "arán"]
    case .er:
      return [.firstSingular: "eré", .secondSingular: "erás", .thirdSingular: "erá", .firstPlural: "eremos", .secondPlural: "eréis", .thirdPlural: "erán"]
    case .ir:
      return [.firstSingular: "iré", .secondSingular: "irás", .thirdSingular: "irá", .firstPlural: "iremos", .secondPlural: "iréis", .thirdPlural: "irán"]
    }
  }

  private var condicional: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.firstSingular: "aría", .secondSingular: "arías", .thirdSingular: "aría", .firstPlural: "aríamos", .secondPlural: "aríais", .thirdPlural: "arían"]
    case .er:
      return [.firstSingular: "ería", .secondSingular: "erías", .thirdSingular: "ería", .firstPlural: "eríamos", .secondPlural: "eríais", .thirdPlural: "erían"]
    case .ir:
      return [.firstSingular: "iría", .secondSingular: "irías", .thirdSingular: "iría", .firstPlural: "iríamos", .secondPlural: "iríais", .thirdPlural: "irían"]
    }
  }

  private var presenteDeSubjuntivo: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.firstSingular: "e", .secondSingular: "es", .thirdSingular: "e", .firstPlural: "emos", .secondPlural: "éis", .thirdPlural: "en"]
    case .er, .ir:
      return [.firstSingular: "a", .secondSingular: "as", .thirdSingular: "a", .firstPlural: "amos", .secondPlural: "áis", .thirdPlural: "an"]
    }
  }

  private var imperfectoDeSubjuntivoRa: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.firstSingular: "ara", .secondSingular: "aras", .thirdSingular: "ara", .firstPlural: "áramos", .secondPlural: "arais", .thirdPlural: "aran"]
    case .er, .ir:
      return [.firstSingular: "iera", .secondSingular: "ieras", .thirdSingular: "iera", .firstPlural: "iéramos", .secondPlural: "ierais", .thirdPlural: "ieran"]
    }
  }

  private var imperfectoDeSubjuntivoSe: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.firstSingular: "ase", .secondSingular: "ases", .thirdSingular: "ase", .firstPlural: "ásemos", .secondPlural: "aseis", .thirdPlural: "asen"]
    case .er, .ir:
      return [.firstSingular: "iese", .secondSingular: "ieses", .thirdSingular: "iese", .firstPlural: "iésemos", .secondPlural: "ieseis", .thirdPlural: "iesen"]
    }
  }

  // Only 2s (tú), 2s (vos), and 2p (vosotros) exist in the regular paradigm.
  private var imperativoAfirmativo: [PersonNumber2: String] {
    switch self {
    case .ar:
      return [.secondSingular: "a", .secondSingularVos: "á", .secondPlural: "ad"]
    case .er:
      return [.secondSingular: "e", .secondSingularVos: "é", .secondPlural: "ed"]
    case .ir:
      return [.secondSingular: "e", .secondSingularVos: "í", .secondPlural: "id"]
    }
  }
}
