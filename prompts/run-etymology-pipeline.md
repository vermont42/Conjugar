# Run the etymology pipeline (clean-session prompt)

Paste this into a fresh session to generate the next batch of Spanish verb etymologies.
It works verbatim every time — resume is automatic (progress is derived by diffing the
work-list against the keys already in `Etymologies.json`; there is no stored "next verb").

```
Read @prompts/etymology-pipeline.md and run one batch of the Spanish etymology pipeline. Resume from where the last session stopped: per Step 1, the next verbs are the smallest-numbered ranks (rank 1 = most-used first) in prompts/etymology-verbs.json (plus the select verbs) not yet keyed in Conjugar/Models/Etymologies.json. Do ~50 verbs (5 parallel general-purpose subagents × ~10). Then extract from the subagent transcripts, validate markup (Step 4), merge (Step 5), validate the JSON, and report progress (Step 7). Delegate all etymology writing to subagents — write none yourself.
```

## Knobs

- **Volume** — replace "run one batch" with "run batches until rank 100 is covered" (it
  loops Steps 1–7), or shrink to "~16 verbs (2 subagents)" for a quick top-up.
- **Commit** — append "then commit `Etymologies.json` with a one-line message" to checkpoint
  each batch in git.

## Check progress without running anything

```bash
python3 -c "
import json, pathlib
wl = json.loads(pathlib.Path('prompts/etymology-verbs.json').read_text())['verbs']
done = set(json.loads(pathlib.Path('Conjugar/Models/Etymologies.json').read_text())['en'])
todo = [v for v in wl if v['infinitive'] not in done]
print(f'Done {len(wl)-len(todo)}/{len(wl)} ranked verbs. Next 3:', [(v['rank'], v['infinitive']) for v in todo[:3]])"
```
