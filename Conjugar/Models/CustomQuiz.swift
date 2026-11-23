//
//  CustomQuiz.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A quiz the learner puts together on the Quiz tab: tenses, a verb set, or both. A part left
/// unchosen is the learner's level's, so a choice of verbs alone asks the level's tenses, and a
/// choice of tenses alone asks the level's verbs, mixed as the default quiz's are. Any tense may be
/// chosen, above the learner's level or not, since the choice is the learner's own.
nonisolated struct CustomQuiz: Equatable, Sendable {
  /// Empty asks the level's tenses.
  var tenses: Set<DisplayTense> = []
  /// Nil asks the level's verbs.
  var verbSet: QuizVerbSet?

  var isEmpty: Bool {
    tenses.isEmpty && verbSet == nil
  }

  /// Every tense a quiz asks, in the order the levels add them.
  static let choosableTenses: [DisplayTense] = QuizLevel.advanced.pool.map(\.tense)

  /// The chosen tenses in `choosableTenses`' order.
  var orderedTenses: [DisplayTense] {
    Self.choosableTenses.filter(tenses.contains)
  }

  /// What the quiz asks. A chosen tense is asked as Advanced asks it, of every person, so that a
  /// chosen imperativo positivo asks nosotros and vosotros too.
  func pool(level: QuizLevel) -> [QuizPoolEntry] {
    guard !tenses.isEmpty else {
      return level.pool
    }
    return QuizLevel.advanced.pool.filter { tenses.contains($0.tense) }
  }

  /// The band a mixed draw takes its verbs from: the chosen band, or the level's.
  func band(level: QuizLevel) -> FrequencyBand? {
    switch verbSet {
    case nil:
      return level.band
    case .band(let band):
      return band
    case .all, .collection, .myVerbs:
      return nil
    }
  }

  /// What `startQuiz` says the learner chose, without saying what.
  var choiceParameter: String {
    switch (tenses.isEmpty, verbSet == nil) {
    case (false, false):
      return "both"
    case (false, true):
      return "tenses"
    case (true, _):
      return "verbs"
    }
  }

  /// The tense's permanent key in the stored choice: its Info article's, which a deeplink
  /// already names, or `gerundio`, which has no article of its own.
  static func key(for tense: DisplayTense) -> String {
    tense == .gerundio ? gerundioKey : ConjugationTable(tense: tense).articleKey
  }

  static func tense(forKey key: String) -> DisplayTense? {
    choosableTenses.first { Self.key(for: $0) == key }
  }

  private static let gerundioKey = "gerundio"
  private static let tensesKey = "tenses"
  private static let verbsKey = "verbs"
}

/// Stored as `tenses=presente_de_indicativo,preterito&verbs=goVerbs`, a form a link's query can
/// carry unchanged. The keys are permanent, since the choice is kept between launches. A key that
/// no longer names anything is dropped rather than failing the whole choice.
nonisolated extension CustomQuiz: RawRepresentable {
  init?(rawValue: String) {
    var components = URLComponents()
    components.percentEncodedQuery = rawValue
    let items = components.queryItems ?? []
    let tenseKeys = items.first { $0.name == Self.tensesKey }?.value?.split(separator: ",").map(String.init) ?? []
    tenses = Set(tenseKeys.compactMap(Self.tense(forKey:)))
    verbSet = items.first { $0.name == Self.verbsKey }?.value.flatMap(QuizVerbSet.init(key:))
  }

  var rawValue: String {
    var items: [URLQueryItem] = []
    if !tenses.isEmpty {
      items.append(URLQueryItem(name: Self.tensesKey, value: orderedTenses.map(Self.key(for:)).joined(separator: ",")))
    }
    if let verbSet {
      items.append(URLQueryItem(name: Self.verbsKey, value: verbSet.key))
    }
    var components = URLComponents()
    components.queryItems = items
    return components.percentEncodedQuery ?? ""
  }
}

/// The verbs a custom quiz may ask about.
nonisolated enum QuizVerbSet: Hashable, Sendable {
  case all
  case band(FrequencyBand)
  /// A pattern list or a model. The top 100 is offered as its band, which holds the same verbs.
  case collection(VerbCollection)
  case myVerbs

  /// A band or every verb is chosen for its size, not its verbs, so it is mixed as the default
  /// quiz is (`QuizDraw`); a collection and My Verbs are lists, and are not.
  var mixesVerbs: Bool {
    switch self {
    case .all, .band:
      return true
    case .collection, .myVerbs:
      return false
    }
  }

  /// The collection's key, for `startQuiz` to name as a collection's quiz does.
  var collectionKey: String? {
    if case .collection(let collection) = self {
      return collection.key
    }
    return nil
  }

  var key: String {
    switch self {
    case .all:
      return Self.allKey
    case .band(let band):
      return Self.bandKey(band)
    case .collection(let collection):
      return collection.key
    case .myVerbs:
      return Self.myVerbsKey
    }
  }

  /// The top-100 band and the top-100 collection share the key `top100`, which reads back as the
  /// band.
  init?(key: String) {
    if let band = FrequencyBand.allCases.first(where: { Self.bandKey($0) == key }) {
      self = .band(band)
      return
    }
    switch key {
    case Self.allKey:
      self = .all
    case Self.myVerbsKey:
      self = .myVerbs
    default:
      guard let collection = VerbCollection(key: key) else {
        return nil
      }
      self = .collection(collection)
    }
  }

  /// The infinitives a list asks about, or nil for a set the draw mixes from a band.
  func infinitives(myVerbs: [String]) -> [String]? {
    switch self {
    case .all, .band:
      return nil
    case .collection(let collection):
      return collection.infinitives
    case .myVerbs:
      return myVerbs
    }
  }

  /// The pattern lists, offered beside the bands. The top 100 is the band.
  static let patternCollections: [VerbCollection] = VerbCollection.featured.filter { $0 != .top100 }

  private static let allKey = "all"
  private static let myVerbsKey = "myVerbs"

  private static func bandKey(_ band: FrequencyBand) -> String {
    "top\(band.verbCount)"
  }
}

nonisolated extension QuizScope {
  /// A custom quiz from the Quiz tab: a round of ten, then Ten More, never ranked.
  static func custom(_ custom: CustomQuiz, myVerbs: [String]) -> QuizScope {
    QuizScope(
      verbs: custom.verbSet?.infinitives(myVerbs: myVerbs),
      questionCount: roundLength,
      source: .custom,
      collectionKey: custom.verbSet?.collectionKey,
      custom: custom
    )
  }
}
