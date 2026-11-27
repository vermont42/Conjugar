//
//  VerbBrowseReviewCard.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Observation

/// The review card above the verb list: which verb it offers, chosen once per opening of the app,
/// and what the learner has done with it. It records the reveal and the snooze in the practice
/// record and sends the card's two signals. `ReviewCardHost` draws it, and `VerbBrowseView` tells
/// it when the app opens, goes to the background, and returns.
@Observable
final class VerbBrowseReviewCard {
  /// The card on screen.
  struct Card: Equatable {
    let offer: PracticeStore.CardOffer
    var isRevealed = false
    var wasSignaled = false
  }

  /// The card chosen at this opening, shown or not. Read `shownCard` to draw it.
  private(set) var card: Card?
  private var isChosen = false
  private var appWasInBackground = false
  @ObservationIgnored private let practice: PracticeStore
  @ObservationIgnored private let settings: Settings
  @ObservationIgnored private let analytics: Analytics
  @ObservationIgnored private let reportAchievements: () -> Void

  init(
    practice: PracticeStore = Current.practice,
    settings: Settings = Current.settings,
    analytics: Analytics = Current.analytics,
    reportAchievements: @escaping () -> Void = { Current.reportAchievements() }
  ) {
    self.practice = practice
    self.settings = settings
    self.analytics = analytics
    self.reportAchievements = reportAchievements
  }

  /// The card to draw, which Suppress Review Card hides at once.
  var shownCard: Card? {
    settings.reviewCardSuppression == .off ? card : nil
  }

  // MARK: - The choice

  /// The list's first appearance chooses. Later appearances, as after a page is popped, keep the
  /// card, so that revealing one does not swap it for the next verb due.
  func listAppeared() {
    if !isChosen {
      choose()
    }
  }

  func appEnteredBackground() {
    appWasInBackground = true
  }

  /// A return from the background is a new opening, which may offer another card.
  func appBecameActive() {
    guard appWasInBackground else {
      return
    }
    appWasInBackground = false
    choose()
  }

  /// Turning Suppress Review Card off offers a card at once if none was chosen. Turning it on
  /// hides the card through `shownCard` and keeps it, so that turning it off again restores it.
  func suppressionChanged() {
    if settings.reviewCardSuppression == .off, card == nil {
      choose()
    }
  }

  /// Offers the irregular verb whose key conjugation is longest overdue, if any.
  private func choose() {
    isChosen = true
    guard settings.reviewCardSuppression == .off else {
      card = nil
      return
    }
    card = practice.cardOffer().map { Card(offer: $0) }
  }

  // MARK: - What the learner does

  /// Sends `viewReviewCard` once for each card, however often the list redraws it.
  func cardAppeared() {
    guard card?.wasSignaled == false else {
      return
    }
    card?.wasSignaled = true
    analytics.signal(name: .viewReviewCard)
  }

  /// A reveal moves the verb's due key conjugations up a box, which can earn an achievement.
  func reveal() {
    guard let card, !card.isRevealed else {
      return
    }
    practice.recordReview(card.offer)
    reportAchievements()
    analytics.signal(name: .tapRevealReviewCard)
    self.card?.isRevealed = true
  }

  /// The page to push when the revealed card is tapped.
  var destination: VerbDestination? {
    card.map { VerbDestination(infinitive: $0.offer.entry.infinitive, source: .reviewCard) }
  }

  /// A card dismissed before its conjugations were seen was no review, so its due key
  /// conjugations return tomorrow in the same box.
  func dismiss() {
    guard let card else {
      return
    }
    if !card.isRevealed {
      practice.snooze(card.offer)
    }
    self.card = nil
  }
}
