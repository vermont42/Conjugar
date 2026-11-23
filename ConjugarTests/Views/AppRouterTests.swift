//
//  AppRouterTests.swift
//  ConjugarTests
//
//  Deeplink routing for `AppRouter.handle(url:)`: the grammar's routes and their round trips,
//  the control's and the quick action's links, and the one-shot game flags (`pendingBossEntry` /
//  `pendingEndScene`). Those are drained only by `GameView.onAppear`, so a `game/boss` or
//  `game/end` URL arriving while the game is already presented must be ignored — otherwise the
//  stale flag would hijack the next plain `conjugar://game`.
//  Swift Testing + `@MainActor` (AppRouter is MainActor).
//

import Foundation
import Testing
import UIKit
@testable import Conjugar

@Suite("AppRouter")
@MainActor
struct AppRouterTests {
  private func url(_ string: String) -> URL { URL(string: string)! }

  @Test func plainGameDeeplinkPresentsWithoutBossOrEnd() {
    let router = AppRouter()
    router.handle(url: url("conjugar://game"))
    #expect(router.showGame)
    #expect(!router.pendingBossEntry)
    #expect(!router.pendingEndScene)
  }

  @Test func bossDeeplinkSetsPendingBossEntryWhenGameClosed() {
    let router = AppRouter()
    router.handle(url: url("conjugar://game/boss"))
    #expect(router.showGame)
    #expect(router.pendingBossEntry)
  }

  @Test func endDeeplinkSetsPendingEndSceneWhenGameClosed() {
    let router = AppRouter()
    router.handle(url: url("conjugar://game/end"))
    #expect(router.showGame)
    #expect(router.pendingEndScene)
  }

  /// The regression guard: a boss deeplink arriving while the game is already up must not
  /// leave a flag armed for the next plain launch.
  @Test func bossDeeplinkIgnoredWhileGameAlreadyPresented() {
    let router = AppRouter()
    router.showGame = true                       // game already on screen
    router.handle(url: url("conjugar://game/boss"))
    #expect(!router.pendingBossEntry)            // flag NOT armed
    #expect(router.showGame)
  }

  @Test func endDeeplinkIgnoredWhileGameAlreadyPresented() {
    let router = AppRouter()
    router.showGame = true
    router.handle(url: url("conjugar://game/end"))
    #expect(!router.pendingEndScene)
    #expect(router.showGame)
  }

  // The onboarding game-preview CTA defers the launch to the cover's onDismiss, unified
  // here so both presenters (MainTabView, SettingsView) share one flag + helper.
  @Test func requestGameAfterOnboardingArmsTheFlagWithoutLaunching() {
    let router = AppRouter()
    router.requestGameAfterOnboarding()
    #expect(router.pendingGameAfterOnboarding)
    #expect(!router.showGame)                    // launch waits for onDismiss
  }

  @Test func launchAfterOnboardingPresentsAndClearsWhenArmed() {
    let router = AppRouter()
    router.requestGameAfterOnboarding()
    router.launchGameAfterOnboardingIfRequested()
    #expect(router.showGame)
    #expect(!router.pendingGameAfterOnboarding)  // one-shot: cleared
  }

  @Test func launchAfterOnboardingIsNoOpWhenNotArmed() {
    let router = AppRouter()
    router.launchGameAfterOnboardingIfRequested()
    #expect(!router.showGame)
  }

  @Test func commandFShowsTheVerbsTabAndKeepsTheFieldsText() {
    let router = AppRouter()
    router.selectedTab = .quiz
    router.openSearch(text: nil, source: .tab)
    #expect(router.selectedTab == .browseVerbs)
    #expect(router.pendingSearch == SearchRequest(text: nil, source: .tab))
  }

  @Test func searchDeeplinkCarriesItsTextAndSource() {
    let router = AppRouter()
    router.selectedTab = .settings
    router.handle(url: url("conjugar://search?q=he%20hablado&source=control"))
    #expect(router.selectedTab == .browseVerbs)
    #expect(router.pendingSearch == SearchRequest(text: "he hablado", source: .control))
  }

  @Test func searchDeeplinkWithNoTextOpensAnEmptyField() {
    let router = AppRouter()
    router.handle(url: url("conjugar://search"))
    #expect(router.pendingSearch == SearchRequest(text: "", source: .deeplink))
    router.handle(url: url("conjugar://search/?q="))
    #expect(router.pendingSearch == SearchRequest(text: "", source: .deeplink))
  }

  @Test func searchDeeplinkWithATargetIsIgnored() {
    let router = AppRouter()
    router.selectedTab = .settings
    router.handle(url: url("conjugar://search/fue"))
    #expect(router.pendingSearch == nil)
    #expect(router.selectedTab == .settings)
  }

  @Test(arguments: ["fue", "he hablado", "año", "a&b=c#d+e/f", "¿qué?", ""])
  func builtSearchDeeplinkRoundTrips(text: String) throws {
    let router = AppRouter()
    let link = try #require(URL.searchDeeplink(text: text, source: .lookup))
    router.handle(url: link)
    #expect(router.pendingSearch == SearchRequest(text: text, source: .lookup))
  }

  @Test func aSearchWithNoTextBuildsNoQueryItemForIt() throws {
    let link = try #require(URL.searchDeeplink(text: nil, source: .control))
    #expect(link.absoluteString == "conjugar://search?source=control")
  }

  @Test func aVerbDeeplinkReplacesAPendingSearch() {
    let router = AppRouter()
    router.handle(url: url("conjugar://search?q=fue"))
    router.handle(url: url("conjugar://verb/ir"))
    #expect(router.pendingSearch == nil)
    #expect(router.pendingVerb?.infinitive == "ir")
  }

  @Test func aSearchDeeplinkReplacesAPendingVerb() {
    let router = AppRouter()
    router.handle(url: url("conjugar://verb/ir"))
    router.handle(url: url("conjugar://search?q=fue"))
    #expect(router.pendingVerb == nil)
    #expect(router.pendingSearch?.text == "fue")
  }

  @Test func verbDeeplinkMarksItsMatch() throws {
    let router = AppRouter()
    let link = try #require(URL.verbDeeplink("ir", source: .lookup, match: "fue"))
    router.handle(url: link)
    #expect(router.pendingVerb == VerbDestination(infinitive: "ir", source: .lookup, marks: [ConjugationCell(tense: .pretérito, personNumber: .thirdSingular)]))
  }

  @Test func aMatchMayBeSeveralWords() {
    let marks = AppRouter.marks(of: "he hablado", on: "hablar", hiding: [])
    #expect(marks == [ConjugationCell(tense: .perfectoDeIndicativo, personNumber: .firstSingular)])
  }

  @Test func aMatchWithoutItsAccentsStillMarks() {
    let marks = AppRouter.marks(of: "tendre", on: "tener", hiding: [])
    #expect(marks == [ConjugationCell(tense: .futuroDeIndicativo, personNumber: .firstSingular)])
  }

  // Tú and vos share hablaste, so a learner who chose tú is not shown the vos row as well.
  @Test func aMatchLeavesOutTheHiddenPersonWhereTheOtherSharesTheForm() {
    let tú = ConjugationCell(tense: .pretérito, personNumber: .secondSingularTú)
    let vos = ConjugationCell(tense: .pretérito, personNumber: .secondSingularVos)
    #expect(AppRouter.marks(of: "hablaste", on: "hablar", hiding: [.secondSingularVos]) == [tú])
    #expect(AppRouter.marks(of: "hablaste", on: "hablar", hiding: []) == [tú, vos])
  }

  @Test func verbDeeplinkWhoseMatchIsNoFormMarksNothing() {
    let router = AppRouter()
    router.handle(url: url("conjugar://verb/ir?match=xyzzy"))
    #expect(router.pendingVerb == VerbDestination(infinitive: "ir", source: .deeplink))
  }

  @Test func builtVerbDeeplinkFindsAVerbWithAnEñe() throws {
    let router = AppRouter()
    let link = try #require(URL.verbDeeplink("añadir", source: .spotlight))
    router.handle(url: link)
    #expect(router.pendingVerb == VerbDestination(infinitive: "añadir", source: .spotlight))
  }

  @Test func verbDeeplinkWithTwoSegmentsIsIgnored() {
    let router = AppRouter()
    router.handle(url: url("conjugar://verb/hablar/extra"))
    #expect(router.pendingVerb == nil)
  }

  @Test func infoDeeplinkOpensAnArticleByItsStableKey() throws {
    let router = AppRouter()
    let link = try #require(URL.infoDeeplink(stableKey: "preterito"))
    router.handle(url: link)
    #expect(router.selectedTab == .info)
    #expect(router.pendingInfo?.stableKey == "preterito")
  }

  @Test func infoDeeplinkAcceptsAPosition() {
    let router = AppRouter()
    router.handle(url: url("conjugar://info/2"))
    #expect(router.pendingInfo == Info.infos[2])
  }

  @Test(arguments: ["conjugar://info/nonsense", "conjugar://info/999", "conjugar://info/-1", "conjugar://info"])
  func infoDeeplinkToNoArticleIsIgnored(link: String) {
    let router = AppRouter()
    router.selectedTab = .settings
    router.handle(url: url(link))
    #expect(router.pendingInfo == nil)
    #expect(router.selectedTab == .settings)
  }

  @Test func everyArticleRoundTripsByItsStableKey() throws {
    for info in Info.infos {
      let router = AppRouter()
      router.handle(url: try #require(URL.infoDeeplink(stableKey: info.stableKey)))
      #expect(router.pendingInfo == info)
    }
  }

  @Test(arguments: ["conjugar://quiz/start", "conjugar://quiz"])
  func quizDeeplinkStillStartsAQuiz(link: String) {
    let router = AppRouter()
    router.handle(url: url(link))
    #expect(router.selectedTab == .quiz)
    #expect(router.pendingQuizStart == .deeplink)
  }

  /// A quiz link carries its `source` to the quiz signals.
  @Test func quizDeeplinkCarriesItsSource() {
    let router = AppRouter()
    router.handle(url: url("conjugar://quiz/start?source=widget"))
    #expect(router.pendingQuizStart == .widget)
  }

  @Test(arguments: ["conjugar://list/nonsense", "conjugar://list/model-31-1", "conjugar://list", "conjugar://list/top100/extra", "conjugar://nonsense/hablar", "https://example.com/verb/hablar"])
  func unknownRoutesAndCollectionsAreIgnored(link: String) {
    let router = AppRouter()
    router.selectedTab = .settings
    router.handle(url: url(link))
    #expect(router.selectedTab == .settings)
    #expect(router.pendingVerb == nil)
    #expect(router.pendingSearch == nil)
    #expect(router.pendingInfo == nil)
    #expect(router.pendingCollection == nil)
  }

  @Test func listDeeplinkOpensACollectionInTheModelsTab() {
    let router = AppRouter()
    router.handle(url: url("conjugar://list/top100"))
    #expect(router.selectedTab == .models)
    #expect(router.pendingCollection == CollectionRequest(collection: .top100, source: .deeplink))
  }

  @Test func aSharedCollectionsLinkSaysSo() throws {
    let router = AppRouter()
    router.handle(url: try #require(VerbCollection.model("31").deeplink))
    #expect(router.pendingCollection == CollectionRequest(collection: .model("31"), source: .sharedLink))
  }

  @Test func everyCollectionRoundTripsThroughItsLink() throws {
    let collections = VerbCollection.featured + ModelInfo.all.map { VerbCollection.model($0.classNumber) }
    for collection in collections {
      let router = AppRouter()
      router.handle(url: try #require(URL.listDeeplink(key: collection.key, source: .deeplink)))
      #expect(router.pendingCollection?.collection == collection, "\(collection.key)")
    }
  }

  // `Shared/` cannot see `AnalyticsSource`, so its intents spell their links as literals. These
  // pin the literals to the routes and the vocabulary.
  @Test func findAVerbControlOpensAnEmptySearch() {
    let router = AppRouter()
    router.handle(url: url(OpenVerbSearchIntent.pendingDeeplink))
    #expect(router.pendingSearch == SearchRequest(text: "", source: .control))
  }

  @Test(arguments: zip(
    [OpenRandomVerbIntent.pendingDeeplink, OpenRandomVerbControlIntent.pendingDeeplink],
    [AnalyticsSource.shortcut, .control]
  ))
  func randomVerbIntentsNameTheirSources(link: String, source: AnalyticsSource) {
    let router = AppRouter()
    router.handle(url: url(link))
    #expect(router.pendingVerb?.source == source)
  }

  @Test func quickQuizControlStartsAQuiz() {
    let router = AppRouter()
    router.handle(url: url(OpenQuizIntent.pendingDeeplink))
    #expect(router.pendingQuizStart == .deeplink)
  }

  @Test func findAVerbQuickActionOpensAnEmptySearch() {
    let router = AppRouter()
    #expect(QuickAction.perform(QuickAction.findVerb.item, router: router))
    #expect(router.selectedTab == .browseVerbs)
    #expect(router.pendingSearch == SearchRequest(text: "", source: .quickAction))
  }

  @Test func findAVerbQuickActionSharesCommandFsTitle() {
    #expect(QuickAction.findVerb.item.localizedTitle == L.BrowseVerbs.findVerb)
  }

  @Test func anUnknownQuickActionIsNotPerformed() {
    let router = AppRouter()
    let item = UIApplicationShortcutItem(type: "biz.joshadams.Conjugar.nonsense", localizedTitle: "x")
    #expect(!QuickAction.perform(item, router: router))
    #expect(router.pendingSearch == nil)
  }

  // A verb link carries the surface it came from to the page, which reports it as `source`.
  @Test func verbDeeplinkCarriesItsSource() {
    let router = AppRouter()
    router.selectedTab = .quiz
    router.handle(url: url("conjugar://verb/hablar?source=widget"))
    #expect(router.selectedTab == .browseVerbs)
    #expect(router.pendingVerb == VerbDestination(infinitive: "hablar", source: .widget))
  }

  @Test func verbDeeplinkWithoutAKnownSourceReportsDeeplink() {
    let router = AppRouter()
    router.handle(url: url("conjugar://verb/hablar"))
    #expect(router.pendingVerb == VerbDestination(infinitive: "hablar", source: .deeplink))
    router.handle(url: url("conjugar://verb/tener?source=bogus"))
    #expect(router.pendingVerb == VerbDestination(infinitive: "tener", source: .deeplink))
  }

  @Test func randomVerbDeeplinkKeepsTheControlsSource() {
    let router = AppRouter()
    router.handle(url: url("conjugar://verb/random?source=control"))
    #expect(router.pendingVerb?.source == .control)
    #expect(router.pendingVerb.map { VerbMap.shared.entry(for: $0.infinitive) != nil } == true)
  }

  // The widgets name a reflexive-only verb as the app shows it, arrepentirse.
  @Test func pronominalVerbDeeplinkOpensTheBareInfinitive() {
    let router = AppRouter()
    router.handle(url: url("conjugar://verb/arrepentirse?source=widget"))
    #expect(router.pendingVerb == VerbDestination(infinitive: "arrepentir", source: .widget))
    router.handle(url: url("conjugar://verb/levantarse"))
    #expect(router.pendingVerb == VerbDestination(infinitive: "levantar", source: .deeplink))
  }

  @Test func unknownVerbDeeplinkIsIgnored() {
    let router = AppRouter()
    router.handle(url: url("conjugar://verb/xyzzyq?source=widget"))
    #expect(router.pendingVerb == nil)
  }
}
