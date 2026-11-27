//
//  VerbCollectionView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A featured collection's page: its description, how many of its verbs have been looked up, a quiz
/// on it, a share button, and its verbs, the most frequent first, each checked once looked up. A
/// model's collection shows on the model's page instead, as `VerbCollectionBar`.
struct VerbCollectionView: View {
  let collection: VerbCollection
  let source: AnalyticsSource
  private let verbs: [VerbMapEntry]
  private let lists: [VerbSort: [VerbMapEntry]]

  init(collection: VerbCollection, source: AnalyticsSource) {
    self.collection = collection
    self.source = source
    verbs = collection.verbs
    lists = VerbSort.sortedLists(ofMapEntries: verbs)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
        VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
          Text(collection.shortDescription)
            .foregroundStyle(Color.customForeground)
          if collection.isPatternList {
            Text(L.VerbCollection.patternNote)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()

        VerbCollectionBar(collection: collection, title: collection.title, verbs: verbs)

        SortableVerbList(lists: lists, initialSort: .frequency, source: .list, showsLookedUp: true) { count in
          L.BrowseVerbs.verbCount(count: count)
        }
      }
      .padding()
      .readingWidth()
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(collection.title)
    .navigationBarTitleDisplayMode(.large)
    .signalsCollectionView(collection, source: source)
  }
}

extension View {
  /// Sends `viewCollection` once for each opening of a collection's page, or a model's. A return
  /// from one of its verb pages is not another opening.
  func signalsCollectionView(_ collection: VerbCollection, source: AnalyticsSource) -> some View {
    modifier(CollectionViewSignal(collection: collection, source: source))
  }
}

private struct CollectionViewSignal: ViewModifier {
  let collection: VerbCollection
  let source: AnalyticsSource
  @State private var hasSignaled = false

  func body(content: Content) -> some View {
    content.onAppear {
      guard !hasSignaled else {
        return
      }
      hasSignaled = true
      collection.signalView(source: source)
    }
  }
}

/// How many of a collection's verbs have been looked up, with a quiz on them and a share button:
/// on a featured collection's page and on every model's page.
struct VerbCollectionBar: View {
  let collection: VerbCollection
  /// The quiz sheet's title and the shared text's.
  let title: String
  let verbs: [VerbMapEntry]
  @Environment(\.isBeneathQuiz) private var isBeneathQuiz
  @State private var isQuizzing = false
  @State private var shareButtonFrame = CGRect.zero

  var body: some View {
    let progress = CollectionProgress(verbs: verbs)

    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      HStack(spacing: Layout.defaultSpacing) {
        Text(progress.description)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
          .accessibilityIdentifier("collection_progress")

        Spacer()

        if !isBeneathQuiz {
          Button {
            isQuizzing = true
          } label: {
            Label(L.Quiz.localizedTitle, systemImage: "pencil.and.list.clipboard")
          }
          .accessibilityHint(L.VerbCollection.quizHint(questionCount: QuizScope.roundLength))
          .accessibilityIdentifier("collection_quiz_button")
        }

        Button {
          share()
        } label: {
          Label(L.Verb.share, systemImage: "square.and.arrow.up")
            .labelStyle(.iconOnly)
        }
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { frame in
          shareButtonFrame = frame
        }
        .accessibilityIdentifier("collection_share_button")
      }
      .buttonStyle(.bordered)
      .tint(Color.customYellow)

      CollectionProgressBar(progress: progress)
    }
    .card()
    .sheet(isPresented: $isQuizzing) {
      QuizSheet(scope: .collection(collection, title: title))
    }
  }

  private func share() {
    Current.analytics.signal(name: .tapShareCollection, parameters: [
      ParameterKey.collection.rawValue: collection.key
    ])
    ShareSheet.present(
      text: collection.shareText,
      title: title,
      icon: UIImage(named: Current.settings.appIcon.previewAssetName),
      anchorLabel: L.Verb.share,
      anchorRect: shareButtonFrame == .zero ? nil : shareButtonFrame
    )
  }
}

/// A featured collection's row or card in the Models tab's Collections section: its symbol, its
/// title, a glimpse of its forms, and how many of its verbs have been looked up. The row is short
/// enough that five leave the models in view; the card adds the description and a bar.
struct VerbCollectionRowLabel: View {
  let collection: VerbCollection
  @Environment(\.rowLabelStyle) private var style

  var body: some View {
    let progress = CollectionProgress(verbs: collection.verbs)

    RowLabel(title: collection.title, titleIsSpanish: false, symbol: collection.systemImageName) {
      ConjugationText(form: collection.examples)
        .font(.subheadline)
        .lineLimit(style == .row ? 1 : nil)

      if style == .card {
        Text(collection.shortDescription)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
          .fixedSize(horizontal: false, vertical: true)

        Spacer(minLength: 0)

        CollectionProgressBar(progress: progress)
      }
    } trailing: {
      Text(verbatim: progress.fraction)
        .font(.caption.monospacedDigit())
        .foregroundStyle(Color.customBlue)
        .accessibilityLabel(progress.description)
    }
  }
}

/// The gold bar of a collection's progress, which VoiceOver skips, since the text beside it says
/// the same.
struct CollectionProgressBar: View {
  let progress: CollectionProgress

  var body: some View {
    ProgressView(value: progress.barValue, total: progress.barTotal)
      .tint(Color.customYellow)
      .accessibilityHidden(true)
  }
}
