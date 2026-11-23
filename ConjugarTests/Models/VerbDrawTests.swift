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
    #expect(VerbDraw.isIrregular(try entry("buscar")))
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

  // Every third day goes to My Verbs, taking them in turn, and the other days to the band.
  @Test func myVerbsGetEveryThirdDayInTurn() throws {
    let myVerbs = try ["churruscar", "abolir", "arrepentir"].map(entry)
    let frequent = VerbDraw.frequentVerbs
    let named = (0..<12).map { VerbDraw.verbOfTheDay(dayNumber: $0, myVerbs: myVerbs, frequentVerbs: frequent)?.infinitive }
    #expect(named[0] == "churruscar")
    #expect(named[3] == "abolir")
    #expect(named[6] == "arrepentir")
    #expect(named[9] == "churruscar")
    for day in 0..<12 where !VerbDraw.isMyVerbsDay(day) {
      #expect(named[day] != "churruscar")
      #expect(VerbMap.shared.entry(for: named[day] ?? "")?.isIn(.top1000) == true)
    }
    // Days before the reference date take turns too, without a crash on a negative index.
    #expect(VerbDraw.verbOfTheDay(dayNumber: -3, myVerbs: myVerbs, frequentVerbs: frequent)?.infinitive == "arrepentir")
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
    let calendar = Calendar.current
    let morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 22, hour: 0, minute: 1)))
    let night = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 22, hour: 23, minute: 59)))
    let myVerbs = [try entry("churruscar")]
    #expect(WidgetSnapshotWriter.verbOfTheDay(on: morning, myVerbs: myVerbs) == WidgetSnapshotWriter.verbOfTheDay(on: night, myVerbs: myVerbs))
  }

  // 2026-01-01 is the writer's day zero, a My Verbs day; the next ten days follow the rule.
  @Test func theWidgetsNextTenDaysComeFromTheBandOrMyVerbs() throws {
    let calendar = Calendar.current
    let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12)))
    let myVerbs = try ["churruscar", "abolir"].map(entry)
    let named = try (0..<10).map { offset in
      let date = try #require(calendar.date(byAdding: .day, value: offset, to: start))
      return try #require(WidgetSnapshotWriter.verbOfTheDay(on: date, myVerbs: myVerbs))
    }
    #expect(named[0].infinitive == "churruscar")
    #expect(named[3].infinitive == "abolir")
    #expect(named[6].infinitive == "churruscar")
    #expect(named[9].infinitive == "abolir")
    for offset in 0..<10 where !offset.isMultiple(of: 3) {
      #expect(named[offset].isIn(.top1000))
    }
  }

  @Test func theSnapshotShowsTheDrawnVerb() throws {
    let calendar = Calendar.current
    let myVerbsDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 4, hour: 9)))
    let snapshot = try #require(WidgetSnapshotWriter.makeSnapshot(for: myVerbsDay, myVerbs: [try entry("arrepentir")]))
    // A reflexive-only verb shows with its pronoun, and its rank may lie outside the band.
    #expect(snapshot.infinitive == "arrepentirse")
    #expect(snapshot.dateString == "2026-01-04")
  }
}
