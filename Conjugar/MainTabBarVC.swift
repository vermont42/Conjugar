//
//  MainTabBarVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/15/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit
import SwiftUI

class MainTabBarVC: UITabBarController {
  static let tabs = ["Browse", "Quiz", "Settings", "Info"]

  convenience init() {
    self.init(nibName: nil, bundle: nil)
    let browseVerbsNavC = UINavigationController(rootViewController: BrowseVerbsVC())
    browseVerbsNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[0], image: UIImage(named: MainTabBarVC.tabs[0]), selectedImage: nil)
    let quizNavC = UINavigationController(rootViewController: QuizVC())
    quizNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[1], image: UIImage(named: MainTabBarVC.tabs[1]), selectedImage: nil)
    let settingsVC = UIHostingController(rootView: SettingsView().environmentObject(Current))
    Current.parentViewController = settingsVC
    settingsVC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[2], image: UIImage(named: MainTabBarVC.tabs[2]), selectedImage: nil)
    let browseInfoNavC = UINavigationController(rootViewController: BrowseInfoVC())
    browseInfoNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[3], image: UIImage(named: MainTabBarVC.tabs[3]), selectedImage: nil)
    viewControllers = [browseVerbsNavC, quizNavC, browseInfoNavC, settingsVC]
  }
}
