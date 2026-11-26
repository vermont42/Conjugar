//
//  VerbVisitTracker.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// When a verb page's visits begin and end, and how deep each one goes. `VerbView` reports what
/// happens to the page, and sends `viewVerbView` and `leaveVerbView` for the events returned.
///
/// A visit is a stretch during which the page is on screen, uncovered, with the app in the
/// foreground. It ends when the page leaves the screen, when the app goes to the background, and
/// when the page presents a sheet (a tense's article, Test Me). It comes back, with source
/// `resume`, when the page reappears, the app returns, or the sheet closes.
///
/// A page opened on a marked form scrolls itself there, and the sections that scroll shows are not
/// sections the learner reached. They count once the learner scrolls.
nonisolated struct VerbVisitTracker: Sendable {
  enum Event: Equatable, Sendable {
    /// A visit began. An arrival, a source other than `resume`, is also the verb's open.
    case began(VerbVisit)
    /// A visit ended at the date given.
    case ended(VerbVisit, end: Date)
  }

  /// How the learner reached the page, which its first visit reports.
  let source: AnalyticsSource
  private(set) var visit: VerbVisit?
  private(set) var visibleSections: Set<VerbPageSection> = []
  private var hasAppeared = false
  private var isOnScreen = false
  private var isCovered = false
  private var isLanding = false

  init(source: AnalyticsSource) {
    self.source = source
  }

  mutating func appeared(at now: Date) -> Event? {
    isOnScreen = true
    let source = hasAppeared ? .resume : source
    hasAppeared = true
    return begin(source: source, at: now)
  }

  mutating func disappeared(at now: Date) -> Event? {
    isOnScreen = false
    return end(at: now)
  }

  mutating func enteredBackground(at now: Date) -> Event? {
    end(at: now)
  }

  mutating func becameActive(at now: Date) -> Event? {
    begin(source: .resume, at: now)
  }

  /// A sheet over the page opened or closed.
  mutating func coveredChanged(_ isCovered: Bool, at now: Date) -> Event? {
    self.isCovered = isCovered
    return isCovered ? end(at: now) : begin(source: .resume, at: now)
  }

  /// The page is about to scroll itself to a marked form.
  mutating func beganLanding() {
    isLanding = true
  }

  /// The learner scrolled the page, which ends the landing.
  mutating func learnerScrolled() {
    isLanding = false
  }

  /// A section came on screen or left it. Returns true when the learner reached it: it came on
  /// screen other than by the landing scroll.
  mutating func sectionVisibilityChanged(_ section: VerbPageSection, isVisible: Bool) -> Bool {
    guard isVisible else {
      visibleSections.remove(section)
      return false
    }
    visibleSections.insert(section)
    guard !isLanding else {
      return false
    }
    visit?.reach(section)
    return true
  }

  private mutating func begin(source: AnalyticsSource, at now: Date) -> Event? {
    guard visit == nil, isOnScreen, !isCovered else {
      return nil
    }
    let newVisit = VerbVisit(source: source, start: now, visibleSections: isLanding ? [] : visibleSections)
    visit = newVisit
    return .began(newVisit)
  }

  private mutating func end(at now: Date) -> Event? {
    guard let visit else {
      return nil
    }
    self.visit = nil
    return .ended(visit, end: now)
  }
}
