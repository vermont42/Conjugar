//
//  ChoiceQuestionTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Choice questions: the machine check that confirms both sentences of every item against the
//  engine, in tú and vos; levels and regions; the draw; and the choice in a default round.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct ChoiceQuestionTests {
  private func makeQuiz(
    level: QuizLevel = .elementary,
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

  private func item(_ id: String) throws -> ChoiceQuestion {
    try #require(ChoiceQuestions.all.first { $0.id == id })
  }

  private func made(
    verb: String = "jugar",
    person: String = "ts",
    level: String = "elementary",
    region: String? = nil,
    reason: String = "habit_in_the_past",
    right: (String, String) = ("imperfectoDeIndicativo", "De niña, Ana {jugaba} al tenis."),
    other: (String, String) = ("pretérito", "De niña, Ana {jugó} al tenis."),
    reviewed: Bool = false
  ) -> ChoiceQuestion? {
    var object: [String: Any] = [
      "id": "\(verb).\(right.0).1", "verb": verb, "person": person, "level": level, "reason": reason,
      "right": ["tense": right.0, "es": right.1], "other": ["tense": other.0, "es": other.1],
      "en": "An English line.", "reviewed": reviewed
    ]
    if let region {
      object["region"] = region
    }
    let data = (try? JSONSerialization.data(withJSONObject: [object])) ?? Data()
    return ChoiceQuestions.decode(data).first
  }

  private static let forbiddenInSecondSingular: Set<String> = ["tú", "ti", "contigo"]
  private static let vosotrosWords: Set<String> = ["vosotros", "vosotras", "os", "vuestro", "vuestra", "vuestros", "vuestras"]

  private static func words(of text: String) -> [String] {
    text.lowercased().split { !$0.isLetter }.map(String.init)
  }

  /// The sentence with its braces and what they hold taken out.
  private static func outsideBraces(_ text: String) -> String {
    var result = ""
    var isInside = false
    for character in text {
      switch character {
      case "{":
        isInside = true
      case "}":
        isInside = false
      default:
        if !isInside {
          result.append(character)
        }
      }
    }
    return result
  }

  /// What is wrong with an item, or nothing. The machine check.
  private func problems(_ item: ChoiceQuestion?) -> [String] {
    guard let item else {
      return ["an item did not decode"]
    }
    var problems: [String] = []
    let id = item.id
    guard VerbMap.shared.entry(for: item.verb) != nil else {
      return ["\(id): \(item.verb) is not in the verb map"]
    }
    guard let level = item.quizLevel else {
      return ["\(id): \(item.level) names no level"]
    }
    guard let reason = item.choiceReason else {
      return ["\(id): \(item.reason) names no reason"]
    }
    guard let rightTense = item.rightSentence.displayTense, let otherTense = item.otherSentence.displayTense else {
      return ["\(id): a sentence names no tense"]
    }
    guard let written = item.rightSentence.writtenPersonNumber, written != .none else {
      return ["\(id): \(item.person) names no person"]
    }
    if item.region != nil, item.choiceRegion == nil {
      problems.append("\(id): \(item.region ?? "") names no region")
    }
    if (reason == .todayInSpain) != (item.choiceRegion == .spain) || (reason == .todayInLatinAmerica) != (item.choiceRegion == .latinAmerica) {
      problems.append("\(id): only an item on today's events names a region, and its reason's")
    }
    if !id.hasPrefix("\(item.verb).\(item.right.tense).") {
      problems.append("\(id): the id does not begin with its verb and right tense")
    }
    if rightTense == otherTense {
      problems.append("\(id): both sentences are in one tense")
    }
    if written == .secondSingularVos || written == .secondPlural {
      problems.append("\(id): an item is written in tú, never vos or vosotros")
    }
    for tense in [rightTense, otherTense] where tense == .imperfectoDeSubjuntivo2 || tense == .pluscuamperfectoDeSubjuntivo2 {
      problems.append("\(id): a sentence is written with the -ra form")
    }
    if item.en.isEmpty {
      problems.append("\(id): no English")
    }
    if Self.outsideBraces(item.right.es) != Self.outsideBraces(item.other.es) {
      problems.append("\(id): the sentences differ outside their braces")
    }
    for sentence in [item.rightSentence, item.otherSentence] {
      if sentence.es.filter({ $0 == "{" }).count != 1 || sentence.es.filter({ $0 == "}" }).count != 1 || sentence.blankText?.isEmpty != false {
        problems.append("\(id): a sentence has one pair of braces around its form")
      }
      let words = Set(Self.words(of: sentence.es))
      if !words.isDisjoint(with: Self.vosotrosWords) {
        problems.append("\(id): a word of vosotros")
      }
      if written == .secondSingularTú, !words.isDisjoint(with: Self.forbiddenInSecondSingular) {
        problems.append("\(id): a second-person item names tú, which vos would not")
      }
      for secondSingular in [DisplayPersonNumber.secondSingularTú, .secondSingularVos] {
        guard let question = QuizQuestion.sentence(sentence, secondSingular: secondSingular), let engine = question.writtenAnswer else {
          problems.append("\(id): the engine gives no form for \(sentence.tense) in \(secondSingular)")
          continue
        }
        guard question.completedSentenceParts != nil else {
          problems.append("\(id): the words the frame supplies do not stand before the braces of \(sentence.es)")
          continue
        }
        if secondSingular == .secondSingularTú || written != .secondSingularTú {
          if sentence.writtenAnswer?.lowercased() != engine.lowercased() {
            problems.append("\(id): {\(sentence.blankText ?? "")} gives \(sentence.writtenAnswer ?? "nothing"), but the engine writes \(engine.lowercased())")
          }
        }
      }
    }
    let regions = item.choiceRegion.map { [$0] } ?? ChoiceRegion.allCases
    for region in regions where !item.isAskable(at: level, in: region) {
      problems.append("\(id): its own level does not ask its right sentence in \(region)")
    }
    if let index = QuizLevel.allCases.firstIndex(of: level), index > 0, item.isAskable(at: QuizLevel.allCases[index - 1], in: regions[0]) {
      problems.append("\(id): a level below its own asks it")
    }
    for secondSingular in [DisplayPersonNumber.secondSingularTú, .secondSingularVos] {
      let prompt = ChoicePrompt(question: item, rightIndex: 0, secondSingular: secondSingular)
      let options = prompt.options
      if options.count != 2 || options[0].form == options[1].form || prompt.quizQuestion == nil {
        problems.append("\(id): no two distinct sentences in \(secondSingular)")
      }
    }
    let line = item.reasonLine
    if !line.contains(rightTense.sentenceDisplayName) || line.contains(otherTense.sentenceDisplayName) != reason.namesBothTenses {
      problems.append("\(id): the reason \"\(line)\" names its tenses wrong")
    }
    return problems
  }

  // The machine check

  @Test func everyItemPassesTheMachineCheck() {
    #expect(ChoiceQuestions.all.count >= 40)
    let problems = ChoiceQuestions.all.flatMap(problems)
    #expect(problems.isEmpty, "\(problems.joined(separator: "\n"))")
  }

  @Test func theMachineCheckCatchesABrokenItem() {
    #expect(problems(made()).isEmpty)
    // A misspelled form, both sentences in one tense, sentences that differ outside their braces,
    // tú named in a second-person item, an unknown reason, a region on an item that needs none,
    // a level that does not ask the right sentence, and the -se form.
    #expect(!problems(made(right: ("imperfectoDeIndicativo", "De niña, Ana {jugava} al tenis."))).isEmpty)
    #expect(!problems(made(other: ("imperfectoDeIndicativo", "De niña, Ana {jugaba} al tenis."))).isEmpty)
    #expect(!problems(made(other: ("pretérito", "De niño, Ana {jugó} al tenis."))).isEmpty)
    #expect(!problems(made(person: "ss", right: ("imperfectoDeIndicativo", "Tú {jugabas} al tenis."), other: ("pretérito", "Tú {jugaste} al tenis."))).isEmpty)
    #expect(!problems(made(reason: "because")).isEmpty)
    #expect(!problems(made(region: "spain")).isEmpty)
    #expect(!problems(made(level: "beginner")).isEmpty)
    #expect(!problems(made(
      level: "advanced",
      reason: "unlikely_si",
      right: ("imperfectoDeSubjuntivo2", "Si Ana {jugase} al tenis, ganaría."),
      other: ("condicional", "Si Ana {jugaría} al tenis, ganaría.")
    )).isEmpty)
  }

  @Test func theIdsAreUniqueAndEveryReasonAndLevelIsCovered() {
    let ids = ChoiceQuestions.all.map(\.id)
    #expect(Set(ids).count == ids.count)
    #expect(Set(ChoiceQuestions.all.compactMap(\.choiceReason)) == Set(ChoiceReason.allCases))
    #expect(Set(Quiz.choicesFixtureIDs).isSubset(of: ids))
    for region in [Region.spain, .latinAmerica] {
      #expect(makeQuiz(region: region).choicesFixture().count == 10)
    }
    for level in QuizLevel.allCases {
      for region in ChoiceRegion.allCases {
        let askable = ChoiceQuestions.askable(at: level, in: region, includesDrafts: true)
        #expect(level == .beginner ? askable.isEmpty : askable.count >= 12, "\(level) in \(region) asks \(askable.count)")
      }
    }
  }

  // Levels, regions, and drafts

  @Test func anItemOnTodaysEventsIsAskedOnlyInItsRegion() throws {
    let heComido = try item("comer.perfectoDeIndicativo.1")
    let comí = try item("comer.pretérito.1")
    #expect(heComido.isAskable(at: .elementary, in: .spain))
    #expect(!heComido.isAskable(at: .elementary, in: .latinAmerica))
    #expect(comí.isAskable(at: .advanced, in: .latinAmerica))
    #expect(!comí.isAskable(at: .advanced, in: .spain))
    let jugaba = try item("jugar.imperfectoDeIndicativo.1")
    #expect(ChoiceRegion.allCases.allSatisfy { jugaba.isAskable(at: .intermediate, in: $0) })
  }

  @Test func levelsAreCumulativeAndTheOtherSentenceMayBeOneNoLevelAsks() throws {
    let tuviera = try item("tener.imperfectoDeSubjuntivo1.1")
    #expect(!tuviera.isAskable(at: .intermediate, in: .spain))
    #expect(tuviera.isAskable(at: .advanced, in: .spain))
    // The condicional after si is no cell a quiz asks of tener in a sentence, yet it is shown.
    #expect(tuviera.otherSentence.displayTense == .condicional)
  }

  @Test func draftsAreLeftOutOfReleaseBuilds() throws {
    let draft = try #require(made())
    let reviewed = try #require(made(reviewed: true))
    #expect(ChoiceQuestions.askable(at: .elementary, in: .spain, from: [draft, reviewed], includesDrafts: false) == [reviewed])
    #expect(ChoiceQuestions.askable(at: .elementary, in: .spain, from: [draft, reviewed], includesDrafts: true).count == 2)
  }

  // The prompt

  @Test func thePromptPlacesTheRightSentenceAndHighlightsItsForm() throws {
    let first = ChoicePrompt(question: try item("jugar.imperfectoDeIndicativo.1"), rightIndex: 0, secondSingular: .secondSingularTú)
    #expect(first.options.map(\.form) == ["jugaba", "jugó"])
    #expect(first.options.map(\.isRight) == [true, false])
    #expect(first.options[0].before == "De niña, Ana ")
    #expect(first.options[0].sentence == "De niña, Ana jugaba al tenis todos los sábados.")
    let second = ChoicePrompt(question: first.question, rightIndex: 1, secondSingular: .secondSingularTú)
    #expect(second.options.map(\.form) == ["jugó", "jugaba"])
    // A form that opens the sentence is capitalized there.
    let eran = ChoicePrompt(question: try item("ser.imperfectoDeIndicativo.2"), rightIndex: 0, secondSingular: .secondSingularTú)
    #expect(eran.options.map(\.form) == ["Eran", "Fueron"])
  }

  @Test func aSecondPersonItemIsShownInTheLearnersTuOrVos() throws {
    let hables = try item("hablar.imperativoNegativo.1")
    let tu = ChoicePrompt(question: hables, rightIndex: 0, secondSingular: .secondSingularTú)
    #expect(tu.options.map(\.sentence) == ["¡No hables tan alto!", "¡No hablas tan alto!"])
    let vos = ChoicePrompt(question: hables, rightIndex: 0, secondSingular: .secondSingularVos)
    let vosPresente = try #require(QuizQuestion("hablar", .presenteDeIndicativo, .secondSingularVos).writtenAnswer?.lowercased())
    #expect(vos.options[1].form == vosPresente)
    #expect(vos.quizQuestion?.personNumber == .secondSingularVos)
    #expect(vos.quizQuestion?.tense == .imperativoNegativo)
  }

  @Test func aReasonNamesItsTenses() throws {
    #expect(try item("jugar.imperfectoDeIndicativo.1").reasonLine == "A habit in the past takes the imperfecto de indicativo.")
    #expect(try item("tener.imperfectoDeSubjuntivo1.1").reasonLine == "After si, an unlikely or untrue condition takes the imperfecto de subjuntivo, never the condicional.")
  }

  // The draw

  @Test func theDrawTakesTheUnaskedFirstAndNeverPlacesAChoiceFirst() {
    var generator = SplitMix64(seed: 3)
    let candidates = ChoiceQuestions.askable(at: .advanced, in: .spain, includesDrafts: true)
    var asked: Set<String> = []
    for _ in candidates {
      guard let prompt = QuizDraw.choice(from: candidates, excluded: asked, secondSingular: .secondSingularTú, using: &generator) else {
        Issue.record("no choice drawn")
        return
      }
      #expect(!asked.contains(prompt.question.id))
      asked.insert(prompt.question.id)
    }
    #expect(asked.count == candidates.count)
    #expect(QuizDraw.choice(from: candidates, excluded: asked, secondSingular: .secondSingularTú, using: &generator) != nil)
    #expect(QuizDraw.choice(from: [], excluded: [], secondSingular: .secondSingularTú, using: &generator) == nil)
    for _ in 0..<50 {
      #expect((1...9).contains(QuizDraw.choicePosition(in: 9, using: &generator)))
    }
  }

  // A round

  @Test(arguments: [QuizLevel.elementary, .intermediate, .advanced])
  func aDefaultRoundAsksOneChoiceNeverFirst(level: QuizLevel) {
    for seed in UInt64(1)...10 {
      let quiz = makeQuiz(level: level, region: seed.isMultiple(of: 2) ? .spain : .latinAmerica, seed: seed)
      #expect(quiz.start())
      #expect(quiz.questions.count == 10)
      let choices = quiz.questions.indices.filter { quiz.questions[$0].choice != nil }
      #expect(choices.count == 1)
      #expect(choices.first != 0)
      let region: ChoiceRegion = quiz.lastRegion == .spain ? .spain : .latinAmerica
      #expect(choices.allSatisfy { quiz.questions[$0].choice?.question.isAskable(at: level, in: region) == true })
    }
  }

  @Test func noChoiceAtBeginnerOrOutsideTheDefaultQuiz() {
    #expect(makeQuiz(level: .beginner).start())
    #expect(makeQuiz(level: .beginner).questions.allSatisfy { $0.choice == nil })
    let scopes: [QuizScope] = [.myVerbs(["hablar", "tener", "ser"]), .sentences(), .recognition(), .verbPage("tener")]
    for scope in scopes {
      let quiz = makeQuiz(level: .advanced)
      #expect(quiz.start(scope: scope))
      #expect(quiz.questions.allSatisfy { $0.choice == nil })
      #expect(!scope.mixesChoiceQuestions)
    }
    #expect(QuizScope.allVerbs.mixesChoiceQuestions)
  }

  /// Answers the questions before the round's choice rightly, leaving the choice on screen.
  private func advanceToTheChoice(_ quiz: Quiz) throws -> ChoicePrompt {
    while quiz.currentQuestion?.choice == nil {
      let question = try #require(quiz.currentQuestion)
      #expect(quiz.process(proposedAnswer: question.writtenAnswer ?? "") == .totalMatch)
    }
    return try #require(quiz.currentQuestion?.choice)
  }

  @Test func aRightChoiceHoldsWithItsReasonAndRecordsNothing() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start())
    let choice = try advanceToTheChoice(quiz)
    let recorded = practice.record
    let index = quiz.currentQuestionIndex
    #expect(quiz.submitChoice(choice.rightIndex) == .totalMatch)
    #expect(quiz.isHeld)
    #expect(quiz.chosenOption == choice.rightIndex)
    #expect(!quiz.isClockRunning)
    #expect(quiz.currentQuestionIndex == index)
    #expect(practice.record == recorded)
    #expect(quiz.points(at: index) == 10)
    // A held choice takes no second choice.
    #expect(quiz.submitChoice(1 - choice.rightIndex) == nil)
    quiz.continueAfterCorrection()
    #expect(!quiz.isHeld)
    #expect(quiz.chosenOption == nil)
    #expect(quiz.quizState == .finished || quiz.currentQuestionIndex == index + 1)
  }

  @Test func aWrongChoiceHoldsAndIsNotAskedAgain() throws {
    let quiz = makeQuiz(level: .advanced)
    #expect(quiz.start())
    let choice = try advanceToTheChoice(quiz)
    let index = quiz.currentQuestionIndex
    let count = quiz.questions.count
    #expect(quiz.submitChoice(1 - choice.rightIndex) == .noMatch)
    #expect(quiz.isHeld)
    #expect(quiz.correction == nil)
    #expect(quiz.questions.count == count)
    #expect(quiz.points(at: index) == 0)
    #expect(quiz.proposedAnswers[index] == choice.form(at: 1 - choice.rightIndex))
    #expect(quiz.correctAnswers[index].lowercased() == quiz.questions[index].writtenAnswer?.lowercased())
  }

  @Test func aRankedRoundScoresOutOfOneHundredAndTenMoreAsksANewChoice() throws {
    let quiz = makeQuiz(level: .intermediate)
    #expect(quiz.start())
    #expect(quiz.isRankedRound)
    while quiz.quizState == .inProgress {
      let question = try #require(quiz.currentQuestion)
      if let choice = question.choice {
        quiz.submitChoice(choice.rightIndex)
        quiz.continueAfterCorrection()
      } else {
        quiz.process(proposedAnswer: question.writtenAnswer ?? "")
      }
    }
    #expect(quiz.firstRoundScore == 100)
    #expect(quiz.correctCount == 10)
    let first = try #require(quiz.questions.compactMap(\.choice).first)
    #expect(quiz.continueSession())
    let choices = quiz.questions.compactMap(\.choice)
    #expect(choices.count == 2)
    #expect(choices.last?.question.id != first.question.id)
  }
}
