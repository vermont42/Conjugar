//
//  SettingsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/24/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController {
  private var settings: Settings?
  private var analyticsService: AnalyticsServiceable?
  private var gameCenter: GameCenterable?
  private var session: URLSession?

  var settingsView: SettingsView {
    if let castedView = view as? SettingsView {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: SettingsView.self))
    }
  }

  convenience init(settings: Settings, analyticsService: AnalyticsServiceable, gameCenter: GameCenterable, session: URLSession) {
    self.init()
    self.settings = settings
    self.analyticsService = analyticsService
    self.gameCenter = gameCenter
    self.session = session
  }

  override func loadView() {
    let settingsView: SettingsView
    settingsView = SettingsView(frame: UIScreen.main.bounds)
    settingsView.regionControl.addTarget(self, action: #selector(SettingsVC.regionChanged(_:)), for: .valueChanged)
    settingsView.difficultyControl.addTarget(self, action: #selector(SettingsVC.difficultyChanged(_:)), for: .valueChanged)
    settingsView.browseVosControl.addTarget(self, action: #selector(SettingsVC.browseVosChanged(_:)), for: .valueChanged)
    settingsView.quizVosControl.addTarget(self, action: #selector(SettingsVC.quizVosChanged(_:)), for: .valueChanged)
    settingsView.gameCenterButton.addTarget(self, action: #selector(authenticate), for: .touchUpInside)
    settingsView.rateReviewButton.addTarget(self, action: #selector(rateReview), for: .touchUpInside)

    guard let session = session else {
      return
    }
    RatingsFetcher.fetchRatingsDescription(session: session) { description in
      if description != RatingsFetcher.errorMessage {
        DispatchQueue.main.async {
          settingsView.showRatingsUI(description: description)
        }
      }
    }

    navigationItem.titleView = UILabel.titleLabel(title: "Settings")
    view = settingsView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    updateControls()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard let gameCenter = gameCenter else {
      fatalError("gameCenter was nil.")
    }
    [settingsView.gameCenterLabel, settingsView.gameCenterDescription, settingsView.gameCenterButton].forEach {
      $0.isHidden = gameCenter.isAuthenticated
    }
    analyticsService?.recordVisitation(viewController: "\(SettingsVC.self)")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !settingsView.gameCenterButton.isHidden {
      settingsView.gameCenterButton.pulsate()
    }
  }

  private func updateControls() {
    guard let settings = settings else {
      fatalError("settings was nil.")
    }
    switch settings.region {
    case .spain:
      settingsView.regionControl.selectedSegmentIndex = 0
    case .latinAmerica:
      settingsView.regionControl.selectedSegmentIndex = 1
    }

    switch settings.difficulty {
    case .easy:
      settingsView.difficultyControl.selectedSegmentIndex = 0
    case .moderate:
      settingsView.difficultyControl.selectedSegmentIndex = 1
    case .difficult:
      settingsView.difficultyControl.selectedSegmentIndex = 2
    }

    switch settings.secondSingularBrowse {
    case .tu:
      settingsView.browseVosControl.selectedSegmentIndex = 0
    case .vos:
      settingsView.browseVosControl.selectedSegmentIndex = 1
    case .both:
      settingsView.browseVosControl.selectedSegmentIndex = 2
    }

    switch settings.secondSingularQuiz {
    case .tu:
      settingsView.quizVosControl.selectedSegmentIndex = 0
    case .vos:
      settingsView.quizVosControl.selectedSegmentIndex = 1
    }
  }

  @objc func regionChanged(_ sender: UISegmentedControl) {
    guard let settings = settings else {
      fatalError("settings was nil.")
    }
    let index = settingsView.regionControl.selectedSegmentIndex
    if index == 0 {
      settings.region = .spain
    } else /* index == 1 */ {
      settings.region = .latinAmerica
    }
  }

  @objc func difficultyChanged(_ sender: UISegmentedControl) {
    let index = settingsView.difficultyControl.selectedSegmentIndex
    if index == 0 {
      settings?.difficulty = .easy
    } else if index == 1 {
      settings?.difficulty = .moderate
    } else /* index == 2 */ {
      settings?.difficulty = .difficult
    }
  }

  @objc func quizVosChanged(_ sender: UISegmentedControl) {
    guard let settings = settings else {
      fatalError("settings was nil.")
    }
    let index = settingsView.quizVosControl.selectedSegmentIndex
    if index == 0 {
      settings.secondSingularQuiz = .tu
    } else if index == 1 {
      settings.secondSingularQuiz = .vos
    }
  }

  @objc func browseVosChanged(_ sender: UISegmentedControl) {
    guard let settings = settings else {
      fatalError("settings was nil.")
    }
    let index = settingsView.browseVosControl.selectedSegmentIndex
    if index == 0 {
      settings.secondSingularBrowse = .tu
    } else if index == 1 {
      settings.secondSingularBrowse = .vos
    } else if index == 2 {
      settings.secondSingularBrowse = .both
    }
  }

  @objc func authenticate() {
    guard let settings = settings else {
      fatalError("settings was nil.")
    }
    guard let gameCenter = gameCenter else {
      fatalError("gameCenter was nil.")
    }
    settings.userRejectedGameCenter = false
    gameCenter.authenticate(analyticsService: analyticsService) { authenticated in
      DispatchQueue.main.async {
        [self.settingsView.gameCenterLabel, self.settingsView.gameCenterDescription, self.settingsView.gameCenterButton].forEach {
          $0.isHidden = authenticated
        }
      }
    }
  }

  @objc func rateReview(completion: @escaping ((Bool) -> ()) = { _ in }) {
    guard let url = URL(string: "https://itunes.apple.com/us/app/immigration/id\(RatingsFetcher.iTunesID)?action=write-review") else {
      return
    }
    UIApplication.shared.open(url, options: [:], completionHandler: { didSucceed in
      completion(didSucceed)
    })
  }
}
