//
//  ModelHeaderUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The scrolling header of the model-detail table: the exemplar's participio and
// gerundio, a pronoun-by-tense grid of the exemplar's conjugations with the
// irregular spans in red, and the verbs-using-this-model count. The UIKit
// adaptation of Conjuguer's endings and stem-alterations cards — Conjugar's
// models are feature stacks over stems, not endings tables, so the *marked
// conjugations themselves* show how the model deviates from regular.

import UIKit

class ModelHeaderUIV: UIView {
  @UsesAutoLayout var participio = UILabel()
  @UsesAutoLayout var gerundio = UILabel()
  @UsesAutoLayout var verbsCount = UILabel()

  /// Grid form labels, person-major to match `columns`: `formLabels[person][tense]`.
  private(set) var formLabels: [[UILabel]] = []

  @UsesAutoLayout
  private var gridScroll: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false
    return scrollView
  }()

  @UsesAutoLayout
  private var gridStack: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.alignment = .top
    stackView.spacing = Layout.defaultSpacing
    return stackView
  }()

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  init(tenseLabels: [String], pronouns: [String]) {
    super.init(frame: .zero)

    [participio, gerundio, verbsCount].forEach {
      $0.font = Fonts.label
      $0.textColor = Colors.yellow
      $0.adjustsFontSizeToFitWidth = true
    }

    gridStack.addArrangedSubview(column(header: "", rowTexts: tenseLabels))
    pronouns.forEach { pronoun in
      let labels = (0 ..< tenseLabels.count).map { _ in formLabel() }
      formLabels.append(labels)
      gridStack.addArrangedSubview(column(header: pronoun, rowLabels: labels))
    }

    gridScroll.addSubview(gridStack)
    [participio, gerundio, gridScroll, verbsCount].forEach {
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      participio.topAnchor.constraint(equalTo: topAnchor, constant: Layout.defaultSpacing),
      participio.leadingAnchor.constraint(equalTo: leadingAnchor),
      participio.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

      gerundio.topAnchor.constraint(equalTo: participio.bottomAnchor, constant: Layout.defaultSpacing),
      gerundio.leadingAnchor.constraint(equalTo: leadingAnchor),
      gerundio.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

      gridScroll.topAnchor.constraint(equalTo: gerundio.bottomAnchor, constant: Layout.defaultSpacing),
      gridScroll.leadingAnchor.constraint(equalTo: leadingAnchor),
      gridScroll.trailingAnchor.constraint(equalTo: trailingAnchor),
      gridScroll.heightAnchor.constraint(equalTo: gridStack.heightAnchor),

      gridStack.topAnchor.constraint(equalTo: gridScroll.contentLayoutGuide.topAnchor),
      gridStack.bottomAnchor.constraint(equalTo: gridScroll.contentLayoutGuide.bottomAnchor),
      gridStack.leadingAnchor.constraint(equalTo: gridScroll.contentLayoutGuide.leadingAnchor),
      gridStack.trailingAnchor.constraint(equalTo: gridScroll.contentLayoutGuide.trailingAnchor),

      verbsCount.topAnchor.constraint(equalTo: gridScroll.bottomAnchor, constant: Layout.defaultSpacing),
      verbsCount.leadingAnchor.constraint(equalTo: leadingAnchor),
      verbsCount.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
      verbsCount.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.0 * Layout.defaultSpacing)
    ])
  }

  /// A grid column: a blue header (pronoun, or empty for the tense-name column)
  /// above one label per tense row. Row heights align across columns because
  /// every label shares the same font.
  private func column(header: String, rowTexts: [String] = [], rowLabels: [UILabel] = []) -> UIStackView {
    let headerLabel = UILabel()
    headerLabel.text = header.isEmpty ? " " : header
    headerLabel.font = Fonts.smallCell
    headerLabel.textColor = Colors.blue

    let rows = rowLabels.isEmpty ? rowTexts.map { text -> UILabel in
      let label = UILabel()
      label.text = text
      label.font = Fonts.smallCell
      label.textColor = Colors.blue
      return label
    } : rowLabels

    let stackView = UIStackView(arrangedSubviews: [headerLabel] + rows)
    stackView.axis = .vertical
    stackView.alignment = .leading
    stackView.spacing = Layout.defaultSpacing / 2.0
    return stackView
  }

  private func formLabel() -> UILabel {
    let label = UILabel()
    label.font = Fonts.smallCell
    label.textColor = Colors.yellow
    return label
  }
}
