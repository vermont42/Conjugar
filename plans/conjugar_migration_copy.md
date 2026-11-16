# Plan: finish moving Conjugar out of `Conjugar.mig`

**Who this is for.** A fresh Claude Code session running in `~/Desktop/workspace/Conjugar`.
You have no prior conversation context; everything you need is below. Verify the
preconditions in Step 0 rather than trusting this document — it was written 2026-08-06 and
state may have drifted.

**Goal.** Bring this working copy up to the merged migration work, carry over the 906 MB of
material that lives only in `../Conjugar.mig`'s working tree, prove the result builds, and
retire the old directory.

---

## What already happened

The 2026 modernization work — SwiftUI rewrite, new conjugation engine, AI tutor, widgets,
minigame — was developed on the `migration` branch in a **separate clone** at
`~/Desktop/workspace/Conjugar.mig`. That work is now merged:

- **PR:** https://github.com/vermont42/Conjugar/pull/11 — **MERGED** 2026-08-06, merge commit `0f0520b`
- 250 commits, 770 files, +252,302 / −9,709

So all *tracked* files reach this directory with a `git pull`. This plan is only about what
`git pull` cannot bring.

**The problem.** `Conjugar.mig` holds **906 MB across 515 gitignored files**, most of it
irreplaceable: purchased 3D rigs, purchased audio masters, source corpora, and the config
holding the TelemetryDeck app ID.

> **Already resolved, do not re-do:** `.claude/ios-build-verify.config.sh` used to be
> gitignored and was on an earlier version of this manifest. It was committed before the
> merge, so `git pull` now delivers it — along with the hand-measured five-tab coordinates
> that `calibrate.sh` cannot reproduce. Nothing to copy by hand.

---

## Step 0 — Verify preconditions

```bash
SRC=~/Desktop/workspace/Conjugar.mig
DST=~/Desktop/workspace/Conjugar        # you should already be here

git -C "$DST" branch --show-current     # expect: master
git -C "$DST" status --short            # expect: empty
git -C "$SRC" status --short            # expect: empty
git -C "$DST" fetch origin -q
git -C "$DST" rev-list --left-right --count origin/master...master
```

That last command prints `<behind> <ahead>`. As of writing it was `251 0` — a clean
fast-forward. **If the right-hand number is not 0**, this copy has local commits that were
never pushed; stop and ask Josh before pulling.

If `$SRC` no longer exists, the move already happened — skip to Step 5 and verify.

---

## Step 1 — Pull the merged work

Do this **before** copying. This copy is on the pre-migration `master`, whose `.gitignore`
predates entries like `audio-sources/`. Copy first and 906 MB shows up as untracked files —
one careless `git add -A` and purchased Pond5 masters and a licensed FBX rig get committed to
a public AGPL repo.

```bash
git -C "$DST" pull
git -C "$DST" log --oneline -1          # expect the merge commit 0f0520b or later
grep -c 'audio-sources' "$DST/.gitignore"   # expect 1 — proves the new .gitignore arrived
```

---

## Step 2 — Remove the dead AWS material

**⚠️ Irreversible, and not this plan's core purpose — confirm with Josh before running it.**

Gitignored leftovers from the 2017 app. The Pinpoint integration is long gone (README says
so explicitly), and these are not in git, so deletion is permanent.

```bash
cd "$DST"
du -sh AWSCore.framework AWSPinpoint.framework amplify awsconfiguration.json 2>/dev/null
rm -rf AWSCore.framework AWSPinpoint.framework amplify awsconfiguration.json
```

---

## Step 3 — Copy the manifest

Eight paths. `rsync -a` preserves timestamps and permissions and is safely re-runnable — a
second pass transfers only what is missing.

| # | Path | Size | Files | Why it cannot be recovered |
|---|------|------|-------|-----------------------------|
| 1 | `tools/blender/source/` | 725M | 70 | 23 FBX rigs, 4 `.blend` files, concept art — including the purchased `Flamenco_Dancer.fbx`. **Every sprite in the game renders from these.** Without them no dancer/bull/matador animation can ever be fixed or re-rendered. |
| 2 | `audio-sources/` | 70M | 13 | The three purchased Pond5 WAV masters (`Flamenco_Adventure`, `Spanish_Guitar_Standoff`, `Spanish_Tension`) plus `pixabay-mpg/`. Only the 192 kbps MP3s are committed. |
| 3 | `corpus/originals/` | 60M | 32 | The government / literature / medieval / technology corpora behind every example sentence and medieval attestation. |
| 4 | `docs/screenshots/` | 30M | 120 | `version_1..3` App Store upload bundles plus `game/` sprite-development captures. |
| 5 | `corpus/working/` | 19M | 277 | The `mined_*.json` LLM-mining outputs, indexes and shards. Regenerable only by re-running the whole mining pipeline against the corpora — real time and real cost. |
| 6 | `docs/spanish_verbs_made_simpler.pdf` | 1.2M | 1 | Commercial reference. Gitignored as *do not redistribute*. |
| 7 | `docs/french_verbs_made_simpler.pdf` | 1.7M | 1 | Its French companion, consulted for the sibling app Conjuguer. |
| 8 | `Conjugar/Secrets.xcconfig` | 4K | 1 | `TELEMETRY_DECK_APP_ID`. Without it the app still builds and runs — analytics just go nowhere. |

**Total: 906M / 515 files.**

```bash
SRC=~/Desktop/workspace/Conjugar.mig
DST=~/Desktop/workspace/Conjugar

MANIFEST=(
  tools/blender/source
  audio-sources
  corpus/originals
  corpus/working
  docs/screenshots
  docs/spanish_verbs_made_simpler.pdf
  docs/french_verbs_made_simpler.pdf
  Conjugar/Secrets.xcconfig
)

for p in "${MANIFEST[@]}"; do
  mkdir -p "$DST/$(dirname "$p")"
  rsync -a "$SRC/$p" "$DST/$(dirname "$p")/"
done
```

Expect a few minutes — item 1 alone is 725 MB. Run it in the background and wait on it
rather than blocking a foreground call.

### Deliberately excluded — do not copy

| Path | Size | Reason |
|------|------|--------|
| `tools/blender/renders/` | 6.6M | Rendered intermediates; the final flipbooks are committed in `Assets.xcassets/Game/`, and these regenerate from `source/`. |
| `tools/blender/dist/` | 1.6M | Packaged Blender output; rebuildable. |
| `build.log` | 836K | Regenerated by every build. |
| `__pycache__/` ×4, `.DS_Store` ×4 | ~90K | Machine noise. |
| `Conjugar.xcodeproj/**/xcuserdata/` | 196K | Per-user Xcode state; intentionally not shared. |
| `.claude/settings.local.json`, `.claude/scheduled_tasks.lock` | 4K | Per-machine Claude Code state. |

> `docs/glosses/`'s phase-2 scratch directories are gitignored but **do not exist on disk** —
> `.gitignore` records that they were preserved in `~/Desktop/workspace/Migration`. Nothing
> to copy.

---

## Step 4 — Verify the copy

Three checks. Run all three; 4b is the one that catches a partially copied directory.

**4a. Per-path size and file count.** Every row should read `OK`:

```bash
for p in "${MANIFEST[@]}"; do
  a=$(du -sk "$SRC/$p" | cut -f1); b=$(du -sk "$DST/$p" 2>/dev/null | cut -f1)
  m=$(find "$SRC/$p" -type f | wc -l);  n=$(find "$DST/$p" -type f 2>/dev/null | wc -l)
  [ "$a" = "$b" ] && [ "$m" = "$n" ] && s=OK || s="*** MISMATCH ***"
  printf "%-44s %8s KB / %4s files   %s\n" "$p" "$a" "$m" "$s"
done
```

**4b. Dry-run rsync** — compares content, not just totals. Silence means complete:

```bash
for p in "${MANIFEST[@]}"; do
  rsync -an --itemize-changes "$SRC/$p" "$DST/$(dirname "$p")/"
done
```

**4c. Git should see nothing.** That these stay invisible is the whole point:

```bash
git -C "$DST" status --short          # expect empty
```

If anything appears here, the `.gitignore` from Step 1 did not arrive. **Stop** and fix that
before committing anything.

---

## Step 5 — Prove this location actually works

Config is the failure mode that size-based verification cannot catch, so exercise it.
`CLAUDE.md` documents the build commands; resolve the scripts once:

```bash
cd "$DST"
export IBV_SCRIPTS=$(dirname "$(find ~/.claude/plugins/marketplaces -path '*ios-build-verify*' -name build_app.sh 2>/dev/null | head -1)")
"$IBV_SCRIPTS/build_app.sh"
"$IBV_SCRIPTS/run_tests.sh"           # expect: Test run with 550 tests in 30 suites passed
"$IBV_SCRIPTS/launch_app.sh"          # exercises the launch anchor + tab coords
"$IBV_SCRIPTS/tap_tab.sh" settings    # exercises MAIN_TABS_COORDS specifically
```

The tests are long-running; start them in the background and wait rather than blocking.

Confirm the TelemetryDeck ID arrived (manifest item 8):

```bash
grep -q 'TELEMETRY_DECK_APP_ID' Conjugar/Secrets.xcconfig && echo "Secrets present"
```

Then confirm the gloss-pipeline scripts resolve against this root. They were repointed away
from a hardcoded `Conjugar.mig` path segment, and this is the first run that proves it:

```bash
cd "$DST/docs" && python3 -c "
import importlib.util, os
spec = importlib.util.spec_from_file_location('bvm','_build_verbmap.py')
bvm = importlib.util.module_from_spec(spec); spec.loader.exec_module(bvm)
print('REPO   ', bvm.REPO)
print('OUT_XML', bvm.OUT_XML, os.path.exists(bvm.OUT_XML))
"
```

`REPO` must print a path ending in `/workspace/Conjugar` with **no** `.mig`, and `OUT_XML`
must exist. `OLD_VERBS_XML` pointing at a missing `verbs.xml` is expected — that is the
deleted legacy engine, and `load_old_xml_glosses()` returns `{}` by design.

---

## Step 6 — Retire the source

**⚠️ Confirm with Josh before running.** Only after Steps 4 and 5 pass:

```bash
mv ~/Desktop/workspace/Conjugar.mig ~/Desktop/workspace/Conjugar.mig.retired
```

Renaming rather than deleting keeps a complete rollback. Josh deletes
`Conjugar.mig.retired` himself once he has gone a few sessions without reaching for it.
**Do not `rm -rf` it.**

---

## Done when

- [ ] `git log --oneline -1` shows the merge commit or later
- [ ] All eight manifest rows report `OK`, and 4b is silent
- [ ] `git status --short` is empty
- [ ] `run_tests.sh` reports 550 tests in 30 suites passed
- [ ] `tap_tab.sh settings` lands on the Settings tab
- [ ] `bvm.REPO` has no `.mig` in it
- [ ] `Conjugar.mig` renamed to `Conjugar.mig.retired`

---

## Rollback

Through Step 5 the source tree is untouched and every step is reversible — re-run Step 3, or
just keep working in `Conjugar.mig`. The only irreversible actions are Step 2's AWS deletion
and Josh's eventual removal of the retired directory. Both are flagged above and both want
his confirmation first.
