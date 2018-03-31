//
//  ConjugatorError.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/2/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

enum ConjugatorError: Error {
  case tooShort
  case invalidEnding(String)
  case tenseNotImplemented(Tense)
  case noSuchConjugation(PersonNumber)
  case personNumberAbsent(Tense)
  case defectiveForPersonNumber(PersonNumber)
  case noFirstPersonSingularImperative
}
