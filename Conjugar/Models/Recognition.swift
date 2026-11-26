//
//  Recognition.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Name the Form: the quiz shows a form, such as fuera, and the learner types its infinitive and
/// chooses its tense and person. This is the direction reading needs, and practice develops in
/// the direction practiced.
nonisolated extension QuizScope {
  static func recognition() -> QuizScope {
    QuizScope(verbs: nil, questionCount: roundLength, source: .recognition, isRecognition: true)
  }
}

/// One cell of one verb whose form is a recognition question's prompt.
nonisolated struct RecognitionCell: Hashable, Sendable {
  let verb: String
  let cell: ConjugationCell
}

/// A tense the learner may choose, with the persons its chips offer: none for the gerundio and the
/// participio.
nonisolated struct RecognitionChoice: Equatable, Sendable {
  let tense: DisplayTense
  let personNumbers: [DisplayPersonNumber]

  /// The cells a learner can name by choosing this tense.
  var cells: [ConjugationCell] {
    personNumbers.isEmpty
      ? [ConjugationCell(tense: tense, personNumber: .none)]
      : personNumbers.map { ConjugationCell(tense: tense, personNumber: $0) }
  }
}

/// The groups the tense chips are shown in. The mood is the group's heading, so a chip names its
/// tense without it: presente under Indicativo, imperfecto 1 under Subjuntivo.
nonisolated enum RecognitionMood: CaseIterable, Sendable {
  case indicativo
  case subjuntivo
  case imperativo
  /// The gerundio and the participio, which have no mood or person.
  case nonFinite

  /// The tenses of the mood in the order a grammar lists them: the simple tenses, then the
  /// compound ones.
  var tenses: [DisplayTense] {
    switch self {
    case .indicativo:
      return [
        .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
        .perfectoDeIndicativo, .pluscuamperfectoDeIndicativo, .futuroPerfecto, .pretéritoAnterior, .condicionalCompuesto
      ]
    case .subjuntivo:
      return [
        .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .futuroDeSubjuntivo,
        .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1, .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo
      ]
    case .imperativo:
      return [.imperativoPositivo, .imperativoNegativo]
    case .nonFinite:
      return [.gerundio, .participio]
    }
  }

  /// The group's heading, in Spanish like every tense name. Nil for the forms with no mood.
  var heading: String? {
    switch self {
    case .indicativo:
      return "Indicativo"
    case .subjuntivo:
      return "Subjuntivo"
    case .imperativo:
      return "Imperativo"
    case .nonFinite:
      return nil
    }
  }

  /// Every tense a chip can offer, mood by mood.
  static let tenseOrder: [DisplayTense] = allCases.flatMap(\.tenses)
}

nonisolated extension DisplayTense {
  /// The tense's name on its chip, under its mood's heading.
  var recognitionChipName: String {
    switch self {
    case .presenteDeIndicativo, .presenteDeSubjuntivo:
      return "presente"
    case .imperfectoDeIndicativo:
      return "imperfecto"
    case .futuroDeIndicativo, .futuroDeSubjuntivo:
      return "futuro"
    case .perfectoDeIndicativo, .perfectoDeSubjuntivo:
      return "perfecto"
    case .pluscuamperfectoDeIndicativo:
      return "pluscuamperfecto"
    case .futuroPerfectoDeSubjuntivo:
      return "futuro perfecto"
    case .imperfectoDeSubjuntivo1:
      return "imperfecto 1"
    case .imperfectoDeSubjuntivo2:
      return "imperfecto 2"
    case .pluscuamperfectoDeSubjuntivo1:
      return "pluscuamperfecto 1"
    case .pluscuamperfectoDeSubjuntivo2:
      return "pluscuamperfecto 2"
    case .imperativoPositivo:
      return "positivo"
    case .imperativoNegativo:
      return "negativo"
    default:
      return displayName
    }
  }
}

/// The three parts of a recognition answer.
nonisolated enum RecognitionPart: CaseIterable, Sendable {
  case infinitive
  case tense
  case person
}

/// A learner's answer: a typed infinitive, a chosen tense, and, unless the tense has no person, a
/// chosen person.
nonisolated struct RecognitionAnswer: Equatable, Sendable {
  let infinitive: String
  let tense: DisplayTense
  /// `.none` for the gerundio and the participio.
  let personNumber: DisplayPersonNumber

  var cell: ConjugationCell {
    ConjugationCell(tense: tense, personNumber: personNumber)
  }

  /// The infinitive as typed, lowercased, with runs of spaces collapsed.
  var typedInfinitive: String {
    AnswerSpelling.normalized(infinitive)
  }

  /// The tense and person as the results name them: "Pretérito (yo)", "Gerundio".
  var cellName: String {
    let tenseName = tense.titleCaseName
    guard let person = MatchedForm.personName(of: cell) else {
      return tenseName
    }
    return "\(tenseName) (\(person))"
  }

  /// "ser · Pretérito (yo)", for the results.
  var summary: String {
    "\(typedInfinitive) · \(cellName)"
  }
}

/// How a recognition answer fared: which parts are wrong, and whether any part was right, which
/// earns one more try at half points, as a slip does.
nonisolated struct RecognitionGrade: Equatable, Sendable {
  let wrongParts: Set<RecognitionPart>
  let hasRightPart: Bool

  var isCorrect: Bool {
    wrongParts.isEmpty
  }

  var earnsSecondAttempt: Bool {
    !isCorrect && hasRightPart
  }

  /// What to check, in the order the parts are read: "Check the tense and the person."
  var line: String {
    switch (wrongParts.contains(.infinitive), wrongParts.contains(.tense), wrongParts.contains(.person)) {
    case (true, false, false):
      return L.Recognition.checkInfinitive
    case (false, true, false):
      return L.Recognition.checkTense
    case (false, false, true):
      return L.Recognition.checkPerson
    case (true, true, false):
      return L.Recognition.checkInfinitiveAndTense
    case (true, false, true):
      return L.Recognition.checkInfinitiveAndPerson
    case (false, true, true):
      return L.Recognition.checkTenseAndPerson
    case (false, false, false), (true, true, true):
      return ""
    }
  }
}

/// A recognition question: the prompt, every cell of every verb that writes it, and the tenses and
/// persons the learner chooses among.
///
/// A form often belongs to several cells (hablamos is the presente and the pretérito of nosotros;
/// hable is the presente de subjuntivo of yo and él and usted's command) or to two verbs (fue, of
/// ser and ir). Every one is a right answer, since the prompt gives no context to choose between
/// them, and no prompt is avoided, since deciding which cells a text can be is the skill being
/// practiced. Only cells the learner can choose count.
nonisolated struct RecognitionQuestion: Equatable, Sendable {
  /// As the engine writes it, the irregular letters in capitals: fUEra, no HAGas, me arrepIEnto.
  let prompt: String
  /// The asked verb's cells first.
  let cells: [RecognitionCell]
  /// The level's tenses, in `RecognitionMood.tenseOrder`, each with the persons a quiz may ask.
  let choices: [RecognitionChoice]

  init(prompt: String, cells: [RecognitionCell], choices: [RecognitionChoice]) {
    self.prompt = prompt
    self.cells = cells
    self.choices = choices
  }

  /// The question whose prompt is `verb`'s form at `cell`, or nil when the engine gives none.
  init?(verb: String, cell: ConjugationCell, choices: [RecognitionChoice], map: ConjugationMap = .bundled) {
    guard case let .success(prompt) = TenseBridge.conjugate(infinitive: verb, tense: cell.tense, personNumber: cell.personNumber, pronoun: .written) else {
      return nil
    }
    let asked = RecognitionCell(verb: verb, cell: cell)
    self.init(prompt: prompt, cells: Self.cells(writing: prompt, asked: asked, choices: choices, map: map), choices: choices)
  }

  /// Every cell the choices offer of every verb that writes `prompt`, the asked verb's first.
  ///
  /// The conjugation map names the verbs to try: those with an entry for a word of the prompt, so
  /// that hablado finds hablar for "ha hablado" and hables finds it for "no hables". Each is then
  /// matched cell by cell, exactly, since habló and hablo are different forms.
  static func cells(writing prompt: String, asked: RecognitionCell, choices: [RecognitionChoice], map: ConjugationMap) -> [RecognitionCell] {
    let offered = Set(choices.flatMap(\.cells))
    var infinitives = [asked.verb]
    for word in AnswerSpelling.normalized(prompt).split(separator: " ") {
      for entry in map.entries(for: String(word)) where !infinitives.contains(entry.infinitive) {
        infinitives.append(entry.infinitive)
      }
    }
    var cells = infinitives.flatMap { infinitive in
      ConjugationMatch.cells(of: infinitive, equalTo: prompt)
        .filter(offered.contains)
        .map { RecognitionCell(verb: infinitive, cell: $0) }
    }
    if !cells.contains(asked) {
      cells.insert(asked, at: 0)
    }
    return cells
  }

  /// The choice for a tense, which says what persons its chips offer.
  func choice(for tense: DisplayTense) -> RecognitionChoice? {
    choices.first { $0.tense == tense }
  }

  /// Whether a typed infinitive is this verb's, case and spacing aside. A reflexive-only verb is
  /// right with its pronoun or without it (arrepentirse, arrepentir). Accents count, since reír
  /// and reir are not the same word.
  static func spells(_ typed: String, _ verb: String) -> Bool {
    let typed = AnswerSpelling.normalized(typed)
    return typed == verb.lowercased() || typed == ReflexivePronoun.citationForm(of: verb).lowercased()
  }

  /// Which parts of an answer are wrong, judged against the cells of the typed verb when it is
  /// one of them, and against every cell otherwise. A part is called wrong only when changing it
  /// alone, or with the other parts called wrong, can make the answer right, so a repair prompt
  /// never sends the learner to change something that was right.
  func grade(_ answer: RecognitionAnswer) -> RecognitionGrade {
    let ofInfinitive = cells.filter { Self.spells(answer.infinitive, $0.verb) }
    let infinitiveIsRight = !ofInfinitive.isEmpty
    let candidates = infinitiveIsRight ? ofInfinitive : cells
    var wrong: Set<RecognitionPart> = infinitiveIsRight ? [] : [.infinitive]

    if candidates.contains(where: { $0.cell == answer.cell }) {
      return RecognitionGrade(wrongParts: wrong, hasRightPart: true)
    }
    if candidates.contains(where: { $0.cell.tense == answer.tense }) {
      wrong.insert(.person)
      return RecognitionGrade(wrongParts: wrong, hasRightPart: true)
    }
    wrong.insert(.tense)
    // A person is judged only between tenses that have persons. Between the gerundio and a
    // finite tense, the tense alone is wrong, and the person follows from it.
    let hasPerson = answer.personNumber != .none
    let personIsRight = hasPerson && candidates.contains { $0.cell.personNumber == answer.personNumber }
    if hasPerson, !personIsRight, candidates.contains(where: { $0.cell.personNumber != .none }) {
      wrong.insert(.person)
    }
    return RecognitionGrade(wrongParts: wrong, hasRightPart: infinitiveIsRight || personIsRight)
  }

  /// The right answers as the correction lists them, one line per verb, its tenses and persons
  /// as search's result rows name them: "hablar · Presente de Subjuntivo (yo, él) · Imperativo
  /// Positivo (usted)".
  var answerLines: [String] {
    var verbs: [String] = []
    for cell in cells where !verbs.contains(cell.verb) {
      verbs.append(cell.verb)
    }
    return verbs.map { verb in
      var groups: [(tense: DisplayTense, persons: [String])] = []
      for cell in cells where cell.verb == verb {
        let person = MatchedForm.personName(of: cell.cell)
        if let index = groups.firstIndex(where: { $0.tense == cell.cell.tense }) {
          if let person, !groups[index].persons.contains(person) {
            groups[index].persons.append(person)
          }
        } else {
          groups.append((cell.cell.tense, person.map { [$0] } ?? []))
        }
      }
      let names = groups.map { group in
        group.persons.isEmpty ? group.tense.titleCaseName : "\(group.tense.titleCaseName) (\(group.persons.joined(separator: ", ")))"
      }
      return ([ReflexivePronoun.citationForm(of: verb)] + names).joined(separator: " · ")
    }
  }

  /// The chip's label for a person in a tense: the subjects a form of that person may take, or,
  /// for a command, whom it addresses.
  static func personLabel(_ personNumber: DisplayPersonNumber, in tense: DisplayTense) -> String {
    let isCommand = tense.isCommand
    switch personNumber {
    case .thirdSingular:
      return isCommand ? "usted" : "él, ella, usted"
    case .thirdPlural:
      return isCommand ? "ustedes" : "ellos, ellas, ustedes"
    default:
      return personNumber.pronoun
    }
  }
}

nonisolated extension QuizQuestion {
  /// A recognition question whose prompt is `verb`'s form at the cell, or nil when the engine
  /// gives none.
  static func recognition(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber, choices: [RecognitionChoice]) -> QuizQuestion? {
    guard let recognition = RecognitionQuestion(verb: verb, cell: ConjugationCell(tense: tense, personNumber: personNumber), choices: choices) else {
      return nil
    }
    return QuizQuestion(verb, tense, personNumber).recognizing(recognition)
  }
}
