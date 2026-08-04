# Skill Evals

One question: does Claude route to the skill, and does the output follow it?

```bash
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

Cases live in `evals/tests/*.yaml` and run through
[promptfoo](https://www.promptfoo.dev). They call real models, so they take minutes and
consume usage. Nothing here runs in CI. Run them locally before a PR that changes a
skill.

This file is the single source of truth. `README.md`, `CLAUDE.md` and `CONTRIBUTING.md`
carry a few lines and a link here, so eval documentation belongs in this file rather
than spread across them.

It is long because most of it is measured findings that cost a run each to learn. Start with
whichever of these you came for:

| You want to | Read |
| ----------- | ---- |
| Run the suite and read the result | [How it works](#how-it-works), then [Running the suite](#running-the-suite) |
| Write a case | [Case format](#case-format), [Assertions](#assertions), [Adding a case](#adding-a-case) |
| Know what the numbers mean | [The measured baseline](#the-measured-baseline) |
| Understand a red case before editing it | [What is still red](#what-is-still-red), then [Guarding against test-fitting](#guarding-against-test-fitting) |
| Know what this does **not** prove | [What these evals do not cover](#what-these-evals-do-not-cover) |

Three things account for most wasted time here, so they are worth knowing up front:

1. **The sealed column is supposed to fail.** promptfoo's total will look terrible. Read the
   per-column split.
2. **A red case is usually routing, not content.** Check whether the skill fired at all before
   editing an assertion.
3. **Prompts must close the questions the skill would ask.** These skills are conversational;
   a naturally phrased prompt returns question one of a dialogue that never continues.

---

## How it works

promptfoo drives these through its
[Claude Agent SDK provider](https://www.promptfoo.dev/docs/providers/claude-agent-sdk),
which loads this repo as a local plugin and reports which skills the model actually
invoked. Everything lives in `evals/promptfooconfig.yaml` plus one YAML file of cases
per skill under `evals/tests/`.

**No API key.** Both the agent under test and the `llm-rubric` judge run through the
Claude Agent SDK, which authenticates with your local Claude Code session, so the whole
suite runs on a subscription. The judge is pinned to the same provider in
`defaultTest.options`; left unpinned, promptfoo picks a grader from whatever key happens
to be in the environment, which is neither free nor deterministic.

Two prerequisites:

```bash
npm install --no-save @anthropic-ai/claude-agent-sdk   # from the repo root
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

- **The SDK must live in `node_modules` next to where you run promptfoo.** A `-g`
  install does not work and neither does `NODE_PATH` — promptfoo resolves the SDK from
  the working directory. `--no-save` keeps `package.json` and a lockfile out of this
  repo; `node_modules/` is already gitignored.
- **A second `npm install --no-save` replaces the first.** With no `package.json` to record
  what is installed, adding any other package that way removes the SDK, and the next run
  reports 100% *errors* rather than failures — `could not be resolved from ...`. If you need
  a scratch package alongside it, name both in one `npm install --no-save` command, or just
  reinstall the SDK afterwards.
- **Node `^20.20.0 || >=22.22.0`**, enforced by promptfoo, which refuses to start below
  it. Nothing in this repo pins a Node version, so this is a prerequisite you supply.

Behavior differs across promptfoo releases, so a suite that ran yesterday can break on
an upgrade with no change here. If a run dies before any case executes, or the two
columns stop differing, pin to the last version you saw work and reconcile the config
against the provider docs before editing a case.

### The two columns are the ablation

Every case runs against both providers:

| Provider | Config | Measures |
| -------- | ------ | -------- |
| `with-skill` | `plugins` points at this repo, `skills: all`, read tools | What the plugin produces |
| `sealed-baseline` | no `plugins`, `tools: []` | What the bare model produces |

### Sealing the baseline takes three keys

None of them is the provider's default, and two are counter-intuitive enough to leak
silently:

| Key | Why |
| --- | --- |
| `tools: []` | `working_dir` is inside the checkout, so a baseline with read tools walks up to `../../skills` and reads `SKILL.md`, then passes rubrics on the answers. This emits `--tools ""`, removing all built-ins |
| `setting_sources: []` | **Omitting the key loads everything**, including this repo's `CLAUDE.md`, which names every skill, every output directory under `docs/`, and every review agent. No tool call is involved, so no assertion can catch it |
| `strict_mcp_config: true` | Without it, `--tools ""` still leaves every `mcp__*` tool in place |

Do not reach for `custom_allowed_tools` or `append_allowed_tools` to restrict a column.
Those map to the SDK's `allowedTools`, which is an auto-approve list, not an availability
list — the SDK's own docs say to use `tools` for that, and an empty array is dropped
entirely, silently restoring the full default tool set.

Both columns carry `setting_sources: []`. If only one does, the ablation compares
contexts rather than the plugin. Plugins load through `--plugin-dir`, so `skills: all`
still works with settings disabled.

**A grader that passes in both columns is measuring the model, not the skill.** That is
the number to read. Use `npx promptfoo@latest view` for the side-by-side.

### The plugin column's tools are chosen, not inherited

`tools: ['Skill', 'Read', 'Glob', 'Grep']`. Read, Glob and Grep are there because every
workflow skill delegates to `references/*.md` and has to be able to open them — `/plan`
alone reads a template, `success-criteria.md` and `plan-review.md`. Three absences are
deliberate:

- **No `AskUserQuestion`.** Wingspan skills ask the user constantly. With the tool
  available the question goes into a tool call the response body never shows, so every
  rubric about *what* the skill asks would grade an empty string. Without it the model
  writes the question as prose, which is what these cases read.
- **No `Write` or `Edit`.** No case asserts that a document landed on disk. Granting them
  would have every run scribble `docs/plan/` and `docs/code-review/` into the fixture,
  which is exactly the contamination the fixture exists to avoid.
- **No `Task`.** The review agents never run. Cases grade which agents a skill *names*
  and how it says it will run them.

### Cases are grouped by what the harness can observe

`promptfooconfig.yaml` registers the case files in three groups, and the group a skill lands
in decides what its cases may assert.

| Group | Skills | A case may assert |
| ----- | ------ | ----------------- |
| Graded on the artifact | `brainstorm`, `plan`, `review`, `debrief`, `refine-approach`, `plan-technical-review`, `elements-of-style` | The document's filename convention, its sections, its content — the artifact is in the response |
| Graded on decisions narrated | `build`, `hotfix`, `create` | Only what the skill *says* it will do. Their real work is mutating files, dispatching agents, or calling a companion plugin, and none of that happens here |

Putting a skill in the wrong group produces an unsatisfiable case. A `build` case asserting
that `docs/plan/…` was updated cannot pass — there is no `Write` tool — and it fails on the
harness rather than on the skill.

There is a third group, and it exists because an earlier version of this document was wrong
about it. `create-pr` and `rebase` declare `disable-model-invocation: true`, so the model
cannot route to them and `skill-used` can never be satisfied. That was written up here as
making them untestable. It does not: it makes the *routing* half of the question moot by
design, which is the whole point of the flag. The *compliance* half tests fine.

| Group | Skills | How |
| ----- | ------ | --- |
| Graded through the slash-command path | `create-pr`, `rebase` | The prompt starts with a literal `/create-pr` or `/rebase`, which the provider expands |

`not-icontains 'Unknown command'` replaces `skill-used` as the proof the skill loaded, and it
is load-bearing on every case in both files. **Column separation here is the sharpest in the
suite**, sharper than any routed skill: the sealed column cannot parse the input at all, so its
entire output is `Unknown command: /create-pr` or `Unknown command: /rebase. Did you mean
/rename?`. Measured 10/10 against 0/10.

Arguments work either on the command line or in a later paragraph; both were verified. Both
skills are almost entirely `Bash`, which the harness does not grant, so their prompts supply
the repo state as text and say not to run anything — without that the response is a request for
shell access and there is nothing to grade.

### Prompts have to close the questions the skill would ask

This is the one place these evals differ most from a code-generating plugin's. Wingspan
skills are conversational by design: `/brainstorm` interviews the user, `/plan` asks
before rewriting a criterion, `/build` asks how to commit. With no `AskUserQuestion` tool
and only one user turn, a naturally phrased prompt returns question one of a dialogue
that never continues, and there is nothing to grade.

So most prompts here end with **"Do not ask me any questions"** and supply what the skill
would otherwise have to ask for — the stack, the test command, the linter. A measured
example: `Write an implementation plan for adding rate limiting to our public API`
produced a list of clarifying questions and scored 0 on every content assertion. The same
case naming Express, Redis, `npm test` and `npm run lint` produced the full plan document.

Two consequences worth knowing before writing a case:

- **Cases that grade the questions omit that instruction on purpose.** Both phrasings are
  legitimate; pick the one matching what the case measures, and say which in a comment.
- **Withholding the toolchain is not a harder test, it is a broken one.** The fixture
  carries no manifest, so a plan asked for without a test command fills `verify:` with
  placeholders and fails an assertion about `/plan`, not about the model.

### Case format

`evals/tests/<skill>.yaml` is a list of promptfoo tests:

```yaml
- description: plan-emits-machine-checkable-success-criteria
  vars:
    prompt: >-
      Write the implementation plan for adding a per-API-key rate limit ... Tests are
      Jest via `npm test`; the linter is `npm run lint`. Do not ask me any questions.
  assert:
    - type: skill-used
      value: 'vgv-wingspan:plan'
    - type: javascript
      value: file://assertions/success-criteria-block.js
    - type: regex
      value: 'docs/plan/\d{4}-\d{2}-\d{2}-(feat|fix|refactor)-[a-z0-9-]+-plan\.md'
    - type: llm-rubric
      value: >-
        Every phase carries its own scope, the files it touches, and something that
        proves the phase is complete.
```

`defaultTest.threshold` in the config is `0.8`, so each case passes when its assertions
average that or better. The threshold is per-case, so a weak case cannot hide behind
strong siblings.

### Assertions

| `type` | Measures | Notes |
| ------ | -------- | ----- |
| `skill-used` / `not-skill-used` | process | Reads `metadata.skillCalls`, which promptfoo derives from `Skill` tool calls. Errored skill attempts do not satisfy it |
| `regex` / `not-regex` | style | Compiled with JS `new RegExp`, so an inline `(?i)` flag matches those literal characters and silently never fires — spell case variants out with a character class instead. Any assertion negates with a `not-` prefix |
| `contains` / `icontains` / `not-icontains` | outcome | Case-insensitive variants for short answers |
| `llm-rubric` | style | Model-graded against a criterion |
| `javascript` | outcome, process | `file://assertions/*.js` — promptfoo resolves `file://` against the config file's directory, even from a test file |

One custom assertion lives in `evals/assertions/`:

- **`success-criteria-block.js`** — the `success-criteria` block is well-formed. A regex
  can prove `verify:` appears somewhere; it cannot prove *every* criterion carries one,
  and one unprovable criterion is enough for `/build` to ship on a gate that proves
  nothing. Checks `GOAL:`, at least one criterion, a `verify:` on each, a `NON-GOALS:`
  section, and a `VERIFICATION COMMAND:`. The fence label is not graded — models relabel
  `success-criteria` as `text` while reproducing the contract exactly, and failing that
  would measure fence syntax.

**Rubrics are graded blind.** The judge sees the response text and the criterion, never
the prompt. So a criterion like "the response fixes the loop bound" is unanswerable and
fails at random. Grade task success with a `regex` and keep the rubric to properties
visible in the text alone.

### The sealed column narrates tool calls it cannot make

With `tools: []` the model still reaches for tools, then writes what it would have run as
prose:

```text
I'll read the file to confirm its exact contents before reviewing.
{"command": "cat -n src/balance.js", "description": "View balance.js with line numbers"}
```

That is the harness working, not a leak — `metadata.toolCalls` is `[]` on those runs. But
it means a `not-regex` looking for shell-ish text can fire on a column that executed
nothing. Negate on skill vocabulary, not on command syntax.

### Isolation is held by the config alone

`skills` is a context filter, not a sandbox. Skill files stay on disk and readable through
Read, Glob and Grep, and `working_dir` points inside this checkout. A run that never
invoked a skill yet opened `SKILL.md` had the answers, so its score measures nothing.

Nothing detects that automatically. The three keys in the table above are the only thing
holding isolation. So treat any change to `tools`, `working_dir`, `setting_sources` or
`plugins` as invalidating every number measured before it, and re-baseline rather than
comparing across the change.

The plugin column is not sealed and does not need to be, but note that it *can* read
`evals/tests/*.yaml` — the answer key — by walking up from the fixture. No observed run
has done so, and nothing prevents it.

The symptom to watch for is the sealed column climbing toward the plugin column. That
reads like the model improving and is almost always contamination.

### Skill routing is tested, not assumed

Prompts name no skill. With `skills: all` the model routes on its own, and `skill-used`
makes a routing failure visible as its own failed assertion instead of as unexplained
content failures downstream. Negative controls invert it: every skill has one case
asserting `not-skill-used`, so a skill firing where it should not is caught rather than
inferred from the prose.

The slash-command path cannot be measured this way: invoking a skill as `/<name>` expands
its content into the prompt with no `Skill` tool call, so routing is only observable when
the model chooses the skill itself. `create-pr` and `rebase` are therefore not
routing-tested at all — both declare `disable-model-invocation: true`, which keeps them
off the model's skill list entirely.

`skills: all` is not scoped to this plugin. Claude Code's own built-in skills are in the
pool too, and one observed run answered `brainstorm-declines-to-write-the-code` by routing
to the built-in `simplify`. So an `Actual skills:` line naming something absent from
`skills/` is a routing miss, not a harness fault.

One case asserts `not-skill-used` on a skill's *own* subject rather than an unrelated one:
`build-refuses-to-build-without-a-plan`. Asked to build with no plan in sight, these
skills move to requirements rather than to code, so a `/build` that fired there would be
building unplanned work — the thing wingspan exists to prevent. The routing outcome is the
finding, not a workaround.

### The fixture must stay neutral

Both providers use `working_dir: ./fixture`, a small Express service: a README, a
`package.json` with `npm test` and `npm run lint`, four source files under `src/`, and one
Jest test file.

**Neutral does not mean empty.** The first version of this fixture was a README and two
empty directories, and it broke the skills that operate on a codebase rather than produce
one. `/build` reported that it had no project to build in; `/hotfix` dispatched its Locate
phase, found nothing, and stopped to ask. Both were behaving correctly. Measured, that
confound alone cost roughly five of twenty-six positive cases across two runs.

Neutral means **nothing that hints at what a Wingspan skill teaches**. Three things must
never go in it:

- **A `docs/` directory**, or any `docs/brainstorm`, `docs/plan`, `docs/reviews` path.
  Those paths and their filename conventions *are* the thing under test.
- **A `CLAUDE.md`.** This repo's own lists every skill, every output directory and every
  review agent, so a fixture carrying one hands the sealed column the answer key.
- **Comments addressed to the model.** The fixture README once carried an HTML comment of
  maintenance rules ("KEEP THIS NEUTRAL", "never add..."). The model read it as an injected
  instruction, flagged it to the user, and spent turns on it. Maintenance guidance goes in
  this file. The fixture holds only what a real project would.

Ordinary source code is not a leak. Wingspan teaches workflow, not JavaScript, and the
sealed column cannot read the fixture anyway — it has no tools. The one cost is that every
case is graded in a JavaScript context, which is a stated limitation rather than
contamination.

Prompts still paste in whatever they are about. A prompt naming a file the fixture does not
have sends the skill hunting, and it correctly stops when it comes up empty, so a pasted
snippet should say it is not in the working directory. Never add the subject of a case to
the fixture: the buggy `balance()` that `/review` and `/hotfix` cases paste would, on disk,
be visible to any run and turn a routing test into a reading-comprehension test.

### Running the suite

```bash
export ASDF_NODEJS_VERSION=22.22.0   # or whatever pins you to a supported Node
P="npx promptfoo@latest"
$P eval -c evals/promptfooconfig.yaml                          # all 67, both columns
$P eval -c evals/promptfooconfig.yaml --filter-pattern plan    # one skill
$P eval -c evals/promptfooconfig.yaml --repeat 2 --no-cache    # is a red case real?
$P eval -c evals/promptfooconfig.yaml --retry-errors           # re-run 529s only
$P view                                                        # the side-by-side
```

**Read the per-column split, not promptfoo's total.** The sealed column is meant to fail,
so a healthy full run reports a total that looks bad. Write the run to the gitignored
`evals/.runs/`, then split it:

```bash
$P eval -c evals/promptfooconfig.yaml --no-cache --no-table -o evals/.runs/latest.json
node -e 'const r=require("./evals/.runs/latest.json"),c={};for(const x of r.results.results){const l=x.provider.label;c[l]??={n:0,pass:0};c[l].n++;c[l].pass+=x.success?1:0}console.table(c)'
```

Then confirm the run was valid at all. The sealed column must have made zero tool calls; a
non-zero count means it could reach `../../skills` and every sealed number is void:

```bash
node -e 'const r=require("./evals/.runs/latest.json");const l=r.results.results.filter(x=>x.provider.label==="sealed-baseline"&&(x.metadata?.toolCalls||[]).length);console.log(l.length?"LEAK: "+l.map(x=>x.testCase.description).join(", "):"clean")'
```

Two things about the numbers. promptfoo caches by default, so `--no-cache` is needed for
fresh generations, and `--repeat N` shows the noise floor. And a `529 Overloaded` scores 0
with no failing assertion, which is indistinguishable from a content failure unless you
check `res.error`, so always follow up with `--retry-errors` before believing a failure
count.

These are not a merge gate, and nothing here runs in CI — run them locally before a PR
that changes a skill. They are non-deterministic and a single rubric verdict can move a
case, so treat one red case as a prompt to look rather than proof of a regression.
`--repeat 2` is the cheapest way to tell a real failure from noise.

### The measured baseline

Composed from two runs against identical skills: the 55-case full run (22m 23s, 367,416
tokens) plus a filtered run of the 12 slash-command cases (1m 54s). Both no cache, sonnet.

| Column | Positive cases | Negative controls | Total |
| ------ | -------------- | ----------------- | ----- |
| `with-skill` | **39 / 54** | 12 / 13 | 51 / 67 |
| `sealed-baseline` | **0 / 54** | 13 / 13 | 13 / 67 |

Positive cases split by skill, negative controls excluded because a sealed model passes
`not-skill-used` for free:

| Skill | `with-skill` | `sealed` | Lift |
| ----- | ------------ | -------- | ---- |
| create-pr | 5/5 | 0/5 | 100 pts |
| rebase | 5/5 | 0/5 | 100 pts |
| plan-technical-review | 3/3 | 0/3 | 100 pts |
| hotfix | 5/6 | 0/6 | 83 pts |
| brainstorm | 4/5 | 0/5 | 80 pts |
| plan | 4/5 | 0/5 | 80 pts |
| debrief | 4/5 | 0/5 | 80 pts |
| elements-of-style | 2/3 | 0/3 | 67 pts |
| review | 3/5 | 0/5 | 60 pts |
| build | 2/5 | 0/5 | 40 pts |
| create | 1/3 | 0/3 | 33 pts |
| refine-approach | 1/4 | 0/4 | 25 pts |

`create-pr` and `rebase` scored **1.00 on every case**, against 0.00 sealed. Read that as two
things at once. The separation is real and is the strongest evidence in the suite that the
plugin does the work — the bare model cannot even parse `/create-pr`. But a file where nothing
ever fails has no headroom to detect a *degradation*, only a break: these cases will catch
someone deleting the secret-file rule or reordering stash-then-rebase, and will not catch the
PR description getting gradually worse. They are a regression net, not a quality gauge.

`plan-technical-review` and `refine-approach` are from a follow-up filtered run, not the full
run above. Both had a YAML syntax error in their `when_to_use` during the full run — an
unquoted scalar containing `": "` — which made the whole frontmatter fail to parse and both
skills load with every field dropped. `claude plugin validate .` catches that, CI would have
caught it, and the lesson is narrower than it looks: **a frontmatter break is silent at
runtime and shows up as a skill that scores oddly, not as an error.** Re-measure after fixing
one; do not trust numbers taken across it.

**The sealed column has scored 0 positive cases on every run, and made zero tool calls
across every sealed run of all seven.** That is the number the suite exists to produce:
every content assertion here is measuring the plugin, and isolation was verified rather
than assumed.

**No positive case passes in both columns.** That is worth checking on every run, because a
case that passes in both is a free point inflating the score while proving nothing — run
the both-column query under **Running the suite**. Two cases had that defect and were
strengthened rather than deleted; see below.

#### What the eval suite has already changed

The five skills that had cases before the fixes went from **13/26 to 18/26**, with no change
to any of their assertions. Six cases went green, one regressed on routing noise.

| Case | Before | After | Fix |
| ---- | ------ | ----- | --- |
| `hotfix-requires-a-regression-test` | red on 5 runs | green | `hotfix` gained a `when_to_use` claiming time-pressure phrasing, plus a Core Standards block |
| `review-numbers-findings-with-stable-ids` | red on 6 runs | green | `review`'s `when_to_use` widened to claim single-file and pasted-snippet review |
| `review-keeps-fixes-inside-the-reviewed-scope` | red on 6 runs | green | Same |
| `plan-checks-for-an-existing-brainstorm-first` | red on 5 runs | green | `plan`'s `when_to_use` widened to claim "plan what we brainstormed" |
| `refine-approach-edits-the-document-in-place` | red | green on 2 runs | `refine-approach` Core Standards block |
| `plan-technical-review-does-not-rewrite-the-plan-from-scratch` | red | green | `when_to_use` boundary with `refine-approach` stated on both sides |

One cause explains all six: **the guidance existed but the model could not reach it.** Either
`when_to_use` did not claim the request, so the skill never fired and the bare model answered,
or the rule sat below the workflow the model was executing.

Two of these were written up in an earlier draft of this document as genuine skill gaps that
this suite deliberately would not guess a fix for. They were real, and the cause was
reachability rather than wording — the rules were unambiguous, they were just unreachable. So
when a case goes red, **check whether the guidance is reachable before concluding the model
ignored it.** A rule the model never reads and a request the skill never claims both look
exactly like a model that will not comply.

`review-numbers-findings-with-stable-ids` is the one worth singling out, because its
assertions *are* the report contract: `FINDING-NN` ids, a `<category>/<rule>` id per finding,
severity counts above the index. It was red on six consecutive runs, which left the fix to
`review`, `build` and `hotfix` unverifiable — the case never routed, so the contract was never
exercised. Widening the trigger made the case reachable and it went green, which verifies both
fixes at once.

#### A documented limitation that was not one

`create-pr` and `rebase` were written up here, in the config, and in `CLAUDE.md` as
structurally uncoverable, on the reasoning that `disable-model-invocation: true` blocks
`skill-used` and therefore collapses the ablation. The first half is true; the second does not
follow. A one-minute probe sending `/create-pr` through both providers would have shown it, and
the probe was not run because the conclusion felt obvious.

What it showed: the plugin column expands the command and follows the skill, the sealed column
answers `Unknown command: /create-pr`, and the two columns separate more cleanly than anywhere
else in the suite. Coverage went from 10 of 12 skills to 12 of 12 on the strength of that one
probe.

The general lesson is not about slash commands. **A limitation you have documented but not
measured is a hypothesis.** Everything else in the "does not cover" section below has a run
behind it; this one had an argument, and the argument was wrong.

#### Guarding against test-fitting

Tuning skills until the score rises corrupts the measurement. Two rules keep that honest, and
they matter more than the number:

1. **Label every change skill-fix or case-fix, and say which in the commit.** A skill-fix
   changes what the plugin teaches. A case-fix changes what the harness asks or grades. The
   two have opposite implications for a rising score: a skill-fix earns it, a case-fix may
   only have removed an obstacle.
2. **A case-fix needs a reason that does not mention the score.** "The prompt named a file
   the fixture does not have, so the skill correctly went looking and correctly stopped" is a
   reason. "This case was too strict" is not, unless it is followed by what the skill actually
   says.

Every case-fix in this suite so far, with its reason:

| Case-fix | Reason |
| -------- | ------ |
| Pasted plans say "not checked in anywhere yet" | `/build` reads `docs/plan/`, the fixture has none, so a named path sent it hunting and it correctly stopped. Four of five cases scored 0.4–0.67 against a skill behaving as designed |
| `/hotfix` prompts paste the code | Its Locate phase dispatches an agent that correctly found nothing in an empty fixture |
| Fixture gained a real project | Same cause, one level up: `/build` and `/hotfix` operate on a codebase and there wasn't one |
| Fixture README lost its HTML comment | The maintenance notes read as instructions; the model flagged them as injected and spent turns on it |
| `elements-of-style` cases rewritten | They passed in **both** columns, sealed at 0.90 and 0.80. They were measuring Claude |
| `hotfix` tradeoff rubric split in two | One compound criterion scored a response doing half of it at 0, sinking the case at exactly 0.80 |
| `build` clear-context rubric relaxed | It demanded the skill always clear context; the skill offers it as the recommended option and lets the user pick. The rubric was wrong about the skill |
| `review` negative control reworded | The sentence to rewrite contained "findings" and "report", the exact words its own rubric negated |

Two changes were reverted rather than kept: an `elements-of-style` assertion on the serial
comma, which the base model applies unprompted, and a `build` rubric asserting the phase loop
writes to the plan file, which no run can satisfy without a `Write` tool.

#### The plugin column is the noisy one

Seven runs. On the 32-case suite, `with-skill` measured 18, 21, 18, 20 and 18 of 32; two of
those were the *same config on the same cases* and differed by three, all of it routing. On
the 55-case suite it measured 38 and 39.

So **a single red case is not evidence of anything.** Use `--repeat 3` before editing one.
`review-runs-the-four-default-agents` regressed across the fix runs on routing alone, and
`hotfix-marks-an-accepted-tradeoff-with-a-todo` was green on one run and red on the next with
nothing changed between them.

#### What is still red

| Case | Diagnosis |
| ---- | --------- |
| `build-executes-one-phase-per-context-window`, `build-decides-commit-autonomy-before-implementing`, `build-treats-a-plan-with-no-criteria-as-ungated` | `/build` routes every time and then spends the response reporting that it has no `Write`, `Edit` or `Bash` tool, so it never reaches the phase loop, the commit decision, or the ship gate. Harness, not skill. Needs either a stateful harness with write tools and a scratch checkout, or rewriting to ask only what `/build` would do |
| `create-stops-when-no-companion-plugin-matches` | **Genuine gap.** `/create` correctly reports that no companion plugin handles Elixir, then offers to scaffold it anyway. The skill says "Inform the user no companion plugin is registered for this project type. Stop." |
| `debrief-does-not-fix-the-code` | **Genuine gap.** `/debrief` writes a correct debrief and then hands over the patched predicate, against its own closing rule ("DO NOT make code changes"). Same buried-guidance shape as the fixed `hotfix` gaps: the rule is the last line of the file. This is the next fix to try, and it should be measured, not assumed |
| `refine-approach-names-one-must-address-item` | Routes to `plan-technical-review` even with the boundary stated on both sides. "Is this plan ready?" is in that skill's trigger list verbatim, so the case may need rewording rather than the skills |
| `refine-approach-asks-before-substantive-changes` | Red on every run. The auto-fix / needs-approval line is now in both Step 5 and Core Standards, and the response still hands back one undifferentiated list |
| `review-establishes-scope-before-reviewing` | Cannot pass here. The skill decides scope by running `detect-review-scope.sh`; there is no `Bash` tool, so it has nothing to decide from |
| `review-runs-the-four-default-agents` | Routing miss, and green on earlier runs. Noise |
| `brainstorm-recommends-planning-when-requirements-are-clear` | Borderline. Handed a fully specified endpoint, `/brainstorm` asks one scoping question instead of saying the requirement is ready to plan. Defensible; the case may be too strict about a skill whose job is to ask |
| `elements-of-style-puts-parallel-ideas-in-parallel-form` | The hardest thing here to grade. The rewrite improves the sentences without making all three clauses share one grammatical shape. Genuine, minor |
| `plan-declines-to-implement` | Not a content failure. `Reached maximum number of turns (16)`, which scores 0 with no failing assertion and reads exactly like a content failure unless you check `res.error`. One case per full run hits this; `--retry-errors` re-runs only those |

Roughly $0.10–0.20 and 10–30 seconds per case per provider, so a full run of 67 cases
across both columns lands around $14–27 of equivalent usage.

### What these evals do not cover

| Not covered | Why |
| ----------- | --- |
| **Judge calibration** | Most assertions here are `llm-rubric` with no human-labelled gold set and no measured agreement. Strong judges reach roughly 80% agreement with humans, and raw agreement can read 90% while a judge does nothing meaningful. Until someone hand-labels a sample, rubric verdicts are unverified — and `llm-rubric` does not calibrate itself |
| **Whether the artifact gets written** | No `Write` tool, so no case proves a brainstorm doc, plan, or review report reached disk with the asserted filename. Cases grade the path the skill *states* it would use |
| **Whether the agents run** | No `Task` tool, so `/build`'s five agents and `/review`'s four never dispatch. Cases grade which agents the skill names and how it says it will run them |
| **Multi-turn behavior** | Every case is one user turn. `/brainstorm`'s interview, `/plan`'s criterion-rewrite confirmation and `/build`'s phase loop all really span many turns, and only their first move is measured |
| **The handoff chain** | Nothing verifies that `/brainstorm` hands a real path to `/plan`, or that `/build` resumes from a `**Status:** Done` marker it wrote itself. Those need a stateful harness |
| **Judge independence** | Generator and rubric grader are the same model family and may share blind spots |
| **Case count** | All 12 skills have cases. Research suggests 100–200 cases; there are 67 |
| **Stable routing** | Whether a skill activates is itself nondeterministic, and a routing miss takes every downstream assertion with it. This is why `skill-used` is its own assertion rather than inferred from content |
| **Prose in a `SKILL.md`** | Deliberate. Asserting `contains` patterns against skill bodies fails a copy-edit that teaches exactly the same thing |
| **The skills' own surfaces** | Nothing verifies that a name in `allowed-tools` still exists, that a markdown link to a reference file resolves, or that a symlink into `skills/shared/` still points at something. See below |

Nothing checks the surfaces either. CI's `validate-skills` job does cover reference links
and frontmatter for *changed* skills, but `claude plugin validate .` does not, and neither
covers these invariants, so they are held by convention alone:

- **`allowed-tools` is an auto-approve list, not an availability list.** `/build` declares
  only a handful of `Bash(...)` patterns yet writes code with `Write` and `Edit` every run.
  So an entry naming a tool that no longer exists costs a permission prompt, not an error,
  and nothing reports it.
- **`create-pr` and `rebase` must stay unreachable from other skills.** Both declare
  `disable-model-invocation: true`, which keeps them off the model's skill list entirely.
  A skill instructing the model to "call `/create-pr`" stalls at that step with no error
  — this is a bug that shipped in `/build`'s Phase 4 and was fixed alongside these evals.
  Adding such an instruction is silent and untested. The two skills' own behavior *is* now
  covered, through the slash-command path; what stays unchecked is other skills calling them.
- **The review sets must not drift into each other.** `/review` runs four agents, `/build`
  five (plus `pr-readiness`), `/hotfix` two. Only the four-and-two are asserted here; the
  boundary itself is convention.
- **`hotfix/` is hotfix's prefix and `fix/` is everyone else's.** Asserted for `/hotfix`
  only.
- **Every user-invocable skill needs a `when_to_use`.** Nothing enforces it, and `/hotfix`
  shipped without one until these evals found it. A skill missing the field is invisible to
  routing except through its `description`, and a skill whose `when_to_use` does not claim a
  request shape is a skill that silently loses that request to the bare model. That is not a
  cosmetic gap: it is the single largest cause of red cases in this suite.
- **A long `SKILL.md` needs a supporting directory.** CI's `validate-skills` job runs with
  `fail-on-warning: true`, and its `body-progressive-disclosure` rule fails a long SKILL.md
  with no `references/` beside it. Nothing warns you as a file grows. `/build` (259 lines)
  and `/plan` (219) are the longest and both have one; `/create` (83), `/elements-of-style`
  (89) and `/rebase` (104) have none and are well short of tripping it. Adding a long section
  to a skill without `references/` is where this bites.

### Adding a case

1. **Write the prompt as a user would send it**, then add what the skill would otherwise
   have to ask for — the stack, the test command, the linter — and "Do not ask me any
   questions" unless the questions are what you are grading.
2. **Make it self-contained.** Paste in the code, the plan, or the diff the prompt refers
   to. Never add it to the fixture.
3. **Add `skill-used`** so a routing failure is legible on its own.
4. **Grade mechanically where you can** — a filename shape, a `**Status:**` marker, an
   agent name, a `TODO(hotfix)` — and with `llm-rubric` where the property is structural.
5. **Include the cases where the skill must say no.** Ask for the anti-pattern outright
   (skip the tests, hotfix a 40-million-row migration) and grade that the response
   declines and offers the alternative. A skill earns its keep on its prohibitions.
6. **Keep one negative control per skill**, asserting `not-skill-used`. Grade only the
   *absence* of the skill's vocabulary in the rubric, and the task itself with a `regex`.
   A negative control whose rubric also asks "did it do the task" is the blind-judge trap
   above.
7. **Write rubric criteria a stranger could apply**, using only the response text. Name
   what satisfies it and what does not.
8. **Check it beats the baseline.** If the assertion passes in the sealed column too, it
   is measuring Claude, not your skill. Strengthen it or drop it.
9. **Do not ask for what the prompt forbade.** A rubric wanting an implementation will
   always fail a prompt ending "do not write the implementation".

---

## When to update what

| You changed | Do this |
| ----------- | ------- |
| Added a skill | Add `evals/tests/<skill>.yaml` and register it under `tests:` |
| What a skill teaches | Run its cases and update any that asserted the old behavior |
| A path or filename convention | Update the `regex` asserting its shape — the conventions in `docs/` are asserted literally |
| A skill's review agent set | Update the agent-name assertions in that skill's cases, and check the `not-regex` that keeps the sets from overlapping |
| A skill's `allowed-tools` | Confirm by hand that every name still exists. Nothing validates them |
| `disable-model-invocation` on any skill | Check no other skill instructs the model to call it |
