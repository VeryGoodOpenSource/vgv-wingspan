# Review Agent Instructions

These instructions are passed to every quality-review agent. Substitute `<RAW_DIR>` with the
absolute raw-reports directory the calling skill provides (each skill gives its own, e.g.
`docs/reviews/raw`) and `<name>` with the bare report stem from that skill's table (e.g.
`vgv-review`) — no directory, no `.md` extension.

Each review agent also carries the findings block in its own `## Output Instructions`, so it
returns the block even when dispatched directly as an agent type, with no calling skill. This
file holds the rules behind that block; when you change the block here, change it in each
review agent too. `agents/test_review_contract.sh` fails CI when the copies drift.

## Reading scope

The finding scope you were given lists the changed files. It bounds what you may report on.
It does not bound what you may read. A review that reads only the changed lines misses the
defects that live at the seam between them and the code they call.

Before reporting, read:

1. **The concrete implementation behind every interface the change calls.** Caching,
   replay-on-subscribe, deduplication, and retry behavior are invisible from an interface and
   routinely invalidate a caller that looks correct in the diff.
2. **The nearest existing analogue.** New use cases, modules, and components usually have a
   sibling solving the same problem. Differences from it are either deliberate, and belong in
   the PR description, or accidental.
3. **The source of truth for any claim the change makes**, including a comment asserting what
   another system does.

When a finding depends on behavior defined outside the changed files, cite that file and line
in `why`.

Each agent produces two outputs:

1. **A detailed report on disk** (for deep reference), and
2. **A structured findings list returned to the caller** (the single source the caller
   uses to number, consolidate, and render both the file and the chat summary).

## 1 — Write the detailed report

Write your full report to `<RAW_DIR>/<name>.md` (create the directory if needed) — e.g. with
`<name>` = `vgv-review`, you write `<RAW_DIR>/vgv-review.md`. This is an absolute path — use
it exactly as given, do not convert to relative. Use your normal Output Format. The caller reads this file
only when acting on a finding needs more than the one-line `fix`, so be thorough but keep it
scannable.

Dispatched without a raw report path, write no file: return the findings block, drop
its **Report** line entirely (do not write it as `none`), and put the full report after the
block instead.

## 2 — Return a structured findings list

Return ONLY the block below to the caller. Do **not** return the full report text.

One list item per finding. Order your own findings by severity (Critical, then
Important, then Suggestion). Keep `title`, `why`, and `fix` to a single line each so
the caller can render them verbatim without re-reading the report.

```markdown
## <Agent Name> Findings
**Verdict**: <pass|fail> | **Critical**: <count> | **Important**: <count> | **Suggestion**: <count>
**Report**: `<RAW_DIR>/<name>.md`

- severity: Critical
  rule: <short kebab-case slug for the check that fired, e.g. "missing-disposal">
  title: <short imperative title, e.g. "Dispose the stream subscription">
  location: <file:line, file:start-end, or just the file path when the finding spans it>
  quote: <the offending line, copied verbatim from the file at location>
  missing: <only with "quote: none" — "file <path>" or "text <text>">
  why: <one line — the concrete impact>
  fix: <one line — the concrete action to take>
- severity: Important
  rule: ...
  title: ...
  location: ...
  quote: ...
  why: ...
  fix: ...
```

The verdict line always comes right after the heading, so a caller can tell a finished
review from a missing or empty reply. The verdict is `fail` when the list has at least one
Critical finding, and `pass` otherwise.

If you found nothing, return the heading and the verdict line with every count at `0`, the
verdict `pass`, and no list items.

### Severity

Every finding uses one of three severities. Map your own vocabulary (errors/warnings,
violations, pass/fail, etc.) onto these — the caller sorts and numbers by them, so consistent
grading keeps the ids stable:

- **Critical** — must fix before merge: bugs, crashes, security issues, missing tests for a
  new unit, layer/dependency violations, or a broken build/analysis.
- **Important** — should fix: convention deviations, test gaps, naming problems, avoidable
  performance costs.
- **Suggestion** — nice to have: style, minor simplification, documentation.

### Rules

- **Every finding must have a `location`** — `file:line`, or the bare `file` path when the
  finding spans it. Never omit it: the caller deduplicates and sorts by location, so a
  location-less finding breaks stable numbering.
- **When a finding depends on behavior defined outside the changed files**, keep `location`
  and `quote` on the changed line the fix edits, and name the `file:line` that defines that
  behavior in `why`. The finding then shows both where to fix and why the line is wrong.
- **Every finding must have a `quote`** — the offending line copied verbatim from the file
  at `location`: the whole line, never shortened, paraphrased, or joined with another line.
  For a `file:start-end` range, quote one line inside it. With a bare file `location`, quote
  the line that best identifies what the finding is about, such as the class declaration.
- **Use `quote: none` only for what the code does not contain**, and only with a bare file
  `location`. Follow it with a `missing` line that names what is missing, so the caller can
  confirm it:
  - `missing: file <path>` — a file that should exist and does not, such as a test file.
    Keep `location` at the file the finding is about, such as the untested source file.
  - `missing: text <text>` — text the file at `location` should contain and does not: an
    entry, a call, or a line the change removed. Copy it exactly, on one line, specific enough
    not to match unrelated code (`_subscription.cancel();`, not `cancel`).
  - Leave `missing` out only when no file can show the problem, such as a commit message
    (locate it at a file the commit changed). The caller keeps such a finding but marks it
    unverified and asks before acting on it.
- **The caller checks every finding against the code** — the `quote`, or what `missing`
  names — and drops the findings the code does not confirm.
- **`rule` names the check, not the instance.** Use a short, reusable kebab-case slug
  (`missing-null-check`, `swallowed-error`, `layer-violation`) — reuse the same slug
  every time the same check fires so the caller can namespace it and let users suppress a
  whole class. Do not put a file path or line in the rule.
- **Titles are the finding's identity.** Write a distinct, specific title per finding —
  the caller uses it verbatim in both the file and the chat summary.
- **No IDs.** The caller assigns the stable `FINDING-NN` id after collecting every
  agent's list. Do not invent your own ids.
- **`why` and `fix` are mandatory and one line each.** A finding with no fix is noise.
- **Skip what is already gated.** When the caller passes an **Already gated** note, do not
  report findings its checks cover: a formatter or analyzer it lists has passed or runs before push, and
  under a squash-only merge strategy commit messages and commit splits do not matter. Report
  everything else as usual.
- **Write to the [writing rules](elements-of-style.md).** The caller pastes them below these
  instructions. Apply them to the detailed report and to every `title`, `why`, and `fix`.
- Do not apply fixes. You review and report; the caller decides what to act on.
