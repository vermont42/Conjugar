//
//  QuizDraw.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Synchronization

/// Chooses the verbs of the default quiz, whose verbs the learner did not choose, once its cells
/// are drawn. The verbs come from the level's frequency band (`QuizLevel.band`), and the quiz is
/// balanced:
///
/// - Half its questions, rounded down, ask a cell in which the verb is irregular, judged per cell
///   (`isIrregular(_:in:)`), since tener is irregular in the presente and regular in the imperfecto.
///   A tense in which few verbs are irregular, as only ser, ir, and ver are in the imperfecto, asks
///   at most one irregular question where the other tenses can make up the half, so a quiz does
///   not repeat era, iba, and veía.
/// - At least two questions ask a core verb (`coreVerbs`).
/// - A prefixed compound (`VerbRelations`) of the 300 most frequent verbs draws as freely as
///   a base verb, since mantener and conseguir are as basic as tener and seguir. Where the band
///   reaches past them, one to three questions ask a rarer compound and no other question does;
///   where it does not, at least one question asks a compound.
/// - The regular questions take the -ar, -er, and -ir endings in turn.
///
/// Every slot gets its role and its irregularity before any verb is drawn, so the counts are exact
/// rather than likely.
nonisolated enum QuizDraw {
  /// The verbs a learner meets most and must know in every tense.
  static let coreVerbs: Set<String> = ["ser", "estar", "haber", "tener", "ir", "hacer"]
  static let minimumCoreQuestions = 2
  static let rareCompoundRange = 1...3
  static let frequentCompoundBand = FrequencyBand.top300
  /// A tense whose irregular verbs in the band come from fewer roots than this asks at most one
  /// irregular question. Roots, not verbs, so that prever and entrever count with ver.
  static let fewIrregularRoots = 5
  static let maximumIrregularWhereFew = 1

  /// The verbs a level's default quiz draws from, the most frequent first.
  static func verbs(for level: QuizLevel) -> [VerbMapEntry] {
    bands[level]?.verbs ?? []
  }

  /// Whether the engine's form of the cell marks an irregular letter, a spelling change (llegué,
  /// cojo) included, as the verb page shows it in red. A compound tense is judged by its
  /// participle alone, since its haber is the same for every verb. Nil when the verb has no form
  /// for the cell.
  static func isIrregular(_ verb: String, in cell: ConjugationCell) -> Bool? {
    let judged = cell.tense.isCompound ? ConjugationCell(tense: .participio, personNumber: .none) : cell
    guard case let .success(form) = TenseBridge.conjugate(infinitive: verb, tense: judged.tense, personNumber: judged.personNumber) else {
      return nil
    }
    return form.contains(where: \.isUppercase)
  }

  static func isCore(_ verb: String) -> Bool {
    coreVerbs.contains(verb)
  }

  static func isCompound(_ verb: String) -> Bool {
    VerbRelations.shared.baseByVerb[verb] != nil
  }

  static func isRareCompound(_ entry: VerbMapEntry) -> Bool {
    isCompound(entry.infinitive) && !entry.isIn(frequentCompoundBand)
  }

  /// One question per cell, in the cells' order.
  static func questions(cells: [ConjugationCell], level: QuizLevel, using generator: inout some RandomNumberGenerator) -> [QuizQuestion] {
    guard let band = bands[level], !cells.isEmpty else {
      return []
    }
    var draw = Draw(band: band)
    return draw.questions(cells: cells, using: &generator)
  }

  private enum Kind: Int, CaseIterable {
    case core
    case frequentCompound
    case rareCompound
    case other
  }

  private enum Role {
    case core
    case compound
    case rareCompound
    case free
  }

  private struct Band {
    let level: QuizLevel
    let verbs: [VerbMapEntry]
    let reachesRareCompounds: Bool
    /// The band's infinitives by class number, then by kind (`Kind.rawValue`), each list by
    /// frequency.
    let verbsByClass: [String: [[String]]]

    init(level: QuizLevel, verbs: [VerbMapEntry]) {
      self.level = level
      self.verbs = verbs
      reachesRareCompounds = verbs.contains(where: QuizDraw.isRareCompound)
      var verbsByClass: [String: [[String]]] = [:]
      for entry in verbs {
        verbsByClass[entry.classNumber, default: Array(repeating: [], count: Kind.allCases.count)][Self.kind(of: entry).rawValue].append(entry.infinitive)
      }
      self.verbsByClass = verbsByClass
    }

    private static func kind(of entry: VerbMapEntry) -> Kind {
      if QuizDraw.isCore(entry.infinitive) {
        return .core
      }
      if QuizDraw.isRareCompound(entry) {
        return .rareCompound
      }
      return QuizDraw.isCompound(entry.infinitive) ? .frequentCompound : .other
    }

    func kinds(for role: Role) -> [Kind] {
      switch role {
      case .core:
        return [.core]
      case .compound:
        return [.frequentCompound, .rareCompound]
      case .rareCompound:
        return [.rareCompound]
      case .free:
        return reachesRareCompounds ? [.core, .frequentCompound, .other] : Kind.allCases
      }
    }
  }

  private static let bands: [QuizLevel: Band] = Dictionary(uniqueKeysWithValues: QuizLevel.allCases.map { level in
    let verbs = level.band.map { VerbMap.shared.entries(in: $0) }
      ?? VerbMap.shared.entries.values.sorted { $0.frequencyRank < $1.frequencyRank }
    return (level, Band(level: level, verbs: verbs))
  })

  /// A model's features are end-anchored, so the verbs of a class are irregular in the same
  /// cells, with rare exceptions (prever and entrever share a class but not a marking), which
  /// the draw catches by judging the verb it chose. Judging one verb per class keeps a draw over
  /// every verb to about a hundred engine calls a cell.
  private static let representatives: [String: String] = {
    var representatives: [String: String] = [:]
    for entry in VerbMap.shared.entries.values.sorted(by: { $0.frequencyRank < $1.frequencyRank }) where representatives[entry.classNumber] == nil {
      representatives[entry.classNumber] = entry.infinitive
    }
    return representatives
  }()

  private static let endingsByClass: [String: RegularRoot] = representatives.compactMapValues { RegularRoot(infinitive: $0) }

  private static let irregularityByCell = Mutex<[ConjugationCell: [(classNumber: String, isIrregular: Bool)]]>([:])

  /// One class of a band that can be asked a cell.
  private struct ClassInCell {
    let isIrregular: Bool
    let ending: RegularRoot?
    let verbsByKind: [[String]]
  }

  private struct LevelCell: Hashable {
    let level: QuizLevel
    let cell: ConjugationCell
  }

  private static let classesByLevelCell = Mutex<[LevelCell: [ClassInCell]]>([:])

  /// The band's classes that can be asked the cell, in a fixed order so that a seed draws the
  /// same quiz in every process.
  private static func classes(of band: Band, in cell: ConjugationCell) -> [ClassInCell] {
    let key = LevelCell(level: band.level, cell: cell)
    if let known = classesByLevelCell.withLock({ $0[key] }) {
      return known
    }
    let computed = classIrregularity(in: cell).compactMap { classNumber, isIrregular in
      band.verbsByClass[classNumber].map { ClassInCell(isIrregular: isIrregular, ending: endingsByClass[classNumber], verbsByKind: $0) }
    }
    classesByLevelCell.withLock { $0[key] = computed }
    return computed
  }

  /// Each class that can be asked the cell, with whether it is irregular there, in a fixed order
  /// so that a seed draws the same quiz in every process.
  private static func classIrregularity(in cell: ConjugationCell) -> [(classNumber: String, isIrregular: Bool)] {
    if let known = irregularityByCell.withLock({ $0[cell] }) {
      return known
    }
    let computed: [(classNumber: String, isIrregular: Bool)] = representatives
      .compactMap { classNumber, verb in isIrregular(verb, in: cell).map { (classNumber: classNumber, isIrregular: $0) } }
      .sorted { $0.classNumber < $1.classNumber }
    irregularityByCell.withLock { $0[cell] = computed }
    return computed
  }

  private struct Slot {
    let cell: ConjugationCell
    var role = Role.free
    var isIrregular: Bool?
    var ending: RegularRoot?
  }

  private struct CandidateKey: Hashable {
    let cell: ConjugationCell
    let role: Role
    let isIrregular: Bool?
    let ending: RegularRoot?
  }

  /// Verbs held as the band's own lists, unjoined, so that no draw copies a band.
  private struct Candidates {
    let lists: [[String]]
    let count: Int

    init(lists: [[String]]) {
      self.lists = lists
      count = lists.reduce(0) { $0 + $1.count }
    }

    var isEmpty: Bool {
      count == 0
    }

    subscript(position: Int) -> String {
      var remaining = position
      for list in lists {
        if remaining < list.count {
          return list[remaining]
        }
        remaining -= list.count
      }
      preconditionFailure("Candidate \(position) is beyond \(count).")
    }

    func first(where predicate: (String) -> Bool) -> String? {
      for list in lists {
        if let found = list.first(where: predicate) {
          return found
        }
      }
      return nil
    }
  }

  private struct Draw {
    let band: Band
    private var candidatesByKey: [CandidateKey: Candidates] = [:]

    init(band: Band) {
      self.band = band
    }

    mutating func questions(cells: [ConjugationCell], using generator: inout some RandomNumberGenerator) -> [QuizQuestion] {
      var slots = cells.map { Slot(cell: $0) }

      var roleNeeds: [(role: Role, count: Int)] = [(.core, QuizDraw.minimumCoreQuestions)]
      if band.reachesRareCompounds {
        roleNeeds.append((.rareCompound, Int.random(in: QuizDraw.rareCompoundRange, using: &generator)))
      } else {
        roleNeeds.append((.compound, 1))
      }
      // A role goes to different cells where it can, since a cell may hold only one core verb
      // of the irregularity it is given (haces alone is regular among the core verbs' tú forms).
      var unassigned = slots.indices.shuffled(using: &generator)
      for (role, needed) in roleNeeds {
        var cellsGiven: Set<ConjugationCell> = []
        for _ in 0..<needed {
          let position = unassigned.firstIndex { !cellsGiven.contains(slots[$0].cell) && hasCandidate(slots[$0].cell, role, isIrregular: nil) }
            ?? unassigned.firstIndex { hasCandidate(slots[$0].cell, role, isIrregular: nil) }
          guard let position else {
            break
          }
          let index = unassigned.remove(at: position)
          slots[index].role = role
          cellsGiven.insert(slots[index].cell)
        }
      }

      var flexible: [Int] = []
      for index in slots.indices {
        let admitsIrregular = hasCandidate(slots[index].cell, slots[index].role, isIrregular: true)
        let admitsRegular = hasCandidate(slots[index].cell, slots[index].role, isIrregular: false)
        if admitsIrregular, admitsRegular {
          flexible.append(index)
        } else {
          slots[index].isIrregular = admitsIrregular
        }
      }
      let fewTenses = fewIrregularTenses(among: slots)
      var preferred: [Int] = []
      var deferred: [Int] = []
      var irregularWhereFew: [DisplayTense: Int] = [:]
      for index in flexible.shuffled(using: &generator) {
        let tense = slots[index].cell.tense
        if fewTenses.contains(tense) {
          let taken = irregularWhereFew[tense, default: 0]
          if taken < QuizDraw.maximumIrregularWhereFew {
            irregularWhereFew[tense] = taken + 1
            preferred.append(index)
          } else {
            deferred.append(index)
          }
        } else {
          preferred.append(index)
        }
      }
      // A cell's slots of one role and irregularity get no more questions than it has verbs to
      // give them, as Beginner's presente has only sois and vais irregular for vosotros, unless
      // the half cannot be made otherwise.
      func key(_ index: Int, isIrregular: Bool) -> CandidateKey {
        CandidateKey(cell: slots[index].cell, role: slots[index].role, isIrregular: isIrregular, ending: nil)
      }
      var used: [CandidateKey: Int] = [:]
      for index in slots.indices {
        if let isIrregular = slots[index].isIrregular {
          used[key(index, isIrregular: isIrregular), default: 0] += 1
        }
      }
      var irregularNeeded = cells.count / 2 - slots.filter { $0.isIrregular == true }.count
      var overflow: [Int] = []
      for index in preferred + deferred {
        let irregularKey = key(index, isIrregular: true)
        let regularKey = key(index, isIrregular: false)
        let hasIrregularRoom = used[irregularKey, default: 0] < candidates(for: irregularKey).count
        let hasRegularRoom = used[regularKey, default: 0] < candidates(for: regularKey).count
        let isIrregular: Bool
        if irregularNeeded > 0, hasIrregularRoom {
          isIrregular = true
          irregularNeeded -= 1
        } else {
          isIrregular = false
          if !hasIrregularRoom || !hasRegularRoom {
            overflow.append(index)
          }
        }
        slots[index].isIrregular = isIrregular
        used[isIrregular ? irregularKey : regularKey, default: 0] += 1
      }
      for index in overflow where irregularNeeded > 0 && slots[index].isIrregular == false {
        slots[index].isIrregular = true
        irregularNeeded -= 1
      }

      let endings: [RegularRoot] = [.ar, .er, .ir]
      var endingTurn = 0
      for index in slots.indices where slots[index].isIrregular == false && slots[index].role == .free {
        let ending = endings[endingTurn % endings.count]
        endingTurn += 1
        if !candidates(for: CandidateKey(cell: slots[index].cell, role: .free, isIrregular: false, ending: ending)).isEmpty {
          slots[index].ending = ending
        }
      }

      var asked: [QuizQuestion] = []
      for slot in slots {
        if let question = question(for: slot, avoiding: asked, using: &generator) {
          asked.append(question)
        }
      }
      return asked
    }

    private mutating func hasCandidate(_ cell: ConjugationCell, _ role: Role, isIrregular: Bool?) -> Bool {
      !candidates(for: CandidateKey(cell: cell, role: role, isIrregular: isIrregular, ending: nil)).isEmpty
    }

    /// The band's verbs of the role whose class can be asked the cell with the irregularity
    /// wanted, by frequency within each class.
    private mutating func candidates(for key: CandidateKey) -> Candidates {
      if let known = candidatesByKey[key] {
        return known
      }
      let kinds = band.kinds(for: key.role)
      var lists: [[String]] = []
      for candidateClass in QuizDraw.classes(of: band, in: key.cell) {
        guard
          key.isIrregular.map({ $0 == candidateClass.isIrregular }) ?? true,
          key.ending.map({ $0 == candidateClass.ending }) ?? true
        else {
          continue
        }
        for kind in kinds where !candidateClass.verbsByKind[kind.rawValue].isEmpty {
          lists.append(candidateClass.verbsByKind[kind.rawValue])
        }
      }
      let found = Candidates(lists: lists)
      candidatesByKey[key] = found
      return found
    }

    /// The tenses among the slots whose irregular verbs in the band come from few roots.
    private mutating func fewIrregularTenses(among slots: [Slot]) -> Set<DisplayTense> {
      var cellByTense: [DisplayTense: ConjugationCell] = [:]
      for slot in slots where cellByTense[slot.cell.tense] == nil {
        cellByTense[slot.cell.tense] = slot.cell
      }
      var few: Set<DisplayTense> = []
      for (tense, cell) in cellByTense {
        let irregular = candidates(for: CandidateKey(cell: cell, role: .free, isIrregular: true, ending: nil)).lists
          + candidates(for: CandidateKey(cell: cell, role: .rareCompound, isIrregular: true, ending: nil)).lists
        var roots: Set<String> = []
        for verb in irregular.joined() {
          roots.insert(VerbRelations.shared.rootByVerb[verb] ?? verb)
          if roots.count >= QuizDraw.fewIrregularRoots {
            break
          }
        }
        if roots.count < QuizDraw.fewIrregularRoots {
          few.insert(tense)
        }
      }
      return few
    }

    /// A verb for the slot, confirmed against the engine, preferring one the quiz has not asked.
    /// A slot that no verb fits as assigned, which the class judgment or a crowded cell can
    /// rarely cause, gives up its ending, then its role, and only then its irregularity.
    private mutating func question(for slot: Slot, avoiding asked: [QuizQuestion], using generator: inout some RandomNumberGenerator) -> QuizQuestion? {
      let askedVerbs = Set(asked.map(\.verb))
      func fits(_ verb: String, isIrregular wanted: Bool?, allowingAskedVerb: Bool) -> Bool {
        guard allowingAskedVerb || !askedVerbs.contains(verb) else {
          return false
        }
        guard !asked.contains(QuizQuestion(verb, slot.cell.tense, slot.cell.personNumber)) else {
          return false
        }
        guard let isIrregular = QuizDraw.isIrregular(verb, in: slot.cell) else {
          return false
        }
        return wanted.map { $0 == isIrregular } ?? true
      }
      var keys = [
        CandidateKey(cell: slot.cell, role: slot.role, isIrregular: slot.isIrregular, ending: slot.ending),
        CandidateKey(cell: slot.cell, role: slot.role, isIrregular: slot.isIrregular, ending: nil),
        CandidateKey(cell: slot.cell, role: .free, isIrregular: slot.isIrregular, ending: nil),
        CandidateKey(cell: slot.cell, role: slot.role, isIrregular: nil, ending: nil),
        CandidateKey(cell: slot.cell, role: .free, isIrregular: nil, ending: nil)
      ]
      var tried: Set<CandidateKey> = []
      keys.removeAll { !tried.insert($0).inserted }
      for key in keys {
        let pool = candidates(for: key)
        guard !pool.isEmpty else {
          continue
        }
        for attempt in 0..<Self.attempts {
          let verb = pool[Int.random(in: 0..<pool.count, using: &generator)]
          if fits(verb, isIrregular: key.isIrregular, allowingAskedVerb: attempt >= Self.attempts / 2) {
            return QuizQuestion(verb, slot.cell.tense, slot.cell.personNumber)
          }
        }
        if let verb = pool.first(where: { fits($0, isIrregular: key.isIrregular, allowingAskedVerb: true) }) {
          return QuizQuestion(verb, slot.cell.tense, slot.cell.personNumber)
        }
      }
      return nil
    }

    private static let attempts = 24
  }
}
