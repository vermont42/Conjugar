# Applying the verb-history corrections

**Status:** not started. Written 2026-07-28, when `docs/history_corrections.md` was finished.

`docs/history_corrections.md` is the fact-check of `docs/verb_history.txt`, the source of
`Info.verbHistoryText`. It holds 84 findings — 20 factual errors, 24 needing hedging, and 40
nitpicks — each with quoted claim, line number, what is actually true, the evidence, and
concrete replacement prose. 104 further proposals were dismissed by an adversarial pass and
are recorded per cluster under collapsed "Raised and dismissed" headings.

Nothing in the essay has been changed. Every entry is a proposal.

## Three things that will bite a fresh session

**1. The nitpicks should not get a blanket "address."** Forty of them, and the grade means "a
specialist's quibble that misleads nobody." Applied mechanically they will cost the essay its
voice. Several are of the form "strictly, the epenthetic *d* breaks a cluster rather than
propping up a syllable," which is true and would turn a good sentence into a worse one — the
document dismissed a batch of similar proposals on exactly that ground. Run errors and hedges
as one pass, then review the nitpicks as a list and pick.

**2. Some findings collide.** Lines 160, 172 and 196 each carry two findings, and cluster C's
"stayed four hundred years" (line 219) is the same underlying claim as cluster G's "two hundred
years more" (line 104), arrived at by different agents that never spoke to each other. A
session applying revisions one at a time in cluster order will double-edit those sentences.

**3. The markup rules are neither optional nor obvious.** Revisions preserve `^heading^`,
`~emphasis~`, `$IRregularity$` and `%tappable term%`; markers must not nest; no `$…$` span may
start with a lone capital, since a capital there means "irregular, shown red" and would
silently redden the first letter of a sentence. Two revisions add a new
`%presente de subjuntivo%` link, which is legal but wants the validator to confirm it.

## The prompt

```
docs/history_corrections.md fact-checks docs/verb_history.txt. Read it fully.

Apply every finding graded "factual error" and "needs hedging", using the
suggested revision as the default and departing from it only if it introduces
a problem. House style: no em-dashes, no parentheticals, preserve all markup
markers, never nest them.

Lines 160, 172 and 196 each carry two findings, and line 104's "two hundred
years more" is the same claim as line 219's "stayed four hundred years" —
resolve each of those as a single edit, not two.

Do NOT apply the nitpicks. List them with a one-line recommendation each and
stop for my decision.

Do not run `python3 scripts/sync_verb_history.py`, which would validate the
markup and push the article into the string catalog. Josh will hand-edit
`docs/verb_history.txt` before having you do that.
```
