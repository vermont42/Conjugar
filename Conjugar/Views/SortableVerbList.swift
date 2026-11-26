//
//  SortableVerbList.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A page's verbs under a sort picker: a model's verbs, a collection's, or every verb built on one
/// root. It owns its order, which starts at `initialSort` each time the page opens and is not
/// saved. A tapped verb opens through `verbPagePush`.
///
/// Its body is several views, not one stack, so that they take the spacing of the page's stack.
struct SortableVerbList: View {
  /// The verbs in each order, sorted once by the page that shows them, as `VerbSort.sortedLists`.
  let lists: [VerbSort: [VerbMapEntry]]
  /// The source that a verb opened from the list reports.
  let source: AnalyticsSource
  /// Checks each verb the learner has looked up, as a collection's rows do.
  var showsLookedUp = false
  /// The line between the picker and the list, given the number of verbs, or nil for none.
  var heading: ((Int) -> String)?
  @State private var sort: VerbSort
  @Environment(\.verbPagePush) private var push

  init(
    lists: [VerbSort: [VerbMapEntry]],
    initialSort: VerbSort,
    source: AnalyticsSource,
    showsLookedUp: Bool = false,
    heading: ((Int) -> String)? = nil
  ) {
    self.lists = lists
    self.source = source
    self.showsLookedUp = showsLookedUp
    self.heading = heading
    _sort = State(initialValue: initialSort)
  }

  var body: some View {
    let entries = lists[sort] ?? []

    SortPicker(selection: $sort)

    if let heading {
      ListHeading(heading(entries.count))
    }

    VerbEntryList(entries: entries, showsLookedUp: showsLookedUp) { verb in
      push?(VerbDestination(infinitive: verb, source: source))
    }
  }
}
