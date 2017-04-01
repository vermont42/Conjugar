//
//  Verb.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

enum VerbError: Error {
    case tooShort
    case invalidEnding(String)
    case tenseNotImplemented(Tense)
    case noSuchConjugation(PersonNumber)
}

struct Verb {
    static func conjugate(infinitive: String, tense: Tense, personNumber: PersonNumber, region: Region = .spain) -> Result<String, VerbError> {
        if infinitive.characters.count < 3 {
            return .failure(.tooShort)
        }
        let index = infinitive.index(infinitive.endIndex, offsetBy: -2)
        let ending = infinitive.substring(from: index)
        if !["ar", "er", "ir"].contains(ending) {
            return .failure(.invalidEnding(ending))
        }
        let stem = infinitive.substring(to: index)
        switch tense {
        case .presenteDeIndicativo:
            switch personNumber {
            case .firstSingular:
                return .success(stem + "o")
            case .firstPlural:
                if ending == "ar" {
                    return .success(stem + "amos")
                }
                else if ending == "er" {
                    return .success(stem + "emos")
                }
                else { // ending == "ir"
                    return .success(stem + "imos")
                }
            case .secondSingular:
                if ending == "ar" {
                    return .success(stem + "as")
                }
                else if ending == "er" {
                    return .success(stem + "es")
                }
                else { // ending == "ir"
                    return .success(stem + "es")
                }
            case .secondPlural:
                if ending == "ar" {
                    return .success(stem + "áis")
                }
                else if ending == "er" {
                    return .success(stem + "éis")
                }
                else { // ending == "ir"
                    return .success(stem + "ís")
                }
            case .thirdSingular:
                if ending == "ar" {
                    return .success(stem + "a")
                }
                else if ending == "er" {
                    return .success(stem + "e")
                }
                else { // ending == "ir"
                    return .success(stem + "e")
                }
            case .thirdPlural:
                if ending == "ar" {
                    return .success(stem + "an")
                }
                else if ending == "er" {
                    return .success(stem + "en")
                }
                else { // ending == "ir"
                    return .success(stem + "en")
                }
            }
        default:
            return .failure(.tenseNotImplemented(tense))
        }
    }
}
