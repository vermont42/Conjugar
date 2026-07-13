//
//  OnboardingView.swift
//  Conjugar
//
//  The first-launch welcome tour, ported from the sibling app Conjuguer and adapted
//  for Conjugar (July 2026). A paged `TabView` of sheets — welcome, the four content
//  tabs, the on-device tutor (only when Apple Intelligence is available), the deep-dive
//  articles, and finally a preview of the under-development game whose CTA launches it.
//  Presented as a `.fullScreenCover`: once at first launch from `MainTabView` (gated by
//  `Settings.hasSeenOnboarding` + the `OnboardingDisplay.onboardingEnabled` kill switch),
//  and on demand from the Settings tab with `isReshow: true`. Styled to Conjugar's yellow
//  design system rather than Conjuguer's blue. `Music.onboarding` plays for the duration
//  and fades out on dismiss.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A page icon: an SF Symbol for the content sheets, or one of the app's custom symbol
/// sets ("bull"/"dancer") for the welcome and game sheets.
private enum OnboardingSymbol {
  case system(String)
  case custom(String)
}

struct OnboardingView: View {
  // Passed in explicitly rather than read from `@Environment`: this view is presented
  // in a `.fullScreenCover`, and cover content does not reliably inherit a custom
  // `.environment(router)` object, so an `@Environment(AppRouter.self)` read traps.
  let router: AppRouter
  let isReshow: Bool
  /// Called by the game sheet's CTA just before dismissal. The presenter records the
  /// intent and launches the game in the cover's `onDismiss`, so the game cover never
  /// tries to present over the still-dismissing onboarding cover.
  var requestGame: () -> Void

  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var currentPage = 0
  @State private var getStartedOffset: CGFloat = 100
  @State private var getStartedOpacity: Double = 0

  private var isTutorAvailable: Bool { Current.languageModelService.isAvailable }
  private var articlesTag: Int { isTutorAvailable ? 5 : 4 }
  private var lastPageTag: Int { isTutorAvailable ? 6 : 5 }

  fileprivate static let entranceAnimation = Animation.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)
  private static let musicFadeDuration: TimeInterval = 1.5

  init(router: AppRouter, isReshow: Bool = false, requestGame: @escaping () -> Void = {}) {
    self.router = router
    self.isReshow = isReshow
    self.requestGame = requestGame
  }

  var body: some View {
    ZStack(alignment: .top) {
      Color.customBackground
        .ignoresSafeArea()

      LinearGradient(
        colors: [.customYellow.opacity(0.20), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 300)
      .frame(maxWidth: .infinity)
      .ignoresSafeArea()
      .allowsHitTesting(false)
      .accessibilityHidden(true)

      VStack {
        HStack {
          Spacer()
          if currentPage < lastPageTag {
            Button(isReshow ? L.Onboarding.dismiss : L.Onboarding.skip) {
              finishOnboarding()
            }
            .foregroundStyle(Color.customYellow)
            .padding(.trailing, Layout.doubleDefaultSpacing)
          }
        }

        TabView(selection: $currentPage) {
          OnboardingPageView(
            symbol: .custom("bull"),
            title: L.Onboarding.welcomeTitle,
            bodyText: L.Onboarding.welcomeBody
          )
          .tag(0)

          OnboardingPageView(
            symbol: .system("list.bullet.rectangle.portrait.fill"),
            title: L.Onboarding.browseTitle,
            bodyText: L.Onboarding.browseBody,
            ctaTitle: L.Onboarding.browseVerbsButton,
            onCTA: { navigate(to: .browseVerbs) }
          )
          .tag(1)

          OnboardingPageView(
            symbol: .system("key.fill"),
            title: L.Onboarding.modelsTitle,
            bodyText: L.Onboarding.modelsBody,
            ctaTitle: L.Onboarding.exploreModelsButton,
            onCTA: { navigate(to: .models) }
          )
          .tag(2)

          OnboardingPageView(
            symbol: .system("trophy.fill"),
            title: L.Onboarding.quizTitle,
            bodyText: L.Onboarding.quizBody,
            ctaTitle: L.Onboarding.startQuizButton,
            onCTA: { navigate(to: .quiz) }
          )
          .tag(3)

          if isTutorAvailable {
            OnboardingPageView(
              symbol: .system("brain.head.profile.fill"),
              title: L.Onboarding.aiTitle,
              bodyText: L.Onboarding.aiBody,
              ctaTitle: L.Onboarding.meetTutorButton,
              onCTA: { navigateToTutor() }
            )
            .tag(4)
          }

          OnboardingPageView(
            symbol: .system("text.book.closed.fill"),
            title: L.Onboarding.learnTitle,
            bodyText: L.Onboarding.learnBody,
            ctaTitle: L.Onboarding.readArticlesButton,
            onCTA: { navigate(to: .info) }
          )
          .tag(articlesTag)

          OnboardingPageView(
            symbol: .custom("dancer"),
            title: L.Onboarding.gameTitle,
            bodyText: L.Onboarding.gameBody,
            ctaTitle: L.Onboarding.playGameButton,
            onCTA: {
              requestGame()
              finishOnboarding()
            },
            animateContent: true
          )
          .tag(lastPageTag)
        }
        .tabViewStyle(.page)

        if currentPage == lastPageTag {
          Button(L.Onboarding.getStarted) {
            finishOnboarding()
          }
          .buttonStyle(PrimaryButtonStyle())
          .padding(.bottom, Layout.tripleDefaultSpacing)
          .offset(y: getStartedOffset)
          .opacity(getStartedOpacity)
        }
      }
    }
    .sensoryFeedback(.impact(weight: .light), trigger: currentPage)
    .onAppear {
      Current.analytics.recordVisitation(viewController: "\(OnboardingView.self)")
      Current.languageModelService.startAvailabilityMonitoring()
      Current.soundPlayer.startMusic(.onboarding)
    }
    .onDisappear {
      Current.languageModelService.stopAvailabilityMonitoring()
      Current.soundPlayer.stopMusic(fadeDuration: Self.musicFadeDuration)
    }
    .onChange(of: currentPage) { oldValue, newValue in
      if newValue == lastPageTag {
        withAnimation(reduceMotion ? nil : OnboardingView.entranceAnimation) {
          getStartedOffset = 0
          getStartedOpacity = 1
        }
      } else if oldValue == lastPageTag {
        getStartedOffset = 100
        getStartedOpacity = 0
      }
    }
  }

  private func navigate(to tab: AppTab) {
    router.selectedTab = tab
    finishOnboarding()
  }

  private func navigateToTutor() {
    router.selectedTab = .info
    router.pendingTutor = true
    finishOnboarding()
  }

  private func finishOnboarding() {
    if !isReshow {
      Current.settings.hasSeenOnboarding = true
    }
    dismiss()
  }
}

private struct OnboardingPageView: View {
  let symbol: OnboardingSymbol
  let title: String
  let bodyText: String
  var ctaTitle: String?
  var onCTA: () -> Void
  var animateContent: Bool

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var contentOffset: CGFloat = 100
  @State private var contentOpacity: Double = 0
  @State private var bounceValue = 0

  init(
    symbol: OnboardingSymbol,
    title: String,
    bodyText: String,
    ctaTitle: String? = nil,
    onCTA: @escaping () -> Void = {},
    animateContent: Bool = false
  ) {
    self.symbol = symbol
    self.title = title
    self.bodyText = bodyText
    self.ctaTitle = ctaTitle
    self.onCTA = onCTA
    self.animateContent = animateContent
  }

  var body: some View {
    VStack(spacing: Layout.doubleDefaultSpacing) {
      Spacer()
        .frame(maxHeight: 100)

      symbolImage
        .font(.system(size: 80))
        .foregroundStyle(Color.customYellow)
        .symbolEffect(.bounce, value: bounceValue)
        .accessibilityHidden(true)

      Text(title)
        .font(.title.weight(.bold))
        .foregroundStyle(Color.customYellow)
        .multilineTextAlignment(.center)
        .padding(.horizontal, Layout.doubleDefaultSpacing)

      Text(bodyText)
        .font(.callout)
        .foregroundStyle(Color.customForeground)
        .multilineTextAlignment(.center)
        .padding(.horizontal, Layout.tripleDefaultSpacing)

      if let ctaTitle {
        Button(ctaTitle) { onCTA() }
          .buttonStyle(PrimaryButtonStyle())
      }

      Spacer()
    }
    .offset(y: animateContent ? contentOffset : 0)
    .opacity(animateContent ? contentOpacity : 1)
    .onAppear {
      bounceValue += 1
      if animateContent {
        withAnimation(reduceMotion ? nil : OnboardingView.entranceAnimation) {
          contentOffset = 0
          contentOpacity = 1
        }
      }
    }
  }

  @ViewBuilder
  private var symbolImage: some View {
    switch symbol {
    case .system(let name):
      Image(systemName: name)
    case .custom(let name):
      Image(name)
    }
  }
}
