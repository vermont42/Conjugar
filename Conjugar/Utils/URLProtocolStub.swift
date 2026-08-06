//
//  URLProtocolStub.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/26/19.
//  Based on an article by Paul Hudson.

import Foundation

nonisolated class URLProtocolStub: URLProtocol {
  nonisolated(unsafe) static var testURLs = [URL?: Data]()

  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    if let url = request.url {
      if let data = URLProtocolStub.testURLs[url] {
        // Deliver a URLResponse *before* the data. Without it, the task has no
        // response, and URLSession's metrics collection (didFinishCollectingMetrics)
        // traps with SIGILL on the async `data(for:)` path in the simulator — which
        // crashed the Settings tab (its ratings lookup uses the stub session).
        if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil) {
          self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        self.client?.urlProtocol(self, didLoad: data)
      }
    }
    self.client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() { }
}
