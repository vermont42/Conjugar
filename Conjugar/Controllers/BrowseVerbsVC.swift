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

  private var verbsBySort: [VerbSort: [VerbMapEntry2]] = [:]

  private var currentSort: VerbSort {
    let index = browseVerbsView.sortControl.selectedSegmentIndex
    guard index >= 0 && index < VerbSort.allCases.count else {
      fatalError("Invalid verb-sort index.")
    }
    return VerbSort.allCases[index]
  }

  private var currentVerbs: [VerbMapEntry2] {
    verbsBySort[currentSort] ?? []
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
    browseVerbsView.sortControl.addTarget(self, action: #selector(BrowseVerbsVC.valueChanged(_:)), for: .valueChanged)
    let entries = VerbMap2.shared.entries.values
    verbsBySort = Dictionary(uniqueKeysWithValues: VerbSort.allCases.map { ($0, $0.sorted(entries)) })
    let initialSortIndex = VerbSort.allCases.firstIndex(of: Current.settings.verbSort) ?? 0
    browseVerbsView.sortControl.selectedSegmentIndex = initialSortIndex
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
    cell.configure(entry: currentVerbs[indexPath.row])
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let verbVC = VerbVC(verb: currentVerbs[indexPath.row].infinitive)
    browseVerbsView.isHidden = true
    navigationController?.pushViewController(verbVC, animated: true)
  }

  @objc func valueChanged(_ sender: UISegmentedControl) {
    Current.settings.verbSort = currentSort
    browseVerbsView.reloadTableData()
  }
}
