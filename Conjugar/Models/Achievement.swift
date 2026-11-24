//
//  Achievement.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Semantic ordering: as Game Center lists them, the patterns level by level, then the verbs.
/// Game Center achievements for mastery milestones, never for volume of play. Each counts what the
/// Mastery page counts, an item in the third box or beyond, so the record that fills the page also
/// earns these. Their titles, descriptions, and artwork live in App Store Connect and
/// `GameCenterResources.gamekit`; see docs/game_center_setup.md.
nonisolated enum Achievement: String, CaseIterable, Sendable {
  case patternsBeginner
  case patternsElementary
  case patternsIntermediate
  case patternsAdvanced
  case pillars
  case coreTen
  case coreTwentyFive
  case coreFifty

  /// How far the record has come toward an achievement.
  struct Progress: Equatable {
    let mastered: Int
    let required: Int

    var isComplete: Bool {
      required > 0 && mastered >= required
    }

    /// What Game Center takes, from 0 to 100.
    var percentComplete: Double {
      guard required > 0 else {
        return 0
      }
      return Double(min(mastered, required)) / Double(required) * 100
    }
  }

  // Achievement IDs are permanent in App Store Connect, so these must match
  // docs/game_center_setup.md exactly and never change, even if an achievement is renamed.
  var identifier: String {
    switch self {
    case .patternsBeginner:
      return "conjugar.achievement.patterns.beginner"
    case .patternsElementary:
      return "conjugar.achievement.patterns.elementary"
    case .patternsIntermediate:
      return "conjugar.achievement.patterns.intermediate"
    case .patternsAdvanced:
      return "conjugar.achievement.patterns.advanced"
    case .pillars:
      return "conjugar.achievement.verbs.pillars"
    case .coreTen:
      return "conjugar.achievement.verbs.core10"
    case .coreTwentyFive:
      return "conjugar.achievement.verbs.core25"
    case .coreFifty:
      return "conjugar.achievement.verbs.core50"
    }
  }

  /// Game Center's points, at most 100 each and 1,000 in all. App Store Connect fixes a value
  /// once the achievement has been live.
  var points: Int {
    switch self {
    case .patternsBeginner:
      return 10
    case .patternsElementary, .pillars, .coreTen:
      return 25
    case .patternsIntermediate, .coreTwentyFive:
      return 50
    case .patternsAdvanced, .coreFifty:
      return 100
    }
  }

  /// The level whose every pattern a pattern achievement asks for.
  var patternLevel: QuizLevel? {
    switch self {
    case .patternsBeginner:
      return .beginner
    case .patternsElementary:
      return .elementary
    case .patternsIntermediate:
      return .intermediate
    case .patternsAdvanced:
      return .advanced
    case .pillars, .coreTen, .coreTwentyFive, .coreFifty:
      return nil
    }
  }

  /// The verbs a verb achievement asks for: the six that most of the language rests on, or the
  /// most frequent irregular verbs, as the Mastery page lists them.
  @MainActor
  var verbs: [String] {
    switch self {
    case .patternsBeginner, .patternsElementary, .patternsIntermediate, .patternsAdvanced:
      return []
    case .pillars:
      return Self.pillarVerbs
    case .coreTen:
      return Array(Mastery.coreVerbs.prefix(10))
    case .coreTwentyFive:
      return Array(Mastery.coreVerbs.prefix(25))
    case .coreFifty:
      return Mastery.coreVerbs
    }
  }

  static let pillarVerbs = ["ser", "estar", "haber", "tener", "ir", "hacer"]

  /// Every achievement's progress in `record`. A pattern achievement counts its level's patterns
  /// in the learner's tú or vos and region, whatever level is chosen. A verb counts once every key
  /// conjugation that Advanced asks of it is mastered, so that choosing Beginner, which asks only
  /// the presente and the commands, earns no verb.
  @MainActor
  static func progress(in record: PracticeRecord, secondSingular: DisplayPersonNumber, region: Region) -> [Achievement: Progress] {
    var masteries: [QuizLevel: Mastery] = [:]
    for level in QuizLevel.allCases {
      masteries[level] = Mastery(level: level, record: record, secondSingular: secondSingular, region: region)
    }
    let masteredVerbs = Set(
      (masteries[.advanced]?.verbs ?? [])
        .filter { row in row.keyConjugations.allSatisfy { $0.state == .mastered } }
        .map(\.infinitive)
    )
    var result: [Achievement: Progress] = [:]
    for achievement in allCases {
      if let level = achievement.patternLevel, let mastery = masteries[level] {
        result[achievement] = Progress(mastered: mastery.masteredPatternCount, required: mastery.patternCount)
      } else {
        let verbs = achievement.verbs
        result[achievement] = Progress(mastered: verbs.filter(masteredVerbs.contains).count, required: verbs.count)
      }
    }
    return result
  }

  @MainActor
  static func progress(in record: PracticeRecord, settings: Settings) -> [Achievement: Progress] {
    progress(
      in: record,
      secondSingular: settings.secondSingularQuiz == .tu ? .secondSingularTú : .secondSingularVos,
      region: settings.region
    )
  }
}

extension GameCenter {
  /// Sends Game Center the achievements' progress as `record` now stands, while the player is
  /// signed in. Progress is computed afresh from the record each time, so nothing made while
  /// signed out is lost: `GameCenterReal` reports again once a sign-in has loaded what Game Center
  /// holds, and sends only what has risen.
  func reportAchievements(record: PracticeRecord, settings: Settings) {
    guard isAuthenticated else {
      return
    }
    reportAchievementProgress(Achievement.progress(in: record, settings: settings).mapValues(\.percentComplete))
  }
}

extension World {
  /// Called when a review card is revealed and when Game Center has loaded a signed-in player's
  /// achievements. A quiz reports through its own Game Center and store as it finishes or is quit.
  func reportAchievements() {
    gameCenter.reportAchievements(record: practice.record, settings: settings)
  }
}
