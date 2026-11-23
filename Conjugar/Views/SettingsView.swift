//
//  SettingsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct SettingsView: View {
  static let englishTitle = "Settings"

  // Passed in from `MainTabView` so it can be handed to the onboarding cover, whose
  // content can't reliably read `@Environment(AppRouter.self)` (see `OnboardingView`).
  let router: AppRouter
  @Bindable private var settings = Current.settings
  @State private var isSignedInToGameCenter = false
  @State private var rateReviewDescription = ""
  @State private var showingGame = false
  @State private var showingOnboarding = false
  @State private var showingResetPractice = false
  // A popover tip attached to a view that outlives the tab's first visit would float over another
  // tab, pointing at nothing, when its rule is met there, as ChangeLevelTip's is when a quiz
  // finishes. Tips are therefore attached only while Settings is on screen.
  @State private var isOnScreen = false
  private let changeLevelTip = ChangeLevelTip()
  private let enableGameCenterTip = EnableGameCenterTip()

  var body: some View {
    NavigationStack {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
          regionCard
          quizCard
          browseCard
          appIconCard
          gameCard
          onboardingCard
          actionsCard
          aboutFooter
        }
        .readingWidth()
        .padding(.horizontal, Layout.defaultHorizontalMargin)
        .padding(.bottom, Layout.tripleDefaultSpacing)
      }
      .frame(maxWidth: .infinity)
      .background(Color.customBackground.ignoresSafeArea())
      .fullScreenCover(isPresented: $showingGame) { GameView() }
      .fullScreenCover(isPresented: $showingOnboarding, onDismiss: router.launchGameAfterOnboardingIfRequested) {
        OnboardingView(router: router, isReshow: true, requestGame: router.requestGameAfterOnboarding)
      }
      .navigationTitle(L.Settings.localizedTitle)
      .onAppear {
        isOnScreen = true
        isSignedInToGameCenter = Current.gameCenter.isAuthenticated
        Current.analytics.signal(name: .viewSettingsView)
      }
      .onDisappear {
        isOnScreen = false
      }
      .task {
        // Surface the failure: show an unavailable message rather than
        // leaving the row silently empty when the iTunes lookup fails.
        rateReviewDescription = await RatingsFetcher.ratingsDescription() ?? L.Settings.ratingsUnavailable
      }
    }
  }

  private var regionCard: some View {
    settingsCard {
      settingSection(
        icon: "globe.americas.fill",
        tint: .customBlue,
        heading: L.Settings.region,
        description: L.Settings.regionDescription
      ) {
        Picker(selection: $settings.region) {
          ForEach(Region.allCases, id: \.self) { region in
            Text(region.localizedRegion).tag(region)
          }
        } label: {
          Text(verbatim: "")
        }
        .pickerStyle(.segmented)
        .selectionFeedback(trigger: settings.region)
        .accessibilityLabel(L.Settings.region)
      }
    }
  }

  private var quizCard: some View {
    settingsCard {
      settingSection(
        icon: "speedometer",
        tint: .customYellow,
        heading: L.Settings.level,
        description: L.Settings.levelDescription
      ) {
        quizLevelPicker
      }
      .popoverTip(isOnScreen ? changeLevelTip : nil)
      .onChange(of: settings.quizLevel) {
        changeLevelTip.invalidate(reason: .actionPerformed)
      }

      GradientDivider()

      settingSection(
        icon: "graduationcap.fill",
        tint: .customGreen,
        heading: L.Settings.quiz,
        description: L.Settings.quizDescription
      ) {
        Picker(selection: $settings.secondSingularQuiz) {
          ForEach(SecondSingularQuiz.allCases, id: \.self) { form in
            Text(form.rawValue).tag(form)
          }
        } label: {
          Text(verbatim: "")
        }
        .pickerStyle(.segmented)
        .selectionFeedback(trigger: settings.secondSingularQuiz)
        .accessibilityLabel(L.Settings.quiz)
      }

      GradientDivider()

      settingSection(
        icon: "clock",
        tint: .customBlue,
        heading: L.Settings.quizClockHeading,
        description: L.Settings.quizClockDescription
      ) {
        Picker(selection: $settings.quizClock) {
          ForEach(QuizClock.allCases, id: \.self) { quizClock in
            Text(quizClock.localizedQuizClock).tag(quizClock)
          }
        } label: {
          Text(verbatim: "")
        }
        .pickerStyle(.segmented)
        .selectionFeedback(trigger: settings.quizClock)
        .accessibilityLabel(L.Settings.quizClockHeading)
        .accessibilityIdentifier("quiz_clock_picker")
      }

      if !Current.practice.isEmpty {
        GradientDivider()

        resetPracticeSection
      }
    }
  }

  private var resetPracticeSection: some View {
    settingSection(
      icon: "arrow.counterclockwise",
      tint: .customRed,
      heading: L.Settings.resetPracticeHeading,
      description: L.Settings.resetPracticeDescription
    ) {
      Button(L.Settings.resetPractice) {
        showingResetPractice = true
      }
      .buttonStyle(TintedCapsuleButtonStyle(tint: .customRed))
      .accessibilityHint(L.Settings.resetPracticeHint)
      .accessibilityIdentifier("settings_reset_practice")
    }
    .alert(L.Settings.resetPracticeTitle, isPresented: $showingResetPractice) {
      Button(L.Settings.resetPracticeConfirm, role: .destructive) {
        withAnimation {
          Current.practice.reset()
        }
        Current.analytics.signal(name: .tapResetPractice)
      }
      Button(role: .cancel) {}
    } message: {
      Text(L.Settings.resetPracticeMessage)
    }
  }

  // A segmented control would truncate Intermediate and Intermedio on an iPhone, so the levels
  // are tiles, each with a gauge whose needle rises with the level.
  private var quizLevelPicker: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: Layout.defaultSpacing), count: QuizLevel.allCases.count),
      alignment: .center,
      spacing: Layout.defaultSpacing
    ) {
      ForEach(QuizLevel.allCases, id: \.self) { quizLevel in
        let isSelected = settings.quizLevel == quizLevel
        Button {
          settings.quizLevel = quizLevel
        } label: {
          VStack(spacing: 4) {
            Image(systemName: quizLevel.systemImage)
              .font(.system(size: 30))
              .foregroundStyle(isSelected ? Color.customYellow : Color.secondary)
              .frame(width: 60, height: 60)
              .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                  .fill(Color.customBackground)
              )
              .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                  .strokeBorder(isSelected ? Color.customYellow : Color.clear, lineWidth: 3)
              )
              .accessibilityHidden(true)
            Text(quizLevel.localizedName)
              .font(.caption)
              .foregroundStyle(isSelected ? Color.customYellow : Color.customForeground)
              .lineLimit(1)
              .minimumScaleFactor(0.7)
          }
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(quizLevel.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("quiz_level_\(quizLevel.rawValue)")
      }
    }
    .selectionFeedback(trigger: settings.quizLevel)
  }

  private var browseCard: some View {
    settingsCard {
      settingSection(
        icon: "books.vertical.fill",
        tint: .customRed,
        heading: L.Settings.browse,
        description: L.Settings.browseDescription
      ) {
        Picker(selection: $settings.secondSingularBrowse) {
          ForEach(SecondSingularBrowse.allCases, id: \.self) { form in
            Text(form.localizedSecondSingularBrowse).tag(form)
          }
        } label: {
          Text(verbatim: "")
        }
        .pickerStyle(.segmented)
        .selectionFeedback(trigger: settings.secondSingularBrowse)
        .accessibilityLabel(L.Settings.browse)
      }

      GradientDivider()

      settingSection(
        icon: "rectangle.on.rectangle.slash",
        tint: .customYellow,
        heading: L.Settings.reviewCardSuppressionHeading,
        description: L.Settings.reviewCardSuppressionDescription
      ) {
        Picker(selection: $settings.reviewCardSuppression) {
          ForEach(ReviewCardSuppression.allCases, id: \.self) { suppression in
            Text(suppression.localizedReviewCardSuppression).tag(suppression)
          }
        } label: {
          Text(verbatim: "")
        }
        .pickerStyle(.segmented)
        .selectionFeedback(trigger: settings.reviewCardSuppression)
        .accessibilityLabel(L.Settings.reviewCardSuppressionHeading)
        .accessibilityIdentifier("review_card_suppression_picker")
      }
    }
  }

  private var appIconCard: some View {
    settingsCard {
      settingSection(
        icon: "apps.iphone",
        tint: .customBlue,
        heading: L.Settings.appIcon,
        description: L.Settings.appIconDescription
      ) {
        LazyVGrid(
          columns: Array(
            repeating: GridItem(.flexible(), spacing: Layout.doubleDefaultSpacing),
            count: 2
          ),
          spacing: Layout.doubleDefaultSpacing
        ) {
          ForEach(AppIcon.allCases, id: \.self) { appIcon in
            Button {
              settings.appIcon = appIcon
            } label: {
              VStack(spacing: Layout.defaultSpacing) {
                Image(appIcon.previewAssetName)
                  .resizable()
                  .aspectRatio(1, contentMode: .fit)
                  .frame(width: 96, height: 96)
                  .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                  .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                      .strokeBorder(
                        settings.appIcon == appIcon ? Color.customYellow : Color.clear,
                        lineWidth: 3
                      )
                  )
                  .accessibilityHidden(true)

                Text(appIcon.localizedName)
                  .font(.callout)
                  .foregroundStyle(Color.customBlue)
                  .multilineTextAlignment(.center)
              }
              .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("app_icon_\(appIcon.rawValue)")
            .accessibilityLabel(appIcon.localizedName)
            .accessibilityAddTraits(settings.appIcon == appIcon ? .isSelected : [])
          }
        }
        .accessibilityIdentifier("grid_settings_appIcon")
        .selectionFeedback(trigger: settings.appIcon)
      }
    }
  }

  private var gameCard: some View {
    settingsCard {
      settingSection(
        icon: "dancer",
        isSystemSymbol: false,
        tint: .customYellow,
        heading: L.Game.title,
        description: L.Game.settingsDescription
      ) {
        Button(L.Game.play) {
          Current.analytics.signal(name: .tapPlayGame)
          showingGame = true
        }
          .buttonStyle(TintedCapsuleButtonStyle(tint: .customYellow))
      }
    }
  }

  private var onboardingCard: some View {
    settingsCard {
      settingSection(
        icon: "hand.wave.fill",
        tint: .customGreen,
        heading: L.Onboarding.onboarding,
        description: L.Onboarding.showOnboardingDescription
      ) {
        Button(L.Onboarding.showOnboarding) {
          Current.analytics.signal(name: .tapShowOnboarding)
          showingOnboarding = true
        }
          .buttonStyle(TintedCapsuleButtonStyle(tint: .customGreen))
      }
    }
  }

  private var actionsCard: some View {
    settingsCard {
      if !isSignedInToGameCenter {
        // Inline rather than `.popoverTip(_:)` on the button: this card sits near the
        // bottom of a long scroll, so at the default scroll position the button is
        // below the fold. TipKit anchors a popover to the (offscreen) button and
        // clamps it to the screen's bottom edge, which puts the popover — including
        // its close button — underneath the floating tab pill. An inline `TipView`
        // scrolls with the content, matching `TryQuizTip`/`ExploreModelsTip`.
        TipView(enableGameCenterTip)

        settingSection(
          icon: "gamecontroller.fill",
          tint: .customRed,
          heading: L.Quiz.gameCenter,
          description: L.Settings.enableDescription
        ) {
          Button(L.Settings.enable) { enableGameCenter() }
            .buttonStyle(TintedCapsuleButtonStyle(tint: .customRed))
        }

        GradientDivider()
      } else {
        settingSection(
          icon: "trophy.fill",
          tint: .customYellow,
          heading: L.Quiz.gameCenter,
          description: L.GameCenter.viewLeaderboardsDescription
        ) {
          Button(L.GameCenter.viewLeaderboards) {
            Current.gameCenter.showLeaderboards()
            Current.analytics.signal(name: .tapViewLeaderboard)
          }
          .buttonStyle(TintedCapsuleButtonStyle(tint: .customYellow))
          .accessibilityHint(L.GameCenter.viewLeaderboardsHint)
          .accessibilityIdentifier("settings_leaderboards")
        }

        GradientDivider()
      }

      settingSection(
        icon: "star.fill",
        tint: .customBlue,
        heading: L.Settings.ratingsAndReviews,
        description: rateReviewDescription
      ) {
        Button(L.Settings.rateOrReview) {
          Current.analytics.signal(name: .tapRateOrReview)
          UIApplication.shared.open(RatingsFetcher.reviewURL)
        }
        .buttonStyle(TintedCapsuleButtonStyle(tint: .customBlue))
      }
    }
  }

  private var aboutFooter: some View {
    VStack(spacing: Layout.defaultSpacing / 2) {
      Text(verbatim: "Conjugar")
        .font(.headline)
        .linguistic()
        .foregroundStyle(Color.customYellow)
      if let version = Self.versionString {
        Text(verbatim: version)
          .font(.caption)
          .foregroundStyle(.secondary)
          .numeric()
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, Layout.defaultSpacing)
    .accessibilityElement(children: .combine)
  }

  private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }

  private func settingSection<Content: View>(
    icon: String,
    isSystemSymbol: Bool = true,
    tint: Color,
    heading: String,
    description: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Label {
        Text(heading)
          .font(.title3.weight(.bold))
          .foregroundStyle(Color.customYellow)
      } icon: {
        // `isSystemSymbol == false` renders a custom symbol set (e.g. the "dancer"
        // line-art icon) rather than an SF Symbol.
        (isSystemSymbol ? Image(systemName: icon) : Image(icon))
          .font(.title3)
          .foregroundStyle(tint)
      }
      .accessibilityAddTraits(.isHeader)

      content()

      if !description.isEmpty {
        Text(description)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func enableGameCenter() {
    enableGameCenterTip.invalidate(reason: .actionPerformed)
    Current.settings.userRejectedGameCenter = false
    // Fire-and-forget: GameKit presents its own login sheet and publishes
    // `isAuthenticated` asynchronously. `isSignedInToGameCenter` is refreshed from
    // that state on the next `onAppear`; making it reactively hide the moment auth
    // settles waits on Settings observability.
    Current.gameCenter.authenticate()
  }

  private static var versionString: String? {
    let info = Bundle.main.infoDictionary
    guard let short = info?["CFBundleShortVersionString"] as? String else { return nil }
    if let build = info?["CFBundleVersion"] as? String {
      return "v\(short) (\(build))"
    }
    return "v\(short)"
  }
}
