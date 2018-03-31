//
//  ReviewPrompter.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/5/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import StoreKit

struct ReviewPrompter {
  private static let promptModulo = 9
  private static let promptInterval: TimeInterval = 60 * 60 * 24 * 180

  internal static func promptableActionHappened() {
    var actionCount = SettingsManager.getPromptActionCount()
    actionCount += 1
    SettingsManager.setPromptActionCount(actionCount)
    let lastReviewPromptDate = SettingsManager.getLastReviewPromptDate()
    let now = Date()
    if actionCount % promptModulo == 0 && now.timeIntervalSince(lastReviewPromptDate) >= promptInterval {
      SKStoreReviewController.requestReview()
      SettingsManager.setLastReviewPromptDate(now)
    }
  }
}
