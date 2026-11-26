//
//  QuizCorrectionView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

extension EnvironmentValues {
  /// True on the pages a quiz pushes over a held correction, which then offer no quiz of their
  /// own, so that there is never a quiz inside a quiz.
  @Entry var isBeneathQuiz = false
}

/// A model's page opened from a quiz's correction, which reports its own source. A verb page's
/// pill pushes a bare `ModelInfo` instead.
struct QuizCorrectionModel: Hashable {
  let model: ModelInfo
}

/// A wrong answer, held: what the learner typed and the right answer, with the letters that
/// differ marked, links to the verb's page and its model's, and Continue.
struct QuizCorrectionView: View {
  let question: QuizQuestion
  let correction: QuizCorrection
  /// False in a quiz begun from the verb's own page, where a link back to it would be circular.
  let showsVerbLink: Bool
  /// The model to link to, or nil in a quiz over that model's own verbs.
  let model: ModelInfo?
  var accessibilityIsFocused: AccessibilityFocusState<Bool>.Binding
  let onOpen: (any Hashable) -> Void
  let onContinue: () -> Void

  private var difference: AnswerDifference {
    correction.difference
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      VStack(alignment: .leading, spacing: 6) {
        if let recognition = question.recognition, let answer = correction.recognitionAnswer {
          answerRow(label: L.Quiz.yourAnswer, text: Self.recognitionGivenText(answer, wrongParts: correction.recognitionGrade?.wrongParts ?? []))
          VStack(alignment: .leading, spacing: 2) {
            Text(L.Quiz.correctAnswer)
              .font(.caption)
              .foregroundStyle(.secondary)
            ForEach(recognition.answerLines, id: \.self) { line in
              Text(spanish: line)
                .font(.title3)
                .fontDesign(.serif)
                .foregroundStyle(Color.customForeground)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        } else {
          answerRow(label: L.Quiz.yourAnswer, text: Self.givenText(difference))
          answerRow(label: L.Quiz.correctAnswer, text: Self.expectedText(difference))
          if let completed = question.completedSentence {
            VStack(alignment: .leading, spacing: 2) {
              Text(L.Sentences.completed)
                .font(.caption)
                .foregroundStyle(.secondary)
              Text(spanish: completed)
                .font(.body)
                .fontDesign(.serif)
                .foregroundStyle(Color.customForeground)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("quiz_correction_sentence")
            }
          }
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(spokenCorrection)
      .accessibilityHint(L.Quiz.correctionHint)
      .accessibilityFocused(accessibilityIsFocused)
      .accessibilityIdentifier("quiz_correction")

      if let diagnosis = correction.diagnosis {
        // Spoken with the correction, above.
        Label(diagnosis.line, systemImage: "lightbulb")
          .font(.subheadline)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityHidden(true)
          .accessibilityIdentifier("quiz_diagnosis")
      }

      if correction.willBeReasked {
        // Spoken with the correction, above.
        Label(L.Quiz.willComeUpAgain, systemImage: "arrow.counterclockwise")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityHidden(true)
          .accessibilityIdentifier("quiz_will_come_up_again")
      }

      if showsVerbLink || model != nil {
        FlowLayout(spacing: Layout.defaultSpacing) {
          if showsVerbLink {
            ForEach(linkedVerbs, id: \.self) { verb in
              link(
                Text(spanish: ReflexivePronoun.citationForm(of: verb)),
                systemImage: "text.book.closed",
                identifier: verb == question.verb ? "quiz_correction_verb" : "quiz_correction_verb_\(verb)"
              ) {
                onOpen(VerbDestination(infinitive: verb, source: .quizCorrection, marks: marks(of: verb)))
              }
            }
          }
          if let model {
            link(
              Text(L.VerbCollection.modelTitle(exemplar: model.exemplar)),
              systemImage: "square.grid.3x3",
              identifier: "quiz_correction_model"
            ) {
              onOpen(QuizCorrectionModel(model: model))
            }
          }
        }
      }

      Button(action: onContinue) {
        Label(L.Quiz.continueAfterCorrection, systemImage: "arrow.right")
          .frame(maxWidth: Self.continueMaxWidth)
      }
      .buttonStyle(PrimaryButtonStyle())
      .frame(maxWidth: .infinity)
      .accessibilityHint(L.Quiz.continueHint)
      .accessibilityIdentifier("quiz_continue_button")
      .id(Self.continueButtonID)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }

  static let continueButtonID = "quiz_continue_button"

  /// The verbs the correction links to: the question's, and for Name the Form every other verb
  /// whose form the prompt is (fue, of ser and ir).
  private var linkedVerbs: [String] {
    var verbs = [question.verb]
    for cell in question.recognition?.cells ?? [] where !verbs.contains(cell.verb) {
      verbs.append(cell.verb)
    }
    return verbs
  }

  /// The cells a linked verb's page marks: the one asked, or every cell a prompt is of that verb.
  private func marks(of verb: String) -> Set<ConjugationCell> {
    guard let recognition = question.recognition else {
      return [ConjugationCell(tense: question.tense, personNumber: question.personNumber)]
    }
    return Set(recognition.cells.filter { $0.verb == verb }.map(\.cell))
  }

  // As wide as an iPhone's card, and no wider on an iPad.
  static let continueMaxWidth: CGFloat = 400

  private func answerRow(label: String, text: Text) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      text
        .font(.title3)
        .fontDesign(.serif)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func link(_ text: Text, systemImage: String, identifier: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label {
        text
      } icon: {
        Image(systemName: systemImage)
      }
      .font(.subheadline)
      .foregroundStyle(Color.customYellow)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(Color.customYellow.opacity(0.08), in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityHint(L.Quiz.correctionLinkHint)
    .accessibilityIdentifier(identifier)
  }

  /// "Incorrect. Your Answer: hablo. Correct Answer: habló. Letters that differ: ó. That is the
  /// form of the Presente de Indicativo (yo). This question will come up again." The answers are
  /// read in Spanish and the rest in the device's language.
  /// The letters are named only while there are few enough to help.
  private var spokenCorrection: Text {
    if let recognition = question.recognition, let answer = correction.recognitionAnswer {
      return spokenRecognitionCorrection(recognition, answer: answer)
    }
    var spoken = AttributedString(L.Quiz.incorrect + " " + L.Quiz.yourAnswer + ": ")
    spoken += AttributedString(spanish: difference.given)
    spoken += AttributedString(". " + L.Quiz.correctAnswer + ": ")
    spoken += AttributedString(spanish: difference.expected.lowercased())
    spoken += AttributedString(".")
    let letters = difference.expectedMarkedLetters
    if !letters.isEmpty, letters.count <= Self.maxSpokenLetters {
      spoken += AttributedString(" " + L.Quiz.lettersDiffer + " ")
      spoken += AttributedString(spanish: letters.joined(separator: ", "))
      spoken += AttributedString(".")
    }
    if let diagnosis = correction.diagnosis {
      spoken += AttributedString(" " + diagnosis.line)
    }
    if correction.willBeReasked {
      spoken += AttributedString(" " + L.Quiz.willComeUpAgain)
    }
    if let completed = question.completedSentence {
      spoken += AttributedString(" " + L.Sentences.completed + ": ")
      spoken += AttributedString(spanish: completed)
    }
    return Text(spoken)
  }

  private static let maxSpokenLetters = 3

  /// "Incorrect. Your Answer: ser, Pretérito, yo. Correct Answer: ser, Pretérito, él; ir,
  /// Pretérito, él. This question will come up again." The answers are read in Spanish.
  private func spokenRecognitionCorrection(_ recognition: RecognitionQuestion, answer: RecognitionAnswer) -> Text {
    func spokenSpanish(_ line: String) -> AttributedString {
      AttributedString(spanish: line.replacingOccurrences(of: " · ", with: ", ").replacingOccurrences(of: " (", with: ", ").replacingOccurrences(of: ")", with: ""))
    }
    var spoken = AttributedString(L.Quiz.incorrect + " " + L.Quiz.yourAnswer + ": ")
    spoken += spokenSpanish(answer.summary)
    spoken += AttributedString(". " + L.Quiz.correctAnswer + ": ")
    spoken += spokenSpanish(recognition.answerLines.joined(separator: "; "))
    spoken += AttributedString(".")
    if correction.willBeReasked {
      spoken += AttributedString(" " + L.Quiz.willComeUpAgain)
    }
    return Text(spoken)
  }

  /// A Name the Form answer, "ser · Pretérito (yo)", each wrong part red and struck through. A
  /// wrong infinitive is marked whole, since one that only lacks letters would have none to mark.
  static func recognitionGivenText(_ answer: RecognitionAnswer, wrongParts: Set<RecognitionPart>) -> Text {
    func part(_ text: String, isWrong: Bool) -> AttributedString {
      var part = AttributedString(text)
      part.foregroundColor = Color.customForeground
      if isWrong {
        part.foregroundColor = Color.customRed
        part.backgroundColor = Self.wrongBackground
        part.strikethroughStyle = Text.LineStyle(pattern: .solid, color: .customRed)
      }
      return part
    }
    var result = part(answer.typedInfinitive, isWrong: wrongParts.contains(.infinitive))
    result += AttributedString(" · ")
    result += part(answer.tense.titleCaseName, isWrong: wrongParts.contains(.tense))
    if let person = MatchedForm.personName(of: answer.cell) {
      result += AttributedString(" (")
      result += part(person, isWrong: wrongParts.contains(.person))
      result += AttributedString(")")
    }
    result.languageIdentifier = "es"
    return Text(result)
  }

  /// The tint behind a wrong letter. Light on white, where a stronger one left the red letters
  /// hard to read, and stronger on black, where a light one would barely show.
  private static let wrongBackground = Color(uiColor: UIColor { traits in
    UIColor.customRed.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.35 : 0.12)
  })

  // The red letters of a conjugation mark its irregularity, so a difference is shown another
  // way: a tinted background, struck through in the learner's answer and underlined in the right
  // one.
  static func givenText(_ difference: AnswerDifference) -> Text {
    var result = AttributedString()
    for (character, isMarked) in zip(Array(difference.given), difference.givenMarks) {
      var part = AttributedString(String(character))
      part.foregroundColor = Color.customForeground
      if isMarked {
        part.foregroundColor = Color.customRed
        part.backgroundColor = Self.wrongBackground
        part.strikethroughStyle = Text.LineStyle(pattern: .solid, color: .customRed)
      }
      result.append(part)
    }
    result.languageIdentifier = "es"
    return Text(result)
  }

  static func expectedText(_ difference: AnswerDifference) -> Text {
    var result = AttributedString()
    var marks = difference.expectedMarks.makeIterator()
    for (text, isIrregular) in segments(of: difference.expected) {
      for character in text {
        var part = AttributedString(String(character))
        part.foregroundColor = isIrregular ? Color.customRed : Color.customForeground
        if marks.next() == true {
          part.backgroundColor = Color.customGreen.opacity(0.3)
          part.underlineStyle = Text.LineStyle(pattern: .solid, color: .customGreen)
        }
        result.append(part)
      }
    }
    result.languageIdentifier = "es"
    return Text(result)
  }

  /// The form's runs, lowercased, each flagged irregular where the engine wrote it in capitals.
  private static func segments(of form: String) -> [(text: String, isIrregular: Bool)] {
    guard case .conjugation(let parts) = form.parseConjugationToSegment() else {
      return [(form.lowercased(), false)]
    }
    return parts.map { part in
      switch part {
      case .regular(let text):
        return (text, false)
      case .irregular(let text):
        return (text, true)
      }
    }
  }
}
