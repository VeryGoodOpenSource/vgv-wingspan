# Validate and Fix

Run static analysis — detect and use the project's linter/analyzer.

Run tests — detect and use the project's test runner.

If failures occur:
- Fix the issue and re-run
- Up to 3 attempts per failure
- After 3 failed attempts, use **AskUserQuestion** to ask the user for guidance with context on what failed and what you tried

Fix all lint warnings before proceeding.
