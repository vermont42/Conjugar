//
//  DailyChallenge.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Synchronization
import UIKit

/// The daily challenge: five questions a day for each level and region, the same on every device
/// on the same date, taken once and shared as a short text.
nonisolated enum DailyChallenge {
  static let questionCount = 5

  /// Draws repeat until no verb is asked twice, since in five questions a second ser would be a
  /// fifth of the challenge. The limit keeps a band that cannot comply from looping forever.
  static let distinctVerbAttempts = 20

  static let maximumScore = questionCount * ConjugationResult.totalMatch.rawValue

  /// A day's challenge at a level in a region. The day is the learner's own calendar day, as
  /// `yyyy-MM-dd`, so that two learners in different time zones share a challenge by date, not by
  /// instant. The region is part of the key because Spain's quiz asks vosotros and Latin
  /// America's never does.
  struct Key: Codable, Hashable, Sendable {
    let day: String
    let levelKey: String
    let regionKey: String

    var level: QuizLevel {
      QuizLevel(rawValue: levelKey) ?? .initial
    }

    var region: Region {
      Region(linkKey: regionKey) ?? .latinAmerica
    }

    init(day: String, level: QuizLevel, region: Region) {
      self.day = day
      levelKey = level.rawValue
      regionKey = region.linkKey
    }

    init(date: Date, level: QuizLevel, region: Region) {
      self.init(day: DailyChallenge.dayString(for: date), level: level, region: region)
    }

    /// The challenge a shared link names, or nil for a day that is not a date.
    init?(dayString: String, level: QuizLevel, region: Region) {
      guard DailyChallenge.date(fromDayString: dayString) != nil else {
        return nil
      }
      self.init(day: dayString, level: level, region: region)
    }

    /// The text the seed is made from. Changing it changes every challenge on every device.
    var seedText: String {
      "challenge-\(day)-\(levelKey)-\(regionKey)"
    }

    /// FNV-1a, which is the same in every process, unlike Swift's `Hasher`.
    var seed: UInt64 {
      DailyChallenge.stableSeed(for: seedText)
    }

    /// Noon of the day, which no time-zone change moves to another date.
    var date: Date {
      DailyChallenge.date(fromDayString: day) ?? .now
    }
  }

  /// How one question of a challenge went, in the colors of the results' marks.
  enum Outcome: String, Codable, Sendable {
    case right
    case secondTry
    case wrong

    init(_ result: ConjugationResult) {
      switch result {
      case .totalMatch:
        self = .right
      case .secondAttemptMatch:
        self = .secondTry
      case .noMatch:
        self = .wrong
      }
    }

    /// The shared text's dot. The app draws circles instead, since the iOS 26 simulator draws
    /// these emoji as empty boxes.
    var dot: String {
      switch self {
      case .right:
        return "🟢"
      case .secondTry:
        return "🟡"
      case .wrong:
        return "🔴"
      }
    }

    var points: Int {
      switch self {
      case .right:
        return ConjugationResult.totalMatch.rawValue
      case .secondTry:
        return ConjugationResult.secondAttemptMatch.rawValue
      case .wrong:
        return 0
      }
    }
  }

  /// The Gregorian calendar in the learner's time zone (`CalendarDay`), so that a learner whose
  /// calendar is another still names the day as a link does.
  static var calendar: Calendar {
    CalendarDay.calendar
  }

  static func dayString(for date: Date) -> String {
    CalendarDay.string(for: date)
  }

  /// Noon of a `yyyy-MM-dd` day, or nil for text that names no day.
  static func date(fromDayString day: String) -> Date? {
    CalendarDay.noon(of: day)
  }

  /// 64-bit FNV-1a.
  static func stableSeed(for text: String) -> UInt64 {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    for byte in text.utf8 {
      hash ^= UInt64(byte)
      hash = hash &* 0x0000_0100_0000_01b3
    }
    return hash
  }

  private static let cache = Mutex<[Key: [QuizQuestion]]>([:])

  /// The challenge's five questions, as drawn in tú.
  static func questions(for key: Key) -> [QuizQuestion] {
    if let cached = cache.withLock({ $0[key] }) {
      return cached
    }
    let drawn = draw(for: key)
    cache.withLock { $0[key] = drawn }
    return drawn
  }

  /// The challenge's five questions as a learner is asked them: a tú question in the learner's
  /// own tú or vos, the same verb and tense, since tú and vos are a setting rather than a region.
  static func questions(for key: Key, secondSingular: DisplayPersonNumber) -> [QuizQuestion] {
    questions(for: key).map { question in
      guard question.personNumber == .secondSingularTú, secondSingular != .secondSingularTú else {
        return question
      }
      let asked = QuizQuestion(question.verb, question.tense, secondSingular)
      return asked.writtenAnswer == nil ? question : asked
    }
  }

  /// `questions(for:)` without the cache. The default quiz's draw over the level's tenses and
  /// band: each cell's tense drawn by weight, its person from those the level asks in the key's
  /// region, then the verbs balanced as a round of ten is (`QuizDraw`). It is seeded by the key
  /// alone, so that nothing on the device (the practice record, My Verbs, the quiz's person
  /// rotation, the settings) enters it. Two devices agree while they run the same build and
  /// verb list: `QuizDraw` uses the standard library's random functions, whose use of the
  /// generator a new toolchain could change, so the tests pin the seed and the draw's
  /// determinism rather than a list of questions.
  static func draw(for key: Key) -> [QuizQuestion] {
    let level = key.level
    let pool = level.pool
    var generator = SplitMix64(seed: key.seed)
    var drawn: [QuizQuestion] = []
    for _ in 0..<distinctVerbAttempts {
      var cells: [ConjugationCell] = []
      while cells.count < questionCount, let entry = pool.weightedRandomElement(using: &generator) {
        let personNumbers = Quiz.personNumbers(in: entry.tense, secondSingular: .secondSingularTú, region: key.region).filter(entry.asks)
        guard let personNumber = personNumbers.randomElement(using: &generator) else {
          break
        }
        cells.append(ConjugationCell(tense: entry.tense, personNumber: personNumber))
      }
      drawn = QuizDraw.questions(cells: cells, band: level.band, using: &generator)
      if drawn.count == questionCount, Set(drawn.map(\.verb)).count == drawn.count {
        break
      }
    }
    return drawn
  }
}

nonisolated extension Region {
  /// The region as a challenge's link and key name it.
  var linkKey: String {
    switch self {
    case .spain:
      return "spain"
    case .latinAmerica:
      return "latinAmerica"
    }
  }

  init?(linkKey: String) {
    guard let region = Region.allCases.first(where: { $0.linkKey == linkKey }) else {
      return nil
    }
    self = region
  }
}

/// A finished challenge, kept on the device and sent nowhere, so that the Quiz tab can show the
/// day's result and share it, and so that a challenge is taken once.
nonisolated struct DailyChallengeResult: Codable, Equatable, Sendable {
  static let storageKey = "dailyChallengeResults"
  /// Enough for a week's challenges, and a few opened from links.
  static let keptCount = 12

  let key: DailyChallenge.Key
  let outcomes: [DailyChallenge.Outcome]

  init(key: DailyChallenge.Key, outcomes: [DailyChallenge.Outcome]) {
    self.key = key
    self.outcomes = outcomes
  }

  /// The challenge's questions as first asked, a slip's second attempt included. A challenge asks
  /// no re-ask, but one would not count.
  init(key: DailyChallenge.Key, questions: [QuizQuestion], results: [ConjugationResult]) {
    self.key = key
    outcomes = zip(questions, results)
      .filter { !$0.0.isReask }
      .prefix(DailyChallenge.questionCount)
      .map { DailyChallenge.Outcome($0.1) }
  }

  var score: Int {
    outcomes.reduce(0) { $0 + $1.points }
  }

  var dots: String {
    outcomes.map(\.dot).joined()
  }

  /// "35 / 50".
  var pointsLine: String {
    "\(score) / \(DailyChallenge.maximumScore)"
  }

  /// What VoiceOver reads for the dots, which it would otherwise read as five circles.
  var spokenSummary: String {
    let right = outcomes.filter { $0 == .right }.count
    let secondTry = outcomes.filter { $0 == .secondTry }.count
    return L.DailyChallenge.spokenResult(right: right, secondTry: secondTry, count: outcomes.count, score: score, maximum: DailyChallenge.maximumScore)
  }

  /// The title, the date in the app's language and the level, the dots and the points, a link that
  /// opens the same challenge, and the App Store.
  func shareText(locale: Locale = DailyChallenge.appLocale) -> String {
    let formatter = DateFormatter()
    formatter.calendar = DailyChallenge.calendar
    formatter.timeZone = DailyChallenge.calendar.timeZone
    formatter.locale = locale
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return L.DailyChallenge.shareText(
      date: formatter.string(from: key.date),
      level: key.level.localizedName,
      dots: dots,
      score: score,
      maximum: DailyChallenge.maximumScore,
      link: URL.challengeDeeplink(key, source: .challengeLink)?.absoluteString ?? "",
      appStoreLink: URL.appStore.absoluteString
    )
  }
}

extension DailyChallengeResult {
  /// The share sheet with `shareText()`, and `tapShareChallenge`.
  @MainActor func share(anchorRect: CGRect?) {
    signalShare()
    ShareSheet.present(
      text: shareText(),
      title: L.DailyChallenge.title,
      icon: UIImage(named: Current.settings.appIcon.previewAssetName),
      anchorLabel: L.DailyChallenge.share,
      anchorRect: anchorRect == .zero ? nil : anchorRect
    )
  }

  /// Names the level and never the result, since no signal says how well a learner did.
  @MainActor func signalShare() {
    Current.analytics.signal(name: .tapShareChallenge, parameters: [ParameterKey.level.rawValue: key.levelKey])
  }
}

nonisolated extension DailyChallenge {
  /// The app's language, which can differ from the region's, for the shared date.
  static var appLocale: Locale {
    Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
  }
}

nonisolated extension QuizScope {
  /// A day's challenge, at the key's level and region whatever the learner's, since a challenge
  /// opened from a friend's link must ask the friend's questions. Never ranked, continued, or
  /// shuffled, and nothing in it is asked again, so that the results show what the shared text
  /// says.
  static func challenge(_ key: DailyChallenge.Key, source: AnalyticsSource = .challenge) -> QuizScope {
    QuizScope(kind: .challenge(key), verbs: nil, questionCount: DailyChallenge.questionCount, source: source, level: key.level)
  }
}

/// A request, from a shared link or the quiz widget, that the Quiz tab start a challenge. A part the
/// link leaves out, or names wrongly, is the learner's own: today, their level, their region.
struct DailyChallengeRequest: Equatable {
  let id = UUID()
  let day: String?
  let level: QuizLevel?
  let region: Region?
  let source: AnalyticsSource

  init(day: String? = nil, level: QuizLevel? = nil, region: Region? = nil, source: AnalyticsSource) {
    self.day = day.flatMap { DailyChallenge.date(fromDayString: $0) == nil ? nil : $0 }
    self.level = level
    self.region = region
    self.source = source
  }

  init(url: URL, source: AnalyticsSource) {
    self.init(
      day: url.deeplinkQueryValue(named: URL.dateQueryName),
      level: url.deeplinkQueryValue(named: URL.levelQueryName).flatMap(QuizLevel.init(rawValue:)),
      region: url.deeplinkQueryValue(named: URL.regionQueryName).flatMap(Region.init(linkKey:)),
      source: source
    )
  }

  func key(now: Date, level learnerLevel: QuizLevel, region learnerRegion: Region) -> DailyChallenge.Key {
    DailyChallenge.Key(day: day ?? DailyChallenge.dayString(for: now), level: level ?? learnerLevel, region: region ?? learnerRegion)
  }
}
