//
//  SetttingsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
  static let englishTitle = "Settings"

  @State private var isGameCenterUIHidden = false
  @State private var rateReviewDescription = ""
  @ObservedObject var store = SelectionStore()

  private let offScreenButtonScale: CGFloat = 1.5
  private let animationDuration = 1.0

  init() {
    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: Colors.yellow], for: .selected)
    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: Colors.yellow], for: .normal)
  }

  var body: some View {
    ZStack {
      Color.black
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .center, spacing: 16) {
        Text(Localizations.Settings.localizedTitle)
          .modifier(HeadingLabel())

        ScrollView(.vertical) {
          Text(Localizations.Settings.region)
            .modifier(SubheadingLabel())

          Picker("", selection: $store.region) {
            ForEach(Region.allCases, id: \.self) { type in
              Text(type.localizedRegion).tag(type)
            }
          }
            .modifier(SegmentedPicker())
            .onAppear {
              self.store.region = Current.settings.region
              self.store.current = Current
            }

          Text(Localizations.Settings.regionDescription)
            .modifier(BodyLabel())

          Spacer(minLength: Layout.tripleDefaultSpacing)

          Text(Localizations.Settings.difficulty)
            .modifier(SubheadingLabel())

          Picker("", selection: $store.difficulty) {
            ForEach(Difficulty.allCases, id: \.self) { type in
              Text(type.localizedDifficulty).tag(type)
            }
          }
            .modifier(SegmentedPicker())
            .onAppear {
              self.store.difficulty = Current.settings.difficulty
              self.store.current = Current
            }

          Text(Localizations.Settings.difficultyDescription)
            .modifier(BodyLabel())

          Spacer(minLength: Layout.tripleDefaultSpacing)

          Text(Localizations.Settings.browse)
            .modifier(SubheadingLabel())

          Picker("", selection: $store.secondSingularBrowse) {
            ForEach(SecondSingularBrowse.allCases, id: \.self) { type in
              Text(type.localizedSecondSingularBrowse).tag(type)
            }
          }
            .modifier(SegmentedPicker())
            .onAppear {
              self.store.secondSingularBrowse = Current.settings.secondSingularBrowse
              self.store.current = Current
            }

          Text(Localizations.Settings.browseDescription)
            .modifier(BodyLabel())

          Spacer(minLength: Layout.tripleDefaultSpacing)

          Text(Localizations.Settings.quiz)
            .modifier(SubheadingLabel())

          Picker("", selection: $store.secondSingularQuiz) {
            ForEach(SecondSingularQuiz.allCases, id: \.self) { type in
              Text(type.rawValue).tag(type)
            }
          }
            .modifier(SegmentedPicker())
            .onAppear {
              self.store.secondSingularQuiz = Current.settings.secondSingularQuiz
              self.store.current = Current
            }

          Text(Localizations.Settings.quizDescription)
            .modifier(BodyLabel())

          Spacer(minLength: Layout.tripleDefaultSpacing)

          if !isGameCenterUIHidden {
            Text(Localizations.Quiz.gameCenter)
              .modifier(SubheadingLabel())

            Button(Localizations.Settings.enable) {
              Current.settings.userRejectedGameCenter = false

              Current.gameCenter.authenticate(
                onViewController: Current.parentViewController ?? UIViewController(),
                completion: { authenticated in
                  self.isGameCenterUIHidden = authenticated
              })
            }
              .modifier(StandardButton())

            Text(Localizations.Settings.enableDescription)
              .modifier(BodyLabel())

            Spacer(minLength: Layout.tripleDefaultSpacing)
          }

          Text(Localizations.Settings.ratingsAndReviews)
            .modifier(SubheadingLabel())

          Button(Localizations.Settings.rateOrReview) {
            UIApplication.shared.open(RatingsFetcher.reviewURL, options: [:])
          }
            .modifier(StandardButton())

          if rateReviewDescription != "" {
            Text(rateReviewDescription)
              .modifier(BodyLabel())
          }

          Spacer()
        }
      }
    }
      .onAppear {
        RatingsFetcher.fetchRatingsDescription(completion: { description in
          if description != RatingsFetcher.errorMessage {
            DispatchQueue.main.async {
              self.rateReviewDescription = description
            }
          }
        })

        Current.analytics.recordVisitation(viewController: "\(SettingsView.self)")

        self.isGameCenterUIHidden = Current.gameCenter.isAuthenticated
      }
  }
}

final class SelectionStore: ObservableObject {
  var current: World?

  var region: Region = Settings.regionDefault {
    didSet {
      current?.settings.region = region
    }
  }

  var difficulty: Difficulty = Settings.difficultyDefault {
    didSet {
      current?.settings.difficulty = difficulty
    }
  }

  var secondSingularBrowse: SecondSingularBrowse = Settings.secondSingularBrowseDefault {
    didSet {
      current?.settings.secondSingularBrowse = secondSingularBrowse
    }
  }

  var secondSingularQuiz: SecondSingularQuiz = Settings.secondSingularQuizDefault {
    didSet {
      current?.settings.secondSingularQuiz = secondSingularQuiz
    }
  }
}
