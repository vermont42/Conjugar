//
//  LanguageModelService.swift
//  Conjugar
//
//  The conjugation-tutor service seam. `LanguageModelServiceReal` wraps Apple's
//  on-device `SystemLanguageModel`; `LanguageModelServiceDummy` is the
//  test/unavailable double. `TutorView` talks to `Current.languageModelService`.
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
  // Poll availability until the model becomes available or the calling task is
  // cancelled. Driven from a view's `.task` (the Info-tab tutor entry point), so it is
  // scoped to that screen's lifetime and auto-cancels on disappear — safe to run from
  // more than one view at once, with no start/stop pairing to get wrong.
  func monitorAvailability() async
}

enum LanguageModelServiceError: Error {
  case sessionUnavailable
}
