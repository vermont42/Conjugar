//
//  BrowseVerbsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class BrowseVerbsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  private var allVerbs: [String] = []
  private var regularVerbs: [String] = []
  private var irregularVerbs: [String] = []
  private var settings: Settings?
  private var analyticsService: AnalyticsService?
  private var reviewPrompter: ReviewPromptable?

  private var currentVerbs: [String] {
    switch browseVerbsView.filterControl.selectedSegmentIndex {
    case 0:
      return irregularVerbs
    case 1:
      return regularVerbs
    case 2:
      return allVerbs
    default:
      fatalError("Invalid verb-filter index.")
    }
  }

  var browseVerbsView: BrowseVerbsView {
    if let castedView = view as? BrowseVerbsView {
      return castedView
    } else {
      fatalError(fatalCastMessage(viewController: BrowseVerbsVC.self, view: BrowseVerbsView.self))
    }
  }

  convenience init(settings: Settings, analyticsService: AnalyticsService, reviewPrompter: ReviewPromptable) {
    self.init()
    self.settings = settings
    self.analyticsService = analyticsService
    self.reviewPrompter = reviewPrompter
  }

  override func loadView() {
    let browseVerbsView = BrowseVerbsView(frame: UIScreen.main.bounds)
    browseVerbsView.setupTable(dataSource: self, delegate: self)
    browseVerbsView.filterControl.addTarget(self, action: #selector(BrowseVerbsVC.valueChanged(_:)), for: .valueChanged)
    allVerbs = Conjugator.shared.allVerbsArray()
    regularVerbs = Conjugator.shared.regularVerbsArray()
    irregularVerbs = Conjugator.shared.irregularVerbsArray()
    navigationItem.titleView = UILabel.titleLabel(title: "Browse")
    view = browseVerbsView
    reviewPrompter?.promptableActionHappened()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    browseVerbsView.isHidden = false
    analyticsService?.recordVisitation(viewController: "\(BrowseVerbsVC.self)")
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentVerbs.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: VerbCell.identifier) as? VerbCell else {
      fatalError("Could not dequeue \(VerbCell.self).")
    }
    cell.configure(verb: currentVerbs[indexPath.row])
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let settings = settings else {
      fatalError("settings was nil.")
    }
    guard let analyticsService = analyticsService else {
      fatalError("analyticsService was nil.")
    }
    tableView.deselectRow(at: indexPath, animated: false)
    let verbVC = VerbVC(settings: settings, analyticsService: analyticsService)
    verbVC.verb = currentVerbs[indexPath.row]
    browseVerbsView.isHidden = true
    navigationController?.pushViewController(verbVC, animated: true)
  }

  @objc func valueChanged(_ sender: UISegmentedControl) {
    browseVerbsView.reloadTableData()
  }
}
