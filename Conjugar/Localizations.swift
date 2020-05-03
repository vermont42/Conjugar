//
//  Localizations.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/1/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

// genstrings -o es.lproj *.swift

enum Localizations {
  enum BrowseInfo {
    static var localizedTitle: String {
      NSLocalizedString("Info", comment: "")
    }
  }

  enum BrowseVerbs {
    static var localizedTitle: String {
      NSLocalizedString("Browse", comment: "")
    }

    static var both: String {
      NSLocalizedString("Both", comment: "")
    }
  }

  enum Info {
  }

  enum Quiz {
    static var localizedTitle: String {
      NSLocalizedString("Quiz", comment: "")
    }
  }

  enum Results {
    static var title: String {
      NSLocalizedString("Results", comment: "")
    }
  }

  enum Settings {
    static var localizedTitle: String {
      NSLocalizedString("Settings", comment: "")
    }
  }

  enum Verb {
    static var irregular: String {
      NSLocalizedString("Irregular", comment: "")
    }

    static var regular: String {
      NSLocalizedString("Regular", comment: "")
    }

    static var defective: String {
      NSLocalizedString("Defective", comment: "")
    }

    static var notDefective: String {
      NSLocalizedString("Not Defective", comment: "")
    }

    static var irregularWithParent: String {
      NSLocalizedString("Irreg. ☛ %@", comment: "")
    }
  }
}
