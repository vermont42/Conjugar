//
//  InfoView.swift
//  Conjugar
//
//  The SwiftUI Info-article detail screen, replacing the UIKit InfoVC/InfoUIV.
//  Serif gold title over reading-width body copy. A tapped `%…%` term
//  either opens an external URL or drills into the referenced Info article via the
//  `navigate` closure; the old pop-then-push cross-link becomes a push.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct InfoView: View {
  let info: Info
  /// Navigate to another Info article (a tapped `%…%` cross-reference).
  let navigate: (Info) -> Void

  var body: some View {
    ZStack {
      Color.customBackground
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text(info.heading)
            .font(.largeTitle.bold())
            .fontDesign(.serif)
            .foregroundStyle(Color.customYellow)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, Layout.defaultSpacing)
            .accessibilityAddTraits(.isHeader)

          // The brand triad, echoing the app icon — a small decorative rule.
          HStack(spacing: 6) {
            Circle().fill(Color.customRed).frame(width: 4, height: 4)
            Circle().fill(Color.customYellow).frame(width: 4, height: 4)
            Circle().fill(Color.customBlue).frame(width: 4, height: 4)
          }
          .frame(maxWidth: .infinity)
          .padding(.bottom, Layout.doubleDefaultSpacing)
          .accessibilityHidden(true)

          RichTextView(blocks: info.richTextBlocks)
            .frame(maxWidth: Layout.readingWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Layout.doubleDefaultSpacing)
        .padding(.vertical, Layout.doubleDefaultSpacing)
      }
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear { Current.analytics.recordVisitation(viewController: "\(InfoView.self)") }
    .environment(\.openURL, OpenURLAction { url in handleInfoLink(url) })
  }

  private func handleInfoLink(_ url: URL) -> OpenURLAction.Result {
    let absolute = url.absoluteString
    if absolute.hasPrefix("http") {
      return .systemAction
    }
    let cleaned = absolute.removingPercentEncoding ?? absolute
    if let target = Info.info(forHeading: cleaned) {
      navigate(target)
      return .handled
    }
    // Unknown cross-reference: swallow the tap rather than let it fail loudly.
    return .handled
  }
}
