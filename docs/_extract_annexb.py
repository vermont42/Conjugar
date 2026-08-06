#!/usr/bin/env python3
"""Extract Annex B (Index by Class and Sub-class) from spanish_verbs_made_simpler.pdf
(pages 228-285) into a Markdown table mapping each of the 4,818 verbs to its
conjugation-model class (sub-class) and model number."""
import re
import subprocess

PDF = "spanish_verbs_made_simpler.pdf"
FIRST, LAST = 228, 285
OUT = "annex_b_verb_models.md"

LIG = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl", "ﬅ": "ft", "ﬆ": "st"}
NUM_RE = re.compile(r"^\d+[A-Z]?(?:-\d+)?$")
FN_RE = re.compile(r"(\d+)$")  # trailing footnote marker on a verb token

# Footnotes 1-25, transcribed from the bottoms of the annex pages.
FOOTNOTES = {
    1: "Frequently conjugated without written accents (e.g., *agrio* rather than *agrió*).",
    2: "To bet.",
    3: "To station or post.",
    4: "To raze, devastate.",
    5: "To burn up, parch.",
    6: "To demolish.",
    7: "To terrify.",
    8: "To stuff.",
    9: "To attest.",
    10: "The new orthographic rules allow alternative forms for the simple past 1s and 3s—*crie/crié, crio/crió*—as well as for the present indicative and subjunctive 2p—*criais/criáis* and *crieis/criéis*.",
    11: "Past participle: *desprovisto/desproveído*.",
    12: "Can also be conjugated without diphthongs, like *cantar*.",
    13: "The new orthographic rules allow alternative forms for the simple past 1s and 3s—*fie/fié, fio/fió*—as well as for the present indicative and subjunctive 2p—*fiais/fiáis* and *fieis/fiéis*.",
    14: "The new orthographic rules allow alternative forms for the simple past 1s—*flui/fluí*—as well as for the present indicative 2p—*fluis/fluís*.",
    15: "Past participle: *frito/freído*.",
    16: "The new orthographic rules allow alternative forms for the simple past 1s and 3s—*guie/guié, guio/guió*—as well as for the present indicative and subjunctive 2p—*guiais/guiáis* and *guieis/guiéis*.",
    17: "The new orthographic rules allow alternative forms for the simple past 1s—*hui/huí*—as well as for the present indicative 2p—*huis/huís*.",
    18: "The new orthographic rules allow alternative forms for the simple past 1s and 3s—*lie/lié, lio/lió*—as well as for the present indicative and subjunctive 2p—*liais/liáis* and *lieis/liéis*.",
    19: "The new orthographic rules allow alternative forms for the simple past 1s and 3s—*pie/pié, pio/pió*—as well as for the present indicative and subjunctive 2p—*piais/piáis* and *pieis/piéis*.",
    20: "Conjugation identical to that of *pudrir* apart from infinitive.",
    21: "Past participle: *provisto/proveído*.",
    22: "Past participle: *refrito/refreído*.",
    23: "In conjugations where stem syllable is stressed, ehu → ehú (as for 1-8 *rehusar*).",
    24: "Past participle: *sofrito/sofreído*.",
    25: "Exists in all six persons but not used in future, conditional, or imperative.",
}


def deligature(s):
    for k, v in LIG.items():
        s = s.replace(k, v)
    return s


def run_pdftotext():
    out = subprocess.run(
        ["pdftotext", "-layout", "-f", str(FIRST), "-l", str(LAST), PDF, "-"],
        capture_output=True, text=True, check=True,
    )
    return out.stdout


def split_verb_footnote(verb):
    """Strip a trailing footnote marker (a bare integer) from a verb token.
    Homonym disambiguators like 'apostar (1)' end in ')' and are preserved."""
    m = FN_RE.search(verb)
    if m and not verb.endswith(")"):
        return verb[: m.start()].strip(), int(m.group(1))
    return verb, None


def records_from_fields(fields):
    recs = []
    if len(fields) >= 3 and NUM_RE.match(fields[2]):
        recs.append((fields[0], fields[1], fields[2]))
    if len(fields) >= 6 and NUM_RE.match(fields[5]):
        recs.append((fields[3], fields[4], fields[5]))
    return recs


def main():
    text = deligature(run_pdftotext())
    master = []
    for page in text.split("\f"):
        left, right = [], []
        for raw in page.splitlines():
            line = raw.strip()
            if not line:
                continue
            fields = re.split(r"\s{2,}", line)
            if fields[0] == "Verb":
                continue
            recs = records_from_fields(fields)
            if not recs:
                continue
            left.append(recs[0])
            if len(recs) > 1:
                right.append(recs[1])
        master.extend(left)
        master.extend(right)
    # Normalize footnote markers.
    out = []
    for verb, cls, num in master:
        verb, fn = split_verb_footnote(verb)
        out.append((verb, cls, num, fn))
    return out


def md_escape(s):
    return s.replace("|", "\\|")


if __name__ == "__main__":
    recs = main()
    used_fns = sorted({fn for *_, fn in recs if fn})
    lines = []
    lines.append("# Annex B — Index by Class and Sub-class for 4,818 Verbs")
    lines.append("")
    lines.append("_Extracted from `docs/spanish_verbs_made_simpler.pdf`, pages 228–285 "
                 "(printed pages 215–272), Annex B._")
    lines.append("")
    lines.append("Each Spanish verb is mapped to the **conjugation model** it follows. The "
                 "**Model (sub-class)** column names the parent model and, in parentheses, the "
                 "specific sub-class whose irregularity it inherits (e.g. `cantar (tocar)` = the "
                 "regular `-ar` model `cantar`, tocar sub-class for the c→qu spelling change). "
                 "The **#** column is the book's model number for that (sub-)class. This is the "
                 "mapping needed to assign a model to each verb when porting the parsimonious "
                 "model scheme to Conjugar.")
    lines.append("")
    lines.append("Conventions (from the annex preamble):")
    lines.append("")
    lines.append("- Alphabetized per post-1994 rules: `ch` and `ll` are treated as the letter "
                 "pairs `c+h`, `l+l`; `ñ` remains a separate letter following `n`.")
    lines.append("- **DEF** (defective): the verb is normally used only in certain "
                 "conjugations (infinitive, participles, and third person).")
    lines.append("- A verb shown with `(se)` (e.g. `arrepentir(se)`) is used only reflexively.")
    lines.append("- Homonyms with different conjugations are disambiguated as `(1)` / `(2)` "
                 "(see footnotes).")
    lines.append("- Superscript footnote markers in the source are rendered here in the "
                 "**Note** column; see [Footnotes](#footnotes).")
    lines.append("")
    lines.append(f"**Total verbs:** {len(recs)}")
    lines.append("")
    lines.append("| # | Verb | Model (sub-class) | Model # | Note |")
    lines.append("|---:|------|-------------------|---------|:----:|")
    for i, (verb, cls, num, fn) in enumerate(recs, 1):
        note = f"[{fn}](#fn{fn})" if fn else ""
        lines.append(f"| {i} | {md_escape(verb)} | {md_escape(cls)} | {num} | {note} |")
    lines.append("")
    lines.append("## Footnotes")
    lines.append("")
    for fn in used_fns:
        lines.append(f'<a id="fn{fn}"></a>**{fn}.** {FOOTNOTES[fn]}')
        lines.append("")
    with open(OUT, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {OUT}: {len(recs)} verbs, {len(used_fns)} footnotes")
