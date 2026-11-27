//
//  MyVerbsList.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// The verb list's My Verbs: the starred verbs, then the recent ones not starred. A swipe removes
/// a verb, its star and its last open alike, so that it leaves the list; a starred verb asks
/// first, since its star was put there on purpose. Clear asks, then forgets every last open and
/// keeps the stars. Neither forgets that a verb was opened, which the collections count.
/// A `List` of its own, because only a List's rows can be swiped to delete.
struct MyVerbsList: View {
  /// Opens a verb's page, through the tab's one push.
  let open: (VerbMapEntry) -> Void
  /// The starred verb whose swipe to remove awaits the learner's answer in an alert.
  @State private var verbToUnstar: VerbMapEntry?
  @State private var isConfirmingClear = false

  private var learnerVerbs: LearnerVerbStore { Current.learnerVerbs }

  var body: some View {
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
              row(entry)
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
              row(entry)
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

  private func row(_ entry: VerbMapEntry) -> some View {
    Button {
      open(entry)
    } label: {
      VerbRowLabel(entry: entry)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("my_verb_row_\(entry.infinitive)")
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.clear)
  }
}
