/**
 * Checks that the response carries a well-formed `success-criteria` block.
 *
 * That block is the contract `/build` parses as its ship gate, so its shape is
 * load-bearing rather than cosmetic. `skills/shared/references/plan-templates/success-criteria.md`
 * defines it:
 *
 *   ```success-criteria
 *   GOAL: <one sentence>
 *
 *   SUCCESS CRITERIA:
 *   - <observable criterion> | verify: <shell command; exit 0 = pass>
 *   - <observable criterion> | verify: manual <numbered human steps>
 *
 *   NON-GOALS:
 *   - <explicitly out of scope>
 *
 *   VERIFICATION COMMAND: <the non-manual verify commands joined; exit 0 = all green>
 *   ```
 *
 * A regex can prove `verify:` appears somewhere. It cannot prove that *every*
 * criterion carries one, which is the invariant that matters: one unverifiable
 * criterion is enough for `/build` to ship on a gate that proves nothing.
 *
 * The fence label is not graded. Models relabel `success-criteria` as `text` or
 * `markdown` while reproducing the contract exactly, and failing that would measure
 * fence syntax rather than the skill. Any fenced block containing `SUCCESS CRITERIA:`
 * counts, and an unfenced block is accepted as a last resort.
 */
const FENCE = /```[^\n]*\n([\s\S]*?)```/g;
const BULLET = /^\s*[-*]\s+(.*)$/;

/** Pulls the candidate block out of the response, fenced or not. */
function extractBlock(text) {
  for (const match of text.matchAll(FENCE)) {
    if (/^\s*SUCCESS CRITERIA:/m.test(match[1])) return match[1];
  }
  // Unfenced fallback: from GOAL: (or SUCCESS CRITERIA: when GOAL is missing) to the end.
  const start = text.search(/^\s*(GOAL:|SUCCESS CRITERIA:)/m);
  return start === -1 ? null : text.slice(start);
}

/**
 * Splits the block into its labelled sections. Returns the bullet lines under each
 * of SUCCESS CRITERIA and NON-GOALS, plus the inline text of GOAL and
 * VERIFICATION COMMAND.
 */
function parseBlock(block) {
  const sections = { goal: null, criteria: null, nonGoals: null, command: null };
  let current = null;

  for (const rawLine of block.split('\n')) {
    const line = rawLine.trim();

    const goal = line.match(/^GOAL:\s*(.*)$/);
    if (goal) {
      sections.goal = goal[1];
      current = null;
      continue;
    }

    const command = line.match(/^VERIFICATION COMMAND:\s*(.*)$/);
    if (command) {
      sections.command = command[1];
      current = null;
      continue;
    }

    if (/^SUCCESS CRITERIA:/.test(line)) {
      sections.criteria = [];
      current = 'criteria';
      continue;
    }

    if (/^NON-GOALS:/.test(line)) {
      sections.nonGoals = [];
      current = 'nonGoals';
      continue;
    }

    const bullet = rawLine.match(BULLET);
    if (bullet && current) sections[current].push(bullet[1].trim());
  }

  return sections;
}

function fail(reason) {
  return { pass: false, score: 0, reason };
}

module.exports = (output) => {
  const text = String(output ?? '');
  const block = extractBlock(text);

  if (block === null) {
    return fail('No success-criteria block: neither a GOAL: nor a SUCCESS CRITERIA: line appears.');
  }

  const { goal, criteria, nonGoals, command } = parseBlock(block);

  if (!goal) return fail('The block has no GOAL: line stating the intended end state.');
  if (criteria === null) return fail('The block has no SUCCESS CRITERIA: section.');
  if (criteria.length === 0) return fail('The SUCCESS CRITERIA: section lists no criteria.');

  const unverifiable = criteria.filter((line) => !/verify:\s*\S/.test(line));
  if (unverifiable.length > 0) {
    return fail(
      `${unverifiable.length} of ${criteria.length} criteria carry no \`verify:\`, so /build ` +
        `would gate on a criterion nothing can prove. First one: "${unverifiable[0]}".`,
    );
  }

  if (nonGoals === null) return fail('The block has no NON-GOALS: section.');
  if (!command) {
    return fail(
      'The block has no VERIFICATION COMMAND: line, so /build has no single authoritative gate.',
    );
  }

  return {
    pass: true,
    score: 1,
    reason: `Well-formed success-criteria block: ${criteria.length} criteria, each with a \`verify:\`.`,
  };
};
