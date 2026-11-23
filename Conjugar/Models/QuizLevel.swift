//
//  QuizLevel.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// What the quiz asks, chosen by the learner. Each level adds tenses to the one before, roughly
/// in the order a course teaches them (A1, A2, B1, then B2 and above), and nothing unlocks.
nonisolated enum QuizLevel: String, CaseIterable, Sendable {
  case beginner
  case elementary
  case intermediate
  case advanced

  /// A new install's level.
  static let initial = QuizLevel.beginner

  /// The level a setting from before levels becomes: Easy already asked the pretérito and futuro.
  init?(legacyDifficulty: String) {
    switch legacyDifficulty {
    case "Easy":
      self = .elementary
    case "Moderate":
      self = .intermediate
    case "Difficult":
      self = .advanced
    default:
      return nil
    }
  }

  var localizedName: String {
    switch self {
    case .beginner:
      return L.QuizLevel.beginner
    case .elementary:
      return L.QuizLevel.elementary
    case .intermediate:
      return L.QuizLevel.intermediate
    case .advanced:
      return L.QuizLevel.advanced
    }
  }

  var systemImage: String {
    switch self {
    case .beginner:
      return "gauge.with.dots.needle.0percent"
    case .elementary:
      return "gauge.with.dots.needle.33percent"
    case .intermediate:
      return "gauge.with.dots.needle.67percent"
    case .advanced:
      return "gauge.with.dots.needle.100percent"
    }
  }

  /// The most frequent verbs the default quiz draws from, or nil for every verb.
  var band: FrequencyBand? {
    switch self {
    case .beginner:
      return .top100
    case .elementary:
      return .top300
    case .intermediate:
      return .top1000
    case .advanced:
      return nil
    }
  }

  /// The tenses the level asks, written out per level so that each reads as a whole.
  var pool: [QuizPoolEntry] {
    switch self {
    case .beginner:
      return [
        QuizPoolEntry(.presenteDeIndicativo),
        QuizPoolEntry(.imperativoPositivo, excluding: QuizPoolEntry.nosotrosAndVosotros)
      ]
    case .elementary:
      return [
        QuizPoolEntry(.presenteDeIndicativo),
        QuizPoolEntry(.imperativoPositivo, excluding: QuizPoolEntry.nosotrosAndVosotros),
        QuizPoolEntry(.pretérito),
        QuizPoolEntry(.imperfectoDeIndicativo),
        QuizPoolEntry(.perfectoDeIndicativo),
        QuizPoolEntry(.futuroDeIndicativo),
        QuizPoolEntry(.gerundio)
      ]
    case .intermediate:
      return [
        QuizPoolEntry(.presenteDeIndicativo),
        QuizPoolEntry(.imperativoPositivo),
        QuizPoolEntry(.pretérito),
        QuizPoolEntry(.imperfectoDeIndicativo),
        QuizPoolEntry(.perfectoDeIndicativo),
        QuizPoolEntry(.futuroDeIndicativo),
        QuizPoolEntry(.gerundio),
        QuizPoolEntry(.presenteDeSubjuntivo),
        QuizPoolEntry(.imperativoNegativo),
        QuizPoolEntry(.condicional),
        QuizPoolEntry(.pluscuamperfectoDeIndicativo),
        QuizPoolEntry(.futuroPerfecto)
      ]
    case .advanced:
      return [
        QuizPoolEntry(.presenteDeIndicativo),
        QuizPoolEntry(.imperativoPositivo),
        QuizPoolEntry(.pretérito),
        QuizPoolEntry(.imperfectoDeIndicativo),
        QuizPoolEntry(.perfectoDeIndicativo),
        QuizPoolEntry(.futuroDeIndicativo),
        QuizPoolEntry(.gerundio),
        QuizPoolEntry(.presenteDeSubjuntivo),
        QuizPoolEntry(.imperativoNegativo),
        QuizPoolEntry(.condicional),
        QuizPoolEntry(.pluscuamperfectoDeIndicativo),
        QuizPoolEntry(.futuroPerfecto),
        QuizPoolEntry(.imperfectoDeSubjuntivo1),
        QuizPoolEntry(.imperfectoDeSubjuntivo2),
        QuizPoolEntry(.perfectoDeSubjuntivo),
        QuizPoolEntry(.pluscuamperfectoDeSubjuntivo1),
        QuizPoolEntry(.pluscuamperfectoDeSubjuntivo2),
        QuizPoolEntry(.condicionalCompuesto),
        QuizPoolEntry(.futuroDeSubjuntivo),
        QuizPoolEntry(.futuroPerfectoDeSubjuntivo),
        QuizPoolEntry(.pretéritoAnterior)
      ]
    }
  }

  /// The entry that asks a tense at this level, if the level asks it.
  func entry(for tense: DisplayTense) -> QuizPoolEntry? {
    pool.first { $0.tense == tense }
  }
}

/// One tense a level asks, the persons it may not ask there, and how often it is drawn.
nonisolated struct QuizPoolEntry: Equatable, Sendable {
  let tense: DisplayTense
  let excludedPersons: Set<DisplayPersonNumber>

  init(_ tense: DisplayTense, excluding excludedPersons: Set<DisplayPersonNumber> = []) {
    self.tense = tense
    self.excludedPersons = excludedPersons
  }

  /// A beginner's commands are those a learner is given and gives: tú or vos, usted, and ustedes.
  static let nosotrosAndVosotros: Set<DisplayPersonNumber> = [.firstPlural, .secondPlural]

  func asks(_ personNumber: DisplayPersonNumber) -> Bool {
    !excludedPersons.contains(personNumber)
  }

  /// A tense is weighted as a whole, whatever its number of persons, and the same at every
  /// level; the weights never follow what the learner has done. The presente and the two
  /// common pasts are the most used. A compound tense is haber, which the presente and other
  /// simple tenses already ask, and a participle that never changes, so a learner who knows
  /// those gets it right; the gerundio is one form, and the futuro de subjuntivo is rare outside
  /// legal and literary prose.
  var weight: Int {
    switch tense {
    case .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo:
      return 3
    case .futuroDeIndicativo, .condicional, .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2,
      .imperativoPositivo, .imperativoNegativo:
      return 2
    default:
      return 1
    }
  }
}

nonisolated extension Array where Element == QuizPoolEntry {
  /// One entry drawn in proportion to its weight.
  func weightedRandomElement(using generator: inout some RandomNumberGenerator) -> QuizPoolEntry? {
    let total = reduce(0) { $0 + $1.weight }
    guard total > 0 else {
      return nil
    }
    var roll = Int.random(in: 0..<total, using: &generator)
    for entry in self {
      if roll < entry.weight {
        return entry
      }
      roll -= entry.weight
    }
    return last
  }

  /// Every entry once, in an order drawn by weight, so a heavier tense tends to come first.
  func weightedShuffled(using generator: inout some RandomNumberGenerator) -> [QuizPoolEntry] {
    var remaining = self
    var ordered: [QuizPoolEntry] = []
    while let entry = remaining.weightedRandomElement(using: &generator), let index = remaining.firstIndex(of: entry) {
      ordered.append(entry)
      remaining.remove(at: index)
    }
    return ordered
  }
}
