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

## When the command cannot run

If git is unavailable or the command fails, skip the check and deliver the document or the
change in your reply instead. Never let the question of where the file lives stop the work
from being produced.

Ask about a branch only on a branch name the command actually returned. Never infer the
current branch from the directory, the prompt, or a guess — a document withheld behind an
invented gate is a document the user did not get.
