//
//  AnswerFrameTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The shape of each kind of quiz answer, and the answer that a filled blank gives.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct AnswerFrameTests {
  private func frame(_ verb: String, _ tense: DisplayTense, _ person: DisplayPersonNumber = .none) -> [AnswerFrame.Segment] {
    QuizQuestion(verb, tense, person).frame.segments
  }

  @Test(arguments: [
    (DisplayPersonNumber.firstSingular, "yo"),
    (.secondSingularTú, "tú"),
    (.secondSingularVos, "vos"),
    (.thirdSingular, "él"),
    (.firstPlural, "nosotros"),
    (.secondPlural, "vosotros"),
    (.thirdPlural, "ellas")
  ])
  func aFiniteFormTakesItsSubjectPronoun(person: DisplayPersonNumber, pronoun: String) {
    #expect(frame("hablar", .presenteDeIndicativo, person) == [.pronoun(pronoun), .blank])
    #expect(frame("hablar", .pluscuamperfectoDeSubjuntivo2, person) == [.pronoun(pronoun), .blank])
  }

  @Test(arguments: [
    (DisplayPersonNumber.secondSingularTú, "tú"),
    (.secondSingularVos, "vos"),
    (.thirdSingular, "usted"),
    (.firstPlural, "nosotros"),
    (.secondPlural, "vosotros"),
    (.thirdPlural, "ustedes")
  ])
  func aCommandNamesWhomItAddresses(person: DisplayPersonNumber, addressee: String) {
    #expect(frame("hablar", .imperativoPositivo, person) == [.addressee(addressee), .punctuation("¡"), .blank, .punctuation("!")])
    #expect(frame("hablar", .imperativoNegativo, person) == [.addressee(addressee), .punctuation("¡"), .word("no"), .blank, .punctuation("!")])
  }

  @Test func theGerundioAndParticipioTakeNothing() {
    #expect(frame("hablar", .gerundio) == [.blank])
    #expect(frame("hablar", .participio) == [.blank])
    #expect(frame("arrepentir", .gerundio) == [.blank])
  }

  @Test func aReflexiveOnlyVerbsPronounStandsWhereSpanishPutsIt() {
    #expect(frame("arrepentir", .presenteDeIndicativo, .firstSingular) == [.pronoun("yo"), .word("me"), .blank])
    #expect(frame("arrepentir", .perfectoDeIndicativo, .firstPlural) == [.pronoun("nosotros"), .word("nos"), .blank])
    #expect(frame("arrepentir", .imperativoNegativo, .secondSingularTú) == [.addressee("tú"), .punctuation("¡"), .word("no"), .word("te"), .blank, .punctuation("!")])
    // The enclitic is part of the answer: arrepiéntete.
    #expect(frame("arrepentir", .imperativoPositivo, .secondSingularTú) == [.addressee("tú"), .punctuation("¡"), .blank, .punctuation("!")])
  }

  @Test func theFrameSplitsAroundItsBlank() {
    let negative = QuizQuestion("hablar", .imperativoNegativo, .thirdSingular).frame
    #expect(negative.leading == [.addressee("usted"), .punctuation("¡"), .word("no")])
    #expect(negative.trailing == [.punctuation("!")])
    #expect(negative.spokenParts == ["usted", "no", nil])
    let bare = QuizQuestion("hablar", .gerundio, .none).frame
    #expect(bare.leading.isEmpty)
    #expect(bare.trailing.isEmpty)
    #expect(bare.spokenParts == [nil])
  }

  private func answer(_ blank: String, _ verb: String, _ tense: DisplayTense, _ person: DisplayPersonNumber = .none) -> String {
    QuizQuestion(verb, tense, person).answer(filling: blank)
  }

  private func grade(_ blank: String, _ verb: String, _ tense: DisplayTense, _ person: DisplayPersonNumber = .none) -> ConjugationResult {
    let question = QuizQuestion(verb, tense, person)
    return question.grade(question.answer(filling: blank))
  }

  @Test func aNegativeCommandsNoIsSupplied() {
    #expect(answer("hables", "hablar", .imperativoNegativo, .secondSingularTú) == "no hables")
    #expect(grade("hables", "hablar", .imperativoNegativo, .secondSingularTú) == .totalMatch)
  }

  @Test func wordsTheFrameSuppliesAreNotDoubled() {
    #expect(answer("no hables", "hablar", .imperativoNegativo, .secondSingularTú) == "no hables")
    #expect(answer("No  hables", "hablar", .imperativoNegativo, .secondSingularTú) == "no hables")
    #expect(answer("arrepientas", "arrepentir", .imperativoNegativo, .secondSingularTú) == "no te arrepientas")
    #expect(answer("te arrepientas", "arrepentir", .imperativoNegativo, .secondSingularTú) == "no te arrepientas")
    #expect(answer("no te arrepientas", "arrepentir", .imperativoNegativo, .secondSingularTú) == "no te arrepientas")
    #expect(answer("me arrepiento", "arrepentir", .presenteDeIndicativo, .firstSingular) == "me arrepiento")
  }

  @Test func aSubjectPronounTypedIntoTheBlankIsStillRight() {
    #expect(grade("yo hablo", "hablar", .presenteDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("ustedes hablan", "hablar", .presenteDeIndicativo, .thirdPlural) == .totalMatch)
    #expect(answer("yo me arrepiento", "arrepentir", .presenteDeIndicativo, .firstSingular) == "me arrepiento")
    #expect(grade("yo me arrepiento", "arrepentir", .presenteDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("tú hablo", "hablar", .presenteDeIndicativo, .firstSingular) == .noMatch)
  }

  @Test func theFramesPunctuationTypedIntoTheBlankIsDropped() {
    #expect(answer("¡habla!", "hablar", .imperativoPositivo, .secondSingularTú) == "habla")
    #expect(grade("¡hables!", "hablar", .imperativoNegativo, .secondSingularTú) == .totalMatch)
  }

  @Test func aReflexiveOnlyVerbIsRightWithOrWithoutItsPronoun() {
    #expect(grade("arrepiento", "arrepentir", .presenteDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("hemos arrepentido", "arrepentir", .perfectoDeIndicativo, .firstPlural) == .totalMatch)
    #expect(grade("arrepiéntete", "arrepentir", .imperativoPositivo, .secondSingularTú) == .totalMatch)
    #expect(grade("arrepienta", "arrepentir", .imperativoNegativo, .thirdSingular) == .totalMatch)
  }

  @Test func aCompoundTenseIsTypedWhole() {
    #expect(grade("he hablado", "hablar", .perfectoDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("hablado", "hablar", .perfectoDeIndicativo, .firstSingular) == .noMatch)
  }

  @Test func aMissingAccentIsStillNotRight() {
    #expect(grade("hableis", "hablar", .imperativoNegativo, .secondPlural) == .noMatch)
  }

  /// Every cell the quiz can ask has a frame with one blank, and the written answer typed into
  /// that blank is right.
  @Test func everyCellsWrittenAnswerFillsItsFrame() {
    let verbs = ["hablar", "tener", "ir", "arrepentir", "reír"]
    for verb in verbs {
      for tense in DisplayTense.conjugatedTenses {
        let persons: [DisplayPersonNumber] = tense == .gerundio || tense == .participio
          ? [.none]
          : DisplayPersonNumber.allCases.filter { $0 != .none }
        for person in persons {
          let question = QuizQuestion(verb, tense, person)
          guard let written = question.writtenAnswer?.lowercased() else {
            continue
          }
          #expect(question.frame.segments.filter { $0 == .blank }.count == 1)
          let typed = Self.blankPart(of: written, frame: question.frame)
          #expect(question.grade(question.answer(filling: typed)) == .totalMatch, "\(verb) \(tense) \(person): \(typed)")
        }
      }
    }
  }

  /// The written answer without the words the frame supplies in front of the blank.
  private static func blankPart(of written: String, frame: AnswerFrame) -> String {
    var words = written.split(separator: " ").map(String.init)
    for segment in frame.leading {
      if case .word(let word) = segment, words.first == word {
        words.removeFirst()
      }
    }
    return words.joined(separator: " ")
  }
}
