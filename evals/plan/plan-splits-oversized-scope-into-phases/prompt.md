---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan]
description: "That a feature spanning several layers is called too large for one pull request and broken into numbered phases rather than planned as one pass."
---

This is the agreed shape of the work. It came out of a discussion yesterday and it is the only record of it, so treat it as authoritative:

Team workspaces.

- A workspace owns its own members, invitations and roles (owner, editor, viewer).
- Every existing record gains a workspace it belongs to; current rows migrate into one personal workspace per existing user.
- Every read and write is scoped to the caller's current workspace, enforced on the server.
- Invitations go out by email, expire after seven days, and a signed-out invitee has to create an account first.
- Four screens: a workspace switcher, a members list, an invitation form, and a settings screen for renaming or deleting a workspace.
- Deleting a workspace soft deletes it for 30 days before it is purged.
- Roles are enforced in the interface as well as on the server.

The product is a Node and Express API on Postgres with a React front end and a transactional email service already wired up. That code sits in another repository, not the one you are opened in, so work from this description — it is accurate and it is all you need.

Turn this into an implementation plan.
