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
  // Passed in from `MainTabView`, whose covers Play and Show Onboarding present, so that a link
  // that arrives during the game can close it.
  let router: AppRouter
  @Bindable private var settings = Current.settings
  @State private var isSignedInToGameCenter = false
  @State private var rateReviewDescription = ""
  @State private var showingResetPractice = false
  /// Notifications are not allowed, so the daily reminder cannot appear.
  @State private var areRemindersDenied = false
  // A popover tip attached to a view that outlives the tab's first visit would float over another
  // tab, pointing at nothing, when its rule is met there, as ChangeLevelTip's is when a quiz
  // finishes. Tips are therefore attached only while Settings is on screen.
  @State private var isOnScreen = false
  /// Whether the title at the top of the screen is on screen. See `WrappingTitle`: at the largest
  /// accessibility size, the system's large title truncated "Configuración".
  @State private var isTitleVisible = true
  private let changeLevelTip = ChangeLevelTip()
  private let enableGameCenterTip = EnableGameCenterTip()

  var body: some View {
    NavigationStack {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
          WrappingTitle(title: L.Settings.localizedTitle, isVisible: $isTitleVisible)
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
      .wrappingTitleBar(L.Settings.localizedTitle, isTitleVisible: isTitleVisible)
      .onAppear {
        isOnScreen = true
        isSignedInToGameCenter = Current.gameCenter.isAuthenticated
        Current.analytics.signal(name: .viewSettingsView)
      }
      .onDisappear {
        isOnScreen = false
      }
      // Notifications can be turned off in the Settings app while the reminder is on.
      .task(id: isOnScreen) {
        guard isOnScreen, settings.dailyReminder == .on else {
          return
        }
        areRemindersDenied = !(await Current.reminderScheduler.isAuthorized())
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

      GradientDivider()

      settingSection(
        icon: "bell.fill",
        tint: .customGreen,
        heading: L.DailyReminder.heading,
        description: L.DailyReminder.description
      ) {
        dailyReminderControls
      }

      if !Current.practice.isEmpty || Current.learnerVerbs.hasOpenHistory {
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
          Current.learnerVerbs.forgetOpenHistory()
        }
        Current.rescheduleReminders()
        Current.analytics.signal(name: .tapResetPractice)
      }
      Button(role: .cancel) {}
    } message: {
      Text(L.Settings.resetPracticeMessage)
    }
  }

  /// Off and On, the time while on, and a way to the Settings app while notifications are not
  /// allowed. Permission is asked for only when the learner turns the reminder on.
  @ViewBuilder
  private var dailyReminderControls: some View {
    Picker(selection: Binding(get: { settings.dailyReminder }, set: { setDailyReminder($0) })) {
      ForEach(DailyReminder.allCases, id: \.self) { reminder in
        Text(reminder.localizedDailyReminder).tag(reminder)
      }
    } label: {
      Text(verbatim: "")
    }
    .pickerStyle(.segmented)
    .selectionFeedback(trigger: settings.dailyReminder)
    .accessibilityLabel(L.DailyReminder.heading)
    .accessibilityIdentifier("daily_reminder_picker")

    if settings.dailyReminder == .on {
      DatePicker(L.DailyReminder.time, selection: dailyReminderTime, displayedComponents: .hourAndMinute)
        .foregroundStyle(Color.customForeground)
        .tint(.customYellow)
        .accessibilityIdentifier("daily_reminder_time")
    }

    if areRemindersDenied {
      Text(L.DailyReminder.denied)
        .font(.callout)
        .foregroundStyle(Color.customRed)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("daily_reminder_denied")
      Button(L.DailyReminder.openSettings) {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
      .buttonStyle(TintedCapsuleButtonStyle(tint: .customGreen))
      .accessibilityIdentifier("daily_reminder_open_settings")
    }
  }

  /// Today at the reminder's time, which the picker shows as a time alone.
  private var dailyReminderTime: Binding<Date> {
    Binding {
      let minutes = settings.dailyReminderMinutes
      return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    } set: { date in
      let components = Calendar.current.dateComponents([.hour, .minute], from: date)
      settings.dailyReminderMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
      Current.rescheduleReminders()
    }
  }

  /// Turning the reminder on asks for permission, and a refusal leaves it off, with a line saying
  /// why. The signal says which: `true`, `false`, or `denied`.
  private func setDailyReminder(_ reminder: DailyReminder) {
    guard reminder == .on else {
      settings.dailyReminder = .off
      areRemindersDenied = false
      Current.rescheduleReminders()
      Current.analytics.signal(name: .tapDailyReminder, parameters: [ParameterKey.enabled.rawValue: "false"])
      return
    }
    Task {
      let isAllowed = await Current.reminderScheduler.requestAuthorization()
      settings.dailyReminder = isAllowed ? .on : .off
      areRemindersDenied = !isAllowed
      Current.rescheduleReminders()
      Current.analytics.signal(name: .tapDailyReminder, parameters: [ParameterKey.enabled.rawValue: isAllowed ? "true" : Self.deniedValue])
    }
  }

  static let deniedValue = "denied"

  // A segmented control would truncate Intermediate and Intermedio on an iPhone, so the levels
  // are tiles, each with a gauge whose needle rises with the level. The names are one size and
  // never shrink, so the columns give way instead: four in a row when every name fits its column,
  // else two rows of two, else one tile per row with the name beside its gauge, for the
  // accessibility sizes. `EqualWidthRow` makes that measurement honest.
  private var quizLevelPicker: some View {
    let levels = QuizLevel.allCases
    let half = levels.count / 2
    return ViewThatFits(in: .horizontal) {
      EqualWidthRow(spacing: Layout.defaultSpacing) {
        ForEach(levels, id: \.self) { levelButton($0, isWide: false) }
      }
      VStack(spacing: Layout.defaultSpacing) {
        EqualWidthRow(spacing: Layout.defaultSpacing) {
          ForEach(levels.prefix(half), id: \.self) { levelButton($0, isWide: false) }
        }
        EqualWidthRow(spacing: Layout.defaultSpacing) {
          ForEach(levels.suffix(from: half), id: \.self) { levelButton($0, isWide: false) }
        }
      }
      VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
        ForEach(levels, id: \.self) { levelButton($0, isWide: true) }
      }
    }
    .selectionFeedback(trigger: settings.quizLevel)
  }

  /// A level's gauge with its name under it, or beside it when `isWide`.
  private func levelButton(_ quizLevel: QuizLevel, isWide: Bool) -> some View {
    let isSelected = settings.quizLevel == quizLevel
    let gauge = Image(systemName: quizLevel.systemImage)
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
    let name = Text(quizLevel.localizedName)
      .font(.caption)
      .foregroundStyle(isSelected ? Color.customYellow : Color.customForeground)
      .lineLimit(1)
    return Button {
      settings.quizLevel = quizLevel
    } label: {
      Group {
        if isWide {
          HStack(spacing: Layout.doubleDefaultSpacing) {
            gauge
            name
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        } else {
          VStack(spacing: 4) {
            gauge
            name
          }
          .frame(maxWidth: .infinity)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(quizLevel.localizedName)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityIdentifier("quiz_level_\(quizLevel.rawValue)")
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
          router.showGame = true
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
          router.reshowOnboarding()
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

        settingSection(
          icon: "rosette",
          tint: .customYellow,
          heading: L.GameCenter.achievementsHeading,
          description: L.GameCenter.viewAchievementsDescription
        ) {
          Button(L.GameCenter.viewAchievements) {
            Current.gameCenter.showAchievements()
            Current.analytics.signal(name: .tapViewAchievements)
          }
          .buttonStyle(TintedCapsuleButtonStyle(tint: .customYellow))
          .accessibilityHint(L.GameCenter.viewAchievementsHint)
          .accessibilityIdentifier("settings_achievements")
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
