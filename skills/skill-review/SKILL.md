---
name: skill-review
description: Reviews a local SKILL.md against the Tessl best-practices rubric and prints a scorecard - deterministic validation checks, Activation Score (description), Implementation Score (body), and an overall percentage. Use when the user wants to grade a skill, check activation quality, audit trigger-term wording, or validate a SKILL.md before publishing. Resolves a skill id to ./skills/<id>/SKILL.md; also accepts a direct file or directory path. Usage - /skill-review commit-smart, /skill-review ./skills/onboard-host, /skill-review /abs/path/SKILL.md
---

# Skill Review

Grade a SKILL.md against the Tessl best-practices rubric and produce a scorecard
that tells the author what to keep, what to tighten, and whether the skill is
ready to ship.

This skill is judgment, not execution — it does not write to the target file.
For auto-fix, use `/skill-optimize`.

## Workflow

### Step 1: Resolve the target

Parse `$ARGUMENTS`:

- Contains `/` or ends in `.md` → treat as a path. If it's a directory, append
  `SKILL.md`. If the path doesn't exist, stop and surface the error.
- Bare token → resolve to `./skills/<arg>/SKILL.md` relative to the repo root.
- Empty → list the local skills with `ls skills/` and use `AskUserQuestion` to
  pick one. If the cwd has no `skills/` dir, ask the user for a path.

### Step 2: Read the SKILL.md

Read the full file with the Read tool. Split into YAML frontmatter (between the
first two `---` fences) and body. Record the total line count.

### Step 3: Run validation checks

Walk the checklist in **Reference → Validation Checklist**. Every check emits
one of `✔`, `⚠`, `✖` plus a one-line reason. Tally errors and warnings.

### Step 4: Activation Score (description)

Grade the `description` field on four 0–4 dimensions from the **Activation
Rubric** in Reference:

- `specificity` — does it name concrete capabilities, not hand-wavy "helps with X"?
- `trigger_term_quality` — does it include the natural words a user would say?
- `completeness` — does it cover both *what* the skill does and *when* to use it?
- `distinctiveness_conflict_risk` — is it distinct from neighbouring skills?

Each dimension: a single sentence grounded in concrete phrases from the actual
description. Then:

- A 1–2 sentence `Assessment` paragraph calling out the dominant failure mode.
- 2–4 bullet `Suggestions` — each a concrete rewrite or addition, not "be more
  specific".

Convert to a percentage: `(sum / 16) * 100`, rounded.

### Step 5: Implementation Score (body)

Same treatment for the body on the **Content Rubric** dimensions:

- `conciseness` — is every sentence pulling weight? Flag explanations of
  concepts Claude already knows.
- `actionability` — are there copy-paste-ready commands, examples, decision
  trees? Or just prose *about* the task?
- `workflow_clarity` — is the order explicit (numbered steps, "first … then"),
  and does each step have a clear start and end?
- `progressive_disclosure` — is high-signal content up top, with detail pushed
  to Reference / sibling files? Or is it a monolithic wall?

Same output shape: four graded dimensions, Assessment, Suggestions. Percentage
is `(sum / 16) * 100`.

### Step 6: Render the scorecard

Print in this exact shape (matches `tessl skill review` output so it's
recognizable):

```
Validation Checks

  ✔ skill_md_line_count - SKILL.md line count is <N> (<= 500)
  ✔ frontmatter_valid - YAML frontmatter is valid
  ...
  ⚠ description_trigger_hint - Description may be missing an explicit 'when to use' trigger hint
  ...

Overall: <PASSED|FAILED> (<errors> errors, <warnings> warnings)

Judge Evaluation

  Description: <A>%
    specificity: <n>/4 - <one-line reason>
    trigger_term_quality: <n>/4 - <one-line reason>
    completeness: <n>/4 - <one-line reason>
    distinctiveness_conflict_risk: <n>/4 - <one-line reason>

    Assessment: <1-2 sentences>

    Suggestions:
      - <concrete rewrite>
      - <concrete rewrite>

  Content: <C>%
    conciseness: <n>/4 - <one-line reason>
    actionability: <n>/4 - <one-line reason>
    workflow_clarity: <n>/4 - <one-line reason>
    progressive_disclosure: <n>/4 - <one-line reason>

    Assessment: <1-2 sentences>

    Suggestions:
      - <concrete rewrite>
      - <concrete rewrite>

Average Score: <round((A + C) / 2)>%
```

Then interpret the average using **Reference → Score bands** and end with one
sentence: ship / minor polish / needs work.

## Tips

- The description is the skill's activation surface. A skill that never fires
  has 0% effective quality regardless of its body. When in doubt, grade the
  description harder.
- "Third-person voice" in a description means it describes the *skill*, not the
  *user*. `Reviews a SKILL.md…` ✔. `Use this to review your skill…` ⚠ —
  second-person but tolerable if it's paired with a clear capability clause.
- Don't grade `conciseness` low just because the SKILL.md is long. Length is
  fine when every paragraph earns its place (`onboard-host` is 278 lines and
  that's correct). Grade it low when the same idea is said twice or when
  Claude-obvious concepts are explained.
- The scorecard is advisory. The author owns the call.

---

## Reference

### Validation Checklist

| Check | Severity | Passes when |
|---|---|---|
| `skill_md_line_count` | error | total lines ≤ 500 |
| `frontmatter_valid` | error | starts with `---`, closes with `---`, parses as YAML |
| `name_field` | error | `name` present, kebab-case, matches the containing directory |
| `description_field` | error | `description` present, 20–1000 chars |
| `description_voice` | warn | description is third-person ("Reviews…", "Creates…"), not "You / this skill lets you…" |
| `description_trigger_hint` | warn | description contains a `Use when…` clause or equivalent |
| `compatibility_field` | ok | absent, or a known platform string |
| `allowed_tools_field` | ok | absent, or a list of tool names |
| `metadata_version` | warn | if `metadata` present, it's a mapping (dict) |
| `metadata_field` | ok | absent or a dict |
| `license_field` | warn | present if the skill is intended for publication |
| `frontmatter_unknown_keys` | warn | all top-level keys are in the known set |
| `body_present` | error | non-empty body after the closing `---` |
| `body_examples` | warn | contains a fenced code block or the word "Example" |
| `body_output_format` | warn | mentions output / return / format / result shape |
| `body_steps` | warn | contains an ordered list or `### Step` headings |

Overall PASSED unless any error-severity check fails.

### Activation Rubric (description)

| Dim | 1 | 2 | 3 | 4 |
|---|---|---|---|---|
| specificity | vague ("helps with X") | one concrete capability | 2–3 concrete capabilities | named capabilities + named artifacts / verbs |
| trigger_term_quality | generic | some relevant keywords | covers common synonyms | covers synonyms + user-voice phrases ("how do I…") |
| completeness | only *what* OR only *when* | both but one is thin | both clearly stated | what + when + usage examples |
| distinctiveness_conflict_risk | could fire for anything in this space | modest overlap with siblings | clear domain with one edge conflict | clearly disjoint — no plausible miss-fire |

### Content Rubric (body)

| Dim | 1 | 2 | 3 | 4 |
|---|---|---|---|---|
| conciseness | repeats itself / explains Claude-obvious concepts | some filler | tight with minor fat | every paragraph earns its place |
| actionability | prose about the task | some examples | executable commands with expected outputs | copy-paste-ready commands + decision trees + expected outputs |
| workflow_clarity | no discernible order | implicit order | numbered steps | numbered steps + explicit prereqs + exit criteria |
| progressive_disclosure | monolith | some sectioning | Reference section separates detail | Reference + sibling files + top stays skimmable |

### Score bands

| Average | Verdict |
|---|---|
| ≥ 90% | Conforms to best practices. Ship. |
| 70–89% | Good — minor polish recommended before publishing. |
| < 70% | Needs work. Run `/skill-optimize` or address the lowest-scoring dimensions by hand. |
