//
//  NSCoderExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/11/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Foundation

extension NSCoder {
  static func fatalErrorNotImplemented() -> Never {
    fatalError("init(coder:) has not been implemented")
  }
}
