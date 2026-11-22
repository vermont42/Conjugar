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

  @State private var sort: VerbSort = Current.settings.verbSort
  @State private var navigationPath = NavigationPath()
  @State private var searchText = ""
  @FocusState private var searchIsFocused: Bool
  /// Follows `searchIsFocused`, but lets go of it a moment later. See `searchFocusChanged`.
  @State private var searchIsEngaged = false
  /// The row that Return opens and the arrow keys move, on iPad and Mac keyboards. Nil until an
  /// arrow is pressed, and cleared whenever the query changes.
  @State private var keyboardSelection: Int?
  /// The closest verb to a query that found nothing, or nil. See `VerbSearch.closestVerb`.
  @State private var guess: VerbMapEntry?
  @State private var addressWasCopied = false
  @Environment(AppRouter.self) private var router
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  private let tryQuizTip = TryQuizTip()

  /// Both sort orders, computed once (mirrors the UIKit VC's `verbsBySort`).
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
      filteredVerbs = verbs
      return
    }
    let results = VerbSearch.matches(for: searchText, in: verbs).map(\.entry)
    if results.isEmpty {
      Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true)
      guess = VerbSearch.closestVerb(to: searchText, in: verbs)
    }
    filteredVerbs = results
  }

  private var trimmedSearchText: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var isSearching: Bool {
    !trimmedSearchText.isEmpty
  }

  private static let isPadOrMac = UIDevice.current.userInterfaceIdiom == .pad

  // iPadOS 26 shrinks .automatic search into a toolbar button that ignores a programmatic
  // .searchFocused, so a letter key could not reopen it. A drawer that stays put accepts it.
  // The iPhone keeps .automatic and looks as before.
  private var searchPlacement: SearchFieldPlacement {
    Self.isPadOrMac ? .navigationBarDrawer(displayMode: .always) : .automatic
  }

  // Hack, ported from Konjugieren: on iPad, a tap outside an empty search field ends the search at
  // touch-down, before the tap completes. A letter row that followed the focus vanished under the
  // finger, so tapping á did nothing. The row follows this instead, which lets go a moment later.
  private func searchFocusChanged() {
    guard !searchIsFocused else {
      searchIsEngaged = true
      return
    }
    Task {
      try? await Task.sleep(for: Self.searchLingering)
      if !searchIsFocused {
        searchIsEngaged = false
      }
    }
  }

  private static let searchLingering = Duration.milliseconds(700)

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
  /// that the app lacks. Phase 5's conjugation lookup will make this rarer, since a conjugation
  /// will then find its verb.
  private var failedSearchHelp: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      if let guess {
        Text(L.BrowseVerbs.guessIntro)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
          .accessibilityIdentifier("search_guess_intro")

        NavigationLink(value: guess.infinitive) {
          VerbRowLabel(entry: guess)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("search_guess_\(guess.infinitive)")
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
      let url = URL.mailto(address, subject: L.BrowseVerbs.verbRequestSubject(query: query), body: L.BrowseVerbs.verbRequestBody(query: query))
    {
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
    return filteredVerbs.count
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
      navigationPath.append(guess.infinitive)
    } else if filteredVerbs.indices.contains(index) {
      navigationPath.append(filteredVerbs[index].infinitive)
    }
  }

  /// Command-F: pop to the list and focus the field.
  private func focusSearch() async {
    if !navigationPath.isEmpty {
      navigationPath = NavigationPath()
      // Hack, from Konjugieren: focus requested while the pop animates sets the focus state
      // without making the field first responder, so typing goes nowhere. Wait out the animation.
      try? await Task.sleep(for: .milliseconds(500))
    }
    searchIsFocused = true
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            Text(L.BrowseVerbs.verbCount(count: filteredVerbs.count))
              .font(.caption.smallCaps())
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .padding(.top, Layout.defaultSpacing)
              .id("top")
              // Stable launch-screen leaf anchor for the ios-build-verify skill's
              // wait-for-render poll (FIRST_SCREEN_ID); a leaf, not a container, to
              // avoid SwiftUI AXTree identifier rollover onto descendants.
              .accessibilityIdentifier("browse_verb_count")

            if searchText.isEmpty {
              TipView(tryQuizTip)
                .padding(.horizontal)
                .padding(.top, Layout.defaultSpacing)
            }

            if !searchText.isEmpty && filteredVerbs.isEmpty {
              ContentUnavailableView(L.BrowseVerbs.searchNoResults, systemImage: "magnifyingglass")
                .padding(.top, Layout.tripleDefaultSpacing)

              failedSearchHelp
                .readingWidth()
            } else if horizontalSizeClass == .regular {
              // iPad / regular width: reflow the rows into an adaptive grid of
              // carded cells (≈2 columns portrait, ≈3–4 landscape). The same
              // `navigationDestination(for: String)` renders the pushed `VerbView`.
              LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
                ForEach(Array(filteredVerbs.enumerated()), id: \.element.infinitive) { index, entry in
                  NavigationLink(value: entry.infinitive) {
                    VerbGridCell(entry: entry)
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
              LazyVStack(spacing: 0) {
                ForEach(Array(filteredVerbs.enumerated()), id: \.element.infinitive) { index, entry in
                  // A real `NavigationLink`: `.isButton` trait, press
                  // highlight, and stronger VoiceOver semantics than the old
                  // `.onTapGesture`. The stack's `navigationDestination(for: String)`
                  // already renders the pushed `VerbView`.
                  NavigationLink(value: entry.infinitive) {
                    VerbRowLabel(entry: entry)
                  }
                  .buttonStyle(.plain)
                  .accessibilityIdentifier("verb_row_\(entry.infinitive)")
                  .background(rowBackground(index: index))
                  Divider().padding(.leading)
                }
              }
            }
          }
          .onChange(of: sort) { _, newValue in
            Current.settings.verbSort = newValue
            recomputeFilteredVerbs()
            proxy.scrollTo("top", anchor: .top)
          }
          .onChange(of: searchText) { _, _ in
            keyboardSelection = nil
            recomputeFilteredVerbs()
          }
          .onChange(of: keyboardSelection) { _, selection in
            if let selection, filteredVerbs.indices.contains(selection) {
              proxy.scrollTo(filteredVerbs[selection].infinitive)
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
          Picker(L.BrowseVerbs.sort, selection: $sort.animation(.snappy)) {
            ForEach(VerbSort.allCases, id: \.self) { order in
              Text(order.localizedDisplayName).tag(order)
            }
          }
          .pickerStyle(.segmented)
          .readingWidth()
          .padding()
        }
      }
      .background(Color.customBackground.ignoresSafeArea())
      .searchable(text: $searchText, placement: searchPlacement, prompt: L.BrowseVerbs.searchPromptVerbOrMeaning)
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
      .sensoryFeedback(.selection, trigger: sort)
      .navigationTitle(L.BrowseVerbs.localizedTitle)
      .navigationDestination(for: String.self) { verb in
        VerbView(verb: verb)
      }
      .onChange(of: router.pendingVerb, initial: true) { _, verb in
        guard let verb else { return }
        navigationPath.append(verb)
        router.pendingVerb = nil
      }
      .onChange(of: router.pendingSearchFocus, initial: true) { _, requested in
        guard requested else { return }
        router.pendingSearchFocus = false
        Task {
          await focusSearch()
        }
      }
      .onAppear {
        Current.analytics.signal(name: .viewVerbBrowseView)
        Current.reviewPrompter.promptableActionHappened()
      }
    }
  }
}

/// The visual content of a verb row — serif gold infinitive + gloss with a blue
/// frequency-rank badge. Shared by Browse Verbs and the Model detail's
/// "verbs using this model" list.
struct VerbRowLabel: View {
  let entry: VerbMapEntry

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.infinitive)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)
        if !entry.gloss.isEmpty {
          Text(entry.gloss)
            .font(.subheadline)
            .foregroundStyle(Color.customForeground)
        }
      }

      Spacer()

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

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .firstTextBaseline) {
        Text(entry.infinitive)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)

        Spacer(minLength: Layout.defaultSpacing)

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
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

#Preview {
  VerbBrowseView()
    .environment(AppRouter())
}
