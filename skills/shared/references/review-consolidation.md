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
`vgv/missing-null-check`, `architecture/layer-violation`. The rule id is the finding's
stable *class* handle: it survives re-runs and lets a user suppress a whole class, while the
`FINDING-NN` id (assigned in Step 3) is the conversational handle for this run.

| Agent | Category | Category slug |
|-------|----------|---------------|
| vgv-review-agent | VGV | `vgv` |
| architecture-review-agent | Architecture | `architecture` |
| test-quality-review-agent | Tests | `tests` |
| code-simplicity-review-agent | Simplicity | `simplicity` |
| pr-readiness-review-agent | PR Readiness | `pr-readiness` |

For any agent not listed — a project may add its own — derive two things from the agent name:
its **report `<name>`** by dropping the trailing `-agent` (`security-review-agent` →
`security-review`, matching the table's `<x>-review` convention), and its **category slug** by
dropping the trailing `-review-agent` and kebab-casing the rest (`security-review-agent` →
`security`).

## Step 2 — Deduplicate

If two agents report the same issue at the same `location` (same `file:line`, same root
cause), merge them into one finding. Keep the highest severity, keep the clearest title, and
record both agents under **Reported by**. Keep the rule id of the higher-severity finding; on
a tie, the one whose category comes first in the Step 1 table. Only keep them separate when
the severity or the actual concern genuinely differs.

## Step 3 — Order deterministically, then number

Sort the merged findings by, in order:

1. **Severity** — Critical, then Important, then Suggestion.
2. **Location** — file path ascending, then line number ascending. A finding with a bare file
   (no line) sorts as line 0, before any `file:line` finding in the same file.
3. **Rule id** — ascending, to break ties within the same location.

Assign ids in that final order: `FINDING-01`, `FINDING-02`, `FINDING-03`, … (zero-padded
to two digits; widen to three past 99). Because the sort key is derived from content
(severity, path, line, rule) and never from the order agents happened to return, the same
findings on the same code always get the same ids — re-running the review keeps `FINDING-03`
pointing at the same issue, and the user can say "fix FINDING-03, skip FINDING-07"
unambiguously. Ids are only guaranteed stable for an unchanged finding set: fixing code, or
adding or dropping an agent, changes which findings exist and renumbers the rest — the rule
id is the handle that survives those changes, so prefer it when referring across runs.

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

Print the Critical and Important rows from the Findings Index **verbatim** — same ids, same
order, same titles — so a summary bullet and a file entry are unambiguously the same finding.
Collapse Suggestions to a single count with a pointer to the file (they live in full in the
report). Lead with the report path and the severity counts.

```markdown
Review complete — <N> findings (<c> critical, <i> important, <s> suggestions). Full report: <path>

- FINDING-01 · 🔴 Critical · `tests/missing-test-file` · AuthCubit has no test file (lib/auth/auth_cubit.dart)
- FINDING-02 · 🔴 Critical · `architecture/layer-violation` · Presentation imports data client directly (lib/ui/home.dart:12)
- FINDING-03 · 🟡 Important · `vgv/force-unwrap` · Force-unwrap on a nullable token (lib/auth/token.dart:20)
- …
- + 4 suggestions (see FINDING-08–FINDING-11 in the report)
```

The id, severity, rule id, and title in each bullet are copied verbatim from the Findings
Index — never paraphrased.

## Step 6 — Acting on findings

Each calling skill defines its own post-review menu (`/review` is advisory and asks first;
`/build` and `/hotfix` fix before shipping). This section only fixes the shared vocabulary
those menus use.

- **By id** — the user references findings by id ("apply FINDING-01 and FINDING-03"). For
  each id, read the linked `raw/` report only when the one-line `fix` isn't enough; read only
  the reports you need — never load every raw file into context.
- **By rule** — a rule id acts on a whole class ("fix every `tests/missing-test-file`",
  "ignore all `simplicity/inline-single-use`"). Apply the action to every finding sharing it.
- **Commit trace** — when fixes are committed and the consolidated report is kept (as in
  `/review`), reference the ids in the commit body, e.g. `Addresses FINDING-01, FINDING-03
  from review.` Skills that delete the report after acting (`/build`, `/hotfix`) fix findings
  in place and do not cite ids, since the report they would point to no longer exists.
