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
| `tapResetPractice` | None | When the learner confirms Reset Practice in Settings. Nothing says what the record held |

### Collection signals

| Signal | Parameters | Sent |
|---|---|---|
| `viewCollection` | `collection` (a key: `top100`, `goVerbs`, `strongPreterite`, `irregularFuture`, `irregularParticiple`, or `model-<class>`), `source` (`tab`, `verbPage`, `quizCorrection`, `sharedLink`, or `deeplink`) | Once for each opening of a featured collection's page or of a model's page, whose bar makes it a collection. A return from one of its verb pages sends nothing |
| `tapShareCollection` | `collection` | On each tap of a collection bar's Share button, whether or not the learner then shares |

A collection's quiz, and a custom quiz over a collection, adds `collection` to `startQuiz`. A collection names a list, never a verb, though
a model's key names the model.

### The `source` vocabulary

`AnalyticsSource` is one vocabulary for every signal that carries `source`: `viewVerbView`;
`finishSearch`, where it names the surface that opened the search field; and `startQuiz`,
`quitQuiz`, `completeQuiz`, and `abandonQuiz` (§ Quiz).

| Value | Sent today? | Meaning |
|---|---|---|
| `browse` | Yes | A row of the verb list with the search field empty |
| `control` | Yes | The Random Verb control in Control Center (`OpenRandomVerbControlIntent`); for `finishSearch`, the Find a Verb control (`OpenVerbSearchIntent`) |
| `custom` | Yes | The quiz signals: a custom quiz begun from the Quiz tab's Custom segment |
| `deeplink` | Yes | A `conjugar://` link with no recognized `source` query item; for `finishSearch`, a `search` link; for the quiz signals, a `quiz` link, which the Quick Quiz control, the Start a Quiz shortcut, and the Live Activity send; for `viewCollection`, a `list` link that names no source |
| `infoLink` | No | Reserved for a link from an Info article to a verb |
| `list` | Yes | A verb opened from a featured collection's page (a verb opened from a model's page stays `model`); for the quiz signals, a collection's quiz |
| `mistakes` | Yes | The quiz signals: Practice My Mistakes, from the Quiz tab's From Your Practice section |
| `lookup` | Yes | The Look Up a Verb shortcut: for `viewVerbView`, the page it opened when one verb answered; for `finishSearch`, the search it opened otherwise |
| `model` | Yes | A verb row on a model's page, in the Models tab or reached from a verb page's pill |
| `modelAlone` | Yes | The quiz signals: a verb model's practice alone, from its card on the model's page or in the Quiz tab's Verb Models list |
| `modelMixed` | Yes | The quiz signals: a verb model's practice mixed with the known models, from the same card |
| `myVerbs` | Yes | A row of My Verbs, the verb list's third segment; for the quiz signals, a quiz over My Verbs begun from the Quiz tab |
| `qrCode` | Yes | `viewPracticeSet` and the quiz signals: a practice set opened from its QR code |
| `quickAction` | Yes | `finishSearch` only: a search begun from the Find a Verb Home Screen quick action |
| `quizCorrection` | Yes | A link on a quiz's held correction: for `viewVerbView`, the verb's page; for `viewCollection`, its model's page |
| `recent` | Yes | A recent verb, listed while the search field is focused and empty |
| `recognition` | Yes | The quiz signals: Name the Form, from the Quiz tab's Exercises section |
| `related` | Yes | A chip on a verb page's Related Verbs card, or a row of the full list it opens |
| `resume` | Yes | A page that came back after another tab, a pushed page, or the background |
| `review` | Yes | The quiz signals: Review, from the Quiz tab's From Your Practice section |
| `reviewCard` | Yes | The review card above the verb list, tapped after its reveal |
| `search` | Yes | A result of a search that found something |
| `searchGuess` | Yes | The closest verb offered by a search that found nothing |
| `sharedLink` | Yes | `viewCollection`: a collection's shared link, which carries `source=sharedLink`. `viewPracticeSet` and the quiz signals: a practice set's shared link |
| `shortcut` | Yes | Open Random Verb run from the Shortcuts app or Siri (`OpenRandomVerbIntent`, offered as the Random Verb shortcut) |
| `spotlight` | Yes | A tap on a verb's Spotlight entry |
| `tab` | Yes | `finishSearch`: a search begun in the Verbs tab itself, Command-F included. The quiz signals: a quiz over every verb begun with the Quiz tab's Start. `viewCollection`: a collection or a model opened from the Models tab's list. `tapViewLeaderboard`: a leaderboard opened from the Quiz tab |
| `verbEssentials` | Yes | The quiz signals: Verb Essentials, from the Quiz tab's Exercises section |
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

**Navigation.** A verb page is pushed from three stacks, the Verbs tab, the Models tab, and the
quiz's (from a held correction, in the tab or in `QuizSheet`). Each injects
`VerbPagePush` (an environment action that appends to its own path) and registers the destinations
`verbPageDestinations()` names (`ModelInfo`, `RelatedVerbListDestination`), so the pill and the card
work in each, and a learner who arrived from a widget reaches a model's page without switching
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
| `quiz` | Any but `set`, or none (`quiz/start` by convention) | None | The Quiz tab, starting a quiz over every verb at once, as the Quick Quiz control and the quiz widget expect. The link's `source` (or `deeplink`) goes to the quiz signals |
| `quiz` | `set` | A custom quiz's stored form (`tenses`, and `verbs` or `infinitives`); `level`, while a part is left to it; `source`, `sharedLink` or `qrCode` | A practice set in a sheet over whatever tab is open, with Start (see [Practice sets](#practice-sets)). A link that names nothing this version knows shows "Practice Set Not Found" |
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
link a pending verb, so the last link wins on a cold launch. Any link but a practice set's clears a
pending practice set, whose sheet would otherwise hide what the link opened.

### Architecture

| File | Purpose |
|------|---------|
| `Utils/URLExtension.swift` | The grammar's constants (routes, query-item names), `isDeeplink`, `deeplinkTarget`, `deeplinkQueryValue(named:)`, `analyticsSource`, and the builders |
| `Views/AppRouter.swift` | `handle(url:)` parses a link and sets the tab and a one-shot request: `pendingVerb` (with its marks), `pendingSearch` (a `SearchRequest`: text and source), `pendingInfo`, `pendingQuizStart`, `pendingPracticeSet` (a `PracticeSetRequest`), or the game's flags. `openSearch(text:source:)` is the search route's effect, which Command-F, the control, and the quick action share. `AppRouter.shared` is the one instance, so that the quick action's scene delegate can reach it |
| `Views/VerbBrowseView.swift` | Consumes `pendingVerb` and `pendingSearch` with `onChange(initial: true)`, since a link can arrive before the tab first appears. A search request pops to the list first, waiting out the pop before it focuses |
| `Views/InfoBrowseView.swift` | Consumes `pendingInfo` the same way |
| `Views/ModelBrowseView.swift` | Consumes `pendingCollection` (a `CollectionRequest`: collection and source) the same way, pushing it onto the Models tab's stack |
| `Views/MainTabView.swift` | Receives URLs via `.onOpenURL`, and drains a control's pending link from the shared defaults when the scene becomes active. Shows a practice set's sheet through `AppRouter.presentablePracticeSet`, which holds the set back while the onboarding tour or the game covers the tabs |
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
conjugar://quiz/set?tenses=preterito&verbs=goVerbs&source=sharedLink
                                                → a practice set: the -go verbs in the pretérito
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
Neither touches the practice record, which keeps the review card's schedules (§ The Practice
Record).

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
`viewVerbView` is sent with a source other than `resume`. The same arrival is the practice record's
lookup. A page that comes back after another tab,
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

## The Practice Record

**What it is.** The quiz's memory and the review card's schedule, one record (`PracticeRecord`,
`Shared/PracticeRecord.swift`, `nonisolated`, Codable): a box and a due date (`ReviewSchedule`) for
each item a quiz answer, a lookup, or the review card has touched, with the last answer, whether it
was right, and the last lookup. It is kept on the device in the App Group's defaults, under
`practiceRecord`, and sent nowhere. `Current.practice` is a `PracticeStore`
(`Models/PracticeStore.swift`, `@Observable`), which maps questions and lookups to items and saves
after each change; the unit-test worlds give it a `GetterSetterFake`, and `Quiz(practice:)` takes a
store of a test's own.

**The items** (`PracticeItem`, mapped in `Models/PracticeItemMapping.swift`). A question whose cell
is irregular, as `QuizDraw.isIrregular(_:in:)` judges it (a capital in the engine's form, so a
spelling change such as busqué or cojo too, and a compound by its participle), exercises the **key
conjugation** whose stem the cell is built on: `key:tener:yo_presente`. A question whose cell is
regular exercises a **pattern**, a tense, a person, and an ending shared by every verb regular in
that cell: `pattern:imperfecto_de_indicativo:fs:er`, so tener's tenía moves the same item as
comer's comía. Keys are built from permanent names (the custom quiz's tense keys, plus
`participio`; `DisplayPersonNumber` raw values; ar, er, ir) so that the widget, which has no verb
map, can read the record. `PracticeItemTests` pins them.

| Key conjugation | Irregular cells that map to it |
|---|---|
| yo presente (tengo) | the presente, every person (tienes, duerme); the presente de subjuntivo; both imperatives, every person (ten, tenga, no tengas); the imperfecto (era, iba, veía) |
| yo pretérito (tuve) | the pretérito, every person (pidió); both imperfectos de subjuntivo; the futuro de subjuntivo; the gerundio (durmiendo, built on durmió) |
| yo futuro (tendré) | the futuro; the condicional |
| participio (escrito) | the participio; every compound tense |

The presente's other persons, the tú and vos commands, the imperfecto, and the gerundio are not
built on their key's form, only near it, so a slip in tienes counts against tengo. Prefixed verbs
(mantener) and reflexive-only verbs (arrepentir, by its bare infinitive) have items of their own.

**Which key conjugations a verb has.** Only those that some irregular cell of the verb maps to
(`PracticeItem.keyConjugations(of:)`), since only such a cell's answer moves one: tener has three
(tenido is regular), pensar one, pedir two, escribir only its participle, and a regular verb none.
A review of a key conjugation asks the first irregular cell built on it (`irregularCells(of:builtOn:)`),
its own cell first: tengo, but pidió for pedir's yo pretérito, since pedí is regular. That is what
makes a review move the item it was for.

**The ladder.** Boxes of 1, 3, 7, 14, and 30 days, the last repeating; due dates fall at the start
of a day. A wrong answer starts an item over (box 0, due tomorrow). A right answer moves it up only
when it is due, so a pattern asked three times in an afternoon climbs one box. A new item answered
right enters box 1 (three days); answered wrong, box 0. A slip's right second attempt is right; a
re-ask is another answer. A lookup starts an irregular verb's key conjugations over; a lookup from
the card (source `reviewCard`) leaves a scheduled item where it is.

**Recording.** `Quiz.process(proposedAnswer:)` records each final answer as it is given, in every
scope (the tab, My Verbs, Test Me, a collection, a custom quiz, a practice set), so a quiz quit after
six questions has practiced six. A slip's first attempt records nothing until the second.

**Due items in the default quiz.** Each round of the default quiz (`QuizScope.mixesDueItems`, the
ranked scope) mixes in up to three due items (`QuizDraw.dueQuestions`), the most overdue first,
placed at random among a draw of seven, in Ten More rounds too. A key conjugation asks the first
irregular cell built on it that the level asks (tú or vos, region, and the level's persons
included), of its verb, if the verb is in the band. A pattern asks its cell of a regular verb of its
ending from the band. An item the level does not ask, or a verb beyond the band, waits for a review
session. Due questions sit outside the mix of `QuizDraw`, which balances the rest, so a round with
due items may have fewer than five irregular questions. A scoped or custom quiz asks only what was
chosen.

**The migration.** On the first launch with no stored record, the store reads `LearnerVerbs`' old
per-verb `review` schedules (or, for an entry from before them, a start at its last open) and gives
each irregular verb's key conjugations that schedule. `LearnerVerbs` no longer has the field;
decoding ignores it.

**Reset Practice** sits at the foot of Settings' quiz card while the record holds anything. An
alert confirms it, and it sends `tapResetPractice`. The record is saved empty rather than removed,
so the next launch does not migrate the old schedules again.

**Seeding the record in the simulator.** As for the learner's record: `xcrun simctl spawn <udid>
defaults write <group container>/Library/Preferences/group.biz.joshadams.Conjugar practiceRecord
-string '<json>'`, with dates as seconds since 2001-01-01, while the app is not running.

## The Review Card

**What it offers.** The card reads the practice record (§ The Practice Record): an irregular verb
whose key conjugation is due, from a lookup or a quiz answer alike. Only irregular verbs, as the
verb page's pill counts them (`VerbDraw.isIrregular`, any class but 1, 2, and 3), so buscar's card
shows busqué's red letters. A regular verb's answers move patterns, which are never on the card.

**What moves it**:

- A lookup by any route but the card puts the verb's key conjugations in box 0, or back there,
  since looking a verb up again suggests it was forgotten. A quiz answer moves its item as the
  ladder says.
- A reveal moves each due key conjugation of the verb up a box; one not due keeps its place. An
  open from the card after the reveal counts as an open for My Verbs but leaves the schedule.
- The ✕ before a reveal is no review: the due key conjugations keep their box and return tomorrow.
  The ✕ after a reveal changes nothing.
- Clear in My Verbs and a swipe that removes a verb leave the schedule; Reset Practice in Settings
  clears it.

**Which card.** `PracticeStore.cardOffer()` takes the verb whose key conjugation is longest
overdue, ties broken by key, with each of its due key conjugations. `VerbBrowseView` chooses once at launch and again at each return from the background,
so a reveal does not swap the card for the next verb due. The card hides while anything is typed
and while the recents show, and is absent from My Verbs, which is a list of its own. On iPad it
stops at 560 points rather than spanning the grid.

**The card** (`Views/ReviewCardView.swift`) shows "Looked up 3 days ago", or "Practiced 3 days
ago" when a quiz answer came after the last lookup ("yesterday" for one, counted in calendar days,
from the latest activity of any of the verb's key conjugations), the citation form (arrepentirse), the gloss, and the key conjugations
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
container>/Library/Preferences/group.biz.joshadams.Conjugar practiceRecord -string '<json>'`, with
dates as seconds since 2001-01-01, while the app is not running. Without `-string`, `defaults`
tries to parse the JSON as a plist and fails. A record of key conjugations due long ago, such as
`{"entries":{"key:tener:yo_presente":{"schedule":{"box":0,"due":0},"lastLookedUp":0}}}`, offers
tener.

## Quiz

The pedagogy plan reshapes the quiz and should extend this rather than replace it.

**Levels.** The learner chooses one of four levels in Settings (`Settings.quizLevel`, key
`quizLevel`; a new install starts at Beginner), and nothing unlocks. `QuizLevel`
(`Models/QuizLevel.swift`, `nonisolated`) lists each level's tenses written out in `pool`, so each
reads as a whole, and each adds to the one before:

| Level | Spanish | Roughly | Tenses added |
|---|---|---|---|
| Beginner | Inicial | A1 | presente; imperativo positivo of tú or vos, usted, and ustedes |
| Elementary | Elemental | A2 | pretérito; imperfecto; perfecto de indicativo; futuro; gerundio |
| Intermediate | Intermedio | B1 | presente de subjuntivo; imperativo negativo; imperativo positivo of nosotros and vosotros; condicional; pluscuamperfecto de indicativo; futuro perfecto |
| Advanced | Avanzado | B2 and above | both imperfectos de subjuntivo; perfecto de subjuntivo; both pluscuamperfectos de subjuntivo; condicional compuesto; futuro de subjuntivo; futuro perfecto de subjuntivo; pretérito anterior |

A `QuizPoolEntry` is a tense, the persons it leaves out (a beginner's commands leave out nosotros and
vosotros), and a weight, the same at every level and never changed by what the learner has done:
3 for the presente, pretérito, and imperfecto, the most used (`docs/tense_frequency.md` puts the
imperfecto above the pretérito); 2 for the other simple tenses and the two imperatives; 1 for the
gerundio, every compound tense (haber, which the simple tenses already ask, and a participle that
never changes), and the futuro de subjuntivo, which is rare outside legal and literary prose. A
weight belongs to a tense as a whole, whatever its number of persons. No tense is asked only of
certain verbs. A stored Easy, Moderate, or Difficult (key `difficulty`) became Elementary,
Intermediate, or Advanced the first time the app ran without a level. The Info tab's filter keeps
its own three difficulties, `InfoDifficulty`, which has nothing to do with the levels.

Every right answer scores 10 at every level, 5 on a second try or on a re-ask, and the score is
their sum: no normalization to fifty questions and no multiplier for the region or level.

**`QuizScope`** (`Models/QuizScope.swift`, `nonisolated`) says what a quiz asks about: the verbs
(nil for every verb, drawn from the level's frequency band; otherwise bare infinitives), the
question count, and the `source` its signals carry. `allVerbs` is the Quiz tab's quiz over every
verb, `allVerbs(source:)` the same begun by a `quiz` link, `myVerbs(_:)` a round over My Verbs,
`verbPage(_:)` Test Me's three, and `collection(_:title:)` a round over a collection, which also
carries a `title` for the sheet and a `collectionKey` for `startQuiz`, and `custom(_:myVerbs:)` a
round of the learner's own choice (§ Custom quiz below), which carries a `custom`. A round is
`QuizScope.roundLength`, ten questions. `continues` (a round's length or more) decides whether the
results offer Ten More, so Test Me's three do not. `isRanked` (every verb, one round, no custom
choice) decides whether a session's first round posts to Game Center (`Quiz.isRankedRound`). No
scoped or custom quiz ranks. `pool(level:)` and `band(level:)` give the tenses a quiz asks and the
band a quiz with nil `verbs` draws from: a custom quiz's choice, else the level's.

**The draw.** `Quiz.start(scope:)` defaults to `.allVerbs`, and returns false, changing nothing,
when the scope gives no question (an empty My Verbs). Every random choice goes through one
generator: `Quiz(randomSource:)` takes one (tests pass `SplitMix64`, so a seed draws the same quiz
in every process); without one, a shuffling quiz uses the system's, and an unshuffled one
(`shouldShuffle: false`, for tests and UI tests) a fixed seed.

- **Every verb** (`mixedQuestions(count:pool:band:)`) draws each question's tense from the pool by
  weight and its person from the tense's rotation, then hands the cells to `QuizDraw`
  (`Models/QuizDraw.swift`, `nonisolated`), which chooses the verbs from the band. See **Which
  verbs** below. `QuizDraw` keeps its per-band data by `FrequencyBand?` (nil for every verb), so a
  custom quiz over a band other than the level's is mixed the same way.
- **A round over chosen verbs** (My Verbs, a collection) draws tenses by weight the same way and
  puts the scope's verbs into them, preferring a verb not already asked in that cell, then the verb
  asked least, then the next in turn, so a defective verb gets its share of the cells it has. A
  tense none of the verbs has is left out. Ten More passes the session's questions so far, so a
  later round goes on taking turns with the earlier ones.
- **Shorter** (Test Me) takes distinct cells one tense at a time, in an order drawn by weight, so the
  presente tends to come first. A beginner's three questions span its two tenses.
- **Each** skips a cell the engine does not give for that verb (a defective verb's), asks tú or vos
  by the quiz setting, no vosotros in the Latin America region, no yo in a command, and no person
  the level leaves out.

**Which verbs.** The default quiz draws its verbs from the level's frequency band
(`QuizLevel.band`): the 100 most frequent verbs at Beginner, 300 at Elementary, 1,000 at
Intermediate, and every verb at Advanced. No verb with an estimated count (`hitsAreProvisional`)
sits in the top 1,000. Within the band the draw is uniform, and it is balanced:

- **Half the questions**, rounded down, ask a cell in which the verb is irregular. Irregularity is
  judged per cell, not per verb (`QuizDraw.isIrregular(_:in:)`): a cell is irregular when the
  engine's form marks a capital, as the verb page shows it in red, so a spelling change (llegué,
  cojo, creyó) counts. A compound tense is judged by its participle alone, since its haber is the
  same for every verb. A tense whose irregular verbs in the band come from fewer than five roots
  (the imperfecto: ser, ir, ver, and ver's compounds) asks at most one irregular question, and the
  other tenses make up the half, so a quiz does not repeat era, iba, and veía. A cell gets no more
  questions of one kind than it has verbs to give them: Beginner's presente has only sois and vais
  irregular for vosotros.
- **At least two questions** ask a core verb: ser, estar, haber, tener, ir, or hacer.
- **Prefixed compounds** (`VerbRelations.shared.baseByVerb`): a compound among the 300 most frequent
  verbs (mantener, conseguir) draws as freely as a base verb. Where the band reaches past them
  (Intermediate and Advanced), exactly one to three questions ask a rarer compound and no other
  question does; at Beginner and Elementary, at least one question asks a compound.
- **The regular questions** take the -ar, -er, and -ir endings in turn, so -er and -ir verbs are not
  drowned by a band's many -ar verbs.

The draw gives every slot its role (core, compound, free) and its irregularity before choosing any
verb, so the counts are exact, not likely, at thirty questions or ten. To keep it cheap, it judges
each cell once per model class rather than per verb: a model's features are end-anchored, so a
class's verbs are irregular in the same cells, with rare exceptions (prever and entrever) that the
draw catches by judging the verb it chose with the engine. The judgments are cached for the
process; a quiz costs about 5 ms at Beginner and 20 ms at Advanced in a debug build. The
hand-curated lists in `VerbFamilies` now live in the test target, as the oracle that the engine's
judgment finds every verb a teacher would call irregular in a tense (`VerbFamiliesTests`).

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
or usted), though never before a command, a gerundio, or a participio. `grade(_:)` gives
`.totalMatch` or `.noMatch`; accents count. The -ra and -se imperfect subjunctives never stand in for
each other.

**One more try.** A wrong first attempt that is a slip (`QuizQuestion.isSlip(_:)`, in
`AnswerSlip.swift`) earns one more: `Quiz.process(proposedAnswer:)` sets `Quiz.firstAttempt` and
returns nil, records nothing, and leaves the clock running. A slip differs from an accepted spelling
only in accents, the diaeresis, and ñ's tilde, however many and at any length (cantaria, ire,
ensenaria), or, in an answer of four letters or more (spaces excluded), by one insertion, deletion,
substitution, or swap. It is never another cell of the verb, compared through `ConjugationMatch`
with accents and tildes ignored (`.bare`) and the cells whose forms are right answers left out: hablo
for habló is the presente, hable for hablé the presente de subjuntivo, and comio for comí is comió,
the wrong person. The quiz shows "Almost! Try once more." under the field, which keeps the slip to
edit, with a pop and a light tap, and VoiceOver announces the line. A right second attempt scores
`.secondAttemptMatch`, 5 points, and is counted apart from `correctCount` (`secondAttemptCount`);
`firstAttempts` keeps the slip for the results, which show "Correct: 8 / 10 · Second Try: 1" and a
"First Try:" line on the row. A wrong second attempt, a second slip included, goes to the
correction. One more try is all a question gets, whatever earns it.

**Naming the error.** Before the slip check, `Quiz.process(proposedAnswer:)` asks
`QuizQuestion.diagnosis(of:)` (`AnswerDiagnosis.swift`) what was wrong with a wrong first attempt.
A diagnosis earns the same one more try: `Quiz.firstAttemptDiagnosis` holds it beside
`firstAttempt`, and `Quiz.secondAttemptPrompt` is its line plus "Try once more." in place of
"Almost! Try once more.", in the same yellow line, sound, and announcement. The held correction
shows the diagnosis of the final answer (`QuizCorrection.diagnosis`) under the two answers with a
lightbulb, without "Try once more.", and VoiceOver reads it after the differing letters; a repair
wrong in a way nothing names gets no line. Every check is an exact construction compared with the
answer, never a resemblance, because a wrong diagnosis is worse than none. They run from the most
specific to the least and stop at the first that fits: a negative command written as the affirmative
or the indicative (no habla, no hablas); a spelling feature of the verb's model left out
(`StemFinalConsonant`: buscé, escogo; `IYHiatus`'s y: leió; `AbsorbIAfterPalatal`: bullió;
`AccentStem`: envio); a `StemVowel` left out (penso, sentió) or, in a cell whose right form has no
stem change, made anyway (piensamos, sintí); the feature-less regular form, said only where the
verb is irregular in more than spelling and stem vowel, so leer's leiste is not "the regular form"
(tení, sabo, he hacido, whose irregularity the line places in the participio); and another cell of
the verb, exact, through `ConjugationMatch`: the other imperfect subjunctive of the same person
("That is the -ra form. The -se form was asked."), then another person of the asked tense (tú's
vos form included, which the quiz does not accept), then another tense, whose persons are named
only when the asked one is not among them. The rules come before the cell match, since dice for
decir's di is both a regular construction and the presente (él). The constructions use
`Conjugator.model(for:)` with a feature removed or replaced and
`TenseBridge.conjugate(infinitive:tense:personNumber:model:)`, which conjugates any displayed cell,
compounds included, against a given model. The engine writes such a construction as the 2010
*Ortografía* would (leió as leio), so the answer is compared in its current spelling too.

**The held correction.** A right answer advances at once. A wrong one holds the question:
`Quiz.process(proposedAnswer:)` stops the clock and sets `Quiz.correction` (a `QuizCorrection`, an
`AnswerDifference`), and
`continueAfterCorrection()` clears it, advances or finishes, and restarts the clock. A wrong last
answer therefore shows its correction before the results. `QuizCorrectionView` sits under the
answer field: Your Answer and Correct Answer, a link to the verb's page (scrolled to the asked cell
and marked) and to its model's page ("Verbs Like tener"), and Continue. The field keeps the
learner's answer and the keyboard, so Return continues; Return resigns a `TextField`, so the view
refocuses the field as the hold begins and again once Back returns from a linked page, clearing the
focus state first because setting it to the value it still holds does nothing. A Magic Tap also
continues. The links push onto the quiz's own stack (it injects `VerbPagePush` and registers
`VerbDestination`, `QuizCorrectionModel`, and `verbPageDestinations()`), report `quizCorrection`,
and leave the clock stopped, since it is stopped for the whole hold. The verb link is left out of a
quiz begun from that verb's page, and the model link out of a quiz over that model's verbs.
`isBeneathQuiz` hides Test Me and a model's Quiz button on the pages pushed while a quiz is in
progress, so there is no quiz inside a quiz.

**The marking.** `QuizQuestion.difference(from:)` shows the nearest of `shownSpellings` (the
written answer, irregularity-marked, winning a tie), so freido is corrected to freído and arepiento
to arrepiento rather than me arrepiento, and drops a leading subject pronoun as grading does.
`AnswerDifference.between(given:expected:)` aligns the two with `VerbSearch.editDistance`'s costs
(a swap of neighbors costs one) and marks what the cheapest alignment leaves unmatched. An accent
is a letter of its own, so hablo against habló marks the o. Red letters already mean irregular, so
a difference is a tinted background instead: struck through in red in the learner's answer, and
underlined in green in the right one, whose red letters stay red. A missing letter has nothing to
mark in the learner's answer, so it shows only in the right one. Case is never a difference.
VoiceOver moves to the correction and reads "Incorrect. Your Answer: hablo. Correct Answer: habló.
Letters that differ: ó." (the letters only when three or fewer; "Half points: only the accent marks
differ." in place of "Incorrect." for a partial match), the answers in Spanish. `SpanishLetterKeyRow` inserts at the answer field's cursor through a `TextSelection`
binding. On the iPhone it is a keyboard toolbar; iPadOS's keyboard shows no toolbar items, so on
the iPad it sits under the field. The question view takes the keyboard again as it appears, since a
quiz started by a link focuses the field before it is on screen and the row then never joins the
keyboard.

**Rounds and Ten More.** A session is rounds of ten. `Quiz.questionCount` counts the rounds'
questions so far, re-asks not included, and `score`, `correctCount`, `secondAttemptCount`,
`reaskCount`, and `reaskCorrectCount` are computed from `questions` and `results` rather than kept
alongside them. A round ends when the last question in `questions`, re-asks included, is answered.
The results then offer Ten More while `Quiz.canContinue` (a finished round, not a quit, of a scope
that `continues`): `continueSession()` appends a fresh draw of ten at the session's level, so every
round has a first round's mix, and the score, the clock, and the questions so far carry on.
`roundCount` counts the rounds. Only the first round of a ranked session posts, and only its own
questions' points (`firstRoundScore`, re-asks not counted), so every ranked score has the same
ceiling, 100. The results' counts ("Correct: 8 / 10 · Second Try: 1 · Asked Again: 1 / 2") and
pills wrap through `FlowLayout`. Ten More has no limit.

**Re-asks.** A wrong answer (`.noMatch`, after any second attempt) inserts the question again,
`QuizQuestion.reasked()`, `Quiz.reaskGap` (3) questions on, or at the round's end if that comes
first, so a question missed near the end returns before the results. A re-ask is asked once,
whatever its answer, and a right answer to it earns 5 on either attempt (`Quiz.points(at:)`); a slip
still earns its second attempt. The correction says "This question will come up again." when it
will, and VoiceOver reads the line with the correction. A re-ask's card shows an "Asked Again" pill,
which VoiceOver announces as the question comes, and its results row says so too. A test or a
fixture that walks a quiz by index must expect `questions` to grow.

**The quiz clock.** `Settings.quizClock` (`QuizClock`, key `quizClock`, default `hide`) decides
whether the question view, the results, and the Live Activity show the time. The clock counts
either way, and stops while a correction holds the question.

**A quiz left in progress.** `QuizAbandonment` keeps an entry in the defaults (key
`quizzesInProgress`) for each quiz under way, written as a round begins and at each question and
removed when it is quit or reaches its results, keyed by `Quiz.abandonmentID`, since a sheet's quiz
can run beside the tab's. `ConjugarApp.init` sends `abandonQuiz` for each entry the last run left
and clears them, before any view can start a quiz of its own.

**Test Me** is the clipboard (`pencil.and.list.clipboard`) first in a verb page's navigation bar,
before the star and Share, read by VoiceOver as "Test Me on This Verb". It opens `QuizSheet`
(`Views/QuizSheet.swift`), which owns a `Quiz` of its own, so a quiz in progress in the tab carries
on, and shows `QuizView(quiz:sheetScope:)`. In sheet mode the view starts the quiz as it appears
(something must be on screen for `onAppear` to fire, hence a `Color.clear` before the start), shows
the results in place of the question with a Done button, closes on Quit, and cannot be swiped away
mid-quiz, so every quiz it starts ends with `quitQuiz` or `completeQuiz`. It skips `viewQuizView`,
the Game Center prompt, and the router's quiz link.

The Live Activity's attributes carry the level's raw value (`QuizActivityAttributes.level`), which
the widget does not show. Each round starts one, and its content state carries the session's
question on screen and its total so far (`totalQuestions`, which a re-ask grows), and the time only
while the quiz clock shows it (`elapsedTime` is optional). **A quiz shorter than a round** starts no
Live Activity, and does not count toward `ChangeLevelTip`, which only a first round's results
donate to. Nor does a collection's quiz start one, though it is a round, because it
runs in the sheet beside a quiz the tab may hold, and the Live Activity is one for the app
(`QuizScope.startsLiveActivity`; `Quiz.hasLiveActivity` keeps a sheet's quiz from ending the tab's).
Quiz.swift reaches the activity through `Current.liveActivities`: `LiveActivitiesReal` on device
and in the simulator World, and `LiveActivitiesSpy` under tests, which `QuizLiveActivityTests`
checks these rules against.
A collection's completed quiz does count toward the tip.

**The Quiz tab's start screen, the practice hub**, says what a session is before Start: a yellow
symbol for the scope (`books.vertical.fill`, or a star for My Verbs; 64 points on an iPhone, 180 on
an iPad), the scope's name ("4,811 verbs" or My Verbs) and a line on what the quiz asks, the
All Verbs / My Verbs / Custom picker, three tiles (10 Questions; 2–3 Minutes, a fixed estimate,
since showing the learner's own times would undo the hidden clock; and the level with its gauge),
for My Verbs the verbs as centered chips, up to twelve and "+N more" (`FlowLayout.centersRows`),
then Start, then From Your Practice (Review, My Mistakes, and Last Quiz), and last, while signed in
to Game Center, a small View Leaderboard button. The level tile is a menu of the four levels with a
chevron, setting the same `Settings.quizLevel` as Settings, where each level is a tile with a gauge
(`gauge.with.dots.needle.0percent` to `100percent`) whose needle rises with the level, since a
four-segment picker would truncate the names on an iPhone. The region is no longer on the hub; it
is in Settings. **Last Quiz** (`LastQuizResult`, `Models/LastQuizResult.swift`) is the last round's
results that appeared: written by `Quiz.finish()` for every scope, a verb page's three and a
collection's sheet included, so after Ten More it is the session so far; a quit writes nothing. It
keeps a kind and a subject (a verb, or a collection's key) rather than a title, so it reads in the
current language: "All Verbs · Elementary · today", then "Correct: 7 / 10 · Second Try: 1 · Score:
75". Review and My Mistakes keep no level. `PracticeStore` keeps it in the App Group under
`lastQuizResult`, sent nowhere; the row is absent until a round has finished, and Reset Practice
forgets it. `ChangeLevelTip` ("Choose Your Level")
points at it after a first round's results; Settings attaches it only while Settings is on screen,
since a popover tip on a view that outlives the tab's first visit would float over the Quiz tab's
results when the quiz finishing met its rule. Start is disabled while My Verbs is empty. The choice is not
stored. On iPad the symbol, type, and tiles are larger and Start is scaled up.

**Custom quiz.** The picker's third segment, Custom (Personalizado), shows `slider.horizontal.3`,
"Custom Quiz", a card summarizing the choice (Tenses, Verbs), and Choose or Change, which pushes
`CustomQuizEditor` (`Views/CustomQuizView.swift`) onto the tab's stack. Its Tenses section is "Set
by Your Level" and one row per tense in the order the levels add them, each saying the level that
adds it ("From Intermediate"); its Verbs section is "Set by Your Level", the three bands, All
Verbs, My Verbs (only while it has verbs or is the stored choice), the four pattern lists, and
Models, a further push of the Models tab's rows. Empty, the segment says what to choose and Start
is disabled, as it is when the choice names an empty My Verbs. The choice is `CustomQuiz`
(`Models/CustomQuiz.swift`, `nonisolated`): a set of tenses and an optional `QuizVerbSet` (`all`, a
`band`, a `collection`, or `myVerbs`). The tab still opens on All Verbs, so Custom is one tap from
Start and never the default.

- **A part left unchosen is the level's.** Tenses alone ask the level's band; a verb set alone asks
  the level's tenses.
- **A chosen tense is asked as Advanced asks it**, of every person, at any level, and any tense may
  be chosen, above the level or not.
- **A band or All Verbs is mixed** as the default quiz is (`QuizDraw`); a collection or My Verbs is
  a list, drawn as a scoped round is. The top 100 is offered only as its band. A pattern list asks
  the chosen or the level's tenses, not its pattern's, so -go verbs may be asked their pretérito.
- **Kept between launches** in `Settings.customQuiz` (key `customQuiz`), not shown in Settings, as
  `tenses=presente_de_indicativo,preterito&verbs=goVerbs`, a form a link's query can carry. A tense's
  key is its Info article's stable key (`ConjugationTable.articleKey`), or `gerundio`; a verb set's
  is `all`, `top100`, `top300`, `top1000`, `myVerbs`, or a collection's key. An unknown key is
  dropped alone. `CustomQuizTests` pins the form.
- **Never ranked**, with Ten More, a Live Activity (it runs on the tab, so a collection choice starts
  one too), and the tip donation, like any round.

### Practice sets

A custom quiz can be shared as a link or a QR code, so that a teacher can hand a class one practice
set without accounts or a server. While Start is enabled, the Custom segment shows Share beside
Change, a menu of Share Link (the system share sheet with a summary, the set's `conjugar://` link,
and the App Store link; there is no web domain, so no universal link) and Show QR Code
(`PracticeSetQRView`, full screen). Both are in `Views/PracticeSetView.swift`; the set is
`PracticeSet` (`Models/PracticeSet.swift`) and the code `QRCode` (`Utils/QRCode.swift`, Core
Image, made on the device).

- **The link** is `conjugar://quiz/set?` followed by the custom quiz's stored form, then `level`
  and `source`. `PracticeSetTests` pins its form, since shared links outlive the version that made
  them.
- **A shared My Verbs carries its verbs**, as `QuizVerbSet.list`, since the opener's My Verbs are
  their own. It travels as `infinitives=tener,a%C3%B1adir` in place of `verbs`, so that an
  infinitive is never read as a set's key, and holds at most `PracticeSet.maximumListCount` (100)
  verbs, which keeps a projected code coarse enough to scan. An empty My Verbs leaves the verbs to
  the level. The editor lists a kept list only while it is the choice, since nothing there builds
  one. A link naming `verbs=myVerbs` drops that part.
- **The level travels only while a part is left to it**, so that every student is asked the same
  tenses and verbs whatever their own level. `QuizScope.level` asks at it without touching the
  learner's setting.
- **The length does not travel.** Every set is a round of ten, then Ten More.
- **Opening a set** shows `PracticeSetView` in a sheet over whatever tab is open, page-sized on
  iPad. It never starts a quiz unasked. Start runs the quiz in a `QuizSheet` over it, never ranked
  and with no Live Activity (`QuizScope.isPracticeSet`). Keep as My Custom Quiz replaces the
  learner's custom quiz, only when tapped; a kept set asks the learner's own level for any part left
  to the level. A list's verbs show as chips, as My Verbs' do.
- **A link that names nothing** this version knows shows "Practice Set Not Found" with a line that
  the link may be cut short or need a newer app. Unknown keys, unknown infinitives, and an unknown
  level are dropped and the rest kept.
- **The QR view** draws dark modules on white in both appearances, since some scanners misread a
  light-on-dark code, keeps the screen awake, and shows the set's tenses and verbs beneath the
  code. Its link says `source=qrCode`; the shared text's says `sharedLink`.

**Signals.** `startQuiz`, `quitQuiz`, `completeQuiz`, and `abandonQuiz` carry `level` (a
`QuizLevel` raw value, in place of the old `difficulty`) and `source`: `tab`, `myVerbs`, `list`,
`verbPage`, `custom`, a practice set's `sharedLink` or `qrCode`, or a `quiz` link's own (`deeplink` by default), so that three-question completions do
not raise a round's completion rate. There is no `tapTestVerb`: the sheet starts its quiz as it
opens, so `startQuiz` with `verbPage` counts the same taps. Ten More sends no signal of its own.

| Signal | Further parameters | Sent |
|---|---|---|
| `startQuiz` | `collection` for a collection's quiz, a custom quiz over one, or a model's practice (`model-4A`); `customChoice` (`tenses`, `verbs`, or `both`) for a custom quiz or a practice set, which says what kind of choice and never which | As a session starts |
| `tapSharePracticeSet` | `method` (`link` or `qrCode`) and `customChoice`, never which tenses or verbs | On Share Link or Show QR Code |
| `viewPracticeSet` | `outcome` (`opened`, or `invalid` for a link that names nothing) and `source` | Once for each practice-set sheet a link opens |
| `tapKeepPracticeSet` | None | On Keep as My Custom Quiz |
| `completeQuiz` | `duration`, `questionCount` (10, 20, …, or 20, 40, … for Verb Essentials) except for a record session or a model's mixed practice, `score` for a ranked session's first round only | At each round's results |
| `quitQuiz` | `duration`, `questionNumber` except for a record session or a model's mixed practice, `score` during a ranked session's first round only | On Quit |
| `abandonQuiz` | `questionNumber` except for a record session or a model's mixed practice | At the next launch, for each quiz the app was left during |

`duration` is wall-clock from the session's start, background included, in the bands of
`AnalyticsBand.quizDuration`: 0-3s, 3-15s, 15-40s, 40s-2m, and 2m+. It replaced the exact
`elapsedTime`. `questionNumber` is `Quiz.questionReached`, which counts no re-ask, since a re-ask
follows only a wrong answer and a count that included them would say how many answers were wrong.
`score` is `firstRoundScore`, and no other quiz or round sends one. **A record session (Review or
Practice My Mistakes) sends no counts** (`QuizScope.sendsQuestionCounts`): a round shorter than ten
is exactly as long as the learner's due or missed items, so its length would count wrong answers.
`QuizAbandonment.Entry.questionNumber` is optional for that reason.

**Game Center.** Each level has a leaderboard, `QuizLevel.leaderboardID` (`Utils/GameCenter.swift`):
`conjugar.level.beginner`, `.elementary`, `.intermediate`, and `.advanced`. App Store Connect never
lets an ID change, so `QuizLeaderboardTests` pins each literally. A ranked session posts
`firstRoundScore`, the first ten questions' points with second attempts' 5s and without re-asks, to
the board of the level it began at (`Quiz.lastLevel`), so every ranked score's ceiling is 100.
Nothing breaks ties at 100. `GameCenter.submitScore(_:level:)` returns at once (`GameCenterReal`
starts its own task), so a test sees the call through `GameCenterSpy`. The quiz's end shows no
leaderboard, and its results offer none: the leaderboard is beside the point of practice. While the
learner is signed in, the Quiz tab's hub ends with a small View Leaderboard button, which opens the
board of the learner's level (`showLeaderboard(level:)`), and Settings' Game Center card offers View
Leaderboards in place of Enable, which opens Game Center's list of the boards
(`showLeaderboards()`). Both send `tapViewLeaderboard`, the hub's with `level` and `source` `tab`. The live board the
shipped app posts to, `biz.joshadams.Conjugar.leaderboard`, is retired on release day.
`Conjugar/GameCenterResources.gamekit` is Xcode's local copy of the configuration. The App Store
Connect side, and how to test before release, are in [`game_center_setup.md`](game_center_setup.md).

### Review and Practice My Mistakes

**Where.** A From Your Practice (De tu práctica) section below the start screen's tiles, on every
segment, with one row each for Review (Repaso) and Practice My Mistakes (Practicar mis errores).
A row with questions shows their count and a play symbol, and a tap starts the session at once on
the tab. An empty row is not a button; it says why it is empty. Review gives the days to the next
due item ("Nothing is due today. The next review is tomorrow."), or, with nothing scheduled, says
that quiz answers and irregular verbs looked up come due a day or more later. My Mistakes says that
a missed question waits there until answered right. The count is `Quiz.askableCount(for:)`, the
session's items the settings let it ask. On an iPhone 17 the Review row sits above the fold.

**What each asks** (`QuizRecordSession`, `Models/QuizRecordSession.swift`, and
`QuizDraw.sessionQuestions`). Review: the record's due items, the most overdue first. My Mistakes:
the items whose last answer was wrong, the most recently missed first (`PracticeRecord.missedItems()`).
A key conjugation asks the first irregular cell built on it (`PracticeItem.irregularCells`), its own
cell first, so pidió for pedir's yo pretérito. A pattern asks its cell of a regular verb of its
ending from the level's band. **Neither is held to the level's tenses or band**, so Review asks what
the default quiz's due items left out (a yo pretérito looked up at Beginner, a participio, a rare
verb looked up). The tú or vos setting and the region still apply (`QuizDraw.canAsk`), so a vosotros
pattern missed in Spain waits while the region is Latin America. A verb's key conjugations sit
together in the verb page's order, at the place of the first drawn; nothing is shuffled
(`QuizScope.shufflesQuestions`).

**Rounds.** Up to ten items, then Ten More while an askable item remains that the session has not
asked (`Quiz.canContinue` reads the record). Fewer than ten make a shorter round. Each round skips
the items the session has already asked, which Review hardly needs (an answered item is no longer
due) but My Mistakes does, since a mistake missed again would come straight back. Re-asks, second
attempts, and recording work as in any quiz. A record session is never ranked, mixes in no due
items, does not donate to `ChangeLevelTip`, and starts the Live Activity, since it runs on the tab.
While it runs, the tab's bar reads the session's name.

### Verb Essentials

**What it asks** (`Models/VerbEssentials.swift`, `QuizScope.verbEssentials(_:)`). Given an
irregular verb, the learner types its key conjugations (`KeyConjugation`): "tener: tengo · tuve ·
tendré · tenido". A round is five verbs, twenty blanks. The verbs are the irregular verbs of the
level's band (`VerbDraw.isIrregular`) with at least one irregular key conjugation
(`VerbEssentials.hasIrregularKeyConjugation`), which leaves out only a few defective verbs and
those whose only change is an ending's i lost after ll or ñ (bullir, tañer): 57 at Beginner, 150 at
Elementary, 389 at Intermediate, and 1,613 at Advanced (measured 2026-11-23). They are drawn at
random, with at most one prefixed compound (detener, componer) a round while base verbs remain
(`VerbEssentials.compoundLimit`). The level's tenses do not apply. A key conjugation the engine
does not give (abolir's yo presente) is not asked. Five More Verbs draws verbs the session has not
asked first. `QuizScope.verbEssentials(_:)` also takes a list of verbs, drawn without the compound
limit.

**One blank, one question.** A verb is four ordinary `QuizQuestion`s sharing a `step`, so every
mechanism applies per blank unchanged: a slip or a diagnosed error earns one more attempt at half
points, a wrong answer holds its correction under its row, and each answer records its own
practice item (`PracticeItem.exercised`): tengo, tuve, and tendré their key conjugations, and
tenido, which is regular, the -er participio's pattern. `Quiz.essentialsRows` gives the current
verb's rows: answered (the engine's form, with its red letters, and how it went), current, given,
or pending. `QuizView` draws the rows before the answer field and the rows after it as separate
children around it, so that the field keeps its identity, and the keyboard its focus, as it moves
down a row. Each row is labeled with its tense, and the right-answer check under the field is not
shown, since the rows show it.

**Re-asks** (`Quiz.reaskPlacement(of:in:)`). A missed blank returns after the next verb, as a step
of its own whose other rows are given in grey, so that a re-ask never lands among another verb's
blanks. A second miss in the same verb joins the first's re-ask step. A missed blank of the last
verb returns at the end.

**The rest.** Never ranked; no due items mixed in; not shuffled (`shufflesQuestions`, which would
scatter a verb's blanks); no `ChangeLevelTip` donation. It runs on the tab and starts the Live
Activity. The bar reads Verb Essentials (Lo esencial del verbo) while it runs, the results offer
Five More Verbs (Cinco verbos más), and the last result keeps the kind `verbEssentials` with its
level. `completeQuiz` keeps `questionCount`, since a round's length depends on no answer.
VoiceOver reads the field as "pretérito, yo, blank" (`AnswerFrameView.spokenPrefix`) and each other
row as one element ("presente de indicativo, yo salgo, right"; "participio, not yet asked"). The
DEBUG fixture `CONJUGAR_QUIZ_FIXTURE essentials` stands in for Verb Essentials only: salir, poder,
escribir, detener, and arrepentir.

### Verb Models

**One model, then mixed** (`Models/ModelPractice.swift`). Verb Essentials over one verb model's
verbs alone, then mixed with the models the learner knows, after Pan et al. (2019) on
blocked-then-mixed practice; for verb models as such there is no study. A model
(`ModelPracticeGroup`) is its ten most frequent verbs whose default sense follows it
(`ModelInfo.row(for:)`) and that have an irregular key conjugation. Every model of the Models tab
offers it but the three regular ones and the five whose key conjugations are all regular (bullir,
bruñir, tañer, empeller, abolir): 94 models, 65 practiced alone and 29 single-verb models (ser,
ir, dar, dormir), which have no practice of their own, since one verb is not a pattern, and join
mixes once known. Spelling changes (toqué, cojo), accent shifts (envío), and irregular participles
(escrito) count, since they show in the key conjugations.

**Known** (`isKnown(in:)`), computed from the practice record and never stored: at least half of
the model's items past the first box. A model's items are its verbs' irregular key conjugations,
the ones a Verb Essentials answer records as key conjugations (`PracticeItem.exercised`); a
regular key conjugation (pensé) moves a pattern that no model owns. So pensar's ten verbs have ten
items and tener's thirty, and one perfect round of five makes a model of ten known. A wrong answer
can make it unknown again. Since the ladder moves an item up only when it is due, a verb looked up
today and answered right today stays in the first box.

**The draws** (`ModelPractice.verbs(for:record:…)`). Alone: five of the model's verbs, the
session's unasked ones first, so Another Round asks the rest and a model of two makes a round of
two. Mixed: three of the model's verbs (`mixGroupVerbCount`) and two of the other known models',
taken one model at a time so that a known model of ten does not crowd out one of one; whichever
side is short leaves the rest to the other; shuffled. Mixed opens once another model is known,
whether or not this one is.

**Where it starts.** `ModelPracticeCard` on each model's page below the collection bar, and the
Quiz hub's Verb Models row (Modelos de verbos) in Exercises, which pushes `ModelPracticeListView`:
the 65 models, the most used first (tener, hacer, pagar), each with its exemplar's key
conjugations in red and a seal once known, expanding to the same card. The card hides beneath a
quiz in progress. A session runs in a `QuizSheet` over `QuizScope.modelPractice(_:)`, titled
"Verbs Like pensar" or "Mixed: pensar" (Mezcla: pensar). Never ranked, no due items, no level tip,
no Live Activity; the results offer Another Round (Otra ronda) and no level pill; the last result
keeps the kind `modelAlone` or `modelMixed` with the class number and no level. `startQuiz` sends
`collection` with the model's key, and **a mixed session sends no counts**
(`QuizScope.sendsQuestionCounts`), since which models are known comes from the learner's answers.

### Name the Form

**What it asks** (`Models/Recognition.swift`, `QuizScope.recognition()`). The quiz shows a form,
such as fuera, and the learner types its infinitive and chooses its tense and person, the
direction reading needs. A round is the default quiz's draw (ten cells of the level's tenses and
band, the persons rotated, no due items), each cell's form the prompt as the engine writes it,
irregular letters red, a reflexive-only verb's pronoun included (me arrepiento). A form already
shown in the session is drawn again, so that no prompt repeats while others remain. The verb and
its gloss are not shown.

**Every reading is right** (`RecognitionQuestion.cells`). A question holds every cell of every
verb that writes its prompt, among the cells the learner can choose (the level's tenses, and the
persons a quiz asks there in the learner's tú or vos and region): fuera is ser's and ir's
Imperfecto de Subjuntivo 1 for yo and él, hablamos the presente and the pretérito, hable the
presente de subjuntivo of yo and él and usted's command, sé saber's yo and ser's command, ve ver's
él and ir's and ver's command. No prompt is avoided, since deciding which cells a text can be is
the skill. The conjugation map names the verbs to try, by each word of the prompt (hablado for "ha
hablado", hagas for "no hagas"), and `ConjugationMatch` confirms each cell exactly, since habló
and hablo are different questions. The Quiz tab touches `ConjugationMap.bundled` from a background
task as it appears, since the map takes a moment to load.

**The grade** (`RecognitionQuestion.grade(_:)`). Judged against the typed verb's cells when the
infinitive is right, else against every cell, and a part is called wrong only when changing it can
make the answer right, so a repair line never sends the learner to change what was right: ir ·
Presente (él) for ve is "Check the tense and the person.", since ver's presente does not rescue
ir. The gerundio has no person to judge. The infinitive is graded as the quiz grades an answer:
case and spaces aside, a reflexive-only verb with or without its se, accents counted (reir is not
reír). An answer with any part right gets one more try at half points (`Quiz.processRecognition`,
`firstAttemptRecognition`), its line naming what to check ("Check the tense." / "Revisa el
tiempo.", six lines in all) before "Try once more."; an answer with no part right goes to the
correction at once. **Answers are not recorded in the practice record**, since recognizing a form
is no evidence of producing it.

**The screen** (`Views/RecognitionChoicesView.swift`). The card shows "Name this form" and the
prompt. Above the field, so that they stay in sight above the keyboard, the tense chips sit under
their moods' headings (Indicativo, Subjuntivo, Imperativo, then the gerundio alone), each chip a
short name (presente, imperfecto 1, positivo) that VoiceOver reads whole ("presente de
subjuntivo"); then, once a tense is chosen, its persons ("él, ella, usted", or "usted" in a
command). A person the newly chosen tense lacks is cleared. Then the Infinitive field and a Check
button, enabled once the answer is whole; Return checks too, and with a part missing announces
what to do. A second attempt's line is scrolled into sight. The correction shows the answer with
its wrong parts red and struck through, then every right answer, one line per verb, as search's
rows name cells ("hablar · Presente de Subjuntivo (yo, él) · Imperativo Positivo (usted)"), and
links to each verb's page with its cells marked. The results row shows the prompt, the answer, and
the right ones.

**Scope flags.** Never ranked, no due items, continues (Ten More), starts the Live Activity, and
donates the level tip as a default round does. The last result's kind is `recognition`, with its
level. `startQuiz`, `quitQuiz`, and `completeQuiz` carry `source` `recognition`, with counts. The
DEBUG fixture `CONJUGAR_QUIZ_FIXTURE recognition` stands in for Name the Form only: ten prompts at
Advanced's tenses (fuera, hablamos, hable, habló, fui, sé, ha hecho, no hagas, me arrepiento,
diciendo), each with a wrong answer worth trying in its comment.

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
level's tenses, titled with the collection's name ("-go Verbs", "Verbs Like tener"). Share
sends the title, the count, the six most frequent verbs, the `list` link with `source=sharedLink`,
and the App Store link; on iPad the sheet anchors to the button's own frame
(`ShareSheet.present(…anchorRect:)`), since the button is in the page, not the navigation bar.

**No `quiz/start?list=<key>`:** a shared link opens the collection, where Quiz is one tap.

