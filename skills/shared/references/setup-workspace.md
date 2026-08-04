# Set Up Workspace

Run before a skill writes its first file, so no document lands as an uncommitted change on a
shared branch.

Run `git rev-parse --abbrev-ref HEAD`. If the result is a base branch (`main`, `master`, or
`develop`), use **AskUserQuestion** to offer creating a feature branch before writing:

```bash
git checkout -b <type>/<kebab-topic>
```

Keep the branch name under 60 characters. `<type>` matches the work (`feat`, `fix`,
`refactor`, `docs`).

If the session is already on a feature branch, continue without prompting.
