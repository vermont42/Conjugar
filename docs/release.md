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
   `AnalyticsSpy`), so `finishSearch`, `leaveVerbView`, and `viewVerbView`'s `source` (browse plan,
   Phase 2) have been seen only in a temporary log. Run a Debug build on a device, flip the
   TelemetryDeck dashboard's Test Mode toggle, and confirm that a search, a verb page, a widget tap
   (`source` `widget`), and the Random Verb control (`source` `control`) arrive with the parameters
   in `docs/feature_architecture.md` § Analytics.

## On Release Day

1. **Deploy the staged privacy-policy lines.** Apply `docs/privacy_policy_pending.md` to
   `docs/privacy_policy3.txt`, in English and Spanish, by its own instructions, and publish the
   policy the day the release that sends the new signals goes live.

## Afterward
