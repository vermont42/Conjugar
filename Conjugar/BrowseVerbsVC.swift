//
//  BrowseVerbsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

// Don't store present subjunctive forms of any verbs except dar, estar, ser, haber, ir, and saber. Instead, construct them based on yo-present form. Actually, it's complicated because of spelling changes. http://www.spanishdict.com/guide/spanish-present-subjunctive

// TODO: Add sentar, perder, pedir, crecer, lucir, conducir, traducir (like conducir), huir, construir (like huir?), oír, jugar, adquirir, argüir, discernir, adquirir.
// When looking up an infinitive, accept, for example, "oir" for "oír" or "arguir" for argüir". Might need to add "accentless" forms for verbs. Could do this programatically.
// Oír breaks the rule that all verbs end in ir, er, or ar. One solution would be strip accents from infinitives passed in.
// Definitely handle oír.
// https://www.thoughtco.com/defective-verbs-spanish-3079156
// In the section Prefixes Count, the following webpage has examples of prefixed irregulars conjugated like their parents. http://www.spanishdict.com/guide/spanish-irregular-present-tense Test.
// More: http://studyspanish.com/grammar/lessons/future

class BrowseVerbsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
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
      fatalError()
    }
  }
  
  var browseVerbsView: BrowseVerbsView {
    return view as! BrowseVerbsView
  }
  
  override func loadView() {
    let browseVerbsView: BrowseVerbsView
    if #available(iOS 11.0, *) {
      browseVerbsView = BrowseVerbsView(frame: UIScreen.main.bounds)
    }
    else {
      browseVerbsView = BrowseVerbsView(frame: UIScreen.main.bounds, safeBottomInset: 49)
    }
    browseVerbsView.setupTable(dataSource: self, delegate: self)
    browseVerbsView.filterControl.addTarget(self, action: #selector(BrowseVerbsVC.valueChanged(_:)), for: .valueChanged)
    view = browseVerbsView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    allVerbs = Conjugator.sharedInstance.allVerbsArray()
    regularVerbs = Conjugator.sharedInstance.regularVerbsArray()
    irregularVerbs = Conjugator.sharedInstance.irregularVerbsArray()
    browseVerbsView.reloadTableData()
    navigationItem.titleView = UILabel.titleLabel(title: "Browse")
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentVerbs.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: VerbCell.identifier) as! VerbCell
    cell.configure(verb: currentVerbs[indexPath.row])
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let verbVC = VerbVC()
    verbVC.verb = currentVerbs[indexPath.row]
    navigationController?.pushViewController(verbVC, animated: true)
  }
  
  @objc func valueChanged(_ sender: UISegmentedControl) {
    browseVerbsView.reloadTableData()
  }
}

