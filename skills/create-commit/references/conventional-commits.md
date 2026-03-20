# Conventional Commits Reference

Full spec: [conventionalcommits.org](https://www.conventionalcommits.org)

## Format

`type(scope)!: short description`

## Types

| Type | When to use |
| ---- | ----------- |
| `feat` | New feature visible to the user |
| `fix` | Bug fix |
| `refactor` | Code restructuring, no behavior change |
| `test` | Adding or updating tests only |
| `docs` | Documentation only |
| `chore` | Maintenance tasks (deps, config, tooling) |
| `build` | Build system or external dependencies |
| `ci` | CI/CD pipeline changes |
| `perf` | Performance improvement |
| `revert` | Reverts a previous commit |
| `style` | Formatting — no logic change |

## Scope

Use the feature folder, package name, or layer (`feat(auth)`, `fix(verify_email)`, `chore(deps)`). Omit only when the change is truly global.

## Subject line rules

- Imperative mood, present tense: "add", "fix", "remove"
- No capital letter after the colon
- No period at the end
- Max 72 characters
- Use `!` for breaking changes: `feat(auth)!: remove legacy login flow`

## Body (optional but recommended)

- Blank line between subject and body
- Explain **what** and **why**, not how
- Wrap at 72 characters per line
- Ticket in footer: `Refs: VGV-123` or `Closes: VGV-123`
