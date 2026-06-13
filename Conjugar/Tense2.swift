//
//  Tense2.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// New (composition-engine) tense model. Suffixed `2` while it lives alongside
// the old `Tense`; the suffix is dropped once the old engine is removed.
//
// Scope: the ten simple / non-finite tenses the verified oracle covers
// (spanish_models.md slot vocabulary §2). The nine compound tenses (haber +
// participle) are mechanical and are added later, not in the Phase 1 skeleton.
enum Tense2: Equatable {
  case presenteDeIndicativo(PersonNumber2)         // PI
  case pretérito(PersonNumber2)                    // PR (pretérito indefinido / simple past)
  case imperfectoDeIndicativo(PersonNumber2)       // IM
  case futuro(PersonNumber2)                       // FU
  case condicional(PersonNumber2)                  // CO
  case presenteDeSubjuntivo(PersonNumber2)         // PS
  case imperfectoDeSubjuntivoRa(PersonNumber2)     // IS, -ra form (Imperfect I)
  case imperfectoDeSubjuntivoSe(PersonNumber2)     // IS, -se form (Imperfect II)
  case imperativoAfirmativo(PersonNumber2)         // IMP (afirmativo)
  case participioPasado                            // PP (person-less)
  case gerundio                                    // GER (person-less)

  /// The person of a finite tense, or nil for the non-finite forms.
  var personNumber: PersonNumber2? {
    switch self {
    case let .presenteDeIndicativo(pn),
         let .pretérito(pn),
         let .imperfectoDeIndicativo(pn),
         let .futuro(pn),
         let .condicional(pn),
         let .presenteDeSubjuntivo(pn),
         let .imperfectoDeSubjuntivoRa(pn),
         let .imperfectoDeSubjuntivoSe(pn),
         let .imperativoAfirmativo(pn):
      return pn
    case .participioPasado, .gerundio:
      return nil
    }
  }
}
