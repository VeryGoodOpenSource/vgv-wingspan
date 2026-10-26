---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
tags: [plan]
description: "That each phase of a plan carries its own scope, the files it touches, and the proof it is done, so it can be implemented and merged on its own."
---

Here is the agreed shape of the work, from a discussion yesterday. It is the only record of it, so treat it as authoritative:

Export to CSV.

- A user can export their order history as a CSV file.
- The export runs in the background; the largest accounts have hundreds of thousands of rows.
- The user gets an email with a download link when it is ready, and the link expires after 24 hours.
- The export respects whatever filters the user had applied on screen.
- A failed export is retried twice, then the user is told it failed.

The app is a Node and Express service on Postgres with a React front end, a job queue, object storage and a transactional email service already in place. That code sits in another repository, not the one you are opened in, so work from this description — it is accurate and it is all you need.

Give me the implementation plan, as one document. I will be building it myself across several sittings and I start each one from scratch, so I have to be able to pick the work up one piece at a time: what that piece delivers, what it touches, and how I know it is finished before I move on.
