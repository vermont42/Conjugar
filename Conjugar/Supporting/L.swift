//
//  L.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/1/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum L {
  enum Accessibility {
    // The VoiceOver action name for a tappable conjugation form: the tap
    // gesture that speaks a form is skipped under VoiceOver, so an accessibility
    // action exposes the same "hear it pronounced" affordance.
    static var speak: String {
      String(localized: "Accessibility.speak")
    }
  }

  enum Alert {
    static var okay: String {
      String(localized: "Alert.okay")
    }

    static var gotIt: String {
      String(localized: "Alert.gotIt")
    }
  }

  enum Both {
    static var masculine: String {
      String(localized: "Both.masculine")
    }

    static var feminine: String {
      String(localized: "Both.feminine")
    }
  }

  enum BrowseInfo {
    static var localizedTitle: String {
      String(localized: "BrowseInfo.localizedTitle")
    }

    static var easy: String {
      String(localized: "BrowseInfo.easy")
    }

    static var easyAndModerate: String {
      String(localized: "BrowseInfo.easyAndModerate")
    }

    static var easyModerateAndDifficult: String {
      String(localized: "BrowseInfo.easyModerateAndDifficult")
    }

    static var filter: String {
      String(localized: "BrowseInfo.filter")
    }

    static var aboutSection: String {
      String(localized: "BrowseInfo.aboutSection")
    }

    static var tensesSection: String {
      String(localized: "BrowseInfo.tensesSection")
    }
  }

  enum BrowseModels {
    static var localizedTitle: String {
      String(localized: "BrowseModels.localizedTitle")
    }

    static func modelCount(count: Int) -> String {
      String(localized: "BrowseModels.modelCount \(count)")
    }

    static var searchPrompt: String {
      String(localized: "BrowseModels.searchPrompt")
    }

    static var searchNoResults: String {
      String(localized: "BrowseModels.searchNoResults")
    }
  }

  enum BrowseVerbs {
    static var localizedTitle: String {
      String(localized: "BrowseVerbs.localizedTitle")
    }

    static var sort: String {
      String(localized: "BrowseVerbs.sort")
    }

    static func verbCount(count: Int) -> String {
      String(localized: "BrowseVerbs.verbCount \(count)")
    }

    /// What the field searches: a conjugation is to find its verb.
    static var searchPromptVerbConjugationOrMeaning: String {
      String(localized: "BrowseVerbs.searchPromptVerbConjugationOrMeaning")
    }

    static var searchNoResults: String {
      String(localized: "BrowseVerbs.searchNoResults")
    }

    /// Introduces the closest verb to a query that found nothing, and says it is a guess.
    static var guessIntro: String {
      String(localized: "BrowseVerbs.guessIntro")
    }

    /// The line under a failed search that asks for a missing verb. The address becomes a link.
    static func verbRequest(query: String, address: String) -> String {
      String(localized: "BrowseVerbs.verbRequest \(query) \(address)")
    }

    static func verbRequestSubject(query: String) -> String {
      String(localized: "BrowseVerbs.verbRequestSubject \(query)")
    }

    static func verbRequestBody(query: String) -> String {
      String(localized: "BrowseVerbs.verbRequestBody \(query)")
    }

    /// Shown for four seconds when no email app could open the request's link.
    static var addressCopied: String {
      String(localized: "BrowseVerbs.addressCopied")
    }

    /// Command-F's menu item, under Verbs in iPadOS's menu bar.
    static var findVerb: String {
      String(localized: "BrowseVerbs.findVerb")
    }
  }

  enum Difficulty {
    static var easy: String {
      String(localized: "Difficulty.easy")
    }

    static var moderate: String {
      String(localized: "Difficulty.moderate")
    }

    static var difficult: String {
      String(localized: "Difficulty.difficult")
    }
  }

  enum Game {
    static var title: String {
      String(localized: "Game.title")
    }

    static var play: String {
      String(localized: "Game.play")
    }

    static var settingsDescription: String {
      String(localized: "Game.settingsDescription")
    }

    static var quit: String {
      String(localized: "Game.quit")
    }

    static var health: String {
      String(localized: "Game.health")
    }

    static var jump: String {
      String(localized: "Game.jump")
    }

    static var moveUp: String {
      String(localized: "Game.moveUp")
    }

    static var moveDown: String {
      String(localized: "Game.moveDown")
    }

    static var moveLeft: String {
      String(localized: "Game.moveLeft")
    }

    static var moveRight: String {
      String(localized: "Game.moveRight")
    }

    // Boss fight — La Llamada. The jaleo shouts and title cards stay Spanish in BOTH
    // localizations; the narrative line and accessibility labels localize normally en/es.
    static var duelTitle: String {
      String(localized: "Game.duelTitle")
    }

    static var tuTurno: String {
      String(localized: "Game.tuTurno")
    }

    static var freezeHint: String {
      String(localized: "Game.freezeHint")
    }

    static var jaleoOle: String {
      String(localized: "Game.jaleoOle")
    }

    static var jaleoUy: String {
      String(localized: "Game.jaleoUy")
    }

    static var jaleoEso: String {
      String(localized: "Game.jaleoEso")
    }

    static var jaleoBien: String {
      String(localized: "Game.jaleoBien")
    }

    static var jaleoVamos: String {
      String(localized: "Game.jaleoVamos")
    }

    static var victoria: String {
      String(localized: "Game.victoria")
    }

    static var bullImpressed: String {
      String(localized: "Game.bullImpressed")
    }

    /// The end-scene captions name each portrait's subjects left to right, one string
    /// per name so the caption can bold whoever the camera is showing.
    static var dancerName: String {
      String(localized: "Game.dancerName")
    }

    static var bullName: String {
      String(localized: "Game.bullName")
    }

    static var matadorName: String {
      String(localized: "Game.matadorName")
    }

    static var amandaName: String {
      String(localized: "Game.amandaName")
    }

    static var vegasName: String {
      String(localized: "Game.vegasName")
    }

    static var joshName: String {
      String(localized: "Game.joshName")
    }

    static var torerosImageLabel: String {
      String(localized: "Game.torerosImageLabel")
    }

    static var familyImageLabel: String {
      String(localized: "Game.familyImageLabel")
    }

    static var pasoLeftMove: String {
      String(localized: "Game.pasoLeftMove")
    }

    static var pasoRightMove: String {
      String(localized: "Game.pasoRightMove")
    }

    static var oleMove: String {
      String(localized: "Game.oleMove")
    }

    static var stompMove: String {
      String(localized: "Game.stompMove")
    }

    static var capeMove: String {
      String(localized: "Game.capeMove")
    }

    static var duendeMeter: String {
      String(localized: "Game.duendeMeter")
    }

    // La Subida — the between-stage banner. Stays Spanish in BOTH localizations, as the
    // title cards do.
    static func nivel(_ n: Int) -> String {
      String(localized: "Game.nivel \(n)")
    }

    // La Subida — challenge-mechanic announcements (the bull "speaks" them). The zombie
    // line is a narrative sentence and localizes en/es; "¡El encierro!" / "¡Apagón!"
    // stay Spanish in BOTH localizations, as the title cards do.
    static var zombieAnnouncement: String {
      String(localized: "Game.zombieAnnouncement")
    }

    static var encierroAnnouncement: String {
      String(localized: "Game.encierroAnnouncement")
    }

    static var apagonAnnouncement: String {
      String(localized: "Game.apagonAnnouncement")
    }

    // La Subida — the two newer mechanic announcements (the bull "speaks" them). Both are
    // narrative sentences and localize en/es, following the `zombieAnnouncement` precedent.
    static var earthquakeAnnouncement: String {
      String(localized: "Game.earthquakeAnnouncement")
    }

    static var multiplyAnnouncement: String {
      String(localized: "Game.multiplyAnnouncement")
    }
  }

  enum GameCenter {
    static var failure: String {
      String(localized: "GameCenter.failure")
    }
  }

  enum Info {
    static var purposeAndUseHeading: String {
      String(localized: "Info.purposeAndUseHeading")
    }

    static var terminologyHeading: String {
      String(localized: "Info.terminologyHeading")
    }

    static var questionsAndAnswersHeading: String {
      String(localized: "Info.questionsAndAnswersHeading")
    }

    static var creditsHeading: String {
      String(localized: "Info.creditsHeading")
    }

    static var verbHistoryHeading: String {
      String(localized: "Info.verbHistoryHeading")
    }

    static var purposeAndUseText: String {
      String(localized: "Info.purposeAndUseText")
    }

    static var terminologyText: String {
      String(localized: "Info.terminologyText")
    }

    static var presenteDeIndicativoText: String {
      String(localized: "Info.presenteDeIndicativoText")
    }

    static var futuroDeIndicativoText: String {
      String(localized: "Info.futuroDeIndicativoText")
    }

    static var preteritoText: String {
      String(localized: "Info.preteritoText")
    }

    static var condicionalText: String {
      String(localized: "Info.condicionalText")
    }

    static var imperfectoDeIndicativoText: String {
      String(localized: "Info.imperfectoDeIndicativoText")
    }

    static var presenteDeSubjuntivoText: String {
      String(localized: "Info.presenteDeSubjuntivoText")
    }

    static var imperfectoDeSubjuntivo1Text: String {
      String(localized: "Info.imperfectoDeSubjuntivo1Text")
    }

    static var imperfectoDeSubjuntivo2Text: String {
      String(localized: "Info.imperfectoDeSubjuntivo2Text")
    }

    static var futuroDeSubjuntivoText: String {
      String(localized: "Info.futuroDeSubjuntivoText")
    }

    static var imperativoPositivoText: String {
      String(localized: "Info.imperativoPositivoText")
    }

    static var imperativoNegativoText: String {
      String(localized: "Info.imperativoNegativoText")
    }

    static var participioText: String {
      String(localized: "Info.participioText")
    }

    static var gerundioText: String {
      String(localized: "Info.gerundioText")
    }

    static var raizFuturaText: String {
      String(localized: "Info.raizFuturaText")
    }

    static var perifrasisVerbalesText: String {
      String(localized: "Info.perifrasisVerbalesText")
    }

    static var perfectoDeIndicativoText: String {
      String(localized: "Info.perfectoDeIndicativoText")
    }

    static var preteritoAnteriorText: String {
      String(localized: "Info.preteritoAnteriorText")
    }

    static var pluscuamperfectoDeIndicativoText: String {
      String(localized: "Info.pluscuamperfectoDeIndicativoText")
    }

    static var futuroPerfectoText: String {
      String(localized: "Info.futuroPerfectoText")
    }

    static var condicionalCompuestoText: String {
      String(localized: "Info.condicionalCompuestoText")
    }

    static var perfectoDeSubjuntivoText: String {
      String(localized: "Info.perfectoDeSubjuntivoText")
    }

    static var pluscuamperfectoDeSubjuntivo1Text: String {
      String(localized: "Info.pluscuamperfectoDeSubjuntivo1Text")
    }

    static var pluscuamperfectoDeSubjuntivo2Text: String {
      String(localized: "Info.pluscuamperfectoDeSubjuntivo2Text")
    }

    static var futuroPerfectoDeSubjuntivoText: String {
      String(localized: "Info.futuroPerfectoDeSubjuntivoText")
    }

    static var questionsAndAnswersText: String {
      String(localized: "Info.questionsAndAnswersText")
    }

    static var voseoText: String {
      String(localized: "Info.voseoText")
    }

    static var verbHistoryText: String {
      String(localized: "Info.verbHistoryText")
    }

    static var creditsText: String {
      String(localized: "Info.creditsText")
    }
  }

  // What the Look Up a Verb shortcut says. Nonisolated, as the Tips accessors are, because
  // `VerbLookup` builds its answer off the main actor.
  enum Lookup {
    /// "tener, “have”", or in Spanish "tener, «have»".
    nonisolated static func verbWithGloss(infinitive: String, gloss: String) -> String {
      String(localized: "Lookup.verbWithGloss \(infinitive) \(gloss)")
    }

    /// "fue: Pretérito (él) of ir".
    nonisolated static func form(_ form: String, cells: String, infinitive: String) -> String {
      String(localized: "Lookup.form \(form) \(cells) \(infinitive)")
    }

    nonisolated static func otherMatchesOne(_ word: String, verb: String) -> String {
      String(localized: "Lookup.otherMatchesOne \(word) \(verb)")
    }

    nonisolated static func otherMatchesMany(_ word: String, count: Int, verb: String) -> String {
      String(localized: "Lookup.otherMatchesMany \(word) \(count) \(verb)")
    }

    nonisolated static func guessVerb(_ word: String, infinitive: String) -> String {
      String(localized: "Lookup.guessVerb \(word) \(infinitive)")
    }

    nonisolated static func guessForm(_ word: String, form: String, infinitive: String) -> String {
      String(localized: "Lookup.guessForm \(word) \(form) \(infinitive)")
    }

    nonisolated static func nothing(_ word: String) -> String {
      String(localized: "Lookup.nothing \(word)")
    }
  }

  enum Model {
    static func numberAndPercent(model: String, percent: Int) -> String {
      String(localized: "Model.numberAndPercent \(model) \(percent)")
    }

    static func verbsUsing(count: Int) -> String {
      String(localized: "Model.verbsUsing \(count)")
    }

    static func modelLabel(number: String) -> String {
      String(localized: "Model.modelLabel \(number)")
    }
  }

  enum ModelSort {
    static var irregularity: String {
      String(localized: "ModelSort.irregularity")
    }

    static var classNumber: String {
      String(localized: "ModelSort.classNumber")
    }
  }

  enum Onboarding {
    static var onboarding: String {
      String(localized: "Onboarding.onboarding")
    }

    static var skip: String {
      String(localized: "Onboarding.skip")
    }

    static var dismiss: String {
      String(localized: "Onboarding.dismiss")
    }

    static var getStarted: String {
      String(localized: "Onboarding.getStarted")
    }

    static var showOnboarding: String {
      String(localized: "Onboarding.showOnboarding")
    }

    static var showOnboardingDescription: String {
      String(localized: "Onboarding.showOnboardingDescription")
    }

    static var welcomeTitle: String {
      String(localized: "Onboarding.welcomeTitle")
    }

    static var welcomeBody: String {
      String(localized: "Onboarding.welcomeBody")
    }

    static var browseTitle: String {
      String(localized: "Onboarding.browseTitle")
    }

    static var browseBody: String {
      String(localized: "Onboarding.browseBody")
    }

    static var browseVerbsButton: String {
      String(localized: "Onboarding.browseVerbsButton")
    }

    static var modelsTitle: String {
      String(localized: "Onboarding.modelsTitle")
    }

    static var modelsBody: String {
      String(localized: "Onboarding.modelsBody")
    }

    static var exploreModelsButton: String {
      String(localized: "Onboarding.exploreModelsButton")
    }

    static var quizTitle: String {
      String(localized: "Onboarding.quizTitle")
    }

    static var quizBody: String {
      String(localized: "Onboarding.quizBody")
    }

    static var startQuizButton: String {
      String(localized: "Onboarding.startQuizButton")
    }

    static var aiTitle: String {
      String(localized: "Onboarding.aiTitle")
    }

    static var aiBody: String {
      String(localized: "Onboarding.aiBody")
    }

    static var meetTutorButton: String {
      String(localized: "Onboarding.meetTutorButton")
    }

    static var learnTitle: String {
      String(localized: "Onboarding.learnTitle")
    }

    static var learnBody: String {
      String(localized: "Onboarding.learnBody")
    }

    static var readArticlesButton: String {
      String(localized: "Onboarding.readArticlesButton")
    }

    static var gameTitle: String {
      String(localized: "Onboarding.gameTitle")
    }

    static var gameBody: String {
      String(localized: "Onboarding.gameBody")
    }

    static var playGameButton: String {
      String(localized: "Onboarding.playGameButton")
    }
  }

  enum Quiz {
    static var localizedTitle: String {
      String(localized: "Quiz.localizedTitle")
    }

    static var briefing: String {
      String(localized: "Quiz.briefing")
    }

    static var yourAnswer: String {
      String(localized: "Quiz.yourAnswer")
    }

    /// What VoiceOver says before the current spelling of a right answer typed in a retired one.
    static var correctSpelled: String {
      String(localized: "Quiz.correctSpelled")
    }

    static var tense: String {
      String(localized: "Quiz.tense")
    }

    static var start: String {
      String(localized: "Quiz.start")
    }

    static var restart: String {
      String(localized: "Quiz.restart")
    }

    static var quit: String {
      String(localized: "Quiz.quit")
    }

    static var gameCenter: String {
      String(localized: "Quiz.gameCenter")
    }

    static var gameCenterMessage: String {
      String(localized: "Quiz.gameCenterMessage")
    }

    static var no: String {
      String(localized: "Quiz.no")
    }

    static var yes: String {
      String(localized: "Quiz.yes")
    }

    static var conjugation: String {
      String(localized: "Quiz.conjugation")
    }

    /// What VoiceOver calls the answer field within its frame: "yo, blank".
    static var blank: String {
      String(localized: "Quiz.blank")
    }

    static var verb: String {
      String(localized: "Quiz.verb")
    }

    static var pronoun: String {
      String(localized: "Quiz.pronoun")
    }

    static var lastAnswer: String {
      String(localized: "Quiz.lastAnswer")
    }

    static var correctAnswer: String {
      String(localized: "Quiz.correctAnswer")
    }

    static var progress: String {
      String(localized: "Quiz.progress")
    }

    static var elapsed: String {
      String(localized: "Quiz.elapsed")
    }

    static var score: String {
      String(localized: "Quiz.score")
    }

    /// The label of the start screen's picker.
    static var scope: String {
      String(localized: "Quiz.scope")
    }

    static var allVerbs: String {
      String(localized: "Quiz.allVerbs")
    }

    static func myVerbsCount(count: Int) -> String {
      String(localized: "Quiz.myVerbsCount \(count)")
    }

    static var myVerbsEmpty: String {
      String(localized: "Quiz.myVerbsEmpty")
    }

    /// After the first twelve of My Verbs' chips: "+3 more".
    static func moreVerbs(count: Int) -> String {
      String(localized: "Quiz.moreVerbs \(count)")
    }

    static var questionsLabel: String {
      String(localized: "Quiz.questionsLabel")
    }

    /// Closes Test Me's sheet once its results show.
    static var done: String {
      String(localized: "Quiz.done")
    }
  }

  enum Results {
    static var title: String {
      String(localized: "Results.title")
    }

    static var time: String {
      String(localized: "Results.time")
    }
  }

  enum Region {
    static var spain: String {
      String(localized: "Region.spain")
    }

    static var latinAmerica: String {
      String(localized: "Region.latinAmerica")
    }
  }

  /// The card above the verb list that offers an irregular verb looked up some days ago.
  enum ReviewCard {
    static var dismiss: String {
      String(localized: "ReviewCard.dismiss")
    }

    /// "Looked up yesterday", "Looked up 3 days ago", or, for nil or less than a day, "Looked up
    /// earlier".
    static func lookedUp(daysAgo: Int?) -> String {
      guard let daysAgo, daysAgo > 0 else {
        return String(localized: "ReviewCard.lookedUpEarlier")
      }
      return String(localized: "ReviewCard.lookedUp \(daysAgo)")
    }

    static var openHint: String {
      String(localized: "ReviewCard.openHint")
    }

    static var prompt: String {
      String(localized: "ReviewCard.prompt")
    }
  }

  enum ReviewCardSuppression {
    static var off: String {
      String(localized: "ReviewCardSuppression.off")
    }

    static var on: String {
      String(localized: "ReviewCardSuppression.on")
    }
  }

  enum Settings {
    static var localizedTitle: String {
      String(localized: "Settings.localizedTitle")
    }

    static var region: String {
      String(localized: "Settings.region")
    }

    static var regionDescription: String {
      String(localized: "Settings.regionDescription")
    }

    static var difficulty: String {
      String(localized: "Settings.difficulty")
    }

    static var difficultyDescription: String {
      String(localized: "Settings.difficultyDescription")
    }

    static var browse: String {
      String(localized: "Settings.browse")
    }

    static var browseDescription: String {
      String(localized: "Settings.browseDescription")
    }

    static var reviewCardSuppressionHeading: String {
      String(localized: "Settings.reviewCardSuppressionHeading")
    }

    static var reviewCardSuppressionDescription: String {
      String(localized: "Settings.reviewCardSuppressionDescription")
    }

    static var quiz: String {
      String(localized: "Settings.quiz")
    }

    static var quizDescription: String {
      String(localized: "Settings.quizDescription")
    }

    static var enable: String {
      String(localized: "Settings.enable")
    }

    static var enableDescription: String {
      String(localized: "Settings.enableDescription")
    }

    static var ratingsAndReviews: String {
      String(localized: "Settings.ratingsAndReviews")
    }

    static var rateOrReview: String {
      String(localized: "Settings.rateOrReview")
    }

    static var addYours: String {
      String(localized: "Settings.addYours")
    }

    static var noRating: String {
      String(localized: "Settings.noRating")
    }

    // A deliberately Spanish exhortation appended after `noRating`, kept Spanish in
    // both localizations by design.
    static var beFirst: String {
      String(localized: "Settings.beFirst")
    }

    static var ratingsUnavailable: String {
      String(localized: "Settings.ratingsUnavailable")
    }

    static func ratings(count: Int) -> String {
      String(localized: "Settings.ratings \(count)")
    }

    static var appIcon: String {
      String(localized: "Settings.appIcon")
    }

    static var appIconDescription: String {
      String(localized: "Settings.appIconDescription")
    }
  }

  enum AppIcon {
    static var bull: String {
      String(localized: "AppIcon.bull")
    }

    static var dancer: String {
      String(localized: "AppIcon.dancer")
    }

    static var matador: String {
      String(localized: "AppIcon.matador")
    }

    static var classic: String {
      String(localized: "AppIcon.classic")
    }
  }

  /// The learner's starred and recent verbs.
  enum MyVerbs {
    static var title: String {
      String(localized: "MyVerbs.title")
    }

    static var starred: String {
      String(localized: "MyVerbs.starred")
    }

    static var recent: String {
      String(localized: "MyVerbs.recent")
    }

    /// Forgets every verb opened and keeps the stars.
    static var clearRecent: String {
      String(localized: "MyVerbs.clearRecent")
    }

    static var delete: String {
      String(localized: "MyVerbs.delete")
    }

    static var emptyTitle: String {
      String(localized: "MyVerbs.emptyTitle")
    }

    static var emptyDescription: String {
      String(localized: "MyVerbs.emptyDescription")
    }

    /// The alert a swipe on a starred verb raises: "Remove the star from “tener”?"
    static func unstarTitle(verb: String) -> String {
      String(localized: "MyVerbs.unstarTitle \(verb)")
    }

    static var unstarMessage: String {
      String(localized: "MyVerbs.unstarMessage")
    }

    static var unstarConfirm: String {
      String(localized: "MyVerbs.unstarConfirm")
    }
  }

  /// The collections at the top of the Models tab and the bar on every model's page.
  enum VerbCollection {
    static var heading: String {
      String(localized: "VerbCollection.heading")
    }

    static var top100Title: String {
      String(localized: "VerbCollection.top100Title")
    }

    static var top100Description: String {
      String(localized: "VerbCollection.top100Description")
    }

    static var goVerbsTitle: String {
      String(localized: "VerbCollection.goVerbsTitle")
    }

    static var goVerbsDescription: String {
      String(localized: "VerbCollection.goVerbsDescription")
    }

    static var strongPreteriteTitle: String {
      String(localized: "VerbCollection.strongPreteriteTitle")
    }

    static var strongPreteriteDescription: String {
      String(localized: "VerbCollection.strongPreteriteDescription")
    }

    static var irregularFutureTitle: String {
      String(localized: "VerbCollection.irregularFutureTitle")
    }

    static var irregularFutureDescription: String {
      String(localized: "VerbCollection.irregularFutureDescription")
    }

    static var irregularParticipleTitle: String {
      String(localized: "VerbCollection.irregularParticipleTitle")
    }

    static var irregularParticipleDescription: String {
      String(localized: "VerbCollection.irregularParticipleDescription")
    }

    /// Below a pattern list's description: where its verbs come from, and why compounds are absent.
    static var patternNote: String {
      String(localized: "VerbCollection.patternNote")
    }

    /// A model's collection, which titles its quiz and its shared text: "Verbs Like tener".
    static func modelTitle(exemplar: String) -> String {
      String(localized: "VerbCollection.modelTitle \(exemplar)")
    }

    static func progress(opened: Int, total: Int) -> String {
      String(localized: "VerbCollection.progress \(opened) \(total)")
    }

    static func quizHint(questionCount: Int) -> String {
      String(localized: "VerbCollection.quizHint \(questionCount)")
    }

    /// VoiceOver's word for a row's check.
    static var lookedUp: String {
      String(localized: "VerbCollection.lookedUp")
    }

    static func shareText(title: String, verbCount: String, sample: String, link: String, appStoreLink: String) -> String {
      String(localized: "VerbCollection.shareText \(title) \(verbCount) \(sample) \(link) \(appStoreLink)")
    }
  }

  enum VerbSort {
    static var frequency: String {
      String(localized: "VerbSort.frequency")
    }

    static var alphabetical: String {
      String(localized: "VerbSort.alphabetical")
    }
  }

  enum Verb {
    /// Test Me's button in a verb page's navigation bar.
    static var testMe: String {
      String(localized: "Verb.testMe")
    }

    static var matchesSearch: String {
      String(localized: "Verb.matchesSearch")
    }

    /// Before a tense's other names under its heading: "also preterite".
    static var alsoKnownAs: String {
      String(localized: "Verb.alsoKnownAs")
    }

    /// The accessibility label of the ⓘ beside a tense's heading.
    static var aboutThisTense: String {
      String(localized: "Verb.aboutThisTense")
    }

    /// Closes a tense's article, opened over the verb page.
    static var closeArticle: String {
      String(localized: "Verb.closeArticle")
    }

    static var irregular: String {
      String(localized: "Verb.irregular")
    }

    static var regular: String {
      String(localized: "Verb.regular")
    }

    static var defective: String {
      String(localized: "Verb.defective")
    }

    static var notDefective: String {
      String(localized: "Verb.notDefective")
    }

    static func irregularWithParent(exemplar: String) -> String {
      String(localized: "Verb.irregularWithParent \(exemplar)")
    }

    /// The VoiceOver hint on the pill that names the verb's model and opens its page.
    static var showsModel: String {
      String(localized: "Verb.showsModel")
    }

    /// The share button in the verb page's navigation bar, and the label the iPad's popover
    /// anchors to.
    static var share: String {
      String(localized: "Verb.share")
    }

    /// The star in the verb page's navigation bar, while the verb is not in My Verbs.
    static var star: String {
      String(localized: "Verb.star")
    }

    /// The star in the verb page's navigation bar, while the verb is in My Verbs.
    static var unstar: String {
      String(localized: "Verb.unstar")
    }

    /// The long-press menu's item, and the VoiceOver action, that copies a form.
    static var copy: String {
      String(localized: "Verb.copy")
    }

    /// What the share button sends: "tener, “have”", the key conjugations, and the App Store link.
    static func shareText(infinitive: String, gloss: String, keyConjugations: String, link: String) -> String {
      String(localized: "Verb.shareText \(infinitive) \(gloss) \(keyConjugations) \(link)")
    }

    /// The heading of the card at the bottom of the verb page.
    static var relatedHeading: String {
      String(localized: "Verb.relatedHeading")
    }

    /// The caption over the verbs built on the same base: "Built on tener".
    static func builtOn(root: String) -> String {
      String(localized: "Verb.builtOn \(root)")
    }

    /// The caption over other verbs of the same model: "Conjugated like cantar".
    static func conjugatedLike(exemplar: String) -> String {
      String(localized: "Verb.conjugatedLike \(exemplar)")
    }

    /// The chip that opens every verb of a relation: "All 9".
    static func allRelated(count: Int) -> String {
      String(localized: "Verb.allRelated \(count)")
    }

    static var etymology: String {
      String(localized: "Verb.etymology")
    }

    static var exampleUse: String {
      String(localized: "Verb.exampleUse")
    }

    static var exampleUses: String {
      String(localized: "Verb.exampleUses")
    }

    static var medievalExample: String {
      String(localized: "Verb.medievalExample")
    }

    static var nextMedievalExample: String {
      String(localized: "Verb.nextMedievalExample")
    }

    static func exampleSource(body: String) -> String {
      String(localized: "Verb.exampleSource \(body)")
    }

    static var exampleSourceClaude: String {
      String(localized: "Verb.exampleSourceClaude")
    }
  }

  enum Tutor {
    static var section: String {
      String(localized: "Tutor.section")
    }

    static var heading: String {
      String(localized: "Tutor.heading")
    }

    static var getSampleQuery: String {
      String(localized: "Tutor.getSampleQuery")
    }

    static var getSampleQueryDescription: String {
      String(localized: "Tutor.getSampleQueryDescription")
    }

    static var poweredBy: String {
      String(localized: "Tutor.poweredBy")
    }

    static var inputPlaceholder: String {
      String(localized: "Tutor.inputPlaceholder")
    }

    static var send: String {
      String(localized: "Tutor.send")
    }

    static var unavailable: String {
      String(localized: "Tutor.unavailable")
    }

    static var unableToAnswer: String {
      String(localized: "Tutor.unableToAnswer")
    }

    static var reasonAppleIntelligenceOff: String {
      String(localized: "Tutor.reasonAppleIntelligenceOff")
    }

    static var reasonDeviceNotEligible: String {
      String(localized: "Tutor.reasonDeviceNotEligible")
    }

    static var reasonModelNotReady: String {
      String(localized: "Tutor.reasonModelNotReady")
    }

    static var reasonUnknown: String {
      String(localized: "Tutor.reasonUnknown")
    }
  }

  // The Tip protocol's `title`/`message` properties are nonisolated, so these
  // accessors must be too.
  enum Tips {
    nonisolated static var tryQuizTitle: String {
      String(localized: "Tips.tryQuizTitle")
    }

    nonisolated static var tryQuizMessage: String {
      String(localized: "Tips.tryQuizMessage")
    }

    nonisolated static var exploreModelsTitle: String {
      String(localized: "Tips.exploreModelsTitle")
    }

    nonisolated static var exploreModelsMessage: String {
      String(localized: "Tips.exploreModelsMessage")
    }

    nonisolated static var changeDifficultyTitle: String {
      String(localized: "Tips.changeDifficultyTitle")
    }

    nonisolated static var changeDifficultyMessage: String {
      String(localized: "Tips.changeDifficultyMessage")
    }

    nonisolated static var enableGameCenterTitle: String {
      String(localized: "Tips.enableGameCenterTitle")
    }

    nonisolated static var enableGameCenterMessage: String {
      String(localized: "Tips.enableGameCenterMessage")
    }

    nonisolated static var redLettersTitle: String {
      String(localized: "Tips.redLettersTitle")
    }

    nonisolated static var redLettersMessage: String {
      String(localized: "Tips.redLettersMessage")
    }

    nonisolated static var scrollToBottomTitle: String {
      String(localized: "Tips.scrollToBottomTitle")
    }

    nonisolated static var scrollToBottomMessage: String {
      String(localized: "Tips.scrollToBottomMessage")
    }
  }
}
