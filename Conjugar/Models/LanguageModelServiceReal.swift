//
//  LanguageModelServiceReal.swift
//  Conjugar
//
//  The Spanish conjugation tutor, ported from Conjuguer's French tutor. Wraps
//  Apple's on-device `SystemLanguageModel` / `LanguageModelSession` and grounds it
//  with `ConjugationTool`, which conjugates real forms through the app's own
//  `TenseBridge`/`Conjugator` engine so the model never invents conjugations.
//
//  The system prompt is localized to the *system language*: Spanish instructions
//  when the device language is Spanish, English otherwise. This is independent of
//  the app's `.xcstrings` UI localization — it steers what language the model
//  answers in.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import os

#if canImport(FoundationModels)
import FoundationModels
#endif

nonisolated private let lmsLogger = Logger(subsystem: "com.racecondition.Conjugar", category: "LanguageModelService")

@available(iOS 26, *)
@MainActor
@Observable
class LanguageModelServiceReal: LanguageModelService {
  private let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)

  private var tutorSession: LanguageModelSession?

  private(set) var isAvailable: Bool
  private(set) var unavailabilityReason: LanguageModelUnavailability?

  init() {
    let snapshot = Self.snapshot(of: model.availability)
    self.isAvailable = snapshot.isAvailable
    self.unavailabilityReason = snapshot.reason
    // Availability can flip after launch (user enables Apple Intelligence, the
    // model finishes downloading). Poll so the Info-tab entry point reacts live —
    // `@Observable` drives the SwiftUI update.
    Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(5))
        guard let self else {
          return
        }
        self.refreshAvailability()
      }
    }
  }

  private func refreshAvailability() {
    let snapshot = Self.snapshot(of: model.availability)
    if snapshot.isAvailable != isAvailable {
      isAvailable = snapshot.isAvailable
    }
    if snapshot.reason != unavailabilityReason {
      unavailabilityReason = snapshot.reason
    }
  }

  private static func snapshot(of availability: SystemLanguageModel.Availability) -> (isAvailable: Bool, reason: LanguageModelUnavailability?) {
    switch availability {
    case .available:
      return (true, nil)
    case .unavailable(.appleIntelligenceNotEnabled):
      return (false, .appleIntelligenceNotEnabled)
    case .unavailable(.deviceNotEligible):
      return (false, .deviceNotEligible)
    case .unavailable(.modelNotReady):
      return (false, .modelNotReady)
    case .unavailable:
      return (false, .unknown)
    @unknown default:
      return (false, .unknown)
    }
  }

  private static let isSpanish = Locale.current.language.languageCode?.identifier == "es"

  private static var tutorInstructions: String {
    isSpanish ? tutorInstructionsSpanish : tutorInstructionsEnglish
  }

  private static let tutorInstructionsEnglish = """
    You are a Spanish verb conjugation tutor. \
    For conjugation questions, call conjugateVerb EXACTLY ONCE with the \
    Spanish infinitive and the SINGLE tense the user asked about. Do not \
    call the tool multiple times for different tenses. \
    Present the Spanish conjugations from the tool result directly. \
    NEVER translate conjugations into English. Always show Spanish words \
    like "yo hablo", never English like "I speak". \
    List ALL persons from the tool result. \
    Tense notes: "presente" = presente de indicativo = present indicative. \
    "pretérito" = preterite = simple past. "imperfecto" = imperfecto de \
    indicativo = imperfect. "futuro" = futuro de indicativo = simple future. \
    "condicional" = the conditional. "presente de subjuntivo" = present \
    subjunctive. "imperfecto de subjuntivo" = imperfect subjunctive (has -ra \
    and -se forms). "futuro de subjuntivo" = future subjunctive. \
    "imperativo" = the imperative = command form (positive and negative). \
    "perfecto de indicativo" = present perfect. \
    "pluscuamperfecto" = pluperfect = past perfect. \
    "pretérito anterior" = past anterior. "futuro perfecto" = future perfect. \
    "condicional compuesto" = conditional perfect. \
    "perfecto de subjuntivo" = present perfect subjunctive. \
    "gerundio" = gerund = present participle. "participio" = past participle. \
    "raíz futura" = future stem. \
    Grammar concept questions are welcome. If the user asks about grammar \
    concepts like the difference between the pretérito and the imperfecto, \
    when to use the subjunctive, ser versus estar, or por versus para, answer \
    directly and helpfully without calling the tool. \
    Only redirect questions that have nothing to do with the Spanish language.
    """

  private static let tutorInstructionsSpanish = """
    Eres un tutor de conjugación de verbos españoles. \
    Para las preguntas de conjugación, llama a conjugateVerb EXACTAMENTE UNA VEZ \
    con el infinitivo español y el ÚNICO tiempo verbal que el usuario preguntó. \
    No llames a la herramienta varias veces para tiempos diferentes. \
    Presenta directamente las conjugaciones españolas del resultado de la herramienta. \
    Responde siempre en español. Muestra las formas españolas como «yo hablo», \
    nunca en inglés como «I speak». \
    Enumera TODAS las personas del resultado de la herramienta. \
    Notas sobre los tiempos: «presente» = presente de indicativo. Los demás \
    tiempos son el pretérito, el imperfecto, el futuro, el condicional, el \
    presente de subjuntivo, el imperfecto de subjuntivo (formas -ra y -se), \
    el futuro de subjuntivo, el imperativo (positivo y negativo), el perfecto \
    de indicativo, el pluscuamperfecto, el pretérito anterior, el futuro \
    perfecto, el condicional compuesto, el perfecto de subjuntivo, el gerundio, \
    el participio y la raíz futura. \
    Las preguntas sobre conceptos gramaticales son bienvenidas. Si el usuario \
    pregunta sobre un concepto como la diferencia entre el pretérito y el \
    imperfecto, cuándo usar el subjuntivo, ser y estar, o por y para, responde \
    directa y útilmente sin llamar a la herramienta. \
    Redirige solo las preguntas que no tienen nada que ver con la lengua española.
    """

  func sendTutorMessage(_ message: String) async throws -> String {
    let maxRetries = 3
    var lastRefusalResponse: String?
    var lastError: Error?

    for attempt in 0...maxRetries {
      ConjugationTool.resetCallCount()
      if attempt > 0 || tutorSession == nil {
        tutorSession = LanguageModelSession(model: model, tools: [ConjugationTool()], instructions: Self.tutorInstructions)
      }
      guard let session = tutorSession else {
        throw LanguageModelServiceError.sessionUnavailable
      }
      do {
        let response = try await session.respond(to: message)
        let cleaned = Self.stripMarkdown(response.content)
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !Self.isLikelyRefusal(cleaned) {
          return cleaned
        }
        let reason = trimmed.isEmpty ? "empty response" : "likely refusal"
        lmsLogger.info("Detected \(reason) on attempt \(attempt + 1), retrying")
        lastRefusalResponse = cleaned
      } catch {
        lmsLogger.warning("Attempt \(attempt + 1) failed: \(error.localizedDescription)")
        lastError = error
      }
    }

    tutorSession = LanguageModelSession(model: model, tools: [ConjugationTool()], instructions: Self.tutorInstructions)
    if lastRefusalResponse != nil {
      return L.Tutor.unableToAnswer
    }
    throw lastError ?? LanguageModelServiceError.sessionUnavailable
  }

  private static func stripMarkdown(_ text: String) -> String {
    text.replacingOccurrences(of: "**", with: "")
  }

  // The on-device model sometimes over-refuses conjugation content; catch its
  // canned refusals (English and Spanish) so `sendTutorMessage` retries with a
  // fresh session instead of surfacing a bogus "I can't help" bubble.
  private static func isLikelyRefusal(_ response: String) -> Bool {
    let lowercased = response.lowercased()
    return lowercased.contains("can't assist")
      || lowercased.contains("cannot assist")
      || lowercased.contains("can't help")
      || lowercased.contains("cannot help")
      || lowercased.contains("ethical guidelines")
      || lowercased.contains("unable to assist")
      || lowercased.contains("unable to provide")
      || lowercased.contains("inappropriate content")
      || lowercased.contains("cannot answer")
      || lowercased.contains("can't answer")
      || lowercased.contains("cannot provide")
      || lowercased.contains("cannot fulfill")
      || lowercased.contains("can't fulfill")
      || lowercased.contains("unable to fulfill")
      || lowercased.contains("outside of the scope")
      || lowercased.contains("outside the scope")
      || lowercased.contains("can't do that")
      || lowercased.contains("cannot do that")
      || lowercased.contains("can't continue")
      || lowercased.contains("cannot continue")
      // Spanish redirects
      || lowercased.contains("no puedo ayudarte")
      || lowercased.contains("no puedo ayudarle")
      || lowercased.contains("no puedo responder")
      || lowercased.contains("soy una ia")
      || lowercased.contains("soy un modelo de lenguaje")
      || lowercased.contains("fuera de mi alcance")
      || lowercased.contains("lo siento, no puedo")
  }

  func resetTutorSession() {
    tutorSession = nil
  }
}

@available(iOS 26, *)
struct ConjugationTool: Tool {
  let name = "conjugateVerb"
  let description = "Look up a Spanish verb conjugation"

  nonisolated(unsafe) private static var callCount = 0
  private static let maxCallsPerSession = 3

  static func resetCallCount() {
    callCount = 0
  }

  @Generable(description: "A Spanish verb conjugation lookup")
  struct Arguments {
    @Guide(description: "The verb infinitive")
    var infinitivo: String

    @Guide(description: "Tense from the question", .anyOf([
      "Presente de Indicativo", "Pretérito", "Imperfecto de Indicativo",
      "Futuro de Indicativo", "Condicional", "Presente de Subjuntivo",
      "Imperfecto de Subjuntivo", "Futuro de Subjuntivo", "Imperativo Positivo",
      "Imperativo Negativo", "Perfecto de Indicativo", "Pretérito Anterior",
      "Pluscuamperfecto de Indicativo", "Futuro Perfecto", "Condicional Compuesto",
      "Perfecto de Subjuntivo", "Pluscuamperfecto de Subjuntivo",
      "Futuro Perfecto de Subjuntivo", "Gerundio", "Participio", "Raíz Futura"
    ]))
    var tense: String
  }

  func call(arguments: Arguments) async throws -> String {
    Self.callCount += 1
    if Self.callCount > Self.maxCallsPerSession {
      lmsLogger.warning("Tool call limit reached (\(Self.maxCallsPerSession))")
      return "Limit reached. Respond with the conjugations you already have."
    }
    lmsLogger.info("Tool call: infinitivo=\(arguments.infinitivo) tense=\(arguments.tense)")
    // Conjugar's engine (`TenseBridge`/`Conjugator`/`VerbMap`) is `nonisolated`, so
    // it can be called directly here — no MainActor hop needed (unlike Conjuguer).
    let result = Self.performLookup(infinitive: arguments.infinitivo, tenseName: arguments.tense)
    lmsLogger.info("Tool result: \(result)")
    return result
  }

  // MARK: - Grounded lookup through the app's engine

  private static let regularPersons: [DisplayPersonNumber] = [
    .firstSingular, .secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural
  ]
  private static let imperativePersons: [DisplayPersonNumber] = [
    .secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural
  ]

  private static func performLookup(infinitive rawInfinitive: String, tenseName: String) -> String {
    let infinitive = normalizeInfinitive(rawInfinitive)
    guard VerbMap.shared.entry(for: infinitive) != nil else {
      return "\"\(rawInfinitive)\" is not a recognized Spanish verb."
    }
    guard let tense = displayTense(forName: tenseName) else {
      return invalidTenseMessage(rawInfinitive: rawInfinitive, tenseName: tenseName)
    }

    if isPersonless(tense) {
      if case .success(let form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: .none) {
        return "\(infinitive) — \(tense.titleCaseName): \(form.lowercased())"
      }
      return "Could not conjugate \(infinitive) for the \(tense.titleCaseName)."
    }

    let imperative = (tense == .imperativoPositivo || tense == .imperativoNegativo)
    let persons = imperative ? imperativePersons : regularPersons
    var lines: [String] = []
    for person in persons {
      if case .success(let form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: person) {
        lines.append("\(pronoun(for: person, imperative: imperative)) \(form.lowercased())")
      }
    }
    guard !lines.isEmpty else {
      return "Could not conjugate \(infinitive) for the \(tense.titleCaseName)."
    }
    return "\(infinitive) — \(tense.titleCaseName): \(lines.joined(separator: ", "))"
  }

  // Textbook pronoun for grounding. Affirmative/negative commands use the usted/
  // ustedes forms for the third persons, matching how Spanish imperatives are taught.
  private static func pronoun(for person: DisplayPersonNumber, imperative: Bool) -> String {
    switch person {
    case .firstSingular:
      return "yo"
    case .secondSingularTú:
      return "tú"
    case .thirdSingular:
      return imperative ? "usted" : "él"
    case .firstPlural:
      return "nosotros"
    case .secondPlural:
      return "vosotros"
    case .thirdPlural:
      return imperative ? "ustedes" : "ellos"
    case .secondSingularVos, .none:
      return ""
    }
  }

  private static func isPersonless(_ tense: DisplayTense) -> Bool {
    switch tense {
    case .gerundio, .participio, .raízFutura:
      return true
    default:
      return false
    }
  }

  // Strips a leading reflexive "se " and, on a miss, a trailing "-se" (lavarse →
  // lavar), then lowercases for the bare-infinitive VerbMap key.
  private static func normalizeInfinitive(_ raw: String) -> String {
    var infinitive = raw.trimmingCharacters(in: .whitespaces).lowercased()
    if infinitive.hasPrefix("se ") {
      infinitive = String(infinitive.dropFirst(3))
    }
    infinitive = infinitive.trimmingCharacters(in: .whitespaces)
    if VerbMap.shared.entry(for: infinitive) == nil, infinitive.hasSuffix("se"), infinitive.count > 4 {
      let stem = String(infinitive.dropLast(2))
      if VerbMap.shared.entry(for: stem) != nil {
        return stem
      }
    }
    return infinitive
  }

  // Folds accents and hyphens so "Pretérito", "Raíz Futura", "Plus-que-..." match
  // plain ASCII keywords.
  private static func folded(_ name: String) -> String {
    name
      .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en"))
      .lowercased()
      .replacingOccurrences(of: "-", with: " ")
  }

  // Maps a tense name (Spanish or English, however the model phrases it) to a
  // `DisplayTense`. Most-specific compound/subjunctive phrases are matched before
  // their shorter substrings, so e.g. "presente de subjuntivo" is not swallowed by
  // the bare "presente" test.
  private static func displayTense(forName name: String) -> DisplayTense? {
    let f = folded(name)

    // Non-finite forms / future stem
    if f.contains("gerundio") || f.contains("gerund") || f.contains("present participle") {
      return .gerundio
    }
    if f.contains("participio") || f.contains("past participle") {
      return .participio
    }
    if f.contains("raiz futura") || f.contains("future stem") || f.contains("future root") {
      return .raízFutura
    }

    // Compound (perfect) subjunctive
    if f.contains("futuro perfecto de subjuntivo") || f.contains("future perfect subjunctive") {
      return .futuroPerfectoDeSubjuntivo
    }
    if f.contains("pluscuamperfecto de subjuntivo 2") {
      return .pluscuamperfectoDeSubjuntivo2
    }
    if f.contains("pluscuamperfecto de subjuntivo") || f.contains("pluperfect subjunctive") || f.contains("past perfect subjunctive") {
      return .pluscuamperfectoDeSubjuntivo1
    }
    if f.contains("perfecto de subjuntivo") || f.contains("present perfect subjunctive") {
      return .perfectoDeSubjuntivo
    }

    // Compound (perfect) indicative / conditional
    if f.contains("condicional compuesto") || f.contains("conditional perfect") || f.contains("perfect conditional") {
      return .condicionalCompuesto
    }
    if f.contains("futuro perfecto") || f.contains("future perfect") {
      return .futuroPerfecto
    }
    if f.contains("pluscuamperfecto") || f.contains("pluperfect") || f.contains("past perfect") {
      return .pluscuamperfectoDeIndicativo
    }
    if f.contains("preterito anterior") || f.contains("past anterior") {
      return .pretéritoAnterior
    }
    if f.contains("perfecto de indicativo") || f.contains("preterito perfecto") || f.contains("present perfect") {
      return .perfectoDeIndicativo
    }

    // Simple subjunctive
    if f.contains("futuro de subjuntivo") || f.contains("future subjunctive") {
      return .futuroDeSubjuntivo
    }
    if f.contains("imperfecto de subjuntivo 2") || f.contains("subjunctive imperfect 2") {
      return .imperfectoDeSubjuntivo2
    }
    if f.contains("imperfecto de subjuntivo") || f.contains("imperfect subjunctive") || f.contains("past subjunctive") {
      return .imperfectoDeSubjuntivo1
    }
    if f.contains("presente de subjuntivo") || f.contains("present subjunctive") || f.contains("subjuntivo") || f.contains("subjunctive") {
      return .presenteDeSubjuntivo
    }

    // Imperative
    if f.contains("imperativo negativo") || f.contains("negative imperative") || f.contains("negative command") {
      return .imperativoNegativo
    }
    if f.contains("imperativo") || f.contains("imperative") || f.contains("command") {
      return .imperativoPositivo
    }

    // Conditional
    if f.contains("condicional") || f.contains("conditional") {
      return .condicional
    }

    // Future
    if f.contains("futuro") || f.contains("future") {
      return .futuroDeIndicativo
    }

    // Imperfect
    if f.contains("imperfecto") || f.contains("imperfect") {
      return .imperfectoDeIndicativo
    }

    // Preterite / simple past
    if f.contains("preterito") || f.contains("preterite") || f.contains("simple past") || f.contains("past") {
      return .pretérito
    }

    // Present (fallback)
    if f.contains("presente") || f.contains("present") || f.contains("indicativo") || f.contains("indicative") {
      return .presenteDeIndicativo
    }

    return nil
  }

  private static func invalidTenseMessage(rawInfinitive: String, tenseName: String) -> String {
    if VerbMap.shared.entry(for: normalizeInfinitive(rawInfinitive)) == nil {
      return "\"\(rawInfinitive)\" is not a recognized Spanish verb."
    }
    return "Could not parse tense \"\(tenseName)\". Valid names include: "
      + "Presente de Indicativo, Pretérito, Imperfecto de Indicativo, Futuro de Indicativo, "
      + "Condicional, Presente de Subjuntivo, Imperfecto de Subjuntivo, Imperativo Positivo, "
      + "Imperativo Negativo, Perfecto de Indicativo, Gerundio, Participio."
  }
}
