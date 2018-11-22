//
//  ReviewPrompter.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/5/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import StoreKit

struct ReviewPrompter {
  static let shared = ReviewPrompter()
  static let promptModulo = 9
  static let promptInterval: TimeInterval = 60 * 60 * 24 * 180
  private let settings: Settings
  private let now: Date
  private let requestReview: () -> ()

  init(settings: Settings = Settings.shared, now: Date = Date(), requestReview: @escaping () -> () = { SKStoreReviewController.requestReview() }) {
    self.settings = settings
    self.now = now
    self.requestReview = requestReview
  }

  func promptableActionHappened() {
    var actionCount = settings.promptActionCount
    actionCount += 1
    settings.promptActionCount = actionCount
    let lastReviewPromptDate = settings.lastReviewPromptDate
    if actionCount % ReviewPrompter.promptModulo == 0 && now.timeIntervalSince(lastReviewPromptDate) >= ReviewPrompter.promptInterval {
      requestReview()
      settings.lastReviewPromptDate = now
    }
  }
}
