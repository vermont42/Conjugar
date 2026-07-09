//
//  ConjugarWidgetBundle.swift
//  ConjugarWidget
//
//  The extension's @main entry point: every widget, control, and Live Activity the
//  extension vends.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct ConjugarWidgetBundle: WidgetBundle {
  var body: some Widget {
    VerbOfTheDayWidget()
    QuizWidget()
    QuickQuizControl()
    RandomVerbControl()
    QuizLiveActivity()
  }
}
