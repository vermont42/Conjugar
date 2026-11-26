//
//  VerbVisitTrackerTests.swift
//  ConjugarTests
//
//  When a verb page's visits begin and end, across the screen, the foreground, a sheet, and the
//  landing scroll. Nonisolated, like the analytics family.
//

import Foundation
import Testing
@testable import Conjugar

@Suite("VerbVisitTracker")
struct VerbVisitTrackerTests {
  private let start = Date(timeIntervalSinceReferenceDate: 0)

  private func at(_ seconds: TimeInterval) -> Date {
    start.addingTimeInterval(seconds)
  }

  private func began(_ event: VerbVisitTracker.Event?) -> VerbVisit? {
    if case .began(let visit) = event {
      return visit
    }
    return nil
  }

  private func ended(_ event: VerbVisitTracker.Event?) -> [String: String]? {
    if case let .ended(visit, end) = event {
      return visit.leaveParameters(end: end)
    }
    return nil
  }

  @Test func theFirstAppearanceReportsTheSourceAndLaterOnesResume() {
    var tracker = VerbVisitTracker(source: .search)
    let arrival = tracker.appeared(at: at(0))
    #expect(began(arrival)?.source == .search)
    let leave = tracker.disappeared(at: at(3))
    #expect(ended(leave) == ["deepestSection": "header", "dwell": "0-5s"])
    let comeback = tracker.appeared(at: at(10))
    #expect(began(comeback)?.source == .resume)
  }

  @Test func theBackgroundEndsAVisitAndTheForegroundResumesIt() {
    var tracker = VerbVisitTracker(source: .tab)
    _ = tracker.appeared(at: at(0))
    let leave = tracker.enteredBackground(at: at(20))
    #expect(ended(leave) == ["deepestSection": "header", "dwell": "15-60s"])
    // Ending twice sends one leave.
    let secondLeave = tracker.enteredBackground(at: at(21))
    #expect(secondLeave == nil)
    let comeback = tracker.becameActive(at: at(100))
    #expect(began(comeback)?.source == .resume)
    // Already visiting: a second activation begins nothing.
    let secondComeback = tracker.becameActive(at: at(101))
    #expect(secondComeback == nil)
  }

  @Test func aPageOffScreenDoesNotResumeWithTheApp() {
    var tracker = VerbVisitTracker(source: .tab)
    _ = tracker.appeared(at: at(0))
    _ = tracker.disappeared(at: at(1))
    _ = tracker.enteredBackground(at: at(2))
    let comeback = tracker.becameActive(at: at(3))
    #expect(comeback == nil)
  }

  /// A sheet ends the visit, so that a three-minute Test Me is not counted as reading the page, and
  /// its closing begins a resumed one.
  @Test func aSheetEndsTheVisitAndItsClosingResumesIt() {
    var tracker = VerbVisitTracker(source: .related)
    _ = tracker.appeared(at: at(0))
    let leave = tracker.coveredChanged(true, at: at(4))
    #expect(ended(leave) == ["deepestSection": "header", "dwell": "0-5s"])
    // The app goes to the background and returns under the sheet: still covered.
    let background = tracker.enteredBackground(at: at(60))
    #expect(background == nil)
    let foreground = tracker.becameActive(at: at(90))
    #expect(foreground == nil)
    let comeback = tracker.coveredChanged(false, at: at(184))
    #expect(began(comeback)?.source == .resume)
  }

  @Test func aSheetClosingOverAPageOffScreenBeginsNothing() {
    var tracker = VerbVisitTracker(source: .tab)
    _ = tracker.appeared(at: at(0))
    _ = tracker.coveredChanged(true, at: at(1))
    _ = tracker.disappeared(at: at(2))
    let comeback = tracker.coveredChanged(false, at: at(3))
    #expect(comeback == nil)
  }

  @Test func aSectionOnScreenIsReachedAndAResumedVisitStartsThere() {
    var tracker = VerbVisitTracker(source: .tab)
    _ = tracker.appeared(at: at(0))
    let simple = tracker.sectionVisibilityChanged(.simple, isVisible: true)
    #expect(simple)
    let compound = tracker.sectionVisibilityChanged(.compound, isVisible: true)
    #expect(compound)
    let simpleGone = tracker.sectionVisibilityChanged(.simple, isVisible: false)
    #expect(!simpleGone)
    let leave = tracker.disappeared(at: at(30))
    #expect(ended(leave)?["deepestSection"] == "compound")
    let comeback = tracker.appeared(at: at(40))
    #expect(began(comeback)?.deepestSection == .compound)
  }

  @Test func theRelatedCardIsTheDeepestSection() {
    var tracker = VerbVisitTracker(source: .tab)
    _ = tracker.appeared(at: at(0))
    _ = tracker.sectionVisibilityChanged(.example, isVisible: true)
    _ = tracker.sectionVisibilityChanged(.related, isVisible: true)
    let leave = tracker.disappeared(at: at(30))
    #expect(ended(leave)?["deepestSection"] == "related")
  }

  /// A page opened on a marked form scrolls itself to the form's card. What that shows is not what
  /// the learner reached, until the learner scrolls.
  @Test func theLandingScrollReachesNothing() {
    var tracker = VerbVisitTracker(source: .search)
    tracker.beganLanding()
    _ = tracker.appeared(at: at(0))
    let compound = tracker.sectionVisibilityChanged(.compound, isVisible: true)
    #expect(!compound)
    let etymology = tracker.sectionVisibilityChanged(.etymology, isVisible: true)
    #expect(!etymology)
    #expect(tracker.visibleSections == [.compound, .etymology])
    let leave = tracker.coveredChanged(true, at: at(10))
    #expect(ended(leave)?["deepestSection"] == "header")
    // A visit resumed before the learner scrolls starts from the top too.
    let comeback = tracker.coveredChanged(false, at: at(20))
    #expect(began(comeback)?.deepestSection == .header)

    tracker.learnerScrolled()
    let example = tracker.sectionVisibilityChanged(.example, isVisible: true)
    #expect(example)
    let lastLeave = tracker.disappeared(at: at(30))
    #expect(ended(lastLeave)?["deepestSection"] == "example")
  }

  @Test func aSectionReachedOutsideAVisitIsStillReported() {
    var tracker = VerbVisitTracker(source: .tab)
    let etymology = tracker.sectionVisibilityChanged(.etymology, isVisible: true)
    #expect(etymology)
    #expect(tracker.visit == nil)
  }
}
