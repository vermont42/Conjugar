//
//  Modifiers.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import SwiftUI

struct HeadingLabel: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.heading)
      .foregroundColor(Color(Colors.yellow))
  }
}

struct SubheadingLabel: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.subheading)
      .foregroundColor(Color(Colors.yellow))
  }
}

struct BodyLabel: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.smallBody)
      .foregroundColor(Color(Colors.yellow))
      .padding(.horizontal, Layout.defaultHorizontalMargin)
  }
}

struct WidgetLabel: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.heading)
  }
}

struct StandardButton: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.button)
      .foregroundColor(Color(Colors.red))
  }
}

struct SegmentedPicker: ViewModifier {
  func body(content: Content) -> some View {
    content
      .pickerStyle(SegmentedPickerStyle())
      .padding(.horizontal, Layout.defaultHorizontalMargin)
  }
}
