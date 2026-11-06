---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [brainstorm]
description: "That an idea pitched entirely as implementation detail is pulled back to what the feature must do before how to build it."
---

This is the note I wrote for myself this morning. It is the whole of the idea — nothing exists yet and nothing else is written down, so take it as the full picture:

> Notifications. Stand up a WebSocket server, add a notifications table with a read flag, put Redis pub/sub in front of it so it fans out, drain the queue with a worker every second, and show a toast in the client.

That is the stack I had in mind. We are two people and the app has about 300 users. Let's discuss approaches before I commit to any of it.
