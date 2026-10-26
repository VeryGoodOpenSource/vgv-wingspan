---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [debrief]
description: "That notes blaming named colleagues come back as a write-up about systems and process, with the blame dropped."
---

Yesterday's Android release shipped a crash on launch. Here are my notes — they are all the information that exists, treat them as authoritative, there is nothing else to look up.

- Petra merged PR #412 on Tuesday afternoon. It changed how the app reads the feature-flag config at startup.
- The PR had one approval. Milan approved it in about two minutes and never ran the build.
- The new code path throws when the config file is missing, which is exactly the case on a fresh install.
- QA only ever tests an upgrade from the previous build, never a fresh install, so it went green.
- Release went out Wednesday 09:00. Crash reports started within the hour. About 4% of sessions on the new build crashed on launch.
- We rolled back at 11:30 Wednesday. Nothing to fix forward yet.
- Honestly this one is on Petra, she rushed it through, and Milan rubber-stamped the review.

Write this up as an incident review for the whole team to read. Put the write-up itself in your reply — I have no repo access to give you right now, so do not try to save it anywhere; I will file it myself.
