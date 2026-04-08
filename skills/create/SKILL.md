---
name: create
user-invocable: true
description: Scaffolds a new project by routing to the right companion plugin's create skill. Use when user says "create a project", "new flutter app", "start a dart package", "scaffold", or asks to set up a new codebase.
argument-hint: what to create (e.g., "flutter app", "dart package")
effort: low
allowed-tools: Read Glob Skill
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Create a new project

Route project creation to the right companion plugin. Wingspan does not scaffold projects itself — it discovers companion plugins from recommendation files and delegates to the matching plugin's create skill.

## Project description

<description>$ARGUMENTS</description>

**If the description above is empty:**

1. First, scan recommendation files (Step 1 below) to discover available project types.
2. Then use **AskUserQuestion tool**:
   - **Question:** "What kind of project would you like to create?"
   - **Options:** Build the option list from the discovered companion plugins' descriptions, plus "Other" as the last option.

DO NOT proceed until you have a project description.

## Step 1: Scan recommendation files

Use **Glob** to find all `*.json` files in `hooks/recommendations/` (relative to the Wingspan plugin root). Then **Read** each file.

Each recommendation file has this structure:

```json
{
  "plugin": "plugin-name",
  "description": "What the plugin provides.",
  "marketplace": "OrgName/repo-name"
}
```

## Step 2: Match the user's request to a plugin

Compare the user's project description against each recommendation's `plugin` name and `description` (case-insensitive). Pick the plugin whose description best matches the requested technology.

- **No match:** Inform the user no companion plugin is registered for this project type. Stop.
- **Multiple matches:** Pick the most specific match for the requested project type.
- **Match found:** Proceed to Step 3.

## Step 3: Verify the plugin is installed

Check the available skills listed in the system-reminder in your conversation context for any skill prefixed with the matched plugin name (`<plugin-name>:`).

If **no skills from that plugin are listed**, the plugin is not installed. Use **AskUserQuestion tool**:

- **Question:** "The companion plugin '`<plugin>`' is needed but not installed. Would you like to install it?"
- **Options:**
  1. "Yes, install it" *(default)*
  2. "No, stop"

If the user chooses to install, output the following commands and **stop**:

```bash
/plugin marketplace add <marketplace>
/plugin install <plugin>
```

Tell the user to run these commands, then re-invoke `/create` with the same project description. **Do not proceed to Step 4.**

## Step 4: Find and invoke the plugin's project-creation skill

The available skills are listed in the system-reminder in your conversation context. Look for skills prefixed with the matched plugin name (`<plugin-name>:<skill-name>`). Among those, find the skill whose name or description best indicates project creation (look for terms like "create", "scaffold", "new project", "generate", "init").

Invoke it using the **Skill tool** with its fully qualified name (e.g., `my-plugin:scaffold-project`), passing the user's full project description as arguments.

- **No project-creation skill found for the plugin:** Inform the user the companion plugin is registered but does not provide a project-creation skill. Stop.
- **If the skill invocation fails:** Surface the error to the user and suggest verifying the companion plugin is properly installed.

## Important

- This skill is a thin router. No technology-specific logic.
- Every user-facing question must use the **AskUserQuestion tool**.
