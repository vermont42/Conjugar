//
//  ChoiceQuestionView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A choice question's two sentences, each with its form in bold yellow and its tense named
/// beneath, and, once one is chosen, the English, the reason, and Continue. The English waits for
/// the choice, since its aspect ("used to play", "was reading") can give the answer away.
struct ChoiceQuestionView: View {
  let choice: ChoicePrompt
  /// The chosen sentence, once the learner has chosen.
  let chosenOption: Int?
  var reasonIsFocused: AccessibilityFocusState<Bool>.Binding
  let onChoose: (Int) -> Void
  let onContinue: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(L.Choice.prompt)
        .font(.subheadline.bold())
        .foregroundStyle(Color.customYellow)
        .accessibilityAddTraits(.isHeader)

      ForEach(Array(choice.options.enumerated()), id: \.offset) { index, option in
        optionButton(option, index: index)
      }

      if chosenOption != nil {
        Text(verbatim: choice.question.en)
          .font(.callout)
          .italic()
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityIdentifier("choice_english")

        // Spoken with the choice's announcement, and focused after it.
        Label(choice.question.reasonLine, systemImage: "lightbulb.fill")
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityFocused(reasonIsFocused)
          .accessibilityIdentifier("choice_reason")

        Button(action: onContinue) {
          Label(L.Quiz.continueAfterCorrection, systemImage: "arrow.right")
            .frame(maxWidth: QuizCorrectionView.continueMaxWidth)
        }
        .buttonStyle(PrimaryButtonStyle())
        .frame(maxWidth: .infinity)
        // No field holds the keyboard here, so Return on a hardware keyboard needs its own way in.
        .keyboardShortcut(.defaultAction)
        .accessibilityHint(L.Quiz.continueHint)
        .accessibilityIdentifier("quiz_continue_button")
        .id(QuizCorrectionView.continueButtonID)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }

  private func optionButton(_ option: ChoicePrompt.Option, index: Int) -> some View {
    let isAnswered = chosenOption != nil
    let isChosen = index == chosenOption
    let isMarked = isAnswered && (option.isRight || isChosen)
    let borderColor: Color = !isMarked ? .customCardBorder : option.isRight ? .customGreen : .customRed
    let tenseName = option.tense.sentenceDisplayName

    return Button {
      onChoose(index)
    } label: {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline) {
          Text(Self.sentenceText(option))
            .font(.title3)
            .fontDesign(.serif)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 0)
          if isMarked {
            Image(systemName: option.isRight ? "checkmark.circle.fill" : "xmark.circle.fill")
              .foregroundStyle(option.isRight ? Color.customGreen : Color.customRed)
              .font(.title3)
          }
        }
        Text(verbatim: tenseName)
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.customBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .strokeBorder(borderColor, lineWidth: isMarked ? 2 : 1)
      )
      .opacity(isAnswered && !isMarked ? 0.6 : 1)
      .contentShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
    // Not disabled, which would dim the right sentence just when the learner should read it.
    .allowsHitTesting(!isAnswered)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(spanish: "\(option.sentence) \(tenseName)"))
    .accessibilityValue(Self.accessibilityValue(isRight: option.isRight, isChosen: isChosen, isAnswered: isAnswered))
    .accessibilityHint(isAnswered ? "" : L.Choice.optionHint)
    .accessibilityAddTraits(.isButton)
    .accessibilityIdentifier("choice_option_\(index)")
  }

  private static func accessibilityValue(isRight: Bool, isChosen: Bool, isAnswered: Bool) -> String {
    guard isAnswered else {
      return ""
    }
    return [isChosen ? L.Choice.yourChoice : nil, isRight ? L.Choice.rightChoice : nil].compactMap { $0 }.joined(separator: ", ")
  }

  /// The sentence with its form in bold yellow.
  static func sentenceText(_ option: ChoicePrompt.Option) -> AttributedString {
    var before = AttributedString(option.before)
    before.foregroundColor = .customForeground
    var form = AttributedString(option.form)
    form.foregroundColor = .customYellow
    // Its own font: a strongly emphasized run stays regular in a serif Text.
    form.font = Font.system(.title3, design: .serif).bold()
    var after = AttributedString(option.after)
    after.foregroundColor = .customForeground
    var sentence = before + form + after
    sentence.languageIdentifier = "es"
    return sentence
  }
}
