//
//  VerbBrowseReviewCardTests.swift
//  ConjugarTests
//
//  The review card above the verb list: its choice once per opening, Suppress Review Card, the
//  reveal and the snooze it records, and the signals it sends once each.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct VerbBrowseReviewCardTests {
  private let analytics = AnalyticsSpy()
  private let practice = PracticeStore(getterSetter: GetterSetterFake())
  private let settings = Settings(getterSetter: GetterSetterFake())
  private let reports = ReportCounter()

  /// Counts the achievement reports.
  private final class ReportCounter {
    var count = 0
  }

  private func daysAgo(_ days: Double) -> Date {
    Date.now.addingTimeInterval(-days * 86_400)
  }

  /// tener is longest overdue, then ir.
  private func makeCard() -> VerbBrowseReviewCard {
    practice.recordLookup("tener", source: .search, at: daysAgo(10))
    practice.recordLookup("ir", source: .search, at: daysAgo(5))
    let reports = reports
    return VerbBrowseReviewCard(
      practice: practice,
      settings: settings,
      analytics: analytics,
      reportAchievements: { reports.count += 1 }
    )
  }

  private func count(_ name: AnalyticsName) -> Int {
    analytics.signalNames.filter { $0 == name }.count
  }

  @Test func nothingIsChosenBeforeTheListAppears() {
    let model = makeCard()
    #expect(model.card == nil)
    model.listAppeared()
    #expect(model.shownCard?.offer.entry.infinitive == "tener")
  }

  @Test func aRevealedCardSurvivesTheListsReappearance() {
    let model = makeCard()
    model.listAppeared()
    model.reveal()
    #expect(practice.cardOffer()?.entry.infinitive == "ir")

    model.listAppeared()
    #expect(model.card?.offer.entry.infinitive == "tener")
    #expect(model.card?.isRevealed == true)
  }

  @Test func aReturnFromTheBackgroundChoosesAgain() {
    let model = makeCard()
    model.listAppeared()
    model.reveal()

    model.appBecameActive()
    #expect(model.card?.offer.entry.infinitive == "tener", "Active without a background is no new opening.")

    model.appEnteredBackground()
    model.appBecameActive()
    #expect(model.card?.offer.entry.infinitive == "ir")
    #expect(model.card?.isRevealed == false)
  }

  @Test func suppressionHidesTheCardAndOffChoosesOne() {
    settings.reviewCardSuppression = .on
    let model = makeCard()
    model.listAppeared()
    #expect(model.card == nil)

    settings.reviewCardSuppression = .off
    model.suppressionChanged()
    #expect(model.shownCard?.offer.entry.infinitive == "tener")

    settings.reviewCardSuppression = .on
    model.suppressionChanged()
    #expect(model.shownCard == nil)
    #expect(model.card != nil, "Suppression hides the card and keeps it.")

    settings.reviewCardSuppression = .off
    model.suppressionChanged()
    #expect(model.shownCard?.offer.entry.infinitive == "tener")
  }

  @Test func aRevealRecordsTheReviewAndSignalsOnce() {
    let model = makeCard()
    model.listAppeared()
    model.reveal()
    let afterOne = practice.record
    model.reveal()

    #expect(practice.record == afterOne)
    #expect(count(.tapRevealReviewCard) == 1)
    #expect(reports.count == 1)
  }

  @Test func theCardSignalsItsViewOnceHoweverOftenItIsDrawn() {
    let model = makeCard()
    model.listAppeared()
    model.cardAppeared()
    model.cardAppeared()
    #expect(count(.viewReviewCard) == 1)

    model.appEnteredBackground()
    model.appBecameActive()
    model.cardAppeared()
    #expect(count(.viewReviewCard) == 2, "A new opening's card is a new card.")
  }

  @Test func aDismissalBeforeTheRevealSnoozes() {
    let model = makeCard()
    model.listAppeared()
    model.dismiss()

    #expect(model.card == nil)
    #expect(practice.cardOffer()?.entry.infinitive == "ir", "tener's key conjugations wait until tomorrow.")
    #expect(count(.tapRevealReviewCard) == 0)
  }

  @Test func aDismissalAfterTheRevealChangesNothing() {
    let model = makeCard()
    model.listAppeared()
    model.reveal()
    let revealed = practice.record
    model.dismiss()

    #expect(model.card == nil)
    #expect(practice.record == revealed)
  }

  @Test func theRevealedCardOpensItsVerbFromTheCard() {
    let model = makeCard()
    model.listAppeared()
    #expect(model.destination == VerbDestination(infinitive: "tener", source: .reviewCard))
  }
}
