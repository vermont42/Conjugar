//
//  QRCode.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import UIKit

/// QR codes made on the device, so that a practice set needs no server.
enum QRCode {
  /// Black modules on white, each `moduleSize` points square, with no smoothing between them.
  /// Medium error correction survives a projector's glare and a phone held at an angle, and a
  /// hundred-verb list still fits well inside its capacity.
  nonisolated static func image(for text: String, moduleSize: CGFloat = 10) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(text.utf8)
    filter.correctionLevel = "M"
    guard
      let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: moduleSize, y: moduleSize)),
      let cgImage = CIContext().createCGImage(output, from: output.extent)
    else {
      return nil
    }
    return UIImage(cgImage: cgImage)
  }
}
