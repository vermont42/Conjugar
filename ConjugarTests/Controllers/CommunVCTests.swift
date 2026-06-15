//
//  CommunVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 12/21/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class CommunVCTests: XCTestCase {
  func testTaps() {
    let settings = Settings(getterSetter: GetterSetterFake())
    let gameCenter = GameCenterFake(isAuthenticated: false)
    let analytics = AnalyticsServiceSpy()
    let quiz = Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false)
    let communGetter = CommunGetterStub()

    Current = World(
      analytics: analytics,
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: quiz,
      session: URLSession.stubSession(ratingsCount: 0),
      communGetter: communGetter,
      locale: AnalyticsLocaleStub(languageCode: "en", regionCode: "US")
    )

    let window = UIWindow(frame: UIScreen.main.bounds)
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    var cvc = CommunVC(commun: communGetter.information)

    rootVC.present(cvc, animated: false)
    XCTAssert(rootVC.presentedViewController is CommunVC)
    var exp = expectation(description: "tap happened")
    cvc.unitTestCompletion = {
      XCTAssertNil(rootVC.presentedViewController)
      exp.fulfill()
    }
    cvc.tapClose()
    let timeout: TimeInterval = 1.0
    waitForExpectations(timeout: timeout)

    rootVC.present(cvc, animated: false)
    XCTAssert(rootVC.presentedViewController is CommunVC)
    exp = expectation(description: "tap happened")
    cvc.unitTestCompletion = {
      XCTAssertNil(rootVC.presentedViewController)
      exp.fulfill()
    }
    cvc.tapOkay()
    waitForExpectations(timeout: timeout)

    var didTapAction = false
    let ctaType = Commun.CommunType.website(actionTitle: ["en": "🐬"], cancelTitle: ["en": "🐉"], action: { didTapAction = true })
    let ctaCommun = Commun(title: ["en": "🥥"], image: UIImage(), imageLabel: ["en": "🍕"], content: ["en": "🐋"], type: ctaType, identifier: 0)
    cvc = CommunVC(commun: ctaCommun)

    rootVC.present(cvc, animated: false)
    XCTAssert(rootVC.presentedViewController is CommunVC)
    exp = expectation(description: "tap happened")
    cvc.unitTestCompletion = {
      XCTAssertNil(rootVC.presentedViewController)
      exp.fulfill()
    }
    cvc.tapCancel()
    waitForExpectations(timeout: timeout)

    rootVC.present(cvc, animated: false)
    XCTAssert(rootVC.presentedViewController is CommunVC)
    exp = expectation(description: "tap happened")
    cvc.unitTestCompletion = {
      XCTAssertNil(rootVC.presentedViewController)
      XCTAssert(didTapAction)
      exp.fulfill()
    }
    cvc.tapAction()
    waitForExpectations(timeout: timeout)
  }
}
