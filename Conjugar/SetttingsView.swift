//
//  SetttingsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
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
        Text("Settings")
          .modifier(HeadingLabel())

        ScrollView(.vertical) {
          Group {
            Text("Region")
              .modifier(SubheadingLabel())

            Picker("", selection: $store.region) {
              ForEach(Region.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
              }
            }
            .modifier(SegmentedPicker())
            .onAppear {
              self.store.region = self.current.settings.region
              self.store.current = self.current
            }

            Text("In Latin American mode, quizzes do not include vosotros conjugations. This setting also determines how Conjugar pronounces conjugations.")
              .modifier(BodyLabel())

            Spacer(minLength: Layout.tripleDefaultSpacing)
          }

          Group {
            Text("Difficulty")
              .modifier(SubheadingLabel())

            Picker("", selection: $store.difficulty) {
              ForEach(Difficulty.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
              }
            }
            .modifier(SegmentedPicker())
            .onAppear {
              self.store.difficulty = self.current.settings.difficulty
              self.store.current = self.current
            }

            Text("Moderate-mode quizzes test more tenses than easy-mode quizzes. Difficult-mode quizzes test more tenses than moderate-mode quizzes.")
              .modifier(BodyLabel())

            Spacer(minLength: Layout.tripleDefaultSpacing)
          }

          Group {
            Text("Browse Tú and/or Vos")
              .modifier(SubheadingLabel())

            Picker("", selection: $store.secondSingularBrowse) {
              ForEach(SecondSingularBrowse.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
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
            Text("Quiz Tú or Vos")
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

            Text("This setting determines whether Conjugar's quiz mode quizzes you on tú forms or vos forms of verbs.")
              .modifier(BodyLabel())

            Spacer(minLength: Layout.tripleDefaultSpacing)
          }

          if !isGameCenterUIHidden {
            Group {
              Text("Game Center")
                .modifier(SubheadingLabel())

              Button("Enable") {
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

              Text("Conjugar can send future quiz scores to Game Center so that you can see them in the global leaderboard. Tap Enable to enable this.")
                .modifier(BodyLabel())

              Spacer(minLength: Layout.tripleDefaultSpacing)
            }
          }

          Group {
            Text("Ratings and Reviews")
              .modifier(SubheadingLabel())

            Button("Rate or Review") {
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
