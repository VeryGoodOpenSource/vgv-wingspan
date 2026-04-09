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
- Module-to-module dependency relationships
- Leaf modules (depended on by many, depend on few)
- Circular dependencies (if any)
- Key external dependencies per module

**Format:** Use a markdown table or arrow notation (`module-a → module-b`).

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
- Testing framework(s) used
- Coverage by module (which have tests, which don't)
- Types of tests present (unit, integration, E2E, visual)
- Areas with notably thin or absent coverage
- Test patterns used (mocks, fixtures, factories)

---

## Section 8: Build & Run Instructions

**Header:** `## Build & Run Instructions`

**Must include:**
- Prerequisites (tools, runtimes, env vars)
- Install dependencies
- Build the project
- Run locally
- Run tests
- Any other common tasks (lint, format, generate)

**Format:** Use code blocks for commands.

---

## Section 9: Suggested Reading Order

**Header:** `## Suggested Reading Order`

**Must include:**
- Numbered list of files/directories to read
- File path for each item
- Brief rationale for why to read it at that position
- Start with entry points, then core abstractions, then modules in dependency order
