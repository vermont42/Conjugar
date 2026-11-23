//
//  ConjugationIndex.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The conjugation map, indexed for search: by folded spelling, so that "hablo" also finds habló
/// and "sueno" finds sueño, and by first letter and length, so that a guess compares a misspelling
/// only with forms that begin as it does and are about as long.
nonisolated struct ConjugationIndex: Sendable {
  let map: ConjugationMap
  private let formsByFoldedForm: [String: [String]]
  private let foldedFormsByStart: [Start: [String]]

  private nonisolated struct Start: Hashable, Sendable {
    let firstLetter: Character
    let length: Int
  }

  init(map: ConjugationMap) {
    self.map = map
    var formsByFoldedForm: [String: [String]] = [:]
    for form in map.entriesByForm.keys.sorted() {
      formsByFoldedForm[VerbSearch.fold(form), default: []].append(form)
    }
    self.formsByFoldedForm = formsByFoldedForm
    var foldedFormsByStart: [Start: [String]] = [:]
    for folded in formsByFoldedForm.keys.sorted() {
      if let firstLetter = folded.first {
        foldedFormsByStart[Start(firstLetter: firstLetter, length: folded.count), default: []].append(folded)
      }
    }
    self.foldedFormsByStart = foldedFormsByStart
  }

  /// Built on first use from `ConjugationMap.bundled`, which takes about a second, so the verb
  /// list touches it from a background task before the learner types.
  static let bundled = ConjugationIndex(map: .bundled)

  nonisolated struct Spelling: Equatable, Sendable {
    let form: String
    /// True when the form equals the word only after folding: habló for "hablo".
    let isFolded: Bool
  }

  /// The forms that `word` spells: itself, if it is one, then those equal to it after folding.
  func spellings(of word: String) -> [Spelling] {
    let lowered = word.lowercased()
    let literal = map.entriesByForm[lowered] == nil ? [] : [Spelling(form: lowered, isFolded: false)]
    let folded = (formsByFoldedForm[VerbSearch.fold(lowered)] ?? [])
      .filter { $0 != lowered }
      .map { Spelling(form: $0, isFolded: true) }
    return literal + folded
  }

  /// The forms that fold to `folded`.
  func forms(folding folded: String) -> [String] {
    formsByFoldedForm[folded] ?? []
  }

  /// The folded forms that begin with `firstLetter` and whose length is within `distance` of
  /// `length`.
  func foldedForms(startingWith firstLetter: Character, nearLength length: Int, distance: Int) -> [String] {
    ((length - distance)...(length + distance)).flatMap { foldedFormsByStart[Start(firstLetter: firstLetter, length: $0)] ?? [] }
  }
}
