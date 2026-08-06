//
//  MedievalExample.swift
//  Conjugar
//
//  One Medieval-Spanish example line for a verb, loaded from the bundled
//  `MedievalExamples.json` (keyed infinitive → array, so the card can cycle every
//  medieval attestation). `work` names the source poem; `ref` is the ready-made
//  citation ("Cantar I, v. 330", "estrofa 470", "copla 900"); `os` is the Old-Spanish
//  verse (medieval spelling, kept intact); `tr` is a Claude English translation.
//  Analogue of Conjuguer's `ChansonExample`, extended with `work` because Conjugar has
//  three medieval works rather than one poem.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated struct MedievalExample: Codable, Hashable {
  let work: String // "cid" | "berceo" | "lba"
  let ref: String
  let os: String
  let tr: String

  /// The display title of the source work, prepended to `ref` on the card. Proper
  /// nouns — identical in every language, so not localized.
  var workTitle: String {
    switch work {
    case "cid": return "Cantar de mio Cid"
    case "berceo": return "Milagros de Nuestra Señora"
    case "lba": return "Libro de buen amor"
    default: return work
    }
  }

  /// The full citation shown under the medieval heading, e.g.
  /// "Cantar de mio Cid, Cantar I, v. 330".
  var reference: String {
    "\(workTitle), \(ref)"
  }
}
