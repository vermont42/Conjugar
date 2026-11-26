//
//  VerbDrawTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

/// The draw behind the widget's verb of the day and every random verb: the 1,000 most frequent
/// verbs, weighted toward irregular and unprefixed verbs, with My Verbs given one draw in three. Nonisolated: it touches only the engine and the verb map.
struct VerbDrawTests {
  private func entry(_ infinitive: String) throws -> VerbMapEntry {
    try #require(VerbMap.shared.entry(for: infinitive))
  }

  @Test func frequentVerbsAreTheTopThousandMostFrequentFirst() {
    let verbs = VerbDraw.frequentVerbs
    #expect(verbs.count == 1000)
    #expect(verbs.map(\.frequencyRank) == Array(1...1000))
  }

  @Test func weightsDoubleForIrregularAndForUnprefixed() throws {
    #expect(VerbDraw.weight(of: try entry("ir")) == 4)
    #expect(VerbDraw.weight(of: try entry("tener")) == 4)
    // Irregular, but built on tener.
    #expect(VerbDraw.weight(of: try entry("detener")) == 2)
    // Regular, with no base.
    #expect(VerbDraw.weight(of: try entry("hablar")) == 2)
    // Regular, and built on cobrar.
    #expect(VerbDraw.weight(of: try entry("recobrar")) == 1)
    // An orthographic class counts as irregular, as the verb page's pill says.
    #expect(try entry("buscar").isIrregular)
  }

  @Test func theSameDayNamesTheSameVerb() throws {
    let myVerbs = [try entry("churruscar")]
    for day in -10...30 {
      let first = VerbDraw.verbOfTheDay(dayNumber: day, myVerbs: myVerbs, frequentVerbs: VerbDraw.frequentVerbs)
      let second = VerbDraw.verbOfTheDay(dayNumber: day, myVerbs: myVerbs, frequentVerbs: VerbDraw.frequentVerbs)
      #expect(first != nil)
      #expect(first == second)
    }
  }

  @Test func withoutMyVerbsEveryDayDrawsFromTheBand() {
    let frequent = VerbDraw.frequentVerbs
    for day in 0..<300 {
      let verb = VerbDraw.verbOfTheDay(dayNumber: day, myVerbs: [], frequentVerbs: frequent)
      #expect(verb?.isIn(.top1000) == true)
    }
  }

  /// The My Verbs verbs of consecutive My Verbs days, each counted as having had its turn for the
  /// days after it. `list(turn)` gives My Verbs on the turn's day, so that it can change between
  /// days.
  private func turns(_ count: Int, list: (Int) throws -> [VerbMapEntry]) rethrows -> [(verb: String, list: [VerbMapEntry], lastShown: [String: Int])] {
    var lastShown: [String: Int] = [:]
    var result: [(verb: String, list: [VerbMapEntry], lastShown: [String: Int])] = []
    for turn in 0..<count {
      let day = turn * VerbDraw.myVerbsOdds
      let myVerbs = try list(turn)
      let verb = VerbDraw.verbOfTheDay(dayNumber: day, myVerbs: myVerbs, lastShown: lastShown, frequentVerbs: VerbDraw.frequentVerbs)?.infinitive ?? ""
      result.append((verb, myVerbs, lastShown))
      lastShown[verb] = day
    }
    return result
  }

  /// No verb has a turn while another of the list has waited longer, or has never had one.
  private func noVerbRepeatsWhileAnotherWaits(_ turns: [(verb: String, list: [VerbMapEntry], lastShown: [String: Int])]) {
    for (index, turn) in turns.enumerated() {
      let chosen = turn.lastShown[turn.verb] ?? Int.min
      for other in turn.list where other.infinitive != turn.verb {
        let waited = turn.lastShown[other.infinitive] ?? Int.min
        #expect(waited >= chosen, "turn \(index): \(turn.verb) came back while \(other.infinitive) waited")
      }
    }
  }

  // Every third day goes to My Verbs, taking them in turn, and the other days to the band.
  @Test func myVerbsGetEveryThirdDayInTurn() throws {
    let myVerbs = try ["churruscar", "abolir", "arrepentir"].map(entry)
    let frequent = VerbDraw.frequentVerbs
    let named = turns(4) { _ in myVerbs }.map(\.verb)
    // In the order of the infinitives, since none has had a turn.
    #expect(named == ["abolir", "arrepentir", "churruscar", "abolir"])
    for day in 0..<12 where !VerbDraw.isMyVerbsDay(day) {
      let verb = VerbDraw.verbOfTheDay(dayNumber: day, myVerbs: myVerbs, frequentVerbs: frequent)
      #expect(verb.map { myVerbs.contains($0) } == false)
      #expect(verb?.isIn(.top1000) == true)
    }
    // Days before the reference date take turns too.
    #expect(VerbDraw.verbOfTheDay(dayNumber: -3, myVerbs: myVerbs, lastShown: ["abolir": -6], frequentVerbs: frequent)?.infinitive == "arrepentir")
  }

  // The review found the same verb on 56 of 60 My Verbs days when one verb was opened between
  // them, because a new verb went to the front of the list and the turn moved down it by one.
  @Test func aVerbOpenedBetweenMyVerbsDaysDoesNotBringOneBack() {
    let frequent = VerbDraw.frequentVerbs
    let result = turns(60) { turn in
      // Twenty recents, the newest first, and one more opened before each day.
      Array(frequent[turn..<(turn + LearnerVerbs.recentLimit)].reversed())
    }
    noVerbRepeatsWhileAnotherWaits(result)
    // With twenty verbs in the list, none comes back within twenty turns.
    for start in 0...(result.count - LearnerVerbs.recentLimit) {
      #expect(Set(result[start..<(start + LearnerVerbs.recentLimit)].map(\.verb)).count == LearnerVerbs.recentLimit)
    }
  }

  // A verb that joins the list goes before any that has had a turn, wherever it sorts.
  @Test func aVerbThatJoinsTheListTakesTheNextTurn() throws {
    let start = try ["beber", "comer", "hablar", "vivir"].map(entry)
    let joined = try entry("abrir")
    let result = turns(8) { turn in turn < 2 ? start : [joined] + start }
    #expect(result.map(\.verb) == ["beber", "comer", "abrir", "hablar", "vivir", "beber", "comer", "abrir"])
    noVerbRepeatsWhileAnotherWaits(result)
  }

  // Opening a verb reorders My Verbs; the turns do not follow the order.
  @Test func aReorderedListKeepsItsTurns() throws {
    let myVerbs = try ["beber", "comer", "hablar", "vivir"].map(entry)
    let result = turns(12) { turn in
      turn.isMultiple(of: 2) ? myVerbs.reversed() : [myVerbs[turn % 4]] + myVerbs.filter { $0 != myVerbs[turn % 4] }
    }
    noVerbRepeatsWhileAnotherWaits(result)
    #expect(Array(result.map(\.verb).prefix(4)) == ["beber", "comer", "hablar", "vivir"])
    #expect(Array(result.map(\.verb).suffix(8)) == Array(result.map(\.verb).prefix(8)))
  }

  // A verb missing from one day's list keeps its place for the next.
  @Test func aVerbMissingForADayKeepsItsPlace() throws {
    let myVerbs = try ["beber", "comer", "hablar"].map(entry)
    let result = turns(5) { turn in turn == 1 ? myVerbs.filter { $0.infinitive != "comer" } : myVerbs }
    #expect(result.map(\.verb) == ["beber", "hablar", "comer", "beber", "hablar"])
    noVerbRepeatsWhileAnotherWaits(result)
  }

  @Test func theWeightsShowInTheDraws() {
    let frequent = VerbDraw.frequentVerbs
    let heavyShareOfBand = Double(frequent.filter { VerbDraw.weight(of: $0) == 4 }.count) / Double(frequent.count)
    let draws = (0..<1500).compactMap { VerbDraw.verbOfTheDay(dayNumber: $0, myVerbs: [], frequentVerbs: frequent) }
    let heavyShareOfDraws = Double(draws.filter { VerbDraw.weight(of: $0) == 4 }.count) / Double(draws.count)
    #expect(heavyShareOfDraws > heavyShareOfBand + 0.1)
  }

  @Test func aRandomVerbGoesToMyVerbsAboutOneTimeInThree() throws {
    let rare = try entry("churruscar")
    #expect(!rare.isIn(.top1000))
    let draws = (0..<900).compactMap { _ in VerbDraw.randomVerb(myVerbs: [rare]) }
    #expect(draws.count == 900)
    let mine = draws.filter { $0 == rare }.count
    // One in three is 300; the bounds are more than four standard deviations wide.
    #expect((240...360).contains(mine))
    #expect(draws.allSatisfy { $0 == rare || $0.isIn(.top1000) })
  }

  @Test func aRandomVerbWithoutMyVerbsComesFromTheBand() {
    for _ in 0..<200 {
      #expect(VerbDraw.randomVerb(myVerbs: [])?.isIn(.top1000) == true)
    }
  }

  @Test func aDrawFallsBackToMyVerbsWhenTheBandIsEmpty() throws {
    let rare = try entry("churruscar")
    var generator = SplitMix64(seed: 1)
    #expect(VerbDraw.draw(goesToMyVerbs: false, myVerbs: [rare], frequentVerbs: [], using: &generator) == rare)
    #expect(VerbDraw.draw(goesToMyVerbs: false, myVerbs: [], frequentVerbs: [], using: &generator) == nil)
  }

  // A day number seeds `SplitMix64`, so a change to its sequence would change every day's verb.
  @Test func theSeededGeneratorKeepsItsSequence() {
    var generator = SplitMix64(seed: 0)
    #expect(generator.next() == 0xE220_A839_7B1D_CDAF)
    #expect(generator.next() == 0x6E78_9E6A_A1B9_65F4)
  }

  // The widget's verb is a function of the day, so any time of the day names it.
  @Test func theWidgetsVerbHoldsThroughTheDay() throws {
    let calendar = CalendarDay.calendar
    let morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 22, hour: 0, minute: 1)))
    let night = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 22, hour: 23, minute: 59)))
    let myVerbs = [try entry("churruscar")]
    #expect(WidgetSnapshotWriter.verbOfTheDay(on: morning, myVerbs: myVerbs) == WidgetSnapshotWriter.verbOfTheDay(on: night, myVerbs: myVerbs))
  }

  // 2026-01-01 is the writer's day zero, a My Verbs day; the next ten days follow the rule.
  @Test func theWidgetsNextTenDaysComeFromTheBandOrMyVerbs() throws {
    let calendar = CalendarDay.calendar
    let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12)))
    let myVerbs = try ["churruscar", "abolir"].map(entry)
    var lastShown: [String: Int] = [:]
    let named = try (0..<10).map { offset in
      let date = try #require(calendar.date(byAdding: .day, value: offset, to: start))
      let verb = try #require(WidgetSnapshotWriter.verbOfTheDay(on: date, myVerbs: myVerbs, lastShown: lastShown))
      if offset.isMultiple(of: 3) {
        lastShown[verb.infinitive] = offset
      }
      return verb
    }
    #expect(named[0].infinitive == "abolir")
    #expect(named[3].infinitive == "churruscar")
    #expect(named[6].infinitive == "abolir")
    #expect(named[9].infinitive == "churruscar")
    for offset in 0..<10 where !offset.isMultiple(of: 3) {
      #expect(named[offset].isIn(.top1000))
    }
  }

  @Test func theSnapshotShowsTheDrawnVerb() throws {
    let calendar = CalendarDay.calendar
    let myVerbsDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 4, hour: 9)))
    let week = try #require(WidgetSnapshotWriter.makeWeek(for: myVerbsDay, myVerbs: [try entry("arrepentir")]))
    // A reflexive-only verb shows with its pronoun, and its rank may lie outside the band.
    #expect(week.firstDay.infinitive == "arrepentirse")
    #expect(week.firstDay.dateString == "2026-01-04")
  }
}
