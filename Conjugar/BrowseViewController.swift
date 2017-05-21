//
//  BrowseViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

// TODO: Add sentar, perder, pedir, crecer, lucir, conducir, huir, construir (like huir?), caer, oír, traer, jugar, adquirir, argüir, discernir, adquirir.
// When looking up an infinitive, accept, for example, "oir" for "oír" or "arguir" for argüir". Might need to add "accentless" forms for verbs. Could do this programatically.
// Oír breaks the rule that all verbs end in ir, er, or ar. One solution would be strip accents from infinitives passed in.
// Definitely handle oír.
// https://www.thoughtco.com/defective-verbs-spanish-3079156
// In the section Prefixes Count, the following webpage has examples of prefixed irregulars conjugated like their parents. http://www.spanishdict.com/guide/spanish-irregular-present-tense Test.
// More: http://studyspanish.com/grammar/lessons/future

class BrowseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  private var verbs: [String] = []
  private var selectedRow = 0
  @IBOutlet var table: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    verbs = Conjugator.sharedInstance.verbArray()
    table.delegate = self
    table.dataSource = self
    table.reloadData()
    Utterer.utter("")
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return verbs.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = table.dequeueReusableCell(withIdentifier: "VerbCell") as! VerbCell
    cell.configure(verb: verbs[indexPath.row])
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectedRow = (indexPath as NSIndexPath).row
    tableView.deselectRow(at: indexPath, animated: false)
    performSegue(withIdentifier: "show verb", sender: self)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "show verb" {
      let verbVC: VerbViewController = segue.destination as! VerbViewController
      verbVC.verb = verbs[selectedRow]
    }
  }
}

