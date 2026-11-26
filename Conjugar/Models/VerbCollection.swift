//
//  VerbCollection.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A fixed list of verbs offered as a place to go: something a self-studier can finish and a
/// teacher can assign. Each shows how many of its verbs have been opened, starts a quiz on itself,
/// and is shared as `conjugar://list/<key>`.
///
/// The featured collections sit at the top of the Models tab: the 100 most frequent verbs and four
/// irregular patterns. Every model of the Models tab is a collection too, shown as a bar on its
/// page. Membership is derived from the engine, never listed by hand: a pattern list holds the
/// base verbs among the 1,000 most frequent whose forms show the pattern, and leaves out prefixed
/// compounds (detener, componer), which follow their base verbs. `VerbFamilies`' hand-made lists
/// survive as a test that each derivation finds their verbs.
///
/// `nonisolated`, like the engine it reads. Its titles and descriptions, which need `L`, are in
/// `VerbCollection+Text.swift`.
nonisolated enum VerbCollection: Hashable, Identifiable, Sendable {
  case top100
  /// tengo, hago, salgo: a yo presente in -go whose g the infinitive lacks.
  case goVerbs
  /// tuve, hice, dije: a pretérito on a new stem, its yo form ending in an unstressed -e.
  case strongPreterite
  /// tendré, haré, diré: a future, and so a conditional, on a changed stem.
  case irregularFuture
  /// hecho, dicho, visto: a participle that is not the regular -ado or -ido.
  case irregularParticiple
  /// A row of the Models tab, by its class number ("31", "4B", "3-1"). An alias class (31-1)
  /// is never one, because its verbs show under its parent's row.
  case model(String)

  /// The Models tab's Collections section, in the order a learner meets the tenses: the
  /// presente, the pretérito, the futuro, then the participle of the compound tenses.
  static let featured: [VerbCollection] = [.top100, .goVerbs, .strongPreterite, .irregularFuture, .irregularParticiple]

  /// The band a pattern list draws from.
  static let patternBand = FrequencyBand.top1000

  private static let modelKeyPrefix = "model-"

  var id: String {
    key
  }

  /// The deeplink target and the analytics value. A key, once shared, must keep opening the same
  /// list. A model's key carries its class number as written, hyphen and letter included
  /// (`model-3-1`, `model-4B`); the prefix ends at the first hyphen, so the number's own hyphens
  /// are safe.
  var key: String {
    switch self {
    case .top100:
      return "top100"
    case .goVerbs:
      return "goVerbs"
    case .strongPreterite:
      return "strongPreterite"
    case .irregularFuture:
      return "irregularFuture"
    case .irregularParticiple:
      return "irregularParticiple"
    case .model(let classNumber):
      return Self.modelKeyPrefix + classNumber
    }
  }

  init?(key: String) {
    if key.hasPrefix(Self.modelKeyPrefix) {
      let classNumber = String(key.dropFirst(Self.modelKeyPrefix.count))
      guard Self.isModelRow(classNumber) else {
        return nil
      }
      self = .model(classNumber)
      return
    }
    guard let featured = Self.featured.first(where: { $0.key == key }) else {
      return nil
    }
    self = featured
  }

  /// Whether a class number has a row in the Models tab: a class of the catalog that is not an
  /// alias riding its parent's model.
  static func isModelRow(_ classNumber: String) -> Bool {
    ModelCatalog.classNumbers.contains(classNumber) && ModelInfo.parentByAlias[classNumber] == nil
  }

  var isModel: Bool {
    if case .model = self {
      return true
    }
    return false
  }

  /// The collection's verbs, the most frequent first. A model's are its row's (`ModelInfo`), so
  /// the bar, the quiz, and the share on the model's page count the verbs the page lists.
  var verbs: [VerbMapEntry] {
    switch self {
    case .model(let classNumber):
      return ModelInfo.byClassNumber[classNumber]?.verbs ?? []
    default:
      return Self.featuredVerbs[self] ?? []
    }
  }

  /// The bare infinitives a quiz on the collection draws from.
  var infinitives: [String] {
    verbs.map(\.infinitive)
  }

  /// How many forms `examples` shows.
  static let exampleCount = 3

  /// A glimpse of the list for its row in the Models tab: the pattern's form of its three most
  /// frequent verbs, engine-marked so the irregular letters render red ("tenGo · haGo · dIGo"),
  /// or for the top 100, its first infinitives. Empty for a model, whose page has a grid.
  var examples: String {
    let verbs = self.verbs.prefix(Self.exampleCount)
    let cell: (tense: DisplayTense, personNumber: DisplayPersonNumber)
    switch self {
    case .top100:
      return verbs.map(\.citationForm).joined(separator: Self.exampleSeparator)
    case .goVerbs:
      cell = (.presenteDeIndicativo, .firstSingular)
    case .strongPreterite:
      cell = (.pretérito, .firstSingular)
    case .irregularFuture:
      cell = (.futuroDeIndicativo, .firstSingular)
    case .irregularParticiple:
      cell = (.participio, .none)
    case .model:
      return ""
    }
    return verbs.compactMap { entry in
      if case .success(let form) = TenseBridge.conjugate(infinitive: entry.infinitive, tense: cell.tense, personNumber: cell.personNumber) {
        return form
      }
      return nil
    }
    .joined(separator: Self.exampleSeparator)
  }

  static let exampleSeparator = " · "

  func contains(_ entry: VerbMapEntry) -> Bool {
    switch self {
    case .top100:
      return entry.isIn(.top100)
    case .goVerbs:
      return Self.isPatternCandidate(entry) && Self.hasGoPresent(entry.infinitive)
    case .strongPreterite:
      return Self.isPatternCandidate(entry) && Self.hasStrongPreterite(entry.infinitive)
    case .irregularFuture:
      return Self.isPatternCandidate(entry) && Self.hasIrregularFuture(entry.infinitive)
    case .irregularParticiple:
      return Self.isPatternCandidate(entry) && Self.hasIrregularParticiple(entry.infinitive)
    case .model:
      return verbs.contains { $0.infinitive == entry.infinitive }
    }
  }

  /// Built once, as the verb map loads once: the pattern tests conjugate a thousand verbs.
  private static let featuredVerbs: [VerbCollection: [VerbMapEntry]] = {
    let candidates = VerbMap.shared.entries(in: .top1000)
    return Dictionary(uniqueKeysWithValues: featured.map { collection in
      (collection, candidates.filter(collection.contains))
    })
  }()

  /// A verb a pattern list may hold: in the band, and not a prefixed compound of another verb
  /// (`VerbMapEntry.isCompound`).
  static func isPatternCandidate(_ entry: VerbMapEntry) -> Bool {
    entry.isIn(patternBand) && !entry.isCompound
  }

  /// A yo presente in -go whose g the infinitive's stem lacks: tengo, hago, digo, caigo, oigo. A g
  /// already in the stem is no -go verb: sigo (seguir), juego (jugar), pago (pagar), distingo.
  static func hasGoPresent(_ infinitive: String) -> Bool {
    guard let form = plainForm(infinitive, .presenteDeIndicativo, .firstSingular) else {
      return false
    }
    return form.hasSuffix("go") && !stem(of: infinitive).contains("g")
  }

  /// A pretérito whose yo form ends in an unstressed -e (tuve, hice, dije, conduje), where a
  /// regular one ends in a stressed -é or -í. Not fui, di, or vi, which are irregular but not
  /// strong.
  static func hasStrongPreterite(_ infinitive: String) -> Bool {
    // Every spelling: guie, as the 2010 Ortografía writes guié, ends in an e too.
    guard case .success(let forms) = Conjugator.conjugateAll(infinitive: infinitive, tense: .pretérito(.firstSingular)) else {
      return false
    }
    return forms.allSatisfy { $0.hasSuffix("e") }
  }

  /// A future on a changed stem (tendré, haré, diré, cabré), which the engine marks with capitals.
  /// The conditional shares the stem.
  static func hasIrregularFuture(_ infinitive: String) -> Bool {
    guard case .success(let form) = TenseBridge.conjugate(infinitive: infinitive, tense: .futuroDeIndicativo, personNumber: .firstSingular) else {
      return false
    }
    return form.contains { $0.isUppercase }
  }

  /// A participle that is not the regular -ado or -ido, accents aside: hecho, visto, roto, and
  /// podrido (pudrir), but not creído or oído, whose written accent only keeps the stress.
  static func hasIrregularParticiple(_ infinitive: String) -> Bool {
    guard let form = plainForm(infinitive, .participio, .none) else {
      return false
    }
    let ending = infinitive.hasSuffix("ar") ? "ado" : "ido"
    return SpellingComparison.fold(form) != SpellingComparison.fold(stem(of: infinitive) + ending)
  }

  /// The form in lowercase, its last word only, so a reflexive verb's pronoun does not count.
  private static func plainForm(_ infinitive: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> String? {
    guard case .success(let form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber) else {
      return nil
    }
    return form.split(separator: " ").last.map { $0.lowercased() }
  }

  /// The infinitive less its -ar, -er, or -ir (or -ír).
  private static func stem(of infinitive: String) -> String {
    String(infinitive.dropLast(2))
  }
}
