---
name: onboard
user-invocable: true
description: >
  Walks a repository and generates a self-contained HTML site summarizing its
  structure, architecture, and key abstractions. Use when user says "onboard",
  "explain this repo", "codebase overview", "help me understand this codebase",
  or "map this codebase".
argument-hint: "[path/to/scope (optional, defaults to repo root)]"
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Generate a codebase onboarding site

Walk a repository and generate a self-contained HTML page that explains its structure, architecture, and key abstractions. Focused on understanding — not best practices or framework guidance.

## Onboard Progress

Copy this checklist and track your progress:

```markdown
Onboard Progress:
- [ ] Phase 0: Parse scope and detect repo
- [ ] Phase 1: Analyze codebase (run analysis agent)
- [ ] Phase 2: Generate HTML (run conversion script, assemble template)
- [ ] Phase 3: Validate output and hand off
```

## Scope

<scope>$ARGUMENTS</scope>

## Phase 0 — Parse scope and detect repo

1. **Parse the scope above.** If empty, default to the repository root (`.`). If a path is provided, validate it exists.

2. **Detect the repository name** for the output filename:

   ```bash
   basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
   ```

3. **Check for existing onboard files:**

   ```bash
   ls docs/onboard/*.html 2>/dev/null
   ```

   If files exist, inform the user: "Found existing onboard site(s) at `docs/onboard/`. Generating a new one will not overwrite existing files (filenames are date-prefixed)."

## Phase 1 — Analyze

Run the **@onboard-analysis-agent** to gather structured codebase analysis. The agent's prompt must include:

1. The scope constraint (repo root or specific path)
2. Instructions to follow the section format defined in [section-prompts.md](references/section-prompts.md)

The agent returns structured markdown with exactly 9 section headers. Capture the full output.

**If the agent fails:** Report the error to the user and stop. Do not generate a partial HTML file.

## Phase 2 — Generate HTML

### 2.1 Save the agent output

Write the agent's markdown output to a temporary file:

```bash
# Write agent output to a temp file for the conversion script
cat > /tmp/onboard-agent-output.md << 'AGENT_EOF'
<paste agent output here>
AGENT_EOF
```

### 2.2 Run the conversion script

Use [convert-md-to-html.py](scripts/convert-md-to-html.py) to assemble the final HTML:

```bash
python3 skills/onboard/scripts/convert-md-to-html.py \
  --template skills/onboard/references/html-template.html \
  --input /tmp/onboard-agent-output.md \
  --repo-name "<repo-name>" \
  --date "YYYY-MM-DD" \
  --scope "<scope>" \
  --output docs/onboard/YYYY-MM-DD-<repo-name>-onboard.html
```

The script handles:
- Parsing agent markdown by `##` headers
- Converting markdown to HTML (headings, lists, code blocks, tables, bold, dep-arrows)
- Replacing all `<!-- META:... -->` and `<!-- CONTENT:... -->` placeholders
- Creating the output directory if needed
- Cross-linking between sections

### 2.3 Validate

Run the validation loop to verify the generated HTML:

1. Check the output file exists and is non-empty
2. Verify no `<!-- CONTENT:` or `<!-- META:` placeholders remain in the output
3. Verify that at least the Project Overview and Architecture Map sections contain real content (not just fallback text)

```bash
# Quick validation checks
test -s docs/onboard/YYYY-MM-DD-<repo-name>-onboard.html && echo "OK: file exists" || echo "FAIL: file missing or empty"
grep -c '<!-- CONTENT:' docs/onboard/YYYY-MM-DD-<repo-name>-onboard.html && echo "FAIL: unfilled placeholders remain" || echo "OK: all placeholders filled"
grep -c '<!-- META:' docs/onboard/YYYY-MM-DD-<repo-name>-onboard.html && echo "FAIL: unfilled meta placeholders" || echo "OK: all meta filled"
```

**If validation fails:**
- Read the script's error output
- Fix the issue (re-run the agent if output was malformed, or fix the script arguments)
- Re-run the conversion script
- Re-validate — repeat until all checks pass

## Phase 3 — Handoff

Announce completion:

```md
Onboard site generated!

File: docs/onboard/<filename>.html

Open it in any browser — the file is fully self-contained with no external dependencies.
```

## Gotchas

- The HTML file must be self-contained: all CSS and JS inline, no external fonts, no CDN scripts. It must work from `file://` with no network.
- The agent output must use the exact section headers listed above. If a header is missing, the conversion script fills the placeholder with `<p>No data available for this section.</p>`.
- Large monorepos: the agent should focus on the top-level structure and the most significant modules, not exhaustively document every package. Depth over breadth for the most important areas.
- The generated file is an untracked working file. The user decides whether to commit it.
- The conversion script requires Python 3.6+. No external packages needed — it uses only the standard library.

## Important

This skill generates a static HTML document. It does NOT make any changes to the codebase, run tests, or modify project configuration.
