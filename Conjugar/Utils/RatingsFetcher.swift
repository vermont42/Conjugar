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
  nonisolated static let errorMessage = "Fetching failed."

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

  static func fetchRatingsDescription(completion: @escaping @Sendable (String) -> ()) {
    let request = URLRequest(url: RatingsFetcher.iTunesURL)

    let task = Current.session.dataTask(with: request) { (responseData, _, error) in
      if error != nil {
        completion(errorMessage)
        return
      } else if let responseData = responseData {
        guard
          let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
          let results = json["results"] as? [[String: Any]],
          results.count == 1
        else {
          completion(errorMessage)
          return
        }

        let ratingsCount = (results[0])["userRatingCountForCurrentVersion"] as? Int ?? 0

        let description: String
        let exhortation = " ¡Sé la primera o el primero!"

        switch ratingsCount {
        case 0:
          description = L.Settings.noRating + exhortation
        default:
          description = L.Settings.ratings(count: ratingsCount) + " " + L.Settings.addYours
        }
        completion(description)
      }
    }

    task.resume()
  }

  nonisolated static func stubData(ratingsCount: Int) -> Data {
    return Data("{ \"resultCount\":1, \"results\": [ { \"userRatingCountForCurrentVersion\": \(ratingsCount) } ] }".utf8)
  }
}
