//
//  RatingsFetcher.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/1/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

struct RatingsFetcher {
  nonisolated static let iTunesID = "1236500467"

  nonisolated private static let urlInitializationMessage = " URL could not be initializaed."

  nonisolated static var iTunesURL: URL {
    guard let iTunesURL = URL(string: "https://itunes.apple.com/lookup?id=\(iTunesID)") else {
      fatalError("iTunes" + urlInitializationMessage)
    }
    return iTunesURL
  }

  nonisolated static var reviewURL: URL {
    guard let reviewURL = URL(string: "https://itunes.apple.com/app/conjugar/id\(iTunesID)?action=write-review") else {
      fatalError("Rate/review" + urlInitializationMessage)
    }
    return reviewURL
  }

  /// The iTunes lookup response. Only the one field the row needs is modeled;
  /// everything else in the payload is ignored.
  private struct LookupResponse: Decodable {
    let results: [Entry]

    struct Entry: Decodable {
      let userRatingCountForCurrentVersion: Int?
    }
  }

  /// The localized ratings sentence for the current app version, or `nil` when the
  /// lookup fails or returns an unexpected shape. Returning an optional lets the
  /// caller surface the failure instead of leaving the row silently empty.
  static func ratingsDescription() async -> String? {
    let request = URLRequest(url: RatingsFetcher.iTunesURL)

    guard
      let (data, _) = try? await Current.session.data(for: request),
      let response = try? JSONDecoder().decode(LookupResponse.self, from: data),
      response.results.count == 1
    else {
      return nil
    }

    let ratingsCount = response.results[0].userRatingCountForCurrentVersion ?? 0

    switch ratingsCount {
    case 0:
      // This Spanish exhortation lives in the catalog so the deliberate mixed-language
      // flavor is visible to translation. It stays Spanish in both localizations by
      // design.
      return L.Settings.noRating + " " + L.Settings.beFirst
    default:
      return L.Settings.ratings(count: ratingsCount) + " " + L.Settings.addYours
    }
  }

  nonisolated static func stubData(ratingsCount: Int) -> Data {
    return Data("{ \"resultCount\":1, \"results\": [ { \"userRatingCountForCurrentVersion\": \(ratingsCount) } ] }".utf8)
  }
}
