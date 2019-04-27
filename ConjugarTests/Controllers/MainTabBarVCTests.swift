//
//  MainTabBarVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class MainTabBarVCTests: XCTestCase {
  func testMainTabBarVC() {
    let settings = Settings(getterSetter: DictionaryGetterSetter(dictionary: [:]))
    let testGameCenter = TestGameCenter()
    let mtbvc = MainTabBarVC(settings: settings, quiz: Quiz(settings: settings, gameCenter: testGameCenter, shouldShuffle: false), analyticsService: TestAnalyticsService(fire: {_ in}), reviewPrompter: TestReviewPrompter(), gameCenter: testGameCenter, session: stubSession)
    XCTAssertNotNil(mtbvc)
    UIApplication.shared.keyWindow?.rootViewController = mtbvc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    if let firstNavC = mtbvc.selectedViewController as? UINavigationController {
      if let browseVerbsVC = firstNavC.visibleViewController {
        if !(browseVerbsVC is BrowseVerbsVC) {
          XCTFail("First tab's UINavigationController's visibleViewController is not a BrowseVerbsVC.")
        }
      }
    } else {
      XCTFail("First tab is not a UINavigationController.")
    }
    mtbvc.selectedIndex = 1
    if let secondNavC = mtbvc.selectedViewController as? UINavigationController {
      if let quizVC = secondNavC.visibleViewController {
        if !(quizVC is QuizVC) {
          XCTFail("Second tab's UINavigationController's visibleViewController is not a QuizVC.")
        }
      }
    } else {
      XCTFail("Second tab is not a UINavigationController.")
    }
    mtbvc.selectedIndex = 2
    if let thirdNavC = mtbvc.selectedViewController as? UINavigationController {
      if let browseInfoVC = thirdNavC.visibleViewController {
        if !(browseInfoVC is BrowseInfoVC) {
          XCTFail("Third tab's UINavigationController's visibleViewController is not a BrowseInfoVC.")
        }
      }
    } else {
      XCTFail("Third tab is not a UINavigationController.")
    }
    mtbvc.selectedIndex = 3
    if let fourthNavC = mtbvc.selectedViewController as? UINavigationController {
      if let settingsVC = fourthNavC.visibleViewController {
        if !(settingsVC is SettingsVC) {
          XCTFail("Fourth tab's UINavigationController's visibleViewController is not a SettingsVC.")
        }
      }
    } else {
      XCTFail("Fourth tab is not a UINavigationController.")
    }
  }

  private var stubSession: URLSession {
    URLProtocolStub.testURLs = [RatingsFetcher.iTunesURL: RatingsFetcher.stubData()]
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: config)
  }
}
