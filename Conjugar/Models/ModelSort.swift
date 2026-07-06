//
//  ModelSort.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

enum ModelSort: String, CaseIterable {
  case irregularity
  case alphabetical
  case classNumber

  var localizedDisplayName: String {
    switch self {
    case .irregularity:
      return Localizations.ModelSort.irregularity
    case .alphabetical:
      return Localizations.VerbSort.alphabetical
    case .classNumber:
      return Localizations.ModelSort.classNumber
    }
  }

  func areInIncreasingOrder(_ lhs: ModelInfo, _ rhs: ModelInfo) -> Bool {
    switch self {
    case .irregularity:
      if lhs.irregularityPercent != rhs.irregularityPercent {
        return lhs.irregularityPercent > rhs.irregularityPercent
      }
      return ModelSort.alphabetical.areInIncreasingOrder(lhs, rhs)
    case .alphabetical:
      return lhs.exemplar.compare(rhs.exemplar, locale: VerbSort.spanish) == .orderedAscending
    case .classNumber:
      return ModelSort.classNumberPrecedes(lhs.classNumber, rhs.classNumber)
    }
  }

  func sorted(_ infos: some Sequence<ModelInfo>) -> [ModelInfo] {
    infos.sorted(by: areInIncreasingOrder)
  }

  /// Book order for class numbers, which is not string order ("2" < "10",
  /// "4A-2" < "4B", "6B-4" < "6C"): compare the leading integer, then the
  /// letter suffix, then the sub-number ("4B" itself precedes "4B-1").
  static func classNumberPrecedes(_ lhs: String, _ rhs: String) -> Bool {
    let lhsComponents = components(of: lhs)
    let rhsComponents = components(of: rhs)
    if lhsComponents.number != rhsComponents.number {
      return lhsComponents.number < rhsComponents.number
    }
    if lhsComponents.letter != rhsComponents.letter {
      return lhsComponents.letter < rhsComponents.letter
    }
    return lhsComponents.sub < rhsComponents.sub
  }

  private static func components(of classNumber: String) -> (number: Int, letter: String, sub: Int) {
    let parts = classNumber.split(separator: "-", maxSplits: 1)
    let head = parts.first ?? ""
    let digits = head.prefix(while: \.isNumber)
    let number = Int(digits) ?? 0
    let letter = String(head.dropFirst(digits.count))
    let sub = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
    return (number, letter, sub)
  }
}
