//
//  AnswerDifferenceTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Which letters a held correction marks, and which right answer it shows.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct AnswerDifferenceTests {
  private func marked(_ text: String, _ marks: [Bool]) -> String {
    String(zip(Array(text), marks).compactMap { $1 ? $0 : nil })
  }

  @Test func anAccentIsADifference() {
    let difference = AnswerDifference.between(given: "hablo", expected: "habló")
    #expect(marked(difference.given, difference.givenMarks) == "o")
    #expect(marked(difference.expected, difference.expectedMarks) == "ó")
    #expect(difference.expectedMarkedLetters == ["ó"])
  }

  @Test func aRedLetterIsNotADifferenceForBeingACapital() {
    let difference = AnswerDifference.between(given: "tengo", expected: "tenGo")
    #expect(!difference.givenMarks.contains(true))
    #expect(!difference.expectedMarks.contains(true))
  }

  @Test func aMissingLetterIsMarkedOnlyInTheRightAnswer() {
    let difference = AnswerDifference.between(given: "arepiento", expected: "arrepiento")
    #expect(!difference.givenMarks.contains(true))
    #expect(marked(difference.expected, difference.expectedMarks) == "r")
  }

  @Test func anExtraLetterIsMarkedOnlyInTheLearnersAnswer() {
    let difference = AnswerDifference.between(given: "tenggo", expected: "tenGo")
    #expect(marked(difference.given, difference.givenMarks) == "g")
    #expect(!difference.expectedMarks.contains(true))
  }

  @Test func aSwapMarksBothLettersOnBothSides() {
    let difference = AnswerDifference.between(given: "hbalo", expected: "hablo")
    #expect(marked(difference.given, difference.givenMarks) == "ba")
    #expect(marked(difference.expected, difference.expectedMarks) == "ab")
  }

  @Test func aWrongStemIsMarkedLetterByLetter() {
    let difference = AnswerDifference.between(given: "teno", expected: "tenGo")
    #expect(!difference.givenMarks.contains(true))
    #expect(marked(difference.expected, difference.expectedMarks) == "G")
    #expect(difference.expectedMarkedLetters == ["g"])
  }

  @Test func theCorrectionDropsAPronounAsGradingDoes() {
    let difference = QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular).difference(from: "yo hablé")
    #expect(difference.given == "hablé")
    #expect(difference.expected.lowercased() == "hablo")
    #expect(marked(difference.given, difference.givenMarks) == "é")
  }

  @Test func theCorrectionShowsTheNearestRightAnswer() {
    // A reflexive-only verb's bare form is nearer than the form with its pronoun.
    let reflexive = QuizQuestion("arrepentir", .presenteDeIndicativo, .firstSingular).difference(from: "arepiento")
    #expect(reflexive.expected.lowercased() == "arrepiento")
    // freído and frito are both right, and freido is one accent from freído.
    let participle = QuizQuestion("freír", .participio, .none).difference(from: "freido")
    #expect(participle.expected.lowercased() == "freído")
    // frite is nearer frito.
    let other = QuizQuestion("freír", .participio, .none).difference(from: "frite")
    #expect(other.expected.lowercased() == "frito")
  }

  @Test func theCorrectionKeepsTheEnginesRedLetters() {
    let difference = QuizQuestion("tener", .presenteDeIndicativo, .firstSingular).difference(from: "teno")
    #expect(difference.expected == QuizQuestion("tener", .presenteDeIndicativo, .firstSingular).writtenAnswer)
    let hasRedLetter = difference.expected.contains { $0.isUppercase }
    #expect(hasRedLetter)
  }

  @Test func aNegativeCommandsNoIsNotADifference() {
    let question = QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú)
    let difference = question.difference(from: question.answer(filling: "hablas"))
    #expect(difference.given == "no hablas")
    #expect(difference.expected.lowercased() == "no hables")
    #expect(marked(difference.given, difference.givenMarks) == "a")
    #expect(marked(difference.expected, difference.expectedMarks).lowercased() == "e")
  }

  @Test func shownSpellingsLeadWithTheWrittenAnswerAndMatchTheAcceptedAnswers() {
    for question in [
      QuizQuestion("freír", .participio, .none),
      QuizQuestion("arrepentir", .presenteDeIndicativo, .firstSingular),
      QuizQuestion("reír", .pretérito, .thirdSingular)
    ] {
      #expect(question.shownSpellings.first == question.writtenAnswer)
      #expect(question.shownSpellings.map { $0.lowercased() } == question.acceptedAnswers)
    }
  }
}
