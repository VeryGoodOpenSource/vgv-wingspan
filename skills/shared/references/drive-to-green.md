# Drive to Green

The authoritative ship gate for `/build` and `/hotfix`. Loop until every gate is green by real output, then prove it with one authoritative command. Delegate the loop to a companion verification skill when the project has one installed; otherwise run the loop generically. Escalate only when a criterion is un-runnable or self-contradictory — never on an ordinary, fixable failure.

## Inputs

The calling skill supplies two things:

- **Gate set** — the commands that must each exit 0.
  - `/build`: the non-manual `verify:` commands from the plan's `success-criteria` block.
  - `/hotfix`: the project's detected formatter, linter, and test runner (no plan, so no `verify:` commands).
- **Authoritative command** — the single command that proves the whole gate set is green.
  - `/build`: the plan's `VERIFICATION COMMAND`.
  - `/hotfix`: the detected suite run once.

The driver that follows is a best-effort accelerator to reach green. The **authoritative command is the source of truth** — it runs unconditionally after the driver, so a driver that stops while still red is caught here rather than shipped.

## Step 1 — Select the driver

Read the plugin's `hooks/recommendations/*.json`. A file participates only if it carries a `verificationSkill` field. For each such file, evaluate its `detect` rule against the current project — the same file/glob + case-insensitive regex OR-logic the `recommend-plugins.sh` hook applies (it greps with `-iE`).

| Condition | Action |
| --------- | ------ |
| `detect` matches **and** the named skill is available | **Delegate** — invoke the skill named in that file's `verificationSkill` field to drive the package to green. |
| `detect` matches but the skill is **not** installed | Surface its install recommendation once, then use the **generic loop**. |
| No `detect` matches | Use the **generic loop**. |

If more than one file matches, first match wins. Prefer the project's MCP analyzer and test tools over shell commands when they are available.

`verificationSkill` values use Claude Code's `plugin-name:skill-name` form. On hosts that list plugin skills under bare names (GitHub Copilot CLI), match the part after the `:`.

## Step 2 — Drive to green

- **Delegated** — invoke the companion skill and let it run its own verify-fix-rerun loop. Do not wrap it in a second loop of your own.
- **Generic** — run each gate-set command. On a non-zero exit, fix the root cause and re-run that command. Repeat until it exits 0. Fix objective failures (red tests, lint errors, coverage gaps) autonomously — do not re-prompt the user for them.

## Step 3 — Authoritative gate

Run the authoritative command **once**, after the driver, regardless of which driver ran.

- Exit 0 → the gate is green. Proceed to manual criteria (Step 5).
- Non-zero → re-enter Step 2, fixing against **this command's** actual output. The authoritative command wins any disagreement with an individual gate-set command.

## Step 4 — Escalation

Objective, fixable failures are never escalated — fix and re-run. Stop and ask the user with **AskUserQuestion** only when:

| Trigger | Detection |
| ------- | --------- |
| **Un-runnable** | `command not found` / exit 127 / a missing tool, dependency, or codegen step / infrastructure failure |
| **No progress** | The failure fingerprint is identical to the prior round, or the failure count did not decrease |
| **Oscillation** | Two gates trade green and red across consecutive rounds |
| **Ceiling reached** | Total Step 2 to Step 3 re-entries reach 5 with gates still red |
| **Criteria disagree with the gate** | Every gate-set command passes but the authoritative command stays red across rounds — the plan is internally inconsistent |

A failure **fingerprint** is the sorted set of `failing command + error signature` for the round; without it, "no progress" is undecidable. Exactly one driver owns escalation per run: if a delegated skill escalates, surface its reason and stop — do not re-invoke it.

When escalating, report the failing command, its output, the rounds attempted, and the specific decision the user must make.

## Step 5 — Manual criteria (`/build` only)

`verify: manual <steps>` criteria cannot be auto-run. Once the authoritative gate is green, present them with **AskUserQuestion** as a checklist and ship only on explicit confirmation. Record the confirmation in the PR body so it is auditable. A plan with only manual criteria skips Steps 2 and 3 and goes straight here — never treat an empty runnable set as green.
