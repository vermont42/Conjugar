//
//  Mastery.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// How far up the review ladder an item has come, as the Mastery page shows it.
enum MasteryState: CaseIterable {
  // Semantic ordering: the legend's, from the top of the ladder down.
  case mastered
  case learning
  case notPracticed

  /// The third box, whose interval is seven days. Below it an item is learning, a lookup
  /// included.
  nonisolated static let masteredBox = 2

  init(_ entry: PracticeRecord.Entry?) {
    guard let entry else {
      self = .notPracticed
      return
    }
    self = entry.schedule.box >= Self.masteredBox ? .mastered : .learning
  }
}

extension PracticeRecord {
  func masteryState(of item: PracticeItem) -> MasteryState {
    MasteryState(entry(for: item))
  }
}

/// What the practice record has made secure at a level, in the two kinds of item it keeps. A
/// regular cell is a pattern that every verb of its ending regular there shares, so the patterns
/// appear once, a grid of endings by persons for each tense, rather than as a row per regular verb
/// filling in together. An irregular verb shows the key conjugations its irregular cells are built
/// on, as far as the level asks them.
struct Mastery {
  /// A tense's patterns at the level: a row per ending, and in each a state per person. The
  /// gerundio has one person, `.none`.
  struct PatternTable: Identifiable {
    let tense: DisplayTense
    let personNumbers: [DisplayPersonNumber]
    let rows: [PatternRow]

    var id: DisplayTense {
      tense
    }
  }

  struct PatternRow: Identifiable {
    let ending: RegularRoot
    /// In the order of the table's `personNumbers`.
    let states: [MasteryState]

    var id: String {
      ending.practiceKey
    }
  }

  /// One key conjugation of an irregular verb, and how far the record has it.
  struct KeyConjugationMark: Identifiable {
    let key: PracticeItem.Key
    let state: MasteryState

    var id: String {
      key.rawValue
    }
  }

  struct VerbRow: Identifiable {
    let infinitive: String
    let keyConjugations: [KeyConjugationMark]

    var id: String {
      infinitive
    }
  }

  /// The verbs the page lists, the same at every level: the most frequent irregular verbs, as
  /// the verb page's pill counts them, spelling changes (llegar) and prefixed compounds
  /// (mantener) included, since the record keeps their key conjugations like any other's.
  static let coreVerbCount = 50

  static let coreVerbs: [String] = Array(VerbEssentials.pool(band: nil).prefix(coreVerbCount))

  let level: QuizLevel
  let patterns: [PatternTable]
  /// The core verbs with a key conjugation the level asks. A verb whose irregular cells all lie
  /// beyond the level, such as creer (creí, creyó) at Beginner, is left out there.
  let verbs: [VerbRow]

  init(level: QuizLevel, record: PracticeRecord, secondSingular: DisplayPersonNumber, region: Region) {
    self.level = level
    let layout = Self.layout(level: level, secondSingular: secondSingular, region: region)
    patterns = layout.patterns.map { table in
      PatternTable(
        tense: table.tense,
        personNumbers: table.personNumbers,
        rows: Self.endings.map { ending in
          PatternRow(
            ending: ending,
            states: table.personNumbers.map { personNumber in
              PracticeItem.pattern(of: ConjugationCell(tense: table.tense, personNumber: personNumber), ending: ending)
                .map(record.masteryState) ?? .notPracticed
            }
          )
        }
      )
    }
    verbs = layout.verbs.map { verb in
      VerbRow(
        infinitive: verb.infinitive,
        keyConjugations: verb.keys.map { key in
          KeyConjugationMark(key: key, state: record.masteryState(of: .keyConjugation(infinitive: verb.infinitive, key: key)))
        }
      )
    }
  }

  /// The learner's: the level, the record, the tú or vos, and the region set now.
  static func current() -> Mastery {
    let settings = Current.settings
    return Mastery(
      level: settings.quizLevel,
      record: Current.practice.record,
      secondSingular: settings.secondSingularQuiz == .tu ? .secondSingularTú : .secondSingularVos,
      region: settings.region
    )
  }

  var patternCount: Int {
    patterns.reduce(0) { $0 + $1.rows.reduce(0) { $0 + $1.states.count } }
  }

  var masteredPatternCount: Int {
    patterns.reduce(0) { total, table in
      total + table.rows.reduce(0) { $0 + $1.states.filter { $0 == .mastered }.count }
    }
  }

  var verbCount: Int {
    verbs.count
  }

  /// A verb counts once every key conjugation the level asks of it is mastered.
  var masteredVerbCount: Int {
    verbs.filter { row in row.keyConjugations.allSatisfy { $0.state == .mastered } }.count
  }

  static let endings: [RegularRoot] = [.ar, .er, .ir]

  /// The key conjugations of the verb that the level asks: those with an irregular cell built on
  /// them that the level asks in a person the settings allow. Only such a cell's answer moves a
  /// key conjugation, so tener's tenido, a regular participle, is never one.
  static func keyConjugations(of infinitive: String, askedBy asks: (ConjugationCell) -> Bool) -> [PracticeItem.Key] {
    PracticeItem.Key.allCases.filter { key in
      key.cells.contains { cell in asks(cell) && QuizDraw.isIrregular(infinitive, in: cell) == true }
    }
  }

  /// What the page lists at a level, apart from the record: each tense's persons and each verb's
  /// key conjugations. Kept once per level and settings, since the verbs' take some thousands of
  /// conjugations and the Quiz tab's row builds a `Mastery` each time it draws.
  private struct Layout {
    let patterns: [(tense: DisplayTense, personNumbers: [DisplayPersonNumber])]
    let verbs: [(infinitive: String, keys: [PracticeItem.Key])]
  }

  private static var layouts: [String: Layout] = [:]

  private static func layout(level: QuizLevel, secondSingular: DisplayPersonNumber, region: Region) -> Layout {
    let cacheKey = [level.rawValue, secondSingular.rawValue, region.rawValue].joined(separator: ":")
    if let cached = layouts[cacheKey] {
      return cached
    }
    let patterns = level.pool.map { entry in
      (
        tense: entry.tense,
        personNumbers: Quiz.personNumbers(in: entry.tense, secondSingular: secondSingular, region: region).filter(entry.asks)
      )
    }
    let asks = { (cell: ConjugationCell) -> Bool in
      patterns.contains { $0.tense == cell.tense && $0.personNumbers.contains(cell.personNumber) }
    }
    let verbs = coreVerbs.compactMap { infinitive -> (infinitive: String, keys: [PracticeItem.Key])? in
      let keys = keyConjugations(of: infinitive, askedBy: asks)
      return keys.isEmpty ? nil : (infinitive, keys)
    }
    let layout = Layout(patterns: patterns, verbs: verbs)
    layouts[cacheKey] = layout
    return layout
  }
}
