---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan]
description: "That the plan names the project's own files and existing test rather than designing against an imagined codebase."
---

The counter in this project only ever counts up by whatever amount it is handed. I want two things from it: a configurable step, so a call with no argument moves the value by that step, and a way to put the value back to where it started. Nobody already calling it with an explicit amount should have to change their code.

Give me the implementation plan before any code gets written.
