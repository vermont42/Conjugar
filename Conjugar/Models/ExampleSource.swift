//
//  ExampleSource.swift
//  Conjugar
//
//  Maps an `Example.source` filename onto a human-readable attribution string.
//  Public-domain literature and the AI-authored tail get a fixed "— Author, Title
//  (year)" credit; government/statistics sources get a localized "Fuente:/Source:"
//  line naming the issuing body. Port of Conjuguer's enum; the source list and the
//  attribution wording track the `^Example Uses^` credits in `Localizable.xcstrings`
//  and the source table in `docs/example-corpus-sources.md`.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum ExampleSource: Hashable {
  case literature(author: String, title: String, year: String)
  case government(body: String) // gov/statistics — "Fuente:/Source: <body>".
  case claude // AI-authored tail.
  case other(String)

  init(rawSource: String) {
    if let work = Self.literatureTable[rawSource] {
      self = .literature(author: work.author, title: work.title, year: work.year)
    } else if let body = Self.governmentTable[rawSource] {
      self = .government(body: body)
    } else if rawSource.hasPrefix("Claude") {
      self = .claude
    } else {
      self = .other(rawSource)
    }
  }

  var attribution: String {
    switch self {
    case .literature(let author, let title, let year):
      return "— \(author), \(title) (\(year))"
    case .government(let body):
      return L.Verb.exampleSource(body: body)
    case .claude:
      return L.Verb.exampleSourceClaude
    case .other(let raw):
      return "— " + raw
    }
  }

  // The eight public-domain literary sources (Project Gutenberg). Author/title/year are
  // proper nouns, identical in every language, so they are not localized.
  private static let literatureTable: [String: (author: String, title: String, year: String)] = [
    "fortunata-y-jacinta-galdos-1887.txt": ("Benito Pérez Galdós", "Fortunata y Jacinta", "1887"),
    "marianela-galdos-1878.txt": ("Benito Pérez Galdós", "Marianela", "1878"),
    "la-regenta-clarin-1885.txt": ("Leopoldo Alas «Clarín»", "La Regenta", "1884–1885"),
    "pazos-de-ulloa-pardo-bazan-1886.txt": ("Emilia Pardo Bazán", "Los pazos de Ulloa", "1886"),
    "pepita-jimenez-valera-1874.txt": ("Juan Valera", "Pepita Jiménez", "1874"),
    "sombrero-tres-picos-alarcon-1874.txt": ("Pedro Antonio de Alarcón", "El sombrero de tres picos", "1874"),
    "la-barraca-blasco-ibanez-1898.txt": ("Vicente Blasco Ibáñez", "La barraca", "1898"),
    "quijote-cervantes-1605.txt": ("Miguel de Cervantes", "Don Quijote", "1605")
  ]

  // Government / statistics sources — issuing body (proper nouns), wrapped by the
  // localized "Fuente:/Source:" prefix in `attribution`.
  private static let governmentTable: [String: String] = [
    "es-trlpi-ley-propiedad-intelectual.txt": "Boletín Oficial del Estado, Ley de Propiedad Intelectual",
    "es-miteco-pniec-2023-2030.txt": "MITECO, Plan Nacional Integrado de Energía y Clima 2023–2030",
    "es-mitma-movilidad-2030.txt": "Mitma, Estrategia de Movilidad 2030",
    "es-ine-informe-anual-2024.txt": "INE, Informe Anual 2024",
    "es-espana-digital-2026.txt": "España Digital 2026",
    "mx-estrategia-digital-nacional.txt": "Estrategia Digital Nacional (México)",
    "co-dane-geih-jul2025.txt": "DANE, Gran Encuesta Integrada de Hogares (Colombia)",
    "co-mintic-gobierno-digital.txt": "MinTIC, Gobierno Digital (Colombia)",
    "co-conpes-3975-transformacion-digital-ia.txt": "CONPES 3975 (Colombia)"
  ]
}
