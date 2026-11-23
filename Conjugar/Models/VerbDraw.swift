//
//  VerbDraw.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Chooses the widget's verb of the day and every random verb (browse plan, Phase 14, ported from
/// Konjugieren). Once My Verbs has entries, it supplies one draw in three: every third day for the
/// widget, and a third of random verbs by chance. The rest come from the 1,000 most frequent verbs,
/// where an irregular verb counts double, and so does a verb that is not a prefixed compound of
/// another verb, so ir counts 4, detener and hablar 2, and recobrar 1.
///
/// "My Verbs" is what the verb list's My Verbs segment shows: the starred verbs, then the last 20
/// opened (`LearnerVerbs.myVerbs`). A random verb opened is a recent verb, so it joins My Verbs and
/// can come back as a My Verbs draw until it ages out of the recents.
nonisolated enum VerbDraw {
  static let myVerbsOdds = 3
  static let frequentBand = FrequencyBand.top1000

  /// Built once, like the verb map it reads, which loads once.
  static let frequentVerbs: [VerbMapEntry] = VerbMap.shared.entries(in: frequentBand)

  /// A verb drawn on demand, for the Random Verb control, the Random Verb shortcut, and the
  /// `verb/random` link.
  static func randomVerb(myVerbs: [VerbMapEntry]) -> VerbMapEntry? {
    var generator = SystemRandomNumberGenerator()
    let goesToMyVerbs = generator.next() % UInt64(myVerbsOdds) == 0
    return draw(goesToMyVerbs: goesToMyVerbs, myVerbs: myVerbs, frequentVerbs: frequentVerbs, using: &generator)
  }

  /// The same verb for the same day number and lists, in any process. My Verbs gets every third
  /// day rather than a chance of one in three, since chance leaves gaps of two weeks, and those
  /// days take its verbs in turn, since chance repeats one while another waits. A day number is
  /// a count of days since a fixed date (`WidgetSnapshotWriter`'s), negative before it.
  static func verbOfTheDay(dayNumber: Int, myVerbs: [VerbMapEntry], frequentVerbs: [VerbMapEntry]) -> VerbMapEntry? {
    if isMyVerbsDay(dayNumber), !myVerbs.isEmpty {
      // Exact, since the day is a multiple of the odds.
      let turn = dayNumber / myVerbsOdds
      return myVerbs[(turn % myVerbs.count + myVerbs.count) % myVerbs.count]
    }
    var generator = SplitMix64(seed: UInt64(bitPattern: Int64(dayNumber)))
    return draw(goesToMyVerbs: false, myVerbs: myVerbs, frequentVerbs: frequentVerbs, using: &generator)
  }

  /// Whether the day goes to My Verbs, when My Verbs has entries.
  static func isMyVerbsDay(_ dayNumber: Int) -> Bool {
    dayNumber.isMultiple(of: myVerbsOdds)
  }

  static func draw(goesToMyVerbs: Bool, myVerbs: [VerbMapEntry], frequentVerbs: [VerbMapEntry], using generator: inout some RandomNumberGenerator) -> VerbMapEntry? {
    if goesToMyVerbs, !myVerbs.isEmpty {
      return myVerbs[Int(generator.next() % UInt64(myVerbs.count))]
    }
    return weightedVerb(from: frequentVerbs, using: &generator) ?? myVerbs.first
  }

  static func weight(of entry: VerbMapEntry) -> UInt64 {
    let irregularWeight: UInt64 = isIrregular(entry) ? 2 : 1
    let compoundWeight: UInt64 = isCompound(entry) ? 1 : 2
    return irregularWeight * compoundWeight
  }

  /// Irregular as the verb page's pill says it: any class but the three regular ones, the
  /// orthographic classes (buscar, llegar) included.
  static func isIrregular(_ entry: VerbMapEntry) -> Bool {
    !regularClassNumbers.contains(entry.classNumber)
  }

  private static let regularClassNumbers: Set<String> = ["1", "2", "3"]

  /// A prefixed compound of another verb of the map, by the Related Verbs card's relation
  /// (`VerbRelations`): detener on tener, reconocer on conocer.
  static func isCompound(_ entry: VerbMapEntry) -> Bool {
    VerbRelations.shared.baseByVerb[entry.infinitive] != nil
  }

  // `Int.random(in:using:)` would serve, but its use of the generator is not documented, so a
  // Swift update could change which verb a day number names.
  private static func weightedVerb(from entries: [VerbMapEntry], using generator: inout some RandomNumberGenerator) -> VerbMapEntry? {
    let total = entries.reduce(0) { $0 + weight(of: $1) }
    guard total > 0 else {
      return nil
    }
    var remaining = generator.next() % total
    for entry in entries {
      let weight = weight(of: entry)
      if remaining < weight {
        return entry
      }
      remaining -= weight
    }
    return entries.last
  }
}
