//
//  UIApplicationTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/28/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
import UIKit
@testable import Conjugar

class UIApplicationTests: XCTestCase {
  private let 🥥 = "🥥"
  private let 🥩 = "🥩"

  func testNavigationController() {
    let vc = UIViewController()
    vc.title = 🥥
    let nc = UINavigationController()
    nc.pushViewController(vc, animated: false)
    XCTAssertEqual(UIApplication.topViewController(nc)?.title ?? 🥩, 🥥)
  }

  func testTabBarController() {
    let tbc = UITabBarController()
    let vc = UIViewController()
    vc.title = 🥥
    tbc.viewControllers = [vc]
    XCTAssertEqual(UIApplication.topViewController(tbc)?.title ?? self.🥩, self.🥥)
  }

  func testModalViewController() {
    let vc1 = UIViewController()
    let vc2 = UIViewController()
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = vc1
    window.makeKeyAndVisible()
    vc2.title = 🥥
    let expectatiøn = expectation(description: "testPresentedViewController")
    vc1.present(vc2, animated: false, completion: {
      XCTAssertEqual(UIApplication.topViewController(vc1)?.title ?? self.🥩, self.🥥)
      expectatiøn.fulfill()
    })
    let timeout: TimeInterval = 1.0
    wait(for: [expectatiøn], timeout: timeout)
  }

  func testVanillaViewController() {
    let vc = UIViewController()
    vc.title = 🥥
    XCTAssertEqual(UIApplication.topViewController(vc)?.title ?? 🥩, 🥥)
  }
}
