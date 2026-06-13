//
//  CloudCommunGetter.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/18/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import CloudKit
import MessageUI
import UIKit

struct CloudCommunGetter: CommunGetter {
  func getCommunication() async -> Commun? {
    let predicate = NSPredicate(format: "isCurrent == 1")
    let query = CKQuery(recordType: "Communs", predicate: predicate)
    let containerIdentifier = "iCloud.biz.Conjugar"

    let record: CKRecord
    do {
      let (matchResults, _) = try await CKContainer(identifier: containerIdentifier).publicCloudDatabase.records(matching: query)
      guard let firstResult = matchResults.first else {
        return nil
      }
      record = try firstResult.1.get()
    } catch {
      return nil
    }

    let separator = "|"

    guard
      let titleString = record["title"] as? String,
      let titleDict = dictFromString(string: titleString, primarySeparator: separator),
      let contentString = record["content"] as? String,
      let contentDict = dictFromString(string: contentString, primarySeparator: separator),
      let okayTitleString = record["okayTitle"] as? String,
      let okayTitleDict = dictFromString(string: okayTitleString, primarySeparator: separator),
      let cancelTitleString = record["cancelTitle"] as? String,
      let cancelTitleDict = dictFromString(string: cancelTitleString, primarySeparator: separator),
      let actionTitleString = record["actionTitle"] as? String,
      let actionTitleDict = dictFromString(string: actionTitleString, primarySeparator: separator),
      let typeString = record["type"] as? String,
      let cloudSchemaVersion = record["version"] as? Int,
      let imageAsset = record["image"] as? CKAsset,
      let imageFileUrl = imageAsset.fileURL,
      let imageData = try? Data(contentsOf: imageFileUrl),
      let image = UIImage(data: imageData),
      let imageLabelString = record["imageLabel"] as? String,
      let imageLabelDict = dictFromString(string: imageLabelString, primarySeparator: separator),
      let identifier = record["identifier"] as? Int
    else {
      return nil
    }

    let typeElements = typeString.components(separatedBy: separator)
    let typeFirstElement = "\(typeElements[0])"

    var type: Commun.CommunType?
    switch typeFirstElement {
    case "newVersion":
      guard
        typeElements.count > 1,
        let cloudVersion = Double(typeElements[1]),
        let appVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        let appVersion = Double(appVersionString),
        let openUrlClosure = openUrlClosure(urlString: "https://itunes.apple.com/\(Current.locale.regionCode)/app/conjugar/id1236500467")
      else {
        return nil
      }

      let alreadyUpdated = appVersion >= cloudVersion

      type = Commun.CommunType.newVersion(
        okayTitle: okayTitleDict,
        actionTitle: actionTitleDict,
        cancelTitle: cancelTitleDict,
        action: openUrlClosure,
        alreadyUpdated: alreadyUpdated
      )

    case "website":
      guard
        typeElements.count > 1,
        let openUrlClosure = openUrlClosure(urlString: typeElements[1])
      else {
        return nil
      }

      type = Commun.CommunType.website(actionTitle: actionTitleDict, cancelTitle: cancelTitleDict, action: openUrlClosure)

    case "information":
      type = Commun.CommunType.information(okayTitle: okayTitleDict)

    case "email":
      if let sendEmailClosure = Emailer.shared.sendEmailClosure {
        type = Commun.CommunType.email(actionTitle: actionTitleDict, cancelTitle: cancelTitleDict, action: sendEmailClosure)
      }

    default:
      break
    }

    let appSchemaVersion = 0
    if
      let type = type,
      appSchemaVersion >= cloudSchemaVersion
    {
      return Commun(title: titleDict, image: image, imageLabel: imageLabelDict, content: contentDict, type: type, identifier: identifier)
    }

    return nil
  }

  private func dictFromString(string: String, primarySeparator: String) -> [String: String]? {
    guard !string.isEmpty else {
      return nil
    }
    let variants = string.components(separatedBy: primarySeparator)
    guard !variants.isEmpty else {
      return nil
    }
    var dict: [String: String] = [:]
    let secondarySeparator = "="
    for variant in variants {
      let components = variant.components(separatedBy: secondarySeparator)
      guard
        components.count == 2,
        ["en", "es"].contains(components[0])
      else {
        continue
      }
      dict[components[0]] = components[1]
    }

    if !dict.isEmpty {
      return dict
    } else {
      return nil
    }
  }
}
