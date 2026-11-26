//
//  VerbBrowseView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct VerbBrowseView: View {
  @State private var search = VerbBrowseSearch()
  /// The starred verb whose swipe to remove awaits the learner's answer in an alert.
  @State private var verbToUnstar: VerbMapEntry?
  @State private var isConfirmingClear = false
  @State private var navigationPath = NavigationPath()
  @FocusState private var searchIsFocused: Bool
  /// Lets `search.isEngaged` go a moment after the focus. See `searchFocusChanged`.
  @State private var lingerTask: Task<Void, Never>?
  @State private var addressWasCopied = false
  @State private var addressNoteTask: Task<Void, Never>?
  /// The review card's verb and state, chosen once per opening of the app. See `chooseReviewCard`.
  @State private var reviewCard: ReviewCardState?
  @State private var reviewCardIsChosen = false
  @State private var appWasInBackground = false
  @Environment(AppRouter.self) private var router
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.scenePhase) private var scenePhase
  private let tryQuizTip = TryQuizTip()

  private var learnerVerbs: LearnerVerbStore { Current.learnerVerbs }

  private var settings: Settings { Current.settings }

  private static let isPadOrMac = UIDevice.current.userInterfaceIdiom == .pad

  // Hack: on iPad, a tap outside an empty search field ends the search at touch-down, before the
  // tap completes. A letter row that followed the focus vanished under the finger, so tapping á did
  // nothing. The row, and the recents, follow `search.isEngaged` instead, which lets go a moment
  // later. A focus regained meanwhile cancels the letting go.
  private func searchFocusChanged() {
    lingerTask?.cancel()
    lingerTask = nil
    guard !searchIsFocused else {
      search.setEngaged(true)
      return
    }
    search.fieldLostFocus()
    lingerTask = Task {
      try? await Task.sleep(for: Self.searchLingering)
      guard !Task.isCancelled else {
        return
      }
      search.setEngaged(false)
    }
  }

  private static let searchLingering = Duration.milliseconds(700)

  /// The field has let go of the focus with nothing typed, and the search may still be animating
  /// away: the span of the linger. On iPad that is a tap's touch-down outside the field.
  private var searchIsEnding: Bool {
    search.isEngaged && !searchIsFocused && !search.isSearching
  }

  // A tap that ends an empty search on iPad would push while the search is still animating away,
  // and UIKit drops such a push; see ViewControllerTransitions. A typed search does not end on that
  // tap, and on iPhone nothing is animating, so both push at once. Every push from this tab comes
  // through here: a row, the guess, My Verbs, the review card, and a link's verb.
  private func push(_ destination: VerbDestination) {
    guard searchIsEnding else {
      navigationPath.append(destination)
      return
    }
    Task {
      await ViewControllerTransitions.waitUntilIdle()
      navigationPath.append(destination)
    }
  }

  // On iPad a key's tap ends an empty search, and the search clears its text as it goes, so a
  // letter set meanwhile is lost. The letters wait for the search to be gone, in the order they
  // were tapped, then reopen it.
  private func insertLetter(_ letter: String) {
    guard search.typeLetter(letter, fieldIsFocused: searchIsFocused) else {
      return
    }
    Task {
      await ViewControllerTransitions.waitUntilIdle()
      search.releaseWaitingLetters()
      searchIsFocused = true
    }
  }

  /// Under "No verbs found": the guess, if any, then a line asking the learner to email a verb
  /// that the app lacks. It appears only when every lookup failed, a form's included, so the
  /// guess may come from a form too (tenjo guesses tener through tengo).
  private var failedSearchHelp: some View {
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
        .background(search.selection == guess.entry.infinitive ? Self.selectionColor : Color.clear)

        Divider()
          .padding(.leading)
      }

      Text(verbRequestText(query: search.trimmedText))
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
  }

  /// The request line, with the address as a `mailto:` link that carries the query.
  private func verbRequestText(query: String) -> AttributedString {
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

  private static let selectionColor = Color.customRed.opacity(0.2)

  private func rowBackground(_ row: VerbBrowseSearch.Row, index: Int) -> Color {
    row.id == search.selection ? Self.selectionColor : .zebraStripe(index)
  }

  private func moveKeyboardSelection(by offset: Int) {
    guard navigationPath.isEmpty else {
      return
    }
    search.moveSelection(by: offset)
  }

  /// Return opens the highlighted row or guess on any keyboard. With nothing highlighted, the iPad
  /// idiom, which a Mac running the app also reports, opens the first result, else the guess; the
  /// iPhone keyboard's Search key only lowers the keyboard, as it always has.
  private func openKeyboardSelection() {
    guard navigationPath.isEmpty, let destination = search.submit(opensFirstResult: Self.isPadOrMac) else {
      return
    }
    push(destination)
  }

  /// Command-F, the Find a Verb control and quick action, or a `search` link. Text that arrives
  /// with the request is shown as results, with the keyboard down so that they are visible. A
  /// request with no text, or with empty text, is for typing, so it focuses the field.
  private func openRequestedSearch() {
    guard let request = router.pendingSearch else {
      return
    }
    router.pendingSearch = nil
    let wantsKeyboard = search.request(request)
    Task {
      await showSearch(focused: wantsKeyboard)
    }
  }

  /// Pops to the list, then focuses the field or lets it go.
  private func showSearch(focused: Bool) async {
    if !navigationPath.isEmpty {
      navigationPath = NavigationPath()
      // Hack: focus requested while the pop animates sets the focus state without making the
      // field first responder, so typing goes nowhere. Wait out the animation. The yield lets
      // the pop begin, so that the wait has a transition to see.
      await Task.yield()
      await ViewControllerTransitions.waitUntilIdle()
    }
    searchIsFocused = focused
  }

  private static let reviewCardMaxWidth: CGFloat = 560

  /// Each launch, and each return from the background, offers the irregular verb whose key
  /// conjugation is longest overdue in the practice record, if any. The choice is made once per
  /// opening, so revealing a card does not swap it for the next verb due.
  private func chooseReviewCard() {
    reviewCardIsChosen = true
    guard settings.reviewCardSuppression == .off else {
      reviewCard = nil
      return
    }
    reviewCard = Current.practice.cardOffer().map { ReviewCardState(offer: $0) }
  }

  private func signalReviewCardShown() {
    guard reviewCard?.wasSignaled == false else {
      return
    }
    reviewCard?.wasSignaled = true
    Current.analytics.signal(name: .viewReviewCard)
  }

  private func revealReviewCard() {
    guard let reviewCard, !reviewCard.isRevealed else {
      return
    }
    Current.practice.recordReview(reviewCard.offer)
    // A reveal moves the verb's due key conjugations up a box, which can reach the third.
    Current.reportAchievements()
    Current.analytics.signal(name: .tapRevealReviewCard)
    withAnimation {
      self.reviewCard?.isRevealed = true
    }
  }

  private func openReviewCard() {
    guard let reviewCard else {
      return
    }
    push(VerbDestination(infinitive: reviewCard.offer.entry.infinitive, source: .reviewCard))
  }

  /// A card dismissed before its conjugations were seen was no review, so its due key
  /// conjugations return tomorrow in the same box.
  private func dismissReviewCard() {
    guard let reviewCard else {
      return
    }
    if !reviewCard.isRevealed {
      Current.practice.snooze(reviewCard.offer)
    }
    withAnimation {
      self.reviewCard = nil
    }
  }

  private func listHeading(_ text: String) -> some View {
    ListHeading(text)
      .padding(.horizontal)
      .padding(.top, Layout.defaultSpacing)
  }

  /// The starred verbs, then the recent ones not starred. A swipe removes a verb, its star and its
  /// last open alike, so that it leaves the list; a starred verb asks first, since its star was put
  /// there on purpose. Clear asks, then forgets every last open and keeps the stars. Neither
  /// forgets that a verb was opened, which the collections count.
  @ViewBuilder
  private var myVerbsList: some View {
    let starred = learnerVerbs.starredVerbs
    let recent = learnerVerbs.recentUnstarredVerbs
    if starred.isEmpty, recent.isEmpty {
      ContentUnavailableView(L.MyVerbs.emptyTitle, systemImage: "star", description: Text(L.MyVerbs.emptyDescription))
        .frame(maxHeight: .infinity)
        .accessibilityIdentifier("my_verbs_empty")
    } else {
      List {
        if !starred.isEmpty {
          Section {
            ForEach(starred, id: \.infinitive) { entry in
              myVerbRow(entry)
                .swipeActions(edge: .trailing) {
                  // Not .destructive: that role removes the row at once, before the learner answers.
                  Button {
                    verbToUnstar = entry
                  } label: {
                    Label(L.MyVerbs.remove, systemImage: "star.slash")
                  }
                  .tint(Color.customRed)
                }
            }
          } header: {
            ListHeading(L.MyVerbs.starred)
              .accessibilityIdentifier("my_verbs_starred_heading")
          }
        }
        if !recent.isEmpty {
          Section {
            ForEach(recent, id: \.infinitive) { entry in
              myVerbRow(entry)
                .swipeActions(edge: .trailing) {
                  Button(role: .destructive) {
                    withAnimation {
                      learnerVerbs.remove(entry.infinitive)
                    }
                  } label: {
                    Label(L.MyVerbs.remove, systemImage: "minus.circle")
                  }
                }
            }
          } header: {
            HStack(alignment: .firstTextBaseline) {
              ListHeading(L.MyVerbs.recent)
                .accessibilityIdentifier("my_verbs_recent_heading")
              Spacer()
              Button(L.MyVerbs.clearRecent) {
                isConfirmingClear = true
              }
              .font(.caption)
              .buttonStyle(.borderless)
              .tint(Color.customBlue)
              .accessibilityIdentifier("my_verbs_clear_recent")
            }
          }
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .accessibilityIdentifier("my_verbs_list")
      .alert(
        L.MyVerbs.unstarTitle(verb: verbToUnstar?.citationForm ?? ""),
        isPresented: Binding(get: { verbToUnstar != nil }, set: { if !$0 { verbToUnstar = nil } }),
        presenting: verbToUnstar
      ) { entry in
        Button(L.MyVerbs.unstarConfirm, role: .destructive) {
          withAnimation {
            learnerVerbs.remove(entry.infinitive)
          }
        }
        Button(role: .cancel) {}
      } message: { _ in
        Text(L.MyVerbs.unstarMessage)
      }
      .alert(L.MyVerbs.clearTitle, isPresented: $isConfirmingClear) {
        Button(L.MyVerbs.clearRecent, role: .destructive) {
          withAnimation {
            learnerVerbs.clearRecents()
          }
        }
        Button(role: .cancel) {}
      } message: {
        Text(L.MyVerbs.clearMessage)
      }
    }
  }

  private func myVerbRow(_ entry: VerbMapEntry) -> some View {
    Button {
      push(VerbDestination(infinitive: entry.infinitive, source: .myVerbs))
    } label: {
      VerbRowLabel(entry: entry)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("my_verb_row_\(entry.infinitive)")
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.clear)
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        // My Verbs is a List of its own, because only a List's rows can be swiped to delete.
        if search.shown == .myVerbs {
          myVerbsList
        } else {
          ScrollViewReader { proxy in
            let shown = search.shown
            let rows = search.rows
            ScrollView {
              if shown == .recents {
                listHeading(L.MyVerbs.recent)
                  .id("top")
                  .accessibilityIdentifier("recent_verbs_heading")
              } else {
                listHeading(L.BrowseVerbs.verbCount(count: rows.count))
                  .id("top")
                  // Stable launch-screen leaf anchor for the ios-build-verify skill's
                  // wait-for-render poll (FIRST_SCREEN_ID); a leaf, not a container, to
                  // avoid SwiftUI AXTree identifier rollover onto descendants.
                  .accessibilityIdentifier("browse_verb_count")
              }

              if shown == .everyVerb {
                TipView(tryQuizTip)
                  .padding(.horizontal)
                  .padding(.top, Layout.defaultSpacing)
              }

              if let reviewCard, shown == .everyVerb, settings.reviewCardSuppression == .off {
                ReviewCardView(
                  entry: reviewCard.offer.entry,
                  daysSinceActivity: reviewCard.offer.daysSinceActivity,
                  wasLookedUp: reviewCard.offer.wasLookedUp,
                  isRevealed: reviewCard.isRevealed,
                  reveal: revealReviewCard,
                  open: openReviewCard,
                  dismiss: dismissReviewCard
                )
                .frame(maxWidth: horizontalSizeClass == .regular ? Self.reviewCardMaxWidth : .infinity)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, Layout.defaultSpacing)
                .transition(.opacity)
                .onAppear {
                  signalReviewCardShown()
                }
              }

              if search.awaitsIndex {
                // A form may yet match, once the index is built. Saying "No verbs found" now
                // would be premature.
                ProgressView()
                  .padding(.top, Layout.tripleDefaultSpacing)
                  .accessibilityIdentifier("search_awaiting_index")
              } else if search.hasFailed {
                ContentUnavailableView(L.BrowseVerbs.searchNoResults, systemImage: "magnifyingglass")
                  .padding(.top, Layout.tripleDefaultSpacing)

                failedSearchHelp
                  .readingWidth()
              } else if horizontalSizeClass == .regular {
                // iPad / regular width: reflow the rows into an adaptive grid of
                // carded cells (≈2 columns portrait, ≈3–4 landscape). The same
                // `navigationDestination(for: VerbDestination)` renders the pushed `VerbView`.
                LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
                  ForEach(rows) { row in
                    Button {
                      push(search.open(row))
                    } label: {
                      VerbGridCell(entry: row.entry, matchLines: search.matchLines(of: row))
                        .card()
                        .overlay {
                          if row.id == search.selection {
                            RoundedRectangle(cornerRadius: Layout.defaultSpacing)
                              .stroke(Color.customRed, lineWidth: 2)
                          }
                        }
                    }
                    .buttonStyle(.plain)
                    // Screenshot-driver anchor (scripts/take_screenshots.sh taps
                    // `verb_row_ser`). Both size-class branches carry it — the iPad
                    // renders this grid, the iPhone the stack below.
                    .accessibilityIdentifier("verb_row_\(row.id)")
                  }
                }
                .padding(.horizontal)
                .padding(.top, Layout.defaultSpacing)
              } else {
                LazyVStack(spacing: 0) {
                  ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    // A real `Button`, not `.onTapGesture`: `.isButton` trait, press highlight,
                    // and stronger VoiceOver semantics. Not a `NavigationLink`, because the open
                    // reports its search; the stack's `navigationDestination(for:
                    // VerbDestination)` renders the pushed `VerbView`.
                    Button {
                      push(search.open(row))
                    } label: {
                      VerbRowLabel(entry: row.entry, matchLines: search.matchLines(of: row))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("verb_row_\(row.id)")
                    .background(rowBackground(row, index: index))
                    Divider().padding(.leading)
                  }
                }
              }
            }
            .onChange(of: search.sort) {
              proxy.scrollTo("top", anchor: .top)
            }
            .onChange(of: search.selection) { _, selection in
              if let selection {
                proxy.scrollTo(selection)
              }
            }
          }
        }

        Divider()

        // A keyboard toolbar never appears for the navigation bar's search field (iOS 26), so
        // the letter row takes the sort picker's place while the field is focused, which puts
        // it directly above the keyboard. Search ignores the sort order and the picker, so the
        // picker is disabled while the field holds a search and the keyboard is down.
        if search.isEngaged {
          SpanishLetterKeyRow { letter in
            insertLetter(letter)
          }
          .padding(.vertical, Layout.defaultSpacing)
        } else {
          SortPicker(selection: Binding(get: { search.listMode }, set: { search.setListMode($0) }))
            .readingWidth()
            .padding()
            .disabled(search.isSearching)
            .accessibilityIdentifier("verb_list_mode_picker")
        }
      }
      .onChange(of: search.sort) {
        Current.settings.verbSort = search.sort
      }
      .background(Color.customBackground.ignoresSafeArea())
      .searchable(
        text: Binding(get: { search.text }, set: { search.setText($0) }),
        placement: BrowseLayout.searchPlacement,
        prompt: L.BrowseVerbs.searchPromptVerbConjugationOrMeaning
      )
      .searchFocused($searchIsFocused)
      .onChange(of: searchIsFocused) {
        searchFocusChanged()
      }
      // The arrow keys are the list's only while the field is focused and the list is on screen,
      // so that a page pushed over the list keeps its own arrow keys.
      .onChange(of: searchIsFocused && navigationPath.isEmpty, initial: true) { _, wantsArrowKeys in
        if wantsArrowKeys {
          VerbSearchArrowKeys.install { offset in
            moveKeyboardSelection(by: offset)
          }
        } else {
          VerbSearchArrowKeys.uninstall()
        }
      }
      .onSubmit(of: .search) {
        openKeyboardSelection()
      }
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .navigationTitle(L.BrowseVerbs.localizedTitle)
      // A verb page's pill and related verbs lead to a model's page and a full list without
      // leaving this tab, so a learner who arrived from a widget or a link reaches them too.
      .verbPageDestinations()
      .onChange(of: router.pendingVerb, initial: true) { _, destination in
        guard let destination else { return }
        push(destination)
        router.pendingVerb = nil
      }
      // A search left with text in the field when the app goes to the background has ended. A
      // return from the background is a new opening, which may offer a review card.
      .onChange(of: scenePhase) {
        switch scenePhase {
        case .background:
          appWasInBackground = true
          search.appEnteredBackground()
        case .active where appWasInBackground:
          appWasInBackground = false
          chooseReviewCard()
        default:
          break
        }
      }
      .onChange(of: settings.reviewCardSuppression) {
        if settings.reviewCardSuppression == .off, reviewCard == nil {
          chooseReviewCard()
        }
      }
      .onChange(of: router.pendingSearch, initial: true) {
        openRequestedSearch()
      }
      .onAppear {
        Current.analytics.signal(name: .viewVerbBrowseView)
        Current.reviewPrompter.promptableActionHappened()
        if !reviewCardIsChosen {
          chooseReviewCard()
        }
      }
      // Loading the conjugation map and indexing its forms took 6.0 to 6.2 seconds at first touch
      // in a Debug build in the simulator (2026-11-26), so it happens off the main actor, begun at
      // launch by ConjugarApp. A search meanwhile matches infinitives and glosses, and runs again
      // when the index arrives.
      .task {
        let index = await Task.detached(priority: .userInitiated) {
          ConjugationIndex.bundled
        }.value
        search.indexIsReady(index)
      }
    }
    .pushesVerbPages(onto: $navigationPath)
  }
}

/// The review card on screen: its verb, chosen once per opening, and what the learner has done.
private struct ReviewCardState {
  let offer: PracticeStore.CardOffer
  var isRevealed = false
  var wasSignaled = false
}

#Preview {
  VerbBrowseView()
    .environment(AppRouter())
}
