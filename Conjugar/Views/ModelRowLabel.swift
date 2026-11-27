//
//  ModelRowLabel.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A model's row or card in the Models tab: the exemplar, the class number, and a pill with the
/// model's irregularity percent, tinted by `ModelPalette`.
struct ModelRowLabel: View {
  let model: ModelInfo

  var body: some View {
    RowLabel(title: model.exemplar) {
      Text(model.classNumber)
        .font(.subheadline)
        .foregroundStyle(Color.customForeground)
    } trailing: {
      Text(verbatim: "\(model.irregularityPercent)%")
        .metadataPill(tint: ModelPalette.tint(forPercent: model.irregularityPercent))
    }
  }
}

/// Shared tint for an irregularity percentage: green (regular) → yellow → red
/// (highly irregular), so the badge's color scales with the number.
enum ModelPalette {
  static func tint(forPercent percent: Int) -> Color {
    switch percent {
    case ..<1:
      return .customGreen
    case 1..<40:
      return .customYellow
    default:
      return .customRed
    }
  }
}
