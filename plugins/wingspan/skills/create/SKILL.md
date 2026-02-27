---
name: create
description: Scaffold a new Dart or Flutter project using Very Good CLI  templates with VGV conventions
---

# Create a new Dart or Flutter project

Orchestrate project scaffolding: gather requirements from the user, delegate execution to the scaffold agent, verify license compliance, and suggest next steps.

## Project request

<project request>$ARGUMENTS</project request>

**If the project request above is empty, ask the user**: "What kind of project would you like to create? Describe the project type, name, and any specific requirements."

DO NOT proceed until you have a description from the user.

## Execution flow

### 1. Clarify the request

Extract **project type**, **name**, and any other details from the user's input. If the type or name is ambiguous, use the **AskUserQuestion tool**:

- No type specified → suggest `flutter_app` for apps, `flutter_package` for libraries, `dart_package` for pure Dart.
- Invalid name → suggest a corrected Dart package name.
- Platforms relevant but unspecified → ask which platforms to target.

Do not ask about parameters with sensible defaults (`org_name`, `publishable`, `output_directory`) unless the user's request implies they care.

### 2. Scaffold the project

Run: Task @vgv-scaffold-agent with the resolved parameters.

The agent handles template selection, parameter validation, project creation, dependency resolution, and test verification. Wait for its structured results before continuing.

### 3. Check license compliance

Run: Task @license-compliance-agent on the new project directory.

License compliance starts at project creation, not at release time.

### 4. Report and suggest next steps

Summarize the scaffold agent's results and license status, then use the **AskUserQuestion tool** to ask: "What would you like to do next?"

Options:
- **`/brainstorm`** — Brainstorm the first feature for this project
- **`/plan`** — Plan an implementation if requirements are already clear
- **Done** — Finish here

## Principles

- Prefer the simplest template that meets the user's needs. Don't suggest `flutter_plugin` when `flutter_package` suffices.
- Never skip verification — a scaffold that doesn't pass its own tests is broken.
