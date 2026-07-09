//
//  CommunView.swift
//  Conjugar
//
//  The SwiftUI presentation of a CloudKit-driven "communication" — a server-sent
//  message shown modally at launch. Replaces the UIKit CommunVC/CommunUIV. Carded
//  content on the app surface, a discoverable toolbar dismiss, a conditionally-
//  omitted image, and the type-specific buttons routed through the shared button
//  styles. Reuses `CommunViewModel` for the display logic.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import UIKit

struct CommunView: View {
  let commun: Commun
  let onDismiss: () -> Void

  private let viewModel: CommunViewModel

  init(commun: Commun, onDismiss: @escaping () -> Void) {
    self.commun = commun
    self.onDismiss = onDismiss
    viewModel = CommunViewModel(commun: commun)
  }

  /// The stub/absent image is a zero-size `UIImage()`; omit the view then.
  private var hasImage: Bool { viewModel.image.size != .zero }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: Layout.doubleDefaultSpacing) {
          Text(viewModel.title)
            .font(.largeTitle.bold())
            .fontDesign(.serif)
            .foregroundStyle(Color.customYellow)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)

          if hasImage {
            Image(uiImage: viewModel.image)
              .resizable()
              .scaledToFit()
              .frame(maxWidth: 220)
              .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
              .accessibilityLabel(viewModel.imageLabel)
          }

          Text(viewModel.content)
            .font(.body)
            .foregroundStyle(Color.customForeground)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
        .padding()
        .frame(maxWidth: Layout.readingWidth)
        .frame(maxWidth: .infinity)
      }
      .background(Color.customBackground.ignoresSafeArea())
      .safeAreaInset(edge: .bottom) { buttons }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(action: close) {
            Image(systemName: "xmark")
          }
          .tint(.customRed)
          .accessibilityLabel(L.Alert.gotIt)
        }
      }
      .onAppear { Current.analytics.recordCommunVisitation(identifier: viewModel.identifier) }
    }
  }

  private var buttons: some View {
    VStack(spacing: Layout.defaultSpacing) {
      if viewModel.shouldShowOkay {
        Button(viewModel.okayTitle, action: okay)
          .buttonStyle(PrimaryButtonStyle())
      }
      if viewModel.shouldShowAction {
        Button(viewModel.actionTitle, action: action)
          .buttonStyle(PrimaryButtonStyle())
      }
      if viewModel.shouldShowCancel {
        Button(viewModel.cancelTitle, action: cancel)
          .buttonStyle(LinkButtonStyle())
      }
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(.bar)
  }

  private func close() {
    Current.analytics.recordCloseTap(identifier: viewModel.identifier)
    onDismiss()
  }

  private func okay() {
    Current.analytics.recordOkayTap(identifier: viewModel.identifier)
    onDismiss()
  }

  private func action() {
    Current.analytics.recordActionTap(identifier: viewModel.identifier)
    SoundPlayer.playRandomApplause()
    onDismiss()
    viewModel.action()
  }

  private func cancel() {
    Current.analytics.recordCancelTap(identifier: viewModel.identifier)
    onDismiss()
  }
}
