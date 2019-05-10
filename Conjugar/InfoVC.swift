//
//  InfoVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class InfoVC: UIViewController, UITextViewDelegate {
  private weak var infoDelegate: InfoDelegate?
  private let infoString: NSAttributedString
  private let analyticsService: AnalyticsServiceable

  var infoView: InfoView {
    if let castedView = view as? InfoView {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: InfoView.self))
    }
  }

  init(analyticsService: AnalyticsServiceable, infoString: NSAttributedString, infoDelegate: InfoDelegate) {
    self.analyticsService = analyticsService
    self.infoString = infoString
    self.infoDelegate = infoDelegate
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    UIViewController.fatalErrorNotImplemented()
  }

  override func loadView() {
    let infoView: InfoView
    infoView = InfoView(frame: UIScreen.main.bounds)
    infoView.info.attributedText = infoString
    infoView.info.delegate = self
    infoView.info.contentOffset = CGPoint.zero
    view = infoView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    analyticsService.recordVisitation(viewController: "\(InfoVC.self)")
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
