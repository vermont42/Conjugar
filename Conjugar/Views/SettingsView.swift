//
//  SettingsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//
//  Rebuilt for the SwiftUI migration to match the app's card-based design system:
//  a NavigationStack with a scroll of grouped `card()`s, each a settings section
//  with a tinted SF Symbol heading, a segmented control or a
//  `TintedCapsuleButtonStyle` action, and a `.callout` explanation, split by
//  `GradientDivider`s. Segmented changes fire a selection haptic; the whole
//  measure is reading-width-constrained for iPad. Because `Settings` is
//  `@Observable`, the pickers bind straight to `Current.settings` via `@Bindable`
//  — the old `SelectionStore` bridge and its `onAppear` copy-in are gone. The
//  global segmented-control appearance (yellow titles) lives in AppDelegate, so
//  this view needs no `init`.
//

import SwiftUI
import TipKit

struct SettingsView: View {
  static let englishTitle = "Settings"

  // Passed in from `MainTabView` so it can be handed to the onboarding cover, whose
  // content can't reliably read `@Environment(AppRouter.self)` (see `OnboardingView`).
  let router: AppRouter
  @Bindable private var settings = Current.settings
  @State private var isGameCenterUIHidden = false
  @State private var rateReviewDescription = ""
  @State private var showingGame = false
  @State private var showingOnboarding = false
  // See MainTabView: the onboarding game CTA defers the game launch to the cover's
  // onDismiss so the two covers never overlap.
  @State private var pendingGameAfterOnboarding = false
  private let changeDifficultyTip = ChangeDifficultyTip()
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
      .fullScreenCover(isPresented: $showingOnboarding, onDismiss: launchGameAfterOnboardingIfRequested) {
        OnboardingView(router: router, isReshow: true, requestGame: { pendingGameAfterOnboarding = true })
      }
      .navigationTitle(L.Settings.localizedTitle)
      .onAppear {
        isGameCenterUIHidden = Current.gameCenter.isAuthenticated
        Current.analytics.recordVisitation(viewController: "\(SettingsView.self)")
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
        heading: L.Settings.difficulty,
        description: L.Settings.difficultyDescription
      ) {
        Picker(selection: $settings.difficulty) {
          ForEach(Difficulty.allCases, id: \.self) { difficulty in
            Text(difficulty.localizedDifficulty).tag(difficulty)
          }
        } label: {
          Text(verbatim: "")
        }
        .pickerStyle(.segmented)
        .selectionFeedback(trigger: settings.difficulty)
        .accessibilityLabel(L.Settings.difficulty)
      }
      .popoverTip(changeDifficultyTip)
      .onChange(of: settings.difficulty) {
        changeDifficultyTip.invalidate(reason: .actionPerformed)
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
    }
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
        description: L.Onboarding.gameBody
      ) {
        Button(L.Game.play) { showingGame = true }
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
        Button(L.Onboarding.showOnboarding) { showingOnboarding = true }
          .buttonStyle(TintedCapsuleButtonStyle(tint: .customGreen))
      }
    }
  }

  private var actionsCard: some View {
    settingsCard {
      if !isGameCenterUIHidden {
        settingSection(
          icon: "gamecontroller.fill",
          tint: .customRed,
          heading: L.Quiz.gameCenter,
          description: L.Settings.enableDescription
        ) {
          Button(L.Settings.enable) { enableGameCenter() }
            .buttonStyle(TintedCapsuleButtonStyle(tint: .customRed))
            .popoverTip(enableGameCenterTip)
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

  private func launchGameAfterOnboardingIfRequested() {
    guard pendingGameAfterOnboarding else { return }
    pendingGameAfterOnboarding = false
    showingGame = true
  }

  private func enableGameCenter() {
    enableGameCenterTip.invalidate(reason: .actionPerformed)
    Current.settings.userRejectedGameCenter = false
    // Fire-and-forget: GameKit presents its own login sheet and publishes
    // `isAuthenticated` asynchronously. `isGameCenterUIHidden` is refreshed from
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
