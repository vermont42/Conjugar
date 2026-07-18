//
//  TutorView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct TutorView: View {
  @State private var messages: [TutorMessage] = []
  @State private var inputText = ""
  @State private var isGenerating = false
  @State private var showingSampleQueries = false
  @State private var showingHint = true
  @State private var hasLoadedHistory = false
  @State private var showingTests = false
  @FocusState private var isInputFocused: Bool

  private static var isSpanish: Bool {
    Locale.current.language.languageCode?.identifier == "es"
  }

  private static let englishSuggestions = [
    "Conjugate hablar in the presente.",
    "What is the pretérito of ir?",
    "What is the participio of hacer?",
    "Conjugate comer in the futuro.",
    "What is the imperativo of ser?",
    "How do you say “I would have spoken” in Spanish?",
    "What is the presente de subjuntivo of tener?",
    "Conjugate vivir in the imperfecto.",
    "What is the difference between the pretérito and the imperfecto?",
    "What is the condicional of poder?",
    "Conjugate dar in the pretérito.",
    "What is the gerundio of decir?"
  ]

  private static let spanishSuggestions = [
    "Conjuga hablar en el presente.",
    "¿Cuál es el pretérito de ir?",
    "¿Cuál es el participio de hacer?",
    "Conjuga comer en el futuro.",
    "¿Cuál es el imperativo de ser?",
    "¿Cómo se dice «habría hablado» en español?",
    "¿Cuál es el presente de subjuntivo de tener?",
    "Conjuga vivir en el imperfecto.",
    "¿Cuál es la diferencia entre el pretérito y el imperfecto?",
    "¿Cuál es el condicional de poder?",
    "Conjuga dar en el pretérito.",
    "¿Cuál es el gerundio de decir?"
  ]

  private static var suggestions: [String] {
    isSpanish ? spanishSuggestions : englishSuggestions
  }

  var body: some View {
    ZStack {
      Color.customBackground
        .ignoresSafeArea()

      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
              Button(L.Tutor.getSampleQuery) {
                showingSampleQueries = true
              }
              .buttonStyle(PrimaryButtonStyle())
              .frame(maxWidth: .infinity)

              Text(L.Tutor.getSampleQueryDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)

              Text(L.Tutor.poweredBy)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, Layout.defaultSpacing)

              ForEach(messages) { message in
                messageBubble(message)
                  .id(message.id)
                  .transition(.move(edge: .bottom).combined(with: .opacity))
              }

              if isGenerating {
                typingIndicator
                  .id("typing")
              }
            }
            .padding(Layout.doubleDefaultSpacing)
            // Cap the chat column to a reading-width measure, centered — full-iPad-width
            // bubbles read badly. No-op on iPhone (narrower than the cap).
            .readingWidth()
          }
          .safeAreaInset(edge: .bottom) {
            if showingHint {
              Text(L.Tutor.inputPlaceholder)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Layout.defaultSpacing)
                .background(Color.customBackground.opacity(0.8))
            }
          }
          .onChange(of: messages.count) {
            if hasLoadedHistory, let lastMessage = messages.last {
              withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
              }
            }
          }
        }

        Rectangle()
          .fill(Color.customBlue)
          .frame(height: 1)
          .padding(.horizontal, Layout.doubleDefaultSpacing)
          .readingWidth()

        inputBar
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        // Hidden affordance: triple-tap the title to open the batch harness.
        Text(L.Tutor.heading)
          .font(.headline)
          .onTapGesture(count: 3) {
            showingTests = true
          }
      }
    }
    .sheet(isPresented: $showingTests) {
      TutorTestView()
    }
    .sheet(isPresented: $showingSampleQueries) {
      sampleQueriesSheet
    }
    .onAppear {
      messages = TutorChatHistory.load(getterSetter: Current.getterSetter)
      Current.analytics.signal(name: .viewTutorView)
    }
    .task {
      hasLoadedHistory = true
    }
    .onDisappear {
      Current.languageModelService.resetTutorSession()
    }
    .onChange(of: isInputFocused) {
      if isInputFocused {
        showingHint = false
      }
    }
  }

  private var sampleQueriesSheet: some View {
    NavigationStack {
      ZStack {
        Color.customBackground.ignoresSafeArea()
        ScrollView {
          VStack(spacing: Layout.defaultSpacing) {
            ForEach(Self.suggestions, id: \.self) { suggestion in
              Button {
                inputText = suggestion
                isInputFocused = true
                showingSampleQueries = false
              } label: {
                Text(suggestion)
                  .fixedSize(horizontal: false, vertical: true)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              .font(.subheadline)
              .foregroundStyle(Color.customBlue)
              .padding(.horizontal, Layout.defaultSpacing + 4)
              .padding(.vertical, Layout.defaultSpacing / 2)
              .background(
                Capsule()
                  .strokeBorder(Color.customBlue.opacity(0.4))
              )
            }
          }
          .padding(Layout.doubleDefaultSpacing)
        }
      }
      .navigationTitle(L.Tutor.getSampleQuery)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(L.Alert.okay) {
            showingSampleQueries = false
          }
        }
      }
    }
  }

  private var typingIndicator: some View {
    HStack {
      HStack(spacing: 4) {
        ForEach(0..<3, id: \.self) { index in
          Circle()
            .fill(Color.secondary)
            .frame(width: 6, height: 6)
            .opacity(0.5)
            .phaseAnimator([false, true], trigger: isGenerating) { content, phase in
              content.offset(y: phase ? -4 : 0)
            } animation: { _ in
              .easeInOut(duration: 0.4).delay(Double(index) * 0.15)
            }
        }
      }
      .padding(Layout.defaultSpacing + 4)
      .background(
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
          .fill(Color.customCardBackground)
          .shadow(radius: 1)
      )
      Spacer(minLength: 60)
    }
  }

  private func messageBubble(_ message: TutorMessage) -> some View {
    HStack {
      if message.role == .user {
        Spacer(minLength: 60)
      }

      Text(message.content)
        .foregroundStyle(message.role == .user ? Color.customBackground : Color.customForeground)
        .padding(Layout.defaultSpacing + 4)
        .background(
          RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(message.role == .user ? Color.customBlue : Color.customCardBackground)
            .shadow(radius: 1)
        )
        .fixedSize(horizontal: false, vertical: true)

      if message.role == .assistant {
        Spacer(minLength: 60)
      }
    }
  }

  private var inputBar: some View {
    HStack(spacing: Layout.defaultSpacing) {
      TextField(text: $inputText, prompt: nil, axis: .vertical) {
        Text(verbatim: "")
      }
        .textFieldStyle(.roundedBorder)
        .lineLimit(1...4)
        .focused($isInputFocused)
        .submitLabel(.send)
        .onSubmit { sendMessage() }

      Button {
        sendMessage()
      } label: {
        if isGenerating {
          ProgressView()
            .frame(width: 24, height: 24)
        } else {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title2)
            .foregroundStyle(Color.customBlue)
        }
      }
      .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)
      .accessibilityLabel(L.Tutor.send)
    }
    .padding(Layout.doubleDefaultSpacing)
    // Cap the input controls to the same reading-width column as the chat, but let the
    // background fill the full width so the bar still reads as a footer edge-to-edge.
    .readingWidth()
    .background(Color.customBackground)
  }

  private func sendMessage() {
    let trimmed = inputText.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty, !isGenerating else {
      return
    }

    Current.analytics.signal(name: .tapSendTutorMessage)
    let userMessage = TutorMessage(role: .user, content: trimmed)
    messages.append(userMessage)
    inputText = ""
    isGenerating = true
    Current.soundPlayer.play(.chirp, shouldDebounce: false)
    saveMessages()

    Task {
      do {
        let response = try await Current.languageModelService.sendTutorMessage(trimmed)
        messages.append(TutorMessage(role: .assistant, content: response))
      } catch {
        messages.append(TutorMessage(role: .assistant, content: L.Tutor.unavailable))
      }
      Current.soundPlayer.play(.chirp, shouldDebounce: false)
      isGenerating = false
      saveMessages()
    }
  }

  private func saveMessages() {
    TutorChatHistory.save(messages, getterSetter: Current.getterSetter)
  }
}
