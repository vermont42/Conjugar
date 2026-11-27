//
//  VerbEntryList.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A list of verbs that opens one on a tap, as `AdaptiveRows`. A model's page, a collection's page,
/// and a related verb's full list use it.
struct VerbEntryList: View {
  let entries: [VerbMapEntry]
  /// Checks each verb the learner has looked up, as a collection's rows do.
  var showsLookedUp = false
  let onSelect: (String) -> Void

  var body: some View {
    AdaptiveRows(entries, id: \.infinitive) { entry in
      onSelect(entry.infinitive)
    } label: { entry in
      VerbRowLabel(entry: entry, isLookedUp: showsLookedUp && Current.learnerVerbs.hasOpened(entry.infinitive))
    }
  }
}
