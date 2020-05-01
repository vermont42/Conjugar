//
//  Localizations.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/1/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

enum Localizations {
    enum BrowseInfo {
        static var englishTitle: String {
            "Info"
        }

        static var localizedTitle: String {
            NSL(englishTitle)
        }
    }

    enum BrowseVerbs {
        static var englishTitle: String {
            "Browse"
        }

        static var localizedTitle: String {
            NSL(englishTitle)
        }
    }

    enum Info {
    }

    enum Quiz {
        static var englishTitle: String {
            "Quiz"
        }

        static var localizedTitle: String {
            NSL(englishTitle)
        }
    }

    enum Results {
        static var title: String {
            NSL("Results")
        }
    }

    enum Settings {
        static var englishTitle: String {
            "Settings"
        }

        static var localizedTitle: String {
            NSL(englishTitle)
        }
    }

    enum Verb {
    }

    private static func NSL(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, comment: comment)
    }
}
