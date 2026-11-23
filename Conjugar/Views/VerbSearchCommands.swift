//
//  VerbSearchCommands.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// Command-F for iPad and Mac keyboards, as Verbs › Find a Verb in iPadOS 26's menu bar. A
/// top-level menu, because the system's own Find item claims ⌘F beside `.textEditing` and a
/// `CommandGroup` there never fires (Konjugieren's finding). The arrow keys through results are
/// in `VerbSearchArrowKeys`, since a menu command cannot take an arrow key from a text field.
struct VerbSearchCommands: Commands {
  let router: AppRouter

  var body: some Commands {
    CommandMenu(L.BrowseVerbs.localizedTitle) {
      Button(L.BrowseVerbs.findVerb) {
        router.openSearch(text: nil, source: .tab)
      }
      .keyboardShortcut("f")
    }
  }
}
