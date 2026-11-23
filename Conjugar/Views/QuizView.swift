//
//  QuizView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct QuizView: View {
  /// Nil for the Quiz tab. A scope makes this Test Me's sheet (`QuizSheet`), which starts that
  /// quiz as it appears, shows the results in place, and closes when the learner is done.
  private let sheetScope: QuizScope?
  @State private var quiz: Quiz
  /// What the tab's picker offers. The choice is not stored, so the tab opens on All Verbs.
  @State private var tabScope = TabQuizScope.allVerbs
  @State private var answer = ""
  @State private var answerSelection: TextSelection?
  @State private var lastProposed: String?
  @State private var lastCorrect: String?
  @State private var lastResult: ConjugationResult?
  @State private var answerToken = 0
  @State private var showingResults = false
  @State private var showingGameCenterPrompt = false
  @FocusState private var fieldFocused: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.horizontalSizeClass) private var sizeClass
  @Environment(\.dismiss) private var dismiss
  @Environment(AppRouter.self) private var router

  init(quiz: Quiz = Current.quiz, sheetScope: QuizScope? = nil) {
    _quiz = State(initialValue: quiz)
    self.sheetScope = sheetScope
  }

  var body: some View {
    NavigationStack {
      Group {
        switch quiz.quizState {
        case .notStarted, .finished:
          if sheetScope == nil {
            startScreen
          } else if quiz.quizState == .finished {
            ResultsView(quiz: quiz)
          } else {
            // Something must be on screen for `onAppear` to start the sheet's quiz.
            Color.clear
          }
        case .inProgress:
          inProgress
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.customBackground.ignoresSafeArea())
      .navigationTitle(sheetTitle ?? L.Quiz.localizedTitle)
      .navigationBarTitleDisplayMode(sheetScope == nil ? .automatic : .inline)
      .navigationDestination(isPresented: $showingResults) { ResultsView(quiz: quiz) }
      .toolbar {
        if quiz.quizState == .inProgress {
          ToolbarItem(placement: .cancellationAction) {
            Button(L.Quiz.quit, role: .destructive) { quit() }
              .tint(.customRed)
          }
          // iPadOS's keyboard shows no toolbar items, so an iPad has the keys under the field.
          if !isLarge {
            ToolbarItem(placement: .keyboard) {
              letterKeys
            }
          }
        } else if sheetScope != nil {
          ToolbarItem(placement: .confirmationAction) {
            Button(L.Quiz.done) { dismiss() }
          }
        }
      }
      .onAppear {
        if let sheetScope {
          if quiz.quizState == .notStarted {
            startQuiz(scope: sheetScope)
          }
          return
        }
        Current.analytics.signal(name: .viewQuizView)
        maybePromptGameCenter()
      }
      .onChange(of: router.pendingQuizStart, initial: true) { _, linkSource in
        // The tab's view handles the deeplink, never Test Me's sheet.
        guard let linkSource, sheetScope == nil else { return }
        router.pendingQuizStart = nil
        if quiz.quizState != .inProgress {
          startQuiz(scope: .allVerbs(source: linkSource))
        }
      }
      .alert(L.Quiz.gameCenter, isPresented: $showingGameCenterPrompt) {
        Button(L.Quiz.no, role: .destructive) {
          Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true)
          Current.settings.userRejectedGameCenter = true
        }
        Button(L.Quiz.yes) { authenticateGameCenter() }
      } message: {
        Text(L.Quiz.gameCenterMessage)
      }
    }
  }

  /// The sheet's title: a collection's name, or the verb Test Me asks about. Nil on the tab.
  private var sheetTitle: String? {
    sheetScope?.title ?? sheetScope?.verbs?.first.map { ReflexivePronoun.citationForm(of: $0) }
  }

  private var myVerbs: [VerbMapEntry] {
    Current.learnerVerbs.myVerbs
  }

  /// The scope the picker's choice starts.
  private var chosenScope: QuizScope {
    switch tabScope {
    case .allVerbs:
      return .allVerbs
    case .myVerbs:
      return .myVerbs(myVerbs.map(\.infinitive))
    }
  }

  /// An iPad's start screen has room for a bigger composition.
  private var isLarge: Bool {
    sizeClass == .regular
  }

  /// A big symbol for the scope, the picker and Start, three facts about the quiz, and for My
  /// Verbs, the verbs it will ask about.
  private var startScreen: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: isLarge ? Layout.tripleDefaultSpacing * 2 : Layout.tripleDefaultSpacing) {
          scopeHero

          VStack(spacing: Layout.doubleDefaultSpacing) {
            Picker(L.Quiz.scope, selection: $tabScope.animation(.snappy)) {
              ForEach(TabQuizScope.allCases, id: \.self) { scope in
                Text(scope.displayName)
                  .tag(scope)
              }
            }
            .pickerStyle(.segmented)
            .controlSize(isLarge ? .large : .regular)
            .accessibilityIdentifier("quiz_scope_picker")

            startButton
              // `PrimaryButtonStyle` fixes its own font, so a scale is the way to enlarge it.
              .scaleEffect(isLarge ? 1.4 : 1)
              .padding(.vertical, isLarge ? Layout.defaultSpacing : 0)
              .disabled(tabScope == .myVerbs && myVerbs.isEmpty)
              .opacity(tabScope == .myVerbs && myVerbs.isEmpty ? 0.4 : 1)
          }

          HStack(alignment: .top, spacing: Layout.defaultSpacing) {
            QuizFactTile(systemImage: "list.number", value: "\(QuizScope.fullLength)", label: L.Quiz.questionsLabel, isLarge: isLarge)
            QuizFactTile(
              systemImage: difficultySymbol,
              value: Current.settings.difficulty.localizedDifficulty,
              label: L.Settings.difficulty,
              isLarge: isLarge
            )
            QuizFactTile(systemImage: "globe.americas.fill", value: Current.settings.region.localizedRegion, label: L.Settings.region, isLarge: isLarge)
          }
          // Equal heights when one label wraps to two lines.
          .fixedSize(horizontal: false, vertical: true)

          if tabScope == .myVerbs, !myVerbs.isEmpty {
            myVerbChips
          }
        }
        .padding(.horizontal, Layout.doubleDefaultSpacing)
        .padding(.vertical, Layout.doubleDefaultSpacing)
        .frame(maxWidth: isLarge ? Layout.readingWidth : 560)
        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
      }
      .scrollBounceBehavior(.basedOnSize)
    }
  }

  private var difficultySymbol: String {
    switch Current.settings.difficulty {
    case .easy:
      return "gauge.with.dots.needle.0percent"
    case .moderate:
      return "gauge.with.dots.needle.50percent"
    case .difficult:
      return "flame.fill"
    }
  }

  /// The scope's symbol, its name, and a line saying what the quiz will ask about.
  private var scopeHero: some View {
    VStack(spacing: Layout.defaultSpacing) {
      Image(systemName: heroSymbol)
        .font(.system(size: isLarge ? 180 : 96, weight: .semibold))
        .foregroundStyle(
          LinearGradient(colors: [.customYellow, .customYellow.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        )
        .contentTransition(.symbolEffect(.replace))
        .symbolEffect(.bounce, value: reduceMotion ? TabQuizScope.allVerbs : tabScope)
        .frame(height: isLarge ? 220 : 120)
        .accessibilityHidden(true)

      Text(tabScope == .allVerbs ? L.BrowseVerbs.verbCount(count: VerbMap.shared.entries.count) : L.MyVerbs.title)
        .font(isLarge ? .largeTitle.bold() : .title.bold())
        .fontDesign(.serif)
        .foregroundStyle(Color.customForeground)
        .contentTransition(.opacity)

      Text(heroDescription)
        .font(isLarge ? .title3 : .subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("quiz_scope_note")
    }
    .accessibilityElement(children: .combine)
  }

  private var heroSymbol: String {
    switch tabScope {
    case .allVerbs:
      return "books.vertical.fill"
    case .myVerbs:
      return myVerbs.isEmpty ? "star" : "star.fill"
    }
  }

  private var heroDescription: String {
    switch tabScope {
    case .allVerbs:
      return L.Quiz.briefing
    case .myVerbs:
      return myVerbs.isEmpty ? L.Quiz.myVerbsEmpty : L.Quiz.myVerbsCount(count: myVerbs.count)
    }
  }

  private static let chipLimit = 12

  /// The verbs a My Verbs quiz will ask about, so the learner sees the list before starting.
  private var myVerbChips: some View {
    let shown = myVerbs.prefix(Self.chipLimit)
    let hiddenCount = myVerbs.count - shown.count
    return FlowLayout(spacing: Layout.defaultSpacing, centersRows: true) {
      ForEach(Array(shown), id: \.infinitive) { entry in
        Text(Self.spanish(entry.citationForm))
          .font(isLarge ? .title3 : .subheadline)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Color.customYellow.opacity(0.08), in: Capsule())
      }
      if hiddenCount > 0 {
        Text(L.Quiz.moreVerbs(count: hiddenCount))
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.vertical, 6)
      }
    }
    .frame(maxWidth: .infinity)
    .transition(.opacity.combined(with: .move(edge: .bottom)))
    .accessibilityIdentifier("quiz_my_verbs_chips")
  }

  /// Spanish text that VoiceOver reads in Spanish, whatever the device's language.
  private static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
  }

  /// The primary Start CTA has a subtle "breathing" pulse: the button gently
  /// scales 1.0 ↔ 1.1 to draw the eye without jarring >1.5× jumps. Suppressed
  /// under Reduce Motion.
  @ViewBuilder
  private var startButton: some View {
    let base = Button(L.Quiz.start) { startQuiz(scope: chosenScope) }
      .buttonStyle(PrimaryButtonStyle())
      .accessibilityIdentifier("quiz_start_button")  // screenshot-driver anchor

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

  /// Scrolls rather than compresses: with the keyboard up at a large Dynamic Type size,
  /// a plain VStack squeezed the question card until the tense name truncated (e.g.
  /// "presente de ind…"), hiding exactly the words that distinguish subjuntivo 1 from 2.
  /// SwiftUI's own keyboard avoidance can leave the field half-covered at accessibility
  /// sizes, so the field is scrolled into view whenever the keyboard or question changes.
  private var inProgress: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: Layout.doubleDefaultSpacing) {
          ProgressView(value: Double(quiz.currentQuestionIndex), total: Double(max(quiz.questionCount, 1)))
            .tint(.customYellow)

          questionCard

          answerField
            .id(QuizView.answerFieldID)

          if isLarge {
            letterKeys
          }

          feedbackReveal
            .frame(minHeight: 64)

          statusStrip
        }
        .padding()
        .frame(maxWidth: Layout.readingWidth)
        .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.never)
      .scrollBounceBehavior(.basedOnSize)
      .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
        revealAnswerField(proxy)
      }
      .onChange(of: quiz.currentQuestionIndex) {
        revealAnswerField(proxy)
      }
    }
    // A link's quiz starts as the tab appears, before the field exists, so the field takes the
    // keyboard again once it is on screen, or the letter keys never join the keyboard.
    .onAppear {
      fieldFocused = false
      Task { @MainActor in
        fieldFocused = true
      }
    }
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
      Text(ReflexivePronoun.citationForm(of: quiz.verb))
        .font(.largeTitle.bold())
        .fontDesign(.serif)
        .foregroundStyle(Color.customYellow)

      let gloss = VerbMap.shared.entry(for: quiz.verb)?.gloss ?? ""
      if !gloss.isEmpty {
        Text(gloss)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      // The person asked is in the answer's frame, below.
      Text(verbatim: quiz.tense.displayName)
        .font(.title3.weight(.semibold))
        .fontDesign(.serif)
        .foregroundStyle(Color.customForeground)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity)
    .card()
  }

  private static let answerFieldID = "answerField"

  /// A nil anchor scrolls the minimum distance, so this is a no-op whenever the field is
  /// already fully visible (the usual case at default text sizes).
  private func revealAnswerField(_ proxy: ScrollViewProxy) {
    withAnimation(.snappy) {
      proxy.scrollTo(QuizView.answerFieldID)
    }
  }

  private var answerField: some View {
    AnswerFrameView(
      frame: quiz.currentQuestion?.frame ?? AnswerFrame(segments: [.blank]),
      text: $answer,
      selection: $answerSelection,
      isFocused: $fieldFocused,
      identifier: "input_quiz_conjugation",  // screenshot-driver anchor
      onSubmit: submit
    )
  }

  private var letterKeys: some View {
    SpanishLetterKeyRow { letter in
      insertLetter(letter)
    }
  }

  /// Replaces the field's selection, or inserts at its cursor, and leaves the cursor after the
  /// letter. With no selection known, the letter goes at the end.
  private func insertLetter(_ letter: String) {
    var text = answer
    guard
      case .selection(let range) = answerSelection?.indices,
      range.lowerBound >= text.startIndex,
      range.upperBound <= text.endIndex
    else {
      answer.append(letter)
      return
    }
    let offset = text.distance(from: text.startIndex, to: range.lowerBound) + letter.count
    text.replaceSubrange(range, with: letter)
    answer = text
    answerSelection = TextSelection(insertionPoint: text.index(text.startIndex, offsetBy: offset))
  }

  @ViewBuilder
  private var feedbackReveal: some View {
    if let result = lastResult {
      HStack(alignment: .top, spacing: Layout.defaultSpacing) {
        Image(systemName: result == .noMatch ? "xmark.circle.fill" : "checkmark.circle.fill")
          .foregroundStyle(result == .totalMatch ? Color.customGreen : result == .partialMatch ? Color.customYellow : Color.customRed)
          .font(.title2)

        if result == .totalMatch, let spelling = quiz.lastCurrentSpelling {
          // "Correct. Spelled: rio", the form read in Spanish.
          ConjugationText(form: spelling, regularColor: .secondary)
            .font(.callout)
            .accessibilityLabel(Text(L.Quiz.correctSpelled + " ") + Text(Self.spanish(spelling.lowercased())))
            .accessibilityIdentifier("quiz_current_spelling")
        }

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

  private func startQuiz(scope: QuizScope) {
    TryQuizTip().invalidate(reason: .actionPerformed)
    guard quiz.start(scope: scope) else {
      return
    }
    Current.soundPlayer.play(.gun, shouldDebounce: false)
    answer = ""
    lastProposed = nil
    lastCorrect = nil
    lastResult = nil
    fieldFocused = true
    var parameters = [
      ParameterKey.difficulty.rawValue: quiz.lastDifficulty.rawValue,
      ParameterKey.source.rawValue: scope.source.rawValue
    ]
    // A quiz over a collection names it.
    if let collectionKey = scope.collectionKey {
      parameters[ParameterKey.collection.rawValue] = collectionKey
    }
    Current.analytics.signal(name: .startQuiz, parameters: parameters)
  }

  private func submit() {
    guard let question = quiz.currentQuestion, !answer.allSatisfy(\.isWhitespace) else { return }
    let proposed = question.answer(filling: answer)
    let (result, correct) = quiz.process(proposedAnswer: proposed)
    switch result {
    case .totalMatch: Current.soundPlayer.play(.chime, shouldDebounce: false)
    case .partialMatch: Current.soundPlayer.play(.chirp, shouldDebounce: false)
    case .noMatch: Current.soundPlayer.play(.buzz, shouldDebounce: false)
    }
    withAnimation(.snappy) {
      lastProposed = proposed
      lastCorrect = correct
      lastResult = result
    }
    answer = ""
    answerSelection = nil
    answerToken += 1
    if quiz.quizState == .finished {
      finish()
    } else {
      fieldFocused = true
    }
  }

  private func finish() {
    Current.soundPlayer.play(Sound.randomApplause, shouldDebounce: false)
    // A scoped quiz posts no score, so it shows no leaderboard.
    if quiz.scope.isRanked {
      Current.gameCenter.showLeaderboard()
    }
    Current.analytics.signal(
      name: .completeQuiz,
      parameters: [
        ParameterKey.difficulty.rawValue: quiz.lastDifficulty.rawValue,
        ParameterKey.elapsedTime.rawValue: "\(quiz.elapsedTime)",
        ParameterKey.score.rawValue: "\(quiz.score)",
        ParameterKey.source.rawValue: quiz.scope.source.rawValue
      ]
    )
    // The sheet shows the results in place of the question; the tab pushes them.
    fieldFocused = false
    if sheetScope == nil {
      showingResults = true
    }
  }

  private func quit() {
    quiz.quit()
    Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true)
    Current.analytics.signal(
      name: .quitQuiz,
      parameters: [
        ParameterKey.difficulty.rawValue: quiz.lastDifficulty.rawValue,
        ParameterKey.elapsedTime.rawValue: "\(quiz.elapsedTime)",
        ParameterKey.questionNumber.rawValue: "\(quiz.currentQuestionIndex + 1)",
        ParameterKey.score.rawValue: "\(quiz.score)",
        ParameterKey.source.rawValue: quiz.scope.source.rawValue
      ]
    )
    fieldFocused = false
    lastResult = nil
    if sheetScope != nil {
      dismiss()
    }
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

/// One fact about the quiz about to start: a yellow symbol, a value, and what the value is.
private struct QuizFactTile: View {
  let systemImage: String
  let value: String
  let label: String
  var isLarge = false

  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: systemImage)
        .font(isLarge ? .system(size: 48) : .title)
        .foregroundStyle(Color.customYellow)
        .contentTransition(.symbolEffect(.replace))
        .frame(height: isLarge ? 64 : 36)
        .accessibilityHidden(true)
      Text(verbatim: value)
        .font(isLarge ? .title2.bold() : .headline)
        .foregroundStyle(Color.customForeground)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text(label)
        .font(isLarge ? .subheadline : .caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.vertical, Layout.doubleDefaultSpacing)
    .padding(.horizontal, Layout.defaultSpacing)
    .background(Color.customYellow.opacity(0.06), in: RoundedRectangle(cornerRadius: Layout.cornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .strokeBorder(Color.customYellow.opacity(0.25), lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
  }
}

/// What the Quiz tab's picker offers. A quiz over one verb starts from that verb's page instead.
enum TabQuizScope: CaseIterable {
  case allVerbs
  case myVerbs

  var displayName: String {
    switch self {
    case .allVerbs:
      return L.Quiz.allVerbs
    case .myVerbs:
      return L.MyVerbs.title
    }
  }
}
