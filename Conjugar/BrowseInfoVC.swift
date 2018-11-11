//
//  BrowseInfoVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class BrowseInfoVC: UIViewController, UITableViewDelegate, UITableViewDataSource, InfoDelegate {
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

  var browseInfoView: BrowseInfoView {
    if let castedView = view as? BrowseInfoView {
      return castedView
    } else {
      fatalError(fatalCastMessage(viewController: BrowseInfoVC.self, view: BrowseInfoView.self))
    }
  }

  override func loadView() {
    let browseInfoView: BrowseInfoView
    browseInfoView = BrowseInfoView(frame: UIScreen.main.bounds)
    browseInfoView.difficultyControl.addTarget(self, action: #selector(BrowseInfoVC.difficultyChanged(_:)), for: .valueChanged)
    browseInfoView.setupTable(dataSource: self, delegate: self)
    navigationItem.titleView = UILabel.titleLabel(title: "Info")
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
    AWSAnalyticsService.shared.recordVisitation(viewController: "\(BrowseInfoVC.self)")
  }
  
  private func updateDifficultyControl() {
    switch SettingsManager.getInfoDifficulty() {
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
    let cell = tableView.dequeueReusableCell(withIdentifier: InfoCell.identifier) as! InfoCell
    guard let decodedString = currentInfos[indexPath.row].heading.removingPercentEncoding else { fatalError("Could not decode string.") }
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
    let infoVC = InfoVC()
    infoVC.infoString = currentInfos[selectedRow].infoString
    infoVC.infoDelegate = self
    navigationController?.pushViewController(infoVC, animated: true)
  }
  
  @objc func difficultyChanged(_ sender: UISegmentedControl) {
    let index = browseInfoView.difficultyControl.selectedSegmentIndex
    if index == 0 {
      SettingsManager.setInfoDifficulty(.easy)
    }
    else if index == 1 {
      SettingsManager.setInfoDifficulty(.moderate)
    }
    else /* index == 2 */ {
      SettingsManager.setInfoDifficulty(.difficult)
    }
    browseInfoView.table.reloadData()
  }
}
