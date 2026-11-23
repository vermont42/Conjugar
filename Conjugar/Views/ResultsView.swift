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

  private var accuracy: Double {
    let total = quiz.questions.count
    guard total > 0 else { return 0 }
    let earned = quiz.results.reduce(0) { $0 + $1.rawValue }
    return Double(earned) / Double(total * ConjugationResult.totalMatch.rawValue)
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

        LazyVStack(spacing: 0) {
          ForEach(Array(quiz.questions.enumerated()), id: \.offset) { index, question in
            resultRow(index: index, verb: question.verb, tense: question.tense, person: question.personNumber)
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

  private var summaryCard: some View {
    VStack(spacing: Layout.defaultSpacing) {
      Text(verbatim: "\(quiz.score)")
        .font(.heroNumeral)
        .foregroundStyle(scoreColor)
        .contentTransition(.numericText())
        .accessibilityLabel(L.Quiz.score + " \(quiz.score)")
        .accessibilityIdentifier("results_score")  // screenshot-driver anchor

      countLine

      HStack(spacing: Layout.defaultSpacing) {
        Text(quiz.lastLevel.localizedName).metadataPill(tint: .customYellow)
        Text(quiz.lastRegion.localizedRegion).metadataPill(tint: .customBlue)
        Text(quiz.elapsedTime.timeString).metadataPill(tint: .customForeground)
      }
    }
    .frame(maxWidth: .infinity)
    .card()
  }

  /// "Correct: 25 / 30 · Second Try: 2", the second part only when an answer was right on its
  /// second attempt.
  private var countLine: some View {
    var line = "\(L.Results.correct): \(quiz.correctCount) / \(quiz.questionCount)"
    if quiz.secondAttemptCount > 0 {
      line += " · \(L.Results.secondTry): \(quiz.secondAttemptCount)"
    }
    return Text(verbatim: line)
      .font(.subheadline.monospacedDigit())
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityIdentifier("results_counts")
  }

  private func resultRow(index: Int, verb: String, tense: DisplayTense, person: DisplayPersonNumber) -> some View {
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
        Text(ReflexivePronoun.citationForm(of: verb).lowercased())
          .font(.headline)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)
        Text(verbatim: person == .none ? tense.displayName : "\(tense.displayName), \(person.shortDisplayName)")
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack(spacing: 4) {
          Text(L.Quiz.yourAnswer + ":").font(.caption).foregroundStyle(.secondary)
          Text(proposed.lowercased())
            .font(.callout)
            .foregroundStyle(isRight ? Color.customForeground : Color.customBlue)
        }
        if let firstAttempt {
          HStack(spacing: 4) {
            Text(L.Results.firstTry + ":").font(.caption).foregroundStyle(Color.customYellow)
            Text(Self.spanish(firstAttempt.lowercased()))
              .font(.callout)
              .foregroundStyle(Color.customYellow)
          }
          .accessibilityElement(children: .combine)
        }
        if !isRight {
          HStack(spacing: 4) {
            Text(L.Quiz.correctAnswer + ":").font(.caption).foregroundStyle(.secondary)
            ConjugationText(form: correct).font(.callout)
          }
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
