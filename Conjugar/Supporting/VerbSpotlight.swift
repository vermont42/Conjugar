//
//  VerbSpotlight.swift
//  Conjugar
//
//  Conjugar's Spotlight entries.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import CoreSpotlight

/// One Spotlight entry per verb, in a named index. Each can be found by its infinitive, by every
/// sense of its glosses, and by its one-word forms, so that typing fue or "arrive" on the Home
/// Screen can find ir or llegar. In the iOS 26.3 simulator Spotlight matched titles only, so
/// whether the other fields help is a device's question; see `docs/release.md`.
nonisolated enum VerbSpotlight {
  struct Text: Hashable, Sendable {
    /// The glosses' phrases, then the key conjugations (tengo, tuve, tendré, tenido). Spotlight
    /// shows the first under the description, so the gloss leads.
    let alternateNames: [String]

    /// Every one-word form in the conjugation map, then the glosses whole and their phrases with
    /// and without "to".
    let keywords: [String]

    /// Shown under the title: the key conjugations, which stand alone with no label. Spotlight
    /// shows a description on one line, so a gloss beside them would run into them.
    let description: String
  }

  static let indexName = "verbs"

  /// What the last run indexed: the stamp of the build and the map it indexed from, and the
  /// identifiers of its entries, so that a later run can remove the entry of a verb the map has
  /// lost.
  struct IndexRecord: Codable, Equatable, Sendable {
    let stamp: String
    let infinitives: [String]
  }

  /// What a launch does about Spotlight.
  enum IndexPlan: Equatable {
    /// The index already holds this build's entries.
    case skip
    /// Index every verb, first removing the entries of these verbs, which the map no longer has.
    case index(removing: [String])
  }

  /// Skip when the last run's stamp is this one's, and otherwise index, removing what the last run
  /// indexed and `infinitives` lacks. With no record, there is nothing known to remove.
  static func plan(last: IndexRecord?, stamp: String, infinitives: Set<String>) -> IndexPlan {
    guard let last else {
      return .index(removing: [])
    }
    if last.stamp == stamp {
      return .skip
    }
    return .index(removing: last.infinitives.filter { !infinitives.contains($0) }.sorted())
  }

  /// The app's version and build, and the number of verbs: a new build or a new map gets new
  /// entries, and a launch of the same build skips the work. A development build keeps its
  /// version and build number, so a change to the entries reaches Spotlight there only after the
  /// app is deleted.
  static func stamp(bundle: Bundle = .main, verbCount: Int) -> String {
    let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    return "\(version) (\(build)), \(verbCount) verbs"
  }

  /// In Caches, which a backup leaves out: an app restored to a new device, whose Spotlight index
  /// starts empty, finds no record and indexes. If iOS purges the file, the next launch indexes
  /// again, which costs only the time.
  static var recordURL: URL? {
    FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
      .appending(path: "spotlight_index.json")
  }

  /// Builds every verb's entry and indexes them, unless this build has already done so
  /// (`plan(last:stamp:infinitives:)`). The engine is nonisolated, so all of it runs off the main
  /// actor, and `MainTabView` starts it at background priority. Building the entries takes about two
  /// seconds in a Debug build on an Intel Mac, and the indexing call about twenty more, so a verb
  /// first shows in Spotlight some seconds after the first launch. The record is written only
  /// once the index has taken the entries, so a run that fails is tried again at the next launch.
  /// Removal goes by identifier, never by type: deleting app entities by type empties the named
  /// index too. Conjugar never used the default index, so there is nothing there to delete.
  @concurrent
  static func indexVerbs(recordURL: URL? = recordURL) async {
    let infinitives = Set(VerbMap.shared.entries.keys)
    let stamp = stamp(verbCount: infinitives.count)
    let last = recordURL.flatMap { try? Data(contentsOf: $0) }.flatMap { try? JSONDecoder().decode(IndexRecord.self, from: $0) }
    guard case .index(let removing) = plan(last: last, stamp: stamp, infinitives: infinitives) else {
      return
    }
    let index = CSSearchableIndex(name: indexName)
    do {
      if !removing.isEmpty {
        try await index.deleteAppEntities(identifiedBy: removing, ofType: VerbEntity.self)
      }
      try await index.indexAppEntities(entities())
    } catch {
      return
    }
    let record = IndexRecord(stamp: stamp, infinitives: infinitives.sorted())
    if let recordURL, let data = try? JSONEncoder().encode(record) {
      try? data.write(to: recordURL, options: .atomic)
    }
  }

  static func entities(map: ConjugationMap = .bundled) -> [VerbEntity] {
    let forms = formsByInfinitive(in: map)
    return VerbMap.shared.entries.values
      .sorted { $0.infinitive < $1.infinitive }
      .map { VerbEntity(entry: $0, spotlight: text(for: $0, forms: forms[$0.infinitive] ?? [])) }
  }

  static func text(for entry: VerbMapEntry, forms: [String]) -> Text {
    let glossPhrases = entry.glosses.flatMap(glossPhrases(in:)).uniqued()
    let keyConjugations = KeyConjugation.forms(of: entry.infinitive).map { $0.form.lowercased() }
    return Text(
      alternateNames: (glossPhrases + keyConjugations).uniqued(),
      keywords: (forms + entry.glosses + glossPhrases + glossPhrases.map { "to \($0)" }).uniqued(),
      description: keyConjugations.joined(separator: " · ")
    )
  }

  /// The phrases a reader might type for a gloss: "arrive, come" gives "arrive" and "come", and
  /// "put (something) away" gives "put away". The parentheses only say what the verb takes.
  static func glossPhrases(in gloss: String) -> [String] {
    gloss
      .replacing(/\([^)]*\)/, with: "")
      .split(whereSeparator: { $0 == "," || $0 == ";" })
      .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
      .filter { !$0.isEmpty }
  }

  /// Each verb's distinct one-word forms (fue, fui, yendo), in the map's order of cells. The
  /// map has no compound tenses and no imperativo negativo, whose last word is already a form.
  static func formsByInfinitive(in map: ConjugationMap) -> [String: [String]] {
    map.paradigms().mapValues { forms in
      forms.dropFirst().compactMap { $0 }.uniqued()
    }
  }

  /// The infinitive of the entry a Spotlight result names. A continued activity carries the
  /// entity's identifier, which iOS has written both bare and as "VerbEntity/<id>".
  static func infinitive(fromActivityIdentifier identifier: String) -> String? {
    let id = identifier.split(separator: "/").last.map(String.init) ?? identifier
    return VerbMap.shared.entry(for: id) == nil ? nil : id
  }
}

extension Array where Element: Hashable {
  /// The elements in order, each at its first appearance.
  nonisolated func uniqued() -> [Element] {
    var seen: Set<Element> = []
    return filter { seen.insert($0).inserted }
  }
}
