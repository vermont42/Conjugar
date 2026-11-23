//
//  InfoDifficulty.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/17/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

/// How advanced an Info article is, which the Info tab filters by. The quiz asks by `QuizLevel`,
/// which has nothing to do with this. The raw values are stored by `Settings.infoDifficulty`.
enum InfoDifficulty: String, CaseIterable {
  case easy = "Easy"
  case moderate = "Moderate"
  case difficult = "Difficult"
}
