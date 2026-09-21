# Feature Branch Check

Run before writing any document or code, so work never lands on a base branch.

```bash
git rev-parse --abbrev-ref HEAD
```

- **Already on a feature branch** → continue without prompting.
- **On a base branch** (`main`, `master`, or `develop`) → use **AskUserQuestion** to offer
  creating one: `git checkout -b <type>/<kebab-topic>`, name under 60 characters. `<type>` is
  the conventional-commit type for the work (`feat`, `fix`, `refactor`, …).

A hotfix is the exception: it uses the `hotfix/` prefix, not `fix/`.
