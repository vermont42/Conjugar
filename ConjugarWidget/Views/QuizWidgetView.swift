//
//  QuizWidgetView.swift
//  ConjugarWidget
//
//  The Quiz widget's UI: an unanswered state with tappable answer buttons, and an
//  answered state showing correct/incorrect. Answer order is shuffled deterministically
//  from the question id so it stays stable across timeline reloads. Ported from Conjuguer.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import SwiftUI
import WidgetKit

struct QuizWidgetView: View {
  let entry: QuizEntry

  private var quiz: WidgetQuizQuestion { entry.snapshot.quizQuestion }

  var body: some View {
    if entry.isAnswered {
      answeredView
    } else {
      questionView
    }
  }

  private var questionView: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(quiz.tenseDisplay)
        .font(.system(size: 9))
        .foregroundStyle(.secondary)
        .lineLimit(1)
      HStack(spacing: 3) {
        Text(quiz.infinitive)
          .font(.caption)
          .fontWeight(.bold)
          .fontDesign(.serif)
        if let pronoun = quiz.pronoun {
          Text(verbatim: "(\(pronoun))")
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
        }
      }
      .lineLimit(1)
      .minimumScaleFactor(0.4)
      Spacer(minLength: 0)
      VStack(spacing: 2) {
        ForEach(shuffledAnswers, id: \.self) { answer in
          answerButton(answer: answer)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(WidgetDeeplink.verb(quiz.infinitive))
  }

  private var answeredView: some View {
    VStack(spacing: 8) {
      Image(systemName: entry.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
        .font(.largeTitle)
        .foregroundStyle(entry.wasCorrect ? .green : .red)
      Text(entry.wasCorrect ? WidgetL.QuizWidget.correct : WidgetL.QuizWidget.incorrect)
        .font(.headline)
      if !entry.wasCorrect {
        Text(mixedCase: quiz.correctAnswer)
          .font(.subheadline)
          .fontWeight(.semibold)
          .fontDesign(.serif)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .widgetURL(WidgetDeeplink.verb(quiz.infinitive))
  }

  private func answerButton(answer: String) -> some View {
    Button(intent: AnswerQuizIntent(selectedAnswer: answer, questionID: quiz.questionID)) {
      Text(mixedCase: answer)
        .font(.caption2)
        .fontWeight(.medium)
        .fontDesign(.serif)
        .lineLimit(1)
        .minimumScaleFactor(0.4)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(.fill.quaternary, in: Capsule())
    }
    .buttonStyle(.plain)
  }

  // Deterministic shuffle keyed on the question id so the layout is stable across reloads.
  private var shuffledAnswers: [String] {
    var answers = quiz.wrongAnswers
    answers.append(quiz.correctAnswer)
    var hasher = Hasher()
    hasher.combine(quiz.questionID)
    var rng = SeededRNG(seed: UInt64(bitPattern: Int64(hasher.finalize())))
    answers.shuffle(using: &rng)
    return answers
  }
}

/// A tiny deterministic RNG (SplitMix64) so answer order depends only on the question id.
private struct SeededRNG: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}
