//
//  World.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/15/19.
//  Enhanced by Stephen Celis on 1/16/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

@MainActor var Current = World.chooseWorld()

class World {
  var analytics: AnalyticsService
  var reviewPrompter: ReviewPrompter
  var gameCenter: GameCenter
  var settings: Settings
  var quiz: Quiz
  var session: URLSession
  var communGetter: CommunGetter
  var locale: AnalyticsLocale
  var languageModelService: LanguageModelService
  var getterSetter: GetterSetter
  var soundPlayer: SoundPlayer
  var hapticPlayer: HapticPlayer

  private static let fakeRatingsCount = 42

  init(
    analytics: AnalyticsService,
    reviewPrompter: ReviewPrompter,
    gameCenter: GameCenter,
    settings: Settings,
    quiz: Quiz,
    session: URLSession,
    communGetter: CommunGetter,
    locale: AnalyticsLocale,
    languageModelService: LanguageModelService,
    getterSetter: GetterSetter,
    soundPlayer: SoundPlayer,
    hapticPlayer: HapticPlayer
  ) {
    self.analytics = analytics
    self.reviewPrompter = reviewPrompter
    self.gameCenter = gameCenter
    self.settings = settings
    self.quiz = quiz
    self.session = session
    self.communGetter = communGetter
    self.locale = locale
    self.languageModelService = languageModelService
    self.getterSetter = getterSetter
    self.soundPlayer = soundPlayer
    self.hapticPlayer = hapticPlayer
  }

  // Under the SwiftUI App lifecycle there is no custom main.swift to select a
  // TestingAppDelegate, so the unit-test World selection lives here instead: a
  // simulator process with the XCTest runtime loaded is a unit-test run and
  // gets World.unitTest. (UI tests run the app in its own process and instead
  // override Current via the launch-argument path in AppDelegate.)
  static func chooseWorld() -> World {
#if targetEnvironment(simulator)
    if NSClassFromString("XCTest") != nil {
      return World.unitTest
    } else {
      return World.simulator
    }
#else
    return World.device
#endif
  }

  static let device: World = {
    let getterSetter = GetterSetterReal()
    let settings = Settings(getterSetter: getterSetter)
    let gameCenter = GameCenterReal.shared

    return World(
      // TODO: swap in a TelemetryDeck-backed AnalyticsService once integrated.
      analytics: AnalyticsServiceSpy(),
      reviewPrompter: ReviewPrompterReal(settings: settings),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true),
      session: URLSession.shared,
      communGetter: CommunGetterReal(),
      locale: AnalyticsLocaleReal(),
      languageModelService: LanguageModelServiceReal(),
      getterSetter: getterSetter,
      soundPlayer: SoundPlayerReal(),
      hapticPlayer: HapticPlayerReal()
    )
  }()

  static let simulator: World = {
    let getterSetter = GetterSetterReal()
    let settings = Settings(getterSetter: getterSetter)
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsServiceSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      communGetter: CommunGetterStub(),
      locale: AnalyticsLocaleStub(languageCode: "en", regionCode: "US"),
      languageModelService: LanguageModelServiceReal(),
      getterSetter: getterSetter,
      soundPlayer: SoundPlayerReal(),
      hapticPlayer: HapticPlayerReal()
    )
  }()

  static let unitTest: World = {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsServiceSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      communGetter: CommunGetterStub(),
      locale: AnalyticsLocaleStub(),
      languageModelService: LanguageModelServiceDummy(),
      getterSetter: getterSetter,
      soundPlayer: SoundPlayerDummy(),
      hapticPlayer: HapticPlayerDummy()
    )
  }()

  static func uiTest(launchArguments arguments: [String]) -> World {
    let region: Region
    if arguments.contains(Region.spain.rawValue) {
      region = .spain
    } else if arguments.contains(Region.latinAmerica.rawValue) {
      region = .latinAmerica
    } else {
      region = Settings.regionDefault
    }

    let difficulty: Difficulty
    if arguments.contains(Difficulty.difficult.rawValue) {
      difficulty = .difficult
    } else if arguments.contains(Difficulty.moderate.rawValue) {
      difficulty = .moderate
    } else if arguments.contains(Difficulty.easy.rawValue) {
      difficulty = .easy
    } else {
      difficulty = Settings.difficultyDefault
    }

    let dictionary = [Settings.regionKey: region.rawValue, Settings.difficultyKey: difficulty.rawValue]
    let getterSetter = GetterSetterFake(dictionary: dictionary)
    let settings = Settings(getterSetter: getterSetter)
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsServiceSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      communGetter: CommunGetterStub(),
      locale: AnalyticsLocaleStub(),
      languageModelService: LanguageModelServiceDummy(),
      getterSetter: getterSetter,
      soundPlayer: SoundPlayerDummy(),
      hapticPlayer: HapticPlayerDummy()
    )
  }
}
