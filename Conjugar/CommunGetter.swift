//
//  CommunGetter.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/14/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation
import MessageUI

protocol CommunGetter {
  func getCommunication(completion: @escaping (Commun) -> Void)
  func openUrlClosure(urlString: String) -> (() -> ())?
}

extension CommunGetter {
  func openUrlClosure(urlString: String) -> (() -> ())? {
    if let url = URL(string: urlString) {
      return { UIApplication.shared.open(url, options: [:], completionHandler: nil) }
    } else {
      return nil
    }
  }
}
