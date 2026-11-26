//
//  MasteryTests.swift
//  ConjugarTests
//
//  The Mastery page's model: an item's state by its box, each level's patterns and persons, the
//  core irregular verbs and the key conjugations each level asks of them, and the counts following
//  a seeded record. MainActor because `Region` and `Mastery` are.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct MasteryTests {
  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return calendar
  }()

  private func date(_ day: Int) -> Date {
    Self.calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: 12)) ?? .distantPast
  }

  private func mastery(
    _ level: QuizLevel,
    _ record: PracticeRecord = PracticeRecord(),
    secondSingular: DisplayPersonNumber = .secondSingularTú,
    region: Region = .latinAmerica
  ) -> Mastery {
    Mastery(level: level, record: record, secondSingular: secondSingular, region: region)
  }

  /// Right on the first day, then right again once due, which reaches the third box.
  private func bringToMastery(_ item: PracticeItem, in record: inout PracticeRecord) {
    record.recordAnswer(item, isCorrect: true, at: date(1), calendar: Self.calendar)
    record.recordAnswer(item, isCorrect: true, at: date(4), calendar: Self.calendar)
  }

  private func pattern(_ tense: DisplayTense, _ personNumber: DisplayPersonNumber, _ ending: RegularRoot) -> PracticeItem {
    PracticeItem.pattern(of: ConjugationCell(tense: tense, personNumber: personNumber), ending: ending)!
  }

  private func state(of tense: DisplayTense, _ personNumber: DisplayPersonNumber, _ ending: RegularRoot, in mastery: Mastery) -> MasteryState? {
    guard
      let table = mastery.patterns.first(where: { $0.tense == tense }),
      let column = table.personNumbers.firstIndex(of: personNumber),
      let row = table.rows.first(where: { $0.ending == ending })
    else {
      return nil
    }
    return row.states[column]
  }

  @Test func theStateFollowsTheBox() {
    let item = pattern(.presenteDeIndicativo, .firstSingular, .ar)
    var record = PracticeRecord()
    #expect(record.masteryState(of: item) == .notPracticed)

    record.recordAnswer(item, isCorrect: true, at: date(1), calendar: Self.calendar)
    #expect(record.entry(for: item)?.schedule.box == 1)
    #expect(record.masteryState(of: item) == .learning)

    record.recordAnswer(item, isCorrect: true, at: date(4), calendar: Self.calendar)
    #expect(record.entry(for: item)?.schedule.box == MasteryState.masteredBox)
    #expect(record.masteryState(of: item) == .mastered)

    record.recordAnswer(item, isCorrect: false, at: date(5), calendar: Self.calendar)
    #expect(record.masteryState(of: item) == .learning)
  }

  @Test func aLookupIsLearning() {
    let item = PracticeItem.keyConjugation(infinitive: "tener", key: .yoPresente)
    var record = PracticeRecord()
    record.recordLookup([item], at: date(1), calendar: Self.calendar)
    #expect(record.masteryState(of: item) == .learning)
  }

  @Test(arguments: [
    (QuizLevel.beginner, Region.latinAmerica, 24),
    (.elementary, .latinAmerica, 87),
    (.intermediate, .latinAmerica, 162),
    (.advanced, .latinAmerica, 297),
    (.beginner, .spain, 27),
    (.elementary, .spain, 102),
    (.intermediate, .spain, 195),
    (.advanced, .spain, 357)
  ])
  func eachLevelHasItsPatterns(level: QuizLevel, region: Region, count: Int) {
    let mastery = mastery(level, region: region)
    #expect(mastery.patternCount == count)
    #expect(mastery.patterns.map(\.tense) == level.pool.map(\.tense))
    #expect(mastery.patterns.allSatisfy { $0.rows.map(\.ending) == [.ar, .er, .ir] })
  }

  @Test func theColumnsAreTheSettingsPersons() {
    let beginner = mastery(.beginner)
    #expect(beginner.patterns.first { $0.tense == .presenteDeIndicativo }?.personNumbers == [.firstSingular, .secondSingularTú, .thirdSingular, .firstPlural, .thirdPlural])
    #expect(beginner.patterns.first { $0.tense == .imperativoPositivo }?.personNumbers == [.secondSingularTú, .thirdSingular, .thirdPlural])

    let vosInSpain = mastery(.intermediate, secondSingular: .secondSingularVos, region: .spain)
    #expect(vosInSpain.patterns.first { $0.tense == .imperativoPositivo }?.personNumbers == [.secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural])
    #expect(vosInSpain.patterns.first { $0.tense == .gerundio }?.personNumbers == [DisplayPersonNumber.none])
  }

  @Test func theCoreVerbsAreTheFiftyMostFrequentIrregularVerbs() {
    #expect(Mastery.coreVerbs.count == Mastery.coreVerbCount)
    #expect(Array(Mastery.coreVerbs.prefix(5)) == ["ser", "estar", "tener", "ir", "hacer"])
    // Spelling changes and prefixed compounds count, as the verb page's pill counts them.
    #expect(Mastery.coreVerbs.contains("llegar"))
    #expect(Mastery.coreVerbs.contains("mantener"))
    #expect(!Mastery.coreVerbs.contains("hablar"))
    let ranks = Mastery.coreVerbs.compactMap { VerbMap.shared.entry(for: $0)?.frequencyRank }
    #expect(ranks == ranks.sorted())
    #expect(Mastery.coreVerbs.allSatisfy { VerbMap.shared.entry(for: $0)?.isIrregular == true })
  }

  @Test func aVerbRegularThroughoutTheLevelIsLeftOut() {
    let beginner = mastery(.beginner).verbs.map(\.infinitive)
    for verb in ["creer", "abrir", "escribir", "leer"] {
      #expect(!beginner.contains(verb), "\(verb)")
    }
    #expect(beginner.count == 46)
    #expect(mastery(.elementary).verbCount == 50)
  }

  @Test func eachLevelAsksItsKeyConjugations() {
    func keys(_ verb: String, _ level: QuizLevel) -> [PracticeItem.Key]? {
      mastery(level).verbs.first { $0.infinitive == verb }?.keyConjugations.map(\.key)
    }
    #expect(keys("tener", .beginner) == [.yoPresente])
    // tenido is regular, so no answer moves it.
    #expect(keys("tener", .elementary) == [.yoPresente, .yoPretérito, .yoFuturo])
    #expect(keys("hacer", .elementary) == [.yoPresente, .yoPretérito, .yoFuturo, .participio])
    // pedí is regular, but pidió, built on it, is not.
    #expect(keys("pedir", .elementary) == [.yoPresente, .yoPretérito])
    // llegue, usted's command, is a spelling change built on llego.
    #expect(keys("llegar", .beginner) == [.yoPresente])
    #expect(keys("llegar", .advanced) == [.yoPresente, .yoPretérito])
    #expect(keys("escribir", .elementary) == [.participio])
  }

  @Test func theDisplayFollowsTheRecord() {
    var record = PracticeRecord()
    bringToMastery(pattern(.presenteDeIndicativo, .firstSingular, .ar), in: &record)
    bringToMastery(pattern(.presenteDeIndicativo, .thirdPlural, .ir), in: &record)
    record.recordAnswer(pattern(.imperativoPositivo, .thirdSingular, .er), isCorrect: true, at: date(1), calendar: Self.calendar)
    bringToMastery(.keyConjugation(infinitive: "ser", key: .yoPresente), in: &record)
    bringToMastery(.keyConjugation(infinitive: "tener", key: .yoPresente), in: &record)
    record.recordAnswer(.keyConjugation(infinitive: "tener", key: .yoPretérito), isCorrect: true, at: date(1), calendar: Self.calendar)

    let beginner = mastery(.beginner, record)
    #expect(state(of: .presenteDeIndicativo, .firstSingular, .ar, in: beginner) == .mastered)
    #expect(state(of: .presenteDeIndicativo, .thirdPlural, .ir, in: beginner) == .mastered)
    #expect(state(of: .presenteDeIndicativo, .firstSingular, .er, in: beginner) == .notPracticed)
    #expect(state(of: .imperativoPositivo, .thirdSingular, .er, in: beginner) == .learning)
    #expect(beginner.masteredPatternCount == 2)
    // At Beginner, ser and tener are asked only their yo presente.
    #expect(beginner.masteredVerbCount == 2)

    // Elementary asks their pretérito too, which neither has mastered.
    let elementary = mastery(.elementary, record)
    #expect(elementary.masteredPatternCount == 2)
    #expect(elementary.masteredVerbCount == 0)
    let tener = elementary.verbs.first { $0.infinitive == "tener" }?.keyConjugations.map(\.state)
    #expect(tener == [.mastered, .learning, .notPracticed])
  }

  @Test func aPatternBeyondTheSettingsIsNotCounted() {
    var record = PracticeRecord()
    bringToMastery(pattern(.presenteDeIndicativo, .secondPlural, .ar), in: &record)
    #expect(mastery(.beginner, record, region: .latinAmerica).masteredPatternCount == 0)
    #expect(mastery(.beginner, record, region: .spain).masteredPatternCount == 1)
  }

  @Test func answersLandWhereTheMappingSendsThem() {
    var record = PracticeRecord()
    for (verb, tense, personNumber) in [
      ("hablar", DisplayTense.imperfectoDeIndicativo, DisplayPersonNumber.firstSingular),
      ("tener", .imperfectoDeIndicativo, .firstPlural),
      ("tener", .pretérito, .thirdSingular),
      ("hacer", .perfectoDeIndicativo, .firstSingular),
      ("vivir", .gerundio, DisplayPersonNumber.none)
    ] {
      let item = PracticeItem.exercised(by: verb, tense: tense, personNumber: personNumber)
      #expect(item != nil)
      item.map { record.recordAnswer($0, isCorrect: true, at: date(1), calendar: Self.calendar) }
    }

    let elementary = mastery(.elementary, record)
    #expect(state(of: .imperfectoDeIndicativo, .firstSingular, .ar, in: elementary) == .learning)
    // tener's imperfecto (teníamos) is regular, so it moves the -er pattern.
    #expect(state(of: .imperfectoDeIndicativo, .firstPlural, .er, in: elementary) == .learning)
    #expect(state(of: .gerundio, .none, .ir, in: elementary) == .learning)
    let keys = Dictionary(uniqueKeysWithValues: elementary.verbs.map { ($0.infinitive, $0.keyConjugations) })
    #expect(keys["tener"]?.first { $0.key == .yoPretérito }?.state == .learning)
    #expect(keys["hacer"]?.first { $0.key == .participio }?.state == .learning)
  }
}
