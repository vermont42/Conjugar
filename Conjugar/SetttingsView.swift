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

  @State private var isGameCenterButtonOffScreen = true
  @State private var isGameCenterUIHidden = false
  @State private var rateReviewDescription = ""

  @EnvironmentObject var current: World
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
          Group {
            Text(Localizations.Settings.region)
              .modifier(SubheadingLabel())

            Picker("", selection: $store.region) {
              ForEach(Region.allCases, id: \.self) { type in
                Text(type.localizedRegion).tag(type)
              }
            }
              .modifier(SegmentedPicker())
              .onAppear {
                self.store.region = self.current.settings.region
                self.store.current = self.current
              }

            Text(Localizations.Settings.regionDescription)
              .modifier(BodyLabel())

            Spacer(minLength: Layout.tripleDefaultSpacing)
          }

          Group {
            Text(Localizations.Settings.difficulty)
              .modifier(SubheadingLabel())

            Picker("", selection: $store.difficulty) {
              ForEach(Difficulty.allCases, id: \.self) { type in
                Text(type.localizedDifficulty).tag(type)
              }
            }
              .modifier(SegmentedPicker())
              .onAppear {
                self.store.difficulty = self.current.settings.difficulty
                self.store.current = self.current
              }

            Text(Localizations.Settings.difficultyDescription)
              .modifier(BodyLabel())

            Spacer(minLength: Layout.tripleDefaultSpacing)
          }

          Group {
            Text("Browse Tú and/or Vos")
              .modifier(SubheadingLabel())

            Picker("", selection: $store.secondSingularBrowse) {
              ForEach(SecondSingularBrowse.allCases, id: \.self) { type in
                Text(type.localizedSecondSingularBrowse).tag(type)
              }
            }
              .modifier(SegmentedPicker())
              .onAppear {
                self.store.secondSingularBrowse = self.current.settings.secondSingularBrowse
                self.store.current = self.current
              }

            Text("This setting determines whether you see tú conjugations, vos conjugations, or both when you browse verb conjugations.")
              .modifier(BodyLabel())

            Spacer(minLength: Layout.tripleDefaultSpacing)
          }

          Group {
            Text(Localizations.Settings.quiz)
              .modifier(SubheadingLabel())

            Picker("", selection: $store.secondSingularQuiz) {
              ForEach(SecondSingularQuiz.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
              }
            }
              .modifier(SegmentedPicker())
              .onAppear {
                self.store.secondSingularQuiz = self.current.settings.secondSingularQuiz
                self.store.current = self.current
              }

            Text(Localizations.Settings.quizDescription)
              .modifier(BodyLabel())

            Spacer(minLength: Layout.tripleDefaultSpacing)
          }

          if !isGameCenterUIHidden {
            Group {
              Text(Localizations.Quiz.gameCenter)
                .modifier(SubheadingLabel())

              Button(Localizations.Settings.enable) {
                self.current.settings.userRejectedGameCenter = false

                self.current.gameCenter.authenticate(
                  onViewController: self.current.parentViewController ?? UIViewController(),
                  completion: { authenticated in
                    self.isGameCenterUIHidden = authenticated
                })
              }
                .modifier(StandardButton())
                .onAppear {
                  self.isGameCenterButtonOffScreen = false
                }
                .scaleEffect(isGameCenterButtonOffScreen ? offScreenButtonScale : 1.0)
                .animation(.easeInOut(duration: animationDuration))

              // Does not work in ScrollView.
              // https://www.hackingwithswift.com/quick-start/swiftui/how-to-start-an-animation-immediately-after-a-view-appears
              // @State var scale: CGFloat = 1

//              .scaleEffect(scale)
//              .onAppear {
//                  let baseAnimation = Animation.easeInOut(duration: 1)
//                  let repeated = baseAnimation.repeatForever(autoreverses: true)
//
//                  return withAnimation(repeated) {
//                      self.scale = 0.9
//                  }
//              }

              Text(Localizations.Settings.enableDescription)
                .modifier(BodyLabel())

              Spacer(minLength: Layout.tripleDefaultSpacing)
            }
          }

          Group {
            Text(Localizations.Settings.ratingsAndReviews)
              .modifier(SubheadingLabel())

            Button(Localizations.Settings.rateOrReview) {
              guard let url = URL(string: "https://itunes.apple.com/us/app/immigration/id\(RatingsFetcher.iTunesID)?action=write-review") else {
                return
              }
              UIApplication.shared.open(url, options: [:])
            }
              .modifier(StandardButton())

            if rateReviewDescription != "" {
              Text(rateReviewDescription)
                .modifier(BodyLabel())
            }
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

        self.current.analytics.recordVisitation(viewController: "\(SettingsView.self)")

        self.isGameCenterUIHidden = self.current.gameCenter.isAuthenticated
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
