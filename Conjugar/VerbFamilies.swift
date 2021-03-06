//
//  VerbFamilies.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

struct VerbFamilies {
  static let regularArVerbs = ["hablar", "caminar", "andar", "trabajar", "estudiar", "escuchar", "visitar", "viajar", "enseñar", "llevar", "bailar", "nadar", "cocinar", "charlar", "platicar", "llorar", "esperar", "buscar", "mirar", "pintar", "gastar", "ganar", "comprar", "tocar", "tomar", "sacar", "ayudar", "cantar", "desear", "necesitar", "cortar", "contestar", "dibujar", "clonar", "datar", "distar", "empinar", "encalar", "esposar", "formar", "glosar", "golpear", "grapar", "hibernar", "maltear", "manar", "nublar", "penar", "ponderar", "rasar", "seriar", "trinchar", "procesar", "declarar", "helar", "usar", "regresar", "quedar", "lavar", "limpiar", "amar"]

  static let regularIrVerbs = ["vivir", "existir", "ocurrir", "recibir", "permitir", "partir", "cumplir", "decidir", "subir", "sufrir", "compartir", "consistir", "insistir", "asistir", "discutir", "unir", "coincidir", "distinguir", "definir", "admitir", "acudir", "nutrir", "evadir"]

  static let regularErVerbs = ["comer", "beber", "leer", "aprender", "comprender", "correr", "deber", "vender", "romper", "temer", "reprender", "barrer", "cometer", "poseer", "responder", "prometer", "meter", "someter", "absorber", "emprender", "coser", "ceder", "exceder", "ofender", "esconder", "lamer", "tejer", "esconder"]

  static let allRegularVerbs = VerbFamilies.regularArVerbs + VerbFamilies.regularErVerbs + VerbFamilies.regularIrVerbs

  static let irregularPresenteDeIndicativoVerbs = ["ser", "ir", "dormir", "hacer", "morir", "morder", "oír", "poder", "haber", "sentir", "sentar"]

  static let irregularImperfectivoVerbs = ["ser", "ir", "ver"]

  static let irregularPreteritoVerbs = ["ser", "ir", "dar", "poner", "poder", "estar", "tener", "andar", "saber", "haber", "caber", "hacer", "venir", "querer", "decir", "traer", "conducir"]

  static let irregularRaizFuturaVerbs = ["haber", "saber", "caber", "poder", "querer", "poner", "tener", "venir", "salir", "valer", "decir", "hacer"]

  static let irregularPresenteDeSubjuntivoVerbs = ["ser", "ir", "haber", "saber", "pensar", "perder", "sentir", "dormir", "pedir", "crecer", "conocer", "lucir", "conducir", "huir", "construir", "estar", "dar", "caber", "decir", "hacer", "caer", "oír", "traer", "poner", "salir", "tener", "valer", "venir", "ver", "jugar", "argüir", "elegir", "colegir", "manecer", "anochecer", "cazar", "granizar"]

  static let irregularTuImperativoVerbs = ["ser", "ir", "decir", "hacer", "poner", "salir", "tener", "venir", "componer", "obtener", "medir", "pedir", "oír", "elegir", "colegir"]

  static let irregularVosImperativoVerbs = ["ser", "ir"]

  static let irregularParticipioVerbs = ["abrir", "cubrir", "decir", "escribir", "hacer", "morir", "poner", "resolver", "romper", "ver", "volver", "pudrir"]

  static let irregularGerundioVerbs = ["poder", "sentir", "medir", "dormir", "caer", "leer", "traer", "construir", "huir", "oír", "ir", "tañer", "bullir", "argüir", "elegir", "colegir", "hervir"]

  static let thirdPersonSingularOnlyVerbs = ["amanecer", "anochecer", "llover", "granizar", "nevar", "relampaguear", "tronar"]
}
