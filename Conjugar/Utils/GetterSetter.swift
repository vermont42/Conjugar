//
//  GetterSetter.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

protocol GetterSetter {
  func get(key: String) -> String?
  func set(key: String, value: String)
}

extension GetterSetter {
  /// Copies a stored string that failed to decode to `backupKey`, so that the store reading it can
  /// start afresh without destroying the only copy. Nothing stored, or the empty string that a
  /// reset writes, is not copied. A later failure overwrites the copy.
  func backUpUnreadable(_ stored: String?, to backupKey: String) {
    guard let stored, !stored.isEmpty else {
      return
    }
    set(key: backupKey, value: stored)
  }
}
