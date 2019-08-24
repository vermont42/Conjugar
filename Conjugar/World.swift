//
//  World.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/15/19.
//  Enhanced by Stephen Celis on 1/16/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

#if targetEnvironment(simulator)
var Current = World.simulator
#else
var Current = World.device
#endif

struct World {
  var analytics: AnalyticsServiceable
  var reviewPrompter: ReviewPromptable
  var gameCenter: GameCenterable
  var settings: Settings
  var quiz: Quiz
  var session: URLSession

  private static let fakeRatingsCount = 42

  static let device: World = {
    let settings = Settings(getterSetter: UserDefaultsGetterSetter())
    let gameCenter = GameCenter.shared

    return World(
      analytics: AWSAnalyticsService(),
      reviewPrompter: ReviewPrompter(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true),
      session: URLSession.shared
    )
  }()

  static let simulator: World = {
    let settings = Settings(getterSetter: UserDefaultsGetterSetter())
    let gameCenter = TestGameCenter()

    return World(
      analytics: TestAnalyticsService(),
      reviewPrompter: TestReviewPrompter(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount)
    )
  }()

  static let unitTest: World = {
    let settings = Settings(getterSetter: DictionaryGetterSetter())
    let gameCenter = TestGameCenter()

    return World(
      analytics: TestAnalyticsService(),
      reviewPrompter: TestReviewPrompter(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount)
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
    let settings = Settings(getterSetter: DictionaryGetterSetter(dictionary: dictionary))
    let gameCenter = TestGameCenter()

    return World(
      analytics: TestAnalyticsService(),
      reviewPrompter: TestReviewPrompter(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount)
    )
  }
}
