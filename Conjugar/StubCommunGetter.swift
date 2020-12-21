//
//  StubCommunGetter.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/14/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import MessageUI
import UIKit

struct StubCommunGetter: CommunGetter {
  func getCommunication(completion: @escaping (Commun) -> Void) {
    let delay: TimeInterval = 2.0
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
//      if let sendEmailClosure = Emailer.shared.sendEmailClosure {
//        let commun = email(sendEmailClosure: sendEmailClosure)
//        completion(commun, communVersion)
//      }
      completion(newVersion)
    })
  }

  func email(sendEmailClosure: @escaping () -> ()) -> Commun {
    Commun(
      title: ["en": "Request for Feedback", "es": "Pedido"],
      image: UIImage(named: "Dancer") ?? UIImage(),
      imageLabel: ["en": "female flamenco dancer", "es": "bailaora de flamenco"],
      content: [
        "en": "The developer of Conjugar, Josh Adams, welcomes feedback on the app and suggestions for new features. To email him, tap the Email button below.",
        "es": "El desarrollador de Conjugar, Josh Adams, agradece los comentarios sobre la aplicación y las sugerencias de nuevas características. Para enviarle un correo electrónico, toca el botón Enviar de abajo."
      ],
      type: .email(actionTitle: ["en": "Email", "es": "Enviar"], cancelTitle: ["en": "No Thanks", "es": "No, Gracias"], action: sendEmailClosure),
      identifier: 0
    )
  }

  let information = Commun(
    title: ["en": "History", "es": "Historia"],
    image: UIImage(named: "Dancer") ?? UIImage(),
    imageLabel: ["en": "female flamenco dancer", "es": "bailaora de flamenco"],
    content: [
      "en": """
Development of Conjugar began in March, 2017. But there is a backstory.

In 1994, while he was attending Dartmouth College, the future developer of Conjugar, Josh Adams, took a class called Intro to Computing. For his culminating project, Mr. Adams created a Hypercard "stack" (app) called Le Conjuguateur. This app was like Conjugar but for French verbs. The app won Dartmouth College's Kemeney Computing Prize (Honorable Mention) and inspired development of Conjugar twenty-three years later.

John Kemeney, inventor of the BASIC programming language, is the namesake of the Kemeney Computing Prize. Ironically, BASIC was the language that Mr. Adams used to teach himself to program at age nine.
""",
      "es": """
El desarrollo de Conjugar comenzó en marzo de 2017. Pero hay una historia de fondo.

En 1994, mientras asistía a Dartmouth College, el eventual desarrollador de Conjugar, Josh Adams, tomó una clase llamada Introducción a la Computación. Para su proyecto culminante, el Sr. Adams creó una "stack" (aplicación) de Hypercard llamada Le Conjuguateur. Esta aplicación era como Conjugar pero para los verbos franceses. La aplicación ganó el Premio de Informática Kemeney de Dartmouth College (Mención de Honor) e inspiró el desarrollo de Conjugar veintitrés años después.

John Kemeney, inventor del lenguaje de programación BASIC, es el homónimo del Premio de Informática Kemeney. Irónicamente, BASIC era el lenguaje que el Sr. Adams usaba para aprender a programar a los nueve años.
"""
    ],
    type: .information(okayTitle: ["en": "Awesome", "es": "Asombrosa"]),
    identifier: 1
  )

  var newVersion: Commun {
    let alreadyUpdated: Bool
    // Change to higher than current app version to screen with action.
    let appVersionFromCloudKit = 2.5
    if
      let appVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
      let appVersion = Double(appVersionString),
      appVersion < appVersionFromCloudKit
    {
      alreadyUpdated = false
    } else {
      alreadyUpdated = true
    }

    guard let openUrlClosure = openUrlClosure(urlString: "https://itunes.apple.com/\(Current.locale.regionCode)/app/conjugar/id1236500467") else {
      fatalError("Could not initialize URL.")
    }

    return Commun(
      title: ["en": "New Version", "es": "Nueva Versión"],
      image: UIImage(named: "Dancer") ?? UIImage(),
      imageLabel: ["en": "female flamenco dancer", "es": "bailaora de flamenco"],
      content: [
        "en": "Ordinarily, the only way for developers of iOS apps to communicate with users in an ad-hoc manner is via App Store release notes for a new version of the app. This manner of communication has two shortcomings. First, the communication is tied to a new release. Without a new release, the developer can't communicate. Second, many users, this developer included, don't regularly read release notes. Version 2.5 of Conjugar has an exciting new feature: the developer can communicate directly with users in Conjugar itself, without releasing a new version. He is doing that right now.",
        "es": "Por lo general, la única forma en que los desarrolladores de aplicaciones iOS pueden comunicarse con los usuarios de manera ad-hoc es a través de las notas de la versión de la App Store para una nueva versión de la aplicación. Esta forma de comunicación tiene dos defectos. Primero, la comunicación está vinculada a una nueva versión. Sin una nueva versión, el desarrollador no puede comunicarse. En segundo lugar, muchos usuarios, incluido este desarrollador, no leen regularmente las notas de la versión. La versión 2.5 de Conjugar tiene una nueva característica interesante: el desarrollador puede comunicarse directamente con los usuarios en Conjugar mismo, sin lanzar una nueva versión. Él está haciendo eso ahora mismo."
      ],
      type: .newVersion(okayTitle: ["en": "Cool, I Have It", "es": "Genial, Lo Tengo"], actionTitle: ["en": "Update", "es": "Actualizar"], cancelTitle: ["en": "No Thanks", "es": "No, Gracias"], action: openUrlClosure, alreadyUpdated: alreadyUpdated),
      identifier: 2
    )
  }

  var website: Commun {
    guard let openUrlClosure = openUrlClosure(urlString: "https://racecondition.software/blog/programmatic-layout/") else {
      fatalError("Could not initialize URL.")
    }
    return Commun(
      title: ["en": "Technical Underpinnings", "es": "Fundamentos Técnicos"],
      image: UIImage(named: "Dancer") ?? UIImage(),
      imageLabel: ["en": "female flamenco dancer", "es": "bailaora de flamenco"],
      content: [
        "en": "In 2017, there were two approaches to creating user interfaces (UIs) in iOS apps. Developers could use a visual editor called Interface Builder (IB) or create UIs entirely in code, an approach called programmatic layout (PL). At that time, iOS developer Josh Adams was more comfortable with IB, but he had used PL while working on an app for San Francisco Airport taxi drivers. He created Conjugar using PL in order to increase his comfort with that technique. He then wrote a tutorial about converting an app from IB to PL. If this subject interests you, tap the Read button below.",
        "es": "En 2017, hubo dos enfoques para crear las interfaces de usuario (IUes) en aplicaciones de iOS. Los desarrolladores pueden usar un editor visual llamado Interface Builder (IB) o crear las IUes completamente en código, un enfoque llamado diseño programático (DP). En ese momento, el desarrollador de iOS Josh Adams se sentía más cómodo con IB, pero había usado DP mientras trabajaba en una aplicación para las taxistas del Aeropuerto de San Francisco. Creó Conjugar usando DP para aumentar su comodidad con esa técnica. Luego escribió un tutorial sobre cómo convertir una aplicación de IB a DP. Si este tema le interesa, toca el botón Leer a continuación."
      ],
      type: .website(actionTitle: ["en": "Read", "es": "Leer"], cancelTitle: ["en": "No Thanks", "es": "No, Gracias"], action: openUrlClosure),
      identifier: 3
    )
  }
}
