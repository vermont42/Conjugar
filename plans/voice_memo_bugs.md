# Plan: Fix the Five Bugs from the Voice Memo

**For:** fresh Claude Code sessions, one phase per session as a rule. The three phases are
independent and can run in any order. **Kind of work:** SwiftUI views, one model type, the string
catalog, tests, and docs. **Written:** 2026-11-27, from Josh's recording `~/Downloads/Bugs.m4a`
and the six screenshots he took on his iPhone while recording it.

## Status

| Phase | Status | Date | Commit | Bugs |
|---:|---|---|---|---|
| 1 | Awaiting Josh | 2026-11-27 | | Bug 1: tense names move from the verb page to the articles |
| 2 | Awaiting Josh | 2026-11-27 | | Bugs 2, 3, 5: truncated titles and level names, and a sweep |
| 3 | Awaiting Josh | 2026-11-27 | | Bug 4: the letter keys cover the quiz's answer field |

A session that finishes a phase fills in its row with "Awaiting Josh" and writes a **How it
differed** note under that phase. Sessions never commit; Josh does. The next session fills in the
Commit cell from `git log`.

## The Source

The recording is 8 minutes long, mostly silence between takes. It was transcribed with
whisper.cpp (`../Video/tools/whisper.cpp`, model `ggml-small.en.bin`), once with a vocabulary
prompt and once without. The prompted run invented a sentence in every silence, so the run
without a prompt is the one below. The four stretches that had sound but no words were
transcribed on their own and are taps and app sounds, not speech. Josh's words, with whisper's
mishearings corrected:

1. **0:05, screenshot 1.** "Get rid of the 'also' label for all tenses. Ensure that Info
   articles for tenses have English and alternate names for tenses. The exception to that is
   Spanish versions of Info articles should not have English tense names."
2. **1:40, screenshot 2.** "The title 'Irregular Participles' is truncated. I do have a fairly
   large Dynamic Type setting, but it's not an accessibility-size type setting, so it should
   work. Apply whatever fix you make to other tabs."
3. **3:47, screenshot 3.** "The label 'Elementary' is truncated."
4. **4:32, screenshot 4.** "As you can see in this freshly started quiz, the accented letters are
   partially covering the input field. It would be better if the input field scrolled up a bit
   so that it's above the accented letters, as shown in screenshot 5."
5. **7:00, screenshot 6.** "'Intermediate' is truncated."

The screenshots are beside this plan, at half size, in
[`voice_memo_bugs/`](voice_memo_bugs/): `screenshot_1.jpg` to `screenshot_6.jpg`. The originals
were `~/Downloads/1.PNG` to `6.PNG`.

## What the Screenshots Say About the Device

Read this before trying to reproduce anything, because the project's simulator does not match.

- **The screen is 375 × 812 points.** Each screenshot is 1125 × 2436 pixels at 3×. The
  "Conjugar iPhone 17" simulator is 402 × 874 points, 27 points wider and 62 taller, so bugs 2
  to 5 may not reproduce there at the same text size. The size, together with the Dynamic
  Island in the status bar, suggests a large iPhone with Display Zoom on. That is a guess. The
  measured size is what matters.
- **The text size is probably xxxLarge**, the largest size that is not an accessibility size.
  This is estimated from the body text's line height in screenshot 6 (about 28 points). Josh
  said only "fairly large" and "not an accessibility size". If xxLarge does not reproduce a
  bug, use xxxLarge.
- **The interface is English, dark mode, Latin American region.**

**A 375 × 812 simulator.** The iPhone 13 mini device type has exactly this screen, and the iOS
26.3 runtime is installed. Phases 2 and 3 need one. This plan assumes Josh agrees to a third
Conjugar simulator (decision D4):

```bash
xcrun simctl create "Conjugar iPhone 13 mini" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-13-mini \
  com.apple.CoreSimulator.SimRuntime.iOS-26-3
```

Not yet tried: whether the 26.3 runtime accepts this device type. If it refuses, the iPhone SE
(3rd generation) is 375 × 667, the same width and shorter, which is a harder test of bug 4. Use
the new simulator with `TARGET_SIM="Conjugar iPhone 13 mini"` before each `ios-build-verify`
script. `tap_tab.sh` holds the iPhone 17's coordinates, so navigate with deeplinks, `tap_id.sh`,
and `describe_ui.sh` frames. When the simulator exists, add it to CLAUDE.md § Conjugar's own
simulators with its UDID, and shut it down after each use.

**Text size and keyboard.**

```bash
xcrun simctl ui "$UDID" content_size extra-extra-extra-large   # restore with: large
```

Bug 4 needs the software keyboard, which the simulator hides while a hardware keyboard is
connected. Simulator's I/O ▸ Keyboard ▸ Connect Hardware Keyboard governs it, and Cmd+K does
nothing on this toolchain. See `docs/screenshot_playbook.md`, workaround #25, and the journal
entry "The quiz's truncated tense names (2026-09-27)". Restore the text size, the hardware
keyboard, the language, and the appearance when done, and say in the journal that you did.

## Decisions This Plan Assumes

Each has a default that the phases build. Josh can strike any of them before a phase starts.

- **D1. "The 'also' label" is the whole line under a tense's heading**, not only the word
  "also". The reason for this reading: his next sentence sends the names to the articles, which
  only makes sense if they leave the verb page. So "also imperfect · pretérito imperfecto"
  goes, and the heading and the ⓘ button stay.
- **D2. What each article shows.** The English article shows the English name, then the RAE's
  name where it differs from the heading, then Andrés Bello's name where there is one. The
  Spanish article shows the RAE's and Bello's names and no English name. Today the English
  interface never shows Bello's names. An article has room for them, and a learner in a Mexican
  classroom meets them.
- **D3. The names are rendered from data, not written into forty catalog strings.**
  `ConjugationTable` already holds every name. `InfoView` draws them under the article's
  heading. The article bodies in `Localizable.xcstrings` do not change.
- **D4. A third Conjugar simulator**, as above.
- **D5. The four articles in the Tenses section that are not verb-page cards get no names
  line**: Participio, Gerundio, Raíz Futura, and Perífrasis Verbales. `ConjugationTable` has no
  names for them.
- **D6. Existing prose stays.** Three Spanish articles already name an English tense in a
  sentence: Perfecto de Indicativo ("el tiempo inglés conocido como "present perfect""),
  Pluscuamperfecto de Indicativo ("past perfect"), and Pluscuamperfecto de Subjuntivo 1 ("third
  conditional"). Their English versions say the same. Each sentence compares the tense's use to
  an English tense and is not a name for the Spanish tense, so this plan leaves all of them. If
  Josh's rule about Spanish articles covers them, Phase 1 rewrites those three Spanish
  sentences.

## How Each Session Works

1. Read CLAUDE.md, this plan's top sections, and the phase.
2. Check `git status`. `plans/pedagogy_fixes.md` has 16 phases that also edit `QuizView.swift`
   and `SettingsView.swift`. Do not start a phase here while another session's uncommitted work
   is in those files.
3. Reproduce the bug before changing code (Phases 2 and 3), and screenshot it.
4. Fix, then run `"$IBV_SCRIPTS/build_app.sh"`, the full test suite, and `swiftlint`.
5. Check the result on screen in English and Spanish, and screenshot it.
6. Update the docs the phase names, append a journal entry to `docs/blog_notes.md`, and fill in
   the Status row.

---

## Phase 1: Tense Names Move to the Articles (Bug 1)

### What is there now

- `VerbView.conjugationCard` (`Conjugar/Views/VerbView.swift`) draws each card's heading, the ⓘ
  button, and under them `secondNamesLine(section.table)`. That line is "also" (`L.Verb.alsoKnownAs`,
  catalog key `Verb.alsoKnownAs`, "also" / "también") followed by the names from
  `ConjugationTable.secondNames(spanishInterface:)`, joined with " · ".
- `ConjugationTable` (`Conjugar/Models/ConjugationTable.swift`) holds the names. `englishNames`
  gives the English name and the RAE's name where it differs. `spanishNames` gives the RAE's
  name and Bello's. `articleKey` is the `Info.stableKey` of the tense's article.
- `InfoView` (`Conjugar/Views/InfoView.swift`) draws an article: a serif gold heading, a
  three-dot rule, and the body. It is used by the Info tab, by `TenseArticleSheet` (the ⓘ
  button's sheet, private to `VerbView.swift`), and by `conjugar://info/<key>`.
- No article lists its tense's other names today. A search of all 30 article bodies in both
  languages for the names in `ConjugationTable` found only the prose mentions listed under D6.

### What to build

1. **Remove the line from the verb page.** Delete `secondNamesLine`, `secondNamesText`, and
   `attributed(_:)` from `VerbView`, and the call in `conjugationCard`. Check whether the inner
   `VStack(alignment: .leading, spacing: 2)` that held the heading row and the line is still
   needed. Check `VerbView.spanishInterface` for other callers before removing it.
2. **Remove the string.** Delete `L.Verb.alsoKnownAs` from `L.swift` and `Verb.alsoKnownAs` from
   the catalog. Edit the catalog with `python3`, per `.claude/rules/localization.md`.
3. **Give `ConjugationTable` the article's names.** Replace `secondNames(spanishInterface:)`
   with a function for the article, for example `articleNames(spanishInterface:)`, that returns
   per D2:
   - English interface: the English name (`isSpanish: false`), then every Spanish name in
     `spanishNames` (`isSpanish: true`). `spanishNames` already starts with the RAE's name, so
     the English list no longer needs its own `rae` column: for all seven tenses that have a
     `rae` value today, it equals the first of `spanishNames` (checked 2026-11-27). The English
     articles of the other tenses gain Spanish names they never showed, such as "antepretérito"
     for Pretérito Anterior and "no + presente de subjuntivo" for Imperativo Negativo. Read all
     20 lists once they render, and tell Josh about any that reads oddly in an English article.
   - Spanish interface: `spanishNames` only.
   Keep `SecondName` or rename it. If renamed, rename it everywhere, including the docs.
4. **Draw the names in `InfoView`.** Find the article's table with
   `ConjugationTable.all.first { $0.articleKey == info.stableKey }`. When there is one and its
   names are not empty, draw them between the heading and the three-dot rule, or just under the
   rule, whichever reads better at xxxLarge on a 375-point screen. Suggested shape, in
   `.subheadline` and `.secondary`, centered like the heading:
   - English: "English: preterite" on one line, "Other names: pretérito perfecto simple ·
     pretérito indefinido" on the next.
   - Spanish: "Otros nombres: pretérito perfecto simple · pretérito indefinido".
   - New strings: `Info.englishNameLabel` ("English" / unused in Spanish, but give it a
     translation anyway) and `Info.otherNamesLabel` ("Other names" / "Otros nombres"). No word
     "also".
   - Presente de Indicativo and Presente de Subjuntivo have no Spanish names. Their English
     articles show the English line alone, and their Spanish articles show no names block.
   - Names wrap. Nothing here has a `lineLimit`.
5. **VoiceOver.** Keep what the old line did: each name is its own element, spoken in its own
   language (`AttributedString(spanish:)` for a Spanish name). The label words ("English",
   "Other names") are read with the first name of their line.
6. **Tests** (Swift Testing), in `ConjugationTableTests` and `InfoTests`:
   - The English list starts with a non-Spanish name for every card, and every later name is
     Spanish.
   - The Spanish list has no non-Spanish name, for every card. This is Josh's exception, pinned.
   - No name repeats its heading (the existing test, kept).
   - Spot checks: Pretérito in English is preterite, pretérito perfecto simple, pretérito
     indefinido. Imperfecto de Indicativo in Spanish is pretérito imperfecto, copretérito.
   - Every card's article resolves back to that card through `articleKey`.
   - Participio, Gerundio, Raíz Futura, and Perífrasis Verbales resolve to no table.
   - Delete the tests of the removed function.
7. **Docs.** Rewrite the "Second names" paragraph of `docs/feature_architecture.md` § Verb Page
   to say where the names live now. Fix the three lines of `docs/project_structure.md` that
   mention second names (the `ConjugationTable.swift`, `ConjugationTableTests.swift`, and
   feature-architecture rows). Search the repo for "second name" and "alsoKnownAs" afterward.
   Leave `docs/blog_notes.md` and finished plans as they are.

### Done when

- No tense card on any verb's page shows a line under its heading, in either language.
- All 20 card articles show their names, from the Info tab, from the ⓘ sheet, and from
  `conjugar://info/preterito`. The four other Tenses articles show none.
- No Spanish article's names block has an English name.
- The suite passes, with the count line printed, and SwiftLint is clean.
- Screenshots: ser's page in English and Spanish, and the Pretérito and Presente de Indicativo
  articles in English and Spanish.

### How it differed

`SecondName` became `TenseName`. The names sit between the heading and the three dots, in
`.subheadline` and `.secondary`, as suggested. The new tests are in `ConjugationTableTests` only,
since the lookup from an article (`ConjugationTable.table(forArticle:)`) lives there. Four English
lists may read oddly; the journal names them.

---

## Phase 2: Truncated Titles and Level Names (Bugs 2, 3, 5)

Create or boot the 375 × 812 simulator, set xxxLarge, and reproduce all three before fixing.
If one does not reproduce at xxxLarge on that screen, say so in the journal and fix it anyway,
since the arithmetic below says each is near its limit.

### Bug 2: a large navigation title is one line and truncates

**Cause.** `VerbCollectionView` sets `.navigationTitle(collection.title)` with
`.navigationBarTitleDisplayMode(.large)`. The system's large title never wraps and never
shrinks. "Irregular Participles" at xxxLarge is wider than the 343 points a 375-point screen
leaves it. Spanish is longer: "Participios irregulares".

**"Other tabs."** Every screen whose large title can outgrow the screen has the same bug. The
inventory, from `Conjugar/Views/`:

| Screen | Title | Mode now | Longest known |
|---|---|---|---|
| `VerbCollectionView` | `collection.title` | `.large` | "100 Most Frequent Verbs", "Los 100 verbos más frecuentes" |
| `VerbView` | the verb's citation form, capitalized | `.large` | "Internacionalizar" (17 letters), and reflexives add "se" |
| `ModelView` | the model's exemplar, capitalized | `.large` | short today; check the longest exemplar |
| `QuizView` on the tab | a session's name while it runs | `.automatic`, so large | "Complete the Sentence", "Lo esencial del verbo", "Identifica la forma" |
| The five tab roots | `localizedTitle` | `.automatic`, so large | "Configuración", "Información" |

**Fix: one shared treatment, in `Utils/Modifiers.swift`.** The title moves into the scroll
content, where text can wrap, and the bar goes inline. `InfoView` already works this way.

- The screen keeps `.navigationTitle(title)`, because back buttons and VoiceOver read it, with
  `.navigationBarTitleDisplayMode(.inline)`.
- The title is the first item of the scroll content: `.largeTitle.bold()`, leading-aligned,
  `.fixedSize(horizontal: false, vertical: true)`, with the header trait. Use `Text(spanish:)`
  where the title is a Spanish word (a verb, an exemplar), so VoiceOver pronounces it.
- The bar's inline title is hidden while the in-content title is on screen and appears once it
  has scrolled away, as the system's large title does. A `ToolbarItem(placement: .principal)`
  whose opacity follows the header's visibility does this. `VerbView.swift` already has a
  `reportsVisibility` helper that may serve. VoiceOver must not hear the title twice.
- Build it as one view plus one modifier so that the three detail screens share it. Name it for
  what it does.

Apply it to `VerbCollectionView`, `VerbView`, and `ModelView`. For `VerbView`, check that the
toolbar's three buttons and the review card still sit right, and that `conjugar://verb/ir?match=fue`
still scrolls to the marked form: a taller scroll content changes the landing position.

**The quiz.** While a quiz is in progress on the tab, make the title `.inline`, as Test Me's
sheet already is (`sheetScope == nil ? .automatic : .inline` in `QuizView.body`). A large title
there costs 54 points of height while the keyboard is up, which is part of bug 4. Then check
that the longest session name fits inline beside the Quit button in both languages. If it does
not, show the session's name in the content, above the progress bar, and leave the bar's title
as "Quiz".

**The five tab roots.** Their titles are short and fixed. Measure "Configuración" and
"Información" at xxxLarge and at the largest accessibility size on the 375-point screen. Change
a root only if its title truncates.

**Rejected.** Shrinking the system title through `UILabel.appearance` inside `UINavigationBar`
reaches into a private label, may not survive iOS 26's bars, and makes a long title small
instead of readable. Shortening the titles fails again at the next text size or in Spanish.

### Bug 3: "Elementary" truncates in the Quiz tab's level tile

**Cause.** `QuizFactTile` (bottom of `QuizView.swift`) draws its value with `.lineLimit(1)` and
`.minimumScaleFactor(0.7)`. Three tiles share the row, so each is about 109 points wide on a
375-point screen. After the tile's padding and the level tile's chevron, the name has about 78
points. "Elementary" in `.headline` at xxxLarge needs about 125, and 0.7 of that is still too
wide. "Intermediate" is longer.

**Fix.** A single word cannot wrap, so the tile needs more width when the name does not fit.

- Use `ViewThatFits(in: .horizontal)` in `factTiles`: first the row of three as it is today,
  then a two-row layout with Questions and Minutes side by side and the Level tile at full
  width beneath them.
- `ViewThatFits` judges by ideal width, and a tile with `.frame(maxWidth: .infinity)` and a
  scalable text always claims to fit. For the measurement to be honest, the level name must
  report its unscaled width in the first candidate. Check this on screen, not by reading the
  code: at default text size the row of three must still be chosen, and at xxxLarge on 375
  points the two-row layout must be.
- Keep a mild `minimumScaleFactor` (0.85 or so) only as a last guard, so that no name is drawn
  much smaller than "10" and "2–3" beside it.
- The iPad's large tiles (`isLarge`) should come out as they are now.

### Bug 5: "Intermediate" truncates in Settings' Level picker

**Cause.** `SettingsView.quizLevelPicker` is a four-column `LazyVGrid` whose names are
`.caption` with `.lineLimit(1)` and `.minimumScaleFactor(0.7)`. Each column is about 72 points
on a 375-point screen. "Intermediate" at xxxLarge needs about 110, and 77 after scaling. The
scaling also gives the four names four different sizes, which screenshot 6 shows: "Beginner" is
plainly larger than "Elementary".

**Fix.** Choose the column count by what fits, and draw all four names at one size.

- Four columns when every name fits unscaled, else two columns (2 × 2), else one column with
  the gauge and the name side by side, for the accessibility sizes.
- `ViewThatFits` over three candidates is one way. Measuring the widest name against the
  available width is another. `AdaptiveRows.swift` and `FlowLayout` exist, but a flow that
  leaves three tiles on one row and one on the next is not acceptable.
- Remove `minimumScaleFactor` here, or keep it mild and equal for all four.
- Keep the identifiers (`quiz_level_<rawValue>`), the selected trait, and the selection
  feedback.
- Update the comment above `quizLevelPicker`, which explains why the levels are tiles.

### The sweep

After the three fixes, walk all five tabs and every screen one push deep on the 375-point
simulator at xxxLarge, in English and then Spanish, and look for an ellipsis. The Spanish level
names are Inicial, Elemental, Intermedio, and Avanzado. The other two `lineLimit(1)` sites with
a scale factor are `MasteryView.swift` (0.6) and the tile above. Segmented pickers ("All Verbs
/ My Verbs / Custom", "Spain / Latin America", "Frequency / Alphabetical") are worth a look in
Spanish. Fix what is the same kind of bug as 2, 3, or 5. List anything else in the journal for
Josh and do not fix it here.

### Done when

- At xxxLarge on 375 × 812, in both languages: every collection's title shows in full, as do
  "Internacionalizar" and a long reflexive verb, all four level names in the Quiz tile, and all
  four in Settings.
- At the default text size on the iPhone 17 simulator, the Quiz tab's tiles and Settings' Level
  picker look as they did before. Compare screenshots.
- At the largest accessibility size, nothing in these places truncates or overlaps.
- The iPad (`TARGET_SIM="Conjugar iPad Pro 11"`) shows the three converted screens and the Quiz
  tab correctly at default size.
- The deeplink landing on a marked form still works.
- The suite passes and SwiftLint is clean.
- `docs/project_structure.md` lists any new file, and `docs/feature_architecture.md` describes
  the shared title treatment where it describes the verb page.

### How it differed

- The simulator was created as planned; the 26.3 runtime accepted the iPhone 13 mini. AXe taps on it
  need coordinates times 0.96, and `axe type` attaches its hardware keyboard. CLAUDE.md says both.
- Settings got the wrapping title too: "Configuración" truncated at the largest accessibility size.
- The session's name moved into the content, as the fallback allowed, since it did not fit inline.
- The Quiz tile keeps no `minimumScaleFactor`. A `Menu`'s label ignores it, so it never worked
  there. At the default size on the iPhone 17, Intermediate takes the full-width row, which is a
  change from before, when it very likely truncated.
- The sweep found two system controls that truncate (the search placeholder, and tab bar labels at
  the largest size), listed in the journal and not fixed.

---

## Phase 3: The Letter Keys Cover the Answer Field (Bug 4)

### What the screenshots show

Measured from the screenshots, in points from the top of the 812-point screen:

| | Screenshot 4 (the bug) | Screenshot 5 (what Josh wants) |
|---|---|---|
| Navigation title | large, expanded | inline, collapsed |
| Answer field | 398 to 462 | 344 to 408 |
| Letter-key bar (á é í ó ú ü ñ) | 428 to 477 | 428 to 477 |
| Keyboard's top edge | 478 | 478 |

In screenshot 4 the bar covers the lower 34 points of the field, including its placeholder. The
scroll view has not moved: the large title is still fully expanded. In screenshot 5 the content
is 54 points higher, which is the height the title gave up when it collapsed, and the field
clears the bar by 20 points.

### What the code does

`QuizView.inProgress` is a `ScrollView` in a `ScrollViewReader`. On
`UIResponder.keyboardDidShowNotification` and on each new question it calls
`revealAnswerField`, which is `proxy.scrollTo(QuizView.answerFieldID)` with a nil anchor. A nil
anchor scrolls the least distance that makes the view visible and does nothing when the view
already counts as visible. The letter keys are a `ToolbarItem(placement: .keyboard)` on iPhone
(`!isLarge`). On an iPad they sit in the content under the field.

### The likely cause, to confirm first

The field's bottom edge (462) is above the keyboard's top edge (478) and below the bar's top
edge (428). So the numbers fit this explanation: **the scroll view's safe area ends at the
keyboard and does not include iOS 26's floating keyboard toolbar**, so the field counts as
visible and the reveal does nothing. The other candidate is timing: the reveal runs before the
safe area has taken the keyboard into account.

Reproduce on the 375 × 812 simulator at xxxLarge with the software keyboard: open the Quiz tab,
tap Start, and screenshot the first question. Then tell the two causes apart with temporary
logging, removed before finishing: the scroll view's bottom safe-area inset and the letter-key
row's global frame, both read with `onGeometryChange`, printed when the keyboard has shown. If
the inset ends at the keyboard's top, it is the first cause. If the inset includes the bar and
the field is still covered, it is timing.

The same flaw probably affects the two other reveals, which use `anchor: .bottom`: the second
attempt's line and the correction's Continue button would land under the bar. Check both during
the reproduction.

### Fix, in order of preference

1. **Tell the scroll view about the bar.** While the keyboard is up on a compact width, give
   the `ScrollView` a bottom `safeAreaPadding` (or `contentMargins(.bottom, _, for:
   .scrollContent)`, whichever `scrollTo` respects) equal to the bar's height plus a small gap.
   Then all three reveals work unchanged, and the learner can also scroll the last content
   above the bar by hand. Take the height from the bar's measured frame if `onGeometryChange`
   reports it reliably from inside a keyboard toolbar item. If it does not, use a constant
   defined beside `SpanishLetterKeyRow.keySide`, since the row's height is the 44-point key
   plus the toolbar's own padding. Screenshot 4 puts the whole bar at about 50 points.
2. **If the cause is timing**, run the reveal again after the layout settles: on a change of
   the bar's frame or of the scroll view's bottom inset, not after a fixed delay.
3. **Last resort: take the keys out of the keyboard toolbar** and draw them with
   `.safeAreaInset(edge: .bottom)` on the scroll view, which makes them part of the layout the
   scroll view knows. This changes how the bar looks on iOS 26, so ask Josh before doing it.

Whichever is used, keep `.scrollDismissesKeyboard(.never)`, keep the reveal animated
(`.snappy`, or no animation under Reduce Motion, which `revealAnswerField` does not check
today), and leave the iPad's layout alone.

Phase 2 makes the in-progress title inline, which by itself would have hidden this bug in
screenshot 4. Do not rely on it. A three-line tense name, the "Asked again" pill, a sentence
question, or a larger text size pushes the field down again. Test with the large title if
Phase 2 has not run.

### Done when

On 375 × 812 with the software keyboard, at xxxLarge and at accessibility-large, in both
languages:

- A freshly started quiz shows the whole field, border included, above the letter keys with a
  visible gap, without the learner scrolling.
- The same holds after each new question, including one whose tense name wraps to three lines
  ("pluscuamperfecto de subjuntivo 2") and a re-asked question with its pill.
- A second attempt's line and a correction's Continue button are fully visible above the bar.
- Complete the Sentence, Name the Form, and Verb Essentials each show their field above the bar.
- At the default text size on the iPhone 17 simulator nothing scrolls that did not before.
- The iPad still has its keys under the field.
- The suite passes and SwiftLint is clean.
- `docs/feature_architecture.md` says, where it describes the quiz's answer field, how the
  field stays clear of the letter keys. Update the doc comment on `inProgress` and on
  `revealAnswerField` to match.

### How it differed

The first cause held: the safe area ended 32 points inside the keys. Fix 1 was used, with the
overlap measured rather than a constant, gated on the keyboard being shown, and measured on the
`ScrollViewReader` to avoid a feedback loop. A correction's Continue was being scrolled back under
the keyboard by the keyboard's own reveal, which `revealWhatComesNext` fixes. Not checked: a
re-ask with its pill, a three-line tense name, and the three exercises.

---

## Not in This Plan

- Names for Participio, Gerundio, Raíz Futura, and Perífrasis Verbales (D5).
- The widget extension. It has its own copies of some render helpers, but none of these five
  bugs is in it.
- App Store screenshots. The verb page looks different after Phase 1, and the screenshots are
  retaken at release in any case.
