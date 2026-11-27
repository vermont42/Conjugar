//
//  CollectionProgress.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// How many of a collection's verbs the learner has looked up, counted once for the row, the card,
/// or the bar that shows it.
struct CollectionProgress: Equatable {
  let opened: Int
  let total: Int

  init(opened: Int, total: Int) {
    self.opened = opened
    self.total = total
  }

  init(verbs: [VerbMapEntry]) {
    self.init(opened: Current.learnerVerbs.openedCount(of: verbs), total: verbs.count)
  }

  /// "2/11", the count on a collection's row and card.
  var fraction: String {
    "\(opened)/\(total)"
  }

  /// "2 of 11 looked up", the bar's text and what VoiceOver reads for the fraction.
  var description: String {
    L.VerbCollection.progress(opened: opened, total: total)
  }

  /// The bar's value, out of `barTotal`, which is never zero, so that an empty collection draws an
  /// empty bar.
  var barValue: Double {
    Double(opened)
  }

  var barTotal: Double {
    Double(max(total, 1))
  }
}
