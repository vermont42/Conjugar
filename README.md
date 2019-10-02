![Conjugar](Conjugar/launch.png "Conjugar's Launch Screen")

### Introduction

**Conjugar** is an iPhone™ app for learning Spanish verb conjugations. **Conjugar** conjugates most Spanish verbs, regular and irregular, in **all** Spanish verb tenses. There is a quiz mode with three difficulty levels. Results from quizzes are available in Game Center™. On a pedagogical note, **Conjugar** contains descriptions of the tenses.

**Conjugar** uses dependency injection (DI) and programmatic layout (PL). Thus, if you are curious about how to implement DI or PL, **Conjugar** may be instructive. I have written tutorials on [DI](https://racecondition.software/blog/dependency-injection/) and [PL](https://racecondition.software/blog/programmatic-layout/).

### Installation

**Conjugar** is available for free download in the iOS App Store™. Tap the logo below to install.

[![Install](apple.png)](https://itunes.apple.com/us/app/conjugar/id1236500467?mt=8)

Alternatively, you can clone this repo and build, using Xcode™, **Conjugar** yourself.

**Conjugar** is currently using AWS Pinpoint analytics. The two relevant frameworks are in source control, but the configuration files and folder, in particular `awsconfiguration.json`, `.amplifyrc`, and `amplify`, respectively, are excluded from source control by the `.gitignore` file. For instructions on Pinpoint configuration, see this excellent [tutorial](https://itnext.io/integrate-analytics-into-your-ios-swift-applications-with-aws-amplify-20d31fe0a20e).

### License

If Conjugar is in the App Store, why is the code on GitHub? I created this app to demonstrate programmatic layout for a conference talk, and I wish to provide helpful example code for folks who are curious about programmatic layout. I originally released Conjugar's source code under the MIT License because that license is maximally convenient for would-be users of the programmatic-layout code. This was a mistake. Some dirtbag released a _clone_ of Conjugar on the App Store that differs only in that it has a hideous app icon, that it requests push-notification permission, and that it crashes on launch. I have changed the MIT License to the GNU Affero General Public License in order to impose onerous requirements on would-be cloners of Conjugar.

### Screenshots

![Conjugar](Conjugar/browse.png "Browse View of Verbs")

![Conjugar](Conjugar/verb.png "One Verb's Conjugations")

![Conjugar](Conjugar/quiz.png "Quiz in Progress")

![Conjugar](Conjugar/browseInfo.png "Info Available")

![Conjugar](Conjugar/info.png "Info on One Tense")

![Conjugar](Conjugar/GameCenter.png "Conjugar in Game Center")

![Conjugar](Conjugar/leaderboard.png "Conjugar's Game Center Leaderboard")
