//
//  InfoBrowseView.swift
//  Conjugar
//
//  The SwiftUI Info topic list, replacing the UIKit BrowseInfoVC/BrowseInfoUIV/
//  InfoCell. Left-aligned rows in a sectioned List, with the difficulty filter
//  moved into the Tenses section header so its relationship to what it filters is
//  explicit.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import UIKit

struct InfoBrowseView: View {
  static let englishTitle = "Info"

  @Environment(AppRouter.self) private var router
  @State private var navigationPath = NavigationPath()
  @State private var infoDifficulty: Difficulty = Current.settings.infoDifficulty
  // Programmatic push of the tutor, triggered by the onboarding "Meet the Tutor" CTA
  // via `router.pendingTutor` (the in-list NavigationLink handles manual taps).
  @State private var showTutor = false

  private var aboutInfos: [Info] {
    Info.infos.filter { $0.section == .about && isWithinFilter($0) }
  }

  private var tenseInfos: [Info] {
    Info.infos.filter { $0.section == .tenses && isWithinFilter($0) }
  }

  private func isWithinFilter(_ info: Info) -> Bool {
    rank(info.difficulty) <= rank(infoDifficulty)
  }

  private func rank(_ difficulty: Difficulty) -> Int {
    Difficulty.allCases.firstIndex(of: difficulty) ?? 0
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      List {
        tutorSection

        Section(L.BrowseInfo.aboutSection) {
          ForEach(aboutInfos) { info in
            row(info)
          }
        }

        Section {
          ForEach(tenseInfos) { info in
            row(info)
          }
        } header: {
          VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
            Text(L.BrowseInfo.tensesSection)
            Picker(L.BrowseInfo.filter, selection: $infoDifficulty) {
              Text(L.BrowseInfo.easy).tag(Difficulty.easy)
              Text(L.BrowseInfo.easyAndModerate).tag(Difficulty.moderate)
              Text(L.BrowseInfo.easyModerateAndDifficult).tag(Difficulty.difficult)
            }
            .pickerStyle(.segmented)
            .textCase(nil)
          }
        }
      }
      // iPad / regular width: cap the grouped list to a comfortable measure and
      // center it, filling the surround with the same grouped background so the
      // sections sit in a centered column instead of stretching edge-to-edge. A
      // no-op on iPhone (narrower than the cap).
      .readingWidth()
      .background(Color(.systemGroupedBackground).ignoresSafeArea())
      .navigationTitle(L.BrowseInfo.localizedTitle)
      .navigationDestination(for: Info.self) { info in
        InfoView(info: info) { target in navigationPath.append(target) }
      }
      .navigationDestination(isPresented: $showTutor) { TutorView() }
      // Consume the onboarding tutor deep-link: `.task(id:)` runs both when the Info
      // tab first appears with the flag already set and when it flips while visible.
      .task(id: router.pendingTutor) {
        guard router.pendingTutor else { return }
        router.pendingTutor = false
        if Current.languageModelService.isAvailable {
          showTutor = true
        }
      }
      .onAppear {
        Current.analytics.signal(name: .viewInfoBrowseView)
      }
      // Poll the on-device model's availability while this screen is visible; SwiftUI
      // cancels the task on disappear, so the tutor row flips live without any manual
      // start/stop pairing.
      .task { await Current.languageModelService.monitorAvailability() }
      .onChange(of: infoDifficulty) { _, newValue in
        Current.settings.infoDifficulty = newValue
      }
      .animation(.snappy, value: infoDifficulty)
      .selectionFeedback(trigger: infoDifficulty)
    }
  }

  private func row(_ info: Info) -> some View {
    NavigationLink(value: info) {
      Text(info.heading)
        .font(.body)
        .fontDesign(.serif)
        .foregroundStyle(Color.customForeground)
    }
    // Screenshot-driver anchor. Keyed by `stableKey`, not `heading`, so the id is
    // identical under `en` and `es` — see `Info.stableKey`.
    .accessibilityIdentifier("info_row_\(info.stableKey)")
  }

  // The conjugation-tutor entry point. Reads the `@Observable` service's live
  // availability: a tappable row when the on-device model is ready, otherwise a
  // reason row (tap to open Settings when Apple Intelligence is merely off). The
  // whole section hides only when there is neither availability nor a reason.
  @ViewBuilder
  private var tutorSection: some View {
    let service = Current.languageModelService
    if service.isAvailable {
      Section(L.Tutor.section) {
        NavigationLink {
          TutorView()
        } label: {
          Label(L.Tutor.heading, systemImage: "brain")
            .foregroundStyle(Color.customForeground)
        }
      }
    } else if let reason = service.unavailabilityReason, TutorDisplay.tutorUnavailableRowEnabled {
      Section(L.Tutor.section) {
        tutorUnavailableRow(reason)
      }
    }
  }

  @ViewBuilder
  private func tutorUnavailableRow(_ reason: LanguageModelUnavailability) -> some View {
    let text = Self.reasonText(reason)
    if reason == .appleIntelligenceNotEnabled {
      Button {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      } label: {
        Label(text, systemImage: "brain")
          .foregroundStyle(Color.customBlue)
      }
    } else {
      Label(text, systemImage: "brain")
        .foregroundStyle(.secondary)
    }
  }

  private static func reasonText(_ reason: LanguageModelUnavailability) -> String {
    switch reason {
    case .appleIntelligenceNotEnabled:
      return L.Tutor.reasonAppleIntelligenceOff
    case .deviceNotEligible:
      return L.Tutor.reasonDeviceNotEligible
    case .modelNotReady:
      return L.Tutor.reasonModelNotReady
    case .unknown:
      return L.Tutor.reasonUnknown
    }
  }
}

#Preview {
  InfoBrowseView()
    .environment(AppRouter())
}
