//
//  QuizView.swift
//  Conjugar
//
//  The SwiftUI quiz screen, replacing the UIKit QuizVC/QuizUIV. It observes the
//  `@MainActor @Observable Quiz` directly (the QuizDelegate is gone). A briefing +
//  primary Start CTA when idle; an in-progress card with a hero question, a visible
//  focus-ringed answer field, a progress bar, haptics + an unmissable answer flash,
//  and a de-emphasized status strip.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct QuizView: View {
  @State private var quiz = Current.quiz
  @State private var answer = ""
  @State private var lastProposed: String?
  @State private var lastCorrect: String?
  @State private var lastResult: ConjugationResult?
  @State private var answerToken = 0
  @State private var showingResults = false
  @State private var showingGameCenterPrompt = false
  @FocusState private var fieldFocused: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(AppRouter.self) private var router

  var body: some View {
    NavigationStack {
      Group {
        switch quiz.quizState {
        case .notStarted, .finished:
          briefing
        case .inProgress:
          inProgress
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.customBackground.ignoresSafeArea())
      .navigationTitle(L.Quiz.localizedTitle)
      .navigationDestination(isPresented: $showingResults) { ResultsView() }
      .toolbar {
        if quiz.quizState == .inProgress {
          ToolbarItem(placement: .cancellationAction) {
            Button(L.Quiz.quit, role: .destructive) { quit() }
              .tint(.customRed)
          }
        }
      }
      .onAppear {
        Current.analytics.recordVisitation(viewController: "\(QuizView.self)")
        maybePromptGameCenter()
      }
      .onChange(of: router.pendingQuizStart, initial: true) { _, shouldStart in
        guard shouldStart else { return }
        router.pendingQuizStart = false
        if quiz.quizState != .inProgress {
          startQuiz()
        }
      }
      .alert(L.Quiz.gameCenter, isPresented: $showingGameCenterPrompt) {
        Button(L.Quiz.no, role: .destructive) {
          SoundPlayer.playRandomSadTrombone()
          Current.settings.userRejectedGameCenter = true
        }
        Button(L.Quiz.yes) { authenticateGameCenter() }
      } message: {
        Text(L.Quiz.gameCenterMessage)
      }
    }
  }

  private var briefing: some View {
    VStack(spacing: Layout.tripleDefaultSpacing) {
      Spacer()

      Image(systemName: "graduationcap.fill")
        .font(.system(size: 56))
        .foregroundStyle(Color.customYellow)
        .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
        .accessibilityHidden(true)

      Text(L.Quiz.briefing)
        .font(.body)
        .foregroundStyle(Color.customForeground)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: Layout.defaultSpacing) {
        Text(Current.settings.difficulty.localizedDifficulty)
          .metadataPill(tint: .customYellow)
        Text(Current.settings.region.localizedRegion)
          .metadataPill(tint: .customBlue)
      }

      startButton

      Spacer()
    }
    .padding()
    .frame(maxWidth: Layout.readingWidth)
    .frame(maxWidth: .infinity)
  }

  /// The primary Start CTA has a subtle "breathing" pulse: the button gently
  /// scales 1.0 ↔ 1.1 to draw the eye without jarring >1.5× jumps. Suppressed
  /// under Reduce Motion.
  @ViewBuilder
  private var startButton: some View {
    let base = Button(L.Quiz.start) { startQuiz() }
      .buttonStyle(PrimaryButtonStyle())

    if reduceMotion {
      base
    } else {
      base.phaseAnimator([1.0, 1.1]) { content, scale in
        content.scaleEffect(scale)
      } animation: { _ in
        .easeInOut(duration: 0.9)
      }
    }
  }

  private var inProgress: some View {
    VStack(spacing: Layout.doubleDefaultSpacing) {
      ProgressView(value: Double(quiz.currentQuestionIndex), total: Double(max(quiz.questionCount, 1)))
        .tint(.customYellow)

      questionCard

      answerField

      feedbackReveal
        .frame(height: 64)

      statusStrip

      Spacer()
    }
    .padding()
    .frame(maxWidth: Layout.readingWidth)
    .frame(maxWidth: .infinity)
    .sensoryFeedback(trigger: answerToken) { _, _ in
      switch lastResult {
      case .totalMatch: return .success
      case .partialMatch: return .warning
      case .noMatch: return .error
      case .none: return nil
      }
    }
  }

  private var questionCard: some View {
    VStack(spacing: Layout.defaultSpacing) {
      Text(quiz.verb)
        .font(.largeTitle.bold())
        .fontDesign(.serif)
        .foregroundStyle(Color.customYellow)

      let gloss = VerbMap.shared.entry(for: quiz.verb)?.gloss ?? ""
      if !gloss.isEmpty {
        Text(gloss)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Text(verbatim: "\(quiz.currentPersonNumber.pronoun) · \(quiz.tense.displayName)")
        .font(.title3.weight(.semibold))
        .fontDesign(.serif)
        .foregroundStyle(Color.customForeground)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .card()
  }

  private var answerField: some View {
    TextField(text: $answer, prompt: Text(L.Quiz.conjugation).foregroundStyle(.secondary)) {
      Text(verbatim: "")
    }
      .accessibilityLabel(L.Quiz.conjugation)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .submitLabel(.next)
      .focused($fieldFocused)
      .font(.title3)
      .fontDesign(.serif)
      .multilineTextAlignment(.center)
      .padding()
      .background(Color.customForeground.opacity(0.06), in: RoundedRectangle(cornerRadius: Layout.cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
          .strokeBorder(fieldFocused ? Color.customYellow : Color.customCardBorder, lineWidth: fieldFocused ? 2 : 1)
      )
      .onSubmit { submit() }
  }

  @ViewBuilder
  private var feedbackReveal: some View {
    if let result = lastResult {
      HStack(alignment: .top, spacing: Layout.defaultSpacing) {
        Image(systemName: result == .noMatch ? "xmark.circle.fill" : "checkmark.circle.fill")
          .foregroundStyle(result == .totalMatch ? Color.customGreen : result == .partialMatch ? Color.customYellow : Color.customRed)
          .font(.title2)

        if let correct = lastCorrect {
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
              Text(L.Quiz.yourAnswer + ":").font(.caption).foregroundStyle(.secondary)
              Text(lastProposed ?? "").font(.callout).foregroundStyle(Color.customBlue)
            }
            HStack(spacing: 4) {
              Text(L.Quiz.correctAnswer + ":").font(.caption).foregroundStyle(.secondary)
              ConjugationText(form: correct).font(.callout)
            }
          }
        }
      }
      .transition(.opacity)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var statusStrip: some View {
    HStack {
      Label {
        Text(verbatim: "\(quiz.score)")
      } icon: {
        Image(systemName: "star.fill")
      }
      .foregroundStyle(.secondary)
      .numeric()
      Spacer()
      Label(quiz.elapsedTime.timeString, systemImage: "clock")
        .foregroundStyle(.secondary)
        .numeric()
    }
    .font(.footnote)
    .labelStyle(.titleAndIcon)
  }

  private func startQuiz() {
    TryQuizTip().invalidate(reason: .actionPerformed)
    SoundPlayer.play(.gun)
    Current.quiz.start()
    answer = ""
    lastProposed = nil
    lastCorrect = nil
    lastResult = nil
    fieldFocused = true
    Current.analytics.recordQuizStart()
  }

  private func submit() {
    guard !answer.isEmpty else { return }
    let proposed = answer
    let (result, correct) = Current.quiz.process(proposedAnswer: proposed)
    switch result {
    case .totalMatch: SoundPlayer.play(.chime)
    case .partialMatch: SoundPlayer.play(.chirp)
    case .noMatch: SoundPlayer.play(.buzz)
    }
    withAnimation(.snappy) {
      lastProposed = proposed
      lastCorrect = correct
      lastResult = result
    }
    answer = ""
    answerToken += 1
    if quiz.quizState == .finished {
      finish()
    } else {
      fieldFocused = true
    }
  }

  private func finish() {
    SoundPlayer.playRandomApplause()
    Current.gameCenter.showLeaderboard()
    Current.analytics.recordQuizCompletion(score: Current.quiz.score)
    showingResults = true
  }

  private func quit() {
    Current.quiz.quit()
    SoundPlayer.playRandomSadTrombone()
    Current.analytics.recordQuizQuit(currentQuestionIndex: Current.quiz.currentQuestionIndex, score: Current.quiz.score)
    fieldFocused = false
    lastResult = nil
  }

  private func maybePromptGameCenter() {
    switch GameCenterPrompt.decision(
      isAuthenticated: Current.gameCenter.isAuthenticated,
      userRejected: Current.settings.userRejectedGameCenter,
      didShowDialog: Current.settings.didShowGameCenterDialog
    ) {
    case .doNothing:
      break
    case .showDialog:
      Current.settings.didShowGameCenterDialog = true
      showingGameCenterPrompt = true
    case .authenticate:
      authenticateGameCenter()
    }
  }

  private func authenticateGameCenter() {
    // Fire-and-forget: GameKit's authenticateHandler presents its own login sheet
    // against the live window and publishes `isAuthenticated` when it settles.
    Current.gameCenter.authenticate()
  }
}
