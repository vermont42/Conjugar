//
//  CommunViewModel.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/15/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import UIKit

struct CommunViewModel {
  private(set) var title = ""
  private(set) var content = ""
  private(set) var image = UIImage()
  private(set) var imageLabel = ""
  private(set) var okayTitle = ""
  private(set) var shouldShowOkay = false
  private(set) var cancelTitle = ""
  private(set) var shouldShowCancel = false
  private(set) var actionTitle = ""
  private(set) var shouldShowAction = false
  private(set) var action: () -> () = {}
  let identifier: Int

  init(commun: Commun) {
    identifier = commun.identifier
    configure(commun: commun)
  }

  private mutating func configure(commun: Commun) {
    title = stringFromDict(commun.title)
    content = stringFromDict(commun.content)
    image = commun.image
    imageLabel = stringFromDict(commun.imageLabel)

    switch commun.type {
    case .information(okayTitle: let okayTitle):
      self.okayTitle = stringFromDict(okayTitle)
      shouldShowOkay = true
    case .newVersion(okayTitle: let okayTitle, actionTitle: let actionTitle, cancelTitle: let cancelTitle, action: let action, alreadyUpdated: let alreadyUpdated):
      self.actionTitle = stringFromDict(actionTitle)
      self.cancelTitle = stringFromDict(cancelTitle)
      self.okayTitle = stringFromDict(okayTitle)
      shouldShowCancel = !alreadyUpdated
      shouldShowAction = !alreadyUpdated
      shouldShowOkay = alreadyUpdated
      self.action = action
    case .email(actionTitle: let actionTitle, cancelTitle: let cancelTitle, let action):
      self.actionTitle = stringFromDict(actionTitle)
      self.cancelTitle = stringFromDict(cancelTitle)
      shouldShowCancel = true
      shouldShowAction = true
      self.action = action
    case .website(actionTitle: let actionTitle, cancelTitle: let cancelTitle, action: let action):
      self.actionTitle = stringFromDict(actionTitle)
      self.cancelTitle = stringFromDict(cancelTitle)
      shouldShowCancel = true
      shouldShowAction = true
      self.action = action
    }
  }

  private func stringFromDict(_ dict: [String: String]) -> String {
    dict[Current.locale.languageCode] ?? dict[Current.locale.defaultLanguageCode] ?? ""
  }
}
