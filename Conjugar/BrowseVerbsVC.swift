//
//  BrowseVerbsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class BrowseVerbsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  static let englishTitle = "Browse"

  private var allVerbs: [String] = []
  private var regularVerbs: [String] = []
  private var irregularVerbs: [String] = []

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

  var browseVerbsView: BrowseVerbsUIV {
    if let castedView = view as? BrowseVerbsUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: BrowseVerbsUIV.self))
    }
  }

  override func loadView() {
    let browseVerbsView = BrowseVerbsUIV(frame: UIScreen.main.bounds)
    browseVerbsView.setupTable(dataSource: self, delegate: self)
    browseVerbsView.filterControl.addTarget(self, action: #selector(BrowseVerbsVC.valueChanged(_:)), for: .valueChanged)
    allVerbs = Conjugator.shared.allVerbs
    regularVerbs = Conjugator.shared.regularVerbs
    irregularVerbs = Conjugator.shared.irregularVerbs
    navigationItem.titleView = UILabel.titleLabel(title: Localizations.BrowseVerbs.localizedTitle)
    view = browseVerbsView
    Current.reviewPrompter.promptableActionHappened()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    browseVerbsView.isHidden = false
    Current.analytics.recordVisitation(viewController: "\(BrowseVerbsVC.self)")
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
    tableView.deselectRow(at: indexPath, animated: false)
    let verbVC = VerbVC(verb: currentVerbs[indexPath.row])
    browseVerbsView.isHidden = true
    navigationController?.pushViewController(verbVC, animated: true)
  }

  @objc func valueChanged(_ sender: UISegmentedControl) {
    browseVerbsView.reloadTableData()
  }
}
