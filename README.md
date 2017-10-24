![Conjugar](Conjugar/launch.png "Conjugar's Launch Screen")

### Introduction

**Conjugar** is an iPhone™ app for learning Spanish verb conjugations. **Conjugar** conjugates most Spanish verbs, regular and irregular, in **all** Spanish verb tenses. There is a quiz mode with three difficulty levels. Results from quizzes are available in Game Center™. On a pedagogical note, **Conjugar** contains descriptions of the tenses.

### Installation

**Conjugar** is available for free download in the iOS App Store™. Tap the log below to install.

[![Install](apple.png)](https://itunes.apple.com/us/app/conjugar/id1236500467?mt=8)

Alternatively, you can clone this repo and build, using Xcode™ 9, **Conjugar** yourself. Building **Conjugar** for the simulator (but not iPhone™) causes the following warning, truncated for clarity: `objc[10192]: Class VCWeakObjectHolder is implemented in both ... Frameworks/ViceroyTrace.framework/ViceroyTrace (0x1269c97c0) and  ... AVConference (0x126857a18). One of the two will be used. Which one is undefined."`

The immediate cause of this warning is linking GameKit.framework, required for Game Center™ support. This [appears](https://forums.developer.apple.com/thread/63254) appears to be a vendor bug.

### Screenshots

![Conjugar](Conjugar/browse.png "Browse View of Verbs")

![Conjugar](Conjugar/verb.png "One Verb's Conjugations")

![Conjugar](Conjugar/quiz.png "Quiz in Progress")

![Conjugar](Conjugar/browseInfo.png "Info Available")

![Conjugar](Conjugar/info.png "Info on One Tense")

![Conjugar](Conjugar/GameCenter.png "Conjugar in Game Center")


![Conjugar](Conjugar/leaderboard.png "Conjugar's Game Center Leaderboard")
