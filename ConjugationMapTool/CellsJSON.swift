//
//  CellsJSON.swift
//  ConjugationMapTool
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The --cells-json output: every one-word form of every verb, with the cells it fills.
// scripts/count_tenses.py reads it to count how often each tense occurs in the text corpus,
// which orders the verb page's cards. See docs/tense_frequency.md.
//
// The shape is form → [[infinitive, tense, person], …], the tense and person being the case
// names of DisplayTense and DisplayPersonNumber:
//
//   "fue": [["ir", "pretérito", "thirdSingular"], ["ser", "pretérito", "thirdSingular"]]
//   "hablado": [["hablar", "participio", "none"]]
//
// It is the conjugation map unpacked, so the counter and the app agree on what a form is. Like
// the map, it holds no compound tense and no imperativo negativo, whose last word (the participle,
// the subjunctive) is already a key; the counter finds those by their auxiliary and by "no".

import Foundation

enum CellsJSON {
  static func data(_ map: ConjugationMap) throws -> Data {
    let rows = map.entriesByForm.mapValues { entries in
      entries.flatMap { entry in
        entry.cells.map { [entry.infinitive, String(describing: $0.tense), String(describing: $0.personNumber)] }
      }
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(rows)
  }
}
