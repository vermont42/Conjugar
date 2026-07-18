//
//  AnalyticsReal.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import TelemetryDeck

// `nonisolated` opts the class out of the module's default main-actor isolation and
// `@unchecked Sendable` lets it be captured in the GCD closures below; `isInitialized`
// is safe because it is only ever read/written on the serial `queue`.
nonisolated final class AnalyticsReal: Analytics, @unchecked Sendable {
  // All TelemetryDeck calls are funneled onto this plain GCD serial queue rather
  // than being made directly from the @MainActor call sites (ConjugarApp.init,
  // view onAppear, Quiz, GameState, GameCenterReal). TelemetryDeck 2.14.1 uses
  // blocking DispatchQueue.sync / .sync(flags: .barrier) internally (SignalCache,
  // TelemetryClient, SignalManager, DurationSignalTracker), so calling it from the
  // main actor runs that blocking work on the main thread. Dispatching to a
  // background serial queue keeps the main thread unblocked, keeps initialize
  // ordered ahead of signals, and confines `isInitialized` to a single thread.
  private let queue = DispatchQueue(label: "biz.joshadams.Conjugar.analytics")
  private var isInitialized = false // only ever touched on `queue`

  func initialize(appID: String) {
    guard !appID.isEmpty else {
      return
    }
    queue.async {
      TelemetryDeck.initialize(config: TelemetryDeck.Config(appID: appID))
      self.isInitialized = true
    }
  }

  func signal(name: AnalyticsName, parameters: [String: String]) {
    queue.async {
      guard self.isInitialized else {
        return
      }
      TelemetryDeck.signal(name.rawValue, parameters: parameters)
    }
  }
}
