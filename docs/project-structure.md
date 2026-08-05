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
├── *.png                       # Legacy UIKit-era screenshots (browse, browseInfo, info, launch, leaderboard, quiz,
│                               #   verb, GameCenter). No longer referenced by README.md — it uses Images/ now
├── Analytics/
│   ├── Analytics.swift         # Analytics protocol + AnalyticsName / ParameterKey enums; nonisolated throughout
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
│   └── Game/                   # Cel-shaded sprite flipbooks: dancer_<action>_N, bull_<action>_N, matador, cape_pickup
├── Audio/                      # Synchronized-folder audio group: boss-fight + power-up SFX (castanetHigh/Low, palmas,
│                               #   crowdOle, stompThud, tensionSting, capeWhoosh, brainLockOn, coin, snort, guitarStrum,
│                               #   speedWhoosh, zombieGroan, stampede, lightsOut) plus spanishTension.mp3 (Music.onboarding)
│                               #   and spanishGuitarStandoff.mp3 (Music.bossFight)
├── Base.lproj/
│   └── LaunchScreen.storyboard # Launch screen
├── es.lproj/
│   └── LaunchScreen.strings    # Spanish launch-screen strings (the only surviving legacy .strings file)
├── Models/
│   ├── verbModelMap.xml        # The verb→model map: 4,811 verbs → class number(s), gloss(es), reflexive flag
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
│   ├── VerbMap.swift           # VerbMapEntry + the load-once @unchecked Sendable cache over verbModelMap.xml
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
│   ├── TenseBridge.swift       # The seam: DisplayTense/DisplayPersonNumber → EngineTense/EnginePersonNumber (+ compounds, negative imperative)
│   ├── DisplayTense.swift      # The UI's tense vocabulary, including the compounds (formerly Tense.swift)
│   ├── DisplayPersonNumber.swift  # The UI's person vocabulary with localized pronouns (formerly PersonNumber.swift)
│   ├── AuxiliaryError.swift    # Error type for auxiliary-verb lookup failures
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
│   ├── ModelInfo.swift         # The Models tab's row model: class number, exemplar, verbs, irregularity percent
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
│   ├── ConjugarTips.swift      # TipKit tips (try the quiz, explore models, change difficulty, enable Game Center)
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
│       └── GameState+Stages.swift      # The five stages, escape beats, stage advance, and soft respawn
├── Supporting/                 # A PBXFileSystemSynchronizedRootGroup — files dropped here need no pbxproj edit
│   ├── AppDelegate.swift       # UIApplicationDelegateAdaptor for the hooks the App lifecycle doesn't cover (appearance config)
│   ├── ConjugarApp.swift       # @main App: analytics init, TipKit configure, cache warm, WindowGroup → MainTabView
│   ├── L.swift                 # Type-safe scoped localization accessors backed by String(localized:)
│   └── Localizable.xcstrings   # The one string catalog holding both en and es
├── Utils/
│   ├── BrowseSearch.swift      # The pure filter seam shared by the Verb and Model browse screens
│   ├── Colors.swift            # Semantic palette bridging the colorsets to UIKit-facing call sites
│   ├── Emailer.swift           # MFMailComposeViewController wrapper for the Settings feedback link
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
│   ├── IntExtension.swift      # Int.timeString — elapsed seconds as h:mm:ss
│   ├── KillSwitches.swift      # Compile-time screenshot kill switches: TipDisplay, OnboardingDisplay, TutorDisplay
│   ├── Layout.swift            # Spacing/geometry constants (8/16/24 pt, readingWidth 680, cornerRadius 12)
│   ├── LiveActivityManager.swift  # Starts / updates / ends the quiz Live Activity, driven from Quiz.swift
│   ├── Modifiers.swift         # The design system: card(), metadataPill(), linguistic(), numeric(), speakOnTapFlash(), PrimaryButtonStyle
│   ├── RatingsFetcher.swift    # Fetches App Store ratings from the iTunes API for the Settings screen
│   ├── ReviewPrompter.swift    # Protocol for review-prompting behavior
│   ├── ReviewPrompterReal.swift   # SKStoreReviewController prompting at usage intervals
│   ├── ReviewPrompterStub.swift   # Canned no-op for tests
│   ├── RichText.swift          # Parses Info markup (^…^ ~…~ $…$ %…%) into RichTextBlock / TextSegment
│   ├── Settings.swift          # @Observable user preferences over GetterSetter
│   ├── SoundPlayer.swift       # Protocol for one-shot SFX and looping music
│   ├── SoundPlayerDummy.swift  # No-op so the test worlds never touch CoreAudio
│   ├── SoundPlayerReal.swift   # AVAudioPlayer implementation: off-main warm-up, per-sound debounce, music fades
│   ├── UIApplicationExtensions.swift  # topViewController / key-window helpers for the remaining UIKit presentations
│   ├── URLProtocolStub.swift   # URLProtocol subclass for stubbing HTTP responses in tests
│   ├── URLSessionExtension.swift  # Stubbed URLSession for testing
│   ├── Utterer.swift           # AVSpeechSynthesizer text-to-speech plus the single .ambient audio-session owner
│   └── WidgetSnapshotWriter.swift  # Picks the daily verb + quiz question, conjugates them, writes JSON to the App Group
└── Views/
    ├── AppRouter.swift         # Tab selection + conjugar:// deeplink routing, incl. the one-shot game/onboarding/tutor flags
    ├── BrowseLayout.swift      # Shared LazyVGrid column sets for the iPad (regular-width) layouts
    ├── ConjugationText.swift   # Renders a conjugated form with its irregular span in customRed
    ├── EtymologyText.swift     # Renders etymology prose (its own minimal `~…~` parser, independent of Info markup)
    ├── GameView.swift          # Toreo por Amor: the full-screen SwiftUI game (climb + boss fight + end scene)
    ├── InfoBrowseView.swift    # The Info topic list, incl. the tutor section and the tense difficulty filter
    ├── InfoView.swift          # Info-article detail; a tapped %…% term opens a URL or pushes another article
    ├── MainTabView.swift       # The app shell: a five-tab TabView, onboarding presentation, game full-screen cover
    ├── ModelBrowseView.swift   # Sortable, searchable list of every verb model with irregularity badges
    ├── ModelView.swift         # Model detail: header pills, the pronoun-by-tense grid, and the verbs using the model
    ├── OnboardingView.swift    # The paged first-launch welcome tour (welcome, four content sheets, tutor, game preview)
    ├── QuizView.swift          # Quiz gameplay: prompt, answer field, timer, score
    ├── ResultsView.swift       # Quiz results with the hero score numeral and the leaderboard button
    ├── RichTextView.swift      # Renders parsed [RichTextBlock] as native SwiftUI Text
    ├── SettingsView.swift      # Settings: pickers, app-icon picker, ratings, Game Center, onboarding reshow, Play
    ├── TutorTestView.swift     # Batch tutor harness (~30 queries, ShareLink export); reached by triple-tapping the tutor title
    ├── TutorView.swift         # The conjugation-tutor chat screen
    ├── VerbBrowseView.swift    # Searchable, sortable list of all verbs; carries the browse_verb_count launch anchor
    └── VerbView.swift          # Verb detail: full conjugation paradigm, etymology, modern and medieval examples

ConjugarWidget/
├── AnswerQuizIntent.swift      # Interactive AppIntent behind the Quiz widget's answer buttons
├── Assets.xcassets/            # Widget-specific asset catalog (AccentColor, WidgetBackground)
├── ConjugarWidgetBundle.swift  # The extension's @main: every widget, control, and Live Activity it vends
├── Info.plist                  # Widget extension configuration
├── Localizable.xcstrings       # Widget-target string catalog (en/es), resolved against the widget bundle
├── QuickQuizControl.swift      # Control Center / Lock Screen control that starts a quiz
├── QuizLiveActivity.swift      # Lock Screen + Dynamic Island rendering of QuizActivityAttributes
├── QuizWidget.swift            # The interactive daily-quiz widget (tap to answer, flips to a result)
├── RandomVerbControl.swift     # Control Center / Lock Screen control that opens a random verb
├── SnapshotReader.swift        # Decodes the App-Group JSON snapshot; supplies the gallery placeholder
├── VerbOfTheDayWidget.swift    # "Verb of the Day" StaticConfiguration refreshing at the next local midnight
├── WidgetDeeplink.swift        # Builds the conjugar:// URLs the widgets attach via .widgetURL(_:)
└── Views/
    ├── AccessoryWidgetView.swift    # Lock Screen accessory presentations
    ├── LargeWidgetView.swift        # systemLarge: header, non-finite forms, presente paradigm, example, etymology
    ├── MediumWidgetView.swift       # systemMedium: header plus the full presente paradigm in two columns
    ├── QuizWidgetView.swift         # The Quiz widget's unanswered / answered states (deterministic answer shuffle)
    ├── SmallWidgetView.swift        # systemSmall: verb, gloss, first three present-tense forms
    ├── WidgetConjugationText.swift  # The widget's copy of the UPPERCASE-means-irregular render convention
    └── WidgetEtymologyText.swift    # The widget's standalone copy of the `~…~` etymology markup renderer

Shared/                         # Compiled into both the app and the widget extension
├── OpenQuizIntent.swift        # Opens the app and stashes a deeplink the app drains on activation
├── OpenRandomVerbIntent.swift  # Same, for a random verb
├── QuizActivityAttributes.swift  # The ActivityKit contract shared by LiveActivityManager and QuizLiveActivity
├── WidgetConstants.swift       # App Group id, snapshot filename, and the shared-defaults keys
├── WidgetL.swift               # Widget-target localization accessors mirroring L, with English defaultValues
└── WidgetSnapshot.swift        # The Codable payload the app precomputes and the widget renders

ConjugarTests/
├── Info.plist
├── Analytics/
│   └── AnalyticsTests.swift            # Signal names and parameters via AnalyticsSpy; pins the wire names
├── Models/
│   ├── ConjugatorTests.swift           # The main engine suite — regular and irregular verbs across all tenses
│   ├── ConjugatorAccessorsTests.swift  # The engine's convenience accessors
│   ├── ConjugatorResolverTests.swift   # Verb → model resolution, incl. prefixed compounds and the regular fallback
│   ├── VerbMapTests.swift              # verbModelMap.xml parsing and lookup
│   ├── TenseBridgeTests.swift          # DisplayTense/DisplayPersonNumber → engine mapping, compounds, negative imperative
│   ├── DisplayTenseTests.swift         # The UI tense vocabulary
│   ├── DisplayPersonNumberTests.swift  # The UI person vocabulary and its pronouns
│   ├── ConjugationResultTests.swift    # Answer scoring, incl. the diacritic-folding partial match
│   ├── ModelInfoTests.swift            # Models-tab row construction and irregularity percent
│   ├── ModelSortTests.swift            # Model-list sort orders
│   ├── VerbSortTests.swift             # Verb-list sort orders and Spanish collation
│   ├── VerbFamiliesTests.swift         # Guard-rail: every hand-curated quiz verb resolves in the verb map
│   ├── QuizTests.swift                 # Quiz logic, scoring, and timer, driven through the @Observable model
│   ├── QuizGoldenFormsTests.swift      # Golden forms: proves the quiz asks for correct Spanish, not just self-consistent Spanish
│   ├── GameStateTests.swift            # Climb helpers: flipbook math, AABB overlap, platform snap, ladders, collisions
│   ├── GameBossTests.swift             # La Llamada: summit gate, demo/echo/judge loop, freeze fake-out, Duende meter, victory
│   ├── ExampleDataTests.swift          # ExampleUses/MedievalExamples decode + ExampleSource attribution mapping
│   ├── EtymologyQuoteConventionTests.swift  # Pins the gloss-quote convention in the shipped Etymologies.json
│   └── CorpusFormsDumpTests.swift      # Harness: drives the engine over every verb to emit corpus/working/forms.json
├── Utils/
│   ├── BrowseSearchTests.swift         # The shared browse filter: empty query, matching, case/diacritic insensitivity
│   ├── GameCenterFakeTests.swift       # The Game Center double's behavior
│   ├── GameCenterPromptTests.swift     # Pins the corrected opt-in gating (the old inline guard was inverted)
│   ├── GetterSetterRealTests.swift     # UserDefaults-backed storage
│   ├── IntExtensionTests.swift         # Int.timeString formatting
│   ├── RatingsFetcherTests.swift       # iTunes-API parsing — deliberately still XCTest (it mutates the global Current)
│   ├── ReviewPrompterRealTests.swift   # Review-prompt interval logic
│   ├── SettingsTests.swift             # Settings persistence and defaults
│   └── SoundPlayerTests.swift          # The audio DI seam: the test world must get SoundPlayerDummy
└── Views/
    ├── AppRouterTests.swift            # Deeplink routing, focused on the one-shot game/boss and game/end flags
    ├── ConjugationTextTests.swift      # The shared conjugation renderer
    ├── EtymologyTextTests.swift        # The etymology markup renderer
    ├── InfoTests.swift                 # The rich-text parser and the Info model
    ├── SettingsViewTests.swift         # Settings-screen state
    └── SymbolValidityTests.swift       # Every systemName: literal in all three targets resolves to a real SF Symbol

docs/
├── project-structure.md        # This file — annotated directory tree
├── blog_notes.md               # Work journal: dated narrative notes for future blog posts and session memory
├── conjugar-ui-issues.md       # The mapped UI audit that drove the SwiftUI migration
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
├── privacy_policy3.txt         # The published privacy policy (English + Spanish) — update it when signals change
├── authored-examples.md        # The 39 verbs whose modern example is Claude-authored (no clean corpus use existed)
├── example-corpus-sources.md   # Provenance and licensing for every example-uses corpus source
├── gloss_verification_report.md    # Audited trail of the multi-agent gloss-verification pass over 4,556 glosses
├── glosses_to_review.md        # Low-confidence authored glosses flagged for a later human pass
├── glosses_missing.txt         # Verbs still lacking a gloss (currently empty)
├── glosses/                    # The gloss pipeline's data: slice_*.tsv, phase1/ blind + verdict files, phase2 consensus
│   └── _phase2_prep.py         # Splits the 549-verb Phase 2 candidate set into per-agent chunks
├── game_design_research.md     # Asset, animation, and architecture research companion to prompts/game.md
├── boss_fight_ideas.md         # Three dance-off concepts; the source of La Llamada
├── dancer_shortlist.md         # Marketplace dancer shortlist from the paid-asset spike
├── screenshot-plan.md          # App Store screenshot capture spec: nine view categories × light/dark × en/es × two devices
├── screenshot-playbook.md      # Screenshot workflow: prerequisites, driver flags, workarounds, recovery
├── screenshots/                # Captured App Store screenshots produced by scripts/take_screenshots.sh (gitignored)
├── video_script.md             # App Store preview script, adapted from Conjuguer's
├── SpanishVerbFrequencies.xml  # Sketch Engine frequency export (esTenTen18) — the source of the frequency ranks
├── SpanishVerbFrequencyRanks.txt   # infinitive,rank for the 999 ranked verbs
├── verbs.csv                   # The same ranking as CSV
├── freq_unmatched.txt          # Ranked verbs with no verbModelMap row (mostly corpus junk; a few genuine gaps)
├── spanish_verbs_made_simpler.pdf  # Commercial reference: *Spanish Verbs Made Simple(r)* (gitignored)
├── french_verbs_made_simpler.pdf   # Its French companion, consulted for the sibling app (gitignored)
├── _extract_annexb.py          # Extracts Annex B from the source PDF into annex_b_verb_models.md
├── _build_verbmap.py           # Builds Conjugar/Models/verbModelMap.xml from the extracted class index + glosses
├── _phase1_prep.py             # Gloss pipeline Phase 1: builds the blind-input files per slice
├── _phase3_classify.py         # Gloss pipeline Phase 3: classifies verdicts
├── _phase3_apply.py            # Gloss pipeline Phase 3: rewrites slice_*.tsv from the Phase 2 consensus
└── _phase3_report.py           # Gloss pipeline Phase 3: renders the summary report

prompts/                        # Session plans and task briefs. Each is a self-contained prompt Josh pastes into a
│                               #   fresh session; the finished ones double as a record of how a feature was specified.
├── ui.md, ui_claude.md         # The SwiftUI migration ask and its plan
├── migrate-app-to-conjugator2-and-sortable-browse.md  # Cutover to the new engine + the all-verbs sortable browse list
├── rename-engine-types-drop-2-suffix.md   # Dropping the transitional "2" suffix from the engine types
├── migrate-groups-to-synchronized-folders.md  # Xcode groups → PBXFileSystemSynchronizedRootGroups
├── phase-2-orthographic-accent-features.md … phase-6-data-entry.md  # The engine build-out, phase by phase
├── phase-5b-alternate-forms.md            # Alternate paradigms and the deferred corner classes
├── fix-reir-oir-prefix-invariance.md      # The reír (6B-4) / oír (10) end-anchoring bug
├── verify-spanish-models-oracle.md        # Verifying spanish_models.md as the conjugation test oracle
├── verify-glosses-workflow.md             # The multi-agent gloss-verification workflow
├── convert-tests-to-swift-testing.md      # XCTest → Swift Testing for the engine suites
├── code-review.md, code_review_2.md       # The two review asks
├── code-review-recommendations.md         # Round 1 findings (July 7, 2026)
├── code-review-recommendations-2.md       # Round 2 findings (July 15, 2026) — the tracked item list, incl. item 15 (iPad)
├── ipad.md, ipad-plan.md                  # The native-iPad ask and its phased plan
├── add-models-tab.md                      # The Models tab
├── add-search-to-browse-and-models.md     # .searchable on both list screens
├── settings-view.md                       # The Settings redesign
├── analytics.md                           # The TelemetryDeck adoption
├── l10n.md                                # Localizations → L + Localizable.xcstrings
├── rename_objects.md                      # Adopting the Fowler test-double naming convention
├── sweep-comments.md                      # Sweeping numbered-suggestion and book-reference provenance comments
├── tips.md                                # TipKit
├── onboarding.md                          # The onboarding flow, ported from Conjuguer
├── icons.md                               # Alternate app icons
├── sound.md                               # The sound-and-music integration ask
├── widgets.md, widget_update.md           # The widget port and its later enrichment
├── fix-cold-launch-widget-deeplink-race.md  # The cold-launch deeplink race
├── etym-starter.md, etymology-pipeline.md, run-etymology-pipeline.md, etymology-verbs.json  # The etymology pipeline
├── example_uses.md, example-uses-pipeline.md, example-uses-stepF-verbs.json  # The example-uses pipeline
├── translate-verb-history.md              # Translating the verb-history essay into Spanish
├── apply_history_corrections.md           # Applying docs/history_corrections.md to both extracts
├── game.md, game2.md, main_game.md        # The game asks
├── game_prototype.md                      # The placeholder-art prototype
├── game_la_subida.md                      # The five-stage climb
├── game-powerups-mechanics-plan.md        # The three power-ups and three challenge mechanics
├── game_boss_llamada.md                   # The boss fight — La Llamada
├── boss_fight.md, fight_changes.md        # The boss-fight ask and its follow-up tweaks
├── game_blender_setup.md                  # Standing up the 3D → 2D sprite pipeline
├── game_dancer_realistic_spike.md, game_paid_dancer_bull_spike.md  # The two art spikes
├── game_dancer_actions.md, game_dancer_finish_actions.md, game_climb_back_view.md  # The dancer's flipbooks
├── game_bull.md, game_bull_actions.md     # The bull's flipbooks
├── matador.md, matador-wire-into-game.md  # The matador sprite and its wiring
├── game_toon_palette.md                   # The cel/toon re-render of both actors
├── game_sound_music.md                    # Game SFX and music integration
└── wire-game-music.md                     # Swapping in the three purchased Pond5 tracks

scripts/
├── README.md                   # What each script is for
├── sync_verb_history.py        # Validates docs/verb_history{,_es}.txt against the markup rules and writes it into the catalog
├── make_symbols.py             # Generates the custom SF Symbols (dancer, bull, olé) from Noun Project SVGs
├── symbol-sources/             # The source SVGs and the SF Symbols template scaffold
├── take_screenshots.sh         # Drives ios-build-verify + axe/simctl through the App Store screenshot sweep
├── prep_screenshot_sim.sh      # Prepares one simulator for one language (clean status bar, locale, appearance)
└── verify_store_media.sh       # Preflight for App Store Connect media: asserts every requirement that has bitten this project

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

asset-licenses/                 # License paper trail for third-party media bundled in the app
├── README.md
├── cgtrader-flamenco-dancer.txt, cgtrader-matador.txt, mixamo-dancer.txt, sketchfab-bull.txt  # 3D sources
├── game-sounds-pixabay.txt, pixabay-game-sfx.txt, pixabay-mpg-sfx.txt   # SFX
└── pond5-game-music.txt        # The three Pond5 music tracks (no attribution required; the in-app credit is a courtesy)

audio-sources/                  # Purchased WAV masters (gitignored); only the 192 kbps MP3s are committed

.claude/
├── ios-build-verify.config.sh  # Per-project build/verify config: scheme, simulator, FIRST_SCREEN_ID, MAIN_TABS_COORDS
└── settings.local.json         # Local Claude Code settings

Conjugar.xcodeproj/             # The Xcode project (scheme `Conjugar`)
ConjugarWidget.entitlements     # Widget entitlements (App Groups)
.swiftlint.yml                  # SwiftLint configuration
unused.rb                       # Legacy helper: finds unreferenced assets
apple.png                       # README imagery: the App Store download badge
Images/                         # README imagery: Splash.png (the DancerIcon hero) plus the ten 800 px-wide
                                #   screenshots of the shipping app. Regenerate from docs/screenshots/ (gitignored)
build.log                       # Raw xcodebuild output from the last ios-build-verify run (gitignored)
```
