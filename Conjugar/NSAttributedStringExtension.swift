//
//  NSAttributedStringExtension.swift
//  Conjugar
//
//  Created by Adams, Josh on 5/13/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
  let result = NSMutableAttributedString()
  result.append(left)
  result.append(right)
  return result
}

