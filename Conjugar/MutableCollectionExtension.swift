//
//  MutableCollectionExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

// Swift 3

//extension MutableCollection where Indices.Iterator.Element == Index {
//  mutating func shuffle() {
//    let c = count
//    guard c > 1 else { return }
//
//    for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
//      let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
//      guard d != 0 else { continue }
//      let i = index(firstUnshuffled, offsetBy: d)
//      swap(&self[firstUnshuffled], &self[i])
//    }
//  }
//}

// Swift 4

extension MutableCollection {
  mutating func shuffle() {
    let c = count
    guard c > 1 else { return }
    
    for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
      let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
      let i = index(firstUnshuffled, offsetBy: d)
      swapAt(firstUnshuffled, i)
    }
  }
}

