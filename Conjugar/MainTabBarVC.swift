//
//  MainTabBarVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/15/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class MainTabBarVC: UITabBarController {
  internal static let tabs = ["Browse", "Quiz", "Settings", "Info"]
  
  init() {
    super.init(nibName: nil, bundle:nil)
    let browseVerbsNavC = UINavigationController(rootViewController: BrowseVerbsVC())
    browseVerbsNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[0], image: UIImage(named: MainTabBarVC.tabs[0]), selectedImage: nil)
    let quizNavC = UINavigationController(rootViewController: QuizVC())
    quizNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[1], image: UIImage(named: MainTabBarVC.tabs[1]), selectedImage: nil)
    let settingsNavC = UINavigationController(rootViewController: SettingsVC())
    settingsNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[2], image: UIImage(named: MainTabBarVC.tabs[2]), selectedImage: nil)
    let browseInfoNavC = UINavigationController(rootViewController: BrowseInfoVC())
    browseInfoNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[3], image: UIImage(named: MainTabBarVC.tabs[3]), selectedImage: nil)
    viewControllers = [browseVerbsNavC, quizNavC, browseInfoNavC, settingsNavC]
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
