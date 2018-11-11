//
//  AWSAnalyticsService.swift
//  Conjugar
//
//  Created by Joshua Adams on 10/8/18.
//  Copyright © 2018 Joshua Adams. All rights reserved.
//

import Foundation
import AWSPinpoint

@objc class AWSAnalyticsService: NSObject, AnalyticsService {
  var pinpoint: AWSPinpoint
  @objc static let shared = AWSAnalyticsService()

  override init() {
    let config = AWSPinpointConfiguration.defaultPinpointConfiguration(launchOptions: nil)
    pinpoint = AWSPinpoint(configuration: config)
    super.init()
    recordCustomProfileDemographics()
//    AWSDDLog.sharedInstance.logLevel = .verbose
//    AWSDDLog.add(AWSDDTTYLogger.sharedInstance)
  }

  @objc func recordEvent(_ eventName: String) {
    recordEvent(eventName, parameters: nil, metrics: nil)
  }

  @objc func recordEvent(_ eventName: String, parameters: [String : String]? = nil, metrics: [String : Double]? = nil) {
    let event = pinpoint.analyticsClient.createEvent(withEventType: eventName)
    if let parameters = parameters {
      for (key, value) in parameters {
        event.addAttribute(value, forKey: key)
      }
    }
    if let metrics = metrics {
      for (key, value) in metrics {
        event.addMetric(NSNumber(value: value), forKey: key)
      }
    }
    pinpoint.analyticsClient.record(event)
    pinpoint.analyticsClient.submitEvents()
  }

  @objc func recordVisitation(viewController: String) {
    let visited = "visited"
    recordEvent(visited, parameters: ["viewController" : "\(viewController)"])
  }

  @objc func recordQuizStart() {
    let quizStart = "quizStart"
    recordEvent(quizStart)
  }

  @objc func recordQuizCompletion(score: Int) {
    let quizCompletion = "quizCompletion"
    recordEvent(quizCompletion, parameters: ["score" : "\(score)"])
  }

  @objc func recordGameCenterAuth() {
    let gameCenterAuth = "gameCenterAuth"
    recordEvent(gameCenterAuth)
  }

  private func recordCustomProfileDemographics() {
    let profile: AWSPinpointEndpointProfile = (pinpoint.targetingClient.currentEndpointProfile())
    profile.demographic?.model = UIDevice.current.modelName
    profile.demographic?.platformVersion = UIDevice.current.systemVersion
    pinpoint.targetingClient.update(profile)
  }
}
