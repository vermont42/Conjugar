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
  @Environment(\.verbPagePush) private var push
  @State private var verbSort = VerbSort.frequency
  @State private var hasSignaledView = false
  private let entriesBySort: [VerbSort: [VerbMapEntry]]

  init(collection: VerbCollection, source: AnalyticsSource) {
    self.collection = collection
    self.source = source
    let entries = collection.verbs
    entriesBySort = Dictionary(uniqueKeysWithValues: VerbSort.allCases.map { ($0, $0.sorted(entries)) })
  }

  var body: some View {
    let entries = entriesBySort[verbSort] ?? []

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

        VerbCollectionBar(collection: collection, title: collection.title, verbs: entries)

        Picker(L.BrowseVerbs.sort, selection: $verbSort.animation(.snappy)) {
          ForEach(VerbSort.allCases, id: \.self) { order in
            Text(order.localizedDisplayName).tag(order)
          }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: verbSort)

        Text(L.BrowseVerbs.verbCount(count: entries.count))
          .font(.caption.smallCaps())
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)

        VerbEntryList(entries: entries, showsLookedUp: true) { verb in
          push?(VerbDestination(infinitive: verb, source: .list))
        }
      }
      .padding()
      .readingWidth()
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(collection.title)
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      // A return from one of the list's verb pages is not another opening of the list.
      guard !hasSignaledView else {
        return
      }
      hasSignaledView = true
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
  @State private var isQuizzing = false
  @State private var shareButtonFrame = CGRect.zero

  var body: some View {
    let openedCount = Current.learnerVerbs.openedCount(of: verbs)
    let progress = L.VerbCollection.progress(opened: openedCount, total: verbs.count)

    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      HStack(spacing: Layout.defaultSpacing) {
        Text(progress)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
          .accessibilityIdentifier("collection_progress")

        Spacer()

        Button {
          isQuizzing = true
        } label: {
          Label(L.Quiz.localizedTitle, systemImage: "pencil.and.list.clipboard")
        }
        .accessibilityHint(L.VerbCollection.quizHint(questionCount: QuizScope.fullLength))
        .accessibilityIdentifier("collection_quiz_button")

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

      ProgressView(value: Double(openedCount), total: Double(max(verbs.count, 1)))
        .tint(Color.customYellow)
        .accessibilityHidden(true)
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

/// A featured collection's row in the Models tab's Collections section, on iPhone: its title and a
/// glimpse of its forms, short enough that five rows leave the models in view. The description
/// waits on the collection's page.
struct VerbCollectionRow: View {
  let collection: VerbCollection

  var body: some View {
    let verbs = collection.verbs
    let openedCount = Current.learnerVerbs.openedCount(of: verbs)

    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Image(systemName: collection.systemImageName)
        .font(.title3)
        .foregroundStyle(Color.customYellow)
        .frame(width: 28)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(collection.title)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)
        ConjugationText(form: collection.examples)
          .font(.subheadline)
          .lineLimit(1)
      }

      Spacer()

      Text(verbatim: "\(openedCount)/\(verbs.count)")
        .font(.caption.monospacedDigit())
        .foregroundStyle(Color.customBlue)
        .accessibilityLabel(L.VerbCollection.progress(opened: openedCount, total: verbs.count))
    }
    .padding(.horizontal)
    .padding(.vertical, 10)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
  }
}

/// A featured collection's card in the Models tab's Collections section, on iPad.
struct VerbCollectionCard: View {
  let collection: VerbCollection

  var body: some View {
    let verbs = collection.verbs
    let openedCount = Current.learnerVerbs.openedCount(of: verbs)

    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      HStack {
        Image(systemName: collection.systemImageName)
          .font(.title2)
          .foregroundStyle(Color.customYellow)
          .accessibilityHidden(true)

        Spacer()

        Text(verbatim: "\(openedCount)/\(verbs.count)")
          .font(.caption.monospacedDigit())
          .foregroundStyle(Color.customBlue)
          .accessibilityLabel(L.VerbCollection.progress(opened: openedCount, total: verbs.count))
      }

      Text(collection.title)
        .font(.title3)
        .fontDesign(.serif)
        .foregroundStyle(Color.customYellow)
      ConjugationText(form: collection.examples)
        .font(.subheadline)
      Text(collection.shortDescription)
        .font(.subheadline)
        .foregroundStyle(Color.customForeground)
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 0)

      ProgressView(value: Double(openedCount), total: Double(max(verbs.count, 1)))
        .tint(Color.customYellow)
        .accessibilityHidden(true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
  }
}
