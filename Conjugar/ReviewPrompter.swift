//
//  ReviewPrompter.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/5/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import StoreKit

struct ReviewPrompter: ReviewPromptable {
  static let promptModulo = 9
  static let promptInterval: TimeInterval = 60 * 60 * 24 * 180
  private let settings: Settings
  private let now: Date
  private let requestReview: () -> ()
  private static let defaultRequestReview: () -> () = {
    if let scene = UIApplication.shared.connectedScenes.first(
      where: { $0.activationState == .foregroundActive }
    ) as? UIWindowScene {
      DispatchQueue.main.async {
        SKStoreReviewController.requestReview(in: scene)
      }
    }
  }

  init(settings: Settings = Settings(getterSetter: UserDefaultsGetterSetter()), now: Date = Date(), requestReview: @escaping () -> () = ReviewPrompter.defaultRequestReview) {
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
