//
//  VerbPageNavigation.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// Pushes a value onto whichever navigation stack shows the verb page, so that the page's links work
/// in the Verbs, Models, and Quiz tabs alike. The stack needs a destination for the value's type,
/// which `verbPageDestinations()` registers: `VerbDestination`, `ModelInfo`, or
/// `RelatedVerbListDestination`.
struct VerbPagePush {
  let push: (any Hashable) -> Void

  func callAsFunction(_ value: some Hashable) {
    push(value)
  }
}

extension EnvironmentValues {
  @Entry var verbPagePush: VerbPagePush?
}

extension View {
  /// The destinations that a verb page, and the pages it leads to, can push. Every stack that shows
  /// verb pages registers them here, so that each builds a verb page, its marks included, alike.
  func verbPageDestinations() -> some View {
    navigationDestination(for: VerbDestination.self) { destination in
      VerbView(verb: destination.infinitive, source: destination.source, marks: destination.marks)
    }
    // Only a verb page's model pill pushes a bare `ModelInfo`; the Models tab's rows push a
    // `CollectionRequest`, which names its source.
    .navigationDestination(for: ModelInfo.self) { model in
      ModelView(model: model, source: .verbPage)
    }
    .navigationDestination(for: RelatedVerbListDestination.self) { destination in
      RelatedVerbListView(destination: destination)
    }
  }

  /// Lets the pages on a stack push onto it through `verbPagePush`. Apply it outside the
  /// `NavigationStack`, so that every pushed page inherits it.
  func pushesVerbPages(onto path: Binding<NavigationPath>) -> some View {
    environment(\.verbPagePush, VerbPagePush { path.wrappedValue.append($0) })
  }
}
