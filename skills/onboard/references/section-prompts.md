# Section Prompts for Onboard Analysis

This document defines the 9 required sections the `onboard-analysis-agent` must produce. Each section header maps directly to a placeholder in the HTML template.

The agent's output must use **exactly** these markdown headers. The skill parses them to inject content into the HTML template.

---

## Section 1: Project Overview & Tech Stack

**Header:** `## Project Overview & Tech Stack`

**Must include:**
- What the project is (one paragraph)
- Primary language(s) and versions
- Frameworks and major libraries with versions
- Build tools and task runners
- Runtime requirements (Node, JVM, Docker, etc.)
- Repository type (monorepo, single package, workspace)

---

## Section 2: Architecture Map

**Header:** `## Architecture Map`

**Must include:**
- Top-level directory layout with purpose of each directory
- Module/package boundaries — each independently buildable or importable unit
- Responsibility of each module in one sentence
- Layer structure if present (data, domain, presentation, etc.)
- Boundary rules — what's allowed to import what

**Format:** Use nested markdown lists to show hierarchy.

---

## Section 3: Dependency Graph

**Header:** `## Dependency Graph`

**Must include:**
- The shape of the dependency graph (e.g., hub-and-spoke, layered, flat)
- Hub modules and leaf modules — what role they play
- Circular dependencies or surprising relationships (if any)
- 3-5 most important external dependencies and what role they play

**Format:** Use arrow notation (`module-a → module-b`) or a simplified diagram. For repos with many modules, describe the pattern rather than listing every relationship — a 15-row table is less useful than a clear description of the graph's shape.

---

## Section 4: Entry Points

**Header:** `## Entry Points`

**Must include:**
- Every place where execution begins
- File path and line number for each
- What each entry point does (one sentence)
- Types: main files, CLI commands, HTTP routes, exported APIs, event handlers, job runners

---

## Section 5: Data & State Flow

**Header:** `## Data & State Flow`

**Must include:**
- Primary user-facing flows (e.g., "request comes in at X, passes through Y, hits DB at Z")
- Where state is stored (in-memory, database, cache, global store)
- How side effects are managed
- State management pattern if applicable

---

## Section 6: Key Abstractions

**Header:** `## Key Abstractions`

**Must include:**
- Types, interfaces, and classes that shape how you think about the codebase
- File path for each
- Why each matters (one sentence)
- Domain models, DTOs, configuration types
- Base classes or interfaces that define contracts

---

## Section 7: Test Landscape

**Header:** `## Test Landscape`

**Must include:**
- Testing framework(s) and conventions (e.g., "uses mocktail for mocking, pump for widget tests")
- Qualitative coverage narrative — which areas are well-tested, which are thin
- Types of tests present (unit, integration, E2E, visual) and where each type lives
- Test patterns used (mocks, fixtures, factories)

**Do not** enumerate exact file counts per module. Describe coverage in relative terms ("strong", "minimal", "none found").

---

## Section 8: Build & Run Instructions

**Header:** `## Build & Run Instructions`

**Must include:**
- Prerequisites (tools, runtimes, services that must be running)
- General workflow: install deps → build → run → test
- Gotchas that will trip up a newcomer (e.g., codegen must run first, multiple SDK versions coexist)
- Where to find detailed commands (Makefile, package.json scripts, root README)

**Do not** reproduce full command sequences that already exist in project files. Point to the source of truth. Focus on what a newcomer needs to know that isn't obvious from the project files themselves.

---

## Section 9: Suggested Reading Order

**Header:** `## Suggested Reading Order`

**Must include:**
- Numbered list of files/directories to read
- File path for each item
- Brief rationale for why to read it at that position
- Start with entry points, then core abstractions, then modules in dependency order
