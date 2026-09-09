/**
 * Turns a promptfoo `-o` JSON export into a GitHub step summary.
 *
 *   node evals/ci-summary.js evals/.runs/ci.json [> $GITHUB_STEP_SUMMARY]
 *
 * Lives in a file rather than inline in the workflow so it can be run against a real
 * export locally, which is the only way to know the field paths still hold after a
 * promptfoo upgrade.
 *
 * The skill for each result comes from the case files, not from parsing the description.
 * That is not a stylistic choice here: wingspan has two pairs of skills where one name is
 * a prefix of the other — `create` / `create-pr` and `plan` / `plan-technical-review` — so
 * both splitting on `-` and guessing the longest prefix attribute cases to the wrong skill.
 * A local script of mine did exactly that and reported `plan` as 4/8 when it is 4/5.
 */
const fs = require('node:fs');
const path = require('node:path');

const TESTS_DIR = path.join(__dirname, 'tests');

/**
 * description -> skill, read from the case files themselves.
 *
 * Scraped with a regex rather than parsed as YAML on purpose: CI installs only the Claude
 * Agent SDK, so a `js-yaml` require would fail there. `- description: <name>` at the start
 * of a line is the one shape every case in every file uses, and the descriptions are plain
 * kebab-case with no quoting or line wrapping.
 */
function skillIndex() {
  const map = new Map();
  for (const f of fs.readdirSync(TESTS_DIR).filter((f) => f.endsWith('.yaml'))) {
    const skill = f.replace(/\.yaml$/, '');
    const text = fs.readFileSync(path.join(TESTS_DIR, f), 'utf8');
    for (const m of text.matchAll(/^- description:\s*(\S.*?)\s*$/gm)) {
      map.set(m[1].replace(/^['"]|['"]$/g, ''), skill);
    }
  }
  return map;
}

/**
 * Did this result miss its routing proof?
 *
 * For most skills that is a failing `skill-used`. `create-pr` and `rebase` declare
 * `disable-model-invocation: true` and can never satisfy it, so their proof that the skill
 * loaded is `not-icontains 'Unknown command'` — a failing one there is the same signal and
 * has to be counted, or those two files would always report zero routing misses.
 */
function missedRouting(parts) {
  return parts.some(
    (c) =>
      !c.pass &&
      (c.assertion?.type === 'skill-used' ||
        (c.assertion?.type === 'not-icontains' &&
          String(c.assertion?.value ?? '').includes('Unknown command'))),
  );
}

function summarize(report, index) {
  const rows = report?.results?.results ?? [];
  const per = new Map();
  const hardErrors = [];
  const failures = [];

  for (const x of rows) {
    const desc = x.testCase?.description ?? '<unknown>';
    const skill = index.get(desc) ?? '(unmapped)';
    const column = x.provider?.label ?? x.provider?.id ?? '?';
    const key = `${skill} ${column}`;
    const agg = per.get(key) ?? { n: 0, pass: 0, routeMiss: 0 };
    agg.n += 1;
    if (x.success) agg.pass += 1;

    const parts = x.gradingResult?.componentResults ?? [];
    if (missedRouting(parts)) agg.routeMiss += 1;
    per.set(key, agg);

    // A threshold message is a content failure; anything else is a harness or API problem
    // and scores 0 with no failing assertion, which reads identically unless separated.
    // `Reached maximum number of turns` shows up this way about once per full run.
    const err = String(x.error ?? '');
    if (err && !/Aggregate score/.test(err)) {
      hardErrors.push(`${desc}: ${err.replace(/\s+/g, ' ').slice(0, 160)}`);
    }
    if (!x.success) failures.push({ desc, score: x.score ?? 0, parts });
  }

  const out = ['### Eval results', ''];
  if (rows.length === 0) {
    out.push('No results in the export. The run did not produce anything to grade.');
    return out.join('\n');
  }

  out.push('| Skill | Column | Passed | Routing misses |', '| --- | --- | --- | --- |');
  for (const [key, v] of [...per.entries()].sort()) {
    const [skill, column] = key.split(' ');
    out.push(`| ${skill} | ${column} | ${v.pass}/${v.n} | ${v.routeMiss} |`);
  }

  const passed = rows.filter((x) => x.success).length;
  out.push('', `**${passed} of ${rows.length} results passed.**`);

  if (hardErrors.length) {
    out.push(
      '',
      '**Hard errors.** These score 0 with no failing assertion, so they are not a content',
      'signal — usually a turn cap, a budget cap, or an overloaded API.',
      '',
    );
    for (const e of hardErrors.slice(0, 10)) out.push(`- \`${e}\``);
    if (hardErrors.length > 10) out.push(`- …and ${hardErrors.length - 10} more`);
  }

  if (failures.length) {
    out.push('', '<details><summary>Failing cases</summary>', '');
    for (const f of failures) {
      out.push(`**${f.desc}** — score ${f.score.toFixed(2)}`);
      for (const c of f.parts.filter((c) => !c.pass)) {
        const reason = String(c.reason ?? '').replace(/\s+/g, ' ').slice(0, 220);
        out.push(`- \`[${c.assertion?.type}]\` ${reason}`);
      }
      out.push('');
    }
    out.push('</details>');
  }

  out.push(
    '',
    '> Advisory, not a gate. Two unedited cases have been measured moving between runs, one',
    '> of them across the pass/fail line, so confirm a red case with `--repeat 3` locally',
    '> before treating it as a regression.',
  );
  return out.join('\n');
}

module.exports = { summarize, skillIndex, missedRouting };

if (require.main === module) {
  const [reportPath] = process.argv.slice(2);
  if (!reportPath) {
    console.error('usage: node evals/ci-summary.js <promptfoo-output.json>');
    process.exit(2);
  }
  let report;
  try {
    report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  } catch (error) {
    console.error(`ci-summary: could not read ${reportPath}: ${error.message}`);
    process.exit(2);
  }
  console.log(summarize(report, skillIndex()));
}
