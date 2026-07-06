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
      .foregroundStyle(Color.customYellow)
  }
}

struct SubheadingLabel: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.subheading)
      .foregroundStyle(Color.customYellow)
  }
}

struct BodyLabel: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.smallBody)
      .foregroundStyle(Color.customYellow)
      .padding(.horizontal, Layout.defaultHorizontalMargin)
  }
}

struct StandardButton: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.button)
      .foregroundStyle(Color.customRed)
  }
}

struct SegmentedPicker: ViewModifier {
  func body(content: Content) -> some View {
    content
      .pickerStyle(SegmentedPickerStyle())
      .padding(.horizontal, Layout.defaultHorizontalMargin)
  }
}
