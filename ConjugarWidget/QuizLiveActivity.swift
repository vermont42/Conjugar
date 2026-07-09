//
//  QuizLiveActivity.swift
//  ConjugarWidget
//
//  The quiz Live Activity: a Lock Screen presentation and a full Dynamic Island. The
//  activity is driven by the app (LiveActivityManager, from Quiz.swift); this file only
//  renders QuizActivityAttributes / ContentState.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct QuizLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: QuizActivityAttributes.self) { context in
      // Lock Screen / banner presentation.
      QuizLiveActivityLockScreenView(context: context)
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.5))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text(verbatim: "\(context.state.currentQuestion)/\(context.attributes.totalQuestions)")
          } icon: {
            Image(systemName: "list.number")
          }
          .font(.caption)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Label {
            Text(verbatim: "\(context.state.score)")
          } icon: {
            Image(systemName: "star.fill")
          }
          .font(.caption)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(WidgetL.LiveActivity.title)
            .font(.headline)
        }
        DynamicIslandExpandedRegion(.bottom) {
          QuizProgressBar(context: context)
        }
      } compactLeading: {
        Image(systemName: "pencil.circle.fill")
      } compactTrailing: {
        Text(verbatim: "\(context.state.currentQuestion)/\(context.attributes.totalQuestions)")
          .font(.caption2)
      } minimal: {
        Image(systemName: "pencil.circle.fill")
      }
      .widgetURL(WidgetDeeplink.quizStart)
    }
  }
}

struct QuizLiveActivityLockScreenView: View {
  let context: ActivityViewContext<QuizActivityAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Label(WidgetL.LiveActivity.title, systemImage: "pencil.circle.fill")
          .font(.headline)
        Spacer()
        Text(context.state.elapsedTime)
          .font(.subheadline.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      QuizProgressBar(context: context)
      HStack {
        Text(verbatim: "\(context.state.currentQuestion)/\(context.attributes.totalQuestions)")
        Spacer()
        Label {
          Text(verbatim: "\(context.state.score)")
        } icon: {
          Image(systemName: "star.fill")
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
  }
}

struct QuizProgressBar: View {
  let context: ActivityViewContext<QuizActivityAttributes>

  private var fraction: Double {
    let total = max(context.attributes.totalQuestions, 1)
    return min(Double(context.state.currentQuestion) / Double(total), 1)
  }

  var body: some View {
    ProgressView(value: fraction)
      .tint(.white)
  }
}
