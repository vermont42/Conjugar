//
//  VerbDraw.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Chooses the widget's verb of the day and every random verb. Once My Verbs has entries, it
/// supplies one draw in three: every third day for the widget, and a third of random verbs by
/// chance. The rest come from the 1,000 most frequent verbs, where an irregular verb counts
/// double, and so does a verb that is not a prefixed compound of another verb, so ir counts 4,
/// detener and hablar 2, and recobrar 1.
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

  /// The same verb for the same day number, lists, and record of turns, in any process. My Verbs
  /// gets every third day rather than a chance of one in three, since chance leaves gaps of two
  /// weeks, and those days take its verbs in turn (`myVerbsTurn`), since chance repeats one while
  /// another waits. A day number is a count of days since a fixed date (`WidgetSnapshotWriter`'s),
  /// negative before it. `lastShown` gives the day number on which each verb last had its turn.
  static func verbOfTheDay(dayNumber: Int, myVerbs: [VerbMapEntry], lastShown: [String: Int] = [:], frequentVerbs: [VerbMapEntry]) -> VerbMapEntry? {
    if isMyVerbsDay(dayNumber), let turn = myVerbsTurn(in: myVerbs, lastShown: lastShown) {
      return turn
    }
    var generator = SplitMix64(seed: UInt64(bitPattern: Int64(dayNumber)))
    return draw(goesToMyVerbs: false, myVerbs: myVerbs, frequentVerbs: frequentVerbs, using: &generator)
  }

  /// The verb of My Verbs whose turn it is: one that has never had a turn, or else the one whose
  /// last turn is oldest, and among equals the first by infinitive. Opening a verb reorders My
  /// Verbs and adds to it, so a turn taken by position would bring one verb back while another
  /// waited; this one is the same whatever the list's order, and a verb new to the list goes
  /// before any that has had a turn. Nil when My Verbs is empty.
  static func myVerbsTurn(in myVerbs: [VerbMapEntry], lastShown: [String: Int]) -> VerbMapEntry? {
    myVerbs.min { first, second in
      let firstShown = lastShown[first.infinitive] ?? Int.min
      let secondShown = lastShown[second.infinitive] ?? Int.min
      return firstShown == secondShown ? first.infinitive < second.infinitive : firstShown < secondShown
    }
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
    let irregularWeight: UInt64 = entry.isIrregular ? 2 : 1
    let compoundWeight: UInt64 = entry.isCompound ? 1 : 2
    return irregularWeight * compoundWeight
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
