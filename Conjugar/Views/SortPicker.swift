//
//  SortPicker.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// The segmented control under or above a list that chooses its order, with a short animation and a
/// selection haptic on each change.
struct SortPicker<Option: PickerOption>: View {
  @Binding var selection: Option

  var body: some View {
    Picker(L.BrowseVerbs.sort, selection: $selection.animation(.snappy)) {
      ForEach(Option.allCases, id: \.self) { option in
        Text(option.localizedDisplayName).tag(option)
      }
    }
    .pickerStyle(.segmented)
    .sensoryFeedback(.selection, trigger: selection)
  }
}
