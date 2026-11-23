# The 2027 Release

What the next App Store release of Conjugar must do, gathered in one place. `CLAUDE.md` § No
Release Before 2027 points here. Add to this document whenever work on `master` leaves a step for
release time, and delete it, along with that `CLAUDE.md` section, once the release has shipped and
every item below is done. Privacy-policy lines are the exception: they wait, word for word, in
`docs/privacy_policy_pending.md`, and this document says only when to apply them.

## Why There Is No Release Before 2027

Josh cannot cut an App Store release of Conjugar, Conjuguer, or Konjugieren from his present
MacBook, and he plans to replace it in 2027. He said so on 2026-11-10. Until then, work accumulates
on `master` and the shipped version, 3.1, does not change. Text hosted outside the app, such as the
privacy policy, can still change at any time, which is why new policy lines are staged rather than
deployed.

What has accumulated since 3.1 is recorded in the plans' Status tables
([`plans/browse_and_verb_implementation.md`](../plans/browse_and_verb_implementation.md) and
[`plans/pedagogy_implementation.md`](../plans/pedagogy_implementation.md)), which are the raw
material for the release notes in `docs/release_notes.txt`.

## Before Submitting

1. **Create the new version in App Store Connect.**
2. **Check the lookup signals on a device.** The simulator never sends signals (its world uses
   `AnalyticsSpy`), so `finishSearch`, `leaveVerbView`, and `viewVerbView`'s `source` have been
   seen only in a temporary log. Run a Debug build on a device, flip the
   TelemetryDeck dashboard's Test Mode toggle, and confirm that a search, a verb page, a widget tap
   (`source` `widget`), and the Random Verb control (`source` `control`) arrive with the parameters
   in `docs/feature_architecture.md` § Analytics. A tap of a verb page's share button should send
   `tapShareVerb`, which no log has shown, since the spy does not print.
3. **Share a verb's page from a device** into Messages and Mail. The share
   sheet, its header, and its Copy were tried only in the simulator. Check that the App Store link
   is tappable in both and that the gloss's quotation marks survive, in English and Spanish.
4. **Try Find a Verb from Control Center and the Home Screen on a device**.
   In the simulator the quick action was tried with the app running and not running, but the
   control was never added to Control Center; only its link was drained. Add the control, tap it
   with the app closed and open, and check that the Verbs tab opens with the search field focused
   and the keyboard up. Check the quick action's title in Spanish ("Buscar un verbo") too. With
   Test Mode on, a search begun from each should send `finishSearch` with `source` `control` or
   `quickAction`.
5. **Try the shortcuts and Spotlight on a device**. In the simulator, Look
   Up a Verb opened the right page or search but its answer was never seen or heard first, Siri
   was never tried, and Spotlight matched only titles. On a device: ask Siri "Look up a verb with
   Conjugar", say "tuve", and check that it speaks "tuve: Pretérito (yo) of tener" before opening
   tener's page with tuve marked; then "fue", which should name ser and ir and open the search.
   Run Start a Quiz and Random Verb from the Shortcuts app with Conjugar closed, and by Siri with
   Conjugar open in front (that case was not tried; their link waits for the app to become active,
   which it already is). In
   Spotlight, search "aprendimos", "learn", and "tuve": if they find aprender, aprender, and
   tener, the keywords work; if only "aprender" does, record it in `docs/feature_architecture.md`
   § Spotlight. On a Spanish-language device, check that the word prompt reads "¿Qué palabra debe
   consultar Conjugar?" (the simulator showed it in English after a language switch). With Test
   Mode on, a lookup that opens a page should send `viewVerbView` with `source` `lookup`, and a
   Spotlight tap `source` `spotlight`.

## On Release Day

1. **Deploy the staged privacy-policy lines.** Apply `docs/privacy_policy_pending.md` to
   `docs/privacy_policy3.txt`, in English and Spanish, by its own instructions, and publish the
   policy the day the release that sends the new signals goes live.

## Afterward
