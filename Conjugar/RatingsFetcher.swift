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
  static var iTunesURL: URL {
    guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(iTunesID)") else {
      fatalError("iTunes URL could not be initialized.")
    }
    return url
  }

  static func fetchRatingsDescription(session: URLSession, completion: @escaping (String) -> ()) {
    let request = URLRequest(url: RatingsFetcher.iTunesURL)

    let task = session.dataTask(with: request) { (responseData, _, error) in
      if error != nil {
        completion(errorMessage)
        return
      } else if let responseData = responseData {
        guard
          let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
          let results = json["results"] as? [[String: Any]],
          results.count == 1,
          let ratingsCount = (results[0])["userRatingCount"] as? Int
        else {
            completion(errorMessage)
            return
        }
        let description: String
        let addYours = "Add yours!"
        switch ratingsCount {
        case 0:
          description = "No one has rated Conjugar. Be the first!"
        case 1:
          description = "There is one rating for Conjugar. \(addYours)"
        default:
          description = "There are \(ratingsCount) ratings for Conjugar. \(addYours)"
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
