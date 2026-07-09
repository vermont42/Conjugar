//
//  EngineTense.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The engine-side tense model; the UI's `DisplayTense` vocabulary maps onto it
// via `TenseBridge`.
//
// Scope: the ten simple / non-finite tenses. The nine compound tenses (haber +
// participle) are mechanical and are composed outside the engine by
// `CompoundTense`.
nonisolated enum EngineTense: Equatable {
  case presenteDeIndicativo(EnginePersonNumber)         // PI
  case pretérito(EnginePersonNumber)                    // PR (pretérito indefinido / simple past)
  case imperfectoDeIndicativo(EnginePersonNumber)       // IM
  case futuro(EnginePersonNumber)                       // FU
  case condicional(EnginePersonNumber)                  // CO
  case presenteDeSubjuntivo(EnginePersonNumber)         // PS
  case imperfectoDeSubjuntivoRa(EnginePersonNumber)     // IS, -ra form (Imperfect I)
  case imperfectoDeSubjuntivoSe(EnginePersonNumber)     // IS, -se form (Imperfect II)
  case imperativoAfirmativo(EnginePersonNumber)         // IMP (afirmativo)
  case participioPasado                            // PP (person-less)
  case gerundio                                    // GER (person-less)

  /// The person of a finite tense, or nil for the non-finite forms.
  var personNumber: EnginePersonNumber? {
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
