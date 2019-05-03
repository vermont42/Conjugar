//
//  URLSessionExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/1/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

extension URLSession {
  static func stubSession(ratingsCount: Int) -> URLSession {
    URLProtocolStub.testURLs = [RatingsFetcher.iTunesURL: RatingsFetcher.stubData(ratingsCount: ratingsCount)]
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: config)
  }
}
