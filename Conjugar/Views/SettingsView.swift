//
//  SettingsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//
//  Rebuilt for the SwiftUI migration to match the app's card-based design system
//  (drawing on the ios-design-agent-skill audit and the sibling apps Conjuguer /
//  Konjugieren): a NavigationStack with a scroll of grouped `card()`s, each a
//  settings section with a tinted SF Symbol heading, a segmented control or a
//  `TintedCapsuleButtonStyle` action, and a `.callout` explanation, split by
//  `GradientDivider`s. Segmented changes fire a selection haptic; the whole
//  measure is reading-width-constrained for iPad. Since Phase 4 / item 11 made
//  `Settings` `@Observable`, the pickers bind straight to `Current.settings` via
//  `@Bindable` — the old `SelectionStore` bridge and its `onAppear` copy-in are gone.
//  The global segmented-control appearance (yellow titles) moved to AppDelegate in
//  Phase 5 / item 13, so this view no longer needs an `init`.
//

import SwiftUI
import TipKit

struct SettingsView: View {
  static let englishTitle = "Settings"

  @Bindable private var settings = Current.settings
  @State private var isGameCenterUIHidden = false
  @State private var rateReviewDescription = ""
  private let changeDifficultyTip = ChangeDifficultyTip()
  private let enableGameCenterTip = EnableGameCenterTip()

  // Segmented-control appearance (yellow titles) is set once in AppDelegate now, not
  // from a per-body-evaluation `init` (item 13).

  var body: some View {
    NavigationStack {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
          regionCard
          quizCard
          browseCard
          actionsCard
          aboutFooter
        }
        .readingWidth()
        .padding(.horizontal, Layout.defaultHorizontalMargin)
        .padding(.bottom, Layout.tripleDefaultSpacing)
      }
      .frame(maxWidth: .infinity)
      .background(Color.customBackground.ignoresSafeArea())
      .navigationTitle(L.Settings.localizedTitle)
      .onAppear {
        isGameCenterUIHidden = Current.gameCenter.isAuthenticated
        Current.analytics.recordVisitation(viewController: "\(SettingsView.self)")
      }
      .task {
        // Surface the failure (item 20): show an unavailable message rather than
        // leaving the row silently empty when the iTunes lookup fails.
        rateReviewDescription = await RatingsFetcher.ratingsDescription() ?? L.Settings.ratingsUnavailable
      }
    }
  }

  // MARK: - Cards

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
        tint: .customBlue,
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

  private var actionsCard: some View {
    settingsCard {
      if !isGameCenterUIHidden {
        settingSection(
          icon: "gamecontroller.fill",
          tint: .customBlue,
          heading: L.Quiz.gameCenter,
          description: L.Settings.enableDescription
        ) {
          Button(L.Settings.enable) { enableGameCenter() }
            .buttonStyle(TintedCapsuleButtonStyle(tint: .customBlue))
            .popoverTip(enableGameCenterTip)
        }

        GradientDivider()
      }

      settingSection(
        icon: "star.fill",
        tint: .customYellow,
        heading: L.Settings.ratingsAndReviews,
        description: rateReviewDescription
      ) {
        Button(L.Settings.rateOrReview) {
          UIApplication.shared.open(RatingsFetcher.reviewURL)
        }
        .buttonStyle(TintedCapsuleButtonStyle(tint: .customYellow))
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

  // MARK: - Section builders

  private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }

  private func settingSection<Content: View>(
    icon: String,
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
        Image(systemName: icon)
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

  // MARK: - Actions

  private func enableGameCenter() {
    enableGameCenterTip.invalidate(reason: .actionPerformed)
    Current.settings.userRejectedGameCenter = false
    // Fire-and-forget: GameKit presents its own login sheet and publishes
    // `isAuthenticated` asynchronously. `isGameCenterUIHidden` is refreshed from
    // that state on the next `onAppear`; making it reactively hide the moment auth
    // settles waits on Settings observability (Phase 4 / item 11).
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
