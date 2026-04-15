# Review Consolidation

## Categorize findings

Consolidate findings from all agent summaries into three categories:

- **Critical** (must fix before merge): Bugs, missing tests, layer violations, broken analysis
- **Important** (should fix): Convention deviations, test gaps, naming issues
- **Suggestions** (note for PR): Style improvements, minor simplifications

## Fix and triage

1. **Auto-fix minor issues**: formatting (run the project's formatter), lint warnings. Stage and commit fixes.

2. **Fix critical issues**: Read the specific report file for full details on each critical finding. Address each one, re-run validation (project's linter and test runner), and commit. Only read reports that contain critical issues — do not load all reports into context.

3. **Present important issues** to the user via **AskUserQuestion**:
   - **Fix all**: address every important issue (read relevant report files for details)
   - **Review the list first**: show the full list for the user to decide
   - **Skip to shipping**: note them in the PR description instead

4. **Record suggestions** for inclusion in the PR description.
