//
//  SymbolValidityTests.swift
//  ConjugarTests
//
//  Asserts every `systemName:` / `systemImage:` string literal in the app, widget, and
//  shared targets resolves to a real SF Symbol via `UIImage(systemName:)`. A bad name
//  (e.g. `figure.jump`, which does not exist) compiles fine but renders nothing at
//  runtime, so only a source sweep catches it. Reuses the `#filePath`-relative repo-root
//  idiom from `CorpusFormsDumpTests`. Custom asset-catalog symbols use `Image("name")` /
//  `.custom("name")`, never `systemName:`, so they don't match here.
//

import Foundation
import Testing
import UIKit
@testable import Conjugar

@Suite("SymbolValidity")
@MainActor
struct SymbolValidityTests {
  /// Source roots to scan, relative to the repo root. Every literal SF Symbol name that
  /// ships in a target lives under one of these.
  private static let scannedRoots = ["Conjugar", "ConjugarWidget", "Shared"]

  /// `systemName:` and `systemImage:` are the two argument labels that take an SF Symbol
  /// name; capture the double-quoted literal that follows either.
  private static let symbolLiteral = /(?:systemName|systemImage):\s*"([^"]+)"/

  @Test func everySystemSymbolLiteralResolves() throws {
    let repoRoot = URL(filePath: #filePath)
      .deletingLastPathComponent()  // Views/
      .deletingLastPathComponent()  // ConjugarTests/
      .deletingLastPathComponent()  // repo root

    var symbols: [String: String] = [:]   // symbol name → the file it first appeared in
    for root in Self.scannedRoots {
      for file in Self.swiftFiles(under: repoRoot.appending(path: root)) {
        let source = try String(contentsOf: file, encoding: .utf8)
        for match in source.matches(of: Self.symbolLiteral) {
          symbols[String(match.output.1)] = file.lastPathComponent
        }
      }
    }

    #expect(!symbols.isEmpty, "Scanned no symbol literals — the sweep is looking in the wrong place.")
    for (name, file) in symbols {
      #expect(
        UIImage(systemName: name) != nil,
        "\(name) (in \(file)) is not a valid SF Symbol — Image(systemName:) will render nothing."
      )
    }
  }

  /// `DanceMove.glyph` names live outside the `systemName:` sweep (the model stores
  /// them label-free), so resolve each one directly: system symbols against the SF
  /// set, custom symbols and sprites against the app's asset catalog.
  @Test func everyDanceMoveGlyphResolves() {
    for move in DanceMove.allCases {
      switch move.glyph {
      case .systemSymbol(let name):
        #expect(
          UIImage(systemName: name) != nil,
          "\(move)'s glyph \(name) is not a valid SF Symbol — it will render nothing."
        )
      case .customSymbol(let name), .sprite(let name):
        #expect(
          UIImage(named: name) != nil,
          "\(move)'s glyph \(name) is missing from the asset catalog."
        )
      case .emoji(let text):
        #expect(!text.isEmpty, "\(move)'s emoji glyph is empty.")
      }
    }
  }

  /// Every `.swift` file under `directory`, recursively. Skips unreadable trees gracefully.
  private static func swiftFiles(under directory: URL) -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
      at: directory, includingPropertiesForKeys: nil
    ) else { return [] }
    return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
  }
}
