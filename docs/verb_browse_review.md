# Review: the Browse and Verb Implementation

**Written:** 2026-11-25, in answer to [`prompts/verb_browse_review.md`](../prompts/verb_browse_review.md).
**Subject:** the code that [`plans/browse_and_verb_implementation.md`](../plans/browse_and_verb_implementation.md)
built for the Verbs and Models tabs: seventeen phases and a closing, commits `f27a7a6` to `421986a`,
about 12,000 added lines in roughly 120 files. **Reviewed at:** `7811ec9`, so the review covers the
code as it stands, including what the pedagogy plan changed in the same files afterward. Nothing
was fixed. This document only reports.

## Verdict

The work is sound. The tree is green (1,344 Swift Testing tests in 85 suites and 11 XCTest tests,
0 SwiftLint violations), the engine stayed `nonisolated` and free of app types, the plan's "How it
differed" notes are honest about what was and was not tried, and no finding is a crash. One
finding can lose data, and only after a decode failure that nothing is known to cause
([C12](#c12)).

Six things deserve attention before the 2027 release, in this order:

1. **Reverse lookup names commands that do not exist** ([C1](#c1)). Searching "hablase" labels it
   "Imperativo Positivo (vos)" beside its real subjunctive reading, and adds a second line,
   "háblase: Imperativo Positivo (tú)". Every -ar verb's -se subjunctive does this, and so does
   every vosotros command with *os* ("levantaos").
2. **A quiz correction's model link can say which verb the learner missed** ([P1](#p1)). The staged
   privacy text says the `collection` parameter is "never a verb". For 29 models it is.
3. **The widget's My Verbs rotation repeats one verb** ([C3](#c3)), the opposite of what the
   rotation was built for.
4. **A search that arrives before the conjugation index is built blocks the main thread**
   ([F1](#f1)). Building the index took 4.6 seconds in a Debug build in the simulator on this Mac,
   not the "about a second" the code comment gives.
5. **Two tips have guards that do not guard** ([C2](#c2), [C7](#c7)). The red-letter tip's
   condition is true for all 4,811 verbs, and the scroll tip shows on the roughly 72% of verb pages
   that have nothing below the conjugations.
6. **Tidying My Verbs erases collection progress** ([C9](#c9)), and Clear does it without asking.

The rest is duplication (the answer to the prompt's question about `VerbBrowseView` and
`ModelBrowseView` is in [Duplication](#duplication)), stale prose, tests that prove less than they
claim, and one view that has grown too large.

## Method

Five Opus subagents each reviewed one area independently, with no view of one another's
conclusions or of Konjugieren's review: search and reverse lookup; the list screens; the verb page
and the models behind it; the ways into a verb from outside a screen, with the signals; and the
learner's record, the verb of the day, and collections. I read `VerbBrowseView`, `ModelBrowseView`,
`ModelView`, `VerbCollectionView`, `VerbEntryList`, `AppRouter`, and `MainTabView` myself, and
re-read the code behind every finding I ranked above "small". Each finding carries one of these
labels, the same four Konjugieren's review uses:

| Label | Meaning |
|---|---|
| **Run** | Confirmed by running code: the simulator, or a temporary probe test (since deleted). |
| **Read** | I traced it in the code myself. |
| **Reviewer** | A subagent reported it with file and line; I did not re-trace it. |
| **Suspected** | Plausible from the code, with the unchecked step named. |

What ran: the full suite and SwiftLint as a baseline; the app on "Conjugar iPhone 17" for seven
search links, four verb pages, and a cold launch with a stashed control link; and a probe test
that timed fifteen queries and the index's first load, conjugated every cell of the 3,180 regular
verbs, looked for conjugations that fold to an infinitive, ran four lookups, and listed the bases
of the 300 most frequent verbs.

Only after that did I read Konjugieren's review. [Konjugieren's Findings, Checked
Here](#konjugierens-findings-checked-here) says which of its findings carried over in the port.

**Not covered:** VoiceOver, a real device, the iPad simulator, a Spanish-language device, the tutor
(the simulator cannot run it), and the quiz beyond `QuizScope`, `QuizSheet`, and the correction's
links. The string catalogs were checked mechanically for the intents' keys only.

Line numbers are those of `7811ec9`.

## Correctness

<a id="c1"></a>
### C1. Reverse lookup accepts any clitic on any command (Run)

`FormLookup`'s enclitic branch (`FormLookup.swift:183-197`) strips clitics from a word, finds
commands, gerunds, and infinitives that the remainder could be, joins the clitics back with
`ReflexivePronoun.enclitic`, and keeps the result if it folds to the word typed. It never asks
whether the clitic agrees with the command's person.

Under the accent rules, the vos command plus *se* or *os* needs no written accent, so the rebuilt
word equals a real form exactly and is recorded as a literal match:

| Typed | What the row says |
|---|---|
| hablase | hablase: Imperfecto de Subjuntivo 2 (yo, él) · Imperativo Positivo (vos) |
| | háblase: Imperativo Positivo (tú) |
| pasase | the same two lines, for pasar |
| levantaos | levantaos: Imperativo Positivo (vos, vosotros) |
| | levántaos: Imperativo Positivo (tú) |

*Hablá* + *se* and *habla* + *se* are not Spanish: a tú or vos command takes *te*. The bogus vos
cell is also marked when the row is opened, and a marked vos cell makes the page show its vos rows
to a learner who hid them. Look Up a Verb reads the same findings aloud. "levantaos" is one of
`ReverseLookupTests`' own queries; the test checks only that the verb is levantar.

**Fix.** In the enclitic branch, require agreement for the first clitic: *se* alone only on the
usted and ustedes commands, the gerund, and the infinitive; *os* only on the vosotros command, the
gerund, and the infinitive; *te* only on tú and vos; *nos* on nosotros. A clitic followed by
lo/la/los/las is an indirect object and stays free. Add tests on the lines, not only the verb.

**Fixed on `master`, 2026-11-25, in Phase 1 of `plans/verb_browse_fixes.md`.** One exception to
the fix as written, by Josh's decision that day: *nos* stays free on every command, because it is
also a common object (dinos, ayúdanos, díganos).

<a id="c2"></a>
### C2. The red-letter tip's guard is true for every verb (Run)

`hasRedLetters` (`VerbView.swift:85-88`) asks whether any form on the page contains an uppercase
letter. The probe found one on the page of every one of the 3,180 regular verbs, because every
compound tense shows a marked auxiliary: hE laxado, haS laxado, hA laxado, hEmos laxado. So the
guard never hides `RedLettersTip`, its doc comment ("has nothing to point at on a regular verb's
page") is untrue, and each body evaluation scans about 120 forms to learn nothing.

**Fix.** Decide which is wanted ([Q3](#open-questions)). If the tip may point at a red auxiliary,
delete the guard. If it should appear only where the verb itself is irregular, test the simple
tenses and the three header forms only, or ask `Conjugator.verbType`.

**Fixed on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`.** `VerbPageForms.hasRedLetters` reads the simple tenses and the header forms only.
A spelling-change verb such as buscar counts, because the engine marks busQUé.

<a id="c3"></a>
### C3. The widget's My Verbs rotation repeats a verb as the list changes (Read)

`VerbDraw.verbOfTheDay` returns `myVerbs[turn % myVerbs.count]` (`VerbDraw.swift:38-46`), and
`myVerbs` is the starred verbs and then the recent ones, newest first
(`Shared/LearnerVerbs.swift:66-80`). Each My Verbs day advances `turn` by one. Each verb opened in
between is prepended, which moves every other verb down by one. The two cancel, and the same verb
comes back. The widget's own tap opens its verb, which reorders the list too.

The reviewer simulated it: with twenty recents and one new verb opened between My Verbs days, the
same verb showed on 56 of 60 consecutive My Verbs days. Phase 14 chose rotation over chance so
that no verb would repeat "while another waits". `myVerbsGetEveryThirdDayInTurn` passes because
its list never changes between days.

**Fix.** Rotate over an order that recency does not change, such as the infinitives sorted, and
test with a list that changes between turns.

**Fixed on `master`, 2026-11-25, in Phase 4 of `plans/verb_browse_fixes.md`.** A My Verbs day goes
to the verb whose last turn is oldest, one that never had a turn first, and among equals the first
by infinitive (`VerbDraw.myVerbsTurn(in:lastShown:)`). The record of turns is kept in the widgets'
file. In the reviewer's scenario no verb now comes back within twenty My Verbs days, and none
while another of the list has waited longer.


<a id="c4"></a>
### C4. Look Up a Verb cannot open the page of a verb with an ñ twin (Run)

`literalAnswerKinds` includes `.exactFoldedInfinitive` (`VerbLookup.swift:39`), although the
comment at line 61 says "A folded form answers only when nothing literal does". Five pairs of
infinitives collide after folding: acunar and acuñar, empanar and empañar, ordenar and ordeñar,
rebanar and rebañar, sonar and soñar. The probe looked up "ordenar", "sonar", and "soñar": each
returned two findings and the search link, not the verb's page. A learner who types soñar with its
ñ has left nothing to guess.

**Fix.** Make the literal tier `[.exactInfinitive, .exactGlossSense, .conjugation]` and let
`.exactFoldedInfinitive` answer with `.foldedConjugation`, when nothing literal does. If naming
both twins for an unaccented "sonar" is wanted, keep that case and fix only the accented one
([Q4](#open-questions)).

**Fixed on `master`, 2026-11-25, in Phase 1 of `plans/verb_browse_fixes.md`.**

<a id="c5"></a>
### C5. A several-word lookup does not forgive a missing ñ, though a one-word lookup does (Run)

`FormLookup.confirmed` tries `.exact` and then `.folded` (`FormLookup.swift:273-276`), and
`.folded` keeps ñ. The one-word path uses `VerbSearch.fold`, which drops it. In the simulator, "he
ensenado" found enseñar but named only "enseñado: Participio"; the perfecto was never named.
`ConjugationMatch` gained a `.bare` mode in pedagogy Phase 3, which `confirmed` never adopted.

**Fix.** A third pass with `.bare`, passed through to `spelling`.

**Fixed on `master`, 2026-11-25, in Phase 1 of `plans/verb_browse_fixes.md`.**

<a id="c6"></a>
### C6. A lookup's link can mark two rows and land on the wrong one (Run)

`VerbLookup.markableText` sends the bare form of the matched cell when the typed text has pronouns
joined (`VerbLookup.swift:107-118`), and `AppRouter.marks` turns that text back into every cell
with the spelling (`AppRouter.swift:197-206`). The probe: "levántate" produces
`verb/levantar?match=levanta`, which marks the presente's él as well as the imperativo's tú, and
the page scrolls to the first marked card, the Presente. "dámelo" and "cómelo" do the same.
`strippedPronounsAndEndingsStillOpenOnePage` checks the URL, not the marks.

**Fix.** Let the link name the cell (`ConjugationCell.code` exists) when the text alone is
ambiguous.

**Fixed on `master`, 2026-11-25, in Phase 1 of `plans/verb_browse_fixes.md`**, with a `cells`
query item.

<a id="c7"></a>
### C7. The scroll tip shows on pages with nothing below the conjugations (Read; counts by a reviewer)

`TipView(scrollToBottomTip)` is drawn on every page (`VerbView.swift:98`). Its message promises
that "below the conjugations, the page tells where the verb comes from and shows it in example
sentences", and only the etymology or example card can retire it. The reviewer counted the bundled
data: about 3,470 verbs have no etymology and no example of either kind. On abaratar the tip
points at nothing, and scrolling to the bottom does not dismiss it. I could not see it on screen,
because the simulator's tip state had already retired it.

**Fix.** Draw the tip only when the page has an etymology or an example.

**Fixed on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`.** The page asks `ScrollToBottomTip.hasTarget(onPageOf:)` before drawing the tip and
before unlocking it.

<a id="c8"></a>
### C8. "Built on" names bases that are not bases (Run)

`VerbRelations.falseCompounds` is documented as covering "every verb resting on a base that no
real compound uses (piar, pirar, timar)" (`RelatedVerbs.swift:66-79`). It lists espirar, expirar,
and suspirar, and not transpirar, whose page says "Built on pirarse". Among the 300 most frequent
verbs the probe found two more pairs that are false by etymology: contemplar on templar
(*contemplari*, from *templum*, against *temperare*) and impedir on pedir (*impedire*, from *pes*,
against *petere*). Others are true by etymology and opaque to a learner: acercar on cercar,
contestar on testar, preparar on parar, revelar on velar.

**Fix.** Add transpirar, contemplar, and impedir. The opaque pairs need a ruling
([Q5](#open-questions)).

**Fixed on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`.** The three are in `falseCompounds`, and the comment says that pirar is no base. The
opaque pairs stay, by Josh's ruling. 973 verbs now have a base, against 976.

<a id="c9"></a>
### C9. Tidying My Verbs erases collection progress (Read)

A collection's "looked up" is `lastOpened != nil` (`Shared/LearnerVerbs.swift:60-62`). A swipe on
a My Verbs row calls `remove`, which deletes the whole entry, so the verb loses its check in every
collection. Phase 16's note records this for Clear and not for the swipe. Clear has no
confirmation (`VerbBrowseView.swift:512-516`), so one tap takes a collection from "37 of 100
looked up" to 0. The starred row's swipe is labeled "Delete", its alert asks about removing the
star, and its action forgets the opens too. `firstOpened` and `openCount` are written on every
open and read nowhere in the app.

**Fix.** Count progress on `firstOpened`, and have Clear and the swipe forget only `lastOpened`.
Or keep the coupling, confirm before Clear, and say so in the docs ([Q6](#open-questions)).

*Fixed on `master`, 2026-11-25, in Phase 3 of `plans/verb_browse_fixes.md`: progress reads
`firstOpened`, Clear asks first, the swipes say Remove, and Settings' Reset Practice is now the
one thing that forgets which verbs were opened.*

<a id="c10"></a>
### C10. The keyboard selection is an index that outlives its rows (Read)

`keyboardSelection` is an index, cleared only when the text changes
(`VerbBrowseView.swift:715`). Three consequences, all on a hardware keyboard:

- **The highlight jumps lists.** Focus the empty field so the recents show, press ↓ twice, and
  press Esc. 700 ms later the list is every verb again, and the highlight sits on the second verb
  of that list. A sort change does the same.
- **Return can open a verb that is not on screen.** While My Verbs shows with no recents,
  `keyboardTargetCount` and `openKeyboardSelection` still count the full list
  (`VerbBrowseView.swift:321-326`, `:347-359`). Command-F, ↓, Return pushes the first verb of the full list
  with nothing highlighted.
- **Arrows and Return disagree on an iPhone.** The arrow commands install on every idiom, and
  Return acts only on the iPad idiom (`:726-741`), so ↓ highlights a row that Return ignores.

**Fix.** Store the selected infinitive, clear it when the shown list changes, count no targets
while My Verbs shows, and let Return act whenever a row is highlighted.

*Fixed on `master`, 2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`: `VerbBrowseSearch.selection` is an
infinitive, cleared whenever what the list shows changes; My Verbs has no keyboard targets; Return
opens a highlighted row on any idiom, and only the iPad idiom opens the first result unasked.*

<a id="c11"></a>
### C11. Three pushes skip the wait that the list's rows take (Read; the drop itself is Suspected)

`push(_:)` waits for UIKit's transition when an empty search has just lost focus, because Phase 2
found that the iPad drops a push made then. My Verbs' rows (`VerbBrowseView.swift:554`), the
review card (`:434`), and a link's `pendingVerb` (`:752-756`) append to the path directly. My
Verbs and the card can both sit under an empty, focused field when there are no recents. Nobody
has tried the tap on an iPad.

**Fix.** Send all three through `push(_:)`.

*Fixed on `master`, 2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`: every push from the tab goes through
`push(_:)`. The drop itself stays untried on these three paths.*

<a id="c12"></a>
### C12. One failed decode silently replaces a record (Reviewer)

If the stored `learnerVerbs` JSON fails to decode, `LearnerVerbStore` starts empty
(`LearnerVerbStore.swift:21`), and the next open overwrites the stored string, so every star and
open is gone with no trace. `PracticeStore` reacts to the same failure by running its migration
again (`PracticeStore.swift:52-57`). Nothing is known to corrupt the string. The likely cause is a
later non-optional field, which the "added fields must be optional" rule already guards against.

**Fix.** On a failed decode, keep the raw string under a backup key before writing anything.

*Fixed on `master`, 2026-11-25, in Phase 3 of `plans/verb_browse_fixes.md`. The account of
`PracticeStore` was right, and it was worse than described: the store saves the migrated record at
once, at launch. Both stores now copy an unreadable string to a backup key, and the practice
store no longer migrates over one.*

### C13. Smaller correctness findings

- **A stashed link waits when the app is already in front (Read).** The four `Shared/` intents
  write a link to the App Group's defaults, and `MainTabView` drains it only when the scene
  becomes active (`MainTabView.swift:85-93`). A shortcut run while Conjugar is frontmost leaves
  the link there, and the next return to the app, whenever it comes, opens a random verb or starts
  a quiz nobody asked for. Phase 11 notes the wait as untried, not the late surprise. I confirmed
  that a cold launch does drain a stashed link. *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`: the stash carries
  the time it was written and is announced by a Darwin notification, which an app in front drains
  at once; one more than a minute old is removed unopened.*
- **An ignored link still dismisses an open practice set (Read).** `handle(url:)` clears
  `pendingPracticeSet` before it knows that the route resolves (`AppRouter.swift:118`), so
  `conjugar://verb/xyzzyq` closes the sheet and opens nothing. *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`: only a
  link that resolves clears it.*
- **A link opens its page beneath the game (Read).** `handle(url:)` never clears `showGame`, so a
  widget tap during the game pushes the verb out of sight and sends `viewVerbView`. See
  [Q7](#open-questions). Settings' Play button and its tour reshow present from local state
  (`SettingsView.swift:21-22`, `:52-53`), which the router cannot see at all, so
  `presentablePracticeSet`'s guard does not cover the game that Settings opens (Reviewer; the
  local state is Read). *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`: a link that resolves, other than `game`, closes
  the game, and Settings' Play and Show Onboarding present through the router's covers.*
- **The linger's task is never cancelled (Read).** Lose focus, regain it, and lose it again within
  700 ms, and the first task ends the linger early (`VerbBrowseView.swift:128-144`). The iPad's
  letter-key path makes exactly that sequence. *Fixed on `master`, 2026-11-26, in Phase 9 of
  `plans/verb_browse_fixes.md`: each change of focus cancels the last linger.*
- **A whitespace-only query hides things and filters nothing (Read).** The tip, the review card,
  and the Models tab's collections test `searchText.isEmpty`; the lists test the trimmed text.
  Type a space and they vanish above a full list. *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md` for the Models tab: `ModelSearch.isSearching` reads the trimmed text. The Verbs tab's tip and card are Phase 9's.* *Fixed on `master` for the Verbs tab, 2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`: the tip, the card, the list, and the picker all read `VerbBrowseSearch.isSearching`, the trimmed test.*
- **The sad trombone replays on a sort change (Read).** `recomputeFilteredVerbs` and
  `recomputeFilteredModels` run on a sort change and play it again for the same failed query. In
  the Models tab the picker is always there. *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md` for the Models tab: `ModelSearch.update` plays it only when the text changes. The Verbs tab's is Phase 9's.* *Fixed on `master` for the Verbs tab, 2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`: the trombone plays when the text changes to a failed query, or when the index arrives and a failure made without it stays one.*
- **Recent can show fewer than twenty (Read).** `recent()` takes twenty before the starred verbs
  are filtered out (`Shared/LearnerVerbs.swift:71-79`). With fifteen of the last twenty opens
  starred, Recent lists five while older unstarred opens exist. *Fixed on `master`, 2026-11-25, in
  Phase 3 of `plans/verb_browse_fixes.md`.*
- **A homonym found by its second sense is answered with its first (Reviewer).** Look Up a Verb
  for "station" answers apostar, "bet", with the stem-changing sense's key conjugations
  (`VerbLookup.swift:125-126`). *Fixed in part on `master`, 2026-11-25, in Phase 1 of
  `plans/verb_browse_fixes.md`: the answer names the sense that matched ("apostar, “station”").
  The key conjugations stay the first sense's, which is also what the page shows; see that phase's
  notes for what the rest would take.*
- **The guess's form names its cells out of page order (Reviewer).** `VerbSearch.guess` builds its
  `MatchedForm` from the map's order, not the page's (`VerbSearch.swift:141-142`). *Fixed on
  `master`, 2026-11-25, in Phase 1 of `plans/verb_browse_fixes.md`.*
- **Links are case-sensitive (Reviewer, who ran Foundation).** iOS matches a scheme without
  regard to case, so `CONJUGAR://VERB/hablar` opens the app, which then ignores it. Every builder
  writes lowercase, so this matters only for a link written by hand. *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`: the
  scheme and the route ignore case; a target does not.*
- **The "All N" chip counts roots, not verbs (Reviewer).** `RelatedVerbsView.swift:99` tests the
  number of chips against 6, so a model of twelve verbs over four roots shows no "All 12".
  *Fixed on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`: `RelatedVerbs.modelHasMore` compares the model's other verbs with the chips
  shown, so mover's page (five chips, twelve verbs) shows "All 12".*
- **The grid's selection outline has the wrong corners (Read).** It strokes a radius of 8
  (`VerbBrowseView.swift:634`) around a card whose radius is 12. *Fixed on `master`, 2026-11-27,
  in Phase 11 of `plans/verb_browse_fixes.md`: `AdaptiveRows` strokes `Layout.cornerRadius`, the
  card's own.*
- **A second tap on the mail link hides its note early (Read).** The first tap's four-second task
  is not cancelled (`VerbBrowseView.swift:295-308`). *Fixed on `master`, 2026-11-26, in Phase 9
  of `plans/verb_browse_fixes.md`: a second tap cancels the first's task.*
- **Two quick letter taps may arrive reversed on iPad (Suspected).** Each tap starts its own
  polling task (`VerbBrowseView.swift:216-226`). The order in which they wake was not tried.
  *Real, and fixed on `master`, 2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`. With AXe on the iPad
  simulator, á then é tapped 50 to 300 ms apart into the focused empty field gave "éá" three
  times in five and lost the á once. Letters that must wait now queue in the model and arrive
  together, in order: "áé" in every trial from 80 to 300 ms. At 50 ms the á is still lost when
  the field is empty, before the fix and after it, though 50 ms taps into a field holding text
  arrive whole. Making the first letter wait whenever the field was empty did not help, so the
  first tap's action seems never to run; that is the touch, not the order, and it was left.*
- **The arrow keys may stay installed over a pushed page (Suspected).** If Return pushes a page
  and the field keeps focus, the priority ↑ and ↓ commands would swallow the page's own arrow
  scrolling. One AXe check would settle it. *Checked on `master`, 2026-11-26, in Phase 9 of
  `plans/verb_browse_fixes.md`, and nothing is lost: ↓ did not scroll tener's page after ⌘F, "tener", Return, but it
  did not scroll the page opened by a link with no search focused either, so there is no arrow
  scrolling to swallow. The commands are now installed only while the list is on screen anyway.*

## Performance

<a id="f1"></a>
### F1. A search that beats the index blocks the main thread (Run for the time, Read for the path)

`ConjugationIndex.bundled` is built lazily, and the Verbs tab warms it in a detached task
(`VerbBrowseView.swift:790-794`) whose comment says the load "takes about a second". The probe
measured its first touch at **4.6 seconds**, in a Debug build in the simulator on this Intel Mac. A
Release build on a phone will be several times faster, and nobody has measured one.

Any search that runs before the warm-up finishes waits for it on the main thread:
`openRequestedSearch` sets the text, `recomputeFilteredVerbs` calls `VerbSearch.matches`, and
`FormLookup` touches the index. That is a cold `conjugar://search?q=…` link, and a learner who
types within the first seconds. Phase 10's own note, about typing lost after a cold quick action,
looks like the same wait.

Once the index exists, search is cheap: 18 to 64 ms per query in the same Debug build, and a
failed search's guess adds 22 to 88 ms. Konjugieren's main-thread stall on a failed search did not
carry over, because `editDistance(_:_:limit:)` stops early here.

**Fix.** Until the index is ready, search infinitives and glosses only and run the search again
when the warm-up completes. Or move matching off the main actor and publish the results.

*Fixed on `master`, 2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`, the first way. A Debug build in the
simulator measured the index's first touch at 6.0 to 6.2 seconds. From a cold `search?q=fue`, the
results showed at 8.0 to 8.7 seconds before the fix, the main thread blocked for 5.4 to 6.0 of
them. After it, the first results (repostar, by its gloss "refuel") showed at about 3.1 seconds,
and ser and ir at 7.0 to 7.9 seconds, with the warm-up begun at launch.*

### F2. Smaller performance findings

- **`VerbView.init` and `ModelView.init` do the page's work (Suspected).** `VerbView.init`
  conjugates about 120 cells and derives the related verbs; `ModelView.init` sorts the model's
  verbs twice (2,968 for cantar) and conjugates 44 cells (`ModelView.swift:84-96`). A
  `navigationDestination` closure can run again whenever the stack's host re-renders, and
  `VerbBrowseView` reads the learner's record, which every page open changes. `@State` survives,
  so the result is correct. Whether the init really reruns was not checked; a print in `init`
  would say. *Checked on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`, and not
  real: with a print in both inits, each push ran its init once, and starring the page, opening it
  from the search field's recents or from My Verbs, and returning from a pushed page ran neither
  again. Left as it is; Phase 8 lightens `ModelView` anyway.*
- **Spotlight is re-indexed at every launch (Read).** A recorded choice, but
  `Task { await VerbSpotlight.indexVerbs() }` (`MainTabView.swift:70`) inherits the launch task's
  priority, so about two seconds of building entries competes with launch. Nothing removes the
  entry of a verb that leaves the map. A version stamp would skip the work on most launches.
  *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`: background priority, a stamp of the version, build, and verb count that
  skips a launch of the same build, and removal by identifier of the verbs the map lost.*
- **Work repeated per render or per call (Reviewer, except where noted).**
  - `LearnerVerbStore.recentVerbs` sorts the record on every access, and the Verbs tab's body
    reads it about eight times. *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: the store derives its four lists once per change.*
  - `signalEndedSearch` runs the whole search again for a query whose matches the view still
    holds (Read; `VerbBrowseView.swift:207`). *Fixed on `master`, 2026-11-26, in Phase 9 of
    `plans/verb_browse_fixes.md`: the report reads the model's results.*
  - `VerbCollection.verbs` for a model filters and sorts all 4,811 entries on each access.
    *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: it reads the model's row.*
  - `VerbMap.entries(in:)` sorts the whole map on every call, and six other files sort every
    entry by rank themselves. Ranks are dense, so one cached list would serve them all, and a band
    would be a prefix of it. *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: `VerbMap.entriesByFrequency`.*
  - `ModelBrowseView.swift:45` folds the query once per model. *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`.*
- **The first visit to the Models tab derives the collections on the main actor (Suspected).**
  `VerbCollection.featuredVerbs` runs about 4,000 conjugations. Not timed.
- **The map's and the index's memory is unmeasured (Suspected).** About 254,000 small arrays, kept
  by the app and by each intent that loads them.

## Privacy

<a id="p1"></a>
### P1. A correction's model link says which model, and for 29 models which verb, was missed (Read)

A held correction appears only after a wrong answer. Its model link pushes
`ModelView(model:source: .quizCorrection)` (`QuizView.swift:77-79`), and `ModelView` then sends
`viewCollection` with `collection: model-<class>` and `source: quizCorrection`
(`VerbCollection+Text.swift:100-105`). Together the two parameters name the model of the verb the
learner just got wrong. The probe counted 29 models with one verb, among them ser, ir, estar,
haber, poder, querer, decir, saber, ver, and dar, so for those the key is the verb.

Each half is fine alone. This plan's Phase 16 added the key, and the pedagogy plan added the
source. The staged policy describes `collection` as "which list: one of five fixed lists, or one
of the 102 models, never a verb" (`docs/privacy_policy_pending.md:308-309`).

**Fix.** For `quizCorrection`, send `viewCollection` without `collection`, or amend the staged
line, which is Josh's call ([Q1](#open-questions)).

*Fixed on `master`, 2026-11-25, in Phase 2 of `plans/verb_browse_fixes.md`: a `viewCollection` whose source is `quizCorrection` carries `source` alone, pinned by
`VerbCollectionTests.aViewNamesItsCollectionExceptFromACorrection`. The staged wording stays, by
Josh's decision.*

## Gaps Between the Docs and the Code

- **G1. The widget does not read the learner's record (Read).** `Shared/LearnerVerbs.swift:12-15`,
  `World.swift:27`, `GetterSetterReal.swift:14-15`, and `docs/feature_architecture.md:592` say it
  does. Nothing under `ConjugarWidget/` names `LearnerVerbs`, `PracticeRecord`, or
  `ReviewSchedule`; the app hands My Verbs to the snapshot writer. Correcting the prose is cheaper
  than moving the types. *Fixed on `master`, 2026-11-25, in Phase 3 of
  `plans/verb_browse_fixes.md`; `PracticeRecord`'s two comments made the same claim and were
  corrected too.*
- **G2. `KeyConjugation`'s rationale is wrong for the verbs it matters most for (Reviewer; the
  grammar is right).** `KeyConjugation.swift:20-21` and `docs/feature_architecture.md:357` say the
  imperfect and future subjunctives follow the yo pretérito. They follow the third-person plural:
  dormí but durmiera, pedí but pidiera, leí but leyera. The four forms are Josh's decision and
  stay; only the sentence is wrong. *Fixed on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`: `KeyConjugation`, `PracticeItem.Key.init(tense:)`,
  and the doc now say so.*
- **G3. A visit's dwell includes time under a sheet (Reviewer).** A sheet does not make its
  presenter disappear, so a three-minute Test Me reports `dwell` as `60s+` for the page. The
  landing scroll to a marked form also counts as the learner reaching `compound`, and can retire
  the scroll tip unprompted. The begin-and-end logic lives in `VerbView`'s body
  (`VerbView.swift:189-233`), where no test reaches it. *Fixed on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`: `VerbVisitTracker` decides,
  and its tests drive it. By Josh's decision that day, a sheet ends the visit and its closing
  begins a `resume` one. What the landing scroll shows is not reached until the learner scrolls.*
- **G4. The Related Verbs card has no `VerbPageSection` (Read)**, so `deepestSection` cannot say
  that a learner reached the last thing on the page. *Fixed on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`: `related`.*
- **G5. A migration for data no shipped build wrote (Read).** `PracticeStore.migrated` and
  `LegacyLearnerVerbs` (`PracticeStore.swift:243-262`) carry Phase 15's per-verb schedules into
  the practice record. Both formats exist only on `master`; version 3.1 has neither. Delete before
  the release unless Josh wants his own simulators' history kept.
- **G6. The Models tab's search field was left as it was (Read).** Phase 0 said to change nothing
  else there. So autocapitalization and autocorrection are still on, and on iPad the field keeps the
  default placement, which Phase 0 found shrinks to a toolbar button and which the Verbs tab
  left for a drawer. I did not look at it on the iPad. See [Q8](#open-questions). *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`: autocorrection and autocapitalization are off, and on iPad, by Josh's choice that day after seeing both, the field is the Verbs tab's drawer (`BrowseLayout.searchPlacement`, which both tabs now read).*
- **G7. Stale prose (Reviewer unless noted).**
  - `docs/feature_architecture.md:1800`: a collection's quiz is "thirty unranked questions". It
    is ten, with Ten More. *Fixed on `master`, 2026-11-26, in Phase 6 of
    `plans/verb_browse_fixes.md`.*
  - `docs/feature_architecture.md:432`: the `quiz` route's query items are "None"; the router
    reads `source`. Line 458 omits three of the router's pending values, and line 614 says the
    push waits "when the search is ending" ([S2](#smells) says when it really waits). *The
    first two fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`; the
    third is S2's, in Phase 9.* *The third fixed on `master`, 2026-11-26, in Phase 9 of
    `plans/verb_browse_fixes.md`.*
  - `VerbBrowseView.swift:788`: "about a second" (Run; see [F1](#f1)). *Fixed on `master`,
    2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`, here, in `ConjugationIndex`, and in
    `docs/feature_architecture.md`.*
  - `AppRouter.swift:5-8`: the header names four ways in and omits Spotlight, Look Up a Verb,
    reminders, and shared links (Read). *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`.*
  - `MainTabView.swift:117`: the doc comment about the onboarding cover sits on
    `widgetChallengeContext` (Read). Line 141 says only controls stash a link; two shortcuts do
    too. *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`.*
  - `Analytics.swift:141`: `control` is documented as the Random Verb control only. *Fixed on `master`, 2026-11-25, in Phase 2 of `plans/verb_browse_fixes.md`:
    it names both controls that send it, and says the Quick Quiz control sends `deeplink`.*
  - `ViewControllerTransitions.swift:10-13` and `docs/project_structure.md:259` describe only the
    letter key's use; `push(_:)` uses it too.
  - The Info article "Purpose/Use" still says a quiz is thirty verbs at Easy, Moderate, or
    Difficult. That is the pedagogy plan's to fix and is listed here so that it is not lost.
- **G8. Comments that narrate history (Read).** Commit `860795f` swept these out and missed
  `ModelBrowseView.swift:5-8` ("replacing the UIKit BrowseModelsVC…"), `ModelView.swift:5-9`, and
  the bug story on `ModelRowLabel` (`ModelBrowseView.swift:245-251`). *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`: each describes the code, and `VerbRowLabel`'s matching story went too.*
- **G9. VoiceOver (Reviewer; nothing was listened to).**
  - The list's rows do not tag the infinitive as Spanish, so an English voice reads "tener".
    Everything this plan added does tag its Spanish, which makes the rows the odd ones out.
  - The pill became a button in Phase 8, and its label is the raw "Irreg. ☛ tener", glyph
    included.
  - The review card is three elements that all perform the same tap, and the card is an
    `onTapGesture`, which Full Keyboard Access cannot reach.
  - The letter keys are 40 points square.

  *Fixed on `master`, 2026-11-26, in Phase 10 of `plans/verb_browse_fixes.md`, but for the rows'
  Spanish, which is Phase 11's: the review card is one `Button` read as one element, the ✕ a second;
  the pill reads "Irregular, like tener" with tener tagged Spanish; and the letter keys are 44
  points square, five apart, 338 points in all. Still nothing was listened to.* *The rows' Spanish
  was fixed on `master`, 2026-11-27, in Phase 11: `RowLabel` tags a verb's infinitive and a model's
  exemplar Spanish, in every list and grid.*

<a id="duplication"></a>
## Duplication

The prompt withdrew the earlier allowance for `VerbBrowseView` and `ModelBrowseView`. The two
screens should stay two screens. The Verbs tab's tracker, recents, keyboard selection, letter row,
guess, and review card have no counterpart in the Models tab, and one generic browse screen would
be mostly switches. What should go is the dozen blocks they copy from each other, and from the
model's and the collection's pages.

### D1. The two browse screens (Read)

| Block | `VerbBrowseView` | `ModelBrowseView` | What would remove it |
|---|---|---|---|
| Every sort order computed once | 46-52, 58 | 25-30, 35 | `Sort.sortedLists(of:)`, also used by `ModelView:85` and `VerbCollectionView:25` |
| Regular-width grid or compact zebra list | 620-667 | 83-120, and 181-204 for collections | A generic `AdaptiveRows` that owns the columns, `.card()`, dividers, and zebra stripe. `VerbEntryList` is this for verbs already, and `VerbBrowseView` does not use it |
| Count heading in small caps | 451-459, 545-550 | 66-72, 174-179 | One `ListHeading` view; `ModelView:115` and `VerbCollectionView:55` have the fifth and sixth copies |
| Segmented sort picker under a divider | 692-700 | 134-141 | `SortPicker(selection:)`; `ModelView:107` and `VerbCollectionView:47` repeat it |
| No-results view and trombone | 72-74, 614-616 | 49-51, 80-82 | A small helper; not worth more |
| `VerbDestination` destination, `verbPageDestinations()`, the `verbPagePush` environment | 746-751, 796 | 147-153, 166 | Register `VerbDestination` inside `verbPageDestinations()`; `QuizView:74` is the third copy |
| A router request consumed once | 752-756 | 155-159 | A helper, or leave |
| Row label and its card twin | `VerbRowLabel`, `VerbGridCell` (810-894) | `ModelRowLabel`, `ModelGridCell` (223-284) | One label with a style, and one modifier for the serif gold title, which `VerbCollectionRow`, `VerbCollectionCard`, and `ReviewCardView` also spell out |

**One of these copies is already a latent bug.** `ModelBrowseView`'s `VerbDestination` destination
builds `VerbView(verb:source:)` without `destination.marks` (`ModelBrowseView.swift:147-149`). The
Verbs and Quiz tabs pass them. Nothing in the Models stack pushes a marked destination today; the
first thing that does will lose its mark and its landing scroll there, silently.

*Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`, the cheap pieces: `ListHeading`, `SortPicker` (over `PickerOption`), `ListSort.sortedLists(of:)`, `zebraStriped(_:)`, `serifTitle()`, and `VerbDestination` registered once, with its marks, inside `verbPageDestinations()`. `AdaptiveRows` and one row label are Phase 11's.* *The rest was fixed on `master`, 2026-11-27, in Phase 11: `AdaptiveRows` draws all four grid-or-list blocks, and `RowLabel` is the one label, as a row or a card, under `VerbRowLabel`, `ModelRowLabel`, and `VerbCollectionRowLabel`; `VerbGridCell`, `ModelGridCell`, `VerbCollectionRow`, `VerbCollectionCard`, and `zebraStriped(_:)` are gone.*

Cheap and safe: the heading, the picker, the sorted lists, the zebra stripe, and the single
`VerbDestination` registration. Medium: `AdaptiveRows`, because the Verbs tab's rows need an
index, match lines, a highlight, and the identifiers that the screenshot driver and the launch
anchor depend on (`verb_row_<infinitive>`, `browse_verb_count`).

### D2. The model's page and the collection's page (Read)

`ModelView:104-122` and `VerbCollectionView:45-62` are the same run: the collection bar, a sort
picker, a count heading, and a `VerbEntryList`. They differ in the default sort, the heading's
string, the push's `source`, and the practice card that the model's page puts between. Both also
keep a `hasSignaledView` flag to send `viewCollection` once. `RelatedVerbListView` has the picker
and the list again. One `SortableVerbList` that owns its sort state would serve all three.
*Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`: `SortableVerbList` serves all three, and `signalsCollectionView(_:source:)` replaces both flags.*

### D3. Smaller duplication (Reviewer unless noted)

- **Edit distance is written three times**: `VerbSearch.swift:194-216`, `:221-249` (the same
  algorithm with a limit), and `AnswerDifference`'s with a backtrace. The first two could be one
  generic function. Edit distance and `fold` now serve the quiz as well, so `VerbSearch` is an odd
  home for them. *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: both moved to `SpellingComparison`, whose one generic distance takes an optional limit; `AnswerDifference` keeps its own for the backtrace.*
- **Stripping "-se" is written twice**: `VerbSearch.spanishQuery` (`VerbSearch.swift:268-277`),
  with its own list of endings, and `ReflexivePronoun.bareInfinitive(fromCitation:)`.
  `RelatedVerbsView.citationForm(_:)` is likewise a copy of `ReflexivePronoun.citationForm(of:)`.
  *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: `spanishQuery` calls `bareInfinitive(fromCitation:)`, and the copy is gone.*
- **"Is this verb irregular?" has three definitions**: `VerbDraw.isIrregular` with its own
  `["1", "2", "3"]`, `Conjugator.verbType`, and `ModelPractice.regularClassNumbers`. Four types
  outside the daily draw reach into `VerbDraw` for it. *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: `VerbMapEntry.isIrregular`, which `verbType` and `ModelPractice` read too, and `VerbMapEntry.isCompound` in place of three copies.*
- **A model's verbs have two definitions**: `VerbCollection.verbs` filters every entry, and
  `ModelView` reads `ModelInfo.verbs`, so one bar uses both. A test exists only to keep them
  equal. *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: `ModelInfo.verbs`, now entries by frequency, is the one list, which the collection, the practice, and the Related Verbs card (a third copy) read; the test went.*
- **`private static func spanish(_:) -> AttributedString` is declared in fifteen views (Read: 15
  declarations, 17 files that set the language).** One extension would do. *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`: `AttributedString(spanish:)` and `Text(spanish:)` in `Utils/SpanishText.swift`; all fifteen declarations went.*
- **`tense == .imperativoPositivo || tense == .imperativoNegativo` is spelled out in six files**,
  while `DisplayTense.isCommand` sits in `GapSentence.swift:251`. *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`: it moved to `DisplayTense.swift`, and the six read it.*
- **The four `Shared/` intents have one `perform()` body**, and `"conjugar://"` is written out in
  seven places besides `URL.deeplinkScheme` (Read). A small protocol with a default `perform()`,
  and `WidgetDeeplink` moved to `Shared/` where a test can pin it, would remove both. *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`:
    `LinkStashingIntent` gives the four one `perform()`, and they and `WidgetDeeplink`, now in
    `Shared/`, build from the grammar's constants in `Shared/DeeplinkGrammar.swift`. Seven
    `"conjugar://` literals in code before, none after.*

<a id="smells"></a>
## Smells

- **S1. `VerbBrowseView` does too much (Read).** The struct is about 790 lines with 16 `@State`
  properties and a `@FocusState`. It owns the search and its ranking, three analytics reports, the recents, the My
  Verbs list with its alert, the failed search's help and mail fallback, hardware-keyboard
  selection, two iPad workarounds, the review card's lifecycle, and two kinds of router request.
  The file also holds four row types that other screens use. Natural seams: `MyVerbsList`,
  `FailedSearchHelp` (which would own `addressWasCopied`), a review-card host, the row types in
  their own file, and an `@Observable` search model that owns the text, the matches, the tracker,
  and the selection. The last would make the decisions testable. Today only
  `keyboardSelection(after:moving:count:)` is tested, and [C10](#c10)'s three bugs live in the
  untested decisions around it. *The search model fixed on `master`, 2026-11-26, in Phase 9 of
  `plans/verb_browse_fixes.md`: `Models/VerbBrowseSearch.swift`, with 37 tests. The view's other seams are Phase 10's.* *The rest fixed on
  `master`, 2026-11-26, in Phase 10 of `plans/verb_browse_fixes.md`: `MyVerbsList`, `FailedSearchHelp`,
  and `ReviewCardHost` are views of their own, and the review card's choice, reveal, snooze, and
  signals are `VerbBrowseReviewCard`, with 9 tests. `VerbBrowseView` is 341 lines with 4 `@State`
  properties.*
- **S2. `searchFocusLostAt` is a `Date` used as a `Bool`, and it never resets (Read).** It is
  assigned `.now` and compared only with `nil` (`VerbBrowseView.swift:36`, `:137`, `:152`). After
  the field first loses focus it stays set until the field is focused again, so every later push
  from the unsearched list goes through `Task { await waitUntilIdle() }`. That is harmless,
  because the wait returns at once when nothing is animating, but the guard does not do what its
  comment describes. *Fixed on `master`, 2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`: the state is gone.
  `searchIsEnding` is true during the linger, with the field unfocused and nothing typed, which is
  the moment it described.*
- **S3. Rows are opened by index, read when the tap fires (Read).** `openRow(at:…)` takes an index
  into `shownVerbs` and into `searchMatches`, two arrays that must stay parallel, and reads both
  when the action runs, though `wasSearching` and `browseSource` were deliberately captured when
  the row was drawn (`VerbBrowseView.swift:164-179`). Opening the right recent verb depends on
  the 700 ms linger still holding. The closure already has the entry; passing the entry and its
  match would remove the lookup and the dependence. *Fixed on `master`, 2026-11-26, in Phase 9 of
  `plans/verb_browse_fixes.md`: a `VerbBrowseSearch.Row` carries its entry and its origin (every verb, a recent verb,
  or a result with its match, place, and count), and the action opens that row.*
- **S4. Timed workarounds (Read).** 700 ms of lingering focus, 500 ms after a pop before focusing
  the field, a poll of up to a second for UIKit's transitions, and a four-second note
  (`VerbBrowseView.swift:146`, `:390`, `:304`; `ViewControllerTransitions.swift:17-22`). Each is
  commented as a hack with its reason, which is right. None is cancelled when superseded. The
  500 ms sleep could use the transition wait that already exists. They are worth one list in a
  doc, to retry on each new iOS. *Fixed on `master`, 2026-11-26, in Phase 9 of `plans/verb_browse_fixes.md`, but
  for the list, which is the Closing's: the linger and the note are cancelled when superseded, and
  the 500 ms sleep is a yield and the transition wait. With ⌘F from a verb page and typing 1.5
  seconds later, the field took the text 12 times in 12 across both simulators with the wait, and
  5 in 6 with neither wait nor sleep.*
- **S5. Declarations in files named for something else (Read).** `VerbDestination` is in
  `VerbVisit.swift`. `VerbListMode` is in `VerbSort.swift`. `verbPageDestinations()` and the
  `verbPagePush` environment key are in `RelatedVerbsView.swift`. `VerbRowLabel`, `VerbGridCell`,
  `LookedUpCheck`, and `MatchLines` are in `VerbBrowseView.swift`. `DisplayTense.isCommand` is in
  `GapSentence.swift`. `QuizScope.collection(_:title:)` is in `VerbCollection+Text.swift`.
  *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`: `VerbDestination.swift`, `VerbListMode.swift`, `VerbPageNavigation.swift`, `VerbRowLabel.swift`, and `RelatedVerbListView.swift` are new; `isCommand` and `collection(_:title:)` moved beside their types.*
- **S6. `QuizScope` is a bag of flags (Reviewer; I read `isRanked`).** `isRanked` is a conjunction
  of nine negatives and a length (`QuizScope.swift:104-107`), so a new mode that forgets to add
  itself is ranked and posts to Game Center. `startsLiveActivity` guesses "runs in a sheet" from
  `collectionKey` and `custom` (`:154-156`). No mode is wrongly ranked today. A `kind` enum with
  only the default ranked fails safe. This is mostly the pedagogy plan's code, built on this
  plan's Phase 13. *Fixed on `master`, 2026-11-27, in Phase 12 of `plans/verb_browse_fixes.md`:
  every scope names a `QuizScope.Kind`, only `allVerbs` at a round's length ranks, the old flags
  are readers of the kind, `Kind.runsInSheet` is what `startsLiveActivity` reads, and a test pins
  every scope the app starts.*
- **S7. The sort picker returns during a search and does nothing (Read).** With text in the field
  and the keyboard down, the picker replaces the letter row. Choosing My Verbs changes nothing on
  screen, and choosing a sort replays the trombone. *Fixed on `master`, 2026-11-26, in Phase 9 of
  `plans/verb_browse_fixes.md`: the picker is disabled while the field holds a search.*
- **S8. Unused or unguarded.**
  - `englishTitle` on four views is read nowhere (Read). *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`: deleted.*
  - `LearnerVerbs.daysSinceOpened` has no caller (Read). *Deleted on `master`, 2026-11-25, in
    Phase 3 of `plans/verb_browse_fixes.md`.*
  - `QuizScope.mixesChoiceQuestions` tests `!isPracticeSet`, which `isRanked` already implies
    (Reviewer). *Confirmed and fixed on `master`, 2026-11-27, in Phase 12 of
    `plans/verb_browse_fixes.md`: a practice set always carries a custom quiz, so it never ranked;
    the test is gone.*
  - `ConjugationTable.isCompound` is used only by tests (Reviewer).
  - `BrowseSearch` is six lines with one caller since the Verbs tab left it (Read). *Fixed on `master`, 2026-11-26, in Phase 7 of `plans/verb_browse_fixes.md`: folded into `ModelSearch`, which folds the query once per search.*
  - `ConjugationMapTool` accepts any `--flag value`, so a misspelled `--forms-json` writes the map
    and silently skips the file (`main.swift:43-53`, Reviewer). *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: an unknown or repeated flag fails the run.*
  - `VerbSearch.keys(for:)` decides whether its cache applies by comparing glosses only
    (`VerbSearch.swift:347-353`, Reviewer). `VerbMapEntry` is `Equatable`. *Fixed on `master`, 2026-11-26, in Phase 8 of `plans/verb_browse_fixes.md`: it compares whole entries.*
  - `SecondSingularBrowse.swift:11` cites "item 20" of a list that the reader cannot see
    (Reviewer).

## Tests

- **T1. Tests that prove less than their names say (Reviewer).**
  - `ReflexivePronounTests`' sweep of the 114 reflexive-only verbs compares through
    `VerbSearch.fold` (`:109`, `:117`), so it cannot catch a wrong enclitic accent, which is the
    thing most likely to be wrong. Only five verbs pin accents exactly. The reviewer ran the
    algorithm standalone on 46 hard cases (conduélete, desvergüénzate, inmiscúyete, comidámonos,
    arrepentíos, huíos, tente) and every one was right, so this is a missing guard, not a bug.
    *Fixed on `master`, 2026-11-25, in Phase 5 of `plans/verb_browse_fixes.md`: a golden table of fourteen verbs' joined commands and gerunds,
    all right.*
  - `matchKindIsSentByItsName` (`LookupSignalsTests.swift:38-41`) compares each wire name with
    `String(describing:)` of the case, so renaming both enums together passes and changes what is
    sent. `guess` and `none` are not pinned at all. *Fixed on `master`, 2026-11-25, in Phase 2 of `plans/verb_browse_fixes.md`:
    `matchKindValuesAreStable` pins both enums' wire names by literals, and `outcomeValuesAreStable`
    pins `SearchOutcome`'s. `AnalyticsTests`' tables now pin `startQuiz`, `tapDailyReminder`,
    `enabled`, and `streak`, which had no literal in the tests, as the reviewer said.*
  - `noParameterCanEchoTheQuery` holds by the types, and four of its eight arguments are words
    already in the vocabulary.
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: `aReportKeepsNoText` pins the types,
    failing if a stored property of a report is text, and the sweep, renamed
    `everyParameterValueIsAWordOfTheVocabularyOrABand`, takes only queries outside the vocabulary,
    two of them long enough that an unbanded length would fail it.*
  - `VerbLookupTests.swift:147` asserts `named.count == maxNamedVerbs || named.contains("comer")`,
    which passes in almost any outcome. *Fixed on `master`, 2026-11-25, in Phase 1 of
    `plans/verb_browse_fixes.md`: it pins the four verbs.*
  - `formsAreEveryOneWordFormOnce` (`VerbSpotlightTests.swift:30-32`) checks that one alternate
    name is present.
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: it now runs on four verbs (ir, tener, arrepentir,
    abolir) and compares each list whole with one built cell by cell from the engine through
    `ConjugationMap.form(of:at:)`.*
  - `ConjugationMapTests.swift:160` takes `prefix(20)` of a dictionary, a different twenty each
    run.
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: the test checks every defective verb.*
  - `ConjugationTableTests.swift:64-70` checks that `ConjugationMatch.allCells` follows
    `ConjugationTable.all`, from which `allCells` is built (`ConjugationMatch.swift:34-43`), so it
    asserts a definition (Read).
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: `searchNamesFollowThePage` walks the rows
    `VerbPageForms` draws, with tú and vos shown, and asks that each is the next cell of `allCells`
    by tense, pronoun, and form.*
  - `strongPreterite` and `irregularParticiple` are pinned by count alone
    (`VerbCollectionTests.swift:60-61`), so one verb swapped for another passes.
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: both are pinned by name, 22 and 17 verbs, as
    the -go and future lists were.*
- **T2. Branches with no test.**
  - The lines a search row shows for an enclitic query ([C1](#c1)), and the marks a lookup's link
    produces ([C6](#c6)).
    *Covered on `master` before Phase 13 of `plans/verb_browse_fixes.md` (2026-11-27): Phase 1 added the rows' lines and the links' marks
    (`ReverseLookupTests`, `AppRouterTests`).*
  - An ñ twin in Look Up a Verb ([C4](#c4)).
    *Covered on `master` before Phase 13 of `plans/verb_browse_fixes.md` (2026-11-27): Phase 1, in `VerbLookupTests`.*
  - The rotation with a list that changes ([C3](#c3)).
    *Covered on `master` before Phase 13 of `plans/verb_browse_fixes.md` (2026-11-27): Phase 4, in `WidgetWeekTests`.*
  - A visit's begin and end across `scenePhase` and a sheet ([G3](#gaps-between-the-docs-and-the-code)).
    *Covered on `master` before Phase 13 of `plans/verb_browse_fixes.md` (2026-11-27): Phase 5, in `VerbVisitTrackerTests`.*
  - Everything in `VerbBrowseView` but one static function ([S1](#smells)).
    *Covered on `master` before Phase 13 of `plans/verb_browse_fixes.md` (2026-11-27): Phases 9 and 10 moved the list's logic into
    `VerbBrowseSearch`, which `VerbBrowseSearchTests` covers.*
  - The widget's link literals: nothing in `ConjugarTests` names `WidgetDeeplink`, so a typo in
    `source=widget` would quietly report `deeplink` (Read). *Fixed on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`: `AppRouterTests`
    pins each of the widgets' links whole and routes it.*
  - `editDistance(_:_:limit:)` against the unlimited version.
    *Covered on `master` before Phase 13 of `plans/verb_browse_fixes.md` (2026-11-27): Phase 8,
    `SpellingComparisonTests.theLimitedDistanceAgreesWithTheUnlimitedOne`.*
  - `ModelView.gridPersons(for:)`.
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: `ModelInfoTests` pins its columns for tú, vos, and
    both, and that they are the verb page's rows in the same order.*
- **T3. Tests that share state or depend on the clock (Reviewer).**
  - `QuizScopeTests` and `VerbCollectionTests:171-179` build a `Quiz` without `practice:`, so
    their answers land in the global `Current.practice`, and a later ranked quiz draws due items
    from whatever was left there.
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: both, and the twelve other suites that built a
    `Quiz` the same way, now give each quiz a `PracticeStore` of its own.*
  - `World.unitTest` gives `learnerVerbs` and `practice` two different fakes, though
    `PracticeStore`'s comment says they must share one store.
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: `World.unitTest` and `World.uiTest` now give both
    stores one `GetterSetterFake`, as the device and simulator worlds give them the App Group's.*
  - `PracticeRecordTests.swift:38-40` subtracts flat 86,400-second days from `Date.now` and
    asserts an exact day count, which fails in the first hour after midnight within ten days of a
    spring-forward change.
    *Fixed on `master`, 2026-11-27, in Phase 13 of `plans/verb_browse_fixes.md`: the store's tests count back by calendar days
    from a fixed noon, in the suite's UTC calendar, which each store is given.*

## Costs of Settled Decisions

These are Josh's decisions, recorded in the plan. Each has a cost its note does not mention.

- **Opening a verb from the widget counts as looking it up.** Every open but the review card's
  calls `recordLookup` (`VerbView.swift:220-223`). On a My Verbs day the widget shows a verb the
  learner already has, and a tap sends its schedule back to the first box.
- **The verb of the day changes only when the app is opened (Reviewer).** The app writes one
  snapshot, for today, on launch and on becoming active. A learner who stays away for five days
  sees one verb for five days. This predates the plan, but Phase 14's "next ten days" was tested
  as a function and never as what the widget holds. The draw is deterministic, so the app could
  write a week of verbs. See [Q9](#open-questions).
  **Fixed on `master`, 2026-11-25, in Phase 4 of `plans/verb_browse_fixes.md`:** the app writes
  today and six days ahead, and the widgets' timelines change at each midnight.
- **A verb deleted from My Verbs can still be offered by the review card**, with "Looked up 3 days
  ago", because Clear and the swipe keep the practice record by decision.
- **Weather verbs share as one form.** A third-person-only verb's key conjugations leave out the
  three yo cells, so llover's shared line is "llovido".

<a id="konjugierens-findings-checked-here"></a>
## Konjugieren's Findings, Checked Here

Read after the review above was complete. IDs are those of
[`../Konjugieren/docs/verb_browse_review.md`](../../Konjugieren/docs/verb_browse_review.md).

### Carried over in the port

| Konjugieren | Here | Evidence |
|---|---|---|
| C1, third part: a folded infinitive answers Look Up a Verb as a literal | [C4](#c4). Five ñ pairs, against eighteen umlaut pairs | Run |
| C2: the widget's rotation repeats | [C3](#c3), the same code | Read |
| C3: the red-letter tip's guard is always true | [C2](#c2). Here the auxiliary alone causes it; there is no capital-S pronoun | Run |
| C4: tidying My Verbs erases collection progress | [C9](#c9), the same code | Read |
| C7: Recent can show fewer than twenty | [C13](#c13-smaller-correctness-findings) | Read |
| C7: a bad link cancels a good pending one | [C13](#c13-smaller-correctness-findings), narrower: only an open practice set is cleared | Read |
| C7: Spotlight is rebuilt at every launch and never removes a verb | [F2](#f2-smaller-performance-findings) | Read |
| F2: an ended search is computed again | [F2](#f2-smaller-performance-findings) | Read |
| P1: a correction's group link names the verb | [P1](#p1). Models here, ablaut groups there; 29 single-verb models, against 18 groups | Read |
| G1: the widget does not read the record | G1 | Read |
| G3: the widget's links are not pinned | T2. Here they are not tested at all | Read |
| G4: a migration for data no shipped build wrote | G5 | Read |
| G5: dwell includes time under a sheet | G3 | Reviewer |
| G6: the Related Verbs card has no section | G4 | Read |
| D5: the collection and family views repeat themselves; a bar handed one list while its quiz asks another | [D2](#d2-the-models-page-and-the-collections-page-read), [D3](#d3-smaller-duplication-reviewer-unless-noted) | Read |
| D6: retyped links and identical `perform` bodies | [D3](#d3-smaller-duplication-reviewer-unless-noted). Four intents here | Read |
| S1: `VerbBrowseView` does too much | S1. About 790 lines and 17 state properties in both apps | Read |
| S2: `searchFocusLostAt` | S2, the same code | Read |
| S3: declarations in files named for something else | S5. `FlowLayout` has its own file here | Read |
| S4: the search keys' cache | S8. Here it checks glosses, which is safer and still incomplete | Reviewer |
| S6: `isRanked` as a conjunction of negatives | S6 | Read |
| S7: timed workarounds, none cancelled | S4. Four here; the 400 ms sheet wait is absent | Read |
| S8: the sort picker during a search | S7 | Read |
| S9: the tool accepts any flag | S8 | Reviewer |
| T1: `allCellsFollowsThePage` asserts a definition | T1, the same shape | Read |
| T1: `noParameterValueEchoesTheQuery` holds by the types | T1 | Reviewer |
| T3: the rotation, the visit's pairing | T2 | Read |
| Costs: a widget open counts as forgetting the verb | [Costs of Settled Decisions](#costs-of-settled-decisions) | Read |

### Did not carry over

- **C1, first part: the ranking puts a folded infinitive above a literal conjugation.** Conjugar
  has the same order of kinds, but the probe found no conjugation that folds to an infinitive: no
  Spanish form but the infinitive ends in -ar, -er, or -ir. The order cannot misrank anything
  today.
- **C5: "alphabetical" that does not sort.** `VerbSort.sorted` sorts, with a Spanish locale.
- **C7: a collection key stored as the link spelled it.** Conjugar's keys are ASCII, and a model's
  class number is validated against the catalog before it is kept.
- **C7: Spotlight's migration flag.** Conjugar never used the default index, so there is no
  migration.
- **C7: two entry points bypass the route.** Conjugar has no Open Verb intent, and Spotlight and
  Look Up a Verb both go through `AppRouter.handle(url:)`.
- **F1: a failed search stalls on its guess.** Measured here at 22 to 88 ms. Conjugar's
  `editDistance` has the early exit that Konjugieren's review suggests. Conjugar has a different
  main-thread wait, [F1](#f1).
- **F2: related verbs rebuilt in `body`.** Conjugar derives them in `VerbView.init`, which is
  better and has its own question ([F2](#f2-smaller-performance-findings)).
- **F2: Look Up a Verb builds the index on the main actor.** `LookUpVerbIntent` is `@concurrent`
  here. `VerbEntityQuery.entities(matching:)` is not, which a reviewer flagged as a suspicion.
  *Checked on `master`, 2026-11-26, in Phase 6 of `plans/verb_browse_fixes.md`, and not real as App
  Intents calls it: a query of the same shape, called through `EntityStringQuery`, ran off the main
  thread, though called directly from the main actor it ran on it. The query's methods are now
  `@concurrent` all the same, so that a direct caller cannot stall either.*
- **G7: the stale figures.** Conjugar's own comments have different stale prose
  ([G7](#gaps-between-the-docs-and-the-code)). The tool's comment about the script sandbox is
  conditional here ("if enabled") and still true.
- **S5: statics with multiple scenes.** Conjugar's `Info.plist` does not enable multiple scenes.
- **S10: two apps building the tool into one directory.** Conjugar's scripts already use
  `ConjugarConjugationMapTool-build`.
- **T1: `differentQuestionsCanOrderDifferently`.** No test by that name exists here.
- **T2: `InfoTests` copies `cleanURLString`.** Nothing by that name exists here.
- **T4: exact results against a growing corpus.** `VerbSearchTests`' exact lists use invented
  verbs.
- **E2 and E3.** `VerbView.section(markedBy:)` here is two comparisons against
  `ConjugationTable.firstSimple` and `.firstCompound`. E2's `rows(for:)` has no counterpart by
  that name here, and I did not look further for one.

### Do not apply to Spanish

- **C1, second part** (stranded separable verbs), **C6** (Swiss spelling), **C7** (a strong second
  reading and the ablaut row), **D2** (the zu-infinitive), **D7** (the main-clause split), **E1**
  (the folded row's types), and the cost about the *sein* collection's quiz all rest on separable
  prefixes, ß, ablaut groups, or auxiliary choice.
- **G2** (the frequency doc's Konjunktiv I counts) is about a German heuristic in Konjugieren's
  counting script. I did not review `scripts/count_tenses.py`, Conjugar's counterpart, for an
  analogous overcount.
- **D1, D3, D4** name Konjugieren's types. Conjugar's nearest analogs are `oneWordCells`, which is
  defined once, and the three places that turn a text into marks (`AppRouter.marks`,
  `VerbBrowseView.marks(of:)`, `VerbLookup.markableText`), which [C6](#c6) touches.
- **The search-scope flip** has no counterpart: Conjugar has no gloss setting.

### Found here and not in Konjugieren's review

[C1](#c1) (clitic agreement), [C5](#c5) (ñ in several-word lookups), [C6](#c6) (a lookup's link
marks two rows), [C7](#c7) (the scroll tip), [C8](#c8) (false bases), [C10](#c10) (the keyboard
selection), [C11](#c11) (pushes that skip the wait), [C12](#c12) (a failed decode), the stashed
link that waits, and [F1](#f1) (the index's first load). Some of these are Spanish-specific. C6,
C7, C10, C11, C12, and the stashed link may exist in Konjugieren too. I did not look, as the
prompt asked.

<a id="open-questions"></a>
## Open Questions

Decisions that are Josh's, each with what I would do. **Josh answered all twelve on 2026-11-25.**
His answers are in [`plans/verb_browse_fixes.md`](../plans/verb_browse_fixes.md) § Decisions
Already Made. He took the course in italics for the first eleven, and for the twelfth chose the
full refactor, `AdaptiveRows` and one row label included.

1. **[P1](#p1).** Drop `collection` from `viewCollection` when the source is `quizCorrection`, or
   amend the staged policy line? *I would drop it.*
2. **[C1](#c1).** How strict should clitic agreement be? The rule proposed rejects tú + *os*
   ("míraos"), which is grammatical as an object and rare. *I would take the strict rule.*
3. **[C2](#c2).** May the red-letter tip point at a red auxiliary on a regular verb's page, or
   should it wait for a verb that is itself irregular? *I would make it wait.*
4. **[C4](#c4).** When a learner asks Look Up a Verb for "sonar", name sonar and soñar, or open
   sonar's page? *I would open sonar's page, and always open soñar's for "soñar".*
5. **[C8](#c8).** Is "Built on" a claim about etymology or about what a learner can see? Under the
   second reading acercar, contestar, preparar, and revelar lose their bases, and impedir might
   keep pedir, since the two conjugate alike. *I would remove the three false ones now and leave
   the opaque ones.*
6. **[C9](#c9).** Should clearing or swiping a verb out of My Verbs keep its check in collections?
   *I would keep the check, by counting progress on `firstOpened`, and confirm before Clear.*
7. **[C13](#c13-smaller-correctness-findings).** When a link arrives while the game is up, should
   the link close the game, or wait as a practice set waits? The same question applies to a sheet
   such as Test Me. *I would close the game and leave sheets alone.*
8. **G6.** Should the Models tab's search field get the Verbs tab's settings: no autocorrection,
   no autocapitalization, and the drawer on iPad? *I would give it the first two and ask to see
   the drawer.*
9. **Costs.** Should the app write a week of verbs so that the widget changes daily without the
   app being opened? *Yes; the draw is already deterministic.*
10. **[C13](#c13-smaller-correctness-findings).** Should a stashed link expire, so that a shortcut
    run with the app in front does nothing later? *I would drain it at once where the intent runs
    in the app, and drop a stash older than a minute.*
11. **G5.** Delete the practice record's migration before the release? *Yes, at release time.*
12. **[Duplication](#duplication).** How far to go: the cheap shared pieces only, or `AdaptiveRows`
    and a search model for `VerbBrowseView` as well? *The cheap pieces and the search model; leave
    `AdaptiveRows` until a third screen needs it.*

## What Is Done Well

- **One matching and ranking function, shared.** `VerbSearch` serves the list, the shortcut's
  picker, and Look Up a Verb, as Phase 0 asked, so they cannot drift.
- **The map is built from the engine's own sources**, and a test proves that the bundled map
  matches a fresh build. The build phase's inputs and outputs are declared, and the tool fails
  loudly.
- **The reflexive display is right.** `ReflexivePronoun` derives each enclitic accent from the
  general rules, not a table, and survived 46 hard cases run standalone. The engine's own output
  did not change, so every oracle test kept its expectation.
- **`ConjugationTable` is the one place the page's order lives**, and the section marks and the
  landing scroll derive from it.
- **The deeplink grammar round-trips.** Builders and parser agree for every route, including ñ,
  a decomposed ñ, and reserved characters in a query, and every one-shot request is consumed
  exactly once.
- **The privacy work is careful**: bands, fixed vocabularies, and staged policy lines in both
  languages for everything this plan sends. That is why P1 stands out.
- **The hacks are labeled as hacks**, each with the failure it works around.

## A Suggested Order of Work

1. **[C1](#c1), [C4](#c4), [C5](#c5), [C6](#c6)**, with tests on the lines and the marks. All
   four are in the lookup, and one session can hold them.
2. **[P1](#p1).** A one-line change, or a ruling.
3. **[C3](#c3) and [C9](#c9).** Small changes to values in `Shared/`, with pure tests.
4. **[C2](#c2), [C7](#c7), [C8](#c8).** Three small fixes on the verb page, two of which need a
   ruling first.
5. **[F1](#f1).** Search without the index until it is ready.
6. **The cheap duplication** ([D1](#d1-the-two-browse-screens-read), [D2](#d2-the-models-page-and-the-collections-page-read)):
   the heading, the picker, the sorted lists, one `VerbDestination` registration, and
   `SortableVerbList`.
7. **[S1](#smells) with [C10](#c10), [C11](#c11), and S2 to S4**: extract the search model, and
   fix the selection, the pushes, and the timers where they then live, under tests.
8. **G1, G2, G7, G8** as a prose pass, **T1 to T3** alongside the code they cover, and **G5** at
   release time.
