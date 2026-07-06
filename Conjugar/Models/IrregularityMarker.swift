//
//  IrregularityMarker.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Reconstructs the legacy engine's irregularity highlighting. The legacy
// verbs.xml hand-encoded each form's irregular letters as UPPERCASE
// ("abIERTo", "hE", "tUVieron"), which `String.conjugatedString` renders as a
// red span (and lowercases for display). Conjugator produces plain-lowercase
// forms, so the bridge recreates the encoding mechanically: diff the conjugated
// form against its **regular composition** (the same verb conjugated with a
// feature-less model) and uppercase the differing span.

import Foundation

enum IrregularityMarker {
  /// `form` with the span that differs from `regular` uppercased, word by word
  /// (compound tenses diff the auxiliary and the participle independently). A
  /// word-count mismatch returns `form` unmarked.
  static func marked(form: String, regular: String) -> String {
    let formWords = form.components(separatedBy: " ")
    let regularWords = regular.components(separatedBy: " ")
    guard formWords.count == regularWords.count else {
      return form
    }
    return zip(formWords, regularWords).map(markedWord).joined(separator: " ")
  }

  /// One word: uppercase between the common prefix and common suffix. A
  /// deletion-only difference (tañó vs the regular *tañió) marks the single
  /// character at the seam; no common affixes at all marks the whole word
  /// (fui vs the regular *sí → FUI).
  private static func markedWord(form: String, regular: String) -> String {
    guard form != regular else {
      return form
    }
    let formChars = Array(form)
    let regularChars = Array(regular)
    var prefix = 0
    while prefix < formChars.count && prefix < regularChars.count && formChars[prefix] == regularChars[prefix] {
      prefix += 1
    }
    var suffix = 0
    while suffix < formChars.count - prefix && suffix < regularChars.count - prefix && formChars[formChars.count - 1 - suffix] == regularChars[regularChars.count - 1 - suffix] {
      suffix += 1
    }
    var start = prefix
    var end = formChars.count - suffix
    if start >= end {
      start = min(prefix, formChars.count - 1)
      end = start + 1
    }
    return String(formChars[..<start]) + String(formChars[start..<end]).uppercased() + String(formChars[end...])
  }
}
