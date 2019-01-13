//
//  InfoVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class InfoVC: UIViewController, UITextViewDelegate {
  weak var infoDelegate: InfoDelegate?
  var infoString: NSAttributedString?
  private var analyticsService: AnalyticsServiceable?

  var infoView: InfoView {
    if let castedView = view as? InfoView {
      return castedView
    } else {
      fatalError(fatalCastMessage(viewController: InfoVC.self, view: InfoView.self))
    }
  }

  convenience init(analyticsService: AnalyticsServiceable) {
    self.init()
    self.analyticsService = analyticsService
  }

  override func loadView() {
    let infoView: InfoView
    infoView = InfoView(frame: UIScreen.main.bounds)
    guard let infoString = infoString else {
      fatalError("InfoVC's infoString property is nil.")
    }
    infoView.info.attributedText = infoString
    infoView.info.delegate = self
    infoView.info.contentOffset = CGPoint.zero
    view = infoView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    analyticsService?.recordVisitation(viewController: "\(InfoVC.self)")
  }

  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
    let http = "http"
    if URL.absoluteString.prefix(http.count) == http {
      return true
    } else {
      navigationController?.popViewController(animated: true)
      infoDelegate?.infoSelectionDidChange(newHeading: URL.absoluteString)
      return false
    }
  }
}
