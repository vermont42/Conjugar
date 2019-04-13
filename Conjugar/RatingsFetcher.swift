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

  static func fetchDescription(completion: @escaping (String) -> ()) {
    guard let itunesUrl = URL(string: "https://itunes.apple.com/lookup?id=\(iTunesID)") else {
      return
    }

    let request = URLRequest(url: itunesUrl)

    let task = URLSession.shared.dataTask(with: request) { (responseData, _, error) in
      if error != nil {
        completion(errorMessage)
        return
      } else if let responseData = responseData {
        guard
          let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
          let results = json?["results"] as? [[String: Any]],
          results.count == 1,
          let ratingsCount = (results[0])["userRatingCountForCurrentVersion"] as? Int
          else {
            completion(errorMessage)
            return
        }

        let description: String
        let addYours = "Add yours!"
        switch ratingsCount {
        case 0:
          description = "No one has rated this version of Conjugar. Be the first!"
        case 1:
          description = "There is one rating for this version of Conjugar. \(addYours)"
        default:
          description = "There are \(ratingsCount) ratings for this version of Conjugar. \(addYours)"
        }
        completion(description)
      }
    }

    task.resume()
  }
}
