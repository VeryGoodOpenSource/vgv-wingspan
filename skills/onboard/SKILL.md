---
name: onboard
user-invocable: true
description: "Walks a repository and generates a self-contained HTML site summarizing its structure, architecture, and key abstractions. Use when user says \"onboard\", \"explain this repo\", \"codebase overview\", \"help me understand this codebase\", or \"map this codebase\"."
argument-hint: "[path/to/scope (optional, defaults to repo root)]"
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Generate a codebase onboarding site

Walk a repository and generate a self-contained HTML page that explains its structure, architecture, and key abstractions. Focused on understanding — not best practices or framework guidance.

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

### 2.1 Read the template

Read the HTML template from [html-template.html](references/html-template.html).

### 2.2 Prepare metadata

Determine values for the metadata placeholders:

| Placeholder | Value |
|-------------|-------|
| `<!-- META:repo-name -->` | Repository name from Phase 0 |
| `<!-- META:date -->` | Today's date in `YYYY-MM-DD` format |
| `<!-- META:scope -->` | The analysis scope (`.` for full repo, or the provided path) |

### 2.3 Map agent output to HTML sections

Parse the agent's markdown output by splitting on `## ` headers. Convert each section's markdown content to HTML:

| Agent Section Header | HTML Placeholder |
|----------------------|-----------------|
| `## Project Overview & Tech Stack` | `<!-- CONTENT:project-overview -->` |
| `## Architecture Map` | `<!-- CONTENT:architecture-map -->` |
| `## Dependency Graph` | `<!-- CONTENT:dependency-graph -->` |
| `## Entry Points` | `<!-- CONTENT:entry-points -->` |
| `## Data & State Flow` | `<!-- CONTENT:data-state-flow -->` |
| `## Key Abstractions` | `<!-- CONTENT:key-abstractions -->` |
| `## Test Landscape` | `<!-- CONTENT:test-landscape -->` |
| `## Build & Run Instructions` | `<!-- CONTENT:build-run -->` |
| `## Suggested Reading Order` | `<!-- CONTENT:reading-order -->` |

**Markdown to HTML conversion rules:**

- `### Heading` → `<h3>Heading</h3>`
- `#### Heading` → `<h4>Heading</h4>`
- Paragraphs → `<p>...</p>`
- `- item` → `<ul><li>item</li></ul>`
- `1. item` → `<ol><li>item</li></ol>`
- `` `code` `` → `<code>code</code>`
- Code blocks → `<pre><code>...</code></pre>`
- `**bold**` → `<strong>bold</strong>`
- `→` in dependency graphs → `<span class="dep-arrow">→</span>`
- Tables → `<table>` with `<th>` and `<td>`

### 2.4 Assemble and write

1. Replace all `<!-- META:... -->` placeholders with their values
2. Replace all `<!-- CONTENT:... -->` placeholders with the converted HTML
3. Ensure `docs/onboard/` directory exists:

   ```bash
   mkdir -p docs/onboard
   ```

4. Write the assembled HTML to:

   ```
   docs/onboard/YYYY-MM-DD-<repo-name>-onboard.html
   ```

## Phase 3 — Handoff

Announce completion:

```md
Onboard site generated!

File: docs/onboard/<filename>.html

Open it in any browser — the file is fully self-contained with no external dependencies.
```

## Gotchas

- The HTML file must be self-contained: all CSS and JS inline, no external fonts, no CDN scripts. It must work from `file://` with no network.
- The agent output must use the exact section headers listed above. If a header is missing, leave the corresponding HTML placeholder empty with a `<p>No data available for this section.</p>` fallback.
- Large monorepos: the agent should focus on the top-level structure and the most significant modules, not exhaustively document every package. Depth over breadth for the most important areas.
- The generated file is an untracked working file. The user decides whether to commit it.

## Important

This skill generates a static HTML document. It does NOT make any changes to the codebase, run tests, or modify project configuration.
