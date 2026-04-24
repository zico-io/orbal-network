---
name: skill-optimize
description: Reviews a SKILL.md against the Tessl rubric, then iteratively proposes and applies edits until the skill clears the target score (default 90%) or max iterations run out (default 3, max 10). Shows a unified diff and confirms before each write unless --yes is passed. Use when the user wants to improve a SKILL.md, auto-fix review findings, tighten a vague description, or bring a skill up to publishing quality. Not for scoring-only — use /skill-review for that. Usage - /skill-optimize commit-smart, /skill-optimize onboard-host --max-iterations 5, /skill-optimize .mex/skills/foo --yes
---

# Skill Optimize

Iteratively improve a SKILL.md: review with the Tessl rubric, propose targeted
edits to the lowest-scoring dimensions, apply them with confirmation, re-score,
repeat. Stop when the score clears the target or the iteration budget is gone.

Sibling of `/skill-review`. If you only want a scorecard, use that instead.

## Workflow

### Step 1: Resolve the target

Same resolver as `/skill-review`:

- Path-looking (`/` in it or ends in `.md`) → treat as a path; append `SKILL.md`
  if it's a directory. Surface missing-file errors, don't invent.
- Bare token → `.mex/skills/<arg>/SKILL.md`.
- Empty → `ls .mex/skills/` and use `AskUserQuestion` to pick.

### Step 2: Parse flags

After the target token, accept any of:

- `--max-iterations N` — clamp to `[1, 10]`, default `3`.
- `--target-score P` — percent, default `90`.
- `--yes` / `-y` — skip per-iteration confirmation (for batch / CI-style use).

Unknown flags → stop and surface, don't silently ignore.

### Step 3: Baseline review

Run the full rubric inline (see **Reference** below for checklist + rubric
tables). Record:

- validation errors / warnings count
- Activation % (description)
- Content % (body)
- Average %

**Exit when:** average already ≥ target. Print the scorecard with
"Already above target — nothing to do." and stop. Do not rewrite a passing skill.

### Step 4: Optimization loop

**Prereq:** baseline review scores from Step 3.
**Exit when:** average ≥ target, iteration budget exhausted, or user chose `Stop`.

For iteration `i` in `1..=max_iterations`:

1. **Pick targets.** Take the 2–3 lowest-scoring dimensions from the last
   review. Break ties by preferring description dimensions over body ones —
   activation failures hurt more than implementation ones.

2. **Draft a revision.** Produce a revised SKILL.md that addresses those
   dimensions while preserving user intent. Play from the **Common Fixes**
   table in Reference. Preserve verbatim: commands, file paths, numeric
   thresholds, external URLs, and any line the author marked with `// keep`
   or `<!-- keep -->`. Rewrite prose, structure, and framing only.

3. **Show the diff.** Render a unified diff in a fenced block with `diff`
   syntax. If the diff is larger than ~80 lines, summarize the high-level
   intent first, then the diff.

4. **Gate the write.** Unless `--yes`, use `AskUserQuestion` with three
   options:
   - `Apply` — write the changes and re-review.
   - `Skip` — don't apply; move to the next iteration with the same baseline.
   - `Stop` — exit the loop immediately.

5. **Write.** Apply via the Edit tool with the smallest reasonable
   `old_string` / `new_string` pairs per change. Do **not** use Write — it
   would clobber anything the diff didn't name.

6. **Re-review.** Run the rubric again. Compare to the previous iteration:
   - If average ≥ target → break, we're done.
   - If any dimension dropped by ≥ 2 points → the optimizer over-trimmed.
     Offer to revert this iteration's changes before continuing.
   - Otherwise → next iteration.

### Step 5: Report

After the loop:

```
Score: <baseline>% → <final>% (<+delta>%) after <n> iterations

Changes applied:
  - <one-line summary of what changed>
  - <one-line summary of what changed>
```

Example:

```
Score: 72% → 91% (+19%) after 2 iterations

Changes applied:
  - Added "Use when…" clause and 3 usage examples to description
  - Promoted implicit steps to ### Step N: headings with exit criteria
```

If the loop stopped because of `Stop`, say so. If it stopped because the score
plateaued, say so and list the remaining low-scoring dimensions the author will
need to address by hand (often these are content the optimizer is deliberately
refusing to touch, like command semantics).

## Tips

- The optimizer must not fabricate behavior the skill doesn't have. If the
  description under-sells real capabilities, fix that; but don't claim the
  skill does things it doesn't.
- Prefer extracting detail into a `REFERENCE.md` sibling over deleting it.
  Progressive disclosure is an explicit rubric dimension, and authors rarely
  want their content removed outright.
- If a dimension starts low and stays low across two iterations, the optimizer
  is probably out of useful plays for that dimension — stop rather than
  thrashing. The remaining gap is a human-judgment call.
- For very short skills (< 50 lines), three iterations is overkill. One pass is
  usually enough; the re-review is the safety check.

---

## Reference

### Validation Checklist

| Check | Severity | Passes when |
|---|---|---|
| `skill_md_line_count` | error | total lines ≤ 500 |
| `frontmatter_valid` | error | starts with `---`, closes with `---`, parses as YAML |
| `name_field` | error | `name` present, kebab-case, matches the containing directory |
| `description_field` | error | `description` present, 20–1000 chars |
| `description_voice` | warn | third-person |
| `description_trigger_hint` | warn | contains a `Use when…` clause or equivalent |
| `body_present` | error | non-empty body |
| `body_examples` | warn | fenced code block or "Example" |
| `body_output_format` | warn | mentions output / return / format / result shape |
| `body_steps` | warn | ordered list or `### Step` headings |
| `frontmatter_unknown_keys` | warn | all top-level keys are in the known set |

### Activation Rubric (description)

| Dim | 1 | 2 | 3 | 4 |
|---|---|---|---|---|
| specificity | vague | one concrete capability | 2–3 capabilities | capabilities + named artifacts / verbs |
| trigger_term_quality | generic | some keywords | common synonyms | synonyms + user-voice phrases |
| completeness | only what OR only when | both, thin | both, clear | what + when + usage examples |
| distinctiveness_conflict_risk | could fire for anything | modest overlap | clear domain | clearly disjoint |

### Content Rubric (body)

| Dim | 1 | 2 | 3 | 4 |
|---|---|---|---|---|
| conciseness | repeats / explains Claude-obvious | some filler | tight, minor fat | every paragraph earns it |
| actionability | prose about the task | some examples | executable commands + outputs | copy-paste + decision trees + outputs |
| workflow_clarity | no order | implicit order | numbered steps | numbered steps + prereqs + exit criteria |
| progressive_disclosure | monolith | some sectioning | Reference separates detail | Reference + siblings + skimmable top |

### Common Fixes

| Low-scoring dimension | Typical edit play |
|---|---|
| `specificity` | Replace "helps with X" with 2–3 named capabilities and the artifacts touched. |
| `trigger_term_quality` | Add user-voice phrases: "when the user asks for / mentions / wants to…" |
| `completeness` | Ensure the description has *both* a "what" clause *and* a "Use when…" clause, plus a `Usage -` examples line. |
| `distinctiveness_conflict_risk` | Name the domain boundary: "Use only when …, not when …". |
| `conciseness` | Delete explanations of HTTP status codes, standard Unix commands, anything Claude already knows. Merge redundant examples. |
| `actionability` | Replace "run your tests" with the exact command + expected output. Add a decision tree for branching logic. |
| `workflow_clarity` | Promote implicit ordering to `### Step N:` headings. Add "prereq:" / "exit when:" clauses. |
| `progressive_disclosure` | Lift deep tables into `## Reference`. For > 300-line skills, consider splitting into a sibling `REFERENCE.md` and linking. |

### Score bands

| Average | Verdict |
|---|---|
| ≥ 90% | Ship. |
| 70–89% | Minor polish. |
| < 70% | Needs work. |
