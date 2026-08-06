//
//  TutorChatHistory.swift
//  Conjugar
//
//  Persists the tutor conversation so it survives tab switches and app relaunches.
//  Conjugar's `GetterSetter` stores strings only, so the `[TutorMessage]` array is
//  JSON-encoded to a string here rather than via a Codable convenience.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

enum TutorChatHistory {
  static let storageKey = "tutorChatHistory"
  static let maxMessages = 200

  static func save(_ messages: [TutorMessage], getterSetter: GetterSetter) {
    let capped = messages.count > maxMessages ? Array(messages.suffix(maxMessages)) : messages
    guard
      let data = try? JSONEncoder().encode(capped),
      let json = String(data: data, encoding: .utf8) else {
      return
    }
    getterSetter.set(key: storageKey, value: json)
  }

  static func load(getterSetter: GetterSetter) -> [TutorMessage] {
    guard
      let json = getterSetter.get(key: storageKey),
      let data = json.data(using: .utf8),
      let messages = try? JSONDecoder().decode([TutorMessage].self, from: data) else {
      return []
    }
    return messages
  }

  static func clear(getterSetter: GetterSetter) {
    getterSetter.set(key: storageKey, value: "")
  }

  static func isEmpty(getterSetter: GetterSetter) -> Bool {
    load(getterSetter: getterSetter).isEmpty
  }
}
