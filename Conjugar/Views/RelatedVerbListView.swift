//
//  RelatedVerbListView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// Every verb built on one root, which a verb page's short list leads to.
struct RelatedVerbListDestination: Hashable {
  let root: String
  let verbs: [String]
}

/// Every verb built on one root, by frequency or alphabetically.
struct RelatedVerbListView: View {
  let destination: RelatedVerbListDestination
  private let lists: [VerbSort: [VerbMapEntry]]

  init(destination: RelatedVerbListDestination) {
    self.destination = destination
    lists = VerbSort.sortedLists(of: destination.verbs.compactMap { VerbMap.shared.entry(for: $0) })
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
        SortableVerbList(lists: lists, initialSort: .frequency, source: .related)
      }
      .padding()
      .readingWidth()
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(L.Verb.builtOn(root: RelatedVerbsView.citationForm(destination.root)))
    .navigationBarTitleDisplayMode(.inline)
  }
}
