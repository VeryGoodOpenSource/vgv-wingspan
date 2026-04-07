# Push Reference

How to push the current branch and handle common failures.

## Push

```bash
git push -u origin <branch>
```

## If the push fails

Diagnose the error and guide the user:

- **Authentication failure** — advise checking SSH keys or credentials for the remote host.
- **Non-fast-forward rejection** — the remote has commits the local branch does not; advise running `git pull --rebase` and re-pushing.
- **Remote not found** — the remote URL may be missing or incorrect; advise running `git remote -v` to verify.
- **Other errors** — report the full error output and stop.
