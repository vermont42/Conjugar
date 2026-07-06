//
//  ModelVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import UIKit

class ModelVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  /// The grid's tense rows: the Spanish analogs of Conjuguer's five endings-grid
  /// tenses, plus futuro — Spanish concentrates irregularity in the future stem
  /// (tendr-, har-), which Conjuguer surfaced via its stem-alterations card.
  /// Tense names are Spanish grammar terms, invariant across localizations like
  /// the Verb screen's tense headings.
  static let gridTenses: [(label: String, tense: DisplayTense)] = [
    ("Ind. Presente", .presenteDeIndicativo),
    ("Imperativo", .imperativoPositivo),
    ("Pretérito", .pretérito),
    ("Futuro", .futuroDeIndicativo),
    ("Subj. Presente", .presenteDeSubjuntivo),
    ("Subj. Imperfecto", .imperfectoDeSubjuntivo1)
  ]

  /// The grid's person columns, in the book's row order (vos is a Verb-screen
  /// affordance; the grid matches Conjuguer's six pronouns).
  static let gridPersons: [DisplayPersonNumber] = [.firstSingular, .secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]

  private let modelInfo: ModelInfo
  private let entries: [VerbMapEntry]

  var modelView: ModelUIV {
    if let castedView = view as? ModelUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: ModelUIV.self))
    }
  }

  var headerView: ModelHeaderUIV? {
    modelView.table.tableHeaderView as? ModelHeaderUIV
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
    var details = L.Model.numberAndPercent(model: modelInfo.classNumber, percent: modelInfo.irregularityPercent)
    if Conjugator.isDefective(infinitive: modelInfo.exemplar) {
      details += " · " + L.Verb.defective
    }
    modelView.details.text = details
    modelView.gloss.text = VerbMap.shared.entry(for: modelInfo.exemplar)?.gloss ?? ""
    modelView.table.tableHeaderView = makeHeaderView()
    view = modelView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    modelView.isHidden = false
    Current.analytics.recordVisitation(viewController: "\(ModelVC.self)")
  }

  // The table sizes its header from an explicit frame, not constraints, so fit
  // it to the table's width whenever layout changes.
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard let headerView = modelView.table.tableHeaderView else {
      return
    }
    let targetSize = CGSize(width: modelView.table.bounds.width, height: UIView.layoutFittingCompressedSize.height)
    let height = headerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
    if headerView.frame.size.height != height {
      headerView.frame.size = CGSize(width: modelView.table.bounds.width, height: height)
      modelView.table.tableHeaderView = headerView
    }
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

  // MARK: - The conjugation-grid header

  /// The exemplar's conjugations, irregular spans red — how this model deviates
  /// from a regular conjugation, slot by slot. The UIKit adaptation of
  /// Conjuguer's endings and stem-alterations cards.
  private func makeHeaderView() -> ModelHeaderUIV {
    let headerView = ModelHeaderUIV(
      tenseLabels: ModelVC.gridTenses.map { $0.label },
      pronouns: ModelVC.gridPersons.map { $0.pronoun }
    )
    headerView.participio.attributedText = nonFiniteLine(tense: .participio)
    headerView.gerundio.attributedText = nonFiniteLine(tense: .gerundio)
    headerView.verbsCount.text = L.Model.verbsUsing(count: modelInfo.verbs.count)
    for (personIndex, personNumber) in ModelVC.gridPersons.enumerated() {
      for (tenseIndex, gridTense) in ModelVC.gridTenses.enumerated() {
        let label = headerView.formLabels[personIndex][tenseIndex]
        if case let .success(form) = TenseBridge.conjugate(infinitive: modelInfo.exemplar, tense: gridTense.tense, personNumber: personNumber) {
          label.attributedText = form.conjugatedString
          label.setAccessibilityLabelInSpanish(form.lowercased())
        } else {
          // A slot with no form: yo has no imperative, and a defective verb's
          // formless slots surface as errors. Keep the row height with a space.
          label.text = " "
        }
      }
    }
    return headerView
  }

  private func nonFiniteLine(tense: DisplayTense) -> NSAttributedString {
    guard case let .success(form) = TenseBridge.conjugate(infinitive: modelInfo.exemplar, tense: tense, personNumber: .none) else {
      return NSAttributedString(string: tense.titleCaseName + ":")
    }
    return NSAttributedString(string: tense.titleCaseName + ": ") + form.conjugatedString
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
