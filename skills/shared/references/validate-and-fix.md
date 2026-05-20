# Validate and Fix

Run static analysis — detect and use the project's linter/analyzer. If MCP tools are available for the project's analyzer, prefer them over shell commands.

Run tests — detect and use the project's test runner. If MCP tools are available for the project's test runner, prefer them over shell commands.

If failures occur:
- Fix the issue and re-run
- Up to 3 attempts per failure
- After 3 failed attempts, use **AskUserQuestion** to ask the user for guidance with context on what failed and what you tried

Fix all lint warnings before proceeding.
