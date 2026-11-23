# Feature Architecture

How the features built by [`plans/browse_and_verb_implementation.md`](../plans/browse_and_verb_implementation.md)
and [`plans/pedagogy_implementation.md`](../plans/pedagogy_implementation.md) fit together: what
each piece is, where it lives, and the rules that keep it true. Created 2026-11-22 by Phase 2 of the
browse plan, on the model of Konjugieren's document of the same name. Each phase that changes a
piece described here updates its section, and later phases add theirs: the deeplink grammar
(browse Phase 10), the learner's record (Phase 12), the review card (Phase 15), and the quiz (the
pedagogy plan). The code is the final authority; this document is a map of it.

## Analytics

`Analytics/Analytics.swift` holds every signal name (`AnalyticsName`), parameter key
(`ParameterKey`), and parameter value (`AnalyticsSource`, `SearchOutcome`, `SearchMatchKind`,
`VerbPageSection`, and the bands in `AnalyticsBand`). A raw value is a wire name: renaming a case
orphans its history on the dashboard, so `AnalyticsTests` and `LookupSignalsTests` pin them.
`AnalyticsReal` sends through TelemetryDeck; `AnalyticsSpy` records in the simulator and under
tests. `.claude/rules/analytics.md` has the plumbing's gotchas.

**No signal carries a verb or any typed text,** because the privacy policy promises that. Counts
and durations go out in bands, never as exact numbers. `LookupSignalsTests` checks that no
`finishSearch` parameter can echo the query.

**A new signal, parameter, or value stages its policy lines** in English and Spanish in
[`privacy_policy_pending.md`](privacy_policy_pending.md), never straight into
`privacy_policy3.txt`, because no release can ship before 2027 and Josh may deploy the policy at any
time.

### Lookup signals

Built 2026-11-22 by Phase 2 of the browse plan.

| Signal | Parameters | Sent |
|---|---|---|
| `viewVerbView` | `source` (below) | When a verb page appears: on arrival, and again with `source` `resume` after the page returns from another tab, a pushed page, or the background |
| `leaveVerbView` | `deepestSection` (`header`, `simple`, `compound`, `etymology`, `example`), `dwell` (`0-5s`, `5-15s`, `15-60s`, `60s+`) | Exactly once for each `viewVerbView`: when the page leaves the screen or the app goes to the background |
| `finishSearch` | `outcome` (`opened`, `abandoned`, `noResult`), `queryLength` (`1-2`, `3-5`, `6-9`, `10+`), `resultCount` (`0`, `1`, `2-10`, `11+`), `matchKind` (below), `resultPosition` (`1`, `2-5`, `6+`, `none`) | Once per search of the verb list: when a result or the guess is opened, the field is cleared, or the app goes to the background with text in the field |

**A visit** (`Models/VerbVisit.swift`, `VerbVisit`) is one stretch of a verb page on screen with
the app in the foreground. `VerbView` begins one in `onAppear` and when the app returns to the
foreground while the page is on screen, and ends it in `onDisappear` and when the app goes to the
background. A page's first visit reports the `source` it was pushed with; every later one reports
`resume`, so arrivals are the views whose source is not `resume`, and background time never counts
as reading. A resumed visit starts from the deepest section already on screen. A system alert,
such as the simulator's "Open in Conjugar?", makes the app inactive but not backgrounded, and ends
nothing.

**Reaching a section** means a third of its first card on screen (`onScrollVisibilityChange`,
threshold 0.3): the header needs nothing; `simple` is the first simple tense's card (Presente de
Indicativo); `compound` is the first compound tense's card (Perfecto de Indicativo); then the
etymology card and the examples card. `VerbView.section(markedBy:)` reads the first of each block
from `DisplayTense.conjugatedTenses`, so a reordering (Phase 6) moves the marks with it. On an
iPhone the Presente card shows without scrolling, so `header` alone will be rare.

**A search** (`Models/SearchReport.swift`, `SearchTracker` and `SearchReport`) begins with the
first non-blank letter in the Verbs tab's field and ends once. Returning to the results and opening
a second verb without editing sends no second `finishSearch`, though the page still reports
`search`; editing the text begins a new search. An abandoned search's `matchKind` is that of the
top result it passed over. Opening the guess reports `opened`, `resultCount` `0`, `matchKind`
`guess`, and position `1`, and the page reports `searchGuess`. Return and the arrow keys (iPad and
Mac) count as ordinary opens. The Models tab's search sends nothing.

`matchKind` values are `VerbSearch.MatchKind`'s nine cases by name (`exactInfinitive`,
`exactFoldedInfinitive`, `exactGlossSense`, `infinitivePrefix`, `wholeWordGloss`,
`infinitiveSubstring`, `foldedInfinitivePrefix`, `foldedInfinitiveSubstring`, `glossSubstring`),
plus `guess` and `none`. The mapping (`MatchKind.analyticsValue`) is an exhaustive switch, so a new
match kind cannot go unnamed. `conjugation` and `foldedConjugation` are in the vocabulary for
Phase 5's reverse lookup and are not sent yet.

### The `source` vocabulary

`AnalyticsSource` is one vocabulary for every signal that carries `source`. Today only
`viewVerbView` does. Phase 13 adds it to the quiz signals, and Konjugieren's later phases added it
to `finishSearch` too (where the search began); this app's Phase 10 or 11 may do the same.

| Value | Sent today? | Meaning |
|---|---|---|
| `browse` | Yes | A row of the verb list with the search field empty |
| `control` | Yes | The Random Verb control in Control Center (`OpenRandomVerbControlIntent`) |
| `deeplink` | Yes | A `conjugar://` link with no recognized `source` query item |
| `infoLink` | No | Reserved for a link from an Info article to a verb |
| `list` | No | Phase 16: a verb opened from a collection |
| `lookup` | No | Phase 11: the Look Up a Verb intent |
| `model` | Yes | A verb row on a model's page in the Models tab |
| `myVerbs` | No | Phase 12: the My Verbs list |
| `quickAction` | No | Phase 10: a Home Screen quick action |
| `recent` | No | Phase 12: the recent verbs |
| `related` | No | Phase 8: another verb's page |
| `resume` | Yes | A page that came back after another tab, a pushed page, or the background |
| `reviewCard` | No | Phase 15: the review card |
| `search` | Yes | A result of a search that found something |
| `searchGuess` | Yes | The closest verb offered by a search that found nothing |
| `sharedLink` | No | Phase 16: a shared collection's link |
| `shortcut` | Yes | Open Random Verb run from the Shortcuts app or Siri (`OpenRandomVerbIntent`) |
| `spotlight` | No | Phase 11: a Spotlight result |
| `tab` | No | Phase 13: a quiz begun from the Quiz tab |
| `verbPage` | No | Phase 13: a quiz begun from a verb's page |
| `widget` | Yes | A tap on any widget: Verb of the Day, the quiz widget, or a Lock Screen accessory |

**How the source travels.** The Verbs and Models tabs push a `VerbDestination` (infinitive plus
source) rather than a bare infinitive, and `VerbView(verb:source:)` takes it. The verb list's rows
are buttons, not `NavigationLink`s, so that an open can send `finishSearch` before it pushes.

**Links carry `source` as a query item** (`conjugar://verb/hablar?source=widget`), because a widget
or an intent can hand the app only a URL. `AppRouter.handle(url:)` reads it through
`URL.analyticsSource` and falls back to `deeplink` when it is missing or unknown.
`WidgetDeeplink.verb(_:)` adds `source=widget`; `OpenRandomVerbIntent` stashes
`conjugar://verb/random?source=shortcut` and `OpenRandomVerbControlIntent`
`…?source=control`. Phase 10's deeplink grammar should keep this query item.

**A verb link may name a pronominal verb with its "se"** (`conjugar://verb/arrepentirse`), which
opens the bare infinitive the map keys on (browse Phase 3). The widgets name a reflexive-only verb
that way, because they show it as the app does.

**The control has its own intent.** An intent cannot tell whether the control or a shortcut ran
it, so the Random Verb control runs `OpenRandomVerbControlIntent` (`Shared/`, hidden from
Shortcuts with `isDiscoverable = false`, sharing the title key), and `OpenRandomVerbIntent` is
left to the Shortcuts app and Siri. Konjugieren found the same in its Phase 3.

**Any new way to reach a verb page** sets its `source` value (adding it here and to the enum if it
is new) and stages a policy line if its kind of surface is not already named.

## Conjugation Map

Built 2026-11-22 by Phase 4 of the browse plan, porting Konjugieren's Phase 5. Phase 5 here (reverse
lookup in search) reads it; the pedagogy plan's Phases 3, 13, and 16 call `ConjugationMatch`.

**What it is.** `ConjugationMap` (`Models/ConjugationMap.swift`) maps every one-word form of every
verb to the verbs and cells it belongs to: fue → ir and ser, each in the pretérito (él). A cell is a
`ConjugationCell`, a `DisplayTense` and a `DisplayPersonNumber`, so a result names itself in the
verb page's own vocabulary. The one-word cells (`ConjugationMap.oneWordCells`, 72 of them) are the
infinitive, the gerund, the participle, the nine simple tenses in all seven persons (vos included),
and the imperativo positivo's six. Compound tenses and the imperativo negativo have no entries,
because their last word (a participle, a subjunctive) does. Forms are the engine's bare forms,
lowercased (the uppercase irregularity marking is highlighting), accents as written: "hablo" finds
only hablar's presente (yo), never habló. A reflexive-only verb is stored bare (arrepiento), so
Phase 5 must strip a pronoun before looking up. 254,328 forms, 293 of them shared by two verbs.

**How it is built.** `ConjugationMapTool` is a macOS command-line target that compiles the engine
from the app's own sources (listed as membership exceptions on the `Models` folder in
`project.pbxproj`) plus `ConjugationMap.swift`. The app target depends on it, so an iOS build builds
it for the Mac first, and the app's "Generate Conjugation Map" Run Script phase (after Resources)
runs it, writing `ConjugationMap.lzfse` straight into the app bundle. Nothing generated is
committed. The phase's inputs are `verbModelMap.xml` and the tool's executable, which stands in
for every engine source: an engine code change relinks the tool and reruns the phase; a
comment-only change recompiles without relinking and does not. An unchanged build skips the phase.
Judge that by the timestamps of the tool and the map, not by the build log. The tool reads
`verbModelMap.xml` through `VerbMap.resourceURLOverride`, since it has no bundle. It is built
optimized even in Debug (2.9 seconds to run, against 9.8 unoptimized) and with code coverage off,
because an instrumented tool writes a `default.profraw` into the repository each time the phase
runs it.

**The file** is one line per verb: the infinitive, then each cell's form as a delta from it (the
letters to drop from its end, then the letters to add: hablar's hablo is `2o`, ir's voy is `2voy`),
"-" for a defective verb's empty slot. Every regular verb of a conjugation writes the same line,
so 1.8 MB of text compresses to 43 KB. One line per form, as Konjugieren writes it, came to
1.4 MB. Loading inverts the paradigms into the form index; `ConjugationMap.bundled` is a
`nonisolated static let`, so Phase 5 can touch it first from a background task.

**Which cells of a verb a text is** is `ConjugationMatch.cells(of:equalTo:accents:)`
(`Models/ConjugationMatch.swift`). It conjugates every displayed cell of the one verb rather than
reading the map, so compounds ("ha hablado") and negative commands ("no hables") match too. It is
exact by default; `.folded` ignores acute accents and the diaeresis but keeps ñ, so the quiz can tell
an accent slip from an accent that marks another tense (hablo for habló is the presente, a real
error). Case and runs of spaces never count, a reflexive-only verb matches with its pronoun or
without, and a verb not in `VerbMap` matches nothing. It makes about 150 engine calls, so call it to
judge an answer, not per keystroke.

**The corpus files.** The same tool writes `corpus/working/forms.json` (the 1,000 most common verbs)
and `forms_all.json` for the Python pipelines, through `scripts/write_forms_json.sh`. It replaced
the disabled `CorpusFormsDumpTests` harness, whose last `forms_all.json` it reproduced byte for
byte.

**Tests.** `ConjugationMapTests` compares the bundled map with a fresh in-process build of every
verb, which catches an engine dependency the tool does not compile, and measures the map against
`ExampleUses.json` (see the Phase 4 note in the browse plan for the exact measure).
