# Game Center Setup

What Conjugar's Game Center configuration is, where it lives, and how to change it. Written
2026-11-23, when each quiz level got its own leaderboard; the achievements were added 2026-11-24.

## Where the Configuration Lives

In two places, which should agree:

- **App Store Connect**, under **Apps** › Conjugar › **Distribution** › **Game Center** (in the
  sidebar, under Growth & Marketing). This is the configuration players see. The page's address is
  `https://appstoreconnect.apple.com/apps/1236500467/distribution/gamecenter`.
- **`Conjugar/GameCenterResources.gamekit/`**, Xcode's local copy of the configuration, in the app
  target's Copy Bundle Resources. Xcode's Game Progress Manager reads it to test leaderboards on a
  device before App Store Connect serves them. It was written by hand from what App Store Connect
  shows, in the shape of the API attributes that Xcode's own files use. **Open it in Xcode once to
  confirm that the editor reads it**; the build only copies the file and would not notice a schema
  mistake. It holds the achievements' images but no leaderboard image, since the live leaderboard's
  (`flag.png`) is only in App Store Connect. Removing a leaderboard from this file does not remove it from App Store Connect.

## The Leaderboards

| Reference name | Leaderboard ID | English | Spanish (Spain and Mexico) |
|---|---|---|---|
| leaderboard | `biz.joshadams.Conjugar.leaderboard` | Leaderboard | (none) |
| Beginner | `conjugar.level.beginner` | Beginner | Inicial |
| Elementary | `conjugar.level.elementary` | Elementary | Elemental |
| Intermediate | `conjugar.level.intermediate` | Intermediate | Intermedio |
| Advanced | `conjugar.level.advanced` | Advanced | Avanzado |

`biz.joshadams.Conjugar.leaderboard` is the original, live, and the app's Default. The
shipped app posts every quiz's score to it, by loading the default leaderboard's ID. Nothing on
`master` posts to it. The other four belong to the levels, and the code takes their IDs from
`QuizLevel.leaderboardID` in `Conjugar/Utils/GameCenter.swift`.
`QuizLeaderboardTests.eachLevelHasItsOwnLeaderboard` pins each ID literally.

**Leaderboard IDs are permanent.** App Store Connect will not edit one after creation, and a
leaderboard can no longer be deleted once it has been submitted for review or is live. A level
renamed later keeps its ID. The `conjugar.` prefix matches the sibling apps' (`konjugieren.level.*`).

Each level leaderboard has the same settings:

| Setting | Value | Why |
|---|---|---|
| Type | Classic | Scores never reset. |
| Score Format | Integer | Scores are whole points. |
| Score Range | 0 to 100 | A ranked score is the first ten questions' points, at most 10 each, so Game Center rejects anything else. |
| Score Submission Type | Best Score | A player's best session stands. |
| Sort Order | High to Low | **The form defaults to Low to High.** Check it. |
| Hidden | No | |
| Score Format Suffix | None | The live board has none either. |
| Image | None | Optional. |

Each has three localizations: English (U.S.), Spanish (Spain), and Spanish (Mexico), the last two
identical, so that a player in Spain or in Latin America sees Spanish. The display name is the
level's name in the app. The description (at most 120 characters; a display name is at most 30):

- English: "The first ten questions of a quiz over all verbs at the Beginner level" (and so on per level)
- Spanish: "Las diez primeras preguntas de un test sobre todos los verbos en el nivel Inicial" (and so on)

The live board has an English localization only.

**What posts.** A quiz over every verb posts the points of its first ten questions, a right second
attempt's 5 included and re-asks not, to the leaderboard of the level it was started at. Ten More
posts nothing. A quiz over My Verbs, a collection, or one verb's page posts nothing. See
[`feature_architecture.md`](feature_architecture.md#quiz).

**Ties.** Many players will tie at 100. Nothing breaks ties, which suits practice over examination
and a clock that is hidden by default.

**Where a player sees them.** The quiz's end no longer opens Game Center. While the player is
signed in, the Quiz tab ends with a small View Leaderboard button, which opens the board of the
player's level, and Settings offers View Leaderboards, which opens Game Center's list of the app's boards.

## Creating a Leaderboard

As App Store Connect presented it on 2026-11-23:

1. **Apps** › Conjugar. The app opens on Distribution.
2. In the sidebar, under Growth & Marketing, click **Game Center**.
3. Click the **+** beside **Leaderboards (n)**.
4. **Add Leaderboard:** enter the Reference Name (internal only) and the Leaderboard ID (up to 100
   characters). Click **Next**.
5. **Choose Leaderboard Type:** Classic Leaderboard. Click **Next**.
6. **Choose Score Format:** set Score Format, Score Range, Score Submission Type, and Sort Order as
   in the table above. Click **Create**. The leaderboard opens with the status "Prepare for
   Submission".
7. Under **Leaderboard Localization**, click **Add Localization** (later the **+** beside the
   heading). Choose the language, enter the Display Name and the description, leave the suffixes
   empty and Score Format (Optional) on "Choose...", so that the localization inherits Integer, and
   click **Save**. Repeat for each language.
8. Do **not** click **Add for Review** until the release that uses the leaderboard is being
   submitted (below).

Leave **Leaderboard Sets** alone. Once an app has one set, App Store Connect requires every future
leaderboard to belong to a set, and four leaderboards gain nothing from one.

## On Release Day

The four level leaderboards are in "Prepare for Submission" and reach players only when Apple
approves them. Apple's help (*Submit Game Center components*) says to include components in the
same submission as the app version the first time they are added:

1. On the app version's page, make sure the **Game Center** checkbox is on.
2. On each level leaderboard's page, click **Add for Review** and add it to the draft submission
   that holds the new app version. Then submit.
3. **Make Beginner the default**, since the default is still the live board. On the Game Center
   page, hover over Beginner's row in the Default column and click **Make Default** (Apple's
   *Manage leaderboards*). The code never reads the default any more, so this only decides which
   board Game Center shows first.
4. After the release is live, archive the old board: on its page, **Archive Leaderboard** ›
   **Archive**. App Store Connect cannot delete a live leaderboard. Archiving removes it from Game
   Center's interface and from `GKLeaderboard` within about 24 hours, and can be undone. An older
   install that is never updated will then post to an archived board, which Game Center hides.

## Testing Before Release

Apple's help (*Overview of testing Game Center*) says prerelease testing happens in the same server
environment as released apps, once the leaderboards are added to the app version under test, and
that friends can see scores on leaderboards not yet released. Konjugieren's attempt to test its
level boards from a development build on 2026-11-14 found them invisible, likely because no app
version yet held them, and found that the scheme's GameKit debug mode hid every board. Conjugar's
shared scheme has no GameKit debug mode.

So the test waits for the 2027 version. Once it is created in App Store Connect, add the four
boards to it (On Release Day, steps 1 and 2, without submitting), then, **before** submitting:
build to the iPhone from Xcode, sign in to Game Center if not already, enable Game Center in
Conjugar's Settings, finish a ten-question quiz over all verbs at some level, and tap **View
Leaderboard** at the foot of the Quiz tab. It should open that level's board with the score. In Settings, **View
Leaderboards** should open the list of the app's boards. Remove the test scores afterward (Apple's
*Remove leaderboard test data*). [`release.md`](release.md) carries the reminder.

## The Achievements

Eight achievements, each for a mastery milestone rather than for volume of play. An item counts
once it is **mastered**, as the app's Mastery page counts it: in the third box of the review
ladder, a week or more from its next review. The code is `Conjugar/Models/Achievement.swift`, and
`AchievementTests.eachIDIsPinned` pins each ID literally. **None of them exists in App Store
Connect yet.** They are in `GameCenterResources.gamekit`, written by hand in the shape of App Store
Connect's API attributes (`vendorIdentifier`, `points`, `showBeforeEarned`, `repeatable`,
`beforeEarnedDescription`, `afterEarnedDescription`), as the leaderboards were, with their images. **Open it in Xcode
once to confirm that the editor reads them.**

| # | Reference name | Achievement ID | Points | Milestone |
|---:|---|---|---:|---|
| 1 | Patterns Beginner | `conjugar.achievement.patterns.beginner` | 10 | All 24 regular patterns that Beginner asks (27 with vosotros) |
| 2 | Patterns Elementary | `conjugar.achievement.patterns.elementary` | 25 | All 87 that Elementary asks (102) |
| 3 | Patterns Intermediate | `conjugar.achievement.patterns.intermediate` | 50 | All 162 that Intermediate asks (195) |
| 4 | Patterns Advanced | `conjugar.achievement.patterns.advanced` | 100 | All 297 that Advanced asks (357) |
| 5 | Pillars | `conjugar.achievement.verbs.pillars` | 25 | ser, estar, haber, tener, ir, and hacer |
| 6 | Core 10 | `conjugar.achievement.verbs.core10` | 25 | The 10 most used irregular verbs, ser to ver |
| 7 | Core 25 | `conjugar.achievement.verbs.core25` | 50 | The 25 most used, ser to venir |
| 8 | Core 50 | `conjugar.achievement.verbs.core50` | 100 | All 50 that the Mastery page lists, ser to leer |

385 of Apple's 1,000 points, so there is room for more. Apple's limits, from its GameKit article
"Rewarding players with achievements": at most 100 achievements, 100 points per achievement, and
1,000 points in all. A point value cannot change once the achievement has been live, and the ID
never can. The `conjugar.` prefix matches the leaderboards' and the sibling apps'.

A pattern is a tense, a person, and an ending (-ar, -er, -ir) where a regular verb's form is
regular, so the counts depend on whether the learner's region asks vosotros. A pattern achievement
counts its level's patterns in the learner's own tú or vos and region, whatever level is chosen. A
verb counts once each of its key conjugations that Advanced asks is mastered (tener's tengo, tuve,
and tendré; tenido is regular, so never), whatever level is chosen, so that switching to Beginner,
which asks only the presente and the commands, earns no verb. The 10 and 25 are the first of the
Mastery page's 50, the most frequent irregular verbs as the verb page's pill counts them, spelling
changes (llegar) and prefixed compounds (mantener) included; the six pillars are all among the
first eight.

Each has the same settings: **Hidden** No (a learner should see what to aim for), **Achievable More
Than Once** No.

### Names and Descriptions

The theme is the painted tile shared by Spain's azulejos and Mexico's Talavera. A regular pattern
is a tile pattern, so the patterns grow from one tile to a border, a mural, and a whole tiled
courtyard; the verbs are the tiled columns that hold up the rest, then painted number plaques. Each
localization has three locales, English (U.S.), Spanish (Spain), and Spanish (Mexico), the Spanish
two identical, as for the leaderboards.

| # | English name | Pre-earned description | Earned description |
|---:|---|---|---|
| 1 | The Tile | Master all 24 regular patterns that Beginner asks, 27 with vosotros. A pattern is mastered once its next review is a week or more away. | Every regular pattern of Beginner, mastered. |
| 2 | The Border | Master all 87 regular patterns that Elementary asks, 102 with vosotros. A pattern is mastered once its next review is a week or more away. | Every regular pattern of Elementary, mastered. |
| 3 | The Mural | Master all 162 regular patterns that Intermediate asks, 195 with vosotros. A pattern is mastered once its next review is a week or more away. | Every regular pattern of Intermediate, mastered. |
| 4 | The Courtyard | Master all 297 regular patterns that Advanced asks, 357 with vosotros. A pattern is mastered once its next review is a week or more away. | Every regular pattern of Advanced, mastered. |
| 5 | The Pillars | Master ser, estar, haber, tener, ir, and hacer: the forms their irregular conjugations are built on, as in tengo · tuve · tendré, in every tense Advanced asks. | ser, estar, haber, tener, ir, and hacer, mastered. |
| 6 | Ten Irregulars | Master the 10 most used irregular verbs, ser to ver: the forms their irregular conjugations are built on, as in tengo · tuve · tendré, in every tense Advanced asks. | The 10 most used irregular verbs, mastered. |
| 7 | Twenty-Five Irregulars | Master the 25 most used irregular verbs, ser to venir: the forms their irregular conjugations are built on, as in tengo · tuve · tendré, in every tense Advanced asks. | The 25 most used irregular verbs, mastered. |
| 8 | Fifty Irregulars | Master the 50 most used irregular verbs, as the Mastery page lists them: the forms their irregular conjugations are built on, as in tengo · tuve · tendré, in every tense Advanced asks. | The 50 most used irregular verbs, mastered. |

| # | Nombre | Descripción antes | Descripción después |
|---:|---|---|---|
| 1 | El azulejo | Domina los 24 patrones regulares que pregunta el nivel Inicial, 27 con vosotros. Un patrón está dominado cuando su próximo repaso queda a una semana o más. | Todos los patrones regulares del nivel Inicial, dominados. |
| 2 | La cenefa | Domina los 87 patrones regulares que pregunta el nivel Elemental, 102 con vosotros. Un patrón está dominado cuando su próximo repaso queda a una semana o más. | Todos los patrones regulares del nivel Elemental, dominados. |
| 3 | El mural | Domina los 162 patrones regulares que pregunta el nivel Intermedio, 195 con vosotros. Un patrón está dominado cuando su próximo repaso queda a una semana o más. | Todos los patrones regulares del nivel Intermedio, dominados. |
| 4 | El patio | Domina los 297 patrones regulares que pregunta el nivel Avanzado, 357 con vosotros. Un patrón está dominado cuando su próximo repaso queda a una semana o más. | Todos los patrones regulares del nivel Avanzado, dominados. |
| 5 | Los pilares | Domina ser, estar, haber, tener, ir y hacer: las formas en que se basan sus conjugaciones irregulares, como tengo · tuve · tendré, en todos los tiempos del nivel Avanzado. | ser, estar, haber, tener, ir y hacer, dominados. |
| 6 | Diez irregulares | Domina los 10 verbos irregulares más usados, de ser a ver: las formas en que se basan sus conjugaciones irregulares, como tengo · tuve · tendré, en todos los tiempos del nivel Avanzado. | Los 10 verbos irregulares más usados, dominados. |
| 7 | Veinticinco irregulares | Domina los 25 verbos irregulares más usados, de ser a venir: las formas en que se basan sus conjugaciones irregulares, como tengo · tuve · tendré, en todos los tiempos del nivel Avanzado. | Los 25 verbos irregulares más usados, dominados. |
| 8 | Cincuenta irregulares | Domina los 50 verbos irregulares más usados, como los lista la página Dominio: las formas en que se basan sus conjugaciones irregulares, como tengo · tuve · tendré, en todos los tiempos del nivel Avanzado. | Los 50 verbos irregulares más usados, dominados. |

### The Artwork

Apple requires an image for each achievement, in each localization: a `.jpeg`, `.jpg`, or `.png`
file of 1024 × 1024 pixels, at least 72 ppi, in the RGB color space. Game Center shows it in a
circle, so each image is a round medallion with everything important inside the middle 80%. The
same image serves every locale; only the number plaques carry anything to read, a numeral.

The drafts were made with the `gpt-image` skill (`gpt-image-2.5-sunburst`, high quality, 1024 ×
1024, opaque), two per achievement, sixteen in all, for about $0.86. Every prompt began with one
shared preamble that keeps them a set and names the colors of `Conjugar/Assets.xcassets` by hex
value: a burnished gold rim in `customYellow` (#CDA51B, shading to its light value #8A6600), a
cream glaze in `customCardBackground`'s light value (#F2F2F7), cobalt in `customBlue` (#1E56E0 and
#5587FF), `customRed` (#C1001D), touches of `customGreen` (#1E7A36), and black (#000000) outside the
medallion. `customCardBorder` is the yellow at 8% opacity, so it was not named. Each prompt then
named its subject: one tile set as a diamond; a border band of five tiles; a mural of some
thirty-six tiles around a red star; a tiled courtyard with a fountain and a gold star; tiled columns
under arches; and Talavera number plaques reading 10, 25, and 50, the last in a laurel wreath. The
preamble, the subjects, the script that ran them, each draft's prompt, and the two contact sheets
Josh chose from are in [`plans/achievement_art/`](../plans/achievement_art/). The sixteen PNG
drafts are gitignored, so only Josh's Mac keeps them; the chosen eight are in the `.gamekit`.

Josh chose the first draft of each on 2026-11-24. The Pillars shows five columns, not six; he kept
it, since nobody counts them. The images are in
`GameCenterResources.gamekit/<locale>/AchievementImage-<ID>-<locale>.jpg`, the same image under
`en-US`, `es-ES`, and `es-MX`, and these are the files to upload. They are **JPEGs at quality 92**,
1024 × 1024, RGB, 72 ppi, about 0.3 MB each and 7.5 MB for the twenty-four, which the build copies
into the app. Konjugieren found that PNGs cost five times as much for no visible difference.

### Creating an Achievement

As Apple's "Manage achievements" help page gives the steps (not yet followed in App Store Connect
itself, so check each step against what the page shows):

1. **Apps** › Conjugar › **Game Center** in the sidebar, as for a leaderboard.
2. Click **Add Achievement**, or the **+** beside Achievements once one exists.
3. Enter the Reference Name and the Achievement ID from the first table. Click **Create**.
4. Enter the Point Value, and leave Hidden and Achievable More Than Once off.
5. Under **Achievement Localization**, click **Add Localization**. Choose English (U.S.), enter
   the name, both descriptions, and the image. Click **Save**. Repeat for Spanish (Spain) and
   Spanish (Mexico).
6. Click **Save** again.
7. Do **not** add it for review until the release that reports it (below).

Game Center lists the achievements in App Store Connect's order; **Edit Order** changes it. Keep
the table's order: the patterns by level, then the verbs.

### How the App Reports Them

`Achievement.progress` computes each achievement's progress from the practice record, and
`GameCenter.reportAchievementProgress(_:)` takes it as a percentage, so Game Center shows an
unearned achievement's progress. A quiz reports when it finishes or is quit, and revealing a review
card reports, the moments an item can reach the third box. Nothing is computed or sent while the
player is signed out. Once a player signs in, `GameCenterReal` loads what Game Center already holds
(`GKAchievement.loadAchievements`), reports from the record, and from then on sends only what has
risen. The record can fall, a wrong answer sending an item back down the ladder, but an achievement
once earned stays earned. Game Center shows its own banner when one completes
(`showsCompletionBanner`).

The Quiz tab's **View Achievements** and Settings' Achievements row open Game Center's achievements
(`GKAccessPoint.shared.trigger(state: .achievements)`). Both appear only while signed in.

### Release Day and Testing

Add the eight achievements for review with the version, as for the level leaderboards (On Release
Day, above). Apple says achievements must be approved before they are available to players, and
that a development build sees unreleased ones with a prerelease indicator. Given what Konjugieren's
test found with its leaderboards, expect them to be visible to a development build only once they
are added to the version under test. Then, on Josh's iPhone signed in to Game Center: finish a quiz,
open **View Achievements**, and check that the eight are listed with any progress. Earning one for
real takes at least a week of practice (a first right answer, then more as each falls due).
