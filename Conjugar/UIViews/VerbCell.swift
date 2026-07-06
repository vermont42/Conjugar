//
//  VerbCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class VerbCell: UITableViewCell {
  static let identifier = "VerbCell"

  @UsesAutoLayout
  var verb: UILabel = {
    let label = UILabel()
    label.textColor = Colors.yellow
    label.font = Fonts.largeCell
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  @UsesAutoLayout
  var gloss: UILabel = {
    let label = UILabel()
    label.textColor = Colors.blue
    label.font = Fonts.smallCell
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  @UsesAutoLayout
  var rank: UILabel = {
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
    [verb, gloss, rank].forEach {
      addSubview($0)
    }
    rank.setContentHuggingPriority(.required, for: .horizontal)
    rank.setContentCompressionResistancePriority(.required, for: .horizontal)

    NSLayoutConstraint.activate([
      verb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.defaultSpacing),
      verb.topAnchor.constraint(equalTo: topAnchor, constant: Layout.defaultSpacing),
      verb.trailingAnchor.constraint(lessThanOrEqualTo: rank.leadingAnchor, constant: Layout.defaultSpacing * -1.0),
      gloss.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.defaultSpacing),
      gloss.topAnchor.constraint(equalTo: verb.bottomAnchor),
      gloss.trailingAnchor.constraint(lessThanOrEqualTo: rank.leadingAnchor, constant: Layout.defaultSpacing * -1.0),
      gloss.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Layout.defaultSpacing * -1.0),
      rank.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Layout.defaultSpacing * -1.0),
      rank.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
  }

  func configure(entry: VerbMapEntry) {
    verb.text = entry.infinitive
    verb.setAccessibilityLabelInSpanish(entry.infinitive)
    gloss.text = entry.gloss
    if let frequencyRank = entry.frequencyRank {
      rank.text = "#\(frequencyRank)"
    } else {
      rank.text = nil
    }
  }
}
