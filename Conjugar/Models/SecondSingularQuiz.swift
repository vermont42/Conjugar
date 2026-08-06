//
//  SecondSingularQuiz.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/8/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

// The raw values double as the persisted `Settings.secondSingularQuiz` value **and**
// the segmented-control labels. Keep them stable: renaming a case's raw
// value would silently reset every user who had picked the renamed option, since the
// stored string would no longer parse back to a case. If the displayed labels ever
// need to change independently of persistence, add a `localizedDisplayName` accessor
// (as `SecondSingularBrowse` already has) rather than editing the raw values.
enum SecondSingularQuiz: String, CaseIterable {
  case tu = "Tú"
  case vos = "Vos"
}
