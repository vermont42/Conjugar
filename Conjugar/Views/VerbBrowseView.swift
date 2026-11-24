//
//  VerbBrowseView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct VerbBrowseView: View {
  static let englishTitle = "Verbs"

  /// The sort order of the full list. It survives a visit to My Verbs and is saved in Settings.
  @State private var sort: VerbSort = Current.settings.verbSort
  /// The picker's choice: a sort order, or My Verbs.
  @State private var listMode = VerbListMode(sort: Current.settings.verbSort)
  /// The starred verb whose swipe to delete awaits the learner's answer in an alert.
  @State private var verbToUnstar: VerbMapEntry?
  @State private var navigationPath = NavigationPath()
  @State private var searchText = ""
  @FocusState private var searchIsFocused: Bool
  /// Follows `searchIsFocused`, but lets go of it a moment later. See `searchFocusChanged`.
  @State private var searchIsEngaged = false
  /// The row that Return opens and the arrow keys move, on iPad and Mac keyboards. Nil until an
  /// arrow is pressed, and cleared whenever the query changes.
  @State private var keyboardSelection: Int?
  /// The closest verb to a query that found nothing, or nil. See `VerbSearch.guess`.
  @State private var guess: VerbSearch.Guess?
  @State private var addressWasCopied = false
  /// The ranked matches behind `filteredVerbs` while searching, which say each row's match kind
  /// for `finishSearch`. Empty when the field is.
  @State private var searchMatches: [VerbSearch.Match] = []
  @State private var searchTracker = SearchTracker()
  /// When the field last lost focus, or nil while it has it. See `push(_:)`.
  @State private var searchFocusLostAt: Date?
  /// The review card's verb and state, chosen once per opening of the app. See `chooseReviewCard`.
  @State private var reviewCard: ReviewCardState?
  @State private var reviewCardIsChosen = false
  @State private var appWasInBackground = false
  @Environment(AppRouter.self) private var router
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.scenePhase) private var scenePhase
  private let tryQuizTip = TryQuizTip()

  /// Both sort orders, computed once.
  private static let verbsBySort: [VerbSort: [VerbMapEntry]] = {
    let entries = VerbMap.shared.entries.values
    return Dictionary(uniqueKeysWithValues: VerbSort.allCases.map { ($0, $0.sorted(entries)) })
  }()

  private var verbs: [VerbMapEntry] { Self.verbsBySort[sort] ?? [] }

  /// The current sort filtered by the search query, materialized into `@State` and
  /// recomputed only when `searchText` or `sort` changes — rather than as a
  /// computed property `body` scanned twice per render. Seeded to the initial sort's
  /// full list so the first frame isn't a "0 verbs" flash.
  @State private var filteredVerbs: [VerbMapEntry] = Self.verbsBySort[Current.settings.verbSort] ?? []

  /// Refilter for the current `searchText` + `sort`, firing the no-results sad trombone
  /// here — the one-shot search transition — instead of inside `body`. An empty query lists
  /// every verb in the chosen sort order. Otherwise `VerbSearch` ranks the matches, by kind and
  /// then frequency, whatever the sort order.
  private func recomputeFilteredVerbs() {
    guess = nil
    guard isSearching else {
      searchMatches = []
      filteredVerbs = verbs
      return
    }
    let matches = VerbSearch.matches(for: searchText, in: verbs)
    if matches.isEmpty {
      Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true)
      guess = VerbSearch.guess(for: searchText, in: verbs)
    }
    searchMatches = matches
    filteredVerbs = matches.map(\.entry)
  }

  private var trimmedSearchText: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var isSearching: Bool {
    !trimmedSearchText.isEmpty
  }

  private var learnerVerbs: LearnerVerbStore { Current.learnerVerbs }

  private var settings: Settings { Current.settings }

  /// The verbs last opened, listed while the field is focused and empty, before anything is typed.
  /// They follow `searchIsEngaged`, not the focus, for the reason `searchFocusChanged` gives.
  private var showsRecents: Bool {
    searchIsEngaged && !isSearching && !learnerVerbs.recentVerbs.isEmpty
  }

  /// My Verbs replaces the full list only while nothing is typed. Search ignores the picker, as it
  /// ignores the sort order, so typing searches every verb.
  private var showsMyVerbs: Bool {
    listMode == .myVerbs && !isSearching && !showsRecents
  }

  /// The rows the list shows, which Return and the arrow keys move through: the recent verbs, or
  /// the search's results, or every verb in the sort order.
  private var shownVerbs: [VerbMapEntry] {
    showsRecents ? learnerVerbs.recentVerbs : filteredVerbs
  }

  /// The source of a row opened with nothing typed. Settled as the row is drawn, because on iPad
  /// a tap can take the focus from the field, and with it the recents, before the row's action runs.
  private var browseSource: AnalyticsSource {
    showsRecents ? .recent : .browse
  }

  private static let isPadOrMac = UIDevice.current.userInterfaceIdiom == .pad

  // iPadOS 26 shrinks .automatic search into a toolbar button that ignores a programmatic
  // .searchFocused, so a letter key could not reopen it. A drawer that stays put accepts it.
  // The iPhone keeps .automatic and looks as before.
  private var searchPlacement: SearchFieldPlacement {
    Self.isPadOrMac ? .navigationBarDrawer(displayMode: .always) : .automatic
  }

  // Hack: on iPad, a tap outside an empty search field ends the search at touch-down, before the
  // tap completes. A letter row that followed the focus vanished under the finger, so tapping á did
  // nothing. The row follows this instead, which lets go a moment later.
  private func searchFocusChanged() {
    if !searchIsFocused {
      searchTracker.fieldClosed()
    }
    guard !searchIsFocused else {
      searchIsEngaged = true
      searchFocusLostAt = nil
      return
    }
    searchFocusLostAt = .now
    Task {
      try? await Task.sleep(for: Self.searchLingering)
      if !searchIsFocused {
        searchIsEngaged = false
      }
    }
  }

  private static let searchLingering = Duration.milliseconds(700)

  // A tap that ends an empty search on iPad would push while the search is still animating away,
  // and UIKit drops such a push; see ViewControllerTransitions. A typed search does not end on that
  // tap, and on iPhone nothing is animating, so both push at once.
  private func push(_ destination: VerbDestination) {
    guard !isSearching, searchFocusLostAt != nil else {
      navigationPath.append(destination)
      return
    }
    Task {
      await ViewControllerTransitions.waitUntilIdle()
      navigationPath.append(destination)
    }
  }

  /// Opens the row at `index` in `shownVerbs`. `wasSearching` and `browseSource` are read when
  /// the row is drawn, so that a tap that changes the field first cannot change the source.
  private func openRow(at index: Int, wasSearching: Bool, browseSource: AnalyticsSource) {
    let rows = shownVerbs
    guard rows.indices.contains(index) else {
      return
    }
    let infinitive = rows[index].infinitive
    guard wasSearching, searchMatches.indices.contains(index) else {
      push(VerbDestination(infinitive: infinitive, source: browseSource))
      return
    }
    let match = searchMatches[index]
    if let search = searchTracker.finish() {
      signal(.opened(query: search.query, source: search.source, resultCount: searchMatches.count, kind: match.kind, position: index))
    }
    push(VerbDestination(infinitive: infinitive, source: .search, marks: marks(of: match.forms)))
  }

  private func openGuess(_ guess: VerbSearch.Guess) {
    if let search = searchTracker.finish() {
      signal(.openedGuess(query: search.query, source: search.source))
    }
    push(VerbDestination(infinitive: guess.entry.infinitive, source: .searchGuess, marks: marks(of: guess.form.map { [$0] } ?? [])))
  }

  private var hiddenPersons: Set<DisplayPersonNumber> {
    Current.settings.secondSingularBrowse.hiddenPersons
  }

  private func marks(of forms: [MatchedForm]) -> Set<ConjugationCell> {
    Set(MatchedForm.shown(forms, hiding: hiddenPersons).flatMap { $0.shownCells(hiding: hiddenPersons) })
  }

  /// What the row at `index` matched, one line per form: "hablo: Presente de Indicativo (yo)".
  /// Empty for a match on the infinitive or a gloss, and for the unsearched list.
  private func matchLines(at index: Int, wasSearching: Bool) -> [String] {
    guard wasSearching, searchMatches.indices.contains(index) else {
      return []
    }
    return MatchedForm.shown(searchMatches[index].forms, hiding: hiddenPersons).map { $0.line(hiding: hiddenPersons) }
  }

  /// A search that ended with nothing opened: cleared, or left in the background.
  private func signalEndedSearch(_ search: SearchTracker.Search) {
    signal(.ended(query: search.query, source: search.source, matches: VerbSearch.matches(for: search.query, in: verbs)))
  }

  private func signal(_ report: SearchReport) {
    Current.analytics.signal(name: .finishSearch, parameters: report.parameters)
  }

  // On iPad a key's tap ends an empty search, and the search clears its text as it goes, so a
  // letter set meanwhile is lost. The letter waits for the search to be gone, then reopens it.
  private func insertLetter(_ letter: String) {
    guard !searchIsFocused else {
      searchText.append(letter)
      return
    }
    Task {
      await ViewControllerTransitions.waitUntilIdle()
      searchText.append(letter)
      searchIsFocused = true
    }
  }

  /// Under "No verbs found": the guess, if any, then a line asking the learner to email a verb
  /// that the app lacks. It appears only when every lookup failed, a form's included, so the
  /// guess may come from a form too (tenjo guesses tener through tengo).
  private var failedSearchHelp: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      if let guess {
        Text(L.BrowseVerbs.guessIntro)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
          .accessibilityIdentifier("search_guess_intro")

        Button {
          openGuess(guess)
        } label: {
          VerbRowLabel(entry: guess.entry, matchLines: guess.form.map { [$0.line(hiding: hiddenPersons)] } ?? [])
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("search_guess_\(guess.entry.infinitive)")
        .background(keyboardSelection == 0 ? Self.selectionColor : Color.clear)

        Divider()
          .padding(.leading)
      }

      Text(verbRequestText(query: trimmedSearchText))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .tint(Color.customBlue)
        .padding(.horizontal)
        .padding(.top, Layout.defaultSpacing)
        .accessibilityIdentifier("verb_request_link")
        .environment(\.openURL, OpenURLAction { url in
          Task {
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
  /// goes to the clipboard instead of nowhere, and a note says so for four seconds.
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
    withAnimation {
      addressWasCopied = false
    }
  }

  private static let selectionColor = Color.customRed.opacity(0.2)

  private func rowBackground(index: Int) -> Color {
    if index == keyboardSelection {
      return Self.selectionColor
    }
    return index.isMultiple(of: 2) ? Color.clear : Color.customYellow.opacity(0.03)
  }

  /// The rows that Return and the arrow keys move through: the verbs as listed, or the guess
  /// when a search found nothing.
  private var keyboardTargetCount: Int {
    if filteredVerbs.isEmpty, isSearching, guess != nil {
      return 1
    }
    return shownVerbs.count
  }

  private func moveKeyboardSelection(by offset: Int) {
    guard navigationPath.isEmpty else {
      return
    }
    keyboardSelection = Self.keyboardSelection(after: keyboardSelection, moving: offset, count: keyboardTargetCount)
  }

  /// The first arrow press lands on the first result, and the selection stops at either end
  /// rather than wrapping. Down moves in reading order, in the iPad's grid too.
  nonisolated static func keyboardSelection(after current: Int?, moving offset: Int, count: Int) -> Int? {
    guard count > 0 else {
      return nil
    }
    guard let current else {
      return offset > 0 ? 0 : nil
    }
    return min(max(current + offset, 0), count - 1)
  }

  private func openKeyboardSelection() {
    guard navigationPath.isEmpty else {
      return
    }
    guard let index = keyboardSelection ?? (isSearching ? 0 : nil) else {
      return
    }
    if filteredVerbs.isEmpty, index == 0, let guess {
      openGuess(guess)
    } else {
      openRow(at: index, wasSearching: isSearching, browseSource: browseSource)
    }
  }

  /// Command-F, the Find a Verb control and quick action, or a `search` link. Text that arrives
  /// with the request is shown as results, with the keyboard down so that they are visible. A
  /// request with no text, or with empty text, is for typing, so it focuses the field.
  private func openRequestedSearch() {
    guard let request = router.pendingSearch else {
      return
    }
    router.pendingSearch = nil
    if let text = request.text {
      if let ended = searchTracker.fieldOpened(from: request.source) {
        signalEndedSearch(ended)
      }
      searchText = text
      // onChange(of: searchText) does not fire when the text is unchanged, and the request
      // still begins a search.
      _ = searchTracker.textChanged(to: text)
    }
    let wantsKeyboard = request.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    Task {
      await showSearch(focused: wantsKeyboard)
    }
  }

  /// Pops to the list, then focuses the field or lets it go.
  private func showSearch(focused: Bool) async {
    if !navigationPath.isEmpty {
      navigationPath = NavigationPath()
      // Hack: focus requested while the pop animates sets the focus state without making the
      // field first responder, so typing goes nowhere. Wait out the animation.
      try? await Task.sleep(for: .milliseconds(500))
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
    Current.analytics.signal(name: .tapRevealReviewCard)
    withAnimation {
      self.reviewCard?.isRevealed = true
    }
  }

  private func openReviewCard() {
    guard let reviewCard else {
      return
    }
    navigationPath.append(VerbDestination(infinitive: reviewCard.offer.entry.infinitive, source: .reviewCard))
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
    Text(text)
      .font(.caption.smallCaps())
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal)
      .padding(.top, Layout.defaultSpacing)
      .accessibilityAddTraits(.isHeader)
  }

  /// The starred verbs, then the recent ones not starred. A swipe deletes a verb, star and opens
  /// alike, so that it leaves the list; a starred verb asks first, since its star was put there on
  /// purpose. Clear forgets every open and keeps the stars.
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
                    Label(L.MyVerbs.delete, systemImage: "star.slash")
                  }
                  .tint(Color.customRed)
                }
            }
          } header: {
            myVerbsHeading(L.MyVerbs.starred)
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
                    Label(L.MyVerbs.delete, systemImage: "trash")
                  }
                }
            }
          } header: {
            HStack(alignment: .firstTextBaseline) {
              myVerbsHeading(L.MyVerbs.recent)
                .accessibilityIdentifier("my_verbs_recent_heading")
              Spacer()
              Button(L.MyVerbs.clearRecent) {
                withAnimation {
                  learnerVerbs.clearRecents()
                }
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
    }
  }

  private func myVerbsHeading(_ text: String) -> some View {
    Text(text)
      .font(.caption.smallCaps())
      .foregroundStyle(.secondary)
      .accessibilityAddTraits(.isHeader)
  }

  private func myVerbRow(_ entry: VerbMapEntry) -> some View {
    Button {
      navigationPath.append(VerbDestination(infinitive: entry.infinitive, source: .myVerbs))
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
        if showsMyVerbs {
          myVerbsList
        } else {
          ScrollViewReader { proxy in
            let rows = shownVerbs
            let browseSource = self.browseSource
            ScrollView {
              if showsRecents {
                listHeading(L.MyVerbs.recent)
                  .id("top")
                  .accessibilityIdentifier("recent_verbs_heading")
              } else {
                listHeading(L.BrowseVerbs.verbCount(count: filteredVerbs.count))
                  .id("top")
                  // Stable launch-screen leaf anchor for the ios-build-verify skill's
                  // wait-for-render poll (FIRST_SCREEN_ID); a leaf, not a container, to
                  // avoid SwiftUI AXTree identifier rollover onto descendants.
                  .accessibilityIdentifier("browse_verb_count")
              }

              if searchText.isEmpty && !showsRecents {
                TipView(tryQuizTip)
                  .padding(.horizontal)
                  .padding(.top, Layout.defaultSpacing)
              }

              if let reviewCard, searchText.isEmpty, !showsRecents, settings.reviewCardSuppression == .off {
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

              if !searchText.isEmpty && filteredVerbs.isEmpty {
                ContentUnavailableView(L.BrowseVerbs.searchNoResults, systemImage: "magnifyingglass")
                  .padding(.top, Layout.tripleDefaultSpacing)

                failedSearchHelp
                  .readingWidth()
              } else if horizontalSizeClass == .regular {
                // iPad / regular width: reflow the rows into an adaptive grid of
                // carded cells (≈2 columns portrait, ≈3–4 landscape). The same
                // `navigationDestination(for: VerbDestination)` renders the pushed `VerbView`.
                let wasSearching = isSearching
                LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
                  ForEach(Array(rows.enumerated()), id: \.element.infinitive) { index, entry in
                    Button {
                      openRow(at: index, wasSearching: wasSearching, browseSource: browseSource)
                    } label: {
                      VerbGridCell(entry: entry, matchLines: matchLines(at: index, wasSearching: wasSearching))
                        .card()
                        .overlay {
                          if index == keyboardSelection {
                            RoundedRectangle(cornerRadius: Layout.defaultSpacing)
                              .stroke(Color.customRed, lineWidth: 2)
                          }
                        }
                    }
                    .buttonStyle(.plain)
                    // Screenshot-driver anchor (scripts/take_screenshots.sh taps
                    // `verb_row_ser`). Both size-class branches carry it — the iPad
                    // renders this grid, the iPhone the stack below.
                    .accessibilityIdentifier("verb_row_\(entry.infinitive)")
                  }
                }
                .padding(.horizontal)
                .padding(.top, Layout.defaultSpacing)
              } else {
                let wasSearching = isSearching
                LazyVStack(spacing: 0) {
                  ForEach(Array(rows.enumerated()), id: \.element.infinitive) { index, entry in
                    // A real `Button`, not `.onTapGesture`: `.isButton` trait, press highlight,
                    // and stronger VoiceOver semantics. Not a `NavigationLink`, because the open
                    // reports its search; the stack's `navigationDestination(for:
                    // VerbDestination)` renders the pushed `VerbView`.
                    Button {
                      openRow(at: index, wasSearching: wasSearching, browseSource: browseSource)
                    } label: {
                      VerbRowLabel(entry: entry, matchLines: matchLines(at: index, wasSearching: wasSearching))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("verb_row_\(entry.infinitive)")
                    .background(rowBackground(index: index))
                    Divider().padding(.leading)
                  }
                }
              }
            }
            .onChange(of: sort) {
              proxy.scrollTo("top", anchor: .top)
            }
            .onChange(of: keyboardSelection) { _, selection in
              if let selection, rows.indices.contains(selection) {
                proxy.scrollTo(rows[selection].infinitive)
              }
            }
          }
        }

        Divider()

        // A keyboard toolbar never appears for the navigation bar's search field (iOS 26), so
        // the letter row takes the sort picker's place while the field is focused, which puts
        // it directly above the keyboard. Search ignores the sort order, so the picker has
        // nothing to do meanwhile.
        if searchIsEngaged {
          SpanishLetterKeyRow { letter in
            insertLetter(letter)
          }
          .padding(.vertical, Layout.defaultSpacing)
        } else {
          Picker(L.BrowseVerbs.sort, selection: $listMode.animation(.snappy)) {
            ForEach(VerbListMode.allCases, id: \.self) { mode in
              Text(mode.localizedDisplayName).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .readingWidth()
          .padding()
          .accessibilityIdentifier("verb_list_mode_picker")
        }
      }
      // These three are here rather than on the ScrollView, which is absent while My Verbs
      // shows, so that a search typed over My Verbs, or a sort chosen from it, still refilters.
      .onChange(of: listMode) {
        if let newSort = listMode.sort {
          sort = newSort
        }
      }
      .onChange(of: sort) {
        Current.settings.verbSort = sort
        recomputeFilteredVerbs()
      }
      .onChange(of: searchText) {
        keyboardSelection = nil
        if let search = searchTracker.textChanged(to: searchText) {
          signalEndedSearch(search)
        }
        recomputeFilteredVerbs()
      }
      .background(Color.customBackground.ignoresSafeArea())
      .searchable(text: $searchText, placement: searchPlacement, prompt: L.BrowseVerbs.searchPromptVerbConjugationOrMeaning)
      .searchFocused($searchIsFocused)
      .onChange(of: searchIsFocused) {
        searchFocusChanged()
        if searchIsFocused {
          VerbSearchArrowKeys.install { offset in
            moveKeyboardSelection(by: offset)
          }
        } else {
          VerbSearchArrowKeys.uninstall()
        }
      }
      // Return opens the highlighted result, else the first, else the guess. Only on the iPad
      // idiom, which a Mac running the app also reports, so that the iPhone keyboard's Search key
      // behaves as before.
      .onSubmit(of: .search) {
        if Self.isPadOrMac {
          openKeyboardSelection()
        }
      }
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .sensoryFeedback(.selection, trigger: listMode)
      .navigationTitle(L.BrowseVerbs.localizedTitle)
      .navigationDestination(for: VerbDestination.self) { destination in
        VerbView(verb: destination.infinitive, source: destination.source, marks: destination.marks)
      }
      // A verb page's pill and related verbs lead to a model's page and a full list without
      // leaving this tab, so a learner who arrived from a widget or a link reaches them too.
      .verbPageDestinations()
      .onChange(of: router.pendingVerb, initial: true) { _, destination in
        guard let destination else { return }
        navigationPath.append(destination)
        router.pendingVerb = nil
      }
      // A search left with text in the field when the app goes to the background has ended. A
      // return from the background is a new opening, which may offer a review card.
      .onChange(of: scenePhase) {
        switch scenePhase {
        case .background:
          appWasInBackground = true
          if let search = searchTracker.finish() {
            signalEndedSearch(search)
          }
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
      // Loading the conjugation map and indexing its forms takes about a second, so it happens
      // off the main actor before the learner types rather than on the first keystroke.
      .task {
        await Task.detached(priority: .utility) {
          _ = ConjugationIndex.bundled
        }.value
      }
    }
    .environment(\.verbPagePush, VerbPagePush { navigationPath.append($0) })
  }
}

/// The review card on screen: its verb, chosen once per opening, and what the learner has done.
private struct ReviewCardState {
  let offer: PracticeStore.CardOffer
  var isRevealed = false
  var wasSignaled = false
}

/// The visual content of a verb row — serif gold infinitive + gloss with a blue
/// frequency-rank badge. Shared by Browse Verbs and the Model detail's
/// "verbs using this model" list.
struct VerbRowLabel: View {
  let entry: VerbMapEntry
  /// What a search matched, if it matched a form. See `MatchLines`.
  var matchLines: [String] = []
  /// A collection's rows check the verbs looked up.
  var isLookedUp = false

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.citationForm)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)
        if !entry.gloss.isEmpty {
          Text(entry.gloss)
            .font(.subheadline)
            .foregroundStyle(Color.customForeground)
        }
        MatchLines(lines: matchLines)
      }

      Spacer()

      if isLookedUp {
        LookedUpCheck()
      }

      Text(verbatim: "#\(entry.frequencyRank)")
        .font(.caption.monospacedDigit())
        .foregroundStyle(Color.customBlue)
        .accessibilityHidden(true)
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    // Make the *entire* row a tap target. Without this, SwiftUI hit-tests only the
    // drawn glyphs (infinitive/gloss/rank), so taps on the transparent Spacer gap and
    // padding fall through — the row felt only partly tappable (and defeated
    // ios-build-verify's tap-to-drill-down on a verb). A content shape over the padded
    // frame claims the whole cell.
    .contentShape(Rectangle())
  }
}

/// The carded grid variant of a verb row for the iPad (regular-width) grid: the
/// same serif gold infinitive + gloss + rank as `VerbRowLabel`, but laid out to
/// fill a `.card()` cell (rank pulled up beside the infinitive, no row padding —
/// the card supplies it).
struct VerbGridCell: View {
  let entry: VerbMapEntry
  var matchLines: [String] = []
  var isLookedUp = false

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .firstTextBaseline) {
        Text(entry.citationForm)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)

        Spacer(minLength: Layout.defaultSpacing)

        if isLookedUp {
          LookedUpCheck()
        }

        Text(verbatim: "#\(entry.frequencyRank)")
          .font(.caption.monospacedDigit())
          .foregroundStyle(Color.customBlue)
          .accessibilityHidden(true)
      }

      if !entry.gloss.isEmpty {
        Text(entry.gloss)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
      }

      MatchLines(lines: matchLines)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

/// The check on a collection's row for a verb looked up, which VoiceOver reads as "Looked up".
struct LookedUpCheck: View {
  var body: some View {
    Image(systemName: "checkmark.circle.fill")
      .font(.subheadline)
      .foregroundStyle(Color.customGreen)
      .accessibilityLabel(L.VerbCollection.lookedUp)
  }
}

/// The forms a search matched, under a row's gloss: "fue: Pretérito (él)". Every word of a line
/// is Spanish, the tense names included, so VoiceOver reads each line in a Spanish voice.
struct MatchLines: View {
  let lines: [String]

  var body: some View {
    ForEach(lines, id: \.self) { line in
      Text(Self.spanish(line))
        .font(.caption)
        .foregroundStyle(Color.customBlue)
        .padding(.top, 2)
    }
  }

  private static func spanish(_ line: String) -> AttributedString {
    var text = AttributedString(line)
    text.languageIdentifier = "es"
    return text
  }
}

#Preview {
  VerbBrowseView()
    .environment(AppRouter())
}
