//
//  FailedSearchHelp.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// Under "No verbs found": the guess, if any, then a line asking the learner to email a verb
/// that the app lacks. It appears only when every lookup failed, a form's included, so the
/// guess may come from a form too (tenjo guesses tener through tengo).
struct FailedSearchHelp: View {
  let search: VerbBrowseSearch
  /// The tab's one push, which waits when a search is ending.
  let push: (VerbDestination) -> Void
  @State private var addressWasCopied = false
  @State private var addressNoteTask: Task<Void, Never>?

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      if let guess = search.guess {
        Text(L.BrowseVerbs.guessIntro)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
          .accessibilityIdentifier("search_guess_intro")

        Button {
          push(search.openGuess(guess))
        } label: {
          VerbRowLabel(entry: guess.entry, matchLines: search.matchLines(of: guess))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("search_guess_\(guess.entry.infinitive)")
        .background(search.selection == guess.entry.infinitive ? Color.keyboardSelection : Color.clear)

        Divider()
          .padding(.leading)
      }

      Text(Self.verbRequestText(query: search.trimmedText))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .tint(Color.customBlue)
        .padding(.horizontal)
        .padding(.top, Layout.defaultSpacing)
        .accessibilityIdentifier("verb_request_link")
        .environment(\.openURL, OpenURLAction { url in
          addressNoteTask?.cancel()
          addressNoteTask = Task {
            await openVerbRequest(url)
          }
          return .handled
        })

      if addressWasCopied {
        Text(L.BrowseVerbs.addressCopied)
          .font(.footnote)
          .foregroundStyle(Color.customYellow)
          .padding(.horizontal)
          .transition(.opacity)
          .accessibilityIdentifier("address_copied_note")
      }
    }
    // Without a guess row to fill it, the stack would shrink to the request line and center it.
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, Layout.defaultSpacing)
    .onDisappear {
      addressNoteTask?.cancel()
      addressNoteTask = nil
    }
  }

  /// The request line, with the address as a `mailto:` link that carries the query.
  private static func verbRequestText(query: String) -> AttributedString {
    let address = URL.developerEmail
    var text = AttributedString(L.BrowseVerbs.verbRequest(query: query, address: address))
    if
      let range = text.range(of: address, options: .backwards),
      let url = URL.mailto(address, subject: L.BrowseVerbs.verbRequestSubject(query: query), body: L.BrowseVerbs.verbRequestBody(query: query)) {
      text[range].link = url
    }
    return text
  }

  /// A device with no email app, such as the simulator, cannot open the link, so the address
  /// goes to the clipboard instead of nowhere, and a note says so for four seconds. A second tap
  /// cancels the first's task, so that the note stays its full four seconds.
  private func openVerbRequest(_ url: URL) async {
    guard !(await UIApplication.shared.open(url)) else {
      return
    }
    UIPasteboard.general.string = URL.developerEmail
    AccessibilityNotification.Announcement(L.BrowseVerbs.addressCopied).post()
    withAnimation {
      addressWasCopied = true
    }
    try? await Task.sleep(for: .seconds(4))
    guard !Task.isCancelled else {
      return
    }
    withAnimation {
      addressWasCopied = false
    }
  }
}
