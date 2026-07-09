//
//  InfoTests.swift
//  ConjugarTests
//
//  Swift Testing suite for the SwiftUI Info migration: the rich-text
//  parser (RichText.swift) and the Info model. Replaces the deleted XCTest suites
//  BrowseInfoVCTests / InfoVCTests / InfoCellTests.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct InfoTests {
  @Test func infosCount() {
    #expect(Info.infos.count == 28)
  }

  /// The difficulty filter thresholds, preserved from the old BrowseInfoVCTests:
  /// Easy → 9, Easy+Moderate → 17, all → 28.
  @Test func difficultyFilterCounts() {
    func rank(_ d: Difficulty) -> Int { Difficulty.allCases.firstIndex(of: d) ?? 0 }
    func count(upTo d: Difficulty) -> Int {
      Info.infos.filter { rank($0.difficulty) <= rank(d) }.count
    }
    #expect(count(upTo: .easy) == 9)
    #expect(count(upTo: .moderate) == 17)
    #expect(count(upTo: .difficult) == 28)
  }

  @Test func sectionsPartitionAllInfos() {
    let about = Info.infos.filter { $0.section == .about }
    let tenses = Info.infos.filter { $0.section == .tenses }
    #expect(about.count + tenses.count == Info.infos.count)
    // The "About" articles are all easy, so the filter never hides them.
    #expect(about.allSatisfy { $0.difficulty == .easy })
  }

  @Test func headingLookupIsCaseInsensitive() {
    #expect(Info.info(forHeading: "voseo")?.heading == "Voseo")
    #expect(Info.info(forHeading: "PRETÉRITO")?.heading == "Pretérito")
    #expect(Info.info(forHeading: "no such article") == nil)
  }

  @Test func everyInfoParsesToAtLeastOneBlock() {
    for info in Info.infos {
      #expect(!info.richTextBlocks.isEmpty, "\(info.heading) produced no blocks")
    }
  }

  @Test func subheadingBecomesOwnBlock() {
    let blocks = "before ^A Heading^\nafter".richTextBlocks
    #expect(blocks.count == 3)
    guard case .body(let pre) = blocks[0] else { Issue.record("expected body first"); return }
    #expect(pre.plainText == "before ")
    guard case .subheading(let heading) = blocks[1] else { Issue.record("expected subheading"); return }
    #expect(heading == "A Heading")
    guard case .body(let post) = blocks[2] else { Issue.record("expected trailing body"); return }
    #expect(post.plainText == "after")
  }

  @Test func boldSegment() {
    let segments = "plain ~bold~ tail".parseBodyToSegments()
    #expect(segments.count == 3)
    #expect(segments[0] == .plain("plain "))
    #expect(segments[1] == .bold("bold"))
    #expect(segments[2] == .plain(" tail"))
  }

  @Test func httpLinkSegment() {
    let segments = "see %https://racecondition.software% now".parseBodyToSegments()
    guard case .link(let text, let url) = segments[1] else {
      Issue.record("expected a link segment")
      return
    }
    #expect(text == "https://racecondition.software")
    #expect(url.absoluteString == "https://racecondition.software")
  }

  @Test func crossReferenceLinkIsPercentEncoded() {
    let segments = "%Presente de Indicativo%".parseBodyToSegments()
    guard case .link(let text, let url) = segments[0] else {
      Issue.record("expected a link segment")
      return
    }
    #expect(text == "Presente de Indicativo")
    // The encoded URL decodes back to the heading so the tap handler can match it.
    #expect(url.absoluteString.removingPercentEncoding == "Presente de Indicativo")
  }

  @Test func conjugationSplitsIrregularSpan() {
    let segments = "$doY$".parseBodyToSegments()
    guard case .conjugation(let parts) = segments[0] else {
      Issue.record("expected a conjugation segment")
      return
    }
    #expect(parts == [.regular("do"), .irregular("y")])
  }
}
