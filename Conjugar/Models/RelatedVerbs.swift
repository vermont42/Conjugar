//
//  RelatedVerbs.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The verbs a verb page leads to: the verbs built on the same base (tener with mantener, detener,
/// and obtener), and a few other verbs of its model, one for each other base. The model's own page
/// is reached through the page's pill. See `VerbRelations` for how a base is found.
nonisolated struct RelatedVerbs: Equatable, Sendable {
  /// The innermost base, which every verb built on it shares: tener for detener, and parecer for
  /// desaparecer, whose own base is aparecer. Always a verb of the map. A verb with no base is its
  /// own root.
  let root: String

  /// The verbs built on `root`, the root verb first, then by frequency. The verb whose page this is
  /// does not appear.
  let builtOnRoot: [String]

  /// The class number of the verb's row in the Models tab, with the alias classes folded into their
  /// parents (31-1 into 31), as `ModelInfo` folds them.
  let modelClassNumber: String

  /// One verb for each other root among the model's verbs, by frequency: the root verb itself when
  /// it uses the model, else the most frequent verb of the model built on it. Empty when every verb
  /// of the model shares this verb's root, as tener's do.
  let modelRelatives: [String]

  /// How many verbs use the model, this one included: the count its page lists.
  let modelVerbCount: Int

  var isEmpty: Bool {
    builtOnRoot.isEmpty && modelRelatives.isEmpty
  }
}

/// How verbs relate through their bases, computed from the verb map.
///
/// The relation is the engine's own: every feature is end-anchored, so a prefixed verb conjugates
/// on its base's model (detener like tener, reconocer like conocer), and a compound has its base's
/// class number or a sub-class of it (contener is 31-1 beside tener's 31; predecir is 28-1 beside
/// decir's 28). A verb's **base** is therefore the longest verb of the map that ends it,
/// after a known prefix, and whose class number has the same leading number: con + tener, de +
/// tener, pre + decir. The class rule keeps presentar (1) off sentar (4A) and andar off dar, since
/// an irregular base always has its own class. The prefix list keeps llamar off amar.
///
/// Only verbs count as bases. Tails that are not verbs, such as -ducir or -scribir, would join
/// conducir with producir, but the same rule joins esperar with operar and resultar with insultar.
/// The verbs of the useful tails already share a model (conducir's 34, escribir's 3-11), so the
/// model row shows them.
nonisolated enum VerbRelations {
  /// Spanish verbal prefixes, Latin and Romance, with their assimilated spellings (com-, cor-, im-).
  /// Left out because they mostly matched by accident: res- (respetar on petar) and tra- (trabajar
  /// on bajar).
  static let prefixes: Set<String> = [
    "a", "ab", "abs", "ad", "ante", "anti", "auto", "ben", "bien", "circun", "co", "com", "con",
    "contra", "cor", "de", "des", "di", "dis", "e", "em", "en", "entre", "equi", "es", "ex", "extra",
    "im", "in", "infra", "inter", "intro", "mal", "man", "menos", "o", "ob", "per", "pos", "post",
    "pre", "pro", "re", "retro", "so", "sobre", "son", "sor", "sos", "su", "sub", "super", "sus",
    "tras", "trans", "yuxta"
  ]

  /// Verbs that look like a prefix and a verb but are not built on that verb, found by reading the
  /// pairs among the 2,000 most frequent verbs, plus every verb resting on a base that no real
  /// compound uses (piar, pirar, timar). Rarer verbs were not read, so a few false pairs remain
  /// there.
  static let falseCompounds: Set<String> = [
    "abalar", "abogar", "abrasar", "acostar", "adherir", "adorar", "adosar", "alegrar", "amigar",
    "apagar", "apechar", "apelar", "apodar", "autorizar", "comparar", "copiar", "decantar",
    "desbastar", "diversificar", "divisar", "embalar", "embotar", "encalar", "encarecer",
    "encastrar", "enfundar", "engastar", "envarar", "equilibrar", "equiparar", "erizar", "escalar",
    "escapar", "espesar", "espetar", "espiar", "espirar", "esposar", "esquejar", "estallar",
    "estimar", "estocar", "estragar", "expiar", "expirar", "impactar", "intercalar", "interpelar",
    "intimar", "procesar", "propagar", "rebasar", "recalar", "recostar", "solicitar", "somatizar",
    "sospechar", "subastar", "suspirar"
  ]

  /// The verb map's relations, built once.
  static let shared = Index(map: .shared)

  static func related(to infinitive: String) -> RelatedVerbs? {
    shared.related(to: infinitive)
  }

  /// The leading number of a class number, which a base and its compounds share: 31 for 31-1, 4B
  /// for 4B-1.
  static func classFamily(_ classNumber: String) -> Substring {
    classNumber.prefix { $0 != "-" }
  }

  nonisolated struct Index: Sendable {
    /// Each verb that has a base, to that base.
    let baseByVerb: [String: String]
    /// Each verb's root, for every verb of the map.
    let rootByVerb: [String: String]
    /// Every verb, keyed by its root, each list by frequency.
    let verbsByRoot: [String: [String]]
    /// Each row of the Models tab, by its class number, to its verbs, by frequency.
    let verbsByModel: [String: [String]]
    private let entries: [String: VerbMapEntry]

    init(map: VerbMap) {
      entries = map.entries
      var baseByVerb: [String: String] = [:]
      for entry in map.entries.values {
        if let base = Self.base(of: entry, in: map.entries) {
          baseByVerb[entry.infinitive] = base
        }
      }
      self.baseByVerb = baseByVerb

      var rootByVerb: [String: String] = [:]
      for infinitive in map.entries.keys {
        var root = infinitive
        // Each step shortens the verb, so this ends; the bound only documents that.
        for _ in 0..<8 {
          guard let base = baseByVerb[root] else {
            break
          }
          root = base
        }
        rootByVerb[infinitive] = root
      }
      self.rootByVerb = rootByVerb

      let byFrequency = map.entries.values.sorted { $0.frequencyRank < $1.frequencyRank }
      var verbsByRoot: [String: [String]] = [:]
      var verbsByModel: [String: [String]] = [:]
      for entry in byFrequency {
        verbsByRoot[rootByVerb[entry.infinitive] ?? entry.infinitive, default: []].append(entry.infinitive)
        for classNumber in Set(entry.classNumbers.map(Self.modelClassNumber)) {
          verbsByModel[classNumber, default: []].append(entry.infinitive)
        }
      }
      self.verbsByRoot = verbsByRoot
      self.verbsByModel = verbsByModel
    }

    /// The Models tab's row for a class number: an alias class (31-1) shows under its parent (31).
    static func modelClassNumber(_ classNumber: String) -> String {
      ModelInfo.parentByAlias[classNumber] ?? classNumber
    }

    private static func base(of entry: VerbMapEntry, in entries: [String: VerbMapEntry]) -> String? {
      let infinitive = entry.infinitive
      guard !VerbRelations.falseCompounds.contains(infinitive) else {
        return nil
      }
      let family = VerbRelations.classFamily(entry.classNumber)
      // Shortest prefix first, so the longest base wins: reponer is re + poner, not rep + oner.
      for prefixLength in 1..<max(infinitive.count - 1, 1) {
        let prefix = String(infinitive.prefix(prefixLength))
        let candidate = String(infinitive.dropFirst(prefixLength))
        guard
          VerbRelations.prefixes.contains(prefix),
          let base = entries[candidate],
          VerbRelations.classFamily(base.classNumber) == family
        else {
          continue
        }
        return candidate
      }
      return nil
    }

    func related(to infinitive: String) -> RelatedVerbs? {
      guard let entry = entries[infinitive] else {
        return nil
      }
      let root = rootByVerb[infinitive] ?? infinitive
      let family = (verbsByRoot[root] ?? []).filter { $0 != infinitive }
      // The root first: on detener's page, tener leads its compounds.
      let builtOnRoot = family.contains(root) ? [root] + family.filter { $0 != root } : family

      let modelClassNumber = Self.modelClassNumber(entry.classNumber)
      let modelVerbs = verbsByModel[modelClassNumber] ?? []
      var representativeByRoot: [String: String] = [:]
      var roots: [String] = []
      for verb in modelVerbs {
        let verbRoot = rootByVerb[verb] ?? verb
        guard verbRoot != root else {
          continue
        }
        if representativeByRoot[verbRoot] == nil {
          roots.append(verbRoot)
          representativeByRoot[verbRoot] = verb
        }
        if verb == verbRoot {
          representativeByRoot[verbRoot] = verb
        }
      }
      let modelRelatives = roots
        .compactMap { representativeByRoot[$0] }
        .sorted { rank(of: $0) < rank(of: $1) }

      return RelatedVerbs(
        root: root,
        builtOnRoot: builtOnRoot,
        modelClassNumber: modelClassNumber,
        modelRelatives: modelRelatives,
        modelVerbCount: modelVerbs.count
      )
    }

    private func rank(of infinitive: String) -> Int {
      entries[infinitive]?.frequencyRank ?? Int.max
    }
  }
}
