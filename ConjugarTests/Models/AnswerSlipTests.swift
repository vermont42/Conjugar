//
//  AnswerSlipTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Which wrong answers are slips that earn one more attempt, and which are near misses that are
//  real errors, because they are another cell of the verb.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct AnswerSlipTests {
  @Test(arguments: [
    ("cantaria", "cantaría", true),
    ("ire", "iré", true),
    ("de", "dé", true),
    ("averigue", "averigüé", true),
    ("ensenaria", "enseñaría", true),
    ("tengp", "tengo", true),
    ("teno", "tengo", true),
    ("vivne", "viven", true),
    ("han dicjo", "han dicho", true),
    ("sot", "soy", false),
    ("vas", "van", false),
    ("tengo", "tengo", false),
    ("tenga", "tengo", true),
    ("tengamos", "tengo", false)
  ])
  func slipBetweenSpellings(answer: String, target: String, isSlip: Bool) {
    #expect(AnswerSlip.isSlip(answer, of: target) == isSlip)
  }

  @Test(arguments: [
    ("cantaria", "cantar", DisplayTense.condicional, DisplayPersonNumber.firstSingular),
    ("tengp", "tener", .presenteDeIndicativo, .firstSingular),
    ("yo tengp", "tener", .presenteDeIndicativo, .firstSingular),
    ("ire", "ir", .futuroDeIndicativo, .firstSingular),
    ("ensenaria", "enseñar", .condicional, .thirdSingular),
    ("no hablez", "hablar", .imperativoNegativo, .secondSingularTú),
    ("han dicjo", "decir", .perfectoDeIndicativo, .thirdPlural),
    ("este", "estar", .presenteDeSubjuntivo, .firstSingular),
    ("me arepiento", "arrepentir", .presenteDeIndicativo, .firstSingular),
    ("arrepientete", "arrepentir", .imperativoPositivo, .secondSingularTú),
    ("no hableis", "hablar", .imperativoNegativo, .secondPlural),
    // The vos subjunctive is a standard variant, not a cell the engine writes, so typed for tú it
    // is a slip of hables rather than another cell.
    ("hablés", "hablar", .presenteDeSubjuntivo, .secondSingularTú)
  ])
  func aSlipEarnsAnotherAttempt(answer: String, verb: String, tense: DisplayTense, person: DisplayPersonNumber) {
    #expect(QuizQuestion(verb, tense, person).isSlip(answer), "\(answer) for \(verb), \(tense.rawValue) \(person.rawValue)")
  }

  // Each is near the right answer and wrong for a reason other than typing: another cell of the
  // verb, with its accents or without them, too short for a one-letter slip, or not wrong at all.
  @Test(arguments: [
    ("hablo", "hablar", DisplayTense.pretérito, DisplayPersonNumber.thirdSingular),
    ("canto", "cantar", .pretérito, .thirdSingular),
    ("hable", "hablar", .pretérito, .firstSingular),
    ("hablé", "hablar", .presenteDeSubjuntivo, .firstSingular),
    ("comio", "comer", .pretérito, .firstSingular),
    ("enseno", "enseñar", .pretérito, .thirdSingular),
    ("hablas", "hablar", .presenteDeIndicativo, .thirdSingular),
    ("hablar", "hablar", .presenteDeIndicativo, .thirdPlural),
    ("sot", "ser", .presenteDeIndicativo, .firstSingular),
    ("hablo", "hablar", .presenteDeIndicativo, .firstSingular),
    ("zzzz", "hablar", .presenteDeIndicativo, .firstSingular)
  ])
  func notASlip(answer: String, verb: String, tense: DisplayTense, person: DisplayPersonNumber) {
    #expect(!QuizQuestion(verb, tense, person).isSlip(answer), "\(answer) for \(verb), \(tense.rawValue) \(person.rawValue)")
  }
}
