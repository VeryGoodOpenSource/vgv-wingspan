---
name: create
description: Scaffold a new Dart or Flutter project using VeryGoodCLI templates with VGV conventions
---

# Create a new Dart or Flutter project

Scaffold a new project using VeryGoodCLI templates. Enforce VGV conventions, resolve dependencies, verify the scaffold, and check license compliance.

## Project request

<project request>$ARGUMENTS</project request>

**If the project request above is empty, ask the user**: "What kind of project would you like to create? Describe the project type, name, and any specific requirements."

DO NOT proceed until you have a description from the user.

## Execution flow

### 0. Parse the request

Extract from the user's input:

- **Project type**: Which template? (`flutter_app`, `flutter_package`, `flutter_plugin`, `flame_game`, `dart_cli`, `dart_package`, `docs_site`)
- **Project name**: Valid Dart package name (lowercase, underscores)
- **Description**: Short project description
- **Organization**: Org identifier (e.g., `com.example`)
- **Output directory**: Where to create the project
- **Platforms**: Target platforms (for `flutter_plugin` and `flame_game`)

### 1. Clarify missing parameters

If the project type or name is ambiguous, use the **AskUserQuestion tool** to resolve:

- If no type is specified, ask which template to use. Default suggestion: `flutter_app` for apps, `flutter_package` for libraries, `dart_package` for pure Dart.
- If the name contains invalid characters, suggest a corrected name.
- If platforms are relevant but unspecified, ask which platforms to target.

Do not ask about parameters that have sensible defaults (`org_name`, `publishable`, `output_directory`) unless the user's request implies they care about them.

### 2. Scaffold the project

Run: Task @vgv-scaffold-agent with the resolved parameters.

The scaffold agent will:
1. Create the project via the `create` MCP tool
2. Resolve dependencies via `packages_get`
3. Run initial tests via `test`

### 3. Check license compliance

Run: Task @license-compliance-agent on the new project directory.

This establishes a clean compliance baseline from the start.

### 4. Report and suggest next steps

Summarize:
- Project created at `<path>`
- Dependencies resolved
- Tests passing (or issues found)
- License compliance status

Use the **AskUserQuestion tool** to ask: "What would you like to do next?"

Options:
- **`/ideate`** — Brainstorm the first feature for this project
- **`/plan`** — Plan an implementation if requirements are already clear
- **Done** — Finish here

## Principles

- A scaffold that doesn't pass its own tests is broken. Never skip the verification step.
- Prefer the simplest template that meets the user's needs. Don't suggest `flutter_plugin` when `flutter_package` suffices.
- License compliance starts at project creation, not at release time.
