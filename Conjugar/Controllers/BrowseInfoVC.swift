//
//  BrowseInfoVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class BrowseInfoVC: UIViewController, UITableViewDelegate, UITableViewDataSource, InfoDelegate {
  static let englishTitle = "Info"

  private var selectedRow = 0
  private var allInfos: [Info] = []
  private var easyModerateInfos: [Info] = []
  private var easyInfos: [Info] = []

  private var currentInfos: [Info] {
    switch browseInfoView.difficultyControl.selectedSegmentIndex {
    case 0:
      return easyInfos
    case 1:
      return easyModerateInfos
    case 2:
      return allInfos
    default:
      fatalError("Invalid UISegmentedControl index.")
    }
  }

  var browseInfoView: BrowseInfoUIV {
    if let castedView = view as? BrowseInfoUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: BrowseInfoUIV.self))
    }
  }

  override func loadView() {
    let browseInfoView: BrowseInfoUIV
    browseInfoView = BrowseInfoUIV(frame: UIScreen.main.bounds)
    browseInfoView.difficultyControl.addTarget(self, action: #selector(BrowseInfoVC.difficultyChanged(_:)), for: .valueChanged)
    browseInfoView.setupTable(dataSource: self, delegate: self)
    navigationItem.titleView = UILabel.titleLabel(title: Localizations.BrowseInfo.localizedTitle)
    easyInfos = Info.infos.filter {
      $0.difficulty == .easy
    }
    easyModerateInfos = Info.infos.filter {
      $0.difficulty == .easy || $0.difficulty == .moderate
    }
    allInfos = Info.infos
    view = browseInfoView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    updateDifficultyControl()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    Current.analytics.recordVisitation(viewController: "\(BrowseInfoVC.self)")
  }

  private func updateDifficultyControl() {
    switch Current.settings.infoDifficulty {
    case .easy:
      browseInfoView.difficultyControl.selectedSegmentIndex = 0
    case .moderate:
      browseInfoView.difficultyControl.selectedSegmentIndex = 1
    case .difficult:
      browseInfoView.difficultyControl.selectedSegmentIndex = 2
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentInfos.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: InfoCell.identifier) as? InfoCell else {
      fatalError("Could not dequeue \(InfoCell.self).")
    }
    guard let decodedString = currentInfos[indexPath.row].heading.removingPercentEncoding else {
      fatalError("Could not decode string.")
    }
    cell.configure(heading: decodedString)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectedRow = (indexPath as NSIndexPath).row
    tableView.deselectRow(at: indexPath, animated: false)
    showInfo()
  }

  func infoSelectionDidChange(newHeading: String) {
    for i in 0 ..< Info.infos.count {
      if currentInfos[i].heading.lowercased() == newHeading.lowercased() {
        selectedRow = i
        break
      }
    }
    showInfo()
  }

  private func showInfo() {
    let infoVC = InfoVC(infoString: currentInfos[selectedRow].infoString, infoDelegate: self)
    navigationController?.pushViewController(infoVC, animated: true)
  }

  @objc func difficultyChanged(_ sender: UISegmentedControl) {
    let index = browseInfoView.difficultyControl.selectedSegmentIndex
    if index == 0 {
      Current.settings.infoDifficulty = .easy
    } else if index == 1 {
      Current.settings.infoDifficulty = .moderate
    } else /* index == 2 */ {
      Current.settings.infoDifficulty = .difficult
    }
    browseInfoView.table.reloadData()
  }
}
