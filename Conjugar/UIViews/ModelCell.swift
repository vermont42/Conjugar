//
//  ModelCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import UIKit

class ModelCell: UITableViewCell {
  static let identifier = "ModelCell"

  @UsesAutoLayout
  var exemplar: UILabel = {
    let label = UILabel()
    label.textColor = Colors.yellow
    label.font = Fonts.largeCell
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  @UsesAutoLayout
  var classNumber: UILabel = {
    let label = UILabel()
    label.textColor = Colors.blue
    label.font = Fonts.smallCell
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  @UsesAutoLayout
  var percent: UILabel = {
    let label = UILabel()
    label.textColor = Colors.blue
    label.font = Fonts.smallCell
    label.textAlignment = .right
    label.isAccessibilityElement = false
    return label
  }()

  required init?(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = Colors.black
    [exemplar, classNumber, percent].forEach {
      addSubview($0)
    }
    percent.setContentHuggingPriority(.required, for: .horizontal)
    percent.setContentCompressionResistancePriority(.required, for: .horizontal)

    NSLayoutConstraint.activate([
      exemplar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.defaultSpacing),
      exemplar.topAnchor.constraint(equalTo: topAnchor, constant: Layout.defaultSpacing),
      exemplar.trailingAnchor.constraint(lessThanOrEqualTo: percent.leadingAnchor, constant: Layout.defaultSpacing * -1.0),
      classNumber.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.defaultSpacing),
      classNumber.topAnchor.constraint(equalTo: exemplar.bottomAnchor),
      classNumber.trailingAnchor.constraint(lessThanOrEqualTo: percent.leadingAnchor, constant: Layout.defaultSpacing * -1.0),
      classNumber.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Layout.defaultSpacing * -1.0),
      percent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Layout.defaultSpacing * -1.0),
      percent.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
  }

  func configure(modelInfo: ModelInfo) {
    exemplar.text = modelInfo.exemplar
    exemplar.setAccessibilityLabelInSpanish(modelInfo.exemplar)
    classNumber.text = modelInfo.classNumber
    percent.text = "\(modelInfo.irregularityPercent)%"
  }
}
