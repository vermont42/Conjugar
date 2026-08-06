# Onboarding

A first-launch welcome tour, styled to Conjugar's yellow design system. Files:
`Views/OnboardingView.swift`, the `OnboardingDisplay` kill switch in `Utils/KillSwitches.swift`,
`Settings.hasSeenOnboarding`, `L.Onboarding` + `Localizable.xcstrings` (`Onboarding.*`). Things
to know:

- **A paged `.fullScreenCover`** (`TabView(.page)` with auto page-dots). Sheets: a welcome
  sheet using the custom **`bull`** symbol, four content sheets (Browse/Models/Quiz/Articles,
  each keeping its CTA → tab), a **conditional AI-tutor sheet** shown only when
  `Current.languageModelService.isAvailable` (so never in the simulator), and a **game-preview
  sheet** using the custom **`dancer`** symbol whose CTA launches the game. The final sheet
  shows the animated **"Get Started"** button below the dots; the top-right button reads
  **Skip** (first run) / **Dismiss** (reshow).
- **Presented from two places.** First launch: `MainTabView` trips `router.showOnboarding` once
  in its launch `.task`, gated by `!Settings.hasSeenOnboarding` **and**
  `OnboardingDisplay.onboardingEnabled` (the screenshot kill switch, mirroring
  `TipDisplay.tipsEnabled`; the Settings "Show Onboarding" reshow ignores it). Reshow:
  `SettingsView`'s onboarding card presents it with `isReshow: true`, which does **not** touch
  the flag.
- **`AppRouter` is passed in explicitly, not via `@Environment`.** A `.fullScreenCover`'s
  content does not inherit a custom `.environment(router)` object (a direct tab child does), so
  `OnboardingView`/`SettingsView` take an explicit `router:` — reading it from the environment
  in the cover traps with "No Observable object of type AppRouter found". Tab-navigation CTAs
  set `router.selectedTab` (and `router.pendingTutor` for the tutor, consumed by
  `InfoBrowseView`); the game CTA defers to each cover's `onDismiss` so two covers never overlap.
- **Music.** `Music.onboarding` (Pond5's "Spanish Tension", `Conjugar/Audio/spanishTension.mp3`)
  plays as a looping bed: `Current.soundPlayer.startMusic(.onboarding)` on the view's
  `.onAppear`, faded out on dismiss via `Current.soundPlayer.stopMusic(fadeDuration:)` — the
  graceful counterpart to `startMusic`'s fade-in. See [`docs/game.md`](game.md) for the rest of
  the `Music` enum.
