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
`FINDING-NN` id (assigned in Step 4) is the conversational handle for this run.

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

A [companion reviewer](review-dispatch.md) returns its own format instead of the findings
block. Save its reply verbatim to `<RAW_DIR>/<name>.md`, so its details link works, then map
each of its findings:

- its location → `location`, its problem → `title` and `why`, its fix → `fix`, and its
  category or standard column → `rule`;
- severity → Critical when that category names security, Important otherwise;
- category slug → the agent name without the plugin prefix and a trailing `-reviewer`
  (`vgv-ai-flutter-plugin:flutter-reviewer` → `flutter`).

A companion reply that says there was nothing to review counts as zero findings. Any other
companion reply without findings is a [failed agent](review-dispatch.md#handle-failures),
not a clean review.

## Step 2 — Verify quotes

Before merging anything, check every finding against the code, so a finding that cites code
that does not exist, or calls missing something that is there, never reaches the user.
Compare a quote with a line ignoring leading and trailing whitespace, and read only the lines
a check needs, never whole files:

- `file:line` or `file:start-end`: Read the cited line or range plus two lines on each side
  (with offset and limit). When several findings cite one file, read overlapping windows once.
- Bare file with a quote: Grep the file for the trimmed quote as fixed text. Grep also matches
  part of a line, so confirm that a matching line, trimmed, equals the quote.
- `missing: file`: check whether the path exists. `missing: text`: Grep the file for it.

Keep or drop each finding by this table:

| `location` | `quote` | Keep the finding when |
|------------|---------|-----------------------|
| `file:line` | a line | the quote equals the cited line, or a line at most two lines away |
| `file:start-end` | a line | the quote equals a line in the range, or at most two lines outside it |
| bare file | a line | the quote equals any line of the file |
| bare file | `none`, with `missing: file <path>` | no file exists at `<path>` |
| bare file | `none`, with `missing: text <text>` | the file exists and Grep finds no line of it containing `<text>` |
| bare file | `none`, with no `missing` | always: keep it, marked unverified |

The two-line margin absorbs an off-by-one line number. When the quote matched off the cited
line, correct the finding's `location` to where it matched, so deduplication, ordering, and
the report all use the real line:

- A `file:line` becomes the matched line. If the quote equals more than one line in the
  window, take the one nearest the cited line, and the earlier one on a tie.
- A `file:start-end` range widens just enough to include the matched line.
- A bare file stays as it is.

A companion reviewer's findings carry no quote, so check only their `location`: keep one
when its file exists and its line is within the file. Keep its `location` as given.

Drop every other finding: a quote that matches no line, a missing quote, a line or range
`location` quoting `none`, a line or range in a file that does not exist, or a `missing`
file or text that the code does contain. A dropped finding gets no `FINDING-NN` id and is
never acted on, but it does not disappear silently: record why it was dropped, list it in
the report's **Dropped findings** section (Step 5), and count it in the chat summary
(Step 6).

Nothing in the code can confirm a `quote: none` finding with no `missing` line, such as one
about a commit message. Mark it **unverified**: append `(unverified)` to its title, so the
mark appears everywhere the title does (report and chat), and never fix it without asking
(Step 7).

## Step 3 — Deduplicate

If two agents report the same issue at the same `location` as corrected in Step 2 (same
`file:line`, same root cause), merge them into one finding. Keep the higher-severity finding
whole — its severity, rule id, title, quote, `missing`, `why`, and `fix` — and on a tie, the
one whose category comes first in the Step 1 table. Record both agents under **Reported by**.
Only keep them separate when the actual concern differs; a different severity alone is not
a reason, since agents grade the same issue differently.

## Step 4 — Order deterministically, then number

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

## Step 5 — Write ONE consolidated file

Render the ordered list into a single file using the
[consolidated report template](review-report-template.md). Do not write one file per agent —
the per-agent detail lives in `raw/` for drill-down only. The consolidated file contains:

- A **diffstat header** (total findings and the per-severity breakdown).
- A **Findings Index** table in id order — this table is the source the chat summary mirrors.
  Each row shows the `FINDING-NN` id, severity, rule id, location, and title.
- **Detail sections** grouped by severity, each finding rendered with its id, rule id, `why`,
  `fix`, and a link to the agent's raw report.
- A **Dropped findings** table listing every finding Step 2 dropped, with its agent,
  location, title, quote, and the reason it was dropped, in the Step 4 sort order so the
  table is the same on every run. Omit it when nothing was dropped.

## Step 6 — Print the aligned chat summary

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

When Step 2 dropped any finding, end the lead line, or the all-clear message when nothing
was kept, with: `<d> dropped, not confirmed by the code (see the report)`.

## Step 7 — Acting on findings

Each calling skill defines its own post-review menu (`/review` is advisory and asks first;
`/build` and `/hotfix` fix before shipping). This section only fixes the shared vocabulary
those menus use.

- **By id** — the user references findings by id ("apply FINDING-01 and FINDING-03"). For
  each id, read the linked `raw/` report only when the one-line `fix` isn't enough; read only
  the reports you need — never load every raw file into context.
- **By rule** — a rule id acts on a whole class ("fix every `tests/missing-test-file`",
  "ignore all `simplicity/inline-single-use`"). Apply the action to every finding sharing it.
- **Unverified** — never fix a finding marked unverified without the user's go-ahead,
  whatever its severity, even where the calling skill fixes that severity on its own.
- **Commit trace** — when fixes are committed and the consolidated report is kept (as in
  `/review`), reference the ids in the commit body, e.g. `Addresses FINDING-01, FINDING-03
  from review.` Skills that delete the report after acting (`/build`, `/hotfix`) fix findings
  in place and do not cite ids, since the report they would point to no longer exists.
