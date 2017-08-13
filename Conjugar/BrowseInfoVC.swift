//
//  BrowseInfoVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class BrowseInfoVC: UIViewController, UITableViewDelegate, UITableViewDataSource, InfoDelegate {
  private var selectedRow = 0
  
  var browseInfoView: BrowseInfoView {
    return view as! BrowseInfoView
  }
  
  override func loadView() {
    let browseInfoView: BrowseInfoView
    browseInfoView = BrowseInfoView(frame: UIScreen.main.bounds)
    browseInfoView.difficultyControl.addTarget(self, action: #selector(BrowseInfoVC.difficultyChanged(_:)), for: .valueChanged)
    browseInfoView.setupTable(dataSource: self, delegate: self)
    navigationItem.titleView = UILabel.titleLabel(title: "Info")
    view = browseInfoView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateDifficultyControl()
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
    let difficulty = SettingsManager.getInfoDifficulty()
    if difficulty == .easy {
      return Info.infos.filter {
        $0.difficulty == .easy
      }.count
    }
    else if difficulty == .moderate {
      return Info.infos.filter {
        $0.difficulty == .easy || $0.difficulty == .moderate
      }.count
    }
    else {
      return Info.infos.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: InfoCell.identifier) as! InfoCell
    let infos: [Info]
    let difficulty = SettingsManager.getInfoDifficulty()
    if difficulty == .easy {
      infos = Info.infos.filter {
        $0.difficulty == .easy
      }
    }
    else if difficulty == .moderate {
      infos = Info.infos.filter {
        $0.difficulty == .easy || $0.difficulty == .moderate
      }
    }
    else {
      infos = Info.infos
    }
    guard let decodedString = infos[indexPath.row].heading.removingPercentEncoding else { fatalError("Could not decode string.") }
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
      if Info.infos[i].heading.lowercased() == newHeading.lowercased() {
        selectedRow = i
        break
      }
    }
    showInfo()
  }
  
  private func showInfo() {
    let infoVC = InfoVC()
    infoVC.infoString = Info.infos[selectedRow].infoString
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
