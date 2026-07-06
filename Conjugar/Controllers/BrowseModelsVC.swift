//
//  BrowseModelsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import UIKit

class BrowseModelsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  static let englishTitle = "Models"

  private var modelsBySort: [ModelSort: [ModelInfo]] = [:]

  private var currentSort: ModelSort {
    let index = browseModelsView.sortControl.selectedSegmentIndex
    guard index >= 0 && index < ModelSort.allCases.count else {
      fatalError("Invalid model-sort index.")
    }
    return ModelSort.allCases[index]
  }

  private var currentModels: [ModelInfo] {
    modelsBySort[currentSort] ?? []
  }

  var browseModelsView: BrowseModelsUIV {
    if let castedView = view as? BrowseModelsUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: BrowseModelsUIV.self))
    }
  }

  override func loadView() {
    let browseModelsView = BrowseModelsUIV(frame: UIScreen.main.bounds)
    browseModelsView.setupTable(dataSource: self, delegate: self)
    browseModelsView.sortControl.addTarget(self, action: #selector(BrowseModelsVC.valueChanged(_:)), for: .valueChanged)
    let models = ModelInfo.all
    modelsBySort = Dictionary(uniqueKeysWithValues: ModelSort.allCases.map { ($0, $0.sorted(models)) })
    let initialSortIndex = ModelSort.allCases.firstIndex(of: Current.settings.modelSort) ?? 0
    browseModelsView.sortControl.selectedSegmentIndex = initialSortIndex
    navigationItem.titleView = UILabel.titleLabel(title: L.BrowseModels.localizedTitle)
    view = browseModelsView
    Current.reviewPrompter.promptableActionHappened()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    browseModelsView.isHidden = false
    Current.analytics.recordVisitation(viewController: "\(BrowseModelsVC.self)")
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentModels.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: ModelCell.identifier) as? ModelCell else {
      fatalError("Could not dequeue \(ModelCell.self).")
    }
    cell.configure(modelInfo: currentModels[indexPath.row])
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let modelVC = ModelVC(modelInfo: currentModels[indexPath.row])
    browseModelsView.isHidden = true
    navigationController?.pushViewController(modelVC, animated: true)
  }

  @objc func valueChanged(_ sender: UISegmentedControl) {
    Current.settings.modelSort = currentSort
    browseModelsView.reloadTableData()
  }
}
