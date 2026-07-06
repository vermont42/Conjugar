//
//  MainTabBarVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
import SwiftUI
@testable import Conjugar

class MainTabBarVCTests: XCTestCase {
  func testMainTabBarVC() {
    let mtbvc = MainTabBarVC()
    XCTAssertNotNil(mtbvc)
    XCTAssertEqual(mtbvc.viewControllers?.count, 5)

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
      if let browseModelsVC = secondNavC.visibleViewController {
        if !(browseModelsVC is BrowseModelsVC) {
          XCTFail("Second tab's UINavigationController's visibleViewController is not a BrowseModelsVC.")
        }
      }
    } else {
      XCTFail("Second tab is not a UINavigationController.")
    }

    mtbvc.selectedIndex = 2
    if let thirdNavC = mtbvc.selectedViewController as? UINavigationController {
      if let quizVC = thirdNavC.visibleViewController {
        if !(quizVC is QuizVC) {
          XCTFail("Third tab's UINavigationController's visibleViewController is not a QuizVC.")
        }
      }
    } else {
      XCTFail("Third tab is not a UINavigationController.")
    }

    mtbvc.selectedIndex = 3
    if let fourthNavC = mtbvc.selectedViewController as? UINavigationController {
      if let browseInfoVC = fourthNavC.visibleViewController {
        if !(browseInfoVC is BrowseInfoVC) {
          XCTFail("Fourth tab's UINavigationController's visibleViewController is not a BrowseInfoVC.")
        }
      }
    } else {
      XCTFail("Fourth tab is not a UINavigationController.")
    }

    mtbvc.selectedIndex = 4
    if mtbvc.selectedViewController == nil {
      XCTFail("Fifth tab's selectedViewController was nil.")
    }
  }
}
