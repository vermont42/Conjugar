// Copyright © 2026 Josh Adams. All rights reserved.

enum TipDisplay {
  /// Master switch for all TipKit tips. Ordinarily `true`. Set to `false` before
  /// generating screenshots (then restore to `true`) so no tip ever appears.
  ///
  /// When `false`, `ConjugarApp` skips `Tips.configure()`. TipKit displays nothing
  /// until it is configured, so every `TipView` and `.popoverTip(_:)` in the app stays
  /// hidden — no per-call-site changes needed.
  static let tipsEnabled = true
}

enum OnboardingDisplay {
  /// Master switch for the first-launch onboarding flow, mirroring `TipDisplay.tipsEnabled`.
  /// Ordinarily `true`. Set to `false` before generating screenshots (then restore to
  /// `true`) so the welcome tour never auto-presents over a screen being captured.
  ///
  /// Only the automatic first-launch presentation (`MainTabView`) consults this. The
  /// Settings "Show Onboarding" button ignores it, so the flow is always manually
  /// reachable for review.
  static let onboardingEnabled = true
}

enum TutorDisplay {
  /// Master switch for the Tutor section's *unavailability* row, mirroring the two
  /// switches above. Ordinarily `true`. Set to `false` before generating screenshots
  /// (then restore to `true`).
  ///
  /// The conjugation tutor needs Apple Intelligence, which is never available in a
  /// simulator, so `InfoBrowseView`'s tutor section renders a reason row there —
  /// "Apple Intelligence is still preparing. Try again later." That is honest on a
  /// device but reads as a defect in an App Store screenshot, so screen 6
  /// (`info_browse`) hides it. Only the reason row is suppressed: when the model *is*
  /// available the section still renders its `NavigationLink`, so this switch can
  /// never hide a working feature.
  static let tutorUnavailableRowEnabled = true
}
