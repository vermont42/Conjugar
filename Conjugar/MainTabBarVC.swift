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
    let browseVerbsNavVC = UINavigationController(rootViewController: BrowseVerbsVC())
    browseVerbsNavVC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[0], image: UIImage(named: MainTabBarVC.tabs[0]), selectedImage: nil)
    let quizNavVC = UINavigationController(rootViewController: QuizVC())
    quizNavVC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[1], image: UIImage(named: MainTabBarVC.tabs[1]), selectedImage: nil)
    let settingsVC = SettingsVC()
    settingsVC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[2], image: UIImage(named: MainTabBarVC.tabs[2]), selectedImage: nil)
    let browseInfoNavVC = UINavigationController(rootViewController: BrowseInfoVC())
    browseInfoNavVC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[3], image: UIImage(named: MainTabBarVC.tabs[3]), selectedImage: nil)
    viewControllers = [browseVerbsNavVC, browseInfoNavVC /* quizNavVC, settingsVC */]
    // TODO: Make BrowseVerbsVC and VerbVC like NOIB VCs.
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
