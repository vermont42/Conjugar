//
//  RatingsFetcher.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/1/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

struct RatingsFetcher {
  static let iTunesID = "1236500467"
  static let errorMessage = "Fetching failed."

  private static let urlInitializationMessage = " URL could not be initializaed."

  static var iTunesURL: URL {
    guard let iTunesURL = URL(string: "https://itunes.apple.com/lookup?id=\(iTunesID)") else {
      fatalError("iTunes" + urlInitializationMessage)
    }
    return iTunesURL
  }

  static var reviewURL: URL {
    guard let reviewURL = URL(string: "https://itunes.apple.com/app/conjugar/id\(iTunesID)?action=write-review") else {
      fatalError("Rate/review" + urlInitializationMessage)
    }
    return reviewURL
  }

  static func fetchRatingsDescription(completion: @escaping (String) -> ()) {
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
          description = Localizations.Settings.noRating + exhortation
        case 1:
          description = Localizations.Settings.oneRating + " " + Localizations.Settings.addYours
        default:
          description = String(format: Localizations.Settings.multipleRatings, ratingsCount) + " " + Localizations.Settings.addYours
        }
        completion(description)
      }
    }

    task.resume()
  }

  static func stubData(ratingsCount: Int) -> Data {
    return Data("{ \"resultCount\":1, \"results\": [ { \"userRatingCountForCurrentVersion\": \(ratingsCount) } ] }".utf8)
  }
}
