# Consolidated Review Report Template

The caller writes exactly one file per review run using this structure. Findings appear in
`FINDING-NN` id order (assigned by the [consolidation procedure](review-consolidation.md)).
The **Findings Index** is the single source of truth: the chat summary reprints its Critical
and Important rows verbatim (same ids, order, titles) and collapses Suggestions to a count.

````markdown
# Code Review — <scope: branch name, or "working tree", or the reviewed paths>

<N> findings · 🔴 <critical> critical · 🟡 <important> important · 🔵 <suggestions> suggestions
Across <F> files. Agents: <list of agents that ran>.<note any agent that failed><if any were dropped: " <d> dropped, not confirmed by the code.">

## Findings Index

| ID | Severity | Rule | Location | Finding |
|----|----------|------|----------|---------|
| FINDING-01 | 🔴 Critical | `tests/missing-test-file` | `lib/auth/auth_cubit.dart` | AuthCubit has no test file |
| FINDING-02 | 🔴 Critical | `architecture/layer-violation` | `lib/ui/home.dart:12` | Presentation imports data client directly |
| FINDING-03 | 🟡 Important | `vgv/force-unwrap` | `lib/auth/token.dart:20` | Force-unwrap on a nullable token |
| FINDING-04 | 🔵 Suggestion | `simplicity/inline-single-use` | `lib/utils/format.dart:20` | Inline single-use helper |

## Critical

### FINDING-01 · `tests/missing-test-file` · `lib/auth/auth_cubit.dart`
AuthCubit has no test file.
- **Why**: Untested state management ships behavior changes silently.
- **Fix**: Add a bloc/cubit test covering the success, failure, and edge states.
- **Reported by**: test-quality-review-agent · [details](raw/test-quality-review.md)

### FINDING-02 · `architecture/layer-violation` · `lib/ui/home.dart:12`
Presentation imports data client directly.
- **Why**: Breaks layer separation; UI now depends on the data layer's implementation.
- **Fix**: Route the call through the repository injected into the cubit.
- **Reported by**: architecture-review-agent · [details](raw/architecture-review.md)

## Important

### FINDING-03 · `vgv/force-unwrap` · `lib/auth/token.dart:20`
Force-unwrap on a nullable token.
- **Why**: Crashes at runtime when the token is null instead of failing gracefully.
- **Fix**: Guard with an early return (or null-aware access) before use.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

## Suggestions

### FINDING-04 · `simplicity/inline-single-use` · `lib/utils/format.dart:20`
Inline single-use helper.
- **Why**: The wrapper adds a hop without adding meaning.
- **Fix**: Inline the single call site and delete the helper.
- **Reported by**: code-simplicity-review-agent · [details](raw/code-simplicity-review.md)

## Dropped findings

The code did not confirm them, so they were not numbered or acted on.

| Agent | Location | Finding | Quote | Reason |
|-------|----------|---------|-------|--------|
| vgv-review-agent | `lib/auth/session.dart:42` | Deduplicate the cached token list | `final tokens = <String>[];` | Matches no line in the file |
| test-quality-review-agent | `lib/auth/auth_repository.dart` | AuthRepository has no test file | none | `test/auth/auth_repository_test.dart` exists |

## Why this matters

<One or two sentences framing the findings as a set: what shipping them unaddressed costs,
and what the biggest lever is. Keep it constructive, not a scold.>
````

## Rules

- **One file.** Never split findings across files. Per-agent raw reports live under `raw/`
  and are linked, not inlined.
- **Index order == detail order.** Both follow the `FINDING-NN` sequence. The chat summary
  reprints the same rows in the same order but shows only Critical and Important (Suggestions
  collapse to a count).
- **Every finding carries a concrete `Fix`.** A finding with no actionable fix is noise.
- Omit a severity section entirely if it has no findings (don't print an empty "Critical").
  Omit **Dropped findings** the same way when nothing was dropped.
- **Dropped findings are never numbered.** They sit outside the `FINDING-NN` sequence, so
  they appear in neither the Findings Index nor the chat summary's bullets. Escape any `|`
  in a quote as `\|` so it does not break the table row.
- **Unverified findings keep the mark in their title.** A finding the code could not confirm
  ends its title with `(unverified)` in the Findings Index, its detail section, and the chat
  bullet, so the user sees it before anything acts on it.
- If **no findings at all**, write a short file: the header line with all-zero counts and a
  single line — "No findings. Code looks good." — and say the same in chat. If findings were
  dropped, still list them under **Dropped findings** and give their count in chat.
