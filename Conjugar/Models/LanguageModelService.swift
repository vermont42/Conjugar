//
//  LanguageModelService.swift
//  Conjugar
//
//  The conjugation-tutor service seam, ported from Conjuguer (French) and adapted
//  for Spanish. `LanguageModelServiceReal` wraps Apple's on-device
//  `SystemLanguageModel`; `LanguageModelServiceDummy` is the test/unavailable
//  double. `TutorView` talks to `Current.languageModelService`.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

// Why the on-device model is not usable, mapped from `SystemLanguageModel.Availability`.
nonisolated enum LanguageModelUnavailability: Equatable {
  case appleIntelligenceNotEnabled
  case deviceNotEligible
  case modelNotReady
  case unknown
}

// One turn in the tutor conversation. `Sendable`/`Codable` so it can be persisted
// (see `TutorChatHistory`) and carried across the async `sendTutorMessage` boundary.
nonisolated struct TutorMessage: Codable, Identifiable, Sendable {
  let id: UUID
  let role: Role
  let content: String
  let timestamp: Date

  enum Role: Codable, Sendable {
    case assistant
    case user
  }

  init(role: Role, content: String) {
    self.id = UUID()
    self.role = role
    self.content = content
    self.timestamp = Date()
  }
}

@MainActor
protocol LanguageModelService {
  var isAvailable: Bool { get }
  var unavailabilityReason: LanguageModelUnavailability? { get }
  func sendTutorMessage(_ message: String) async throws -> String
  func resetTutorSession()
  // Start/stop the live availability poll. Scoped to when the Info-tab tutor entry
  // point is on screen, rather than running for the whole app lifetime (item 15):
  // `InfoBrowseView` starts it on appear and stops it on disappear.
  func startAvailabilityMonitoring()
  func stopAvailabilityMonitoring()
}

enum LanguageModelServiceError: Error {
  case sessionUnavailable
}
