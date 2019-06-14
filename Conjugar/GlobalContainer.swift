//
//  GlobalContainer.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/7/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation
import Swinject

struct GlobalContainer {
  private static let container = Container()
  private static let notRegisteredMessage = "has not been registered."
  static let fakeRatingsCount = 42

  static var settings: Settings {
    if let settings = container.resolve(Settings.self) {
      return settings
    } else {
      fatalError("\(Settings.self) \(notRegisteredMessage)")
    }
  }

  static var analytics: AnalyticsServiceable {
    if let analytics = container.resolve(AnalyticsServiceable.self) {
      return analytics
    } else {
      fatalError("\(AnalyticsServiceable.self) \(notRegisteredMessage)")
    }
  }

  static var reviewPrompter: ReviewPromptable {
    if let reviewPrompter = container.resolve(ReviewPromptable.self) {
      return reviewPrompter
    } else {
      fatalError("\(ReviewPromptable.self) \(notRegisteredMessage)")
    }
  }

  static var gameCenter: GameCenterable {
    if let gameCenter = container.resolve(GameCenterable.self) {
      return gameCenter
    } else {
      fatalError("\(GameCenterable.self) \(notRegisteredMessage)")
    }
  }

  static var quiz: Quiz {
    if let quiz = container.resolve(Quiz.self) {
      return quiz
    } else {
      fatalError("\(Quiz.self) \(notRegisteredMessage)")
    }
  }

  static var session: URLSession {
    if let session = container.resolve(URLSession.self) {
      return session
    } else {
      fatalError("\(URLSession.self) \(notRegisteredMessage)")
    }
  }

  static func registerSettings(_ settings: Settings) {
    container.register(Settings.self) { _ in settings }
  }

  static func registerAnalytics(_ analytics: AnalyticsServiceable) {
    container.register(AnalyticsServiceable.self) { _ in analytics }
  }

  static func registerReviewPrompter(_ reviewPrompter: ReviewPromptable) {
    container.register(ReviewPromptable.self) { _ in reviewPrompter }
  }

  static func registerGameCenter(_ gameCenter: GameCenterable) {
    container.register(GameCenterable.self) { _ in gameCenter }
  }

  static func registerQuiz(_ quiz: Quiz) {
    container.register(Quiz.self) { _ in quiz }
  }

  static func registerSession(_ session: URLSession) {
    container.register(URLSession.self) { _ in session }
  }

  static func registerDeviceDependencies() {
    let settings = Settings(getterSetter: UserDefaultsGetterSetter())
    let gameCenter = GameCenter()

    registerDependencies(settings: settings, analytics: AWSAnalyticsService(), reviewPrompter: ReviewPrompter(), gameCenter: gameCenter, quiz: Quiz(shouldShuffle: true), session: URLSession.shared)
  }

  static func registerSimulatorDependencies() {
    let settings = Settings(getterSetter: UserDefaultsGetterSetter())
    let gameCenter = TestGameCenter()

    registerDependencies(settings: settings, analytics: TestAnalyticsService(), reviewPrompter: TestReviewPrompter(), gameCenter: gameCenter, quiz: Quiz(shouldShuffle: true), session: URLSession.stubSession(ratingsCount: fakeRatingsCount))
  }

  static func registerUnitTestingDependencies() {
    registerUITestingDependencies(launchArguments: [])
  }

  static func registerUITestingDependencies(launchArguments arguments: [String]) {
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

    registerDependencies(settings: settings, analytics: TestAnalyticsService(), reviewPrompter: TestReviewPrompter(), gameCenter: gameCenter, quiz: Quiz(shouldShuffle: false), session: URLSession.stubSession(ratingsCount: fakeRatingsCount))
  }

  static func registerDependencies(settings: Settings, analytics: AnalyticsServiceable, reviewPrompter: ReviewPromptable, gameCenter: GameCenterable, quiz: Quiz, session: URLSession) {
    container.register(Settings.self) { _ in settings }
    container.register(AnalyticsServiceable.self) { _ in analytics }
    container.register(ReviewPromptable.self) { _ in reviewPrompter }
    container.register(GameCenterable.self) { _ in gameCenter }
    container.register(Quiz.self) { _ in quiz }
    container.register(URLSession.self) { _ in session }
  }
}
