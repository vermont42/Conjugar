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
      title: L.BrowseVerbs.localizedTitle,
      image: UIImage(named: BrowseVerbsVC.englishTitle),
      selectedImage: nil
    )

    let browseModelsNavC = UINavigationController(rootViewController: BrowseModelsVC())
    browseModelsNavC.tabBarItem = UITabBarItem(
      title: L.BrowseModels.localizedTitle,
      image: UIImage(systemName: "key.fill"),
      selectedImage: nil
    )

    let quizNavC = UINavigationController(rootViewController: QuizVC())
    quizNavC.tabBarItem = UITabBarItem(
      title: L.Quiz.localizedTitle,
      image: UIImage(named: QuizVC.englishTitle),
      selectedImage: nil
    )

    let settingsVC = UIHostingController(rootView: SettingsView())
    Current.parentViewController = settingsVC
    settingsVC.tabBarItem = UITabBarItem(
      title: L.Settings.localizedTitle,
      image: UIImage(named: SettingsView.englishTitle),
      selectedImage: nil
    )

    let browseInfoNavC = UINavigationController(rootViewController: BrowseInfoVC())
    browseInfoNavC.tabBarItem = UITabBarItem(
      title: L.BrowseInfo.localizedTitle,
      image: UIImage(named: BrowseInfoVC.englishTitle),
      selectedImage: nil
    )

    viewControllers = [browseVerbsNavC, browseModelsNavC, quizNavC, browseInfoNavC, settingsVC]
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    Task {
      guard let commun = await Current.communGetter.getCommunication() else { return }
      let lastCommunIdentifierShown = Current.settings.lastCommunIdentifierShown
      if Current.quiz.quizState != .inProgress && commun.identifier > lastCommunIdentifierShown {
        let communVC = CommunVC(commun: commun)
        communVC.modalPresentationStyle = .fullScreen
        self.present(communVC, animated: true)
        Current.settings.lastCommunIdentifierShown = commun.identifier
      }
    }
  }
}
