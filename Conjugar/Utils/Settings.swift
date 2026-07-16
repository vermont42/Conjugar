//
//  Settings.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation
import Observation
import UIKit
import os

nonisolated private let settingsLogger = Logger(subsystem: "com.racecondition.Conjugar", category: "Settings")

// `@MainActor @Observable`: views that read a setting invalidate automatically when
// it changes, so the Quiz briefing pills track the Settings tab live and
// `SettingsView` binds its pickers straight to this object. Persistence is funneled
// through the two `read`/`persist` helper families below. The helpers are `static`
// so the `read` calls are legal during `init` (calling an instance method on a
// not-yet-fully-initialized `self` is not).
@MainActor
@Observable
final class Settings {
  private let getterSetter: GetterSetter

  var region: Region {
    didSet { Settings.persist(getterSetter, Settings.regionKey, region, oldValue) }
  }
  static let regionKey = "region"
  static let regionDefault: Region = .latinAmerica

  var difficulty: Difficulty {
    didSet { Settings.persist(getterSetter, Settings.difficultyKey, difficulty, oldValue) }
  }
  static let difficultyKey = "difficulty"
  static let difficultyDefault: Difficulty = .easy

  var infoDifficulty: Difficulty {
    didSet { Settings.persist(getterSetter, Settings.infoDifficultyKey, infoDifficulty, oldValue) }
  }
  static let infoDifficultyKey = "infoDifficulty"
  static let infoDifficultyDefault: Difficulty = .difficult

  var secondSingularBrowse: SecondSingularBrowse {
    didSet { Settings.persist(getterSetter, Settings.secondSingularBrowseKey, secondSingularBrowse, oldValue) }
  }
  static let secondSingularBrowseKey = "secondSingularBrowse"
  static let secondSingularBrowseDefault: SecondSingularBrowse = .tu

  var verbSort: VerbSort {
    didSet { Settings.persist(getterSetter, Settings.verbSortKey, verbSort, oldValue) }
  }
  static let verbSortKey = "verbSort"
  static let verbSortDefault: VerbSort = .frequency

  var modelSort: ModelSort {
    didSet { Settings.persist(getterSetter, Settings.modelSortKey, modelSort, oldValue) }
  }
  static let modelSortKey = "modelSort"
  static let modelSortDefault: ModelSort = .irregularity

  var secondSingularQuiz: SecondSingularQuiz {
    didSet { Settings.persist(getterSetter, Settings.secondSingularQuizKey, secondSingularQuiz, oldValue) }
  }
  static let secondSingularQuizKey = "secondSingularQuiz"
  static let secondSingularQuizDefault: SecondSingularQuiz = .tu

  var promptActionCount: Int {
    didSet { Settings.persist(getterSetter, Settings.promptActionCountKey, promptActionCount, oldValue) }
  }
  static let promptActionCountKey = "promptActionCount"
  static let promptActionCountDefault = 0

  var lastReviewPromptDate: Date {
    didSet { Settings.persist(getterSetter, Settings.lastReviewPromptDateKey, lastReviewPromptDate, oldValue) }
  }
  static let lastReviewPromptDateKey = "lastReviewPromptDate"
  static let lastReviewPromptDateDefault = Date(timeIntervalSince1970: 0.0)

  var userRejectedGameCenter: Bool {
    didSet { Settings.persist(getterSetter, Settings.userRejectedGameCenterKey, userRejectedGameCenter, oldValue) }
  }
  static let userRejectedGameCenterKey = "userRejectedGameCenter"
  static let userRejectedGameCenterDefault = false

  var didShowGameCenterDialog: Bool {
    didSet { Settings.persist(getterSetter, Settings.didShowGameCenterDialogKey, didShowGameCenterDialog, oldValue) }
  }
  static let didShowGameCenterDialogKey = "didShowGameCenterDialog"
  static let didShowGameCenterDialogDefault = false

  var lastCommunIdentifierShown: Int {
    didSet { Settings.persist(getterSetter, Settings.lastCommunIdentifierShownKey, lastCommunIdentifierShown, oldValue) }
  }
  static let lastCommunIdentifierShownKey = "lastCommunIdentifierShown"
  static let lastCommunIdentifierShownDefault = -1

  // Flipped true the first time the onboarding flow is dismissed, so it auto-presents
  // exactly once. The Settings "Show Onboarding" button re-shows it without touching
  // this flag (see `OnboardingView(isReshow:)`).
  var hasSeenOnboarding: Bool {
    didSet { Settings.persist(getterSetter, Settings.hasSeenOnboardingKey, hasSeenOnboarding, oldValue) }
  }
  static let hasSeenOnboardingKey = "hasSeenOnboarding"
  static let hasSeenOnboardingDefault = false

  // The user-selected app icon. On change, persists the choice AND swaps the live
  // home-screen icon via `setAlternateIconName`. `dancer` is the primary DancerIcon
  // (nil alternate) and the fresh-install default; selecting `classic` restores the
  // original flat-vector dancer (the `ClassicIcon` alternate).
  var appIcon: AppIcon {
    didSet {
      Settings.persist(getterSetter, Settings.appIconKey, appIcon, oldValue)
      guard appIcon != oldValue else { return }
      setAppIcon(appIcon)
    }
  }
  static let appIconKey = "appIcon"
  static let appIconDefault: AppIcon = .dancer

  init(getterSetter: GetterSetter) {
    self.getterSetter = getterSetter

    region = Settings.read(getterSetter, Settings.regionKey, default: Settings.regionDefault)
    difficulty = Settings.read(getterSetter, Settings.difficultyKey, default: Settings.difficultyDefault)
    infoDifficulty = Settings.read(getterSetter, Settings.infoDifficultyKey, default: Settings.infoDifficultyDefault)
    secondSingularBrowse = Settings.read(getterSetter, Settings.secondSingularBrowseKey, default: Settings.secondSingularBrowseDefault)
    verbSort = Settings.read(getterSetter, Settings.verbSortKey, default: Settings.verbSortDefault)
    modelSort = Settings.read(getterSetter, Settings.modelSortKey, default: Settings.modelSortDefault)
    secondSingularQuiz = Settings.read(getterSetter, Settings.secondSingularQuizKey, default: Settings.secondSingularQuizDefault)
    promptActionCount = Settings.read(getterSetter, Settings.promptActionCountKey, default: Settings.promptActionCountDefault)
    lastReviewPromptDate = Settings.read(getterSetter, Settings.lastReviewPromptDateKey, default: Settings.lastReviewPromptDateDefault)
    userRejectedGameCenter = Settings.read(getterSetter, Settings.userRejectedGameCenterKey, default: Settings.userRejectedGameCenterDefault)
    didShowGameCenterDialog = Settings.read(getterSetter, Settings.didShowGameCenterDialogKey, default: Settings.didShowGameCenterDialogDefault)
    lastCommunIdentifierShown = Settings.read(getterSetter, Settings.lastCommunIdentifierShownKey, default: Settings.lastCommunIdentifierShownDefault)
    hasSeenOnboarding = Settings.read(getterSetter, Settings.hasSeenOnboardingKey, default: Settings.hasSeenOnboardingDefault)
    appIcon = Settings.read(getterSetter, Settings.appIconKey, default: Settings.appIconDefault)
  }

  // Swap the live home-screen icon. No-op when the requested icon already matches
  // (avoids the system "You have changed the icon" alert on a redundant set) or when
  // the device doesn't support alternate icons. `didSet`, not `init`, drives this, so
  // it never fires at launch; iOS persists the chosen alternate icon across launches.
  private func setAppIcon(_ icon: AppIcon) {
    guard UIApplication.shared.supportsAlternateIcons else { return }
    let desiredName = icon.alternateIconName
    guard UIApplication.shared.alternateIconName != desiredName else { return }
    UIApplication.shared.setAlternateIconName(desiredName) { error in
      if let error {
        settingsLogger.error("Could not set alternate app icon: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  // Read a value for `key`, seeding (and persisting) `defaultValue` the first time
  // the key is absent so the store always reflects the effective setting. A
  // present-but-unparseable value falls back to the default without a rewrite.

  private static func read<T: RawRepresentable<String>>(_ getterSetter: GetterSetter, _ key: String, default defaultValue: T) -> T {
    guard let raw = getterSetter.get(key: key) else {
      getterSetter.set(key: key, value: defaultValue.rawValue)
      return defaultValue
    }
    return T(rawValue: raw) ?? defaultValue
  }

  private static func read(_ getterSetter: GetterSetter, _ key: String, default defaultValue: Int) -> Int {
    guard let raw = getterSetter.get(key: key) else {
      getterSetter.set(key: key, value: "\(defaultValue)")
      return defaultValue
    }
    return Int(raw) ?? defaultValue
  }

  private static func read(_ getterSetter: GetterSetter, _ key: String, default defaultValue: Bool) -> Bool {
    guard let raw = getterSetter.get(key: key) else {
      getterSetter.set(key: key, value: "\(defaultValue)")
      return defaultValue
    }
    return raw == "true"
  }

  private static func read(_ getterSetter: GetterSetter, _ key: String, default defaultValue: Date) -> Date {
    guard let raw = getterSetter.get(key: key), let interval = TimeInterval(raw) else {
      getterSetter.set(key: key, value: "\(defaultValue.timeIntervalSince1970)")
      return defaultValue
    }
    return Date(timeIntervalSince1970: interval)
  }

  // Persist `value` only when it actually changed, mirroring the old `didSet` guards.

  private static func persist(_ getterSetter: GetterSetter, _ key: String, _ value: some RawRepresentable<String>, _ oldValue: some RawRepresentable<String>) {
    guard value.rawValue != oldValue.rawValue else { return }
    getterSetter.set(key: key, value: value.rawValue)
  }

  private static func persist(_ getterSetter: GetterSetter, _ key: String, _ value: Int, _ oldValue: Int) {
    guard value != oldValue else { return }
    getterSetter.set(key: key, value: "\(value)")
  }

  private static func persist(_ getterSetter: GetterSetter, _ key: String, _ value: Bool, _ oldValue: Bool) {
    guard value != oldValue else { return }
    getterSetter.set(key: key, value: "\(value)")
  }

  private static func persist(_ getterSetter: GetterSetter, _ key: String, _ value: Date, _ oldValue: Date) {
    guard value != oldValue else { return }
    getterSetter.set(key: key, value: "\(value.timeIntervalSince1970)")
  }
}
