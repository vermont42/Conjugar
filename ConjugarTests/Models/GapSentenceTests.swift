//
//  GapSentenceTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Complete the Sentence: the machine check that confirms every authored sentence against the
//  engine, in tú and vos and in both regions; frames, tokens, and grading in a sentence; the draw;
//  and a round in the quiz.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct GapSentenceTests {
  private func makeQuiz(
    level: QuizLevel = .beginner,
    secondSingular: SecondSingularQuiz = .tu,
    region: Region = .spain,
    practice: PracticeStore = PracticeStore(getterSetter: GetterSetterFake()),
    seed: UInt64 = 5
  ) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: region.rawValue,
      Settings.secondSingularQuizKey: secondSingular.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: true, randomSource: SplitMix64(seed: seed), practice: practice)
  }

  private func sentence(_ id: String) throws -> GapSentence {
    try #require(GapSentences.all.first { $0.id == id })
  }

  private func made(verb: String, tense: String, person: String?, es: String, reviewed: Bool = false) -> GapSentence {
    var object: [String: Any] = ["id": "\(verb).\(tense).1", "verb": verb, "tense": tense, "es": es, "en": "An English line.", "reviewed": reviewed]
    if let person {
      object["person"] = person
    }
    let data = (try? JSONSerialization.data(withJSONObject: [object])) ?? Data()
    return GapSentences.decode(data).first ?? GapSentence.unreadable
  }

  /// Words a second-person singular sentence may not use, since it is asked in vos too, and words
  /// of vosotros, which no sentence uses.
  private static let forbiddenInSecondSingular: Set<String> = ["tú", "ti", "contigo"]
  private static let vosotrosWords: Set<String> = ["vosotros", "vosotras", "os", "vuestro", "vuestra", "vuestros", "vuestras"]

  private static func words(of text: String) -> [String] {
    text.lowercased().split { !$0.isLetter }.map(String.init)
  }

  /// What is wrong with a sentence, or nothing. The machine check.
  private func problems(_ sentence: GapSentence) -> [String] {
    var problems: [String] = []
    guard VerbMap.shared.entry(for: sentence.verb) != nil else {
      return ["\(sentence.id): \(sentence.verb) is not in the verb map"]
    }
    guard let tense = sentence.displayTense else {
      return ["\(sentence.id): \(sentence.tense) names no tense"]
    }
    guard let written = sentence.writtenPersonNumber else {
      return ["\(sentence.id): \(sentence.person ?? "") names no person"]
    }
    if !sentence.id.hasPrefix("\(sentence.verb).\(sentence.tense).") {
      problems.append("\(sentence.id): the id does not begin with its verb and tense")
    }
    if (tense == .gerundio || tense == .participio) != (written == .none) {
      problems.append("\(sentence.id): only a gerundio or participio has no person")
    }
    if written == .secondSingularVos || written == .secondPlural {
      problems.append("\(sentence.id): a sentence is written in tú, never vos or vosotros")
    }
    if sentence.es.filter({ $0 == "{" }).count != 1 || sentence.es.filter({ $0 == "}" }).count != 1 || sentence.blankText?.isEmpty != false {
      problems.append("\(sentence.id): a sentence has one pair of braces around its answer")
    }
    if sentence.en.isEmpty {
      problems.append("\(sentence.id): no English")
    }
    if tense == .imperfectoDeSubjuntivo2 || tense == .pluscuamperfectoDeSubjuntivo2 {
      problems.append("\(sentence.id): a sentence is written with the -ra form")
    }
    let words = Set(Self.words(of: sentence.es))
    if !words.isDisjoint(with: Self.vosotrosWords) {
      problems.append("\(sentence.id): a word of vosotros")
    }
    if written == .secondSingularTú, !words.isDisjoint(with: Self.forbiddenInSecondSingular) {
      problems.append("\(sentence.id): a second-person sentence names tú, which vos would not")
    }
    if !GapSentences.askable(at: .advanced, from: [sentence], includesDrafts: true).contains(sentence) {
      problems.append("\(sentence.id): no level asks it")
    }
    for secondSingular in [DisplayPersonNumber.secondSingularTú, .secondSingularVos] {
      guard let question = QuizQuestion.sentence(sentence, secondSingular: secondSingular) else {
        problems.append("\(sentence.id): no question in \(secondSingular)")
        continue
      }
      guard let engine = question.writtenAnswer else {
        problems.append("\(sentence.id): the engine gives no form in \(secondSingular)")
        continue
      }
      guard sentence.frame(personNumber: question.personNumber) != nil else {
        problems.append("\(sentence.id): the words the frame supplies (\(question.frame.leading)) do not stand before the braces")
        continue
      }
      // The braces are the tú form, so in vos they are checked only for the frame.
      if secondSingular == .secondSingularTú || written != .secondSingularTú {
        if sentence.writtenAnswer?.lowercased() != engine.lowercased() {
          problems.append("\(sentence.id): {\(sentence.blankText ?? "")} gives \(sentence.writtenAnswer ?? "nothing"), but the engine writes \(engine.lowercased())")
        }
      }
    }
    // A word of the sentence that is a tú form alone (tienes, puedes) would read wrong to a
    // learner whose setting is vos. Commands are left out, since sal, ten, and ven are words too.
    for word in Self.words(of: sentence.es.replacingOccurrences(of: "{\(sentence.blankText ?? "")}", with: " ")) {
      let cells = ConjugationMap.bundled.entries(for: word).flatMap(\.cells).filter { !$0.tense.isCommand }
      if !cells.isEmpty, cells.allSatisfy({ $0.personNumber == .secondSingularTú }) {
        problems.append("\(sentence.id): \(word) is a tú form, which vos would not use")
      }
    }
    return problems
  }

  // The machine check

  @Test func everySentencePassesTheMachineCheck() {
    #expect(GapSentences.all.count >= 100)
    let problems = GapSentences.all.flatMap(problems)
    #expect(problems.isEmpty, "\(problems.joined(separator: "\n"))")
  }

  @Test func theIdsAreUniqueAndTheFixtureNamesRealOnes() {
    let ids = GapSentences.all.map(\.id)
    #expect(Set(ids).count == ids.count)
    #expect(Set(Quiz.sentencesFixtureIDs).isSubset(of: ids))
    #expect(makeQuiz().sentencesFixture().count == Quiz.sentencesFixtureIDs.count)
  }

  @Test func theMachineCheckCatchesABrokenSentence() {
    // A misspelled blank, a missing "no", tú named in a second-person sentence, vosotros, a
    // tú form in the words around the blank, and the -se form.
    #expect(!problems(made(verb: "tener", tense: "presenteDeIndicativo", person: "ss", es: "¿Cuántos años {tenes}?")).isEmpty)
    #expect(!problems(made(verb: "ir", tense: "imperativoNegativo", person: "ss", es: "¡{Vayas} solo!")).isEmpty)
    #expect(!problems(made(verb: "tener", tense: "presenteDeIndicativo", person: "ss", es: "¿Y tú {tienes} hambre?")).isEmpty)
    #expect(!problems(made(verb: "tener", tense: "presenteDeIndicativo", person: "sp", es: "¿{Tenéis} hambre?")).isEmpty)
    #expect(!problems(made(verb: "tener", tense: "presenteDeIndicativo", person: "fs", es: "Yo {tengo} lo que quieres.")).isEmpty)
    #expect(!problems(made(verb: "tener", tense: "imperfectoDeSubjuntivo2", person: "fs", es: "Si yo {tuviese} tiempo, iría.")).isEmpty)
    #expect(!problems(made(verb: "tener", tense: "presenteDeIndicativo", person: "fs", es: "Yo {tengo} dos {hermanos}.")).isEmpty)
    #expect(problems(made(verb: "tener", tense: "presenteDeIndicativo", person: "fs", es: "Yo {tengo} dos hermanos.")).isEmpty)
  }

  @Test func theTwentyFiveMostFrequentVerbsHaveFourSentencesOrMore() {
    let verbs = VerbMap.shared.entries.values.filter { $0.frequencyRank <= 25 }.map(\.infinitive)
    #expect(verbs.count == 25)
    for verb in verbs {
      let count = GapSentences.all.filter { $0.verb == verb }.count
      #expect(count >= 4, "\(verb) has \(count)")
    }
  }

  @Test func everyLevelAsksSentencesAndBeginnerOnlyItsTenses() {
    for level in QuizLevel.allCases {
      let askable = GapSentences.askable(at: level, includesDrafts: true)
      #expect(askable.count >= 25, "\(level) asks \(askable.count)")
      let tenses = Set(level.pool.map(\.tense))
      #expect(askable.allSatisfy { $0.displayTense.map(tenses.contains) == true })
    }
    let beginner = GapSentences.askable(at: .beginner, includesDrafts: true)
    #expect(Set(beginner.map(\.verb)).count == 25)
  }

  // Frames, tokens, and grading

  @Test func aNegativeCommandsNoIsSuppliedAndTheAddresseeNamed() throws {
    let vayas = try sentence("ir.imperativoNegativo.1")
    #expect(vayas.frame(personNumber: .secondSingularTú)?.segments == [.addressee("tú"), .context("¡"), .word("No"), .blank, .context(" solo de noche!")])
    #expect(vayas.frame(personNumber: .secondSingularVos)?.segments.first == .addressee("vos"))
    #expect(vayas.frame(personNumber: .secondSingularTú)?.sentenceTokens == [
      .addressee("tú"), .answerWord("¡No"), .blank(leading: "", trailing: ""), .word("solo"), .word("de"), .word("noche!")
    ])
    let question = try #require(QuizQuestion.sentence(vayas, secondSingular: .secondSingularTú))
    #expect(question.answer(filling: "vayas") == "no vayas")
    #expect(question.answer(filling: "no vayas") == "no vayas")
    #expect(question.grade(question.answer(filling: "vayas")) == .totalMatch)
  }

  @Test func marksWrittenAgainstTheBlankTravelWithIt() throws {
    let tienes = try sentence("tener.presenteDeIndicativo.1")
    #expect(tienes.frame(personNumber: .secondSingularTú)?.sentenceTokens == [
      .addressee("tú"), .word("¿Cuántos"), .word("años"), .blank(leading: "", trailing: "?")
    ])
    let puedes = try sentence("poder.presenteDeIndicativo.2")
    #expect(puedes.frame(personNumber: .secondSingularTú)?.sentenceTokens.dropFirst().first == .blank(leading: "¿", trailing: ""))
    let pase = try sentence("pasar.imperativoPositivo.1")
    #expect(pase.frame(personNumber: .thirdSingular)?.sentenceTokens.prefix(2) == [.addressee("usted"), .blank(leading: "", trailing: ",")])
  }

  @Test func onlyACommandOrTheSecondPersonSingularNamesItsPerson() throws {
    let somos = try sentence("ser.presenteDeIndicativo.1")
    #expect(somos.frame(personNumber: .firstPlural)?.segments == [.context("Mi hermana y yo "), .blank, .context(" de Chile.")])
    let siguiendo = try sentence("seguir.gerundio.1")
    #expect(siguiendo.frame(personNumber: .none)?.segments.first == .context("Estoy "))
  }

  @Test func aSecondPersonSentenceAsksTuOrVos() throws {
    let tienes = try sentence("tener.presenteDeIndicativo.1")
    let tu = try #require(QuizQuestion.sentence(tienes, secondSingular: .secondSingularTú))
    let vos = try #require(QuizQuestion.sentence(tienes, secondSingular: .secondSingularVos))
    #expect(tu.personNumber == .secondSingularTú)
    #expect(vos.personNumber == .secondSingularVos)
    #expect(vos.grade("tenés") == .totalMatch)
    #expect(vos.grade("tienes") == .noMatch)
    let somos = try sentence("ser.presenteDeIndicativo.1")
    #expect(QuizQuestion.sentence(somos, secondSingular: .secondSingularVos)?.personNumber == .firstPlural)
  }

  @Test func eitherImperfectSubjunctiveIsRightInASentenceAlone() throws {
    let tuviera = try #require(QuizQuestion.sentence(try sentence("tener.imperfectoDeSubjuntivo1.1"), secondSingular: .secondSingularTú))
    #expect(tuviera.grade("tuviera") == .totalMatch)
    #expect(tuviera.grade("tuviese") == .totalMatch)
    #expect(tuviera.shownSpellings.first?.lowercased() == "tuviera")
    let hubiera = try #require(QuizQuestion.sentence(try sentence("hablar.pluscuamperfectoDeSubjuntivo1.1"), secondSingular: .secondSingularTú))
    #expect(hubiera.grade("hubiese hablado") == .totalMatch)
    #expect(QuizQuestion("tener", .imperfectoDeSubjuntivo1, .firstSingular).grade("tuviese") == .noMatch)
    #expect(DisplayTense.imperfectoDeSubjuntivo1.sentenceDisplayName == "imperfecto de subjuntivo")
    #expect(DisplayTense.presenteDeSubjuntivo.sentenceDisplayName == "presente de subjuntivo")
  }

  @Test func theCompletedSentenceCapitalizesABlankThatOpensIt() throws {
    #expect(try sentence("tener.imperativoPositivo.1").completed(with: "tené") == "Tené cuidado con el perro.")
    #expect(try sentence("poder.presenteDeIndicativo.2").completed(with: "podés") == "¿Podés cerrar la ventana, por favor?")
    #expect(try sentence("ser.presenteDeIndicativo.1").completed(with: "somos") == "Mi hermana y yo somos de Chile.")
  }

  @Test func aDiagnosisStillNamesAnErrorInASentence() throws {
    let question = try #require(QuizQuestion.sentence(try sentence("hacer.perfectoDeIndicativo.1"), secondSingular: .secondSingularTú))
    #expect(question.diagnosis(of: question.answer(filling: "he hacido")) != nil)
  }

  @Test func draftsAreLeftOutOfReleaseBuilds() {
    let draft = made(verb: "tener", tense: "presenteDeIndicativo", person: "fs", es: "Yo {tengo} dos hermanos.")
    let reviewed = made(verb: "tener", tense: "presenteDeIndicativo", person: "fs", es: "Yo {tengo} dos hermanos.", reviewed: true)
    #expect(GapSentences.askable(at: .beginner, from: [draft, reviewed], includesDrafts: false) == [reviewed])
    #expect(GapSentences.askable(at: .beginner, from: [draft, reviewed], includesDrafts: true).count == 2)
  }

  // The draw

  @Test func aRoundTakesOneSentenceAVerbAndTheUnaskedFirst() {
    var generator = SplitMix64(seed: 3)
    let candidates = GapSentences.askable(at: .advanced, includesDrafts: true)
    let round = QuizDraw.sentences(from: candidates, count: 10, excluded: [], using: &generator)
    #expect(round.count == 10)
    #expect(Set(round.map(\.verb)).count == 10)
    let next = QuizDraw.sentences(from: candidates, count: 10, excluded: Set(round.map(\.id)), using: &generator)
    #expect(Set(next.map(\.id)).isDisjoint(with: round.map(\.id)))
    let short = QuizDraw.sentences(from: Array(candidates.prefix(3)), count: 10, excluded: [], using: &generator)
    #expect(short.count == 3)
  }

  @Test func theScopeIsUnrankedAndContinues() {
    let scope = QuizScope.sentences()
    #expect(scope.isSentences)
    #expect(scope.source == .sentences)
    #expect(scope.questionCount == 10)
    #expect(!scope.isRanked)
    #expect(!scope.mixesDueItems)
    #expect(scope.continues)
    #expect(scope.sendsQuestionCounts)
    #expect(scope.startsLiveActivity)
    #expect(LastQuizResult.Kind(scope: scope) == .sentences)
  }

  // A round

  @Test func aBeginnerRoundAsksTenSentencesOfItsTensesFromTenVerbs() {
    let quiz = makeQuiz(region: .latinAmerica)
    #expect(quiz.start(scope: .sentences()))
    #expect(quiz.questions.count == 10)
    let tenses = Set(QuizLevel.beginner.pool.map(\.tense))
    #expect(quiz.questions.allSatisfy { $0.sentence != nil && tenses.contains($0.tense) })
    #expect(Set(quiz.questions.map(\.verb)).count == 10)
    #expect(quiz.questions.allSatisfy { $0.frame.isSentence })
  }

  @Test func aVosLearnerIsAskedVos() {
    let quiz = makeQuiz(level: .advanced, secondSingular: .vos)
    #expect(quiz.start(scope: .sentences()))
    while quiz.quizState == .inProgress {
      #expect(quiz.currentQuestion?.personNumber != .secondSingularTú)
      quiz.process(proposedAnswer: quiz.currentQuestion?.writtenAnswer ?? "")
    }
  }

  @Test func anAnswerIsRecordedAndAMissIsAskedAgainInItsSentence() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .sentences()))
    let first = try #require(quiz.currentQuestion)
    #expect(quiz.process(proposedAnswer: first.writtenAnswer ?? "") == .totalMatch)
    #expect(!practice.record.isEmpty)

    let second = try #require(quiz.currentQuestion)
    #expect(quiz.process(proposedAnswer: "zzzzzz") == .noMatch)
    #expect(quiz.isHeld)
    let reask = try #require(quiz.questions.first { $0.isReask })
    #expect(reask.sentence == second.sentence)
  }

  @Test func aFinishedRoundKeepsItsResultAndTenMoreAsksNewSentences() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(level: .advanced, practice: practice)
    #expect(quiz.start(scope: .sentences()))
    while quiz.quizState == .inProgress {
      quiz.process(proposedAnswer: quiz.currentQuestion?.writtenAnswer ?? "")
    }
    #expect(quiz.score == 100)
    #expect(practice.lastResult?.kind == .sentences)
    #expect(practice.lastResult?.level == .advanced)
    #expect(practice.lastResult?.title == "Complete the Sentence")

    #expect(quiz.continueSession())
    #expect(quiz.questions.count == 20)
    #expect(Set(quiz.questions.compactMap { $0.sentence?.id }).count == 20)
  }
}

private extension GapSentence {
  /// Stands in for a sentence that did not decode, which every check rejects.
  static let unreadable = GapSentences.decode(Data(#"[{"id":"","verb":"","tense":"","es":"","en":"","reviewed":false}]"#.utf8))[0]
}
