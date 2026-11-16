# Plan: Sort Prompts, Plans, and Documents, and Rename to snake_case

**For:** a fresh Claude Code session in this repo. **Kind of work:** moving and renaming prose and
data files, repairing every reference to them, and three small documentation edits. No app
behavior changes. **Written:** 2026-11-16 by the Konjugieren session that did the same work there
that day (Konjugieren commits `42ef201` and `bb22346`).

## Status

**Done 2026-11-16, uncommitted.** 99 renames in two runs of the tool (95 files and the
`end_scene_images/` directory, then three directories), recorded in
`plans/location_cleanup_moves.json` except for the three directories of the second run:
`asset-licenses/` → `asset_licenses/`, `scripts/symbol-sources/` → `scripts/symbol_sources/`,
and `Images/` → `images/`. Of the 71 Markdown files in `prompts/`, 24 are Josh's and stayed; 44
went to `plans/` and three to `docs/`. One of Josh's moved the other way, from `docs/` to
`prompts/`. `CLAUDE.md` has the two new sections and `docs/project_structure.md` lists every file
in all three folders.

**How it differed.** Josh widened the scope when asked: the seven Python scripts in `docs/` moved
to `scripts/` with their paths rewritten by hand, and every kebab-case name outside the three
folders was renamed too, including `images/` and the Noun Project SVGs. The thirty
`Conjugar.mig/...` mentions needed nothing, since none names a file that moved. The tool missed
two kinds of reference that the plan did not foresee: a path split across `os.path.join`
arguments, and a bare name (`milagros-berceo.txt`) shared by a downloaded original and the file
derived from it. It also rewrote only the first of several `Images/` paths on a line of
`README.md`. All three were fixed by hand.

## What Josh Wants, and Why

Josh's own words, from the prompt that started this in Konjugieren
(`../Konjugieren/prompts/location_cleanup.md`):

> In my head canon, a prompt is something that I write to get Claude to do something, a plan is
> something that Claude writes to get another session to do something, and a document is an
> output from Claude that contains information and is not a plan. Example: research.

And the reason, which settles more borderline files than the definitions do:

> If only Claude worked on this project, everything could live in one big folder. But folders
> make finding files easier for me. I sometimes don't even remember filenames, just a vague sense
> that I wrote a prompt or you wrote a plan about some subject.

So **authorship decides the folder**, and when a file fits two folders, choose the one where he
would look first. Then two rules about names:

> In general, I try to live by DRY, including in filenames. File location now specifies file
> role: plan or prompt. I prefer snake_case over kebab-case.

The end state: `prompts/` holds what Josh wrote, `plans/` holds what Claude wrote to direct
another session, `docs/` holds Claude's informational output, every file and directory in the
three folders is snake_case, and no filename repeats the word its folder already says.

## Read First

1. `../Konjugieren/CLAUDE.md`, the sections **Prompts, Plans, and Documents** and **File Naming**.
   They are the finished form of the rule. You will add adapted copies here.
2. `../Konjugieren/docs/blog_notes.md`, the seven entries dated 2026-11-16, starting at "Prompts,
   plans, and documents, each in its own folder". They say what went wrong and why each ruling
   was made. The last one, "A search that could not fail", is the one not to skip.
3. The docstring of `../Konjugieren/scripts/rename_files.py`, the tool you will use.
4. This repo's `CLAUDE.md`. Three of its rules bind this work: **do not commit or push**, append a
   journal entry to `docs/blog_notes.md`, and no em dashes between clauses.

## Rulings Already Made

Josh ruled on these cases in Konjugieren. Apply them here without asking again.

| Case | Ruling |
|---|---|
| A plan, orchestrator plan, subagent brief, handoff, or resume prompt that Claude wrote | `plans/`, even though a brief is a "prompt" in the ordinary sense |
| A prompt Claude wrote for another tool (an image generator, Claude in Chrome, Blender) | `plans/` |
| A file Josh began that Claude has mostly written since, and that still has work to do | `plans/`. Majority authorship decides, not who began the file |
| Josh's prompt carrying a status line Claude added later | `prompts/`. It is still his prompt |
| Research, an audit, tiered recommendations, a findings report | `docs/`, even with "plan" in the name |
| A playbook or pipeline description: how something is done whenever it is done | `docs/` |
| A review sheet or audit that a plan's phase generated | Stays beside that plan in `plans/` |
| A file that drops "prompt" or "plan" and is left with too little to identify it | Name it for its subject (`example_prompt.md` became `example_authoring.md`) |
| The journal, `docs/blog_notes.md` | Retarget link targets only. Leave every word as written |
| A link to a renamed file in an old email | Not a reason to stop |
| A link to a renamed file in a **published blog post** | Stop and ask Josh before renaming |

Names that are not ours to choose stay as they are: Swift source files, anything a tool dictates
(`.claude/ios-build-verify.config.sh`, `.claude/rules/`), a downloaded file's publisher name, and
the conventional capitals of `README.md`, `LICENSE`, and `CLAUDE.md`.

## This Repo, As Measured on 2026-11-16

Measure again before relying on any number here.

- **Branch `master`, clean tree.** `plans/` exists and holds only this file.
- **`prompts/`: 73 files and one subdirectory**, in a mix of kebab-case and snake_case. This
  repo's `CLAUDE.md` says to create new plans "typically in the `prompts/` folder", so expect a
  large share of these to be Claude's plans. Subject pairs are a strong hint and are not proof:
  `ipad.md` beside `ipad-plan.md`, `end_scene.md` beside `end_scene_plan.md`, `code-review.md`
  beside `code-review-recommendations.md`.
- **Not prose, inside `prompts/`:** `etymology-verbs.json`, `example-uses-stepF-verbs.json`, and
  `end_scene_images/` (two `.txt` files and `recolor_suit.py`).
- **`docs/`: 44 files and three subdirectories.** `glosses/` has 68 tracked files. `screenshots/`
  and `__pycache__/` are untracked.
- **Not prose, inside `docs/`:** six Python scripts (`_build_verbmap.py`, `_extract_annexb.py`,
  `_phase1_prep.py`, and three `_phase3_*.py`), two PDFs, and `SpanishVerbFrequencies.xml`.
- **Read by path, so a rename must reach the reader:**
  - `scripts/sync_verb_history.py` and `scripts/README.md` read `docs/verb_history.txt` and
    `docs/verb_history_es.txt`.
  - `scripts/take_screenshots.sh`, `scripts/verify_store_media.sh`, and
    `scripts/prep_screenshot_sim.sh` name `docs/screenshot-plan.md`,
    `docs/screenshot-playbook.md`, and `docs/video_script.md`.
  - `docs/_build_verbmap.py` and `docs/_extract_annexb.py` read five files in `docs/`.
  - `.claude/rules/analytics.md` lists `docs/privacy_policy3.txt` under `paths:`. That is a glob
    the harness matches, not prose. If the file is ever renamed, the rule silently stops loading.
  - `README.md` names `docs/project-structure.md` and `docs/frequencies.txt`.
- **The Xcode project references nothing** in `docs/` or `prompts/`.
- **Outside links:** the only GitHub URL in this repo that points at one of its own files is to
  `LICENSE`. The Blog repo links to this repo's Swift files and branches and to nothing in
  `docs/`, `prompts/`, or `frequency/`. Re-run both searches yourself (step 1).
- **`Conjugar.mig`** appears about thirty times in this repo's own files as a path prefix. It
  appears to be this checkout's former folder name. The tool will skip those mentions and report
  them, because the prefix does not match the repo's present name. See step 5.
- **No docs checker.** Conjuguer and Konjugieren each have `scripts/check_docs.py`. This repo has
  none, so step 8 gives the checks to run by hand.

## The Work, in Order

### 0. Preflight

`git status` must be clean, so that the diff you hand Josh is only this work. If it is not, stop
and tell him.

### 1. Search for outside links before choosing any name

A rename that is pushed breaks every GitHub link to the old path, and GitHub does not redirect.
Run these **bare**: no `timeout`, which is not installed on this Mac, and no `2>/dev/null`.

```bash
grep -rnoE "github\.com/vermont42/Conjugar/(blob|tree|raw)/[A-Za-z0-9_./-]+" ~/Desktop/workspace/Blog/_posts | sort -u
grep -rnoIE "(github\.com|raw\.githubusercontent\.com)/vermont42/Conjugar/[A-Za-z0-9_./-]+" . --exclude-dir=.git --exclude-dir=corpus | sort -u
```

The first should print links to Swift files and branches. **If it prints nothing, the search is
broken, not clean.** That is the mistake Konjugieren's session made: a wrapped search failed
silently, its silence was reported as "no links", and the push broke two links in a published
post. If a published post links to any file you mean to move or rename, stop and ask Josh.

Also ask yourself whether the shipped app or App Store Connect points at a file by URL. The
privacy policy is the likely case. `docs/privacy_policy3.txt` is already snake_case and should
not need to move, which is the safe outcome.

### 2. Classify every file in `prompts/` and `docs/` by reading it

**Do not classify by filename.** Konjugieren's session guessed its `docs/` candidates from names
and was wrong in both directions: two files with "plan" in the name were not plans, and
`code-review.md` turned out to be five lines of Josh asking for a review.

Read the opening of every Markdown and text file. Authorship is usually obvious:

- **Josh's prompts** open in the first person with no heading, address Claude as "you", and run
  a few paragraphs. Typos are a fair sign.
- **Claude's plans** open with a title, name an audience ("a fresh session", "an orchestrator
  session"), carry a status line and a written date, and often run to hundreds of lines.
- **Claude's documents** report: findings, measurements, verdicts, recommendations.

The first commit that added a file helps when the text does not settle it:

```bash
git log --diff-filter=A --follow --format='%ad %s' --date=short -- <path> | tail -1
```

Build a table of every file: where it is, where it goes, its new name, and one line of reason.

**Files that are not prose.** Josh's prompt said: "Some files, for example Python scripts, are not
documents, plans, or prompts. Such files are outside the scope of this project, but please ask if
you see another type of file that should move." So do not sort the JSON, Python, PDF, and XML
files by authorship. Treat them this way:

- A data file or image that one plan or prompt reads travels with that file, so the two stay in
  one folder. `prompts/end_scene_images/` goes wherever the end-scene files that use it go.
- The Python scripts in `docs/` are a question for Josh: leave them, or move them to `scripts/`.
- All of them still take snake_case names if they stay in the three folders.

**Ask Josh once.** Gather the files you could not place and the non-prose questions into one
batch of questions, and ask before moving anything. Do not ask about the obvious ones. He
answers quickly and has been extending scope when asked.

### 3. Build the move map

Write the map as JSON, old path to new path, and save it as `plans/location_cleanup_moves.json`.
It is the record of what was renamed, and the Conjuguer session may read it (step 7).

Naming rules:

- snake_case, lowercase: hyphens become underscores, and a camelCase or capitalized name is
  split and lowered (`Localization.md` became `localization.md` in Konjugieren).
- Keep dots that belong to a version or a compound extension (`release_notes_2.0.txt`).
- Drop "prompt", "prompts", "plan", and "plans" as words in a name, in all three folders. If
  what remains no longer identifies the file among its neighbors, name it for its subject.
- Two files may share a name across folders. `prompts/ipad.md` and `plans/ipad.md` are fine and
  are what DRY asks for: one subject, and the folder says which is which. Two files may not
  share a name within a folder. The tool refuses that.
- Rename directories in the three folders as well, `docs/glosses/` if it needs it.

### 4. Dry run, read the report, apply

```bash
python3 ../Konjugieren/scripts/rename_files.py plans/location_cleanup_moves.json --exclude plans/location_cleanup.md --verbose
python3 ../Konjugieren/scripts/rename_files.py plans/location_cleanup_moves.json --exclude plans/location_cleanup.md --apply
```

`--exclude` keeps the tool out of this plan, which names the old paths on purpose. It matters
only if the plan has been committed, since the tool edits tracked files only.

The tool repairs Markdown link targets, written-out paths, and bare filenames in every tracked
text file, and gives `docs/blog_notes.md` link targets only. Read two lists in its report before
applying:

- **Skipped.** Paths whose prefix names a different file. Each is either correct to skip, such
  as a sibling repo's file, or a reference you must fix by hand. A GitHub URL in this list is an
  inbound link you missed in step 1.
- **Needs a human.** Relative mentions of a file that changes folder, and bare names that two
  renamed files share.

A directory that moves and a file inside it that is renamed need **two runs**: files first, then
the directory. The tool says so if you try both at once.

### 5. Fix what the tool cannot see

- **`Conjugar.mig/...` self-references.** Confirm with the journal or with Josh that this was the
  repo's own folder name. If so, the mentions in the Skipped list that name a moved or renamed
  file need the new path by hand. Do not rewrite the `Conjugar.mig` part itself: prompts and
  journal entries describe the tree as it was.
- **Names built at runtime.** Search the scripts for the stem of each renamed data file. A format
  string such as `"%s-round%d.json"` matches no filename, and Konjugieren had one.
- **Generated and untracked files.** List what is on disk, not only what is tracked, and list
  inside ignored directories, which `git status --ignored` shows as one line. If a script writes
  a file whose tracked sibling you renamed, rename the generated file too, add it to the map,
  and check its `.gitignore` line.
- **Another repo's file with the same path.** "Konjugieren's `docs/pdf.md`" has a prefix that
  looks like this repo's own. Review the changed lines that mention Konjugieren or Conjuguer:

  ```bash
  git diff HEAD -U0 | grep -E '^\+[^+]' | grep -iE 'Konjugieren|Conjuguer'
  ```
- **`paths:` globs** in `.claude/rules/*.md`, if you renamed anything they name.

### 6. Update the documents that describe the layout

- **`CLAUDE.md`:**
  - Add the two sections from Konjugieren's `CLAUDE.md`, **Prompts, Plans, and Documents** and
    **File Naming**, adapted to this repo. Change the repo name in the search recipe, and point
    at `../Konjugieren/scripts/rename_files.py`.
  - Change "When you create a new plan (typically in the `prompts/` folder)" to say `plans/`.
  - Every `docs/project-structure.md` becomes `docs/project_structure.md`. The tool does this.
- **`docs/project_structure.md`** (its new name). Its `prompts/` header calls that folder
  "Session plans and task briefs", which will be false. Rewrite the header, add a `plans/` tree,
  and give **every** file in `prompts/`, `plans/`, and `docs/` a one-line description by
  subject. Josh finds files by subject, so these lines are what the sorting is for. Compare each
  tree with `ls` when you finish. Konjugieren's had thirteen files it had never listed.

### 7. Cross-repo references

**Edit only this repo.** The Conjuguer session may be running at the same time.

- **This repo's references to Konjugieren, which was renamed today.** Fix these now:
  - `docs/history_corrections.md:1955`: `Konjugieren/prompts/verify-verb-history.md` is now
    `Konjugieren/plans/verify_verb_history.md`.
  - `docs/conjugar-ui-issues.md:19` and `:348`, `prompts/ui_claude.md:12`, `prompts/ui.md:11`:
    `Konjugieren/docs/ui-audit.md` is now `Konjugieren/docs/ui_audit.md`.
  - For any other, the full list of Konjugieren's renames is
    `git -C ../Konjugieren show -M --name-status 42ef201 | grep '^R'`.
- **This repo's references to Conjuguer.** Nine mentions name files in `Conjuguer/docs/` and
  `Conjuguer/prompts/`. If `../Conjuguer/plans/location_cleanup_moves.json` exists, update them
  from it. If it does not, list them in your report.
- **Other repos' references to this repo.** Do not edit them. Report them with their new paths.
  As of today they are: in Konjugieren, `plans/sweep_comments.md:11` and `prompts/comments.md:5`
  (`Conjugar.mig/prompts/sweep-comments.md`), and `plans/verify_verb_history.md:70-71`,
  `docs/verb_history_claims.md:100`, and `docs/verb_history_phase1.md:1084`
  (`Conjugar.mig/docs/history_corrections.md`, `docs/verb_history.txt`); in Conjuguer,
  `prompts/verify-verb-history.md`, which names the same two files.

### 8. Verify

There is no checker here, so run these and read the output.

```bash
# Every relative Markdown link resolves.
python3 - <<'EOF'
import os, re, subprocess
bad = 0
for f in subprocess.run(["git", "ls-files", "-co", "--exclude-standard", "*.md"], capture_output=True, text=True).stdout.splitlines():
    for n, line in enumerate(open(f, encoding="utf-8", errors="replace"), 1):
        for m in re.finditer(r"\[[^\]]*\]\(([^)#\s]+)(?:#[^)]*)?\)", re.sub(r"`[^`]*`", "", line)):
            t = m.group(1)
            if "://" in t or t.startswith(("/", "mailto:")):
                continue
            if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(f), t))):
                bad += 1
                print(f"{f}:{n}: broken link to {t}")
print(bad, "broken links")
EOF
```

Run that link check **before** step 4 as well, and compare. Links that were already broken are
not yours to explain.

- Every changed `.py` passes `python3 -m py_compile`, and every changed `.sh` passes `bash -n`.
- Every path that a changed script names exists on disk.
- Every tracked JSON file you renamed or edited still loads.
- No kebab-case name is left in the three folders: `ls prompts plans docs | grep -- -`.
- Old names are gone outside the journal. Search for a sample of them.
- `python3 scripts/sync_verb_history.py` still finds its inputs. Read its docstring for a mode
  that checks without writing.
- Swift files should change in comments only. Confirm it. If any other line changed, build and
  run the tests as `CLAUDE.md` describes.

### 9. Journal, then report

Append an entry to `docs/blog_notes.md`: narrative, dated, no em dashes between clauses. Say what
the classification found, what Josh ruled, and what differed from this plan.

Then tell Josh:

- the table of moves, with the files you placed on judgment marked;
- anything the Skipped list held that you could not resolve;
- the cross-repo references from step 7 that someone must fix elsewhere;
- **kebab-case names outside the three folders.** As of today: `frequency/` (three JSON files and
  `CORPES-LICENSE.txt`), the `asset-licenses/` directory and its eight files, three files in
  `corpus/grokked`, and `scripts/symbol-sources/`. `tools/blender/blender-mcp` is third-party. In
  Konjugieren Josh extended the rename to `verbdata/` only when asked, so ask. Do not rename
  these unasked.

**Do not commit or push.** Leave everything in the working tree on `master` for Josh's
`/commit-and-push`.

## Mistakes Made in Konjugieren, So That You Make New Ones

1. **Classified by filename.** Wrong in both directions. Read the files.
2. **Reported "a few" files in a data folder** after a count that had filtered out JSON. The
   folder was mostly JSON, and the true number was 63. Count without filters before you describe
   a scope to Josh.
3. **Trusted an empty search.** Covered in step 1. A check must be seen to find something before
   its silence means anything.
4. **Listed ignored files and saw only a directory.** `git status --ignored` collapses an ignored
   directory to one line. Fourteen working files were inside it.
5. **Wrote an example link in the journal.** A sample Markdown link in backticks still parses as
   a link to a checker. Describe a link in words.
