//
//  World.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/15/19.
//  Enhanced by Stephen Celis on 1/16/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Observation
import SwiftUI

#if targetEnvironment(simulator)
var Current = World.simulator
#else
var Current = World.device
#endif

class World {
  var analytics: AnalyticsService
  var reviewPrompter: ReviewPrompter
  var gameCenter: GameCenter
  var settings: Settings
  var quiz: Quiz
  var session: URLSession
  var communGetter: CommunGetter
  var locale: AnalyticsLocale
  var parentViewController: UIViewController?

  private static let fakeRatingsCount = 42

  init(
    analytics: AnalyticsService,
    reviewPrompter: ReviewPrompter,
    gameCenter: GameCenter,
    settings: Settings,
    quiz: Quiz,
    session: URLSession,
    communGetter: CommunGetter,
    locale: AnalyticsLocale
  ) {
    self.analytics = analytics
    self.reviewPrompter = reviewPrompter
    self.gameCenter = gameCenter
    self.settings = settings
    self.quiz = quiz
    self.session = session
    self.communGetter = communGetter
    self.locale = locale
  }

  static let device: World = {
    let settings = Settings(getterSetter: GetterSetterReal())
    let gameCenter = GameCenterReal.shared

    return World(
      // TODO: swap in a TelemetryDeck-backed AnalyticsService once integrated.
      analytics: AnalyticsServiceSpy(),
      reviewPrompter: ReviewPrompterReal(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true),
      session: URLSession.shared,
      communGetter: CommunGetterReal(),
      locale: AnalyticsLocaleReal()
    )
  }()

  static let simulator: World = {
    let settings = Settings(getterSetter: GetterSetterReal())
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsServiceSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      communGetter: CommunGetterStub(),
      locale: AnalyticsLocaleStub(languageCode: "en", regionCode: "US")
    )
  }()

  static let unitTest: World = {
    let settings = Settings(getterSetter: GetterSetterFake())
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsServiceSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      communGetter: CommunGetterStub(),
      locale: AnalyticsLocaleStub()
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
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: dictionary))
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsServiceSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      communGetter: CommunGetterStub(),
      locale: AnalyticsLocaleStub()
    )
  }
}
