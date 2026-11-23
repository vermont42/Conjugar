# Project Structure

```
Conjugar/
├── Info.plist                  # App configuration (conjugar:// URL scheme, iPad orientations, TelemetryDeckAppID)
├── Conjugar.entitlements       # App entitlements (App Groups for widget sharing, Game Center)
├── PrivacyInfo.xcprivacy       # Privacy manifest for App Store submission
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
│                               #   JPEG portraits (generated with gpt-image; see plans/end_scene.md, Phase 1)
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
│   ├── ExampleUses.json        # Bundled modern-prose example sentences keyed by bare infinitive
│   ├── MedievalExamples.json   # Bundled Medieval-Spanish attestations keyed infinitive → array
│   │
│   │  ── the conjugation engine (all nonisolated + Sendable) ──
│   ├── Conjugator.swift        # Engine entry point: resolves a verb's model (VerbMap → ModelCatalog) and composes features
│   ├── ConjugationFeature.swift  # The feature protocol (applies(to:) + apply(stem:ending:tense:)) and the `Slot` vocabulary
│   ├── ConjugatorError.swift   # Errors from the conjugation engine
│   ├── ModelCatalog.swift      # Class number ("1", "4B-1", "31-1", …) → VerbModel (base + ordered features)
│   ├── VerbModel.swift         # One regular base root plus an ordered feature list; also the alternate-paradigm scheme
│   ├── VerbMap.swift           # VerbMapEntry + the load-once @unchecked Sendable cache over verbModelMap.xml.
│   │                           #   ranked(_:) derives the dense 1…4,811 frequency rank from the stored counts at parse time
│   ├── VerbVisit.swift         # VerbDestination (infinitive + analytics source + search marks, what the tabs push) and VerbVisit (one
│   │                           #   stretch of a verb page on screen: viewVerbView/leaveVerbView, deepest section, dwell)
│   ├── SearchReport.swift      # SearchTracker (one search, first letter to its end) and SearchReport (finishSearch's banded
│   │                           #   parameters); MatchKind.analyticsValue
│   ├── VerbSearch.swift        # The one verb-search rule: folding, -se stripping, every gloss, forms (via FormLookup), MatchKind
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
│   ├── DisplayTense.swift      # The UI's tense vocabulary, including the compounds (formerly Tense.swift)
│   ├── DisplayPersonNumber.swift  # The UI's person vocabulary with localized pronouns (formerly PersonNumber.swift)
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
│   ├── ContentCaches.swift     # Pre-warms Etymology / ExampleData / MedievalData off the main actor at launch
│   ├── Etymology.swift         # Load-once etymology lookup by infinitive (`~bold~` markup)
│   ├── Example.swift           # One modern-prose example: text, translation, source, token, line
│   ├── ExampleData.swift       # Load-once ExampleUses.json cache keyed by bare infinitive
│   ├── ExampleSource.swift     # Maps an Example.source filename onto a human-readable attribution
│   ├── MedievalExample.swift   # One Medieval-Spanish verse: work, ref, Old-Spanish line, translation
│   ├── MedievalData.swift      # Load-once MedievalExamples.json cache keyed by bare infinitive
│   ├── Info.swift              # Info article model: InfoSection + heading/body parsed into richTextBlocks
│   ├── ModelInfo.swift         # The Models tab's row model: class number, exemplar, verbs, irregularity percent; row(for:) a verb
│   ├── RelatedVerbs.swift      # VerbRelations: each verb's base and root (detener → tener), and the verb page's related verbs
│   │
│   │  ── quiz, settings vocabulary, services ──
│   ├── Quiz.swift              # @Observable quiz state: questions, closure-based timer, scoring, Live Activity hooks
│   ├── QuizState.swift         # notStarted / inProgress / finished
│   ├── ConjugationResult.swift # Answer scoring: totalMatch / partialMatch (diacritic-folded) / noMatch
│   ├── Difficulty.swift        # Setting enum: easy / moderate / difficult, each with a score modifier
│   ├── Region.swift            # Setting enum: Spain vs. Latin America (TTS accent + score modifier)
│   ├── SecondSingularBrowse.swift  # Setting enum: which 2s form(s) the browse screens show
│   ├── SecondSingularQuiz.swift    # Setting enum: which 2s form the quiz asks for
│   ├── VerbSort.swift          # Verb-list sort order (frequency / alphabetical) + the Spanish collation locale
│   ├── ModelSort.swift         # Model-list sort order (irregularity / alphabetical / class number)
│   ├── VerbType.swift          # verbModelMap `vt` marker: irregular / regular -ar / -er / -ir
│   ├── VerbFamilies.swift      # The hand-curated verb lists the quiz builds questions from
│   ├── AppIcon.swift           # Alternate app-icon enum (bull / dancer / matador / classic) + preview asset names
│   ├── ConjugarTips.swift      # TipKit tips (try the quiz, explore models, change difficulty, enable Game Center; on the
│   │                           #   verb page, red letters and keep scrolling)
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
│       ├── GameState+Obstacles.swift   # Per-stage rolling obstacle sets and spawning (formerly GameState+Flags.swift)
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
│                               #   key conjugations as the description; indexed at each launch
├── Utils/
│   ├── BrowseSearch.swift      # The pure filter the Models tab searches through (the Verbs tab ranks with VerbSearch)
│   ├── Colors.swift            # Semantic palette bridging the colorsets to UIKit-facing call sites
│   ├── Emailer.swift           # MFMailComposeViewController wrapper for the Settings feedback link (address from URL.developerEmail)
│   ├── FontExtensions.swift    # Font.button and Font.heroNumeral
│   ├── GameCenter.swift        # Protocol for Game Center operations (fire-and-forget auth, observable isAuthenticated)
│   ├── GameCenterFake.swift    # In-memory double for the test/simulator worlds
│   ├── GameCenterReal.swift    # GKLocalPlayer authentication, score reporting, leaderboard presentation
│   ├── GetterSetter.swift      # Protocol for string key-value storage
│   ├── GetterSetterFake.swift  # In-memory dictionary implementation for tests
│   ├── GetterSetterReal.swift  # UserDefaults implementation
│   ├── GlyphWarmer.swift       # Pre-rasterizes emoji glyphs so the game's first flag emoji doesn't stall the render thread
│   ├── GradientDivider.swift   # Hairline separator that fades to transparent, for splitting sections inside a card()
│   ├── HapticPlayer.swift      # The haptics seam, protocol-injected like SoundPlayer
│   ├── HapticPlayerDummy.swift # No-op so the test worlds never touch the Taptic Engine
│   ├── HapticPlayerReal.swift  # UIKit feedback generators, held and re-prepare()d for low latency
│   ├── FlowLayout.swift        # A Layout that wraps its children into rows (the related-verb chips), ported from Konjugieren
│   ├── IntExtension.swift      # Int.timeString — elapsed seconds as h:mm:ss
│   ├── KillSwitches.swift      # Compile-time screenshot kill switches: TipDisplay, OnboardingDisplay, TutorDisplay
│   ├── Layout.swift            # Spacing/geometry constants (8/16/24 pt, readingWidth 680, cornerRadius 12)
│   ├── LiveActivityManager.swift  # Starts / updates / ends the quiz Live Activity, driven from Quiz.swift
│   ├── Modifiers.swift         # The design system: card(), metadataPill(), linguistic(), numeric(), speakOnTapFlash(),
│   │                           #   copyOnLongPress() (a Copy context menu and VoiceOver action), PrimaryButtonStyle
│   ├── RatingsFetcher.swift    # Fetches App Store ratings from the iTunes API for the Settings screen
│   ├── ReviewPrompter.swift    # Protocol for review-prompting behavior
│   ├── ReviewPrompterReal.swift   # SKStoreReviewController prompting at usage intervals
│   ├── ReviewPrompterStub.swift   # Canned no-op for tests
│   ├── RichText.swift          # Parses Info markup (^…^ ~…~ $…$ %…%) into RichTextBlock / TextSegment
│   ├── Settings.swift          # @Observable user preferences over GetterSetter
│   ├── ShareSheet.swift        # Workaround for ShareLink: presents UIActivityViewController from a plain button, with an
│   │                           #   LPLinkMetadata header and Copy kept; on iPad anchored to the named bar button
│   ├── SoundPlayer.swift       # Protocol for one-shot SFX and looping music
│   ├── SoundPlayerDummy.swift  # No-op so the test worlds never touch CoreAudio
│   ├── SoundPlayerReal.swift   # AVAudioPlayer implementation: off-main warm-up, per-sound debounce, music fades
│   ├── UIApplicationExtensions.swift  # topViewController / key-window helpers for the remaining UIKit presentations
│   ├── URLExtension.swift      # The conjugar:// deeplink grammar's constants, parsers (deeplinkTarget, deeplinkQueryValue, analyticsSource), and builders (verbDeeplink, searchDeeplink, infoDeeplink); URL.developerEmail and URL.mailto for the failed search's request line; URL.appStore, with no storefront
│   ├── URLProtocolStub.swift   # URLProtocol subclass for stubbing HTTP responses in tests
│   ├── URLSessionExtension.swift  # Stubbed URLSession for testing
│   ├── Utterer.swift           # AVSpeechSynthesizer text-to-speech plus the single .ambient audio-session owner
│   ├── VerbSearchArrowKeys.swift  # Hack: priority UIKeyCommands for ↑/↓ through verb results while the search field is focused
│   ├── ViewControllerTransitions.swift  # Hack: waits for UIKit transitions to end, so an iPad letter key survives search dismissal
│   └── WidgetSnapshotWriter.swift  # Picks the daily verb + quiz question, conjugates them, writes JSON to the App Group.
│                                   #   Draws from the top verbOfTheDayPoolSize (1,000) verbs by frequency
└── Views/
    ├── AppRouter.swift         # Tab selection + conjugar:// deeplink routing (verb with match, search, info, quiz, game), the one-shot requests the tabs consume (pendingVerb, pendingSearch, pendingInfo, game/onboarding/tutor flags), openSearch for Command-F, the control, and the quick action; SearchRequest
    ├── BrowseLayout.swift      # Shared LazyVGrid column sets for the iPad (regular-width) layouts
    ├── ConjugationText.swift   # Renders a conjugated form with its irregular span in customRed
    ├── EtymologyText.swift     # Renders etymology prose (its own minimal `~…~` parser, independent of Info markup)
    ├── GameView.swift          # Toreo por Amor: the full-screen SwiftUI game (climb + boss fight + end scene and its slideshow)
    ├── InfoBrowseView.swift    # The Info topic list, incl. the tutor section and the tense difficulty filter
    ├── InfoView.swift          # Info-article detail; a tapped %…% term opens a URL or pushes another article
    ├── MainTabView.swift       # The app shell: a five-tab TabView, onboarding presentation, game full-screen cover
    ├── ModelBrowseView.swift   # Sortable, searchable list of every verb model with irregularity badges
    ├── ModelView.swift         # Model detail: header pills, the pronoun-by-tense grid, and the verbs using the model, by frequency or alphabetically
    ├── OnboardingView.swift    # The paged first-launch welcome tour (welcome, four content sheets, tutor, game preview)
    ├── QuizView.swift          # Quiz gameplay: prompt, answer field, timer, score
    ├── ResultsView.swift       # Quiz results with the hero score numeral and the leaderboard button
    ├── RelatedVerbsView.swift  # The verb page's Related Verbs card, the full related list, VerbPagePush, and verbPageDestinations()
    ├── RichTextView.swift      # Renders parsed [RichTextBlock] as native SwiftUI Text
    ├── SettingsView.swift      # Settings: pickers, app-icon picker, ratings, Game Center, onboarding reshow, Play
    ├── TutorTestView.swift     # Batch tutor harness (~30 queries, ShareLink export); reached by triple-tapping the tutor title
    ├── TutorView.swift         # The conjugation-tutor chat screen
    ├── SpanishLetterKeyRow.swift  # á é í ó ú ü ñ keys with an insert closure; replaces the Verbs sort picker while search is focused
    ├── VerbEntryList.swift     # Lazy verb rows (compact) or carded grid (regular) that open a verb; a model's page and the related list use it
    ├── VerbBrowseView.swift    # Searchable, sortable list of all verbs (search ranked by VerbSearch); failed-search guess and mail line; Return and arrow keys on iPad; carries the browse_verb_count launch anchor
    ├── VerbSearchCommands.swift  # Command-F as a top-level menu (Verbs › Find a Verb) that opens the verb search through AppRouter.openSearch
    └── VerbView.swift          # Verb detail: full conjugation paradigm, etymology, modern and medieval examples, related verbs; the pill opens the model; sends viewVerbView/leaveVerbView per VerbVisit

ConjugarWidget/
├── AnswerQuizIntent.swift      # Interactive AppIntent behind the Quiz widget's answer buttons
├── Assets.xcassets/            # Widget-specific asset catalog (AccentColor, WidgetBackground)
├── ConjugarWidgetBundle.swift  # The extension's @main: every widget, control, and Live Activity it vends
├── FindVerbControl.swift       # Control Center / Lock Screen control that opens the verb search, empty and focused
├── Info.plist                  # Widget extension configuration
├── Localizable.xcstrings       # Widget-target string catalog (en/es), resolved against the widget bundle
├── QuickQuizControl.swift      # Control Center / Lock Screen control that starts a quiz
├── QuizLiveActivity.swift      # Lock Screen + Dynamic Island rendering of QuizActivityAttributes
├── QuizWidget.swift            # The interactive daily-quiz widget (tap to answer, flips to a result)
├── RandomVerbControl.swift     # Control Center / Lock Screen control that opens a random verb
├── SnapshotReader.swift        # Decodes the App-Group JSON snapshot; supplies the gallery placeholder
├── VerbOfTheDayWidget.swift    # "Verb of the Day" StaticConfiguration refreshing at the next local midnight
├── WidgetDeeplink.swift        # Builds the conjugar:// URLs the widgets attach via .widgetURL(_:); verb links carry ?source=widget
└── Views/
    ├── AccessoryWidgetView.swift    # Lock Screen accessory presentations
    ├── LargeWidgetView.swift        # systemLarge: header, non-finite forms, presente paradigm, example, etymology
    ├── MediumWidgetView.swift       # systemMedium: header plus the full presente paradigm in two columns
    ├── QuizWidgetView.swift         # The Quiz widget's unanswered / answered states (deterministic answer shuffle)
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
├── OpenQuizIntent.swift        # Opens the app and stashes a deeplink the app drains on activation
├── OpenRandomVerbIntent.swift  # Same, for a random verb, as Shortcuts and Siri run it (source=shortcut)
├── OpenRandomVerbControlIntent.swift  # The Random Verb control's own hidden copy of it (source=control)
├── OpenVerbSearchIntent.swift  # The Find a Verb control's hidden intent: stashes conjugar://search?source=control
├── QuizActivityAttributes.swift  # The ActivityKit contract shared by LiveActivityManager and QuizLiveActivity
├── WidgetConstants.swift       # App Group id, snapshot filename, and the shared-defaults keys
├── WidgetL.swift               # Widget-target localization accessors mirroring L, with English defaultValues
└── WidgetSnapshot.swift        # The Codable payload the app precomputes and the widget renders

ConjugarTests/
├── Info.plist
├── Analytics/
│   ├── AnalyticsTests.swift            # Signal names and parameters via AnalyticsSpy; pins the wire names
│   └── LookupSignalsTests.swift        # finishSearch/viewVerbView/leaveVerbView: bands, the search's lifecycle, reports, visits, link sources, no echo of the query
├── Models/
│   ├── ConjugatorTests.swift           # The main engine suite — regular and irregular verbs across all tenses
│   ├── ConjugatorAccessorsTests.swift  # The engine's convenience accessors
│   ├── ConjugatorResolverTests.swift   # Verb → model resolution, incl. prefixed compounds and the regular fallback
│   ├── VerbMapTests.swift              # verbModelMap.xml parsing and lookup
│   ├── VerbSearchTests.swift           # Search ranking (Josh's table of queries), folding, -se stripping, every gloss of a homonym, the failed-search guess
│   ├── ConjugationTableTests.swift     # The verb page's order, second names, and articles; search names follow the page
│   ├── ReverseLookupTests.swift        # A form finds its verb: shared forms, accents, enclitics, compounds, vos, participle endings,
│   │                                   #   the row's names, the guess from a form, every example's token through search
│   ├── VerbLookupTests.swift           # Look Up a Verb: each kind of answer and its wording, page or search, a lookup link's marks
│   ├── VerbSpotlightTests.swift        # Spotlight entries: gloss phrases, forms as keywords, key conjugations, the activity identifier
│   ├── VerbMapRankingTests.swift       # Rank derivation on a fixture, the shipped map's invariants, and
│   │                                   #   line-for-line agreement with docs/frequencies.txt
│   ├── TenseBridgeTests.swift          # DisplayTense/DisplayPersonNumber → engine mapping, compounds, negative imperative
│   ├── ReflexivePronounTests.swift     # Reflexive-only verbs: arrepentirse in every slot, every rx verb's pronoun placement,
│   │                                   #   the enclisis accent rule, citation-form search, and quiz grading with and without the pronoun
│   ├── DisplayTenseTests.swift         # The UI tense vocabulary
│   ├── DisplayPersonNumberTests.swift  # The UI person vocabulary and its pronouns
│   ├── ConjugationResultTests.swift    # Answer scoring, incl. the diacritic-folding partial match
│   ├── ModelInfoTests.swift            # Models-tab row construction and irregularity percent
│   ├── ModelSortTests.swift            # Model-list sort orders
│   ├── RelatedVerbsTests.swift         # Bases and roots (tener, decir, formar), the class and prefix rules, false compounds,
│   │                                   #   model relatives one per root by frequency, and the pill's model row
│   ├── KeyConjugationTests.swift       # The four key conjugations (regular, stem-changing, irregular, reflexive, defective),
│   │                                   #   the share text, URL.appStore, and what a long press copies
│   ├── VerbSortTests.swift             # Verb-list sort orders and Spanish collation
│   ├── VerbFamiliesTests.swift         # Guard-rail: every hand-curated quiz verb resolves in the verb map
│   ├── QuizTests.swift                 # Quiz logic, scoring, and timer, driven through the @Observable model
│   ├── QuizGoldenFormsTests.swift      # Golden forms: proves the quiz asks for correct Spanish, not just self-consistent Spanish
│   ├── GameStateTests.swift            # Climb helpers: flipbook math, AABB overlap, platform snap, ladders, collisions
│   ├── GameBossTests.swift             # La Llamada: summit gate, demo/echo/judge loop, freeze fake-out, Duende meter, victory, end-scene slideshow
│   ├── ExampleDataTests.swift          # ExampleUses/MedievalExamples decode + ExampleSource attribution mapping
│   ├── EtymologyQuoteConventionTests.swift  # Pins the gloss-quote convention in the shipped Etymologies.json
│   └── ConjugationMapTests.swift       # The bundled map against a fresh build, the 99% example measure, shared forms, the
│                                       #   file format, and ConjugationMatch (accents, compounds, the reflexive pronoun)
├── Utils/
│   ├── BrowseSearchTests.swift         # The shared browse filter: empty query, matching, case/diacritic insensitivity
│   ├── GameCenterFakeTests.swift       # The Game Center double's behavior
│   ├── GameCenterPromptTests.swift     # Pins the corrected opt-in gating (the old inline guard was inverted)
│   ├── GetterSetterRealTests.swift     # UserDefaults-backed storage
│   ├── IntExtensionTests.swift         # Int.timeString formatting
│   ├── RatingsFetcherTests.swift       # iTunes-API parsing — deliberately still XCTest (it mutates the global Current)
│   ├── ReviewPrompterRealTests.swift   # Review-prompt interval logic
│   ├── SettingsTests.swift             # Settings persistence and defaults
│   ├── SoundPlayerTests.swift          # The audio DI seam: the test world must get SoundPlayerDummy
│   └── URLExtensionTests.swift         # mailto encoding of a learner's query
└── Views/
    ├── AppRouterTests.swift            # Deeplink routing: the grammar's routes and round trips (search, verb with match, info, the reserved list), the intents' literal links, the quick action, and the one-shot game/boss and game/end flags
    ├── ConjugationTextTests.swift      # The shared conjugation renderer
    ├── EtymologyTextTests.swift        # The etymology markup renderer
    ├── InfoTests.swift                 # The rich-text parser, the Info model, and every article link in en and es
    ├── SettingsViewTests.swift         # Settings-screen state
    ├── SymbolValidityTests.swift       # Every systemName: literal in all three targets resolves to a real SF Symbol
    └── VerbBrowseKeyboardTests.swift   # How the arrow keys move the highlighted verb result

docs/                           # Claude's output that holds information and is not a plan: research, audits, playbooks,
│                               #   reference guides, drafts. See CLAUDE.md § Prompts, Plans, and Documents
├── project_structure.md        # This file — annotated directory tree
├── blog_notes.md               # Work journal: dated narrative notes for future blog posts and session memory
├── game.md                     # Toreo por Amor: La Subida, La Llamada, the Music enum, debug deeplinks and env vars
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
├── purpose_and_use_proposed.txt    # Draft replacement for Info.purposeAndUseText
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
├── pedagogy_implementation.md             # The quiz rebuilt for practice: grading, levels, ten-question rounds, a practice
│                                          #   record, diagnosis, new exercises, hub, streak, achievements. Ported from
│                                          #   Konjugieren's pedagogy plan; 24 phases
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
├── write_forms_json.sh         # Builds ConjugationMapTool and writes corpus/working/forms.json and forms_all.json (replaced
│                               #   the CorpusFormsDumpTests harness on 2026-11-22)
├── count_tenses.py             # Counts each tense in the corpus from ConjugationMapTool --cells-json; docs/tense_frequency.md
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
images/                         # README imagery: splash.png (the DancerIcon hero) plus the ten 800 px-wide
                                #   screenshots of the shipping app. Regenerate from docs/screenshots/ (gitignored)
build.log                       # Raw xcodebuild output from the last ios-build-verify run (gitignored)
```
