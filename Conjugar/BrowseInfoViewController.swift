//
//  BrowseInfoViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class BrowseInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, InfoDelegate {
  @IBOutlet var table: UITableView!
  private var selectedRow = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.titleTextAttributes = [
      NSAttributedStringKey.foregroundColor.rawValue : UIColor.white,
    ]
    table.delegate = self
    table.dataSource = self
    table.reloadData()
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Info.infos.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = table.dequeueReusableCell(withIdentifier: "InfoCell") as! InfoCell
    cell.configure(info: Info.infoTitles[indexPath.row])
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectedRow = (indexPath as NSIndexPath).row
    tableView.deselectRow(at: indexPath, animated: false)
    performSegue(withIdentifier: "show info", sender: self)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "show info" {
      guard let infoVC: InfoViewController = segue.destination as? InfoViewController else { return }
      infoVC.infoIndex = selectedRow
      infoVC.infoDelegate = self
    }
  }
  
  func infoSelectionDidChange(newIndex: Int) {
    selectedRow = newIndex
    performSegue(withIdentifier: "show info", sender: self)
  }
}
