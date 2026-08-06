//
//  RichText.swift
//  Conjugar
//
//  SwiftUI-native rich-text model + parser for the Info articles (and, later,
//  any other marked-up body copy).
//
//  It replaces the legacy `String.infoString` NSAttributedString pipeline: rather
//  than build an attributed string for a UITextView, it parses Conjugar's Info
//  markup into structured blocks/segments that `RichTextView` renders as native
//  SwiftUI `Text`, so body copy can be adaptive-colored (`customForeground`) with
//  serif headings and reading-width layout.
//
//  Conjugar's markup (see the table in CLAUDE.md):
//    ^…^  subheading (section heading)
//    ~…~  bold / emphasis
//    %…%  tappable term (cross-links to another Info article) or an http(s) URL
//    $…$  conjugation — uppercase letters mark the irregular span (shown red)
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A top-level block of an Info article: either a section subheading or a run of
/// inline body segments.
enum RichTextBlock: Hashable {
  case body([TextSegment])
  case subheading(String)
}

/// One inline run within a body block.
enum TextSegment: Hashable {
  case bold(String)
  case conjugation([ConjugationPart])
  case link(text: String, url: URL)
  case plain(String)
}

/// A run inside a `$…$` conjugation segment: `irregular` letters render red, the
/// rest render in the normal foreground color.
enum ConjugationPart: Hashable {
  case irregular(String)
  case regular(String)
}

extension String {
  static var subheadingMarker: Character { "^" }
  static var boldMarker: Character { "~" }
  static var linkMarker: Character { "%" }
  static var conjugationMarker: Character { "$" }

  func trimmingLeadingNewlines() -> String {
    var result = self
    while result.hasPrefix("\n") {
      result.removeFirst()
    }
    return result
  }

  /// Parse the full marked-up body of an Info article into ordered blocks.
  /// Subheadings (`^…^`) become their own `.subheading` blocks; the text between
  /// them is parsed into `.body` segments.
  var richTextBlocks: [RichTextBlock] {
    var blocks: [RichTextBlock] = []
    var currentText = ""
    var inSubheading = false
    var justClosedSubheading = false

    for char in self {
      if char == String.subheadingMarker {
        justClosedSubheading = false
        if inSubheading {
          let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmed.isEmpty {
            blocks.append(.subheading(trimmed))
          }
          currentText = ""
          inSubheading = false
          justClosedSubheading = true
        } else {
          if !currentText.isEmpty {
            blocks.append(.body(currentText.parseBodyToSegments()))
            currentText = ""
          }
          inSubheading = true
        }
      } else {
        // Swallow the single newline that usually follows a closing subheading so
        // the next body block doesn't start with a blank line.
        if justClosedSubheading {
          justClosedSubheading = false
          if char == "\n" {
            continue
          }
        }
        currentText.append(char)
      }
    }

    if !currentText.isEmpty {
      if inSubheading {
        // Unterminated subheading: recover its text as a subheading rather than crash.
        assertionFailure("Unterminated subheading marker ^ in Info body.")
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          blocks.append(.subheading(trimmed))
        }
      } else {
        blocks.append(.body(currentText.parseBodyToSegments()))
      }
    }

    return blocks
  }

  /// Parse a single body run into inline segments (plain / bold / link / conjugation).
  func parseBodyToSegments() -> [TextSegment] {
    var segments: [TextSegment] = []
    var currentText = ""
    var inBold = false
    var inLink = false
    var inConjugation = false
    var markupStart = startIndex

    func flushPlain() {
      if !currentText.isEmpty {
        segments.append(.plain(currentText))
        currentText = ""
      }
    }

    for index in indices {
      let char = self[index]

      if char == String.boldMarker {
        if inBold {
          flushPlain()
          segments.append(.bold(String(self[self.index(after: markupStart)..<index])))
          inBold = false
        } else {
          flushPlain()
          inBold = true
          markupStart = index
        }
      } else if char == String.linkMarker {
        if inLink {
          flushPlain()
          let content = String(self[self.index(after: markupStart)..<index])
          if let url = Self.linkURL(for: content) {
            segments.append(.link(text: content, url: url))
          } else {
            segments.append(.plain(content))
          }
          inLink = false
        } else {
          flushPlain()
          inLink = true
          markupStart = index
        }
      } else if char == String.conjugationMarker {
        if inConjugation {
          flushPlain()
          let content = String(self[self.index(after: markupStart)..<index])
          segments.append(content.parseConjugationToSegment())
          inConjugation = false
        } else {
          flushPlain()
          inConjugation = true
          markupStart = index
        }
      } else if !inBold && !inLink && !inConjugation {
        currentText.append(char)
      }
    }

    // Recover any unterminated marker as plain text rather than crashing on bad data.
    if inBold || inLink || inConjugation {
      assertionFailure("Unterminated inline marker in Info body.")
      let tail = String(self[self.index(after: markupStart)...])
      if !tail.isEmpty {
        segments.append(.plain(tail))
      }
    } else {
      flushPlain()
    }

    return segments
  }

  /// URL for a `%…%` link: an http(s) target passes through; anything else is a
  /// cross-reference to another Info heading and is percent-encoded so it forms a
  /// valid URL the tap handler can decode and match.
  private static func linkURL(for content: String) -> URL? {
    if content.hasPrefix("http") {
      return URL(string: content)
    }
    let encoded = content.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? content
    return URL(string: encoded)
  }

  /// Split a conjugation string into irregular (uppercase) and regular runs,
  /// lowercasing everything for display. Mirrors the legacy `conjugatedString`;
  /// also used directly for the Verb/Model/Quiz conjugation displays, where the
  /// engine marks the irregular span with uppercase letters.
  func parseConjugationToSegment() -> TextSegment {
    guard !isEmpty else { return .conjugation([]) }

    var parts: [ConjugationPart] = []
    var currentRun = ""
    var currentIsUpper: Bool?

    func flushRun() {
      guard !currentRun.isEmpty else { return }
      parts.append(currentIsUpper == true ? .irregular(currentRun) : .regular(currentRun))
    }

    for char in self {
      let isUpper = char.isUppercase
      if currentIsUpper == nil {
        currentIsUpper = isUpper
        currentRun = char.lowercased()
      } else if isUpper == currentIsUpper {
        currentRun += char.lowercased()
      } else {
        flushRun()
        currentRun = char.lowercased()
        currentIsUpper = isUpper
      }
    }
    flushRun()

    return .conjugation(parts)
  }
}

extension [TextSegment] {
  /// The concatenated plain text of these segments, markup stripped — for
  /// accessibility labels and tests.
  var plainText: String {
    map { segment in
      switch segment {
      case .plain(let text), .bold(let text), .link(let text, _):
        return text
      case .conjugation(let parts):
        return parts.map {
          switch $0 {
          case .regular(let text), .irregular(let text):
            return text
          }
        }
        .joined()
      }
    }
    .joined()
  }
}
