#!/usr/bin/env python3
import os, re, importlib.util
HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('bvm','_build_verbmap.py')
bvm = importlib.util.module_from_spec(spec); spec.loader.exec_module(bvm)
oldxml = bvm.load_old_xml_glosses()

CONS = os.path.join(HERE,'glosses/phase1/phase2/consensus_all.tsv')
CAND = os.path.join(HERE,'glosses/phase1/phase2_candidates.tsv')

flagged_before = set()
for l in open(CAND,encoding='utf-8').read().splitlines()[1:]:
    p=l.split('\t')
    if len(p)>4 and p[4]=='1': flagged_before.add(p[0])

rows=[l.split('\t') for l in open(CONS,encoding='utf-8').read().splitlines()[1:] if l.strip()]
def g(r,i): return r[i] if len(r)>i else ''
replaces=[r for r in rows if r[2]=='replace']
keeps=[r for r in rows if r[2]=='keep']
flags=[r for r in rows if r[2]=='flag']
keep_confirmed_flagged=[r for r in keeps if r[0] in flagged_before]

xml=open(bvm.OUT_XML,encoding='utf-8').read()
comma_oldxml=[]
for m in re.finditer(r'<verb in="([^"]+)"[^>]*tn="([^"]*,[^"]*)"',xml):
    if m.group(1) in oldxml: comma_oldxml.append((m.group(1),m.group(2)))

out=[]
out.append('# Gloss verification report (B2) — Phases 1–3\n')
out.append('Audited trail of the multi-agent gloss-verification pass over the 4,556 authored '
           'glosses in `docs/glosses/slice_*.tsv`. Phase 1 blind-glossed every verb (anti-anchoring) '
           'and flagged a 549-verb contested∪flagged set; Phase 2 ran 3 independent diverse-lens, '
           'web-grounded checkers per verb (RAE / Wiktionary / morphology) + a consensus reconciliation '
           '(≥2/3 same sense with ≥1 dictionary citation); Phase 3 applied the result to the slices. '
           'Written for a bilingual auditor — Josh cannot vet the Spanish himself.\n')
out.append('## Summary\n')
out.append(f'- Authored glosses swept: **4,556**')
out.append(f'- Contested∪flagged set verified by 3-checker consensus: **549**')
out.append(f'- Glosses **changed** (replace): **{len(replaces)}**')
out.append(f'- Previously-flagged glosses **confirmed** (flag cleared): **{len(keep_confirmed_flagged)}**')
out.append(f'- Flags before → after: **522 → {len(flags)}**')
out.append(f'- Consensus strength: {sum(1 for r in rows if g(r,4)=="3")}/549 unanimous (3/3), '
           f'{sum(1 for r in rows if g(r,4)=="2")}/549 at 2/3')
out.append(f'- Out-of-bounds findings (report-only, not auto-edited): **{len(comma_oldxml)}**\n')

out.append('## Changes applied (80 replacements)\n')
out.append('Each: `infinitive: old → new` · consensus N/3 · citation · rationale.\n')
for r in replaces:
    inf,cur,fin,ac,cit,conf=g(r,0),g(r,1),g(r,3),g(r,4),g(r,5),g(r,6)
    out.append(f'- **{inf}**: `{cur}` → `{fin}` · {ac}/3 · {conf} · {cit}')
out.append('')

out.append('## Previously-flagged glosses now confirmed (flag cleared)\n')
out.append(f'{len(keep_confirmed_flagged)} glosses that were self-flagged low-confidence by the '
           'single-pass author, now confirmed correct by ≥2/3 grounded consensus. Flag cleared.\n')
for r in keep_confirmed_flagged:
    inf,cur,ac,cit=g(r,0),g(r,1),g(r,4),g(r,5)
    out.append(f'- **{inf}**: `{cur}` ✓ · {ac}/3 · {cit}')
out.append('')

out.append('## Residual flags (genuinely unresolved)\n')
for r in flags:
    inf,cur,fin,cit,note=g(r,0),g(r,1),g(r,3),g(r,5),g(r,7)
    out.append(f'- **{inf}**: current `{cur}`; candidate `{fin}` — {cit} {("("+note+")") if note else ""}')
out.append('')

out.append('## Needs human decision — out-of-bounds (old `verbs.xml`-sourced, NOT auto-edited)\n')
out.append('These glosses come from the legacy `Conjugar/Models/verbs.xml` (source 2, '
           'read-only); a slice edit would be a no-op. They carry a **comma / second sense**, which the '
           'gloss convention prefers single-sense. They are **correct** multi-sense glosses — the '
           'single-sense choice is an English phrasing call (note `deber: owe, must` — the *second* '
           'clause is the more common sense), so this is a legitimate human decision, not a Spanish one. '
           'Options: terse-ify in `verbs.xml`, or extend `terse()` to the old-xml path (risks dropping '
           'the better sense). Left as-is for now.\n')
for inf,tn in comma_oldxml:
    out.append(f'- **{inf}**: `{tn}`')
out.append('')

open(os.path.join(HERE,'gloss_verification_report.md'),'w',encoding='utf-8').write('\n'.join(out))
print(f'report: {len(replaces)} changes, {len(keep_confirmed_flagged)} confirmed-flags, '
      f'{len(flags)} residual, {len(comma_oldxml)} out-of-bounds')
