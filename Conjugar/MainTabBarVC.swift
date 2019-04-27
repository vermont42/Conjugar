//
//  MainTabBarVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/15/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class MainTabBarVC: UITabBarController {
  static let tabs = ["Browse", "Quiz", "Settings", "Info"]

  convenience init(settings: Settings, quiz: Quiz, analyticsService: AnalyticsServiceable, reviewPrompter: ReviewPromptable, gameCenter: GameCenterable, session: URLSession) {
    self.init(nibName: nil, bundle: nil)
    let browseVerbsNavC = UINavigationController(rootViewController: BrowseVerbsVC(settings: settings, analyticsService: analyticsService, reviewPrompter: reviewPrompter))
    browseVerbsNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[0], image: UIImage(named: MainTabBarVC.tabs[0]), selectedImage: nil)
    let quizNavC = UINavigationController(rootViewController: QuizVC(settings: settings, quiz: quiz, analyticsService: analyticsService, gameCenter: gameCenter))
    quizNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[1], image: UIImage(named: MainTabBarVC.tabs[1]), selectedImage: nil)
    let settingsNavC = UINavigationController(rootViewController: SettingsVC(settings: settings, analyticsService: analyticsService, gameCenter: gameCenter, session: session))
    settingsNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[2], image: UIImage(named: MainTabBarVC.tabs[2]), selectedImage: nil)
    let browseInfoNavC = UINavigationController(rootViewController: BrowseInfoVC(settings: settings, analyticsService: analyticsService))
    browseInfoNavC.tabBarItem = UITabBarItem(title: MainTabBarVC.tabs[3], image: UIImage(named: MainTabBarVC.tabs[3]), selectedImage: nil)
    viewControllers = [browseVerbsNavC, quizNavC, browseInfoNavC, settingsNavC]
  }
}
