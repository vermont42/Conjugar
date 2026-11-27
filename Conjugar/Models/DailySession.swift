//
//  DailySession.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// The daily session: ten questions at the learner's level, filled first from the due items the
/// level asks and the band holds, then with the default quiz's draw. Finishing one extends the
/// streak (`DailyStreak`). It asks no choice between two sentences, since a choice moves nothing in
/// the practice record, which the session is for.
nonisolated extension QuizScope {
  /// The daily session, from the Quiz tab's row or from the reminder. Never ranked and never
  /// continued, since a second session is one of its own, which a repair counts.
  static func daily(source: AnalyticsSource = .daily) -> QuizScope {
    QuizScope(kind: .daily, verbs: nil, questionCount: roundLength, source: source)
  }
}

nonisolated extension AnalyticsBand {
  /// The streak a daily session leaves, or the one at stake while a repair waits.
  static func streak(_ length: Int) -> String {
    switch length {
    case ...1:
      return "1"
    case 2...6:
      return "2-6"
    case 7...29:
      return "7-29"
    default:
      return "30+"
    }
  }
}

extension DailyStreak.Status {
  /// What the Quiz tab's row says about the streak.
  var hubDetail: String {
    switch self {
    case .none:
      return L.DailySession.description
    case let .active(length, isDoneToday):
      return isDoneToday ? L.DailySession.streakDoneToday(length) : L.DailySession.streakKeepGoing(length)
    case .repairable:
      return repairLine
    }
  }

  /// What the results say about the streak after a daily session.
  var resultsLine: String {
    switch self {
    case .none:
      return ""
    case let .active(length, _):
      return L.DailySession.streak(length)
    case .repairable:
      return repairLine
    }
  }

  private var repairLine: String {
    guard case let .repairable(length, sessionsToday) = self else {
      return ""
    }
    return sessionsToday == 0 ? L.DailySession.repairTwo(length) : L.DailySession.repairOne(length)
  }
}
