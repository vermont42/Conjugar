---
paths:
  - "ConjugarTests/**"
---

# ConjugarTests

## XCTest + MainActor: the isolated-deinit crash (write new tests in Swift Testing)

> **Landmine (Xcode 26.3).** Under `SWIFT_DEFAULT_ACTOR_ISOLATION =
> MainActor`, every pure-Swift `@MainActor` class gets an *isolated deinit*, and this
> toolchain's `swift_task_deinitOnExecutorImpl` **double-frees** (`malloc: pointer being
> freed was not allocated` → SIGABRT) when **XCTest** deallocates such an object at
> teardown. It fires mostly through `World.deinit` releasing its `@MainActor` service
> members when a test reassigns `Current` in `setUp`. It is **test-only** — the shipping
> app never deallocates `World` (a `Current` singleton) — and **Swift Testing does not
> trigger it** (Konjugieren's all–Swift Testing suite is why it never hit this).
>
> **Convention: write new tests as Swift Testing** (`@Suite`/`@Test`/`#expect`), not
> XCTest. Add `@MainActor` to a suite that touches MainActor types; leave engine suites
> nonisolated (they touch only the nonisolated engine). `@Test(arguments:)` collections
> are evaluated *outside* the suite's isolation, so any static data they reference must
> be `nonisolated`.
>
> A full `xcodebuild … test` run passes today (all XCTest + Swift Testing, 0 failures), but
> the rule still stands, since MainActor default isolation remains: a new pure-Swift
> `@MainActor` object deallocated by XCTest will hit the same double-free — so **write new
> tests in Swift Testing.**
