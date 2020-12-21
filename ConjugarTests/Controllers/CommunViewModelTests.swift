//
//  CommunViewModelTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 12/21/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

@testable import Conjugar
import XCTest

class CommunViewModelTests: XCTestCase {
  func testProperties() {
    var didTapAction = false

    let settings = Settings(getterSetter: DictionaryGetterSetter())
    let gameCenter = TestGameCenter(isAuthenticated: false)
    let analytics = TestAnalyticsService()
    let quiz = Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false)
    let communGetter = StubCommunGetter()

    Current = World(
      analytics: analytics,
      reviewPrompter: TestReviewPrompter(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: quiz,
      session: URLSession.stubSession(ratingsCount: 0),
      communGetter: communGetter,
      locale: StubLocale(languageCode: "en", regionCode: "US")
    )

    let actionType = Commun.CommunType.website(actionTitle: ["en": "🐬"], cancelTitle: ["en": "🐉"], action: { didTapAction = true })
    let commun = Commun(title: ["en": "🐋"], image: UIImage(), imageLabel: ["en": "🍕"], content: ["en": "🏴󠁧󠁢󠁷󠁬󠁳󠁿"], type: actionType, identifier: 0)
    let vm = CommunViewModel(commun: commun)

    XCTAssertFalse(didTapAction)
    vm.action()
    XCTAssert(didTapAction)
    XCTAssertEqual(vm.title, "🐋")
    XCTAssertEqual(vm.content, "🏴󠁧󠁢󠁷󠁬󠁳󠁿")
    XCTAssertEqual(vm.imageLabel, "🍕")
    XCTAssertEqual(vm.okayTitle, "")
    XCTAssertEqual(vm.cancelTitle, "🐉")
    XCTAssertEqual(vm.actionTitle, "🐬")
  }
}
