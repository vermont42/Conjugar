//
//  ResultsView.swift
//  Conjugar
//
//  The SwiftUI quiz-results screen, replacing the UIKit ResultsVC/ResultsUIV/
//  ResultCell. A hero score numeral color-coded by accuracy over a carded
//  difficulty/region/time summary, then a labeled, color-coded row per question.
//  Reads the finished `Current.quiz`.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct ResultsView: View {
  private let quiz = Current.quiz

  private var accuracy: Double {
    let total = quiz.questions.count
    guard total > 0 else { return 0 }
    let earned = zip(quiz.proposedAnswers, quiz.correctAnswers).reduce(0) { sum, pair in
      sum + ConjugationResult.compare(lhs: pair.0, rhs: pair.1).rawValue
    }
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
            resultRow(index: index, verb: question.0, tense: question.1, person: question.2)
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
    .onAppear { Current.analytics.recordVisitation(viewController: "\(ResultsView.self)") }
  }

  private var summaryCard: some View {
    VStack(spacing: Layout.defaultSpacing) {
      Text(verbatim: "\(quiz.score)")
        .font(.heroNumeral)
        .foregroundStyle(scoreColor)
        .contentTransition(.numericText())
        .accessibilityLabel(L.Quiz.score + " \(quiz.score)")

      HStack(spacing: Layout.defaultSpacing) {
        Text(quiz.lastDifficulty.localizedDifficulty).metadataPill(tint: .customYellow)
        Text(quiz.lastRegion.localizedRegion).metadataPill(tint: .customBlue)
        Text(quiz.elapsedTime.timeString).metadataPill(tint: .customForeground)
      }
    }
    .frame(maxWidth: .infinity)
    .card()
  }

  private func resultRow(index: Int, verb: String, tense: DisplayTense, person: DisplayPersonNumber) -> some View {
    let proposed = index < quiz.proposedAnswers.count ? quiz.proposedAnswers[index] : ""
    let correct = index < quiz.correctAnswers.count ? quiz.correctAnswers[index] : ""
    let result = ConjugationResult.compare(lhs: proposed, rhs: correct)
    let isRight = result == .totalMatch

    return HStack(alignment: .top, spacing: Layout.defaultSpacing) {
      Image(systemName: isRight ? "checkmark.circle.fill" : result == .partialMatch ? "circle.lefthalf.filled" : "xmark.circle.fill")
        .foregroundStyle(isRight ? Color.customGreen : result == .partialMatch ? Color.customYellow : Color.customRed)

      VStack(alignment: .leading, spacing: 2) {
        Text(verb.lowercased())
          .font(.headline)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)
        Text(verbatim: "\(tense.displayName), \(person.shortDisplayName)")
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack(spacing: 4) {
          Text(L.Quiz.yourAnswer + ":").font(.caption).foregroundStyle(.secondary)
          Text(proposed.lowercased())
            .font(.callout)
            .foregroundStyle(isRight ? Color.customForeground : Color.customBlue)
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
}
