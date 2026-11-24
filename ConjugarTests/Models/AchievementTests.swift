//
//  AchievementTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The Game Center achievements: their permanent IDs and points, what each counts in the practice
//  record, and what reaches Game Center. MainActor because `Mastery` and `Region` are.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct AchievementTests {
  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return calendar
  }()

  private static func daysAgo(_ days: Double) -> Date {
    Date.now.addingTimeInterval(-days * 86_400)
  }

  /// Right twelve days ago, then right again once due, which reaches the third box.
  private static func bringToMastery(_ item: PracticeItem, in record: inout PracticeRecord) {
    record.recordAnswer(item, isCorrect: true, at: daysAgo(12), calendar: calendar)
    record.recordAnswer(item, isCorrect: true, at: daysAgo(8), calendar: calendar)
  }

  private static func mastery(_ level: QuizLevel, region: Region = .latinAmerica) -> Mastery {
    Mastery(level: level, record: PracticeRecord(), secondSingular: .secondSingularTú, region: region)
  }

  /// Every pattern the level asks in the region, with tú.
  private static func patterns(at level: QuizLevel, region: Region = .latinAmerica) -> [PracticeItem] {
    mastery(level, region: region).patterns.flatMap { table in
      table.personNumbers.flatMap { personNumber in
        Mastery.endings.compactMap { ending in
          PracticeItem.pattern(of: ConjugationCell(tense: table.tense, personNumber: personNumber), ending: ending)
        }
      }
    }
  }

  /// Every key conjugation that Advanced asks of the verb.
  private static func keys(of infinitive: String) -> [PracticeItem] {
    let row = mastery(.advanced).verbs.first { $0.infinitive == infinitive }
    return (row?.keyConjugations ?? []).map { .keyConjugation(infinitive: infinitive, key: $0.key) }
  }

  private static func record(mastering items: [PracticeItem]) -> PracticeRecord {
    var record = PracticeRecord()
    for item in items {
      bringToMastery(item, in: &record)
    }
    return record
  }

  private static func progress(_ record: PracticeRecord, region: Region = .latinAmerica) -> [Achievement: Achievement.Progress] {
    Achievement.progress(in: record, secondSingular: .secondSingularTú, region: region)
  }

  /// App Store Connect never lets an ID change, so each is pinned as it is to be created there.
  @Test(arguments: [
    (Achievement.patternsBeginner, "conjugar.achievement.patterns.beginner"),
    (.patternsElementary, "conjugar.achievement.patterns.elementary"),
    (.patternsIntermediate, "conjugar.achievement.patterns.intermediate"),
    (.patternsAdvanced, "conjugar.achievement.patterns.advanced"),
    (.pillars, "conjugar.achievement.verbs.pillars"),
    (.coreTen, "conjugar.achievement.verbs.core10"),
    (.coreTwentyFive, "conjugar.achievement.verbs.core25"),
    (.coreFifty, "conjugar.achievement.verbs.core50")
  ])
  func eachIDIsPinned(achievement: Achievement, identifier: String) {
    #expect(achievement.identifier == identifier)
  }

  @Test func theIDsAreDistinctAndThePointsWithinApplesLimits() {
    #expect(Set(Achievement.allCases.map(\.identifier)).count == Achievement.allCases.count)
    #expect(Achievement.allCases.allSatisfy { (1...100).contains($0.points) })
    #expect(Achievement.allCases.reduce(0) { $0 + $1.points } == 385)
  }

  @Test func theVerbsAreTheMostFrequentIrregularOnes() {
    #expect(Achievement.pillars.verbs.allSatisfy(Mastery.coreVerbs.contains))
    #expect(Achievement.coreTen.verbs == ["ser", "estar", "tener", "ir", "hacer", "poder", "decir", "haber", "dar", "ver"])
    #expect(Achievement.coreTwentyFive.verbs == Array(Mastery.coreVerbs.prefix(25)))
    #expect(Achievement.coreFifty.verbs == Mastery.coreVerbs)
    // A verb with no key conjugation at Advanced could never be earned.
    let advanced = Set(Self.mastery(.advanced).verbs.map(\.infinitive))
    #expect(Mastery.coreVerbs.allSatisfy(advanced.contains))
  }

  @Test func anEmptyRecordHasEarnedNothing() {
    let progress = Self.progress(PracticeRecord())
    #expect(progress.count == Achievement.allCases.count)
    #expect(progress.values.allSatisfy { $0.mastered == 0 && !$0.isComplete && $0.percentComplete == 0 })
    #expect(progress[.patternsBeginner]?.required == 24)
    #expect(progress[.patternsAdvanced]?.required == 297)
    #expect(progress[.pillars]?.required == 6)
    #expect(progress[.coreFifty]?.required == 50)
    #expect(Self.progress(PracticeRecord(), region: .spain)[.patternsBeginner]?.required == 27)
  }

  /// A level's patterns are the level below's and more, so earning one earns those below.
  @Test(arguments: QuizLevel.allCases)
  func aLevelsPatternsEarnItAndTheLevelsBelow(level: QuizLevel) {
    let progress = Self.progress(Self.record(mastering: Self.patterns(at: level)))
    for achievement in Achievement.allCases {
      guard let patternLevel = achievement.patternLevel else {
        #expect(progress[achievement]?.mastered == 0)
        continue
      }
      let isAtOrBelow = QuizLevel.allCases.firstIndex(of: patternLevel)! <= QuizLevel.allCases.firstIndex(of: level)!
      #expect(progress[achievement]?.isComplete == isAtOrBelow, "\(achievement) after \(level)")
    }
  }

  @Test func onePatternShortIsNotEarned() {
    let progress = Self.progress(Self.record(mastering: Array(Self.patterns(at: .beginner).dropLast())))
    #expect(progress[.patternsBeginner] == Achievement.Progress(mastered: 23, required: 24))
    #expect(progress[.patternsBeginner]?.isComplete == false)
    #expect(abs((progress[.patternsBeginner]?.percentComplete ?? 0) - 2_300.0 / 24) < 0.001)
  }

  @Test func learningCountsForNothing() {
    var record = PracticeRecord()
    for item in Self.patterns(at: .beginner) + Self.keys(of: "ser") {
      record.recordAnswer(item, isCorrect: true, at: Self.daysAgo(1), calendar: Self.calendar)
    }
    #expect(Self.progress(record).values.allSatisfy { $0.mastered == 0 })
  }

  /// tener asks tengo, tuve, and tendré at Advanced, so two of them earn nothing, whatever level
  /// is chosen.
  @Test func aVerbNeedsEveryKeyConjugationAdvancedAsks() {
    let keys = Self.keys(of: "tener")
    #expect(keys == [PracticeItem.Key.yoPresente, .yoPretérito, .yoFuturo].map { .keyConjugation(infinitive: "tener", key: $0) })

    #expect(Self.progress(Self.record(mastering: Array(keys.prefix(2))))[.pillars]?.mastered == 0)
    let progress = Self.progress(Self.record(mastering: keys))
    #expect(progress[.pillars]?.mastered == 1)
    #expect(progress[.coreTen]?.mastered == 1)
    #expect(progress[.coreFifty]?.mastered == 1)
  }

  @Test func eachStepOfTheCoreVerbs() {
    let ten = Self.progress(Self.record(mastering: Achievement.coreTen.verbs.flatMap(Self.keys)))
    #expect(ten[.pillars]?.isComplete == true)
    #expect(ten[.coreTen]?.isComplete == true)
    #expect(ten[.coreTwentyFive] == Achievement.Progress(mastered: 10, required: 25))
    #expect(ten[.coreFifty] == Achievement.Progress(mastered: 10, required: 50))

    // Any ten of the fifty do not make the ten most frequent.
    let laterTen = Self.progress(Self.record(mastering: Mastery.coreVerbs.suffix(10).flatMap(Self.keys)))
    #expect(laterTen[.coreTen]?.mastered == 0)
    #expect(laterTen[.coreFifty]?.mastered == 10)

    let all = Self.progress(Self.record(mastering: Mastery.coreVerbs.flatMap(Self.keys)))
    #expect([Achievement.pillars, .coreTen, .coreTwentyFive, .coreFifty].allSatisfy { all[$0]?.isComplete == true })
    #expect(all[.patternsBeginner]?.mastered == 0)
  }

  @Test func aVosotrosPatternCountsOnlyInSpain() {
    let vosotros = PracticeItem.pattern(of: ConjugationCell(tense: .presenteDeIndicativo, personNumber: .secondPlural), ending: .ar)!
    let record = Self.record(mastering: [vosotros])
    #expect(Self.progress(record)[.patternsBeginner]?.mastered == 0)
    #expect(Self.progress(record, region: .spain)[.patternsBeginner]?.mastered == 1)
  }

  @Test func nothingIsReportedWhileSignedOut() {
    let settings = Settings(getterSetter: GetterSetterFake())
    let record = Self.record(mastering: Self.patterns(at: .beginner))

    let signedOut = GameCenterSpy(isAuthenticated: false)
    signedOut.reportAchievements(record: record, settings: settings)
    #expect(signedOut.achievementReports.isEmpty)

    let signedIn = GameCenterSpy()
    signedIn.reportAchievements(record: record, settings: settings)
    #expect(signedIn.achievementReports.count == 1)
    #expect(signedIn.achievementReports.first?.keys.count == Achievement.allCases.count)
  }
}
