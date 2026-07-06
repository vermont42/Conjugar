//
//  ConjugationTextTests.swift
//  ConjugarTests
//
//  Swift Testing for the shared conjugation renderer used by the migrated Verb
//  (and, later, Model / Quiz / Results) SwiftUI screens.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
@testable import Conjugar

@MainActor
@Suite struct ConjugationTextTests {
  @Test func plainLowercasesAndStripsMarkers() {
    #expect(ConjugationText.plain("tenGo") == "tengo")
    #expect(ConjugationText.plain("¡ten!") == "¡ten!")
  }

  @Test func irregularSpanIsRedTheRestIsRegular() {
    let regular = Color.customForeground
    let attributed = ConjugationText.attributedString(for: "tenGo", regularColor: regular)

    // Reconstructed plain text is the lowercased form.
    #expect(String(attributed.characters) == "tengo")

    // The irregular "g" run carries customRed; the surrounding runs do not.
    var sawRed = false
    var sawRegular = false
    for run in attributed.runs {
      let text = String(attributed[run.range].characters)
      if run.foregroundColor == Color.customRed {
        #expect(text == "g")
        sawRed = true
      } else if run.foregroundColor == regular {
        sawRegular = true
      }
    }
    #expect(sawRed)
    #expect(sawRegular)
  }

  @Test func fullyRegularFormHasNoRedRun() {
    let attributed = ConjugationText.attributedString(for: "hablo")
    #expect(String(attributed.characters) == "hablo")
    for run in attributed.runs {
      #expect(run.foregroundColor != Color.customRed)
    }
  }
}
