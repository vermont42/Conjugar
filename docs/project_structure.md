# Project Structure

```
Conjugar/
├── Info.plist                  # App configuration (conjugar:// URL scheme, iPad orientations, TelemetryDeckAppID)
├── Conjugar.entitlements       # App entitlements (App Groups for widget sharing, Game Center)
├── PrivacyInfo.xcprivacy       # Privacy manifest for App Store submission
├── GameCenterResources.gamekit/ # Xcode's local Game Center configuration: the live leaderboard, one per quiz level, and the eight achievements with their art
├── Secrets.example.xcconfig    # Template for Secrets.xcconfig (TELEMETRY_DECK_APP_ID)
├── flamencoLoop.mp3            # Music.gameLoop — Pond5 "Flamenco Adventure" (legacy filename); the one music file NOT in Audio/
├── *.mp3                       # Legacy one-shot SFX at the target root (applause1-3, buzz, chime, chirp, chomp, gun,
│                               #   moo, pop, sadTrombone1-4, shieldActivate, silence, soccerKick) — see Models/Sound.swift
├── Analytics/
│   ├── Analytics.swift         # Analytics protocol + AnalyticsName / ParameterKey enums, and every parameter value:
│   │                           #   AnalyticsSource, SearchOutcome, SearchMatchKind, VerbPageSection, AnalyticsBand; nonisolated throughout
│   ├── AnalyticsReal.swift     # TelemetryDeck conformer; funnels every SDK call onto a serial GCD queue
│   └── AnalyticsSpy.swift      # Test spy recording signalNames / signalParameters
├── Assets.xcassets/
│   ├── *.colorset/             # Adaptive palette: customBackground/Blue/CardBackground/CardBorder/Foreground/Green/Red/Yellow
│   ├── bull|dancer|ole.symbolset/  # Custom SF Symbols (tab bar, onboarding, boss-fight olé glyph); see scripts/make_symbols.py
│   ├── LaunchDancer.imageset/  # The launch screen's artwork, referenced by name from LaunchScreen.storyboard.
│                               #   Derived from DancerIcon-dark (the launch background is hardcoded black, so the
│                               #   dark variant blends). NOT named `Dancer`: the generated asset symbol would
│                               #   lowercase to `dancer` and collide with the `dancer` symbolset (a build warning)
│   ├── *Icon.appiconset/       # App icons: DancerIcon (primary), BullIcon, MatadorIcon, ClassicIcon
│   ├── *IconPreview.imageset/  # Tappable thumbnails for the Settings icon picker (icons aren't loadable by name)
│   └── Game/                   # Cel-shaded sprite flipbooks: dancer_<action>_N, bull_<action>_N, matador, cape_pickup;
│                               #   plus endScene_toreros / endScene_familia, the end-scene slideshow's two 3504x2336
│                               #   JPEG portraits (generated with gpt-image; recipe in plans/end_scene.md)
├── Audio/                      # Synchronized-folder audio group: boss-fight + power-up SFX (castanetHigh/Low, palmas,
│                               #   crowdOle, stompThud, tensionSting, capeWhoosh, brainLockOn, coin, snort, guitarStrum,
│                               #   speedWhoosh, zombieGroan, stampede, lightsOut, neigh, ole, castanetPortrait) plus spanishTension.mp3 (Music.onboarding)
│                               #   and spanishGuitarStandoff.mp3 (Music.bossFight)
├── Base.lproj/
│   └── LaunchScreen.storyboard # Launch screen
├── es.lproj/
│   └── LaunchScreen.strings    # Spanish launch-screen strings (the only surviving legacy .strings file)
├── Models/
│   ├── verbModelMap.xml        # The verb→model map: 4,811 verbs → class number(s), gloss(es), reflexive flag,
│   │                           #   frequency counts (hi/gb/hp — see frequency/README.md; the rank is derived, not stored)
│   ├── Etymologies.json        # Bundled verb etymologies keyed language → infinitive
│   ├── ChoiceQuestions.json    # The default quiz's choices: one sentence in two tenses (the form in braces), the level from which each is
│   │                           #   asked, a region for today's-events items, a reason; written only through scripts/choice_questions.py
│   ├── ExampleUses.json        # Bundled modern-prose example sentences keyed by bare infinitive
│   ├── GapSentences.json       # Complete the Sentence's authored sentences (the answer in braces, tú written for tú or vos), written
│   │                           #   only through scripts/gap_sentences.py; `reviewed` gates release builds
│   ├── MedievalExamples.json   # Bundled Medieval-Spanish attestations keyed infinitive → array
│   │
│   │  ── the conjugation engine (all nonisolated + Sendable) ──
│   ├── Conjugator.swift        # Engine entry point: resolves a verb's model (VerbMap → ModelCatalog) and composes features; Orthography writes the 2010 Ortografía's unaccented monosyllables (rio, guie, fias)
│   ├── ConjugationFeature.swift  # The feature protocol (applies(to:) + apply(stem:ending:tense:)) and the `Slot` vocabulary
│   ├── ConjugatorError.swift   # Errors from the conjugation engine
│   ├── ModelCatalog.swift      # Class number ("1", "4B-1", "31-1", …) → VerbModel (base + ordered features)
│   ├── VerbModel.swift         # One regular base root plus an ordered feature list; also the alternate-paradigm scheme
│   ├── VerbMap.swift           # VerbMapEntry + the load-once @unchecked Sendable cache over verbModelMap.xml.
│   │                           #   ranked(_:) derives the dense 1…4,811 frequency rank from the stored counts at parse time,
│   │                           #   and entriesByFrequency, which a band is a prefix of; VerbMapEntry.isIrregular, the one definition
│   ├── VerbDestination.swift   # A verb page to push: infinitive, analytics source, and the cells to mark; every stack registers it in verbPageDestinations()
│   ├── VerbVisit.swift         # VerbVisit: one stretch of a verb page on screen (viewVerbView/leaveVerbView, deepest section, dwell)
│   ├── VerbVisitTracker.swift  # When a verb page's visits begin and end (screen, foreground, a sheet over the page) and
│   │                           #   what they reach, the landing scroll to a marked form reaching nothing; VerbView sends its events
│   ├── VerbPageForms.swift     # A verb page's forms: the header's three, ConjugationSection and ConjugationDisplayRow per tense,
│   │                           #   the marked card, and hasRedLetters (the verb's own, compound auxiliaries aside)
│   ├── SearchReport.swift      # SearchTracker (one search, first letter to its end) and SearchReport (finishSearch's banded
│   │                           #   parameters); MatchKind.analyticsValue
│   ├── SpellingComparison.swift # fold and the one edit distance (optional limit), shared by the verb search and the quiz
│   ├── VerbSearch.swift        # The one verb-search rule: -se stripping, every gloss, forms (via FormLookup), MatchKind
│   │                           #   ranking by kind then frequency; guess(for:) for a failed search, from an infinitive or a form
│   ├── FormLookup.swift        # Reverse lookup: which verbs' forms a query is (fue, hablo→habló, dímelo, he hablado, hecha),
│   │                           #   as MatchedForms that name their cells ("fue: Pretérito (él)")
│   ├── ConjugationIndex.swift  # The conjugation map indexed by folded spelling and by first letter + length (for the guess)
│   ├── RegularRoot.swift       # The three regular roots (cantar/comer/subir) plus the voseo supplement
│   ├── EngineTense.swift       # Engine-side tense model — the ten simple / non-finite tenses only
│   ├── EnginePersonNumber.swift  # Engine-side person model — six standard persons plus vos
│   ├── AccentFeature.swift     # AccentStem: written accent on the stem's last i/u in the stressed slots (envío, actúo, aíslo)
│   ├── DiaeresisFeature.swift  # DiaeresisDropBeforeY: argüir's güy → guy (arguyo) while plain güi keeps the diaeresis
│   ├── FutureFeature.swift     # Irregular future/conditional as an ending rewrite over FU{all} + CO{all}
│   ├── OrthographicFeature.swift  # Spelling-only changes: stem-final consonant swaps (c↔qu, g↔gu, z↔c…), IYHiatus, AbsorbIAfterPalatal
│   ├── PreteriteFeature.swift  # Strong / suppletive preterites (endings only), which also drive the imperfect subjunctives
│   ├── ResidueFeature.swift    # Per-verb residue: LiteralSlotOverride, IrregularParticiple, ApocopatedImperative,
│   │                           #   DefectiveFeature, RunningStemConsonantSwap, CollapseDoubleI
│   ├── StemFeature.swift       # Rebuilds the stem from the regular base in a slot set (irregular 1s + present subjunctive)
│   ├── StemVowelFeature.swift  # Stem-vowel diphthongs (STR) and -ir weak-slot raising (WK) as one parameterized operation
│   ├── IrregularityMarker.swift  # Recreates the legacy UPPERCASE irregular-span encoding by diffing form vs. regular composition
│   ├── CompoundTense.swift     # Composes the nine compound (perfect) tenses as haber + participle, outside the engine
│   ├── TenseBridge.swift       # The seam: DisplayTense/DisplayPersonNumber → EngineTense/EnginePersonNumber (+ compounds, negative imperative);
│   │                           #   `pronoun: .written` adds a reflexive-only verb's pronoun
│   ├── ReflexivePronoun.swift  # A reflexive-only verb as Spanish writes it: proclitic (me arrepiento), enclitic with the
│   │                           #   enclisis accent (arrepiéntete, arrepintámonos), citation form (arrepentirse)
│   ├── DisplayTense.swift      # The UI's tense vocabulary, including the compounds
│   ├── DisplayPersonNumber.swift  # The UI's person vocabulary with localized pronouns
│   ├── AuxiliaryError.swift    # Error type for auxiliary-verb lookup failures
│   ├── ConjugationMap.swift    # ConjugationCell (a tense + person) and the conjugation map: every one-word form → its verbs
│   │                           #   and cells. ConjugationMapTool writes it into the bundle at build time (delta lines, LZFSE)
│   ├── ConjugationMatch.swift  # Which cells of a verb a text is (hablo → presente yo), exact or accents folded, compounds
│   │                           #   included; for the quiz's slip-or-error check. Conjugates directly, not through the map
│   ├── ConjugationTable.swift  # The verb page's cards: their order (by corpus frequency, docs/tense_frequency.md), each
│   │                           #   tense's second names (preterite · pretérito perfecto simple), and its Info article
│   ├── KeyConjugation.swift    # A verb's four key conjugations, unlabeled (tengo · tuve · tendré · tenido), each with its
│   │                           #   cell, mixed case; and the verb page's share text built on them
│   ├── VerbLookup.swift        # What the Look Up a Verb shortcut says about a word ("tuve: Pretérito (yo) of tener") and
│   │                           #   the link it opens: the verb's page, marked, or the search. Built on VerbSearch
│   │
│   │  ── content ──
│   ├── ContentCaches.swift     # Pre-warms Etymology / ExampleData / MedievalData, the related verbs, and the Models tab's rows and collections off the main actor at launch
│   ├── Etymology.swift         # Load-once etymology lookup by infinitive (`~bold~` markup)
│   ├── Example.swift           # One modern-prose example: text, translation, source, token, line
│   ├── ExampleData.swift       # Load-once ExampleUses.json cache keyed by bare infinitive
│   ├── ExampleSource.swift     # Maps an Example.source filename onto a human-readable attribution
│   ├── MedievalExample.swift   # One Medieval-Spanish verse: work, ref, Old-Spanish line, translation
│   ├── MedievalData.swift      # Load-once MedievalExamples.json cache keyed by bare infinitive
│   ├── Info.swift              # Info article model: InfoSection + heading/body parsed into richTextBlocks
│   ├── ModelInfo.swift         # The Models tab's row model: class number, exemplar, verbs (by frequency, the one definition of a
│   │                           #   model's verbs), irregularity percent; row(for:) a verb
│   ├── RelatedVerbs.swift      # VerbRelations: each verb's base and root (detener → tener), and the verb page's related verbs;
│   │                           #   isCompound, the one definition of a prefixed compound
│   ├── FrequencyBand.swift     # The frequency bands, defined once: top 100, 300, 1,000; VerbMapEntry.isIn, VerbMap.entries(in:)
│   ├── VerbDraw.swift          # The verb of the day and every random verb: the top 1,000 weighted toward irregular and
│   │                           #   unprefixed verbs, My Verbs one draw in three
│   ├── CollectionProgress.swift  # How many of a collection's verbs have been looked up: the fraction, the sentence, the bar's value
│   ├── VerbCollection.swift    # The collections: the top 100, four irregular patterns (-go, strong preterite, irregular
│   │                           #   future and participle) derived from the engine, and every model; keys, membership
│   ├── VerbCollection+Text.swift  # A collection's title, description, symbol, examples line, share text, viewCollection;
│   │                           #   QuizScope.collection(_:title:)
│   │
│   │  ── quiz, settings vocabulary, services ──
│   ├── Quiz.swift              # @Observable quiz state: questions, closure-based timer, scoring, Live Activity hooks; start(scope:), the level's weighted draw through an injectable random source (randomSource:), the scoped draw, per-tense person rotation, the held correction (correction, continueAfterCorrection()), a slip's or a diagnosed error's second attempt (firstAttempt, firstAttemptDiagnosis, secondAttemptPrompt), re-asks, Ten More (continueSession()), the session's computed score and counts (firstRoundScore, questionReached), the record of a quiz in progress, a default round's one choice (drawRound, submitChoice, chosenOption), the Speed Round's answers, batches, and clock (processSpeedRoundAnswer, clockTicked(), speedRoundMiss, speedRoundItems()), DEBUG fixtures (screenshot, grading, frames, corrections, slips, diagnoses, essentials, recognition, sentences, choices, speedRound)
│   ├── QuizQuestion.swift      # One question (verb, tense, person, isReask; reasked()): its written answer, every accepted spelling (shownSpellings, acceptedAnswers), grade(_:), its frame, and answer(filling:)
│   ├── QuizCorrection.swift    # A wrong answer held on its question: its AnswerDifference, its AnswerDiagnosis, and whether the question will be asked again
│   ├── QuizClock.swift         # Setting enum: whether the quiz shows the time (hide, the default, or show)
│   ├── QuizAbandonment.swift   # The quizzes in progress, kept in the defaults so the next launch sends abandonQuiz for one the app was left during
│   ├── AnswerDifference.swift  # Which letters of a wrong answer and of the nearest right one differ, by an edit-distance alignment; QuizQuestion.difference(from:)
│   ├── AnswerFrame.swift       # The shape of an answer: the words around the blank (yo, (tú) ¡no … !, a reflexive me, or a sentence's words) and the answer a filled blank gives; a sentence's word-by-word tokens
│   ├── QuizLevel.swift         # The four levels (beginner … advanced): each one's tenses (pool, QuizPoolEntry with the persons it leaves out and its weight), frequency band, name, gauge symbol, and the old difficulty each migrates from
│   ├── QuizDraw.swift          # The default quiz's verbs: the level's frequency band (or a custom quiz's), half the questions in an irregular cell (judged per cell,
│   │                           #   isIrregular(_:in:)), the core verbs, one to three rare prefixed compounds, regular endings in turn
│   ├── QuizDueItems.swift      # The default quiz's due items: up to three a round from the practice record, within the level and band, mixed in at random;
│   │                           #   recordQuestions, the draw it shares with the record sessions
│   ├── QuizRecordSession.swift # Review and Practice My Mistakes: each one's items from the record, QuizScope.recordSession, and its rounds' questions
│   │                           #   (beyond the level's tenses and band, a verb's key conjugations together), QuizDraw.canAsk
│   ├── PracticeItemMapping.swift  # Which practice item a question exercises (an irregular cell's key conjugation, a regular cell's pattern), the key
│   │                           #   conjugations a lookup schedules, the irregular cells a review asks, the record's tense keys
│   ├── PracticeStore.swift     # Current.practice: the practice record's answers, lookups, due and missed items, the review card's offer, reveal,
│   │                           #   and snooze, the last quiz's results, the Speed Round's best, each level's best ranked score, the daily streak, Reset Practice, and the migration of LearnerVerbs' old review schedules
│   ├── SpeedRound.swift        # The Speed Round: its constants, the mastered items it may ask, QuizScope.speedRound, and QuizDraw.speedRoundQuestions
│   │                           #   (each item in turn, never twice running) with speedRoundCells (the irregular cells a mastered key conjugation asks)
│   ├── DailyChallenge.swift    # The daily challenge: its key (day, level, region) and seed, the draw every device makes, the result and its shared text, QuizScope.challenge, and the link's request
│   ├── DailySession.swift      # The daily session: QuizScope.daily, the streak's bands, and what the hub's row and the results say
│   ├── DailyStreak.swift       # The daily session's streak: finished sessions by calendar day, its status, and the repair of one missed day
│   ├── DailyReminder.swift     # The Daily Reminder setting, DailyReminderPlan (14 days of worded reminders), and its rescheduling
│   ├── VerbEssentials.swift    # Verb Essentials: QuizScope.verbEssentials, five irregular verbs of the band (one prefixed compound at most) asked their
│   │                           #   key conjugations as one step each; Quiz.essentialsRows, currentStepRange, and reaskPlacement (a missed blank after the next verb)
│   ├── ModelPractice.swift     # Verb Models: ModelPracticeGroup (a model's ten most frequent verbs with an irregular key conjugation, its items, known at half
│   │                           #   past the first box), ModelPracticeSession (alone or mixed), QuizScope.modelPractice, and the draws (three own verbs and two of known models)
│   ├── Recognition.swift       # Name the Form: QuizScope.recognition, RecognitionQuestion (a prompt, every cell of every verb that writes it, the level's
│   │                           #   tenses and persons), grading by part (infinitive, tense, person) and the lines to check, RecognitionMood's chip groups
│   ├── GapSentence.swift       # Complete the Sentence: QuizScope.sentences, GapSentence (its frame, with a command's "no" split out and
│   │                           #   tú or vos named), GapSentences (load, drafts in debug, askable at a level), QuizDraw.sentences, the
│   │                           #   either-imperfect-subjunctive rule, QuizQuestion.completedSentence (and its parts)
│   ├── ChoiceQuestion.swift    # The default round's choice of tense: ChoiceQuestion (two GapSentences, a level, an optional ChoiceRegion, a
│   │                           #   ChoiceReason and its line), ChoicePrompt (the order and the learner's tú or vos), ChoiceQuestions (load, askable
│   │                           #   at a level in a region), QuizDraw.choice and choicePosition (never first)
│   ├── Achievement.swift       # The eight Game Center achievements: permanent IDs, points, each one's progress in the practice record as the
│   │                           #   Mastery page counts it (a level's patterns, or core verbs fully mastered at Advanced), and the report to Game Center
│   ├── Mastery.swift           # The Mastery page's model: MasteryState (mastered at the third box, learning, not yet practiced), each level's
│   │                           #   regular patterns as endings-by-persons grids, the 50 most frequent irregular verbs' key conjugations the level asks, counts
│   ├── LastQuizResult.swift    # The last round's results that the Quiz tab's hub shows: a kind and subject (not a title), level, counts, score, date
│   ├── QuizScope.swift         # What a quiz asks about: every verb, My Verbs, Test Me's one verb, a collection, a custom choice, or a practice set; its Kind (one case per quiz the app starts, a record session's, a model practice's, and a challenge's details as payloads, and runsInSheet), question count (a round of ten, or Test Me's three), source, title, a practice set's or challenge's level, the old mode flags as readers of the kind, isRanked (the allVerbs kind only), mixesChoiceQuestions, sendsQuestionCounts, shufflesQuestions, continues, startsLiveActivity, showsVerbLink, pool(level:), band(level:)
│   ├── CustomQuiz.swift        # The Quiz tab's Custom choice: chosen tenses and a QuizVerbSet (all, a band, a collection, a shared list of infinitives, My Verbs), each the level's when unchosen; stored as tenses=…&verbs=… (or infinitives=…); QuizScope.custom
│   ├── PracticeSet.swift       # A custom quiz shared as a link or a QR code: the conjugar://quiz/set link both ways, My Verbs shared as a list (at most 100), the level that travels, the scope its quiz asks, the share text; PracticeSetRequest
│   ├── QuizState.swift         # notStarted / inProgress / finished
│   ├── ConjugationResult.swift # What an answered question earned: totalMatch (10) / secondAttemptMatch (5) / noMatch
│   ├── AnswerSlip.swift        # Whether a wrong answer is a slip that earns one more attempt (accents only, or one edit in four letters or more), and never another cell of the verb; QuizQuestion.isSlip(_:)
│   ├── AnswerDiagnosis.swift   # The one line that names a wrong answer's error, from exact constructions over the verb's model (a negative command, a spelling or stem change left out, the regular form, another cell); QuizQuestion.diagnosis(of:)
│   ├── AnswerSpelling.swift    # How the quiz reads an answer: case, spacing, and a leading subject pronoun of the asked person
│   ├── StandardVariants.swift  # The RAE's standard doublets of a cell (frito, satisface, adecúo, vos hablés…), accepted by the quiz only
│   ├── InfoDifficulty.swift    # The Info filter's enum: easy / moderate / difficult, shown as Essential / Common / All (the quiz asks by QuizLevel)
│   ├── Region.swift            # Setting enum: Spain vs. Latin America (TTS accent, and no vosotros questions in Latin America)
│   ├── SecondSingularBrowse.swift  # Setting enum: which 2s form(s) the browse screens show
│   ├── SecondSingularQuiz.swift    # Setting enum: which 2s form the quiz asks for
│   ├── ReviewCardSuppression.swift # Setting enum: whether the verb list hides the review card (off / on)
│   ├── ListSort.swift          # PickerOption (a SortPicker's choices) and ListSort (an order for a list's items, with sortedLists(of:), every order sorted once)
│   ├── VerbSort.swift          # Verb-list sort order (frequency / alphabetical) + the Spanish collation locale; mapLists, the whole
│   │                           #   map in each order, which sortedLists(ofMapEntries:) filters for a long list
│   ├── VerbListMode.swift      # The Verbs tab picker's three segments: the two sorts and My Verbs
│   ├── LearnerVerbStore.swift  # Current.learnerVerbs: records opens and stars in LearnerVerbs and saves to the App Group
│   ├── ModelSort.swift         # Model-list sort order (irregularity / alphabetical / class number)
│   ├── ModelSearch.swift       # The Models tab's search: models by folded exemplar or class number, a space alone no search, the trombone only when the text changes
│   ├── VerbBrowseSearch.swift  # The Verbs tab's @Observable search model: text, ranked result rows, guess, SearchTracker, keyboard selection;
│   │                           #   decides what shows (recents, My Verbs, results, every verb), what Return opens, each open's report, letters in order
│   ├── VerbBrowseReviewCard.swift  # The Verbs tab's @Observable review card: its verb, chosen once per opening, Suppress Review Card, the reveal and the
│   │                           #   snooze it records, and its two signals, sent once each; ReviewCardHost draws it
│   ├── VerbType.swift          # verbModelMap `vt` marker: irregular / regular -ar / -er / -ir
│   ├── AppIcon.swift           # Alternate app-icon enum (bull / dancer / matador / classic) + preview asset names
│   ├── ConjugarTips.swift      # TipKit tips (try the quiz, explore models, choose a level, enable Game Center; on the
│   │                           #   verb page, red letters and keep scrolling, each only on a page it has something to point at)
│   ├── Sound.swift             # One-shot SFX vocabulary; CaseIterable so SoundPlayerReal can pre-decode off-main
│   ├── Music.swift             # Looping background tracks (gameLoop / onboarding / bossFight)
│   ├── Haptic.swift            # Tactile-feedback vocabulary played through Current.hapticPlayer
│   ├── LanguageModelService.swift      # Tutor service seam + TutorMessage + LanguageModelUnavailability
│   ├── LanguageModelServiceDummy.swift # Always-unavailable double for the test/UI-test worlds
│   ├── LanguageModelServiceReal.swift  # On-device SystemLanguageModel tutor + ConjugationTool (grounded in the app's engine)
│   ├── TutorChatHistory.swift  # JSON-encodes [TutorMessage] through GetterSetter so chats survive relaunch
│   ├── World.swift             # The DI container and `Current` global; chooseWorld() picks device/simulator/unitTest/uiTest
│   └── Game/
│       ├── GameModels.swift            # Entity structs/enums: Platform, Ladder, Obstacle, ObstacleStyle, HeartMissile, HitParticle, …
│       ├── GameState.swift             # @Observable core loop: phases, player/bull state, HUD, audio, debug env vars
│       ├── GameState+Animation.swift   # Per-action frame counts and flipbook index math for both actors
│       ├── GameState+BossFight.swift   # La Llamada: the call-and-response dance-off, Duende meter, victory, end scene
│       ├── GameState+Mechanics.swift   # Challenge mechanics (zombie / encierro / apagón) and their shuffle-bag scheduler
│       ├── GameState+Obstacles.swift   # Per-stage rolling obstacle sets and spawning
│       ├── GameState+Physics.swift     # Horizontal move, gravity + platform snap, ladders, jump, "reached the bull"
│       ├── GameState+PowerUps.swift    # Power-ups (cape / speed / serenata) and their shared 7 s envelope
│       ├── GameState+Slideshow.swift   # End-scene slideshow: live → Los toreros → La familia iris-wipe cycle, Ken Burns camera, caption boldness
│       └── GameState+Stages.swift      # The five stages, escape beats, stage advance, and soft respawn
├── Supporting/                 # A PBXFileSystemSynchronizedRootGroup — files dropped here need no pbxproj edit
│   ├── AppDelegate.swift       # UIApplicationDelegateAdaptor for the hooks the App lifecycle doesn't cover (appearance config, installing the quick action, naming its scene delegate)
│   ├── ConjugarShortcuts.swift # The AppShortcutsProvider: Look Up a Verb, Start a Quiz, Random Verb (English phrases)
│   ├── ConjugarApp.swift       # @main App: analytics init, TipKit configure, cache warm, holds AppRouter.shared, WindowGroup → MainTabView, VerbSearchCommands
│   ├── L.swift                 # Type-safe scoped localization accessors backed by String(localized:)
│   ├── Localizable.xcstrings   # The one string catalog holding both en and es
│   ├── LookUpVerbIntent.swift  # The Look Up a Verb intent, and the hidden OpenLookupResultIntent that opens its answer
│   ├── QuickAction.swift       # The Find a Verb Home Screen quick action (conjugar://search?source=quickAction) and QuickActionSceneDelegate, which receives it
│   ├── VerbEntity.swift        # A verb as App Intents and Spotlight see it (AppEntity + IndexedEntity) and its string query
│   └── VerbSpotlight.swift     # One Spotlight entry per verb in the named index "verbs": forms and glosses as keywords,
│                               #   key conjugations as the description; indexed when the build or the verb count changes
├── Utils/
│   ├── Colors.swift            # Semantic palette bridging the colorsets to UIKit-facing call sites
│   ├── Emailer.swift           # MFMailComposeViewController wrapper for the Settings feedback link (address from URL.developerEmail)
│   ├── FontExtensions.swift    # Font.button and Font.heroNumeral
│   ├── GameCenter.swift        # Protocol for Game Center operations (fire-and-forget auth, observable isAuthenticated, scores, achievement progress); each level's leaderboard ID
│   ├── GameCenterFake.swift    # In-memory double for the test/simulator worlds
│   ├── GameCenterReal.swift    # GKLocalPlayer authentication, score submission to a level's board, leaderboard and achievement presentation, achievement progress held until a sign-in loads and sent only when risen
│   ├── GameCenterSpy.swift     # Test double recording each score submitted, leaderboard shown, and achievement report
│   ├── GetterSetter.swift      # Protocol for string key-value storage, and the backup of a stored string that fails to decode
│   ├── GetterSetterFake.swift  # In-memory dictionary implementation for tests
│   ├── GetterSetterReal.swift  # UserDefaults implementation (the standard defaults, or the App Group's for LearnerVerbs)
│   ├── GlyphWarmer.swift       # Pre-rasterizes emoji glyphs so the game's first flag emoji doesn't stall the render thread
│   ├── GradientDivider.swift   # Hairline separator that fades to transparent, for splitting sections inside a card()
│   ├── HapticPlayer.swift      # The haptics seam, protocol-injected like SoundPlayer
│   ├── HapticPlayerDummy.swift # No-op so the test worlds never touch the Taptic Engine
│   ├── HapticPlayerReal.swift  # UIKit feedback generators, held and re-prepare()d for low latency
│   ├── FlowLayout.swift        # A Layout that wraps its children into rows (the related-verb chips, the Quiz tab's My Verbs chips, centered; a sentence's words, centered vertically)
│   ├── IntExtension.swift      # Int.timeString — elapsed seconds as h:mm:ss
│   ├── KillSwitches.swift      # Compile-time screenshot kill switches: TipDisplay, OnboardingDisplay, TutorDisplay
│   ├── Layout.swift            # Spacing/geometry constants (8/16/24 pt, readingWidth 680, cornerRadius 12)
│   ├── LiveActivities.swift    # Protocol: start / update / end the quiz Live Activity, driven from Quiz.swift via Current
│   ├── LiveActivitiesReal.swift  # The ActivityKit conformer (device and the simulator World)
│   ├── LiveActivitiesSpy.swift   # Counts starts, updates, and ends under unit and UI tests
│   ├── ReminderScheduler.swift      # Protocol: ask notification permission and schedule the daily reminders
│   ├── ReminderSchedulerReal.swift  # The UserNotifications conformer, each reminder carrying conjugar://quiz/daily?source=reminder
│   ├── ReminderSchedulerSpy.swift   # Records the reminders scheduled, and grants or refuses permission, under unit and UI tests
│   ├── ReminderNotificationDelegate.swift  # Opens a tapped reminder's link through AppRouter; shows nothing while the app is open
│   ├── Modifiers.swift         # The design system: card(), metadataPill(), linguistic(), numeric(), speakOnTapFlash(),
│   │                           #   copyOnLongPress() (a Copy context menu and VoiceOver action), serifTitle(), Color.zebraStripe and listRow, PrimaryButtonStyle
│   ├── QRCode.swift            # A QR code made on the device with Core Image, black on white, for a practice set
│   ├── RatingsFetcher.swift    # Fetches App Store ratings from the iTunes API for the Settings screen
│   ├── ReviewPrompter.swift    # Protocol for review-prompting behavior
│   ├── ReviewPrompterReal.swift   # SKStoreReviewController prompting at usage intervals
│   ├── ReviewPrompterStub.swift   # Canned no-op for tests
│   ├── SpanishText.swift       # AttributedString(spanish:) and Text(spanish:): text that VoiceOver reads in a Spanish voice
│   ├── RichText.swift          # Parses Info markup (^…^ ~…~ $…$ %…%) into RichTextBlock / TextSegment
│   ├── Settings.swift          # @Observable user preferences over GetterSetter
│   ├── ShareSheet.swift        # Workaround for ShareLink: presents UIActivityViewController from a plain button, with an
│   │                           #   LPLinkMetadata header and Copy kept; on iPad anchored to the named bar button or a given rect
│   ├── SoundPlayer.swift       # Protocol for one-shot SFX and looping music
│   ├── SoundPlayerDummy.swift  # No-op so the test worlds never touch CoreAudio
│   ├── SoundPlayerReal.swift   # AVAudioPlayer implementation: off-main warm-up, per-sound debounce, music fades
│   ├── UIApplicationExtensions.swift  # topViewController / key-window helpers for the remaining UIKit presentations
│   ├── URLExtension.swift      # The conjugar:// deeplink grammar's constants, parsers (deeplinkTarget, deeplinkQueryValue, analyticsSource), and builders (verbDeeplink, searchDeeplink, infoDeeplink); URL.developerEmail and URL.mailto for the failed search's request line; URL.appStore, with no storefront
│   ├── URLProtocolStub.swift   # URLProtocol subclass for stubbing HTTP responses in tests
│   ├── URLSessionExtension.swift  # Stubbed URLSession for testing
│   ├── Utterer.swift           # AVSpeechSynthesizer text-to-speech plus the single .ambient audio-session owner
│   ├── VerbSearchArrowKeys.swift  # Hack: priority UIKeyCommands for ↑/↓ through verb results while the search field is focused
│   ├── ViewControllerTransitions.swift  # Hack: waits for UIKit transitions to end: an iPad letter key, a push as the search ends, focus after a pop
│   └── WidgetSnapshotWriter.swift  # Picks the daily verb (VerbDraw, with My Verbs in turn) + the quiz widget's question (the first of
│                                   #   the day's challenge, with wrong answers of its shape) for today and six days ahead, and writes the
│                                   #   week as JSON to the App Group on a new day, a change to My Verbs, or a new level, region, or tú or vos
└── Views/
    ├── AnswerFrameView.swift   # An AnswerFrame drawn on one line around the quiz's answer field, or a sentence wrapped word by word around it; VoiceOver reads the frame as the field's label
    ├── AppRouter.swift         # Tab selection + conjugar:// deeplink routing (verb with match, search, info, list, quiz, game), the one-shot requests the tabs consume (pendingVerb, pendingSearch, pendingInfo, pendingCollection, pendingQuizStart with its link's source, pendingPracticeSet from quiz/set and presentablePracticeSet, which waits out a cover, game/onboarding/tutor flags), openSearch for Command-F, the control, and the quick action; SearchRequest, CollectionRequest
    ├── AdaptiveRows.swift      # Items as striped rows over dividers (compact) or a grid of cards (regular), with a highlight and identifiers; every browse list uses it
    ├── BrowseLayout.swift      # Shared LazyVGrid column sets for the iPad (regular-width) layouts, the browse grids' padding, and the browse tabs' search placement (a drawer on iPad)
    ├── ConjugationText.swift   # Renders a conjugated form with its irregular span in customRed
    ├── EtymologyText.swift     # Renders etymology prose (its own minimal `~…~` parser, independent of Info markup)
    ├── FailedSearchHelp.swift  # Under "No verbs found": the guess, and the mail line whose address goes to the clipboard, with a note, when no email app opens
    ├── GameView.swift          # Toreo por Amor: the full-screen SwiftUI game (climb + boss fight + end scene and its slideshow)
    ├── InfoBrowseView.swift    # The Info topic list, incl. the tutor section and the tense difficulty filter
    ├── InfoView.swift          # Info-article detail; a tapped %…% term opens a URL or pushes another article
    ├── MainTabView.swift       # The app shell: a five-tab TabView, onboarding presentation, game full-screen cover
    ├── ModelBrowseView.swift   # The Collections section above a sortable, searchable list of every verb model with irregularity badges; consumes list links
    ├── ModelRowLabel.swift     # A model's row or card (exemplar, class number, percent pill) and ModelPalette, the pill's tint
    ├── ModelPracticeCard.swift # A model's practice card: Alone and Mixed, the known seal, why Mixed is closed, or a single-verb model's note; on each model's page and in the list
    ├── ModelPracticeListView.swift  # The Quiz hub's Verb Models list: the models practiced alone, the most used first, each with its key conjugations, expanding to its card
    ├── MasteryView.swift       # The Mastery page the Quiz hub pushes: a legend, a grid per tense of the regular patterns, and the irregular verbs' key conjugations, each marked; shows only
    ├── MyVerbsList.swift       # The verb list's My Verbs: Starred, then Recent with Clear, swipes to remove, the alerts that ask first, and the empty state
    ├── ModelView.swift         # Model detail: header pills, the pronoun-by-tense grid, the model's collection bar, its practice card, and the verbs using the model, by frequency or alphabetically
    ├── OnboardingView.swift    # The paged first-launch welcome tour (welcome, four content sheets, tutor, game preview)
    ├── QuizSheet.swift         # A quiz in a sheet with a Quiz of its own over a QuizScope: Test Me, a collection's Quiz, a model's practice, and a practice set's Start
    ├── QuizView.swift          # The Quiz tab's start screen, the practice hub (scope symbol, All Verbs / My Verbs / Custom picker, the questions, minutes, and level-menu tiles or the custom summary, chips, Start, the From Your Practice rows for Review, My Mistakes, Mastery, and Last Quiz, the Exercises rows for Verb Essentials, Verb Models, Name the Form, Complete the Sentence, and Speed Round, the level's personal best under Start, small View Leaderboard and View Achievements buttons) and gameplay: prompt, framed answer field, a Verb Essentials verb's rows around the field, Name the Form's prompt, chips, and Check, a sentence's English and Draft pill, a choice in the field's place with its region pill, held correction, a re-ask's pill, score, the time while the quiz clock shows it, Ten More; pushes a correction's links; a sheet mode for QuizSheet
    ├── CustomQuizView.swift    # The Custom segment's editor of tenses and verbs, its Models list, and the summary card on the start screen and a practice set's sheet
    ├── PracticeSetView.swift   # A shared practice set's sheet (Start, Keep as My Custom Quiz, "Practice Set Not Found") and its full-screen QR code
    ├── QuizCorrectionView.swift # A wrong answer's held correction: the two answers with their differing letters marked (a Name the Form answer's wrong parts, and
    │                           #   every right reading; a sentence completed), links to the verb's and model's pages, Continue; isBeneathQuiz
    ├── ChoiceQuestionView.swift # A choice question's two sentences (the form in bold yellow, its tense beneath), and once chosen the marks,
    │                           #   the English, the reason, and Continue
    ├── RecognitionChoicesView.swift # Name the Form's prompt (RecognitionPromptView) and its chips: the level's tenses under their moods, then the tense's persons
    ├── ReviewCardHost.swift    # The verb list's review card, if offered: VerbBrowseReviewCard drawn as a ReviewCardView, 560 points at most on iPad
    ├── ReviewCardView.swift    # The review card above the verb list: an irregular verb looked up days ago, its key conjugations hidden until tapped; one Button, the ✕ beside it
    ├── ResultsView.swift       # Quiz results for a given Quiz: the hero score numeral, the counts (re-asks among them), level/region/time pills (no level for a model's practice), Ten More (Five More Verbs, Another Round), a Speed Round's right answers, best, and Another Round, and each answer, with Example Use on each verb's first right row
    ├── RelatedVerbsView.swift  # The verb page's Related Verbs card: verbs built on the same base and others of the model, with an "All N" chip
    ├── RelatedVerbListView.swift  # Every verb built on one root (RelatedVerbListDestination), a SortableVerbList
    ├── RichTextView.swift      # Renders parsed [RichTextBlock] as native SwiftUI Text
    ├── SettingsView.swift      # Settings: pickers, app-icon picker, ratings, Game Center (Enable, or View Leaderboards and View Achievements once signed in), onboarding reshow, Play
    ├── TutorTestView.swift     # Batch tutor harness (~30 queries, ShareLink export); reached by triple-tapping the tutor title
    ├── TutorView.swift         # The conjugation-tutor chat screen
    ├── SpanishLetterKeyRow.swift  # á é í ó ú ü ñ keys with an insert closure; replaces the Verbs sort picker while search is focused
    ├── VerbCollectionView.swift  # A featured collection's page; VerbCollectionBar (progress, Quiz, Share; also on every model's page);
    │                           #   the Models tab's VerbCollectionRowLabel (a row, or a card on iPad) and CollectionProgressBar
    ├── VerbEssentialsRowView.swift  # A Verb Essentials row other than the field's: its tense, yo, and the answered form with how it went, a given form, or a
    │                           #   dashed blank to come; VerbEssentialsRowLabel
    ├── ListHeading.swift       # The small-caps line that names or counts a list (the Verbs and Models tabs, My Verbs, a model's and a collection's page)
    ├── SortPicker.swift        # The segmented order picker over any PickerOption, with its animation and selection haptic
    ├── SortableVerbList.swift  # A sort picker, an optional count heading, and a VerbEntryList: a model's page, a collection's page, the related list
    ├── VerbPageNavigation.swift  # VerbPagePush and its environment key, verbPageDestinations() (VerbDestination, ModelInfo, the related list), pushesVerbPages(onto:)
    ├── RowLabel.swift          # The one label of a verb's, model's, or collection's row or card (RowLabelStyle, set by AdaptiveRows); its title tagged Spanish
    ├── VerbRowLabel.swift      # A verb's row or card (VerbRowLabel), LookedUpCheck, and MatchLines
    ├── VerbEntryList.swift     # Verbs as AdaptiveRows that open a verb, optionally checking those looked up; a model's page, a collection's page, and the related list use it
    ├── VerbBrowseView.swift    # The Verbs tab: the navigation stack, VerbBrowseSearch's list or grid, the picker or letter row, the router's requests, and the focus and UIKit workarounds; hosts MyVerbsList, FailedSearchHelp, and ReviewCardHost; carries the browse_verb_count launch anchor (its rows are AdaptiveRows of VerbRowLabel)
    ├── VerbSearchCommands.swift  # Command-F as a top-level menu (Verbs › Find a Verb) that opens the verb search through AppRouter.openSearch
    └── VerbView.swift          # Verb detail: full conjugation paradigm, etymology, modern and medieval examples, related verbs; the pill opens the model; the star and Share in the navigation bar; sends viewVerbView/leaveVerbView as VerbVisitTracker says and records each open

ConjugarWidget/
├── AnswerQuizIntent.swift      # Interactive AppIntent behind the Quiz widget's answer buttons
├── Assets.xcassets/            # Widget-specific asset catalog (AccentColor, WidgetBackground)
├── ConjugarWidgetBundle.swift  # The extension's @main: every widget, control, and Live Activity it vends
├── FindVerbControl.swift       # Control Center / Lock Screen control that opens the verb search, empty and focused
├── Info.plist                  # Widget extension configuration
├── Localizable.xcstrings       # Widget-target string catalog (en/es), resolved against the widget bundle
├── QuickQuizControl.swift      # Control Center / Lock Screen control that starts a quiz
├── QuizLiveActivity.swift      # Lock Screen + Dynamic Island rendering of QuizActivityAttributes
├── QuizWidget.swift            # The interactive daily-quiz widget (tap to answer, flips to a result), a timeline entry per day
├── RandomVerbControl.swift     # Control Center / Lock Screen control that opens a random verb
├── SnapshotReader.swift        # Decodes the App-Group week (WidgetWeek); supplies the gallery placeholder
├── VerbOfTheDayWidget.swift    # "Verb of the Day" StaticConfiguration: a timeline entry per day of the week, each from its midnight
└── Views/
    ├── AccessoryWidgetView.swift    # Lock Screen accessory presentations
    ├── LargeWidgetView.swift        # systemLarge: header, non-finite forms, presente paradigm, example, etymology
    ├── MediumWidgetView.swift       # systemMedium: header plus the full presente paradigm in two columns
    ├── QuizWidgetView.swift         # The Quiz widget's unanswered / answered states (deterministic answer shuffle; a tap beside the answers opens the day's challenge)
    ├── SmallWidgetView.swift        # systemSmall: verb, gloss, first three present-tense forms
    ├── WidgetConjugationText.swift  # The widget's copy of the UPPERCASE-means-irregular render convention
    └── WidgetEtymologyText.swift    # The widget's standalone copy of the `~…~` etymology markup renderer

ConjugationMapTool/             # macOS command-line target, built for the host and run by the app's "Generate Conjugation
│                               #   Map" build phase. Compiles the engine files that project.pbxproj's membership
│                               #   exceptions on Models/ list, plus ConjugationMap.swift
├── main.swift                  # Writes ConjugationMap.lzfse into the app bundle (--map), and forms.json /
│                               #   forms_all.json for the corpus pipelines (via scripts/write_forms_json.sh)
└── CellsJSON.swift             # --cells-json: every form with its cells, for scripts/count_tenses.py

Shared/                         # Compiled into both the app and the widget extension
├── CalendarDay.swift           # A day as yyyy-MM-dd in the Gregorian calendar and the current time zone: the challenge's, the widgets' days
├── DeeplinkGrammar.swift       # The conjugar:// grammar's routes, targets, and query names, isDeeplink, deeplinkRoute, and the raw builder
├── LinkStashingIntent.swift    # The one perform() of the intents that open the app on a link: stash it and announce it
├── OpenQuizIntent.swift        # A LinkStashingIntent: the Quick Quiz control and the Start a Quiz shortcut (conjugar://quiz/start)
├── OpenRandomVerbIntent.swift  # Same, for a random verb, as Shortcuts and Siri run it (source=shortcut)
├── OpenRandomVerbControlIntent.swift  # The Random Verb control's own hidden copy of it (source=control)
├── OpenVerbSearchIntent.swift  # The Find a Verb control's hidden intent: stashes conjugar://search?source=control
├── PendingDeeplink.swift       # The dated stash in the App Group's defaults, its Darwin-notification announcement, and its one-minute expiry
├── QuizActivityAttributes.swift  # The ActivityKit contract shared by LiveActivitiesReal and QuizLiveActivity
├── LearnerVerbs.swift          # The learner's record: verbs opened (dates, count) and starred, as JSON in the App Group (the widget reads the snapshot, not this)
├── PracticeRecord.swift        # The practice record: PracticeItem (a key conjugation or a pattern, with permanent string keys) and each item's
│                               #   schedule, last answer, and last lookup, as JSON in the App Group; never sent
├── ReviewSchedule.swift        # The practice record's Leitner ladder (1, 3, 7, 14, 30 days): a box and a due date, moved by answers, lookups, and the review card
├── WidgetConstants.swift       # App Group id, snapshot filename, and the shared-defaults keys
├── WidgetDeeplink.swift        # The links the widgets and the Live Activity attach via .widgetURL(_:); here so that AppRouterTests can route them
├── WidgetL.swift               # Widget-target localization accessors mirroring L, with English defaultValues
└── WidgetSnapshot.swift        # The Codable payload the app precomputes and the widget renders: WidgetSnapshot (one day) and
                                #   WidgetWeek (seven days, the first at the top level, with the app's My Verbs bookkeeping)

ConjugarTests/
├── Info.plist
├── Analytics/
│   ├── AnalyticsTests.swift            # Signal names and parameters via AnalyticsSpy; pins the wire names
│   ├── LookupSignalsTests.swift        # finishSearch/viewVerbView/leaveVerbView: bands, the search's lifecycle, reports, visits, link sources, no echo of the query
│   └── VerbVisitTrackerTests.swift     # A page's visits across the screen, the foreground, a sheet, and the landing scroll
├── Models/
│   ├── ConjugatorTests.swift           # The main engine suite — regular and irregular verbs across all tenses
│   ├── ConjugatorAccessorsTests.swift  # The engine's convenience accessors
│   ├── ConjugatorResolverTests.swift   # Verb → model resolution, incl. prefixed compounds and the regular fallback
│   ├── VerbMapTests.swift              # verbModelMap.xml parsing and lookup
│   ├── VerbSearchTests.swift           # Search ranking (Josh's table of queries), -se stripping, every gloss of a homonym, the failed-search guess
│   ├── SpellingComparisonTests.swift   # Folding, the edit distance, and the limited distance agreeing with the unlimited one
│   ├── ConjugationTableTests.swift     # The verb page's order, second names, and articles; search names follow the page
│   ├── ReverseLookupTests.swift        # A form finds its verb: shared forms, accents, enclitics, compounds, vos, participle endings,
│   │                                   #   the row's names, the guess from a form, every example's token through search
│   ├── VerbLookupTests.swift           # Look Up a Verb: each kind of answer and its wording, page or search, a lookup link's marks
│   ├── VerbSpotlightTests.swift        # Spotlight entries: gloss phrases, forms as keywords, key conjugations, the activity identifier,
│   │                                   #   and the version stamp that skips or re-indexes
│   ├── PendingDeeplinkTests.swift      # The intents' stash: drained once, good for a minute, an undated one dropped
│   ├── VerbMapRankingTests.swift       # Rank derivation on a fixture, the shipped map's invariants, and
│   │                                   #   line-for-line agreement with docs/frequencies.txt
│   ├── TenseBridgeTests.swift          # DisplayTense/DisplayPersonNumber → engine mapping, compounds, negative imperative
│   ├── ReflexivePronounTests.swift     # Reflexive-only verbs: arrepentirse in every slot, every rx verb's pronoun placement,
│   │                                   #   the enclisis accent rule, a golden table of joined forms by verb shape, citation-form search,
│   │                                   #   and quiz grading with and without the pronoun
│   ├── DisplayTenseTests.swift         # The UI tense vocabulary
│   ├── DisplayPersonNumberTests.swift  # The UI person vocabulary and its pronouns
│   ├── ModelInfoTests.swift            # Models-tab row construction and irregularity percent
│   ├── ModelSortTests.swift            # Model-list sort orders
│   ├── ModelSearchTests.swift          # The Models tab's search: folding, class numbers, a space alone, when the trombone plays
│   ├── RelatedVerbsTests.swift         # Bases and roots (tener, decir, formar), the class and prefix rules, false compounds,
│   │                                   #   pairs false by etymology, model relatives one per root by frequency, the "All N" chips, and the pill's model row
│   ├── VerbPageFormsTests.swift        # The verb page's forms by chosen person and marks; which verbs have red letters; the scroll tip's target
│   ├── KeyConjugationTests.swift       # The four key conjugations (regular, stem-changing, irregular, reflexive, defective),
│   │                                   #   the share text, URL.appStore, and what a long press copies
│   ├── VerbSortTests.swift             # Verb-list sort orders, Spanish collation, and sortedLists(of:)
│   ├── LearnerVerbsTests.swift         # The learner's record (opens, stars, recents, Clear, Remove, Reset Practice's forget, older JSON), its store and its backup of a corrupt record, the list modes
│   ├── VerbDrawTests.swift             # The verb of the day and random verbs: weights, My Verbs every third day in turn over a list that
│   │                                   #   grows, is reordered, or loses a verb, the band, one in three on demand, the seeded generator's sequence
│   ├── WidgetWeekTests.swift           # The widgets' week: seven dated days of VerbDraw's verbs, today kept on a rewrite, turns across odd
│   │                                   #   openings, the gate, the file read both ways, the timeline, the eighth day, an answer's own day
│   ├── ReviewScheduleTests.swift       # The ladder alone: a start, reviews, a snooze, a new item, answers moving an item only when due
│   ├── PracticeItemTests.swift         # Which item each question exercises across tenses, persons, and kinds of verb; pinned keys; which key
│   │                                   #   conjugations a lookup schedules and a review asks
│   ├── PracticeRecordTests.swift       # The practice record and its store: the ladder through answers and lookups, due and missed order, the
│   │                                   #   review card's offer and caption, a relaunch, the migration, a reset that stays
│   ├── QuizPracticeTests.swift         # Every answer recorded as given by every scope, a quit keeping them, and the default quiz's due items
│   ├── QuizRecordSessionTests.swift    # Review and My Mistakes: items beyond the level, a verb's key conjugations together, rounds of ten then the rest,
│   │                                   #   a mistake leaving once right and not returning in Ten More, the region, no score and no counts
│   ├── QuizHubTests.swift              # The last quiz's results: the stored form, each scope's kind and title, a relaunch, Reset, and
│   │                                   #   what a finished round, Ten More, a quit, a Review, a verb page, and a collection keep
│   ├── AchievementTests.swift          # Achievements: each ID pinned, the points, the verbs, an empty record, each level's patterns earning its own and
│   │                                   #   those below, one short, learning, every key Advanced asks, the core steps, vosotros in Spain, nothing while signed out
│   ├── MasteryTests.swift              # Mastery: the state by box, each level's patterns in both regions, the persons, the core verbs, the key
│   │                                   #   conjugations each level asks, the display following a seeded record, and answers landing where mapped
│   ├── FrequencyBandTests.swift        # Each band holds exactly its count, the bands nest, and where one ends
│   ├── VerbFamilies.swift              # Hand-curated lists of verbs irregular in a tense, and regular verbs by ending: an oracle for the quiz's draw and the collections
│   ├── VerbFamiliesTests.swift         # The lists resolve in the verb map, and the quiz's per-cell judgment finds each listed irregular (and regular) verb
│   ├── QuizTests.swift                 # Quiz logic, scoring, and timer, driven through the @Observable model
│   ├── QuizLiveActivityTests.swift     # Which quizzes start, update, and end the Live Activity, against LiveActivitiesSpy
│   ├── QuizRoundTests.swift            # Rounds of ten, re-ask placement and points, Ten More, which round ranks, the record of a quiz in progress, the quiz clock
│   ├── QuizLeaderboardTests.swift      # One leaderboard a level: each ID pinned, which sessions post, the score and the level they post
│   ├── QuizPersonalBestTests.swift     # The best ranked score at each level (first, beaten, not beaten, per level, none for Ten More, 0, or unranked, across a launch and a reset) and the achievement reports at a finish and a quit
│   ├── QuizLevelTests.swift            # Each level's tenses and weights, only its own cells drawn, tenses at their weight under a seed;
│   │                                   #   the setting's default and the migration from the old difficulty
│   ├── QuizVerbMixTests.swift          # The default quiz's verbs under forty seeds: the band, exactly half irregular cells, at most one irregular
│   │                                   #   imperfecto, the core verbs, rare and frequent compounds, endings, ten questions (nine typed beside a choice), scopes unaffected
│   ├── QuizScopeTests.swift            # The scoped quiz: My Verbs and Test Me draws, defective verbs, region and vos, ranking, and every scope the app starts pinned for ranking, sheet, and Live Activity
│   ├── CustomQuizTests.swift           # The custom quiz: the stored form and its keys, the scope, never ranked, and sessions over chosen tenses, verbs, or both
│   ├── PracticeSetTests.swift          # Practice sets: the pinned link, every set's round trip, links that name nothing, My Verbs as a capped list, the level that travels, the scope and its session, the share text, the QR code read back; the quiz/set route (in AppRouterTests)
│   ├── QuizGradingTests.swift          # Accepted answers (pronouns, spacing, each standard variant), the 2010 spelling, per-tense person rotation
│   ├── QuizCorrectionTests.swift       # The held correction's state machine: hold, clock, Continue, the last question
│   ├── QuizSecondAttemptTests.swift    # One more try: a slip waits with the clock running, half points on a right second attempt, a second slip to the correction
│   ├── AnswerSlipTests.swift           # Which near misses are slips, and which are another cell of the verb (hablo for habló, comio for comí)
│   ├── VerbEssentialsTests.swift       # Verb Essentials: each blank's answers for -go, strong-pretérito, irregular-future, irregular-participle, and prefixed verbs,
│   │                                   #   the draw (band, compound limit, asked verbs last), the rows, re-ask placement, each blank recorded, Five More Verbs
│   ├── ModelPracticeTests.swift        # Verb Models: which models and verbs, items, known and unknown, mix partners, the mixed draw (three and two, one model at a time,
│   │                                   #   a short side, asked verbs last), the scopes, and sessions (a round making a model known, Another Round, the last result)
│   ├── RecognitionTests.swift          # Name the Form: the cells of fuera, hablamos, hable, sé, ve, compounds, commands, and a gerundio; grading by part; the lines;
│   │                                   #   the correction's lines; the scope; and a round (no record, a second try, a re-ask, the last result, Ten More)
│   ├── GapSentenceTests.swift          # Complete the Sentence: the machine check (every blank the engine's in tú and vos, no vosotros, no tú
│   │                                   #   named, no tú form around the blank, asked at some level) and its breaking; the top 300's counts;
│   │                                   #   frames, tokens, grading, -ra and -se; drafts; the draw; the scope; and rounds
│   ├── ChoiceQuestionTests.swift       # Choice questions: the machine check (both sentences the engine's in tú and vos, differing only in their
│   │                                   #   braces, asked from their own level, a region only for today's events, each reason naming its tenses)
│   │                                   #   and its breaking; regions, levels, drafts; the prompt; the draw; and rounds (one choice never first,
│   │                                   #   none at Beginner or elsewhere, a held right or wrong choice, nothing recorded, out of 100, Ten More)
│   ├── SpeedRoundTests.swift           # The Speed Round: the mastered items, the draw (in turn, never twice running, a pattern's regular verbs, a key
│   │                                   #   conjugation's cells by level), the scope, the best, and rounds (a miss moving on, nothing recorded, batches, sixty ticks)
│   ├── DailyChallengeTests.swift       # The daily challenge: the pinned seed, days, the same draw from the same key, five balanced
│   │                                   #   questions by level and region, vos, the result and the agreed text, the widget's question and its
│   │                                   #   wrong answers' shape, a challenge in a quiz (whatever the device, no re-ask, kept once), the store, the link
│   ├── DailySessionTests.swift         # The streak under a fixed calendar (repair, a 25-hour day, pruning, bands), the session's draw and
│   │                                   #   flags, quizzes finished on chosen days, the reminder plan and rescheduling, the setting, the link
│   ├── AnswerDiagnosisTests.swift      # Each diagnosis for real verbs, the answers that get none, the lines in English, and a diagnosed error's second attempt in a quiz
│   ├── AnswerDifferenceTests.swift     # The letters a correction marks (accents, red letters, missing, extra, swapped) and the right answer it shows
│   ├── AnswerFrameTests.swift          # Each kind of question's frame, and the answer a filled blank gives (supplied no, reflexive pronoun, typed pronoun)
│   ├── VerbCollectionTests.swift       # Collections: keys, derived membership with VerbFamilies as oracle, progress, quiz, share text
│   ├── QuizGoldenFormsTests.swift      # Golden forms: proves the quiz asks for correct Spanish, not just self-consistent Spanish
│   ├── GameStateTests.swift            # Climb helpers: flipbook math, AABB overlap, platform snap, ladders, collisions
│   ├── GameBossTests.swift             # La Llamada: summit gate, demo/echo/judge loop, freeze fake-out, Duende meter, victory, end-scene slideshow
│   ├── ExampleDataTests.swift          # ExampleUses/MedievalExamples decode + ExampleSource attribution mapping
│   ├── EtymologyQuoteConventionTests.swift  # Pins the gloss-quote convention in the shipped Etymologies.json
│   └── ConjugationMapTests.swift       # The bundled map against a fresh build, the 99% example measure, shared forms, the
│                                       #   file format, and ConjugationMatch (accents, compounds, the reflexive pronoun)
├── Utils/
│   ├── GameCenterFakeTests.swift       # The Game Center double's behavior
│   ├── GameCenterPromptTests.swift     # Pins the Game Center opt-in gating
│   ├── GetterSetterRealTests.swift     # UserDefaults-backed storage
│   ├── IntExtensionTests.swift         # Int.timeString formatting
│   ├── RatingsFetcherTests.swift       # iTunes-API parsing — deliberately still XCTest (it mutates the global Current)
│   ├── ReviewPrompterRealTests.swift   # Review-prompt interval logic
│   ├── SettingsTests.swift             # Settings persistence and defaults (the verb sort, Suppress Review Card)
│   ├── SoundPlayerTests.swift          # The audio DI seam: the test world must get SoundPlayerDummy
│   └── URLExtensionTests.swift         # mailto encoding of a learner's query
└── Views/
    ├── AppRouterTests.swift            # Deeplink routing: the grammar's routes and round trips (search, verb with match, info, the reserved list), the intents' and the widgets' links, an ignored link, a link during the game, case, the tour's reshow, the quick action, and the one-shot game/boss and game/end flags
    ├── ConjugationTextTests.swift      # The shared conjugation renderer
    ├── EtymologyTextTests.swift        # The etymology markup renderer
    ├── InfoTests.swift                 # The rich-text parser, the Info model, and every article link in en and es
    ├── SettingsViewTests.swift         # Settings-screen state
    ├── SymbolValidityTests.swift       # Every systemName: literal in all three targets resolves to a real SF Symbol
    ├── VerbBrowseReviewCardTests.swift # The review card's model: chosen once per opening, Suppress Review Card, the reveal, the snooze, each signal once
    ├── VerbBrowseSearchTests.swift     # The Verbs tab's search model: what shows, the selection across each change, Return, each report, before the index, a requested search, letter order
    ├── RowLabelTests.swift             # The rows' Spanish titles, a row's stripe or highlight, a collection's progress
    └── VoiceOverLabelTests.swift       # What VoiceOver reads for the model pill (no ☛) and the review card, with the Spanish tagged Spanish

docs/                           # Claude's output that holds information and is not a plan: research, audits, playbooks,
│                               #   reference guides, drafts. See CLAUDE.md § Prompts, Plans, and Documents
├── project_structure.md        # This file — annotated directory tree
├── blog_notes.md               # Work journal: dated narrative notes for future blog posts and session memory
├── game.md                     # Toreo por Amor: La Subida, La Llamada, the Music enum, debug deeplinks and env vars
├── game_center_setup.md        # The Game Center leaderboards (one per quiz level): App Store Connect settings, how to create one,
│                               #   release-day steps, and testing before release
├── onboarding.md               # The first-launch welcome tour: sheets, presentation, kill switch, music
├── conjugation_tutor.md        # The on-device AI tutor: grounding tool, prompts, availability, TutorTestView
├── conjugar_ui_issues.md       # The mapped UI audit that drove the SwiftUI migration
├── code_review_recommendations.md    # Round 1 code-review findings, ranked (July 7, 2026)
├── code_review_recommendations_2.md  # Round 2 findings (July 15, 2026), the tracked item list, incl. item 15 (iPad)
├── old_engine_assessment.md    # Assessment of the legacy verbs.xml engine as logic reference and differential oracle
├── spanish_taxonomy.md         # Conjugar's own composition taxonomy (base + ordered features), not the book's
├── spanish_models.md           # Verb models transcribed from *Spanish Verbs Made Simple(r)*, Annex A
├── spanish_models_verification.md  # Verification of spanish_models.md against the source PDF
├── annex_b_verb_models.md      # Annex B index by class and sub-class for 4,818 verbs, extracted from the PDF
├── def_worklist.md             # Defective (DEF) verbs mapped to their models
├── phase6_known_issues.md      # Phase 6 known issues (resolved 2026-06-13: reír/oír end-anchoring)
├── history_corrections.md      # Fact-check of the verb-history essay, with replacement prose
├── verb_history.txt            # Editable English source of Info.verbHistoryText; sync with scripts/sync_verb_history.py
├── verb_history_es.txt         # The Spanish translation of the same, synced with --lang es
├── privacy_policy3.txt         # The published privacy policy (English + Spanish), describing the shipped app
├── privacy_policy_pending.md   # Policy lines for signals built on master, English + Spanish, waiting for the 2027 release
├── feature_architecture.md     # How the browse and pedagogy plans' features fit together; § Analytics: signals, the source vocabulary;
│                               #   § Verb Page: ConjugationTable, second names, the article sheet, the tips
├── tense_frequency.md          # How often each tense occurs in the corpus, which orders the verb page; method and results
├── app_description.txt         # App Store descriptions: the 2.8 text and the 3.0 rewrite, English and Spanish
├── release_notes.txt           # App Store release notes, newest version first
├── release.md                  # The 2027 release: every step left for release day (App Store Connect, device checks,
│                               #   applying docs/privacy_policy_pending.md). CLAUDE.md § No Release Before 2027 points here
├── rae_reply_draft.md          # Draft reply to the CORPES coordinator, who could not find the credit in the shipped app
├── etymology_pipeline.md       # How the etymologies were generated, a batch per session, English and Spanish.
│                               #   The work-list is exhausted; kept as the recipe
├── etymology_verbs.json        # That pipeline's work-list: the 988 usage-ranked verbs plus the select verbs
├── authored_examples.md        # The 39 verbs whose modern example is Claude-authored (no clean corpus use existed)
├── example_corpus_sources.md   # Provenance and licensing for every example-uses corpus source
├── gloss_verification_report.md    # Audited trail of the multi-agent gloss-verification pass over 4,556 glosses
├── glosses_to_review.md        # Low-confidence authored glosses flagged for a later human pass
├── glosses_missing.txt         # Verbs still lacking a gloss (currently empty)
├── glosses/                    # The gloss pipeline's data: slice_*.tsv, phase1/ blind + verdict files, phase2 consensus
│   └── legacy_verbs_xml_glosses.tsv  # The 149 glosses that only the deleted legacy verbs.xml supplied, rescued
├── game_design_research.md     # Asset, animation, and architecture research companion to prompts/game.md
├── boss_fight_ideas.md         # Three dance-off concepts; the source of La Llamada
├── dancer_shortlist.md         # Marketplace dancer shortlist from the paid-asset spike
├── screenshot_playbook.md      # Screenshot workflow: prerequisites, driver flags, workarounds, recovery
├── screenshots/                # Gitignored capture area. version_<N>/ are the assembled App Store upload bundles
│                               #   (iPhone/iPad × en/es, 36 cells each; version_3 is current). game/ holds the
│                               #   sprite-development captures cited by blog_notes.md and plans/game_boss_llamada.md.
│                               #   scripts/take_screenshots.sh writes fresh timestamped PNGs to the top level
├── video_script.md             # App Store preview script, adapted from Conjuguer's
├── verb_browse_review.md       # 2026-11-25 review of the code the browse plan built (Verbs and Models tabs): correctness,
│                               #   performance, privacy, doc gaps, duplication (the VerbBrowseView/ModelBrowseView map), smells,
│                               #   tests; Konjugieren's findings checked against Conjugar; twelve open questions for Josh.
│                               #   Reports only; Josh's answers and the fixes are in plans/verb_browse_fixes.md
├── verb_frequency_sources.md   # 2026-08-28 research behind the frequency/ pipeline: RAE CORPES XXI (CC BY-SA 4.0) as the
│                               #   primary key, Google Books as tie-breaker, measured coverage, paid options and why they lose.
│                               #   Shipped 2026-08-30; kept as the record of what was measured, not as a live plan
├── frequencies.txt             # The app's verb order, `<rank> <infinitive>` × 4,811. Written by
│                               #   frequency/generate_frequencies_txt.py; VerbMapRankingTests pins the app to it line for line
├── spanish_verb_frequencies.xml  # The retired Sketch Engine export (esTenTen18) that ranked the top 988 verbs through
│                               #   August 2026. Read by nothing; kept as provenance of the ranks users saw then
├── spanish_verbs_made_simpler.pdf  # Commercial reference: *Spanish Verbs Made Simple(r)* (gitignored)
└── french_verbs_made_simpler.pdf   # Its French companion, consulted for the sibling app (gitignored)

prompts/                        # What Josh writes to get Claude to do something. An arrow names what the prompt
│                               #   produced. See CLAUDE.md § Prompts, Plans, and Documents
├── analytics.md                # Adopt TelemetryDeck, as the siblings did, and rewrite the privacy policy
├── boss_fight.md               # The game's open items; ideate a family-friendly boss fight (→ docs/boss_fight_ideas.md)
├── code_review.md              # The round-1 full-codebase review (→ docs/code_review_recommendations.md)
├── end_scene.md                # The end-scene slideshow: two portraits and an expanding-circle transition (→ plans/end_scene.md)
├── etym_starter.md             # Port Conjuguer's etymology pipeline (→ docs/etymology_pipeline.md)
├── example_uses.md             # Example uses for the ranked verbs, Conjuguer-style, with medieval examples
│                               #   (→ docs/example_corpus_sources.md, plans/example_uses_pipeline.md)
├── fight_changes.md            # Boss-fight and final-scene tweaks from an annotated screenshot
├── frequency.md                # Find frequency-of-use data for all 4,811 verbs (→ docs/verb_frequency_sources.md)
├── game.md                     # The game: Donkey-Kong-inspired, with three earlier in-app games as precedent
├── game2.md                    # Prototype feel tweaks: control sizes, the jump button, contextual up and down
├── icons.md                    # Alternate app icons: bull, dancer, matador, and the classic icon
├── ipad.md                     # Write a native-iPad plan for round-2 review item 15 (→ plans/ipad.md)
├── main_game.md                # Finish the main game: power-ups, obstacles, challenge mechanics, levels
│                               #   (→ plans/game_la_subida.md)
├── matador.md                  # How the matador should look and how to make him (→ plans/matador_wire_into_game.md)
├── onboarding.md               # Port Conjuguer's onboarding flow, in Conjugar's yellow
├── pedagogy_review.md          # Review the code the pedagogy plan built, checked against Konjugieren's review, and
│                               #   plan the fixes (→ plans/pedagogy_fixes.md)
├── power_up_fixes.md           # Flourishes for the cape, speed, and serenata power-ups
├── rae_followup.md             # The CORPES coordinator's replies; draft an answer (→ docs/rae_reply_draft.md)
├── rename_objects.md           # Adopt Fowler's test-double naming
├── screenshot.md               # App Store screenshot capture spec: nine view categories × light/dark × en/es × two devices
├── settings_view.md            # Redesign SettingsView; borrow Conjuguer's start-button animation
├── sound.md                    # Plan the game's sound and music (→ plans/game_sound_music.md)
├── tips.md                     # Port Conjuguer's TipKit tips
├── two_plans.md                # Port Konjugieren's browse and pedagogy plans to Conjugar
│                               #   (→ plans/browse_and_verb_implementation.md, plans/pedagogy_implementation.md)
├── ui.md                       # Migrate to SwiftUI by way of the siblings' UI audits (→ plans/ui.md)
├── verb_browse_review.md       # Review the code the browse plan built, then ask Josh the open questions and plan the
│                               #   fixes (→ docs/verb_browse_review.md, plans/verb_browse_fixes.md)
├── widget_update.md            # Add etymologies and example uses to the large widget
└── widgets.md                  # Port Conjuguer's widgets

plans/                          # What Claude writes to get another session to do something: plans, briefs, handoffs,
│                               #   resume prompts. Most are finished and kept as the record of how a feature was specified
├── location_cleanup.md         # Sorting prompts, plans, and docs by authorship, and snake_case names (2026-11-16)
├── location_cleanup_moves.json # That sort's record: every file it moved or renamed, old path → new path
├── conjugar_migration_copy.md  # Finishing the move out of Conjugar.mig and retiring that checkout
├── verify_spanish_models_oracle.md        # Verifying spanish_models.md as the conjugation test oracle
├── phase_2_orthographic_accent_features.md  # Engine Phase 2: orthographic and accent features
├── phase_3_stem_vowel_raising.md          # Phase 3: stem-vowel diphthongs and -ir raising
├── phase_4_irregular_1s_preterite_future.md  # Phase 4: irregular 1s and subjunctive, strong preterites, future stems
├── phase_5_residue_assembly.md            # Phase 5: per-verb residue and assembly of the irregular classes
├── phase_5b_alternate_forms.md            # Phase 5b: alternate forms and the deferred corner classes
├── phase_6_data_entry.md                  # Phase 6: the verb → model map, by bulk data entry
├── fix_reir_oir_prefix_invariance.md      # The reír (6B-4) / oír (10) end-anchoring bug
├── verify_glosses_workflow.md             # The multi-agent gloss-verification workflow
├── convert_tests_to_swift_testing.md      # XCTest → Swift Testing for the engine suites
├── migrate_groups_to_synchronized_folders.md  # Xcode groups → PBXFileSystemSynchronizedRootGroups
├── migrate_app_to_conjugator2_and_sortable_browse.md  # Cutover to the new engine + the all-verbs sortable browse list
├── rename_engine_types_drop_2_suffix.md   # Dropping the transitional "2" suffix from the engine types
├── add_models_tab.md                      # The Models tab, Conjuguer-style
├── add_search_to_browse_and_models.md     # .searchable on both list screens
├── l10n.md                                # Localizations → L + Localizable.xcstrings
├── ui.md                                  # The SwiftUI migration, from prep through screen-by-screen rebuild
├── code_review_2.md                       # The round-2 review brief for a fresh session (→ docs/code_review_recommendations_2.md)
├── ipad.md                                # Native iPad support, phased; the Claude-side phases are done
├── fix_cold_launch_widget_deeplink_race.md  # Checking for the cold-launch widget-deeplink race (not vulnerable)
├── sweep_comments.md                      # Sweeping numbered-suggestion and book-reference provenance comments
├── run_etymology_pipeline.md              # The paste-in prompt that ran one batch of docs/etymology_pipeline.md
├── example_uses_pipeline.md               # Example sentences and medieval examples for the ranked verbs, steps A–F
├── example_uses_step_f_verbs.json         # Step F's work-list: the 352 special verbs with a medieval example
├── translate_verb_history.md              # Translating the verb-history essay into Spanish
├── apply_history_corrections.md           # Applying docs/history_corrections.md to the essay
├── frequency_ranks_for_all_verbs.md       # Ranking every verb: frequency/ pipeline (CORPES XXI + Google Books), counts in
│                                          #   verbModelMap.xml (`hi`/`gb`/`hp`), ranks derived at parse time, credits, RAE note
├── game_prototype.md                      # The placeholder-art prototype
├── game_la_subida.md                      # The five-stage climb
├── game_powerups_mechanics.md             # Two more power-ups and two more mechanics, so a run never repeats one
├── game_boss_llamada.md                   # The boss fight — La Llamada
├── game_blender_setup.md                  # Standing up the 3D → 2D sprite pipeline
├── game_dancer_realistic_spike.md         # Art spike: a rendered-realistic dancer, for a go/no-go decision
├── game_paid_dancer_bull_spike.md         # Art spike: marketplace assets for the dancer and the bull
├── game_dancer_actions.md                 # The dancer's four remaining actions (X-Bot mannequin; superseded)
├── game_dancer_finish_actions.md          # The flamenco-gown dancer's idle, climb, jump, and cape
├── game_climb_back_view.md                # Rendering the climb from behind
├── game_bull.md                           # The bull's sprites, master plan
├── game_bull_actions.md                   # The bull's three actions, Phases 2–7
├── matador_wire_into_game.md              # Wiring the finished matador sprite into the game
├── game_toon_palette.md                   # The cel/toon re-render of both actors
├── game_sound_music.md                    # Game SFX and music integration
├── wire_game_music.md                     # Swapping in the three purchased Pond5 tracks
├── end_scene.md                           # The end-scene slideshow, in two phases: images, then game
├── browse_and_verb_implementation.md      # Verbs and Models tabs: search ranking, reverse lookup, the conjugation map,
│                                          #   section order, related verbs, share, Spotlight, My Verbs, review card, collections.
│                                          #   Ported from Konjugieren's browse plan; 17 phases, run before the pedagogy plan
├── verb_browse_fixes.md                   # Fixes for what docs/verb_browse_review.md found in the browse plan's code: 13 phases
│                                          #   and a closing, with Josh's twelve decisions of 2026-11-25 (lookup, privacy, the
│                                          #   learner's record, the widget's week, the verb page, links, shared list pieces,
│                                          #   a search model, AdaptiveRows). Not started
├── pedagogy_implementation.md             # The quiz rebuilt for practice: grading, levels, ten-question rounds, a practice
│                                          #   record, diagnosis, new exercises, hub, streak, achievements. Ported from
│                                          #   Konjugieren's pedagogy plan; 24 phases
├── pedagogy_fixes.md                      # The review of the pedagogy plan's code and the plan to fix it, in one file: the
│                                          #   findings (what the learner is taught, correctness, privacy, docs, accessibility,
│                                          #   smells, tests), Konjugieren's findings checked here, Josh's 23 decisions of
│                                          #   2026-11-27, and 16 phases and a closing. Not started
├── voice_memo_bugs.md                     # Five bugs Josh recorded on his iPhone on 2026-11-27 (375-point screen, xxxLarge
│                                          #   text): the "also" names line leaves the verb page for the tense articles, a
│                                          #   truncated large title, truncated level names in the Quiz tab and Settings, and
│                                          #   the letter keys covering the quiz's answer field. Three phases. Not started
├── voice_memo_bugs/                       # His six screenshots at half size, screenshot_1.jpg to screenshot_6.jpg
├── gap_sentences_batch_1.md               # The review sheet of the first 118 sentences (the 25 most frequent verbs), from gap_sentences.py
├── choice_questions_batch_1.md            # The review sheet of the first 45 choice questions (which tense a speaker would use), from choice_questions.py
├── pedagogy_variant_audit.md              # Which alternate Spanish forms the quiz accepts (rio/rió, frito, satisface,
│                                          #   adecúo, vos hablés…), with RAE sources per row and Josh's rulings
├── achievement_art/                       # What produced the Game Center achievements' tile medallions:
│   ├── preamble.txt, subjects.txt         #   the shared prompt and each achievement's subject
│   ├── generate.sh                        #   two gpt-image drafts per achievement
│   ├── drafts/                            #   each draft's full prompt; the sixteen PNG drafts are gitignored (Josh chose every draft 1)
│   └── review_a.png, review_b.png         #   the contact sheets he chose from
└── end_scene_images/                      # What produced the two end-scene portraits, for exact regeneration:
    ├── toreros.txt, familia.txt           #   the image prompts (reference order is in the plan)
    └── recolor_suit.py                    #   the pixel-only navy → royal-blue suit recolor applied to the La familia winner

scripts/
├── README.md                   # What each script is for
├── sync_verb_history.py        # Validates docs/verb_history{,_es}.txt against the markup rules and writes it into the catalog
├── make_symbols.py             # Generates the custom SF Symbols (dancer, bull, olé) from Noun Project SVGs
├── symbol_sources/             # The source SVGs and the SF Symbols template scaffold
├── take_screenshots.sh         # Drives ios-build-verify + axe/simctl through the App Store screenshot sweep
├── prep_screenshot_sim.sh      # Prepares one simulator for one language (clean status bar, locale, appearance)
├── verify_store_media.sh       # Preflight for App Store Connect media: asserts every requirement that has bitten this project
├── write_forms_json.sh         # Builds ConjugationMapTool and writes corpus/working/forms.json and forms_all.json
├── count_tenses.py             # Counts each tense in the corpus from ConjugationMapTool --cells-json; docs/tense_frequency.md
├── gap_sentences.py            # Complete the Sentence's review sheet, approval, and status over Conjugar/Models/GapSentences.json
├── choice_questions.py         # The choice questions' review sheet, approval, and status over Conjugar/Models/ChoiceQuestions.json
├── _extract_annexb.py          # Extracts Annex B from docs/spanish_verbs_made_simpler.pdf into docs/annex_b_verb_models.md
├── _build_verbmap.py           # Builds Conjugar/Models/verbModelMap.xml from the extracted class index + glosses +
│                               #   frequency/verb_counts.json. Reproduces the shipped file byte-for-byte
├── _phase1_prep.py             # Gloss pipeline Phase 1: builds the blind-input files per slice in docs/glosses/
├── _phase2_prep.py             # Phase 2: splits the 549-verb candidate set into per-agent chunks
├── _phase3_classify.py         # Phase 3: classifies verdicts
├── _phase3_apply.py            # Phase 3: rewrites docs/glosses/slice_*.tsv from the Phase 2 consensus
└── _phase3_report.py           # Phase 3: renders docs/gloss_verification_report.md

tools/
├── reorg_group.rb              # One-shot: turned an app-target virtual group into a real folder in project.pbxproj
├── validate_refs.rb            # Asserts every file reference in project.pbxproj resolves on disk (no build needed)
└── blender/                    # The 3D → 2D sprite render harness (see its README)
    ├── README.md               # Pipeline documentation
    ├── blender-mcp/addon.py    # The Blender MCP addon the sessions drove Blender through
    ├── gen_dancer_action.py    # Builds one dancer action in Blender
    ├── gen_bull_action.py      # Builds one bull action
    ├── gen_matador.py          # Builds the static matador
    ├── gen_muleta_pickup.py    # Builds the cape pickup
    ├── render_sprites.py       # Renders an action to a numbered PNG sequence
    └── pack_or_rename.sh       # Turns render output into Xcode-ready imagesets

frequency/                      # The frequency-of-use pipeline behind the #rank badge. Only durable artifacts are
│                               #   tracked (see frequency/.gitignore); both source downloads are re-fetchable.
├── README.md                   # Provenance: sources, sizes, SHA-256, licences, re-download recipe, the attribute
│                               #   table, the estimate tiers, the clamp, the gates, the rebuild order
├── corpes_license.txt          # The CORPES zip's own license.txt (CC BY-SA 4.0), so the licence travels with the data
├── corpes_lemas.zip            # RAE CORPES XXI 1.5 lemma list, 16.3 MB. Browser download only — rae.es answers curl
│                               #   with a Cloudflare challenge (gitignored)
├── extract_gbooks_verbs.sh     # Fetches the three Google Books Spanish 1-gram shards, keeps the _VERB rows
├── gbooks/verb_{0,1,2}.tsv     # Those rows, ~830 MB (gitignored)
├── aggregate_gbooks.py         # Sums them through corpus/working/forms_all.json, splitting the 264 ambiguous forms by EM
├── gbooks_verb_lemmas.json     # Per-infinitive 1950–2019 token sums. The only Google Books artifact a rebuild needs
├── build_counts.py             # CORPES + Google Books + editorial → verb_counts.json + report.md, behind six gates
├── editorial_counts.json       # The four hand-assigned counts, with a written reason each
├── verb_counts.json            # One row per infinitive: corpes / corpes_se / gbooks / hits / estimate. What
│                               #   scripts/_build_verbmap.py reads
├── generate_frequencies_txt.py # verbModelMap.xml → docs/frequencies.txt; --check compares without writing
└── report.md                   # The last build's report: coverage, the fit, every estimate, the movers, the gaps (gitignored)

corpus/                         # Spanish text corpus for the example-uses pipeline. Only durable artifacts are tracked
│                               #   (see corpus/.gitignore); originals are re-fetchable and intermediates regenerable.
├── originals/                  # Fetched source texts: government/, literature/, medieval/, technology/ (gitignored)
├── grokked/                    # Verse-only medieval editions + ref map: Cantar de Mio Cid, Milagros, Libro de Buen Amor
├── json/                       # The finished artifacts copied into the app: ExampleUses.json, MedievalExamples.json
└── working/
    ├── fetch_corpus.sh         # Fetches the corpus into originals/
    ├── clean_corpus.py         # Strips retrieval cruft (Gutenberg boilerplate, PDF headers, OCR front matter)
    ├── grok_medieval.py        # Turns the three medieval editions into verse-only text plus a citation ref map
    ├── oldspanish.py           # Old-Spanish → Modern-Castilian canonicalizer for the medieval tier
    ├── build_corpus_index.py   # Inverted verb→occurrences index over the modern corpus
    ├── build_medieval_index.py # The same over the grokked verse
    ├── build_special_index.py  # The same for the step-F "special" verbs
    ├── build_tail_index.py     # Candidate index for the uncovered tail (step D — tail rescue)
    ├── build_examples.py       # Deterministic bookends for the mining pass (stage C)
    ├── write_authored.py       # Emits the Claude-authored residue (step D)
    └── write_authored_special.py   # The same for the special verbs

asset_licenses/                 # License paper trail for third-party media bundled in the app
├── README.md
├── cgtrader_flamenco_dancer.txt, cgtrader_matador.txt, mixamo_dancer.txt, sketchfab_bull.txt  # 3D sources
├── game_sounds_pixabay.txt, pixabay_game_sfx.txt, pixabay_mpg_sfx.txt   # SFX
└── pond5_game_music.txt        # The three Pond5 music tracks (no attribution required; the in-app credit is a courtesy)

audio-sources/                  # Purchased WAV masters (gitignored); only the 192 kbps MP3s are committed

art-sources/                    # Image-generation working files (gitignored: family photos). end-scene/ holds the seven
                                #   references, every gpt-image and Gemini candidate, and the local contact sheets

.claude/
├── ios-build-verify.config.sh  # Per-project build/verify config: scheme, simulator, FIRST_SCREEN_ID, MAIN_TABS_COORDS
├── rules/                      # Claude Code guidance split out of CLAUDE.md. Each file's `paths` frontmatter makes it
│   │                           #   load only when a session touches a matching file. Kept here, not in docs/, because
│   │                           #   only this folder gets that automatic loading
│   ├── analytics.md            # TelemetryDeck gotchas (Conjugar/Analytics/**, ConjugarTests/Analytics/**, privacy policy)
│   ├── localization.md         # .xcstrings workflow, escaping, percent signs, Info markup table (**/*.xcstrings, L.swift)
│   └── testing.md              # The XCTest isolated-deinit crash and Swift Testing conventions (ConjugarTests/**)
└── settings.local.json         # Local Claude Code settings (gitignored; absent unless created)

Conjugar.xcodeproj/             # The Xcode project (scheme `Conjugar`)
ConjugarWidget.entitlements     # Widget entitlements (App Groups)
.swiftlint.yml                  # SwiftLint configuration
unused.rb                       # Legacy helper: finds unreferenced assets
apple.png                       # README imagery: the App Store download badge
images/                         # README imagery: splash.png (the DancerIcon hero) plus fifteen 800 px-wide
                                #   screenshots, English, dark mode (game.png from 2026-08; the rest 2026-11-24).
                                #   Regenerate from docs/screenshots/ (gitignored); blog_notes 2026-11-24 has how
build.log                       # Raw xcodebuild output from the last ios-build-verify run (gitignored)
```
