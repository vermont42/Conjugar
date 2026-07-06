//
//  ModelVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import UIKit

class ModelVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  private let modelInfo: ModelInfo
  private let entries: [VerbMapEntry]

  var modelView: ModelUIV {
    if let castedView = view as? ModelUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: ModelUIV.self))
    }
  }

  init(modelInfo: ModelInfo) {
    self.modelInfo = modelInfo
    entries = modelInfo.verbs.compactMap { VerbMap.shared.entry(for: $0) }
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override func loadView() {
    let modelView = ModelUIV(frame: UIScreen.main.bounds)
    modelView.setupTable(dataSource: self, delegate: self)
    initNavigationItemTitleView()
    modelView.details.text = String(format: Localizations.Model.numberAndPercent, modelInfo.classNumber, modelInfo.irregularityPercent)
    modelView.gloss.text = VerbMap.shared.entry(for: modelInfo.exemplar)?.gloss ?? ""
    modelView.verbsCount.text = String(format: Localizations.Model.verbsUsing, modelInfo.verbs.count)
    view = modelView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    modelView.isHidden = false
    Current.analytics.recordVisitation(viewController: "\(ModelVC.self)")
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return entries.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: VerbCell.identifier) as? VerbCell else {
      fatalError("Could not dequeue \(VerbCell.self).")
    }
    cell.configure(entry: entries[indexPath.row])
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let verbVC = VerbVC(verb: entries[indexPath.row].infinitive)
    modelView.isHidden = true
    navigationController?.pushViewController(verbVC, animated: true)
  }

  private func initNavigationItemTitleView() {
    let titleLabel = UILabel.titleLabel(title: modelInfo.exemplar.capitalized)
    navigationItem.titleView = titleLabel
    titleLabel.isUserInteractionEnabled = true
    titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapSpanish(_:))))
  }

  @objc func tapSpanish(_ sender: UITapGestureRecognizer) {
    if let label = sender.view as? UILabel {
      Utterer.utter(label.attributedText?.string ?? label.text ?? "")
    }
  }
}
