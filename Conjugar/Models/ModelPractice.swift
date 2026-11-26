//
//  ModelPractice.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A verb model as its practice sees it: Verb Essentials over the model's verbs alone, then mixed
/// with the models already known. Practicing a pattern alone before mixing it did better in Pan et
/// al. (2019); for verb models as such there is no study, so this is a bet.
struct ModelPracticeGroup: Identifiable {
  /// A model is its ten most frequent verbs, for what its practice asks and for what half of its
  /// items counts. Counted over every verb, cazar's 440 would need hundreds of right answers to be
  /// known, nearly all of them to rare verbs that repeat the pattern of the first ten.
  static let verbLimit = 10

  let classNumber: String
  let exemplar: String
  /// The most frequent first. Only verbs whose default sense follows the model, since the
  /// exercise conjugates that sense, and only those with an irregular key conjugation.
  let verbs: [String]

  var id: String {
    classNumber
  }

  /// One verb is not a pattern, so a single-verb model is not practiced alone. It joins other
  /// models' mixes once it is known.
  var offersPracticeAlone: Bool {
    verbs.count > 1
  }

  /// The items the group's answers move: each verb's irregular key conjugations, which are what
  /// Verb Essentials records as key conjugations. pensar's pensé is regular, so its answer moves
  /// the -ar pretérito's pattern, which every regular verb shares and no model owns.
  var items: [PracticeItem] {
    verbs.flatMap { verb in
      KeyConjugation.allCases.compactMap { key -> PracticeItem? in
        let item = PracticeItem.exercised(by: verb, tense: key.tense, personNumber: key.personNumber)
        guard case .keyConjugation? = item else {
          return nil
        }
        return item
      }
    }
  }

  /// A model is known once at least half of its items have moved past the first box. For a model
  /// of ten verbs with one irregular key conjugation each, that is one round of five answered
  /// right. A wrong answer sends an item back to the first box, so a model can stop being known.
  func isKnown(in record: PracticeRecord) -> Bool {
    let items = items
    guard !items.isEmpty else {
      return false
    }
    let climbed = items.filter(record.isPastFirstBox).count
    return 2 * climbed >= items.count
  }

  /// Every model with a verb the exercise can ask, in no particular order. The regular models
  /// are not patterns to practice, and five models (bullir, tañer, abolir) have no irregular key
  /// conjugation to ask.
  static let all: [ModelPracticeGroup] = ModelInfo.all.compactMap { row in
    guard !VerbMapEntry.isRegularClass(row.classNumber) else {
      return nil
    }
    let verbs = row.verbs
      .lazy
      .filter { ModelInfo.row(for: $0.infinitive)?.classNumber == row.classNumber }
      .map(\.infinitive)
      .filter(VerbEssentials.hasIrregularKeyConjugation)
      .prefix(verbLimit)
    guard !verbs.isEmpty else {
      return nil
    }
    return ModelPracticeGroup(classNumber: row.classNumber, exemplar: row.exemplar, verbs: Array(verbs))
  }

  /// The models with a pattern to practice, the most used first, by each model's most frequent
  /// verb: tener and hacer before pensar. This is the hub's list.
  static let practicedAloneByUse: [ModelPracticeGroup] = all
    .filter(\.offersPracticeAlone)
    .sorted { rank(of: $0) < rank(of: $1) }

  private static let groupsByClassNumber = Dictionary(uniqueKeysWithValues: all.map { ($0.classNumber, $0) })

  static func group(_ classNumber: String) -> ModelPracticeGroup? {
    groupsByClassNumber[classNumber]
  }

  /// The known models, single-verb models among them, the most used first.
  static func known(in record: PracticeRecord) -> [ModelPracticeGroup] {
    allByUse.filter { $0.isKnown(in: record) }
  }

  /// The models a mix adds to this one: every other known model. Mixed opens for a model once
  /// there is one, whether or not the model itself is known, since nothing here is earned.
  func mixPartners(in record: PracticeRecord) -> [ModelPracticeGroup] {
    Self.known(in: record).filter { $0.classNumber != classNumber }
  }

  private static let allByUse = all.sorted { rank(of: $0) < rank(of: $1) }

  private static func rank(of group: ModelPracticeGroup) -> Int {
    group.verbs.first.flatMap { VerbMap.shared.entry(for: $0)?.frequencyRank } ?? .max
  }
}

extension PracticeRecord {
  /// An item enters the first box and leaves it by a right answer given when it is due.
  func isPastFirstBox(_ item: PracticeItem) -> Bool {
    (entry(for: item)?.schedule.box ?? 0) > 0
  }
}

/// One of the two sessions a model offers.
nonisolated struct ModelPracticeSession: Hashable, Identifiable, Sendable {
  // Semantic ordering: alone comes before mixed.
  enum Mode: String, Sendable {
    case alone
    case mixed
  }

  let classNumber: String
  let mode: Mode

  var id: String {
    "\(classNumber)-\(mode.rawValue)"
  }

  var collection: VerbCollection {
    .model(classNumber)
  }

  var source: AnalyticsSource {
    switch mode {
    case .alone:
      return .modelAlone
    case .mixed:
      return .modelMixed
    }
  }
}

extension ModelPracticeSession {
  /// "Verbs Like pensar", as the model's page titles its collection, or "Mixed: pensar".
  var title: String {
    let exemplar = ModelCatalog.exemplar(forClass: classNumber) ?? classNumber
    switch mode {
    case .alone:
      return L.VerbCollection.modelTitle(exemplar: exemplar)
    case .mixed:
      return L.ModelPractice.mixedTitle(exemplar: exemplar)
    }
  }
}

extension QuizScope {
  /// Verb Essentials over a model, alone or mixed with the known models. The draw reads the model
  /// and the record itself, so `verbs` is only the model's.
  static func modelPractice(_ session: ModelPracticeSession) -> QuizScope {
    QuizScope(
      verbs: ModelPracticeGroup.group(session.classNumber)?.verbs ?? [],
      questionCount: verbEssentialsVerbCount * KeyConjugation.allCases.count,
      source: session.source,
      title: session.title,
      collectionKey: session.collection.key,
      isVerbEssentials: true,
      modelPractice: session
    )
  }
}

enum ModelPractice {
  /// How many of a mixed round's five verbs are the model's own. The rest are the known models'.
  /// The session stays mostly about the model the learner chose, and the two known verbs make
  /// them pick the pattern rather than repeat it.
  static let mixGroupVerbCount = 3

  /// A round's verbs. Alone, five of the model's verbs. Mixed, `mixGroupVerbCount` of them and the
  /// rest the known models', in a shuffled order, so that the learner has to tell the patterns
  /// apart. Verbs the session has asked come only once every other has been.
  static func verbs(
    for session: ModelPracticeSession,
    record: PracticeRecord,
    count: Int = QuizScope.verbEssentialsVerbCount,
    asked: Set<String> = [],
    using generator: inout some RandomNumberGenerator
  ) -> [String] {
    guard let group = ModelPracticeGroup.group(session.classNumber) else {
      return []
    }
    switch session.mode {
    case .alone:
      return VerbEssentials.verbs(from: group.verbs, count: count, asked: asked, limitsCompounds: false, using: &generator)
    case .mixed:
      return mixedVerbs(
        group: group,
        partners: group.mixPartners(in: record),
        count: count,
        groupCount: mixGroupVerbCount,
        asked: asked,
        using: &generator
      )
    }
  }

  /// A mixed round: `groupCount` verbs of `group`, and the rest drawn from `partners` one model at
  /// a time, so that a partner of ten verbs does not crowd out a partner of one. Whichever side
  /// cannot fill its share leaves the rest to the other.
  static func mixedVerbs(
    group: ModelPracticeGroup,
    partners: [ModelPracticeGroup],
    count: Int,
    groupCount: Int,
    asked: Set<String> = [],
    using generator: inout some RandomNumberGenerator
  ) -> [String] {
    let own = freshFirst(group.verbs, asked: asked, using: &generator)
    let queues = partners.shuffled(using: &generator).map { freshFirst($0.verbs, asked: asked, using: &generator) }
    let longest = queues.map(\.count).max() ?? 0
    let inTurn = (0..<longest).flatMap { turn in
      queues.compactMap { $0.indices.contains(turn) ? $0[turn] : nil }
    }
    // Taking one from each partner in turn can put an asked verb before another partner's fresh
    // one. Fresh verbs come first, each side keeping its turn order.
    let others = inTurn.filter { !asked.contains($0) } + inTurn.filter { asked.contains($0) }

    let otherCount = min(max(count - min(groupCount, own.count), 0), others.count)
    let ownCount = min(count - otherCount, own.count)
    return (own.prefix(ownCount) + others.prefix(otherCount)).shuffled(using: &generator)
  }

  private static func freshFirst(_ verbs: [String], asked: Set<String>, using generator: inout some RandomNumberGenerator) -> [String] {
    verbs.filter { !asked.contains($0) }.shuffled(using: &generator) + verbs.filter { asked.contains($0) }.shuffled(using: &generator)
  }
}
