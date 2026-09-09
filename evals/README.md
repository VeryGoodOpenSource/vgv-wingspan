# Skill Evals

One question per case: does Claude route to the skill, and does the output follow it?

```bash
npm install --no-save @anthropic-ai/claude-agent-sdk   # from the repo root
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

Cases live in `evals/tests/*.yaml` and run through
[promptfoo](https://www.promptfoo.dev)'s
[Claude Agent SDK provider](https://www.promptfoo.dev/docs/providers/claude-agent-sdk),
which loads this repo as a local plugin and reports which skills the model actually
invoked. They call real models, so they take minutes and consume usage.

This file is the reference for writing and running a case. It deliberately does not carry
the run-by-run history — what each fix moved, and by how much, belongs in the commit that
made it.

**No API key.** Both the agent under test and the `llm-rubric` judge authenticate through
your Claude Code session, so the whole suite runs on a subscription. The judge is pinned to
the same provider in `defaultTest.options`; left unpinned, promptfoo picks a grader from
whatever key is in the environment, which is neither free nor deterministic.

Three prerequisites, each of which has broken a run:

- **The SDK must live in `node_modules` next to where you run promptfoo.** A `-g` install
  does not work and neither does `NODE_PATH`. `--no-save` keeps `package.json` out of the
  repo; `node_modules/` is already gitignored.
- **A second `npm install --no-save` replaces the first.** With no `package.json` recording
  what is installed, adding any other package that way removes the SDK, and the next run
  reports 100% *errors* rather than failures. Name everything in one command.
- **Node `^20.20.0 || >=22.22.0`**, enforced by promptfoo, which refuses to start below it.
  Nothing in this repo pins a Node version.

`max_turns` is `16`, not the `12` the sibling vgv-ai-flutter-plugin suite uses. Wingspan
skills chain reference files — `/build` reads four before it answers — and at 12 those cases
died on `Reached maximum number of turns`, which scores 0 with no failing assertion and
reads exactly like a content failure. It is the one run setting here that should not be
copied from that repo.

Behavior differs across promptfoo releases, so a suite that ran yesterday can break on an
upgrade with no change here. If a run dies before any case executes, or the two columns
stop differing, pin to the last version you saw work before editing a case.

---

## The two columns

Every case runs against both providers. An assertion that passes in both is measuring the
model, not the skill, so read the per-column split rather than promptfoo's total.

| Provider | Config | Measures |
| -------- | ------ | -------- |
| `with-skill` | `plugins` points at this repo, `skills: all`, read tools | What the plugin produces |
| `sealed-baseline` | no `plugins`, `tools: []` | What the bare model produces |

### Sealing the baseline takes three keys

None is the provider's default, and two leak silently:

| Key | Why |
| --- | --- |
| `tools: []` | `working_dir` is inside the checkout, so a baseline with read tools walks up to `../../skills`, reads `SKILL.md`, and passes rubrics on the answers. This emits `--tools ""`, removing all built-ins |
| `setting_sources: []` | **Omitting the key loads everything**, including this repo's `CLAUDE.md`, which names every skill, every output directory under `docs/`, and every review agent. No tool call is involved, so no assertion can catch it |
| `strict_mcp_config: true` | Without it, `--tools ""` still leaves every `mcp__*` tool in place |

Do not reach for `custom_allowed_tools` or `append_allowed_tools` to restrict a column.
Those map to the SDK's `allowedTools`, an auto-approve list rather than an availability
list, and an empty array is dropped entirely — silently restoring the full default tool set.

Both columns carry `setting_sources: []`. If only one does, the ablation compares contexts
rather than the plugin. Plugins load through `--plugin-dir`, so `skills: all` still works
with settings disabled.

### Isolation is held by the config alone

`skills` is a context filter, not a sandbox. Skill files stay on disk and readable, and
`working_dir` points inside this checkout. A run that never invoked a skill yet opened
`SKILL.md` had the answers, so its score measures nothing.

Nothing detects that automatically. The three keys above are the only thing holding
isolation, so treat any change to `tools`, `working_dir`, `setting_sources` or `plugins` as
invalidating every number measured before it. The plugin column is not sealed and does not
need to be, but note it *can* read `evals/tests/*.yaml` — the answer key — by walking up
from the fixture. No observed run has.

**The symptom to watch for is the sealed column climbing toward the plugin column.** That
reads like the model improving and is almost always contamination.

### The plugin column's tools are chosen, not inherited

`tools: ['Skill', 'Read', 'Glob', 'Grep']`. Read, Glob and Grep are there because every
workflow skill delegates to `references/*.md` — `/plan` alone reads a template,
`success-criteria.md` and `plan-review.md`. Three absences are deliberate:

- **No `AskUserQuestion`.** These skills ask constantly. With the tool available the
  question goes into a tool call the response body never shows, so every rubric about
  *what* the skill asks would grade an empty string.
- **No `Write` or `Edit`.** No case asserts a document reached disk, and granting them would
  have every run scribble `docs/plan/` into the fixture.
- **No `Task`.** The review agents never dispatch. Cases grade which agents a skill *names*.

### The sealed column narrates tool calls it cannot make

With `tools: []` the model still reaches for tools, then writes what it would have run:

```text
I'll read the file to confirm its exact contents before reviewing.
{"command": "cat -n src/balance.js", "description": "View balance.js with line numbers"}
```

That is the harness working, not a leak — `metadata.toolCalls` is `[]` on those runs. But a
`not-regex` looking for shell-ish text can fire on a column that executed nothing. Negate
on skill vocabulary, not on command syntax.

---

## Writing a case

### Pick the group first

`promptfooconfig.yaml` registers the case files in three groups, and the group decides what
a case may assert. Putting a skill in the wrong one produces a case that cannot pass, and it
fails on the harness rather than on the skill.

| Group | Skills | A case may assert |
| ----- | ------ | ----------------- |
| Graded on the artifact | `brainstorm`, `plan`, `review`, `debrief`, `refine-approach`, `plan-technical-review`, `elements-of-style` | The document's filename convention, its sections, its content — the artifact is in the response |
| Graded on decisions narrated | `build`, `hotfix`, `create` | Only what the skill *says* it will do. Their real work is file mutation, agent dispatch, or a companion plugin, none of which happens here |
| Graded through the slash-command path | `create-pr`, `rebase` | The prompt opens with a literal `/create-pr` or `/rebase`, which the provider expands |

The third group exists because `create-pr` and `rebase` declare
`disable-model-invocation: true`, so the model cannot route to them and `skill-used` can
never be satisfied. That makes the *routing* half of the question moot by design — the point
of the flag — not the compliance half. `not-icontains 'Unknown command'` replaces
`skill-used` as the proof the skill loaded, and is load-bearing on every case in both files:
the sealed column cannot parse the input at all, so its entire output is
`Unknown command: /create-pr`. Arguments work on the command line or in a later paragraph.
Both skills are almost entirely `Bash`, which the harness does not grant, so their prompts
supply the repo state as text and say not to run anything.

### Close the questions the skill would ask

This is where these evals differ most from a code-generating plugin's. Wingspan skills are
conversational by design: `/brainstorm` interviews, `/plan` confirms before rewriting a
criterion, `/build` asks how to commit. With no `AskUserQuestion` tool and one user turn, a
naturally phrased prompt returns question one of a dialogue that never continues.

So most prompts end with **"Do not ask me any questions"** and supply what the skill would
otherwise ask for — the stack, the test command, the linter. Measured: `Write an
implementation plan for adding rate limiting to our public API` produced a list of
clarifying questions and scored 0 on every content assertion; the same case naming Express,
Redis, `npm test` and `npm run lint` produced the full plan.

- **Cases that grade the questions omit that instruction on purpose.** Both phrasings are
  legitimate; say which in a comment.
- **Withholding the toolchain is not a harder test, it is a broken one.** A plan asked for
  without a test command fills `verify:` with placeholders and fails an assertion about
  `/plan`, not about the model.

### Format

```yaml
- description: plan-emits-machine-checkable-success-criteria
  vars:
    prompt: >-
      Write the implementation plan for adding a per-API-key rate limit ... Tests are
      Jest via `npm test`; the linter is `npm run lint`. Do not ask me any questions.
  assert:
    - type: skill-used
      value: 'vgv-wingspan:plan'
      weight: 3
    - type: javascript
      value: file://assertions/success-criteria-block.js
    - type: regex
      value: 'docs/plan/\d{4}-\d{2}-\d{2}-(feat|fix|refactor)-[a-z0-9-]+-plan\.md'
    - type: llm-rubric
      value: >-
        Every phase carries its own scope, the files it touches, and something that
        proves the phase is complete.
```

### The threshold and the routing weight

`defaultTest.threshold` is `0.8`: a case passes when its assertions average that or better,
per case, so a weak case cannot hide behind strong siblings.

**Routing assertions carry `weight: 3`.** Unweighted they were outvoted — measured on this
suite, 15 of 67 cases would report green with the skill never invoked and every content
assertion passing, because a 7-assertion case scores 0.86 on a pure routing miss. With
weight 3 that number is 0.

The weight buys strictness on routing by loosening content: a case can absorb one more
content miss than before. Measured cost, two cases where two content assertions may fail
and the case still passes, both mechanical-heavy. Raising the weight past 3 widens that hole
rather than closing it. **Do not tune either number to make a red case go green** — see
[skill-fix or case-fix](#skill-fix-or-case-fix).

### Assertions

| `type` | Measures | Notes |
| ------ | -------- | ----- |
| `skill-used` / `not-skill-used` | process | Reads `metadata.skillCalls`, which promptfoo derives from `Skill` tool calls. Errored skill attempts do not satisfy it |
| `regex` / `not-regex` | style | Compiled with JS `new RegExp`, so an inline `(?i)` flag matches those literal characters and silently never fires — spell case variants out with a character class. Any assertion negates with a `not-` prefix |
| `contains` / `icontains` / `not-icontains` | outcome | Case-insensitive variants for short answers |
| `llm-rubric` | style | Model-graded against a criterion |
| `javascript` | outcome, process | `file://assertions/*.js` — promptfoo resolves `file://` against the config file's directory, even from a test file |

One custom assertion lives in `evals/assertions/`:

- **`success-criteria-block.js`** — the `success-criteria` block is well-formed. A regex can
  prove `verify:` appears somewhere; it cannot prove *every* criterion carries one, and one
  unprovable criterion is enough for `/build` to ship on a gate that proves nothing. Checks
  `GOAL:`, at least one criterion, a `verify:` on each, `NON-GOALS:`, and a
  `VERIFICATION COMMAND:`. The fence label is not graded — models relabel `success-criteria`
  as `text` while reproducing the contract exactly, and failing that would measure fence
  syntax.

**Rubrics are graded blind.** The judge sees the response text and the criterion, never the
prompt. So a criterion like "the response fixes the loop bound" is unanswerable and fails at
random. Grade task success with a `regex` and keep the rubric to properties visible in the
text alone.

### Routing is tested, not assumed

Prompts name no skill. With `skills: all` the model routes on its own, and `skill-used`
makes a routing failure legible as its own failed assertion instead of as unexplained
content failures downstream. Negative controls invert it: every skill has one case asserting
`not-skill-used`.

`skills: all` is not scoped to this plugin. Claude Code's built-ins are in the pool too, and
one observed run answered a `brainstorm` case by routing to the built-in `simplify`. So an
`Actual skills:` line naming something absent from `skills/` is a routing miss, not a
harness fault.

One case asserts `not-skill-used` on a skill's *own* subject:
`build-refuses-to-build-without-a-plan`. Asked to build with no plan in sight, these skills
move to requirements rather than to code, so a `/build` that fired there would be building
unplanned work — the thing wingspan exists to prevent.

### The fixture must stay neutral

Both providers use `working_dir: ./fixture`, a small Express service: a README, a
`package.json` with `npm test` and `npm run lint`, four source files, one Jest test.

**Neutral does not mean empty.** The first version was a README and two empty directories,
and it broke every skill that operates on a codebase rather than producing one. `/build`
reported it had no project to build in; `/hotfix` dispatched its Locate phase, found
nothing, and stopped to ask. Both were behaving correctly. That confound alone cost roughly
five of twenty-six positive cases across two runs.

Neutral means **nothing that hints at what a skill teaches**. Three things must never go in:

- **A `docs/` directory**, or any `docs/brainstorm`, `docs/plan`, `docs/reviews` path. Those
  paths and their filename conventions *are* the thing under test.
- **A `CLAUDE.md`.** This repo's own names every skill, output directory and review agent.
- **Comments addressed to the model.** The fixture README once carried an HTML comment of
  maintenance rules ("KEEP THIS NEUTRAL"). The model read it as an injected instruction,
  flagged it, and spent turns on it. Maintenance guidance goes in this file.

Ordinary source code is not a leak — wingspan teaches workflow, not JavaScript, and the
sealed column has no tools to read it with. Prompts still paste in whatever they are about,
and a prompt naming a file the fixture does not have sends the skill hunting, so a pasted
snippet should say it is not in the working directory. **Never add the subject of a case to
the fixture:** the buggy `balance()` that `/review` and `/hotfix` cases paste would, on
disk, turn a routing test into a reading-comprehension test.

### Skill-fix or case-fix

Tuning skills until the score rises corrupts the measurement. Two rules keep it honest:

1. **Label every change skill-fix or case-fix in the commit.** A skill-fix changes what the
   plugin teaches and earns a rising score. A case-fix changes what the harness asks or
   grades, and may only have removed an obstacle.
2. **A case-fix needs a reason that does not mention the score.** "The prompt named a file
   the fixture does not have, so the skill correctly went looking and correctly stopped" is
   a reason. "This case was too strict" is not, unless followed by what the skill says.

The check that catches the worst version of this: **an assertion passing in the sealed column
too is measuring Claude, not your skill.** Strengthen it rather than banking it.

### The checklist

1. **Write the prompt as a user would send it**, then add what the skill would otherwise have
   to ask for, plus "Do not ask me any questions" unless the questions are what you grade.
2. **Make it self-contained.** Paste in the code, the plan, or the diff. Never add it to the
   fixture.
3. **Add the routing assertion with `weight: 3`** so a routing failure is legible on its own
   and cannot be outvoted.
4. **Grade mechanically where you can** — a filename shape, a `**Status:**` marker, an agent
   name, a `TODO(hotfix)` — and with `llm-rubric` where the property is structural.
5. **Include the cases where the skill must say no.** Ask for the anti-pattern outright (skip
   the tests, hotfix a 40-million-row migration) and grade that the response declines and
   offers the alternative. A skill earns its keep on its prohibitions.
6. **Keep one negative control per skill**, asserting `not-skill-used`. Grade only the
   *absence* of the skill's vocabulary in the rubric, and the task itself with a `regex`. A
   negative control whose rubric also asks "did it do the task" is the blind-judge trap.
7. **Write rubric criteria a stranger could apply** using only the response text.
8. **Check it beats the baseline.**
9. **Do not ask for what the prompt forbade.** A rubric wanting an implementation will always
   fail a prompt ending "do not write the implementation".

---

## Running

```bash
export ASDF_NODEJS_VERSION=22.22.0   # or whatever pins you to a supported Node
P="npx promptfoo@latest"
$P eval -c evals/promptfooconfig.yaml                          # all 67, both columns
$P eval -c evals/promptfooconfig.yaml --filter-pattern '^plan-' # one skill
$P eval -c evals/promptfooconfig.yaml --repeat 2 --no-cache    # is a red case real?
$P eval -c evals/promptfooconfig.yaml --retry-errors           # re-run 529s only
$P view                                                        # the side-by-side
```

Anchor `--filter-pattern` with `^` and a trailing hyphen. `plan` alone also selects every
`plan-technical-review-*` case, and `create` also selects `create-pr-*`.

A full two-column run is all 67 cases, 134 results, and measured **16m 34s** and **16m 55s**
on two runs at concurrency 4 — $0.047-0.051 per result, $6.33-6.82 total in API-equivalent
terms, worst single result $0.297 against the `max_budget_usd: 0.5` circuit breaker, which
has never tripped. Locally none of that is billed at
all: the run authenticates through your Claude Code session. Filter to the skill you touched
while iterating; the full run is a pre-merge check.

**Nothing eval-related runs in CI.** These call real models and are nondeterministic, so a
single run is not a reliable gate. Run them by hand before a PR that changes a skill.

**Read the per-column split, not the total.** The sealed column is meant to fail, so a
healthy full run reports a total that looks bad. Write to the gitignored `evals/.runs/`,
then split:

```bash
$P eval -c evals/promptfooconfig.yaml --no-cache --no-table -o evals/.runs/latest.json
node -e 'const r=require("./evals/.runs/latest.json"),c={};for(const x of r.results.results){const l=x.provider.label;c[l]??={n:0,pass:0};c[l].n++;c[l].pass+=x.success?1:0}console.table(c)'
```

Then confirm the run was valid. The sealed column must have made zero tool calls; a non-zero
count means it could reach `../../skills` and every sealed number is void:

```bash
node -e 'const r=require("./evals/.runs/latest.json");const l=r.results.results.filter(x=>x.provider.label==="sealed-baseline"&&(x.metadata?.toolCalls||[]).length);console.log(l.length?"LEAK: "+l.map(x=>x.testCase.description).join(", "):"clean")'
```

And check no positive case passes in both columns — one that does is a free point inflating
the score while proving nothing:

```bash
node -e 'const r=require("./evals/.runs/latest.json"),b={};for(const x of r.results.results){(b[x.testCase.description]??={})[x.provider.label]=x}for(const[d,c]of Object.entries(b)){if((c["with-skill"]?.testCase.assert||[]).some(a=>a.type==="not-skill-used"))continue;if(c["with-skill"]?.success&&c["sealed-baseline"]?.success)console.log("BOTH PASS:",d)}'
```

**Noise is real.** promptfoo caches by default, so `--no-cache` is needed for fresh
generations. Two runs of identical config on identical cases have differed by three of 32,
all of it routing, and single cases have crossed the pass/fail line untouched. A `529
Overloaded` or `Reached maximum number of turns` scores 0 with no failing assertion, which
is indistinguishable from a content failure unless you check `res.error`. So: `--repeat 2`
before believing a red case, and `--retry-errors` before believing a failure count.

---

## What this does not cover

| Not covered | Why |
| ----------- | --- |
| **Judge calibration** | Most assertions are `llm-rubric` with no human-labelled gold set and no measured agreement. Strong judges reach roughly 80% agreement with humans, and raw agreement can read 90% while a judge does nothing meaningful. Rubric verdicts are unverified rather than wrong |
| **Whether the artifact gets written** | No `Write` tool, so no case proves a brainstorm doc, plan or review report reached disk. Cases grade the path the skill *states* it would use |
| **Whether the agents run** | No `Task` tool, so `/build`'s five agents and `/review`'s four never dispatch |
| **Anything `/build` does after phase one** | `/build` routes every time, then spends the response reporting it has no `Write`, `Edit` or `Bash` tool, so the phase loop, the commit decision and the ship gate are all unreachable. Three cases are red for this reason and need a stateful harness with a scratch checkout |
| **Scope detection in `/review`** | The skill decides scope by running `detect-review-scope.sh`. With no `Bash` tool it has nothing to decide from, so `review-establishes-scope-before-reviewing` cannot pass here |
| **Multi-turn behavior** | Every case is one user turn. `/brainstorm`'s interview, `/plan`'s confirmation and `/build`'s phase loop span many, and only the first move is measured |
| **The handoff chain** | Nothing verifies `/brainstorm` hands a real path to `/plan`, or that `/build` resumes from a `**Status:** Done` marker it wrote |
| **Judge independence** | Generator and rubric grader are the same model family and may share blind spots |
| **Case count** | All 12 skills have cases. Research suggests 100–200; there are 67 |
| **Stable routing** | Whether a skill activates is itself nondeterministic, which is why `skill-used` is its own weighted assertion rather than inferred from content |
| **Prose in a `SKILL.md`** | Deliberate. Asserting `contains` against skill bodies fails a copy-edit that teaches the same thing |

### Surfaces nothing checks

CI's `validate-skills` job covers reference links and frontmatter for *changed* skills, and
`claude plugin validate .` covers the manifests. Neither covers these, so they are held by
convention:

- **`allowed-tools` is an auto-approve list, not an availability list.** `/build` declares a
  handful of `Bash(...)` patterns yet writes code with `Write` and `Edit` every run. An entry
  naming a tool that no longer exists costs a permission prompt, not an error.
- **`create-pr` and `rebase` must stay unreachable from other skills.** A skill instructing
  the model to "call `/create-pr`" stalls there with no error — a bug that shipped in
  `/build`'s Phase 4. Their own behavior is covered now; other skills calling them is not.
- **The review sets must not drift.** `/review` runs four agents, `/build` five, `/hotfix`
  two. Only the four and the two are asserted.
- **`hotfix/` is hotfix's branch prefix and `fix/` is everyone else's.** Asserted for
  `/hotfix` only.
- **A rule at the bottom of a `SKILL.md` is a rule the model does not reach.** Four skills
  have now failed a case this way — `/hotfix`, `/refine-approach`, `/debrief` and `/plan` —
  each with the correct rule stated unambiguously in a footer below the workflow the model
  was executing. Promoting it to a **Core Standards** block at the top fixed all four, with
  no assertion changed. When a case goes red, check whether the guidance is reachable before
  concluding the model ignored it.
- **A refusal that also delivers the thing is not a refusal.** The recurring shape: the skill
  states the right position, then hands over the output anyway — `/create` reporting no
  companion plugin and offering to scaffold regardless, `/debrief` writing the document and
  attaching the patch, `/plan` producing the plan with the implementation inside it. State
  the position, do not deliver the thing alongside it, and leave a narrow path for the user
  to ask again after reading. Watch for the loophole: `/debrief` first relocated the fix into
  an action item, so the rule had to say an action item states the change without containing
  it.
- **Every user-invocable skill needs a `when_to_use`.** Nothing enforces it, and `/hotfix`
  shipped without one until these evals found it. A `when_to_use` that does not claim a
  request shape silently loses that request to the bare model — the single largest cause of
  red cases here.
- **A frontmatter break is silent at runtime.** An unquoted scalar containing `": "` fails
  the whole YAML parse and the skill loads with every field dropped, scoring oddly rather
  than erroring. `claude plugin validate .` catches it; the run does not. Re-measure after
  fixing one.
- **A long `SKILL.md` needs a supporting directory.** `validate-skills` runs with
  `fail-on-warning: true`, and `body-progressive-disclosure` fails a long SKILL.md with no
  `references/` beside it. `/create` (83 lines), `/elements-of-style` (89) and `/rebase`
  (104) have none and are well short of tripping it; adding a long section to one is where
  this bites.

---

## When to update what

| You changed | Do this |
| ----------- | ------- |
| Added a skill | Add `evals/tests/<skill>.yaml`, register it under `tests:` in the right group, and weight its routing assertion |
| What a skill teaches | Run its cases and update any that asserted the old behavior |
| A path or filename convention | Update the `regex` asserting its shape — the conventions in `docs/` are asserted literally |
| A skill's review agent set | Update the agent-name assertions, and the `not-regex` keeping the sets from overlapping |
| A skill's `allowed-tools` | Confirm by hand that every name still exists. Nothing validates them |
| `disable-model-invocation` on any skill | Check no other skill instructs the model to call it, and move its cases to the slash-command group |
| `tools`, `working_dir`, `setting_sources` or `plugins` | Re-baseline. Earlier numbers are void |
