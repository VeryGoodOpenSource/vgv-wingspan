---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [refine-approach]
description: "That answering the open questions a review raised gets folded into the approach instead of being asked again."
---

Duplicates get skipped — keep the existing contact. Cap the file at 5,000 rows. Invalid rows get skipped individually and listed in the summary, the rest of the import still goes through.
