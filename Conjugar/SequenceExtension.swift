//
//  SequenceExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

// Swift 3

extension Sequence {
  func shuffled() -> [Iterator.Element] {
    var result = Array(self)
    result.shuffle()
    return result
  }
}

// Swift 4

//extension Sequence {
//  func shuffled() -> [Element] {
//    var result = Array(self)
//    result.shuffle()
//    return result
//  }
//}
