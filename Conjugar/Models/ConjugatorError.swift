//
//  ConjugatorError.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Errors from the conjugation engine.
enum ConjugatorError: Error, Equatable {
  /// Infinitive shorter than the smallest valid Spanish infinitive ("ir").
  case infinitiveTooShort
  /// Infinitive does not end in -ar, -er, or -ir/-ír. Associated value is the ending.
  case invalidInfinitiveEnding(String)
  /// The requested affirmative-imperative person has no form in the regular
  /// paradigm yet (usted/nosotros/ustedes are derived from the subjunctive in a
  /// later phase). Retained as the safety fallback for the derivation; in Phase 5
  /// every non-defective imperative person now resolves.
  case imperativeNotAvailable(EnginePersonNumber)
  /// The requested slot has **no form at all** for this verb — a *defective*
  /// verb (Phase 5, taxonomy §5 abolir: only the slots whose post-stem vowel is
  /// -i-/-ie-/-io- exist). Associated value is the missing slot.
  case noForm(EngineTense)
}
