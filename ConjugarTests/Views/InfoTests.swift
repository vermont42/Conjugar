//
//  InfoTests.swift
//  ConjugarTests
//
//  The rich-text parser (RichText.swift) and the Info model.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct InfoTests {
  @Test func infosCount() {
    #expect(Info.infos.count == 30)
  }

  /// The difficulty filter thresholds (each About article is `.easy`, so adding one bumps
  /// every tier): Easy → 11, Easy+Moderate → 19, all → 30. Perífrasis Verbales, though in Tenses, is easy too.
  @Test func difficultyFilterCounts() {
    func rank(_ d: InfoDifficulty) -> Int { InfoDifficulty.allCases.firstIndex(of: d) ?? 0 }
    func count(upTo d: InfoDifficulty) -> Int {
      Info.infos.filter { rank($0.difficulty) <= rank(d) }.count
    }
    #expect(count(upTo: .easy) == 11)
    #expect(count(upTo: .moderate) == 19)
    #expect(count(upTo: .difficult) == 30)
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

  @Test func stableKeysAreUnique() {
    let keys = Info.infos.map(\.stableKey)
    #expect(Set(keys).count == keys.count)
  }

  /// The periphrasis article sits after the non-finite forms it is built from and before the
  /// compound tenses, and it is easy, so the filter never hides it.
  @Test func periphrasisFollowsTheNonFiniteForms() throws {
    let keys = Info.infos.map(\.stableKey)
    let index = try #require(keys.firstIndex(of: "perifrasis_verbales"))
    #expect(keys[index - 1] == "raiz_futura")
    #expect(keys[index + 1] == "perfecto_de_indicativo")
    let info = Info.infos[index]
    #expect(info.section == .tenses)
    #expect(info.difficulty == .easy)
  }

  /// Every `%…%` cross-reference in every article, in both languages, names an article heading in
  /// that language, so the tap opens it. (Conjugar's articles link only to articles, never to a
  /// verb.) The tense headings are Spanish in both interfaces; the About headings are localized.
  @Test(arguments: ["en", "es"])
  func everyLinkInAnArticleOpensAnArticle(language: String) throws {
    let strings = try #require(Self.strings(language: language))
    let otherLanguage = language == "en" ? "es" : "en"
    let otherStrings = try #require(Self.strings(language: otherLanguage))
    func localizedHeadings(_ strings: [String: String]) -> [String] {
      strings.filter { $0.key.hasPrefix("Info.") && $0.key.hasSuffix("Heading") }.map(\.value)
    }
    let allLocalized = Set(localizedHeadings(strings) + localizedHeadings(otherStrings))
    let fixedHeadings = Info.infos.map(\.heading).filter { !allLocalized.contains($0) }
    let headings = Set((fixedHeadings + localizedHeadings(strings)).map { $0.lowercased() })
    #expect(headings.count == Info.infos.count)

    let texts = strings.filter { $0.key.hasPrefix("Info.") && $0.key.hasSuffix("Text") }
    #expect(texts.count == Info.infos.count)
    for (key, text) in texts {
      for target in Self.linkTargets(in: text) where !target.hasPrefix("http") {
        #expect(headings.contains(target.lowercased()), "\(key) [\(language)] links to “\(target)”, which is no article’s heading.")
      }
    }
  }

  /// The Futuro de Indicativo and Gerundio articles lead to the periphrasis article.
  @Test(arguments: ["en", "es"])
  func futuroAndGerundioLinkToPeriphrasis(language: String) throws {
    let strings = try #require(Self.strings(language: language))
    for key in ["Info.futuroDeIndicativoText", "Info.gerundioText"] {
      let text = try #require(strings[key])
      let targets = Self.linkTargets(in: text).map { $0.lowercased() }
      #expect(targets.contains("perífrasis verbales"), "\(key) [\(language)] does not link to Perífrasis Verbales.")
    }
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

  /// The compiled catalog for one language, read from the app bundle's `.lproj`.
  private static func strings(language: String) -> [String: String]? {
    guard let url = Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: language) else {
      return nil
    }
    return NSDictionary(contentsOf: url) as? [String: String]
  }

  /// The text between each pair of `%` markers, as `parseBodyToSegments` reads them.
  private static func linkTargets(in text: String) -> [String] {
    text.split(separator: String.linkMarker, omittingEmptySubsequences: false)
      .enumerated()
      .filter { !$0.offset.isMultiple(of: 2) }
      .map { String($0.element) }
  }
}
