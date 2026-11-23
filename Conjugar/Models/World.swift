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
  var analytics: Analytics
  var reviewPrompter: ReviewPrompter
  var gameCenter: GameCenter
  var settings: Settings
  var quiz: Quiz
  var session: URLSession
  var languageModelService: LanguageModelService
  var getterSetter: GetterSetter
  var soundPlayer: SoundPlayer
  var hapticPlayer: HapticPlayer
  /// The learner's opened and starred verbs, kept in the App Group so the widget can read them.
  var learnerVerbs: LearnerVerbStore
  /// What each quiz answer and lookup has practiced, kept in the App Group and sent nowhere.
  var practice: PracticeStore
  var liveActivities: LiveActivities

  private static let fakeRatingsCount = 42

  init(
    analytics: Analytics,
    reviewPrompter: ReviewPrompter,
    gameCenter: GameCenter,
    settings: Settings,
    quiz: Quiz,
    session: URLSession,
    languageModelService: LanguageModelService,
    getterSetter: GetterSetter,
    soundPlayer: SoundPlayer,
    hapticPlayer: HapticPlayer,
    learnerVerbs: LearnerVerbStore,
    practice: PracticeStore,
    liveActivities: LiveActivities
  ) {
    self.analytics = analytics
    self.reviewPrompter = reviewPrompter
    self.gameCenter = gameCenter
    self.settings = settings
    self.quiz = quiz
    self.session = session
    self.languageModelService = languageModelService
    self.getterSetter = getterSetter
    self.soundPlayer = soundPlayer
    self.hapticPlayer = hapticPlayer
    self.learnerVerbs = learnerVerbs
    self.practice = practice
    self.liveActivities = liveActivities
  }

  /// The App Group's defaults, where the record of the learner's verbs and the practice record
  /// live. The standard
  /// defaults stand in should the group be unavailable, so that the record is still kept.
  private static var sharedGetterSetter: GetterSetterReal {
    GetterSetterReal(userDefaults: WidgetConstants.sharedDefaults ?? .standard)
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
      analytics: AnalyticsReal(),
      reviewPrompter: ReviewPrompterReal(settings: settings),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true),
      session: URLSession.shared,
      languageModelService: LanguageModelServiceReal(),
      getterSetter: getterSetter,
      soundPlayer: SoundPlayerReal(),
      hapticPlayer: HapticPlayerReal(),
      learnerVerbs: LearnerVerbStore(getterSetter: sharedGetterSetter),
      practice: PracticeStore(getterSetter: sharedGetterSetter),
      liveActivities: LiveActivitiesReal()
    )
  }()

  static let simulator: World = {
    let getterSetter = GetterSetterReal()
    let settings = Settings(getterSetter: getterSetter)
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: true),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      languageModelService: LanguageModelServiceReal(),
      getterSetter: getterSetter,
      soundPlayer: SoundPlayerReal(),
      hapticPlayer: HapticPlayerReal(),
      learnerVerbs: LearnerVerbStore(getterSetter: sharedGetterSetter),
      practice: PracticeStore(getterSetter: sharedGetterSetter),
      liveActivities: LiveActivitiesReal()
    )
  }()

  static let unitTest: World = {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      languageModelService: LanguageModelServiceDummy(),
      getterSetter: getterSetter,
      soundPlayer: SoundPlayerDummy(),
      hapticPlayer: HapticPlayerDummy(),
      learnerVerbs: LearnerVerbStore(getterSetter: GetterSetterFake()),
      practice: PracticeStore(getterSetter: GetterSetterFake()),
      liveActivities: LiveActivitiesSpy()
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

    let quizLevel = QuizLevel.allCases.last { arguments.contains($0.rawValue) } ?? Settings.quizLevelDefault

    let dictionary = [Settings.regionKey: region.rawValue, Settings.quizLevelKey: quizLevel.rawValue]
    let getterSetter = GetterSetterFake(dictionary: dictionary)
    let settings = Settings(getterSetter: getterSetter)
    let gameCenter = GameCenterFake()

    return World(
      analytics: AnalyticsSpy(),
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false),
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      languageModelService: LanguageModelServiceDummy(),
      getterSetter: getterSetter,
      soundPlayer: SoundPlayerDummy(),
      hapticPlayer: HapticPlayerDummy(),
      learnerVerbs: LearnerVerbStore(getterSetter: GetterSetterFake()),
      practice: PracticeStore(getterSetter: GetterSetterFake()),
      liveActivities: LiveActivitiesSpy()
    )
  }
}
