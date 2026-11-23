//
//  VerbSearchArrowKeys.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import UIKit

// Hack: the arrow keys reach a focused search field as cursor movement, which outranks
// .onKeyPress, .keyboardShortcut, and .commands alike. A UIKeyCommand that asks for priority over
// system behavior is the one way to see them. It must sit on a responder above the field, so it
// goes on the window's root view controller, and its action is defined on every view controller
// because SwiftUI's own controllers are the ones the chain reaches. It is installed only while the
// verb search field is focused, so that no other text field, such as the quiz's or the tutor's,
// loses its arrow keys.
enum VerbSearchArrowKeys {
  private static var move: ((Int) -> Void)?
  private static weak var host: UIViewController?

  private static let commands: [UIKeyCommand] = {
    let down = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(UIViewController.verbSearchMoveDown(_:)))
    let up = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(UIViewController.verbSearchMoveUp(_:)))
    for command in [down, up] {
      command.wantsPriorityOverSystemBehavior = true
    }
    return [down, up]
  }()

  static func install(move: @escaping (Int) -> Void) {
    self.move = move
    guard host == nil, let root = keyWindowRoot else {
      return
    }
    commands.forEach(root.addKeyCommand)
    host = root
  }

  static func uninstall() {
    move = nil
    commands.forEach { host?.removeKeyCommand($0) }
    host = nil
  }

  fileprivate static func handle(_ offset: Int) {
    move?(offset)
  }

  private static var keyWindowRoot: UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
  }
}

extension UIViewController {
  @objc fileprivate func verbSearchMoveDown(_ sender: UIKeyCommand) {
    VerbSearchArrowKeys.handle(1)
  }

  @objc fileprivate func verbSearchMoveUp(_ sender: UIKeyCommand) {
    VerbSearchArrowKeys.handle(-1)
  }
}
