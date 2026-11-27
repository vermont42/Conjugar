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
  @State private var reviewCard = VerbBrowseReviewCard()
  @State private var navigationPath = NavigationPath()
  @FocusState private var searchIsFocused: Bool
  /// Lets `search.isEngaged` go a moment after the focus. See `searchFocusChanged`.
  @State private var lingerTask: Task<Void, Never>?
  @Environment(AppRouter.self) private var router
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.scenePhase) private var scenePhase
  private let tryQuizTip = TryQuizTip()

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

  private func rowBackground(_ row: VerbBrowseSearch.Row, index: Int) -> Color {
    row.id == search.selection ? .keyboardSelection : .zebraStripe(index)
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

  private func listHeading(_ text: String) -> some View {
    ListHeading(text)
      .padding(.horizontal)
      .padding(.top, Layout.defaultSpacing)
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        if search.shown == .myVerbs {
          MyVerbsList { entry in
            push(VerbDestination(infinitive: entry.infinitive, source: .myVerbs))
          }
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

                ReviewCardHost(model: reviewCard, push: push)
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

                FailedSearchHelp(search: search, push: push)
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
          search.appEnteredBackground()
          reviewCard.appEnteredBackground()
        case .active:
          reviewCard.appBecameActive()
        default:
          break
        }
      }
      .onChange(of: settings.reviewCardSuppression) {
        reviewCard.suppressionChanged()
      }
      .onChange(of: router.pendingSearch, initial: true) {
        openRequestedSearch()
      }
      .onAppear {
        Current.analytics.signal(name: .viewVerbBrowseView)
        Current.reviewPrompter.promptableActionHappened()
        reviewCard.listAppeared()
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

#Preview {
  VerbBrowseView()
    .environment(AppRouter())
}
