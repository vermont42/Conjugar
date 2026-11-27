# The 2027 Release

What the next App Store release of Conjugar must do, gathered in one place. `CLAUDE.md` § No
Release Before 2027 points here. Add to this document whenever work on `master` leaves a step for
release time, and delete it, along with that `CLAUDE.md` section, once the release has shipped and
every item below is done. Privacy-policy lines are the exception: they wait, word for word, in
`docs/privacy_policy_pending.md`, and this document says only when to apply them.

## Why There Is No Release Before 2027

Josh cannot cut an App Store release of Conjugar, Conjuguer, or Konjugieren from his present
MacBook, and he plans to replace it in 2027. He said so on 2026-11-10. Until then, work accumulates
on `master` and the shipped version, 3.1, does not change. Text hosted outside the app, such as the
privacy policy, can still change at any time, which is why new policy lines are staged rather than
deployed.

What has accumulated since 3.1 is recorded in the plans' Status tables
([`plans/browse_and_verb_implementation.md`](../plans/browse_and_verb_implementation.md) and
[`plans/pedagogy_implementation.md`](../plans/pedagogy_implementation.md)), which are the raw
material for the release notes in `docs/release_notes.txt`.

## Before Submitting

1. **Create the new version in App Store Connect.**
2. **Check the lookup signals on a device.** The simulator never sends signals (its world uses
   `AnalyticsSpy`), so `finishSearch`, `leaveVerbView`, and `viewVerbView`'s `source` have been
   seen only in a temporary log. Run a Debug build on a device, flip the
   TelemetryDeck dashboard's Test Mode toggle, and confirm that a search, a verb page, a widget tap
   (`source` `widget`), and the Random Verb control (`source` `control`) arrive with the parameters
   in `docs/feature_architecture.md` § Analytics. A tap of a verb page's share button should send
   `tapShareVerb`, which no log has shown, since the spy does not print.
3. **Share a verb's page from a device** into Messages and Mail. The share
   sheet, its header, and its Copy were tried only in the simulator. Check that the App Store link
   is tappable in both and that the gloss's quotation marks survive, in English and Spanish.
4. **Try Find a Verb from Control Center and the Home Screen on a device**.
   In the simulator the quick action was tried with the app running and not running, but the
   control was never added to Control Center; only its link was drained. Add the control, tap it
   with the app closed and open, and check that the Verbs tab opens with the search field focused
   and the keyboard up. Check the quick action's title in Spanish ("Buscar un verbo") too. With
   Test Mode on, a search begun from each should send `finishSearch` with `source` `control` or
   `quickAction`.
5. **Try the shortcuts and Spotlight on a device**. In the simulator, Look
   Up a Verb opened the right page or search but its answer was never seen or heard first, Siri
   was never tried, and Spotlight matched only titles. On a device: ask Siri "Look up a verb with
   Conjugar", say "tuve", and check that it speaks "tuve: Pretérito (yo) of tener" before opening
   tener's page with tuve marked; then "fue", which should name ser and ir and open the search.
   Run Start a Quiz and Random Verb from the Shortcuts app with Conjugar closed, and by Siri with
   Conjugar open in front: since 2026-11-26 the intent announces its link and an app in front
   opens it at once (`PendingDeeplink`), so neither should wait for the next time the app becomes
   active. In
   Spotlight, search "aprendimos", "learn", and "tuve": if they find aprender, aprender, and
   tener, the keywords work; if only "aprender" does, record it in `docs/feature_architecture.md`
   § Spotlight. Spotlight is now indexed only when the build or the verb count changes: install
   the release build over the previous one and check that "aprender" finds the verb after the first
   launch, then that a second launch leaves it there. After installing from a backup restore, if
   the chance comes, check the same. On a Spanish-language device, check that the word prompt reads "¿Qué palabra debe
   consultar Conjugar?" (the simulator showed it in English after a language switch). With Test
   Mode on, a lookup that opens a page should send `viewVerbView` with `source` `lookup`, and a
   Spotlight tap `source` `spotlight`.

6. **Try a quiz's Live Activity and an abandoned quiz on a device.** Neither was seen in the
   simulator. Start a quiz over all verbs and check the Lock Screen and the Dynamic Island: the
   question count should read 1/10, grow by one after a wrong answer (its re-ask), and show no time
   while Settings' Quiz Clock is Hide, and the time when it is Show. Tap Ten More at the results and
   check that a new activity starts at 11/20. With Test Mode on, quit one quiz, finish a round of
   another, and leave a third mid-question by swiping the app away; the next launch should send
   `abandonQuiz` with the question reached, and the others `quitQuiz` and `completeQuiz` with a
   `duration` band.
7. **Test the level leaderboards from a development build.** Add the four `conjugar.level.*`
   leaderboards to the new version (Add for Review into the version's draft submission, without
   submitting), then follow [`game_center_setup.md`](game_center_setup.md) § Testing Before
   Release: finish a quiz over all verbs, go back to the Quiz tab, tap View Leaderboard at the foot
   of the tab, and check that the level's board shows the score; check Settings' View Leaderboards
   too. With Test Mode on, `tapViewLeaderboard` should arrive, with `level` and `source` `tab` from
   the Quiz tab.
8. **Test the achievements from the same build.** Add the eight `conjugar.achievement.*`
   achievements to the version too, then tap View Achievements at the foot of the Quiz tab and in
   Settings, and check that Game Center lists all eight in order, with their art and any progress
   the practice record has made. See [`game_center_setup.md`](game_center_setup.md) § Release Day
   and Testing. With Test Mode on, `tapViewAchievements` should arrive, with `source` `tab` from
   the Quiz tab and nothing from Settings.
9. **Try the daily reminder on a device.** In Settings, turn Daily Reminder on, allow
   notifications at the system's request, and set the time two minutes ahead. Lock the device. The
   reminder should arrive at that time, titled "Time to Practice" and saying how many conjugations
   are due. Tap it: the app should open on the Quiz tab with a daily session under way and its
   field focused. With Test Mode on, its `startQuiz` should carry `source` `reminder`, finishing it
   should send `completeQuiz` with a `streak` band, and turning the reminder off and on should send
   `tapDailyReminder` with `enabled`. On the simulator the reminder fired at its time, but AXe's taps
   could not open it from the Lock Screen, so the tap's path through `ReminderNotificationDelegate`
   has not been tried. Turn notifications off for Conjugar in the Settings app and check that
   Settings' Daily Reminder shows its red line and Open Settings.
10. **Try the daily challenge on two devices and the quiz widget.** On two devices with the same
    date, level, and region, the Quiz tab's Daily Challenge should ask the same five questions.
    Finish it on one, tap the row's share symbol, and send the text to the other in Messages: the
    dots should draw as colored circles there, and tapping the `conjugar://` link should open the
    same challenge, or the hub if it was taken. Add the quiz widget to a Home Screen: its question
    should be the challenge's first, and a tap beside its answers should open the challenge. With
    Test Mode on, `startQuiz` should carry `source` `challenge`, `challengeLink`, or
    `challengeWidget`, and Share Result should send `tapShareChallenge` with `level`. Only the
    widget's bundle was checked on the simulator, never the widget on a Home Screen.
11. **Leave the widgets overnight without opening the app.** The app writes a week of verbs and
    questions, and the widgets' timelines change at each midnight (Phase 4 of
    `plans/verb_browse_fixes.md`). With the Verb of the Day and quiz widgets on a device's Home
    Screen and a Verb of the Day accessory on its Lock Screen, note the verb and the question, and
    leave the app closed for two nights. Each morning both should have changed, the quiz widget
    unanswered. Answer it, and it should flip to its result. On the simulator the timeline was
    checked with a file whose days were shifted back, never across a real midnight on a device.
12. **Delete the practice record's migration.** `PracticeStore.migrated(from:calendar:)` and
    `LegacyLearnerVerbs` (`Models/PracticeStore.swift`) read the per-verb review schedules that
    `LearnerVerbs.Entry.review` kept before the practice record. Both formats exist only on
    `master`, and no shipped build wrote either, so the migration has nothing to read on a
    learner's device (G5 of `docs/verb_browse_review.md`; Josh's decision of 2026-11-25). Delete
    the function and the struct, and let `PracticeStore.init` start an empty record when nothing is
    stored. Delete `PracticeRecordTests.theFirstLaunchMigratesTheReviewCardsSchedules`, and keep
    `anUnreadableRecordIsBackedUpAndNotMigratedOver` for its backup, renamed and without its
    `LearnerVerbs` seed. Then correct the prose: `init`'s doc comment (which says `getterSetter`
    must hold `LearnerVerbs` for the migration's sake; the shared store stays, since `World` gives
    both stores one), the paragraph **The migration** in `docs/feature_architecture.md` and the
    sentence there about Reset Practice saving the record empty "so the next launch does not
    migrate the old schedules again", the suite's header comment in `PracticeRecordTests.swift`,
    and the entry for `PracticeStore.swift` in `docs/project_structure.md`. A simulator that has
    launched since the practice record arrived already stores one, so the migration no longer runs
    there either, and deleting it changes nothing on Josh's simulators.

## On Release Day

1. **Deploy the staged privacy-policy lines.** Apply `docs/privacy_policy_pending.md` to
   `docs/privacy_policy3.txt`, in English and Spanish, by its own instructions, and publish the
   policy the day the release that sends the new signals goes live.
2. **Submit the level leaderboards with the version.** Each `conjugar.level.*` leaderboard must be
   in the same submission as the app version, with the version's Game Center checkbox on. Make
   Beginner the Default. See [`game_center_setup.md`](game_center_setup.md) § On Release Day.
3. **Submit the eight achievements with the version**, in the same submission, as for the
   leaderboards. See [`game_center_setup.md`](game_center_setup.md) § The Achievements.
4. **Once the release is live, archive the old leaderboard**, `biz.joshadams.Conjugar.leaderboard`,
   which the shipped app posts to until then.

## Afterward
