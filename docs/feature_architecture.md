# Feature Architecture

How the features of [`plans/browse_and_verb_implementation.md`](../plans/browse_and_verb_implementation.md)
and [`plans/pedagogy_implementation.md`](../plans/pedagogy_implementation.md) fit together: what
each piece is, where it lives, and the rules that keep it true. Work that changes a piece described
here updates its section, and a new piece adds its own. The code is the final authority; this
document is a map of it.

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
`privacy_policy3.txt`, because no release can ship before 2027 and the policy may be deployed at any
time.

### Lookup signals

| Signal | Parameters | Sent |
|---|---|---|
| `viewVerbView` | `source` (below) | When a verb page appears: on arrival, and again with `source` `resume` after the page returns from another tab, a pushed page, or the background |
| `leaveVerbView` | `deepestSection` (`header`, `simple`, `compound`, `etymology`, `example`), `dwell` (`0-5s`, `5-15s`, `15-60s`, `60s+`) | Exactly once for each `viewVerbView`: when the page leaves the screen or the app goes to the background |
| `finishSearch` | `source` (where the search began: `tab`, `control`, `quickAction`, `deeplink`, or `lookup`), `outcome` (`opened`, `abandoned`, `noResult`), `queryLength` (`1-2`, `3-5`, `6-9`, `10+`), `resultCount` (`0`, `1`, `2-10`, `11+`), `matchKind` (below), `resultPosition` (`1`, `2-5`, `6+`, `none`) | Once per search of the verb list: when a result or the guess is opened, the field is cleared, or the app goes to the background with text in the field |

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
from `ConjugationTable` (§ Verb Page), the page's own order, so a reordering moves the marks with it.
On an iPhone the Presente card shows without scrolling, so `header` alone will be rare.

**A search** (`Models/SearchReport.swift`, `SearchTracker` and `SearchReport`) begins with the
first non-blank letter in the Verbs tab's field and ends once. Returning to the results and opening
a second verb without editing sends no second `finishSearch`, though the page still reports
`search`; editing the text begins a new search. An abandoned search's `matchKind` is that of the
top result it passed over. Opening the guess reports `opened`, `resultCount` `0`, `matchKind`
`guess`, and position `1`, and the page reports `searchGuess`. Return and the arrow keys (iPad and
Mac) count as ordinary opens. The Models tab's search sends nothing.

**Where a search began** is the surface that opened the field: `SearchTracker.fieldOpened(from:)`
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
`conjugation` and `foldedConjugation` are a form of the verb (§ Reverse Lookup); a guess made from
a form is still `guess`. Rows and verbs correspond one to one, so `resultCount` and
`resultPosition` are counted in verbs.

### Other verb-page signals

| Signal | Parameters | Sent |
|---|---|---|
| `tapTenseArticle` | None | When the ⓘ beside a tense's heading on a verb page opens that tense's article. The article itself also sends `viewInfoView`. It does not say which tense or which verb |
| `tapShareVerb` | None | On each tap of the share button in a verb page's navigation bar, whether or not the learner then shares. It does not say which verb. Copying a form, by a long press or from the share sheet, sends nothing |
| `tapStarVerb` | `starred` (`true` or `false`) | On each tap of the star in a verb page's navigation bar. `starred` is the state after the tap, since a count of taps alone cannot tell starring from unstarring. It does not say which verb |

### Review-card signals

| Signal | Parameters | Sent |
|---|---|---|
| `viewReviewCard` | None | Once for each review card shown above the verb list: at most once per opening of the app, however often the list redraws. It does not say which verb |
| `tapRevealReviewCard` | None | When a tap reveals a card's key conjugations, once per card. With `viewReviewCard` it gives the reveals per card shown. A dismissal sends nothing; it is a `viewReviewCard` with no reveal |

### Collection signals

| Signal | Parameters | Sent |
|---|---|---|
| `viewCollection` | `collection` (a key: `top100`, `goVerbs`, `strongPreterite`, `irregularFuture`, `irregularParticiple`, or `model-<class>`), `source` (`tab`, `verbPage`, `sharedLink`, or `deeplink`) | Once for each opening of a featured collection's page or of a model's page, whose bar makes it a collection. A return from one of its verb pages sends nothing |
| `tapShareCollection` | `collection` | On each tap of a collection bar's Share button, whether or not the learner then shares |

A collection's quiz adds `collection` to `startQuiz`. A collection names a list, never a verb, though
a model's key names the model.

### The `source` vocabulary

`AnalyticsSource` is one vocabulary for every signal that carries `source`: `viewVerbView`;
`finishSearch`, where it names the surface that opened the search field; and `startQuiz`,
`quitQuiz`, and `completeQuiz` (§ The Scoped Quiz).

| Value | Sent today? | Meaning |
|---|---|---|
| `browse` | Yes | A row of the verb list with the search field empty |
| `control` | Yes | The Random Verb control in Control Center (`OpenRandomVerbControlIntent`); for `finishSearch`, the Find a Verb control (`OpenVerbSearchIntent`) |
| `deeplink` | Yes | A `conjugar://` link with no recognized `source` query item; for `finishSearch`, a `search` link; for the quiz signals, a `quiz` link, which the Quick Quiz control, the Start a Quiz shortcut, and the Live Activity send; for `viewCollection`, a `list` link that names no source |
| `infoLink` | No | Reserved for a link from an Info article to a verb |
| `list` | Yes | A verb opened from a featured collection's page (a verb opened from a model's page stays `model`); for the quiz signals, a collection's quiz |
| `lookup` | Yes | The Look Up a Verb shortcut: for `viewVerbView`, the page it opened when one verb answered; for `finishSearch`, the search it opened otherwise |
| `model` | Yes | A verb row on a model's page, in the Models tab or reached from a verb page's pill |
| `myVerbs` | Yes | A row of My Verbs, the verb list's third segment; for the quiz signals, a quiz over My Verbs begun from the Quiz tab |
| `quickAction` | Yes | `finishSearch` only: a search begun from the Find a Verb Home Screen quick action |
| `recent` | Yes | A recent verb, listed while the search field is focused and empty |
| `related` | Yes | A chip on a verb page's Related Verbs card, or a row of the full list it opens |
| `resume` | Yes | A page that came back after another tab, a pushed page, or the background |
| `reviewCard` | Yes | The review card above the verb list, tapped after its reveal |
| `search` | Yes | A result of a search that found something |
| `searchGuess` | Yes | The closest verb offered by a search that found nothing |
| `sharedLink` | Yes | `viewCollection`: a collection's shared link, which carries `source=sharedLink` |
| `shortcut` | Yes | Open Random Verb run from the Shortcuts app or Siri (`OpenRandomVerbIntent`, offered as the Random Verb shortcut) |
| `spotlight` | Yes | A tap on a verb's Spotlight entry |
| `tab` | Yes | `finishSearch`: a search begun in the Verbs tab itself, Command-F included. The quiz signals: a quiz over every verb begun with the Quiz tab's Start. `viewCollection`: a collection or a model opened from the Models tab's list |
| `verbPage` | Yes | The quiz signals: Test Me's three questions on a verb's page. `viewCollection`: a model's page opened from a verb page's model pill |
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
opens the bare infinitive the map keys on. The widgets name a reflexive-only verb
that way, because they show it as the app does.

**The control has its own intent.** An intent cannot tell whether the control or a shortcut ran
it, so the Random Verb control runs `OpenRandomVerbControlIntent` (`Shared/`, hidden from
Shortcuts with `isDiscoverable = false`, sharing the title key), and `OpenRandomVerbIntent` is
left to the Shortcuts app and Siri.

**Any new way to reach a verb page** sets its `source` value (adding it here and to the enum if it
is new) and stages a policy line if its kind of surface is not already named.

## Conjugation Map

The reverse lookup (§ Reverse Lookup) reads the map, and the pedagogy plan's grading calls
`ConjugationMatch`.

**What it is.** `ConjugationMap` (`Models/ConjugationMap.swift`) maps every one-word form of every
verb to the verbs and cells it belongs to: fue → ir and ser, each in the pretérito (él). A cell is a
`ConjugationCell`, a `DisplayTense` and a `DisplayPersonNumber`, so a result names itself in the
verb page's own vocabulary. The one-word cells (`ConjugationMap.oneWordCells`, 72 of them) are the
infinitive, the gerund, the participle, the nine simple tenses in all seven persons (vos included),
and the imperativo positivo's six. Compound tenses and the imperativo negativo have no entries,
because their last word (a participle, a subjunctive) does. Forms are the engine's bare forms,
lowercased (the uppercase irregularity marking is highlighting), accents as written: "hablo" finds
only hablar's presente (yo), never habló. A reflexive-only verb is stored bare (arrepiento), so
the reverse lookup strips a pronoun before looking up. 254,328 forms, 293 of them shared by two
verbs.

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
so 1.8 MB of text compresses to 43 KB. One line per form came to 1.4 MB. Loading inverts the
paradigms into the form index; `ConjugationMap.bundled` is a `nonisolated static let`, which the
reverse lookup's `ConjugationIndex.bundled` touches from a background task when the Verbs tab
appears.

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
`ExampleUses.json`.

## Reverse Lookup

A form typed into the Verbs tab's search finds its verb, and each result names what it matched.

**The pieces.** `ConjugationIndex` (`Models/ConjugationIndex.swift`) indexes the conjugation map by
folded spelling (so "hablo" also reaches habló, "sueno" sueño) and by first letter and length (for
the guess). `ConjugationIndex.bundled` takes about a second to build, so `VerbBrowseView` builds it
in a detached task when it appears. `FormLookup.forms(for:)` (`Models/FormLookup.swift`) returns,
for each verb, the `MatchedForm`s a query is: the form as the app spells it, its cells in page order,
and whether it matched only after folding. `VerbSearch.matches(for:in:index:)` calls it and gives
each such verb the kind `conjugation` (some form matched as written) or `foldedConjugation`, with
its forms in `Match.forms`, literal ones first. `VerbSearch.guess(for:in:index:)` gives the empty
state's guess. Both are `nonisolated` and take the entries to search, so `VerbLookup` calls them
from outside the view (§ App Shortcuts and Spotlight).

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
"come" gives the verbs glossed "come" first (llegar, venir, acudir) and then comer, ahead of
comenzar; "listen" finds escuchar before listar; "ve" finds ir and ver before venir and verter.
`foldedConjugation` comes right after `conjugation` rather than below every literal kind, so "de",
"se", and "esta" find dar, saber and ser, and estar before the hundreds of verbs that begin with
those letters.

**Naming.** `MatchedForm.line(hiding:)` gives "hablo: Presente de Indicativo (yo)", groups joined by
" · ", in the page's Spanish tense names, with a command's third persons as usted and ustedes. Where
tú and vos share a form in one tense, the person the browse setting hides is left out
(`shownCells(hiding:)`), and a folded form all of whose cells are hidden is dropped when another form
remains (`MatchedForm.shown(_:hiding:)`). A vos-only form (hablás, or "tenes") always shows.

**Landing.** `VerbDestination.marks` carries the shown cells. `VerbView` builds its cards with the
marked rows tinted (VoiceOver reads "Matches your search" as the value), and on first appearance
scrolls to the first card, in its own `sections` order, that holds a marked row, so a reordering
cannot misdirect it. The names a result row gives follow `ConjugationMatch.allCells`, which derives
from `ConjugationTable`, so they list tenses in the page's order too. A page opened for a vos form
shows vos as well as tú whatever the setting, and likewise tú for a learner who chose vos. The
gerund and participle in the header are tinted when marked; the infinitive has nothing to tint.

**Tests.** `ReverseLookupTests` pins the lookup examples, the naming, the ranking, the enclitic
rules forward, the guess, and that every `ExampleUses.json` token finds its verb through search
(1,340 of 1,340).

## Verb Page

**`ConjugationTable`** (`Models/ConjugationTable.swift`) owns the verb page's cards: their order,
each tense's second names, and its Info article (`articleKey`, an `Info.stableKey`). The page
builds its cards from `ConjugationTable.all`; `VerbView.section(markedBy:)` and
`ConjugationMatch.allCells` read it, so the landing scroll, the `leaveVerbView` marks, and a search
row's names all follow the page. Nothing else uses this order: Info, the quiz, the Models grid, the
widgets, and the conjugation map keep `DisplayTense.conjugatedTenses`, which the map's file format
depends on.

**The order** is by corpus frequency within each block, simple tenses first, with the two
imperatives together at the end of the simple block. [`tense_frequency.md`](tense_frequency.md) has
the counts and the method, and `scripts/count_tenses.py` reproduces them from
`ConjugationMapTool --cells-json`. `ConjugationTableTests` pins the order; change the doc and the
script first.

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

**The pill** that names a verb's model ("Regular AR ›", "Irreg. ☛ tener ›") opens that model's page
(`ModelInfo.row(for:)`, which folds the alias classes 29-2, 30-1, 31-1, and 32-1 into their parents).

**The Related Verbs card** (`Views/RelatedVerbsView.swift`) sits at the bottom of the page, below the
examples. It has up to two rows of chips, six verbs each:

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
and -scribir would also join esperar with operar, and their verbs already share a model.
`falseCompounds` lists 59 verbs that look built on a verb but are not (trabajar on bajar, escapar
on capar), read from the 2,000 most frequent verbs, so a few false pairs remain among rarer ones.
976 verbs have a base; 605 roots have at least one other verb built on them.

**Navigation.** A verb page is pushed from two stacks, the Verbs tab and the Models tab. Each injects
`VerbPagePush` (an environment action that appends to its own path) and registers the destinations
`verbPageDestinations()` names (`ModelInfo`, `RelatedVerbListDestination`), so the pill and the card
work in both tabs, and a learner who arrived from a widget reaches a model's page without switching
tabs. `ModelView` pushes its verbs through the same action.

**A model's page** has a Frequency/Alphabetical control above its verb list, Alphabetical by default
and not stored. The list (`VerbEntryList`, shared with the full related list) is lazy in both size
classes, since the cantar model holds 2,968 verbs.

### Copy and share

**The key conjugations** are `KeyConjugation` (`Models/KeyConjugation.swift`): four, each the stem a
family of tenses is built on. The yo presente (tengo) stands for the presente de subjuntivo and the
usted, nosotros, ustedes, and negative imperatives; the yo pretérito (tuve) for the imperfectos and
futuro de subjuntivo; the yo futuro (tendré) for the condicional; the participio (tenido) for every
compound tense. Each case names its cell (`tense`, `personNumber`), so the pedagogy plan can map
practice items onto it. `forms(of:)` returns them mixed case, as the engine writes them (tenGo,
tUVE, tenDré, tenido), for a caller that shows red letters; `line(for:)` gives the lowercased
"tengo · tuve · tendré · tenido". A reflexive-only verb's forms carry their pronoun (me arrepiento ·
me arrepentí · me arrepentiré · arrepentido). A form the engine cannot produce is left out, so abolir
has three: abolí · aboliré · abolido. Both are `nonisolated`, for Spotlight and the widget
extension; the share text is MainActor because `L` is. Nothing calls the set "principal parts", in
the interface or in code.

**The share button** sits in the verb page's navigation bar and presents `ShareSheet`
(`Utils/ShareSheet.swift`), a `UIActivityViewController` with an `LPLinkMetadata` header (the verb's
citation form and the learner's chosen app icon) and Copy kept. It is not a `ShareLink`, which
reports no tap in a toolbar, and whose `SharePreview` drops Copy. On iPad the popover hangs from the
button, found by its label (`L.Verb.share`) among the visible bar items. The text, in the learner's
language, is the verb and its gloss, the key conjugations, and the App Store link (`URL.appStore`,
no storefront), with no `conjugar://` link:

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
nothing. The infinitive is the navigation bar's title, which takes no menu, so it does not copy.
VoiceOver gets a "Copy" / "Copiar" action beside "Speak". The modifier pads the row before the menu
and takes the padding back after, so the lifted preview does not crop the first and last letters.

## Deeplinks

The app opens `conjugar://` links from widgets, controls, intents, the Home Screen quick action,
and `simctl openurl`. There is no web domain, so there are no universal links.

### Grammar

Every route follows one shape:

```
conjugar://<route>[/<target>][?<item>=<value>&…]
```

- **The route** is the host. It names the kind of place: a verb, the search, an article.
- **The target** is at most one path segment, percent-encoded, naming one thing of that kind: an
  infinitive, a stable key. A route that needs no target takes none, and the `search` route
  refuses one.
- **Text travels in query items, never in the path**, because it can hold spaces and slashes ("he
  hablado"). Query items modify a route; unknown ones are ignored.
- **`source`** may follow any route that leads to a verb page, a search, or a quiz. It
  names the surface that built the link, from `AnalyticsSource`, because a widget or an intent can
  hand the app nothing but a URL. A missing or unknown value counts as `deeplink`.
- **Builders, not literals.** App code builds links with `URL.verbDeeplink(_:source:match:)`,
  `URL.searchDeeplink(text:source:)`, `URL.infoDeeplink(stableKey:)`, and
  `URL.listDeeplink(key:source:)` (`Utils/URLExtension.swift`), which percent-encode. Only the
  widget extension (`WidgetDeeplink`) and `Shared/`'s intents, which cannot see `AnalyticsSource`,
  write literals; each intent keeps its literal in a `pendingDeeplink` constant, and
  `AppRouterTests` pins it to the routes and the vocabulary.

| Route | Target | Query items | Opens |
|---|---|---|---|
| `verb` | An infinitive, bare or with "se" (`arrepentirse` opens arrepentir), or `random` (drawn by `VerbDraw`; see [The Verb of the Day and Random Verbs](#the-verb-of-the-day-and-random-verbs)) | `source`; `match`, a form the page marks as it marks a search's match (`verb/ir?match=fue`) | The Verbs tab's verb page, scrolled to the first marked card |
| `search` | None | `q`, the text; `source` | The Verbs tab's list with its search field. With text, the results show with the keyboard down; with none, or `q` empty, the field is cleared and focused for typing |
| `info` | A `stableKey`, or a position in `Info.infos` | None | The Info tab, with the article pushed |
| `quiz` | Any, or none (`quiz/start` by convention) | None | The Quiz tab, starting a quiz over every verb at once, as the Quick Quiz control and the quiz widget expect. The link's `source` (or `deeplink`) goes to the quiz signals |
| `game` | None, `boss`, or `end` | None | The game, full screen over any tab (see `docs/game.md`) |
| `list` | A collection's key (`top100`, `goVerbs`, `model-31`, `model-4B`; see [Collections](#collections)) | `source`; a shared collection sends `sharedLink` | The Models tab, with the collection's page pushed, or for a model the model's page. An unknown key, or an alias class's (`model-31-1`), is ignored |

**`match`** goes through `AppRouter.marks(of:on:hiding:)`: `ConjugationMatch.cells(of:equalTo:)`,
as written, else with accents folded, so several words ("he hablado") and compounds work. Where tú
and vos share the form in one tense (hablaste), the person that Settings' second-singular choice
hides is left out, as a search's marks leave it (`MatchedForm.shownCells(hiding:)`). A match that is
no form of the verb opens the page unmarked. The Look Up a Verb shortcut opens pages this way.

**`info`** accepts a position as well as a key, but a position moves when the articles are
reordered, so app code always builds the key (`Info.info(deeplinkTarget:)`). The Info tab's own
cross-references go by heading inside `InfoView`, since they never leave it.

**A link replaces what another left pending:** a verb link clears a pending search and a search
link a pending verb, so the last link wins on a cold launch.

### Architecture

| File | Purpose |
|------|---------|
| `Utils/URLExtension.swift` | The grammar's constants (routes, query-item names), `isDeeplink`, `deeplinkTarget`, `deeplinkQueryValue(named:)`, `analyticsSource`, and the builders |
| `Views/AppRouter.swift` | `handle(url:)` parses a link and sets the tab and a one-shot request: `pendingVerb` (with its marks), `pendingSearch` (a `SearchRequest`: text and source), `pendingInfo`, `pendingQuizStart`, or the game's flags. `openSearch(text:source:)` is the search route's effect, which Command-F, the control, and the quick action share. `AppRouter.shared` is the one instance, so that the quick action's scene delegate can reach it |
| `Views/VerbBrowseView.swift` | Consumes `pendingVerb` and `pendingSearch` with `onChange(initial: true)`, since a link can arrive before the tab first appears. A search request pops to the list first, waiting out the pop before it focuses |
| `Views/InfoBrowseView.swift` | Consumes `pendingInfo` the same way |
| `Views/ModelBrowseView.swift` | Consumes `pendingCollection` (a `CollectionRequest`: collection and source) the same way, pushing it onto the Models tab's stack |
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
conjugar://list/goVerbs?source=sharedLink       → the Models tab, the -go verbs' page
conjugar://list/model-31                        → the Models tab, tener's model page
```

### Control Center controls

Three controls, in `ConjugarWidget/`: **Quick Quiz** (`QuickQuizControl`), **Random Verb**
(`RandomVerbControl`), and **Find a Verb** (`FindVerbControl`), which opens the verb search empty
and focused. Each runs an intent from `Shared/` (`OpenQuizIntent`, `OpenRandomVerbControlIntent`,
`OpenVerbSearchIntent`), compiled into both the app and the extension, with
`openAppWhenRun = true`. A control cannot navigate, so its intent writes its `pendingDeeplink` to
the App Group's defaults (`WidgetConstants.pendingDeeplinkKey`) and `MainTabView` routes it when the
scene becomes active. `OpenVerbSearchIntent` is hidden from Shortcuts (`isDiscoverable = false`),
because the Look Up a Verb shortcut covers this. Its title, "Find a Verb" / "Buscar un verbo", is
Command-F's, under the widget catalog's own keys (`Widget.findVerbName`, `Widget.intentFindVerb`,
also in the app's catalog for the intent's metadata).

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

### Shortcuts

`Supporting/ConjugarShortcuts.swift` is the `AppShortcutsProvider`. Its phrases are English only;
its short titles are localized.

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
An exact English sense answers because the verb list ranks it above a form ("come").

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

**Only titles matched** in the iOS 26.3 simulator: "aprender" finds its entry,
but "aprendimos", "learn", and "tuve" find nothing from Conjugar. `docs/release.md` asks for a
device check. A tap arrives as a `CSSearchableItemActionType` activity, which `MainTabView` routes
as `verb/<infinitive>?source=spotlight`; `VerbSpotlight.infinitive(fromActivityIdentifier:)` reads
the identifier bare or as "VerbEntity/<id>". `VerbEntityQuery` ranks a parameter picker's matches
with `VerbSearch` before cutting at 25; no shortcut takes a `VerbEntity` yet.

**For a future change:** deleting app entities by type empties every index of the app, the named
one included, so delete before indexing, never after.

## The Learner's Record

**The record.** `LearnerVerbs` (`Shared/LearnerVerbs.swift`, `nonisolated`, Codable) holds one
`Entry` per verb, keyed by the bare infinitive the verb map uses (arrepentir, never arrepentirse):
first and last opened, `openCount`, and the date starred. A verb neither opened since the last
Clear nor starred has no entry. `recent(limit:)` (20 by default) and `starred` are newest first,
ties broken by infinitive; `myVerbs` is the starred verbs, then the recent ones not starred.
`remove(_:)` forgets a verb entirely; `clearRecents()` forgets every open and keeps the stars.

**Storage.** `Current.learnerVerbs` is a `LearnerVerbStore` (`Models/LearnerVerbStore.swift`,
`@Observable`), which saves the record as JSON after each change, under `LearnerVerbs.storageKey`,
through a `GetterSetterReal` given the App Group's defaults (`WidgetConstants.sharedDefaults`). The
widget extension can therefore decode it with `LearnerVerbs(json:)`. The unit and UI-test worlds
use a `GetterSetterFake`. The store answers in `VerbMapEntry`s and skips an infinitive the verb map
lacks. To read the record in the simulator: `xcrun simctl spawn <udid>
defaults read <group container>/Library/Preferences/group.biz.joshadams.Conjugar learnerVerbs`,
where the container comes from `xcrun simctl get_app_container <udid> biz.joshadams.Conjugar
groups`.

**Every field added to `Entry` later must be optional.** Synthesized decoding requires every
non-optional key, so a new non-optional field would make every older record decode as nothing, and
the learner's verbs would vanish silently. `LearnerVerbsTests` pins the decoding of an entry with
only its key and count.

**An open** is a verb page's arrival by any route, recorded in `VerbView.beginVisit` whenever
`viewVerbView` is sent with a source other than `resume`. A page that comes back after another tab,
a pushed page, or the background is not a new open.

**Where it shows.**

- **Recents.** While the verb list's search field is focused and empty, the list shows "Recent" and
  the recent verbs in place of every verb (`VerbBrowseView.showsRecents`), as rows the arrow keys
  and Return reach. They follow `searchIsEngaged`, which lets go of the focus 0.7 seconds late,
  and a row's push waits on `ViewControllerTransitions.waitUntilIdle()` when the search is ending,
  both because on iPad a tap outside an empty search field ends the search at touch-down, before
  the tap completes. A row opens with source `recent`.
- **My Verbs** is the third segment of the picker under the list (`VerbListMode`: Frequency,
  Alphabetical, My Verbs). Only a sort is saved in Settings, so the app opens on the full list. My
  Verbs is a `List` of its own, so that rows can be swiped: Starred, then Recent with a Clear
  button, and an empty state. A swipe forgets the verb; a starred one asks first. Typing searches
  every verb, whatever the picker says. A row opens with source `myVerbs`.
- **The star** sits in the verb page's navigation bar beside Share, reads "Add to My Verbs" or
  "Remove from My Verbs", and sends `tapStarVerb` with `starred`.

## The Review Card

The pedagogy plan's practice record is meant to take the schedule over.

**The schedule.** `ReviewSchedule` (`Shared/ReviewSchedule.swift`, `nonisolated`, Codable) is a box
and a due date on a Leitner ladder of 1, 3, 7, 14, and 30 days, the last repeating. Due dates fall
at the start of a day, so a verb looked up at 11 p.m. waits for the next morning. Three operations:
`lookedUp` (box 0, due tomorrow), `revealed` (up one box), and `dismissed` (same box, due
tomorrow). It is stored as the optional `review` on each `LearnerVerbs.Entry`.

**Only irregular verbs**: a regular verb's key conjugations are the pattern of its whole class, so
its lookup has nothing of its own to review. Irregular is what the verb page's pill says, any class
but 1, 2, and 3 (`VerbDraw.isIrregular`), so the orthographic classes count: buscar's card shows
busqué's red letters. `LearnerVerbs` has no verb map, so `LearnerVerbStore.isReviewable` decides,
and the record schedules only what its caller asks (`recordOpen(_:at:schedulesReview:)`). A regular
verb's entry never has a `review`, which spares the pedagogy plan a migration.

**What moves it**:

- An open by any route but the card puts the verb in box 0, or back there, since looking a verb up
  again suggests it was forgotten.
- A reveal moves it up a box. An open from the card after the reveal (source `reviewCard`) counts
  as an open for My Verbs but leaves the schedule.
- The ✕ before a reveal is no review: same box, due tomorrow. The ✕ after a reveal changes nothing.
- Clear in My Verbs forgets the opens and with them the schedules; a swipe that removes a verb
  removes its schedule. A starred verb never opened is never due.

**An older record.** An entry written before the review card existed has opens but no `review`. As
it loads, the store schedules each such irregular verb as looked up on its last open
(`LearnerVerbs.scheduleUnscheduledReviews(where:)`) and saves, so a learner with history sees a
card on the first day. The fallback is written once rather than computed on every read, because a
read-time fallback could not tell an old irregular entry from a regular verb opened yesterday.

**Which card.** `LearnerVerbStore.verbDueForReview()` takes the longest overdue, ties broken by
infinitive. `VerbBrowseView` chooses once at launch and again at each return from the background,
so a reveal does not swap the card for the next verb due. The card hides while anything is typed
and while the recents show, and is absent from My Verbs, which is a list of its own. On iPad it
stops at 560 points rather than spanning the grid.

**The card** (`Views/ReviewCardView.swift`) shows "Looked up 3 days ago" ("yesterday" for one,
counted in calendar days), the citation form (arrepentirse), the gloss, and the key conjugations
(`KeyConjugation.forms`) under a redacted placeholder, with "Recall its conjugations, then tap to
check." A tap anywhere reveals them with their red letters; a second tap opens the page, and a
chevron says so. A reflexive-only verb's forms carry their pronoun (me arrepiento). VoiceOver reads
the infinitive and forms in Spanish, the forms separated by commas rather than middle dots, and each
text element carries the tap as its action.

**Suppress Review Card** (`Settings.reviewCardSuppression`, `ReviewCardSuppression`, Off by
default) sits in the Settings card with Browse Tú and/or Vos. On hides a card at once and chooses
none at later openings; Off chooses one at once if none shows. The schedule keeps running
underneath. No signal is sent for the setting.

**Seeding a card in the simulator.** Write the record through `cfprefsd`, not into the plist file,
which `cfprefsd` would not reread: `xcrun simctl spawn <udid> defaults write <group
container>/Library/Preferences/group.biz.joshadams.Conjugar learnerVerbs -string '<json>'`, with
dates as seconds since 2001-01-01, while the app is not running. Without `-string`, `defaults`
tries to parse the JSON as a plist and fails.

## The Scoped Quiz

The pedagogy plan reshapes the quiz and should extend this rather than replace it.

**`QuizScope`** (`Models/QuizScope.swift`, `nonisolated`) says what a quiz asks about: the verbs
(nil for every verb, through the curated lists in `VerbFamilies`; otherwise bare infinitives), the
question count, and the `source` its signals carry. `allVerbs` is the Quiz tab's quiz over every
verb, `allVerbs(source:)` the same begun by a `quiz` link, `myVerbs(_:)` thirty questions over My
Verbs, `verbPage(_:)` Test Me's three, and `collection(_:title:)` thirty questions over a
collection, which also carries a `title` for the sheet and a `collectionKey` for `startQuiz`.
`QuizScope.fullLength` is 30, and `isRanked` (every verb, full length) decides both whether the
score goes to Game Center and whether the leaderboard shows at the end. No scoped quiz ranks.

**The draw.** `Quiz.start(scope:)` defaults to `.allVerbs`, and returns false, changing nothing,
when the scope gives no question (an empty My Verbs). The difficulty's plan over the curated lists
is `Quiz.standardQuestions()`, unshuffled. A scoped quiz borrows it:

- **Full length** (My Verbs) keeps the plan's tenses and persons, so its mix is the tab's at that
  difficulty, and puts the scope's verbs into the slots in turn, preferring a verb not already asked
  in that cell. Two verbs share thirty questions about evenly.
- **Shorter** (Test Me) takes distinct cells one tense at a time from the plan's tenses, so three
  questions at Easy are a presente, a futuro, and a pretérito, never three of one tense.
- **Either** skips a cell the engine does not give for that verb (a defective verb's), asks tú or vos
  by the quiz setting, no vosotros in the Latin America region, and no yo in a command, as the tab's
  plan does.

The tab's plan draws each question's person from a rotation of that tense's own
(`Quiz.personNumber(for:)`), carried from one quiz to the next. A single rotation over every tense
fell into step with a quiz's length, so a tense asked once a quiz, a command above all, met the
same person every time.

A question is a `QuizQuestion` (`Quiz.Question`), which also grades. `acceptedAnswers` expands every
spelling the quiz takes rather than folding the learner's answer, since a fold applied to both sides
would accept misspellings: the written answer, a reflexive-only verb's bare form, and
`StandardVariants`, the RAE's standard doublets of a cell (frito beside freído, satisface beside
satisfaz, adecúo beside adecuo, the Río de la Plata's vos hablés beside hables, and every alternate
the engine models in `Conjugator.conjugateAll`, which includes the spelling the 2010 *Ortografía*
retired, rió beside rio). `grade(_:)` reads the answer through `AnswerSpelling`, which ignores case,
runs of spaces, and a leading subject pronoun of the asked person (yo hablo; tú or tu; él, el, ella,
or usted), though never before a command, a gerundio, or a participio. An answer right but for its
accents is still `.partialMatch`. The -ra and -se imperfect subjunctives never stand in for each
other. `SpanishLetterKeyRow` inserts at the answer field's cursor through a `TextSelection`
binding. On the iPhone it is a keyboard toolbar; iPadOS's keyboard shows no toolbar items, so on
the iPad it sits under the field. The question view takes the keyboard again as it appears, since a
quiz started by a link focuses the field before it is on screen and the row then never joins the
keyboard.

**Test Me** is the clipboard (`pencil.and.list.clipboard`) first in a verb page's navigation bar,
before the star and Share, read by VoiceOver as "Test Me on This Verb". It opens `QuizSheet`
(`Views/QuizSheet.swift`), which owns a `Quiz` of its own, so a quiz in progress in the tab carries
on, and shows `QuizView(quiz:sheetScope:)`. In sheet mode the view starts the quiz as it appears
(something must be on screen for `onAppear` to fire, hence a `Color.clear` before the start), shows
the results in place of the question with a Done button, closes on Quit, and cannot be swiped away
mid-quiz, so every quiz it starts ends with `quitQuiz` or `completeQuiz`. It skips `viewQuizView`,
the Game Center prompt, and the router's quiz link.

**A quiz that is not full length** starts no Live Activity, and does not count toward
`ChangeDifficultyTip`. Nor does a collection's quiz start one, though it is full length, because it
runs in the sheet beside a quiz the tab may hold, and the Live Activity is one for the app
(`QuizScope.startsLiveActivity`; `Quiz.hasLiveActivity` keeps a sheet's quiz from ending the tab's).
Quiz.swift reaches the activity through `Current.liveActivities`: `LiveActivitiesReal` on device
and in the simulator World, and `LiveActivitiesSpy` under tests, which `QuizLiveActivityTests`
checks these rules against.
A collection's completed quiz does count toward the tip.

**The Quiz tab's start screen**: a large yellow symbol for the scope (`books.vertical.fill`, or a
star for My Verbs), the scope's name ("4,811 verbs" or My Verbs) and a line on what the quiz asks,
an All Verbs / My Verbs picker above Start, three tiles (30 questions, the difficulty, the region),
and for My Verbs the verbs as centered chips, up to twelve and "+N more" (`FlowLayout.centersRows`).
The third tile is the region rather than points per answer, because the points depend on both
settings and are not a whole number. Start is disabled while My Verbs is empty. The choice is not
stored. On iPad the symbol, type, and tiles are larger and Start is scaled up.

**Signals.** `startQuiz`, `quitQuiz`, and `completeQuiz` carry `source`: `tab`, `myVerbs`,
`verbPage`, or a `quiz` link's own (`deeplink` by default), so that three-question completions do
not raise the full quiz's completion rate. There is no `tapTestVerb`: the sheet starts its quiz as
it opens, so `startQuiz` with `verbPage` counts the same taps.

## The Verb of the Day and Random Verbs

**`FrequencyBand`** (`Models/FrequencyBand.swift`, `nonisolated`) defines the bands once: `.top100`,
`.top300`, and `.top1000`, with `VerbMapEntry.isIn(_:)` and `VerbMap.entries(in:)`, most frequent
first. The rank has no ties, so each band holds exactly its count. The pedagogy plan's levels use
them.

**`VerbDraw`** (`Models/VerbDraw.swift`, `nonisolated`) chooses the widget's verb of the day and
every random verb: the Random Verb control, the Random Verb shortcut, and the `verb/random` link,
which all reach `AppRouter.handle(url:)`. A draw comes from the 1,000 most frequent verbs, where an
irregular verb (any class but 1, 2, and 3, as the verb page's pill counts it, so the orthographic
classes too) weighs 2 and a verb with no base in `VerbRelations` weighs 2, multiplied: ir and tener
weigh 4, detener and hablar 2, recobrar 1. Frequency inside the band is not weighted. In the band,
39% of verbs are irregular and 80% unprefixed; in 1,000 simulated days, 58% and 89% of the draws.

**My Verbs** (`LearnerVerbs.myVerbs`: the starred verbs, then the last 20 opened, as the list's
segment shows them) supplies one draw in three once it has entries. The widget gives it the days
whose number since 2026-01-01 is a multiple of three and takes its verbs in turn, since chance
leaves gaps of two weeks and repeats one verb while another waits. A random verb on demand goes to
My Verbs with a chance of one in three. A random verb opened is a recent verb, so it joins My Verbs
and can return as a My Verbs draw until it ages out.

**Stable through the day.** A frequent day seeds `SplitMix64` (`Models/Game/GameModels.swift`,
`nonisolated` so that the draw can use it) with the day number, so its verb is a function of the
day. Its sequence must not change; `VerbDrawTests` pins its first outputs. A My Verbs day depends on
the list, which can change during the day, but `WidgetSnapshotWriter.refresh(myVerbs:)` writes one
snapshot per date and skips the write when today's is on disk, so the first activation of a day
settles the verb. `MainTabView` reads My Verbs on the main actor
(`Current.learnerVerbs.record.myVerbs`, infinitives) and passes them to the detached refresh, which
resolves them only when it writes.

**No new signal.** `viewVerbView` with `source` `widget`, `control`, or `shortcut` already counts
the pages these draws open.

## Collections

Fixed lists of verbs as places to go: each shows how many of its verbs have been looked up, starts
a quiz on itself, and is shared as a link.

**`VerbCollection`** (`Models/VerbCollection.swift`, `nonisolated`) is the five featured lists and
every model: `.top100`, `.goVerbs`, `.strongPreterite`, `.irregularFuture`, `.irregularParticiple`,
and `.model(classNumber)`. Its key is the `list` link's target and the signals' value: `top100`,
`goVerbs`, `strongPreterite`, `irregularFuture`, `irregularParticiple`, and `model-<class>` with the
class number as written (`model-31`, `model-3-1`, `model-4B`). An alias class (31-1) is no
collection, since its verbs show under its parent's row. A key, once shared, must keep opening the
same list. Titles, descriptions, symbols, and the share text are in `VerbCollection+Text.swift`,
on the main actor.

**Membership is derived from the engine**, most frequent first:

| Collection | Verbs | Test, per verb |
|---|---|---|
| `top100` | 100 | `FrequencyBand.top100` |
| `goVerbs` | 11 | `hasGoPresent`: the yo presente ends in -go and the stem has no g of its own, so not sigo, juego, pago, or distingo |
| `strongPreterite` | 22 | `hasStrongPreterite`: the yo pretérito ends in an unstressed -e (tuve, hice, conduje), so not fui, di, or vi |
| `irregularFuture` | 13 | `hasIrregularFuture`: the engine marks the yo futuro with capitals (tendré) |
| `irregularParticiple` | 17 | `hasIrregularParticiple`: the participle, accents folded, is not stem + -ado or -ido, so podrido counts and creído does not |
| `model-<class>` | The model's page's verbs | `isInModel`: any reading's class, an alias class's under its parent |

A pattern list holds only **base verbs among the 1,000 most frequent** (`isPatternCandidate`: in
`FrequencyBand.top1000`, and not a compound by `VerbDraw.isCompound`, the Related Verbs relation),
because compounds such as detener follow their base verbs, and every compound is still on its
model's page, which has its own bar. With compounds the lists would hold 33 to 49 verbs, mostly of
tener, poner, venir, and traer. The pattern tests are static and take any infinitive, so the
pedagogy plan's draw can ask them. `VerbFamilies`' hand-made lists are their oracle in
`VerbCollectionTests`: each derivation finds their verbs (ser, ir, and dar aside, whose pretéritos
are irregular but not strong).

**Where they live**: a Collections section at the top of the Models tab, above
the "102 models" count, hidden while a model search is typed. On iPhone each is a compact row: the
title, three of its forms with the irregular letters red (`examples`: "tengo · hago · digo"), and
"opened/total"; five two-line rows with descriptions pushed every model below the fold, so the
description waits on the collection's page. On iPad each is a card with the forms, the description,
and a progress bar. A row pushes a `CollectionRequest` (collection and source) onto the tab's stack.
So does each model row, which is how the model's page learns it came from the tab; a bare
`ModelInfo`, pushed only by a verb page's model pill, opens the page with source `verbPage`.

**A featured collection's page** (`Views/VerbCollectionView.swift`) shows the description (and, for a
pattern list, a note on the band and compounds), the bar, a Frequency/Alphabetical control
(Frequency first, not stored), and the verbs (`VerbEntryList` with `showsLookedUp`). A verb opened
there reports `list`. **A model's page** gains the same bar between its grid and its verbs, and its
rows gain the check; a verb opened there still reports `model`.

**The bar** (`VerbCollectionBar`): "3 of 70 looked up", Quiz, Share, and a progress bar. Progress
counts verbs with a last open (`LearnerVerbStore.openedCount(of:)`); a star alone does not count,
and Clear in My Verbs resets every collection's progress. Quiz opens `QuizSheet` with
`QuizScope.collection(_:title:)`: thirty unranked questions over the collection's verbs in the
difficulty's tenses, titled with the collection's name ("-go Verbs", "Verbs Like tener"). Share
sends the title, the count, the six most frequent verbs, the `list` link with `source=sharedLink`,
and the App Store link; on iPad the sheet anchors to the button's own frame
(`ShareSheet.present(…anchorRect:)`), since the button is in the page, not the navigation bar.

**No `quiz/start?list=<key>`:** a shared link opens the collection, where Quiz is one tap.

