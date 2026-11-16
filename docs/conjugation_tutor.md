# Conjugation Tutor (on-device LLM)

A Spanish conjugation tutor: a chat screen (`Views/TutorView.swift`) backed by
`LanguageModelServiceReal`, which wraps Apple's **on-device** `SystemLanguageModel` /
`LanguageModelSession` from the **Foundation Models** framework. Reached from a section at the
top of the Info tab (`InfoBrowseView`). Files: `Models/LanguageModelService.swift` (protocol +
`TutorMessage` + `LanguageModelUnavailability`), `LanguageModelServiceReal.swift`,
`LanguageModelServiceDummy.swift`, `TutorChatHistory.swift`, `Views/TutorView.swift`,
`Views/TutorTestView.swift`. Things to know when working on it:

- **Grounded, never hallucinated.** The model is given one `Tool` (`ConjugationTool`, in
  `LanguageModelServiceReal.swift`) that looks up real forms through the app's own engine —
  `VerbMap.shared.entry(for:)` to validate the verb, then `TenseBridge.conjugate(...)` per
  person. Because the whole engine is `nonisolated`, the tool's `nonisolated` `call` invokes
  it directly, with no `@MainActor` hop. A tolerant `displayTense(forName:)` maps a Spanish
  **or** English tense name onto `DisplayTense`, most-specific compound/subjunctive phrases
  first so "presente de subjuntivo" isn't swallowed by "presente". Marked forms are lowercased
  to strip the red-irregularity UPPERCASE encoding before they reach the model.
- **Prompt is localized by *system language*, not the UI locale.** `LanguageModelServiceReal`
  holds two hand-written instruction blocks and picks Spanish when
  `Locale.current.language.languageCode == "es"`, English otherwise — this steers what
  language the model *answers in*, independent of the `.xcstrings` UI localization. **If you
  change tutor behavior, edit both blocks.**
- **Over-refusal workaround.** The on-device model sometimes refuses conjugation content, so
  `sendTutorMessage` retries up to 3× with a fresh session and screens replies through
  `isLikelyRefusal` (English + Spanish canned-refusal phrases); a persistent refusal falls
  back to `L.Tutor.unableToAnswer`.
- **Availability is live.** The service polls `SystemLanguageModel.availability` every 5 s and
  is `@Observable`, so the Info-tab section flips itself between a tappable `NavigationLink`
  (→ `TutorView`) and a reason row (the "Apple Intelligence not enabled" reason deep-links to
  Settings). **In the simulator the model is unavailable**, so the tutor screen isn't even
  reachable there — the chat and the `TutorTestView` batch harness can only be *exercised* on
  a real Apple-Intelligence device.
- **`TutorTestView`** is a batch harness (runs ~30 Spanish/English queries, one per fresh
  session, `ShareLink`-exports the results) reached by a **triple-tap on the tutor's title**.
  It is deliberately **not** behind `#if DEBUG` — it ships. Its hardcoded strings use
  `Text(verbatim:)` to stay out of the string catalog.
- **iOS 26 only.** The Foundation Models types are guarded `@available(iOS 26, *)` +
  `#if canImport(FoundationModels)`, but since the deployment target is already iOS 26 the
  service is instantiated unconditionally in `World`. Editing this code trips a swarm of bogus
  SourceKit "only available in macOS 26 / cannot find type" diagnostics — all stale-index
  noise; trust `xcodebuild`, which compiles it cleanly.
- Chat history persists through `Current.getterSetter` (`TutorChatHistory.swift`).
