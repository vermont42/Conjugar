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
    if #available(iOS 11.0, *) {
      browseInfoView = BrowseInfoView(frame: UIScreen.main.bounds)
    }
    else {
      browseInfoView = BrowseInfoView(frame: UIScreen.main.bounds, safeBottomInset: 49)
    }
    browseInfoView.setupTable(dataSource: self, delegate: self)
    view = browseInfoView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.titleView = UILabel.titleLabel(title: "Info")
    browseInfoView.reloadTableData()
  }
    
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Info.infos.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: InfoCell.identifier) as! InfoCell
    guard let decodedString = Info.infos[indexPath.row].heading.removingPercentEncoding else { fatalError("Could not decode string.") }
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
}
