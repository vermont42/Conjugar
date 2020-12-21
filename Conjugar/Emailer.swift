//
//  Emailer.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/20/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import MessageUI

struct Emailer {
  static let shared = Emailer()
  private let delegāte = EmailDelegate()

  var sendEmailClosure: (() -> ())? {
    if MFMailComposeViewController.canSendMail() {
      return {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = delegāte
        mail.setToRecipients(["vermontcoder@gmail.com"])
        mail.setSubject("Conjugar")
        UIApplication.topViewController()?.present(mail, animated: true)
      }
    } else {
      return nil
    }
  }

  private class EmailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
      controller.dismiss(animated: true)
    }
  }
}
