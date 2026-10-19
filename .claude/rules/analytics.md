---
paths:
  - "Conjugar/Analytics/**"
  - "ConjugarTests/Analytics/**"
  - "docs/privacy_policy3.txt"
---

# Analytics (TelemetryDeck)

Conjugar uses the same analytics schema as the sibling apps Conjuguer and Konjugieren.
Files: `Analytics/Analytics.swift` (the `Analytics`
protocol plus the `AnalyticsName` / `ParameterKey` enums), `AnalyticsReal.swift`,
`AnalyticsSpy.swift`.

- **Event names are an enum, not strings.** `Current.analytics.signal(name: .viewVerbView)`;
  parameters are `[String: String]` keyed by `ParameterKey.…rawValue`. **A raw
  value is a wire name** — renaming a case orphans its dashboard history, which is why
  `AnalyticsTests` pins the parameter-carrying ones.
- **The whole family is `nonisolated`,** like the engine. Without it the module's default
  MainActor isolation would make the protocol — and by witness inference every conformer's
  methods — MainActor-isolated, contradicting `AnalyticsReal`'s off-main design and making
  the spy unusable from a nonisolated test suite.
- **`AnalyticsReal` funnels every TelemetryDeck call onto a serial GCD queue.** TelemetryDeck
  2.14.1 uses blocking `DispatchQueue.sync` internally, so calling it from a `@MainActor`
  call site would run that blocking work on the main thread. The queue also orders
  `initialize` ahead of signals and confines `isInitialized` to one thread.
- **The app ID is kept out of the working tree.** It lives in gitignored
  `Conjugar/Secrets.xcconfig` as `TELEMETRY_DECK_APP_ID` (copy `Secrets.example.xcconfig`),
  reaches the bundle through the `TelemetryDeckAppID` Info.plist key — the xcconfig is the
  app target's `baseConfigurationReference` for both Debug and Release — and is read in
  `ConjugarApp.init()` → `Current.analytics.initialize(appID:)`. An empty ID leaves the
  service uninitialized so it silently drops signals; **a fresh clone with no
  `Secrets.xcconfig` still builds and runs.**
- **Only `World.device` gets `AnalyticsReal`;** simulator/unit-test/UI-test worlds get
  `AnalyticsSpy`, which records `signalNames`/`signalParameters` for assertions. So
  **signals never reach the dashboard from a normal simulator run** — the spy is a dead end
  by design.
- **Debug builds land in the dashboard's Test Mode, not the live view.** The SDK's
  `TelemetryDeck.Config.testMode` defaults to the `DEBUG` flag, so everything from Xcode —
  device or simulator — is tagged `isTestMode == true` and is **invisible until you flip the
  Test Mode toggle** (top-left of the dashboard, above the sidebar; a "Test Data" banner
  confirms it). This is the first thing to check when signals seem missing; it is not a bug.
  TestFlight and App Store builds go to the live view with no code change.
- **No `becameActive` signal.** TelemetryDeck records launches and sessions itself, and
  reports app version, device model, and country/language natively.

The published policy describing what is collected is `docs/privacy_policy3.txt` (English
plus a Spanish translation); **update it when you add or remove a signal.**
