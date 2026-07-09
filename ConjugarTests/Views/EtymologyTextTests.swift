//
//  EtymologyTextTests.swift
//  ConjugarTests
//
//  Swift Testing for the etymology renderer used by the Verb screen's etymology
//  card. The markup is the `~…~`-bold / `\n\n`-paragraph vocabulary the pipeline in
//  `prompts/etymology-pipeline.md` emits, with a literal `*` before a bold run for
//  reconstructed forms (`*~steh₂-~`).
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
@testable import Conjugar

@MainActor
@Suite struct EtymologyTextTests {
  @Test func plainStripsBoldMarkersOnly() {
    #expect(EtymologyText.plain("From Latin ~stāre~ (“to stand”).") == "From Latin stāre (“to stand”).")
    // The reconstruction asterisk and paragraph break survive; only ~ is removed.
    #expect(EtymologyText.plain("*~steh₂-~\n\ntail") == "*steh₂-\n\ntail")
  }

  @Test func boldSpansAreEmphasizedTheRestIsNot() {
    let attributed = EtymologyText.attributedString(for: "From Latin ~stāre~ today.")

    // Reconstructed plain text drops the markers.
    #expect(String(attributed.characters) == "From Latin stāre today.")

    // Exactly the "stāre" run carries strong emphasis; the surrounding prose does not.
    var emphasized = ""
    var plain = ""
    for run in attributed.runs {
      let text = String(attributed[run.range].characters)
      if run.inlinePresentationIntent == .stronglyEmphasized {
        emphasized += text
      } else {
        plain += text
      }
    }
    #expect(emphasized == "stāre")
    #expect(plain == "From Latin  today.")
  }

  @Test func reconstructionAsteriskPassesThroughOutsideTheBold() {
    let attributed = EtymologyText.attributedString(for: "root *~steh₂-~ here")
    #expect(String(attributed.characters) == "root *steh₂- here")

    // The asterisk stays in a non-emphasized run; only steh₂- is emphasized.
    for run in attributed.runs where run.inlinePresentationIntent == .stronglyEmphasized {
      #expect(String(attributed[run.range].characters) == "steh₂-")
    }
  }

  @Test func paragraphBreakIsPreserved() {
    let attributed = EtymologyText.attributedString(for: "First ~one~.\n\nSecond ~two~.")
    #expect(String(attributed.characters).contains("\n\n"))
  }

  @Test func unmarkedTextRoundTripsWithNoEmphasis() {
    let attributed = EtymologyText.attributedString(for: "No markup here.")
    #expect(String(attributed.characters) == "No markup here.")
    for run in attributed.runs {
      #expect(run.inlinePresentationIntent != .stronglyEmphasized)
    }
  }
}
