# Skill Evals

Does Claude route to the skill, and does the output follow it? Cases run through
[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals) against real models.

```bash
E="claude plugin eval . --scaffold --allow-tools Write"
$E                                                    # every case, both arms
$E --tag plan                                         # one skill
$E --ablation none                                    # with-plugin arm only, half the cost
```

`--allow-tools Write` is as load-bearing as `--scaffold`. Without it the four cases that grade
a written document score 0 with no failing content grader, and the runner warns
`case … cannot pass with the granted tools`.

- Claude Code **>= 2.1.269**.
- No API key locally. Runs authenticate the same way your normal session does.
- `--scaffold` is **not optional**. Without it the fixture never runs and cases fail for
  unrelated reasons.

---

## The two arms

| Arm     | What it is              | Measures                     |
| ------- | ----------------------- | ---------------------------- |
| with    | The plugin loaded       | What the plugin produces     |
| without | No plugin loaded at all | What the bare model produces |

`Δ` is the with-arm score minus the without-arm score. A grader that passes in both arms is
measuring the model, not the skill.

Each run gets a throwaway home directory, workspace, and Claude Code configuration, and the
eval directory is unreadable from inside a run.

Exclude negative controls when you compare arms. A model with no plugin passes a "must not
invoke the skill" check for free.

---

## What these cases can reach

Wingspan's skills drive git, write documents and dispatch agents. An eval run grants none of
that:

- **`Write` only, and only where a case asks for it.** A case grants a gated tool twice over:
  the operator passes `--allow-tools Write` (CI does, and so must you), and the case lists
  `Write` in its own `allowed_tools`. Four cases do, because their subject is the document the
  skill writes; every other case is graded on the **reply** alone. `Bash` and `Edit` are
  granted nowhere, so no case runs git, a test suite, or a CLI.
- **No MCP tools.** A plugin server without a directory under `mocks/` is not started, and
  `context7` has none. Every run reports that on a `mocked:` line.
- **Prompts carry their own context.** A plan, a diff, an incident report or a draft the case
  is about is pasted into the prompt and named as authoritative, because the model cannot go
  and read one.

**Routing is the suite's loudest signal, and it is noisy.** In a measured two-arm run of all
47 cases, 10 cases scored 0 on `skill-fired`; in the next run of the same suite it was 10
different ones. Four cases that scored 1.00 one run missed routing entirely the next. Read a
red routing result as a hypothesis, confirm it with `--runs 3`, and treat a case that misses
across three runs as a finding about the skill rather than a case to reword — three separate
rewording passes over the `/review` cases never made that skill fire reliably when the user
pastes the whole file into the prompt.

**Do not write a prompt that tells the model not to edit anything.** "Don't change any files,
just describe what you would do" reads like the obvious way to fit the no-Write sandbox, and
it kills routing outright: 5 of 5 cases rewritten that way dropped to `Skill called 0x`. Leave
the task a task, and mention the environment as a fact if you must — "put the write-up in your
reply, I have no repo access to give you right now" keeps the skill firing.

**A skill that speaks through a file it writes needs `Write` and a `files` target.** Grade the
document, not the summary the skill prints after it: give the case `Write` in `allowed_tools`,
run with `--allow-tools Write`, and set `target: files` on the regex graders (`focus: files` on
an `llm` one). `files` matches across everything the run wrote, so a grader never has to guess
the filename the skill picked. A case that still grades the reply for template wording is
measuring the summary, and the summary is not where the template lives.

Two skills have no cases. `create-pr` and `rebase` both set
`disable-model-invocation: true`, and the Skill tool refuses those unless the user typed the
command that turn — `Skill <name> cannot be used with the Skill tool due to
disable-model-invocation`. No prompt can route to them, so there is nothing to measure.

---

## Writing a case

A case is a directory. Nothing registers it; it is found by being there.

```text
evals/<skill>/<case-name>/
├── prompt.md          # frontmatter: run limits; body: the prompt
├── case.yaml          # schema_version, name, and the fixture hook
├── fixture.sh         # symlink to ../../_fixture/fixture.sh — never a real file
└── graders/
    ├── skill-fired.md
    └── <one file per grader>
```

`prompt.md`:

```markdown
---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan]
description: That a feature spanning four layers is split into phases rather than planned as one pass.
---

Here is the brainstorm we settled on: ...

Turn it into an implementation plan.
```

Every case repeats that frontmatter verbatim; there is no shared-defaults mechanism. The
directory name under `evals/` is the tag, and the tag is what CI scopes a run by, so
`tags:` must name the skill's own directory.

`case.yaml`:

```yaml
schema_version: "1.1"
name: plan-splits-a-multi-layer-feature-into-phases
context:
  scaffold_script: fixture.sh
```

A grader, `graders/numbers-the-phases.md`:

```markdown
---
type: regex
pattern: 'Phase 1'
---
```

A case passes at `--threshold 0.8`, averaged across its graders and weighted. The default
threshold is `1.0`, so **pass `--threshold 0.8` or every imperfect case exits 1**.

### Grader reference

| `type`        | Options                               | Notes                                                                    |
| ------------- | ------------------------------------- | ------------------------------------------------------------------------ |
| `tool_used`   | `tool`, `input_match`, `min`, `max`   | Routing. The defaults are wrong for this suite, see below                |
| `regex`       | `pattern`, `flags`, `match`, `target` | `match: not_contains` for absence. Case-insensitivity goes in `flags: i` |
| `tool_order`  | `before`, `after`                     | `before` runs first, `after` second                                      |
| `file_exists` | `path`, `exists`                      | Unused here: no case may write a file                                    |
| `llm`         | `criteria`, `focus`                   | Frontmatter is just `type: llm`; the file body is the rubric             |
| `baseline`    | `baseline_file`, `criteria`           | Unused here                                                              |

There are **no custom-code graders**.

A grader reads `last_message` unless its `target` says otherwise. The other targets are
`trace`, `files`, `{ source: file, path: <path> }`, and `mock_calls`.

### Routing graders

Every case carries one:

```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?plan"'
weight: 3
arm: both
---
```

**`arm: both` is mandatory.** Without it a two-arm run drops every `tool_used: Skill`
grader from the score, so a case whose skill never fires still scores `1.00`. It also
penalizes the without-arm, which inflates `Δ`, so read the two arm scores rather than `Δ`.

**`weight: 3` is mandatory** and nothing applies it for you. It sinks a case on a routing
miss alone. It does not protect the content graders: against `n` content graders of weight
1, a single content miss scores `(n + 2) / (n + 3)`, which clears 0.8 for every `n >= 2`.
When one grader carries a case's whole point, weight that grader too.

The `(?:[\w-]+:)?` prefix matches the plugin-namespaced `vgv-wingspan:plan` form as well as
the bare one. Keep it.

Negative controls use the same grader with `min: 0` and `max: 0`.

### Traps that have each cost a false result

- **Rubrics are graded blind.** The judge sees the response and the criterion, not the
  prompt. Grade task success with a `regex`.
- **Only ask for what the prompt supplied.** A rubric wanting detail the prompt never gave
  can never pass.
- **A workflow skill answers with a question.** `brainstorm`, `plan` and `build` are
  supposed to stop and ask. A rubric that demands a finished artifact from a skill whose
  first step is a clarifying question fails the correct behavior. Grade the question.
- **The fixture must stay neutral.** It cannot be empty, or the model asks for code instead
  of writing it. It cannot name what a skill teaches either — no `docs/plan/`, no PR
  template, no conventional-commit history — or the no-plugin arm infers the conventions the
  case exists to measure.
- **Prompts must be self-contained.** Paste in the plan, diff or draft a prompt refers to,
  and name pasted text as authoritative when it describes state not on disk.
- **Check both arms answered.** A no-plugin arm that asks a clarifying question instead of
  doing the work makes every grader look discriminating. That is a prompt that is not
  self-contained, not a result.
- **A FAIL clause can punish a better answer than the PASS clause asked for.** Write the
  FAIL clause for the wrong answer, not for any departure from the shortest right one.
- **`PASS%` in the results table is runs scoring exactly 1.00**, not runs clearing
  `--threshold`. A case at 0.90 shows `33%` while passing the threshold on every run. Read
  `SCORE` against the threshold; read `PASS%` only when hunting flaky graders.
- **Judges are not stable.** A case with several `llm` graders will fail something most runs
  whatever the skill did. When a judge fails a reply that plainly satisfies its rubric,
  convert the check to a `regex` on the skill's vocabulary rather than rewording the rubric.

Beyond that: write prompts as a user would send them, name no skill in a prompt, grade
mechanically where you can, include the cases where the skill must say no, and keep a
negative control's rubric to the absence of the skill's vocabulary.

### Graders that cannot fail

A grader that passes in the no-plugin arm measures the model, not the skill. Find them by
running the case two-arm and comparing the two `graders` lists.

**One two-arm run cannot disqualify a grader.** Use `--runs 3` on both arms, and prefer
reasons that do not depend on a score at all.

**Adding beats deleting.** A free grader still fails if the skill later regresses, so it is
a regression test even when it earns no Δ. Keep every free grader that pins a convention or
an anti-pattern. Delete only for a reason that holds without a score:

1. **A genuine duplicate** of a grader beside it.
2. **It restates the prompt.** A pattern matching a phrase the prompt supplied passes
   whenever the model read the question.
3. **It is table stakes for the format**, such as a heading in a document the prompt asked
   for.

Everything else gets added to. Read both arms' output side by side, find what only the
plugin produced, grade that, and weight it so the case turns on it.

If nothing discriminates even then, the skill may teach nothing the model does not already
do, and the fix is the skill rather than the case.

### Writing an `llm` rubric

Frontmatter is only `type: llm`. The body is the rubric, as concrete PASS and FAIL
conditions with an example of each:

```markdown
---
type: llm
---

PASS if the response asks the user at least one clarifying question about scope or intent
before proposing an approach, for example which of two flows the feature must support.

FAIL if it goes straight to an implementation proposal.
```

Match the skill's own vocabulary. Keep `llm` graders for short output; for anything long a
`regex` reads the whole thing the same way every time.

---

## The fixture

Every run starts in an empty workspace. `_fixture/fixture.sh` recreates the neutral project
skeleton, hooked up through `context.scaffold_script`, and runs **only with `--scaffold`**.

It writes `package.json`, `src/counter.js` and `test/counter.test.js`. The source exists so
a run opens in a real project rather than an empty directory, and it is deliberately the
most boring code that satisfies that: one class with one method, and one test with one
assertion. Nothing there is a Wingspan convention, because everything there is visible to
the no-plugin arm of every case.

`context.scaffold_script` will not take a path that leaves the case directory, but it does
resolve a symlink inside it, so each case's `fixture.sh` is a symlink to the one script. A
new case needs its own:

```bash
ln -s ../../_fixture/fixture.sh evals/<skill>/<case>/fixture.sh
```

CI fails the `plugin-validate` job on a `fixture.sh` that is a real file, points elsewhere,
or dangles.

**On Windows**, a checkout without `core.symlinks=true` turns each link into a text file
and runs fail at scaffold time. CI runs on Linux and is unaffected.

---

## Running

```bash
E="claude plugin eval . --scaffold --allow-tools Write"
$E                                             # every case, both arms
$E --tag plan --tag build                      # two skills
$E --case plan-splits-a-multi-layer-feature-into-phases
$E --ablation none                             # with-plugin arm only, half the cost
$E --runs 3 --threshold 0.8                    # is a red case real?
```

Read the two arm scores, not the total. The without-arm is supposed to score badly.

**One run is not a measurement**, and these are not a merge gate.

- `--runs 3` before believing a red case.
- A case that hit its turn cap or timed out scores 0 with **no failing grader**, which
  reads exactly like a content failure. Check the `NOTES` column, or
  `cases[].arms.with[].error` in the JSON.
- A usage limit hit mid-suite makes every later run fail the same way without marking the
  document `partial`. Check the errors.
- The suite judges with `claude-sonnet-5`. When a case routes but scores badly, read the
  judge's votes in the report before editing the skill.
- **The no-plugin arm swings between runs.** One two-arm run cannot disqualify a grader.

Every run writes `results/<timestamp>/` with `aggregate-result.json` and a self-contained
`report.html`, which is where you find out *why* a run scored low. `results/` is gitignored.

---

## Running in CI

`.github/workflows/evals.yaml` runs after a merge to `main`, never on a pull request,
scoped by `--tag` to the changed skills, with-plugin arm only, and `continue-on-error`.

- Changing `_fixture/`, `skills/shared/` or `agents/` widens the scope to every skill.
- A directory under `evals/` only becomes a `--tag` if it holds `*/case.yaml`. `results/`
  sits there without being a skill.
- The scope job's `find` uses `-exec dirname {} \;` rather than `-printf '%h\n'`, which is
  GNU-only and fails on macOS.
- CI needs `ANTHROPIC_API_KEY`, having no Claude Code session, and `--trust-plugin`.
- `--ablation none` and `--ablation with-without` weight the baseline differently. Compare
  runs from one mode at a time.
- The job has a one-hour ceiling.

---

## What this does not cover

- **Anything downstream of a tool call.** No `Bash` means no git state, no `gh`, and no
  dispatched review agent actually running. A case measures what the skill says it will do,
  except for the written document, which four cases read back with a `files` target.
- **`create-pr` and `rebase`.** `disable-model-invocation: true` puts them out of reach of
  any prompt.
- **Judge calibration.** Most content graders are `llm` with no human-labelled gold set.
- **Stable routing.** Whether a skill activates is nondeterministic, which is why routing is
  a `tool_used` grader rather than inferred from content.
- **Prose in a `SKILL.md`.** Deliberate: asserting `contains` patterns against skill bodies
  fails the gate on a copy-edit.
- **The skills' own surfaces.** `skills_lint` catches a link to a missing file and a `name`
  that does not match its directory. Nothing catches a link resolving to the *wrong* file,
  or an `allowed-tools` name that does not exist.
