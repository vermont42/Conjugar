//
//  InfoBrowseView.swift
//  Conjugar
//
//  The SwiftUI Info topic list, replacing the UIKit BrowseInfoVC/BrowseInfoUIV/
//  InfoCell. Left-aligned rows in a sectioned List (audit §7: "About" vs
//  "Tenses"), with the difficulty filter moved into the Tenses section header so
//  its relationship to what it filters is explicit. Ported/adapted from
//  Konjugieren's InfoBrowseView.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct InfoBrowseView: View {
  static let englishTitle = "Info"

  @State private var navigationPath = NavigationPath()
  @State private var infoDifficulty: Difficulty = Current.settings.infoDifficulty

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
      .navigationTitle(L.BrowseInfo.localizedTitle)
      .navigationDestination(for: Info.self) { info in
        InfoView(info: info) { target in navigationPath.append(target) }
      }
      .onAppear { Current.analytics.recordVisitation(viewController: "\(InfoBrowseView.self)") }
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
  }
}

#Preview {
  InfoBrowseView()
}
