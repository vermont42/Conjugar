//
//  LanguageModelServiceDummy.swift
//  Conjugar
//
//  The no-op tutor service used by the unit-test and UI-test worlds, where the
//  real on-device model must not be touched. Always reports unavailable.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

@MainActor
class LanguageModelServiceDummy: LanguageModelService {
  var isAvailable: Bool { false }
  var unavailabilityReason: LanguageModelUnavailability? { .deviceNotEligible }

  func sendTutorMessage(_ message: String) async throws -> String {
    ""
  }

  func resetTutorSession() {}
}
