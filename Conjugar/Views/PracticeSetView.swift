//
//  PracticeSetView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A shared practice set, opened from a link or a QR code: what it asks, Start, and a way to keep
/// it as the learner's custom quiz. It never starts a quiz unasked.
struct PracticeSetView: View {
  let request: PracticeSetRequest
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var sizeClass
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isQuizzing = false
  @State private var hasSignaledView = false

  private var isLarge: Bool {
    sizeClass == .regular
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Color.customBackground
          .ignoresSafeArea()

        if let practiceSet = request.practiceSet {
          content(practiceSet)
        } else {
          ContentUnavailableView(
            L.PracticeSet.invalidTitle,
            systemImage: "questionmark.square.dashed",
            description: Text(L.PracticeSet.invalidDescription)
          )
          .accessibilityIdentifier("practice_set_invalid")
        }
      }
      .navigationTitle(L.PracticeSet.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(L.Quiz.done) {
            dismiss()
          }
          .accessibilityIdentifier("practice_set_dismiss")
        }
      }
    }
    .onAppear {
      guard !hasSignaledView else {
        return
      }
      hasSignaledView = true
      Current.analytics.signal(name: .viewPracticeSet, parameters: [
        ParameterKey.outcome.rawValue: request.practiceSet == nil ? PracticeSetRequest.invalidOutcome : PracticeSetRequest.openedOutcome,
        ParameterKey.source.rawValue: request.source.rawValue
      ])
    }
    .sheet(isPresented: $isQuizzing) {
      if let practiceSet = request.practiceSet {
        QuizSheet(scope: practiceSet.scope(source: request.source, title: L.PracticeSet.title))
      }
    }
  }

  private func content(_ practiceSet: PracticeSet) -> some View {
    let level = practiceSet.level ?? Current.settings.quizLevel

    return ScrollView {
      VStack(spacing: isLarge ? Layout.tripleDefaultSpacing * 2 : Layout.tripleDefaultSpacing) {
        VStack(spacing: Layout.defaultSpacing) {
          Image(systemName: "graduationcap.fill")
            .font(.system(size: isLarge ? 140 : 80, weight: .semibold))
            .foregroundStyle(
              LinearGradient(colors: [.customYellow, .customYellow.opacity(0.6)], startPoint: .top, endPoint: .bottom)
            )
            .accessibilityHidden(true)

          Text(L.PracticeSet.title)
            .font(isLarge ? .largeTitle.bold() : .title.bold())
            .fontDesign(.serif)
            .foregroundStyle(Color.customForeground)
            .accessibilityAddTraits(.isHeader)

          Text(L.PracticeSet.description)
            .font(isLarge ? .title3 : .subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }

        startButton
          // `PrimaryButtonStyle` fixes its own font, so a scale is the way to enlarge it.
          .scaleEffect(isLarge ? 1.4 : 1)
          .padding(.vertical, isLarge ? Layout.defaultSpacing : 0)

        CustomQuizSummaryCard(
          custom: practiceSet.custom,
          level: level,
          byLevelLabel: practiceSet.level == nil ? L.CustomQuiz.byLevel : L.PracticeSet.byLevel,
          isLarge: isLarge
        )
        .accessibilityIdentifier("practice_set_summary")

        if case .list(let infinitives) = practiceSet.custom.verbSet {
          verbChips(infinitives)
        }

        keepButton(practiceSet)
      }
      .padding(Layout.doubleDefaultSpacing)
      .frame(maxWidth: isLarge ? Layout.readingWidth : 560)
      .frame(maxWidth: .infinity)
    }
  }

  @ViewBuilder
  private var startButton: some View {
    let base = Button(L.Quiz.start) { isQuizzing = true }
      .buttonStyle(PrimaryButtonStyle())
      .accessibilityHint(L.PracticeSet.startHint)
      .accessibilityIdentifier("practice_set_start_button")

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

  private static let chipLimit = 12

  private func verbChips(_ infinitives: [String]) -> some View {
    let shown = infinitives.prefix(Self.chipLimit)
    let hiddenCount = infinitives.count - shown.count
    return FlowLayout(spacing: Layout.defaultSpacing, centersRows: true) {
      ForEach(Array(shown), id: \.self) { infinitive in
        Text(spanish: VerbMap.shared.entry(for: infinitive)?.citationForm ?? infinitive)
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
    .accessibilityIdentifier("practice_set_verbs")
  }

  /// Keeping replaces the learner's own custom quiz, which the footer says. A kept set asks the
  /// learner's level for any part it leaves to the level, as every custom quiz does.
  private func keepButton(_ practiceSet: PracticeSet) -> some View {
    let isKept = Current.settings.customQuiz == practiceSet.custom

    return VStack(spacing: Layout.defaultSpacing) {
      Button {
        Current.settings.customQuiz = practiceSet.custom
        Current.analytics.signal(name: .tapKeepPracticeSet)
        AccessibilityNotification.Announcement(L.PracticeSet.kept).post()
      } label: {
        Label(isKept ? L.PracticeSet.kept : L.PracticeSet.keep, systemImage: isKept ? "checkmark" : "square.and.arrow.down")
          .font(isLarge ? .title3.bold() : .headline)
          .padding(.horizontal, Layout.defaultSpacing)
          .padding(.vertical, 4)
      }
      .buttonStyle(.bordered)
      .tint(.customYellow)
      .disabled(isKept)
      .accessibilityIdentifier("practice_set_keep_button")

      if !isKept {
        Text(L.PracticeSet.keepFooter)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

extension PracticeSetRequest {
  static let openedOutcome = "opened"
  static let invalidOutcome = "invalid"
}

/// A practice set's QR code, big enough to project, with a caption naming what it asks. The
/// screen stays awake while it shows, since a class may take a while to scan it.
struct PracticeSetQRView: View {
  let practiceSet: PracticeSet
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        ZStack {
          Color.customBackground
            .ignoresSafeArea()

          ScrollView {
            VStack(spacing: Layout.doubleDefaultSpacing) {
              Text(L.PracticeSet.scanTitle)
                .font(.largeTitle.bold())
                .fontDesign(.serif)
                .foregroundStyle(Color.customForeground)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

              // Dark modules on white in either appearance, since some scanners misread a code
              // drawn light on dark.
              if let url = practiceSet.deeplink(source: .qrCode), let image = QRCode.image(for: url.absoluteString) {
                Image(uiImage: image)
                  .interpolation(.none)
                  .resizable()
                  .scaledToFit()
                  .padding(Layout.tripleDefaultSpacing)
                  .background(.white, in: RoundedRectangle(cornerRadius: 16))
                  .frame(maxWidth: max(min(geometry.size.width, geometry.size.height * 0.7) - Layout.tripleDefaultSpacing * 2, 200))
                  .accessibilityElement()
                  .accessibilityLabel(L.PracticeSet.qrCodeLabel)
                  .accessibilityAddTraits(.isImage)
                  .accessibilityIdentifier("practice_set_qr_code")
              }

              // Two elements, since chosen tenses are named in Spanish and the verbs in the
              // learner's language.
              VStack(spacing: 4) {
                let tensesAreSpanish = !practiceSet.custom.tenses.isEmpty
                let tenses = practiceSet.tensesSummary(levelFallback: Current.settings.quizLevel)
                Text(tensesAreSpanish ? AttributedString(spanish: tenses) : AttributedString(tenses))
                  .fontDesign(tensesAreSpanish ? .serif : .default)
                Text(verbatim: practiceSet.verbsSummary(levelFallback: Current.settings.quizLevel))
              }
              .font(.title3)
              .foregroundStyle(Color.customForeground)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)

              Text(L.PracticeSet.scanNote)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Layout.doubleDefaultSpacing)
            .frame(maxWidth: .infinity)
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(L.Quiz.done) {
            dismiss()
          }
          .accessibilityIdentifier("practice_set_qr_dismiss")
        }
      }
    }
    .onAppear {
      UIApplication.shared.isIdleTimerDisabled = true
    }
    .onDisappear {
      UIApplication.shared.isIdleTimerDisabled = false
    }
  }
}
