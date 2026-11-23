# Feature Architecture

How the features built by [`plans/browse_and_verb_implementation.md`](../plans/browse_and_verb_implementation.md)
and [`plans/pedagogy_implementation.md`](../plans/pedagogy_implementation.md) fit together: what
each piece is, where it lives, and the rules that keep it true. Created 2026-11-22 by Phase 2 of the
browse plan, on the model of Konjugieren's document of the same name. Each phase that changes a
piece described here updates its section, and later phases add theirs: the deeplink grammar
(browse Phase 10, § Deeplinks), the learner's record (Phase 12), the review card (Phase 15), and the quiz (the
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
| `finishSearch` | `source` (where the search began: `tab`, `control`, `quickAction`, or `deeplink`; since Phase 10), `outcome` (`opened`, `abandoned`, `noResult`), `queryLength` (`1-2`, `3-5`, `6-9`, `10+`), `resultCount` (`0`, `1`, `2-10`, `11+`), `matchKind` (below), `resultPosition` (`1`, `2-5`, `6+`, `none`) | Once per search of the verb list: when a result or the guess is opened, the field is cleared, or the app goes to the background with text in the field |

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
from `ConjugationTable` (Phase 6), the page's own order, so a reordering moves the marks with it.
On an iPhone the Presente card shows without scrolling, so `header` alone will be rare.

**A search** (`Models/SearchReport.swift`, `SearchTracker` and `SearchReport`) begins with the
first non-blank letter in the Verbs tab's field and ends once. Returning to the results and opening
a second verb without editing sends no second `finishSearch`, though the page still reports
`search`; editing the text begins a new search. An abandoned search's `matchKind` is that of the
top result it passed over. Opening the guess reports `opened`, `resultCount` `0`, `matchKind`
`guess`, and position `1`, and the page reports `searchGuess`. Return and the arrow keys (iPad and
Mac) count as ordinary opens. The Models tab's search sends nothing.

**Where a search began** (Phase 10) is the surface that opened the field: `SearchTracker.fieldOpened(from:)`
records it when the Find a Verb control, the quick action, or a `search` link opens the field, and
the first letter typed (or a link's own text) begins a search with that source. A search in
progress when another surface opens the field ends there. A field that closes with nothing typed
forgets the surface, so a later search typed into it is `tab`, as is any search begun in the tab,
Command-F included.

`matchKind` values are `VerbSearch.MatchKind`'s eleven cases by name (`exactInfinitive`,
`exactFoldedInfinitive`, `exactGlossSense`, `conjugation`, `foldedConjugation`,
`infinitivePrefix`, `wholeWordGloss`, `infinitiveSubstring`, `foldedInfinitivePrefix`,
`foldedInfinitiveSubstring`, `glossSubstring`), plus `guess` and `none`. The mapping
(`MatchKind.analyticsValue`) is an exhaustive switch, so a new match kind cannot go unnamed.
`conjugation` and `foldedConjugation` are a form of the verb (Phase 5's reverse lookup); a guess
made from a form is still `guess`. Rows and verbs correspond one to one, as before, so
`resultCount` and `resultPosition` mean what they did.

### Other verb-page signals

| Signal | Parameters | Sent |
|---|---|---|
| `tapTenseArticle` | None | When the ⓘ beside a tense's heading on a verb page opens that tense's article (Phase 6). The article itself also sends `viewInfoView`. It does not say which tense or which verb |
| `tapShareVerb` | None | On each tap of the share button in a verb page's navigation bar (Phase 9), whether or not the learner then shares. It does not say which verb. Copying a form, by a long press or from the share sheet, sends nothing |

### The `source` vocabulary

`AnalyticsSource` is one vocabulary for every signal that carries `source`. Today `viewVerbView`
does, and since Phase 10 `finishSearch` too, where it names the surface that opened the search
field. Phase 13 adds it to the quiz signals.

| Value | Sent today? | Meaning |
|---|---|---|
| `browse` | Yes | A row of the verb list with the search field empty |
| `control` | Yes | The Random Verb control in Control Center (`OpenRandomVerbControlIntent`); for `finishSearch`, the Find a Verb control (`OpenVerbSearchIntent`, Phase 10) |
| `deeplink` | Yes | A `conjugar://` link with no recognized `source` query item; for `finishSearch`, a `search` link |
| `infoLink` | No | Reserved for a link from an Info article to a verb |
| `list` | No | Phase 16: a verb opened from a collection |
| `lookup` | Yes | The Look Up a Verb shortcut (Phase 11): for `viewVerbView`, the page it opened when one verb answered; for `finishSearch`, the search it opened otherwise |
| `model` | Yes | A verb row on a model's page, in the Models tab or reached from a verb page's pill |
| `myVerbs` | No | Phase 12: the My Verbs list |
| `quickAction` | Yes | `finishSearch` only: a search begun from the Find a Verb Home Screen quick action (Phase 10) |
| `recent` | No | Phase 12: the recent verbs |
| `related` | Yes | A chip on a verb page's Related Verbs card, or a row of the full list it opens (Phase 8) |
| `resume` | Yes | A page that came back after another tab, a pushed page, or the background |
| `reviewCard` | No | Phase 15: the review card |
| `search` | Yes | A result of a search that found something |
| `searchGuess` | Yes | The closest verb offered by a search that found nothing |
| `sharedLink` | No | Phase 16: a shared collection's link |
| `shortcut` | Yes | Open Random Verb run from the Shortcuts app or Siri (`OpenRandomVerbIntent`, offered as the Random Verb shortcut since Phase 11) |
| `spotlight` | Yes | A tap on a verb's Spotlight entry (Phase 11) |
| `tab` | Yes | `finishSearch`: a search begun in the Verbs tab itself, Command-F included (Phase 10). Phase 13: a quiz begun from the Quiz tab |
| `verbPage` | No | Phase 13: a quiz begun from a verb's page |
| `widget` | Yes | A tap on any widget: Verb of the Day, the quiz widget, or a Lock Screen accessory |

**How the source travels.** The Verbs and Models tabs push a `VerbDestination` (infinitive plus
source) rather than a bare infinitive, and `VerbView(verb:source:)` takes it. The verb list's rows
are buttons, not `NavigationLink`s, so that an open can send `finishSearch` before it pushes.

**Links carry `source` as a query item** (`conjugar://verb/hablar?source=widget`), because a widget
or an intent can hand the app only a URL. `AppRouter.handle(url:)` reads it through
`URL.analyticsSource` and falls back to `deeplink` when it is missing or unknown.
`WidgetDeeplink.verb(_:)` adds `source=widget`; `OpenRandomVerbIntent` stashes
`conjugar://verb/random?source=shortcut`, `OpenRandomVerbControlIntent` `…?source=control`, and
`OpenVerbSearchIntent` `conjugar://search?source=control`. § Deeplinks has the grammar.

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
`nonisolated static let`, which Phase 5's `ConjugationIndex.bundled` touches from a background
task when the Verbs tab appears.

**Which cells of a verb a text is** is `ConjugationMatch.cells(of:equalTo:accents:)`
(`Models/ConjugationMatch.swift`). It conjugates every displayed cell of the one verb rather than
reading the map, so compounds ("ha hablado") and negative commands ("no hables") match too. It is
exact by default; `.folded` ignores acute accents and the diaeresis but keeps ñ, so the quiz can tell
an accent slip from an accent that marks another tense (hablo for habló is the presente, a real
error). Case and runs of spaces never count, a reflexive-only verb matches with its pronoun or
without, and a verb not in `VerbMap` matches nothing. It makes about 150 engine calls, so call it to
judge an answer, not per keystroke. The one exception is search's several-word queries ("he
hablado"), which call it for the one or two verbs whose form the last word is, a few milliseconds.

**The corpus files.** The same tool writes `corpus/working/forms.json` (the 1,000 most common verbs)
and `forms_all.json` for the Python pipelines, through `scripts/write_forms_json.sh`. It replaced
the disabled `CorpusFormsDumpTests` harness, whose last `forms_all.json` it reproduced byte for
byte.

**Tests.** `ConjugationMapTests` compares the bundled map with a fresh in-process build of every
verb, which catches an engine dependency the tool does not compile, and measures the map against
`ExampleUses.json` (see the Phase 4 note in the browse plan for the exact measure).

## Reverse Lookup

Built 2026-11-22 by Phase 5 of the browse plan, porting Konjugieren's Phase 6. A form typed into the
Verbs tab's search finds its verb, and each result names what it matched.

**The pieces.** `ConjugationIndex` (`Models/ConjugationIndex.swift`) indexes the conjugation map by
folded spelling (so "hablo" also reaches habló, "sueno" sueño) and by first letter and length (for
the guess). `ConjugationIndex.bundled` takes about a second to build, so `VerbBrowseView` builds it
in a detached task when it appears. `FormLookup.forms(for:)` (`Models/FormLookup.swift`) returns,
for each verb, the `MatchedForm`s a query is: the form as the app spells it, its cells in page order,
and whether it matched only after folding. `VerbSearch.matches(for:in:index:)` calls it and gives
each such verb the kind `conjugation` (some form matched as written) or `foldedConjugation`, with
its forms in `Match.forms`, literal ones first. `VerbSearch.guess(for:in:index:)` replaces
`closestVerb` as the empty state's guess. Both are `nonisolated` and take the entries to search, so
Phase 11's `VerbLookup` calls them from outside the view (§ App Shortcuts and Spotlight).

**What a query may be.** One word is looked up as written and folded; with up to two enclitic
pronouns split off a command, gerund, or infinitive (dímelo, levántate, diciéndole, vámonos,
levantaos, idos, decírselo), each candidate rejoined through `ReflexivePronoun.enclitic` and kept
only if it gives back the word; and as a participle with a feminine or plural ending (hecha, rotos,
dichas), only if the -o form is a participle cell. Several words: a leading subject pronoun is
dropped and narrows the persons ("ella hable"); the whole text is confirmed by `ConjugationMatch`
for the verbs whose form the last word is ("he hablado", "no hables", "me arrepiento"); failing
that, a leading "no" and object pronouns are dropped ("se lo dije", "me levanto"); failing that, a
non-finite last word finds its verb ("estoy hablando", "voy a comer").

**Ranking.** The two conjugation kinds sit after `exactGlossSense` and before `infinitivePrefix`.
"come" keeps Josh's Phase 0 order (llegar, venir, acudir) and then gives comer, ahead of comenzar;
"listen" finds escuchar before listar; "ve" finds ir and ver before venir and verter. Unlike
Konjugieren, `foldedConjugation` comes right after `conjugation` rather than below every literal
kind, so "de", "se", and "esta" find dar, saber and ser, and estar before the hundreds of verbs that
begin with those letters.

**Naming.** `MatchedForm.line(hiding:)` gives "hablo: Presente de Indicativo (yo)", groups joined by
" · ", in the page's Spanish tense names, with a command's third persons as usted and ustedes. Where
tú and vos share a form in one tense, the person the browse setting hides is left out
(`shownCells(hiding:)`), and a folded form all of whose cells are hidden is dropped when another form
remains (`MatchedForm.shown(_:hiding:)`). A vos-only form (hablás, or "tenes") always shows.

**Landing.** `VerbDestination.marks` carries the shown cells. `VerbView` builds its cards with the
marked rows tinted (VoiceOver reads "Matches your search" as the value), and on first appearance
scrolls to the first card, in its own `sections` order, that holds a marked row, so a reordering
cannot misdirect it. The names a result row gives follow `ConjugationMatch.allCells`, which Phase 6
derived from `ConjugationTable`, so they list tenses in the page's order too. A page opened for a vos form shows vos as well as tú whatever the
setting, and likewise tú for a learner who chose vos. The gerund and participle in the header are
tinted when marked; the infinitive has nothing to tint.

**Tests.** `ReverseLookupTests` pins the plan's examples, the naming, the ranking around the Phase 0
table, the enclitic rules forward, the guess, and that every `ExampleUses.json` token finds its verb
through search (1,340 of 1,340).

## Verb Page

Built 2026-11-22 by Phase 6 of the browse plan, porting Konjugieren's Phase 7.

**`ConjugationTable`** (`Models/ConjugationTable.swift`) owns the verb page's cards: their order,
each tense's second names, and its Info article (`articleKey`, an `Info.stableKey`). The page
builds its cards from `ConjugationTable.all`; `VerbView.section(markedBy:)` and
`ConjugationMatch.allCells` read it, so the landing scroll, the `leaveVerbView` marks, and a search
row's names all follow the page. Nothing else uses this order: Info, the quiz, the Models grid, the
widgets, and the conjugation map keep `DisplayTense.conjugatedTenses`, which the map's file format
depends on.

**The order** is by corpus frequency within each block, simple tenses first, with the two
imperatives together at the end of the simple block (Josh, 2026-11-22).
[`tense_frequency.md`](tense_frequency.md) has the counts and the method, and
`scripts/count_tenses.py` reproduces them from `ConjugationMapTool --cells-json`. `ConjugationTableTests`
pins the order; change the doc and the script first.

**Second names** sit under each heading after "also" / "también". The headings are Spanish in
either interface, so the names follow the interface: English gets the English textbook name and the
RAE's name where it differs from the heading (Pretérito: "also preterite · pretérito perfecto
simple"); Spanish gets the RAE's name and Andrés Bello's ("también pretérito imperfecto ·
copretérito"). The Presente de Indicativo and Presente de Subjuntivo have none in Spanish. The line
is one `Text` to the eye, but its `accessibilityRepresentation` gives VoiceOver each name as its own
element in its own language, without the "also". The heading itself is tagged Spanish.

**The ⓘ button** at the right of a heading opens that tense's article in a sheet over the page
(`TenseArticleSheet`, private to `VerbView.swift`), so closing it returns to the same verb. A
`%…%` link inside the article pushes the linked article within the sheet. The glyph is 17 points;
`Layout.tapTargetInset` grows its hit area to about 47 without moving the heading. It sends
`tapTenseArticle`.

**The tips** (`Models/ConjugarTips.swift`) are inline `TipView`s between the header and the first
card, and obey `TipDisplay.tipsEnabled`. `RedLettersTip` appears only on a page with a red letter
(a form with an uppercase letter, header forms included), so hablar's page shows none.
`ScrollToBottomTip` waits on a persisted `@Parameter`, `isUnlocked`, which the next verb page to
appear sets once the red-letter tip is closed, so the two never appear one straight after the
other. Reaching the etymology or the examples invalidates it. Each, once closed, never returns.

**The iPad grid** (`BrowseLayout.detailColumns`) aligns its cells to the top, so that a five-row
imperative beside a seven-row tense starts level with it.

### Ways between verbs

Built 2026-11-22 by Phase 8 of the browse plan, porting Konjugieren's Phase 9.

**The pill** that names a verb's model ("Regular AR ›", "Irreg. ☛ tener ›") opens that model's page
(`ModelInfo.row(for:)`, which folds the alias classes 29-2, 30-1, 31-1, and 32-1 into their parents).

**The Related Verbs card** (`Views/RelatedVerbsView.swift`) sits at the bottom of the page, below the
examples (Josh, 2026-11-22, as for Konjugieren). It has up to two rows of chips, six verbs each:

- **Built on tener**: the verbs that share the page's root, the root first, then by frequency. "All
  N" opens `RelatedVerbListView`, every verb of the root with a Frequency/Alphabetical control,
  Frequency first.
- **Conjugated like cantar**: one verb per other root among the model's verbs, by frequency (the root
  verb when it uses the model, else the model's most frequent verb built on it). "All N" opens the
  model's page. The row is absent when every verb of the model shares the page's root, as for tener.

**The relation** is `VerbRelations` (`Models/RelatedVerbs.swift`), computed once from the verb map. A
verb's base is the longest verb of the map that ends it after a known Spanish prefix and whose class
number has the same leading number (contener 31-1 on tener 31; predecir 28-1 on decir 28). Its root
follows bases inward (desaparecer → aparecer → parecer). Bases must be verbs: tails such as -ducir
and -scribir would also join esperar with operar, and their verbs already share a model (Josh,
2026-11-22). `falseCompounds` lists 59 verbs that look built on a verb but are not (trabajar on
bajar, escapar on capar), read from the 2,000 most frequent verbs, so a few false pairs remain among
rarer ones. 976 verbs have a base; 605 roots have at least one other verb built on them.

**Navigation.** A verb page is pushed from two stacks, the Verbs tab and the Models tab. Each injects
`VerbPagePush` (an environment action that appends to its own path) and registers the destinations
`verbPageDestinations()` names (`ModelInfo`, `RelatedVerbListDestination`), so the pill and the card
work in both tabs, and a learner who arrived from a widget reaches a model's page without switching
tabs. `ModelView` pushes its verbs through the same action; its old `onSelectVerb` closure is gone.

**A model's page** has a Frequency/Alphabetical control above its verb list, Alphabetical by default
and not stored. The list (`VerbEntryList`, shared with the full related list) is lazy in both size
classes, since the cantar model holds 2,968 verbs.

### Copy and share

Built 2026-11-22 by Phase 9 of the browse plan, porting Konjugieren's Phase 10.

**The key conjugations** are `KeyConjugation` (`Models/KeyConjugation.swift`): four, each the stem a
family of tenses is built on (Josh, 2026-11-22). The yo presente (tengo) stands for the presente de
subjuntivo and the usted, nosotros, ustedes, and negative imperatives; the yo pretérito (tuve) for
the imperfectos and futuro de subjuntivo; the yo futuro (tendré) for the condicional; the participio
(tenido) for every compound tense. Each case names its cell (`tense`, `personNumber`), so the
pedagogy plan can map practice items onto it. `forms(of:)` returns them mixed case, as the engine
writes them (tenGo, tUVE, tenDré, tenido), for a caller that shows red letters; `line(for:)` gives
the lowercased "tengo · tuve · tendré · tenido". A reflexive-only verb's forms carry their pronoun
(me arrepiento · me arrepentí · me arrepentiré · arrepentido). A form the engine cannot produce is
left out, so abolir has three: abolí · aboliré · abolido. Both are `nonisolated`, for Spotlight and
the widget extension later; the share text is MainActor because `L` is. Nothing calls the set
"principal parts", in the interface or in code.

**The share button** sits in the verb page's navigation bar and presents `ShareSheet`
(`Utils/ShareSheet.swift`), a `UIActivityViewController` with an `LPLinkMetadata` header (the verb's
citation form and the learner's chosen app icon) and Copy kept. `ShareLink` was not used, for
Konjugieren's reasons: it reports no tap in a toolbar, and a `SharePreview` drops Copy. On iPad the
popover hangs from the button, found by its label (`L.Verb.share`) among the visible bar items. The
text, in the learner's language, is the verb and its gloss, the key conjugations, and the App Store
link (`URL.appStore`, no storefront), with no `conjugar://` link:

```
tener, “have”
tengo · tuve · tendré · tenido

Every conjugation of tener is in Conjugar:
https://apps.apple.com/app/conjugar/id1236500467
```

In Spanish the gloss sits in «», as the app's other Spanish strings quote, and the line reads
"Todas las conjugaciones de tener están en Conjugar:".

**A long press** on a form, or a right-click on a Mac, opens a context menu with Copy
(`copyOnLongPress` in `Utils/Modifiers.swift`); a tap still speaks. It copies the form alone,
lowercased, without the subject pronoun or an imperative's ¡…!, so ¡TEN! copies "ten"; a
reflexive-only verb's form keeps its reflexive pronoun ("me arrepiento"). The participio and
gerundio copy; the raíz futura (tendr-) does not, since a stem is not a word, and a dash copies
nothing. The infinitive is the navigation bar's title, which takes no menu, so it does not copy
(Konjugieren's infinitive sat in the page and did). VoiceOver gets a "Copy" / "Copiar" action beside
"Speak". The modifier pads the row before the menu and takes the padding back after, so the lifted
preview does not crop the first and last letters.

## Deeplinks

Built 2026-11-22 by Phase 10 of the browse plan, porting the grammar of Konjugieren's Phase 11. The
app opens `conjugar://` links from widgets, controls, intents, the Home Screen quick action, and
`simctl openurl`. There is no web domain, so there are no universal links (decided for Konjugieren
and carried over; see the browse plan).

### Grammar

Written before the `search` and `info` routes were added, so that every route follows one shape:

```
conjugar://<route>[/<target>][?<item>=<value>&…]
```

- **The route** is the host. It names the kind of place: a verb, the search, an article.
- **The target** is at most one path segment, percent-encoded, naming one thing of that kind: an
  infinitive, a stable key. A route that needs no target takes none, and the `search` route
  refuses one.
- **Text travels in query items, never in the path**, because it can hold spaces and slashes ("he
  hablado"). Query items modify a route; unknown ones are ignored.
- **`source`** may follow any route that leads to a verb page, a search, or (Phase 13) a quiz. It
  names the surface that built the link, from `AnalyticsSource`, because a widget or an intent can
  hand the app nothing but a URL. A missing or unknown value counts as `deeplink`.
- **Builders, not literals.** App code builds links with `URL.verbDeeplink(_:source:match:)`,
  `URL.searchDeeplink(text:source:)`, and `URL.infoDeeplink(stableKey:)` (`Utils/URLExtension.swift`),
  which percent-encode. Only the widget extension (`WidgetDeeplink`) and `Shared/`'s intents, which
  cannot see `AnalyticsSource`, write literals; each intent keeps its literal in a
  `pendingDeeplink` constant, and `AppRouterTests` pins it to the routes and the vocabulary.

| Route | Target | Query items | Opens | Since |
|---|---|---|---|---|
| `verb` | An infinitive, bare or with "se" (`arrepentirse` opens arrepentir), or `random` | `source`; `match`, a form the page marks as it marks a search's match (`verb/ir?match=fue`) | The Verbs tab's verb page, scrolled to the first marked card | Before 2026; `match` Phase 10 |
| `search` | None | `q`, the text; `source` | The Verbs tab's list with its search field. With text, the results show with the keyboard down; with none, or `q` empty, the field is cleared and focused for typing | Phase 10 |
| `info` | A `stableKey`, or a position in `Info.infos` | None | The Info tab, with the article pushed | Phase 10 |
| `quiz` | Any, or none (`quiz/start` by convention) | None | The Quiz tab, starting a quiz at once, as the Quick Quiz control and the quiz widget expect | Before 2026 |
| `game` | None, `boss`, or `end` | None | The game, full screen over any tab (see `docs/game.md`) | Before 2026 |
| `list` | Reserved for Phase 16's collections | `source` | Nothing yet: ignored | Reserved Phase 10 |

**`match`** goes through `AppRouter.marks(of:on:hiding:)`: `ConjugationMatch.cells(of:equalTo:)`,
as written, else with accents folded, so several words ("he hablado") and compounds work. Where tú
and vos share the form in one tense (hablaste), the person that Settings' second-singular choice
hides is left out, as a search's marks leave it (`MatchedForm.shownCells(hiding:)`). A match that is
no form of the verb opens the page unmarked. Phase 11's Look Up a Verb opens pages this way.

**`info`** accepts a position as well as a key, as Konjugieren's links did, but a position moves when
the articles are reordered, so app code always builds the key (`Info.info(deeplinkTarget:)`). The
Info tab's own cross-references still go by heading inside `InfoView`, since they never leave it.

**A link replaces what another left pending:** a verb link clears a pending search and a search
link a pending verb, so the last link wins on a cold launch.

### Architecture

| File | Purpose |
|------|---------|
| `Utils/URLExtension.swift` | The grammar's constants (routes, query-item names), `isDeeplink`, `deeplinkTarget`, `deeplinkQueryValue(named:)`, `analyticsSource`, and the builders |
| `Views/AppRouter.swift` | `handle(url:)` parses a link and sets the tab and a one-shot request: `pendingVerb` (with its marks), `pendingSearch` (a `SearchRequest`: text and source), `pendingInfo`, `pendingQuizStart`, or the game's flags. `openSearch(text:source:)` is the search route's effect, which Command-F, the control, and the quick action share. `AppRouter.shared` is the one instance, so that the quick action's scene delegate can reach it |
| `Views/VerbBrowseView.swift` | Consumes `pendingVerb` and `pendingSearch` with `onChange(initial: true)`, since a link can arrive before the tab first appears. A search request pops to the list first, waiting out the pop before it focuses |
| `Views/InfoBrowseView.swift` | Consumes `pendingInfo` the same way |
| `Views/MainTabView.swift` | Receives URLs via `.onOpenURL`, and drains a control's pending link from the shared defaults when the scene becomes active |
| `Supporting/QuickAction.swift` | The Home Screen quick action and the scene delegate that receives it (below) |

### Examples

```
conjugar://verb/hablar                          → hablar's page
conjugar://verb/ir?match=fue&source=lookup      → ir's page at the Pretérito, fue marked
conjugar://verb/arrepentirse?source=widget      → arrepentir's page (shown as arrepentirse)
conjugar://search?q=he%20hablado                → the verb list searched for "he hablado"
conjugar://search?source=control                → the verb list with an empty, focused field
conjugar://info/voseo                           → the Voseo article
conjugar://info/1                               → the article at position 1 (Terminology, today)
conjugar://quiz/start                           → the Quiz tab, a quiz started
```

### Control Center controls

Three controls, in `ConjugarWidget/`: **Quick Quiz** (`QuickQuizControl`), **Random Verb**
(`RandomVerbControl`), and, since Phase 10, **Find a Verb** (`FindVerbControl`), which opens the
verb search empty and focused. Each runs an intent from `Shared/` (`OpenQuizIntent`,
`OpenRandomVerbControlIntent`, `OpenVerbSearchIntent`), compiled into both the app and the
extension, with `openAppWhenRun = true`. A control cannot navigate, so its intent writes its
`pendingDeeplink` to the App Group's defaults (`WidgetConstants.pendingDeeplinkKey`) and
`MainTabView` routes it when the scene becomes active. `OpenVerbSearchIntent` is hidden from
Shortcuts (`isDiscoverable = false`), because Phase 11's Look Up a Verb is the shortcut for this.
Its title, "Find a Verb" / "Buscar un verbo", is Command-F's, under the widget catalog's own keys
(`Widget.findVerbName`, `Widget.intentFindVerb`, also in the app's catalog for the intent's
metadata).

### Home Screen quick actions

A long press on the app icon offers **Find a Verb** ("Buscar un verbo"), which routes
`conjugar://search?source=quickAction`: the same empty, focused search as the control and
Command-F. `Supporting/QuickAction.swift` installs the item at every launch
(`UIApplication.shortcutItems`, from `AppDelegate`) rather than declaring it in Info.plist, so its
title comes from the string catalog (`L.BrowseVerbs.findVerb`, Command-F's). SwiftUI has no hook
for quick actions, so `AppDelegate` names `QuickActionSceneDelegate` as the scene's delegate in
`application(_:configurationForConnecting:options:)`. A quick action that launches the app arrives
in `scene(_:willConnectTo:options:)`, before any view exists, and one that brings it forward in
`windowScene(_:performActionFor:completionHandler:)`. SwiftUI still owns the window, and
`.onOpenURL` still receives links (checked in the iOS 26.3 simulator with the app running and not
running).

## App Shortcuts and Spotlight

Built 2026-11-22 by Phase 11 of the browse plan, porting Konjugieren's Phase 11.

### Shortcuts

`Supporting/ConjugarShortcuts.swift` is the `AppShortcutsProvider`. Its phrases are English only,
Konjugieren's convention; its short titles are localized.

| Shortcut | Intent | Phrases | Opens |
|---|---|---|---|
| Look Up a Verb / Consultar un verbo | `LookUpVerbIntent` | "Look up a verb / a word / a conjugation with Conjugar" | Asks for a word, answers, then opens a page or a search (below) |
| Start a Quiz / Empezar un test | `OpenQuizIntent` (`Shared/`) | "Start a quiz with Conjugar", "Quiz me with Conjugar" | The Quiz tab, a quiz started (`conjugar://quiz/start`) |
| Random Verb / Verbo aleatorio | `OpenRandomVerbIntent` (`Shared/`) | "Show a random verb with Conjugar", "Random verb with Conjugar" | A random verb's page (`source=shortcut`) |

The two intents in `Shared/` stash their link in the App Group's defaults, as the controls do, and
`MainTabView` routes it when the scene becomes active. A shortcut run while Conjugar is already in
front would wait for the next activation (untried).

### Look Up a Verb

A phrase can carry only an entity or an enum, not free text, so the shortcut asks "Which word should
Conjugar look up?", with autocorrection off. `LookUpVerbIntent.perform()` builds a `VerbLookup`
(`Models/VerbLookup.swift`) off the main actor and answers with `.result(opensIntent:dialog:)`,
naming the hidden `OpenLookupResultIntent`, which routes the lookup's link through
`AppRouter.shared`. A result can open the app only by naming another intent.

`VerbLookup` reads `VerbSearch.matches`. Its answers are the matches of kind `exactInfinitive`,
`exactFoldedInfinitive`, `exactGlossSense`, or `conjugation`, or failing those, `foldedConjugation`.
An exact English sense answers because the verb list ranks it above a form ("come"); that is
Conjugar's departure from Konjugieren.

| Answers | Says | Opens |
|---|---|---|
| One verb, by infinitive or English sense | "tener, “have”: tengo · tuve · tendré · tenido" | `verb/tener?source=lookup` |
| One verb, by a form | "tuve: Pretérito (yo) of tener" | `verb/tener?source=lookup&match=tuve` |
| Several verbs | One line per verb, at most four ("fue: Pretérito (él) of ser", then of ir) | `search?q=fue&source=lookup` |
| None, but other matches | "Conjugar has no verb or conjugation spelled “habl”, but one verb matches: hablar, “speak”." | The search |
| None; the guess | "… Perhaps you meant tengo, of tener." | The search |
| Nothing | "Conjugar has no verb or conjugation spelled “xyzzyq”." | The search |

A form's line names only the spellings that matched as typed ("hablo" leaves out habló), and leaves
out the second-singular person the page hides. The link's `match` is the typed form when it is a
cell, and otherwise the bare form of its first cell (dímelo sends `di`), because the `verb` route
marks through `ConjugationMatch`, which reads cells only. The answer's strings are `L.Lookup`,
whose accessors are `nonisolated`.

### Spotlight

`Supporting/VerbSpotlight.swift` indexes one `VerbEntity` (`Supporting/VerbEntity.swift`, an
`AppEntity` and `IndexedEntity`) per verb into the named index `verbs`, at every launch, from
`MainTabView`'s `.task`, off the main actor. Building the entries takes about two seconds and the
indexing call about twenty in a Debug build on an Intel Mac.

| Field | Holds |
|---|---|
| `id` | The bare infinitive (arrepentir) |
| Title, subtitle | The citation form (arrepentirse) and the first gloss |
| `contentDescription` | The key conjugations, unlabeled: "tengo · tuve · tendré · tenido" |
| `alternateNames` | The glosses' phrases ("arrive", "come"), then the key conjugations |
| `keywords` | Every one-word form in the conjugation map, every gloss, and each phrase with and without "to" |

**Only titles matched** in the iOS 26.3 simulator, as in Konjugieren: "aprender" finds its entry,
but "aprendimos", "learn", and "tuve" find nothing from Conjugar. `docs/release.md` asks for a
device check. A tap arrives as a `CSSearchableItemActionType` activity, which `MainTabView` routes
as `verb/<infinitive>?source=spotlight`; `VerbSpotlight.infinitive(fromActivityIdentifier:)` reads
the identifier bare or as "VerbEntity/<id>". `VerbEntityQuery` ranks a parameter picker's matches
with `VerbSearch` before cutting at 25; no shortcut takes a `VerbEntity` yet.

**Konjugieren's lesson, kept for a future change:** deleting app entities by type empties every
index of the app, the named one included, so delete before indexing, never after.

