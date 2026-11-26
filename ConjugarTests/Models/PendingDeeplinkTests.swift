//
//  PendingDeeplinkTests.swift
//  ConjugarTests
//
//  The stash through which the controls and the shortcuts open a page: a link drains once, and
//  one older than a minute is removed unopened. Each test has a defaults suite of its own.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct PendingDeeplinkTests {
  private let link = URL(string: "conjugar://verb/random?source=shortcut")!
  private let written = Date(timeIntervalSinceReferenceDate: 800_000_000)

  /// A suite of its own, emptied, so that no test reads another's stash or the app's.
  private func defaults() throws -> UserDefaults {
    let name = "PendingDeeplinkTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defaults.removePersistentDomain(forName: name)
    return defaults
  }

  @Test func aFreshLinkDrainsOnce() throws {
    let defaults = try defaults()
    PendingDeeplink.stash(link, in: defaults, at: written)
    #expect(PendingDeeplink.drain(from: defaults, at: written.addingTimeInterval(5)) == link)
    #expect(PendingDeeplink.drain(from: defaults, at: written.addingTimeInterval(6)) == nil)
  }

  @Test func aLinkIsGoodForAMinute() throws {
    let defaults = try defaults()
    PendingDeeplink.stash(link, in: defaults, at: written)
    #expect(PendingDeeplink.drain(from: defaults, at: written.addingTimeInterval(PendingDeeplink.lifetime)) == link)
  }

  @Test(arguments: [61.0, 3_600.0, 259_200.0, -61.0] as [TimeInterval])
  func anOlderLinkIsRemovedUnopened(age: TimeInterval) throws {
    let defaults = try defaults()
    PendingDeeplink.stash(link, in: defaults, at: written)
    #expect(PendingDeeplink.drain(from: defaults, at: written.addingTimeInterval(age)) == nil)
    #expect(defaults.object(forKey: WidgetConstants.pendingDeeplinkKey) == nil)
  }

  @Test func aLaterStashReplacesAnEarlierOne() throws {
    let defaults = try defaults()
    let later = URL(string: "conjugar://quiz/start")!
    PendingDeeplink.stash(link, in: defaults, at: written)
    PendingDeeplink.stash(later, in: defaults, at: written.addingTimeInterval(10))
    #expect(PendingDeeplink.drain(from: defaults, at: written.addingTimeInterval(11)) == later)
  }

  // Builds before 2026-11-26 stashed the bare string, with no date to judge its age by.
  @Test func anUndatedStashIsRemovedUnopened() throws {
    let defaults = try defaults()
    defaults.set(link.absoluteString, forKey: WidgetConstants.pendingDeeplinkKey)
    #expect(PendingDeeplink.drain(from: defaults, at: written) == nil)
    #expect(defaults.object(forKey: WidgetConstants.pendingDeeplinkKey) == nil)
  }

  @Test func nothingStashedDrainsNothing() throws {
    #expect(PendingDeeplink.drain(from: try defaults(), at: written) == nil)
    #expect(PendingDeeplink.drain(from: nil, at: written) == nil)
  }
}
