//
//  DailySessionTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The daily session, its streak and the streak's repair, and the reminder: the streak's arithmetic
//  under a fixed calendar, the session's draw and flags, a quiz finishing on chosen days, and which
//  reminders are scheduled.
//

import Foundation
import Testing
@testable import Conjugar

/// A clock a test moves from day to day.
@MainActor
private final class TestClock {
  var now: Date

  init(_ now: Date) {
    self.now = now
  }
}

@MainActor
struct DailySessionTests {
  /// Madrid's, so that a day of 25 hours, at the end of summer time, can be tried.
  private static let madrid: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
    return calendar
  }()

  private static func date(_ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0, calendar: Calendar = madrid) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)) ?? .distantPast
  }

  private static func november(_ day: Int, hour: Int = 12, calendar: Calendar = madrid) -> Date {
    date(11, day, hour: hour, calendar: calendar)
  }

  private static func streak(sessions days: [Int]) -> DailyStreak {
    var streak = DailyStreak()
    for day in days {
      streak.recordSession(at: november(day), calendar: madrid)
    }
    return streak
  }

  /// The learner's own calendar, which the quiz's reminders are scheduled in.
  private static func local(_ day: Int, hour: Int = 10) -> Date {
    november(day, hour: hour, calendar: .current)
  }

  private func makeQuiz(
    level: QuizLevel = .beginner,
    practice: PracticeStore,
    settings: Settings? = nil,
    gameCenter: GameCenter = GameCenterFake(),
    scheduler: ReminderScheduler = ReminderSchedulerSpy(),
    clock: TestClock
  ) -> Quiz {
    let settings = settings ?? Self.settings(level: level)
    return Quiz(
      settings: settings,
      gameCenter: gameCenter,
      shouldShuffle: true,
      randomSource: SplitMix64(seed: 5),
      practice: practice,
      reminderScheduler: scheduler,
      now: { clock.now }
    )
  }

  private static func settings(level: QuizLevel = .beginner, reminder: DailyReminder = .off) -> Settings {
    Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: Region.latinAmerica.rawValue,
      Settings.dailyReminderKey: reminder.rawValue
    ]))
  }

  private func finishRight(_ quiz: Quiz) {
    while quiz.quizState == .inProgress {
      if quiz.isHeld {
        quiz.continueAfterCorrection()
        continue
      }
      quiz.process(proposedAnswer: quiz.currentQuestion?.writtenAnswer?.lowercased() ?? "")
    }
  }

  /// Each verb looked up long enough before `date` that its key conjugations are due.
  private static func practice(lookingUp verbs: [String], before date: Date) -> PracticeStore {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    for (index, verb) in verbs.enumerated() {
      practice.recordLookup(verb, source: .search, at: date.addingTimeInterval(-Double(40 - index) * 86_400))
    }
    return practice
  }

  // The streak.

  @Test func noSessionsMakeNoStreak() {
    #expect(DailyStreak().status(at: Self.november(24), calendar: Self.madrid) == .none)
  }

  @Test func aStreakHoldsThroughTheNextDayAndCanBeRepairedTheDayAfter() {
    let streak = Self.streak(sessions: [20])

    #expect(streak.status(at: Self.november(20), calendar: Self.madrid) == .active(length: 1, isDoneToday: true))
    #expect(streak.status(at: Self.november(21), calendar: Self.madrid) == .active(length: 1, isDoneToday: false))
    #expect(streak.status(at: Self.november(22), calendar: Self.madrid) == .repairable(length: 1, sessionsToday: 0))
    #expect(streak.status(at: Self.november(23), calendar: Self.madrid) == .none)
  }

  @Test func aDayCountsOnceHoweverManySessions() {
    let streak = Self.streak(sessions: [20, 20, 21])

    #expect(streak.status(at: Self.november(21), calendar: Self.madrid) == .active(length: 2, isDoneToday: true))
  }

  /// The missed day the repair bridges does not count: 20, 21, and 23 make three days.
  @Test func twoSessionsAfterAMissedDayRepairTheStreak() {
    var streak = Self.streak(sessions: [20, 21, 23])
    let afterOne = streak.status(at: Self.november(23), calendar: Self.madrid)

    #expect(afterOne == .repairable(length: 2, sessionsToday: 1))
    #expect(afterOne.awaitsRepairSession)

    streak.recordSession(at: Self.november(23, hour: 20), calendar: Self.madrid)
    let afterTwo = streak.status(at: Self.november(23, hour: 20), calendar: Self.madrid)

    #expect(afterTwo == .active(length: 3, isDoneToday: true))
    #expect(!afterTwo.awaitsRepairSession)
    #expect(streak.status(at: Self.november(24), calendar: Self.madrid) == .active(length: 3, isDoneToday: false))
  }

  @Test func oneSessionAfterAMissedDayStartsAStreakOfItsOwn() {
    let streak = Self.streak(sessions: [20, 21, 23])

    #expect(streak.status(at: Self.november(24), calendar: Self.madrid) == .active(length: 1, isDoneToday: false))
  }

  @Test func twoMissedDaysBreakTheStreakForGood() {
    let streak = Self.streak(sessions: [19, 20, 23, 23])

    #expect(streak.status(at: Self.november(23), calendar: Self.madrid) == .active(length: 1, isDoneToday: true))
  }

  /// Summer time ends in Madrid on 25 October 2026, a day of 25 hours, which is still one day.
  @Test func aDayOfTwentyFiveHoursIsOneDay() {
    var streak = DailyStreak()
    streak.recordSession(at: Self.date(10, 24, hour: 23, minute: 30), calendar: Self.madrid)
    streak.recordSession(at: Self.date(10, 25, hour: 23, minute: 30), calendar: Self.madrid)

    #expect(streak.status(at: Self.date(10, 26, hour: 0, minute: 30), calendar: Self.madrid) == .active(length: 2, isDoneToday: false))
  }

  @Test func onlyTheLastTwoRunsAreKept() {
    let streak = Self.streak(sessions: [10, 11, 15, 20])

    #expect(streak.sessions.keys.sorted() == ["2026-11-15", "2026-11-20"])
  }

  @Test(arguments: [(0, "1"), (1, "1"), (2, "2-6"), (6, "2-6"), (7, "7-29"), (29, "7-29"), (30, "30+")])
  func theStreakIsSentInBands(length: Int, band: String) {
    #expect(AnalyticsBand.streak(length) == band)
  }

  @Test func theStoredFormIsPinned() throws {
    let streak = try #require(DailyStreak(json: #"{"sessions":{"2026-11-22":1,"2026-11-23":2}}"#))

    #expect(streak.status(at: Self.november(23), calendar: Self.madrid) == .active(length: 2, isDoneToday: true))
    #expect(DailyStreak(json: "") == nil)
  }

  @Test func theStoreKeepsTheStreakAcrossALaunchAndResetForgetsIt() {
    let getterSetter = GetterSetterFake()
    let practice = PracticeStore(getterSetter: getterSetter, calendar: Self.madrid)
    #expect(practice.isEmpty)

    #expect(practice.recordDailySession(at: Self.november(23)) == .active(length: 1, isDoneToday: true))
    #expect(!practice.isEmpty)

    let relaunched = PracticeStore(getterSetter: getterSetter, calendar: Self.madrid)
    #expect(relaunched.streakStatus(at: Self.november(24)) == .active(length: 1, isDoneToday: false))

    relaunched.reset()
    #expect(relaunched.dailyStreak.isEmpty)
    #expect(PracticeStore(getterSetter: getterSetter, calendar: Self.madrid).streakStatus(at: Self.november(24)) == .none)
  }

  // The session.

  @Test func theScopeIsNeitherRankedNorContinuedAndCountsAsADailySession() {
    let scope = QuizScope.daily()

    #expect(scope.questionCount == QuizScope.roundLength)
    #expect(scope.source == .daily)
    #expect(QuizScope.daily(source: .reminder).source == .reminder)
    #expect(!scope.isRanked)
    #expect(!scope.continues)
    #expect(!scope.mixesChoiceQuestions)
    #expect(!scope.mixesDueItems)
    #expect(scope.sendsQuestionCounts)
    #expect(scope.startsLiveActivity)
    #expect(LastQuizResult.Kind(scope: scope) == .daily)
  }

  /// tener's yo presente is asked at Beginner, and its yo pretérito and yo futuro wait for a
  /// Review, since Beginner asks neither tense.
  @Test func dueItemsTheLevelAsksComeFirstAndTheRestWait() throws {
    let clock = TestClock(.now)
    let practice = Self.practice(lookingUp: ["tener"], before: clock.now)
    let quiz = makeQuiz(practice: practice, clock: clock)

    #expect(quiz.start(scope: .daily()))
    let items = quiz.questions.compactMap(PracticeItem.exercised(by:))

    #expect(quiz.questions.count == QuizScope.roundLength)
    #expect(quiz.questions.allSatisfy { $0.choice == nil })
    #expect(items.contains(.keyConjugation(infinitive: "tener", key: .yoPresente)))
    #expect(!items.contains(.keyConjugation(infinitive: "tener", key: .yoPretérito)))
    #expect(!items.contains(.keyConjugation(infinitive: "tener", key: .yoFuturo)))
    #expect(quiz.questions.allSatisfy { Set(QuizLevel.beginner.pool.map(\.tense)).contains($0.tense) })
  }

  @Test func tenDueItemsFillTheSession() {
    let clock = TestClock(.now)
    let verbs = ["ser", "estar", "tener", "hacer", "ir", "poder", "decir", "querer", "venir", "poner", "saber", "salir"]
    let practice = Self.practice(lookingUp: verbs, before: clock.now)
    let due = Set(practice.dueItems(at: clock.now).map(\.key))
    let quiz = makeQuiz(practice: practice, clock: clock)

    #expect(quiz.start(scope: .daily()))

    #expect(quiz.questions.count == QuizScope.roundLength)
    #expect(quiz.questions.allSatisfy { PracticeItem.exercised(by: $0).map { due.contains($0.key) } ?? false })
  }

  // A quiz on chosen days.

  @Test func finishingExtendsTheStreakAndPostsNoScore() {
    let clock = TestClock(Self.local(24))
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let gameCenter = GameCenterSpy()
    let scheduler = ReminderSchedulerSpy()
    let quiz = makeQuiz(practice: practice, gameCenter: gameCenter, scheduler: scheduler, clock: clock)

    #expect(quiz.start(scope: .daily()))
    finishRight(quiz)

    #expect(quiz.dailyStreakStatus == .active(length: 1, isDoneToday: true))
    #expect(practice.streakStatus(at: clock.now) == .active(length: 1, isDoneToday: true))
    #expect(!quiz.canContinue)
    #expect(gameCenter.submissions.isEmpty)
    #expect(practice.lastResult?.kind == .daily)
    #expect(practice.lastResult?.level == .beginner)
    // The reminder is off, so finishing clears what was scheduled.
    #expect(scheduler.schedules.count == 1)
    #expect(scheduler.scheduled.isEmpty)
  }

  @Test func aQuitSessionDoesNotCount() {
    let clock = TestClock(Self.local(24))
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice, clock: clock)

    #expect(quiz.start(scope: .daily()))
    quiz.process(proposedAnswer: quiz.currentQuestion?.writtenAnswer?.lowercased() ?? "")
    quiz.quit()

    #expect(quiz.dailyStreakStatus == nil)
    #expect(practice.dailyStreak.isEmpty)
  }

  @Test func anotherQuizLeavesTheStreakAlone() {
    let clock = TestClock(Self.local(24))
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice, clock: clock)

    #expect(quiz.start(scope: .allVerbs))
    finishRight(quiz)

    #expect(quiz.dailyStreakStatus == nil)
    #expect(practice.dailyStreak.isEmpty)
  }

  @Test func aRepairAcrossFourDays() {
    let clock = TestClock(Self.local(20))
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice, clock: clock)

    for day in [20, 21] {
      clock.now = Self.local(day)
      quiz.start(scope: .daily())
      finishRight(quiz)
    }
    #expect(quiz.dailyStreakStatus == .active(length: 2, isDoneToday: true))

    clock.now = Self.local(23)
    #expect(practice.streakStatus(at: clock.now) == .repairable(length: 2, sessionsToday: 0))
    quiz.start(scope: .daily())
    finishRight(quiz)
    #expect(quiz.dailyStreakStatus == .repairable(length: 2, sessionsToday: 1))
    #expect(quiz.dailyStreakStatus?.awaitsRepairSession == true)

    clock.now = Self.local(23, hour: 11)
    quiz.start(scope: .daily())
    finishRight(quiz)
    #expect(quiz.dailyStreakStatus == .active(length: 3, isDoneToday: true))
  }

  // The reminder.

  @Test func aReminderComesEachDayAtTheChosenTime() {
    let reminders = DailyReminderPlan.reminders(
      record: PracticeRecord(),
      streak: DailyStreak(),
      minutes: 18 * 60,
      now: Self.november(24, hour: 10),
      asks: { _ in true },
      calendar: Self.madrid
    )

    #expect(reminders.count == DailyReminderPlan.dayCount)
    #expect(reminders.first?.date == Self.date(11, 24, hour: 18))
    #expect(reminders.first?.identifier == "dailyReminder.2026-11-24")
    #expect(reminders.last?.date == Self.date(12, 7, hour: 18))
    #expect(reminders.allSatisfy { $0.title == L.DailyReminder.title && $0.body == L.DailyReminder.body })
  }

  @Test func todaysReminderIsLeftOutOnceItsTimeHasPassed() {
    let reminders = DailyReminderPlan.reminders(
      record: PracticeRecord(),
      streak: DailyStreak(),
      minutes: 18 * 60,
      now: Self.november(24, hour: 19),
      asks: { _ in true },
      calendar: Self.madrid
    )

    #expect(reminders.count == DailyReminderPlan.dayCount - 1)
    #expect(reminders.first?.date == Self.date(11, 25, hour: 18))
  }

  /// A day whose session is done gets none, the next day an ordinary one, and the day after the
  /// repair's line.
  @Test func aDoneDayGetsNoReminderAndAMissedOneGetsTheRepairLine() {
    let reminders = DailyReminderPlan.reminders(
      record: PracticeRecord(),
      streak: Self.streak(sessions: [24]),
      minutes: 18 * 60,
      now: Self.november(24, hour: 13),
      asks: { _ in true },
      calendar: Self.madrid
    )

    #expect(reminders.first?.date == Self.date(11, 25, hour: 18))
    #expect(reminders.first?.body == L.DailyReminder.body)
    #expect(reminders.dropFirst().first?.body == L.DailySession.repairTwo(1))
  }

  /// The count is of what will be due on each reminder's day that the settings can ask.
  @Test func theReminderSaysWhatWillBeDue() {
    let practice = Self.practice(lookingUp: ["tener"], before: Self.november(24, hour: 10))
    let reminders = DailyReminderPlan.reminders(
      record: practice.record,
      streak: DailyStreak(),
      minutes: 18 * 60,
      now: Self.november(24, hour: 10),
      asks: { _ in true },
      calendar: Self.madrid
    )

    let count = practice.record.dueItems(at: Self.november(24, hour: 18)).count
    #expect(count > 0)
    #expect(reminders.first?.body == L.DailyReminder.bodyDue(count))
    #expect(DailyReminderPlan.reminders(
      record: practice.record,
      streak: DailyStreak(),
      minutes: 18 * 60,
      now: Self.november(24, hour: 10),
      asks: { _ in false },
      calendar: Self.madrid
    ).first?.body == L.DailyReminder.body)
  }

  @Test func reschedulingFollowsTheSetting() {
    let scheduler = ReminderSchedulerSpy()
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let settings = Self.settings(reminder: .on)

    DailyReminderPlan.reschedule(with: scheduler, settings: settings, practice: practice, now: Self.november(24, hour: 10), calendar: Self.madrid)
    #expect(scheduler.scheduled.count == DailyReminderPlan.dayCount)

    settings.dailyReminderMinutes = 9 * 60
    DailyReminderPlan.reschedule(with: scheduler, settings: settings, practice: practice, now: Self.november(24, hour: 10), calendar: Self.madrid)
    #expect(scheduler.scheduled.first?.date == Self.date(11, 25, hour: 9))

    settings.dailyReminder = .off
    DailyReminderPlan.reschedule(with: scheduler, settings: settings, practice: practice, now: Self.november(24, hour: 10), calendar: Self.madrid)
    #expect(scheduler.scheduled.isEmpty)
  }

  /// Finishing today's session drops today's reminder.
  @Test func finishingASessionDropsTodaysReminder() {
    let clock = TestClock(Self.local(24))
    let scheduler = ReminderSchedulerSpy()
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice, settings: Self.settings(reminder: .on), scheduler: scheduler, clock: clock)

    quiz.start(scope: .daily())
    finishRight(quiz)

    let today = DailyReminderPlan.identifierPrefix + DailyStreak.dayKey(clock.now)
    #expect(!scheduler.scheduled.isEmpty)
    #expect(!scheduler.scheduled.contains { $0.identifier == today })
  }

  @Test func theReminderSettingDefaultsToOffAtSixAndPersists() {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    #expect(settings.dailyReminder == .off)
    #expect(settings.dailyReminderMinutes == 18 * 60)

    settings.dailyReminder = .on
    settings.dailyReminderMinutes = 7 * 60 + 30
    let reloaded = Settings(getterSetter: getterSetter)
    #expect(reloaded.dailyReminder == .on)
    #expect(reloaded.dailyReminderMinutes == 450)
  }

  @Test func theReminderLinkStartsADailySession() throws {
    let link = try #require(URL.dailySessionDeeplink(source: .reminder))
    #expect(link.absoluteString == "conjugar://quiz/daily?source=reminder")

    let router = AppRouter()
    router.handle(url: link)
    #expect(router.selectedTab == .quiz)
    #expect(router.pendingDailySession == .reminder)
    #expect(router.pendingQuizStart == nil)

    let bare = AppRouter()
    bare.handle(url: try #require(URL(string: "conjugar://quiz/daily")))
    #expect(bare.pendingDailySession == .deeplink)
  }
}
