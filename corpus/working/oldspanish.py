#!/usr/bin/env python3
"""Old-Spanish → Modern-Castilian canonicalizer for the medieval example tier.

The medieval works (Cantar de Mio Cid, Berceo's *Milagros*, Juan Ruiz's *Libro de buen amor*)
are spelled in 12th–14th-c. Castilian: *ferir, fazer, dixo, ovo, auer, connusco*. The app's
conjugation engine only knows **modern** forms (*herir, hacer, dijo, hubo, haber, conocer*).
To attach a medieval verse line to the right modern verb we must reduce **both** sides — the
corpus token AND every generated modern surface form — to a shared canonical key, then compare
canonical↔canonical. This module is that reducer; it is imported by `build_medieval_index.py`
and by any verification script, so the rule set lives in exactly one place.

Two public entry points:

  * ``canon(word)``      → the canonical key (accents stripped, letter rules applied). Feed it a
                           corpus token OR a modern engine form; matching modern/medieval reflexes
                           collapse to the same key.
  * ``variants(word)``   → the ordered list of raw tokens worth canonicalizing for one corpus
                           word: the word itself, its enclitic-pronoun-stripped stem, and its
                           apocope-restored form (``diz``→``dize``). The index builder canonicalizes
                           each and unions the verb hits.

Design notes
------------
* **Symmetric rules.** Every letter rule is applied to both sides, so a rule that is "wrong" for
  modern Spanish (dropping initial *h-*) still lets *fizo*→``izo`` meet modern *hizo*→``izo``.
  The canonical space is deliberately lossy — its only job is to make etymological reflexes
  collide, not to be readable.
* **Exception table first.** Strong preterites and suppletions (*sopo→supo, ovo→hubo, dixo→dijo*)
  are not reachable by spelling rules, so a hand table rewrites the raw old token to a modern
  surface form *before* the letter rules run. It covers the Cid's high-frequency irregulars —
  exactly the reflexes the learner most wants to see, and the ones a pure rule engine misses.
* **Recall over precision.** The mining subagents (pipeline step C) do the final select/reject,
  so this stage should surface candidates generously; ``variants`` + the exception table favor
  recall. Over-matching a *person* (accent-stripping collapses *habló*/*hablo*) is harmless; the
  reflex-only policy in the index builder is what prevents cross-*verb* false positives.
"""
import re
import unicodedata

# --- enclitic pronoun set (attached to the verb in Old Spanish; split off before identifying it).
#     Ordered longest-first so 'melo' strips before 'me'. Old apocopated forms included ('l' = le,
#     's' = se, 'nos'→'nis' etc.). 'gelo/gela' = archaic "se lo / se la".
ENCLITICS = [
    "meleo", "gelo", "gela", "gelos", "gelas", "selo", "sela", "selos", "selas",
    "melo", "mela", "telo", "tela", "noslo", "voslo", "melos", "melas",
    "nos", "vos", "les", "las", "los", "me", "te", "se", "le", "la", "lo", "ni",
    "l", "s", "m", "t",
]

# --- apocope restorations: Old Spanish routinely dropped a final -e ('diz' for 'dize', 'quier'
#     for 'quiere', 'tien' for 'tiene', 'faz' for 'faze', 'val' for 'vale'). Restoring the -e lets
#     the stem reach its modern reflex through the normal rules. Keyed by the apocopated surface.
APOCOPE = {
    "diz": "dize", "quier": "quiere", "tien": "tiene", "vien": "viene", "faz": "faze",
    "faze": "faze", "val": "vale", "sal": "sale", "pon": "pone", "man": "mande",
    "yaz": "yaze", "plaz": "plaze", "pesa": "pesa",
}

# --- Strong-preterite / suppletive EXCEPTION TABLE (raw old surface → a modern surface form that
#     the engine DOES generate). Rules can't derive these; a few hundred high-frequency entries
#     cover the medieval tier's irregulars. Values are chosen to canonicalize onto a real modern
#     form of the intended verb. Grouped by verb for auditability.
OLD_MODERN = {
    # haber (auxiliary + possessive 'have') — the single most divergent high-freq verb.
    "auer": "haber", "aver": "haber", "aue": "hab", "avie": "habia", "avié": "habia",
    "avien": "habian", "avién": "habian", "avia": "habia", "avya": "habia",
    "ovo": "hubo", "ove": "hube", "oviste": "hubiste", "ovieron": "hubieron",
    "oviesse": "hubiese", "oviessen": "hubiesen", "oviere": "hubiere", "ovist": "hubiste",
    "ovieron": "hubieron", "ovist": "hubiste", "aya": "haya", "ayan": "hayan",
    # ser / ir (shared preterite fu-)
    "fue": "fue", "fu": "fue", "foe": "fue", "fo": "fue", "fueron": "fueron",
    "fust": "fuiste", "fust": "fuiste", "seer": "ser", "seyer": "ser", "sedie": "seria",
    "yes": "eres", "sodes": "sois", "son": "son", "era": "era", "eran": "eran",
    # ir
    "ir": "ir", "iva": "iba", "ivan": "iban", "va": "va", "van": "van", "vaen": "van",
    "exir": "salir", "exida": "salida", "exien": "salian",
    # decir
    "dixo": "dijo", "dixe": "dije", "dixer": "dijere", "dixieron": "dijeron",
    "dixieron": "dijeron", "dixiessen": "dijesen", "dizir": "decir", "dezir": "decir",
    "diz": "dice", "dizen": "dicen", "dixol": "dijo", "digo": "digo",
    # hacer / fazer
    "fazer": "hacer", "fazen": "hacen", "fazie": "hacia", "fazié": "hacia",
    "fizo": "hizo", "fiço": "hizo", "fiz": "hice", "fizieron": "hicieron",
    "fiziesse": "hiciese", "fecho": "hecho", "fecha": "hecha", "fazade": "haced",
    # tener
    "tener": "tener", "tovo": "tuvo", "tove": "tuve", "tovieron": "tuvieron",
    "toviesse": "tuviese", "tien": "tiene", "tienen": "tienen", "tovol": "tuvo",
    # venir
    "venir": "venir", "vino": "vino", "vinien": "venian", "vinieron": "vinieron",
    "viniesse": "viniese", "vien": "viene",
    # ver
    "veer": "ver", "vido": "vio", "vidieron": "vieron", "viestes": "visteis",
    "veyen": "veian", "veye": "veia", "vio": "vio",
    # dar
    "dar": "dar", "dio": "dio", "dieron": "dieron", "diesse": "diese", "diessen": "diesen",
    # poder
    "poder": "poder", "pudo": "pudo", "pud": "pude", "pudieron": "pudieron",
    "podie": "podia", "podié": "podia", "podrie": "podria",
    # poner
    "poner": "poner", "puso": "puso", "pus": "puse", "pusieron": "pusieron",
    "misó": "puso", "miso": "puso", "misieron": "pusieron",
    # saber
    "saber": "saber", "sopo": "supo", "sope": "supe", "sopieron": "supieron",
    "sopiesse": "supiese", "sopiessen": "supiesen", "sabie": "sabia",
    # traer / aducir
    "traer": "traer", "troxo": "trajo", "traxo": "trajo", "troxieron": "trajeron",
    "aduxo": "adujo", "aduxieron": "adujeron", "aduzir": "aducir",
    # querer
    "querer": "querer", "quiso": "quiso", "quis": "quise", "quisieron": "quisieron",
    "quisiesse": "quisiese", "quisiessen": "quisiesen", "quier": "quiere",
    # conocer
    "connuscer": "conocer", "connusco": "conozco", "connoscer": "conocer",
    "conosco": "conozco", "conoscer": "conocer",
    # prender (strong pret. priso; modern reflex prender)
    "prender": "prender", "priso": "prendio", "prisieron": "prendieron",
    "preso": "preso", "presa": "presa",
    # estar
    "estar": "estar", "estido": "estuvo", "estidieron": "estuvieron", "estodo": "estuvo",
    # cabalgar (Old cavalgar) + a handful of high-freq f-/h- and spelling reflexes
    "cavalgar": "cabalgar", "cavalgo": "cabalga", "cavalgan": "cabalgan",
    "ferir": "herir", "firió": "hirio", "firio": "hirio", "firieron": "hirieron",
    "fablar": "hablar", "fabló": "hablo", "fablo": "hablo", "fablava": "hablaba",
    "fallar": "hallar", "falló": "hallo", "fallo": "hallo", "fallaron": "hallaron",
    "fincar": "hincar", "fincó": "hinco", "finco": "hinco", "fincaron": "hincaron",
    "foir": "huir", "fuir": "huir", "foyr": "huir",
    "morir": "morir", "morio": "murio", "murió": "murio",
    "oir": "oir", "odir": "oir", "udir": "oir", "oyó": "oyo", "oyo": "oyo",
}


def _strip_accents(text):
    """Remove combining accent marks but PRESERVE ñ (phonemic: año≠ano)."""
    text = text.replace("ñ", "\x01").replace("Ñ", "\x01")
    text = "".join(c for c in unicodedata.normalize("NFD", text)
                   if unicodedata.category(c) != "Mn")
    return text.replace("\x01", "ñ")


_INTERVOCALIC_U = re.compile(r"(?<=[aeiou])u(?=[aeiou])")


def _pre(w):
    """Pre-normalize: NFC, lowercase, ç→z (BEFORE accent stripping, which would otherwise
    decompose ç to a bare c), then strip accents while preserving ñ."""
    w = unicodedata.normalize("NFC", w).lower().strip()
    w = w.replace("ç", "z")
    return _strip_accents(w)


# Exception table re-keyed through the same pre-normalization used at lookup time, so a ç- or
# accent-bearing corpus token (fiço, avié) hits the entry keyed by its plain form (fizo, avie).
_EX = {_pre(k): v for k, v in OLD_MODERN.items()}


def _letter_rules(w):
    """Symmetric spelling reduction — applied identically to old tokens and modern forms so
    etymological reflexes collide. Order matters. (ç and accents are already gone via _pre.)"""
    if not w:
        return w
    w = w.replace("ss", "s")               # vassallo → vasallo
    w = _INTERVOCALIC_U.sub("b", w)        # consonantal u between vowels: biuo → bibo, auer → aber
    w = w.replace("x", "j")                # x (/ʃ/) → j: baxar → bajar
    w = w.replace("j", "i").replace("y", "i")  # j, y-as-vowel → i: meior/mejor, yo/io collapse
    if w.startswith("f"):                  # initial f- → h-  (fazer → hacer, fue → hue)
        w = "h" + w[1:]
    if w.startswith("h"):                  # then initial h- → ∅ (absorbs the f/h alternation)
        w = w[1:]
    w = w.replace("v", "b")                # auer → aber vs haber → aber (after h-drop)
    if w.startswith("rr"):                 # word-initial rr → r (rrey → rey); internal rr kept
        w = w[1:]
    return w


def canon(word):
    """Canonical matching key for a single word (old or modern). Idempotent on modern forms."""
    w = _pre(word)
    w = _EX.get(w, w)                 # whole-word suppletive rewrite first
    w = _pre(w)                       # the rewrite value may carry ç / accents (habia)
    return _letter_rules(w)


def _strip_enclitic(tok):
    """If tok ends in an attached pronoun cluster, return the bare verb stem, else None."""
    low = tok.lower()
    for enc in ENCLITICS:
        if len(low) > len(enc) + 1 and low.endswith(enc):
            return low[: -len(enc)]
    return None


def variants(word):
    """Ordered raw candidates for one corpus token: itself, apocope-restored, enclitic-stripped.
    The index builder canonicalizes each and unions the verb hits (recall-favoring)."""
    low = unicodedata.normalize("NFC", word).lower().strip()
    out = [low]
    if low in APOCOPE:
        out.append(APOCOPE[low])
    stem = _strip_enclitic(low)
    if stem:
        out.append(stem)
        if stem in APOCOPE:
            out.append(APOCOPE[stem])
        # apocope + enclitic: 'tornós' → stem 'torn' is too short; 'dixol' → 'dixo' (exception)
        if stem + "o" in OLD_MODERN or stem + "e" in OLD_MODERN:
            out.append(stem + "o")
            out.append(stem + "e")
    # dedupe preserving order
    seen, ordered = set(), []
    for v in out:
        if v and v not in seen:
            seen.add(v)
            ordered.append(v)
    return ordered


# --- self-test: run `python3 oldspanish.py` to sanity-check the high-frequency reflexes.
if __name__ == "__main__":
    CASES = [
        ("ferir", "herir"), ("fazer", "hacer"), ("fablar", "hablar"), ("fijo", "hijo"),
        ("fizo", "hizo"), ("fiço", "hizo"), ("dixo", "dijo"), ("sopo", "supo"),
        ("ovo", "hubo"), ("auer", "haber"), ("tovo", "tuvo"), ("vido", "vio"),
        ("cavalgar", "cabalgar"), ("priso", "prendio"), ("connusco", "conozco"),
        ("vassallo", "vasallo"), ("biuo", "vivo"), ("plaça", "plaza"),
    ]
    ok = 0
    for old, modern in CASES:
        a, b = canon(old), canon(modern)
        flag = "OK " if a == b else "XX "
        ok += a == b
        print(f"  {flag} {old:12s} -> {a:10s}   {modern:12s} -> {b:10s}")
    print(f"\n{ok}/{len(CASES)} reflex pairs collide")
    print("variants('díxol')  =", variants("díxol"))
    print("variants('tornós') =", variants("tornós"))
    print("variants('diz')    =", variants("diz"))
