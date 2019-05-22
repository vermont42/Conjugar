//
//  UIColorExtension.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/22/19.
//  Borrowed from: https://stackoverflow.com/a/48610603/8248798
//

import UIKit

extension UIColor {
  static func == (l: UIColor, r: UIColor) -> Bool {
    var l_red = CGFloat(0); var l_green = CGFloat(0); var l_blue = CGFloat(0); var l_alpha = CGFloat(0)
    guard l.getRed(&l_red, green: &l_green, blue: &l_blue, alpha: &l_alpha) else { return false }
    var r_red = CGFloat(0); var r_green = CGFloat(0); var r_blue = CGFloat(0); var r_alpha = CGFloat(0)
    guard r.getRed(&r_red, green: &r_green, blue: &r_blue, alpha: &r_alpha) else { return false }
    return l_red == r_red && l_green == r_green && l_blue == r_blue && l_alpha == r_alpha
  }
}
