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
  convenience init() {
    self.init(nibName: nil, bundle: nil)

    let browseVerbsNavC = UINavigationController(rootViewController: BrowseVerbsVC())
    browseVerbsNavC.tabBarItem = UITabBarItem(
      title: Localizations.BrowseVerbs.localizedTitle,
      image: UIImage(named: Localizations.BrowseVerbs.englishTitle),
      selectedImage: nil
    )

    let quizNavC = UINavigationController(rootViewController: QuizVC())
    quizNavC.tabBarItem = UITabBarItem(
      title: Localizations.Quiz.localizedTitle,
      image: UIImage(named: Localizations.Quiz.englishTitle),
      selectedImage: nil
    )

    let settingsVC = UIHostingController(rootView: SettingsView().environmentObject(Current))
    Current.parentViewController = settingsVC
    settingsVC.tabBarItem = UITabBarItem(
      title: Localizations.Settings.localizedTitle,
      image: UIImage(named: Localizations.Settings.englishTitle),
      selectedImage: nil
    )

    let browseInfoNavC = UINavigationController(rootViewController: BrowseInfoVC())
    browseInfoNavC.tabBarItem = UITabBarItem(
      title: Localizations.BrowseInfo.localizedTitle,
      image: UIImage(named: Localizations.BrowseInfo.englishTitle),
      selectedImage: nil
    )

    viewControllers = [browseVerbsNavC, quizNavC, browseInfoNavC, settingsVC]
  }
}
