# Game Center Setup

What Conjugar's Game Center configuration is, where it lives, and how to change it. Written
2026-11-23, when each quiz level got its own leaderboard.

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
  mistake. It holds no image, since the live leaderboard's (`flag.png`) is only in App Store
  Connect. Removing a leaderboard from this file does not remove it from App Store Connect.

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
signed in, a ranked quiz's results offer View Leaderboard, which opens its level's board, and
Settings offers View Leaderboards, which opens Game Center's list of the app's boards.

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
Leaderboard** on the results. It should open that level's board with the score. In Settings, **View
Leaderboards** should open the list of the app's boards. Remove the test scores afterward (Apple's
*Remove leaderboard test data*). [`release.md`](release.md) carries the reminder.
