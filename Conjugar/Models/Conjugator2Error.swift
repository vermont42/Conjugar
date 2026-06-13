//
//  Conjugator2Error.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Errors from the new composition engine. Suffixed `2` while it lives alongside
// the old `ConjugatorError`.
enum Conjugator2Error: Error, Equatable {
  /// Infinitive shorter than the smallest valid Spanish infinitive ("ir").
  case infinitiveTooShort
  /// Infinitive does not end in -ar, -er, or -ir/-ír. Associated value is the ending.
  case invalidInfinitiveEnding(String)
  /// The requested affirmative-imperative person has no form in the regular
  /// paradigm yet (usted/nosotros/ustedes are derived from the subjunctive in a
  /// later phase).
  case imperativeNotAvailable(PersonNumber2)
}
