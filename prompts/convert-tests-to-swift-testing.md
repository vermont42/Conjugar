# Task: Convert the Conjugar engine tests from XCTest to Swift Testing

You are starting a fresh session on the **Conjugar parsimony project** (see
`CLAUDE.md` for the overall goal). This is an **infrastructure / test-hygiene
task, not engine work**: migrate the new-engine test file from **XCTest** to
**idiomatic Swift Testing** (`import Testing`, `@Test`, `#expect`, and
**`@Test(arguments:)` parameterization**). Do **not** change any conjugation
logic, add features, or alter expected forms — the oracle values and coverage
must come through **identical**. This is not a token-for-token port: the success
criterion is "same assertions, same results, expressed the idiomatic Swift
Testing way" — in particular the per-person paradigms become parameterized tests
(see below), not loops over a helper.

> **Use the `swift-testing-expert` skill.** This machine has the Swift Testing
> Agent Skill installed (`swift-testing-expert:swift-testing-expert`). Invoke it
> at the start of the session and lean on it throughout — it is the authority on
> idiomatic structure, `#expect`/`#require`, traits/tags, `@Test(arguments:)`
> parameterization, parallel execution, and XCTest→Swift Testing migration.
> Where its guidance is more specific than this prompt, follow the skill; this
> prompt fixes the *what* (the file, the coverage, the sequencing), the skill
> informs the *how*.

## Scope

- **Convert exactly one file:** `ConjugarTests/Models/Conjugator2Tests.swift`
  (the composition-engine tests — 56 `func test…` methods after Phase 4,
  0 failures).
- **Leave the old-engine XCTest files alone.** `ConjugarTests/` has ~35 other
  XCTest files (`ConjugatorTests.swift`, the controller/UIView tests, etc.) that
  exercise the *old* engine and UI. Swift Testing and XCTest **coexist in the
  same test target and the same `xcodebuild test` run**, so there is no need to
  touch them — and they'll be removed wholesale when the old engine is retired.
  Converting only `Conjugator2Tests.swift` keeps this diff small and reviewable.

## Why

Swift Testing is the modern, first-party framework (bundled with Xcode 16+; the
build machine is on **Xcode 26.3**, so it's available). For this codebase the
concrete wins are: `#expect(a == b)` shows both operands on failure with no
custom message plumbing; suites are plain `struct`s (value-typed, fresh instance
per test, no `setUp`/`tearDown` ceremony); and the paradigm assertions become
natural **parameterized tests**. The engine is pure and stateless, so it's an
ideal first candidate.

## Where things stand (read before converting)

`Conjugator2Tests.swift` today:

- `import XCTest` + `@testable import Conjugar`.
- `final class Conjugator2Tests: XCTestCase` with 56 `func test…()` methods
  (Phase 1 regulars + voseo + validation; Phase 2 orthographic/accent; Phase 3
  stem-vowel/raising; Phase 4 1s/preterite/future + the tener capstone).
- One instance property: `private let persons = PersonNumber2.oracleOrder`.
- **Five private helpers** that everything routes through:
  - `assertEqual(_ infinitive:, _ tense:, _ expected:, file:line:)` — regular
    (no-model) conjugation, `XCTAssertEqual` of the `.success` form.
  - `assertEqual(_ infinitive:, _ model:, _ tense:, _ expected:, file:line:)` —
    model-taking overload.
  - `assertParadigm(_ infinitive:, _ tense:, _ expected:[String], file:line:)`
    and its **model-taking overload** — loop over `persons`, one `assertEqual`
    per person.
  - `assertFailure(_ result:, _ expected:, file:line:)` — asserts a
    `.failure(Conjugator2Error)` (used by `testInvalidInput` and
    `testNonSecondPersonImperativeIsUnavailable`).

Both `assertEqual`/`assertParadigm` thread `file: StaticString = #filePath,
line: UInt = #line` so failures point at the call site, not the helper.

## How to convert (the mechanical mapping)

1. **Imports.** Replace `import XCTest` with `import Testing`. Keep
   `@testable import Conjugar`.
2. **Suite type.** Turn `final class Conjugator2Tests: XCTestCase` into a
   `struct Conjugator2Tests` (optionally annotated `@Suite("Conjugator2 (new
   engine)")`). A struct gives a fresh instance per test; the `persons` stored
   `let` stays as-is.
3. **Test methods.** Mark each test `@Test`, drop the `test` prefix from the
   name, and give it a human display name, e.g. `@Test("tener capstone")
   func tenerCapstone()`.
4. **Assertions.** `XCTAssertEqual(a, b, msg)` → `#expect(a == b, "\(msg)")`.
   There is no `XCTFail` — use `Issue.record("…")` for an unconditional failure.
5. **Replace the loop helpers with one form-expect helper.** The two
   `assertParadigm` overloads (which loop over `persons`) are superseded by
   `@Test(arguments:)` (step "Parameterize" below) — remove them. Keep a single
   small helper that conjugates one slot and `#expect`s it, used as the body of
   every parameterized test, with source location forwarded (XCTest's
   `file:/line:` becomes Swift Testing's single `sourceLocation:` parameter):
   ```swift
   private func expectForm(
     _ infinitive: String,
     model: VerbModel2? = nil,
     _ tense: Tense2,
     _ expected: String,
     sourceLocation: SourceLocation = #_sourceLocation
   ) {
     let result = model.map { Conjugator2.conjugate(infinitive: infinitive, tense: tense, model: $0) }
       ?? Conjugator2.conjugate(infinitive: infinitive, tense: tense)
     switch result {
     case let .success(form):
       #expect(form == expected, "\(infinitive) \(tense)", sourceLocation: sourceLocation)
     case let .failure(error):
       Issue.record("\(infinitive) \(tense) unexpectedly failed: \(error)", sourceLocation: sourceLocation)
     }
   }
   ```
6. **The failure-path helper.** Rewrite `assertFailure` without `XCTFail`:
   ```swift
   private func assertFailure(
     _ result: Result<String, Conjugator2Error>,
     _ expected: Conjugator2Error,
     sourceLocation: SourceLocation = #_sourceLocation
   ) {
     guard case let .failure(error) = result else {
       Issue.record("Expected failure \(expected).", sourceLocation: sourceLocation)
       return
     }
     #expect(error == expected, sourceLocation: sourceLocation)
   }
   ```
   (`testInvalidInput` also has an inline `if case .success … XCTFail` — convert
   that to `Issue.record`, or fold it into the same `guard case .failure` shape.)

### Required: parameterize (the idiomatic conversion)

`assertParadigm` is a textbook parameterized test, so the conversion **must** use
`@Test(arguments:)` rather than looping a helper. Two patterns cover everything:

- **Single-paradigm slots** — parameterize over `zip(persons, expected)`:
  ```swift
  @Test("cantar — presente de indicativo", arguments: zip(
    PersonNumber2.oracleOrder,
    ["canto", "cantas", "canta", "cantamos", "cantáis", "cantan"]))
  func cantarPresent(person: PersonNumber2, expected: String) {
    expectForm("cantar", .presenteDeIndicativo(person), expected)
  }
  ```
  For a model-bearing verb, build the model inside the body (it's pure and cheap,
  so rebuilding per case is fine):
  ```swift
  @Test("tener — presente de indicativo", arguments: zip(
    PersonNumber2.oracleOrder,
    ["tengo", "tienes", "tiene", "tenemos", "tenéis", "tienen"]))
  func tenerPresent(person: PersonNumber2, expected: String) {
    expectForm("tener", model: Self.tener, .presenteDeIndicativo(person), expected)
  }
  ```

- **Mixed-paradigm / multi-tense methods** (the capstones, the composition tests
  that assert several tenses + singletons in one XCTest method) — parameterize
  over `(Tense2, String)` pairs so every slot is its own reported case and the
  whole verb is one `@Test`:
  ```swift
  @Test("tener — capstone (whole phase)", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "tengo"),
    (.presenteDeIndicativo(.secondSingular), "tienes"),
    // … PI, PS, PR, IS, FU, CO slots …
    (.condicional(.firstSingular), "tendría"),
  ])
  func tenerCapstone(tense: Tense2, expected: String) {
    expectForm("tener", model: Self.tener, tense, expected)
  }
  ```

Guidance for a clean result:
- Hoist any model that several `@Test`s share to a `static let` on the suite
  (e.g. `Self.tener`) so it's defined once, not per method.
- Prefer splitting a multi-paradigm XCTest method into **one parameterized
  `@Test` per tense** where that reads cleanly (e.g. the regular-root indicative/
  subjunctive methods); use the `(Tense2, String)` pattern when a verb's point is
  the *interaction across* tenses (capstones, last-wins/reset cases).
- The non-finite singletons (PP, GER, IMP 2s/2p) and the validation/failure tests
  stay plain (non-parameterized) `@Test`s — don't contort them into `arguments:`.
- **Coverage is invariant:** every (verb, tense, person, expected) tuple asserted
  by the XCTest version must still be asserted. Parameterization changes how cases
  are *reported*, never *which* forms are checked. Diff method-by-method against
  the original to prove nothing was dropped.

## Gotchas

- **Parallel + random order by default.** Swift Testing runs tests in parallel,
  in randomized order. This engine is pure (`Conjugator2` is a stateless `enum`;
  the suite holds only a `let`), so that's safe — do **not** add `.serialized`
  unless you actually observe a data race (you won't here).
- **The reported case count will rise** (one per `arguments:` element), and
  that's expected — parameterization expands each paradigm into per-slot cases.
  Don't chase the old "56 tests" number; chase **0 failures** and **identical
  coverage** (every form the XCTest version checked is still checked).
- **`#expect` vs `#require`.** Use `#expect` for ordinary checks (continues on
  failure). Reserve `#require` (throws, halts the test) for preconditions where
  continuing is meaningless — not needed for these value comparisons.
- **No behavior change.** The structure changes (parameterization), but **no
  expected string may change** — the forms are oracle-verified. If an expected
  value moved, you've made a mistake.

## Method (build/test mechanics)

The standalone `swiftc` driver (see other phase prompts) tests *engine* sources,
not the XCTest/Testing file, so it's unaffected. Validate the conversion through
the real test target:

```
cd /Users/josh/Desktop/workspace/Conjugar.mig
xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
  -destination 'platform=iOS Simulator,id=<an available iPhone sim>' \
  -only-testing:ConjugarTests/Conjugator2Tests
```

(`xcrun simctl list devices available | grep iPhone` for a sim id.) The
`-only-testing:ConjugarTests/Conjugator2Tests` selector addresses the Swift
Testing suite by type name exactly as it did the XCTest class. Confirm **every
assertion still passes (0 failures)** and that the same verbs/tenses are covered
— diff the converted file against the original method-by-method to prove nothing
was dropped. The file auto-compiles (synchronized folders); no `project.pbxproj`
edit.

## Deliverable

- `Conjugator2Tests.swift` converted to Swift Testing, **all assertions green**
  via the real test target, coverage provably identical to the XCTest version.
- A one-line entry in `docs/blog_notes.md` under today's date.
- A clean **commit on `migration`** (e.g. "Convert Conjugator2 tests to Swift
  Testing"), **push only if the user asks**. End the commit message with the
  repo's Co-Authored-By trailer.

## Note on sequencing

**Do this before Phase 5.** Phase 5 (residue + full assembly) assumes the suite
is already Swift Testing and will add its new tests directly in this style —
parameterized `@Test`s reusing the `expectForm` helper and the `static let`
shared models. Converting first means Phase 5 writes idiomatic tests from the
start instead of porting a fresh batch of XCTest methods afterward. The engine
phases 1–4 are already complete and committed, so this conversion has the full
56-method suite to work from and nothing depends on it landing in any particular
engine state.
