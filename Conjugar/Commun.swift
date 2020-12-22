//
//  Commun.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/14/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import UIKit

struct Commun {
  let title: [String: String]
  let image: UIImage
  let imageLabel: [String: String]
  let content: [String: String]
  let type: CommunType
  let identifier: Int

  enum CommunType {
    case information(okayTitle: [String: String])
    case newVersion(okayTitle: [String: String], actionTitle: [String: String], cancelTitle: [String: String], action: () -> (), alreadyUpdated: Bool)
    case email(actionTitle: [String: String], cancelTitle: [String: String], action: () -> ())
    case website(actionTitle: [String: String], cancelTitle: [String: String], action: () -> ())
  }
}
