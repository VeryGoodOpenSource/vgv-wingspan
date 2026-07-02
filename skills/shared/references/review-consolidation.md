# Review Consolidation

All review agents return a [structured findings list](review-agent-instructions.md).
This procedure turns those lists into **one ordered set of findings** that is the single
source of truth for both the consolidated review file and the chat summary. The file and
the chat must never be authored separately — render both from the same ordered list, or
they drift and the ids stop matching.

## Step 1 — Collect

Gather the findings from every agent that returned. Tag each finding with its **category**
(the dimension of the agent that produced it) and build its **rule id** by namespacing the
agent's `rule` slug with the category slug — `<category-slug>/<rule>`, e.g.
`vgv/missing-null-check`, `best-practices/deprecated-model-id`. The rule id is the finding's
stable *class* handle: it survives re-runs and lets a user suppress a whole class, while the
`FINDING-NN` id (assigned in Step 3) is the conversational handle for this run.

| Agent | Category | Category slug |
|-------|----------|---------------|
| vgv-review-agent | VGV | `vgv` |
| architecture-review-agent | Architecture | `architecture` |
| best-practices-review-agent | Best Practices | `best-practices` |
| test-quality-review-agent | Tests | `tests` |
| code-simplicity-review-agent | Simplicity | `simplicity` |
| pr-readiness-review-agent | PR Readiness | `pr-readiness` |

## Step 2 — Deduplicate

If two agents report the same issue at the same `location` (same `file:line`, same root
cause), merge them into one finding. Keep the highest severity, keep the clearest title,
and record both agents under **Reported by**. Only keep them separate when the severity or
the actual concern genuinely differs.

## Step 3 — Order deterministically, then number

Sort the merged findings by, in order:

1. **Severity** — Critical, then Important, then Suggestion.
2. **Location** — file path ascending, then line number ascending.
3. **Rule id** — ascending, to break ties within the same location.

Assign ids in that final order: `FINDING-01`, `FINDING-02`, `FINDING-03`, … (zero-padded
to two digits; widen to three past 99). Because the sort key is derived from content
(severity, path, line, rule) and never from the order agents happened to return, the same
findings on the same code always get the same ids — re-running the review keeps `FINDING-03`
pointing at the same issue, and the user can say "fix FINDING-03, skip FINDING-07"
unambiguously. Sorting by file before category also keeps the numbering stable when an agent
is added to or dropped from the run.

## Step 4 — Write ONE consolidated file

Render the ordered list into a single file using the
[consolidated report template](review-report-template.md). Do not write one file per agent —
the per-agent detail lives in `raw/` for drill-down only. The consolidated file contains:

- A **diffstat header** (total findings and the per-severity breakdown).
- A **Findings Index** table in id order — this table is the source the chat summary mirrors.
  Each row shows the `FINDING-NN` id, severity, rule id, location, and title.
- **Detail sections** grouped by severity, each finding rendered with its id, rule id, `why`,
  `fix`, and a link to the agent's raw report.

## Step 5 — Print the aligned chat summary

Print the **same Findings Index**, in the **same id order, with the same titles**, so a
summary bullet and a file entry are unambiguously the same finding. Keep it scannable:
show every Critical and Important finding by id; collapse Suggestions to a count with a
pointer to the file. End with the path to the consolidated file.

```markdown
Review complete — <N> findings (<c> critical, <i> important, <s> suggestions). Full report: <path>

- FINDING-01 · 🔴 Critical · `architecture/layer-violation` · Presentation imports data client directly (lib/ui/home.dart:12)
- FINDING-02 · 🔴 Critical · `tests/missing-test-file` · AuthCubit has no test file (lib/auth/auth_cubit.dart)
- FINDING-03 · 🟡 Important · `best-practices/deprecated-model-id` · Uses deprecated model id `claude-3-opus` (lib/ai/client.dart:8)
- …
- + 4 suggestions (see FINDING-08–FINDING-11 in the report)
```

The id, severity, rule id, and title in each bullet are copied verbatim from the Findings
Index — never paraphrased.

## Step 6 — Act (by id or rule)

- **Auto-fix minor issues** (formatting, lint) — run the project's formatter/linter, stage.
- **Fix by id** — the user references findings by id ("apply FINDING-01 and FINDING-03").
  For each id, read the linked `raw/` report only if you need more detail than the `fix`
  line, address it, then re-run validation (project linter + test runner). Read only the
  reports you need — do not load every raw file into context.
- **Act by rule** — the user may reference a rule id to act on a whole class ("fix every
  `tests/missing-test-file`" or "ignore all `simplicity/inline-single-use`"). Apply the
  action to every finding sharing that rule id.
- **Present Important findings** via **AskUserQuestion**: fix all, review the list, or defer
  to the PR description.
- **Record remaining findings** (by id) in the PR description.

When you commit fixes, reference the ids in the commit body so the history maps back to the
review, e.g. `Addresses FINDING-01, FINDING-03 from code review.`
