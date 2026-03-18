---
name: create
user-invocable: true
description: Scaffold a new project by routing to the right companion plugin's create skill. Use when user says "create a project", "new flutter app", "start a dart package", "scaffold", or asks to set up a new codebase.
argument-hint: what to create (e.g., "flutter app", "dart package")
allowed-tools: Skill
---

# Create a new project

Route project creation to the right companion plugin. Wingspan does not scaffold projects itself — it finds the installed companion plugin skill that handles the requested project type and delegates to it.

## Project description

<description>$ARGUMENTS</description>

**If the description above is empty**, use the **AskUserQuestion tool**:

- **Question:** "What kind of project would you like to create?"
- **Options:** "Flutter app", "Dart package", "Dart CLI", "Other"

DO NOT proceed until you have a project description.

## Step 1: Find a matching create skill

The available skills are listed in the system-reminder in your conversation context. Find a skill from a companion plugin that handles project creation for the type described by the user.

Match the user's project description against skill names and descriptions (case-insensitive). Look for skills that mention project creation, scaffolding, or template generation for the requested technology stack.

- **No match:** Inform the user no companion plugin with a create skill is installed for this project type. Stop.
- **Multiple matches:** Pick the most specific match for the requested project type.
- **Match found:** Proceed to Step 2.

## Step 2: Delegate to the companion plugin's create skill

Invoke the matched skill using the **Skill tool**, passing the user's full project description as arguments so the plugin can determine the right template and parameters.

**If the skill invocation fails:** Surface the error to the user and suggest verifying the companion plugin is properly installed.

## Important

- This skill is a thin router. No technology-specific logic.
- Every user-facing question must use the **AskUserQuestion tool**.
