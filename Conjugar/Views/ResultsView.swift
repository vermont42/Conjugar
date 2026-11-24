//
//  ResultsView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct ResultsView: View {
  /// The tab's quiz, or Test Me's own in a verb page's sheet.
  let quiz: Quiz
  /// Continues the session with another round, offered while `Quiz.canContinue`.
  var onTenMore: (() -> Void)?
  /// The rows whose example sentence is open.
  @State private var openExamples: Set<Int> = []

  private var accuracy: Double {
    guard quiz.maximumScore > 0 else { return 0 }
    return Double(quiz.score) / Double(quiz.maximumScore)
  }

  private var scoreColor: Color {
    switch accuracy {
    case 0.8...: return .customGreen
    case 0.5..<0.8: return .customYellow
    default: return .customRed
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: Layout.doubleDefaultSpacing) {
        summaryCard

        if let onTenMore, quiz.canContinue {
          Button(continueLabel, action: onTenMore)
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityHint(continueHint)
            .accessibilityIdentifier("results_ten_more")
        }

        LazyVStack(spacing: 0) {
          let exampleRows = Self.exampleRows(in: quiz)
          ForEach(Array(quiz.questions.enumerated()), id: \.offset) { index, question in
            resultRow(index: index, question: question, offersExample: exampleRows.contains(index))
            Divider().padding(.leading)
          }
        }
      }
      .padding()
      .frame(maxWidth: Layout.readingWidth)
      .frame(maxWidth: .infinity)
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(L.Results.title)
    .navigationBarTitleDisplayMode(.inline)
    .onAppear { Current.analytics.signal(name: .viewResultsView) }
  }

  // A model's round is as many verbs as the model and the known models can give, which may be
  // fewer than five, so its button promises a round rather than a number.
  private var continueLabel: String {
    if quiz.scope.modelPractice != nil {
      return L.ModelPractice.anotherRound
    }
    return quiz.scope.isVerbEssentials ? L.VerbEssentials.fiveMore : L.Results.tenMore
  }

  private var continueHint: String {
    if quiz.scope.modelPractice != nil {
      return L.ModelPractice.anotherRoundHint
    }
    return quiz.scope.isVerbEssentials ? L.VerbEssentials.fiveMoreHint : L.Results.tenMoreHint
  }

  private var summaryCard: some View {
    VStack(spacing: Layout.defaultSpacing) {
      Text(verbatim: "\(quiz.score)")
        .font(.heroNumeral)
        .foregroundStyle(scoreColor)
        .contentTransition(.numericText())
        .accessibilityLabel(L.Quiz.score + " \(quiz.score)")
        .accessibilityIdentifier("results_score")  // screenshot-driver anchor

      countLine

      // Wraps once a long level and region name meet the time on an iPhone.
      FlowLayout(spacing: Layout.defaultSpacing, centersRows: true) {
        // A model's practice asks the same at every level.
        if quiz.scope.modelPractice == nil {
          Text(quiz.lastLevel.localizedName).metadataPill(tint: .customYellow)
        }
        Text(quiz.lastRegion.localizedRegion).metadataPill(tint: .customBlue)
        if Current.settings.quizClock == .show {
          Text(quiz.elapsedTime.timeString).metadataPill(tint: .customForeground)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .card()
  }

  /// "Correct: 8 / 10 · Second Try: 1 · Asked Again: 1 / 2", the second part only when an answer
  /// was right on its second attempt and the third only when a question was asked again. The
  /// parts wrap whole.
  private var countLine: some View {
    var parts = ["\(L.Results.correct): \(quiz.correctCount) / \(quiz.questionCount)"]
    if quiz.secondAttemptCount > 0 {
      parts.append("\(L.Results.secondTry): \(quiz.secondAttemptCount)")
    }
    if quiz.reaskCount > 0 {
      parts.append("\(L.Results.askedAgain): \(quiz.reaskCorrectCount) / \(quiz.reaskCount)")
    }
    return FlowLayout(spacing: 6, centersRows: true) {
      ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
        Text(verbatim: index < parts.count - 1 ? part + " ·" : part)
      }
    }
    .font(.subheadline.monospacedDigit())
    .foregroundStyle(.secondary)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(parts.joined(separator: ", "))
    .accessibilityIdentifier("results_counts")
  }

  /// The rows that offer their verb's example sentence: each verb's first right row, so that a
  /// right answer is rewarded and the quiz itself never pauses after one.
  private static func exampleRows(in quiz: Quiz) -> Set<Int> {
    var rows: Set<Int> = []
    var verbs: Set<String> = []
    for index in quiz.results.indices where quiz.results[index] != .noMatch && quiz.questions.indices.contains(index) {
      let verb = quiz.questions[index].verb
      if !verbs.contains(verb), ExampleData.example(for: verb) != nil {
        verbs.insert(verb)
        rows.insert(index)
      }
    }
    return rows
  }

  @ViewBuilder
  private func exampleReveal(index: Int, verb: String) -> some View {
    if let example = ExampleData.example(for: verb) {
      let isOpen = openExamples.contains(index)
      Button {
        withAnimation(.snappy) {
          if isOpen {
            openExamples.remove(index)
          } else {
            openExamples.insert(index)
          }
        }
      } label: {
        // An HStack, not a Label, whose icon would sit apart from its title in a row.
        HStack(spacing: 4) {
          Image(systemName: isOpen ? "book.fill" : "book")
          Text(L.Verb.exampleUse)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.customYellow)
      }
      .buttonStyle(.plain)
      .accessibilityHint(L.Results.exampleHint)
      .accessibilityAddTraits(isOpen ? .isSelected : [])
      .accessibilityIdentifier("results_example_\(index)")

      if isOpen {
        VStack(alignment: .leading, spacing: 4) {
          Text(Self.spanish(example.es))
            .font(.callout)
            .fontDesign(.serif)
            .foregroundStyle(Color.customForeground)
          Text(example.en)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(example.provenance.attribution)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .transition(.opacity)
      }
    }
  }

  private func resultRow(index: Int, question: QuizQuestion, offersExample: Bool) -> some View {
    let (verb, tense, person) = (question.verb, question.tense, question.personNumber)
    let proposed = index < quiz.proposedAnswers.count ? quiz.proposedAnswers[index] : ""
    let correct = index < quiz.correctAnswers.count ? quiz.correctAnswers[index] : ""
    let result = index < quiz.results.count ? quiz.results[index] : ConjugationResult.noMatch
    let isRight = result != .noMatch
    let firstAttempt = result == .secondAttemptMatch && index < quiz.firstAttempts.count ? quiz.firstAttempts[index] : nil

    return HStack(alignment: .top, spacing: Layout.defaultSpacing) {
      Group {
        switch result {
        case .totalMatch:
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Color.customGreen)
        case .secondAttemptMatch:
          Image(systemName: "circle.lefthalf.filled")
            .foregroundStyle(Color.customYellow)
            .accessibilityLabel(L.Results.secondTry)
        case .noMatch:
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(Color.customRed)
        }
      }

      VStack(alignment: .leading, spacing: 2) {
        // Name the Form's row shows its prompt, since the verb and cell are what it asked for.
        if let recognition = question.recognition {
          ConjugationText(form: recognition.prompt)
            .font(.headline)
        } else {
          Text(ReflexivePronoun.citationForm(of: verb).lowercased())
            .font(.headline)
            .fontDesign(.serif)
            .foregroundStyle(Color.customYellow)
          Text(verbatim: person == .none ? tense.displayName : "\(tense.displayName), \(person.shortDisplayName)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        if question.isReask {
          // Text, not a Label, whose icon would sit apart from its title in a row.
          Text("\(Image(systemName: "arrow.counterclockwise")) \(L.Quiz.askedAgain)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.customYellow)
            .accessibilityLabel(L.Quiz.askedAgain)
        }

        HStack(spacing: 4) {
          Text(L.Quiz.yourAnswer + ":").font(.caption).foregroundStyle(.secondary)
          // A recognition answer keeps its tense's capitals: "ser · Pretérito (yo)".
          Text(Self.spanish(question.recognition == nil ? proposed.lowercased() : proposed))
            .font(.callout)
            .foregroundStyle(isRight ? Color.customForeground : Color.customBlue)
        }
        if let firstAttempt {
          HStack(spacing: 4) {
            Text(L.Results.firstTry + ":").font(.caption).foregroundStyle(Color.customYellow)
            Text(Self.spanish(question.recognition == nil ? firstAttempt.lowercased() : firstAttempt))
              .font(.callout)
              .foregroundStyle(Color.customYellow)
          }
          .accessibilityElement(children: .combine)
        }
        if !isRight, let recognition = question.recognition {
          VStack(alignment: .leading, spacing: 2) {
            Text(L.Quiz.correctAnswer + ":").font(.caption).foregroundStyle(.secondary)
            ForEach(recognition.answerLines, id: \.self) { line in
              Text(Self.spanish(line))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .accessibilityElement(children: .combine)
        } else if !isRight {
          HStack(spacing: 4) {
            Text(L.Quiz.correctAnswer + ":").font(.caption).foregroundStyle(.secondary)
            ConjugationText(form: correct).font(.callout)
          }
        }
        if offersExample {
          exampleReveal(index: index, verb: verb)
        }
      }

      Spacer()
    }
    .padding(.vertical, Layout.defaultSpacing)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Spanish text that VoiceOver reads in Spanish, whatever the device's language.
  private static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
  }
}
