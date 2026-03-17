---
name: create
user-invocable: true
description: Scaffold a new project by routing to the right companion plugin. Use when user says "create a project", "new flutter app", "start a dart package", "scaffold", or asks to set up a new codebase.
argument-hint: what to create (e.g., "flutter app", "dart package")
---

# Create a new project

Route project creation to the right companion plugin. Wingspan does not scaffold projects itself — it discovers which companion plugin handles the requested project type and delegates to it.

## Project description

<description>$ARGUMENTS</description>

**If the description above is empty**, use the **AskUserQuestion tool**:

- **Question:** "What kind of project would you like to create?"
- **Options:** "Flutter app", "Dart package", "Dart CLI", "Other"

DO NOT proceed until you have a project description.

## Step 1: Find a matching companion plugin

Use Glob to find recommendation files:

```
plugins/wingspan/hooks/recommendations/*.json
```

Read each file. Skip files without a `create` field. For those that have one, check whether any of the `create.keywords` appears in the user's project description (case-insensitive).

- **No match:** Inform the user no companion plugin handles this project type. Stop.
- **Match found:** Proceed with the matched recommendation.

See `references/recommendation-format.md` for the recommendation file schema.

## Step 2: Verify the companion plugin is installed

Use Grep to search for the plugin name in these settings files (check each that exists):

1. `.claude/settings.local.json`
2. `.claude/settings.json`
3. `$HOME/.claude/settings.json`

**If NOT installed**, tell the user:

```
The `<plugin-name>` plugin is needed. Install it:

/plugin marketplace add <marketplace>
/plugin install <plugin-name>

Then run `/create <original description>` again.
```

Stop after showing install instructions.

## Step 3: Delegate to the companion plugin

The companion plugin owns template selection, project naming, and all creation details. Hand off by calling the plugin's creation MCP tool. Discover the correct tool name from the available MCP tools — look for a tool from the matched plugin that handles project creation.

Pass the user's full project description so the plugin can determine the right template and parameters.

**If the tool call fails:** Surface the error to the user and suggest running the creation command manually.

## Important

- This skill is a thin router. No technology-specific logic.
- Do not guess MCP tool names. Discover them from available tools.
- Every user-facing question must use the **AskUserQuestion tool**.
