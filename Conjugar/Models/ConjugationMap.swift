//
//  ConjugationMap.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// One slot of a verb's paradigm: a tense and a person, `.none` for the infinitive, the gerund,
/// and the participle. The vocabulary is the UI's, so a cell names itself in the tense names the
/// verb page uses.
nonisolated struct ConjugationCell: Hashable, Sendable {
  let tense: DisplayTense
  let personNumber: DisplayPersonNumber

  /// Four letters, the two raw values run together: `ptts` is the pretérito (él). The map's file
  /// format writes cells this way.
  var code: String { tense.rawValue + personNumber.rawValue }

  init(tense: DisplayTense, personNumber: DisplayPersonNumber) {
    self.tense = tense
    self.personNumber = personNumber
  }

  init?(code: some StringProtocol) {
    guard
      code.count == 4,
      let tense = DisplayTense(rawValue: String(code.prefix(2))),
      let personNumber = DisplayPersonNumber(rawValue: String(code.suffix(2)))
    else {
      return nil
    }
    self.init(tense: tense, personNumber: personNumber)
  }

  /// The persons of a finite tense: the six, and vos.
  static let finitePersons: [DisplayPersonNumber] = [
    .firstSingular, .secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural
  ]
}

/// Every one-word form of every verb, mapped to the verbs and cells it belongs to, so that search
/// can start from a form: fue finds ir and ser, both in the pretérito (él).
///
/// ConjugationMapTool builds the map at build time and writes it into the app bundle, and the app
/// reads that copy. The tool compiles this file and the engine from the app's own sources, so the
/// two cannot disagree; see docs/feature_architecture.md § Conjugation Map.
///
/// Forms are the engine's bare forms (arrepiento, not me arrepiento), lowercased, with accents as
/// written. Compound tenses and the imperativo negativo have no entries, because their last word
/// already does: "he hablado" resolves through hablado, "no hables" through hables. Entries for
/// haber would otherwise attach to every verb. The future stem is not a word and has none either.
nonisolated struct ConjugationMap: Equatable, Sendable {
  nonisolated struct Entry: Hashable, Sendable {
    let infinitive: String
    /// In the order of `ConjugationMap.oneWordCells`.
    let cells: [ConjugationCell]
  }

  static let resourceName = "ConjugationMap"
  static let resourceExtension = "lzfse"

  /// Keys are lowercase, because `IrregularityMarker` marks the irregular span in uppercase
  /// (tUve), and that casing is highlighting rather than spelling. Within a key, entries are
  /// sorted by infinitive.
  let entriesByForm: [String: [Entry]]

  /// The entries for `form`, matched exactly apart from case: "hablo" does not find habló.
  func entries(for form: String) -> [Entry] {
    entriesByForm[form.lowercased()] ?? []
  }

  /// The copy in the app bundle, loaded on first use. Loading takes a moment, so a caller on the
  /// main actor may want to touch it first from a background task. Empty if the file is missing,
  /// which `ConjugationMapTests` would catch.
  static let bundled: ConjugationMap = {
    guard
      let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension),
      let data = try? Data(contentsOf: url),
      let map = try? ConjugationMap(compressed: data)
    else {
      return ConjugationMap(entriesByForm: [:])
    }
    return map
  }()
}

// The bundled file is this text, compressed with LZFSE. Measured on 2026-11-22: 4,811 verbs,
// 254,328 forms, 1.8 MB of text, 43 KB compressed. One line per form came to 7.1 MB and 1.4 MB,
// because every line repeated an infinitive and its cell codes.
nonisolated extension ConjugationMap {
  /// One line per verb, sorted by infinitive: the infinitive, then a tab before each form of
  /// `oneWordCells` after the first (the infinitive itself), in that order. A form is written as
  /// its difference from the infinitive: the number of letters to drop from the infinitive's
  /// end, then the letters to add. A defective verb's empty slot is "-".
  ///
  ///     hablar	1ndo	1do	2o	1s	2ás	…
  ///     ir	2yendo	1do	2voy	2vas	…
  ///
  /// So hablando is hablar less one letter plus "ndo", and voy is ir less two plus "voy". Every
  /// regular verb of a conjugation writes the same line after its infinitive, which is what
  /// lets LZFSE shrink the file forty-fold.
  var text: String {
    paradigms().sorted { $0.key < $1.key }.map { infinitive, forms in
      ([infinitive] + forms.dropFirst().map { form in
        form.map { Self.delta(from: infinitive, to: $0) } ?? Self.emptySlot
      })
      .joined(separator: "\t")
    }
    .joined(separator: "\n")
  }

  init(text: String) {
    var paradigms: [String: [String?]] = [:]
    for line in text.split(separator: "\n") {
      let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
      guard let infinitive = fields.first.map(String.init) else {
        continue
      }
      paradigms[infinitive] = [infinitive] + fields.dropFirst().map { field in
        field == Self.emptySlot ? nil : Self.form(from: infinitive, delta: field)
      }
    }
    self.init(paradigms: paradigms)
  }

  func compressed() throws -> Data {
    try (Data(text.utf8) as NSData).compressed(using: .lzfse) as Data
  }

  init(compressed data: Data) throws {
    let decompressed = try (data as NSData).decompressed(using: .lzfse) as Data
    self.init(text: String(bytes: decompressed, encoding: .utf8) ?? "")
  }

  /// Each verb's forms in `oneWordCells` order, nil for an empty slot.
  init(paradigms: [String: [String?]]) {
    var cellsByForm: [String: [String: [ConjugationCell]]] = [:]
    for (infinitive, forms) in paradigms {
      for (cell, form) in zip(Self.oneWordCells, forms) {
        if let form {
          cellsByForm[form, default: [:]][infinitive, default: []].append(cell)
        }
      }
    }
    self.init(entriesByForm: cellsByForm.mapValues { cellsByInfinitive in
      cellsByInfinitive.keys.sorted().map { Entry(infinitive: $0, cells: cellsByInfinitive[$0] ?? []) }
    })
  }

  /// The inverse of `init(paradigms:)`.
  func paradigms() -> [String: [String?]] {
    var paradigms: [String: [String?]] = [:]
    let indexes = Dictionary(uniqueKeysWithValues: Self.oneWordCells.enumerated().map { ($1, $0) })
    for (form, entries) in entriesByForm {
      for entry in entries {
        for cell in entry.cells {
          if let index = indexes[cell] {
            paradigms[entry.infinitive, default: Array(repeating: nil, count: Self.oneWordCells.count)][index] = form
          }
        }
      }
    }
    return paradigms
  }

  private static let emptySlot = "-"

  /// "2o" for hablar → hablo: the letters to drop from the end of `infinitive`, then the letters
  /// to add.
  static func delta(from infinitive: String, to form: String) -> String {
    let common = zip(infinitive, form).prefix { $0 == $1 }.count
    return "\(infinitive.count - common)" + form.dropFirst(common)
  }

  /// The inverse of `delta(from:to:)`. Forms hold no digits, so the count ends where the
  /// letters begin.
  static func form(from infinitive: String, delta: some StringProtocol) -> String {
    let digits = delta.prefix { $0.isNumber }
    let dropCount = Int(digits) ?? 0
    return String(infinitive.dropLast(dropCount)) + delta.dropFirst(digits.count)
  }
}

nonisolated extension ConjugationMap {
  /// The cells whose forms are one word: the infinitive, the gerund, the participle, the nine
  /// simple tenses, and the imperativo positivo, every person and vos included.
  static let oneWordCells: [ConjugationCell] = {
    var cells = [DisplayTense.infinitivo, .gerundio, .participio].map { ConjugationCell(tense: $0, personNumber: .none) }
    for tense in DisplayTense.conjugatedTenses where !tense.isCompound && tense != .imperativoNegativo {
      for personNumber in ConjugationCell.finitePersons where tense != .imperativoPositivo || personNumber != .firstSingular {
        cells.append(ConjugationCell(tense: tense, personNumber: personNumber))
      }
    }
    return cells
  }()

  /// The bare form of a one-word cell, lowercased, or nil for a defective verb's empty slot.
  /// A form of more than one word would be a bug in `oneWordCells`, and is left out too.
  static func form(of infinitive: String, at cell: ConjugationCell) -> String? {
    if cell.tense == .infinitivo {
      return infinitive
    }
    guard
      case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: cell.tense, personNumber: cell.personNumber),
      !form.isEmpty,
      !form.contains(" ")
    else {
      return nil
    }
    return form.lowercased()
  }

  /// Builds the map from `VerbMap.shared`, which must be loadable: from the bundle in the app,
  /// or from `VerbMap.resourceURLOverride` in ConjugationMapTool.
  static func build() -> ConjugationMap {
    var paradigms: [String: [String?]] = [:]
    for infinitive in VerbMap.shared.entries.keys {
      paradigms[infinitive] = oneWordCells.map { form(of: infinitive, at: $0) }
    }
    return ConjugationMap(paradigms: paradigms)
  }
}
