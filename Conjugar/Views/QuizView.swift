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
  /// A Name the Form question's chosen tense and person, cleared for each question.
  @State private var recognitionTense: DisplayTense?
  @State private var recognitionPerson: DisplayPersonNumber?
  /// The haptic for the last answer: a light tap for a slip, which waits for one more attempt.
  @State private var lastFeedback: SensoryFeedback?
  /// Whether the check for the last answer, which was right, shows under the next question.
  @State private var showsRightAnswer = false
  @State private var answerToken = 0
  @State private var showingResults = false
  @State private var showingGameCenterPrompt = false
  @State private var isShowingQRCode = false
  /// The Share menu's frame in window coordinates, which an iPad's share popover anchors to.
  @State private var shareButtonFrame = CGRect.zero
  @FocusState private var fieldFocused: Bool
  @AccessibilityFocusState private var correctionHasAccessibilityFocus: Bool
  @AccessibilityFocusState private var choiceReasonHasAccessibilityFocus: Bool
  /// Pages opened from a held correction, pushed over the quiz, which waits beneath them.
  @State private var navigationPath = NavigationPath()
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.horizontalSizeClass) private var sizeClass
  @Environment(\.dismiss) private var dismiss
  @Environment(AppRouter.self) private var router

  init(quiz: Quiz = Current.quiz, sheetScope: QuizScope? = nil) {
    _quiz = State(initialValue: quiz)
    self.sheetScope = sheetScope
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      Group {
        switch quiz.quizState {
        case .notStarted, .finished:
          if sheetScope == nil {
            startScreen
          } else if quiz.quizState == .finished {
            ResultsView(quiz: quiz, onTenMore: continueSession)
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
      .navigationTitle(sheetTitle ?? sessionTitle ?? L.Quiz.localizedTitle)
      .navigationBarTitleDisplayMode(sheetScope == nil ? .automatic : .inline)
      .navigationDestination(isPresented: $showingResults) { ResultsView(quiz: quiz, onTenMore: continueSession) }
      .navigationDestination(for: VerbDestination.self) { destination in
        VerbView(verb: destination.infinitive, source: destination.source, marks: destination.marks)
      }
      .navigationDestination(for: QuizCorrectionModel.self) { destination in
        ModelView(model: destination.model, source: .quizCorrection)
      }
      .navigationDestination(for: ModelPracticeDestination.self) { _ in
        ModelPracticeListView()
      }
      .navigationDestination(for: MasteryDestination.self) { _ in
        MasteryView()
      }
      .navigationDestination(for: CustomQuizDestination.self) { destination in
        switch destination {
        case .editor:
          CustomQuizEditor()
        case .models:
          CustomQuizModelList()
        }
      }
      .verbPageDestinations()
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
        // Name the Form finds a prompt's verbs in the map, which takes a moment to load.
        Task.detached(priority: .utility) {
          _ = ConjugationMap.bundled
        }
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
    // A correction's links, and the links on the pages they open, push onto this stack.
    .environment(\.verbPagePush, VerbPagePush { navigationPath.append($0) })
    .environment(\.isBeneathQuiz, quiz.quizState == .inProgress)
    .accessibilityAction(.magicTap) {
      if quiz.isHeld {
        continueAfterCorrection()
      }
    }
    // Back from a page opened from the correction, the keyboard returns, so Return continues.
    .onChange(of: navigationPath.isEmpty) { _, isEmpty in
      if isEmpty, quiz.isHeld {
        refocusAnswer(after: .milliseconds(450))
      }
    }
  }

  /// The sheet's title: a collection's name, or the verb Test Me asks about. Nil on the tab.
  private var sheetTitle: String? {
    sheetScope?.title ?? sheetScope?.verbs?.first.map { ReflexivePronoun.citationForm(of: $0) }
  }

  /// A Review's, My Mistakes', or Verb Essentials' name while it runs on the tab, since its
  /// questions look like any quiz's.
  private var sessionTitle: String? {
    guard sheetScope == nil, quiz.quizState == .inProgress else {
      return nil
    }
    if quiz.scope.isVerbEssentials {
      return L.VerbEssentials.title
    }
    if quiz.scope.isRecognition {
      return L.Recognition.title
    }
    if quiz.scope.isSentences {
      return L.Sentences.title
    }
    return quiz.scope.recordSession?.title
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
    case .custom:
      return .custom(customQuiz, myVerbs: myVerbs.map(\.infinitive))
    }
  }

  private var customQuiz: CustomQuiz {
    Current.settings.customQuiz
  }

  /// A custom quiz kept from an earlier launch may name My Verbs after they have been cleared.
  private var customQuizLacksMyVerbs: Bool {
    customQuiz.verbSet == .myVerbs && myVerbs.isEmpty
  }

  private var canStart: Bool {
    switch tabScope {
    case .allVerbs:
      return true
    case .myVerbs:
      return !myVerbs.isEmpty
    case .custom:
      return !customQuiz.isEmpty && !customQuizLacksMyVerbs
    }
  }

  /// An iPad's start screen has room for a bigger composition.
  private var isLarge: Bool {
    sizeClass == .regular
  }

  /// The practice hub: what a session is and how long it takes, the level, Start, what the record
  /// has due or missed, the last result, the exercises beside the quiz, and the leaderboard last. For Custom, what the quiz asks
  /// and the way to change it take the facts' place; for My Verbs, its verbs follow them.
  private var startScreen: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: isLarge ? Layout.tripleDefaultSpacing * 2 : Layout.doubleDefaultSpacing) {
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

            if tabScope == .custom {
              customQuizSummary
            } else {
              factTiles
            }

            if tabScope == .myVerbs, !myVerbs.isEmpty {
              myVerbChips
            }

            startButton
              // `PrimaryButtonStyle` fixes its own font, so a scale is the way to enlarge it.
              .scaleEffect(isLarge ? 1.4 : 1)
              .padding(.vertical, isLarge ? Layout.defaultSpacing : 0)
              .disabled(!canStart)
              .opacity(canStart ? 1 : 0.4)
          }

          practiceSection

          exercisesSection

          if Current.gameCenter.isAuthenticated {
            leaderboardButton
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

  /// How many questions, how long they take, and the level, which a tap changes here rather than
  /// in Settings. The minutes are a fixed estimate, since showing the learner's own times would
  /// undo the hidden clock.
  private var factTiles: some View {
    HStack(alignment: .top, spacing: Layout.defaultSpacing) {
      QuizFactTile(systemImage: "list.number", value: "\(QuizScope.roundLength)", label: L.Quiz.questionsLabel, isLarge: isLarge)
      QuizFactTile(
        systemImage: "timer",
        value: L.Quiz.sessionMinutes,
        label: L.Quiz.minutesLabel,
        accessibilityLabel: L.Quiz.sessionLength,
        isLarge: isLarge
      )
      levelMenu
    }
    // Equal heights when one label wraps to two lines.
    .fixedSize(horizontal: false, vertical: true)
    .transition(.opacity)
  }

  private var levelMenu: some View {
    let settings = Current.settings
    return Menu {
      Picker(L.Settings.level, selection: Binding(get: { settings.quizLevel }, set: { settings.quizLevel = $0 })) {
        ForEach(QuizLevel.allCases, id: \.self) { level in
          Label(level.localizedName, systemImage: level.systemImage)
            .tag(level)
        }
      }
    } label: {
      QuizFactTile(
        systemImage: settings.quizLevel.systemImage,
        value: settings.quizLevel.localizedName,
        label: L.Settings.level,
        showsMenuIndicator: true,
        isLarge: isLarge
      )
    }
    .buttonStyle(.plain)
    .accessibilityHint(L.Quiz.levelMenuHint)
    .accessibilityIdentifier("quiz_level_menu")
    .sensoryFeedback(.selection, trigger: settings.quizLevel)
    .onChange(of: settings.quizLevel) {
      ChangeLevelTip().invalidate(reason: .actionPerformed)
    }
  }

  /// A modest control below everything else, since the leaderboard is beside the point of
  /// practice, though one tap away.
  private var leaderboardButton: some View {
    Button {
      let level = Current.settings.quizLevel
      Current.gameCenter.showLeaderboard(level: level)
      Current.analytics.signal(name: .tapViewLeaderboard, parameters: [
        ParameterKey.level.rawValue: level.rawValue,
        ParameterKey.source.rawValue: AnalyticsSource.tab.rawValue
      ])
    } label: {
      Label(L.GameCenter.viewLeaderboard, systemImage: "trophy")
        .font(isLarge ? .body : .subheadline)
    }
    .buttonStyle(.bordered)
    .tint(.customYellow)
    .controlSize(isLarge ? .regular : .small)
    .accessibilityHint(L.GameCenter.viewLeaderboardHint)
    .accessibilityIdentifier("quiz_leaderboard_button")
  }

  /// What a custom quiz will ask, and the way to change it, one tap from Start.
  private var customQuizSummary: some View {
    VStack(spacing: Layout.doubleDefaultSpacing) {
      if !customQuiz.isEmpty {
        CustomQuizSummaryCard(custom: customQuiz, level: Current.settings.quizLevel, isLarge: isLarge)
          .accessibilityIdentifier("custom_quiz_summary")
      }

      HStack(spacing: Layout.defaultSpacing) {
        NavigationLink(value: CustomQuizDestination.editor) {
          Label(customQuiz.isEmpty ? L.CustomQuiz.choose : L.CustomQuiz.change, systemImage: "slider.horizontal.3")
            .font(isLarge ? .title3.bold() : .headline)
            .padding(.horizontal, Layout.defaultSpacing)
            .padding(.vertical, 4)
            .frame(maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.customYellow)
        .accessibilityHint(L.CustomQuiz.chooseHint)
        .accessibilityIdentifier("custom_quiz_choose_button")

        if canStart {
          practiceSetShareMenu
        }
      }
      // Equal heights, since a Menu's bordered label sits a little taller than a NavigationLink's.
      .fixedSize(horizontal: false, vertical: true)
    }
    .transition(.opacity)
    .fullScreenCover(isPresented: $isShowingQRCode) {
      PracticeSetQRView(practiceSet: sharedPracticeSet)
    }
  }

  /// The custom quiz as a practice set, for a teacher to hand a class.
  private var sharedPracticeSet: PracticeSet {
    PracticeSet(sharing: customQuiz, level: Current.settings.quizLevel, myVerbs: myVerbs.map(\.infinitive))
  }

  private var practiceSetShareMenu: some View {
    Menu {
      Button {
        sharedPracticeSet.signalShare(method: PracticeSet.linkMethod)
        ShareSheet.present(
          text: sharedPracticeSet.shareText(levelFallback: Current.settings.quizLevel),
          title: L.PracticeSet.title,
          icon: UIImage(named: Current.settings.appIcon.previewAssetName),
          anchorLabel: L.Verb.share,
          anchorRect: shareButtonFrame == .zero ? nil : shareButtonFrame
        )
      } label: {
        Label(L.PracticeSet.shareLink, systemImage: "link")
      }
      .accessibilityIdentifier("practice_set_share_link")

      Button {
        sharedPracticeSet.signalShare(method: PracticeSet.qrCodeMethod)
        isShowingQRCode = true
      } label: {
        Label(L.PracticeSet.showQRCode, systemImage: "qrcode")
      }
      .accessibilityIdentifier("practice_set_show_qr_code")
    } label: {
      Label(L.Verb.share, systemImage: "square.and.arrow.up")
        .font(isLarge ? .title3.bold() : .headline)
        .padding(.horizontal, Layout.defaultSpacing)
        .padding(.vertical, 4)
        .frame(maxHeight: .infinity)
    }
    .buttonStyle(.bordered)
    .tint(.customYellow)
    .onGeometryChange(for: CGRect.self) { proxy in
      proxy.frame(in: .global)
    } action: { frame in
      shareButtonFrame = frame
    }
    .accessibilityHint(L.PracticeSet.shareHint)
    .accessibilityIdentifier("custom_quiz_share_button")
  }

  /// The scope's symbol, its name, and a line saying what the quiz will ask about.
  private var scopeHero: some View {
    VStack(spacing: Layout.defaultSpacing) {
      Image(systemName: heroSymbol)
        .font(.system(size: isLarge ? 180 : 64, weight: .semibold))
        .foregroundStyle(
          LinearGradient(colors: [.customYellow, .customYellow.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        )
        .contentTransition(.symbolEffect(.replace))
        .symbolEffect(.bounce, value: reduceMotion ? TabQuizScope.allVerbs : tabScope)
        .frame(height: isLarge ? 220 : 76)
        .accessibilityHidden(true)

      Text(heroTitle)
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
    case .custom:
      return "slider.horizontal.3"
    }
  }

  private var heroTitle: String {
    switch tabScope {
    case .allVerbs:
      return L.BrowseVerbs.verbCount(count: VerbMap.shared.entries.count)
    case .myVerbs:
      return L.MyVerbs.title
    case .custom:
      return L.CustomQuiz.title
    }
  }

  private var heroDescription: String {
    switch tabScope {
    case .allVerbs:
      return L.Quiz.briefing
    case .myVerbs:
      return myVerbs.isEmpty ? L.Quiz.myVerbsEmpty : L.Quiz.myVerbsCount(count: myVerbs.count)
    case .custom:
      if customQuiz.isEmpty {
        return L.CustomQuiz.emptyDescription
      }
      return customQuizLacksMyVerbs ? L.Quiz.myVerbsEmpty : L.CustomQuiz.description
    }
  }

  /// Review and Practice My Mistakes, on every segment, each saying why it is empty when it is,
  /// the Mastery page, and the last round's results once a quiz has finished.
  private var practiceSection: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(L.PracticeSession.heading)
        .font(isLarge ? .title3.bold() : .headline)
        .foregroundStyle(Color.customForeground)
        .accessibilityAddTraits(.isHeader)

      ForEach(QuizRecordSession.allCases, id: \.self) { session in
        let count = quiz.askableCount(for: session)
        QuizPracticeRow(
          title: session.title,
          detail: session.detail(count: count, daysUntilNextDue: Current.practice.daysUntilNextDue()),
          systemImage: session.systemImage,
          hint: session.hint,
          identifier: session.identifier,
          isLarge: isLarge,
          start: count > 0 ? { startQuiz(scope: .recordSession(session)) } : nil
        )
      }

      let mastery = Mastery.current()
      QuizPracticeRow(
        title: L.Mastery.title,
        detail: L.Mastery.hubSummary(
          masteredPatterns: mastery.masteredPatternCount,
          patterns: mastery.patternCount,
          masteredVerbs: mastery.masteredVerbCount,
          verbs: mastery.verbCount
        ),
        systemImage: "circle.grid.3x3.fill",
        hint: L.Mastery.hubHint,
        identifier: "quiz_mastery",
        isLarge: isLarge,
        opensList: true,
        start: { navigationPath.append(MasteryDestination()) }
      )

      if let lastResult = Current.practice.lastResult {
        LastQuizResultRow(result: lastResult, isLarge: isLarge)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Ways to practice beside the quiz, at the learner's level.
  private var exercisesSection: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(L.Quiz.exercises)
        .font(isLarge ? .title3.bold() : .headline)
        .foregroundStyle(Color.customForeground)
        .accessibilityAddTraits(.isHeader)

      QuizPracticeRow(
        title: L.VerbEssentials.title,
        detail: L.VerbEssentials.description,
        systemImage: "square.stack.3d.up.fill",
        hint: L.VerbEssentials.startHint,
        identifier: "quiz_verb_essentials",
        isLarge: isLarge,
        start: { startQuiz(scope: .verbEssentials()) }
      )

      QuizPracticeRow(
        title: L.ModelPractice.title,
        detail: L.ModelPractice.hubDescription,
        systemImage: "square.grid.3x3.square",
        hint: L.ModelPractice.hubHint,
        identifier: "quiz_model_practice",
        isLarge: isLarge,
        opensList: true,
        start: { navigationPath.append(ModelPracticeDestination()) }
      )

      QuizPracticeRow(
        title: L.Recognition.title,
        detail: L.Recognition.description,
        systemImage: "text.magnifyingglass",
        hint: L.Recognition.startHint,
        identifier: "quiz_recognition",
        isLarge: isLarge,
        start: { startQuiz(scope: .recognition()) }
      )

      let hasSentences = !GapSentences.askable(at: Current.settings.quizLevel).isEmpty
      QuizPracticeRow(
        title: L.Sentences.title,
        detail: hasSentences ? L.Sentences.description : L.Sentences.noneAtLevel,
        systemImage: "character.cursor.ibeam",
        hint: L.Sentences.startHint,
        identifier: "quiz_sentences",
        isLarge: isLarge,
        start: hasSentences ? { startQuiz(scope: .sentences()) } : nil
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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
          // Over the session so far, so that Ten More and a re-ask lengthen the bar's road.
          ProgressView(value: Double(quiz.currentQuestionIndex), total: Double(max(quiz.questions.count, 1)))
            .tint(.customYellow)

          questionCard

          // A Verb Essentials verb shows its rows, with the answer field in the current one. The
          // rows before and after the field are separate children around it, so that the field
          // keeps its place in the hierarchy, and the keyboard its focus, as it moves down a row.
          let essentialsRows = quiz.essentialsRows
          let currentRowIndex = essentialsRows?.firstIndex { $0.content == .current }
          if let essentialsRows, let currentRowIndex, currentRowIndex > 0 {
            VStack(spacing: Layout.doubleDefaultSpacing) {
              ForEach(essentialsRows.prefix(currentRowIndex)) { row in
                VerbEssentialsRowView(row: row)
              }
            }
          }

          // The choices come before the field, so that they stay in sight above the keyboard and
          // Return can check the answer once the infinitive is typed.
          if let recognition = quiz.currentQuestion?.recognition {
            RecognitionChoicesView(
              recognition: recognition,
              tense: $recognitionTense,
              personNumber: $recognitionPerson,
              isLocked: quiz.isHeld
            )
          }

          answerSection(essentialsRows: essentialsRows, currentRowIndex: currentRowIndex)

          if quiz.isAwaitingSecondAttempt {
            secondAttemptLine
              .frame(minHeight: 44)
              .id(QuizView.secondAttemptLineID)
          } else if let question = quiz.currentQuestion, let correction = quiz.correction {
            QuizCorrectionView(
              question: question,
              correction: correction,
              showsVerbLink: quiz.scope.source != .verbPage,
              model: correctionModel(for: question),
              accessibilityIsFocused: $correctionHasAccessibilityFocus,
              onOpen: { navigationPath.append($0) },
              onContinue: continueAfterCorrection
            )
            .transition(.opacity)
          } else if essentialsRows == nil, !quiz.isHeld {
            // A Verb Essentials row shows how its answer went, and a held choice its sentences.
            rightAnswerReveal
              .frame(minHeight: 44)
          }

          if let question = quiz.currentQuestion, question.recognition != nil, !quiz.isHeld {
            Button {
              submit()
            } label: {
              Label(L.Recognition.check, systemImage: "checkmark")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(recognitionAnswer(for: question) == nil)
            .opacity(recognitionAnswer(for: question) == nil ? 0.4 : 1)
            .accessibilityHint(L.Recognition.checkHint)
            .accessibilityIdentifier("recognition_check_button")
            .id(QuizView.checkButtonID)
          }

          if let essentialsRows, let currentRowIndex, currentRowIndex < essentialsRows.count - 1 {
            VStack(spacing: Layout.doubleDefaultSpacing) {
              ForEach(essentialsRows.dropFirst(currentRowIndex + 1)) { row in
                VerbEssentialsRowView(row: row)
              }
            }
          }

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
        recognitionTense = nil
        recognitionPerson = nil
        revealAnswerField(proxy)
        // A re-ask's later blanks in Verb Essentials are not announced again.
        if quiz.currentQuestion?.isReask == true, !quiz.isMidStep {
          AccessibilityNotification.Announcement(L.Quiz.askedAgain).post()
        }
      }
      // Name the Form's chips push its field low: a choice brings the field and Check back into
      // sight, as a second attempt's line does its line.
      .onChange(of: recognitionTense) {
        revealCheckButton(proxy)
      }
      // The field returns after a choice, and takes the keyboard once it is on screen.
      .onChange(of: quiz.currentQuestion?.choice != nil) { _, isChoice in
        guard !isChoice, quiz.quizState == .inProgress else {
          return
        }
        fieldFocused = false
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(50))
          if quiz.quizState == .inProgress {
            fieldFocused = true
          }
        }
      }
      .onChange(of: recognitionPerson) {
        revealCheckButton(proxy)
      }
      .onChange(of: quiz.isAwaitingSecondAttempt) { _, isAwaiting in
        guard isAwaiting else {
          return
        }
        withAnimation(reduceMotion ? nil : .snappy) {
          proxy.scrollTo(QuizView.secondAttemptLineID, anchor: .bottom)
        }
      }
      .onChange(of: quiz.isHeld) { _, isHeld in
        guard isHeld else {
          return
        }
        if quiz.currentQuestion?.choice != nil {
          choiceReasonHasAccessibilityFocus = true
        } else {
          correctionHasAccessibilityFocus = true
          refocusAnswer(after: .milliseconds(50))
        }
        withAnimation(reduceMotion ? nil : .snappy) {
          proxy.scrollTo(QuizCorrectionView.continueButtonID, anchor: .bottom)
        }
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
      lastFeedback
    }
  }

  /// The answer field, with its labels and the letter keys under it on an iPad, or a choice's
  /// sentences in its place.
  @ViewBuilder
  private func answerSection(essentialsRows: [VerbEssentialsRow]?, currentRowIndex: Int?) -> some View {
    // A choice has no field, and so no keyboard, until its Continue.
    if let choice = quiz.currentQuestion?.choice {
      ChoiceQuestionView(
        choice: choice,
        chosenOption: quiz.chosenOption,
        reasonIsFocused: $choiceReasonHasAccessibilityFocus,
        onChoose: choose,
        onContinue: continueAfterCorrection
      )
    } else {
      VStack(alignment: .leading, spacing: 4) {
        if let essentialsRows, let currentRowIndex {
          VerbEssentialsRowLabel(key: essentialsRows[currentRowIndex].key)
            .accessibilityHidden(true)
        }
        if quiz.currentQuestion?.recognition != nil {
          Text(L.Recognition.infinitiveHeading)
            .font(.subheadline.bold())
            .foregroundStyle(Color.customYellow)
            .accessibilityHidden(true)
        }
        answerField(spokenPrefix: currentRowIndex.flatMap { essentialsRows?[$0].key.tense.displayName })
        if let sentence = quiz.currentQuestion?.sentence {
          Text(sentence.en)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("quiz_sentence_english")
        }
      }
      .id(QuizView.answerFieldID)

      if isLarge {
        letterKeys
      }
    }
  }

  private var questionCard: some View {
    VStack(spacing: Layout.defaultSpacing) {
      if quiz.currentQuestion?.isReask == true {
        Label(L.Quiz.askedAgain, systemImage: "arrow.counterclockwise")
          .labelStyle(.titleAndIcon)
          .metadataPill(tint: .customYellow)
          .accessibilityIdentifier("quiz_asked_again")
      }

      #if DEBUG
      if let sentence = quiz.currentQuestion?.sentence, !sentence.reviewed {
        Text(L.Sentences.draft)
          .metadataPill(tint: .customRed)
          .accessibilityIdentifier("quiz_sentence_draft")
      }
      #endif

      if let recognition = quiz.currentQuestion?.recognition {
        RecognitionPromptView(prompt: recognition.prompt)
      } else {
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
      }

      // An item true in one region only says which, since the answer is that region's usage.
      if let region = quiz.currentQuestion?.choice?.question.choiceRegion {
        Label(region == .spain ? L.Choice.inSpain : L.Choice.inLatinAmerica, systemImage: "globe")
          .labelStyle(.titleAndIcon)
          .metadataPill(tint: .customBlue)
          .accessibilityIdentifier("choice_region")
      }

      // The person asked is in the answer's frame, below, a Verb Essentials row names its own
      // tense, and a choice's sentences name theirs.
      if quiz.essentialsRows == nil, quiz.currentQuestion?.recognition == nil, quiz.currentQuestion?.choice == nil {
        Text(verbatim: quiz.currentQuestion?.sentence == nil ? quiz.tense.displayName : quiz.tense.sentenceDisplayName)
          .font(.title3.weight(.semibold))
          .fontDesign(.serif)
          .foregroundStyle(Color.customForeground)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity)
    .card()
  }

  private static let answerFieldID = "answerField"
  private static let secondAttemptLineID = "secondAttemptLine"
  private static let checkButtonID = "recognitionCheckButton"

  private func revealCheckButton(_ proxy: ScrollViewProxy) {
    guard recognitionTense != nil else {
      return
    }
    withAnimation(reduceMotion ? nil : .snappy) {
      proxy.scrollTo(QuizView.checkButtonID, anchor: .bottom)
    }
  }

  /// A nil anchor scrolls the minimum distance, so this is a no-op whenever the field is
  /// already fully visible (the usual case at default text sizes).
  private func revealAnswerField(_ proxy: ScrollViewProxy) {
    withAnimation(.snappy) {
      proxy.scrollTo(QuizView.answerFieldID)
    }
  }

  private func answerField(spokenPrefix: String?) -> some View {
    AnswerFrameView(
      frame: quiz.currentQuestion?.frame ?? AnswerFrame(segments: [.blank]),
      text: $answer,
      selection: $answerSelection,
      isFocused: $fieldFocused,
      identifier: "input_quiz_conjugation",  // screenshot-driver anchor
      spokenPrefix: spokenPrefix,
      placeholder: quiz.currentQuestion?.recognition == nil ? nil : L.Recognition.infinitiveHeading,
      hint: quiz.currentQuestion?.recognition == nil ? nil : L.Recognition.fieldHint,
      onSubmit: {
        if quiz.isHeld {
          continueAfterCorrection()
        } else {
          submit()
        }
      }
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

  /// The check for a right answer, under the next question, with the current spelling of an
  /// answer typed in a retired one. A wrong answer holds its question instead.
  @ViewBuilder
  private var rightAnswerReveal: some View {
    if showsRightAnswer {
      HStack(alignment: .top, spacing: Layout.defaultSpacing) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color.customGreen)
          .font(.title2)

        if let spelling = quiz.lastCurrentSpelling {
          // "Correct. Spelled: rio", the form read in Spanish.
          ConjugationText(form: spelling, regularColor: .secondary)
            .font(.callout)
            .accessibilityLabel(Text(L.Quiz.correctSpelled + " ") + Text(Self.spanish(spelling.lowercased())))
            .accessibilityIdentifier("quiz_current_spelling")
        }
      }
      .transition(.opacity)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  /// "Almost! Try once more." under the field, or a diagnosis's line with "Try once more.", while
  /// the field keeps the first attempt for the learner to edit.
  private var secondAttemptLine: some View {
    Label(quiz.secondAttemptPrompt, systemImage: "hand.raised.fill")
      .font(.headline)
      .foregroundStyle(Color.customYellow)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .transition(.opacity.combined(with: .scale(scale: 0.9)))
      .accessibilityIdentifier("quiz_almost")
  }

  /// The verb's model for a correction's link, or nil in a quiz over that model's own verbs.
  private func correctionModel(for question: QuizQuestion) -> ModelInfo? {
    guard let model = ModelInfo.row(for: question.verb),
          VerbCollection.model(model.classNumber).key != quiz.scope.collectionKey else {
      return nil
    }
    return model
  }

  /// Gives the answer field the keyboard while the question waits, on a held correction so
  /// that Return continues, or after a slip so that the learner can edit it. Return resigns the
  /// field while the focus state can still read true. Back from a linked page gives the field its
  /// keyboard again without telling the focus state, which reads false, so setting it true then
  /// does nothing and the field's border stays unfocused. Either way, the state is cleared and
  /// set again once the field is back on screen.
  private func refocusAnswer(after delay: Duration) {
    fieldFocused = false
    Task { @MainActor in
      try? await Task.sleep(for: delay)
      guard navigationPath.isEmpty, isWaitingOnQuestion else {
        return
      }
      fieldFocused = false
      try? await Task.sleep(for: .milliseconds(50))
      if navigationPath.isEmpty, isWaitingOnQuestion {
        fieldFocused = true
      }
    }
  }

  private var isWaitingOnQuestion: Bool {
    quiz.quizState == .inProgress && (quiz.isHeld || quiz.isAwaitingSecondAttempt)
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
      if Current.settings.quizClock == .show {
        Label(quiz.elapsedTime.timeString, systemImage: "clock")
          .foregroundStyle(.secondary)
          .numeric()
      }
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
    recognitionTense = nil
    recognitionPerson = nil
    lastFeedback = nil
    showsRightAnswer = false
    navigationPath = NavigationPath()
    fieldFocused = true
    var parameters = [
      ParameterKey.level.rawValue: quiz.lastLevel.rawValue,
      ParameterKey.source.rawValue: scope.source.rawValue
    ]
    // A quiz over a collection names it.
    if let collectionKey = scope.collectionKey {
      parameters[ParameterKey.collection.rawValue] = collectionKey
    }
    if let custom = scope.custom {
      parameters[ParameterKey.customChoice.rawValue] = custom.choiceParameter
    }
    Current.analytics.signal(name: .startQuiz, parameters: parameters)
  }

  /// The Name the Form answer the screen holds, or nil until the infinitive, the tense, and,
  /// unless the tense has none, the person are all given.
  private func recognitionAnswer(for question: QuizQuestion) -> RecognitionAnswer? {
    guard
      let recognition = question.recognition,
      !answer.allSatisfy(\.isWhitespace),
      let recognitionTense,
      let choice = recognition.choice(for: recognitionTense)
    else {
      return nil
    }
    if choice.personNumbers.isEmpty {
      return RecognitionAnswer(infinitive: answer, tense: recognitionTense, personNumber: .none)
    }
    guard let recognitionPerson, choice.personNumbers.contains(recognitionPerson) else {
      return nil
    }
    return RecognitionAnswer(infinitive: answer, tense: recognitionTense, personNumber: recognitionPerson)
  }

  private func submit() {
    guard let question = quiz.currentQuestion else { return }
    let result: ConjugationResult?
    if question.recognition != nil {
      guard let recognitionAnswer = recognitionAnswer(for: question) else {
        // Return with a part missing: the field keeps the keyboard, and VoiceOver says what to do.
        AccessibilityNotification.Announcement(L.Recognition.incomplete).post()
        fieldFocused = false
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(50))
          if quiz.quizState == .inProgress {
            fieldFocused = true
          }
        }
        return
      }
      result = quiz.processRecognition(recognitionAnswer)
    } else {
      guard !answer.allSatisfy(\.isWhitespace) else { return }
      result = quiz.process(proposedAnswer: question.answer(filling: answer))
    }
    switch result {
    case .totalMatch, .secondAttemptMatch:
      Current.soundPlayer.play(.chime, shouldDebounce: false)
      lastFeedback = .success
    case .noMatch:
      Current.soundPlayer.play(.buzz, shouldDebounce: false)
      lastFeedback = .error
    case nil:
      Current.soundPlayer.play(.pop, shouldDebounce: false)
      lastFeedback = .impact(weight: .light)
    }
    answerToken += 1
    guard let result else {
      // A slip or a diagnosed error: the field keeps it to edit, and Return, which resigned the field, must find it
      // focused again.
      withAnimation(reduceMotion ? nil : .snappy) {
        showsRightAnswer = false
      }
      AccessibilityNotification.Announcement(quiz.secondAttemptPrompt).post()
      refocusAnswer(after: .milliseconds(50))
      return
    }
    guard result != .noMatch else {
      // The field keeps the answer while its correction holds the question.
      withAnimation(reduceMotion ? nil : .snappy) {
        showsRightAnswer = false
      }
      return
    }
    withAnimation(.snappy) {
      showsRightAnswer = true
    }
    answer = ""
    answerSelection = nil
    if quiz.quizState == .finished {
      finish()
    } else {
      fieldFocused = true
    }
  }

  /// A sentence chosen in a choice question: the sound and haptic of a typed answer, and the
  /// reason announced, since the card holds with it, right or wrong.
  private func choose(_ index: Int) {
    guard let choice = quiz.currentQuestion?.choice, let result = quiz.submitChoice(index) else {
      return
    }
    let isRight = result != .noMatch
    Current.soundPlayer.play(isRight ? .chime : .buzz, shouldDebounce: false)
    lastFeedback = isRight ? .success : .error
    answerToken += 1
    withAnimation(reduceMotion ? nil : .snappy) {
      showsRightAnswer = false
    }
    let reason = choice.question.reasonLine
    let rightSentence = choice.options.first(where: \.isRight)?.sentence ?? ""
    AccessibilityNotification.Announcement(isRight ? L.Choice.announceRight(reason) : L.Choice.announceWrong(right: rightSentence, reason: reason)).post()
  }

  /// Return in the field, Continue, or a Magic Tap: the next question, or the results.
  private func continueAfterCorrection() {
    quiz.continueAfterCorrection()
    answer = ""
    answerSelection = nil
    if quiz.quizState == .finished {
      finish()
    } else {
      fieldFocused = true
    }
  }

  private func finish() {
    Current.soundPlayer.play(Sound.randomApplause, shouldDebounce: false)
    var parameters = [
      ParameterKey.duration.rawValue: quiz.durationBand,
      ParameterKey.level.rawValue: quiz.lastLevel.rawValue,
      ParameterKey.source.rawValue: quiz.scope.source.rawValue
    ]
    if quiz.scope.sendsQuestionCounts {
      parameters[ParameterKey.questionCount.rawValue] = "\(quiz.questionCount)"
    }
    if quiz.isRankedRound {
      parameters[ParameterKey.score.rawValue] = "\(quiz.firstRoundScore)"
    }
    Current.analytics.signal(name: .completeQuiz, parameters: parameters)
    // The sheet shows the results in place of the question; the tab pushes them.
    fieldFocused = false
    if sheetScope == nil {
      showingResults = true
    }
  }

  private func quit() {
    quiz.quit()
    Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true)
    var parameters = [
      ParameterKey.duration.rawValue: quiz.durationBand,
      ParameterKey.level.rawValue: quiz.lastLevel.rawValue,
      ParameterKey.source.rawValue: quiz.scope.source.rawValue
    ]
    if quiz.scope.sendsQuestionCounts {
      parameters[ParameterKey.questionNumber.rawValue] = "\(quiz.questionReached)"
    }
    if quiz.isRankedRound {
      parameters[ParameterKey.score.rawValue] = "\(quiz.firstRoundScore)"
    }
    Current.analytics.signal(name: .quitQuiz, parameters: parameters)
    fieldFocused = false
    lastFeedback = nil
    showsRightAnswer = false
    if sheetScope != nil {
      dismiss()
    }
  }

  /// Ten More, from the results: the session's next round, typed into at once.
  private func continueSession() {
    guard quiz.continueSession() else {
      return
    }
    answer = ""
    answerSelection = nil
    recognitionTense = nil
    recognitionPerson = nil
    lastFeedback = nil
    showsRightAnswer = false
    showingResults = false
    // The tab pops its results, and a field focused before the pop ends never takes the keyboard.
    fieldFocused = false
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(450))
      if quiz.quizState == .inProgress {
        fieldFocused = true
      }
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
  /// What VoiceOver reads in place of the value and label, such as words for "2–3".
  var accessibilityLabel: String?
  /// The level's tile is a menu, and its chevron says so.
  var showsMenuIndicator = false
  var isLarge = false

  var body: some View {
    let tile = VStack(spacing: 6) {
      Image(systemName: systemImage)
        .font(isLarge ? .system(size: 48) : .title)
        .foregroundStyle(Color.customYellow)
        .contentTransition(.symbolEffect(.replace))
        .frame(height: isLarge ? 64 : 36)
        .accessibilityHidden(true)
      HStack(spacing: 3) {
        Text(verbatim: value)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        if showsMenuIndicator {
          Image(systemName: "chevron.up.chevron.down")
            .font(isLarge ? .subheadline.bold() : .caption2.bold())
            .foregroundStyle(Color.customYellow)
            .accessibilityHidden(true)
        }
      }
      .font(isLarge ? .title2.bold() : .headline)
      .foregroundStyle(Color.customForeground)
      Text(label)
        .font(isLarge ? .subheadline : .caption)
        // Fixed, since `.secondary` inside a menu's label would take the app's tint.
        .foregroundStyle(Color.secondary)
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
    .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    .accessibilityElement(children: .combine)

    if let accessibilityLabel {
      tile.accessibilityLabel(accessibilityLabel)
    } else {
      tile
    }
  }
}

/// The last round's results, kept on the device: what was quizzed, at which level, when, and how
/// it went.
private struct LastQuizResultRow: View {
  let result: LastQuizResult
  var isLarge = false

  var body: some View {
    HStack(spacing: Layout.doubleDefaultSpacing) {
      Image(systemName: "flag.checkered")
        .font(isLarge ? .system(size: 36) : .title2)
        .foregroundStyle(Color.customYellow)
        .frame(width: isLarge ? 52 : 36)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        Text(L.Quiz.lastQuiz)
          .font(isLarge ? .title3.bold() : .headline)
          .foregroundStyle(Color.customForeground)
        subjectLine
          .font(isLarge ? .body : .subheadline)
          .foregroundStyle(Color.customForeground)
          .fixedSize(horizontal: false, vertical: true)
        Text(verbatim: resultLine)
          .font((isLarge ? Font.body : .subheadline).monospacedDigit())
          .foregroundStyle(Color.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(Layout.doubleDefaultSpacing)
    .background(Color.customYellow.opacity(0.06), in: RoundedRectangle(cornerRadius: Layout.cornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .strokeBorder(Color.customYellow.opacity(0.25), lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("quiz_last_result")
  }

  /// "All Verbs · Elementary · today", a verb page's infinitive read in Spanish.
  private var subjectLine: Text {
    var line = AttributedString(result.title)
    if result.kind == .verbPage {
      line.languageIdentifier = "es"
    }
    for part in [result.level?.localizedName, relativeDay].compactMap({ $0 }) {
      line += AttributedString(" · \(part)")
    }
    return Text(line)
  }

  /// "Correct: 8 / 10 · Second Try: 1 · Score: 85", the second part only when there was one.
  private var resultLine: String {
    var parts = ["\(L.Results.correct): \(result.correctCount) / \(result.questionCount)"]
    if result.secondAttemptCount > 0 {
      parts.append("\(L.Results.secondTry): \(result.secondAttemptCount)")
    }
    parts.append("\(L.Quiz.score): \(result.score)")
    return parts.joined(separator: " · ")
  }

  private var relativeDay: String? {
    guard let days = PracticeRecord.daysBetween(result.date, and: .now) else {
      return nil
    }
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    formatter.unitsStyle = .full
    // The app's language, which can differ from the region's.
    formatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
    // A clock set back would otherwise make the last quiz tomorrow's.
    return formatter.localizedString(from: DateComponents(day: -max(days, 0)))
  }
}

/// A way to practice from the record: a symbol, a name, and how many questions wait or why none
/// do. With questions, the row is a button that starts the session; without, it only explains.
private struct QuizPracticeRow: View {
  let title: String
  let detail: String
  let systemImage: String
  let hint: String
  let identifier: String
  var isLarge = false
  /// Whether the row pushes a list rather than starting a session, which its chevron says.
  var opensList = false
  let start: (() -> Void)?

  var body: some View {
    if let start {
      Button(action: start) {
        content
      }
      .buttonStyle(.plain)
      .accessibilityHint(hint)
      .accessibilityIdentifier(identifier)
    } else {
      content
        .accessibilityIdentifier(identifier)
    }
  }

  private var content: some View {
    HStack(spacing: Layout.doubleDefaultSpacing) {
      Image(systemName: systemImage)
        .font(isLarge ? .system(size: 36) : .title2)
        .foregroundStyle(Color.customYellow)
        .frame(width: isLarge ? 52 : 36)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(isLarge ? .title3.bold() : .headline)
          .foregroundStyle(Color.customForeground)
        Text(detail)
          .font(isLarge ? .body : .subheadline)
          // Fixed, since `.secondary` inside a button would take the button's tint.
          .foregroundStyle(Color.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if opensList {
        Image(systemName: "chevron.right")
          .font(isLarge ? .title2 : .body)
          .foregroundStyle(Color.secondary)
          .accessibilityHidden(true)
      } else if start != nil {
        Image(systemName: "play.circle.fill")
          .font(isLarge ? .system(size: 36) : .title2)
          .foregroundStyle(Color.customYellow)
          .accessibilityHidden(true)
      }
    }
    .padding(Layout.doubleDefaultSpacing)
    .background(Color.customYellow.opacity(0.06), in: RoundedRectangle(cornerRadius: Layout.cornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .strokeBorder(Color.customYellow.opacity(0.25), lineWidth: 1)
    }
    .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    .accessibilityElement(children: .combine)
  }
}

/// What a record session's row on the Quiz tab says and shows.
private extension QuizRecordSession {
  func detail(count: Int, daysUntilNextDue: Int?) -> String {
    switch self {
    case .review:
      if count > 0 {
        return L.PracticeSession.reviewCount(count: count)
      }
      return daysUntilNextDue.map { L.PracticeSession.reviewNextDue(days: $0) } ?? L.PracticeSession.reviewEmpty
    case .mistakes:
      return count > 0 ? L.PracticeSession.mistakesCount(count: count) : L.PracticeSession.mistakesEmpty
    }
  }

  var hint: String {
    switch self {
    case .review:
      return L.PracticeSession.reviewHint
    case .mistakes:
      return L.PracticeSession.mistakesHint
    }
  }

  var systemImage: String {
    switch self {
    case .review:
      return "clock.arrow.circlepath"
    case .mistakes:
      return "arrow.uturn.backward.circle"
    }
  }

  var identifier: String {
    switch self {
    case .review:
      return "quiz_review"
    case .mistakes:
      return "quiz_mistakes"
    }
  }
}

/// What the Quiz tab's picker offers. A quiz over one verb starts from that verb's page instead.
enum TabQuizScope: CaseIterable {
  case allVerbs
  case myVerbs
  case custom

  var displayName: String {
    switch self {
    case .allVerbs:
      return L.Quiz.allVerbs
    case .myVerbs:
      return L.MyVerbs.title
    case .custom:
      return L.CustomQuiz.segment
    }
  }
}
